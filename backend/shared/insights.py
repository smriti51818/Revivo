"""Seller insights — pure aggregation + Bedrock prompt/fallback.

Turns a seller's listings + orders into real metrics, then feeds a compact
summary to a Bedrock model (Amazon Nova) for recommendations. Falls back to
deterministic, data-grounded advice when Bedrock isn't available.
"""
from __future__ import annotations

import time
import json
from datetime import datetime, timezone

# Platform-wide impact constants — shared with shared.models.aggregate_impact so
# the meal/CO2/savings math is identical everywhere the app shows it.
from shared.models import _CO2_PER_KG, _MEALS_PER_KG

_IST_OFFSET = 19800  # +5:30 for local (India) hour-of-day

_MONTHS = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
]
_WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

# period -> (number of buckets, days per bucket). "year" is handled specially
# with calendar-month buckets. None means "all time" (no order filtering).
_PERIODS = {"week": (7, 1), "month": (4, 7), "year": (12, None)}


def _f(value) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def _epoch(value) -> int | None:
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _ist_hour(epoch) -> int | None:
    try:
        return datetime.fromtimestamp(
            int(epoch) + _IST_OFFSET, tz=timezone.utc
        ).hour
    except (TypeError, ValueError):
        return None


def _window_start(period: str | None, now: int) -> int | None:
    """Epoch cutoff for a period, or None for 'all time'/unknown period."""
    if period == "week":
        return now - 7 * 86400
    if period == "month":
        return now - 28 * 86400
    if period == "year":
        return now - 365 * 86400
    return None


def _earnings_series(orders: list, period: str | None, now: int) -> dict:
    """Bucketed revenue for the earnings chart: {'labels': [...], 'values': [...]}.

    week -> 7 daily buckets, month -> 4 weekly buckets, year -> 12 monthly
    buckets. Values are rupee totals; the client just plots them.
    """
    period = period if period in _PERIODS else "week"

    if period == "year":
        now_dt = datetime.fromtimestamp(now + _IST_OFFSET, tz=timezone.utc)
        # 12 month buckets ending with the current month.
        months = []
        y, m = now_dt.year, now_dt.month
        for _ in range(12):
            months.append((y, m))
            m -= 1
            if m == 0:
                m = 12
                y -= 1
        months.reverse()
        index = {ym: i for i, ym in enumerate(months)}
        values = [0.0] * 12
        for o in orders:
            e = _epoch(o.get("createdAt"))
            if e is None:
                continue
            d = datetime.fromtimestamp(e + _IST_OFFSET, tz=timezone.utc)
            i = index.get((d.year, d.month))
            if i is not None:
                values[i] += _f(o.get("total"))
        labels = [_MONTHS[m - 1] for (_, m) in months]
        return {"labels": labels, "values": [round(v) for v in values]}

    buckets, bucket_days = _PERIODS[period]
    span = bucket_days * 86400
    values = [0.0] * buckets
    for o in orders:
        e = _epoch(o.get("createdAt"))
        if e is None:
            continue
        age = now - e
        if age < 0:
            age = 0
        idx = buckets - 1 - (age // span)
        if 0 <= idx < buckets:
            values[idx] += _f(o.get("total"))

    if period == "week":
        today = datetime.fromtimestamp(now + _IST_OFFSET, tz=timezone.utc).weekday()
        labels = [_WEEKDAYS[(today - (buckets - 1 - i)) % 7] for i in range(buckets)]
    else:  # month -> weekly buckets
        labels = ["Wk 1", "Wk 2", "Wk 3", "Wk 4"]
    return {"labels": labels, "values": [round(v) for v in values]}


def _impact(orders: list) -> dict:
    """Meals + buyer savings from the (period-filtered) orders.

    Uses the same constants and savings formula as shared.models.aggregate_impact
    so the seller's insights never disagree with the network impact page.
    """
    kg = sum(_f(o.get("quantityKg")) for o in orders)
    savings = sum(
        max(
            0.0,
            (_f(o.get("marketPricePerKg")) - _f(o.get("pricePerKg")))
            * _f(o.get("quantityKg")),
        )
        for o in orders
    )
    return {
        "foodKeptKg": round(kg, 1),
        "meals": round(kg * _MEALS_PER_KG),
        "buyerSavings": round(savings),
        "co2SavedKg": round(kg * _CO2_PER_KG),
    }


def aggregate_seller_insights(
    listings: list,
    orders: list,
    period: str | None = None,
    now: int | None = None,
) -> dict:
    """Aggregate a seller's LISTING + ORDER items into metrics + top movers.

    When `period` is 'week'/'month'/'year', orders are filtered to that trailing
    window so every downstream number (revenue, movers, earnings chart, impact)
    reflects the selected range. Bands come from the seller's *current* active
    listings — a live snapshot, not a period slice.
    """
    now = now if now is not None else int(time.time())
    period = period if period in _PERIODS else None

    start = _window_start(period, now)
    if start is not None:
        orders = [o for o in orders if (_epoch(o.get("createdAt")) or 0) >= start]

    active = [x for x in listings if x.get("status") == "ACTIVE"]

    revenue = sum(_f(o.get("total")) for o in orders)
    sold_kg = sum(_f(o.get("quantityKg")) for o in orders)

    bands = {"GOOD": 0, "USE_SOON": 0, "RESCUE": 0}
    for x in active:
        b = str(x.get("band", "GOOD"))
        bands[b] = bands.get(b, 0) + 1

    by_veg: dict = {}
    for o in orders:
        veg = o.get("vegetable") or ""
        if not veg:
            continue
        d = by_veg.setdefault(veg, {"kg": 0.0, "revenue": 0.0, "orders": 0})
        d["kg"] += _f(o.get("quantityKg"))
        d["revenue"] += _f(o.get("total"))
        d["orders"] += 1
    movers = sorted(
        (
            {
                "vegetable": k,
                "kg": round(v["kg"], 1),
                "revenue": round(v["revenue"]),
                "orders": v["orders"],
            }
            for k, v in by_veg.items()
        ),
        key=lambda m: m["kg"],
        reverse=True,
    )[:5]

    hours: dict = {}
    for o in orders:
        h = _ist_hour(o.get("createdAt"))
        if h is not None:
            hours[h] = hours.get(h, 0) + 1
    peak_hour = max(hours, key=hours.get) if hours else None

    return {
        "period": period or "all",
        "totals": {
            "activeListings": len(active),
            "listedKg": round(sum(_f(x.get("quantityKg")) for x in active)),
            "soldKg": round(sold_kg, 1),
            "orders": len(orders),
            "revenue": round(revenue),
        },
        "bands": bands,
        "movers": movers,
        "peakHour": peak_hour,
        "earnings": _earnings_series(orders, period, now),
        "impact": _impact(orders),
    }


def _hour_label(hour: int) -> str:
    end = (hour + 3) % 24

    def fmt(h):
        suffix = "AM" if h < 12 else "PM"
        base = h % 12 or 12
        return f"{base} {suffix}"

    return f"{fmt(hour)} – {fmt(end)}"


_SYSTEM = (
    "You are Revivo's analyst for a food-surplus marketplace seller. Given "
    "their real metrics, return exactly 3 short, specific, actionable "
    "recommendations to sell more surplus and waste less. Ground every point "
    "in the numbers. Return ONLY a JSON array of objects with keys 'title' "
    "(<= 6 words) and 'body' (one sentence). No prose, no code fences."
)


def build_insights_converse_args(agg: dict, max_tokens: int = 400) -> dict:
    """Bedrock Converse API kwargs from the aggregated data (model-agnostic)."""
    return {
        "system": [{"text": _SYSTEM}],
        "messages": [
            {
                "role": "user",
                "content": [{"text": "Seller metrics (JSON):\n" + json.dumps(agg)}],
            }
        ],
        "inferenceConfig": {"maxTokens": max_tokens},
    }


def parse_ai_recommendations(text: str) -> list | None:
    """Parse a model's JSON array of {title, body}; None if unusable.

    Tolerates markdown code fences and surrounding prose by slicing from the
    first '[' to the last ']' (models like Nova often add a preamble).
    """
    if not text:
        return None
    cleaned = text.strip()
    if "```" in cleaned:
        cleaned = cleaned.replace("```json", "").replace("```", "")
    start, end = cleaned.find("["), cleaned.rfind("]")
    if start != -1 and end != -1 and end > start:
        cleaned = cleaned[start : end + 1]
    try:
        data = json.loads(cleaned)
    except (ValueError, TypeError):
        return None
    out = []
    for item in data if isinstance(data, list) else []:
        if not isinstance(item, dict):
            continue
        title = str(item.get("title", "")).strip()
        body = str(item.get("body", "")).strip()
        if title and body:
            out.append({"title": title, "body": body})
    return out or None


def fallback_insights(agg: dict) -> list:
    """Deterministic, data-grounded recommendations when Bedrock is unavailable."""
    recs = []
    bands = agg.get("bands", {})
    movers = agg.get("movers", [])
    totals = agg.get("totals", {})
    peak = agg.get("peakHour")

    if bands.get("RESCUE", 0) > 0:
        recs.append(
            {
                "title": "Clear rescue-band stock",
                "body": f"You have {bands['RESCUE']} listing(s) near expiry — "
                "discount them or route to an NGO kitchen today.",
            }
        )
    if movers:
        top = movers[0]
        recs.append(
            {
                "title": f"Restock {top['vegetable']}",
                "body": f"Your best seller: {top['kg']:g} kg sold across "
                f"{top['orders']} order(s).",
            }
        )
    if peak is not None:
        recs.append(
            {
                "title": "List before peak demand",
                "body": f"Most orders land around {_hour_label(peak)} — "
                "list surplus a few hours before.",
            }
        )
    if len(recs) < 3:
        recs.append(
            {
                "title": "List earlier in the day",
                "body": f"{totals.get('listedKg', 0)} kg is active now; "
                "morning listings clear faster before the freshness window closes.",
            }
        )
    return recs[:3]

"""Seller insights — pure aggregation + Bedrock prompt/fallback.

Turns a seller's listings + orders into real metrics, then feeds a compact
summary to a Bedrock model (Amazon Nova) for recommendations. Falls back to
deterministic, data-grounded advice when Bedrock isn't available.
"""
from __future__ import annotations

import json
from datetime import datetime, timezone

_IST_OFFSET = 19800  # +5:30 for local (India) hour-of-day


def _f(value) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def _ist_hour(epoch) -> int | None:
    try:
        return datetime.fromtimestamp(
            int(epoch) + _IST_OFFSET, tz=timezone.utc
        ).hour
    except (TypeError, ValueError):
        return None


def aggregate_seller_insights(listings: list, orders: list) -> dict:
    """Aggregate a seller's LISTING + ORDER items into metrics + top movers."""
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

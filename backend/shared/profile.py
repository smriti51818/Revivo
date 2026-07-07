"""Persisted profile aggregates — the real numbers behind wallet, vendor trust,
and per-user stats that used to be faked client-side.

Two small item types live alongside the domain data in the single table:

    USER#{sub}   / WALLET   -> {balance}                     (Revivo credits, ₹)
    VENDOR#{id}  / STATS    -> {orders, soldKg, revenue,     (reputation)
                                ratingSum, ratingCount}

Both are updated with atomic ADD so concurrent orders/ratings can't race, and
they're created on first write (no pre-seeding). Averages and the Trusted flag
are derived on read so they can never drift from the counters.
"""
from __future__ import annotations

from decimal import Decimal

# Loyalty: 1 credit (= ₹1) earned per ₹10 a buyer saves vs the market price.
_RUPEES_PER_CREDIT = 10

# Trusted Vendor threshold (matches the client's old vendor_directory rule).
_TRUSTED_MIN_ORDERS = 10
_TRUSTED_MIN_RATING = 4.3


def wallet_key(sub: str) -> dict:
    return {"PK": f"USER#{sub}", "SK": "WALLET"}


def vendor_stats_key(vendor_id: str) -> dict:
    return {"PK": f"VENDOR#{vendor_id}", "SK": "STATS"}


def credits_for_saved(saved_rupees: float) -> int:
    """How many credits a buyer earns for saving `saved_rupees` on an order."""
    if saved_rupees <= 0:
        return 0
    return int(saved_rupees // _RUPEES_PER_CREDIT)


def _as_float(value) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


# ─── writes (best-effort; callers wrap so a stats failure never fails the order)

def credit_wallet(table, sub: str, credits: int) -> None:
    if credits <= 0:
        return
    table.update_item(
        Key=wallet_key(sub),
        UpdateExpression="ADD balance :c",
        ExpressionAttributeValues={":c": Decimal(str(int(credits)))},
    )


def spend_wallet(table, sub: str, credits: int) -> int:
    """Deduct up to `credits` from the balance, atomically. Returns the amount
    actually spent (0 if the balance was insufficient)."""
    if credits <= 0:
        return 0
    amount = Decimal(str(int(credits)))
    try:
        table.update_item(
            Key=wallet_key(sub),
            UpdateExpression="ADD balance :neg",
            ConditionExpression="balance >= :amt",
            ExpressionAttributeValues={":neg": -amount, ":amt": amount},
        )
        return int(credits)
    except Exception:
        return 0


def get_wallet_balance(table, sub: str) -> int:
    item = table.get_item(Key=wallet_key(sub)).get("Item") or {}
    return int(_as_float(item.get("balance", 0)))


def record_vendor_sale(table, vendor_id: str, kg: float, revenue: float) -> None:
    if not vendor_id:
        return
    table.update_item(
        Key=vendor_stats_key(vendor_id),
        UpdateExpression="ADD orders :one, soldKg :kg, revenue :rev",
        ExpressionAttributeValues={
            ":one": 1,
            ":kg": Decimal(str(round(_as_float(kg), 2))),
            ":rev": Decimal(str(round(_as_float(revenue), 2))),
        },
    )


def record_vendor_rating(table, vendor_id: str, stars: int) -> None:
    if not vendor_id:
        return
    table.update_item(
        Key=vendor_stats_key(vendor_id),
        UpdateExpression="ADD ratingSum :s, ratingCount :one",
        ExpressionAttributeValues={":s": int(stars), ":one": 1},
    )


# ─── reads / projections ─────────────────────────────────────────────

def to_public_vendor_stats(item: dict | None) -> dict:
    """Derive avg rating + Trusted from the raw counters (never stored, so they
    can't go stale). Returns zeroed stats for a vendor with no activity yet."""
    item = item or {}
    orders = int(_as_float(item.get("orders", 0)))
    rating_count = int(_as_float(item.get("ratingCount", 0)))
    rating_sum = int(_as_float(item.get("ratingSum", 0)))
    avg = round(rating_sum / rating_count, 1) if rating_count else 0.0
    return {
        "orders": orders,
        "soldKg": item.get("soldKg", Decimal("0")),
        "revenue": item.get("revenue", Decimal("0")),
        "avgRating": Decimal(str(avg)),
        "ratingCount": rating_count,
        "trusted": orders >= _TRUSTED_MIN_ORDERS and avg >= _TRUSTED_MIN_RATING,
    }


def aggregate_buyer_stats(orders: list) -> dict:
    """Orders placed, rupees saved, kg rescued — from the buyer's own orders."""
    total_saved = 0.0
    total_kg = 0.0
    for o in orders:
        market = _as_float(o.get("marketPricePerKg"))
        price = _as_float(o.get("pricePerKg"))
        qty = _as_float(o.get("quantityKg"))
        total_saved += max(0.0, (market - price)) * qty
        total_kg += qty
    return {
        "orders": len(orders),
        "saved": round(total_saved),
        "kg": round(total_kg, 1),
    }


def aggregate_cook_stats(rescues: list, ngo_name: str) -> dict:
    """Rescues handled + meals served for a cook, matched by NGO name across the
    rescue board (delivered rescues carry a logged meal count)."""
    mine = [
        r
        for r in rescues
        if r.get("ngoName") == ngo_name and r.get("status") == "DELIVERED"
    ]
    kg = sum(_as_float(r.get("quantityKg")) for r in mine)
    meals = sum(int(_as_float(r.get("mealsServed", 0))) for r in mine)
    return {
        "rescues": len(mine),
        "meals": meals,
        "kg": round(kg, 1),
    }

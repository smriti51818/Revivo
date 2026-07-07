"""Domain item builders for the single-table design.

Pure functions — no I/O — so they are easy to unit test. Numeric values are
stored as Decimal (DynamoDB does not accept Python floats).
"""
from __future__ import annotations

import time
from decimal import Decimal

from .freshness import FreshnessResult
from .ids import new_id


def _dec(value) -> Decimal:
    return Decimal(str(value))


def build_listing_item(
    data: dict,
    vendor: dict,
    freshness: FreshnessResult,
    now: int | None = None,
) -> dict:
    """Build a LISTING item from validated input + a freshness estimate."""
    now = now if now is not None else int(time.time())
    listing_id = new_id("lst")
    recommended_price = round(data["basePrice"] * freshness.price_factor, 2)

    item = {
        "PK": f"LISTING#{listing_id}",
        "SK": "META",
        "type": "LISTING",
        "listingId": listing_id,
        "vendorId": vendor["id"],
        "vendorName": vendor["name"],
        "vegetable": data["vegetable"],
        "quantityKg": _dec(data["quantityKg"]),
        "storage": data["storage"],
        "purchasedAt": int(data["purchasedAt"]),
        "tempC": _dec(data["tempC"]),
        "band": freshness.band,
        "remainingHours": _dec(freshness.remaining_hours),
        "totalHours": _dec(freshness.total_hours),
        "timeRange": freshness.time_range_label,
        "priceFactor": _dec(freshness.price_factor),
        "basePrice": _dec(data["basePrice"]),
        "recommendedPrice": _dec(recommended_price),
        "imageKey": data.get("imageKey", ""),
        "status": "ACTIVE",
        "createdAt": now,
        "expiryEpoch": freshness.expiry_epoch,
        "ttl": freshness.expiry_epoch,
        # Access patterns
        "GSI1PK": f"VENDOR#{vendor['id']}",
        "GSI1SK": f"LISTING#{now}#{listing_id}",
        "GSI2PK": "STATUS#ACTIVE",
        "GSI2SK": f"{freshness.expiry_epoch}#{listing_id}",
    }

    if data.get("gps"):
        item["gps"] = {
            "lat": _dec(data["gps"]["lat"]),
            "lng": _dec(data["gps"]["lng"]),
        }
    return item


# Internal keys (PK/SK/GSIs/ttl) never leave the API — only the client-facing
# projection below does. Decimal values pass through and are serialised by the
# DecimalEncoder in shared.responses.
def to_public_listing(item: dict) -> dict:
    """Project a stored LISTING item to the shape the app consumes."""
    public = {
        "id": item.get("listingId"),
        "vegetable": item.get("vegetable"),
        "vendorId": item.get("vendorId"),
        "vendorName": item.get("vendorName"),
        "quantityKg": item.get("quantityKg"),
        "band": item.get("band"),
        "timeRange": item.get("timeRange"),
        "basePrice": item.get("basePrice"),
        "recommendedPrice": item.get("recommendedPrice"),
        "priceFactor": item.get("priceFactor"),
        "storage": item.get("storage"),
        "imageKey": item.get("imageKey", ""),
        # Seed data may store a direct image URL; enriched from imageKey
        # otherwise (see shared.uploads.attach_image_url).
        "imageUrl": item.get("imageUrl"),
        "createdAt": item.get("createdAt"),
        "purchasedAt": item.get("purchasedAt"),
        # The live-countdown inputs: absolute expiry + the full shelf window, so
        # the client can recompute band + price decay in real time as it ticks.
        "expiryEpoch": item.get("expiryEpoch"),
        "totalHours": item.get("totalHours"),
        "status": item.get("status"),
    }
    if item.get("gps"):
        public["gps"] = item["gps"]
    return public


def build_order_item(
    data: dict,
    buyer: dict,
    listing: dict,
    now: int | None = None,
) -> dict:
    """Build an ORDER item from validated input + the referenced listing.

    Price fields are snapshotted from the listing so the order is immutable
    even if the listing later changes. `listing` numerics are Decimal.
    """
    now = now if now is not None else int(time.time())
    order_id = new_id("ord")
    qty = _dec(data["quantityKg"])
    price_per_kg = listing.get("recommendedPrice", Decimal("0"))
    market_price = listing.get("basePrice", price_per_kg)
    total = (qty * price_per_kg).quantize(Decimal("0.01"))

    return {
        "PK": f"ORDER#{order_id}",
        "SK": "META",
        "type": "ORDER",
        "orderId": order_id,
        "buyerId": buyer["id"],
        "buyerName": buyer["name"],
        "listingId": listing.get("listingId"),
        "vendorId": listing.get("vendorId"),
        "vendorName": listing.get("vendorName"),
        "vegetable": listing.get("vegetable"),
        "band": listing.get("band"),
        "quantityKg": qty,
        "pricePerKg": price_per_kg,
        "marketPricePerKg": market_price,
        "total": total,
        "status": "CONFIRMED",
        "pickupSlot": data.get("pickupSlot", ""),
        "paymentMethod": data.get("paymentMethod", "PICKUP"),
        "createdAt": now,
        # Access patterns: buyer's orders (GSI1), vendor's incoming (GSI3).
        "GSI1PK": f"BUYER#{buyer['id']}",
        "GSI1SK": f"ORDER#{now}#{order_id}",
        "GSI3PK": f"VENDOR#{listing.get('vendorId')}",
        "GSI3SK": f"ORDER#{now}#{order_id}",
    }


def to_public_order(item: dict) -> dict:
    """Project a stored ORDER item to the shape the app consumes."""
    return {
        "id": item.get("orderId"),
        "buyerName": item.get("buyerName"),
        "vendorName": item.get("vendorName"),
        "vegetable": item.get("vegetable"),
        "listingId": item.get("listingId"),
        "band": item.get("band"),
        "quantityKg": item.get("quantityKg"),
        "pricePerKg": item.get("pricePerKg"),
        "marketPricePerKg": item.get("marketPricePerKg"),
        "total": item.get("total"),
        "status": item.get("status"),
        "pickupSlot": item.get("pickupSlot", ""),
        "paymentMethod": item.get("paymentMethod", "PICKUP"),
        "rating": item.get("rating"),
        "ratingTags": item.get("ratingTags", []),
        "ratingComment": item.get("ratingComment", ""),
        "createdAt": item.get("createdAt"),
    }


# ─── Rescues ─────────────────────────────────────────────────────────
# Surplus routed to an NGO kitchen. One rescue item moves through this
# lifecycle; the map is action -> (required current status, resulting status)
# so transitions are validated with a DynamoDB conditional update.
RESCUE_TRANSITIONS = {
    "ACCEPT": ("OFFERED", "ACCEPTED"),
    "CLAIM": ("ACCEPTED", "ASSIGNED"),
    "PICKUP": ("ASSIGNED", "PICKED_UP"),
    "DELIVER": ("PICKED_UP", "DELIVERED"),
}


def build_rescue_item(data: dict, now: int | None = None) -> dict:
    """Build a RESCUE item (starts OFFERED) from validated input."""
    now = now if now is not None else int(time.time())
    rescue_id = new_id("rsc")
    return {
        "PK": f"RESCUE#{rescue_id}",
        "SK": "META",
        "type": "RESCUE",
        "rescueId": rescue_id,
        "vendorName": data["vendorName"],
        "pickupArea": data["pickupArea"],
        "vegetable": data["vegetable"],
        "quantityKg": _dec(data["quantityKg"]),
        "band": data.get("band", "RESCUE"),
        "timeRange": data.get("timeRange", ""),
        "distanceKm": _dec(data.get("distanceKm", 0)),
        "status": "OFFERED",
        "createdAt": now,
        # One partition lists the whole board, newest-first (GSI2).
        "GSI2PK": "RESCUE#BOARD",
        "GSI2SK": f"{now}#{rescue_id}",
    }


def to_public_rescue(item: dict) -> dict:
    """Project a stored RESCUE item to the shape the app consumes."""
    return {
        "id": item.get("rescueId"),
        "vendorName": item.get("vendorName"),
        "pickupArea": item.get("pickupArea"),
        "vegetable": item.get("vegetable"),
        "quantityKg": item.get("quantityKg"),
        "band": item.get("band"),
        "timeRange": item.get("timeRange"),
        "distanceKm": item.get("distanceKm"),
        "status": item.get("status"),
        "ngoName": item.get("ngoName"),
        "mealsServed": item.get("mealsServed"),
        "mealPhotoKey": item.get("mealPhotoKey", ""),
        "createdAt": item.get("createdAt"),
    }


# ─── Impact aggregation ──────────────────────────────────────────────
# Pure function so it is unit-testable without DynamoDB. Rescues that an NGO
# has committed to (accepted onward) count as rescued; delivered ones count as
# meals served. Order savings feed the recovered-value figure.
_MEALS_PER_KG = 1 / 0.4  # ~0.4 kg of produce per served meal
_CO2_PER_KG = 2.5  # kg CO2e avoided per kg of food kept out of landfill
_MEALS_GOAL = 5000


def _as_float(value) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def aggregate_impact(items: list) -> dict:
    """Aggregate a list of table items into the impact summary + leaderboard."""
    rescues = [i for i in items if i.get("type") == "RESCUE"]
    orders = [i for i in items if i.get("type") == "ORDER"]
    committed = [r for r in rescues if r.get("status") != "OFFERED"]
    delivered = [r for r in rescues if r.get("status") == "DELIVERED"]

    kg_rescued = sum(_as_float(r.get("quantityKg")) for r in committed)
    meals_served = round(
        sum(_as_float(r.get("quantityKg")) for r in delivered) * _MEALS_PER_KG
    )
    money_saved = sum(
        max(
            0.0,
            (_as_float(o.get("marketPricePerKg")) - _as_float(o.get("pricePerKg")))
            * _as_float(o.get("quantityKg")),
        )
        for o in orders
    )

    vendors = {r.get("vendorName") for r in rescues if r.get("vendorName")}
    vendors |= {o.get("vendorName") for o in orders if o.get("vendorName")}
    ngos = {r.get("ngoName") for r in committed if r.get("ngoName")}

    board: dict = {}

    def _add(name, role, kg):
        if not name:
            return
        board.setdefault(name, {"role": role, "kg": 0.0})["kg"] += kg

    for r in committed:
        _add(r.get("vendorName"), "Vendor", _as_float(r.get("quantityKg")))
    for o in orders:
        _add(o.get("vendorName"), "Vendor", _as_float(o.get("quantityKg")))
    for r in delivered:
        _add(r.get("ngoName"), "NGO", _as_float(r.get("quantityKg")))

    leaderboard = [
        {
            "rank": rank,
            "name": name,
            "role": data["role"],
            "kg": round(data["kg"]),
            "meals": round(data["kg"] * _MEALS_PER_KG),
        }
        for rank, (name, data) in enumerate(
            sorted(board.items(), key=lambda kv: kv[1]["kg"], reverse=True)[:5],
            start=1,
        )
    ]

    return {
        "summary": {
            "kgRescued": round(kg_rescued),
            "mealsServed": meals_served,
            "co2SavedKg": round(kg_rescued * _CO2_PER_KG),
            "moneySaved": round(money_saved),
            "activeVendors": len(vendors),
            "activeNgos": len(ngos),
            "mealsGoal": _MEALS_GOAL,
        },
        "leaderboard": leaderboard,
    }

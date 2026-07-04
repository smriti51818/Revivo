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
        "createdAt": item.get("createdAt"),
        "expiryEpoch": item.get("expiryEpoch"),
        "status": item.get("status"),
    }
    if item.get("gps"):
        public["gps"] = item["gps"]
    return public

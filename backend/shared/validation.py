"""Input validation + sanitization for listing creation.

All user input is validated before any DynamoDB write — quantity/price/date
ranges and string caps prevent injection and garbage data.
"""
from __future__ import annotations

import time

from .market_prices import market_price

VALID_STORAGE = {"ROOM", "REFRIGERATED", "COLD_STORAGE"}
_MAX_AGE_DAYS = 30
_FUTURE_SKEW_SECONDS = 3600


class ValidationError(ValueError):
    """Raised when listing input fails validation."""


def _num(value, name: str, lo: float, hi: float) -> float:
    try:
        v = float(value)
    except (TypeError, ValueError):
        raise ValidationError(f"{name} must be a number")
    if v < lo or v > hi:
        raise ValidationError(f"{name} must be between {lo} and {hi}")
    return v


def validate_listing_input(body: dict, now: int | None = None) -> dict:
    now = now if now is not None else int(time.time())

    vegetable = str(body.get("vegetable", "")).strip()
    if not vegetable or len(vegetable) > 50:
        raise ValidationError("vegetable is required and must be <= 50 chars")

    quantity_kg = _num(body.get("quantityKg"), "quantityKg", 0.1, 1000)

    # Price is derived from the vegetable's market rate; the seller never types
    # it. An explicit basePrice (e.g. from tests) is still honoured if provided.
    raw_price = body.get("basePrice")
    if raw_price in (None, ""):
        base_price = market_price(vegetable)
    else:
        base_price = _num(raw_price, "basePrice", 1, 100000)

    storage = str(body.get("storage", "ROOM")).upper()
    if storage not in VALID_STORAGE:
        raise ValidationError(f"storage must be one of {sorted(VALID_STORAGE)}")

    try:
        purchased_at = int(body.get("purchasedAt"))
    except (TypeError, ValueError):
        raise ValidationError("purchasedAt (epoch seconds) is required")
    if purchased_at > now + _FUTURE_SKEW_SECONDS:
        raise ValidationError("purchasedAt cannot be in the future")
    if purchased_at < now - _MAX_AGE_DAYS * 86400:
        raise ValidationError("purchasedAt is too old to list")

    temp_c = _num(body.get("tempC", 28.0), "tempC", -10, 60)

    gps = body.get("gps")
    if gps is not None:
        gps = {
            "lat": _num(gps.get("lat"), "gps.lat", -90, 90),
            "lng": _num(gps.get("lng"), "gps.lng", -180, 180),
        }

    image_key = str(body.get("imageKey", "")).strip()[:200]

    return {
        "vegetable": vegetable,
        "quantityKg": quantity_kg,
        "basePrice": base_price,
        "storage": storage,
        "purchasedAt": purchased_at,
        "tempC": temp_c,
        "gps": gps,
        "imageKey": image_key,
    }


_PAYMENT_METHODS = {"UPI", "CARD", "WALLET", "PICKUP"}


def validate_order_input(body: dict) -> dict:
    """Validate a buyer's order: a listing id, quantity + optional fulfilment."""
    listing_id = str(body.get("listingId", "")).strip()
    if not listing_id or len(listing_id) > 60:
        raise ValidationError("listingId is required")

    quantity_kg = _num(body.get("quantityKg"), "quantityKg", 0.1, 1000)

    payment = str(body.get("paymentMethod", "PICKUP")).strip().upper()
    if payment not in _PAYMENT_METHODS:
        payment = "PICKUP"

    return {
        "listingId": listing_id,
        "quantityKg": quantity_kg,
        "pickupSlot": str(body.get("pickupSlot", "")).strip()[:40],
        "paymentMethod": payment,
    }


def validate_rating_input(body: dict) -> dict:
    """Validate a buyer's post-order rating: 1–5 stars + optional tags/comment."""
    try:
        stars = int(body.get("stars"))
    except (TypeError, ValueError):
        raise ValidationError("stars must be a number 1-5")
    if not 1 <= stars <= 5:
        raise ValidationError("stars must be 1-5")

    raw_tags = body.get("tags")
    tags = []
    if isinstance(raw_tags, list):
        tags = [str(t).strip()[:24] for t in raw_tags[:6] if str(t).strip()]

    return {
        "stars": stars,
        "tags": tags,
        "comment": str(body.get("comment", "")).strip()[:280],
    }


VALID_RESCUE_ACTIONS = {"ACCEPT", "CLAIM", "PICKUP", "DELIVER"}


def validate_rescue_input(body: dict) -> dict:
    """Validate a new rescue offer."""
    vendor = str(body.get("vendorName", "")).strip()
    if not vendor or len(vendor) > 60:
        raise ValidationError("vendorName is required")

    vegetable = str(body.get("vegetable", "")).strip()
    if not vegetable or len(vegetable) > 50:
        raise ValidationError("vegetable is required")

    quantity_kg = _num(body.get("quantityKg"), "quantityKg", 0.1, 1000)
    distance_km = _num(body.get("distanceKm", 0), "distanceKm", 0, 100)

    return {
        "vendorName": vendor,
        "pickupArea": str(body.get("pickupArea", "")).strip()[:60],
        "vegetable": vegetable,
        "quantityKg": quantity_kg,
        "band": str(body.get("band", "RESCUE")).upper()[:20],
        "timeRange": str(body.get("timeRange", "")).strip()[:40],
        "distanceKm": distance_km,
    }


def validate_rescue_action(body: dict) -> dict:
    """Validate a rescue lifecycle action (ACCEPT/CLAIM/PICKUP/DELIVER)."""
    action = str(body.get("action", "")).upper()
    if action not in VALID_RESCUE_ACTIONS:
        raise ValidationError(
            f"action must be one of {sorted(VALID_RESCUE_ACTIONS)}"
        )
    ngo_name = str(body.get("ngoName", "")).strip()[:60]
    if action == "ACCEPT" and not ngo_name:
        raise ValidationError("ngoName is required to accept a rescue")
    return {"action": action, "ngoName": ngo_name}

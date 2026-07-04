"""Input validation + sanitization for listing creation.

All user input is validated before any DynamoDB write — quantity/price/date
ranges and string caps prevent injection and garbage data.
"""
from __future__ import annotations

import time

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
    base_price = _num(body.get("basePrice"), "basePrice", 1, 100000)

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


def validate_order_input(body: dict) -> dict:
    """Validate a buyer's order request: a listing id + a quantity."""
    listing_id = str(body.get("listingId", "")).strip()
    if not listing_id or len(listing_id) > 60:
        raise ValidationError("listingId is required")

    quantity_kg = _num(body.get("quantityKg"), "quantityKg", 0.1, 1000)

    return {"listingId": listing_id, "quantityKg": quantity_kg}

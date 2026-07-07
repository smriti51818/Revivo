"""Time-aware freshness engine — the core of Revivo's "live countdown".

Given what a vegetable is, when it was bought, how it's stored, and the local
temperature, it estimates remaining usable life and maps it to a band:

    GOOD      -> full commercial value
    USE_SOON  -> discounted, approaching end of optimal window
    RESCUE    -> near end of usable life, route to rescue

Output is a band + an honest time *range*, plus a price factor and the epoch
used for the DynamoDB TTL (the countdown itself).
"""
from __future__ import annotations

import time
from dataclasses import dataclass, asdict
from decimal import Decimal

from . import shelf_life

# Band thresholds on remaining/total ratio.
_GOOD_MIN = 0.50
_USE_SOON_MIN = 0.20

# Price multiplier per band.
_PRICE_FACTOR = {"GOOD": 1.0, "USE_SOON": 0.7, "RESCUE": 0.4}


@dataclass
class FreshnessResult:
    band: str
    remaining_hours: float
    total_hours: float
    ratio: float
    low_hours: float
    high_hours: float
    time_range_label: str
    price_factor: float
    expiry_epoch: int

    def to_dict(self) -> dict:
        return asdict(self)


def _band_for(ratio: float) -> str:
    if ratio >= _GOOD_MIN:
        return "GOOD"
    if ratio >= _USE_SOON_MIN:
        return "USE_SOON"
    return "RESCUE"


def _format_range(low_hours: float, high_hours: float) -> str:
    """Human range, in hours or days, acknowledging uncertainty."""
    if high_hours <= 0:
        return "expired"
    if high_hours < 48:
        lo, hi = max(0, round(low_hours)), round(high_hours)
        return f"~{lo}-{hi} hours" if lo != hi else f"~{hi} hours"
    lo_d, hi_d = round(low_hours / 24), round(high_hours / 24)
    return f"~{lo_d}-{hi_d} days" if lo_d != hi_d else f"~{hi_d} days"


def estimate_freshness(
    vegetable: str,
    purchased_at_epoch: int,
    storage: str = "ROOM",
    temp_c: float = 28.0,
    now_epoch: int | None = None,
) -> FreshnessResult:
    now = now_epoch if now_epoch is not None else int(time.time())

    total_hours = (
        shelf_life.base_hours(vegetable)
        * shelf_life.storage_multiplier(storage)
        * shelf_life.temperature_factor(temp_c)
    )
    total_hours = max(1.0, total_hours)

    elapsed_hours = max(0.0, (now - purchased_at_epoch) / 3600.0)
    remaining_hours = total_hours - elapsed_hours
    ratio = remaining_hours / total_hours

    band = _band_for(ratio)

    # ±15% band around the point estimate — the honest range.
    low = max(0.0, remaining_hours * 0.85)
    high = max(0.0, remaining_hours * 1.15)

    expiry_epoch = int(purchased_at_epoch + total_hours * 3600)

    return FreshnessResult(
        band=band,
        remaining_hours=round(remaining_hours, 1),
        total_hours=round(total_hours, 1),
        ratio=round(ratio, 3),
        low_hours=round(low, 1),
        high_hours=round(high, 1),
        time_range_label=_format_range(low, high),
        price_factor=_PRICE_FACTOR[band],
        expiry_epoch=expiry_epoch,
    )


def apply_live_freshness(listing: dict, now: int | None = None) -> dict:
    """Return a copy of a stored LISTING with band + price recomputed for *now*.

    Freshness (and therefore the recommended price) decays continuously as the
    clock ticks. The stored `band`/`recommendedPrice` are only the snapshot from
    listing time; this recomputes them from the immutable inputs (vegetable,
    purchase time, storage, temperature) so the price a buyer is charged matches
    the live countdown they see. Returns the listing unchanged if it lacks the
    inputs (e.g. legacy/seed rows without a purchase time).
    """
    veg = listing.get("vegetable")
    purchased = listing.get("purchasedAt")
    base = listing.get("basePrice")
    if not veg or not purchased or base is None:
        return listing

    fr = estimate_freshness(
        str(veg),
        int(purchased),
        str(listing.get("storage", "ROOM")),
        float(listing.get("tempC", 28) or 28),
        now_epoch=now,
    )
    recommended = Decimal(str(round(float(base) * fr.price_factor, 2)))
    return {
        **listing,
        "band": fr.band,
        "timeRange": fr.time_range_label,
        "remainingHours": Decimal(str(fr.remaining_hours)),
        "totalHours": Decimal(str(fr.total_hours)),
        "priceFactor": Decimal(str(fr.price_factor)),
        "recommendedPrice": recommended,
        "expiryEpoch": fr.expiry_epoch,
    }

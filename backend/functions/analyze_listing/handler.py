"""POST /listings/analyze — server-side freshness analysis (no persist).

Runs the same freshness engine used at publish time and returns the band, an
honest time window, and a fair suggested price. This lets the seller see the
real Revivo assessment before listing — computed on AWS, not on the device.
"""
import json

from shared.freshness import estimate_freshness
from shared.responses import error, ok
from shared.validation import ValidationError, validate_listing_input


def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return error(400, "invalid JSON body")

    try:
        data = validate_listing_input(body)
    except ValidationError as exc:
        return error(400, str(exc))

    fr = estimate_freshness(
        vegetable=data["vegetable"],
        purchased_at_epoch=data["purchasedAt"],
        storage=data["storage"],
        temp_c=data["tempC"],
    )
    # data["basePrice"] is the vegetable's market rate (derived in validation).
    market = data["basePrice"]
    recommended = round(market * fr.price_factor, 2)

    return ok(
        200,
        {
            "band": fr.band,
            "timeRange": fr.time_range_label,
            "marketPrice": market,
            "recommendedPrice": recommended,
            "remainingHours": fr.remaining_hours,
            "totalHours": fr.total_hours,
            "priceFactor": fr.price_factor,
        },
    )

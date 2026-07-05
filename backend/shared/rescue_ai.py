"""Bedrock (Claude) prompt building for rescue explanations — pure + testable.

The handler does the I/O (Bedrock invoke); these helpers build the request body
and a deterministic fallback so the feature degrades gracefully when Bedrock
model access isn't enabled in the account.
"""
from __future__ import annotations

_MEALS_PER_KG = 1 / 0.4  # ~0.4 kg of produce per served meal


def _as_float(value) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def _meals(rescue: dict) -> int:
    return round(_as_float(rescue.get("quantityKg")) * _MEALS_PER_KG)


_SYSTEM = (
    "You are Revivo's food-rescue assistant. In two short, warm sentences, "
    "explain why an NGO kitchen should rescue this surplus produce now. Be "
    "concrete about the freshness urgency and how many meals it can yield. "
    "No emojis, no preamble — return only the explanation."
)


def build_explain_body(rescue: dict, max_tokens: int = 160) -> dict:
    """Build the Bedrock InvokeModel body (Anthropic messages schema)."""
    veg = rescue.get("vegetable", "produce")
    qty = _as_float(rescue.get("quantityKg"))
    band = rescue.get("band", "RESCUE")
    time_range = rescue.get("timeRange", "")
    area = rescue.get("pickupArea", "")
    vendor = rescue.get("vendorName", "a vendor")

    facts = (
        f"Produce: {veg}\n"
        f"Quantity: {qty:g} kg (about {_meals(rescue)} meals)\n"
        f"Freshness band: {band}\n"
        f"Good for: {time_range or 'a short window'}\n"
        f"From: {vendor}\n"
        f"Pickup area: {area or 'nearby'}"
    )

    return {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": max_tokens,
        "system": _SYSTEM,
        "messages": [
            {
                "role": "user",
                "content": f"Explain why to rescue this:\n{facts}",
            }
        ],
    }


_URGENCY = {
    "RESCUE": "It's in its final freshness window, so rescuing it today keeps "
    "good food out of landfill.",
    "USE_SOON": "It's still good but should be used soon — ideal for a kitchen "
    "cooking today.",
    "GOOD": "It's fresh and ready to become nourishing meals.",
}


def fallback_explanation(rescue: dict) -> str:
    """Deterministic explanation when Bedrock is unavailable."""
    veg = rescue.get("vegetable", "produce")
    qty = _as_float(rescue.get("quantityKg"))
    band = str(rescue.get("band", "RESCUE")).upper()
    window = rescue.get("timeRange", "")
    urgency = _URGENCY.get(band, "Rescuing it now keeps good food out of landfill.")
    window_txt = f" It stays good for about {window}." if window else ""
    return (
        f"{qty:g} kg of {veg} can become roughly {_meals(rescue)} meals. "
        f"{urgency}{window_txt}"
    )

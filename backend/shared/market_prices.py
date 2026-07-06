"""Reference market price (INR/kg) per vegetable for the pilot market.

The seller never types a price. Revivo prices surplus automatically as
market_price x freshness factor, so fresh produce lists at market rate and
near-expiry produce is fairly (and transparently) discounted.
"""
from __future__ import annotations

MARKET_PRICE_PER_KG: dict[str, float] = {
    "tomato": 40,
    "potato": 30,
    "onion": 35,
    "spinach": 30,
    "coriander": 40,
    "carrot": 45,
    "bell_pepper": 80,
    "cabbage": 25,
    "cauliflower": 40,
    "brinjal": 35,
    "okra": 50,
    "green_chilli": 60,
    "cucumber": 30,
    "beans": 60,
    "beetroot": 40,
    "radish": 30,
    "pumpkin": 25,
    "drumstick": 70,
    "curry_leaves": 40,
    "mint": 30,
}

DEFAULT_MARKET_PRICE = 40.0


def _key(vegetable: str) -> str:
    return vegetable.strip().lower().replace(" ", "_").replace("-", "_")


def market_price(vegetable: str) -> float:
    """Fair market price per kg for a vegetable, tolerant of label variants."""
    return float(MARKET_PRICE_PER_KG.get(_key(vegetable), DEFAULT_MARKET_PRICE))

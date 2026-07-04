"""Validated shelf-life reference data.

Base usable life (hours from purchase) at ambient room temperature for the
pilot market's common vegetables, plus storage and temperature adjustment
factors. Loaded once into warm Lambda memory — small, pure data, no I/O.

These are estimates. Revivo deliberately presents freshness as *bands with
time ranges*, never a false-precision percentage.
"""

# Base shelf life in hours at ~room temperature (Coimbatore ambient).
BASE_SHELF_LIFE_HOURS: dict[str, float] = {
    "tomato": 96,
    "potato": 480,
    "onion": 720,
    "spinach": 36,
    "coriander": 36,
    "carrot": 240,
    "bell_pepper": 168,
    "cabbage": 336,
    "cauliflower": 120,
    "brinjal": 120,
    "okra": 72,
    "green_chilli": 168,
    "cucumber": 120,
    "beans": 96,
    "beetroot": 336,
    "radish": 168,
    "pumpkin": 720,
    "drumstick": 96,
    "curry_leaves": 60,
    "mint": 36,
}

# Storage condition multipliers.
STORAGE_MULTIPLIER: dict[str, float] = {
    "ROOM": 1.0,
    "REFRIGERATED": 2.5,
    "COLD_STORAGE": 3.5,
}

DEFAULT_SHELF_LIFE_HOURS = 96.0
REFERENCE_TEMP_C = 25.0


def base_hours(vegetable: str) -> float:
    """Base shelf life for a vegetable, tolerant of label variations."""
    key = vegetable.strip().lower().replace(" ", "_").replace("-", "_")
    return BASE_SHELF_LIFE_HOURS.get(key, DEFAULT_SHELF_LIFE_HOURS)


def storage_multiplier(storage: str) -> float:
    return STORAGE_MULTIPLIER.get((storage or "ROOM").upper(), 1.0)


def temperature_factor(temp_c: float) -> float:
    """Warmer than reference shortens life; cooler mildly extends it.

    Clamped to a sane range so a bad reading can't produce absurd estimates.
    """
    factor = 1.0 - (temp_c - REFERENCE_TEMP_C) * 0.03
    return max(0.4, min(1.4, factor))

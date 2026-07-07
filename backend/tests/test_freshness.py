"""Unit tests for the time-aware freshness engine."""
from decimal import Decimal

from shared.freshness import apply_live_freshness, estimate_freshness
from shared import shelf_life

NOW = 1_700_000_000
HOUR = 3600


def _at(hours_ago: float, **kwargs):
    return estimate_freshness(
        kwargs.pop("vegetable", "tomato"),
        purchased_at_epoch=int(NOW - hours_ago * HOUR),
        now_epoch=NOW,
        **kwargs,
    )


def test_fresh_produce_is_good_at_full_price():
    r = _at(1, storage="ROOM", temp_c=28)
    assert r.band == "GOOD"
    assert r.price_factor == 1.0
    assert r.remaining_hours > 0
    assert r.ratio > 0.5


def test_midlife_produce_is_use_soon_and_discounted():
    r = _at(60, storage="ROOM", temp_c=28)  # ~0.3 ratio for tomato
    assert r.band == "USE_SOON"
    assert r.price_factor == 0.7
    assert 0.20 <= r.ratio < 0.50


def test_near_end_of_life_is_rescue():
    r = _at(80, storage="ROOM", temp_c=28)
    assert r.band == "RESCUE"
    assert r.price_factor == 0.4
    assert r.ratio < 0.20


def test_expired_produce_reports_rescue_and_expired_label():
    r = _at(200, storage="ROOM", temp_c=28)
    assert r.band == "RESCUE"
    assert r.remaining_hours < 0
    assert r.time_range_label == "expired"


def test_refrigeration_extends_shelf_life():
    room = _at(60, storage="ROOM", temp_c=28)
    fridge = _at(60, storage="REFRIGERATED", temp_c=28)
    assert fridge.total_hours > room.total_hours
    assert fridge.ratio > room.ratio
    # Same elapsed time, refrigeration keeps it in a better band.
    assert fridge.band == "GOOD"
    assert room.band == "USE_SOON"


def test_higher_temperature_shortens_shelf_life():
    hot = _at(1, storage="ROOM", temp_c=35)
    cool = _at(1, storage="ROOM", temp_c=18)
    assert hot.total_hours < cool.total_hours


def test_unknown_vegetable_falls_back_to_default():
    r = _at(1, vegetable="unobtainium", storage="ROOM", temp_c=25)
    expected_total = shelf_life.DEFAULT_SHELF_LIFE_HOURS  # temp factor = 1 at 25C
    assert abs(r.total_hours - expected_total) < 0.5
    assert r.band == "GOOD"


def test_expiry_epoch_matches_total_life():
    r = _at(0, storage="ROOM", temp_c=25)
    expected = NOW + r.total_hours * HOUR
    assert abs(r.expiry_epoch - expected) < HOUR


def test_time_range_label_uses_days_for_long_life():
    r = _at(1, vegetable="potato", storage="REFRIGERATED", temp_c=20)
    assert "days" in r.time_range_label


def test_result_is_json_serialisable():
    import json

    r = _at(10)
    assert json.dumps(r.to_dict())  # does not raise


# ─── live re-pricing ────────────────────────────────────────────────
def _listing(hours_ago, base=40):
    return {
        "vegetable": "tomato",
        "purchasedAt": int(NOW - hours_ago * HOUR),
        "storage": "ROOM",
        "tempC": Decimal("28"),
        "basePrice": Decimal(str(base)),
        "band": "GOOD",
        "recommendedPrice": Decimal(str(base)),
    }


def test_apply_live_freshness_decays_band_and_price_over_time():
    fresh = apply_live_freshness(_listing(1), now=NOW)
    decayed = apply_live_freshness(_listing(60), now=NOW)  # ~use-soon for tomato
    assert fresh["band"] == "GOOD"
    assert fresh["recommendedPrice"] == Decimal("40")
    assert decayed["band"] == "USE_SOON"
    assert decayed["recommendedPrice"] < fresh["recommendedPrice"]
    assert isinstance(decayed["recommendedPrice"], Decimal)


def test_apply_live_freshness_passes_through_without_inputs():
    row = {"band": "GOOD", "recommendedPrice": Decimal("40")}  # no purchasedAt
    assert apply_live_freshness(row, now=NOW) is row

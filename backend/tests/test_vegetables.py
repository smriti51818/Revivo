"""Unit tests for market pricing + Rekognition label matching."""
from shared.market_prices import DEFAULT_MARKET_PRICE, market_price
from shared.vegetables import VEGETABLES, match_vegetable


def test_market_price_known_and_variants():
    assert market_price("Tomato") == 40
    assert market_price("bell pepper") == 80  # label variant -> bell_pepper
    assert market_price("Green Chilli") == 60


def test_market_price_unknown_falls_back():
    assert market_price("Dragonfruit") == DEFAULT_MARKET_PRICE


def test_match_takes_highest_confidence_produce_label():
    labels = [
        {"Name": "Food", "Confidence": 99.0},
        {"Name": "Produce", "Confidence": 98.0},
        {"Name": "Tomato", "Confidence": 94.0},
    ]
    assert match_vegetable(labels) == "Tomato"


def test_match_maps_synonyms_to_revivo_names():
    assert match_vegetable([{"Name": "Eggplant", "Confidence": 90}]) == "Brinjal"
    assert match_vegetable([{"Name": "Chili", "Confidence": 90}]) == "Green Chilli"


def test_match_returns_none_when_nothing_matches():
    assert match_vegetable([{"Name": "Bicycle", "Confidence": 99}]) is None
    assert match_vegetable([]) is None


def test_every_matched_name_is_a_known_vegetable():
    for name in ["Tomato", "Brinjal", "Green Chilli", "Beans"]:
        assert name in VEGETABLES

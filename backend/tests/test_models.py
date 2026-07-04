"""Unit tests for listing item building + input validation."""
from decimal import Decimal

import pytest

from shared.freshness import estimate_freshness
from shared.models import build_listing_item, to_public_listing
from shared.validation import ValidationError, validate_listing_input

NOW = 1_700_000_000


def _valid_body(**overrides):
    body = {
        "vegetable": "Tomato",
        "quantityKg": 15,
        "basePrice": 30,
        "storage": "ROOM",
        "purchasedAt": NOW - 3600,
        "tempC": 28,
    }
    body.update(overrides)
    return body


# ─── validation ─────────────────────────────────────────────────────
def test_valid_input_is_normalised():
    data = validate_listing_input(_valid_body(), now=NOW)
    assert data["vegetable"] == "Tomato"
    assert data["storage"] == "ROOM"
    assert data["quantityKg"] == 15.0


def test_missing_vegetable_rejected():
    with pytest.raises(ValidationError):
        validate_listing_input(_valid_body(vegetable="  "), now=NOW)


def test_quantity_out_of_range_rejected():
    with pytest.raises(ValidationError):
        validate_listing_input(_valid_body(quantityKg=5000), now=NOW)


def test_future_purchase_date_rejected():
    with pytest.raises(ValidationError):
        validate_listing_input(_valid_body(purchasedAt=NOW + 100000), now=NOW)


def test_invalid_storage_rejected():
    with pytest.raises(ValidationError):
        validate_listing_input(_valid_body(storage="FREEZER"), now=NOW)


def test_gps_is_validated_when_present():
    data = validate_listing_input(
        _valid_body(gps={"lat": 11.0, "lng": 76.9}), now=NOW
    )
    assert data["gps"]["lat"] == 11.0


# ─── item building ──────────────────────────────────────────────────
def test_build_listing_item_shapes_single_table_keys():
    data = validate_listing_input(_valid_body(), now=NOW)
    fr = estimate_freshness("Tomato", data["purchasedAt"], "ROOM", 28, NOW)
    item = build_listing_item(
        data, {"id": "v1", "name": "Rajesh"}, fr, now=NOW
    )

    assert item["PK"].startswith("LISTING#")
    assert item["SK"] == "META"
    assert item["type"] == "LISTING"
    assert item["GSI1PK"] == "VENDOR#v1"
    assert item["GSI2PK"] == "STATUS#ACTIVE"
    assert item["status"] == "ACTIVE"
    assert item["band"] == fr.band
    assert item["ttl"] == fr.expiry_epoch


def test_recommended_price_applies_band_factor():
    data = validate_listing_input(_valid_body(basePrice=30), now=NOW)
    fr = estimate_freshness("Tomato", data["purchasedAt"], "ROOM", 28, NOW)
    item = build_listing_item(data, {"id": "v1", "name": "R"}, fr, now=NOW)
    expected = Decimal(str(round(30 * fr.price_factor, 2)))
    assert item["recommendedPrice"] == expected


def test_numeric_fields_are_decimal_for_dynamodb():
    data = validate_listing_input(_valid_body(), now=NOW)
    fr = estimate_freshness("Tomato", data["purchasedAt"], "ROOM", 28, NOW)
    item = build_listing_item(data, {"id": "v1", "name": "R"}, fr, now=NOW)
    assert isinstance(item["quantityKg"], Decimal)
    assert isinstance(item["basePrice"], Decimal)
    assert isinstance(item["recommendedPrice"], Decimal)


# ─── public projection ──────────────────────────────────────────────
def test_public_listing_projects_client_fields_only():
    data = validate_listing_input(_valid_body(), now=NOW)
    fr = estimate_freshness("Tomato", data["purchasedAt"], "ROOM", 28, NOW)
    item = build_listing_item(data, {"id": "v1", "name": "Rajesh"}, fr, now=NOW)

    public = to_public_listing(item)

    assert public["id"] == item["listingId"]
    assert public["vendorName"] == "Rajesh"
    assert public["band"] == fr.band
    assert public["recommendedPrice"] == item["recommendedPrice"]
    # Internal single-table keys must never be exposed.
    for hidden in ("PK", "SK", "GSI1PK", "GSI2PK", "GSI2SK", "ttl"):
        assert hidden not in public


def test_public_listing_includes_gps_when_present():
    data = validate_listing_input(
        _valid_body(gps={"lat": 11.0, "lng": 76.9}), now=NOW
    )
    fr = estimate_freshness("Tomato", data["purchasedAt"], "ROOM", 28, NOW)
    item = build_listing_item(data, {"id": "v1", "name": "R"}, fr, now=NOW)
    assert to_public_listing(item)["gps"]["lat"] == Decimal("11.0")

"""Unit tests for listing item building + input validation."""
from decimal import Decimal

import pytest

from shared.freshness import estimate_freshness
from shared.models import (
    RESCUE_TRANSITIONS,
    aggregate_impact,
    build_listing_item,
    build_order_item,
    build_rescue_item,
    to_public_listing,
    to_public_order,
    to_public_rescue,
)
from shared.validation import (
    ValidationError,
    validate_listing_input,
    validate_order_input,
    validate_rating_input,
    validate_rescue_action,
    validate_rescue_input,
)

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


# ─── orders ─────────────────────────────────────────────────────────
def _listing_item():
    data = validate_listing_input(_valid_body(basePrice=40), now=NOW)
    fr = estimate_freshness("Tomato", data["purchasedAt"], "ROOM", 28, NOW)
    return build_listing_item(data, {"id": "v1", "name": "GreenLeaf"}, fr, now=NOW)


def test_validate_order_requires_listing_and_quantity():
    with pytest.raises(ValidationError):
        validate_order_input({"quantityKg": 5})
    with pytest.raises(ValidationError):
        validate_order_input({"listingId": "lst_1", "quantityKg": 0})


def test_validate_order_captures_pickup_slot_and_payment():
    data = validate_order_input({
        "listingId": "lst_1",
        "quantityKg": 3,
        "pickupSlot": "7:00 PM–7:30 PM",
        "paymentMethod": "upi",
    })
    assert data["pickupSlot"] == "7:00 PM–7:30 PM"
    assert data["paymentMethod"] == "UPI"
    # Unknown methods fall back to pay-on-pickup.
    assert validate_order_input(
        {"listingId": "l", "quantityKg": 1, "paymentMethod": "bitcoin"}
    )["paymentMethod"] == "PICKUP"


def test_validate_rating_bounds_and_normalises():
    data = validate_rating_input(
        {"stars": 5, "tags": ["Fresh", "On time", ""], "comment": "  great  "}
    )
    assert data["stars"] == 5
    assert data["tags"] == ["Fresh", "On time"]
    assert data["comment"] == "great"
    for bad in ({}, {"stars": 0}, {"stars": 6}, {"stars": "x"}):
        with pytest.raises(ValidationError):
            validate_rating_input(bad)


def test_build_order_snapshots_listing_price_and_keys():
    listing = _listing_item()
    order = validate_order_input(
        {"listingId": listing["listingId"], "quantityKg": 4}
    )
    item = build_order_item(order, {"id": "b1", "name": "Hotel"}, listing, now=NOW)

    assert item["PK"].startswith("ORDER#")
    assert item["SK"] == "META"
    assert item["type"] == "ORDER"
    assert item["GSI1PK"] == "BUYER#b1"
    assert item["GSI3PK"] == f"VENDOR#{listing['vendorId']}"
    assert item["pricePerKg"] == listing["recommendedPrice"]
    assert item["marketPricePerKg"] == listing["basePrice"]
    # total = qty * recommended price, quantized to paise.
    assert item["total"] == (Decimal("4") * listing["recommendedPrice"]).quantize(
        Decimal("0.01")
    )
    assert item["status"] == "CONFIRMED"


def test_public_order_hides_internal_keys():
    listing = _listing_item()
    order = validate_order_input(
        {"listingId": listing["listingId"], "quantityKg": 4}
    )
    item = build_order_item(order, {"id": "b1", "name": "Hotel"}, listing, now=NOW)
    public = to_public_order(item)
    assert public["id"] == item["orderId"]
    assert public["vendorName"] == "GreenLeaf"
    for hidden in ("PK", "SK", "GSI1PK", "GSI3PK"):
        assert hidden not in public


# ─── rescues ────────────────────────────────────────────────────────
def _rescue_body(**overrides):
    body = {
        "vendorName": "Kovai Fresh Mart",
        "pickupArea": "RS Puram",
        "vegetable": "Baby Spinach",
        "quantityKg": 4,
        "band": "RESCUE",
        "timeRange": "~2-3 h",
        "distanceKm": 0.8,
    }
    body.update(overrides)
    return body


def test_build_rescue_starts_offered_on_board():
    item = build_rescue_item(validate_rescue_input(_rescue_body()), now=NOW)
    assert item["PK"].startswith("RESCUE#")
    assert item["type"] == "RESCUE"
    assert item["status"] == "OFFERED"
    assert item["GSI2PK"] == "RESCUE#BOARD"
    assert item["quantityKg"] == Decimal("4")


def test_public_rescue_hides_internal_keys():
    item = build_rescue_item(validate_rescue_input(_rescue_body()), now=NOW)
    public = to_public_rescue(item)
    assert public["id"] == item["rescueId"]
    assert public["vendorName"] == "Kovai Fresh Mart"
    for hidden in ("PK", "SK", "GSI2PK", "GSI2SK"):
        assert hidden not in public


def test_rescue_missing_vendor_rejected():
    with pytest.raises(ValidationError):
        validate_rescue_input(_rescue_body(vendorName="  "))


def test_rescue_action_accept_requires_ngo():
    with pytest.raises(ValidationError):
        validate_rescue_action({"action": "ACCEPT"})
    ok = validate_rescue_action({"action": "ACCEPT", "ngoName": "Seva"})
    assert ok == {"action": "ACCEPT", "ngoName": "Seva"}


def test_rescue_action_rejects_unknown():
    with pytest.raises(ValidationError):
        validate_rescue_action({"action": "TELEPORT"})


def test_rescue_transitions_form_a_chain():
    # Each action's result is the next action's required current status.
    assert RESCUE_TRANSITIONS["ACCEPT"] == ("OFFERED", "ACCEPTED")
    assert RESCUE_TRANSITIONS["CLAIM"][0] == RESCUE_TRANSITIONS["ACCEPT"][1]
    assert RESCUE_TRANSITIONS["PICKUP"][0] == RESCUE_TRANSITIONS["CLAIM"][1]
    assert RESCUE_TRANSITIONS["DELIVER"][0] == RESCUE_TRANSITIONS["PICKUP"][1]


# ─── impact aggregation ─────────────────────────────────────────────
def test_aggregate_impact_counts_rescues_orders_and_leaderboard():
    items = [
        # Delivered rescue → counts as rescued + meals; NGO on leaderboard.
        {
            "type": "RESCUE",
            "status": "DELIVERED",
            "quantityKg": Decimal("8"),
            "vendorName": "GreenLeaf Farms",
            "ngoName": "Annapoorna Trust",
        },
        # Accepted (committed but not delivered) → rescued, no meals yet.
        {
            "type": "RESCUE",
            "status": "ACCEPTED",
            "quantityKg": Decimal("2"),
            "vendorName": "GreenLeaf Farms",
            "ngoName": "Seva Kitchen",
        },
        # Offered → not yet committed, excluded from totals.
        {"type": "RESCUE", "status": "OFFERED", "quantityKg": Decimal("5"),
         "vendorName": "Daily Greens"},
        # Order → savings feed recovered value.
        {
            "type": "ORDER",
            "status": "CONFIRMED",
            "quantityKg": Decimal("10"),
            "vendorName": "GreenLeaf Farms",
            "marketPricePerKg": Decimal("40"),
            "pricePerKg": Decimal("34"),
        },
    ]

    result = aggregate_impact(items)
    summary = result["summary"]

    assert summary["kgRescued"] == 10  # 8 delivered + 2 accepted
    assert summary["mealsServed"] == 20  # 8 kg / 0.4
    assert summary["co2SavedKg"] == 25  # 10 * 2.5
    assert summary["moneySaved"] == 60  # (40-34) * 10
    assert summary["activeNgos"] == 2
    assert summary["activeVendors"] == 2  # GreenLeaf + Daily Greens

    # GreenLeaf supplied the most (8 + 2 rescued + 10 sold = 20 kg) → rank 1.
    assert result["leaderboard"][0]["name"] == "GreenLeaf Farms"
    assert result["leaderboard"][0]["rank"] == 1


def test_aggregate_impact_handles_empty_table():
    result = aggregate_impact([])
    assert result["summary"]["kgRescued"] == 0
    assert result["leaderboard"] == []

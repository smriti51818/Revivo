"""Tests for the persisted profile aggregates (wallet / vendor / buyer / cook)."""
from decimal import Decimal

from shared.profile import (
    aggregate_buyer_stats,
    aggregate_cook_stats,
    credits_for_saved,
    to_public_vendor_stats,
)


def test_credits_for_saved_is_one_per_ten_rupees():
    assert credits_for_saved(0) == 0
    assert credits_for_saved(9.99) == 0
    assert credits_for_saved(10) == 1
    assert credits_for_saved(45) == 4
    assert credits_for_saved(-5) == 0


def test_vendor_stats_derives_avg_and_trusted_on_read():
    fresh = to_public_vendor_stats(None)
    assert fresh["orders"] == 0
    assert fresh["avgRating"] == Decimal("0")
    assert fresh["trusted"] is False

    trusted = to_public_vendor_stats(
        {
            "orders": Decimal("12"),
            "soldKg": Decimal("340"),
            "revenue": Decimal("9000"),
            "ratingSum": Decimal("54"),  # 54 / 12 = 4.5
            "ratingCount": Decimal("12"),
        }
    )
    assert trusted["avgRating"] == Decimal("4.5")
    assert trusted["ratingCount"] == 12
    assert trusted["trusted"] is True


def test_vendor_not_trusted_below_thresholds():
    # Enough orders but a weak average.
    weak = to_public_vendor_stats(
        {"orders": Decimal("20"), "ratingSum": Decimal("80"), "ratingCount": Decimal("20")}
    )  # avg 4.0
    assert weak["trusted"] is False
    # Great average but too few orders.
    few = to_public_vendor_stats(
        {"orders": Decimal("3"), "ratingSum": Decimal("15"), "ratingCount": Decimal("3")}
    )  # avg 5.0
    assert few["trusted"] is False


def test_aggregate_buyer_stats_sums_saved_and_kg():
    orders = [
        {"marketPricePerKg": Decimal("40"), "pricePerKg": Decimal("16"), "quantityKg": Decimal("10")},
        {"marketPricePerKg": Decimal("30"), "pricePerKg": Decimal("21"), "quantityKg": Decimal("5")},
    ]
    stats = aggregate_buyer_stats(orders)
    assert stats["orders"] == 2
    assert stats["saved"] == round((40 - 16) * 10 + (30 - 21) * 5)  # 240 + 45 = 285
    assert stats["kg"] == 15.0


def test_aggregate_cook_stats_matches_delivered_by_ngo():
    board = [
        {"ngoName": "Seva Kitchen", "status": "DELIVERED", "quantityKg": Decimal("8"), "mealsServed": 20},
        {"ngoName": "Seva Kitchen", "status": "PICKED_UP", "quantityKg": Decimal("5"), "mealsServed": 0},
        {"ngoName": "Other Trust", "status": "DELIVERED", "quantityKg": Decimal("9"), "mealsServed": 30},
    ]
    stats = aggregate_cook_stats(board, "Seva Kitchen")
    assert stats["rescues"] == 1
    assert stats["meals"] == 20
    assert stats["kg"] == 8.0

"""Unit tests for seller insights aggregation + AI parsing/fallback."""
from shared.insights import (
    aggregate_seller_insights,
    fallback_insights,
    parse_ai_recommendations,
)


def _listing(veg, qty, band, status="ACTIVE"):
    return {"type": "LISTING", "vegetable": veg, "quantityKg": qty,
            "band": band, "status": status}


def _order(veg, qty, total, created):
    return {"type": "ORDER", "vegetable": veg, "quantityKg": qty,
            "total": total, "createdAt": created}


def test_aggregates_totals_bands_and_movers():
    listings = [
        _listing("Tomato", 20, "GOOD"),
        _listing("Spinach", 5, "RESCUE"),
        _listing("Onion", 10, "GOOD", status="SOLD"),  # excluded from active
    ]
    orders = [
        _order("Tomato", 6, 168, 1000),
        _order("Tomato", 4, 112, 2000),
        _order("Spinach", 3, 54, 3000),
    ]
    agg = aggregate_seller_insights(listings, orders)

    assert agg["totals"]["activeListings"] == 2  # SOLD excluded
    assert agg["totals"]["orders"] == 3
    assert agg["totals"]["revenue"] == 334
    assert agg["bands"]["RESCUE"] == 1
    assert agg["movers"][0]["vegetable"] == "Tomato"  # most kg sold
    assert agg["movers"][0]["kg"] == 10


def test_empty_seller():
    agg = aggregate_seller_insights([], [])
    assert agg["totals"]["orders"] == 0
    assert agg["movers"] == []
    assert agg["peakHour"] is None


def test_fallback_is_grounded_in_data():
    agg = aggregate_seller_insights(
        [_listing("Spinach", 5, "RESCUE")],
        [_order("Tomato", 6, 168, 1000)],
    )
    recs = fallback_insights(agg)
    assert 1 <= len(recs) <= 3
    assert any("rescue" in r["title"].lower() for r in recs)
    assert all(r["title"] and r["body"] for r in recs)


def test_parse_ai_handles_json_and_fences():
    assert parse_ai_recommendations('[{"title":"A","body":"b"}]') == [
        {"title": "A", "body": "b"}
    ]
    fenced = '```json\n[{"title":"X","body":"y"}]\n```'
    assert parse_ai_recommendations(fenced) == [{"title": "X", "body": "y"}]
    assert parse_ai_recommendations("not json") is None
    assert parse_ai_recommendations("") is None

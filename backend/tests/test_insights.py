"""Unit tests for seller insights aggregation + AI parsing/fallback."""
import time

from shared.insights import (
    aggregate_seller_insights,
    fallback_insights,
    parse_ai_recommendations,
)


def _listing(veg, qty, band, status="ACTIVE"):
    return {"type": "LISTING", "vegetable": veg, "quantityKg": qty,
            "band": band, "status": status}


def _order(veg, qty, total, created, market=None, price=None):
    o = {"type": "ORDER", "vegetable": veg, "quantityKg": qty,
         "total": total, "createdAt": created}
    if market is not None:
        o["marketPricePerKg"] = market
    if price is not None:
        o["pricePerKg"] = price
    return o


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


def test_period_filters_orders_to_trailing_window():
    now = int(time.time())
    day = 86400
    orders = [
        _order("Tomato", 4, 100, now - 2 * day),    # in this week
        _order("Tomato", 4, 100, now - 20 * day),   # in this month, not week
        _order("Tomato", 4, 100, now - 300 * day),  # in this year, not month
    ]
    week = aggregate_seller_insights([], orders, period="week", now=now)
    month = aggregate_seller_insights([], orders, period="month", now=now)
    year = aggregate_seller_insights([], orders, period="year", now=now)

    assert week["totals"]["orders"] == 1
    assert month["totals"]["orders"] == 2
    assert year["totals"]["orders"] == 3
    assert week["period"] == "week"


def test_earnings_series_shape_and_bucketing():
    now = int(time.time())
    day = 86400
    orders = [
        _order("Tomato", 4, 210, now - 1 * day),
        _order("Tomato", 4, 90, now - 1 * day),
    ]
    agg = aggregate_seller_insights([], orders, period="week", now=now)
    earnings = agg["earnings"]
    assert len(earnings["labels"]) == 7
    assert len(earnings["values"]) == 7
    assert sum(earnings["values"]) == 300  # both orders land in one bucket

    year = aggregate_seller_insights([], orders, period="year", now=now)
    assert len(year["earnings"]["values"]) == 12


def test_impact_uses_market_price_savings():
    now = int(time.time())
    orders = [_order("Tomato", 10, 200, now - 3600, market=30, price=20)]
    agg = aggregate_seller_insights([], orders, period="week", now=now)
    impact = agg["impact"]
    assert impact["foodKeptKg"] == 10
    assert impact["meals"] == 25          # 10 kg * 2.5 meals/kg
    assert impact["buyerSavings"] == 100  # (30-20) * 10 kg


def test_parse_ai_handles_json_and_fences():
    assert parse_ai_recommendations('[{"title":"A","body":"b"}]') == [
        {"title": "A", "body": "b"}
    ]
    fenced = '```json\n[{"title":"X","body":"y"}]\n```'
    assert parse_ai_recommendations(fenced) == [{"title": "X", "body": "y"}]
    assert parse_ai_recommendations("not json") is None
    assert parse_ai_recommendations("") is None

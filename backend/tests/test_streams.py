"""Unit tests for DynamoDB Streams record parsing."""
from shared.streams import order_ids_from_records


def _record(event_name, item_type, order_id=None):
    image = {"type": {"S": item_type}}
    if order_id is not None:
        image["orderId"] = {"S": order_id}
    return {"eventName": event_name, "dynamodb": {"NewImage": image}}


def test_picks_only_inserted_orders():
    records = [
        _record("INSERT", "ORDER", "ord_1"),
        _record("INSERT", "LISTING", "lst_9"),   # wrong type
        _record("MODIFY", "ORDER", "ord_2"),     # status update, not a new order
        _record("INSERT", "ORDER", "ord_3"),
    ]
    assert order_ids_from_records(records) == ["ord_1", "ord_3"]


def test_ignores_orders_without_id_and_empty_batch():
    assert order_ids_from_records([]) == []
    assert order_ids_from_records([_record("INSERT", "ORDER")]) == []

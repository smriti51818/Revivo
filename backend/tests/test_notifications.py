"""Unit tests for notification stream parsing + item building."""
from shared.notifications import (
    build_notification_item,
    notifications_from_records,
    to_public_notification,
)


def _order(order_id, vendor_id, qty, veg, buyer):
    return {
        "eventName": "INSERT",
        "dynamodb": {
            "NewImage": {
                "type": {"S": "ORDER"},
                "orderId": {"S": order_id},
                "vendorId": {"S": vendor_id},
                "buyerName": {"S": buyer},
                "vegetable": {"S": veg},
                "quantityKg": {"N": qty},
            }
        },
    }


def _rescue(rescue_id, qty, veg, area):
    return {
        "eventName": "INSERT",
        "dynamodb": {
            "NewImage": {
                "type": {"S": "RESCUE"},
                "rescueId": {"S": rescue_id},
                "vegetable": {"S": veg},
                "quantityKg": {"N": qty},
                "pickupArea": {"S": area},
            }
        },
    }


def test_order_notifies_the_seller():
    specs = notifications_from_records(
        [_order("ord_1", "vendor_9", "8", "Tomatoes", "Hotel Ashok")]
    )
    assert len(specs) == 1
    spec = specs[0]
    assert spec["recipientId"] == "vendor_9"
    assert spec["kind"] == "ORDER"
    assert spec["body"] == "Hotel Ashok ordered 8 kg Tomatoes"
    assert spec["refId"] == "ord_1"


def test_rescue_is_broadcast_without_recipient():
    specs = notifications_from_records(
        [_rescue("rsc_2", "12.5", "Spinach", "RS Puram")]
    )
    assert specs[0]["recipientId"] is None
    assert specs[0]["kind"] == "RESCUE"
    assert specs[0]["body"] == "12.5 kg Spinach near RS Puram"


def test_ignores_non_insert_and_other_types():
    modify = {
        "eventName": "MODIFY",
        "dynamodb": {"NewImage": {"type": {"S": "ORDER"}}},
    }
    listing = {
        "eventName": "INSERT",
        "dynamodb": {"NewImage": {"type": {"S": "LISTING"}}},
    }
    assert notifications_from_records([modify, listing]) == []
    assert notifications_from_records([]) == []


def test_build_and_project_notification_item():
    spec = {
        "recipientId": "vendor_9",
        "kind": "ORDER",
        "title": "New order received",
        "body": "Hotel Ashok ordered 8 kg Tomatoes",
        "refId": "ord_1",
    }
    item = build_notification_item(spec, now=1000)
    assert item["GSI1PK"] == "USER#vendor_9"
    assert item["GSI1SK"].startswith("NOTIF#1000#")
    assert item["read"] is False
    assert item["ttl"] > item["createdAt"]

    public = to_public_notification(item)
    assert public["title"] == "New order received"
    assert public["read"] is False
    assert "id" in public and public["id"]

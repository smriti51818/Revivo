"""Helpers for reading DynamoDB Streams records — pure and unit-testable."""
from __future__ import annotations


def order_ids_from_records(records: list) -> list:
    """Return the orderIds of newly-inserted ORDER items in a stream batch.

    Ignores MODIFY/REMOVE events (so the workflow's own status updates don't
    re-trigger it) and non-ORDER items (listings, rescues).
    """
    order_ids = []
    for record in records or []:
        if record.get("eventName") != "INSERT":
            continue
        new_image = record.get("dynamodb", {}).get("NewImage", {})
        if new_image.get("type", {}).get("S") != "ORDER":
            continue
        order_id = new_image.get("orderId", {}).get("S")
        if order_id:
            order_ids.append(order_id)
    return order_ids

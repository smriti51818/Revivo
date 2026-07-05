"""Notification specs from DynamoDB Streams + item builders — pure + testable.

The notifier Lambda does the I/O (DynamoDB write + SNS publish); these helpers
turn a stream batch into notification specs and build the stored items.
"""
from __future__ import annotations

import time

from .ids import new_id


def _s(image: dict, key: str):
    return image.get(key, {}).get("S")


def _qty(image: dict, key: str) -> str:
    raw = image.get(key, {}).get("N")
    if raw is None:
        return ""
    try:
        return f"{float(raw):g}"
    except (TypeError, ValueError):
        return ""


def notifications_from_records(records: list) -> list:
    """Emit notification specs for newly-inserted ORDER and RESCUE items.

    ORDER -> addressed to the seller (vendorId). RESCUE -> broadcast (no
    recipient; SNS only). MODIFY/REMOVE and other types are ignored so the
    workflow's own status updates never generate notifications.
    """
    specs = []
    for record in records or []:
        if record.get("eventName") != "INSERT":
            continue
        image = record.get("dynamodb", {}).get("NewImage", {})
        item_type = _s(image, "type")

        if item_type == "ORDER":
            qty = _qty(image, "quantityKg")
            veg = _s(image, "vegetable") or "produce"
            buyer = _s(image, "buyerName") or "A buyer"
            specs.append(
                {
                    "recipientId": _s(image, "vendorId"),
                    "kind": "ORDER",
                    "title": "New order received",
                    "body": f"{buyer} ordered {qty} kg {veg}".replace(
                        "  ", " "
                    ),
                    "refId": _s(image, "orderId"),
                }
            )
        elif item_type == "RESCUE":
            qty = _qty(image, "quantityKg")
            veg = _s(image, "vegetable") or "produce"
            area = _s(image, "pickupArea") or "you"
            specs.append(
                {
                    "recipientId": None,  # broadcast to the network (SNS only)
                    "kind": "RESCUE",
                    "title": "New rescue available",
                    "body": f"{qty} kg {veg} near {area}".replace("  ", " "),
                    "refId": _s(image, "rescueId"),
                }
            )
    return specs


def build_notification_item(spec: dict, now: int | None = None) -> dict:
    """Build a stored NOTIFICATION item addressed to a user (GSI1 = USER#id)."""
    now = now if now is not None else int(time.time())
    notif_id = new_id("ntf")
    recipient = spec["recipientId"]
    return {
        "PK": f"NOTIF#{notif_id}",
        "SK": "META",
        "type": "NOTIFICATION",
        "notifId": notif_id,
        "userId": recipient,
        "kind": spec.get("kind", "INFO"),
        "title": spec.get("title", ""),
        "body": spec.get("body", ""),
        "refId": spec.get("refId"),
        "read": False,
        "createdAt": now,
        "ttl": now + 30 * 86400,
        "GSI1PK": f"USER#{recipient}",
        "GSI1SK": f"NOTIF#{now}#{notif_id}",
    }


def to_public_notification(item: dict) -> dict:
    """Project a stored NOTIFICATION item to the shape the app consumes."""
    return {
        "id": item.get("notifId"),
        "kind": item.get("kind"),
        "title": item.get("title"),
        "body": item.get("body"),
        "refId": item.get("refId"),
        "read": bool(item.get("read")),
        "createdAt": item.get("createdAt"),
    }

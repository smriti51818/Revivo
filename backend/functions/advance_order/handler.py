"""POST /orders/{orderId}/status — the vendor manually advances fulfilment.

The Step Functions lifecycle auto-advances orders on a timer for the demo, but a
real vendor needs to drive it themselves: mark a lot ready for pickup, then mark
it handed over. Owner-only (the order's vendorId must match the caller), and
limited to the two forward states a seller controls.
"""
import json

from shared.dynamo import get_table
from shared.models import to_public_order
from shared.responses import error, ok
from shared.uploads import attach_image_url

_ALLOWED = {"READY_FOR_PICKUP", "COMPLETED"}


def handler(event, context):
    order_id = (event.get("pathParameters") or {}).get("orderId")
    if not order_id:
        return error(400, "orderId is required")

    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return error(400, "invalid JSON body")

    status = str(body.get("status", "")).strip().upper()
    if status not in _ALLOWED:
        return error(400, f"status must be one of {sorted(_ALLOWED)}")

    claims = (
        event.get("requestContext", {}).get("authorizer", {}).get("claims", {})
    )
    vendor_id = claims.get("sub")

    table = get_table()
    key = {"PK": f"ORDER#{order_id}", "SK": "META"}
    order = table.get_item(Key=key).get("Item")
    if not order:
        return error(404, "order not found")
    if order.get("vendorId") != vendor_id:
        return error(403, "not your order")

    updated = table.update_item(
        Key=key,
        UpdateExpression="SET #s = :s",
        ExpressionAttributeNames={"#s": "status"},
        ExpressionAttributeValues={":s": status},
        ReturnValues="ALL_NEW",
    )["Attributes"]

    return ok(200, {"order": attach_image_url(to_public_order(updated))})

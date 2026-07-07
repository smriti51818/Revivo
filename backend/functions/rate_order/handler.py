"""POST /orders/{orderId}/rate — the buyer rates a completed order.

Stores 1–5 stars + optional quality tags/comment on the ORDER item. Owner-only.
This is the post-transaction layer of the trust model: quality feedback that a
later pass aggregates into a vendor reputation.
"""
import json

from shared.dynamo import get_table
from shared.models import to_public_order
from shared.responses import error, ok
from shared.validation import ValidationError, validate_rating_input


def handler(event, context):
    order_id = (event.get("pathParameters") or {}).get("orderId")
    if not order_id:
        return error(400, "orderId is required")

    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return error(400, "invalid JSON body")

    try:
        data = validate_rating_input(body)
    except ValidationError as exc:
        return error(400, str(exc))

    claims = (
        event.get("requestContext", {}).get("authorizer", {}).get("claims", {})
    )
    buyer_id = claims.get("sub")

    table = get_table()
    key = {"PK": f"ORDER#{order_id}", "SK": "META"}
    order = table.get_item(Key=key).get("Item")
    if not order:
        return error(404, "order not found")
    if order.get("buyerId") != buyer_id:
        return error(403, "not your order")

    # "rating" is a DynamoDB reserved word — alias it as #r.
    updated = table.update_item(
        Key=key,
        UpdateExpression="SET #r = :s, ratingTags = :t, ratingComment = :c",
        ExpressionAttributeNames={"#r": "rating"},
        ExpressionAttributeValues={
            ":s": data["stars"],
            ":t": data["tags"],
            ":c": data["comment"],
        },
        ReturnValues="ALL_NEW",
    )["Attributes"]

    return ok(200, {"order": to_public_order(updated)})

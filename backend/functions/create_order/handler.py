"""POST /orders — a buyer places an order against a surplus listing.

Looks up the referenced listing, snapshots its price/vendor into an immutable
ORDER item, and writes it. Order Streams later drive the Step Functions
lifecycle + seller notification.
"""
import json

from shared.dynamo import get_table
from shared.models import build_order_item, to_public_order
from shared.responses import error, ok
from shared.validation import ValidationError, validate_order_input


def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return error(400, "invalid JSON body")

    try:
        data = validate_order_input(body)
    except ValidationError as exc:
        return error(400, str(exc))

    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("claims", {})
    )
    buyer = {
        "id": claims.get("sub", "demo-buyer"),
        "name": claims.get("name") or "Buyer",
    }

    table = get_table()
    listing = table.get_item(
        Key={"PK": f"LISTING#{data['listingId']}", "SK": "META"}
    ).get("Item")
    if not listing:
        return error(404, "listing not found")

    item = build_order_item(data, buyer, listing)
    table.put_item(Item=item)

    return ok(201, {"order": to_public_order(item)})

"""POST /orders — a buyer places an order against a surplus listing.

Reserves stock first-come-first-serve with an atomic conditional decrement, so
the same surplus can't be over-sold; a depleted listing drops off the market.
The listing's price/vendor are snapshotted into an immutable ORDER item. Order
Streams then drive the Step Functions lifecycle + the seller notification.
"""
import json
from decimal import Decimal

from botocore.exceptions import ClientError

from shared.dynamo import get_table
from shared.freshness import apply_live_freshness
from shared.models import build_order_item, to_public_order
from shared.responses import error, ok
from shared.validation import ValidationError, validate_order_input


def _as_float(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


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
    key = {"PK": f"LISTING#{data['listingId']}", "SK": "META"}
    listing = table.get_item(Key=key).get("Item")
    if not listing:
        return error(404, "listing not found")

    ordered = data["quantityKg"]
    available = _as_float(listing.get("quantityKg"))
    if ordered > available + 1e-9:
        return error(409, f"Only {available:g} kg left — reduce the quantity")

    # Reserve stock atomically so two buyers can't claim the same surplus.
    try:
        updated = table.update_item(
            Key=key,
            UpdateExpression="SET quantityKg = quantityKg - :q",
            ConditionExpression="quantityKg >= :q",
            ExpressionAttributeValues={":q": Decimal(str(ordered))},
            ReturnValues="ALL_NEW",
        )["Attributes"]
    except ClientError as exc:
        if exc.response.get("Error", {}).get("Code") == (
            "ConditionalCheckFailedException"
        ):
            return error(409, "that surplus was just claimed — please refresh")
        return error(500, "could not reserve stock")

    # Depleted? Mark SOLD and drop it off the active market (GSI2 STATUS#ACTIVE).
    if _as_float(updated.get("quantityKg")) <= 0:
        table.update_item(
            Key=key,
            UpdateExpression="SET #s = :sold REMOVE GSI2PK, GSI2SK",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={":sold": "SOLD"},
        )

    # Charge the *live* freshness-decayed price, not the stale listing-time
    # snapshot, so the price matches the countdown the buyer just saw.
    priced_listing = apply_live_freshness(listing)
    item = build_order_item(data, buyer, priced_listing)
    table.put_item(Item=item)

    return ok(201, {"order": to_public_order(item)})

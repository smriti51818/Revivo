"""GET /orders/incoming — orders placed against this seller's listings.

Newest first (GSI3 VENDOR#<sub>). Lets the seller see live hotel orders and
their fulfilment status, mirroring the buyer's own order view.
"""
from boto3.dynamodb.conditions import Key

from shared.dynamo import get_table
from shared.models import to_public_order
from shared.responses import error, ok
from shared.uploads import attach_image_url


def handler(event, context):
    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("claims", {})
    )
    vendor_id = claims.get("sub", "demo-vendor")

    try:
        result = get_table().query(
            IndexName="GSI3",
            KeyConditionExpression=Key("GSI3PK").eq(f"VENDOR#{vendor_id}"),
            ScanIndexForward=False,
        )
    except Exception as exc:  # pragma: no cover - surfaced to the client
        return error(500, f"query failed: {exc}")

    orders = [attach_image_url(to_public_order(i)) for i in result.get("Items", [])]
    return ok(200, {"orders": orders, "count": len(orders)})

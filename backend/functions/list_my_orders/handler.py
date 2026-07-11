"""GET /orders — the signed-in buyer's orders, newest first (GSI1 BUYER#<sub>)."""
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
    buyer_id = claims.get("sub", "demo-buyer")

    try:
        result = get_table().query(
            IndexName="GSI1",
            KeyConditionExpression=Key("GSI1PK").eq(f"BUYER#{buyer_id}"),
            ScanIndexForward=False,
        )
    except Exception as exc:  # pragma: no cover - surfaced to the client
        return error(500, f"query failed: {exc}")

    orders = [attach_image_url(to_public_order(i)) for i in result.get("Items", [])]
    return ok(200, {"orders": orders, "count": len(orders)})

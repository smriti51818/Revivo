"""GET /listings/mine — the signed-in vendor's own listings.

Queries GSI1 (VENDOR#<sub>) newest-first, so the seller dashboard shows what
they just published at the top.
"""
from boto3.dynamodb.conditions import Key

from shared.dynamo import get_table
from shared.models import to_public_listing
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
            IndexName="GSI1",
            KeyConditionExpression=Key("GSI1PK").eq(f"VENDOR#{vendor_id}"),
            ScanIndexForward=False,
        )
    except Exception as exc:  # pragma: no cover - surfaced to the client
        return error(500, f"query failed: {exc}")

    listings = [
        attach_image_url(to_public_listing(i)) for i in result.get("Items", [])
    ]
    return ok(200, {"listings": listings, "count": len(listings)})

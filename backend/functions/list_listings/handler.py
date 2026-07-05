"""GET /listings — active surplus listings for the marketplace.

Queries GSI2 (STATUS#ACTIVE), whose sort key is `<expiryEpoch>#<id>`, so the
soonest-to-expire (rescue) items surface first — exactly the order a buyer
should see. Optional `?limit=` (default 50, max 100).
"""
from boto3.dynamodb.conditions import Key

from shared.dynamo import get_table
from shared.models import to_public_listing
from shared.responses import error, ok
from shared.uploads import attach_image_url


def handler(event, context):
    params = event.get("queryStringParameters") or {}
    try:
        limit = min(int(params.get("limit", 50)), 100)
    except (TypeError, ValueError):
        limit = 50

    try:
        result = get_table().query(
            IndexName="GSI2",
            KeyConditionExpression=Key("GSI2PK").eq("STATUS#ACTIVE"),
            Limit=limit,
        )
    except Exception as exc:  # pragma: no cover - surfaced to the client
        return error(500, f"query failed: {exc}")

    listings = [
        attach_image_url(to_public_listing(i)) for i in result.get("Items", [])
    ]
    return ok(200, {"listings": listings, "count": len(listings)})

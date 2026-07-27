"""DELETE /listings/{listingId} — the owner removes a listing.

Owner-only (vendorId must match the caller's sub). Deletes the item from
DynamoDB so it drops off the marketplace immediately.
"""
from botocore.exceptions import ClientError

from shared.dynamo import get_table
from shared.responses import error, ok


def handler(event, context):
    listing_id = (event.get("pathParameters") or {}).get("listingId")
    if not listing_id:
        return error(400, "listingId is required")

    claims = (
        event.get("requestContext", {}).get("authorizer", {}).get("claims", {})
    )
    vendor_id = claims.get("sub", "")

    try:
        get_table().delete_item(
            Key={"PK": f"LISTING#{listing_id}", "SK": "META"},
            ConditionExpression="attribute_exists(PK) AND vendorId = :vid",
            ExpressionAttributeValues={":vid": vendor_id},
        )
    except ClientError as exc:
        if exc.response.get("Error", {}).get("Code") == (
            "ConditionalCheckFailedException"
        ):
            return error(403, "listing not found or not yours")
        return error(500, "delete failed")

    return ok(200, {"deleted": True})

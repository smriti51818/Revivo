"""PATCH /listings/{listingId} — the owner updates a listing's stock (quantity).

Owner-only (vendorId must match the caller's sub). If quantity hits 0 the
listing is marked SOLD and drops off the active market.
"""
import json
from decimal import Decimal

from botocore.exceptions import ClientError

from shared.dynamo import get_table
from shared.models import to_public_listing
from shared.responses import error, ok
from shared.uploads import attach_image_url


def handler(event, context):
    listing_id = (event.get("pathParameters") or {}).get("listingId")
    if not listing_id:
        return error(400, "listingId is required")

    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return error(400, "invalid JSON body")

    claims = (
        event.get("requestContext", {}).get("authorizer", {}).get("claims", {})
    )
    vendor_id = claims.get("sub", "")

    try:
        qty = float(body.get("quantityKg"))
    except (TypeError, ValueError):
        return error(400, "quantityKg must be a number")
    if qty < 0 or qty > 1000:
        return error(400, "quantityKg must be between 0 and 1000")

    names = {"#v": "vendorId"}
    values = {":q": Decimal(str(qty)), ":vid": vendor_id}
    update = "SET quantityKg = :q"
    if qty <= 0:
        update += ", #s = :sold REMOVE GSI2PK, GSI2SK"
        names["#s"] = "status"
        values[":sold"] = "SOLD"

    try:
        result = get_table().update_item(
            Key={"PK": f"LISTING#{listing_id}", "SK": "META"},
            UpdateExpression=update,
            ConditionExpression="attribute_exists(PK) AND #v = :vid",
            ExpressionAttributeNames=names,
            ExpressionAttributeValues=values,
            ReturnValues="ALL_NEW",
        )
    except ClientError as exc:
        if exc.response.get("Error", {}).get("Code") == (
            "ConditionalCheckFailedException"
        ):
            return error(403, "listing not found or not yours")
        return error(500, "update failed")

    return ok(
        200,
        {"listing": attach_image_url(to_public_listing(result["Attributes"]))},
    )

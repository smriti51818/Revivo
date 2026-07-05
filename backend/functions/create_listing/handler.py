"""POST /listings — create a surplus listing.

Validates input, computes the freshness band + recommended price, writes the
listing to DynamoDB (whose Streams then trigger buyer matching + the Step
Functions lifecycle in later modules).
"""
import json

from shared.dynamo import get_table
from shared.freshness import estimate_freshness
from shared.models import build_listing_item, to_public_listing
from shared.responses import error, ok
from shared.uploads import attach_image_url
from shared.validation import ValidationError, validate_listing_input


def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return error(400, "invalid JSON body")

    try:
        data = validate_listing_input(body)
    except ValidationError as exc:
        return error(400, str(exc))

    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("claims", {})
    )
    vendor = {
        "id": claims.get("sub", "demo-vendor"),
        "name": claims.get("name") or "Vendor",
    }

    freshness = estimate_freshness(
        vegetable=data["vegetable"],
        purchased_at_epoch=data["purchasedAt"],
        storage=data["storage"],
        temp_c=data["tempC"],
    )
    item = build_listing_item(data, vendor, freshness)
    get_table().put_item(Item=item)

    return ok(201, {"listing": attach_image_url(to_public_listing(item))})

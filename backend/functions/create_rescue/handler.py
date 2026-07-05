"""POST /rescues — offer surplus to the rescue network (starts OFFERED).

Later this is created automatically when a listing enters the rescue window
(DynamoDB Streams); the explicit endpoint keeps it demoable + seedable now.
"""
import json

from shared.dynamo import get_table
from shared.models import build_rescue_item, to_public_rescue
from shared.responses import error, ok
from shared.validation import ValidationError, validate_rescue_input


def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return error(400, "invalid JSON body")

    try:
        data = validate_rescue_input(body)
    except ValidationError as exc:
        return error(400, str(exc))

    item = build_rescue_item(data)
    get_table().put_item(Item=item)
    return ok(201, {"rescue": to_public_rescue(item)})

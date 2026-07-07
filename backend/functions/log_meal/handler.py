"""POST /rescues/{rescueId}/meals — a cook logs meals served for a rescue.

Persists the meal count (and optional proof-photo S3 key) on the RESCUE item,
turning a delivered rescue into measurable, auditable Transform-stage impact.
Previously this lived only in client memory and reset on restart.
"""
import json

from shared.dynamo import get_table
from shared.models import to_public_rescue
from shared.responses import error, ok
from shared.validation import ValidationError, validate_meal_log


def handler(event, context):
    rescue_id = (event.get("pathParameters") or {}).get("rescueId")
    if not rescue_id:
        return error(400, "rescueId is required")

    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return error(400, "invalid JSON body")

    try:
        data = validate_meal_log(body)
    except ValidationError as exc:
        return error(400, str(exc))

    table = get_table()
    key = {"PK": f"RESCUE#{rescue_id}", "SK": "META"}
    if not table.get_item(Key=key).get("Item"):
        return error(404, "rescue not found")

    updated = table.update_item(
        Key=key,
        UpdateExpression="SET mealsServed = :m, mealPhotoKey = :p",
        ExpressionAttributeValues={
            ":m": data["meals"],
            ":p": data["photoKey"],
        },
        ReturnValues="ALL_NEW",
    )["Attributes"]

    return ok(200, {"rescue": to_public_rescue(updated)})

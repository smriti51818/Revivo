"""POST /rescues/{rescueId} — advance a rescue through its lifecycle.

Body: {"action": "ACCEPT"|"CLAIM"|"PICKUP"|"DELIVER", "ngoName": "..."}.
A DynamoDB conditional update enforces the required current status, so two
volunteers can't both claim the same pickup (returns 409 on a stale action).
"""
import json

from botocore.exceptions import ClientError

from shared.dynamo import get_table
from shared.models import RESCUE_TRANSITIONS, to_public_rescue
from shared.responses import error, ok
from shared.validation import ValidationError, validate_rescue_action


def handler(event, context):
    rescue_id = (event.get("pathParameters") or {}).get("rescueId")
    if not rescue_id:
        return error(400, "rescueId is required")

    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return error(400, "invalid JSON body")

    try:
        data = validate_rescue_action(body)
    except ValidationError as exc:
        return error(400, str(exc))

    expected, new_status = RESCUE_TRANSITIONS[data["action"]]
    update = "SET #s = :new"
    values = {":new": new_status, ":expected": expected}
    if data["action"] == "ACCEPT":
        update += ", ngoName = :ngo"
        values[":ngo"] = data["ngoName"]

    try:
        result = get_table().update_item(
            Key={"PK": f"RESCUE#{rescue_id}", "SK": "META"},
            UpdateExpression=update,
            ConditionExpression="#s = :expected",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues=values,
            ReturnValues="ALL_NEW",
        )
    except ClientError as exc:
        if exc.response.get("Error", {}).get("Code") == (
            "ConditionalCheckFailedException"
        ):
            return error(
                409, f"rescue is not ready for {data['action'].lower()}"
            )
        return error(500, "update failed")

    return ok(200, {"rescue": to_public_rescue(result["Attributes"])})

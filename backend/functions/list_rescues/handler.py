"""GET /rescues — the rescue board (all rescues, newest first).

The client groups by status (new / in progress / completed), mirroring the
Cook/NGO inbox and Volunteer pickup views.
"""
from boto3.dynamodb.conditions import Key

from shared.dynamo import get_table
from shared.models import to_public_rescue
from shared.responses import error, ok


def handler(event, context):
    try:
        result = get_table().query(
            IndexName="GSI2",
            KeyConditionExpression=Key("GSI2PK").eq("RESCUE#BOARD"),
            ScanIndexForward=False,
        )
    except Exception as exc:  # pragma: no cover - surfaced to the client
        return error(500, f"query failed: {exc}")

    rescues = [to_public_rescue(i) for i in result.get("Items", [])]
    return ok(200, {"rescues": rescues, "count": len(rescues)})

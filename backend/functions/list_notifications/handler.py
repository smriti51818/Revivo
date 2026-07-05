"""GET /notifications — the current user's notification feed (newest first)."""
from boto3.dynamodb.conditions import Key

from shared.dynamo import get_table
from shared.notifications import to_public_notification
from shared.responses import error, ok


def handler(event, context):
    claims = (
        event.get("requestContext", {}).get("authorizer", {}).get("claims", {})
    )
    user_id = claims.get("sub")
    if not user_id:
        return error(401, "unauthenticated")

    result = get_table().query(
        IndexName="GSI1",
        KeyConditionExpression=Key("GSI1PK").eq(f"USER#{user_id}")
        & Key("GSI1SK").begins_with("NOTIF#"),
        ScanIndexForward=False,  # newest first
        Limit=50,
    )
    items = [to_public_notification(i) for i in result.get("Items", [])]
    unread = sum(1 for i in items if not i["read"])
    return ok(200, {"notifications": items, "unread": unread})

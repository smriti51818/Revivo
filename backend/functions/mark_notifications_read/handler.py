"""POST /notifications/read — mark the current user's notifications as read."""
from boto3.dynamodb.conditions import Key

from shared.dynamo import get_table
from shared.responses import error, ok


def handler(event, context):
    claims = (
        event.get("requestContext", {}).get("authorizer", {}).get("claims", {})
    )
    user_id = claims.get("sub")
    if not user_id:
        return error(401, "unauthenticated")

    table = get_table()
    result = table.query(
        IndexName="GSI1",
        KeyConditionExpression=Key("GSI1PK").eq(f"USER#{user_id}")
        & Key("GSI1SK").begins_with("NOTIF#"),
        # "read" is a DynamoDB reserved word — alias it.
        ProjectionExpression="PK, SK, #r",
        ExpressionAttributeNames={"#r": "read"},
    )

    updated = 0
    for item in result.get("Items", []):
        if item.get("read"):
            continue
        table.update_item(
            Key={"PK": item["PK"], "SK": item["SK"]},
            UpdateExpression="SET #r = :t",
            ExpressionAttributeNames={"#r": "read"},
            ExpressionAttributeValues={":t": True},
        )
        updated += 1

    return ok(200, {"updated": updated})

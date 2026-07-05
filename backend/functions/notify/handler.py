"""DynamoDB Streams -> notifications (in-app feed item + SNS publish).

A new ORDER notifies the seller (stored feed + SNS); a new RESCUE is broadcast
to the rescue-network SNS topic. Runs as a second, independent consumer of the
table stream, alongside the order-workflow starter.
"""
import os

import boto3

from shared.dynamo import get_table
from shared.notifications import (
    build_notification_item,
    notifications_from_records,
)

_sns = None
_TOPIC_ARN = os.environ.get("TOPIC_ARN", "")


def _client():
    global _sns
    if _sns is None:
        _sns = boto3.client("sns")
    return _sns


def handler(event, context):
    specs = notifications_from_records(event.get("Records", []))
    table = get_table()
    stored = 0
    published = 0
    for spec in specs:
        if spec.get("recipientId"):
            table.put_item(Item=build_notification_item(spec))
            stored += 1
        if _TOPIC_ARN:
            try:
                _client().publish(
                    TopicArn=_TOPIC_ARN,
                    Subject=(spec.get("title") or "Revivo")[:100],
                    Message=spec.get("body", ""),
                    MessageAttributes={
                        "kind": {
                            "DataType": "String",
                            "StringValue": spec.get("kind", "INFO"),
                        }
                    },
                )
                published += 1
            except Exception:  # noqa: BLE001 - SNS is best-effort
                pass
    return {"stored": stored, "published": published}

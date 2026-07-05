"""DynamoDB Streams handler — starts the order lifecycle state machine.

Fires when a new ORDER item is written, kicking off the Step Functions
execution that advances the order through PREPARING -> READY_FOR_PICKUP ->
COMPLETED over time.
"""
import json
import os

import boto3

from shared.streams import order_ids_from_records

_sfn = None


def _client():
    global _sfn
    if _sfn is None:
        _sfn = boto3.client("stepfunctions")
    return _sfn


def handler(event, context):
    arn = os.environ["STATE_MACHINE_ARN"]
    started = 0
    for order_id in order_ids_from_records(event.get("Records", [])):
        _client().start_execution(
            stateMachineArn=arn,
            name=f"order-{order_id}",
            input=json.dumps({"orderId": order_id, "pk": f"ORDER#{order_id}"}),
        )
        started += 1
    return {"started": started}

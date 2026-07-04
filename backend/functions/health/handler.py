"""Public health check — verifies API Gateway → Lambda → DynamoDB wiring."""
import json
import os


def handler(event, context):
    body = {
        "status": "ok",
        "service": "revivo",
        "table": os.environ.get("TABLE_NAME"),
        "bucket": os.environ.get("UPLOADS_BUCKET"),
    }
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body),
    }

"""POST /rescues/{rescueId}/explain — AI "why rescue this?" via Bedrock (Claude).

Fetches the rescue, asks Claude for a short, warm explanation, and returns it.
If Bedrock model access isn't enabled (or on any error) it returns a
deterministic fallback, so the feature always works in a live demo.
"""
import json
import os

import boto3

from shared.dynamo import get_table
from shared.rescue_ai import build_explain_body, fallback_explanation
from shared.responses import error, ok

_MODEL_ID = os.environ.get(
    "BEDROCK_MODEL_ID", "anthropic.claude-3-haiku-20240307-v1:0"
)
_bedrock = None


def _client():
    global _bedrock
    if _bedrock is None:
        _bedrock = boto3.client("bedrock-runtime")
    return _bedrock


def handler(event, context):
    rescue_id = (event.get("pathParameters") or {}).get("rescueId")
    if not rescue_id:
        return error(400, "rescueId is required")

    item = (
        get_table()
        .get_item(Key={"PK": f"RESCUE#{rescue_id}", "SK": "META"})
        .get("Item")
    )
    if not item:
        return error(404, "rescue not found")

    try:
        resp = _client().invoke_model(
            modelId=_MODEL_ID,
            body=json.dumps(build_explain_body(item)),
        )
        payload = json.loads(resp["body"].read())
        text = "".join(
            block.get("text", "")
            for block in payload.get("content", [])
            if block.get("type") == "text"
        ).strip()
        if not text:
            raise ValueError("empty completion")
        return ok(200, {"explanation": text, "source": "ai"})
    except Exception:  # noqa: BLE001 - degrade to a deterministic fallback
        return ok(
            200,
            {"explanation": fallback_explanation(item), "source": "fallback"},
        )

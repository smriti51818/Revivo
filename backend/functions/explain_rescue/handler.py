"""POST /rescues/{rescueId}/explain — AI "why rescue this?" via Amazon Bedrock.

Fetches the rescue, asks a Bedrock model (Amazon Nova, via the Converse API)
for a short, warm explanation, and returns it. If Bedrock isn't available (or
on any error) it returns a deterministic fallback, so the feature always works
in a live demo.
"""
import os

import boto3

from shared.dynamo import get_table
from shared.rescue_ai import build_explain_converse_args, fallback_explanation
from shared.responses import error, ok

_MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "apac.amazon.nova-micro-v1:0")
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
        resp = _client().converse(
            modelId=_MODEL_ID, **build_explain_converse_args(item)
        )
        text = resp["output"]["message"]["content"][0]["text"].strip()
        if not text:
            raise ValueError("empty completion")
        return ok(200, {"explanation": text, "source": "ai"})
    except Exception as _exc:  # noqa: BLE001 - degrade to a deterministic fallback
        print(f"[bedrock] {type(_exc).__name__}: {_exc}")
        return ok(
            200,
            {"explanation": fallback_explanation(item), "source": "fallback"},
        )

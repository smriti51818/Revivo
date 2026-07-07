"""GET /listings/insights — data-driven seller insights + Bedrock AI summary.

Aggregates the seller's real listings + orders into metrics and top movers,
then asks a Bedrock model (Amazon Nova, via the Converse API) for 3
recommendations grounded in those numbers. Degrades to deterministic,
data-grounded advice if Bedrock isn't available.
"""
import os

import boto3
from boto3.dynamodb.conditions import Key

from shared.dynamo import get_table
from shared.insights import (
    aggregate_seller_insights,
    build_insights_converse_args,
    fallback_insights,
    parse_ai_recommendations,
)
from shared.responses import error, ok

_MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "apac.amazon.nova-micro-v1:0")
_bedrock = None


def _client():
    global _bedrock
    if _bedrock is None:
        _bedrock = boto3.client("bedrock-runtime")
    return _bedrock


def handler(event, context):
    claims = (
        event.get("requestContext", {}).get("authorizer", {}).get("claims", {})
    )
    vendor_id = claims.get("sub")
    if not vendor_id:
        return error(401, "unauthenticated")

    table = get_table()
    listings = table.query(
        IndexName="GSI1",
        KeyConditionExpression=Key("GSI1PK").eq(f"VENDOR#{vendor_id}"),
    ).get("Items", [])
    orders = table.query(
        IndexName="GSI3",
        KeyConditionExpression=Key("GSI3PK").eq(f"VENDOR#{vendor_id}"),
    ).get("Items", [])

    agg = aggregate_seller_insights(listings, orders)

    recommendations = None
    source = "fallback"
    try:
        resp = _client().converse(
            modelId=_MODEL_ID, **build_insights_converse_args(agg)
        )
        text = resp["output"]["message"]["content"][0]["text"]
        recommendations = parse_ai_recommendations(text)
        if recommendations:
            source = "ai"
    except Exception as _exc:  # noqa: BLE001 - degrade to deterministic advice
        print(f"[bedrock] {type(_exc).__name__}: {_exc}")
        recommendations = None

    if not recommendations:
        recommendations = fallback_insights(agg)

    return ok(
        200,
        {"insights": agg, "recommendations": recommendations, "source": source},
    )

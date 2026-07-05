"""GET /impact — network-wide impact summary + leaderboard.

Scans the table (projected to just the fields it needs) and aggregates in one
pure function. A scan is fine at pilot scale; at volume this is replaced by a
DynamoDB Streams-updated running counter item.
"""
from shared.dynamo import get_table
from shared.models import aggregate_impact
from shared.responses import error, ok

# `type` and `status` are DynamoDB reserved words, so every projected
# attribute is aliased.
_PROJECTION = "#t, #st, #q, #vn, #nn, #mp, #pp"
_NAMES = {
    "#t": "type",
    "#st": "status",
    "#q": "quantityKg",
    "#vn": "vendorName",
    "#nn": "ngoName",
    "#mp": "marketPricePerKg",
    "#pp": "pricePerKg",
}


def _scan_all(table) -> list:
    items = []
    kwargs = {
        "ProjectionExpression": _PROJECTION,
        "ExpressionAttributeNames": _NAMES,
    }
    resp = table.scan(**kwargs)
    items.extend(resp.get("Items", []))
    while "LastEvaluatedKey" in resp:
        resp = table.scan(ExclusiveStartKey=resp["LastEvaluatedKey"], **kwargs)
        items.extend(resp.get("Items", []))
    return items


def handler(event, context):
    try:
        items = _scan_all(get_table())
    except Exception as exc:  # pragma: no cover - surfaced to the client
        return error(500, f"scan failed: {exc}")
    return ok(200, aggregate_impact(items))

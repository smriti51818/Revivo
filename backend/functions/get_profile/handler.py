"""GET /profile — the signed-in user's real, persisted numbers.

Replaces the hardcoded profile stats and the name-hash-faked vendor reputation
with live aggregates from the table:

    wallet  — Revivo credit balance (earned server-side on every order)
    vendor  — orders / soldKg / revenue / avg rating / Trusted flag (sellers)
    buyer   — orders placed / rupees saved / kg rescued
    cook    — rescues handled / meals served / kg (matched by NGO name)

The client shows whichever block matches the caller's role.
"""
from boto3.dynamodb.conditions import Key

from shared.dynamo import get_table
from shared.profile import (
    aggregate_buyer_stats,
    aggregate_cook_stats,
    get_wallet_balance,
    to_public_vendor_stats,
    vendor_stats_key,
)
from shared.responses import error, ok


def handler(event, context):
    claims = (
        event.get("requestContext", {}).get("authorizer", {}).get("claims", {})
    )
    sub = claims.get("sub")
    name = claims.get("name") or ""
    if not sub:
        return error(401, "not authenticated")

    table = get_table()

    wallet = get_wallet_balance(table, sub)
    vendor = to_public_vendor_stats(
        table.get_item(Key=vendor_stats_key(sub)).get("Item")
    )

    # Buyer aggregates from the caller's own orders (GSI1 BUYER#<sub>).
    buyer_orders = table.query(
        IndexName="GSI1",
        KeyConditionExpression=Key("GSI1PK").eq(f"BUYER#{sub}"),
    ).get("Items", [])
    buyer = aggregate_buyer_stats(buyer_orders)

    # Cook aggregates from the rescue board, matched by NGO name.
    board = table.query(
        IndexName="GSI2",
        KeyConditionExpression=Key("GSI2PK").eq("RESCUE#BOARD"),
    ).get("Items", [])
    cook = aggregate_cook_stats(board, name)

    return ok(
        200,
        {
            "wallet": wallet,
            "vendor": vendor,
            "buyer": buyer,
            "cook": cook,
        },
    )

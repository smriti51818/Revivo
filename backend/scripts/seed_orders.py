#!/usr/bin/env python3
"""Seed a believable order history so the impact dashboard, buyer "My orders",
and seller incoming-orders all have coherent live data.

Creates COMPLETED orders (Hotel Ashok buying from the marketplace cast) plus a
couple of live in-flight orders to GreenLeaf Farms so the seller has something
to accept/advance during a demo. Idempotent: clears the buyer's existing orders
first. Prices are snapshotted the same way the live checkout does
(market x freshness factor), so the money-saved figures are real.

Run from backend/ with backend/.venv active:
    python scripts/seed_orders.py
"""
import os
import sys
import time

import boto3
from boto3.dynamodb.conditions import Key

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.models import build_order_item  # noqa: E402

_REGION = os.environ.get("AWS_REGION", "ap-south-1")
_TABLE = os.environ.get("TABLE_NAME", "RevivoTable")
_POOL = os.environ.get("COGNITO_USER_POOL_ID", "ap-south-1_4GFtB35OS")

_dynamo = boto3.resource("dynamodb", region_name=_REGION)
_cognito = boto3.client("cognito-idp", region_name=_REGION)

# Completed orders (vendor, veg, kg, market, offer-price, band, days-ago).
# offer-price = what was paid; savings = (market - offer) x kg.
_COMPLETED = [
    ("GreenLeaf Farms", "Tomato", 8, 40, 34, "GOOD", 6),
    ("Kovai Fresh Mart", "Spinach", 4, 30, 12, "RESCUE", 5),
    ("Anna Vegetable Stall", "Bell Pepper", 5, 80, 56, "USE_SOON", 4),
    ("Sunrise Organics", "Carrot", 10, 45, 38, "GOOD", 3),
    ("Daily Greens", "Beans", 3, 60, 24, "RESCUE", 2),
    ("GreenLeaf Farms", "Carrot", 12, 45, 45, "GOOD", 1),
]

# A couple of in-flight orders to the demo seller (GreenLeaf Farms) so the
# seller has live incoming orders to accept/advance. (veg, kg, market, price,
# band, status, hours-ago).
_LIVE = [
    ("Tomato", 6, 40, 28, "USE_SOON", "CONFIRMED", 2),
    ("Spinach", 3, 30, 12, "RESCUE", "PREPARING", 5),
]


def _sub(email: str) -> str:
    user = _cognito.admin_get_user(UserPoolId=_POOL, Username=email)
    for attr in user["UserAttributes"]:
        if attr["Name"] == "sub":
            return attr["Value"]
    raise SystemExit(f"could not find sub for {email}")


def _vendor_id(name: str, seller_sub: str) -> str:
    if name == "GreenLeaf Farms":
        return seller_sub
    slug = name.lower().split()[0]
    return f"vnd_{slug}"


def _order(table, buyer, vendor_name, vendor_id, veg, kg, market, price, band,
           status, secs_ago):
    now = int(time.time()) - secs_ago
    listing = {
        "listingId": f"lst_seed_{veg.lower()}",
        "vendorId": vendor_id,
        "vendorName": vendor_name,
        "vegetable": veg,
        "band": band,
        "recommendedPrice": price,
        "basePrice": market,
    }
    item = build_order_item({"quantityKg": kg, "pickupSlot": "6:00-6:30 PM"},
                            buyer, listing, now=now)
    item["status"] = status
    table.put_item(Item=item)
    saved = (market - price) * kg
    print(f"  {status:<10} {vendor_name:<20} {veg:<11} {kg:>2}kg  saved ₹{saved}")


def main() -> None:
    table = _dynamo.Table(_TABLE)
    buyer_sub = _sub("hotel@revivo.demo")
    seller_sub = _sub("seller@revivo.demo")
    buyer = {"id": buyer_sub, "name": "Hotel Ashok"}

    # Idempotent: clear the buyer's existing orders.
    existing = table.query(
        IndexName="GSI1",
        KeyConditionExpression=Key("GSI1PK").eq(f"BUYER#{buyer_sub}"),
    ).get("Items", [])
    for it in existing:
        table.delete_item(Key={"PK": it["PK"], "SK": it["SK"]})
    if existing:
        print(f"Cleared {len(existing)} existing order(s) for the buyer.\n")

    print("Completed orders (impact + history):")
    for vendor, veg, kg, market, price, band, days in _COMPLETED:
        _order(table, buyer, vendor, _vendor_id(vendor, seller_sub), veg, kg,
               market, price, band, "COMPLETED", days * 86400)

    print("\nLive incoming orders to GreenLeaf Farms:")
    for veg, kg, market, price, band, status, hrs in _LIVE:
        _order(table, buyer, "GreenLeaf Farms", seller_sub, veg, kg, market,
               price, band, status, hrs * 3600)

    print(f"\nSeeded {len(_COMPLETED) + len(_LIVE)} orders.")


if __name__ == "__main__":
    main()

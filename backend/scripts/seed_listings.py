#!/usr/bin/env python3
"""Seed demo listings for the seller demo account (seller@revivo.demo).

Creates a spread of listings (varied freshness bands + vegetable photos) owned
by the seller's Cognito sub, so the seller dashboard has real inventory to show.
Idempotent: clears the seller's existing listings first, then re-seeds.

Run from backend/ with backend/.venv active:
    python scripts/seed_listings.py
"""
import os

import boto3
from boto3.dynamodb.conditions import Key

from shared.freshness import estimate_freshness
from shared.market_prices import market_price
from shared.models import build_listing_item

_REGION = os.environ.get("AWS_REGION", "ap-south-1")
_TABLE = os.environ.get("TABLE_NAME", "RevivoTable")
_POOL = os.environ.get("COGNITO_USER_POOL_ID", "ap-south-1_4GFtB35OS")
_SELLER_EMAIL = "seller@revivo.demo"

_dynamo = boto3.resource("dynamodb", region_name=_REGION)
_cognito = boto3.client("cognito-idp", region_name=_REGION)

# (vegetable, quantity kg, storage, hours-since-purchase) — the hours drive the
# freshness band, so we get a realistic GOOD / USE_SOON / RESCUE spread.
_SEED = [
    ("Tomato", 15, "ROOM", 6),
    ("Onion", 30, "ROOM", 48),
    ("Carrot", 25, "REFRIGERATED", 18),
    ("Cauliflower", 8, "ROOM", 60),
    ("Okra", 5, "ROOM", 40),
    ("Spinach", 4, "ROOM", 28),
    ("Coriander", 3, "ROOM", 26),
]


def _seller_sub() -> str:
    user = _cognito.admin_get_user(UserPoolId=_POOL, Username=_SELLER_EMAIL)
    for attr in user["UserAttributes"]:
        if attr["Name"] == "sub":
            return attr["Value"]
    raise SystemExit("could not find the seller's sub")


def _image_url(vegetable: str) -> str:
    slug = vegetable.lower().replace(" ", ",")
    return f"https://loremflickr.com/400/320/{slug},vegetable"


def main() -> None:
    table = _dynamo.Table(_TABLE)
    sub = _seller_sub()
    vendor = {"id": sub, "name": "Seller Demo"}
    import time

    now = int(time.time())

    # Clear existing listings for this seller (idempotent re-seed).
    existing = table.query(
        IndexName="GSI1",
        KeyConditionExpression=Key("GSI1PK").eq(f"VENDOR#{sub}"),
    ).get("Items", [])
    for item in existing:
        table.delete_item(Key={"PK": item["PK"], "SK": item["SK"]})
    print(f"Cleared {len(existing)} existing listing(s) for {_SELLER_EMAIL}")

    for veg, qty, storage, hours_ago in _SEED:
        purchased = now - hours_ago * 3600
        data = {
            "vegetable": veg,
            "quantityKg": qty,
            "basePrice": market_price(veg),
            "storage": storage,
            "purchasedAt": purchased,
            "tempC": 28,
            "imageKey": "",
        }
        fr = estimate_freshness(veg, purchased, storage, 28)
        item = build_listing_item(data, vendor, fr, now=now)
        item["imageUrl"] = _image_url(veg)
        table.put_item(Item=item)
        print(f"  + {veg:<12} {qty:>3} kg  {fr.band:<9} {fr.time_range_label}")

    print(f"\nSeeded {len(_SEED)} listings for {_SELLER_EMAIL}.")


if __name__ == "__main__":
    main()

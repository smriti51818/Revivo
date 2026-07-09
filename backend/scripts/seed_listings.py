#!/usr/bin/env python3
"""Seed a coherent, multi-vendor marketplace into the live table.

Two sets of listings are created so both live views look real:
  * the demo seller's own inventory (owned by seller@revivo.demo's Cognito sub,
    vendor name "GreenLeaf Farms") — this is what the seller dashboard shows;
  * a spread of listings from five other Coimbatore vendors (synthetic vendor
    ids) — so the buyer marketplace (STATUS#ACTIVE) is a believable multi-vendor
    board rather than a single seller.

Hours-since-purchase drive the freshness band, so we get a realistic
GOOD / USE_SOON / RESCUE spread and honest per-listing dynamic pricing.
Idempotent: clears every previously-seeded listing first, then re-seeds.

Run from backend/ with backend/.venv active:
    python scripts/seed_listings.py
"""
import os
import sys
import time

import boto3
from boto3.dynamodb.conditions import Key

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.freshness import estimate_freshness  # noqa: E402
from shared.market_prices import market_price  # noqa: E402
from shared.models import build_listing_item  # noqa: E402

_REGION = os.environ.get("AWS_REGION", "ap-south-1")
_TABLE = os.environ.get("TABLE_NAME", "RevivoTable")
_POOL = os.environ.get("COGNITO_USER_POOL_ID", "ap-south-1_4GFtB35OS")
_SELLER_EMAIL = "seller@revivo.demo"
_SELLER_NAME = "GreenLeaf Farms"

_dynamo = boto3.resource("dynamodb", region_name=_REGION)
_cognito = boto3.client("cognito-idp", region_name=_REGION)

# The demo seller's own inventory (dashboard). (veg, kg, storage, hours-ago).
# Hours are tuned to the vegetable's shelf life to give a GOOD/USE_SOON/RESCUE
# spread so the freshness bands + dynamic pricing are all visible at a glance.
_SELLER_SEED = [
    ("Tomato", 12, "ROOM", 6),        # GOOD
    ("Carrot", 28, "REFRIGERATED", 20),  # GOOD
    ("Spinach", 5, "ROOM", 20),       # USE_SOON
    ("Coriander", 3, "ROOM", 30),     # RESCUE
]

# Other vendors on the marketplace. (vendor_id, vendor_name, veg, kg, storage, hrs).
_MARKET_SEED = [
    ("vnd_kovai", "Kovai Fresh Mart", "Spinach", 4, "ROOM", 28),      # RESCUE
    ("vnd_sunrise", "Sunrise Organics", "Carrot", 20, "REFRIGERATED", 10),  # GOOD
    ("vnd_anna", "Anna Vegetable Stall", "Bell Pepper", 6, "ROOM", 90),  # USE_SOON
    ("vnd_rstraders", "RS Traders", "Cauliflower", 9, "ROOM", 95),   # RESCUE
    ("vnd_dailygreens", "Daily Greens", "Beans", 5, "ROOM", 75),     # RESCUE
]


def _seller_sub() -> str:
    user = _cognito.admin_get_user(UserPoolId=_POOL, Username=_SELLER_EMAIL)
    for attr in user["UserAttributes"]:
        if attr["Name"] == "sub":
            return attr["Value"]
    raise SystemExit("could not find the seller's sub")


def _image_url(vegetable: str, lock: int) -> str:
    slug = vegetable.lower().replace(" ", ",")
    # `lock` makes the photo deterministic per listing (stable across re-seeds).
    return f"https://loremflickr.com/400/320/{slug},vegetable?lock={lock}"


def _clear_vendor(table, vendor_id: str) -> int:
    existing = table.query(
        IndexName="GSI1",
        KeyConditionExpression=Key("GSI1PK").eq(f"VENDOR#{vendor_id}"),
    ).get("Items", [])
    for item in existing:
        table.delete_item(Key={"PK": item["PK"], "SK": item["SK"]})
    return len(existing)


def _put(table, vendor: dict, veg: str, qty, storage: str, hours_ago: int,
         now: int, lock: int) -> None:
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
    item["imageUrl"] = _image_url(veg, lock)
    table.put_item(Item=item)
    print(f"  + {vendor['name']:<20} {veg:<12} {qty:>3} kg  "
          f"{fr.band:<9} ₹{item['recommendedPrice']}/kg")


def main() -> None:
    table = _dynamo.Table(_TABLE)
    sub = _seller_sub()
    now = int(time.time())
    lock = 1

    # Clear the seller's own + every synthetic marketplace vendor (idempotent).
    cleared = _clear_vendor(table, sub)
    for vid, *_ in _MARKET_SEED:
        cleared += _clear_vendor(table, vid)
    print(f"Cleared {cleared} previously-seeded listing(s).\n")

    print(f"Seller inventory ({_SELLER_NAME}):")
    seller = {"id": sub, "name": _SELLER_NAME}
    for veg, qty, storage, hrs in _SELLER_SEED:
        _put(table, seller, veg, qty, storage, hrs, now, lock)
        lock += 1

    print("\nMarketplace vendors:")
    for vid, vname, veg, qty, storage, hrs in _MARKET_SEED:
        _put(table, {"id": vid, "name": vname}, veg, qty, storage, hrs, now, lock)
        lock += 1

    total = len(_SELLER_SEED) + len(_MARKET_SEED)
    print(f"\nSeeded {total} listings across {1 + len(_MARKET_SEED)} vendors.")


if __name__ == "__main__":
    main()

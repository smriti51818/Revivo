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
_BUCKET = os.environ.get(
    "UPLOADS_BUCKET", "revivo-data-uploadsbucket5e5e9b64-k0l6pkbemzzz"
)
_SELLER_EMAIL = "seller@revivo.demo"
_SELLER_NAME = "GreenLeaf Farms"

# Real, curated produce photos live here; they're uploaded to S3 and each
# listing references its photo via imageKey (no direct image URL is stored).
_ASSETS_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "seed_assets",
    "produce",
)

_dynamo = boto3.resource("dynamodb", region_name=_REGION)
_cognito = boto3.client("cognito-idp", region_name=_REGION)
_s3 = boto3.client("s3", region_name=_REGION)

# The demo seller's own inventory (dashboard). (veg, kg, storage, hours-ago).
# Hours are tuned to the vegetable's shelf life to give a GOOD/USE_SOON/RESCUE
# spread so the freshness bands + dynamic pricing are all visible at a glance.
# Every vegetable here has a real photo in seed_assets/produce/.
_SELLER_SEED = [
    ("Tomato", 12, "ROOM", 6),           # GOOD
    ("Carrot", 28, "REFRIGERATED", 20),  # GOOD
    ("Spinach", 5, "ROOM", 20),          # USE_SOON
    ("Beans", 4, "ROOM", 75),            # RESCUE
]

# Other vendors on the marketplace. (vendor_id, vendor_name, veg, kg, storage, hrs).
_MARKET_SEED = [
    ("vnd_kovai", "Kovai Fresh Mart", "Cauliflower", 4, "ROOM", 95),    # RESCUE
    ("vnd_sunrise", "Sunrise Organics", "Carrot", 20, "REFRIGERATED", 10),  # GOOD
    ("vnd_anna", "Anna Vegetable Stall", "Bell Pepper", 6, "ROOM", 90),  # USE_SOON
    ("vnd_rstraders", "RS Traders", "Tomato", 9, "ROOM", 78),          # RESCUE
    ("vnd_dailygreens", "Daily Greens", "Spinach", 5, "ROOM", 30),     # RESCUE
]


def _seller_sub() -> str:
    user = _cognito.admin_get_user(UserPoolId=_POOL, Username=_SELLER_EMAIL)
    for attr in user["UserAttributes"]:
        if attr["Name"] == "sub":
            return attr["Value"]
    raise SystemExit("could not find the seller's sub")


def _slug(vegetable: str) -> str:
    return vegetable.lower().replace(" ", "_")


# Cache of vegetable-slug -> uploaded S3 key, so each photo uploads only once.
_uploaded: dict[str, str] = {}


def _image_key(vegetable: str) -> str:
    """Upload the vegetable's real photo to S3 (once) and return its imageKey.

    Returns '' when there's no matching file — the listing then seeds without a
    photo and the app shows its tinted placeholder.
    """
    slug = _slug(vegetable)
    if slug in _uploaded:
        return _uploaded[slug]
    path = os.path.join(_ASSETS_DIR, f"{slug}.jpg")
    if not os.path.exists(path):
        _uploaded[slug] = ""
        return ""
    key = f"uploads/seed/{slug}.jpg"
    with open(path, "rb") as fh:
        _s3.put_object(
            Bucket=_BUCKET, Key=key, Body=fh.read(), ContentType="image/jpeg"
        )
    _uploaded[slug] = key
    return key


def _clear_vendor(table, vendor_id: str) -> int:
    existing = table.query(
        IndexName="GSI1",
        KeyConditionExpression=Key("GSI1PK").eq(f"VENDOR#{vendor_id}"),
    ).get("Items", [])
    for item in existing:
        table.delete_item(Key={"PK": item["PK"], "SK": item["SK"]})
    return len(existing)


def _put(table, vendor: dict, veg: str, qty, storage: str, hours_ago: int,
         now: int) -> None:
    purchased = now - hours_ago * 3600
    data = {
        "vegetable": veg,
        "quantityKg": qty,
        "basePrice": market_price(veg),
        "storage": storage,
        "purchasedAt": purchased,
        "tempC": 28,
        "imageKey": _image_key(veg),
    }
    fr = estimate_freshness(veg, purchased, storage, 28)
    item = build_listing_item(data, vendor, fr, now=now)
    # No imageUrl is stored — it's regenerated from imageKey on read, so a
    # seller's photo edit reflects immediately (see shared.uploads).
    table.put_item(Item=item)
    photo = "photo" if data["imageKey"] else "no-photo"
    print(f"  + {vendor['name']:<20} {veg:<12} {qty:>3} kg  "
          f"{fr.band:<9} ₹{item['recommendedPrice']}/kg  [{photo}]")


def main() -> None:
    table = _dynamo.Table(_TABLE)
    sub = _seller_sub()
    now = int(time.time())

    # Clear the seller's own + every synthetic marketplace vendor (idempotent).
    cleared = _clear_vendor(table, sub)
    for vid, *_ in _MARKET_SEED:
        cleared += _clear_vendor(table, vid)
    print(f"Cleared {cleared} previously-seeded listing(s).\n")

    print(f"Seller inventory ({_SELLER_NAME}):")
    seller = {"id": sub, "name": _SELLER_NAME}
    for veg, qty, storage, hrs in _SELLER_SEED:
        _put(table, seller, veg, qty, storage, hrs, now)

    print("\nMarketplace vendors:")
    for vid, vname, veg, qty, storage, hrs in _MARKET_SEED:
        _put(table, {"id": vid, "name": vname}, veg, qty, storage, hrs, now)

    total = len(_SELLER_SEED) + len(_MARKET_SEED)
    print(f"\nSeeded {total} listings across {1 + len(_MARKET_SEED)} vendors.")


if __name__ == "__main__":
    main()

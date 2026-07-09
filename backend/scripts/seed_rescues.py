"""Seed the rescue board into the live table so the Sell->Rescue->Transform
story has real data — a spread of statuses (OFFERED / ACCEPTED / PICKED_UP /
DELIVERED) using the same vendor + vegetable cast as the marketplace.

Run from the backend/ directory (with backend/.venv active):

    python scripts/seed_rescues.py            # region ap-south-1, table RevivoTable
    TABLE_NAME=RevivoTable AWS_REGION=ap-south-1 python scripts/seed_rescues.py
"""
import os
import sys

import boto3
from boto3.dynamodb.conditions import Key

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.models import build_rescue_item  # noqa: E402

# Same vendors/vegetables as the marketplace; NGOs are the demo cast. A mix of
# statuses so the rescue board demos the live flow AND the impact dashboard
# shows delivered numbers immediately.
_SEED = [
    {
        "vendorName": "Kovai Fresh Mart",
        "pickupArea": "R.S. Puram",
        "vegetable": "Spinach",
        "quantityKg": 4,
        "band": "RESCUE",
        "timeRange": "~2-3 h",
        "distanceKm": 0.8,
    },
    {
        "vendorName": "Daily Greens",
        "pickupArea": "Gandhipuram",
        "vegetable": "Beans",
        "quantityKg": 5,
        "band": "RESCUE",
        "timeRange": "~3-4 h",
        "distanceKm": 2.9,
    },
    {
        "vendorName": "Anna Vegetable Stall",
        "pickupArea": "Town Hall",
        "vegetable": "Tomato",
        "quantityKg": 8,
        "band": "RESCUE",
        "timeRange": "~4-5 h",
        "distanceKm": 2.1,
        "status": "ACCEPTED",
        "ngoName": "Annapoorna Trust",
    },
    {
        "vendorName": "RS Traders",
        "pickupArea": "Peelamedu",
        "vegetable": "Cauliflower",
        "quantityKg": 6,
        "band": "RESCUE",
        "timeRange": "picked up",
        "distanceKm": 1.7,
        "status": "PICKED_UP",
        "ngoName": "Seva Kitchen",
    },
    {
        "vendorName": "GreenLeaf Farms",
        "pickupArea": "Saibaba Colony",
        "vegetable": "Carrot",
        "quantityKg": 10,
        "band": "RESCUE",
        "timeRange": "delivered",
        "distanceKm": 3.4,
        "status": "DELIVERED",
        "ngoName": "Annapoorna Trust",
    },
]

# Historical DELIVERED rescues so the Impact dashboard reflects a running pilot
# (meals = delivered kg x 2.5). Real records — just already completed.
_HISTORY = [
    ("Sunrise Organics", "Saravanampatti", "Spinach", 14, "Seva Kitchen"),
    ("Kovai Fresh Mart", "R.S. Puram", "Tomato", 22, "No Food Waste"),
    ("Daily Greens", "Gandhipuram", "Cauliflower", 16, "Annapoorna Trust"),
    ("Anna Vegetable Stall", "Town Hall", "Beans", 12, "Seva Kitchen"),
    ("GreenLeaf Farms", "Saibaba Colony", "Carrot", 20, "No Food Waste"),
    ("RS Traders", "Peelamedu", "Bell Pepper", 9, "Annapoorna Trust"),
    ("Sunrise Organics", "Saravanampatti", "Tomato", 18, "Seva Kitchen"),
    ("Kovai Fresh Mart", "R.S. Puram", "Spinach", 11, "Annapoorna Trust"),
]
for _v, _a, _veg, _kg, _ngo in _HISTORY:
    _SEED.append({
        "vendorName": _v,
        "pickupArea": _a,
        "vegetable": _veg,
        "quantityKg": _kg,
        "band": "RESCUE",
        "timeRange": "delivered",
        "distanceKm": 2.0,
        "status": "DELIVERED",
        "ngoName": _ngo,
    })


def main() -> None:
    table_name = os.environ.get("TABLE_NAME", "RevivoTable")
    region = os.environ.get("AWS_REGION", "ap-south-1")
    table = boto3.resource("dynamodb", region_name=region).Table(table_name)

    # Idempotent: clear the existing rescue board first.
    existing = table.query(
        IndexName="GSI2",
        KeyConditionExpression=Key("GSI2PK").eq("RESCUE#BOARD"),
    ).get("Items", [])
    for item in existing:
        table.delete_item(Key={"PK": item["PK"], "SK": item["SK"]})
    if existing:
        print(f"Cleared {len(existing)} existing rescue(s).")

    for data in _SEED:
        item = build_rescue_item(data)
        if data.get("status"):
            item["status"] = data["status"]
        if data.get("ngoName"):
            item["ngoName"] = data["ngoName"]
        table.put_item(Item=item)
        print(
            f"  + {data['vendorName']:<20} {data['vegetable']:<12} "
            f"{data['quantityKg']:>2}kg  {item['status']}"
        )

    print(f"\nSeeded {len(_SEED)} rescues into {table_name} ({region}).")


if __name__ == "__main__":
    main()

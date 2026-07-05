"""Seed a few OFFERED rescues into the live table so the Cook/NGO inbox and
Volunteer board have data to demo. Uses your default AWS credentials.

Run from the backend/ directory (with backend/.venv active):

    python scripts/seed_rescues.py            # region ap-south-1, table RevivoTable
    TABLE_NAME=RevivoTable AWS_REGION=ap-south-1 python scripts/seed_rescues.py
"""
import os
import sys

import boto3

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.models import build_rescue_item  # noqa: E402

_SEED = [
    {
        "vendorName": "Kovai Fresh Mart",
        "pickupArea": "RS Puram",
        "vegetable": "Baby Spinach",
        "quantityKg": 4,
        "band": "RESCUE",
        "timeRange": "~2-3 h",
        "distanceKm": 0.8,
    },
    {
        "vendorName": "Daily Greens",
        "pickupArea": "Gandhipuram",
        "vegetable": "French Beans",
        "quantityKg": 5,
        "band": "RESCUE",
        "timeRange": "~3-4 h",
        "distanceKm": 2.9,
    },
    {
        "vendorName": "Anna Vegetable Stall",
        "pickupArea": "Town Hall",
        "vegetable": "Tomatoes",
        "quantityKg": 8,
        "band": "RESCUE",
        "timeRange": "~4-5 h",
        "distanceKm": 2.1,
    },
]


def main() -> None:
    table_name = os.environ.get("TABLE_NAME", "RevivoTable")
    region = os.environ.get("AWS_REGION", "ap-south-1")
    table = boto3.resource("dynamodb", region_name=region).Table(table_name)

    for data in _SEED:
        item = build_rescue_item(data)
        table.put_item(Item=item)
        print(f"seeded {item['rescueId']}  {data['vegetable']} ({data['quantityKg']}kg)")

    print(f"\nDone. Seeded {len(_SEED)} rescues into {table_name} ({region}).")


if __name__ == "__main__":
    main()

"""Seed a few OFFERED rescues into the live table so the Cook/NGO inbox has
data to demo. Uses your default AWS credentials.

Run from the backend/ directory (with backend/.venv active):

    python scripts/seed_rescues.py            # region ap-south-1, table RevivoTable
    TABLE_NAME=RevivoTable AWS_REGION=ap-south-1 python scripts/seed_rescues.py
"""
import os
import sys

import boto3

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.models import build_rescue_item  # noqa: E402

# A mix of OFFERED rescues (to demo the live accept→pickup→deliver flow) and
# a few already DELIVERED (so the Impact dashboard shows real numbers at once).
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
        "status": "DELIVERED",
        "ngoName": "Annapoorna Trust",
    },
    {
        "vendorName": "GreenLeaf Farms",
        "pickupArea": "Saibaba Colony",
        "vegetable": "Garden Carrots",
        "quantityKg": 10,
        "band": "RESCUE",
        "timeRange": "delivered",
        "distanceKm": 3.4,
        "status": "DELIVERED",
        "ngoName": "Seva Kitchen",
    },
]


def main() -> None:
    table_name = os.environ.get("TABLE_NAME", "RevivoTable")
    region = os.environ.get("AWS_REGION", "ap-south-1")
    table = boto3.resource("dynamodb", region_name=region).Table(table_name)

    for data in _SEED:
        item = build_rescue_item(data)
        if data.get("status"):
            item["status"] = data["status"]
        if data.get("ngoName"):
            item["ngoName"] = data["ngoName"]
        table.put_item(Item=item)
        print(
            f"seeded {item['rescueId']}  {data['vegetable']} "
            f"({data['quantityKg']}kg, {item['status']})"
        )

    print(f"\nDone. Seeded {len(_SEED)} rescues into {table_name} ({region}).")


if __name__ == "__main__":
    main()

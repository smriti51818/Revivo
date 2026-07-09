#!/usr/bin/env python3
"""Create (or update) the demo Cognito accounts for fast testing.

Usage: DEMO_PASSWORD=<your-password> python scripts/seed_users.py

Seeds two pre-confirmed accounts — one per active role — with the friendly
display names used across the demo cast, so live listings/orders read
"GreenLeaf Farms" and "Hotel Ashok" rather than "Seller Demo". Re-running is
safe: existing accounts have their name/role refreshed and password re-set.
"""
import os
import sys

import boto3

_cognito = boto3.client("cognito-idp", region_name="ap-south-1")

# (email, role, display name) — the cook role was removed from the app, so only
# the seller + buyer accounts are seeded. Names match the demo marketplace cast.
DEMO_ACCOUNTS = [
    ("seller@revivo.demo", "seller", "GreenLeaf Farms"),
    ("hotel@revivo.demo", "buyer", "Hotel Ashok"),
]

_pool_id = os.environ.get("COGNITO_USER_POOL_ID", "ap-south-1_4GFtB35OS")
_password = os.environ.get("DEMO_PASSWORD")

if not _password:
    print("Error: DEMO_PASSWORD env var not set")
    print("Usage: DEMO_PASSWORD=your-password python scripts/seed_users.py")
    sys.exit(1)


def _attrs(email: str, role: str, name: str) -> list[dict]:
    return [
        {"Name": "email", "Value": email},
        {"Name": "email_verified", "Value": "true"},
        {"Name": "name", "Value": name},
        {"Name": "custom:role", "Value": role},
    ]


def seed_users() -> None:
    for email, role, name in DEMO_ACCOUNTS:
        try:
            _cognito.admin_create_user(
                UserPoolId=_pool_id,
                Username=email,
                TemporaryPassword=_password,
                UserAttributes=_attrs(email, role, name),
                MessageAction="SUPPRESS",
            )
            print(f"created {email:<22} role={role:<7} name={name!r}")
        except _cognito.exceptions.UsernameExistsException:
            # Refresh name/role on the existing account so the cast stays current.
            _cognito.admin_update_user_attributes(
                UserPoolId=_pool_id,
                Username=email,
                UserAttributes=_attrs(email, role, name),
            )
            print(f"updated {email:<22} role={role:<7} name={name!r}")
        except Exception as e:  # noqa: BLE001
            print(f"error   {email:<22}: {e}")
            continue

        _cognito.admin_set_user_password(
            UserPoolId=_pool_id, Username=email, Password=_password, Permanent=True
        )


if __name__ == "__main__":
    print(f"Seeding {len(DEMO_ACCOUNTS)} demo accounts to {_pool_id}...\n")
    seed_users()
    print(f"\nReady - log in with the emails above / password {_password}.")

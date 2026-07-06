#!/usr/bin/env python3
"""Create demo Cognito user accounts for fast testing.

Usage: DEMO_PASSWORD=<your-password> python seed_users.py

Creates 4 accounts (one per role) pre-confirmed so they can log in immediately.
"""
import os
import sys

import boto3

_cognito = boto3.client("cognito-idp", region_name="ap-south-1")

DEMO_ACCOUNTS = [
    ("seller@revivo.demo", "seller", "Seller Demo"),
    ("hotel@revivo.demo", "buyer", "Hotel Demo"),
    ("cook@revivo.demo", "cook", "Cook Demo"),
]

# Read from env vars
_pool_id = os.environ.get("COGNITO_USER_POOL_ID", "ap-south-1_4GFtB35OS")
_password = os.environ.get("DEMO_PASSWORD")

if not _password:
    print("Error: DEMO_PASSWORD env var not set")
    print("Usage: DEMO_PASSWORD=your-password python seed_users.py")
    sys.exit(1)


def seed_users():
    for email, role, name in DEMO_ACCOUNTS:
        try:
            _cognito.admin_create_user(
                UserPoolId=_pool_id,
                Username=email,
                TemporaryPassword=_password,
                UserAttributes=[
                    {"Name": "email", "Value": email},
                    {"Name": "email_verified", "Value": "true"},
                    {"Name": "name", "Value": name},
                    {"Name": "custom:role", "Value": role},
                ],
                MessageAction="SUPPRESS",
            )
            _cognito.admin_set_user_password(
                UserPoolId=_pool_id,
                Username=email,
                Password=_password,
                Permanent=True,
            )
            print(f"✓ {email:<25} role={role:<10} password={_password}")
        except _cognito.exceptions.UsernameExistsException:
            print(f"⚠ {email:<25} already exists")
        except Exception as e:
            print(f"✗ {email:<25} error: {e}")


if __name__ == "__main__":
    print(f"Seeding {len(DEMO_ACCOUNTS)} demo accounts to {_pool_id}...\n")
    seed_users()
    print("\n🎯 Ready to log in! Open the app and try any of the above.")

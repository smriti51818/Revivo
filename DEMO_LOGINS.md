# Demo Login Credentials

Use these accounts to test the app quickly after redeploying the infrastructure.

## Create the accounts

After running `cdk deploy --all`, set a password and seed:

```bash
cd /Users/smriti/Documents/Projects/Revivo/backend
source .venv/bin/activate

# Choose your own password (must be 8+ chars with uppercase + number)
DEMO_PASSWORD="YourPassword123" python scripts/seed_users.py
```

If it succeeds, you'll see:
```
✓ seller@revivo.demo       role=seller    password=YourPassword123
✓ hotel@revivo.demo        role=buyer     password=YourPassword123
✓ cook@revivo.demo         role=cook      password=YourPassword123
✓ volunteer@revivo.demo    role=volunteer password=YourPassword123
```

## Quick test flow

1. **Start app:** `flutter run`
2. **At role select:** Pick a role
3. **At login:** Enter the email + password you set above
4. **Instant login** (no email code needed — pre_signup trigger auto-confirms)
5. **Explore** — create/order, see live data

## Accounts at a glance

| Email | Role | What to test |
|-------|------|---|
| `seller@revivo.demo` | Seller | Publish listings, view orders, upload photos |
| `hotel@revivo.demo` | Buyer (Hotel) | Browse market, place orders, watch status advance |
| `cook@revivo.demo` | Cook/NGO | Accept rescues, pickup, mark delivered |
| `volunteer@revivo.demo` | Volunteer | View pickup tasks |

## Reset if needed

If something breaks, you can re-run the seed script with the same password to overwrite them with fresh accounts.

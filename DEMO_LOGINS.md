# Demo Login Credentials

The app ships pointed at the live AWS backend (`useLiveApi: true`), so log in
with the seeded demo accounts below. Login is instant — the `pre_signup`
Lambda auto-confirms, so no email code is needed.

## Accounts

| Email | Role | Display name | What to test |
|-------|------|--------------|--------------|
| `seller@revivo.demo` | Seller | **GreenLeaf Farms** | Dashboard inventory, waste-risk insight, incoming orders (accept / advance / reject), AI insights, publish a listing (Rekognition auto-identify) |
| `hotel@revivo.demo` | Buyer (Hotel) | **Hotel Ashok** | Browse the marketplace, place an order, watch the Step Functions status advance, rate & review, Impact + Rescue network |

Password for both: **`TestPass123`**

## (Re)create the accounts + data

After `cdk deploy --all` (or to reset the demo), from `backend/` with `.venv` active:

```bash
DEMO_PASSWORD='TestPass123' python scripts/seed_users.py   # 2 accounts, friendly names
python scripts/seed_listings.py                            # 6-vendor marketplace
python scripts/seed_rescues.py                             # rescue board + delivered history
python scripts/seed_orders.py                              # order history + live incoming
```

## Golden path (for the demo)

1. **Seller (GreenLeaf Farms)** — open Insights: see the **waste-risk projection**
   ("N kg reaches Rescue within 24h") and **Bedrock-generated recommendations**.
2. **Buyer (Hotel Ashok)** — the marketplace shows 6 vendors with live freshness
   bands + auto-decayed prices. Place an order on a Rescue-band deal.
3. Back on **Seller** — the new order appears in Incoming; Accept → the
   **Step Functions** lifecycle advances it (Preparing → Ready → Completed).
4. **Buyer** — track the order, then rate it; see the **Impact** dashboard and
   the **Rescue network** (surplus → NGO, with a live "why rescue this?" from
   Bedrock).

> Note: the cook/NGO login was removed — the rescue lifecycle is shown read-only
> in-app. Only the two accounts above exist.

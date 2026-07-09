# Revivo — Architecture

> Companion to the diagram at [`architecture.svg`](architecture.svg). Revivo is a
> serverless, event-driven system on AWS. Two flows matter most: the vendor
> listing pipeline (photo → AI → live marketplace) and the order lifecycle
> (placed → prepared → ready → completed), which runs on Step Functions with
> zero polling from the client.

## 1. Request lifecycles

**Sell (list surplus):**
```
Flutter → presigned S3 PUT (upload) → Rekognition DetectLabels (identify_vegetable)
       → analyze_listing (freshness band + market/recommended price)
       → create_listing → DynamoDB write (GSI2 STATUS#ACTIVE)
       → live on the buyer marketplace
```
Freshness is **recomputed on every read**, not on a timer: `apply_live_freshness()`
takes the immutable `purchasedAt` + shelf-life inputs and derives the current
band + decayed price from wall-clock time. This is why the countdown and price
move in real time on both the seller and buyer screens without a backend push.

**Buy (order lifecycle):**
```
Flutter → create_order (atomic stock decrement, price snapshotted from the
       live listing) → DynamoDB Streams (INSERT ORDER)
       ├─→ start_order_workflow → Step Functions: CONFIRMED → PREPARING
       │        (wait 15s) → READY_FOR_PICKUP (wait 15s) → COMPLETED (wait 15s)
       └─→ notify → in-app notification for the seller + SNS publish
Buyer polls GET /orders every 8s → sees status advance live, no manual refresh
```

**Rescue (read-only network, surplus → NGO):**
```
create_rescue (OFFERED) → GET /rescues (rescue board)
       → transition_rescue (OFFERED → ACCEPTED → ASSIGNED → PICKED_UP → DELIVERED,
         conditional update — 409 on a stale transition)
       → explain_rescue: Bedrock (Amazon Nova, Converse API) writes a 2-sentence
         "why rescue this" grounded in quantity/band/window; deterministic
         fallback if Bedrock is unavailable
```

**AI insights (seller):**
```
GET /listings/insights?period=week|month|year
   → aggregate_seller_insights(): filters the seller's real orders to that
     window, computes revenue/movers/band-mix/earnings time-series/impact
   → Bedrock (Nova) Converse: 3 recommendations grounded in those numbers
     (source="ai"); deterministic, still data-grounded fallback if Bedrock
     errors (source="fallback")
   → client also derives a forward-looking waste-risk projection from the
     seller's live listings (no AI needed — it's a pure function of the
     existing freshness countdown)
```

## 2. Data model — DynamoDB single table (`RevivoTable`)

| Entity | PK | SK | Access pattern |
|--------|----|----|----|
| User (Cognito-linked) | — | — | `custom:role` on the JWT; no separate profile item required for auth |
| Listing | `LISTING#<id>` | `META` | GSI1 `VENDOR#<id>` (seller's own); GSI2 `STATUS#ACTIVE` (marketplace) |
| Order | `ORDER#<id>` | `META` | GSI1 `BUYER#<id>` (buyer's orders); GSI3 `VENDOR#<id>` (seller's incoming) |
| Rescue | `RESCUE#<id>` | `META` | GSI2 `RESCUE#BOARD` (the board) |
| Notification | `NOTIF#<id>` | `META` | GSI1 `USER#<id>` (per-user feed, unread count) |

DynamoDB Streams (single stream, two independent consumers — the order-workflow
starter and the notifier) drive everything event-based downstream of a write.
No cron, no EventBridge — every side effect traces back to an actual write.

## 3. Security

- **Auth** — Amazon Cognito, JWT with `custom:role` custom attribute (zero-code
  role-based access — the same API routes serve both roles, scoped by the
  authenticated `sub`).
- **API authorization** — API Gateway's Cognito authorizer rejects unauthorized
  calls before a Lambda ever runs; `/health` is the only public route.
- **Uploads** — S3 presigned PUT URLs (short-lived, single-use).
- **Encryption** — DynamoDB at rest, S3 SSE-S3, TLS in transit.
- **Ownership checks** — every mutation (`update_listing`, `rate_order`,
  `transition_rescue`) verifies the caller's `sub` owns the resource before
  writing; stock decrements use a DynamoDB conditional expression so two
  concurrent buyers can never over-sell the same listing.

## 4. Resilience

- DynamoDB Streams consumers retry on failure (`retry_attempts=2`) before the
  record is dropped — a transient Lambda error doesn't silently lose a
  notification or a workflow start.
- Step Functions is a **Standard** state machine — each execution is durable
  and resumable; a Lambda cold start mid-flow doesn't lose the order's place.
- `transition_rescue` and stock decrements use DynamoDB conditional writes, so
  a stale client request gets a clean 409 instead of corrupting state.
- Bedrock calls (`seller_insights`, `explain_rescue`) are wrapped so any
  failure (no model access, throttling, network) degrades to a deterministic,
  still data-grounded response — the feature never hard-fails.

## 5. What's intentionally out of scope for the pilot

EventBridge-driven recalculation, SMS delivery, and a dedicated cook/volunteer
login are **not** part of the deployed system — freshness recalculates on
read (cheaper and simpler than a timer), and the rescue network is currently
surfaced read-only inside the same two-role app. See the README's
**Future scope** section for what a wider pilot would add.

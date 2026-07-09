# Revivo — Demo script (90 seconds)

> Goal: show the full **Sell → live marketplace → Order → Step Functions
> lifecycle → Impact** loop on the live AWS backend, with the Step Functions
> console visible for the order advancing in real time.

## Setup before demo
- [ ] Backend deployed (`make infra-deploy`) — already live at
      `https://j5aq1g1vbd.execute-api.ap-south-1.amazonaws.com/prod`.
- [ ] Demo data seeded (see [`DEMO_LOGINS.md`](../DEMO_LOGINS.md)).
- [ ] Step Functions console open on `revivo-order-lifecycle`.
- [ ] Two devices/windows: **GreenLeaf Farms** (seller) and **Hotel Ashok**
      (buyer), both logged in with password `TestPass123`.

## Narrative

1. **Seller — Insights.** Open GreenLeaf Farms' Insights tab. Point out the
   **waste-risk projection** ("N kg reaches Rescue within 24h") computed live
   from the seller's actual listings, and the **3 Bedrock-generated
   recommendations** (Amazon Nova, grounded in this seller's real revenue,
   top movers, and freshness mix — not canned copy).

2. **Buyer — Marketplace.** Switch to Hotel Ashok. The marketplace shows 6
   vendors with **live freshness bands and prices that are decaying in real
   time** (same formula, computed independently on the client and re-verified
   server-side at order time — the price you see is the price you pay).
   Place an order on a listing in the Use Soon or Rescue band.

3. **Watch Step Functions.** Switch to the AWS console. The new `ORDER` item
   triggers `start_order_workflow` off DynamoDB Streams — a fresh execution
   appears in `revivo-order-lifecycle` and advances **Confirmed → Preparing →
   Ready for Pickup → Completed** over ~45 seconds, no polling or manual
   trigger. Back in the buyer app, **My Orders** reflects each stage live
   (8s poll).

4. **Rate & Impact.** Once Completed, rate the order. Open **Impact** — kg
   rescued, meals, CO₂ avoided, ₹ saved, and the leaderboard update from real
   aggregated order + rescue data.

5. **Rescue network (read-only).** Open the Rescue board — surplus routed to
   an NGO kitchen, each card carrying a **Bedrock-written explanation** of why
   it should be rescued now (quantity, freshness window, meal estimate), with
   a deterministic fallback if Bedrock is momentarily unavailable.

> *One seller. One order. Cart to Step-Functions-tracked completion in under
> a minute — every number on screen is real.*

## Talking points for judges
- **Why AWS:** DynamoDB Streams is the single source of truth for "something
  changed" — it fans out to two independent consumers (order-workflow starter,
  notifier) with no polling anywhere in the backend. Step Functions makes the
  order lifecycle durable and visible, not a hidden state field. Bedrock
  (Amazon Nova via the Converse API) grounds every AI response in that
  specific seller's or rescue's real numbers, and degrades to a deterministic,
  still-useful fallback if the model call fails — the feature never breaks
  the demo.
- **Honesty:** Rekognition identifies the vegetable from the photo; it does
  not claim to assess freshness. Freshness bands come from a validated
  shelf-life + storage-condition model, recomputed live from wall-clock time,
  not a fabricated percentage.

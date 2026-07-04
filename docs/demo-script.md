# Revivo — Demo script (90 seconds)

> Goal: show the full **Sell → Rescue → Transform** loop with the AWS Step Functions
> console visible and an SMS arriving on a physical phone.

## Setup before demo
- [ ] Backend deployed (`make infra-deploy`) and seeded (`make seed`).
- [ ] Step Functions console open on the listing state machine.
- [ ] Impact dashboard open on a second screen.
- [ ] A real phone ready to receive the rescue SMS.
- [ ] Logged in as **Rajesh (vendor)**, **Hotel Annapoorna (buyer)**, **Shiva Temple (cook)**.

## Narrative

1. **6:30 PM — Sell.** Rajesh finishes his day at Gandhipuram Market with 15 kg unsold tomatoes.
   He opens Revivo, snaps a photo. The app timestamps + GPS-tags + compresses + uploads to S3 in
   under a second. Rekognition: *tomatoes, no visible defects* → green trust badge. Freshness band:
   **Good (~14–18h)**. Price: ₹25/kg. **Listing live.**

2. **Watch Step Functions.** The listing enters **ACTIVE**. DynamoDB Streams trigger the matching
   Lambda. Within 3 seconds, Hotel Annapoorna (1.2 km, bought tomatoes yesterday, rated 4.8) gets a
   push notification. One tap → 10 kg ordered → kitchen helper dispatched.

3. **Escalation.** Listing moves to **DISCOUNTED** — 5 kg remaining, Use Soon band, price drops to
   ₹18. Notification radius expands. No buyer bites.

4. **9 PM — Rescue.** Band shifts to **Rescue**; sale probability 8%. Step Functions transitions to
   **RESCUE**. The rescue engine matches Shiva Temple kitchen (1.5 km, morning annadanam prep,
   reliability 4.9). Bedrock writes the explanation. **An SMS lands on the phone on stage.**

5. **Transform.** Cook replies *YES*. NSS volunteer picks up by 9:30 PM. Next morning the tomatoes
   are sambar for 60 people. Rajesh's impact card updates: **₹250 recovered · 15 kg saved · 60 meals
   enabled**, and he climbs to #3 on the Gandhipuram leaderboard.

> *One vendor. One evening. One vegetable. From cart to plate in three hours.*

## Talking points for judges
- **Why AWS:** the vegetable's lifecycle *is* an event-driven state machine — Streams, Step
  Functions, EventBridge, Bedrock, presigned S3, Cognito. Remove AWS and you lose the architecture.
- **Honesty:** Rekognition screens visible defects, it does **not** assess freshness — that's why we
  show bands, not fake percentages.

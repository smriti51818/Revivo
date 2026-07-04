# Revivo — Architecture

> Companion to the diagram at [`architecture.png`](architecture.png). Revivo is a low-latency,
> event-driven, fully serverless system. Every decision optimizes the vendor listing flow
> (< 3s end-to-end) and real-time buyer notification (< 5s listing → delivery).

## 1. Request lifecycle (the golden path)

```
Flutter → presigned S3 upload → Rekognition (async) → create_listing Lambda
       → DynamoDB write (Streams) → Step Functions start + match_buyers Lambda
       → SNS push → Buyer
```

Escalation (autonomous rescue):

```
EventBridge (every 10 min) → recalc_freshness Lambda → band = Rescue
       → Step Functions RESCUE state → rescue_engine (matching filters)
       → Bedrock explain → SNS SMS → Cook  (SQS DLQ on failure)
```

## 2. Performance budget

| User action | Target | How |
|-------------|--------|-----|
| Photo upload + Rekognition ID | < 2 s | Image compressed < 500 KB on device; S3 presigned upload bypasses API Gateway |
| Freshness calc + price | < 500 ms | Shelf-life DB cached in Lambda warm memory; simple arithmetic |
| Listing goes live | < 1 s | DynamoDB single-digit ms write; Streams trigger matching |
| Buyer notification | < 3 s | Streams → matching Lambda → SNS in parallel, no polling |
| Rescue trigger | < 10 s | EventBridge rule batch-processes Rescue-band listings |
| Impact dashboard | < 1 s | Pre-aggregated metrics + CloudWatch counters |

## 3. Data model — DynamoDB single table (`RevivoTable`)

| Entity | PK | SK | Access pattern |
|--------|----|----|----------------|
| User | `USER#<id>` | `PROFILE` | GSI1 `ROLE#<role>` |
| Listing | `LISTING#<id>` | `META` | GSI2 `STATUS#ACTIVE` (+geo bucket); **TTL** = freshness expiry |
| Order | `LISTING#<id>` | `ORDER#<id>` | GSI3 `BUYER#<id>` |
| Rescue | `LISTING#<id>` | `RESCUE#<id>` | GSI `COOK#<id>` |
| Impact | `IMPACT#<userId>` | `<period>` | pre-aggregated |
| Cache | `CACHE#SHELFLIFE` | `<veg>` | Lambda warm memory |

Streams on the table drive matching + lifecycle. TTL is the "live countdown" primitive.

## 4. Security (zero-code at the edge)

- **Auth** — Cognito JWT, role-based (`custom:role`), 1h token expiry + refresh.
- **API authorization** — API Gateway Cognito authorizer rejects unauthorized calls before Lambda.
- **Uploads** — S3 presigned URLs (5-min expiry, single-use, scoped to vendor folder).
- **Encryption** — DynamoDB at rest, S3 SSE-S3, TLS 1.2 in transit.
- **Photo integrity** — server validates timestamp (< 10 min) + GPS (< 500 m from registered spot).
- **Input validation** — Lambda sanitization; quantity/date/length caps.
- **Rate limiting** — API Gateway throttling (10 listings/h vendors, 50 req/min buyers).

## 5. Resilience

- DynamoDB Streams retry failed matching (3× backoff) — no listing silently lost.
- Step Functions catch/retry at every transition; failures move to `EXPIRED`, never limbo.
- SNS failures route to SQS DLQ; system falls back to the next receiver.
- Idempotent Lambdas + DynamoDB conditional writes prevent duplicates on retries.

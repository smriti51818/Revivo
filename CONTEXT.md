# Revivo — Complete Project Context

> **AWS SDG-2 Hackathon 2026 (#include 1.0) · Team Neura**  
> Smriti T M (Lead), Pooja S, Thaenmozhi A  
> Track: SDG-2 Zero Hunger · Goal: Top 10 of 450 teams  
> Build started: 2026-07-04 · Working branch: `develop`  
> Current HEAD commit: `f2524b0`

> **⚠️ READ THIS FIRST:** Sections 1–13 describe the stable foundation and are current.
> Sections 14–19 describe Phase 1 and were written when Phases 2–4 were still pending.
> **Phases 2–4 have since been built on the buyer/hotel side.** The authoritative
> "current state" is **Section 20** at the bottom — read it for what actually exists
> today, what's still thin (seller & cook), and what to build next.

---

## 1. What Revivo Is

A **Time-Aware Food Recovery Network**. Every surplus vegetable batch is a decaying asset with a live countdown. The system auto-escalates through three stages:

```
SELL ──► RESCUE ──► TRANSFORM (Community Cooking Circles)
 ↑          ↑            ↑
 Fresh     Urgent     NGO/Cook
```

The auto-escalation based on real-time freshness bands is the **core differentiator** vs Too Good To Go / OLIO / Ninjacart. Price decays in real time — what the buyer sees on the countdown is exactly what they are charged.

**Three active roles (Volunteer was removed):**
- **Seller** — vegetable vendor or hotel listing surplus
- **Buyer** — hotel/restaurant buying surplus at discounted live price
- **Cook/NGO** — rescues near-expiry batches, drives them to delivery

---

## 2. Tech Stack (Non-Negotiable — Locked by Spec)

| Layer | Tech | Details |
|---|---|---|
| Mobile | Flutter 3.44 / Dart 3.12 | `sdk: ^3.12.0`, `version: 0.1.0+1` |
| State management | Flutter Riverpod `^2.6.1` | Notifier, AsyncNotifier, Provider |
| Routing | GoRouter `^14.6.2` | StatefulShellRoute per role |
| Media capture | image_picker `^1.1.2` | Camera only (gallery disabled) |
| HTTP | http `^1.2.2` | No native SDK |
| Utilities | intl `^0.19.0`, url_launcher `^6.3.1` | formatters, maps/tel links |
| Backend compute | AWS Lambda Python 3.12 | One function per folder |
| API | AWS API Gateway REST | Cognito JWT authorizer, stage: `prod` |
| Database | DynamoDB single-table | `RevivoTable`, PAY_PER_REQUEST, Streams NEW_AND_OLD_IMAGES, TTL on `ttl` field |
| Auth | AWS Cognito | `custom:role` attribute, USER_PASSWORD_AUTH + SRP |
| Storage | S3 | Presigned PUT/GET, 7-day lifecycle, AES-256, BLOCK_ALL public access |
| AI — produce ID | Amazon Rekognition | `DetectLabels` → vegetable name |
| AI — insights | Amazon Bedrock | Nova Micro `apac.amazon.nova-micro-v1:0`, Converse API |
| AI — rescue explain | Amazon Bedrock | Same model/API |
| Order lifecycle | AWS Step Functions | Standard, 15s/stage (45s total), 15min timeout |
| Notifications | SNS `revivo-notifications` + Lambda | DynamoDB Streams consumer |
| Infra-as-code | AWS CDK Python | 5 stacks |
| Linting | ruff | Backend |
| Testing | pytest (backend), flutter test (app) | 56 + 11 tests |

**Why Nova, not Claude:**  
Claude 3 Haiku requires an AWS Marketplace subscription that cannot be granted to a Lambda IAM role via policy. Amazon Nova needs no opt-in. IAM grants `bedrock:InvokeModel` + `bedrock:Converse` on `arn:aws:bedrock:*::foundation-model/*` and `arn:aws:bedrock:*:*:inference-profile/*`.

---

## 3. Live AWS Environment

| Resource | Value |
|---|---|
| Region | `ap-south-1` |
| Account ID | `138430391721` |
| API Gateway URL | `https://j5aq1g1vbd.execute-api.ap-south-1.amazonaws.com/prod` |
| API throttle | 50 RPS / burst 20 |
| Cognito User Pool ID | `ap-south-1_4GFtB35OS` |
| Cognito App Client ID | `4hi9r9pue4h1qpeuc9enp60553` |
| Bedrock model ID | `apac.amazon.nova-micro-v1:0` |
| DynamoDB table | `RevivoTable` |
| SNS topic | `revivo-notifications` |
| Step Functions SM | `revivo-order-lifecycle` |
| S3 lifecycle | 7 days (images expire — re-seed if needed) |

**Demo credentials (password: `TestPass123` for all)**
```
seller@revivo.demo  →  Seller role
hotel@revivo.demo   →  Buyer role
cook@revivo.demo    →  Cook/NGO role
```

**5 CDK Stacks:**

| Stack | Constructs |
|---|---|
| `Revivo-Data` | DynamoDB `RevivoTable` (GSI1/2/3, Streams, TTL), S3 `UploadsBucket` (CORS, 7-day lifecycle) |
| `Revivo-Auth` | Cognito UserPool (`revivo-users`, `custom:role`), AppClient, `PreSignupFn` (auto-confirms) |
| `Revivo-Api` | All 21 Lambda functions + REST API + Cognito authorizer |
| `Revivo-Workflow` | Step Functions `revivo-order-lifecycle` + `StartOrderWorkflowFn` (DynamoDB Streams trigger) |
| `Revivo-Notify` | SNS `revivo-notifications` + `NotifierFn` (DynamoDB Streams trigger) |

**Deploy commands:**
```bash
cd infra && source .venv/bin/activate
npx aws-cdk@2 deploy --all --require-approval never

# Seed demo data (after deploy):
cd backend && source .venv/bin/activate
PYTHONPATH="$PWD" python scripts/seed_listings.py
PYTHONPATH="$PWD" python scripts/seed_rescues.py
```

---

## 4. Repository Layout

```
Revivo/
├── app/
│   ├── lib/
│   │   ├── core/
│   │   │   ├── api/             api_client.dart, json_utils.dart, providers.dart
│   │   │   ├── auth/            cognito_service.dart
│   │   │   ├── config/          app_config.dart
│   │   │   ├── freshness/       freshness_estimator.dart, live_clock.dart
│   │   │   ├── models/          freshness.dart, user_role.dart
│   │   │   ├── router/          app_router.dart
│   │   │   ├── session/         session_controller.dart
│   │   │   ├── theme/           app_colors.dart, app_spacing.dart, app_theme.dart
│   │   │   ├── widgets/         app_card, band_chip, freshness_countdown,
│   │   │   │                    primary_button, produce_image, scaffold_with_nav_bar,
│   │   │   │                    section_header, stat_tile, status_chip
│   │   │   └── format.dart
│   │   └── features/
│   │       ├── auth/            splash, login, register, role_select, confirm_code
│   │       ├── buyer/           market, product, cart, checkout, order_confirmed,
│   │       │                    order_tracking, my_orders + domain/data/application/widgets
│   │       ├── seller/          dashboard, orders, add_listing, insights
│   │       │                    + domain/data/application/widgets
│   │       ├── cook/            cook_inbox_screen.dart
│   │       ├── rescue/          domain/data/application/widgets
│   │       ├── impact/          impact_screen + domain/data/application
│   │       ├── notifications/   domain/data/application/widgets
│   │       └── shared/          profile_screen.dart
│   ├── test/
│   │   ├── live_clock_test.dart   (7 tests)
│   │   └── cart_test.dart         (4 tests)
│   └── pubspec.yaml
├── backend/
│   ├── functions/               (one folder per Lambda)
│   ├── shared/                  (Lambda layer code)
│   ├── tests/                   (pytest, 56 tests)
│   └── scripts/                 seed_listings.py, seed_rescues.py, seed_users.py
├── infra/
│   ├── stacks/                  data, auth, api, workflow, notification, shared_layer
│   └── app.py
├── docs/
├── seed/
├── CONTEXT.md                   ← this file
├── README.md
├── DEMO_LOGINS.md
└── Makefile
```

---

## 5. Complete API Surface (All Routes Live)

| Method | Path | Lambda | Auth | Notes |
|---|---|---|---|---|
| GET | `/health` | `health` | Public | |
| GET | `/me` | `whoami` | JWT | Returns user claims |
| POST | `/uploads` | `create_upload_url` | JWT | Presigned S3 PUT |
| POST | `/listings` | `create_listing` | JWT | Seller only |
| GET | `/listings` | `list_listings` | JWT | All active (GSI2) + `apply_live_freshness` |
| GET | `/listings/mine` | `list_my_listings` | JWT | Seller's own (GSI1) + live freshness |
| POST | `/listings/analyze` | `analyze_listing` | JWT | Returns `marketPrice` + `recommendedPrice` + band |
| POST | `/listings/identify` | `identify_vegetable` | JWT | Rekognition DetectLabels → veg name |
| GET | `/listings/insights` | `seller_insights` | JWT | Real metrics + Bedrock/Nova AI recs |
| PATCH | `/listings/{listingId}` | `update_listing` | JWT | Owner-only stock update; 0→SOLD |
| POST | `/orders` | `create_order` | JWT | FCFS atomic stock reserve + live price charge |
| GET | `/orders` | `list_my_orders` | JWT | Buyer's orders (GSI1) |
| GET | `/orders/incoming` | `list_vendor_orders` | JWT | Seller's incoming orders (GSI3) |
| POST | `/orders/{orderId}/rate` | `rate_order` | JWT | Owner-only, 1–5 stars + tags + comment |
| POST | `/rescues` | `create_rescue` | JWT | New rescue offer |
| GET | `/rescues` | `list_rescues` | JWT | Rescue board (GSI2 RESCUE#BOARD) |
| POST | `/rescues/{rescueId}` | `transition_rescue` | JWT | ACCEPT/CLAIM/PICKUP/DELIVER lifecycle |
| POST | `/rescues/{rescueId}/explain` | `explain_rescue` | JWT | Bedrock AI "why rescue this?" |
| GET | `/impact` | `impact` | JWT | Aggregated kg/meals/CO₂/leaderboard |
| GET | `/notifications` | `list_notifications` | JWT | In-app feed (GSI1 USER#sub) |
| POST | `/notifications/read` | `mark_notifications_read` | JWT | Mark-read (uses `#r` alias for reserved `read`) |

---

## 6. DynamoDB Single-Table Design

**Table name:** `RevivoTable`  
**Billing:** PAY_PER_REQUEST  
**Streams:** NEW_AND_OLD_IMAGES (consumed by WorkflowStack + NotificationStack)  
**TTL:** `ttl` attribute (set to `expiryEpoch` on listings — auto-deletes expired rows)

**Key pattern:** `PK` (STRING) + `SK` (STRING, always `"META"` for entity root items)

| Entity | PK | SK | GSI1PK | GSI1SK | GSI2PK | GSI2SK | GSI3PK | GSI3SK |
|---|---|---|---|---|---|---|---|---|
| Listing | `LISTING#{id}` | `META` | `VENDOR#{sub}` | `LISTING#{ts}#{id}` | `STATUS#ACTIVE` | `{expiryEpoch}#{id}` | — | — |
| Order | `ORDER#{id}` | `META` | `BUYER#{sub}` | `ORDER#{ts}#{id}` | — | — | `VENDOR#{sub}` | `ORDER#{ts}#{id}` |
| Rescue | `RESCUE#{id}` | `META` | — | — | `RESCUE#BOARD` | `{ts}#{id}` | — | — |
| Notification | `NOTIF#{id}` | `META` | `USER#{sub}` | `NOTIF#{ts}#{id}` | — | — | — | — |

**Access patterns:**
- `GET /listings` → GSI2 query `STATUS#ACTIVE` (sorted by expiryEpoch)
- `GET /listings/mine` → GSI1 query `VENDOR#{sub}`
- `GET /orders` → GSI1 query `BUYER#{sub}`
- `GET /orders/incoming` → GSI3 query `VENDOR#{sub}`
- `GET /rescues` → GSI2 query `RESCUE#BOARD`
- `GET /notifications` → GSI1 query `USER#{sub}`

**Critical gotcha — reserved words:**
- `rating` is a DynamoDB reserved word → always alias as `ExpressionAttributeNames={"#r": "rating"}` in any UpdateExpression
- `status` is a DynamoDB reserved word → aliased as `#s` in the Step Functions state machine UpdateExpression
- `read` is a DynamoDB reserved word → aliased as `#r` in `mark_notifications_read`

---

## 7. Shared Backend Layer (`backend/shared/`)

Every Lambda in `Revivo-Api` uses a shared Lambda layer containing this code.

### `freshness.py`
Core of the time-aware engine.

```python
# Band thresholds (remaining/total ratio)
_GOOD_MIN = 0.50
_USE_SOON_MIN = 0.20
_PRICE_FACTOR = {"GOOD": 1.0, "USE_SOON": 0.7, "RESCUE": 0.4}

def estimate_freshness(vegetable, purchased_at_epoch, storage="ROOM", temp_c=28.0, now_epoch=None) -> FreshnessResult
def apply_live_freshness(listing: dict, now: int | None = None) -> dict
```

`apply_live_freshness()` — takes a stored listing dict, recomputes `band`, `timeRange`, `remainingHours`, `totalHours`, `priceFactor`, `recommendedPrice` (Decimal), `expiryEpoch` from immutable inputs (`vegetable`, `purchasedAt`, `storage`, `tempC`). Returns listing unchanged if inputs missing (for legacy/seed rows). Called in `list_listings`, `list_my_listings`, and `create_order`.

### `shelf_life.py`
20 vegetables with base shelf hours at room temp (Coimbatore ambient), plus storage multipliers and temperature factor.

```python
# Storage multipliers
STORAGE_MULTIPLIER = {"ROOM": 1.0, "REFRIGERATED": 2.5, "COLD_STORAGE": 3.5}

# Temperature factor: 1.0 - (temp_c - 25.0) * 0.03, clamped [0.4, 1.4]

# Selected base hours (all 20 are defined)
"spinach": 36, "coriander": 36, "mint": 36
"tomato": 96, "okra": 72, "drumstick": 96
"potato": 480, "onion": 720, "pumpkin": 720
DEFAULT_SHELF_LIFE_HOURS = 96.0
```

### `market_prices.py`
INR/kg reference prices for all 20 vegetables.

```python
# Examples:
"tomato": 40, "potato": 30, "onion": 35, "bell_pepper": 80,
"drumstick": 70, "okra": 50, "beans": 60, "green_chilli": 60
DEFAULT_MARKET_PRICE = 40.0
```

Sellers never enter a price — `validate_listing_input()` derives `basePrice` from `market_price(vegetable)`.

### `models.py`
Pure domain item builders and public projections.

**`build_listing_item(data, vendor, freshness, now)`**
- Stores `GPS: {lat, lng}` if `data.get("gps")` is present (schema already supports location)
- GSI2SK sorts by `expiryEpoch#{id}` so the active feed is naturally ordered by urgency

**`to_public_listing(item)`**  
Projects: `id, vegetable, vendorId, vendorName, quantityKg, band, timeRange, basePrice, recommendedPrice, priceFactor, storage, imageKey, imageUrl, createdAt, purchasedAt, expiryEpoch, totalHours, status` + optional `gps`

**`build_order_item(data, buyer, listing, now)`**  
Snapshots `pricePerKg = listing.recommendedPrice` (the live-freshness-decayed price), `marketPricePerKg = listing.basePrice`, computes `total = qty × pricePerKg`. Order is immutable after creation.

**`to_public_order(item)`**  
Projects: `id, buyerName, vendorName, vegetable, listingId, band, quantityKg, pricePerKg, marketPricePerKg, total, status, pickupSlot, paymentMethod, rating, ratingTags, ratingComment, createdAt`

**`RESCUE_TRANSITIONS`** — validated lifecycle map:
```python
{
  "ACCEPT":  ("OFFERED",   "ACCEPTED"),
  "CLAIM":   ("ACCEPTED",  "ASSIGNED"),
  "PICKUP":  ("ASSIGNED",  "PICKED_UP"),
  "DELIVER": ("PICKED_UP", "DELIVERED"),
}
```

**`aggregate_impact(items)`**  
Aggregates from raw table items (type=RESCUE + type=ORDER).  
Constants: `_MEALS_PER_KG = 1/0.4 = 2.5`, `_CO2_PER_KG = 2.5`, `_MEALS_GOAL = 5000`  
Leaderboard: top 5 by kg, ranked. NGO name only appears if DELIVERED.

### `validation.py`
All input limits (enforced before any DynamoDB write):

| Field | Limits |
|---|---|
| `vegetable` | required, ≤50 chars |
| `quantityKg` | 0.1–1000 |
| `basePrice` | 1–100000 (or auto-derived from market_prices) |
| `storage` | ROOM / REFRIGERATED / COLD_STORAGE |
| `purchasedAt` | epoch, not future, not >30 days old |
| `tempC` | -10 to 60 |
| `gps.lat` | -90 to 90 |
| `gps.lng` | -180 to 180 |
| `imageKey` | ≤200 chars |
| `pickupSlot` | ≤40 chars |
| `paymentMethod` | UPI / CARD / WALLET / PICKUP (defaults to PICKUP) |
| `rating stars` | 1–5 integer |
| `rating tags` | list, max 6 items, each ≤24 chars |
| `rating comment` | ≤280 chars |
| `rescueAction` | ACCEPT / CLAIM / PICKUP / DELIVER |
| `ngoName` (ACCEPT) | required, ≤60 chars |

### `insights.py`
`build_insights_converse_args(agg)` → Bedrock Converse API kwargs dict: `{system: [{text}], messages: [{role, content:[{text}]}], inferenceConfig: {maxTokens: 600}}`

### `rescue_ai.py`
`build_explain_converse_args(rescue_data)` → same Converse API kwargs structure.  
`fallback_explanation(rescue_data)` → deterministic text (always safe, even if Bedrock fails).

### Other shared files

| File | Purpose |
|---|---|
| `vegetables.py` | Rekognition label strings → Revivo vegetable key (tolerant matching) |
| `notifications.py` | `notifications_from_records(stream_records)` → list of notification items to write. INSERT ORDER → notifies seller. INSERT RESCUE → broadcasts to rescue network. |
| `streams.py` | `order_ids_from_records(records)` → filters DynamoDB stream records for INSERT + type=ORDER only (prevents re-trigger loop on the step function's own status updates) |
| `responses.py` | `ok(status, body)`, `error(status, msg)` with `DecimalEncoder` for DynamoDB Decimal values |
| `dynamo.py` | Boto3 DynamoDB resource singleton, `TABLE_NAME` from env |
| `ids.py` | `new_id(prefix)` — URL-safe random ID like `lst_abc123` |
| `uploads.py` | `generate_presigned_url(bucket, key, expiry=900)` for S3 PUT; `attach_image_url(item, bucket)` for GET |

---

## 8. CDK Stack Details

### Revivo-Data (`data_stack.py`)
- DynamoDB: PAY_PER_REQUEST, Streams NEW_AND_OLD_IMAGES, TTL=`ttl`, DESTROY on removal
- 3 GSIs: each GSI has `GSI{n}PK` + `GSI{n}SK` string keys
- S3: AES-256, BLOCK_ALL public, enforce SSL, 7-day lifecycle, CORS allows PUT/GET/POST from all origins, DESTROY + auto_delete_objects

### Revivo-Auth (`auth_stack.py`)
- UserPool: email sign-in, self-sign-up, auto-verify email
- `custom:role` attribute: mutable string, 1–20 chars
- Password policy: min 8, requires lowercase + digits
- App client: USER_PASSWORD_AUTH + SRP, `prevent_user_existence_errors=True`
- Client reads `email, email_verified, fullname, custom:role`; writes `email, fullname, custom:role`
- `PreSignupFn` trigger: auto-confirms user + email (no verification code in demo)

### Revivo-Api (`api_stack.py`)
- Shared layer injected into all functions that use `use_shared=True`
- All routes except `/health` are protected with `CognitoUserPoolsAuthorizer`
- CORS: ALL_ORIGINS, ALL_METHODS, DEFAULT_HEADERS
- Throttle: 50 RPS rate limit, 20 burst

### Revivo-Workflow (`workflow_stack.py`)
- Step Functions Standard machine: `revivo-order-lifecycle`
- Stages: Wait(15s) → SET status=PREPARING → Wait(15s) → SET status=READY_FOR_PICKUP → Wait(15s) → SET status=COMPLETED
- UpdateExpression uses `#s` alias for reserved word `status`
- `StartOrderWorkflowFn` Lambda: DynamoDB Streams trigger, batch=5, retries=2. Filters for INSERT records with `type==ORDER` only (via `streams.order_ids_from_records`)
- Machine timeout: 15 minutes

### Revivo-Notify (`notification_stack.py`)
- Second independent DynamoDB Streams consumer (alongside workflow starter)
- On INSERT ORDER → writes NOTIF item to table + publishes to SNS
- On INSERT RESCUE → publishes to SNS
- Both Streams triggers run independently; no coordination needed

---

## 9. Flutter App — Core Layer

### `app_config.dart`
```dart
AppConfig.current = AppConfig(
  region: 'ap-south-1',
  userPoolId: 'ap-south-1_4GFtB35OS',
  userPoolClientId: '4hi9r9pue4h1qpeuc9enp60553',
  apiBaseUrl: 'https://j5aq1g1vbd.execute-api.ap-south-1.amazonaws.com/prod',
  useLiveApi: true,
)
```
Set `useLiveApi: false` for fully offline in-memory mode — all repos fall back to `InMemory*` implementations.

### `cognito_service.dart`
- Pure HTTPS JSON API (`InitiateAuth` → USER_PASSWORD_AUTH)
- Always lowercases + trims email before sending (prevents case-sensitivity auth failures)
- Trims password before sending
- Decodes JWT ID token to extract `sub`, `email`, `name`, `custom:role`
- `AuthException(message, code)` for user-friendly errors
- `NeedsConfirmationException` thrown if account is unconfirmed (triggers `ConfirmCodeScreen`)

### `app_colors.dart` — Design tokens
```dart
primary = Color(0xFF1FBF61)          // Revivo green
primaryDark = Color(0xFF15A34E)
primarySurface = Color(0xFFE7F7EC)
background = Color(0xFFF5F6F5)
surface = Color(0xFFFFFFFF)
surfaceAlt = Color(0xFFF0F2F0)
border = Color(0xFFE7E9E7)
borderStrong = Color(0xFFD6DAD6)
textPrimary = Color(0xFF16191B)
textSecondary = Color(0xFF6B7280)
textMuted = Color(0xFF9AA0A6)
success = Color(0xFF1FBF61)
warning = Color(0xFFF59E0B)
danger = Color(0xFFEF4444)
info = Color(0xFF3B82F6)
successSurface = Color(0xFFE7F7EC)
warningSurface = Color(0xFFFDF3E2)
dangerSurface = Color(0xFFFDEAEA)
infoSurface = Color(0xFFE8F1FE)
```

### `app_spacing.dart` — Spacing & radius tokens
```dart
AppSpacing: xs=4, sm=8, md=12, lg=16, xl=20, xxl=24, xxxl=32, screen=16
AppRadius: sm=10, md=14, lg=20, pill=999
```

### `format.dart`
```dart
String formatMoney(double v)          // "₹40.00"
String formatKg(double v)             // "2.5 kg" or "500 g"
String formatCountdown(Duration d)    // "2d 3h", "4h 12m", "8m 30s", "Expired"
String formatCount(num v)             // "1,234" with locale separators
```

### `live_clock.dart`
```dart
class LiveClock {
  static double ratio({required DateTime expiresAt, required double totalHours, DateTime? now})
  static FreshnessBand band({...})
  // price = marketPrice × band.priceFactor, rounded to 2dp
  static double price({required double marketPrice, required DateTime expiresAt, required double totalHours, DateTime? now})
}
```
Mirrors backend thresholds exactly: ratio≥0.5→GOOD(×1.0), ≥0.2→USE_SOON(×0.7), <0.2→RESCUE(×0.4).

### `freshness.dart`
```dart
enum FreshnessBand { good, useSoon, rescue }
// Extensions:
static FreshnessBand fromRatio(double ratio) // mirrors backend _band_for
double get priceFactor                        // 1.0 / 0.7 / 0.4
String get label                              // "Good" / "Use Soon" / "Rescue"
```

### `freshness_countdown.dart`
```dart
// FreshnessTicker: StatefulWidget with Timer.periodic(1 second)
// Builder signature: Widget Function(BuildContext, Duration remaining, FreshnessBand band)
class FreshnessTicker { ... }

// FreshnessCountdownPill: colored pill (green/amber/red) with schedule or bolt icon
// bolt icon shown at RESCUE band
// showBandLabel flag: "Rescue · 1h 22m" vs just "1h 22m"
class FreshnessCountdownPill { bool showBandLabel = false }
```

### `app_router.dart` — Full route tree
```
/splash              → SplashScreen
/role                → RoleSelectScreen
/login               → LoginScreen(role: UserRole?)
/register            → RegisterScreen(role: UserRole?)
/confirm-code        → ConfirmCodeScreen(args: ConfirmCodeArgs)

/buyer/product       → ProductDetailsScreen(offer: Offer)     [full-page, back button]
/buyer/cart          → CartScreen
/buyer/checkout      → CheckoutScreen
/buyer/order-confirmed → OrderConfirmedScreen(orders: List<Order>)
/buyer/track         → OrderTrackingScreen(order: Order)

Seller shell (StatefulShellRoute, IndexedStack):
  /seller/dashboard  → SellerDashboardScreen    [tab 0: Dashboard]
  /seller/orders     → SellerOrdersScreen        [tab 1: Orders]
  /seller/add        → AddListingScreen          [tab 2: List]
  /seller/insights   → SellerInsightsScreen      [tab 3: Insights]
  /seller/profile    → ProfileScreen             [tab 4: Profile]

Buyer shell (StatefulShellRoute, IndexedStack):
  /buyer/home        → BuyerMarketScreen         [tab 0: Market]
  /buyer/orders      → BuyerOrdersScreen         [tab 1: Orders]
  /buyer/impact      → ImpactScreen              [tab 2: Impact]
  /buyer/profile     → ProfileScreen             [tab 3: Profile]

Cook shell (StatefulShellRoute, IndexedStack):
  /cook/inbox        → CookInboxScreen           [tab 0: Rescues]
  /cook/impact       → ImpactScreen              [tab 1: Impact]
  /cook/profile      → ProfileScreen             [tab 2: Profile]
```

---

## 10. Flutter App — Features In Detail

### Auth (`features/auth/`)

| Screen | What it does |
|---|---|
| `SplashScreen` | Checks session, redirects to role or shell |
| `RoleSelectScreen` | Pick Seller / Buyer (Hotel) / Cook |
| `LoginScreen` | EMAIL + password, Cognito auth, friendly errors |
| `RegisterScreen` | Name + email + password + chosen role; calls Cognito signUp |
| `ConfirmCodeScreen` | Email verification code entry; handles stuck UNCONFIRMED accounts; resend code |

### Buyer (`features/buyer/`)

**Domain models:**

`Offer`:
```dart
final String id, vendorName, vegetable;
final double availableKg, marketPrice, offerPrice, distanceKm;
final FreshnessBand band;
final String timeRange;
final bool organic;           // used by "Organic" filter
final String? imagePath, imageUrl;
final DateTime? expiresAt;    // absolute expiry epoch as DateTime
final double? totalHours;     // full shelf window hours
bool get hasClock             // true when expiresAt+totalHours present
bool isExpired([DateTime? now])
FreshnessBand liveBand([DateTime? now])
double livePrice([DateTime? now])
double liveSavingsPerKg([DateTime? now])
int liveSavingsPct([DateTime? now])
```

`Order`:
```dart
final String id, vendorName, vegetable, pickupSlot, paymentMethod;
final String? buyerName, imagePath;
final double quantityKg, pricePerKg, marketPricePerKg;
final FreshnessBand band;
final OrderStatus status;     // confirmed/preparing/readyForPickup/completed
final DateTime placedAt;
final int? rating;
final List<String> ratingTags;
final String ratingComment;
bool get isRated
double get total
double get saved
Order copyWith({OrderStatus? status})
```

`CartItem`:
```dart
final Offer offer;
final double quantityKg;
double get unitPrice   // offer.livePrice()
double get lineTotal   // quantityKg × unitPrice
double get lineSaved   // quantityKg × offer.liveSavingsPerKg()
```

`CartBill.of(items)`:
```dart
const double kPlatformFee = 8.0;
// platformFee = 0 if items is empty, else 8.0
// total = itemTotal + platformFee
```

**Providers:**
- `offersProvider` (AsyncNotifierProvider) — fetches all active listings
- `ordersProvider` (AsyncNotifierProvider) — `placeOrder()`, `rateOrder()`, `reload()` (silent re-fetch)
- `cartProvider` (NotifierProvider) — `add(offer)`, `setQuantity(offerId, qty)`, `remove(offerId)`, `clear()`
- `cartCountProvider` — total unique line count
- `cartBillProvider` — derived `CartBill` from current cart

**Screens:**

`BuyerMarketScreen`:
- Header: user name + "Coimbatore · surplus nearby" + cart badge (live count)
- Search: client-side filter on `vegetable` + `vendorName`, lowercased
- Filters: `_MarketFilter` enum — All / Rescue deals (band==rescue) / Organic (`offer.organic`) / Nearby (sorted by `distanceKm`)
- Pull-to-refresh via `ref.refresh(offersProvider.future)`
- Each `OfferCard` → `/buyer/product`

`ProductDetailsScreen`:
- Clock hero card: gradient, `FreshnessTicker` showing band label + countdown + "Drops to ₹X in ~Yh" (next band threshold)
- Uses `offer.livePrice()` everywhere (not stored `offerPrice`)
- `offer.liveSavingsPct()` savings badge
- Quantity stepper (0.1 kg steps)
- CTA: "Add to cart" → `cartProvider.notifier.add()`

`CartScreen`:
- Groups items by `vendorName`
- Each `_CartTile`: `FreshnessTicker` wrapping price, qty stepper (−/+), remove icon
- `_PickupNote` static reminder widget
- `BillSummary` at bottom (itemTotal, saved, ₹8 fee, grand total)
- "Go to checkout" bar → `/buyer/checkout`

`CheckoutScreen`:
- `PayMethod` enum: pickup('Pay on pickup', 'PICKUP'), upi('UPI', 'UPI'), card('Card', 'CARD'), wallet('Revivo Wallet', 'WALLET')
- 6 dynamic half-hour slot chips from next :00/:30 boundary
- Places one `POST /orders` per cart item sequentially
- On success: `cartProvider.notifier.clear()`, navigate to `/buyer/order-confirmed` with `List<Order>`

`OrderConfirmedScreen`: Shows each order line, combined total, pickup slot, savings banner.

`BuyerOrdersScreen`: Order list, each card tappable → `/buyer/track` with `extra: order`

`OrderTrackingScreen`:
- 4 stages: Placed (CONFIRMED) → Vendor Preparing (PREPARING) → Ready for Pickup (READY_FOR_PICKUP) → Completed (COMPLETED)
- `_TimelineRow` widget: done (filled circle + check), active (hollow circle + dot), todo (gray)
- Polls every 8s via `ordersProvider.notifier.reload()` (Timer.periodic, no loading flicker)
- Live-reads freshest order from `ordersProvider` state by ID; falls back to passed-in order until first poll
- Pickup card: slot, `vendorName + Coimbatore`, Directions (Google Maps search URL), Call (`tel:+919000000000`)
- Bill card: qty × price/kg, savings vs market, payment method label
- On `completed`: shows `ImpactReceipt` + `_ratingSection`
- `_ratingSection`: if rated → shows stars + tags; else → "Rate this rescue" → `showRateOrderSheet()`

**Widgets:**
- `OfferCard`: `FreshnessCountdownPill`, live savings badge `_LiveSavingsTag`, `ProduceImage`
- `BillSummary`: itemised (item total, savings in green, platform fee, grand total)
- `RateOrderSheet`: 5-star tap row, 5 `FilterChip` quick-tags (Fresh/On time/Great value/Good quality/Friendly), `TextField` comment (280 chars), submit button disabled until star selected
- `ImpactReceipt`: gradient card, money saved / meals (~2.5/kg) / CO₂ (~2.5 kg/kg), "Share impact" copies text to clipboard

### Seller (`features/seller/`)

**Domain models:**

`Listing`:
```dart
final String id, vegetable, timeRange;
final double quantityKg, basePrice, recommendedPrice;
final FreshnessBand band;
final StorageCondition storage;   // room / refrigerated / coldStorage
final DateTime createdAt;
final bool organic;
final String? imagePath, imageKey, imageUrl;
final DateTime? purchasedAt;
final double? tempC;
final DateTime? expiresAt;
final double? totalHours;
bool get isLowStock   // quantityKg <= 3
bool get hasClock
Listing copyWith({double? quantityKg})
```

`StorageCondition` enum: `room('ROOM')`, `refrigerated('REFRIGERATED')`, `coldStorage('COLD_STORAGE')`

`SellerInsightsData`:
```dart
int activeListings, orders;
double listedKg, soldKg, revenue;
int good, useSoon, rescue;   // listing counts by band
List<MoverRow> movers;       // top-selling vegetables
int? peakHour;               // hour of day with most orders (0–23)
List<InsightRec> recommendations;  // from Bedrock or fallback
bool aiPowered;              // true if Bedrock returned real recs
bool get hasActivity         // orders>0 || activeListings>0
```

**Providers:**
- `listingsProvider` (AsyncNotifier) — `addListing()`, `updateStock(id, qty)`, `uploadPhoto(path)`, `identify(imageKey)`, `analyze(...)`
- `sellerInsightsProvider` (FutureProvider) — fetches from `GET /listings/insights`
- `vendorOrdersProvider` — polls `GET /orders/incoming`, `reload()` method

**Screens:**

`SellerDashboardScreen`:
- Stats row: "Total listings" (live count) + "Sold today" (kg from today's orders)
- `NotificationBell` in header (with unread badge)
- Each `ListingCard` with `FreshnessCountdownPill` when `listing.hasClock`
- Tap "Update stock" or "Edit" → `_StockSheet` modal: qty stepper (−/+1), text input, "Save stock" + "Mark sold out" (→ qty=0)
- FAB → `/seller/add`

`AddListingScreen`:
- Camera-only capture via `image_picker` → upload to S3 immediately → `identify_vegetable` Rekognition auto-ID
- 20 vegetable options (`_vegetables` const list, same 20 as shelf_life.py)
- 8 purchase-time options (`_purchaseOptions`): Just now (0h) → A week ago (168h)
- Quick-qty chips: [2.0, 5.0, 10.0, 25.0, 50.0] kg; stepper for custom (0.1–500 kg)
- `StorageCondition` selector
- `POST /listings/analyze` called → returns `FreshnessAnalysis` (marketPrice, recommendedPrice, band, timeRange, remainingHours)
- Auto-price card: market price struck-through → Revivo price + band chip + "listing value / buyer saves / ~meals" stats
- Publish → `POST /listings` → resets form

`SellerOrdersScreen`:
- Polls `GET /orders/incoming` every 8s
- Shows buyer name, vegetable, qty, total, status chip

`SellerInsightsScreen`:
- Shows `SellerInsightsData`: revenue/kg/orders hero, band distribution (Good/Use Soon/Rescue counts), top movers table, peak hour
- AI recommendations with "Powered by Amazon Bedrock" badge (or "Advisory" if fallback)
- Empty state if no activity yet

### Cook/NGO (`features/cook/`)

`CookInboxScreen`:
- `NotificationBell` in header
- Stats: "New rescues" count + "Meals available today" (~`estimatedMeals` sum)
- "New rescues near you" section: `RescueStatus.offered` items
  - `RescueCard` with `_ExplainSection` (Bedrock "why rescue this?" expandable)
  - Action: `AsyncActionButton` "Accept · ~N meals" → `rescuesProvider.notifier.accept(id, ngoName)`
- "In progress" section: all non-offered, non-delivered rescues
  - accepted → "Start pickup" → `claimPickup(id)`
  - assigned → "Mark collected" → `markPickedUp(id)`
  - pickedUp → "Mark delivered" → `markDelivered(id)` (shows toast "~N meals served 🌱")
- Cook drives the rescue to completion (no volunteer role)

`Rescue` domain:
```dart
enum RescueStatus { offered, accepted, assigned, pickedUp, delivered }
final String id, vendorName, pickupArea, vegetable;
final double quantityKg, distanceKm;
final FreshnessBand band;
final String timeRange;
final RescueStatus status;
final String? ngoName;
int get estimatedMeals  // (quantityKg / 0.4).round()
```

### Impact (`features/impact/`)

`ImpactScreen`:
- Hero: total kg rescued (big number), vendor + NGO count
- 4 metric tiles: meals served, CO₂ avoided (kg), value recovered (₹), active partners
- Monthly meal goal progress bar: `mealsServed / _MEALS_GOAL` where goal=5000
- Top 5 leaderboard: rank (medal for 1–3), name, role (Vendor/NGO), kg rescued, meals

`ImpactSummary` fields: `kgRescued, mealsServed, co2SavedKg, moneySaved, activeVendors, activeNgos, mealsGoal`

### Notifications (`features/notifications/`)

`NotificationBell`:
- Unread count badge (red pill, "9+" if >9)
- Tap → `notificationsProvider.notifier.reload()` → opens modal sheet → marks all read on close
- Bell wired into Seller dashboard header AND Cook inbox header

`_NotificationsSheet`:
- Max height 55% of screen, scrollable
- Each tile: colored icon (green=unread, gray=read), title + body + relative time (now/5m/2h/3d)

### Rescue (`features/rescue/`)

`RescueCard`:
- Shows vegetable, vendor, qty, band chip, time range, distance, estimated meals
- `_ExplainSection`: expandable "Why rescue this?" → calls `POST /rescues/{id}/explain` via `rescuesProvider.notifier.explain(id)` → shows Bedrock text or fallback
- `AsyncActionButton`: handles async action with loading state + error snackbar

### Shared (`features/shared/`)

`ProfileScreen`:
- Shows name, email, role badge, `_trustCard()` (placeholder for trust score)
- Role-aware stats tiles: Seller (listings/orders), Buyer (orders/saved), Cook (rescues/meals) — currently hardcoded display values
- Menu items (placeholder)
- "Sign out" → `sessionProvider.notifier.signOut()` → `/role`

---

## 11. Test Suite

| Suite | File | Count | What is tested |
|---|---|---|---|
| Flutter | `test/live_clock_test.dart` | 7 | `formatCountdown`, `LiveClock.band()`, `LiveClock.price()`, `Offer.liveBand/livePrice/liveSavingsPct`, `isExpired`, fallback when no clock data |
| Flutter | `test/cart_test.dart` | 4 | `CartController` add/setQuantity/remove, `CartBill.of()` totals |
| Backend | `tests/test_freshness.py` | ~12 | `estimate_freshness`, `apply_live_freshness`, band thresholds, storage multipliers |
| Backend | `tests/test_models.py` | ~10 | `build_listing_item`, `to_public_listing`, `build_order_item`, `aggregate_impact` |
| Backend | `tests/test_insights.py` | 4 | `build_insights_converse_args` structure |
| Backend | `tests/test_rescue_ai.py` | 4 | `build_explain_converse_args` structure + fallback |
| Backend | `tests/test_notifications.py` | 5 | `notifications_from_records`, `build_notification_item` |
| Backend | `tests/test_streams.py` | ~6 | `order_ids_from_records` filtering |
| Backend | `tests/test_vegetables.py` | ~8 | Rekognition label mapping |

**Run commands:**
```bash
# Backend:
cd backend && source .venv/bin/activate
PYTHONPATH="$PWD" pytest tests/ -v

# Flutter:
cd app && flutter test

# Linting:
cd backend && ruff check .
cd app && flutter analyze

# CDK synth check:
cd infra && source .venv/bin/activate && npx aws-cdk@2 synth
```

---

## 12. Commit History (Meaningful, Chronological)

```
c7a9b03  feat(orders): rate & review completed rescues + impact receipt
           rate_order Lambda + POST /orders/{id}/rate + #r alias + RateOrderSheet
           + ImpactReceipt (copy-to-clipboard) + tracking screen sections

1890a70  feat(orders): live order tracking with status timeline + pickup
           OrderTrackingScreen (4-stage timeline, 8s poll, Directions/Call)
           + url_launcher added to pubspec

4288092  feat(cart): multi-vendor cart + checkout with pickup slots & payment
           CartItem/CartBill/kPlatformFee, CartController, CartScreen (vendor-grouped),
           CheckoutScreen (6 slots + PayMethod), OrderConfirmedScreen rewrite,
           BillSummary widget, cart badge on market header, router updates

8986b61  feat(clock): live freshness countdown + real-time price decay
           apply_live_freshness() backend, list_listings/list_my_listings use it,
           create_order charges live price, FreshnessTicker/FreshnessCountdownPill,
           LiveClock, Offer/Listing clock fields, product page hero, offer cards

97a5804  fix(ai): wire Bedrock via Amazon Nova + Converse API
           Switched both AI endpoints from InvokeModel to Converse, hardened JSON
           parser, fixed apac. prefix, insights+rescue_ai arg builders renamed

e5cd420  feat(seller): update-stock, live sales/insights, seed data, fresh form
           PATCH /listings/{id}, seller orders tab live, seller insights live +
           Nova AI recs, seed_listings.py with loremflickr photos

fe46d73  feat(seller): Rekognition auto-ID, auto-pricing, pro add-listing UX
           POST /listings/identify (DetectLabels), market_prices.py auto-price,
           camera capture → upload → Rekognition flow, auto-price card

e63c393  refactor: remove the Volunteer role from the whole app
           Deleted features/volunteer, /volunteer route, UserRole.volunteer,
           Cook now drives rescues to delivery

95896c9  feat(seller): overhaul add-listing + genuine AWS freshness analysis
           POST /listings/analyze endpoint, vegetable dropdown 20 types,
           8 purchase-time options, quantity stepper + quick chips

706b226  feat(orders): live seller order queue + first-come-first-serve stock
           create_order atomic decrement (conditional DynamoDB update),
           409 on over-order, SOLD when depleted, GET /orders/incoming

6e9400e  fix(auth): normalize email (lowercase) + trim password on login

fc516f5  feat(ai+notify): Bedrock rescue explanations (M8) + SNS notifications (M6)
           explain_rescue Lambda, RescueCard ExplainSection, NotificationsStack,
           NotificationBell, in-app feed, mark-as-read

685818b  feat(workflow): Step Functions order lifecycle via DynamoDB Streams (M7)

e9cbd44  feat(impact): live impact aggregation endpoint (GET /impact)

a06e15e  feat(images): finish photo upload + display pipeline
```

---

## 13. Hard Rules — Never Break

1. **No `Co-Authored-By:` trailer** — ever. Commits are attributed to Smriti only.
2. **Never mention "Kumaraguru College of Technology" or "KCT"** — not in code, README, commits, or docs. Team is "Team Neura" only. City references (Coimbatore, Gandhipuram) and partner ("local NSS unit") are fine.
3. **One clean commit per feature/module** — no WIP. Always end with `flutter analyze` clean + `ruff check` clean + all tests passing.
4. **Conventional commits:** `feat(scope):`, `fix(scope):`, `refactor:`, `chore:`

---

## 14. What Is DONE — Phase 1 "Real & Alive" ✅

All four Phase 1 commits delivered end-to-end, live-verified against the deployed AWS stack.

### The Clock (`8986b61`)
- `apply_live_freshness()` recomputes freshness from immutable stored inputs at every read. Stored `recommendedPrice` was snapshot-only; now it's always live.
- `list_listings` + `list_my_listings` both call `apply_live_freshness` per item before `to_public_listing`.
- `create_order` calls `apply_live_freshness` on the listing before building the order item — display price == charged price.
- Backend emits `expiryEpoch` (absolute seconds) + `totalHours` (full shelf window) so the client can recompute independently.
- Flutter: `LiveClock` mirrors backend thresholds, `FreshnessTicker` ticks every second, `FreshnessCountdownPill` colors: green/amber/red, bolt icon at rescue band.
- `Offer` and `Listing` gained `expiresAt`, `totalHours`, `hasClock`, `liveBand()`, `livePrice()` etc.
- Product details screen: clock hero with next-band threshold ("Drops to ₹X in ~Yh").

### Cart → Checkout (`4288092`)
- `CartItem.lineTotal` uses `offer.livePrice()` — bill moves as the clock ticks.
- `CartController`: add/setQuantity/remove/clear in a single `cartProvider` Notifier.
- `kPlatformFee = 8.0` — charged once per checkout, not per item.
- Cart screen: vendor-grouped, qty stepper, live prices, bill summary.
- Checkout: 6 dynamic half-hour slot chips from next :00/:30, `PayMethod` enum (4 options).
- Places one order per cart line sequentially; clears cart on success.
- `OrderConfirmedScreen` rewritten to accept `List<Order>`, shows combined total + savings.
- Backend: `pickupSlot` (≤40) + `paymentMethod` (4 values) validated, stored in ORDER item, returned in `to_public_order`.

### Order Tracking (`1890a70`)
- 4-stage status timeline in `OrderTrackingScreen` using `_TimelineRow` (done/active/todo states with circles and connectors).
- 8-second polling via `Timer.periodic` calling `ordersProvider.notifier.reload()` (silent, no spinner).
- Live-reads the freshest copy from state by `order.id`, falls back to the passed-in order before first poll.
- Pickup card: venue string, pickup slot, Directions (Google Maps search URL via `url_launcher`), Call (`tel:` URI).
- Bill card: qty × price, savings, payment method label.

### Rate & Review + Impact Receipt (`c7a9b03`)
- `POST /orders/{orderId}/rate`: owner-only, validates 1–5 stars + ≤6 tags + ≤280 comment.
- `rating` reserved word in DynamoDB → aliased as `#r` in UpdateExpression.
- `RateOrderSheet`: bottom sheet with 5 stars (disabled submit until star selected), 5 FilterChips, comment field.
- `ImpactReceipt`: gradient card, 3 stats (saved/meals/CO₂), "Share impact" → clipboard.
  - Meals: `(quantityKg × 2.5).round()`
  - CO₂: `quantityKg × 2.5` kg
- `_ratingSection` in tracking screen: shows submitted stars+tags if rated, else "Rate this rescue" button.

---

## 15. What Is PENDING

### Phase 2 — Discovery & Location

**Goal:** Make the app feel like Swiggy — location-aware, rich discovery feed, easy browsing.

**Note:** The GPS schema is already in `models.py` — `build_listing_item` stores `gps: {lat, lng}` and `to_public_listing` includes the `gps` field when present. The seed and create flow just need to pass GPS coordinates.

#### Rich Home Feed (overhaul `buyer_market_screen.dart`)
Current: flat list with 4 filter chips.  
Target:
- Category tab bar: All | Vegetables | Fruits | Grains | Dairy
- Horizontal "Rescue Deals Ending Soon" strip — sorted by `offer.expiresAt` ascending (data already on `Offer`). `FreshnessCountdownPill` on each card.
- Horizontal "Near You" vendor strip (sort by `distanceKm`)
- Hero banner: "X rescues ending in <1h" (filter `offer.expiresAt` within 1h)
- Summary stat: "N kg available from M vendors today"
- Backend: no new endpoint needed — data already in `GET /listings` response

#### Real Search
Current: cosmetic filter on loaded list (vegetable + vendorName, client-side).  
Target: same mechanism is fine for the pilot (no backend search endpoint needed). Add debouncing, clear button, empty state with suggestion chips.

#### Vendor Profile Page
- New screen: `VendorProfileScreen(vendorId: String, vendorName: String)`
- Shows: vendor avatar, name, location, active listing count, avg rating, "Trusted Vendor" badge
- Lists this vendor's active offers (filter `offersProvider` state by `vendorId`, no new API call needed)
- Tap vendor name in `OfferCard`, `OrderTrackingScreen` → navigate to vendor profile

#### Rescue Map *(signature wow feature)*
- Add `flutter_map` (OpenStreetMap, no API key) or `google_maps_flutter`
- Markers colored by band: green (GOOD), amber (USE_SOON), red pulsing (RESCUE)
- Data: listings already have optional `gps` field in DynamoDB. Seed with Coimbatore coords.
- Backend: `list_listings` already returns `gps` if present. No new endpoint.
- `create_listing` flow: add GPS field to `AddListingScreen` (could be auto from device GPS via `geolocator` package, or hardcoded for pilot vendors)
- Tap marker → `ProductDetailsScreen`

#### Location Setup
- First-launch screen asking permission (optional for MVP — can default to Coimbatore)
- `distanceKm` is already in `Offer` model — can compute from device GPS vs listing GPS

**Backend changes for Phase 2:**
- Update `seed_listings.py` to include `gps: {lat, lng}` for each seeded listing (Coimbatore coords)
- Add `gps` field to `AddListingScreen` form (auto-GPS or default)
- Optionally add `GET /vendors/{vendorId}/profile` — or compute from existing loaded data

---

### Phase 3 — Trust & Social

**Goal:** Surface credibility signals — make buyers confident, reward reliable vendors.

#### Quality Confidence Card (on `ProductDetailsScreen`)
- Under the listing title, above the clock hero
- Shows: avg rating (⭐ X.X from N orders), "AI-verified produce" badge (if Rekognition found no defect labels)
- Backend: add `avgRating` + `ratingCount` to `to_public_listing` response. Options:
  - Compute on the fly in `list_listings` (scan vendor's orders from GSI3 — expensive)
  - Better: maintain running totals in a separate `VENDOR_STATS#{vendorId}` DynamoDB item, updated in `rate_order` Lambda

#### Ratings on Listing Cards (`offer_card.dart`)
- Currently: band pill + price
- Add: `⭐ X.X (N)` under vendor name
- Requires `avgRating` + `ratingCount` in `Offer` domain and API response

#### Trusted Vendor Badge (auto-earned)
- After `POST /orders/{id}/rate`: check if `total_completed_orders ≥ 10` AND `avg_rating ≥ 4.0`
- If yes, set a `trustedVendor: true` flag on a `VENDOR_STATS#` DynamoDB item
- Show badge on `VendorProfileScreen` and `OfferCard`
- Backend: new logic in `rate_order/handler.py` (post-update check)

#### Defect Screening Visible in UI
- `identify_vegetable` already calls `DetectLabels` — extend to also check for defect-related labels (mold, damage, rot, wilted)
- Store `defectFlags: []` on listing at creation
- Show "AI screened ✓ No defects" or "⚠ Flagged for review" badge on product details

#### Seller Analytics Charts
- `SellerInsightsScreen` currently shows text metrics + AI tips
- Add `fl_chart` package
- Revenue over time: line chart (grouped by day from `createdAt` on orders)
- Sales by vegetable: horizontal bar chart from `movers`
- Band distribution: simple pie or ring chart from `good/useSoon/rescue` counts
- `GET /listings/insights` already returns all needed data — just needs chart rendering

---

### Phase 4 — Depth & Delight

**Goal:** Retention mechanics and full platform feel.

#### Revivo Wallet / Credits
- Earn 1 credit per ₹10 saved on each order
- Credits visible on `ProfileScreen`
- Credits applied at checkout to offset platform fee
- Backend: `walletBalance` field on DynamoDB user record (or Cognito custom attribute), updated in `create_order`
- `PayMethod.wallet` is already in the enum — currently simulated, wire it up

#### Favorites
- Heart icon on `OfferCard`, `ProductDetailsScreen`
- State stored locally (shared_preferences or Hive, no backend needed for pilot)
- Favorites filter tab in market screen
- Optional: notify when favorited vendor goes RESCUE band (local notification)

#### Full Notification Center Screen
- Currently: modal bottom sheet from `NotificationBell`
- New: full-page `NotificationCenterScreen` accessible from profile or dedicated tab
- Categories: Order Updates | Rescue Alerts | System
- Each item tappable → navigate to relevant screen (tracking screen for orders, rescue inbox for rescues)

#### Push Notifications via APNs/FCM
- SNS topic already exists (`revivo-notifications`), Streams Lambda already publishes
- Missing: device token registration. Add `POST /devices` endpoint to store APNs/FCM tokens
- `flutter_local_notifications` or Firebase Messaging for client-side

#### Cook: Meal-Proof Loop
- After `RescueStatus.delivered`: show "Upload meal photo" prompt on Cook inbox
- Photo → S3 → stored as `mealPhotoKey` on RESCUE item
- Impact screen shows sample meal photos from delivered rescues
- Unlocks "Meal Hero" milestone badge

#### Refer & Earn
- Unique referral code per user (6-char from sub, stored in Cognito or DynamoDB)
- `ShareScreen` with deep link + referral code
- `POST /referrals` validates code, credits referrer on referred user's first order

#### FSSAI / Help
- Static info page: FSSAI guidelines for food redistribution
- FAQ: food safety, pricing transparency, complaint process

#### Milestone Badges
- Trigger events: first order, 10 orders, first rescue, 100 kg rescued, 1000 meals enabled
- Stored as `badges: [...]` on DynamoDB user record, shown on profile
- Unlock animation screen on first earn

---

## 16. M12 Deliverables (All Pending — Mandatory for Submission)

| Deliverable | Status | Notes |
|---|---|---|
| `README.md` with live URLs | ❌ | Needs Amplify link, API URL, arch diagram embedded, deploy instructions |
| Architecture PNG diagram | ❌ | All 5 stacks, data flow, AI services, DynamoDB access patterns |
| 5–10 min YouTube demo video | ❌ | Golden path: Seller lists → countdown ticks → Buyer buys → Cook rescues → Impact shown |
| Amplify hosting deployment | ❌ | `flutter build web` → Amplify Hosting |
| Demo script | ❌ | Step-by-step for judges; use demo credentials |

---

## 17. Key Technical Gotchas

**Live price == charged price:**  
`apply_live_freshness()` runs at every read in `list_listings`, `list_my_listings`. `create_order` calls it again immediately before building the ORDER item. The price decay the buyer sees on the countdown is exactly what they're charged. Never use the stored `recommendedPrice` directly for charging.

**FCFS stock reservation:**  
`create_order` uses `ConditionExpression="quantityKg >= :q"` with an atomic `SET quantityKg = quantityKg - :q`. Returns 409 "that surplus was just claimed" on `ConditionalCheckFailedException`. When remaining qty hits 0, a second update removes `GSI2PK`/`GSI2SK` (drops from active market) and sets `status=SOLD`.

**DynamoDB reserved words:**
- `rating` → `ExpressionAttributeNames={"#r": "rating"}` (in `rate_order`)
- `status` → `{"#s": "status"}` (in Step Functions DynamoUpdateItem + `update_listing`)
- `read` → `{"#r": "read"}` (in `mark_notifications_read`)

**Step Functions no re-trigger:**  
`start_order_workflow/handler.py` uses `streams.order_ids_from_records()` which filters for stream records with `eventName=INSERT` AND `type=ORDER`. This prevents the step function's own status updates (which are MODIFY events, not INSERT) from starting new executions.

**SNS two consumers:**  
Both `StartOrderWorkflowFn` (WorkflowStack) and `NotifierFn` (NotificationStack) consume the same DynamoDB stream independently. They don't coordinate. ORDER inserts fire both. RESCUE inserts only fire NotifierFn (it has no ORDER-type filter).

**Image pipeline — 7-day S3 expiry:**  
S3 bucket has a 7-day lifecycle rule. Demo images from `seed_listings.py` (loremflickr direct URLs stored as `imageUrl` in the item) don't expire. But images uploaded via the app have presigned GET URLs that expire after 15 minutes (900s) — `to_public_listing` re-generates a fresh presigned URL at every read via `attach_image_url()`.

**GPS field already in schema:**  
`build_listing_item` already handles `data.get("gps")` and stores `{lat, lng}`. `to_public_listing` already returns `gps` if present. Rescue Map (Phase 2) doesn't need a schema migration — just needs seed data and the form to send coordinates.

**Bedrock Converse API (not InvokeModel):**  
Both Bedrock Lambdas use `client.converse(modelId=MODEL_ID, **args)` where `args` has the shape `{system: [{text}], messages: [{role, content:[{text}]}], inferenceConfig: {maxTokens}}`. Response text is at `resp["output"]["message"]["content"][0]["text"]`. Both handlers have a `try/except` that returns the deterministic fallback on any error.

**Cognito case-sensitivity:**  
Pool is case-sensitive. `cognito_service.dart` lowercases + trims email at sign-in and registration. `prevent_user_existence_errors=True` on the app client masks error reasons (can't distinguish "user not found" from "wrong password") — friendly error messaging is handled in the Dart layer.

**Cart platform fee:**  
`CartBill.of(items)` only charges `kPlatformFee` (₹8) if `items.isNotEmpty`. An empty cart has 0 fee. The fee is charged once per checkout session, not per item.

**Multi-vendor checkout:**  
`CheckoutScreen` places one `POST /orders` per cart item sequentially. If one fails mid-checkout, already-placed orders are not rolled back. This is acceptable for pilot scope — the seller still gets the notification, and the buyer's `GET /orders` will show the placed ones.

---

## 18. New Machine Setup

```bash
# Prerequisites check
flutter --version   # Need 3.44+
python3 --version   # 3.9+ (CDK uses 3.9, Lambda runtime is 3.12)
node --version      # 18+
aws configure list  # Must have ap-south-1 creds for account 138430391721

# Flutter app
cd app
flutter pub get
flutter run   # Connects to live AWS (useLiveApi: true)

# Run offline (no AWS)
# Set useLiveApi: false in app/lib/core/config/app_config.dart

# Backend tests
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install pytest ruff boto3
PYTHONPATH="$PWD" pytest tests/ -v
ruff check .

# CDK setup
cd infra
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
npx aws-cdk@2 synth   # Should print 5 stacks, no errors

# Full deploy
npx aws-cdk@2 deploy --all --require-approval never

# Seed demo data
cd ../backend && source .venv/bin/activate
PYTHONPATH="$PWD" python scripts/seed_listings.py
PYTHONPATH="$PWD" python scripts/seed_rescues.py
```

---

## 19. What to Build Next (Priority Order)

1. **Phase 2 — Discovery & Location** (highest judge impact, most visible)
   - Rich home feed: category tabs + "Rescue deals ending soon" horizontal strip
   - Real search with debounce + clear + empty state
   - Vendor profile screen
   - Rescue Map with `flutter_map` (OpenStreetMap, no API key needed)
   - Seed GPS coords into listings

2. **M12 Deliverables** (mandatory for submission)
   - README + architecture diagram
   - Amplify deploy (`flutter build web`)
   - Demo video (screen record golden path with demo credentials)
   - Demo script for judges

3. **Phase 3 — Trust & Social** (quality signals, differentiator)
   - Ratings on listing cards + avg rating in `to_public_listing` response
   - Quality Confidence Card on product details
   - Trusted Vendor badge

4. **Phase 4 — Depth & Delight** (retention, only if time allows)

---

---

## 20. CURRENT STATE (authoritative — 2026-07-07, HEAD `f2524b0`)

Since Section 15 was written, **Phases 2, 3 and 4 were largely built** — but almost
entirely on the **buyer/hotel** experience. The hotel side is now Zomato/Blinkit/Swiggy-grade.
The **seller** and **cook** sides got only one feature each and remain comparatively plain.

### 20.1 New commits since `c7a9b03`
```
f2524b0  feat(cook): meal-proof loop — log meals served after delivery
592419b  feat(app): notification center, milestone badges, help/FSSAI & refer-earn
cf78d8f  feat(buyer): Revivo wallet credits & favorites
b3650e4  feat(buyer): vendor ratings & reviews on the storefront
aa1f999  feat(seller): analytics charts on insights
247a5e4  feat(buyer): discovery & trust — vendor profiles, ratings, categories, quality card & rescue radar
2b84376  feat(orders): Blinkit order details, failed-payment flow & account details
dcb9c5e  feat(impact): richer impact dashboard
f4cd9ce  feat(buyer): live hotel dashboard, Zomato cart bar & cart redesign with coupons
```
~5,000 insertions across 45 files. **All new work is Flutter-only** — no backend/CDK changes;
these features run on client-side state + deterministic derived data (see `vendor_directory.dart`).

### 20.2 New files added (all Flutter)

**Core:**
- `core/discovery/produce_category.dart` — `ProduceCategory` enum (All/Vegetables/Leafy/Roots/Herbs…) + `matchesCategory()`
- `core/discovery/vendor_directory.dart` — `vendorInfo(name)` + `vendorReviews(name)`: deterministic per-vendor rating/reviews/distance/area/trusted-flag from an FNV-1a hash of the name (stable across rebuilds; **placeholder until a real VENDOR_STATS backend item ships**). `trusted = completedOrders>=10 && rating>=4.3`.
- `core/widgets/live_clock_chip.dart` — `LiveClockChip` ticking wall-clock pill
- `core/format.dart` — added more formatters

**Buyer (hotel) — the polished side:**
- `buyer/rescue_map_screen.dart` — **Rescue Radar** map (surplus lots plotted by bearing/distance, band-colored)
- `buyer/vendor_profile_screen.dart` — vendor page: rating, trusted badge, reviews, this vendor's active offers
- `buyer/order_details_screen.dart` — Blinkit-style full order detail (454 lines)
- `buyer/domain/coupon.dart` — `Coupon` model + validation (tested in `test/coupon_test.dart`, 105 lines)
- `buyer/domain/failed_payment.dart` — failed-payment retry model
- `buyer/application/{favorites,wallet,failed_payments}_providers.dart`
- `buyer/widgets/cart_bar.dart` — Zomato-style persistent bottom cart bar
- `buyer/widgets/live_rescue_rail.dart` — horizontal "Ending soon" rail
- `buyer/widgets/coupon_sheet.dart`, `payment_sheet.dart`, `favorite_heart.dart`, `quality_card.dart`, `trust_badges.dart` (`TrustedVendorBadge`, `RatingPill`)

**Seller — only ONE new file:**
- `seller/widgets/insight_charts.dart` — `BandRing` (donut of freshness mix, CustomPainter) + `MoverBars` (top-movers bars)

**Cook — only TWO new files:**
- `cook/meal_log_sheet.dart` — bottom sheet to log meals served
- `rescue/application/meal_log_providers.dart` — in-memory meal log

**Shared:**
- `shared/account_details_screen.dart` — edit name/phone/address (`profile_providers.dart`)
- `shared/help_screen.dart` — FSSAI food-safety info + FAQ
- `shared/refer_screen.dart` — refer & earn with referral code
- `shared/badges.dart` — `MilestoneBadge` + `buyerBadges()` (buyer-only gamification)
- `notifications/notification_center_screen.dart` — full-page notification history

### 20.3 New routes (added to `app_router.dart`)
```
/buyer/vendor   → VendorProfileScreen(vendorName: String)
/buyer/map      → RescueMapScreen
/buyer/order    → OrderDetailsScreen(order: Order)
/account        → AccountDetailsScreen        (shared)
/notifications  → NotificationCenterScreen    (shared)
/help           → HelpScreen                  (shared)
/refer          → ReferScreen                 (shared)
```

### 20.4 What each role's experience looks like NOW

**Buyer / Hotel (POLISHED — "almost over" per the user):**
- Market: live clock strip ("X kg from N vendors today"), Rescue Radar entry, "Ending soon" horizontal rail, search + clear, category chips, filter chips (All/Rescue/Saved/Organic/Nearby), offer cards with favorite hearts + rating pills + trusted badges
- Persistent `CartBar` (Zomato pattern), cart redesign with coupons, payment sheet, checkout with wallet credits
- Product details: quality confidence card, vendor link, live clock hero
- Orders: Blinkit-style order details + tracking timeline + failed-payment retry
- Impact: richer dashboard. Profile: wallet card + milestone badges + refer & earn + account details + help
- Vendor profile pages, Rescue Radar map

**Seller (STILL PLAIN — needs work):**
- Dashboard: 2 stat tiles (total listings, sold today) + inventory list w/ countdown pills + stock-update sheet
- Orders: flat incoming-order list, FCFS, status chips — no seller-side pickup coordination, no buyer contact, no "hand over" action
- Add listing: strong (camera→Rekognition→auto-price)
- Insights: **good now** — BandRing donut, MoverBars, peak-demand hero, Bedrock recs
- Profile: shared screen but wallet/badges/refer are **gated to buyers only** → seller sees contact + hardcoded stats + menu

**Cook / NGO (STILL PLAIN — needs work):**
- Inbox: single screen does everything — new rescues / in-progress / delivered sections, accept→start pickup→collected→delivered, meal-log sheet after delivery
- Impact: shared screen. Profile: shared, plain (no cook gamification)
- No pickup route/navigation, no kitchen/capacity view, no distribution proof beyond a meal count, no batch handling

### 20.5 Still genuinely PENDING
- **Seller & Cook production-grade uplift** (see Section 21 — the current priority)
- **Backend for the new features:** wallet, favorites, coupons, vendor stats/ratings, referrals, meal-log, milestone badges are all **client-side/in-memory or deterministic-derived only**. No DynamoDB persistence yet. `vendor_directory.dart` fakes per-vendor reputation from a name hash.
- **Trust backend:** real `VENDOR_STATS#{vendorId}` aggregation from `rate_order` (avg rating, completed orders, trusted flag) — currently faked client-side
- **GPS:** listings still have no real coordinates; Rescue Radar uses derived bearing/distance, not real geo
- **Push notifications:** SNS wired but no device-token registration (in-app feed only)
- **M12 deliverables:** README, architecture diagram, Amplify deploy, demo video/script — all still not started

### 20.6 Profile screen role-gating (important)
`shared/profile_screen.dart` shows wallet card, milestone badges, and (implicitly) buyer framing
**only when `role == UserRole.buyer`**. `_statsFor()` returns **hardcoded** numbers for all three
roles. Seller and cook profiles are therefore thin and static — a fast win is role-specific
wallet/earnings, badges, and real stats.

---

## 21. SELLER & COOK — PRODUCTION-GRADE IMPROVEMENT PLAN

The definitive backlog for bringing seller + cook up to the hotel side's bar. Grouped by role,
ordered by impact. Reuse existing widgets (`AppCard`, `StatTile`, `FreshnessCountdownPill`,
`BandRing`, `LiveClockChip`, `TrustedVendorBadge`, `RatingPill`, gradient hero pattern).

### 21.1 SELLER — target: a "surplus command center", not a CRUD list

1. **Dashboard hero: "Revenue at risk" live card.** Gradient hero (reuse insights `_peakCard` style) showing ₹ value of inventory currently in USE_SOON + RESCUE bands, with a live countdown to the next price drop and a one-tap "Push to rescue" / "Discount now" action. This makes the time-aware thesis visible to the seller, not just the buyer.
2. **Today's earnings strip.** Real revenue today, orders today, kg moved, avg time-to-sell — replace the hardcoded profile stats with live aggregates from `vendorOrdersProvider`.
3. **Smart re-list / expiry nudges.** Cards on the dashboard: "3 lots enter Rescue in <2h — drop price or route to a kitchen." One tap creates a rescue (`POST /rescues`) directly from a listing about to expire — closes the Sell→Rescue loop from the seller side (currently rescues appear only for cooks).
4. **Order fulfilment actions.** Seller Orders tab is read-only. Add: "Mark ready for pickup", "Handed over" (manual override of the Step Functions auto-advance), buyer name + call button, pickup slot display, and a per-order OTP/handover code for pickup verification.
5. **Seller trust profile.** Give sellers the `TrustedVendorBadge` + `RatingPill` on their own profile, a "Reviews" view (reuse `vendorReviews`), and a real trust score from completed orders — mirrors what buyers already see about them.
6. **Seller wallet / payouts.** Earnings balance, weekly payout summary, "You've recovered ₹X that would've been waste." Reuse the buyer wallet gradient card, re-themed for payouts.
7. **Seller milestones.** `sellerBadges()` in `badges.dart` (parallel to `buyerBadges`): "First surplus saved", "100 kg rescued", "Zero-waste week", "Trusted vendor". Un-gate the profile badges section for sellers.
8. **Bulk / recurring listings.** "List again" from a past listing, and a quick multi-add for vendors who dump surplus daily — production sellers won't re-shoot photos every time.
9. **Demand heatmap.** Extend insights: which vegetables/hours sell fastest, so the seller lists the right surplus at the right time. Data already aggregated server-side.

### 21.2 COOK / NGO — target: a "rescue operations console", not one scrolling list

1. **Split the single screen into a real flow.** Tabs or segments: **Available** (offers) · **My pickups** (active) · **Delivered/Impact**. The current all-in-one list won't scale past a few rescues.
2. **Pickup route & navigation.** Each accepted rescue needs Directions (Google Maps URL — same `url_launcher` pattern as buyer tracking), vendor call button, pickup ETA, and an optional multi-stop "plan my run" that orders today's pickups by distance (reuse `vendorInfo.distanceKm`/bearing).
3. **Rescue Radar for cooks.** A map (reuse `RescueMapScreen`) of surplus pulsing red at RESCUE band near the kitchen — the cook's version of the buyer radar. This is a listed **signature wow feature** not yet built for cooks.
4. **Kitchen capacity & matching.** "Can we take this?" — let the cook set daily meal capacity; show whether an incoming rescue fits remaining capacity. Prevents over-accepting.
5. **Distribution proof loop (extend meal-log).** After logging meals, prompt an optional **photo of the served meals** (camera → S3, same pipeline as listings) → shows on Impact as verifiable proof. Turns the meal-log number into a shareable, fundable story. This is the "meal-proof loop" half-built (number only) — add the photo.
6. **Beneficiary / distribution detail.** Where the meals went (shelter, community kitchen, count of people) — the data NGOs actually report to donors/CSR.
7. **Cook trust + milestones.** `cookBadges()`: "First rescue", "1,000 meals served", "Meal Hero", "Zero-waste kitchen". Un-gate profile badges + add a cook wallet-style "impact ledger" (kg rescued, meals served, CO₂ avoided, lifetime).
8. **Urgency triage.** Sort/flag the offers list by time-to-expiry so the cook grabs the most urgent surplus first (reuse `_endingSoon` logic from the buyer market).
9. **Team / volunteer assignment (stretch).** Even without the removed Volunteer role, let a cook assign a pickup to a named runner and track it — real kitchens have staff.

### 21.3 Cross-cutting (both roles)
- **Un-gate profile features** in `profile_screen.dart`: role-specific wallet/ledger, badges, and **real** stats (kill the hardcoded `_statsFor` numbers).
- **Onboarding** per role (3-slide intro) — sellers and cooks currently drop straight into a cold dashboard.
- **Empty states with a first action** (seller: "List your first surplus"; cook: "No rescues yet — here's how it works").
- **Backend to make it real (biggest gap):** persist wallet/badges/vendor-stats/meal-log/ratings in DynamoDB so the numbers survive restarts and match across roles. Today they're client-side only.

### 21.4 Suggested build order (highest wow-per-hour first)
1. Seller "Revenue at risk" hero + expiry nudges + one-tap route-to-rescue (**the differentiator, seller-side**)
2. Cook: split into Available/Pickups/Delivered + Directions + urgency triage
3. Cook meal-proof **photo** + Cook Rescue Radar map
4. Un-gate profiles: seller/cook wallet+ledger, `sellerBadges`/`cookBadges`, real stats
5. Seller order fulfilment actions (mark ready / handover code / call buyer)
6. Backend persistence for wallet/vendor-stats/meal-log (removes the "faked data" caveat before judging)

> **Uniqueness anchors** (what no competitor has, keep leaning in): the live price-decay clock made
> actionable for *sellers* ("revenue at risk"), the seller-initiated Sell→Rescue auto-escalation,
> the cook's Rescue Radar + verifiable meal-proof photo loop, and one impact ledger that ties a
> vendor's surplus → a hotel's saving → a kitchen's served meals end to end.

---

---

## 22. SESSION UPDATE — seller/cook uplift + persistence shipped (HEAD `ed9fb94`)

The Section 21 plan is now largely built, in 6 commits:

```
ed9fb94  feat(seller): order fulfilment — mark ready/handed over, call buyer, handover code
b80ca19  feat(cook): rescue operations console — Available/Pickups/Delivered + nav + meal proof
c1f64e3  feat(profile): real role-aware stats, un-gate seller/cook wallet & badges
f7bdb93  feat(backend): persist wallet, vendor reputation & meal logs in DynamoDB
061cd9d  feat(seller): revenue-at-risk command center + one-tap route to rescue
```
(plus `f2524b0` cook meal-proof loop from the prior session)

### Delivered
- **Seller "Revenue at risk" command center** — dashboard hero (₹ of USE_SOON+RESCUE
  stock, ₹ already lost to decay, live "next price drop" countdown) + per-lot nudge cards
  with one-tap **Route to rescue** (`POST /rescues` + pull off market) and Sold-out.
  `Listing` gained liveBand/livePricePerKg/liveValue/freshValue/atRisk/nextDropAt (+5 tests).
- **Backend persistence (kills the faked data)** — new single-table items
  `USER#{sub}/WALLET` and `VENDOR#{id}/STATS`; `create_order` credits the wallet
  (1/₹10 saved), records the vendor sale, and redeems `creditsUsed` atomically;
  `rate_order` rolls stars into vendor reputation (avg + Trusted derived on read);
  `POST /rescues/{id}/meals` persists meals + proof-photo key; `GET /profile` returns
  role-aware live stats. `shared/profile.py` + 5 tests (61 backend tests).
- **Real profile** — `GET /profile` drives role-aware ledger (buyer credits / seller
  recovered revenue / cook meals), real seller rating + Trusted badge, real stat tiles,
  and `sellerBadges()`/`cookBadges()`. Killed the hardcoded `_statsFor`/4.8★.
- **Cook operations console** — Available / My pickups / Delivered segments, urgency
  triage, Directions + call on pickups, meal-log now **persisted** (+ camera→S3 proof
  photo via new `core/uploads/image_uploader.dart`), Rescue Radar entry in the header.
  Deleted the in-memory `meal_log_providers`.
- **Seller order fulfilment** — `POST /orders/{id}/status` (owner-only manual advance);
  Mark ready → Mark handed over, call buyer, and a 4-digit handover code shown on both
  the seller card and the buyer's tracking screen (pure function of the order id).

### New backend routes (need `cdk deploy Revivo-Api`)
```
GET  /profile                    role-aware wallet + vendor + buyer + cook stats
POST /rescues/{rescueId}/meals   log meals served (+ photo key)
POST /orders/{orderId}/status    vendor marks ready / handed over
```
(`create_order` also now accepts `creditsUsed`.)

### Still faked / not yet persisted (honest remaining gaps)
- **Favorites & coupons** — still client-side/in-memory (favorites are per-device; coupons
  are static promo config). Fine for the pilot; persist if judged on it.
- **Storefront vendor ratings** — offer cards still use the `vendor_directory.dart`
  name-hash for rating/distance. Real reputation now exists (`VENDOR#/STATS` via
  `GET /profile`), but `list_listings` doesn't yet **join** it into the offer payload,
  so the storefront cards aren't wired to real ratings. Next: attach `avgRating`/
  `ratingCount`/`trusted` per vendor in `list_listings` → `Offer` → offer cards.
- **Wallet at checkout** — earn + balance + redemption are server-persisted, but the
  checkout redemption UI still reads the in-memory `walletProvider`; wire it to
  `GET /profile` balance + send `creditsUsed` (backend already supports it).
- **GPS** — listings still carry no real coordinates; Rescue Radar uses derived bearing.
- **M12 deliverables** — README, architecture diagram, Amplify deploy, demo video/script.

### UI / motion system (commits `bf1105f`, `5a2690c`)
A theme-level polish + motion pass toward the rounded, soft-shadow grocery-app
reference — **no screen layouts changed**:
- **Type**: Poppins app-wide via `google_fonts` (⚠️ fetches at first launch +
  caches; falls back to system font offline). `AppTheme._textTheme`.
- **Surfaces**: `AppCard` now floats on `AppShadows.card` (soft diffuse shadow)
  instead of a hairline border; tinted cards keep their border. New tokens
  `AppRadius.xl` (26) / `AppRadius.button` (16), `AppShadows.card/lifted`.
- **Controls**: pill primary CTAs (StadiumBorder), rounded filled/outlined
  buttons + inputs, floating snackbars, floating rounded bottom nav (pill
  indicator, Poppins labels).
- **Motion** (`core/widgets/motion.dart`): `Pressable` (scale-on-press) +
  `FadeSlideIn` (staggered entrance). Smooth fade-through+rise page transitions
  (theme `pageTransitionsTheme`). Wired: offer-card press, Hero produce image
  market→product, staggered market grid, easeOutBack cart-badge pop, floating
  cart bar. Extend the same primitives to seller/cook lists as a follow-up.

*Last updated: 2026-07-07 · HEAD: `5a2690c` · flutter analyze clean · 21 Flutter + 61 backend tests green · ruff + cdk synth clean · UI = Poppins + soft-shadow/curvy + motion · 3 API routes still await `cdk deploy Revivo-Api`*

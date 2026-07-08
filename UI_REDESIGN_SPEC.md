# Revivo — UI Redesign Specification
### Complete Screen-by-Screen Design Brief for Claude Design

---

## 1. PROJECT OVERVIEW

**Revivo** is a time-aware food rescue marketplace for the AWS SDG-2 hackathon.  
Three user roles interact in a closed loop:

```
[SELLER / Vegetable Vendor]  →  lists surplus produce
        ↓
[BUYER / Hotel Kitchen]  →  orders at freshness-decayed prices
        ↓
[COOK / NGO Kitchen]  →  rescues items buyers didn't buy, converts to meals
```

**Platform:** Flutter mobile app (iOS + Android)  
**Design Goal:** Look and feel like **Zomato / Swiggy** — a million-dollar, app-store-quality product. Buttery smooth, green-dominant, Poppins font, rounded cards with soft shadows, no hard borders, no AI slop. Every screen should feel like it was designed by a senior Dribbble designer.

---

## 2. DESIGN SYSTEM

### 2.1 Color Palette

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#1FBF61` | Brand green — buttons, active states, CTAs |
| `primaryDark` | `#16A34A` | Gradient end, pressed state |
| `primarySurface` | `#E6F8ED` | Light green tint — chips, selected states, banners |
| `primaryLight` | `#4ADE80` | Highlights, sparkle |
| `background` | `#F9FAFB` | Page background |
| `surface` | `#FFFFFF` | Card backgrounds |
| `surfaceAlt` | `#F3F4F6` | Secondary fills, unselected chips |
| `border` | `#E5E7EB` | Subtle dividers |
| `textPrimary` | `#111827` | Headlines |
| `textSecondary` | `#4B5563` | Body, labels |
| `textMuted` | `#9CA3AF` | Captions, placeholders |
| `warning` | `#F59E0B` | "Use soon" freshness band |
| `danger` | `#EF4444` | "Rescue" band, errors |
| `info` | `#3B82F6` | Order confirmed state |
| `success` | `#1FBF61` | Same as primary (green = good) |

**Rule:** Use green (`primary`) generously — nav bar active, FABs, all primary buttons, progress bars, freshness indicators, section dividers. The app should feel **green-first**.

### 2.2 Typography

**Font:** Poppins (Google Fonts — already added via `google_fonts: ^6.2.1`)

| Use | Weight | Size |
|---|---|---|
| Screen title / hero number | ExtraBold 800 | 22–30px |
| Card title | Bold 700 | 15–17px |
| Body / label | SemiBold 600 | 13–14px |
| Caption / meta | Medium 500 | 11–12px |
| AppBar title | Bold 700 | 17px |
| Pill/chip label | Bold 700 | 11–12px |

### 2.3 Shape Language

- Cards: `borderRadius: 20px` — soft, not sharp, no hairline borders
- Buttons (primary): `StadiumBorder` — full pill shape  
- Buttons (secondary): `borderRadius: 16px`  
- Chips: `borderRadius: 100px` (pill)  
- Input fields: `borderRadius: 16px`  
- Bottom nav: rounded top corners `26px`, floats above content with shadow
- Shadows: `BoxShadow(color: black 5% opacity, blurRadius: 20, offset: Offset(0, 8))` — soft diffuse, not harsh drop shadow
- NO hard borders on white cards — use shadows only
- Tinted/colored cards: keep a subtle 1px border in the tint color at 25% opacity

### 2.4 Icon Pack

**Replace ALL Material Icons with HugeIcons package** (`hugeicons_flutter`)

Key mappings:
| Current Material Icon | HugeIcon equivalent |
|---|---|
| `Icons.eco` | `HugeIcons.strokeRoundedLeaf01` |
| `Icons.storefront_outlined` | `HugeIcons.strokeRoundedStore02` |
| `Icons.restaurant_outlined` | `HugeIcons.strokeRoundedRestaurant02` |
| `Icons.soup_kitchen_outlined` | `HugeIcons.strokeRoundedChefHat` |
| `Icons.add_shopping_cart` | `HugeIcons.strokeRoundedShoppingCart01` |
| `Icons.search` | `HugeIcons.strokeRoundedSearch01` |
| `Icons.place_outlined` | `HugeIcons.strokeRoundedLocation01` |
| `Icons.radar` | `HugeIcons.strokeRoundedRadar01` |
| `Icons.notifications_none_rounded` | `HugeIcons.strokeRoundedNotification01` |
| `Icons.star_rounded` | `HugeIcons.strokeRoundedStar` |
| `Icons.check_circle_outline` | `HugeIcons.strokeRoundedCheckmarkCircle01` |
| `Icons.inventory_2_outlined` | `HugeIcons.strokeRoundedPackageOpen` |
| `Icons.call_outlined` | `HugeIcons.strokeRoundedCall` |
| `Icons.directions_outlined` | `HugeIcons.strokeRoundedRoute01` |
| `Icons.vpn_key_outlined` | `HugeIcons.strokeRoundedKey01` |
| `Icons.receipt_long_outlined` | `HugeIcons.strokeRoundedReceipt` |
| `Icons.trending_down` | `HugeIcons.strokeRoundedTrendDown` |
| `Icons.verified_rounded` | `HugeIcons.strokeRoundedVerified` |
| `Icons.bolt` | `HugeIcons.strokeRoundedFlash` |
| `Icons.schedule` | `HugeIcons.strokeRoundedClock01` |
| `Icons.arrow_forward_rounded` | `HugeIcons.strokeRoundedArrowRight01` |
| `Icons.logout` | `HugeIcons.strokeRoundedLogout01` |
| `Icons.person_outline` | `HugeIcons.strokeRoundedUser01` |
| `Icons.add` | `HugeIcons.strokeRoundedAdd01` |
| `Icons.edit_outlined` | `HugeIcons.strokeRoundedPencilEdit01` |
| `Icons.help_outline` | `HugeIcons.strokeRoundedHelpCircle` |
| `Icons.volunteer_activism_outlined` | `HugeIcons.strokeRoundedHandHoldingSmartphone` |
| `Icons.delivery_dining` | `HugeIcons.strokeRoundedDeliveryTruck01` |
| `Icons.payments_outlined` | `HugeIcons.strokeRoundedWallet01` |
| `Icons.timelapse` | `HugeIcons.strokeRoundedHourglass` |

### 2.5 Motion Principles

- Page transitions: fade + 3% upward slide, `easeOutCubic`, 280ms
- Cards on list load: staggered `FadeSlideIn` — 45ms between each, max 8 staggered
- Button press: `AnimatedScale` 0.97, 110ms `easeOut`
- Hero shared element: produce image flies from market card → product detail page
- State changes (badge count, status chips): `AnimatedSwitcher` 200ms
- Cart badge pop: `AnimatedScale` with `easeOutBack` curve on count change
- Bottom sheet entry: slide from bottom, `easeOutCubic`, 320ms

---

## 3. NAVIGATION ARCHITECTURE

### 3.1 Bottom Navigation — All Three Roles

**Shape:** Floating pill-shaped bottom nav, rounded top corners (26px), white background, soft top shadow `(0, -4, 20, black 8%)`, 70px height.

**Active indicator:** Green pill (`primarySurface` bg + `primary` icon/label).

**Buyer (Hotel) Nav — 4 tabs:**
1. 🌿 Market (home)
2. 📋 My Orders
3. 💚 Impact
4. 👤 Profile

**Seller (Vendor) Nav — 3 tabs:**
1. 📦 Dashboard
2. 🧾 Orders
3. 👤 Profile

**Cook (NGO) Nav — 3 tabs:**
1. 📥 Rescues
2. 🌍 Impact
3. 👤 Profile

---

## 4. AUTH SCREENS

### 4.1 Splash Screen

**Layout:**
- Full-screen white background
- Center: Large green circle (120×120px) with a Revivo leaf icon (HugeIcons)
- Below: "Revivo" in Poppins ExtraBold 34px, black
- Below: "Reviving value before waste" in Poppins Medium 14px, textMuted
- Bottom: Thin green progress bar (3px, pill ends, 140px wide) with shimmer animation
- Below bar: "CONNECTING HARVESTS" in Poppins SemiBold 10px, letter-spacing 2, textMuted
- Animated: logo fades + scales in (0→1, 400ms), text slides up from below (60ms delay), progress bar fills over 1.4s

**Fix needed:** Add entrance animation — currently static.

---

### 4.2 Role Selection Screen

**Layout:**
- White background
- Top: Revivo logomark (30px circle) + "Revivo" wordmark, top-left
- "Choose your\nrole" — Poppins ExtraBold 28px, line-height 1.2
- Subtitle: 13.5px textSecondary
- Three role cards (vertical list, 12px gap):

**Each Role Card:**
- White card, `borderRadius: 20`, soft shadow
- Left: 52×52px green rounded square icon container (`primarySurface` bg, `primary` icon 26px HugeIcon)
- Middle: Role name (Poppins Bold 16px) + tagline (12.5px textSecondary)
- Right: Custom radio — outer circle 22px, inner green dot when selected
- Selected state: entire card gets `primarySurface` bg + green 1.5px border

**Role labels + taglines:**
- **Vendor** (Seller) — "I sell surplus vegetables from my farm / godown"  
- **Hotel Kitchen** (Buyer) — "I buy fresh surplus for my kitchen / restaurant"  
- **NGO / Rescue Kitchen** (Cook) — "I pick up unsold food and turn it into meals"  

**Bottom:** Full-width green pill CTA "Continue →" (disabled until selection made)

---

### 4.3 Login Screen

**Layout:**
- White background, padding 24px
- Top center: 72×72 green circle logo + "Revivo" (22px 800) + "Reduce waste, grow business" (13px textSecondary)
- "Login as [Role]" heading below — 20px 700
- Email field: HugeIcon mail prefix, rounded 16px input
- Password field: HugeIcon lock prefix, eye toggle suffix
- "Forgot password?" right-aligned link in primary green
- Green pill CTA "Login as [Role]" full width
- Divider "OR CONTINUE WITH"
- Google / Apple buttons (outlined, 50% width each)
- "Don't have an account? **Register**" — Register is green

**Fix needed:** Make the role shown on the button visually match the selected role from the previous screen (show role icon next to label).

---

### 4.4 Register Screen

Same layout as Login. Fields: Name, Email, Password, Confirm Password. CTA: "Create account as [Role]"

---

## 5. BUYER / HOTEL KITCHEN SCREENS

### 5.1 Buyer Home — Market Screen

**Current issues to fix:**
- "Ending live soon" rail is broken / not showing
- Rescue Radar entry shows but tapping shows empty
- Filters (chips row) look plain — needs better visual representation
- Search field is basic — needs better treatment

**Redesigned Layout:**

**Header (not in AppBar — custom):**
- Left: Green circle avatar (44px) with restaurant HugeIcon
- Center: "Good morning, [Name]" in Poppins Bold 17px, "Coimbatore · surplus nearby" in 11.5px textMuted with location HugeIcon
- Right: Notification bell (HugeIcon) + Cart icon with animated badge

**Live Strip (below header, 8px gap):**
- Green pulsing dot + "LIVE" label (10px, letterSpacing 1.5, primary green)
- Then: "X.X kg from N vendors today" in 11.5px textSecondary
- Placed in a subtle `primarySurface` rounded pill container

**Rescue Radar Banner (always visible, never skip):**
- Green gradient card (primary → primaryDark), `borderRadius: 20`
- Left: Radar HugeIcon in white circle (40×40, 20% white bg)
- Title: "Rescue Radar" Poppins Bold 14px white
- Subtitle: "N surplus lots near your hotel" 11.5px white 90% opacity
- Right arrow HugeIcon in white
- FIX: This card must ALWAYS load offers first (watch `offersProvider`) and show actual count — currently count shows 0 because offers haven't loaded yet when the widget builds. Use `offers.when(data: ...)` to show the real count.

**"Ending Soon" Horizontal Rail — FIX THIS:**
- Currently broken because `_endingSoon()` filters for non-`good` band offers, but all demo offers are in `good` band  
- Fix: Show the rail for offers where `expiresAt` is within 6 hours OR `liveBand() != good` — whichever gives more results
- If still empty, show all offers sorted by soonest expiry as "Live deals" 
- Rail design: `SizedBox(height: 160)`, `ListView.builder` horizontal, each card 140px wide
- Mini offer card: produce image top, veg name + price + countdown pill, gradient overlay at bottom
- Horizontal padding: 16px screen + 8px between cards

**Search Field (redesigned):**
- Floating search bar: white card, shadow, `borderRadius: 100` (pill shape), 52px height
- HugeIcon search inside on left, "Search vegetables, vendors..." hint
- Clear X button appears on right when typing
- When focused: expand slightly (AnimatedContainer), show recent searches below as chips

**Category Chips (redesigned):**
- Replace plain `ChoiceChip` with custom horizontal scroll row
- Each chip: small emoji + label, `borderRadius: 100`
- Selected: `primary` bg, white text, slight scale-up animation
- Unselected: `surfaceAlt` bg, `textSecondary`
- Categories: 🥬 All · 🍅 Leafy · 🥕 Root · 🌶️ Spices · 🥦 Gourd

**Filter Tabs (redesigned):**
- Replace `ChoiceChip` row with a sliding pill indicator (like a tab bar)
- Tabs: All · Rescue Deals · Saved · Organic · Nearby
- Rescue Deals tab gets a red dot badge when there are rescue-band offers
- Saved tab gets heart icon prefix

**Offer Cards List (staggered FadeSlideIn already done — keep):**
- Cards: white, `borderRadius: 20`, soft shadow, no border
- Image: top 132px, rounded top corners only, produce image with tinted overlay
- On image: Distance pill (top-left), Organic tag (top-left), Heart button (top-right), freshness countdown pill (bottom-right), "X% off" green badge (bottom-left)
- Below image: Vendor name + trusted badge + star rating pill
- Veggie name in Poppins Bold 15.5px
- Price row: "₹X/kg" in primary green 15px 800 + strikethrough market price + "Xkg left" right-aligned

**Bottom:** `CartBar` floating pill (already designed — keep)

---

### 5.2 Product Details Screen

**Current state:** Good structure, needs polish.

**Redesigned layout:**

**Image Hero (220px tall):**
- Full-width, `borderRadius: 20` only at bottom (so it bleeds to top edge of screen)
- Produce image with freshness-tinted overlay
- Back arrow button (top-left, white circle 40px, slight shadow)
- Heart (favorite) button (top-right, white circle 40px)
- Freshness countdown pill (bottom-right)
- Share button (top-right, next to heart)
- Hero animation tag: `'offer-${offer.id}'` (already done — keep)

**Content below image (padding 20px):**
- Vendor row: Avatar circle (green, 32px) + vendor name clickable + ">" + star rating pill
- Vegetable name: Poppins ExtraBold 24px
- Price row: "₹X / kg" in primary 22px 800 + strikethrough + "X% below market" green pill

**Freshness Clock Card** (tinted bg, already good — keep design):
- Band color bg, big countdown timer in 36px 800
- "Drops to ₹X/kg in mm:ss" with trending-down HugeIcon

**Quality Card:** keep

**Quantity Stepper Card:**
- Cleaner stepper: "-" and "+" are green circle buttons (44×44), quantity in center 20px 800
- "X kg available" caption below

**Savings Summary:** keep structure, improve typography

**CTA:**
- Full-width green pill "Add to cart · ₹X" — 56px height, Poppins Bold 16px

---

### 5.3 Cart Screen

**Layout:**
- AppBar: "My Cart" + item count badge
- Cart items list: each item is a card with produce name, quantity stepper (inline -/+), price, remove button (trash HugeIcon)
- Coupon section: pill-shaped input field + "Apply" green button
- Bill summary section at bottom of list
- Sticky bottom: "Checkout · ₹total" green pill CTA

---

### 5.4 Checkout Screen

- Delivery/Pickup slot selector (chip-based time slots)
- Payment method selector: UPI / Card / Revivo Wallet / Pay on pickup — radio cards
- Wallet balance shown if credits available with "Use ₹X credits" toggle
- Order summary
- "Place Order" green pill CTA at bottom

---

### 5.5 Order Confirmed Screen

**Layout:**
- Green checkmark animation (Lottie or custom AnimatedBuilder) at top center
- "Order placed!" Poppins ExtraBold 26px
- Order ID in a pill chip
- "Track your order" button → Order Tracking Screen
- "Continue shopping" text link

---

### 5.6 My Orders Screen

**Current issues:** Plain list, no visual hierarchy. Fix:

**Redesigned layout:**
- Active orders section at top: each card prominent with colored status chip
- Completed orders below: slightly muted cards
- Pull to refresh

**Order Card (redesigned):**
- White card, `borderRadius: 20`, soft shadow
- Top row: Veggie name (Bold 16px) + Status chip (colored pill — confirmed=blue, preparing=amber, ready=green, completed=gray)
- Second row: Vendor name + "· Xmins ago"
- Divider
- Meta row: Qty · Total · Saved (in primary green)
- Bottom row: Pickup slot (with clock HugeIcon) + "Track Order →" primary text button (active only)
- Completed orders show "Rate this rescue ⭐" or rating stars if already rated

---

### 5.7 Order Tracking Screen ⭐ (Key Screen — Zomato Style)

**This is the showcase screen — make it stunning.**

**Top section — Live Map (180px):**
- Custom-painted map canvas (already exists as `_MapGridPainter`) — make it look much better:
  - Dark green grid lines on `primarySurface` background
  - Green pulsing dot for "You are here" (hotel)
  - Moving truck icon (`HugeIcons.strokeRoundedDeliveryTruck01`) animating along a path
  - Vendor location marker (leaf HugeIcon, green circle)
  - Subtle animated ping circles emanating from the truck
- "On the way · ~N mins" or "Ready for pickup" floating label over map (white pill, shadow)

**Order Header (below map):**
- Icon tile (48×48, rounded 16px, green or blue bg) + Veg name + quantity + vendor name

**Status Timeline (Zomato style — the core tracker):**
4 steps: Order Placed → Vendor Preparing → Ready for Pickup → Completed  
Each step:
- Circle indicator: done=filled green with checkmark, active=green with inner dot + pulsing ring animation, todo=gray outline
- Vertical connector line: green for done steps, dashed gray for upcoming
- Step title (Bold 14px) + subtitle (12px textMuted)
- Active step: title in `textPrimary`, with a live-updating sub-text like "Preparing your 5kg Tomatoes..."

**Handover Code (shown when order is active, not completed):**
- Large prominent card with `primarySurface` bg
- Key HugeIcon + "Show this code at pickup" label
- Code: 4-digit number in Poppins ExtraBold 32px, `primary` color, letter-spacing 8px
- "The vendor will scan this to confirm handover"

**Pickup Info Card:**
- Clock HugeIcon + slot time
- Location HugeIcon + vendor address
- Two buttons: "Directions" (outlined) + "Call Vendor" (outlined)

**Bill Card:** keep current structure, improve typography

**Completed state only — Impact Receipt:**
- Green gradient banner: "🌱 You rescued X kg!" + "Saved ₹X vs market"
- Rate this rescue section: star tapper + tag chips

---

### 5.8 Rescue Radar Screen ⭐ (FIX — Currently Shows Empty)

**Root cause:** `offersProvider` is an `AsyncNotifier` — the radar screen reads `offersProvider.valueOrNull` which is null on first build before the future resolves. The `CustomPaint` then renders with 0 dots.

**Fix:** Wrap the radar widget in `offers.when(loading: ..., data: (offers) => _radar(...))` — never pass empty list to the painter.

**Redesigned Layout:**

**Full-screen radar view:**
- Replace the scrollable `ListView` layout with a hero radar display:
- Top 60% of screen: the animated radar canvas (already good painter — keep) but make it bigger
- Bottom 40%: horizontal scroll list of nearby offer cards

**Radar Canvas improvements:**
- Backdrop: `primarySurface` 40% with subtle noise texture
- Range rings: green 22% opacity, dashed stroke
- Sweep gradient: green comet with longer trail
- Center marker: green circle with hotel HugeIcon + "YOU" label below
- Offer dots: larger (32×32px), show mini produce emoji or first letter in white
- Tapping a dot: shows a bottom sheet with the offer card (not navigate away)

**Bottom list:**
- "N lots within 3.5 km" section header
- Horizontal scrollable mini-cards (each 160px wide, 200px tall)
  - Produce image top half
  - Name + price + distance below
  - Freshness band colored bottom border
  - Tap → Product Details

---

### 5.9 Vendor Profile Screen

- Header: vendor name, rating stars, order count, trusted badge
- Produce listings from this vendor
- Review section

---

## 6. SELLER / VENDOR SCREENS

### 6.1 Seller Dashboard Screen ⭐

**Current state:** Basic list with stat tiles. Needs full redesign.

**Redesigned Layout:**

**Header:**
- Left: Green circle avatar (44px) with store HugeIcon
- Name + "SURPLUS COMMAND CENTER" label (10px, letter-spacing 1.5, textMuted)
- Right: Notification bell HugeIcon

**Stats Row (2 cards, side by side):**
Each stat card: white card, shadow, `borderRadius: 20`
- Left: Total Listings — value in 26px 800 + "live now" tag
- Right: Sold Today — "X kg" value + "N orders" tag

**Revenue at Risk Widget** (keep logic, redesign visual):
- Only shows when there are at-risk items
- Orange→Red gradient card, `borderRadius: 20`, 100% width
- Top row: "⚠ Revenue at Risk" title + total ₹ amount (white, 24px 800)
- "₹X already lost to decay" in white 70% opacity
- Per-lot nudge cards below (white cards inside the gradient card):
  - Veg name + freshness pill + countdown
  - Two buttons: "Route to rescue" (outlined white) + "Sold out" (text)
- "All clear" state: green card with checkmark + "No items at risk right now"

**"Your Inventory" Section Header + "Add listing" link:**
- Section title left + "Add +" right (green text button)

**Listing Cards (redesigned — currently plain):**
Each card: white, `borderRadius: 20`, shadow, `Pressable` wrap
- Left: 64×64 produce image with freshness-tinted overlay
- Center: Veg name (Bold 16px) + Qty remaining (12px textMuted)
- Right: Live price "₹X/kg" (green 15px 800) + freshness band pill
- Below: Progress bar showing freshness % remaining (green→amber→red gradient)
- Tap → goes to Update Stock Screen (new)
- Long press or swipe: reveal "Route to rescue" action

**Staggered FadeSlideIn** for listing cards (same as buyer market)

**FAB:** Green circle "+" with add HugeIcon, bottom-right, opens Add Listing Screen

---

### 6.2 Add Listing Screen

**Current state:** Works but looks plain.

**Redesigned Layout:**
- AppBar: "List Surplus Produce" + back
- Photo capture section at top: dashed border rectangle (like Instagram), camera HugeIcon centered, "Add produce photo" text, tapping opens camera/gallery; after selection shows preview with circular X remove button (top-right)
- Produce type picker: large horizontal scroll row of pill chips with emoji — "🍅 Tomato", "🥔 Potato" etc. Selected = green pill
- Storage condition: 3 icon cards (Room / Cold / Frozen)
- "When did you buy it?" — styled radio list (purchase options)
- Quantity field: styled number input with kg suffix + quick quantity pills (2kg, 5kg, 10kg, 25kg, 50kg)
- **Live Freshness Preview Card** (the wow moment):
  - Updates in real time as you fill in the form
  - Shows: current band chip + "Live price ₹X/kg" + "Market price ₹X/kg" + "Expires in Xh"
  - Tinted background matching the band color
- CTA: "List for ₹X/kg" green pill

---

### 6.3 Update Stock Screen ⭐ (NEW SCREEN)

**Currently:** Update stock opens inline in the dashboard. User wants a DEDICATED FULL SCREEN.

**Route:** `/seller/update-stock` (already registered in router with `Listing extra`)

**Layout:**
- AppBar: "Update Stock — [Veg name]" + back button
- Top hero: existing listing's produce image (160px tall, full width, clipped)
- Listing summary card: veg name, current freshness band pill, current price, expires at time

**Editable fields:**
1. **Current Quantity** — large stepper widget:
   - Minus button (38px circle) · qty display (28px 800) · Plus button (38px circle)
   - Quick set buttons row: "0 (Sold out)", "5 kg", "10 kg", "25 kg"
   - Subtitle: "X kg currently listed"

2. **Storage Condition update** — 3 icon cards (Room / Cold / Frozen), horizontally spaced

3. **Photos** (optional) — "Update photo" button, shows current photo thumbnail if exists

**Live Impact Preview** (same as Add Listing — updates as qty/storage changes):
- New estimated price, new band, "Route to rescue?" prompt if band is rescue

**Action Buttons (bottom, side by side):**
- "Save changes" — full-width green pill (primary CTA)
- "Route to rescue" — outlined green pill (secondary) — creates rescue + removes from buyer market
- "Mark as sold out" — text button in danger red — sets qty to 0

**Confirmation toast** on save: floating snackbar "Stock updated · ₹X/kg live"

---

### 6.4 Seller Orders Screen

**Current state:** Has good structure, needs design polish.

**Redesigned Layout:**
- No AppBar title — custom header matching dashboard style
- "Incoming Orders" title (22px 800) + "Live from hotels — first come, first served" subtitle
- Segment control: "To Fulfil (N)" / "Completed (N)" — pill tab switcher

**Order Card (redesigned):**
- White card, `borderRadius: 20`, shadow
- Top: Buyer name (Bold 16px) + Status chip pill (right-aligned)
- Veg name + "X kg · ₹X/kg" in textMuted
- Divider
- Freshness band chip (left) + Total amount (₹X bold 18px, right)

**Active order actions (to-fulfil only):**
- Handover Code row:
  - Left: White pill with key HugeIcon + "Code XXXX" (bold, letter-spacing 2)
  - Right: "Track" outlined button + "Call" outlined button (icon only)
- Full-width green pill action button:
  - "Mark ready for pickup" (when confirmed/preparing)
  - "Mark handed over" (when readyForPickup) — with checkmark icon

---

### 6.5 Seller Insights Screen

- Charts for weekly revenue, band breakdown, top produce
- HugeIcon trendUp for revenue, package for inventory

---

## 7. COOK / NGO RESCUE KITCHEN SCREENS

### 7.1 Cook Inbox Screen ⭐ (Operations Console)

**Current state:** Has 3-segment control, needs full visual polish.

**Redesigned Layout:**

**Header:**
- Left: Green circle avatar with chef hat HugeIcon
- NGO name + "RESCUE KITCHEN" label
- Right: Radar HugeIcon button (navigates to Rescue Radar) + Notification bell

**Segment Control (Available / My Pickups / Delivered):**
- 3-tab pill switcher — full width, `borderRadius: 16`
- Selected: `primary` bg, white text, count badge (white pill, 25% opacity bg)
- Unselected: `surfaceAlt` bg, `textSecondary`
- Count badges update live

**AVAILABLE tab:**
- Stats row: "N new rescues · Nearby" card + "~N meals available · Today" card
- Rescue cards sorted by urgency (rescue band first, then nearest)

**MY PICKUPS tab:**
- Rescue cards with:
  - Nav row: "Directions · X km" full-width outlined button + "Call" icon button
  - Action button: lifecycle-appropriate CTA

**DELIVERED tab:**
- Rescue cards with meal proof state:
  - Logged: green `primarySurface` pill "✓ N meals served" (with photo badge if photo exists)
  - Not logged: "Log meals served" outlined button

**Rescue Card (redesigned):**
- White card, `borderRadius: 20`, shadow
- Top: Freshness band colored left border (4px) — visual urgency indicator
- Vendor name (Bold 15px) + distance pill (right)
- Produce: "Xkg [Veg]" with band chip
- Estimated meals: "~N meals" in `primarySurface` green pill
- NGO accepted by: shown in My Pickups tab
- Action area at bottom: CTA buttons

---

### 7.2 Meal Log Sheet (Bottom Sheet)

**Current state:** Works, needs visual polish.

**Redesigned layout:**
- Bottom sheet handle (gray pill, centered top)
- "Log meals served" title (17px 800)
- "Rescue: X kg [Veg] from [Vendor]" subtitle
- Photo section: large dashed rectangle (200×140px) — shows camera icon if no photo, shows preview if captured; small X to remove
- Meals count input: large centered number input (44px font), "estimated meals served" label below, - / + stepper buttons on sides
- "Submit meal proof" green pill CTA
- "Skip for now" text button below

---

## 8. SHARED / PROFILE SCREENS

### 8.1 Profile Screen (Role-Aware)

**Current state:** Good structure, needs visual uplift.

**Redesigned Layout:**

**Hero Identity Section:**
- Green gradient header band (primary→primaryDark) at top, 180px tall, with leaf pattern texture (CSS-style)
- Large avatar: 72px circle, white bg, initial letter in primary green 28px 800
- Name below: 20px 800, white
- Role badge below: "Hotel Kitchen" / "Surplus Vendor" / "Rescue Kitchen" in white 80% opacity 12px
- Email in white 60% opacity 11px

**Ledger Card (role-aware value card):**
- Green gradient card (keep current design — already good)
- Buyer: "Revivo Credits" + ₹X balance + "1 credit / ₹10 saved" pill
- Seller: "Recovered from waste" + ₹X revenue + "Xkg sold" pill
- Cook: "Meals served" + ~N count + "N rescues" pill

**Trust / Verification Card:**
- `primarySurface` bg card
- Verified HugeIcon + "Trusted Vendor" / "Verified Partner"
- For sellers with ratings: star rating (X.X) + "X ratings"

**Stats Row (2 tiles):** keep, improve typography

**Milestones (Badges):**
- Grid of milestone chips (3 per row)
- Earned: `primarySurface` bg, primary icon, bold title
- Unearned: `surfaceAlt` bg, muted icon, muted title
- "X / Y earned" progress shown as a thin green progress bar at top of section

**Menu Items Card:**
- White card, `borderRadius: 20`
- Each item: HugeIcon (left, textSecondary) + label + right arrow HugeIcon
- Dividers between items
- Items: Account Details · Notifications · Refer & Earn · Help & Safety

**Sign Out Button:**
- Bottom: danger-red outlined pill button, full width, logout HugeIcon

---

### 8.2 Impact Screen

- Total kg saved counter (large hero number)
- CO₂ equivalent saved
- Meals enabled (for cook role: meals served)
- Weekly bar chart

---

### 8.3 Notification Center

- Grouped by Today / Earlier
- Each notification: icon in colored circle + title + time ago
- Unread: subtle `primarySurface` background tint

---

### 8.4 Account Details Screen

- Edit name, phone, address
- Profile photo update
- Save button

---

## 9. CROSS-ROLE FLOW INTEGRATION

This section defines how the 3 roles connect — judges will look for this.

### 9.1 The Sell → Buy Flow

1. **Seller** adds listing (Add Listing Screen) → appears in **Buyer** Market Screen
2. **Buyer** sees offer, taps → Product Details → Add to Cart → Checkout → Order placed
3. **Seller** sees new order in Seller Orders Screen (polls every 8s)
4. **Seller** taps "Mark ready for pickup" → status updates
5. **Buyer** sees "Ready for pickup" on Order Tracking Screen
6. **Buyer** arrives, shows 4-digit handover code to Seller
7. **Seller** taps "Mark handed over" → order completed
8. **Buyer** can rate the seller (feeds into Trusted Vendor score)

**Visual cue:** The same handover code (e.g., "7284") appears on:
- Seller Orders Screen: in a white pill "Code 7284"
- Buyer Order Tracking Screen: in a large green pill "Show this code at pickup · **7284**"

### 9.2 The Rescue Flow

1. Seller's item ages past USE_SOON into RESCUE band → Revenue at Risk widget fires
2. **Seller** taps "Route to rescue" on Dashboard → creates rescue lot + removes from buyer market
3. **Cook** sees new rescue in Available tab (Cook Inbox)
4. Cook taps "Accept ~N meals" → appears in My Pickups
5. Cook taps "Start pickup" → "Mark collected" → "Mark delivered"
6. Cook logs meal count + optional photo → Delivered tab shows verified badge
7. All parties see the impact in their Profile → Impact Screen

### 9.3 Status Chip Color Mapping (Consistent across all 3 roles)

| Status | Color | HugeIcon |
|---|---|---|
| Confirmed | Blue (`#3B82F6`) | `strokeRoundedCheckmarkCircle01` |
| Preparing | Amber (`#F59E0B`) | `strokeRoundedPackageOpen` |
| Ready for Pickup | Green (`#1FBF61`) | `strokeRoundedStore02` |
| Completed | Gray (`#9CA3AF`) | `strokeRoundedTick01` |
| Rescue Offered | Orange (`#F97316`) | `strokeRoundedFlash` |
| Rescue Accepted | Blue | `strokeRoundedHandHoldingSmartphone` |
| Rescue Picked Up | Amber | `strokeRoundedDeliveryTruck01` |
| Rescue Delivered | Green | `strokeRoundedVerified` |

---

## 10. KEY BUGS TO FIX

### Bug 1 — "Ending Soon" Rail is Empty
**Location:** `buyer_market_screen.dart` → `_endingSoon()` method  
**Root cause:** Filters for `liveBand() != good`, but all seeded demo offers have `liveBand() == good` because their `expiresAt` is far in the future.  
**Fix:** Show all offers sorted by closest expiry as "Deals Today" rail, regardless of band. OR: for demo purposes, seed 2–3 offers with `expiresAt = DateTime.now().add(Duration(hours: 2))` so they show as USE_SOON/RESCUE.

### Bug 2 — Rescue Radar Shows No Dots
**Location:** `rescue_map_screen.dart` → `_RescueMapScreenState.build()`  
**Root cause:** `ref.watch(offersProvider).valueOrNull` returns null on first frame. `plotted` is empty. `CustomPaint` draws rings but no dots.  
**Fix:** Change build logic to:
```dart
offers.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => Center(child: Text('Error: $e')),
  data: (offers) {
    final plotted = offers.where((o) => !o.isExpired()).take(14).toList();
    return _radarBody(plotted);
  },
)
```

### Bug 3 — Update Stock Opens No Screen
**Location:** `seller_dashboard_screen.dart` → `_editStock()`  
**Current:** Calls `context.push('/seller/update-stock', extra: listing)` but the route exists; need to verify `update_stock_screen.dart` exists and is wired.  
**Fix:** Ensure `UpdateStockScreen` is a full standalone screen (not a bottom sheet).

### Bug 4 — Static Map on Order Tracking Is Not Animated
**Location:** `order_tracking_screen.dart` → `_MapGridPainter`  
**Fix:** Add animated truck icon and pulsing markers using `AnimationController`.

### Bug 5 — Cart Badge Doesn't Show on First Item Add
**Location:** `buyer_market_screen.dart` → `_CartButton`  
**Check:** `AnimatedScale` is wired to `count > 0 ? 1 : 0` — this should work. If not: wrap with `AnimatedSwitcher` as fallback.

---

## 11. NEW SCREENS TO BUILD

### 11.1 Order Tracking Screen — Demo Enhancement
Already exists at `/buyer/track`. Enhance the map section with:
- Better animated canvas (truck moving, pulse rings)
- Cleaner Zomato-style step timeline with pulsing active step

### 11.2 Update Stock Screen (Full Screen)
New file: `app/lib/features/seller/update_stock_screen.dart`  
Route: `/seller/update-stock` with `Listing` as extra  
(File exists but may be a stub — make it a fully designed screen per section 6.3)

### 11.3 Seller Order Tracking Screen (Demo)
**Purpose:** When seller taps "Track" on an order card, they should see the same Zomato-style map/timeline but from the seller's POV.  
**Layout:** Same as `OrderTrackingScreen` but read-only — no rate/handover code shown to seller, just the live timeline and the buyer's pickup slot.  
Route: `/seller/track` with `Order` as extra  

---

## 12. ANIMATION CHECKLIST

All of these should be in the final redesign:

- [ ] Splash: logo fade-scale in + progress bar fill
- [ ] Role select: cards FadeSlideIn staggered (80ms apart)
- [ ] Market: FadeSlideIn stagger on offer cards (already done)
- [ ] Market: `AnimatedScale` easeOutBack on cart badge (already done)
- [ ] Offer card: `Pressable` scale on press (already done)
- [ ] Market → Product: Hero image fly animation (already done)
- [ ] Seller dashboard: FadeSlideIn stagger on listing cards
- [ ] Cook inbox: FadeSlideIn stagger on rescue cards per segment switch
- [ ] Order tracker: Pulse animation on active timeline step
- [ ] Order tracker: Truck/delivery icon moving on map
- [ ] Status chips: `AnimatedSwitcher` on status change
- [ ] Bottom nav: pill indicator slides smoothly between tabs
- [ ] Segment controls (Cook): sliding pill indicator
- [ ] Page transitions: fade + rise (already done)

---

## 13. PUBSPEC DEPENDENCIES (Current)

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  go_router: ^14.6.2
  google_fonts: ^6.2.1        # Poppins — already added
  hugeicons: ^0.0.7            # ADD THIS for HugeIcons
  image_picker: ^1.1.2
  url_launcher: ^6.3.1
  http: ^1.2.2
  shared_preferences: ^2.3.3
  intl: ^0.19.0
```

**To add HugeIcons:**
```yaml
hugeicons: ^0.0.7
```
Then run `flutter pub get`.

Import in files: `import 'package:hugeicons/hugeicons.dart';`  
Usage: `HugeIcon(icon: HugeIcons.strokeRoundedLeaf01, color: Colors.white, size: 24)`

---

## 14. SUMMARY — WHAT THE REDESIGN MUST DELIVER

1. **Visual identity:** Every screen feels Zomato/Swiggy premium — green-dominant, Poppins, soft shadows, no hard borders, rounded everything
2. **HugeIcons everywhere** — replace all Material icons
3. **Buyer Market:** Fixed "Ending Soon" rail, fixed Rescue Radar, better search + filter representation
4. **Order Tracking:** Animated map, Zomato-style step timeline with pulsing active state, handover code prominently displayed
5. **Seller Dashboard:** Full redesign, listing cards with freshness progress bar
6. **Update Stock:** Dedicated full screen (not inline)
7. **Cook Console:** Polished 3-segment with urgency-sorted rescue cards, better meal log sheet
8. **Profile:** Green gradient hero header, role-aware ledger card, milestone badges grid
9. **All 3 flows connected visually** — handover code appears in both seller and buyer screens
10. **Animations:** Every interaction has micro-feedback — press, scroll, state change, page transition

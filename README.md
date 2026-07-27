# NoWaito — MVP Codebase v3 (Flutter, fully fixed)

## What was fixed in this version

### Mobile app — all screens fully wired to backend

| Issue | Fixed |
|---|---|
| Driver card showed hardcoded name/vehicle | Real driver fetched from `/api/drivers/{id}` after assignment |
| "Rate Manjunath R." hardcoded on Trip Complete | Real driver name from API |
| SOS button did nothing | Calls `tel:112` via url_launcher |
| Share trip button did nothing | Opens WhatsApp with real trip + driver details |
| Bottom nav tabs did nothing | All 4 tabs on both apps fully wired to routes |
| No in-app notifications | `flutter_local_notifications` integrated — 8 notification triggers |
| Emergency cancel quota hardcoded "1 of 1" | Real quota derived from `Driver.emergencyCancelAvailable` |
| `_openSheet()` race condition | Quotes fetched first, sheet opened only after load completes |
| Wrong `BuildContext` on booking | `GoRouter` captured before sheet opens; sheet uses its own context |
| `withOpacity` deprecation warnings | All replaced with `withValues(alpha:)` |
| Missing Android 13+ notification permission | `POST_NOTIFICATIONS` + `CALL_PHONE` added to manifest |
| Missing screens (Trips, Wallet, Profile, Earnings) | All 4 screens created and fully wired |

### New screens added
- **Rider Trips** — trip history list (empty state + list)
- **Rider Wallet** — payment methods + Safe Pass subscription tiers
- **Rider Profile** — settings, support, notification toggles
- **Driver Earnings** — daily earnings, vs Ola/Uber comparison, weekly chart
- **Driver Profile** — documents, zone pass status, support

### New service added
- `NotificationService` — in-app local notifications for:
  - Driver assigned (rider side)
  - Driver arrived (rider side)
  - Trip started (rider side)
  - Trip complete with amount (rider side)
  - Safety check prompt at +5 min (rider side)
  - New ride assigned (driver side)
  - Trip complete with earnings (driver side)
  - Rider cancelled / no-show (driver side)

---

## Running locally

### 1. Backend
```bash
docker compose up -d
cd backend
# IntelliJ: set Active profiles = free-cloud, add env vars, click Run
# OR PowerShell with Maven installed:
# mvn spring-boot:run -Dspring-boot.run.profiles=free-cloud
```

### 2. Mobile app
```bash
cd mobile
flutter pub get
flutter run
```

**Physical device:** edit `mobile/.env` and set:
```
API_BASE_URL=http://YOUR_LAN_IP:8080
```
Your phone and laptop must be on the same WiFi.

### 3. Ops web
```bash
cd ops-web
npm install && npm run dev
```

---

## End-to-end test flow

1. App opens → Role Select → **Continue as Rider** → enter phone → use dev OTP from backend console
2. Rider Home → tap drop field → sheet opens with real prices from API → select vehicle → **Book**
3. Active Trip screen polls every 2.5s — watch status update in real time
4. In a second session → **Continue as Driver** → log in → **Go Online**
5. Assignment engine matches → Driver gets in-app notification → Active Ride screen shows trip
6. Driver: **Mark Arrived** → **Start Trip** → **Complete Ride**
7. Rider: auto-navigates to Trip Complete → safety check notification at +5s → rate driver

---

## Free-tier services
| Service | Provider | Config |
|---|---|---|
| Database | Supabase (free) | `SUPABASE_DB_*` env vars |
| Redis | Upstash (free) | `UPSTASH_REDIS_*` env vars |
| Payments | Razorpay test mode | `RAZORPAY_*` env vars |
| Notifications | flutter_local_notifications | No signup needed |
| Maps | Placeholder (Mapbox when ready) | Add token to `.env` |

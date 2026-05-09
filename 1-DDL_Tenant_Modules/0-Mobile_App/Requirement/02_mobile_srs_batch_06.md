# Mobile SRS — Batch 06 (Fees · Transport)

> Index: `02_mobile_srs_index.md`. Features: F-060, F-061, F-062, F-070, F-071, F-072, F-073.

---

## F-060: Fee Summary & Dues (Student / Parent)

### 1. Overview
Read-only fee summary: outstanding amount, breakup by head, due-dates, partial payments. **Hard pre-req:** SR-AUTH-001 (fee endpoint ownership) — BG-12.

### 2. User Stories
- **US-060.1** *As a parent fee-payer, I see "₹12,500 due by 15 May".*
- **US-060.2** *Tap → invoice detail with line items + receipts of past payments.*
- **US-060.3** *Edge — non-fee-payer parent reading another parent's invoice → 403.*

### 3. Functional Requirements
- **FR-060.1** Endpoint authorizes by guardian binding + `is_fee_payer=1` (or student self).
- **FR-060.2** Returns: open invoices, paid invoices, allocations, partial-payment splits.
- **FR-060.3** Detail: invoice header + line items + payment history.
- **FR-060.4** Soft deletes filtered.

### 4. Screen Specifications

#### S-060.1 — Fees summary
```
┌──────────────────────────────────┐
│ Fees · Asha (VII-B)               │
│ ──────────────                    │
│ Total due:  ₹ 12,500              │
│  ❗ ₹ 7,500 overdue                │
│                                  │
│ Open invoices                     │
│ • Term 1 fees — due 15 May  ₹12,500│
│   [View]   [Pay now]              │
│                                  │
│ Past payments                     │
│ • 12 Apr — ₹ 5,000 — Receipt #R… │
└──────────────────────────────────┘
```

States: loading, empty (all paid), error, offline (cached, "as of HH:MM").

### 5. API Contracts

#### `GET /api/mobile/v1/fees/summary`
- **Header:** `X-Active-Student-Id` (parent) optional for student self.
- **Status:** MODIFY (BG-12 SR-AUTH-001 fix). Module: StudentFee.
- **Response 200:** `{ data:{ total_due, overdue_amount, invoices:[...], payments:[...] }}`.
- **4xx:** `403 NOT_FEE_PAYER`, `403 CHILD_ACCESS_REVOKED`.

### 6. Data Model
`cache_fees_summary` per student_uuid.

### 7. Offline Behavior
Read-only cached.

### 8. Push Notifications
Consumes `FEE_DUE_SOON`, `FEE_PAID_RECEIPT`, `FEE_FAILED`.

### 9. Permissions & Security
- **CRITICAL** — SR-AUTH-001 (BG-12).
- Audit: `FEE_SUMMARY_VIEWED` (compliance for who-saw-what).
- `security-rules.md` §"Financial data".

### 10. Non-Functional Requirements
- Cached < 300 ms; network < 1.5 s.
- Localization: `f060.title`, `f060.label.{due,overdue,paid}`.

### 11. Acceptance Criteria
- **AC-060.1** Tampered request fetching another child → 403.
- **AC-060.2** Soft-deleted invoices not shown.
- **AC-060.3** Multi-child parent: switching child changes the summary.

### 12. Dependencies
- F-002, F-005. BG-12. StudentFee module.

### 13. Out of Scope
- Fee-structure breakdown editing — web-only.

---

## F-061: Pay Fee via Razorpay (Parent)

### 1. Overview
Parent initiates Razorpay payment for an invoice. Mobile uses Razorpay Standard Checkout SDK (or web view). **Hard pre-reqs:** BG-15 (Payment DDL — broken prefixes), BG-16 (webhook auth — SEC-004), BG-13 (proceedPayment IDOR — SEC-STP-007), BG-17 (rotate keys — SEC-PAY-001).

### 2. User Stories
- **US-061.1** *As a parent, I tap "Pay" on an invoice and complete the payment.*
- **US-061.2** *On success, I get a push receipt within 60 s.*
- **US-061.3** *Edge — payment fails (insufficient funds): server marks attempt failed; mobile shows clear error and retry CTA.*

### 3. Functional Requirements
- **FR-061.1** Server-side: client requests `POST /fees/pay` with `invoice_id` + amount; server creates a Razorpay order, returns `{ order_id, key_id, amount, currency, prefill_email/phone }`.
- **FR-061.2** Mobile launches Razorpay SDK; on result, server reconciles via webhook (NOT client-trusted).
- **FR-061.3** Webhook (server-side) verifies signature, updates `pay_payments` (correct prefix), allocates to `fin_fee_invoices`, emits `FEE_PAID_RECEIPT` push.
- **FR-061.4** Client polls `GET /fees/pay/{transaction_id}` to confirm — does NOT mark paid based on SDK callback alone.
- **FR-061.5** Mass-assignment guard (D25/D30) on pay endpoints (BG-39).
- **FR-061.6** Idempotency key per pay-attempt to avoid double-charge on retry.

### 4. Screen Specifications

#### S-061.1 — Confirm
Invoice + amount; "Pay ₹12,500" CTA.

#### S-061.2 — Razorpay sheet (SDK)
Native overlay; not in our control beyond branding.

#### S-061.3 — Result (poll)
"Verifying payment …" → "Paid ✓" with receipt CTA OR "Failed — try again".

States: loading, error, offline (block start; show "online required").

### 5. API Contracts

#### `POST /api/mobile/v1/fees/pay`
- **Status:** MODIFY (BG-13, BG-15, BG-16, BG-17).
- **Request:** `{ invoice_id, amount }` — server validates ownership + amount.
- **Response 200:** `{ order_id, key_id, amount, currency, prefill:{email,phone} }`.
- **4xx:** `403 NOT_FEE_PAYER`, `409 ALREADY_PAID`, `422 AMOUNT_MISMATCH`.

#### `GET /api/mobile/v1/fees/pay/{order_id}`
- Returns `{ status: PENDING | SUCCESS | FAILED | REFUNDED, receipt_url? }`.

#### `POST {server}/webhook/razorpay`
- Server-side; **MUST** be outside auth middleware (BG-16 / SEC-004).
- Signature verified.

### 6. Data Model
```sql
pending_writes: NOT used for F-061 (payment is online-only)
cache_payments (order_id PRIMARY KEY, status, payload_json)
```

### 7. Offline Behavior
**Not supported offline.**

### 8. Push Notifications
Emits: `FEE_PAID_RECEIPT`, `FEE_FAILED`.

### 9. Permissions & Security
- **CRITICAL** — fee data + payment → IDOR + webhook auth + key rotation.
- BG-13 SEC-STP-007 fix; BG-15 DDL; BG-16 webhook outside auth; BG-17 rotate test keys.
- Jailbreak / root: block payment screen.
- Audit: `FEE_PAY_INITIATED`, `FEE_PAY_SUCCESS`, `FEE_PAY_FAILED`.
- `security-rules.md` §"Payment integration".

### 10. Non-Functional Requirements
- SDK launch < 1 s; result poll TTL ≤ 5 s.
- Receipt push fires < 60 s p95.
- Localization: `f061.cta`, `f061.status.{pending,success,failed}`.
- Analytics: `pay_initiated`, `pay_success`, `pay_failed{reason}`.

### 11. Acceptance Criteria
- **AC-061.1** Two simultaneous "Pay" taps result in only one Razorpay order (idempotency).
- **AC-061.2** Tampered `invoice_id` (another child's) → 403.
- **AC-061.3** SDK callback "success" alone does NOT mark paid client-side until poll confirms server status.
- **AC-061.4** Razorpay webhook reaches server even when user not authenticated (BG-16).

### 12. Dependencies
- F-060. BG-13, BG-15, BG-16, BG-17, BG-39.

### 13. Out of Scope
- Payment by netbanking / wallet outside Razorpay Standard — covered by Razorpay's stack.
- Saved cards / tokenisation — Razorpay-managed.
- Refund flow on mobile — admin/web only.

---

## F-062: Receipt / Invoice Document Download

### 1. Overview
Download receipt PDF after payment, or older invoice PDF, via signed URL. Wraps DomPDF receipts (D9). Uses universal PDF viewer CC-05.

### 2. User Stories
- **US-062.1** *As a parent, I download my receipt and share it.*
- **US-062.2** *As a parent, I revisit a year-old invoice from history.*

### 3. Functional Requirements
- **FR-062.1** Endpoint returns time-limited signed URL.
- **FR-062.2** Document types: `RECEIPT`, `INVOICE`, `STATEMENT`.

### 4. Screen Specifications
List → tap → CC-05 viewer.

### 5. API Contracts

#### `GET /api/mobile/v1/documents/{type}/{id}/pdf`
- **Status:** NEW (BG-33). Module: many.
- **Response 200:** `{ url, expires_at }`.

### 6. Data Model
`cache_attachments (id, url, fetched_at, file_path)`.

### 7. Offline Behavior
Once downloaded → fully offline.

### 8. Push Notifications
None.

### 9. Permissions & Security
- BG-33 signed URLs — single-use, expires in 5 min, scoped to authenticated user.
- OS: Storage / Photos (Android 13+).
- Audit: `DOCUMENT_DOWNLOADED` row.

### 10. Non-Functional Requirements
- 30-page PDF first paint < 3.5 s.
- Localization: `f062.title`, `f062.share`.

### 11. Acceptance Criteria
- **AC-062.1** Signed URL fetched without auth header AFTER expiry → 403.
- **AC-062.2** Sharing the doc opens system share sheet (CC-05).

### 12. Dependencies
- F-060. BG-33.

### 13. Out of Scope
- Editable invoice copy — web-only.

---

## F-070: Transport Route View (Student / Parent)

### 1. Overview
View assigned transport route, stops, pickup time, driver/conductor name, vehicle number. **Pre-req:** BG-25 (Transport route registration broken — module currently registers 0 tenant routes).

### 2. User Stories
- **US-070.1** *As a parent, I see "Route 4 · Pickup 07:35 from XYZ stop · Driver: Ramesh · Vehicle KA-01-1234".*

### 3. Functional Requirements
- **FR-070.1** Endpoint scoped to student's `tpt_student_assignment`.
- **FR-070.2** Read-only at v1.
- **FR-070.3** Vehicle / driver PII — Aadhaar / PAN MUST NOT be returned (Transport module currently stores plaintext — IT Act risk; mobile must enforce field stripping).

### 4. Screen Specifications

#### S-070.1 — Route map + stops
Map with stops + ETA list.

States: loading, empty (no transport), error, offline (cached).

### 5. API Contracts

#### `GET /api/mobile/v1/transport/route/me`
- **Status:** NEW (BG-25). Module: Transport.
- **Header:** `X-Active-Student-Id` for parents.
- **Response 200:** `{ data:{ route:{id,name}, stops:[...], pickup_time, driver:{name,phone_masked}, vehicle:{number,model} }}`.

### 6. Data Model
`cache_route_assignment` keyed by student_uuid.

### 7. Offline Behavior
Term-cached.

### 8. Push Notifications
N/A directly.

### 9. Permissions & Security
- BR-PPT-012 enforced for parent.
- PII: never return Aadhaar/PAN; phone masked (last 4 digits visible).
- Audit: not logged (read-heavy).
- Block until BG-25 fixed.

### 10. Non-Functional Requirements
- Cached < 300 ms.
- Localization: `f070.label.*`.

### 11. Acceptance Criteria
- **AC-070.1** Aadhaar / PAN absent from response payload (regression test).
- **AC-070.2** Student without transport assignment → friendly empty state.

### 12. Dependencies
- F-002, F-005. BG-25.

### 13. Out of Scope
- Stop change request (web-only at v1).

---

## F-071: Live Trip Tracking (Parent)

### 1. Overview
Live GPS tracking of the morning / evening trip on a map. Parents see vehicle location, ETA to their child's stop, and a boarded/un-boarded indicator.

### 2. User Stories
- **US-071.1** *As a parent, I want a live map showing the bus, so I leave the office on time.*
- **US-071.2** *Push notifies "Trip started" + "Asha boarded".*

### 3. Functional Requirements
- **FR-071.1** Live position via WebSocket (Pusher / Reverb / native — Q-OQ Phase 3) OR poll-fallback every 15 s.
- **FR-071.2** Trip status: `NOT_STARTED | IN_PROGRESS | COMPLETED | CANCELLED`.
- **FR-071.3** Stop ETA computed server-side (route geometry + last GPS).
- **FR-071.4** Boarded indicator from `tpt_trip_boarding`.

### 4. Screen Specifications
Map with vehicle marker; bottom sheet with ETA + child-status badge.

### 5. API Contracts

#### `GET /api/mobile/v1/transport/trip/live/{trip_id}`
- HTTP poll fallback. Auth + tenant + active-child.
- **Status:** NEW (BG-27). Module: Transport.

#### WebSocket channel `private-tenant.{uuid}.trip.{trip_id}` (TBD)
- Events: `gps_update`, `boarding`, `trip_status`.

### 6. Data Model
Ephemeral; minimal cache for last-known position.

### 7. Offline Behavior
Cannot track live offline; show last-cached position with timestamp.

### 8. Push Notifications
Consumes `TRANSPORT_TRIP_STARTED`, `TRANSPORT_BOARDED`, `TRANSPORT_INCIDENT`.

### 9. Permissions & Security
- Authorize: parent's child is on `tpt_student_assignment` for that route.
- WebSocket auth via Sanctum.
- Audit: not logged (high-frequency).

### 10. Non-Functional Requirements
- GPS update freshness target ≤ 30 s.
- Battery: limit map refresh to once per 5 s.
- Localization: `f071.label.*`.

### 11. Acceptance Criteria
- **AC-071.1** Trip not started → map shows "Waiting for trip to start".
- **AC-071.2** Boarded event received via push within 30 s of driver-side scan.

### 12. Dependencies
- F-070. BG-27. WebSocket infra (Phase 3 OQ).

### 13. Out of Scope
- Walking-route from stop to home — v1.2.

---

## F-072: Driver Route Execution & Boarding QR (Transport Staff)

### 1. Overview
Driver app flow: start trip, mark each student boarded (QR scan) at each stop, capture GPS pings, end trip.

### 2. User Stories
- **US-072.1** *As a driver, I tap "Start trip" before I leave depot.*
- **US-072.2** *At each stop I scan student QRs to mark boarded; confirms green / red audio.*
- **US-072.3** *GPS pings batch-uploaded every 30 s.*

### 3. Functional Requirements
- **FR-072.1** `start_trip` returns `trip_id` + ordered stops.
- **FR-072.2** Foreground GPS service required while trip in progress; user-visible notification.
- **FR-072.3** Boarding scan: QR encodes `student_uuid + tenant + signed_token`; server validates.
- **FR-072.4** Idempotency: boarding identified by `(trip_id, student_uuid)`.
- **FR-072.5** End-trip closes the trip and stops GPS service.
- **FR-072.6** Aadhaar/PAN of driver / conductor must NOT surface on this app — PII minimisation.

### 4. Screen Specifications

#### S-072.1 — Trip dashboard
Stops list with progress; "Scan boarding" CTA at active stop.

#### S-072.2 — Scanner
`mobile_scanner` overlay; auto-confirm; sound + haptic.

States: loading, scan-error (invalid QR / wrong tenant), offline (queue boarding records, queue GPS pings).

### 5. API Contracts

#### `POST /api/mobile/v1/transport/trip/start`
- **Status:** NEW (BG-26).
- **Response:** `{ trip_id, stops:[...], started_at }`.

#### `POST /api/mobile/v1/transport/trip/board`
- **Idempotency-Key:** `board:{trip_id}:{student_uuid}`.
- **Request:** `{ trip_id, student_uuid, stop_id, captured_at, lat, lon }`.
- **Response 201:** `{ status:"BOARDED|DUPLICATE" }`.

#### `POST /api/mobile/v1/transport/trip/gps`
- Batch payload: `{ trip_id, points:[{captured_at,lat,lon,speed_kmh,heading}] }`.

#### `POST /api/mobile/v1/transport/trip/end`
- Closes trip.

### 6. Data Model
```sql
pending_writes feature_id='F-072'  (boarding + GPS batches)
cache_active_trip (trip_id, started_at, stops_json)
```

### 7. Offline Behavior
Queue boarding records and GPS pings; sync on reconnection. Server upserts by idempotency key.

### 8. Push Notifications
Emits: `TRANSPORT_TRIP_STARTED`, `TRANSPORT_BOARDED`.

### 9. Permissions & Security
- OS: Camera (QR), Location (always — background), Notifications.
- Authorize: driver assigned to trip / vehicle.
- QR signing prevents student-id spoofing.
- Audit: `TRIP_STARTED`, `BOARDED`, `TRIP_ENDED`.
- Recommend separate driver app at v1.1 (Q-9) — minimises PII exposure on shared device.

### 10. Non-Functional Requirements
- Boarding scan to confirm < 500 ms.
- GPS ping batch every 30 s; battery foreground-service notification visible.
- Localization: `f072.cta.*`.
- Analytics: `trip_started`, `boarded`, `trip_ended`, `gps_ping_batch`.

### 11. Acceptance Criteria
- **AC-072.1** Boarding the same student twice → server returns `DUPLICATE` and no double-record.
- **AC-072.2** GPS pings batched 30-at-a-time during trip.
- **AC-072.3** Trip end stops the foreground service.
- **AC-072.4** Tampered QR (different tenant) → rejected.

### 12. Dependencies
- F-002. BG-25, BG-26.

### 13. Out of Scope
- Per-leg analytics (delays, stops missed) — v1.1.

---

## F-073: Trip Incident Reporting (Transport Staff)

### 1. Overview
Driver / conductor reports an incident (breakdown, accident, route deviation, behaviour) with photo + description.

### 2. User Stories
- **US-073.1** *As a conductor, I report a breakdown with a photo so principal + parents are alerted instantly.*

### 3. Functional Requirements
- **FR-073.1** Categories: BREAKDOWN, ACCIDENT, BEHAVIOUR, MEDICAL, ROUTE_DEVIATION, OTHER.
- **FR-073.2** Photos optional (max 3, ≤ 1 MB each post-compression).
- **FR-073.3** Severity: LOW / MEDIUM / HIGH / CRITICAL.
- **FR-073.4** HIGH / CRITICAL → immediate Principal push (`TRANSPORT_INCIDENT`); CRITICAL also pushes parents on the route.

### 4. Screen Specifications
Form: type chips, severity, description, photo grid, submit.

### 5. API Contracts

#### `POST /api/mobile/v1/transport/trip/incident`
- **Status:** NEW (BG-26).
- **Request:** multipart — JSON + photos.
- **Response 201:** `{ incident_id, severity, dispatched_to:[...] }`.

### 6. Data Model
`pending_writes` feature='F-073' for offline submissions.

### 7. Offline Behavior
Queued writes.

### 8. Push Notifications
Emits `TRANSPORT_INCIDENT` (channel `transport`+`security`, quiet-hours bypass).

### 9. Permissions & Security
- OS: Camera, Location.
- Authorize: driver/conductor on active trip.
- Audit: `INCIDENT_REPORTED`.

### 10. Non-Functional Requirements
- Submission perceived < 200 ms.
- 3-photo upload < 10 s p50 over 4G.
- Localization: `f073.category.*`.

### 11. Acceptance Criteria
- **AC-073.1** CRITICAL incident pushes principal + parents on the route within 30 s.
- **AC-073.2** Offline incident queued; parents pushed only on sync.

### 12. Dependencies
- F-072. BG-26. Notification module wiring.

### 13. Out of Scope
- Insurance claim attachments — web-only at v1.

---

> End Batch 06. Continue to `02_mobile_srs_batch_07.md` (Communication + HPC).

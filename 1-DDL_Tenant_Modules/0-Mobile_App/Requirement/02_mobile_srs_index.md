# Prime-AI Mobile App — Software Requirements Specification (Master Index)

> **Phase:** 2 of 3 (SRS). **Predecessor:** `01_mobile_feature_list_v1.md`.
> **Prompt:** `{OLD_REPO}/1-DDL_Tenant_Modules/0-Mobile_App/Claude_Prompt/PrimeAi_MobileApp_prompt_v2.md`
> **Owner:** Business Analyst + Mobile Application Architect (Claude)
> **Sources consumed:** `{OLD_REPO}/1-DDL_Tenant_Modules/0-Mobile_App/Claude_Context/00_context_index.md`

---

## 1. Document Control

| Field | Value |
|-------|-------|
| Document ID | PRIME-MOB-SRS-v1 |
| Version | 1.0 (draft) |
| Date | 2026-05-08 |
| Status | Draft for review |
| Author | Claude (BA + Mobile Architect role) |
| Predecessor | `01_mobile_feature_list_v1.md` (Phase 1, 2026-05-05) |
| Successor (planned) | Phase 3 design artifacts in `0-Mobile_App/Design/` |

### 1.1 Source-of-truth dependencies

| Source | Last-Updated cited in Phase 1 | Used for |
|--------|-------------------------------|----------|
| `{AI_BRAIN}/memory/MEMORY.md` | 2026-03-21 | Cross-cutting bug IDs (SEC-*, BUG-*) |
| `{AI_BRAIN}/memory/project-context.md` | continuously updated | Stack, Sanctum, UUIDs, roles, workflows |
| `{AI_BRAIN}/memory/modules-map.md` | 2026-04-09 audit | Module FULL/PARTIAL status, route prefixes |
| `{AI_BRAIN}/memory/architecture.md` | 2026-03-12 | Auth middleware stack, maturity matrix |
| `{AI_BRAIN}/memory/conventions.md` | n/a | Table prefixes, JSON envelope |
| `{AI_BRAIN}/memory/db-schema.md` | 2026-03-12 | 370 tenant tables, DDL paths |
| `{AI_BRAIN}/memory/tenancy-map.md` | n/a | Bootstrappers, BUG-004, SEC-004, SEC-PLATFORM-002 |
| `{AI_BRAIN}/memory/student-parent-portal.md` | 2026-04-02 | 35+23 web screens, 16 new tables, IDOR risks |
| `{AI_BRAIN}/memory/known-bugs-and-roadmap.md` | 2026-03-26 | Critical SEC/BUG IDs, mobile blockers |
| `{AI_BRAIN}/state/decisions.md` | running | D1–D34 architectural decisions |
| `{AI_BRAIN}/state/progress.md` | 2026-04-09 | Per-module completion %, IDOR confirmed unpatched |
| `{AI_BRAIN}/rules/{tenancy,security,module,school}-rules.md` | various | §9 Permissions & Security per feature |

### 1.2 Module-map audit anchor

All module status references in this SRS are pinned to the **2026-04-09 audit** of `modules-map.md`. Any change in module status after that date supersedes this document — re-audit before sprint commit.

---

## 2. Glossary & Acronyms

| Term | Meaning |
|------|---------|
| AOT | Ahead-Of-Time compilation (Flutter ships AOT binaries) |
| APNs | Apple Push Notification service |
| BG-XX | Backend Gap item (catalogued in Phase 1 §6) |
| CC-XX | Cross-Cutting capability ID (Phase 1 §3) |
| DLT | Distributed Ledger Technology — TRAI mandatory SMS template registry (India) |
| F-XXX | Feature ID (Phase 1 §2) |
| FCM | Firebase Cloud Messaging (Android push) |
| FET | Free Educational Timetable solver (used by SmartTimetable) |
| FR-XXX.N | Functional Requirement N for feature F-XXX |
| FSM | Finite State Machine |
| HPC | Holistic Progress Card — D13 (4 PDF templates × 30–50 pages) |
| IDOR | Insecure Direct Object Reference (security flaw class) |
| KPI | Key Performance Indicator |
| LMS | Learning Management System (LmsHomework, LmsQuiz, LmsExam, LmsQuests) |
| LXP | Learning Experience Platform |
| MVP | Minimum Viable Product (P0 only) |
| NFR | Non-Functional Requirement |
| OTP | One-Time Password |
| P0/P1/P2 | Priority bands (MVP / v1.1 / later) |
| PII | Personally Identifiable Information |
| PTM | Parent-Teacher Meeting |
| RBAC | Role-Based Access Control |
| RBS | Requirements Breakdown Structure (`PrimeAI_RBS_Menu_Mapping_v2.0.md`) |
| SaaS | Software-as-a-Service |
| Sanctum | Laravel Sanctum (token-based auth) |
| SEC-* | Security issue ID (catalogued in `known-bugs-and-roadmap.md`) |
| SLA | Service Level Agreement |
| SR-AUTH-* | Student-Parent portal AUTH security IDs |
| stancl/tenancy | Multi-tenant Laravel package v3.9 (D1) |
| SRS | Software Requirements Specification |
| TLS | Transport Layer Security |
| TOTP | Time-based One-Time Password |

---

## 3. Overall Mobile Architecture

### 3.1 Client Architecture (Flutter — pending §7 Q-1 confirmation)

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                            │
│  Screens (one widget per F-XXX) · Theming (tenant-driven CC-10) │
│  Localization (.arb files — Hindi + English at v1)              │
└────────────────────────┬────────────────────────────────────────┘
                         │ State (Riverpod 2.x recommended)
┌────────────────────────▼────────────────────────────────────────┐
│                  APPLICATION / DOMAIN LAYER                      │
│  UseCases per feature · Repositories (interface) · Models       │
│  Result<T> sealed type · Domain errors (mapped from API codes)  │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                       DATA LAYER                                 │
│  ┌─────────────────────┐  ┌──────────────────────────────────┐  │
│  │ Remote (Dio + retry │  │ Local (Drift / SQLite)           │  │
│  │ + auth interceptor +│  │ ┌──────────────────────────────┐ │  │
│  │ idempotency-key  +  │  │ │ pending_writes (queue)       │ │  │
│  │ tenant header)      │  │ │ cache_<entity> tables        │ │  │
│  │                     │  │ │ device_state (token, tenant) │ │  │
│  └─────────────────────┘  │ └──────────────────────────────┘ │  │
│                           └──────────────────────────────────┘  │
│  flutter_secure_storage (Sanctum token, refresh state)          │
│  firebase_messaging (push) · pdfx (viewer) · geolocator (GPS)   │
└─────────────────────────────────────────────────────────────────┘
```

**Key client-side libraries (Flutter)**

| Concern | Library | Why |
|---------|---------|-----|
| HTTP | `dio` + `dio_smart_retry` + custom `AuthInterceptor`, `TenantInterceptor`, `IdempotencyInterceptor` | Pluggable, retry on 5xx/network |
| State | `flutter_riverpod` 2.x | Compile-time safety, async value |
| Local DB | `drift` | Type-safe SQLite, reactive streams, migrations |
| Secure storage | `flutter_secure_storage` | Keychain (iOS) / EncryptedSharedPreferences (Android) |
| Push | `firebase_messaging`, native APNs cap | FCM-first; iOS routes via FCM HTTP v1 |
| PDF | `syncfusion_flutter_pdfviewer` (or `pdfx`) | Reliable, large PDFs (HPC 30–50 pages) |
| Biometric | `local_auth` | Unified Face ID / Touch ID / Android |
| Camera + QR | `mobile_scanner` | F-001 tenant QR, F-072 boarding QR |
| Maps | `flutter_map` (OSM) or `google_maps_flutter` | Q-12 — open question |
| GPS | `geolocator` + `flutter_background_service` | F-072 driver pings |
| Network monitor | `connectivity_plus` | Sync triggers |
| File picker / share | `file_picker`, `share_plus` | F-041 homework upload, CC-05 share |
| Crash | `sentry_flutter` (recommended; CC-11 OQ) | Off-platform; redact PII |
| i18n | `intl` + `.arb` | hi-IN, en-IN |
| Forced upgrade | `package_info_plus` + custom version check | F-135 |
| Cert pinning | `dio_certificate_pinning` | Per Phase 3 security design |

### 3.2 Auth Flow Diagram (Tenant resolution → Sanctum login → Refresh)

```
                ┌─────────────────────────────────────┐
                │           Cold Start                │
                └──────────────┬──────────────────────┘
                               │
                  ┌────────────▼─────────────┐
                  │  Read secure-storage     │
                  │  {tenant_host, token}    │
                  └────────────┬─────────────┘
            ┌──────────────────┴──────────────────┐
            │                                     │
       missing                                  present
            │                                     │
┌───────────▼───────────────┐         ┌──────────▼──────────────────┐
│  F-001 Tenant Resolution  │         │  GET /auth/me (silent ping) │
│  (subdomain | code | QR)  │         └──────────┬──────────────────┘
│  POST /tenant/resolve     │                    │
└───────────┬───────────────┘            ┌───────┴───────┐
            │                          200            401/expired
            │                            │                │
┌───────────▼───────────────┐    ┌───────▼──────┐  ┌──────▼──────┐
│  Branding cached, tenant  │    │  Home (role- │  │  F-002 Login│
│  pinned                   │    │  aware)      │  │  screen     │
└───────────┬───────────────┘    └──────────────┘  └──────┬──────┘
            │                                             │
┌───────────▼───────────────┐                ┌───────────▼──────────────┐
│  F-002 Login              │◀───────────────│  POST /auth/login        │
│  (email/phone + password) │                │  → {token, user, child[]}│
│  → store token (secure)   │                └──────────────────────────┘
│  → POST /devices (FCM)    │
│  → biometric prompt (F-04)│
└───────────┬───────────────┘
            │
            ▼
       Role-aware Home (F-010 / F-011 / F-012 / F-013)
```

**Token lifecycle**

| Event | Action |
|-------|--------|
| Successful login | Sanctum personal_access_tokens row issued; `expires_at` = `null` (current default) — mobile applies a **client-side rolling refresh policy** (default 7-day inactivity → force re-login) |
| 401 on any call | If biometric enabled → silent biometric prompt; if cancelled / no biometric → push to Login screen with deep-link replay |
| User logout | Client calls `DELETE /auth/logout` → server revokes token row; client wipes secure storage + Drift `cache_*` tables |
| App uninstall / reinstall | Token lost (secure storage cleared); next launch hits F-001 Tenant Resolution again |
| Tenant deactivated mid-session | `EnsureTenantIsActive` middleware returns 403 with `error_code = TENANT_INACTIVE`; client shows blocking dialog and clears cache |

### 3.3 API Gateway / Base URL Strategy

**Two supported patterns; client uses (b) by default.**

(a) **Per-tenant subdomain** (e.g. `xyz.prime-ai.com`):
- Web app uses this; mobile MAY use it when subdomain mode is selected during F-001.
- Backend: existing `InitializeTenancyByDomain` middleware works unchanged.

(b) **Single API host + tenant header** (default for mobile):
- Base URL: `https://api.prime-ai.com/api/mobile/v1/*` (TBD — Q-13)
- Header: `X-Tenant-Host: xyz.prime-ai.com` (or `X-Tenant-Code: ABC123`)
- Backend: requires **NEW middleware `InitializeTenancyByHeader`** (BG-01).

**Rationale:** mobile clients deal poorly with per-subdomain TLS cert variation; one cert + header is operationally simpler. Header value is captured at F-001.

**Standard headers on every request**

| Header | Purpose |
|--------|---------|
| `Authorization: Bearer <sanctum_token>` | Sanctum auth |
| `X-Tenant-Host` (or `X-Tenant-Code`) | Tenant resolution |
| `X-Active-Student-Id` | Parent role only — selected child (F-005) |
| `X-Idempotency-Key` | All POST/PUT/DELETE — UUIDv4 generated client-side |
| `X-App-Version` | e.g. `1.0.3+45` — for forced-upgrade gate |
| `X-Platform` | `ios` / `android` |
| `X-Device-Id` | Stable per-install (ANDROID_ID + UUID fallback) |
| `Accept-Language` | `hi-IN`, `en-IN` |
| `Accept` | `application/json` |

### 3.4 Push Notification Architecture

```
  ┌───────────────────┐                     ┌─────────────────────┐
  │ Domain event      │                     │ Mobile device       │
  │ (e.g. AttendanceMarked)│                │ (Flutter)           │
  └────────┬──────────┘                     └──────────▲──────────┘
           │ Laravel event                             │
           ▼                                           │
  ┌───────────────────┐                                │
  │ Listener:         │                                │
  │ DispatchMobilePush│                                │
  └────────┬──────────┘                                │
           │                                           │
           ▼                                           │
  ┌───────────────────────────┐                        │
  │ Notification module       │                        │
  │ MobilePushDispatcher      │                        │
  │  • resolve recipients     │                        │
  │  • check quiet hours      │                        │
  │  • render template (i18n) │                        │
  │  • write ntf_notifications│                        │
  └────────┬──────────────────┘                        │
           ▼                                           │
  ┌───────────────────────────┐    FCM HTTP v1   ┌─────┴─────────┐
  │ ntf_device_tokens lookup  │─────────────────▶│  FCM / APNs   │
  │ payload + deep_link       │                  │               │
  └───────────────────────────┘                  └───────────────┘
```

**Required backend gaps**

| BG | Description | Effort |
|----|-------------|--------|
| BG-08 | Un-comment Notification routes; fix `tenant.*` Gate prefix | S |
| BG-09 | New `MOBILE_PUSH` channel + `MobilePushDispatcher` service | M |
| BG-10 | New `ntf_device_tokens` register endpoint | S |
| BG-37 | Cross-platform push templates (FCM payload schema) | M |

**Payload schema (FCM HTTP v1)**

```json
{
  "message": {
    "token": "<device_token>",
    "notification": {
      "title": "{{i18n title}}",
      "body":  "{{i18n body}}"
    },
    "data": {
      "event_type": "ATTENDANCE_ABSENT",
      "subject_id": "456",
      "subject_type": "student",
      "deep_link": "primeai://attendance/student/456?date=2026-05-08",
      "thread_id": "attendance:456",
      "tenant_host": "xyz.prime-ai.com"
    },
    "android": { "priority": "high", "notification": { "channel_id": "academics" } },
    "apns": { "payload": { "aps": { "badge": 0, "sound": "default" } } }
  }
}
```

**Deep-link URI scheme:** `primeai://<feature>/<sub-resource>/<id>?<context>` (full table in Phase 3 `01_mobile_information_architecture.md`).

### 3.5 Offline & Sync Strategy

#### 3.5.1 Cache layer (Drift)

| Drift table | Source backend table(s) | TTL | Write-through? |
|-------------|--------------------------|-----|----------------|
| `cache_user_profile` | `sys_users` (Resource) | 24 h | No |
| `cache_children` (Parent) | `std_student_guardian_jnt` | login + manual | No |
| `cache_timetable_today` | `tt_timetable_cells`, `tt_timetable_cell_teachers` | end-of-day | No |
| `cache_lesson_plans` | `syl_lesson_plans` (Syllabus) | term-end | No |
| `cache_homework_list` | `lms_homework`, `lms_homework_submissions` | 7 d, refresh on F-040 open | No |
| `cache_fees_open` | `fin_fee_invoices` | 24 h | No |
| `cache_notifications` | `ntf_notifications` | 100 most recent | Yes (read-receipt queued) |
| `cache_route_assignment` | `tpt_routes`, `tpt_route_stops` | term-end | No |
| `cache_quiz_metadata` | `lms_quizzes` | per attempt | No |
| `cache_attachments` (file blobs) | `sys_media` (signed URLs) | 30 d LRU | No |

#### 3.5.2 Pending-writes queue (Drift)

```
pending_writes (
  id            INTEGER PK,
  feature_id    TEXT     -- e.g. 'F-020'
  endpoint      TEXT,
  http_method   TEXT,
  request_body  TEXT,    -- JSON
  idempotency_key TEXT,
  created_at    INTEGER,
  attempt_count INTEGER DEFAULT 0,
  last_error    TEXT,
  next_attempt_at INTEGER
)
```

| Feature | Queue strategy | Conflict resolution |
|---------|----------------|---------------------|
| F-020 Mark attendance | Per-period entry; idempotency key `{class_section_id}:{period_id}:{date}` | Server upsert by composite key — last-write-wins; server returns `409 + canonical_record` when teacher overlap detected |
| F-041 Submit homework | Multipart upload, queued | Submission immutable once accepted (status=`submitted`); resubmit creates new version |
| F-061 Pay fee | **Not queued** — payment must be online (Razorpay handshake) |
| F-072 Driver GPS pings | Batched 30-pings-per-payload; idempotency key per ping | Server deduplicates by `(trip_id, captured_at)` |
| F-073 Incident report | Single-shot upload | Last-write-wins on `(trip_id, type, captured_at)` |
| F-080 Read-receipt | Background flush every 60 s | Idempotent — server marks `read_at = MIN(existing, incoming)` |
| F-100 / F-102 Leave apply | Single submit; queued if offline | Idempotency key by `(applicant_id, from_date, to_date, type)` |

#### 3.5.3 Sync triggers

- **Connectivity-on event** (`connectivity_plus`): drain queue
- **Periodic background fetch** (`workmanager` / iOS background-fetch): every 15 min when phone idle
- **Foreground app-resume**: pull-to-refresh on visible screen
- **FCM "data" message with `event_type: SYNC_HINT`**: targeted pull (e.g. when a teacher publishes homework, hint the student app to refresh F-040)

### 3.6 Security (summary — full design in Phase 3 `06_mobile_security_design.md`)

| Concern | Approach |
|---------|----------|
| Token storage | Sanctum token in Keychain Access Group / Android Keystore (`flutter_secure_storage`). NEVER in SharedPreferences. |
| Token in transit | HTTPS only; cert pinning to `*.prime-ai.com` SHA-256 (rotated annually) |
| Biometric (F-004) | Unlocks **already-stored** token; never generates the token from biometric data |
| Jailbreak / root | Detect at startup (`flutter_jailbreak_detection`); block payment + HPC / fees / sensitive PII screens; allow read-only. Disable on dev builds. |
| Session timeout | Auto-lock screen after 5 min idle (configurable per tenant); biometric or password to unlock |
| Remote wipe | Server-issued token revocation honored on next 401; client wipes Drift `cache_*` + secure storage |
| Audit log | Every mobile write surfaces a row in `sys_activity_logs` (BG-43) — feature-level details in §9 of each batch |
| PII redaction | Logs (Sentry, Crashlytics) MUST redact: `password`, `token`, `aadhaar`, `pan`, `account_no`, `card_no`, `cvv`. SDK config in CC-11. |
| Forced upgrade | `GET /api/mobile/v1/version` returns `min_supported_version`; below → block all calls except upgrade prompt |
| Anti-cheat (F-053 online exam) | iOS: ScreenCaptureKit detection; Android: `FLAG_SECURE`; foreground-service pin; ANY backgrounding → auto-submit (Q-8) |
| Mass-assignment | Backend: D25 `validated()` only; D30 FormRequest `authorize()` returns Gate check (BG-39, BG-40) |
| Rate-limit | Mobile auth (login, forgot, reset): `throttle:5,2` per `student-parent-portal.md` recommendation |

### 3.7 Critical SEC/BUG IDs the SRS depends on (must be fixed pre-MVP)

| ID | Title | Blocks |
|----|-------|--------|
| SEC-PLATFORM-002 | `env('APP_DOMAIN')` in routes — breaks under config:cache | F-001 |
| SEC-PLATFORM-004 | `is_super_admin` in `User::$fillable` | F-002 |
| BUG-001 | Missing model imports (HPC) — fatal Gate | F-090 |
| BUG-002 | Duplicate `Gate::policy()` registrations | many |
| BUG-NEW-001 | Payment module — 3 broken prefixes, no DDL | F-061 |
| BUG-NEW-002 | Notification routes commented out | F-080, F-081 |
| BUG-NEW-004 | `lms_homework_assignment` migration missing | F-040, F-041 |
| BUG-007 | Student null pointer on session | F-021, F-040, F-050 |
| SEC-004 | Razorpay webhook behind auth | F-061 |
| SEC-PAY-001 | Razorpay test keys committed | F-061 |
| SEC-NEW-001 | Hardcoded API keys (QuestionBank) | F-051 |
| SEC-NEW-002 | StudentExamAttempt IDOR | F-053 |
| SEC-STP-007 | `proceedPayment` IDOR | F-061 |
| SEC-STP-008 | `StudentExamAttemptController::attempt` IDOR | F-053 |
| SEC-HPC-001 | 13/15 HpcController methods no auth | F-090 |
| SEC-HWK-003 | LmsHomework `show()` IDOR | F-040, F-042 |
| SR-AUTH-001 | Fee endpoint ownership not enforced | F-060, F-061 |
| BR-PPT-012 | ParentChildPolicy not implemented | F-005, F-011, F-022, F-043 |

---

## 4. Cross-cutting Non-Functional Requirements (NFRs)

### 4.1 Performance budgets

| Surface | 4G median | 3G p95 | Wifi |
|---------|-----------|--------|------|
| Cold start to first paint | < 2.0 s | < 4.0 s | < 1.5 s |
| Login → Home (data) | < 2.5 s | < 5.0 s | < 1.8 s |
| Dashboard render (cached) | < 300 ms | < 300 ms | < 200 ms |
| Dashboard render (network) | < 1.8 s | < 4.0 s | < 1.0 s |
| List screen (50 items) | < 1.5 s | < 3.5 s | < 800 ms |
| PDF first-page render (HPC 30-page) | < 3.5 s | < 8 s | < 2 s |
| Mark attendance submit (queued, perceived) | < 100 ms (local) | < 100 ms | < 100 ms |
| Mark attendance sync confirm | < 5 s | < 12 s | < 3 s |

### 4.2 Network resilience

- All GETs cached in Drift; UI shows cache + "as of HH:MM" indicator while refresh runs
- Retry policy: `dio_smart_retry` — 3 attempts, exponential backoff 1 s / 2 s / 4 s, only on idempotent methods
- Offline banner appears within 3 s of connectivity loss
- Queue size cap: 5,000 entries; oldest non-critical (read-receipts) dropped first; user shown warning at 80%

### 4.3 Accessibility

- WCAG 2.1 AA contrast (4.5:1 normal text, 3:1 large)
- Minimum tap target 44×44 dp
- TalkBack (Android) / VoiceOver (iOS) labels on every interactive element
- Font scaling supported to 200%
- Color is never the sole signal (icons + text labels)
- Dynamic Type respected in text sizes

### 4.4 Localization

- v1 baseline: Hindi (hi-IN) + English (en-IN) — see Q-6
- All strings in `.arb` files keyed by `feature_id.element_id`
- RTL not required for v1
- Number, date, currency formats locale-aware (e.g. ₹ vs Rs.)
- Tenant override: school may force a default locale via `prm_tenant_settings.default_locale`

### 4.5 Battery & data

- Background GPS (F-072) only while trip-active and foreground-service notification visible
- Image uploads (F-041, F-073) compressed client-side to ≤ 1 MB before upload
- Push notification payloads ≤ 4 KB (FCM limit)
- Daily mobile-data budget per typical user < 50 MB

### 4.6 App-size targets

| Platform | App-store size | Install size |
|----------|----------------|--------------|
| Android (split per ABI) | < 25 MB | < 60 MB |
| iOS | < 50 MB | < 90 MB |

### 4.7 Compatibility matrix

| Platform | Min OS | Target OS |
|----------|--------|-----------|
| Android | API 26 (8.0 Oreo) | API 34 (14) |
| iOS | 14.0 | 17.x |

(Indian K-12 parent device data: Android 8/9/10 still ≈ 30% combined as of 2026.)

---

## 5. Master Feature Index (links every batch)

| Batch | File | Feature IDs | Functional Areas |
|-------|------|-------------|------------------|
| 01 | `02_mobile_srs_batch_01.md` | F-001, F-002, F-003, F-004, F-005 | Authentication & Onboarding |
| 02 | `02_mobile_srs_batch_02.md` | F-010, F-011, F-012, F-013 | Dashboards |
| 03 | `02_mobile_srs_batch_03.md` | F-020, F-021, F-022, F-023, F-030, F-031, F-032 | Attendance, Timetable, Syllabus, Lesson Plan |
| 04 | `02_mobile_srs_batch_04.md` | F-040, F-041, F-042, F-043 | Homework |
| 05 | `02_mobile_srs_batch_05.md` | F-050, F-051, F-052, F-053, F-054 | Quiz, Quest, Exam, Results |
| 06 | `02_mobile_srs_batch_06.md` | F-060, F-061, F-062, F-070, F-071, F-072, F-073 | Fees, Transport |
| 07 | `02_mobile_srs_batch_07.md` | F-080, F-081, F-082, F-083, F-084, F-090, F-091 | Communication, HPC |
| 08 | `02_mobile_srs_batch_08.md` | F-100, F-101, F-102, F-103, F-110, F-111, F-120, F-121 | Leave, Library, Hostel |
| 09 | `02_mobile_srs_batch_09.md` | F-130, F-131, F-132, F-133, F-134, F-135, F-140 | Profile, Settings, Search |

> Cross-cutting capabilities (CC-01 .. CC-11) are documented inline with their primary feature, except CC-05 (PDF viewer), CC-10 (tenant branding), CC-11 (analytics) which appear in this index §6 / §10 and in F-001 (CC-10) / F-135 (CC-11).

---

## 6. API Summary Table

> Status legend: **NEW** = not yet on web · **REUSE** = wraps existing controller · **MODIFY** = needs auth/IDOR/payload fix before mobile can call.

All endpoints rooted at `/api/mobile/v1/`. Auth: Sanctum bearer + `X-Tenant-Host`. Detailed contracts per feature in batch files.

| # | Endpoint | Method | Status | Owning Module | Linked Feature(s) | BG ref |
|---|----------|--------|--------|---------------|-------------------|--------|
| 1 | `tenant/resolve` | POST | NEW | Prime | F-001 | BG-02 |
| 2 | `tenant/{code}/branding` | GET | NEW | Prime | F-001, CC-10 | BG-02 |
| 3 | `auth/login` | POST | NEW (wraps Sanctum) | Prime / App | F-002 | BG-03 |
| 4 | `auth/logout` | DELETE | NEW (wraps Sanctum) | Prime / App | F-002 | BG-03 |
| 5 | `auth/me` | GET | NEW | Prime / App | F-002, F-005 | BG-03 |
| 6 | `auth/forgot` | POST | NEW | App | F-003 | BG-03 |
| 7 | `auth/reset` | POST | NEW | App | F-003 | BG-03 |
| 8 | `me/children` | GET | NEW | StudentProfile / ParentPortal | F-005 | BG-28 |
| 9 | `devices` | POST | NEW | Notification | F-002, F-080 | BG-10 |
| 10 | `devices/{id}` | DELETE | NEW | Notification | F-002 | BG-10 |
| 11 | `student/dashboard` | GET | NEW (aggregator) | StudentPortal | F-010 | BG-34 |
| 12 | `parent/dashboard` | GET | NEW + new module | ParentPortal (PLANNED) | F-011 | BG-28, BG-34 |
| 13 | `teacher/dashboard` | GET | NEW (aggregator) | SmartTimetable / SchoolSetup / new TeacherPortal | F-012 | BG-34 |
| 14 | `principal/dashboard` | GET | NEW (aggregator) | Dashboard (with auth fix) | F-013 | BG-34 |
| 15 | `attendance` | POST | NEW | StudentProfile (today) → Attendance (PLANNED) | F-020 | BG-23, BG-24 |
| 16 | `attendance/me` | GET | NEW | StudentProfile | F-021 | — |
| 17 | `attendance/student/{id}` | GET | NEW | StudentProfile | F-022 | BG-12 |
| 18 | `attendance/punch` | POST | NEW | SchoolSetup / HrStaff | F-023 | BG-31 |
| 19 | `timetable/me` | GET | NEW (wraps SmartTimetable) | SmartTimetable | F-030 | — |
| 20 | `syllabus/progress/{subject_id}` | GET | NEW | Syllabus | F-031 | — |
| 21 | `syllabus/lesson-plans` | GET | NEW | Syllabus | F-032 | — |
| 22 | `homework` | GET | MODIFY (IDOR fix) | LmsHomework | F-040 | BG-18 |
| 23 | `homework/{id}` | GET | MODIFY (IDOR fix) | LmsHomework | F-040 | BG-18 |
| 24 | `homework/{id}/submission` | POST | NEW | LmsHomework | F-041 | BG-19, BG-20 |
| 25 | `homework/{id}/grade` | POST | NEW | LmsHomework | F-042 | — |
| 26 | `parent/homework/{student_id}` | GET | NEW + new module | ParentPortal | F-043 | BG-28 |
| 27 | `quizzes` | GET | REUSE (route prefix typo `lms-quize`) | LmsQuiz | F-050 | — |
| 28 | `quizzes/{id}/attempt` | POST | REUSE | LmsQuiz | F-050 | — |
| 29 | `quests/{id}/attempt` | POST | MODIFY (Gate uncomment) | LmsQuests | F-051 | — |
| 30 | `exams/schedule` | GET | NEW | LmsExam | F-052 | — |
| 31 | `exams/{id}/attempt` | POST | MODIFY (IDOR fix) | LmsExam / StudentPortal | F-053 | BG-14, BG-22 |
| 32 | `exams/results` | GET | REUSE | LmsExam / Hpc | F-054 | — |
| 33 | `fees/summary` | GET | MODIFY (ownership) | StudentFee | F-060 | BG-12 |
| 34 | `fees/pay` | POST | MODIFY (IDOR + DDL) | Payment + StudentPortal | F-061 | BG-12, BG-13, BG-15, BG-16 |
| 35 | `documents/{id}/pdf` | GET | NEW (signed URL) | many | F-062, F-090, F-130, F-054, CC-05 | BG-33 |
| 36 | `transport/route/me` | GET | NEW | Transport | F-070 | BG-25 |
| 37 | `transport/trip/live/{trip_id}` | GET / WebSocket | NEW | Transport | F-071 | BG-27 |
| 38 | `transport/trip/start` | POST | NEW | Transport | F-072 | BG-26 |
| 39 | `transport/trip/end` | POST | NEW | Transport | F-072 | BG-26 |
| 40 | `transport/trip/board` | POST | NEW | Transport | F-072 | BG-26 |
| 41 | `transport/trip/gps` | POST | NEW (batched) | Transport | F-072 | BG-26 |
| 42 | `transport/trip/incident` | POST | NEW | Transport | F-073 | BG-26 |
| 43 | `notifications` | GET | MODIFY (uncomment) | Notification | F-080 | BG-08 |
| 44 | `notifications/{id}/read` | POST | MODIFY | Notification | F-080 | BG-08 |
| 45 | `preferences/notifications` | GET / PUT | MODIFY | Notification | F-081 | BG-08 |
| 46 | `messaging/threads` | GET | NEW (new module) | Communication (PLANNED) | F-082 | BG-29 |
| 47 | `messaging/threads/{id}/messages` | GET / POST | NEW | Communication | F-082 | BG-29 |
| 48 | `notices` | GET | NEW | SchoolSetup | F-083 | BG-38 |
| 49 | `circulars/{id}/ack` | POST | NEW | SchoolSetup / Notification | F-084 | BG-38 |
| 50 | `hpc/me` | GET | MODIFY (auth) | Hpc | F-090 | BG-11 |
| 51 | `hpc/parent-form/{token}` | GET / POST | MODIFY (auth) | Hpc | F-091 | BG-11 |
| 52 | `leave/student/apply` | POST | NEW (new module) | Attendance (PLANNED) | F-100 | BG-32 |
| 53 | `leave/student/{id}/decision` | POST | NEW | Attendance (PLANNED) | F-101 | BG-32 |
| 54 | `leave/employee/apply` | POST | NEW | SchoolSetup / HrStaff | F-102 | BG-31 |
| 55 | `leave/employee/{id}/decision` | POST | NEW | SchoolSetup / HrStaff | F-103 | BG-31 |
| 56 | `library/catalog` | GET | REUSE | Library | F-110 | — |
| 57 | `library/me/borrowed` | GET | REUSE | Library | F-111 | — |
| 58 | `hostel/leave-pass/apply` | POST | NEW (new module) | Hostel (PLANNED) | F-120 | BG-30 |
| 59 | `hostel/notifications/me` | GET | NEW | Hostel (PLANNED) | F-121 | BG-30 |
| 60 | `me/profile` | GET / PUT | MODIFY | StudentProfile | F-130 | — |
| 61 | `me/health` | GET | NEW | StudentProfile | F-131 | — |
| 62 | `me/teachers` | GET | NEW | StudentProfile / SchoolSetup | F-132 | — |
| 63 | `me/preferences` | GET / PUT | NEW | App | F-133 | — |
| 64 | `support/tickets` | POST / GET | NEW | App | F-134 | — |
| 65 | `version` | GET | NEW | App | F-135 | BG-35 |
| 66 | `search` | GET | NEW | search infra | F-140 | BG-36 |

---

## 7. Push Notification Catalogue

> Per-feature push details in batch §8. This is the global catalogue.

| Event ID | Trigger | Recipient logic | Default Channel | i18n keys | Deep Link |
|----------|---------|------------------|------------------|-----------|-----------|
| `AUTH_NEW_DEVICE_LOGIN` | Successful login on a new `device_id` | Self | `security` | `push.auth.new_device.{title,body}` | `primeai://settings/devices` |
| `ATTENDANCE_ABSENT` | Today's attendance submitted with status=`Absent` | Parents of student | `academics` | `push.attendance.absent.*` | `primeai://attendance/student/{id}?date={d}` |
| `ATTENDANCE_LATE` | status=`Late` | Parents | `academics` | `push.attendance.late.*` | same |
| `HOMEWORK_PUBLISHED` | New `lms_homework` row visible to class | Students of class + their Parents | `academics` | `push.homework.new.*` | `primeai://homework/{id}` |
| `HOMEWORK_DUE_SOON` | Due-date crontab T-24h | Students with no submission | `academics` | `push.homework.due.*` | `primeai://homework/{id}` |
| `HOMEWORK_GRADED` | Teacher grades submission | Submitting student + Parents | `academics` | `push.homework.graded.*` | `primeai://homework/{id}/submission` |
| `QUIZ_ASSIGNED` | New quiz allocation | Students | `academics` | `push.quiz.new.*` | `primeai://quiz/{id}` |
| `EXAM_REMINDER` | Exam day T-24h, T-1h | Students + Parents | `academics` | `push.exam.reminder.*` | `primeai://exams/schedule` |
| `EXAM_RESULT_PUBLISHED` | Result row published | Students + Parents | `academics` | `push.exam.result.*` | `primeai://exams/result/{id}` |
| `FEE_DUE_SOON` | Invoice due-date T-7d, T-3d | Fee-payer Parent | `fees` | `push.fee.due.*` | `primeai://fees/summary` |
| `FEE_PAID_RECEIPT` | Razorpay webhook success | Fee-payer Parent | `fees` | `push.fee.paid.*` | `primeai://fees/receipt/{id}` |
| `FEE_FAILED` | Razorpay failure | Fee-payer Parent | `fees` | `push.fee.failed.*` | `primeai://fees/summary` |
| `TRANSPORT_TRIP_STARTED` | Driver F-072 trip-start | Parents on route | `transport` | `push.trip.started.*` | `primeai://transport/trip/{id}` |
| `TRANSPORT_BOARDED` | F-072 student boarded | Parents of that student | `transport` | `push.trip.boarded.*` | same |
| `TRANSPORT_INCIDENT` | F-073 incident report | Principal + Parents on route | `transport`+`security` | `push.trip.incident.*` | same |
| `NOTICE_PUBLISHED` | F-083 notice published | Audience filter | `general` | `push.notice.*` | `primeai://notices/{id}` |
| `CIRCULAR_PUBLISHED` | F-084 circular | Audience filter | `general` | `push.circular.*` | `primeai://circulars/{id}` |
| `MESSAGE_RECEIVED` | F-082 1:1 message | Other party | `messaging` | `push.message.*` | `primeai://messages/{thread_id}` |
| `HPC_REPORT_PUBLISHED` | HPC publish | Student + Parents | `academics` | `push.hpc.*` | `primeai://hpc/{report_id}` |
| `HPC_PARENT_FORM_DUE` | F-091 parent form token issued | Parent | `academics` | `push.hpc.parent_form.*` | `primeai://hpc/parent-form/{token}` |
| `LEAVE_DECISION` | Leave approved/rejected | Applicant | `general` | `push.leave.{approved,rejected}.*` | `primeai://leave/{id}` |
| `LEAVE_PENDING_APPROVAL` | New leave request | Approver(s) | `approvals` | `push.leave.pending.*` | `primeai://approvals/leave` |
| `HOSTEL_PASS_DECISION` | F-120 decision | Boarder + Parent | `general` | `push.hostel.pass.*` | `primeai://hostel/pass/{id}` |
| `HOSTEL_SICKBAY_ALERT` | F-121 sick-bay event | Parent | `general` | `push.hostel.sickbay.*` | `primeai://hostel/sickbay/{id}` |
| `LIBRARY_DUE_SOON` | F-111 due-date T-2d | Borrower | `general` | `push.library.due.*` | `primeai://library/me` |
| `FORCE_UPGRADE_AVAILABLE` | F-135 — version below floor | All on outdated build | `system` | `push.upgrade.*` | `primeai://upgrade` |

**Channel definitions (Android `NotificationChannel`):**

| Channel ID | Importance | Sound | Vibration | Quiet hours respected |
|-----------|-----------|-------|-----------|----------------------|
| `security` | HIGH | default | yes | NO |
| `academics` | DEFAULT | default | yes | YES |
| `fees` | HIGH | default | yes | YES |
| `transport` | HIGH | custom | yes | NO (safety) |
| `messaging` | HIGH | default | yes | YES |
| `general` | DEFAULT | default | no | YES |
| `approvals` | DEFAULT | default | yes | YES |
| `system` | DEFAULT | none | no | YES |

---

## 8. Permissions Matrix (OS permissions × features)

| OS Permission | Features needing it | Justification copy (i18n key) |
|----------------|----------------------|-------------------------------|
| Camera | F-001 (QR), F-041 (homework photo), F-072 (boarding QR), F-073 (incident photo) | `perm.camera.reason` |
| Photos / Gallery | F-041, F-073, F-130 (avatar) | `perm.photos.reason` |
| Storage (Android < 13) / Photos add-only (Android 13+) | F-062, F-090 (PDF download), CC-05 (share/save) | `perm.storage.reason` |
| Location (foreground) | F-070, F-071 (proximity-to-stop hint) | `perm.location_fg.reason` |
| Location (background, "always allow") | F-072 (driver only) | `perm.location_bg.reason` |
| Push notifications | F-080 + every push event | `perm.push.reason` |
| Biometric / FaceID | F-004 | `perm.biometric.reason` |
| Microphone | (none in v1; potential v1.2 voice notes in messaging) | n/a |
| Contacts | (none in v1) | n/a |
| Calendar | (none in v1; potential exam-add-to-calendar deferred) | n/a |

**Permission UX rule:** every dangerous permission is requested **just-in-time** at the feature entry point with a "why we need this" pre-prompt; never on first launch.

---

## 9. Release & Versioning Strategy (summary; full plan in Phase 3 `07_mobile_release_plan.md`)

### 9.1 Versioning

- **SemVer**: `MAJOR.MINOR.PATCH`
- Build number monotonically increasing per CI run: `1.0.3+45`
- `min_supported_version` enforced server-side via `GET /version` → `force_upgrade=true` blocks all calls (F-135)

### 9.2 Phased rollout

| Phase | Target audience | Features |
|-------|------------------|----------|
| Internal alpha | Prime-AI dev team | All P0 |
| Closed beta | 1 pilot tenant (TBD) | All P0 |
| Open beta (Play store internal track / TestFlight) | 5 pilot tenants | All P0 + bug fixes |
| GA v1.0 | All paying tenants | P0 only (M1 + M2 sprints) |
| v1.1 | All | P1 features (M3 + M4 sprints) |
| v1.2 | All | P2 features |

### 9.3 Feature flags (server-side, per tenant)

- `mobile.feature.<F-XXX>.enabled` → table `prm_tenant_feature_flags` (TBD — Phase 3 §3)
- Tenant-level kill switch for risky features (F-053, F-061) without app update

### 9.4 Forced upgrade

- `min_supported_version` checked on every cold start (F-135)
- Below floor → blocking screen with platform-specific deep-link to App Store / Play Store
- Two-week grace period after each release before raising the floor

### 9.5 Crash reporting

- Sentry mobile SDK (CC-11; Q-OQ open)
- PII redaction: scrub `password`, `token`, `aadhaar`, `pan`, `account_no`, `card_no`, `cvv`
- Crash-free rate target ≥ 99.5%

---

## 10. Acceptance / Sign-off

This index is approved when each downstream batch (`02_mobile_srs_batch_01.md` through `02_mobile_srs_batch_09.md`) is reviewed against:

- [ ] Every F-XXX in Phase 1 §2 is covered exactly once
- [ ] API summary §6 matches each feature's §5 contract
- [ ] Every push event in §7 is referenced from the right feature §8
- [ ] Open Questions Q-1 .. Q-13 from Phase 1 §7 are surfaced in feature §13 (Out of Scope) where they affect scope
- [ ] BG-01 .. BG-43 are each linked from at least one feature §5 (Backend gap)

> **STOP at end of Phase 2.** Wait for `approved — proceed to Phase 3` before producing the 9 design artifacts.

# Prime-AI Mobile App — Feature List v1 (Phase 1)

> **Phase:** 1 of 3 (Feature List). **STOP at end of this file.** Wait for `approved — proceed to Phase 2`.
> **Prompt:** `{OLD_REPO}/1-DDL_Tenant_Modules/0-Mobile_App/Claude_Prompt/PrimeAi_MobileApp_prompt_v2.md`
> **Owner:** Business Analyst + Mobile Application Architect (Claude)
> **Date:** 2026-05-05
> **Sources consumed:** Listed in `{OLD_REPO}/1-DDL_Tenant_Modules/0-Mobile_App/Claude_Context/00_context_index.md`

---

## Section 1 — Executive Summary

### 1.1 Recommended Stack — **Flutter** (Dart) for v1

**Justification (3 lines, project-grounded):**
1. **Android-first market.** Indian K-12 parents skew heavily Android (>90% of installs). Flutter ships a single AOT-compiled binary per platform with consistent performance on the low-end Android 8/9 devices that dominate this segment — exactly the constraint Hindi/regional-language K-12 users impose. React Native's JS bridge struggles on these devices for image-heavy lists (transport routes, gradebooks).
2. **Document-heavy app.** HPC PDFs (4 templates × 30–50 pages — D13), fee receipts (DomPDF), ID cards, and certificates are first-class screens. Flutter's `pdfx` / `syncfusion_flutter_pdfviewer` is more reliable than RN's PDF stack and integrates cleanly with `permission_handler` for download/share. The web app already uses DomPDF (D9) so the backend produces ready-to-render PDFs.
3. **Offline-first SQLite via Drift.** Mobile must support Indian-network reality (frequent 2G/3G drops in transit, on rural school routes). Drift gives type-safe SQLite + reactive streams, mirroring the structure of `tenant_db` tables one-to-one and supporting the queued-write/conflict-resolution model the prompt mandates. RN's WatermelonDB is competitive but Drift's tooling and migrations align better with the relational data we're mirroring.

> **Open Decision (§7 Q-1):** confirm Flutter, or override if team has a strong RN/Expo skill base. The feature catalogue below is stack-agnostic.

### 1.2 Feature count by user role and priority

| Role | P0 (MVP) | P1 (v1.1) | P2 (later) | Total touched |
|------|----------|-----------|------------|---------------|
| Student | 16 | 6 | 4 | 26 |
| Parent | 14 | 5 | 3 | 22 |
| Teacher | 8 | 7 | 2 | 17 |
| Transport Staff | 4 | 1 | 0 | 5 |
| Principal/Head | 2 | 4 | 1 | 7 |
| Accountant | 1 | 2 | 1 | 4 |
| Admin/HR/Other | 0 | 3 | 2 | 5 |
| **Cross-cutting** | 9 | 2 | 0 | 11 |

> Many features serve multiple roles — totals overlap. Catalogue has **53 distinct features (F-001 … F-145)** + 11 cross-cutting capabilities.

### 1.3 Prime-AI modules — touched vs left web-only

Status legend (cited from `modules-map.md` 2026-04-09 audit):
- **FULL** = controllers + models + routes shipped
- **PARTIAL** = scaffold present but listed as low completion in `progress.md`
- **DDL_ONLY** = table designed but no controllers
- **PLANNED** = V2 requirement doc only, no DDL or code

**Touched on mobile (P0/P1):**

| Module | Status | Mobile coverage | Notes |
|--------|--------|-----------------|-------|
| StudentPortal | PARTIAL ~50% | Heavy (most P0 features for students) | IDOR in `proceedPayment` and Exam attempt confirmed unpatched (SEC-STP-007/008). Mobile must NOT replicate the IDOR pattern. |
| Hpc | FULL ~70% | View HPC PDF, parent form token | 4 PDF templates DomPDF-fixed. SEC-HPC-001 critical (13/15 controllers no auth). |
| StudentProfile | PARTIAL ~20% | Profile, attendance read, health records | Leave subsystem dead code (no LeaveController, no routes). Aadhaar/PAN plaintext (Transport too). |
| StudentFee | PARTIAL ~50% | Fee summary, dues, receipts (read) | SEC-STP-007 IDOR; FeeInvoice IDOR; SR-AUTH-001. Mobile pay flow must verify ownership server-side, not relay client-supplied IDs. |
| Payment | PARTIAL ~45% | Razorpay deep-link/webview | **BLOCKED** — DDL absent (BUG-NEW-001: 3 broken prefixes ptm/pmt/none). Webhook behind auth (SEC-004). Mobile can call `proceedPayment` only after fixes. |
| Notification | PARTIAL ~35% | Inbox, push, preferences | **BLOCKED** — all routes commented (BUG-NEW-002). Gate prefix `prime.*` mismatch (SEC-VND-006-style). Mobile inbox needs route reactivation. |
| Transport | PARTIAL ~40% | Route view, live trip GPS, driver execution, boarding QR, incident report | Module web.php registers 0 tenant routes (transport tenant.* misrouted). Aadhaar/PAN plaintext on driver records. |
| LmsHomework | PARTIAL ~52% | Homework list, submit, view | SEC-HWK-003 IDOR on `show()`. Submission portal currently absent on web. |
| LmsQuiz | PARTIAL ~72% | Quiz attempt | Most-mature LMS submodule. Route prefix typo `lms-quize` (cosmetic). |
| LmsQuests | PARTIAL ~52% | Quest attempt (P1) | SEC-QZT-002 commented Gate. |
| LmsExam | PARTIAL ~55% | Exam schedule view; **online exam attempt deferred to P1** | SEC-EXM-005 IDOR on grievance review. PERF-LMS-002 9+ unbounded queries. |
| Syllabus | PARTIAL ~55% | Syllabus progress (read), lesson plan view | 14 of 15 controllers unrouted. |
| QuestionBank | PARTIAL ~45% | Self-practice (P2) | API keys ROTATED + moved to env (SEC-NEW-001 partial). AI generation returns demo data (dead code). |
| Library | FULL ~? | Catalog browse, my books (P1) | Module IS in tenant.php (was earlier reported wrong). |
| Complaint | PARTIAL ~30% | Complaint submit, status track (P1) | 6 routes point to non-existent methods (500). dummy_table_name dropdown bug. |
| SchoolSetup | PARTIAL ~40% | Read-only directory (teachers, classes); Employee leave apply (P1) | Employee Leave DDL v4 (D33) ready, code pending. |
| ParentPortal | PLANNED (DDL prompt ready) | Heavy (P2/P3 of features) | `5-Work-In-Progress/ParentPortal/1-Claude_Prompt/PPT_2step_Prompt1.md` — 6 ppt_* tables, 38 screens. Mobile plays a major role here. |
| Hostel | PLANNED (DDL v3 ready, D34) | Mess opt-out, leave-pass, sick-bay alert (P2) | `HST_DDL_v3.sql` 36 tables. Code unstarted. |
| Cafeteria | PLANNED (CAF_2step_Prompt1.md) | Meal-card balance, QR scan top-up (P2) | 21 caf_* tables. POS counter is web-only. |
| Certificate | PLANNED (CRT_2step_Prompt1.md) | View / share earned certificates (P1) | 10 crt_* tables. Public verification URL. |
| FrontOffice | PLANNED (FOF_2step_Prompt1.md) | Gate pass / early-departure (P1, principal) | 22 fof_* tables. |
| HrStaff | PLANNED (HRS_2step_Prompt1.md) | Self-service: payslip view, leave apply (P1) | 15 hrs_* tables. |
| Communication | PLANNED | Parent-teacher 1:1 chat (P1) | 14 com_* tables, DLT SMS, 7-state delivery FSM. |

**Left web-only (no mobile feature in v1.0/v1.1):**

| Module | Status | Why excluded from mobile |
|--------|--------|---------------------------|
| Prime, Billing, GlobalMaster, SystemConfig | Central (FULL) | SaaS admin, not for school users |
| SmartTimetable | FULL ~60% | FET solver, 24+60 constraint classes, 3037-line god controller — generation/refinement is web-only. Mobile reads the *result*. |
| TimetableFoundation | FULL | Configuration setup, web-only. |
| Vendor | PARTIAL ~50% | Procurement-side; not student/parent/teacher daily flow. |
| Inventory | PLANNED | Stockroom workflow (GRN/PO/PR), web-only. |
| Accounting | PARTIAL ~30% | Voucher engine, double-entry. Reports may surface on Principal mobile dashboard later. |
| MarksheetGeneration | DDL_ONLY | Backend computation only — output is `lms_exam_results` which mobile already reads. |
| Feedback | DDL_ONLY | Survey design + compliance reporting → web. Survey *response* may move to mobile in a v1.2 (excluded from v1). |
| StandardTimetable | PARTIAL stub | Skeleton only. |
| Scheduler, EventEngine | PARTIAL ~25% | Internal infra, no UI. |
| QuestionBank authoring | PARTIAL | Question entry is web-only. Self-practice consumption may surface on mobile in P2. |
| Recommendation | PARTIAL ~39% | Rules editing web-only. Output (recommended materials) read-only on mobile. |
| Admission | PLANNED | Application form is for *prospective* students/parents (no app account yet). Web-only. |
| Maintenance | PLANNED | Internal facility tickets, web. |
| VisitorSecurity | PLANNED | Gate-pass kiosk. Public scan URL only on mobile. |
| Template, Documentation | PARTIAL | Author/editor — web. |

### 1.4 Architectural notes

**Auth flow (mobile)**

```
[Cold start]
  → App splash → check secure-storage for {tenantHostOrCode + sanctumToken}
  → If absent: Tenant Resolution screen (Q-2: enter school subdomain | tenant code | scan onboarding QR)
    → call POST {host}/api/mobile/v1/tenant/resolve  → returns {tenant_uuid, tenant_name, branding, supported_modules}
  → If present: silent token-refresh ping POST /api/mobile/v1/auth/me
    → if 401 → Login screen
[Login]
  → POST /api/mobile/v1/auth/login {email_or_phone, password, device_token, device_meta}
    → returns {sanctum_token, user{id, role, user_type}, child_list (if PARENT)}
  → store sanctum_token in flutter_secure_storage (Keychain / EncryptedSharedPreferences)
  → register FCM/APNs token via POST /api/mobile/v1/devices
[Subsequent requests]
  Headers:  Authorization: Bearer <sanctum_token>
            X-Tenant-Host: schoolxyz.prime-ai.com   (or X-Tenant-Code)
            X-App-Version, X-Platform, X-Device-Id
  → InitializeTenancyByDomain reads X-Tenant-Host (NEW middleware variant required — current middleware reads HTTP host)
  → EnsureTenantIsActive
  → EnsureTenantHasModule (mobile-flag enabled per plan)
[Refresh / re-auth]
  → Sanctum tokens have null expiry by config (project-context.md).
    Mobile must add a configurable rolling refresh policy (default 7 days inactivity → re-login).
  → Biometric unlock unlocks the existing token without forcing re-login (token kept in secure-storage).
```

**Push strategy** — FCM (Android) + APNs (iOS) only at v1. Backend sends via a new `MobilePushDispatcher` service. Routes through existing `Notification` module → new channel `MOBILE_PUSH` in `ntf_notification_channels`. Each push payload includes `deep_link` (URI per `mobile_information_architecture.md` in Phase 3) + `event_type` + `subject_id`. Quiet hours (configurable per user) honored via `ntf_user_preferences`. SMS fallback deferred to v1.1 (planned `Communication` module).

**Offline strategy (Drift / SQLite)**

| Cached locally | Read | Write | Sync trigger |
|----------------|------|-------|--------------|
| User profile, child list | Yes (24h TTL) | No | Login + manual refresh |
| Today's timetable | Yes (until end of day) | No | Pull on dashboard open |
| Today's attendance roster (Teacher) | Yes (full day) | **Queued write** (mark attendance) | Background sync every 60s + on connectivity-on event |
| Lesson plans (assigned) | Yes (current term) | No | Pull on Lesson tab open |
| Homework list (current week + 30 days) | Yes | **Queued write** (submission) | Connectivity-on event |
| Fee invoices (open + 12-month history) | Yes | No (payment is online-only) | Pull on Fees tab open |
| Notifications inbox (last 100) | Yes | **Queued read-receipt** | Background |
| Transport route + stops (assigned) | Yes (full route) | No | Pull on Transport tab open |
| Live trip GPS (driver) | Streaming | **Queued GPS pings** | Background, every 30s with batching |
| HPC PDF, ID card, certificate (downloaded) | Yes (file) | No | One-shot download |

**Conflict resolution**: server-wins for read-only entities; for queued writes (attendance, submission, GPS pings) use idempotency keys (`X-Idempotency-Key: <uuid>`) — server upserts on `(student_id, date)` for attendance, on `(submission_id)` for homework. Last-write-wins on submissions; server returns conflict rows with `409 + canonical_record` so mobile can drop the local copy.

**Tenant resolution** — see Auth flow above. Three input paths: subdomain, tenant-code, onboarding QR. The `X-Tenant-Host` header is the explicit signal — *do not* rely on HTTP host because mobile clients may use a single API gateway hostname (`api.prime-ai.com`) rather than per-tenant subdomains. This requires a backend gap item: a new `InitializeTenancyByHeader` middleware variant.

---

## Section 2 — Feature Catalogue

> **Conventions:** Every feature has a 20-row table with the exact field set required by the prompt §1.A. Source modules cite `modules-map.md` audit dates. Source tables cite `db-schema.md` and the relevant DDL prefixes. Open security risks cite IDs from `known-bugs-and-roadmap.md` and module rows in `state/progress.md`.

### 2.1 Authentication & Onboarding

#### F-001: Multi-Tenant App Setup & School Lookup

| Field | Value |
|-------|-------|
| Feature ID | F-001 |
| Functional Area | Authentication |
| Source Module(s) | Prime (central) |
| Module Status | FULL ~65% (Prime), but no mobile-specific endpoint yet |
| Existing Web Surface | None — web app uses HTTP host header to resolve tenant; mobile cannot |
| Source Tables | `prm_tenant`, `prm_tenant_domains`, `prm_plans`, `prm_tenant_plan_module_jnt` |
| Description | First-launch screen lets user identify their school by typing the school subdomain (e.g. `xyz` → `xyz.prime-ai.com`), entering a 6-character tenant code printed on the school's onboarding sheet, or scanning a school-issued QR code. Validates with the backend, fetches branding (logo, color, app name), and pins this tenant for the app install. |
| Primary Users | All roles (first-time setup) |
| Secondary Users | n/a |
| Mobile Justification | §4.2 (device cap — camera for QR), §4.4 (web flow has no equivalent — host header is automatic on web) |
| Trigger / Entry Point | First app launch / "switch school" action in Settings |
| Key Screens | Welcome → Tenant Lookup (3 input modes) → Branding Confirm → Login |
| Device Capabilities | Camera (QR), Push (after login) |
| Offline Behavior | None (network required) |
| Backend Dependency | **NEW API needed** — `POST /api/mobile/v1/tenant/resolve` and `GET /api/mobile/v1/tenant/{code}/branding` in `Modules/Prime/`. Owning module = Prime. |
| RBS Mapping | TBD (Phase 2) |
| Notification Triggers | None |
| Priority | P0 |
| Complexity | M |
| Security Risks Inherited | SEC-PLATFORM-002 (env('APP_DOMAIN') in routes — must use `config('app.domain')`). BUG-004 (tenant onboarding pipeline broken — but resolve is read-only so unaffected). |
| Open Questions | See §7 Q-2: which input modes are required at v1? Branding fields — logo only or full theme? |

---

#### F-002: Login (Email/Phone + Password)

| Field | Value |
|-------|-------|
| Feature ID | F-002 |
| Functional Area | Authentication |
| Source Module(s) | App\Models\User (sys_users tenant table); Sanctum |
| Module Status | FULL (Sanctum already configured per `project-context.md`) |
| Existing Web Surface | `routes/auth.php` web login (Student Portal `/student-portal/login` 2026-04-02 ✅) |
| Source Tables | `sys_users` (tenant), `sys_model_has_roles_jnt`, `personal_access_tokens` |
| Description | Standard login: enter email or phone + password. Returns Sanctum token, user profile, role, and (for Parent) the list of accessible children. Stores token in OS-level secure storage. Supports a "Remember device" toggle that registers the device with FCM/APNs token. |
| Primary Users | All roles |
| Secondary Users | n/a |
| Mobile Justification | §4.2 (biometric for subsequent unlock), §4.1 (multiple times per day re-auth via biometric) |
| Trigger / Entry Point | After tenant resolved or token expired |
| Key Screens | Login → 2FA (if configured) → Home |
| Device Capabilities | Biometric (later sessions), Push (after first login) |
| Offline Behavior | None |
| Backend Dependency | **NEW API needed** — `POST /api/mobile/v1/auth/login` (a thin wrapper over existing Sanctum `POST /tokens/create`). Existing endpoints are session-based, not token-based, for portal users. |
| RBS Mapping | TBD |
| Notification Triggers | "New device login" push to user (P1) |
| Priority | P0 |
| Complexity | S |
| Security Risks Inherited | SEC-PLATFORM-004 (`is_super_admin` in $fillable — DO NOT relay client-side); BUG-008 (duplicate `user_type` and `two_factor_auth_enabled` in $fillable). Mobile must not trust returned User object beyond the documented fields — use a Resource transformer. |
| Open Questions | 2FA — total TOTP / OTP — is it active for any role? `two_factor_auth_enabled` exists on User but no portal flow surfaces it. |

---

#### F-003: Forgot Password / OTP Reset

| Field | Value |
|-------|-------|
| Feature ID | F-003 |
| Functional Area | Authentication |
| Source Module(s) | App (password reset), Notification (delivery) |
| Module Status | FULL (web `/forgot-password` exists per tenancy-map.md `routes/auth.php`) |
| Existing Web Surface | `routes/tenant.php` auth routes |
| Source Tables | `password_reset_tokens` (Laravel default) |
| Description | Email or phone-based password reset. User enters email/phone → receives an email link or 6-digit OTP → enters OTP → sets new password. |
| Primary Users | All roles |
| Secondary Users | n/a |
| Mobile Justification | §4.4 (lower-friction than web for users without inbox access on mobile) |
| Trigger / Entry Point | "Forgot password" link on Login screen |
| Key Screens | Enter email/phone → OTP input → New password |
| Device Capabilities | None |
| Offline Behavior | None |
| Backend Dependency | **NEW API + LIKELY NEW DELIVERY CHANNEL** — `POST /api/mobile/v1/auth/forgot` and `POST /api/mobile/v1/auth/reset`. Phone-based OTP requires SMS — depends on `Communication` module (PLANNED). For v1 email-only OTP using existing mailer (LoginMail style). |
| RBS Mapping | TBD |
| Notification Triggers | Reset email; "Password changed" alert (P1) |
| Priority | P0 |
| Complexity | M |
| Security Risks Inherited | None directly. Apply rate limiting (throttle:5,2 per `student-parent-portal.md` recommendation). |
| Open Questions | SMS OTP at v1 (waits on `Communication` module) or email-only? |

---

#### F-004: Biometric Unlock

| Field | Value |
|-------|-------|
| Feature ID | F-004 |
| Functional Area | Authentication |
| Source Module(s) | n/a (client-only) |
| Module Status | n/a |
| Existing Web Surface | None |
| Source Tables | None (token + device flag in secure storage) |
| Description | After first password login, user may enable Face ID / Touch ID / Android biometric to unlock the app on subsequent launches without retyping password. Biometric unlocks the locally stored Sanctum token; failure falls back to password. |
| Primary Users | All roles |
| Secondary Users | n/a |
| Mobile Justification | §4.1 (used multiple times daily); §4.2 (device biometric) |
| Trigger / Entry Point | Settings → "Enable biometric" toggle, prompted post-first-login |
| Key Screens | Biometric prompt overlay |
| Device Capabilities | Biometric, Secure storage |
| Offline Behavior | Full — works offline if token still valid |
| Backend Dependency | None |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P0 |
| Complexity | S |
| Security Risks Inherited | None. Use Keychain Access Group / Android Keystore — never AES-keys-in-prefs. |
| Open Questions | None |

---

#### F-005: Multi-Child Switcher (Parent)

| Field | Value |
|-------|-------|
| Feature ID | F-005 |
| Functional Area | Authentication / Context |
| Source Module(s) | StudentProfile, ParentPortal (PLANNED) |
| Module Status | StudentProfile FULL; ParentPortal PLANNED |
| Existing Web Surface | Web Parent Portal screen P3 — "0% Missing" per `student-parent-portal.md` |
| Source Tables | `std_student_guardian_jnt` (with `can_access_parent_portal=true` flag, `is_fee_payer` flag), `std_students`, `std_guardians` |
| Description | A parent with two or more children sees a header pill showing the active child; tapping shows a list of all children they can access. Selecting one updates the global "active child" context for every screen (timetable, fees, attendance, results, transport, etc.). |
| Primary Users | Parent |
| Secondary Users | n/a |
| Mobile Justification | §4.1 (every screen request); §4.4 (web has the same pattern but mobile expects a sticky pill, not a dropdown) |
| Trigger / Entry Point | Header avatar tap; first-login auto-selects first accessible child (per `student-parent-portal.md` D3) |
| Key Screens | Child Switcher modal |
| Device Capabilities | None |
| Offline Behavior | Full — child list cached; switching uses local state |
| Backend Dependency | **NEW API needed** — `GET /api/mobile/v1/me/children`. Server stores `active_student_id` in token claims OR client passes `X-Active-Student-Id` header on every request. Recommend the latter (stateless). Backend must validate guardian-child binding **on every endpoint** (parent IDOR is the #1 risk per `student-parent-portal.md`). |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P0 |
| Complexity | M |
| Security Risks Inherited | **CRITICAL** — every parent endpoint must enforce `ParentChildPolicy` (planned in `5-Work-In-Progress/ParentPortal/1-Claude_Prompt/PPT_2step_Prompt1.md` BR-PPT-012). Web Parent Portal is "P0 IDOR" risk per portal doc. Mobile must replicate the policy, not bypass it. |
| Open Questions | Should the active child be propagated via header, query string, or path? Header is least error-prone. |

---

### 2.2 Dashboard & Home

#### F-010: Student Dashboard

| Field | Value |
|-------|-------|
| Feature ID | F-010 |
| Functional Area | Dashboard |
| Source Module(s) | StudentPortal (S2) |
| Module Status | StudentPortal PARTIAL ~50% — Dashboard ✅ |
| Existing Web Surface | `/student-portal/dashboard` |
| Source Tables | aggregates from `std_attendance_details`, `lms_homework_submissions`, `tt_timetable_cells`, `fin_fee_invoices`, `lms_exam_allocations`, `ntf_notifications` |
| Description | Glance home for a student: today's classes, today's attendance status, due homework count, pending fee dues, upcoming exams, and unread notifications. Each tile deep-links into the corresponding feature. |
| Primary Users | Student |
| Secondary Users | n/a |
| Mobile Justification | §4.1, §4.4 |
| Trigger / Entry Point | Default home after login |
| Key Screens | Home (tile grid) |
| Device Capabilities | Push (badges on tiles) |
| Offline Behavior | Read-only (last cached snapshot, with timestamp) |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/student/dashboard`. Aggregator already exists on web (`StudentDashboardAggregatorService` per `student-parent-portal.md` D4) — wrap it. |
| RBS Mapping | TBD |
| Notification Triggers | None (consumes inbound push) |
| Priority | P0 |
| Complexity | M |
| Security Risks Inherited | N+1 risk on nested eager loads noted in `student-parent-portal.md` S2. Mobile dashboard call MUST be a single optimized aggregator response, not multiple parallel requests. |
| Open Questions | Tile order — fixed or user-customizable? |

---

#### F-011: Parent Dashboard

| Field | Value |
|-------|-------|
| Feature ID | F-011 |
| Functional Area | Dashboard |
| Source Module(s) | ParentPortal (P2 — PLANNED) |
| Module Status | PLANNED — 0% Missing per `student-parent-portal.md` |
| Existing Web Surface | None (planned route `/parent-portal/dashboard`) |
| Source Tables | aggregates from std_*, lms_*, fin_*, tpt_*, hpc_* tables for the active child |
| Description | Per-active-child summary: today's attendance, today's class count, fee balance, recent test scores, current HPC status, transport pickup status, unread notifications. Cycles between children via the child switcher (F-005). |
| Primary Users | Parent |
| Secondary Users | n/a |
| Mobile Justification | §4.1, §4.4 |
| Trigger / Entry Point | Default home for Parent role after login |
| Key Screens | Home (tile grid + child pill) |
| Device Capabilities | Push |
| Offline Behavior | Read-only cached |
| Backend Dependency | **NEW API + NEW BACKEND MODULE** — `GET /api/mobile/v1/parent/dashboard?student_id={id}`. Belongs in `Modules/ParentPortal/` (PLANNED). `ParentDashboardAggregatorService` planned in PPT_2step_Prompt1.md. |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P0 |
| Complexity | L |
| Security Risks Inherited | ParentPortal is greenfield — must implement `ParentChildPolicy` from day 1 (BR-PPT-012). |
| Open Questions | Multi-child consolidated dashboard view (all children at a glance) vs single-active-child? |

---

#### F-012: Teacher Dashboard

| Field | Value |
|-------|-------|
| Feature ID | F-012 |
| Functional Area | Dashboard |
| Source Module(s) | SchoolSetup (Teacher), SmartTimetable, LmsHomework |
| Module Status | SchoolSetup PARTIAL ~40%; SmartTimetable FULL ~60% |
| Existing Web Surface | None (no dedicated teacher dashboard on web — Teachers currently use the admin dashboard at /dashboard which has zero auth — a critical gap) |
| Source Tables | `tt_timetable_cells`, `tt_timetable_cell_teachers`, `std_attendance_details`, `lms_homework`, `cmp_complaints` (assigned), `sch_employee_leave_applications` (mine + pending-approvals) |
| Description | Today's classes (period-by-period), pending attendance to mark, homework to grade, upcoming substitution requests, leave applications pending my approval. Quick actions: mark attendance, mark absent. |
| Primary Users | Teacher |
| Secondary Users | Class Teacher (extra widget — class-level attendance summary) |
| Mobile Justification | §4.1, §4.3, §4.4 |
| Trigger / Entry Point | Default home for Teacher role |
| Key Screens | Home with day-list of periods |
| Device Capabilities | Push, Biometric |
| Offline Behavior | Read-only cached |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/teacher/dashboard`. New module concern: there is no dedicated TeacherPortal module in modules-map.md. Decide: extend `StudentPortal` paradigm with a sister `TeacherPortal` module, or layer on `Modules/SmartTimetable/` + `Modules/SchoolSetup/`. |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P0 |
| Complexity | L |
| Security Risks Inherited | Existing `Modules/Dashboard` ZERO authorization (P0 in `progress.md`). Mobile dashboard MUST authorize per teacher_id, not just any user. |
| Open Questions | Should non-teacher employees (admin, accountant, librarian) see Teacher dashboard or a separate F-013? Recommend separate. |

---

#### F-013: Principal / Head Dashboard

| Field | Value |
|-------|-------|
| Feature ID | F-013 |
| Functional Area | Dashboard |
| Source Module(s) | Aggregates across SchoolSetup, StudentProfile, StudentFee, Hpc, Notification |
| Module Status | Components FULL; aggregator does not exist |
| Existing Web Surface | None (admin dashboard is generic, zero auth) |
| Source Tables | aggregates from std_*, fin_*, sch_*, ntf_* |
| Description | Daily KPIs: attendance %, today's collection, open complaints/SLAs, pending approvals (leave, exam, HPC publish), notice draft inbox. |
| Primary Users | Principal, VicePrincipal, SchoolAdmin |
| Secondary Users | n/a |
| Mobile Justification | §4.1 (daily glance), §4.4 (web is bloated; principal needs glance + approve) |
| Trigger / Entry Point | Default home for principal role |
| Key Screens | Home (KPI cards + pending approvals queue) |
| Device Capabilities | Push, Biometric |
| Offline Behavior | Read-only cached |
| Backend Dependency | **NEW API + new aggregator** — `GET /api/mobile/v1/principal/dashboard`. Likely lives in `Modules/Dashboard/` with proper authorization for the first time. |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P1 |
| Complexity | L |
| Security Risks Inherited | `Modules/Dashboard` ZERO Gate auth currently. Mobile must demand a real principal-scoped policy. |
| Open Questions | Which KPIs are P1 vs P2? Exam pass% / fee collection trend / etc. require additional reporting tables. |

---

### 2.3 Attendance

#### F-020: Mark Class Attendance (Teacher)

| Field | Value |
|-------|-------|
| Feature ID | F-020 |
| Functional Area | Attendance |
| Source Module(s) | StudentProfile (currently) — supersession by planned `Attendance` module (`att_*` 14 tables) noted in modules-map.md |
| Module Status | StudentProfile PARTIAL ~20% — `AttendanceController` Gate facade not imported (fatal); validation commented out |
| Existing Web Surface | StudentProfile/AttendanceController — broken |
| Source Tables | `std_attendance_details`, `std_attendance_corrections`, `tt_timetable_cells`, `sch_class_section_jnt`, `std_students` |
| Description | Open today's class roster (resolved from active period), mark each student Present/Absent/Late/Leave/Half-day with one-tap row toggles. Bulk actions ("Mark all present"). Adds remark per student if needed. Submits with idempotency key. |
| Primary Users | Teacher |
| Secondary Users | Class Teacher (review/correct same day) |
| Mobile Justification | §4.1 (multiple times daily), §4.2 (offline-tolerant — schools have weak signal in classrooms), §4.4 (web is heavy for a per-class action) |
| Trigger / Entry Point | Period tile on Teacher Dashboard, or "Today's Classes" tab |
| Key Screens | Class list → Roster → Confirm |
| Device Capabilities | Offline (queued writes) |
| Offline Behavior | Queued writes — capture marks locally; sync on connectivity. |
| Backend Dependency | **NEW API** — `POST /api/mobile/v1/attendance` `{class_section_id, period_id, date, marks: [{student_id, status_id, remark}]}` with `X-Idempotency-Key`. Existing AttendanceController has fatal Gate import bug (must be fixed). Strongly recommend implementing in the **new planned `Attendance` (`att_*`) module** rather than patching StudentProfile, per `progress.md`. |
| RBS Mapping | TBD |
| Notification Triggers | "Your child was marked absent today" → Parent (real-time push) |
| Priority | P0 |
| Complexity | L |
| Security Risks Inherited | StudentProfile attendance: `Gate facade not imported in AttendanceController` — fatal. `storeBulkAttendance` validation fully commented out. Mobile API must be built on a freshly authorized controller, not the current broken one. |
| Open Questions | Half-day handling — split AM/PM rows or single attendance with `is_half_day` flag? Existing schema has no half-day column. |

---

#### F-021: View My Attendance (Student)

| Field | Value |
|-------|-------|
| Feature ID | F-021 |
| Functional Area | Attendance |
| Source Module(s) | StudentPortal (S8) |
| Module Status | ✅ FULL on web |
| Existing Web Surface | `/student-portal/my-attendance` |
| Source Tables | `std_attendance_details`, `sch_holidays`, `tt_timetable_cells` |
| Description | Calendar view + summary % for current term. Day-detail shows per-period status. Term-over-term trend chart. |
| Primary Users | Student |
| Secondary Users | n/a |
| Mobile Justification | §4.1 |
| Trigger / Entry Point | Tile on Student Dashboard |
| Key Screens | Calendar → Day detail |
| Device Capabilities | Offline |
| Offline Behavior | Read-only cached (current term) |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/student/attendance?from=&to=`. Existing portal controller logic adaptable. |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P0 |
| Complexity | S |
| Security Risks Inherited | Web S8 already authorized via `EnsureStudentAccess` middleware — replicate. |
| Open Questions | Show subject-wise attendance% (depends on per-period attendance vs daily)? |

---

#### F-022: View Child Attendance (Parent)

| Field | Value |
|-------|-------|
| Feature ID | F-022 |
| Functional Area | Attendance |
| Source Module(s) | ParentPortal (P5 — PLANNED) |
| Module Status | PLANNED 0% per portal doc |
| Existing Web Surface | None |
| Source Tables | same as F-021 |
| Description | Same as F-021 but scoped to active child. Push notification on "marked absent today". |
| Primary Users | Parent |
| Secondary Users | n/a |
| Mobile Justification | §4.1, §4.3 (same-day absence push) |
| Trigger / Entry Point | Parent dashboard tile |
| Key Screens | Calendar → Day detail |
| Device Capabilities | Push, Offline |
| Offline Behavior | Read-only cached |
| Backend Dependency | **NEW API + new ParentPortal controller** — `GET /api/mobile/v1/parent/student/{id}/attendance?from=&to=` |
| RBS Mapping | TBD |
| Notification Triggers | "Marked absent today" → fee-payer + active guardian; "Late arrival" → all guardians |
| Priority | P0 |
| Complexity | S |
| Security Risks Inherited | ParentChildPolicy required (BR-PPT-012). |
| Open Questions | Push policy — every absence vs only first absence in a day vs only N consecutive absences? |

---

#### F-023: Self-Punch Attendance (Employee)

| Field | Value |
|-------|-------|
| Feature ID | F-023 |
| Functional Area | Attendance |
| Source Module(s) | SchoolSetup (Employee Setup DDL v4 — D33) |
| Module Status | DDL_ONLY (`sch_employee_attendance_punches`, `sch_employee_attendance_corrections` from D33) |
| Existing Web Surface | None |
| Source Tables | `sch_employee_attendance_punches` (raw biometric/mobile), `sch_employee_attendance` (rolled-up day record), `sch_employee_shift_assignments` |
| Description | Teachers and other employees punch IN/OUT from the app. Captures GPS lat/lng (device.geo column already in v4 schema), photo selfie (per row `source = 'mobile'`). Late/early metrics computed by backend service. |
| Primary Users | Teacher, Staff |
| Secondary Users | n/a |
| Mobile Justification | §4.2 (GPS, camera selfie), §4.1 |
| Trigger / Entry Point | Floating "Punch IN/OUT" button on Teacher dashboard |
| Key Screens | Punch confirm → Selfie → GPS confirm |
| Device Capabilities | GPS, Camera, Push (reminder) |
| Offline Behavior | Queued — punches stored locally, GPS captured at moment of punch (not at sync time) |
| Backend Dependency | **NEW** — `POST /api/mobile/v1/employee/punch` `{type: IN|OUT, lat, lng, selfie_media_id, ts}`. Module: SchoolSetup or new HrStaff module (planned). |
| RBS Mapping | TBD |
| Notification Triggers | "Forgot to punch out" reminder push (P1) |
| Priority | P1 |
| Complexity | M |
| Security Risks Inherited | None directly. Verify GPS isn't spoofed (server-side check vs configured school radius). |
| Open Questions | Geo-fence radius — per school setting? Selfie required at v1 or v1.1? |

---

### 2.4 Academics — Timetable, Syllabus, Lesson Plans, Homework

#### F-030: My Timetable (Student / Teacher)

| Field | Value |
|-------|-------|
| Feature ID | F-030 |
| Functional Area | Academics |
| Source Module(s) | SmartTimetable, TimetableFoundation |
| Module Status | FULL ~60% (SmartTimetable) |
| Existing Web Surface | `/student-portal/my-timetable` (S7 ✅), and Teacher views via SmartTimetable |
| Source Tables | `tt_timetable_cells`, `tt_timetable_cell_teachers`, `tt_activities`, `sch_subjects`, `sch_class_section_jnt`, `sch_rooms`, `tt_period_set_periods` |
| Description | Day/Week tabs. Per period: subject, teacher, room. Color-coded by subject. Tap → period detail (cell teachers, lesson plan link, room change indicator). Highlights "now" cell. |
| Primary Users | Student, Teacher |
| Secondary Users | Parent (P6 view) |
| Mobile Justification | §4.1 (multiple checks daily) |
| Trigger / Entry Point | Tile / bottom-tab |
| Key Screens | Day → Week → Period detail |
| Device Capabilities | Offline |
| Offline Behavior | Full (week cache) |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/timetable?role=student|teacher&from=&to=`. Existing portal controller methods adaptable. |
| RBS Mapping | TBD |
| Notification Triggers | "Substitution today: P3 you replace Mr. X" → Teacher (P1) |
| Priority | P0 |
| Complexity | M |
| Security Risks Inherited | RoomChangeTrackingService exists (D20) — re-use. |
| Open Questions | Show parallel periods / Hobby/Skill markers (D14 pattern) on mobile? Recommend yes. |

---

#### F-031: Syllabus Progress (Student)

| Field | Value |
|-------|-------|
| Feature ID | F-031 |
| Functional Area | Academics |
| Source Module(s) | Syllabus, StudentPortal (S9) |
| Module Status | Syllabus PARTIAL ~55%; S9 ✅ on web |
| Existing Web Surface | `/student-portal/syllabus-progress` |
| Source Tables | `slb_lessons`, `slb_topics`, `slb_subject_syllabus`, `slb_syllabus_schedules`, `slb_competencies` |
| Description | Per-subject completion bars + topic checklist with status (Not Started / In Progress / Done). Tap topic → linked study materials, books, and competencies. |
| Primary Users | Student |
| Secondary Users | Parent (read-only via P4) |
| Mobile Justification | §4.1 |
| Trigger / Entry Point | Tile |
| Key Screens | Subject list → Subject detail (topic tree) → Topic detail |
| Device Capabilities | Offline |
| Offline Behavior | Read-only cached (whole term) |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/student/syllabus`. |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P0 |
| Complexity | M |
| Security Risks Inherited | Syllabus has 14 of 15 controllers unrouted; CompetencieController has 6 zero-Gate methods. Mobile MUST go through a freshly hardened API path. |
| Open Questions | Display competency mastery from HPC linkages? |

---

#### F-032: Lesson Plan Viewer (Teacher)

| Field | Value |
|-------|-------|
| Feature ID | F-032 |
| Functional Area | Academics |
| Source Module(s) | Syllabus + future `Academics` module (PLANNED — `acd_*` 31 tables) |
| Module Status | Syllabus PARTIAL; Academics PLANNED |
| Existing Web Surface | partial — Syllabus module shows lessons but no dedicated lesson-plan viewer |
| Source Tables | `slb_lessons`, `slb_topics`, planned `acd_lesson_plans` |
| Description | List my assigned lessons by date. Per lesson: objectives, materials, activities, homework template, attached files. Read-only on mobile. |
| Primary Users | Teacher |
| Secondary Users | n/a |
| Mobile Justification | §4.2 (offline reading in classroom), §4.1 |
| Trigger / Entry Point | Period tile → Lesson Plan link |
| Key Screens | Lesson list → Lesson detail |
| Device Capabilities | Offline |
| Offline Behavior | Full (current week + next week cached) |
| Backend Dependency | **NEW API + dependent on Academics module which is PLANNED** — partial v1 from Syllabus until Academics ships. |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P0 (read), P1 (annotate) |
| Complexity | M |
| Security Risks Inherited | Syllabus auth gaps (above). |
| Open Questions | Allow private teacher annotations on lessons? (Likely v1.1.) |

---

#### F-040: Homework List & Detail (Student)

| Field | Value |
|-------|-------|
| Feature ID | F-040 |
| Functional Area | Academics — Homework |
| Source Module(s) | LmsHomework |
| Module Status | PARTIAL ~52%. **SEC-HWK-003 IDOR** on `show()`. |
| Existing Web Surface | partial — visible via Student learning hub |
| Source Tables | `lms_homework`, `lms_homework_allocations`, `lms_homework_submissions`, planned `lms_homework_assignment` (BUG-NEW-004 — currently missing) |
| Description | Tabs: Pending / Submitted / Graded. Per item: subject, topic, due date, late-submission status, attachment list. Tap → detail with description, attachments, submission box. |
| Primary Users | Student |
| Secondary Users | Parent (P7 read) |
| Mobile Justification | §4.1, §4.2 (offline read) |
| Trigger / Entry Point | Dashboard tile / bottom-tab |
| Key Screens | List → Detail |
| Device Capabilities | Offline |
| Offline Behavior | Read-only cached (current week + due-not-submitted) |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/student/homework?status=`. Pre-req: fix SEC-HWK-003 (IDOR on show), and create the missing `lms_homework_assignment` migration (BUG-NEW-004) before exposing publish-related fields. |
| RBS Mapping | TBD |
| Notification Triggers | "New homework assigned" push to student + parent |
| Priority | P0 |
| Complexity | M |
| Security Risks Inherited | SEC-HWK-003 (IDOR on show); BUG-NEW-004 (missing table); SR-AUTH-003 (AJAX endpoints unauthenticated — applies to mark-read endpoints which the inbox might reuse). |
| Open Questions | Group homework (multiple students submit same artifact) — supported? |

---

#### F-041: Submit Homework — File / Photo / Text (Student)

| Field | Value |
|-------|-------|
| Feature ID | F-041 |
| Functional Area | Academics — Homework |
| Source Module(s) | LmsHomework |
| Module Status | PARTIAL ~52% — **submission portal currently absent on web** per `progress.md` |
| Existing Web Surface | None (S13 in `student-parent-portal.md` flagged "No submission endpoint") |
| Source Tables | `lms_homework_submissions`, attachments → `sys_media` (Spatie) or new LMS storage path (D28) |
| Description | Compose a submission: take photo of homework book pages, attach PDF/image/doc, type a text answer, upload one or many files. Validation: file size, mime types per `lms_homework.allowed_file_types`. Late submission gated by `restrict_late_submission`. |
| Primary Users | Student |
| Secondary Users | n/a |
| Mobile Justification | §4.2 (camera primary capture mode), §4.1 |
| Trigger / Entry Point | "Submit" button on Homework Detail (F-040) |
| Key Screens | Compose → Add file/photo/text → Confirm |
| Device Capabilities | Camera, File Picker, Storage |
| Offline Behavior | Queued write (submission attempts are queued; large media uploads resume on connectivity) |
| Backend Dependency | **NEW API** — `POST /api/mobile/v1/student/homework/{id}/submit`. Backend needs: a brand-new submission endpoint (does not exist on web), upload to LMS cloud storage path (D28 `lms_homework_upload_path`). |
| RBS Mapping | TBD |
| Notification Triggers | "Submission received" → student; "New submission" → teacher |
| Priority | P0 |
| Complexity | L |
| Security Risks Inherited | LMS storage path config is currently advisory (D28 — no implementation yet). Mass-assignment risk via D25 — must use validated() not all(). |
| Open Questions | Storage server live? Per D28 advisory, separate cloud server is planned but not implemented. Local fallback path acceptable for v1 MVP? |

---

#### F-042: Grade Homework (Teacher)

| Field | Value |
|-------|-------|
| Feature ID | F-042 |
| Functional Area | Academics — Homework |
| Source Module(s) | LmsHomework |
| Module Status | PARTIAL ~52% |
| Existing Web Surface | partial — submission grading exists in HomeworkSubmissionController but with IDOR (SEC-HWK-003) |
| Source Tables | `lms_homework_submissions`, `lms_homework` |
| Description | List of submissions for an assignment. Per row: student, submitted_at, files. Tap → review (PDF/image viewer), grade (mark / status / feedback text). Bulk operations on web only. |
| Primary Users | Teacher |
| Secondary Users | n/a |
| Mobile Justification | §4.4 |
| Trigger / Entry Point | Homework tile on Teacher Dashboard |
| Key Screens | Assignment list → Submissions → Reviewer |
| Device Capabilities | Document/PDF viewer |
| Offline Behavior | Read-only cached |
| Backend Dependency | **MODIFY EXISTING** — fix SEC-HWK-003 first, then expose `GET/PATCH /api/mobile/v1/teacher/homework/{id}/submissions/{sid}`. |
| RBS Mapping | TBD |
| Notification Triggers | "Homework graded" → student + parent |
| Priority | P1 |
| Complexity | M |
| Security Risks Inherited | SEC-HWK-003 (IDOR). |
| Open Questions | Audio feedback (record voice note) — v1 or v1.1? |

---

#### F-043: Homework Monitoring (Parent)

| Field | Value |
|-------|-------|
| Feature ID | F-043 |
| Functional Area | Academics — Homework |
| Source Module(s) | ParentPortal (P7 PLANNED) |
| Module Status | PLANNED |
| Existing Web Surface | None |
| Source Tables | same as F-040 |
| Description | Read-only mirror of child's F-040 with parent-specific framing (e.g. "due today: 3"). Push when homework assigned and when graded. |
| Primary Users | Parent |
| Secondary Users | n/a |
| Mobile Justification | §4.1, §4.3 |
| Trigger / Entry Point | Parent dashboard tile |
| Key Screens | List → Detail |
| Device Capabilities | Push |
| Offline Behavior | Read-only cached |
| Backend Dependency | **NEW API + new ParentPortal controller** |
| RBS Mapping | TBD |
| Notification Triggers | "New homework assigned"; "Homework graded" |
| Priority | P0 |
| Complexity | S |
| Security Risks Inherited | ParentChildPolicy. |
| Open Questions | Allow parents to mark "submitted on paper" if school does paper submissions? (likely no — keep web-only.) |

---

### 2.5 Assessments — Quiz / Quest / Exam / Results

#### F-050: Quiz List + Take Quiz (Student)

| Field | Value |
|-------|-------|
| Feature ID | F-050 |
| Functional Area | Assessments |
| Source Module(s) | LmsQuiz, QuestionBank, StudentPortal Attempt subsystem |
| Module Status | LmsQuiz ~72% (most-mature LMS sub); StudentAttempt DDL ready (`student-parent-portal.md`) |
| Existing Web Surface | `/student-portal/quiz` — ❌ stub view per S14 |
| Source Tables | `lms_quizzes`, `lms_quiz_questions`, `lms_quiz_quest_attempts`, `lms_quiz_quest_attempt_answers`, `lms_quiz_quest_results`, `lms_attempt_checkpoints` |
| Description | List allocated quizzes (Pending / In Progress / Completed). Tap → start attempt. Server-side timer, shuffle if configured. Question types: MCQ, multi-select, descriptive, file. Save-and-resume supported via `lms_attempt_checkpoints`. Result instantly if `show_result_immediately=true`. |
| Primary Users | Student |
| Secondary Users | Parent (P9 — read-only) |
| Mobile Justification | §4.1, §4.3 (timed, time-bounded windows) |
| Trigger / Entry Point | Dashboard tile / Learning Hub |
| Key Screens | List → Instructions → Quiz Player → Result |
| Device Capabilities | None (mobile attempt vs anti-cheat — see §7 Q-8) |
| Offline Behavior | None — quizzes are timed and server-validated |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/student/quizzes`, `POST /v1/student/quizzes/{id}/start`, `POST /v1/student/quizzes/attempt/{aid}/answer`, `POST /v1/student/quizzes/attempt/{aid}/submit`. Reuses StudentPortal Attempt models. Pre-req: web stub completion (S14 currently ❌). |
| RBS Mapping | TBD |
| Notification Triggers | "Quiz available" / "Quiz closing in 1 hour" |
| Priority | P0 |
| Complexity | XL |
| Security Risks Inherited | SEC-STP-008 IDOR on attempt — mobile must never accept student-specified `attempt_id`; server-resolves from token. PERF: `loadExamQuestions` N+1. |
| Open Questions | Anti-cheat on mobile: kiosk mode (lock other apps) — Android achievable, iOS limited. Acceptable level? |

---

#### F-051: Quest Attempt (Student)

| Field | Value |
|-------|-------|
| Feature ID | F-051 |
| Functional Area | Assessments |
| Source Module(s) | LmsQuests |
| Module Status | PARTIAL ~52%; SEC-QZT-002 commented Gate. |
| Existing Web Surface | `/student-portal/quest` — ❌ stub per S15 |
| Source Tables | `lms_quests`, `lms_quest_questions`, `lms_quiz_quest_attempts` (polymorphic on assessment_type=QUEST), `lms_quest_badges` |
| Description | Quest = gamified longer-form assessment. Similar player to F-050 but with badges/levels. |
| Primary Users | Student |
| Secondary Users | Parent (P21 — badge monitor) |
| Mobile Justification | §4.1, §4.4 |
| Trigger / Entry Point | Learning Hub |
| Key Screens | Quest list → Detail → Player → Badge unlock animation |
| Device Capabilities | None |
| Offline Behavior | None |
| Backend Dependency | **NEW API** — endpoint family parallel to F-050. Pre-req: SEC-QZT-002 fix. |
| RBS Mapping | TBD |
| Notification Triggers | "New quest", "Badge earned" |
| Priority | P1 |
| Complexity | L |
| Security Risks Inherited | SEC-QZT-002. |
| Open Questions | Badge image storage (sys_media or static asset)? |

---

#### F-052: Exam Schedule View (Student / Parent)

| Field | Value |
|-------|-------|
| Feature ID | F-052 |
| Functional Area | Assessments |
| Source Module(s) | LmsExam |
| Module Status | PARTIAL ~55% |
| Existing Web Surface | `/student-portal/exam-schedule` ✅ S10; Parent P10 PLANNED |
| Source Tables | `lms_exams`, `lms_exam_papers`, `lms_exam_allocations`, `lms_exam_paper_sets`, `tt_academic_terms` |
| Description | Upcoming exams calendar + list. Per exam: subject, mode (Online/Offline/Hybrid/Practical), date, duration, venue, syllabus, paper structure. Add to phone calendar. |
| Primary Users | Student, Parent |
| Secondary Users | n/a |
| Mobile Justification | §4.1 |
| Trigger / Entry Point | Tile |
| Key Screens | List → Detail (with "Add to calendar" action) |
| Device Capabilities | Calendar |
| Offline Behavior | Read-only cached |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/student/exams?from=&to=` |
| RBS Mapping | TBD |
| Notification Triggers | "Exam tomorrow", "Exam venue change" |
| Priority | P0 |
| Complexity | S |
| Security Risks Inherited | None directly; PERF-LMS-002 on `index()` should be respected by aggregator. |
| Open Questions | None |

---

#### F-053: Online Exam Player (Student)

| Field | Value |
|-------|-------|
| Feature ID | F-053 |
| Functional Area | Assessments |
| Source Module(s) | LmsExam, StudentPortal (S13 ❌ stub) |
| Module Status | Partial — backend ready in StudentAttempt DDL, web client is a stub |
| Existing Web Surface | None |
| Source Tables | `lms_exam_attempts`, `lms_exam_attempt_answers`, `lms_exam_results`, `lms_attempt_activity_logs`, `lms_attempt_checkpoints` |
| Description | Same as Quiz Player but with: server-side timer per exam, fullscreen enforcement, tab-switch / app-switch detection (logged to `lms_attempt_activity_logs`), copy-paste disabled, auto-save every 60s, auto-submit on expiry, save-state for app crash/resume (per `student-parent-portal.md` D7). |
| Primary Users | Student |
| Secondary Users | n/a |
| Mobile Justification | Conditional — see §7 Q-8. Mobile-first option only if school accepts the lower anti-cheat ceiling. |
| Trigger / Entry Point | Exam Schedule tile (only when "Take Now" window is active) |
| Key Screens | Pre-flight checks → Instructions → Player → Submit |
| Device Capabilities | Fullscreen, Background-detection, Anti-screenshot (Android FLAG_SECURE), Camera (proctoring photo if configured) |
| Offline Behavior | None — disconnect during exam triggers warning + auto-submit on threshold |
| Backend Dependency | **NEW API** + heavy proctoring. Cross-cuts LmsExam + StudentPortal. |
| RBS Mapping | TBD |
| Notification Triggers | "Exam window opens in 15 min" |
| Priority | P1 (gated by §7 Q-8 decision) |
| Complexity | XL |
| Security Risks Inherited | SEC-STP-008 IDOR on attempt entry; SEC-EXM-005 IDOR on grievance review. Proctoring data privacy (camera frames). |
| Open Questions | Q-8: allow online exam on mobile or web-only? |

---

#### F-054: Results / Report Card (Student / Parent)

| Field | Value |
|-------|-------|
| Feature ID | F-054 |
| Functional Area | Assessments — Results |
| Source Module(s) | LmsExam, MarksheetGeneration (DDL_ONLY), Hpc |
| Module Status | LmsExam PARTIAL ~55%; MSG DDL_ONLY (D32); HPC FULL ~70% |
| Existing Web Surface | `/student-portal/results` 🟡 (no marks displayed); P12 PLANNED |
| Source Tables | `lms_exam_results`, `msh_student_results`, `msh_student_subject_results`, `msh_student_subject_exam_marks`, `hpc_reports`, `lms_exam_marks_entry` |
| Description | Per-exam results (online + offline + bulk). Grade summary, subject-wise breakdown, IA marks (when MSG ships). Download PDF report card (DomPDF). Trends chart. |
| Primary Users | Student, Parent |
| Secondary Users | n/a |
| Mobile Justification | §4.1 (event spike on result day), §4.4 |
| Trigger / Entry Point | Push on result publish; Tile on dashboard |
| Key Screens | List → Result Detail → PDF download |
| Device Capabilities | Document viewer (PDF), Storage |
| Offline Behavior | Read-only cached + downloaded PDFs |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/student/results`. **BLOCKED for full feature** until MarksheetGeneration ships (D32 — 5 sprints / ~9.5 weeks). v1 can show LmsExam results only. |
| RBS Mapping | TBD |
| Notification Triggers | "Result published — Term 2" |
| Priority | P0 (LmsExam results); P1 (consolidated marksheet via MSG) |
| Complexity | M |
| Security Risks Inherited | S11 currently shows "no marks displayed" (web bug). Backend-side fix is independent of mobile. |
| Open Questions | Marksheet via MSG vs simple LmsExam aggregation at v1? |

---

### 2.6 Fees & Payments

#### F-060: Fee Summary & Dues (Student / Parent)

| Field | Value |
|-------|-------|
| Feature ID | F-060 |
| Functional Area | Fees |
| Source Module(s) | StudentFee |
| Module Status | PARTIAL ~50%. **SR-AUTH-001 critical** (fee routes lack ownership checks). |
| Existing Web Surface | S6 (Student Fee Summary ✅), S4 Invoice View (🟡 IDOR), P14 PLANNED |
| Source Tables | `fin_fee_invoices`, `fin_fee_receipts`, `fin_fee_student_assignments`, `fin_fee_fine_transactions`, `fin_fee_concession_types` |
| Description | "Total due", "Total paid", "Next due date". Per-installment breakdown. Color-coded by status (Paid / Due / Overdue / Concession). Tap invoice → detail (heads, fines, concessions). |
| Primary Users | Student, Parent |
| Secondary Users | n/a |
| Mobile Justification | §4.1 |
| Trigger / Entry Point | Tile |
| Key Screens | Summary → Invoice list → Invoice detail |
| Device Capabilities | Document viewer (download invoice/receipt PDF) |
| Offline Behavior | Read-only cached |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/student/fees`. Pre-req: **fix SR-AUTH-001** (ownership checks on every fee endpoint) before exposing to mobile, otherwise the IDOR is more dangerous on mobile (deep-linkable). |
| RBS Mapping | TBD |
| Notification Triggers | "Fee due in 7 days", "Fee overdue" |
| Priority | P0 |
| Complexity | M |
| Security Risks Inherited | **SR-AUTH-001, SEC-STP-007** (proceedPayment IDOR). Mobile MUST add ownership policy. |
| Open Questions | Show concession application flow on mobile? (likely web-only at v1) |

---

#### F-061: Pay Fee via Razorpay (Parent)

| Field | Value |
|-------|-------|
| Feature ID | F-061 |
| Functional Area | Fees / Payments |
| Source Module(s) | StudentFee + Payment |
| Module Status | StudentFee 50%; Payment 45%. **BLOCKED — BUG-NEW-001 (PAY: 3 broken prefixes, no DDL); SEC-004 (webhook behind auth — payments fail today).** |
| Existing Web Surface | `/student-portal/pay-due-amount/pay-now/{id}` 🟡 partial IDOR fix; SEC-STP-007 unpatched |
| Source Tables | `pay_payments` (PLANNED canonical prefix), `pmt_payment_webhooks`, `pmt_payment_refunds`, `fin_fee_invoices`, `fin_fee_receipts`, `fin_fee_transactions` |
| Description | Parent (only `is_fee_payer=true` per `std_student_guardian_jnt`) selects an invoice or installment, sees breakup, hits Pay → opens Razorpay native checkout (Razorpay's Flutter / React Native SDK) → payment → server webhook → success/failure screen. Razorpay idempotent on `payment_reference UNIQUE` (per CAF/PPT pattern). |
| Primary Users | Parent (fee-payer only) |
| Secondary Users | n/a |
| Mobile Justification | §4.1, §4.3 |
| Trigger / Entry Point | "Pay" CTA on Invoice Detail (F-060) |
| Key Screens | Invoice → Pay confirm → Razorpay → Result → Receipt download |
| Device Capabilities | None (Razorpay handles UPI/cards/wallets) |
| Offline Behavior | None — must be online |
| Backend Dependency | **MULTIPLE BLOCKERS:** (1) Fix BUG-NEW-001 — standardize Pay module to `pay_*` and write DDL. (2) Fix SEC-004 — move Razorpay webhook OUTSIDE auth middleware (per tenancy-map.md). (3) Fix SEC-STP-007 — IDOR on proceedPayment. (4) **NEW API** — `POST /api/mobile/v1/parent/fees/{invoice_id}/pay` returning Razorpay order_id; webhook flow unchanged. |
| RBS Mapping | TBD |
| Notification Triggers | "Payment success — receipt #..." → fee-payer + active guardian. "Payment failed". |
| Priority | P0 (after blockers cleared) |
| Complexity | XL |
| Security Risks Inherited | SEC-PAY-001 (Razorpay test keys hardcoded — must be REVOKED + moved to env), SEC-004, SEC-STP-007, BUG-NEW-001. |
| Open Questions | UPI deep-link vs Razorpay checkout — recommend Razorpay native SDK for consistency with web. |

---

#### F-062: Receipt / Invoice Document Download

| Field | Value |
|-------|-------|
| Feature ID | F-062 |
| Functional Area | Fees / Documents |
| Source Module(s) | StudentFee |
| Module Status | PARTIAL — DomPDF receipt generation exists (D9) |
| Existing Web Surface | yes (web download links) |
| Source Tables | `fin_fee_receipts`, `fin_fee_invoices` |
| Description | Download PDF, share to WhatsApp/Drive, view inline. |
| Primary Users | Student, Parent |
| Secondary Users | n/a |
| Mobile Justification | §4.4 |
| Trigger / Entry Point | "Download" / "Share" on Invoice / Receipt detail |
| Key Screens | PDF viewer overlay |
| Device Capabilities | Document viewer, Share sheet, Storage |
| Offline Behavior | Full once downloaded |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/student/receipts/{id}.pdf` (signed URL, 24h TTL, per PPT pattern). |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P0 |
| Complexity | S |
| Security Risks Inherited | None direct; ensure signed URL not enumerable. |
| Open Questions | None |

---

### 2.7 Transport

#### F-070: Transport Route View (Student / Parent)

| Field | Value |
|-------|-------|
| Feature ID | F-070 |
| Functional Area | Transport |
| Source Module(s) | Transport |
| Module Status | PARTIAL ~40%. **Module web.php registers 0 tenant routes** (transport routes misrouted via tenant.*). |
| Existing Web Surface | `/student-portal/transport` ✅ (S24); P23 PLANNED |
| Source Tables | `tpt_routes`, `tpt_pickup_points`, `tpt_student_allocation_jnt`, `tpt_route_scheduler_jnt`, `tpt_vehicle`, `tpt_driver_helper` |
| Description | My/child's assigned route, pickup point, time, vehicle reg, driver/helper name & phone. Map view of route stops. Tap-to-call driver. |
| Primary Users | Student, Parent |
| Secondary Users | n/a |
| Mobile Justification | §4.1, §4.2 (map / GPS), §4.3 (delays) |
| Trigger / Entry Point | Tile |
| Key Screens | Route summary → Map → Driver contact |
| Device Capabilities | Map (Google Maps / OSM), Phone dialer |
| Offline Behavior | Full (assigned route cached) |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/student/transport`. Pre-req: fix transport route registration. |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P0 |
| Complexity | M |
| Security Risks Inherited | Aadhaar/PAN of drivers stored plaintext (IT Act violation). Mobile DTO must redact or omit. |
| Open Questions | Use Google Maps or OpenStreetMap (cost vs polish)? |

---

#### F-071: Live Trip Tracking (Parent)

| Field | Value |
|-------|-------|
| Feature ID | F-071 |
| Functional Area | Transport |
| Source Module(s) | Transport (`tpt_live_trips`, `tpt_gps_trip_log`, `tpt_gps_alerts`) |
| Module Status | PARTIAL — tables exist but no live tracking endpoint surfaces |
| Existing Web Surface | None |
| Source Tables | `tpt_live_trips`, `tpt_trips`, `tpt_gps_trip_log`, `tpt_student_boarding_logs` |
| Description | Real-time vehicle location on map, ETA to my child's stop, "boarded/de-boarded" event when boarding QR is scanned at pickup. Push when bus is 5 min away. |
| Primary Users | Parent |
| Secondary Users | n/a |
| Mobile Justification | §4.2 (GPS, Map), §4.3 (real-time) |
| Trigger / Entry Point | "Track Bus" CTA on Transport tile |
| Key Screens | Live Map |
| Device Capabilities | Map, Push |
| Offline Behavior | None (live data) |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/parent/student/{id}/transport/live` (WebSocket or long-poll). Pre-req: F-072 (driver-side GPS pings). |
| RBS Mapping | TBD |
| Notification Triggers | "Bus 5 min away", "Child boarded", "Child de-boarded" |
| Priority | P0 (subject to F-072) |
| Complexity | XL |
| Security Risks Inherited | None direct — but exposing live GPS of a bus to all parents on the route raises privacy concerns. Limit polygon to "near my stop". |
| Open Questions | Streaming via WebSocket vs polling every 30s? Prefer polling for simplicity at v1. |

---

#### F-072: Driver Route Execution & Boarding QR (Transport Staff)

| Field | Value |
|-------|-------|
| Feature ID | F-072 |
| Functional Area | Transport |
| Source Module(s) | Transport |
| Module Status | PARTIAL — tables exist for boarding logs and trip incidents |
| Existing Web Surface | None |
| Source Tables | `tpt_live_trips`, `tpt_student_boarding_logs`, `tpt_gps_trip_log`, `tpt_trip_incidents`, `tpt_attendance_devices` |
| Description | Driver/Conductor logs into the app, sees today's route + roster, presses "Start Trip" → app starts streaming GPS pings every 30s + pushes to backend. At each stop, scans student's boarding QR (from F-130 student ID) → records boarding/de-boarding. End-of-trip summary. |
| Primary Users | Transport Staff (Driver, Conductor) |
| Secondary Users | n/a |
| Mobile Justification | §4.2 (GPS, camera/QR), §4.3 (real-time), §4.4 |
| Trigger / Entry Point | Default home for Transport role |
| Key Screens | Today's route → Stop list → QR scanner → Trip summary |
| Device Capabilities | GPS (foreground service), Camera (QR scan), Phone |
| Offline Behavior | Queued — boarding events queued + GPS pings batched if signal lost |
| Backend Dependency | **NEW API** — `POST /api/mobile/v1/driver/trip/start`, `POST /v1/driver/trip/{id}/gps`, `POST /v1/driver/trip/{id}/board`. **Pre-req:** fix transport routing 0 endpoints issue. |
| RBS Mapping | TBD |
| Notification Triggers | "Trip started", "Stop missed" alert |
| Priority | P0 |
| Complexity | XL |
| Security Risks Inherited | Plaintext driver Aadhaar/PAN on backend (not exposed in mobile DTO). |
| Open Questions | Battery cost of foreground GPS — accept for v1? |

---

#### F-073: Trip Incident Reporting (Transport Staff)

| Field | Value |
|-------|-------|
| Feature ID | F-073 |
| Functional Area | Transport |
| Source Module(s) | Transport |
| Module Status | PARTIAL — `tpt_trip_incidents` exists |
| Existing Web Surface | None |
| Source Tables | `tpt_trip_incidents`, `sys_media` |
| Description | During a trip, driver reports an incident: breakdown / accident / passenger illness / traffic / late. Photo + GPS captured. Pushes to dispatcher + parent (if affecting trip ETA). |
| Primary Users | Transport Staff |
| Secondary Users | Dispatcher (web), Parent (push only) |
| Mobile Justification | §4.2 (camera, GPS), §4.3 |
| Trigger / Entry Point | Floating button during trip |
| Key Screens | Type → Photo → Notes → Submit |
| Device Capabilities | Camera, GPS |
| Offline Behavior | Queued |
| Backend Dependency | **NEW API** — `POST /api/mobile/v1/driver/trip/{id}/incident` |
| RBS Mapping | TBD |
| Notification Triggers | Incident → dispatcher + affected parents |
| Priority | P0 |
| Complexity | M |
| Security Risks Inherited | None |
| Open Questions | Audio note capture? (v1.1) |

---

### 2.8 Communication & Notifications

#### F-080: Notification Inbox

| Field | Value |
|-------|-------|
| Feature ID | F-080 |
| Functional Area | Communication |
| Source Module(s) | Notification |
| Module Status | PARTIAL ~35% — **BLOCKED: routes commented out (BUG-NEW-002), Gate prefix `prime.*` mismatch.** |
| Existing Web Surface | `/student-portal/all-notifications` ✅ S32; "Notice Board" S27 🟡 (reads notifications instead of sch_notices) |
| Source Tables | `ntf_notifications`, `ntf_notification_recipients`, `ntf_notification_templates`, `ntf_user_preferences`, `ntf_notification_threads`, `ntf_device_tokens` |
| Description | List inbound notifications (push + in-app). Categories: Academic / Fee / Transport / Notice / Personal. Mark as read, swipe to archive. Tap → deep-link to source feature. |
| Primary Users | All roles |
| Secondary Users | n/a |
| Mobile Justification | §4.1, §4.3 |
| Trigger / Entry Point | Bell icon / bottom-tab |
| Key Screens | Inbox → Detail |
| Device Capabilities | Push |
| Offline Behavior | Read-only cached |
| Backend Dependency | **MAJOR BLOCKER + NEW API** — Re-activate routes (BUG-NEW-002), fix Gate prefix to `tenant.*`. Add `GET /api/mobile/v1/notifications`, `PATCH /v1/notifications/{id}/read`. Add `POST /v1/devices` for FCM/APNs token registration → writes to `ntf_device_tokens`. Existing event flow `SystemNotificationTriggered → ProcessSystemNotification → channel dispatch` is sufficient — register a new `MOBILE_PUSH` channel in `ntf_notification_channels`. |
| RBS Mapping | TBD |
| Notification Triggers | n/a (consumes) |
| Priority | P0 |
| Complexity | L |
| Security Risks Inherited | SR-AUTH-003 (mark-read AJAX endpoint unauthenticated); SR-AUTH-004 (testNotification has hardcoded user_id). Both must be fixed. |
| Open Questions | Threaded notifications (`ntf_notification_threads` exists) — surface threads at v1 or flat list? Recommend flat for v1. |

---

#### F-081: Push Notification Preferences

| Field | Value |
|-------|-------|
| Feature ID | F-081 |
| Functional Area | Communication |
| Source Module(s) | Notification |
| Module Status | PARTIAL — `ntf_user_preferences` exists |
| Existing Web Surface | None visible |
| Source Tables | `ntf_user_preferences` |
| Description | Per-category opt-in/out (Academic, Fee, Transport, Personal). Quiet hours setting (e.g. 22:00–07:00). Test push button. |
| Primary Users | All roles |
| Secondary Users | n/a |
| Mobile Justification | §4.1 (settings) |
| Trigger / Entry Point | Settings → Notifications |
| Key Screens | Preferences |
| Device Capabilities | None |
| Offline Behavior | Read-only |
| Backend Dependency | **NEW API** — `GET/PUT /api/mobile/v1/me/notification-preferences` |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P0 |
| Complexity | S |
| Security Risks Inherited | None |
| Open Questions | None |

---

#### F-082: Parent-Teacher 1:1 Messaging (Communication)

| Field | Value |
|-------|-------|
| Feature ID | F-082 |
| Functional Area | Communication |
| Source Module(s) | Communication (PLANNED — `com_*` 14 tables, DLT-compliant SMS, 7-state delivery FSM); ParentPortal P16 (PLANNED — `msg_threads`, `msg_messages`, `msg_attachments`) |
| Module Status | PLANNED |
| Existing Web Surface | None |
| Source Tables | `msg_threads`, `msg_messages`, `msg_attachments` (NEW per portal doc) |
| Description | 1:1 thread between Parent and Teacher (subject + class context). Text + attachments. Read receipts. School-monitored (admin can audit threads). |
| Primary Users | Parent, Teacher |
| Secondary Users | Class Teacher (broadcast-style messages) |
| Mobile Justification | §4.1, §4.3 |
| Trigger / Entry Point | "Messages" tab; deep-link from teacher list |
| Key Screens | Thread list → Thread → Composer |
| Device Capabilities | Push, Camera (attach photo), Document picker |
| Offline Behavior | Read cached + queued sends |
| Backend Dependency | **BLOCKED on Communication module** (PLANNED). |
| RBS Mapping | TBD |
| Notification Triggers | "New message from..." |
| Priority | P1 |
| Complexity | XL |
| Security Risks Inherited | None direct; ensure school admin audit access. |
| Open Questions | Voice notes — v1.1. |

---

#### F-083: Notice Board (School-wide notices)

| Field | Value |
|-------|-------|
| Feature ID | F-083 |
| Functional Area | Communication |
| Source Module(s) | SchoolSetup (`sch_notices` planned) — currently consumed via Notification per S27 🟡 bug |
| Module Status | PARTIAL — S27 reads notifications instead of `sch_notices` |
| Existing Web Surface | S27 🟡 |
| Source Tables | `sch_notices` (planned), or fallback `ntf_notifications` filtered |
| Description | School-wide announcements, sorted by date. Pinned notices at top. Categories. Read receipt count visible to admins (web). |
| Primary Users | All roles |
| Secondary Users | n/a |
| Mobile Justification | §4.1 |
| Trigger / Entry Point | Tab |
| Key Screens | Notice list → Detail |
| Device Capabilities | None |
| Offline Behavior | Read-only cached |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/notices`. Backend gap: create `sch_notices` table + controller. |
| RBS Mapping | TBD |
| Notification Triggers | "New notice" push |
| Priority | P0 |
| Complexity | M |
| Security Risks Inherited | None |
| Open Questions | Use Notification module or new SchoolSetup notices? Recommend new — distinct lifecycle and audience. |

---

#### F-084: Circulars (Acknowledgement-required)

| Field | Value |
|-------|-------|
| Feature ID | F-084 |
| Functional Area | Communication |
| Source Module(s) | FrontOffice (PLANNED — `fof_*` 22 tables) |
| Module Status | PLANNED |
| Existing Web Surface | None |
| Source Tables | `fof_circulars` (planned) |
| Description | School circulars requiring parent acknowledgement signature (digital). Track who has acknowledged. |
| Primary Users | Parent |
| Secondary Users | n/a |
| Mobile Justification | §4.1, §4.3 |
| Trigger / Entry Point | Push + tab |
| Key Screens | List → Detail → Acknowledge |
| Device Capabilities | None |
| Offline Behavior | Read cached + queued ack |
| Backend Dependency | **BLOCKED on FrontOffice module** (PLANNED). |
| RBS Mapping | TBD |
| Notification Triggers | "Acknowledge by date" |
| Priority | P1 |
| Complexity | M |
| Security Risks Inherited | None |
| Open Questions | None |

---

### 2.9 HPC / Progress Card

#### F-090: View HPC Report (Student / Parent)

| Field | Value |
|-------|-------|
| Feature ID | F-090 |
| Functional Area | HPC |
| Source Module(s) | Hpc |
| Module Status | FULL ~70%. **SEC-HPC-001 critical** (13/15 controllers no auth). |
| Existing Web Surface | `/student-portal/progress-card` ✅ S19 (no PDF download); P13 70% (token works) |
| Source Tables | `hpc_reports`, `hpc_student_evaluations`, `hpc_student_snapshots`, `hpc_parent_form_tokens`, `hpc_learning_activities`, `hpc_circular_goals` |
| Description | View latest HPC report. Tabs by parameter (academic, scholastic, co-scholastic, etc.). Download PDF (4 templates by grade — D13). Share. |
| Primary Users | Student, Parent |
| Secondary Users | n/a |
| Mobile Justification | §4.1, §4.4 (PDF viewing) |
| Trigger / Entry Point | Tile |
| Key Screens | Report → Tab views → PDF |
| Device Capabilities | Document viewer, Storage, Share |
| Offline Behavior | Full once downloaded |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/student/hpc/{id}` (data) + `GET /v1/student/hpc/{id}.pdf` (signed). Pre-req: fix SEC-HPC-001. |
| RBS Mapping | TBD |
| Notification Triggers | "HPC published" |
| Priority | P0 |
| Complexity | M |
| Security Risks Inherited | SEC-HPC-001, BUG-001 missing model imports (fatal Gate). |
| Open Questions | Render data natively or just PDF? Recommend native data + optional PDF download. |

---

#### F-091: Parent Form Token Submission (HPC)

| Field | Value |
|-------|-------|
| Feature ID | F-091 |
| Functional Area | HPC |
| Source Module(s) | Hpc |
| Module Status | FULL — token mechanism works |
| Existing Web Surface | yes (token URL) |
| Source Tables | `hpc_parent_form_tokens` |
| Description | Parent receives a token link (email/SMS/push) to fill the parent-feedback form for their child's HPC. Token is single-use, time-bound. Mobile opens via deep-link, fills form, submits. |
| Primary Users | Parent |
| Secondary Users | n/a |
| Mobile Justification | §4.1 |
| Trigger / Entry Point | Push deep-link / email link |
| Key Screens | Form → Submit → Confirmation |
| Device Capabilities | None |
| Offline Behavior | None (token validation server-side) |
| Backend Dependency | **MODIFY EXISTING** — adapt token URL handler to render JSON for mobile clients. |
| RBS Mapping | TBD |
| Notification Triggers | "Please fill HPC parent form" |
| Priority | P1 |
| Complexity | M |
| Security Risks Inherited | None |
| Open Questions | None |

---

### 2.10 Approvals & Leave

#### F-100: Apply for Student Leave

| Field | Value |
|-------|-------|
| Feature ID | F-100 |
| Functional Area | Leave |
| Source Module(s) | StudentProfile (Leave subsystem currently dead code) — supersession by planned `Attendance` module |
| Module Status | DEAD CODE — 4 Leave* models exist but ZERO routes (per `progress.md` 2026-04-09) |
| Existing Web Surface | `/student-portal/apply-leave` ❌ stub (S30) |
| Source Tables | `std_leave_applications` (currently dead), or planned `att_leave_*` |
| Description | Student/Parent submits leave: type, from, to, reason, doctor's note (file). Status track (Submitted / Reviewed / Approved / Rejected). |
| Primary Users | Parent (on behalf of child), Student |
| Secondary Users | n/a |
| Mobile Justification | §4.1, §4.4 |
| Trigger / Entry Point | Tile / Settings |
| Key Screens | Compose → Submit → Status |
| Device Capabilities | Camera, File picker |
| Offline Behavior | Queued |
| Backend Dependency | **BLOCKED — leave subsystem must be implemented** (no controller, no routes). Mobile cannot ship until backend lives. |
| RBS Mapping | TBD |
| Notification Triggers | "Leave approved/rejected" |
| Priority | P1 |
| Complexity | M |
| Security Risks Inherited | SEC-STD-005 (no tenant scoping on LeaveApplication when implemented). VAL-STD-002 (half-day overlap fraud vector). |
| Open Questions | Wait for `Attendance` module (`att_leave_*`) vs activate dead `std_leave_*`? Recommend the planned `att_*` per modules-map.md. |

---

#### F-101: Approve Student Leave (Teacher / Class Teacher)

| Field | Value |
|-------|-------|
| Feature ID | F-101 |
| Functional Area | Leave |
| Source Module(s) | same as F-100 |
| Module Status | DEAD CODE |
| Existing Web Surface | None |
| Source Tables | same |
| Description | Class Teacher receives leave applications for their students; approves or rejects with remark. |
| Primary Users | Class Teacher, Principal |
| Secondary Users | n/a |
| Mobile Justification | §4.1, §4.4 |
| Trigger / Entry Point | Approval queue tile |
| Key Screens | Queue → Detail → Approve / Reject |
| Device Capabilities | Push |
| Offline Behavior | Read-only cached |
| Backend Dependency | **BLOCKED — same as F-100** |
| RBS Mapping | TBD |
| Notification Triggers | "Pending leave to approve" |
| Priority | P1 |
| Complexity | S |
| Security Risks Inherited | same as F-100 |
| Open Questions | None |

---

#### F-102: Apply for Employee Leave (Teacher / Staff)

| Field | Value |
|-------|-------|
| Feature ID | F-102 |
| Functional Area | Leave |
| Source Module(s) | SchoolSetup Employee Leave Management (D26, D33 — DDL v4 ready, code pending) |
| Module Status | DDL_ONLY — 8 tables in v2, expanded to v4 |
| Existing Web Surface | None |
| Source Tables | `sch_employee_leave_applications`, `sch_employee_leave_approvals`, `sch_employee_leave_application_docs`, `sch_employee_leave_application_remarks`, `sch_employee_leave_balance`, `sch_leave_approval_policies`, `sch_leave_approval_policy_levels`, `sch_leave_approval_level_approvers` |
| Description | Employee submits leave with type, from, to, reason, half-day, supporting doc. Multi-level approval flow per `sch_leave_approval_policies`. Live balance shown. |
| Primary Users | Teacher, Staff |
| Secondary Users | n/a |
| Mobile Justification | §4.1, §4.4 |
| Trigger / Entry Point | Tile on Teacher dashboard / Settings |
| Key Screens | Compose → Submit → Status (with multi-level audit trail) |
| Device Capabilities | Camera, File picker |
| Offline Behavior | Queued |
| Backend Dependency | **BLOCKED — code unimplemented** (D26/D33 are DDL-only). |
| RBS Mapping | TBD |
| Notification Triggers | "Leave Submitted", per-level approval moves |
| Priority | P1 |
| Complexity | L |
| Security Risks Inherited | None |
| Open Questions | None |

---

#### F-103: Approve Employee Leave (Multi-level)

| Field | Value |
|-------|-------|
| Feature ID | F-103 |
| Functional Area | Leave |
| Source Module(s) | same as F-102 |
| Module Status | DDL_ONLY |
| Existing Web Surface | None |
| Source Tables | same |
| Description | Pending-approvals queue (level-aware). Approve / Reject / Request Info / Request Document. Threaded comments per remarks model. |
| Primary Users | Approver (varies by `approver_type`: USER/ROLE/DESIGNATION/DEPARTMENT_HEAD/REPORTING_TO) |
| Secondary Users | n/a |
| Mobile Justification | §4.1, §4.4 |
| Trigger / Entry Point | Approvals tile (Teacher dashboard / Principal dashboard) |
| Key Screens | Queue → Detail → Action |
| Device Capabilities | Push |
| Offline Behavior | Read-only |
| Backend Dependency | **BLOCKED** |
| RBS Mapping | TBD |
| Notification Triggers | "Pending approval", "Escalation" |
| Priority | P1 |
| Complexity | L |
| Security Risks Inherited | None |
| Open Questions | None |

---

### 2.11 Library

#### F-110: Library Catalog Browse

| Field | Value |
|-------|-------|
| Feature ID | F-110 |
| Functional Area | Library |
| Source Module(s) | Library |
| Module Status | FULL (cited as in tenant.php — was earlier reported wrong) |
| Existing Web Surface | `/student-portal/library` ✅ S22 |
| Source Tables | `lib_books`, `lib_book_copies`, `lib_categories`, `lib_genres`, `lib_digital_resources` |
| Description | Browse catalog by category/genre/author. Search by title/ISBN. View book detail (availability, location). Reserve a copy. |
| Primary Users | Student |
| Secondary Users | Parent (read-only) |
| Mobile Justification | §4.1, §4.4 |
| Trigger / Entry Point | Tile |
| Key Screens | Search → List → Detail → Reserve |
| Device Capabilities | None |
| Offline Behavior | Read-only cached (popular subset) |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/library/books?search=&category=`. |
| RBS Mapping | TBD |
| Notification Triggers | "Reservation available" |
| Priority | P1 |
| Complexity | M |
| Security Risks Inherited | LIB has 22 controllers cross-importing `Modules\Vendor\Models\Vendor` — clean up before exposing. |
| Open Questions | None |

---

#### F-111: My Books / Borrow History

| Field | Value |
|-------|-------|
| Feature ID | F-111 |
| Functional Area | Library |
| Source Module(s) | Library |
| Module Status | FULL |
| Existing Web Surface | `/student-portal/library/my-books` ✅ S23 |
| Source Tables | `lib_transactions`, `lib_fines`, `lib_reservations`, `lib_members` |
| Description | Currently borrowed books with return date. Overdue fines. Borrow history. |
| Primary Users | Student |
| Secondary Users | n/a |
| Mobile Justification | §4.1 |
| Trigger / Entry Point | Tile |
| Key Screens | Active borrows → Detail; History |
| Device Capabilities | None |
| Offline Behavior | Read-only cached |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/library/me`. |
| RBS Mapping | TBD |
| Notification Triggers | "Book due in 2 days", "Fine accrued" |
| Priority | P1 |
| Complexity | S |
| Security Risks Inherited | None |
| Open Questions | None |

---

### 2.12 Hostel (PLANNED module — v1.2 features)

#### F-120: Hostel Pass / Leave Request (Boarder)

| Field | Value |
|-------|-------|
| Feature ID | F-120 |
| Functional Area | Hostel |
| Source Module(s) | Hostel (PLANNED — DDL v3 ready, D34) |
| Module Status | DDL_ONLY (36 tables) |
| Existing Web Surface | None |
| Source Tables | `hst_leave_passes`, `hst_movement_log`, `hst_emergency_contacts`, `hst_visitor_log` |
| Description | Boarder requests a leave pass (overnight / weekend / emergency). Guardian consent flow. Warden approval. QR-based gate exit. |
| Primary Users | Student (boarder), Parent |
| Secondary Users | Warden |
| Mobile Justification | §4.1, §4.3 |
| Trigger / Entry Point | Tile (only for boarders — feature-flagged) |
| Key Screens | Compose → Consent → Status → Gate QR |
| Device Capabilities | Camera (consent media), QR display |
| Offline Behavior | Read cached + queued submit |
| Backend Dependency | **BLOCKED on Hostel module** (DDL ready, code pending). |
| RBS Mapping | TBD |
| Notification Triggers | Status updates |
| Priority | P2 |
| Complexity | L |
| Security Risks Inherited | None |
| Open Questions | None |

---

#### F-121: Hostel Notifications (Mess opt-out, Sick-bay alerts)

| Field | Value |
|-------|-------|
| Feature ID | F-121 |
| Functional Area | Hostel |
| Source Module(s) | Hostel (PLANNED) |
| Module Status | DDL_ONLY |
| Existing Web Surface | None |
| Source Tables | `hst_mess_opt_outs`, `hst_sick_bay_log`, `hst_notification_log` |
| Description | Boarder opts out of meals. Parent receives sick-bay alerts when child is admitted. |
| Primary Users | Student (boarder), Parent |
| Secondary Users | Warden |
| Mobile Justification | §4.1, §4.3 |
| Trigger / Entry Point | Tile / push |
| Key Screens | Mess opt-out form; Sick-bay alert detail |
| Device Capabilities | Push |
| Offline Behavior | Read cached |
| Backend Dependency | **BLOCKED on Hostel module** |
| RBS Mapping | TBD |
| Notification Triggers | "Child in sick-bay", "Mess opt-out reminder" |
| Priority | P2 |
| Complexity | M |
| Security Risks Inherited | None |
| Open Questions | None |

---

### 2.13 Profile, Health, ID, Settings

#### F-130: My Profile / Student ID Card

| Field | Value |
|-------|-------|
| Feature ID | F-130 |
| Functional Area | Profile |
| Source Module(s) | StudentProfile, SchoolSetup |
| Module Status | FULL |
| Existing Web Surface | `/student-portal/academic-information` 🟡 (S3); `/student-portal/student-id-card` ✅ S29 (no PDF) |
| Source Tables | `std_students`, `std_student_profiles`, `std_student_addresses`, `sys_users`, `std_student_documents` |
| Description | Read-only profile (name, DOB, blood group, class, section, photo). Generate ID Card with QR (used by F-072 driver scan). Download PDF. |
| Primary Users | Student, Parent (P4 child academic) |
| Secondary Users | n/a |
| Mobile Justification | §4.1, §4.4 |
| Trigger / Entry Point | Tile / drawer |
| Key Screens | Profile → ID Card |
| Device Capabilities | Document viewer, QR display |
| Offline Behavior | Full |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/me` (role-aware response) + `GET /v1/me/id-card.pdf` |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P0 |
| Complexity | S |
| Security Risks Inherited | None |
| Open Questions | None |

---

#### F-131: Health Records (Student)

| Field | Value |
|-------|-------|
| Feature ID | F-131 |
| Functional Area | Profile / Health |
| Source Module(s) | StudentProfile |
| Module Status | FULL ✅ S18 |
| Existing Web Surface | `/student-portal/health-records` |
| Source Tables | `std_student_health_profiles`, `std_vaccination_records`, `std_medical_incidents`, planned `std_medical_details` |
| Description | Health profile, vaccinations, medical incidents log, allergies. Read-only on mobile. |
| Primary Users | Student |
| Secondary Users | Parent |
| Mobile Justification | §4.1 |
| Trigger / Entry Point | Tile |
| Key Screens | Health summary |
| Device Capabilities | None |
| Offline Behavior | Read-only cached |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/student/health` |
| RBS Mapping | TBD |
| Notification Triggers | "Vaccination due" reminder |
| Priority | P1 |
| Complexity | S |
| Security Risks Inherited | None |
| Open Questions | None |

---

#### F-132: My Teachers Directory (Student)

| Field | Value |
|-------|-------|
| Feature ID | F-132 |
| Functional Area | Profile / Directory |
| Source Module(s) | SchoolSetup, SmartTimetable |
| Module Status | FULL ✅ S17 |
| Existing Web Surface | `/student-portal/my-teachers` |
| Source Tables | `sch_teachers`, `sch_subject_teachers`, `tt_timetable_cell_teachers` |
| Description | List of subject teachers + class teacher. Tap → contact (if school-permitted), schedule, subjects taught. |
| Primary Users | Student, Parent |
| Secondary Users | n/a |
| Mobile Justification | §4.1 |
| Trigger / Entry Point | Tile |
| Key Screens | List → Detail |
| Device Capabilities | Phone dialer (if permitted) |
| Offline Behavior | Read-only cached |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/student/teachers` |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P1 |
| Complexity | S |
| Security Risks Inherited | None |
| Open Questions | Phone contact gating policy? |

---

#### F-133: Settings & Language

| Field | Value |
|-------|-------|
| Feature ID | F-133 |
| Functional Area | Settings |
| Source Module(s) | n/a (mostly client) + GlobalMaster `glb_languages` |
| Module Status | FULL (`glb_languages`) |
| Existing Web Surface | None equivalent |
| Source Tables | `glb_languages`, `sys_users.locale` (per stancl/tenancy locale field) |
| Description | Toggle between Hindi / English (and additional regional languages per §7 Q-6). Theme (light/dark/auto). Account settings (change password, change email, logout). |
| Primary Users | All |
| Secondary Users | n/a |
| Mobile Justification | §4.1 |
| Trigger / Entry Point | Drawer → Settings |
| Key Screens | Settings → sub-pages |
| Device Capabilities | None |
| Offline Behavior | Full |
| Backend Dependency | **NEW API** — `PATCH /api/mobile/v1/me/locale`, `POST /v1/me/password` |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P0 |
| Complexity | S |
| Security Risks Inherited | None |
| Open Questions | Localization scope (§7 Q-6) |

---

#### F-134: Help & Support

| Field | Value |
|-------|-------|
| Feature ID | F-134 |
| Functional Area | Support |
| Source Module(s) | Documentation |
| Module Status | PARTIAL ~60% |
| Existing Web Surface | `Modules/Documentation/` |
| Source Tables | `doc_articles`, `doc_categories`, `doc_article_media` |
| Description | FAQ, help articles, "Contact school admin" button (opens email or phone). |
| Primary Users | All |
| Secondary Users | n/a |
| Mobile Justification | §4.1 |
| Trigger / Entry Point | Drawer → Help |
| Key Screens | Categories → Article |
| Device Capabilities | Email, Phone |
| Offline Behavior | Read-only cached |
| Backend Dependency | **NEW API** — `GET /api/mobile/v1/help/articles` |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P0 |
| Complexity | S |
| Security Risks Inherited | DOC-XSS-001 (`{!! content !!}`) — server-side fix; mobile uses `Markdown` strict parser. |
| Open Questions | None |

---

#### F-135: About / Version / Forced Update

| Field | Value |
|-------|-------|
| Feature ID | F-135 |
| Functional Area | App Lifecycle |
| Source Module(s) | new `MobileApi` (cross-cutting) |
| Module Status | NEW |
| Existing Web Surface | None |
| Source Tables | new — `mobile_app_versions` (tenant-agnostic, prime_db) |
| Description | "About" screen with version, build, support email. On launch, app calls `/api/mobile/v1/version` — returns minimum supported version. If client < minimum, force update (block UI). If client < latest, soft-recommend update. |
| Primary Users | All |
| Secondary Users | n/a |
| Mobile Justification | §4.1 |
| Trigger / Entry Point | Drawer → About; cold start |
| Key Screens | About; Forced Update overlay |
| Device Capabilities | App store deep-link |
| Offline Behavior | Cached version data; forced-update only enforced once online |
| Backend Dependency | **NEW** — central endpoint `GET /api/mobile/v1/version` (does NOT need tenant context) |
| RBS Mapping | TBD |
| Notification Triggers | "New version available" |
| Priority | P0 |
| Complexity | S |
| Security Risks Inherited | None |
| Open Questions | None |

---

### 2.14 Search

#### F-140: App-wide Search

| Field | Value |
|-------|-------|
| Feature ID | F-140 |
| Functional Area | Search |
| Source Module(s) | All |
| Module Status | NEW backend (Meilisearch already in tech stack per project-context.md) |
| Existing Web Surface | None |
| Source Tables | aggregated index over teachers / classes / books / lessons / notices |
| Description | Single search bar across teachers, lessons, books, notices, fees. Powered by Meilisearch. |
| Primary Users | All |
| Secondary Users | n/a |
| Mobile Justification | §4.1 (frequent quick lookups) |
| Trigger / Entry Point | Search icon top-right |
| Key Screens | Search results grouped by entity |
| Device Capabilities | None |
| Offline Behavior | None (live index) |
| Backend Dependency | **NEW API + new indexer** — `GET /api/mobile/v1/search?q=`. Backend gap: indexer + Meilisearch tenant config (Meilisearch already in stack but no indexes built yet). |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P1 |
| Complexity | L |
| Security Risks Inherited | Per-tenant index isolation must be enforced. |
| Open Questions | None |

---

## Section 3 — Cross-Cutting Capabilities

> Same table format as §2 for consistency. Reduced for already-covered cases.

#### CC-01: Multi-tenant Login (covered by F-001 + F-002)
*See feature pair above.*

#### CC-02: Biometric Unlock — F-004

#### CC-03: Push Notification Preferences — F-081

#### CC-04: In-App Messaging — F-082

#### CC-05: Document / PDF Viewer

| Field | Value |
|-------|-------|
| Feature ID | CC-05 |
| Functional Area | Document |
| Source Module(s) | StudentFee, Hpc, Certificate, FrontOffice — anywhere DomPDF is used |
| Module Status | FULL (DomPDF per D9) |
| Existing Web Surface | per-feature download |
| Source Tables | `sys_media`, signed URL temp tokens |
| Description | Universal in-app PDF/image viewer with zoom, share, save-to-device. Supports HPC reports (4 templates), invoices, receipts, ID cards, certificates, marksheet, transport route maps. |
| Primary Users | All |
| Secondary Users | n/a |
| Mobile Justification | §4.4 |
| Trigger / Entry Point | "View PDF" / "Open" actions |
| Key Screens | Viewer overlay |
| Device Capabilities | Document viewer, Share, Storage |
| Offline Behavior | Full once downloaded |
| Backend Dependency | Each module's existing PDF endpoint must surface a mobile-friendly signed URL. |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P0 |
| Complexity | S |
| Security Risks Inherited | None |
| Open Questions | None |

#### CC-06: Profile & Language Switcher — F-133

#### CC-07: App-wide Search — F-140

#### CC-08: Help & Support — F-134

#### CC-09: About / Version / Forced Update — F-135

#### CC-10: Tenant Branding (logo, color, app name)

| Field | Value |
|-------|-------|
| Feature ID | CC-10 |
| Functional Area | Branding |
| Source Module(s) | Prime |
| Module Status | partial |
| Existing Web Surface | per-tenant logo upload |
| Source Tables | `prm_tenant`, tenant settings |
| Description | App reads branding from tenant resolve response (F-001) — logo, primary color, school name appear in header / splash. Sourced at runtime; not built per tenant. |
| Primary Users | All |
| Secondary Users | n/a |
| Mobile Justification | §4.1 (every screen) |
| Trigger / Entry Point | Implicit |
| Key Screens | All |
| Device Capabilities | None |
| Offline Behavior | Cached; refresh on next tenant resolve |
| Backend Dependency | F-001 endpoint extension |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P0 |
| Complexity | S |
| Security Risks Inherited | None |
| Open Questions | §7 Q-5 — full white-label vs Prime-AI master shell? |

#### CC-11: Analytics & Crash Reporting

| Field | Value |
|-------|-------|
| Feature ID | CC-11 |
| Functional Area | Observability |
| Source Module(s) | n/a (client) |
| Module Status | NEW |
| Existing Web Surface | None |
| Source Tables | None |
| Description | Mobile-side telemetry: screen views, key event funnels (login, payment, attempt-submit), crash reports. Server-side counterpart goes to existing Telescope (already enabled per architecture.md). |
| Primary Users | n/a (Anthropic / Prime-AI dev team) |
| Secondary Users | n/a |
| Mobile Justification | §4.1 (operational) |
| Trigger / Entry Point | Implicit per screen / event |
| Key Screens | None |
| Device Capabilities | None (third-party SDK — Sentry, Firebase Crashlytics) |
| Offline Behavior | Buffered + flushed on connectivity |
| Backend Dependency | None (third-party) |
| RBS Mapping | TBD |
| Notification Triggers | None |
| Priority | P0 |
| Complexity | S |
| Security Risks Inherited | None — but PII redaction in crash reports must be enforced (no Aadhaar, password, token). |
| Open Questions | Sentry vs Crashlytics vs both? |

---

## Section 4 — Explicitly Excluded from Mobile

| Feature | Reason |
|---------|--------|
| Tenant onboarding / SaaS admin | Central admin only; mobile is for school users |
| Plan / billing administration (`Modules/Prime`, `Modules/Billing`) | SaaS admin only |
| Geo / Country / State / Board / Language master CRUD | Configuration; web-only |
| SmartTimetable generation, FET solver, constraint configuration | Heavy desktop-class flow with maps + dragging |
| TimetableFoundation period-set / day-type configuration | Setup-time, not mobile |
| Bulk fee structure setup, fee head master CRUD | Configuration; web-only |
| Bulk student import / bulk parent creation | Excel-driven |
| Payroll run, pay heads, salary structures (HrStaff config) | Web-only |
| Question Bank authoring (full CRUD) | Long-form authoring |
| Recommendation rule editor | Web-only |
| HPC template + PDF authoring | DomPDF design surface, web-only |
| Vendor procurement workflow (PO/PR/Quotation/AMC) | Internal procurement, web-only |
| Inventory: GRN, stock issue, reorder, vendor integration | Stockroom workstation |
| Accounting: voucher engine, chart of accounts, journals | Web-only |
| Marksheet config templates (MSG) | Configuration; web-only |
| Admission funnel (enquiry → application → shortlist → enroll) | Pre-account; web-only |
| Visitor / Gate / CCTV operations console | Kiosk/desk-side |
| Maintenance: ticket creation by admin, AMC contracts | Web-only |
| FrontOffice: postal register, gate pass desk console | Desk-only |
| Cafeteria POS counter | Counter terminal |
| Documentation authoring | Editor needs full keyboard |
| Template builder (visual canvas) | Heavy editor |
| Communication module config (DLT templates, channel setup) | Web-only |
| Feedback cycle creation (templates, questions, schedules) | Web-only |
| Online exam authoring (paper sets, blueprint) | Web-only |
| Substitution dispatch console | Web-only |
| Teacher availability bulk edit | Web-only |
| Auditor / Accounting reports / general ledger | Web-only |

---

## Section 5 — MVP (P0) Scope Recommendation

> Sequenced into 4 mobile sprints aligned with the 9-phase `{LIFECYCLE_BLUEPRINT}`. Each sprint = ~3 weeks of mobile dev + concurrent backend gap fixes.

| Sprint | Features | Backend pre-reqs (BLOCKERS in **bold**) |
|--------|----------|-----------------------------------------|
| **M1 — Auth + Skeleton** | F-001, F-002, F-003, F-004, F-005, F-130, F-133, F-134, F-135, CC-10, CC-11 | New `InitializeTenancyByHeader` middleware; new `MobileApi` namespace skeleton (per Modules/<Name>/Http/Controllers/Api/Mobile pattern); fix **SEC-PLATFORM-002** (env in routes); rate-limit mobile auth endpoints |
| **M2 — Read-only essentials** | F-010, F-011, F-012, F-021, F-022, F-030, F-031, F-052, F-054 (LmsExam only), F-060, F-070, F-080, F-081, F-083, F-090, F-131, F-132, CC-05 | Fix **BUG-NEW-002** (NTF routes commented); fix **SR-AUTH-001** (fee IDOR); fix **SEC-HPC-001**; fix **BUG-001** (HPC fatal Gate imports); register a `MOBILE_PUSH` channel; aggregator endpoints for student / parent / teacher dashboards |
| **M3 — Write actions (queued)** | F-020 (attendance), F-040, F-041, F-050 (Quiz), F-061 (Pay) | Fix **BUG-NEW-001** (PAY DDL + 3 prefixes); fix **SEC-004** (webhook auth); fix **SEC-PAY-001** (Razorpay test keys); fix **SEC-STP-007/008** (IDOR); fix **SEC-HWK-003**; fix **BUG-NEW-004** (lms_homework_assignment); ship LMS storage path config (D28) |
| **M4 — Transport & Push polish** | F-071, F-072, F-073, F-043 | Fix transport routing (0 routes today); add `MobilePushDispatcher`; per-feature push template registry |

> **Hard recommendation:** ship M1 + M2 as `v1.0.0` (Read-only MVP) before M3/M4. Read-only ships *before* the Pay flow can land safely.

---

## Section 6 — Backend Gap Summary

| # | Backend Change | Owning Module | Effort | Module Status | Linked Features |
|---|----------------|---------------|--------|---------------|-----------------|
| BG-01 | New middleware `InitializeTenancyByHeader` reading `X-Tenant-Host` | App\Http\Middleware (or stancl extension) | M | core | F-001, all |
| BG-02 | New `Modules/Prime/Http/Controllers/Api/Mobile/TenantController` — resolve + branding | Prime | S | FULL | F-001 |
| BG-03 | New `Modules/Prime/Http/Controllers/Api/Mobile/AuthController` — Sanctum login/forgot/reset | Prime / App | M | FULL | F-002, F-003 |
| BG-04 | Fix SEC-PLATFORM-002 — `env('APP_DOMAIN')` → `config('app.domain')` | core | S | core | F-001 prereq |
| BG-05 | Fix SEC-PLATFORM-004 — remove `is_super_admin` from $fillable | App\Models\User | S | core | F-002 prereq |
| BG-06 | Fix BUG-001 — missing model imports (HPC) in AppServiceProvider | core | S | core | F-090 prereq |
| BG-07 | Fix BUG-002 — duplicate `Gate::policy()` registrations | core | M | core | many |
| BG-08 | Fix BUG-NEW-002 — un-comment Notification routes + fix `tenant.*` Gate prefix | Notification | S | PARTIAL ~35% | F-080, F-081 |
| BG-09 | New `MOBILE_PUSH` channel + `MobilePushDispatcher` service | Notification | M | PARTIAL | F-080 + all push |
| BG-10 | New `ntf_device_tokens` register endpoint | Notification | S | PARTIAL | F-080 |
| BG-11 | Fix SEC-HPC-001 — add Gate to all 13 HpcController methods | Hpc | M | FULL | F-090 |
| BG-12 | Fix SR-AUTH-001 — fee endpoint ownership checks | StudentFee | M | PARTIAL | F-060, F-061 |
| BG-13 | Fix SEC-STP-007 — IDOR in `proceedPayment` | StudentPortal | S | PARTIAL | F-061 |
| BG-14 | Fix SEC-STP-008 — IDOR in `StudentExamAttemptController::attempt` | StudentPortal | S | PARTIAL | F-053 |
| BG-15 | Fix BUG-NEW-001 — Payment module DDL + standardize `pay_*` prefix | Payment | L | PARTIAL | F-061 |
| BG-16 | Fix SEC-004 — move Razorpay webhook OUTSIDE auth middleware | Payment | S | PARTIAL | F-061 |
| BG-17 | Rotate hardcoded API keys (SEC-NEW-001 / QB-SEC-001 / SEC-PAY-001) | QuestionBank, Payment | S | mixed | many |
| BG-18 | Fix SEC-HWK-003 — IDOR on homework `show()` | LmsHomework | S | PARTIAL | F-040, F-042 |
| BG-19 | Fix BUG-NEW-004 — create `lms_homework_assignment` migration | LmsHomework | M | PARTIAL | F-040, F-041 |
| BG-20 | New homework-submission endpoint (does not exist on web) | LmsHomework | M | PARTIAL | F-041 |
| BG-21 | Implement LMS cloud-storage paths per D28 advisory | LmsHomework, LmsExam | M | PARTIAL | F-041, F-053 |
| BG-22 | Fix SEC-EXM-005 — IDOR on grievance review | LmsExam | S | PARTIAL | future |
| BG-23 | Fix StudentProfile AttendanceController fatal Gate import | StudentProfile | S | PARTIAL | F-020 |
| BG-24 | Build attendance API in NEW `Attendance` module (`att_*` 14 tables) | Attendance (PLANNED) | XL | PLANNED | F-020 |
| BG-25 | Fix Transport route registration (0 active routes) | Transport | M | PARTIAL | F-070, F-072 |
| BG-26 | Driver app endpoints (start trip, GPS, board, incident) | Transport | L | PARTIAL | F-072, F-071, F-073 |
| BG-27 | Live trip parent endpoint (poll/WebSocket) | Transport | L | PARTIAL | F-071 |
| BG-28 | Implement ParentPortal module (DDL ready) | ParentPortal (PLANNED) | XL | PLANNED | F-005, F-011, F-022, F-043, plus all P-* |
| BG-29 | Implement Communication module (PLANNED) | Communication (PLANNED) | XL | PLANNED | F-082, SMS OTP |
| BG-30 | Implement Hostel module (DDL v3 ready, D34) | Hostel (PLANNED) | XL | PLANNED | F-120, F-121 |
| BG-31 | Implement employee leave APIs (DDL v4 ready, D33) | SchoolSetup / HrStaff | L | DDL_ONLY | F-102, F-103 |
| BG-32 | Implement student leave (`Attendance` module `att_leave_*`) | Attendance (PLANNED) | M | PLANNED | F-100, F-101 |
| BG-33 | Mobile-friendly signed PDF URLs across modules | many | M | mixed | F-062, F-090, F-130, F-054 |
| BG-34 | Mobile dashboard aggregator services (Student / Parent / Teacher / Principal) | various | L | partial | F-010..F-013 |
| BG-35 | New endpoint `GET /api/mobile/v1/version` for forced update | central | S | NEW | F-135 |
| BG-36 | Per-tenant Meilisearch indexes for app-wide search | search infra | L | NEW | F-140 |
| BG-37 | Cross-platform push templates (FCM payload schema) | Notification | M | PARTIAL | all push |
| BG-38 | New `sch_notices` table + controller (vs. relying on ntf_*) | SchoolSetup | M | NEW | F-083 |
| BG-39 | Apply D25 — replace `$request->all()` with `$request->validated()` across mobile-touched controllers | many | M | mixed | mass-assignment safety |
| BG-40 | Apply D30 — every FormRequest authorize() returns Gate check, not bare true | many | M | mixed | defense-in-depth |
| BG-41 | Standardize Gate prefix to `tenant.*` (D24) on touched modules | many | M | mixed | auth correctness |
| BG-42 | Confirm route registration architecture per D22 for any NEW Mobile API controllers | each module | S | per-module | new mobile endpoints |
| BG-43 | Audit logging for every mobile write (`sys_activity_logs`) | each | S | mixed | compliance |

---

## Section 7 — Open Decisions for You

1. **Stack choice** — Confirm Flutter (recommended), or override to React Native + Expo. The catalogue is stack-agnostic; downstream Phase 2 SRS docs will pick libraries based on this answer.
2. **Tenant resolution at app launch** — three input modes proposed (subdomain text / 6-char tenant code / onboarding QR). Which are required at v1? Recommend tenant code + QR; defer subdomain to advanced.
3. **RBS mapping** — Want each feature back-mapped to specific Functionality / Task / Sub-task IDs from `PrimeAI_RBS_Menu_Mapping_v2.0.md` in Phase 2, or keep mobile feature IDs as canonical with a separate cross-reference table?
4. **iOS deployment ownership** — Per-tenant Apple Developer accounts (true white-label) vs. one Prime-AI master Apple account hosting all schools (skinned via tenant config)? Big cost & operational difference.
5. **Branding & white-label** — App icon + name + splash colour per tenant (build-time per-tenant artifact) vs. runtime branding (single master app, tenant logo/color loaded after F-001)?
6. **Localization scope** — Hindi + English at v1 only, or also regional (Marathi, Gujarati, Tamil, Telugu, Bengali)? Each language adds ~3% effort plus translator cost.
7. **Push providers** — FCM + APNs only, or also include MSG91/Twilio SMS fallback (DLT-compliant SMS lives in planned `Communication` module — blocks if needed at v1)?
8. **Online-exam mobile policy** — Allow F-053 online exam attempt on mobile (weaker anti-cheat than browser kiosk) or restrict mobile to schedule + results only and require web for the actual attempt? Recommend the latter for v1.0; revisit for v1.1.
9. **Transport staff app** — One unified app with role-gated UI vs. a separate stripped-down "Driver/Conductor" app to minimize PII exposure on shared devices? Recommend separate driver app at v1.1; v1.0 reuses unified app gated by role.
10. **`/api/mobile/v1/*` namespace ownership** — Each module gets a `Modules/<Name>/Http/Controllers/Api/Mobile/<Feature>Controller.php` (per Rule §2.7 — backend logic stays in business module), with route registration in each module's `routes/api.php`. This complies with the "no generic Mobile module for business logic" rule. Confirm — or propose a single `Modules/MobileApi/` shell module that delegates to existing services?
11. **P0 vs P1 borderline calls to confirm** —
    - F-013 Principal dashboard — leave at P1?
    - F-053 Online exam — depends on Q-8.
    - F-091 HPC parent form — P1?
    - F-100..F-103 Leave (student + employee) — P1?
12. **RBS_ONLY blockers — fast-track or defer?**
    - **ParentPortal (BG-28)** — required for ANY P0 parent feature (F-005, F-011, F-022, F-043). Recommend fast-track.
    - **Attendance module (BG-24, BG-32)** — required for proper F-020. Alternative: ship F-020 against existing StudentProfile AttendanceController (after fixing fatal Gate import) at v1; migrate to `att_*` later.
    - **Payment DDL (BG-15)** — required for F-061. Recommend fast-track concurrent with M3.
    - **Communication (BG-29)** — F-082 messaging. Defer to v1.1.
    - **Hostel (BG-30)**, **Employee leave (BG-31)**, **HrStaff** — defer to v1.1+.
13. **App-store account & signing** — Prime-AI Apple/Google accounts, or per-school accounts? Cost: $99/yr (Apple) per tenant if per-school, plus enterprise distribution complexity.

---

## STOP — End of Phase 1

> Awaiting "approved — proceed to Phase 2" or change requests.
> Any change requests should reference Feature IDs (F-XXX, CC-XX, BG-XX) for unambiguous edits.

---

## Appendix — Quick Cross-Index

**By Priority**
- **P0 (29):** F-001..F-005, F-010..F-012, F-020..F-022, F-030, F-031, F-040, F-041, F-050, F-052, F-054, F-060..F-062, F-070..F-073, F-080, F-081, F-083, F-090, F-130, F-133..F-135, CC-05, CC-10, CC-11
- **P1 (16):** F-013, F-023, F-032, F-042, F-043, F-051, F-053, F-082, F-084, F-091, F-100..F-103, F-110, F-111, F-131, F-132, F-140
- **P2 (2):** F-120, F-121

**By Module Status (for each touched module)**
- FULL or PARTIAL (immediately addressable, with bug fixes): All §2.1–§2.13 except the PLANNED-only features below
- PLANNED (blocks the feature):
  - **ParentPortal:** F-005, F-011, F-022, F-043, plus all explicit P-* mirrors (29 features touched in v1.0/v1.1)
  - **Attendance (`att_*`):** F-020, F-100, F-101 (alternative path through StudentProfile possible for F-020)
  - **Communication:** F-082, SMS OTP in F-003
  - **Hostel:** F-120, F-121
  - **Cafeteria, Certificate, FrontOffice, HrStaff, Maintenance, VisitorSecurity:** v1.1+ features only — confirm in §7 Q-12

**Critical Backend Blockers to clear before MVP ships**
1. SEC-PLATFORM-002 (env in routes) — affects F-001
2. SEC-PLATFORM-004 (is_super_admin in $fillable) — affects F-002
3. BUG-001 (missing model imports — HPC) — affects F-090
4. BUG-NEW-002 (NTF routes commented) — affects F-080, all push
5. BUG-NEW-001 (PAY 3 broken prefixes, no DDL) — blocks F-061
6. SEC-004 (webhook behind auth) — blocks F-061
7. SEC-PAY-001 / SEC-NEW-001 / QB-SEC-001 (hardcoded API keys) — must rotate before any production
8. SEC-STP-007 / SEC-STP-008 (IDOR) — affects F-061, F-053
9. SR-AUTH-001 (fee endpoint ownership) — blocks F-060, F-061
10. SEC-HPC-001 (HPC zero auth) — blocks F-090

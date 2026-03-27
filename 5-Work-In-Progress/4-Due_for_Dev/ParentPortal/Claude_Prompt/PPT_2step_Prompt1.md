# PPT — Parent Portal Module Development Lifecycle Prompt (v1)

**Purpose:** Consolidated prompt to build the **PPT (ParentPortal)** module from scratch using `PPT_ParentPortal_Requirement.md` as the single source of truth. Execute phases sequentially; Claude stops after each for your review.

**⚠️ IMPORTANT — This is a GREENFIELD module (0% code).**
- Phase 2 covers DDL (6 new `ppt_*` tables) AND Authorization Architecture (custom middleware, Policies, FormRequests, Services) — both are required from scratch.
- No existing code to read — all artifacts must be generated fresh.

**Output Files:**
1. `PPT_FeatureSpec.md` — Complete Feature Specification + Architecture Blueprint
2. `PPT_DDL_Auth.md` — DDL for 6 ppt_* tables + Authorization Architecture (Middleware, Policies, FormRequests, Services)
3. `PPT_Dev_Plan.md` — Full Development Plan (P0 → P1 → P2 → P3)

**Developer:** Brijesh
**Module:** ParentPortal — Parent/guardian-facing self-service portal for Indian K-12 schools. OTP-based passwordless login, multi-child support, fee payment, messaging, leave applications, consent forms, PTM booking.
**Existing code:** NONE — 0 controllers, 0 views, 0 routes. Greenfield.
**Owned tables:** 6 new `ppt_*` tables to be created. Reads from 30+ external module tables.

---

## DEFAULT PATHS

Read `{AI_BRAIN}/config/paths.md` — resolve all path variables from this file.

## Rules
- All paths come from `paths.md` unless overridden in CONFIGURATION below.
- If a variable exists in both `paths.md` and CONFIGURATION, the CONFIGURATION value wins.

---

## Repositories

```
DB_REPO        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
OLD_REPO       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
AI_BRAIN       = {OLD_REPO}/AI_Brain
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai_tarun
LARAVEL_CLAUDE = {LARAVEL_REPO}/.claude/rules
```

## CONFIGURATION

```
MODULE_CODE       = PPT
MODULE            = ParentPortal
MODULE_DIR        = Modules/ParentPortal/
BRANCH            = Brijesh_Main
DB_TABLE_PREFIX   = ppt_
DATABASE_NAME     = tenant_db
COMPLETION        = 0%                             # Greenfield — no existing code

OUTPUT_DIR        = {OLD_REPO}/5-Work-In-Progress/ParentPortal/2-Claude_Plan
TENANT_DDL        = {DB_REPO}/1-Master_DDLs/tenant_db_v2.sql
REQUIREMENT_FILE  = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V2/PPT_ParentPortal_Requirement.md

FEATURE_FILE      = PPT_FeatureSpec.md
DDL_AUTH_FILE     = PPT_DDL_Auth.md
DEV_PLAN_FILE     = PPT_Dev_Plan.md

PPT_MODULE_DIR    = {LARAVEL_REPO}/Modules/ParentPortal/
CONTROLLERS_DIR   = {PPT_MODULE_DIR}/app/Http/Controllers/
ROUTES_WEB        = {PPT_MODULE_DIR}/routes/web.php
ROUTES_API        = {PPT_MODULE_DIR}/routes/api.php
```

---

## HOW TO USE THIS PROMPT

1. Paste this entire document into a new Claude conversation
2. Say: **"Start Phase 1"**
3. Claude reads requirement files, generates output, and **STOPS**
4. Review the output; give feedback or say: **"Approved. Proceed to Phase 2"**
5. Repeat for Phase 3

---

## KEY CONTEXT — PPT (PARENT PORTAL) MODULE

### What This Module Does

ParentPortal is the **parent/guardian-facing self-service interface** of Prime-AI. It provides parents of enrolled students access to: multi-child dashboard (switch active child), OTP-based passwordless login, attendance calendar, weekly timetable, homework tracker, exam results + report card download, fee invoices + Razorpay payment, direct parent-teacher messaging, leave applications, digital consent forms, PTM slot booking, event calendar + RSVP, health/HPC reports, transport tracking, document vault + duplicate certificate requests, notification inbox with smart quiet-hours preferences, and account settings — all through a dedicated portal separate from the admin backend and the Student Portal.

### Current State (0% — Greenfield)

No code exists. Everything must be built from scratch:
- 0 controllers → Target: 16 controllers
- 0 services → Target: 5 services
- 0 FormRequests → Target: 9 FormRequests
- 0 policies → Target: 3 policies
- 0 Blade views → Target: ~45 views
- 0 routes → Target: ~75 web + ~18 API routes
- 0 tables → Target: 6 new `ppt_*` tables

### Critical Security Requirements (P0 — Must be built first)

```
P0 IDOR Prevention (BR-PPT-012):
  ALL data endpoints must enforce ParentChildPolicy.
  No child data is accessible without verified guardian→child link:
    std_student_guardian_jnt WHERE guardian.user_id = auth()->id()
    AND can_access_parent_portal = 1
  This is NOT optional — every single controller method needs this check.

P0 Fee Payment IDOR (BR-PPT-002):
  Parent can ONLY pay invoices for their OWN linked child.
  Ownership guard: FeeInvoice → fin_fee_invoices.student_id must match
  a student in guardian's allowed children list.

P0 Custom Middleware — parent.portal:
  Must verify ALL three conditions on every portal request:
  1. auth()->user()->user_type === 'PARENT'
  2. std_guardians record exists for this user (via user_id)
  3. At least 1 std_student_guardian_jnt record exists with
     guardian_id + can_access_parent_portal = 1
  Return 404 (not 401/403) on failure — prevents enumeration of portal existence.

P0 OTP Rate Limiting (BR-PPT-013):
  Max 3 OTP requests per mobile per hour.
  Max 3 OTP attempts per code (10-minute expiry).
  30-minute lockout after 5 consecutive failures.
  Enforce via Laravel Rate Limiter (not throttle middleware alone).

P0 Multi-Child Context (BR-PPT-010):
  active_student_id stored in ppt_parent_sessions (DB, not PHP session).
  On every data request: verify that active_student_id belongs to
  the authenticated parent's allowed children list.
```

### Architecture Decisions
- **Single Laravel module** (`Modules\ParentPortal`) — 16 controllers, all portal screens in one module
- Stancl/tenancy v3.9 — `InitializeTenancyByDomain` + `PreventAccessFromCentralDomains` in middleware stack
- Route prefix: `parent-portal/` | Route name prefix: `ppt.`
- **Custom middleware `parent.portal`** — NOT Spatie roles; enforces user_type=PARENT + guardian + child access check
- Auth: OTP-based passwordless login (AuthController) + standard password login fallback
- Multi-child: `ppt_parent_sessions.active_student_id` stores active child (DB, not session); enables multi-device sync
- Rate limiting: `throttle:3,1` on OTP send; `throttle:3,5` on fee payment initiation
- Layout: `parentportal::components.layouts.master` — separate from admin and student portal layouts
- **6 owned tables** — all `ppt_*` prefix; all other data read from 30+ tables across 15 modules
- Payment: Razorpay hosted checkout (not embed); idempotency via `payment_reference` UNIQUE nullable
- Notifications: FCM (Android), APNs (iOS), Web Push (PWA); Laravel Notification channels; fallback SMS (MSG91/Twilio)
- PDF generation: DomPDF for fee receipts, report cards, HPC reports; A4 format with school letterhead
- Signed URLs: document downloads expire after 24 hours via `Storage::temporaryUrl()`
- Audit: All parent actions logged to `sys_activity_logs` (view, payment, message, leave)
- Dashboard cache: `Cache::tags(['parent', $guardianId])->remember(300, ...)` — 5 min TTL; invalidated on data change

### Module Scale
| Artifact | Current | Target (after completion) |
|---|---|---|
| Controllers | 0 | 16 (AuthController + 15 feature controllers) |
| Services | 0 | 5 (ParentDashboardService, FeePaymentService, MessagingService, NotificationPreferenceService, PtmSchedulingService) |
| FormRequests | 0 | 9 (see Phase 2 for full list) |
| Policies | 0 | 3 (ParentChildPolicy, ParentMessagePolicy, ParentLeavePolicy) |
| Middleware | 0 | 1 (parent.portal custom middleware) |
| Blade views | 0 | ~45 views |
| Routes | 0 | ~75 web + ~18 API |
| Tables owned | 0 | 6 (ppt_* prefix) |
| Test files | 0 | 20+ (security + functional + regression) |
| Completion | 0% | 100% |

### Tables Owned (6 new ppt_* tables)

| Table | Purpose |
|---|---|
| `ppt_parent_sessions` | Per-device portal state, active child, device tokens (FCM/APNs/WebPush), notification preferences, quiet hours |
| `ppt_messages` | Parent-teacher direct messages scoped to child context; thread-based with FULLTEXT search |
| `ppt_leave_applications` | Leave applications submitted by parent on behalf of child |
| `ppt_event_rsvps` | Parent RSVPs and volunteer sign-ups for school events |
| `ppt_document_requests` | Online requests for duplicate certificates (TC, MarkSheet, Bonafide, etc.) |
| `ppt_consent_form_responses` | Parent responses to school digital consent forms (immutable after signing) |

### Tables Consumed (Read or Write via External Models — 30+ tables)

**STD Module (StudentProfile):**
`std_students`, `std_guardians`, `std_student_guardian_jnt` (core FK chain), `std_health_records`, `std_student_academic_sessions`

**FIN Module (StudentFee):**
`fin_fee_invoices`, `fin_fee_installments`, `fin_transactions`

**Attendance:**
`std_attendance` (daily), `std_subject_attendance` (subject-wise)

**Timetable:**
`tt_timetable_cells`, `tt_published_timetables`

**LMS Modules:**
`hmw_assignments`, `hmw_submissions`, `exm_results`, `exm_report_cards`

**HPC Module:**
`hpc_health_profiles`, `hpc_physical_assessments`, `hpc_counsellor_reports`

**Transport:**
`tpt_routes`, `tpt_vehicles`, `tpt_student_route_jnt`

**System:**
`sys_users`, `sys_media`, `sys_school_settings`, `ntf_notifications`, `ntf_circulars`

### Core Parent Data Relationship Chain
```
auth()->user() [sys_users, user_type=PARENT]
    └── guardian [std_guardians, via user_id]
         └── studentGuardianJnts [std_student_guardian_jnt]
              │     WHERE can_access_parent_portal = 1
              └── students [std_students] — the allowed children
                   └── active child (ppt_parent_sessions.active_student_id)
                        ├── attendance [std_attendance]
                        ├── feeInvoices [fin_fee_invoices]
                        ├── timetableCells [tt_timetable_cells]
                        ├── homeworkAssignments [hmw_assignments]
                        ├── examResults [exm_results]
                        ├── healthProfile [hpc_health_profiles]
                        └── transportAllocation [tpt_student_route_jnt]
```

---

## PHASE 1 — Feature Specification

### Phase 1 Input Files
Read ALL these files in order before generating any output:

1. `{REQUIREMENT_FILE}` — **Primary source** — PPT v2 requirement (all 18 FRs, 6 table definitions, routes, business rules, workflows, tests)
2. `{AI_BRAIN}/memory/project-context.md` — Project context
3. `{AI_BRAIN}/memory/modules-map.md` — Existing module inventory (esp. STD, FIN, TT, HMW, EXM modules)
4. `{AI_BRAIN}/agents/business-analyst.md` — BA agent instructions (read if file exists)
5. `{TENANT_DDL}` — Verify external table column names (std_student_guardian_jnt.can_access_parent_portal, std_health_records.parent_visible, fin_fee_invoices columns)

### Phase 1 Task — Generate `PPT_FeatureSpec.md`

Generate a comprehensive feature specification document. This is both a forward-looking spec and an architecture blueprint. Organise into 11 sections:

---

#### Section 1 — Module Identity & Scope
- Module code, namespace (`Modules\ParentPortal`), route prefix (`parent-portal/`), route name prefix (`ppt.`), DB prefix (`ppt_`)
- Module type: Parent/guardian-facing portal — separate from admin backend and StudentPortal
- In-scope features (verbatim from req v2 Section 4 — all 18 FRs)
- Out-of-scope: admin student management (STD module); fee structure management (FIN module); payment processing logic (Payment module); attendance marking (ACD/STD module); homework creation (HMW module)
- Module scale table (controllers / services / FormRequests / policies / middleware / views / routes — current: 0, target: full)
- Note the 6 owned `ppt_*` tables AND the 30+ external tables consumed

#### Section 2 — Screens Inventory (All 38 Screens)
For each screen, provide:
| # | Screen Name | Route Name | View File | FR Ref | Description |
|---|---|---|---|---|---|

Use three categories: 🆕 To Build (greenfield — all 38 screens)

List screens grouped by functional area:
- **Auth** (SCR-PPT-01: Login OTP/Password, SCR-PPT-02: OTP Verification)
- **Dashboard & Navigation** (SCR-PPT-03: Dashboard, SCR-PPT-04: Child Switcher)
- **Academic** (SCR-PPT-05: Attendance Calendar, SCR-PPT-06: Subject-wise Attendance, SCR-PPT-07: Timetable, SCR-PPT-08: Homework List, SCR-PPT-09: Homework Detail, SCR-PPT-10: Results List, SCR-PPT-11: Result Detail, SCR-PPT-12: Report Card Download)
- **Finance** (SCR-PPT-13: Fee Summary, SCR-PPT-14: Razorpay Checkout, SCR-PPT-15: Payment Success, SCR-PPT-16: Payment History)
- **Communication** (SCR-PPT-17: Message Inbox, SCR-PPT-18: Message Thread, SCR-PPT-19: Compose Message, SCR-PPT-20: Notification Inbox, SCR-PPT-21: Notification Detail, SCR-PPT-22: Notification Preferences)
- **Requests & Forms** (SCR-PPT-23: Leave List, SCR-PPT-24: Apply Leave, SCR-PPT-25: Leave Status, SCR-PPT-26: Consent Forms List, SCR-PPT-27: Consent Form Detail)
- **Meetings & Events** (SCR-PPT-28: PTM Events, SCR-PPT-29: PTM Slot Booking, SCR-PPT-30: Event Calendar, SCR-PPT-31: Event Detail)
- **Health & Info** (SCR-PPT-32: Health Overview, SCR-PPT-33: Health Report Detail, SCR-PPT-34: Transport Info, SCR-PPT-35: Document Vault, SCR-PPT-36: Document Request Form, SCR-PPT-37: Document Request Status)
- **Settings** (SCR-PPT-38: Account Settings)

For each screen document:
- Proposed view file path: `resources/views/` under `parentportal::` namespace
- FR reference (FR-PPT-xx)
- Controller@Method
- Key data requirements and external module dependencies
- Build complexity: Simple / Medium / Complex

#### Section 3 — Security Architecture Matrix
Document all security requirements with implementation approach:

| Requirement | Category | Enforcement Point | Implementation |
|---|---|---|---|

Critical items to highlight with ⚠️ marker:
- **P0 IDOR — ParentChildPolicy**: Every data request verifies guardian→child ownership (BR-PPT-012)
- **P0 Fee payment IDOR**: `fin_fee_invoices` accessed only via verified guardian→student chain (BR-PPT-002)
- **P0 Custom middleware**: `parent.portal` — three-condition check; returns 404 not 401/403 (prevents enumeration)
- **P0 Multi-child context**: `active_student_id` verified on each request — must be in guardian's allowed children (BR-PPT-010)
- **P0 OTP rate limiting**: max 3/hour/mobile + max 3 attempts/code + 30-min lockout (BR-PPT-013)
- **P0 Razorpay idempotency**: `payment_reference` UNIQUE nullable prevents double-credit on webhook replay (BR-PPT-018)
- **P1 Signed URLs**: Document downloads via `Storage::temporaryUrl()` — 24-hour expiry (BR-PPT-011 / FR-PPT-16)
- **P1 Counsellor report gate**: Hidden unless `sys_school_settings.parent_counsellor_report_visibility = 1` (BR-PPT-007)
- **P1 Medical record gate**: Per-record `std_health_records.parent_visible = 1` required (BR-PPT-006)
- **P1 Quiet hours**: AbsenceAlert and EmergencyAlert ALWAYS bypass quiet hours; all others buffered (BR-PPT-008)
- **P2 Audit logging**: All parent actions → `sys_activity_logs` (req Section 10)
- **P2 Consent form immutability**: `signed_at` timestamp + `signed_ip` immutable after signing; unique constraint prevents double-sign (BR-PPT-014)

For each row in the matrix, add:
- **Design Decision**: where in code this is enforced
- **Test scenario reference** from req Section 12

#### Section 4 — Business Rules (All 18 rules)
For each rule:
- Rule ID (BR-PPT-001 to BR-PPT-018)
- Rule text (verbatim from req v2 Section 8)
- Enforcement point: `middleware` | `policy` | `service_layer` | `form_validation` | `db_constraint`
- Implementation approach (what code enforces it)

Groups:
1. Data Isolation (BR-PPT-001 to BR-PPT-003) — core ownership, IDOR, messaging restriction
2. Application Rules (BR-PPT-004 to BR-PPT-007) — leave dates, report card gate, medical visibility, counsellor gate
3. Notification Rules (BR-PPT-008 to BR-PPT-009) — quiet hours, device tokens
4. Multi-Child & Payments (BR-PPT-010, BR-PPT-011, BR-PPT-012) — active context, document fee gate, IDOR policy
5. Auth & Session Rules (BR-PPT-013 to BR-PPT-018) — OTP limits, consent uniqueness, PTM booking, volunteer capacity, leave event dispatch, Razorpay idempotency

Critical rules to emphasise:
- BR-PPT-001: Guardian can ONLY access data for children linked via `std_student_guardian_jnt` — core IDOR prevention
- BR-PPT-002: Fee payment — student_id match mandatory — cannot pay another child's invoice
- BR-PPT-010: active_student_id in DB not PHP session — multi-device sync requirement
- BR-PPT-012: ParentChildPolicy on EVERY SINGLE data endpoint — no exceptions
- BR-PPT-013: OTP rate limiting — three separate limits, different enforcement points
- BR-PPT-017: Leave approval dispatches event to attendance module — cross-module integration point

#### Section 5 — Workflow Diagrams (6 FSMs)
For each workflow:
- Step-by-step flow with security check points highlighted with ⚠️
- External module integration points highlighted with 🔗

Workflows to document (from req Section 9):
1. **OTP Login Flow** (FR-PPT-02) — rate limit check → send OTP → OTP entry (3 attempts, 10-min expiry) → verify → AUTHENTICATED → first login password setup → dashboard. Mark lockout after 5 failures.
2. **Fee Payment FSM** (FR-PPT-05) — invoice list → ownership guard ⚠️ → Razorpay order → hosted checkout → signature verification ⚠️ → `fin_transactions` created → SMS receipt → PDF receipt. Mark idempotency check on webhook replay.
3. **Leave Application FSM** (FR-PPT-10) — PENDING → APPROVED (event dispatched to attendance 🔗) | REJECTED (reviewer_notes stored) | WITHDRAWN (from PENDING only). Mark from_date >= tomorrow validation ⚠️.
4. **Document Request FSM** (FR-PPT-16) — PENDING → PROCESSING → READY (fee_required > 0: payment gate ⚠️) → COMPLETED (signed URL generated) | REJECTED. Mark 24-hour URL expiry.
5. **Consent Form FSM** (FR-PPT-11) — PUBLISHED → SIGNED (immutable: timestamp + IP recorded ⚠️) | DECLINED (reason required). Mark DEADLINE_PASSED → read-only state; unique constraint prevents double-sign.
6. **PTM Slot Booking FSM** (FR-PPT-12) — SLOT_AVAILABLE → BOOKING_PENDING (DB transaction locked ⚠️) → BOOKED (confirmation sent) | Error (race condition: "Slot just taken"). Mark 1-hour cancellation cutoff → LOCKED.

#### Section 6 — Functional Requirements Summary (18 FRs)
For each FR-PPT-01 to FR-PPT-18:
| FR ID | Name | Status | Controller@Method | Tables Written | External Tables Read | Key Design Notes | Priority |
|---|---|---|---|---|---|---|---|

All status: 🆕 To Build (greenfield)

Group by priority: P0 (Critical) | P1 (High) | P2 (Medium)

Also note for each FR:
- Which business rule(s) it relates to
- Which external module it reads from
- Whether it has cross-module event dispatch

#### Section 7 — External Module Dependencies Matrix
For each external module PPT depends on:
| Module | Direction | Tables/Models Used | Portal Feature(s) | Notes |
|---|---|---|---|---|

Document the core FK chain in full:
```
auth()->user() [sys_users, user_type=PARENT]
    → guardian [std_guardians, user_id FK]
    → studentGuardianJnts [std_student_guardian_jnt, can_access_parent_portal=1]
    → students [std_students]
    → active child [ppt_parent_sessions.active_student_id]
```

Note each dependency's soft/hard status:
- **Hard** (portal broken if absent): STD, FIN, PAY, SYS
- **Soft — graceful degradation** (show "module not activated"): TT, HMW, EXM, ACD, HPC, TPT, NTF, EVN
- Verify `std_student_guardian_jnt.can_access_parent_portal` column existence in `{TENANT_DDL}`
- Verify `std_health_records.parent_visible` flag column in `{TENANT_DDL}`
- Verify `fin_fee_invoices` column structure (direct `student_id`? or via FK chain?) in `{TENANT_DDL}`

#### Section 8 — Service Architecture (Target State — 5 services)
Define each planned service:

**1. ParentDashboardService**
```
File:    Modules/ParentPortal/app/Services/ParentDashboardService.php
Purpose: Aggregate all dashboard widgets for active child in max 5 queries total
Key Methods:
  getDashboardData(Guardian $guardian, Student $activeChild): array
    └── Batch-fetches: attendance stats, today's timetable, pending homework,
        upcoming exams (3), fee summary (unpaid total), pending consent forms,
        leave applications (pending count), notification unread count
        → All data in ≤ 5 queries via eager-loading + tagged cache
  getChildSummary(Student $student): array
    └── Academic session, class, section, roll number
```

**2. FeePaymentService**
```
File:    Modules/ParentPortal/app/Services/FeePaymentService.php
Purpose: Razorpay order creation, signature verification, payment recording
Key Methods:
  initiatePayment(Guardian $guardian, FeeInvoice $invoice, array $data): array
    └── Ownership guard → Razorpay order → return order_id + key
  verifyAndRecord(array $razorpayPayload): bool
    └── HMAC signature verify → idempotency check (payment_reference unique)
        → fin_transactions create → invoice status update → dispatch receipt
```

**3. MessagingService**
```
File:    Modules/ParentPortal/app/Services/MessagingService.php
Purpose: Thread-based parent-teacher messaging with ownership enforcement
Key Methods:
  getOrCreateThread(int $guardianId, int $teacherUserId, int $studentId): string
    └── thread_id = MD5(guardianId + teacherUserId + studentId)
  getAllowedTeachers(Student $student): Collection
    └── Teachers from timetable assignments for active child (ParentMessagePolicy)
  storeMessage(ComposeMessageRequest $request, Guardian $guardian): PptMessage
```

**4. NotificationPreferenceService**
```
File:    Modules/ParentPortal/app/Services/NotificationPreferenceService.php
Purpose: Evaluate notification delivery considering preferences and quiet hours
Key Methods:
  shouldDeliver(PptParentSession $session, string $alertType, string $channel): bool
    └── Check preference JSON → check quiet hours → check urgent bypass
        (AbsenceAlert + EmergencyAlert ALWAYS bypass quiet hours — BR-PPT-008)
  savePreferences(Guardian $guardian, array $preferences): void
    └── Upsert ppt_parent_sessions.notification_preferences_json
```

**5. PtmSchedulingService**
```
File:    Modules/ParentPortal/app/Services/PtmSchedulingService.php
Purpose: Race-condition-safe PTM slot booking
Key Methods:
  getAvailableSlots(int $ptmEventId): Collection
  bookSlot(PtmBookingRequest $request, Guardian $guardian): object
    └── DB::transaction() + select-for-update → conflict check → book → notify
  cancelBooking(int $bookingId, Guardian $guardian): bool
    └── ≥ 1 hour before PTM check → release slot
```

**Note:** Controllers must remain thin — call services and pass result to view.

#### Section 9 — FormRequest Architecture (Target State — 9 FormRequests)
For each planned FormRequest:
| Class | Controller Method | authorize() logic | Key Rules |
|---|---|---|---|

All 9 FormRequests (P0/P1):

1. **`ComposeMessageRequest`** — `authorize()`: parent.portal middleware handles auth; verify recipient is an allowed teacher via MessagingService::getAllowedTeachers() | rules: recipient_teacher_id required + allowed, subject required + max:200, message_body required + max:5000, attachments nullable + array + each: mimes:jpg,jpeg,png,pdf + max:5120

2. **`ApplyLeaveRequest`** — `authorize()`: parent.portal + active child verified | rules: from_date required + date + after:today (MUST be >= tomorrow), to_date required + after_or_equal:from_date, leave_type required + in enum list, reason required + min:20 + max:2000, supporting_doc nullable + file + mimes:jpg,jpeg,png,pdf + max:5120

3. **`EventRsvpRequest`** — `authorize()`: parent.portal middleware | rules: event_id required + exists, rsvp_status required + in:Attending,Not_Attending,Maybe, is_volunteer nullable + boolean, volunteer_role nullable + required_if:is_volunteer,true + max:150

4. **`DocumentRequestForm`** — `authorize()`: parent.portal + active child verified | rules: document_type required + in enum list, reason required + min:20 + max:2000, urgency required + in:Normal,Urgent

5. **`NotificationPreferencesRequest`** — `authorize()`: parent.portal middleware | rules: preferences required + array (validated against allowed alert types), quiet_hours_start nullable + date_format:H:i, quiet_hours_end nullable + date_format:H:i + required_with:quiet_hours_start

6. **`SwitchChildRequest`** — `authorize()`: parent.portal + verify student_id is in guardian's allowed children list | rules: student_id required + integer; custom rule: student must be in `std_student_guardian_jnt` for authenticated guardian with can_access_parent_portal=1

7. **`FeePaymentRequest`** — `authorize()`: parent.portal + verify invoice ownership via guardian→student chain | rules: invoice_id required + exists:fin_fee_invoices,id + ownership check, amount required + numeric + min:0.01 + max=invoice balance, gateway required (Razorpay is the gateway), payment_note nullable + max:500

8. **`ConsentFormSignRequest`** — `authorize()`: parent.portal + active child verified + deadline not passed | rules: response required + in:Signed,Declined, decline_reason required_if:response,Declined + min:10 + max:1000, signer_name required + min:3 + max:150; prepareForValidation: strip_tags on signer_name

9. **`PtmBookingRequest`** — `authorize()`: parent.portal + active child verified | rules: ptm_event_id required + exists, teacher_user_id required + exists:sys_users,id, slot_time required + date_format:H:i, booking_date required + date + after_or_equal:today

#### Section 10 — Policy Architecture (Target State — 3 policies)

**1. ParentChildPolicy** (Core — applied on every data request)
| Method | Arguments | Authorization Logic |
|---|---|---|
| `viewChildData(User $user, Student $student)` | user, student | Check std_student_guardian_jnt: guardian.user_id = user.id + student_id = student.id + can_access_parent_portal = 1 |
| `isActiveChild(User $user, Student $student)` | user, student | viewChildData() + student.id = ppt_parent_sessions.active_student_id for this guardian |
| `viewHealthRecord(User $user, Student $student, $record)` | user, student, record | viewChildData() + record.parent_visible = 1 |
| `viewCounsellorReport(User $user)` | user | sys_school_settings.parent_counsellor_report_visibility = 1 |
| `payInvoice(User $user, Student $student, $invoice)` | user, student, invoice | viewChildData() + invoice.student_id = student.id + invoice status is payable + balance > 0 |

**2. ParentMessagePolicy**
| Method | Arguments | Authorization Logic |
|---|---|---|
| `composeMessage(User $user, User $teacher)` | parent user, teacher user | Teacher must teach at least one subject to parent's active child (verified via timetable assignments) |
| `viewThread(User $user, string $threadId)` | user, threadId | thread_id = MD5(guardian_id + teacher_id + student_id) — verify guardian_id belongs to user |

**3. ParentLeavePolicy**
| Method | Arguments | Authorization Logic |
|---|---|---|
| `apply(User $user, Student $student)` | user, student | viewChildData() from ParentChildPolicy |
| `withdraw(User $user, $leaveApplication)` | user, leaveApplication | leaveApplication.guardian_id = user.guardian.id + status = 'Pending' (can only withdraw from Pending state) |

Register all policies in `ParentPortalServiceProvider`:
```php
Gate::policy(Student::class, ParentChildPolicy::class);
// Note: ParentChildPolicy is a baseline; call via $this->authorize('viewChildData', $student)
```

#### Section 11 — Test Plan Outline
From req v2 Section 12 (33 test scenarios):

**P0 Security Tests (6 scenarios — Critical):**
| # | Test Class | Scenario | Expected |
|---|---|---|---|
| 1 | ParentAuthTest | PARENT user logs in via OTP; portal dashboard loads; STUDENT/STAFF user redirected | 200 for parent; 404 for others |
| 2 | OtpRateLimitTest | > 3 OTP requests/hour blocked; > 5 failures trigger 30-min lockout | 429 on rate limit; lockout respected |
| 3 | ParentChildAccessTest | Parent accesses own child's data (200); attempt another student's data (403) | IDOR prevented |
| 4 | FeePaymentAuthTest | Parent pays own child's invoice (200); cross-child invoice payment blocked | 403 on cross-child |
| 5 | FeePaymentIdempotencyTest | Razorpay webhook replay with same payment_id does not double-credit | Idempotent; no duplicate fin_transaction |
| 6 | SwitchChildTest | Parent switches active child; all subsequent data reflects new child context | 200; active_student_id updated in DB |

**P1 Functional Tests (17 scenarios — High/Medium):**
All messaging tests (T-07 to T-10), leave application tests (T-11 to T-14), consent form tests (T-15 to T-16), PTM booking tests (T-17 to T-19), document tests (T-20 to T-21), report card gate test (T-22), notification preference tests (T-23 to T-24), multi-device token test (T-25).

**P2 Integration Tests (10 scenarios — Health visibility, event RSVP, transport graceful degradation, unit tests for services):**
T-26 to T-33 from req Section 12.

**Test Setup:**
```php
uses(Tests\TestCase::class, RefreshDatabase::class);
// Parent user factory: user (user_type=PARENT) + std_guardians record + std_student_guardian_jnt (can_access_parent_portal=1)
// Student factory: std_students record + academic session
// Parent-B factory: different parent with different children (for IDOR tests)
// Razorpay: mock FeePaymentService → bind in test AppServiceProvider
// Queue::fake() for notification dispatch tests
// Event::fake() for leave approval cross-module event
// For OTP tests: mock SMS gateway; control OTP generation
```

---

### Phase 1 Output Files
| File | Location |
|---|---|
| `PPT_FeatureSpec.md` | `{OUTPUT_DIR}/PPT_FeatureSpec.md` |

### Phase 1 Quality Gate
- [ ] All 38 screens inventoried in Section 2 with controller mapping and FR reference
- [ ] All 18 FRs (FR-PPT-01 to FR-PPT-18) in Section 6 with priority, tables, and design notes
- [ ] All 18 business rules (BR-PPT-001 to BR-PPT-018) in Section 4 with enforcement point
- [ ] ParentChildPolicy enforcement requirement (BR-PPT-012) explicitly documented as ⚠️ P0 in Section 3
- [ ] All 6 FSM workflows in Section 5 with security checkpoints marked
- [ ] Multi-child architecture (active_student_id in DB — BR-PPT-010) documented in Section 3 and Section 8
- [ ] OTP rate limiting (BR-PPT-013) three-tier limits documented in Section 3
- [ ] Razorpay idempotency (BR-PPT-018) documented with payment_reference unique constraint
- [ ] Custom `parent.portal` middleware three-condition check documented in Section 3
- [ ] Fee invoice ownership chain (guardian→student→invoice) documented in Sections 3 and 7
- [ ] `std_student_guardian_jnt.can_access_parent_portal` column verified in TENANT_DDL in Section 7
- [ ] `std_health_records.parent_visible` column verified in TENANT_DDL in Section 7
- [ ] All 5 services designed with method signatures in Section 8
- [ ] All 9 FormRequest classes designed with authorize() logic in Section 9
- [ ] All 3 policies designed with methods in Section 10
- [ ] Soft/hard module dependencies clearly separated in Section 7
- [ ] Counsellor report gate (BR-PPT-007: school setting) and medical record gate (BR-PPT-006: per-record flag) documented
- [ ] Quiet hours bypass rule (AbsenceAlert + EmergencyAlert always bypass) documented in Section 4
- [ ] Leave approval → attendance module event dispatch (BR-PPT-017) flagged as cross-module integration in Sections 5 and 7
- [ ] All 6 P0 security test scenarios in Section 11
- [ ] 24-hour signed URL requirement for document downloads documented in Sections 3 and 9
- [ ] Consent form immutability (signed_at + signed_ip + unique key) documented in Sections 4 and 10

**After Phase 1, STOP and say:**
"Phase 1 (Feature Specification) complete. Output saved to `{OUTPUT_DIR}/PPT_FeatureSpec.md`. Please review and say 'Approved. Proceed to Phase 2' to continue."

---

## PHASE 2 — DDL + Authorization Architecture Layer

> **Why Phase 2 covers both DDL and Authorization:** PPT is a greenfield module that needs its 6 `ppt_*` tables created AND a comprehensive authorization architecture built from scratch. DDL provides the data foundation; the authorization layer (middleware, policies, FormRequests, services) provides the security backbone that must be in place before any feature controller is written.

### Phase 2 Input Files
1. `{OUTPUT_DIR}/PPT_FeatureSpec.md` — Table designs (all 6 ppt_* tables with columns and indexes), Service designs (Section 8), FormRequest designs (Section 9), Policy designs (Section 10)
2. `{REQUIREMENT_FILE}` — Section 5 (complete DDL column specs for all 6 tables), Section 8 (business rules), Section 14 (architecture suggestions SUG-PPT-01 to SUG-PPT-24)
3. `{AI_BRAIN}/agents/db-architect.md` — DDL conventions, required columns, index rules, naming rules
4. `{AI_BRAIN}/memory/conventions.md` — Table prefix and naming conventions
5. `{TENANT_DDL}` — Verify std_guardians, std_students, sys_users primary key types (INT vs BIGINT) before writing FKs

---

### Phase 2A Task — Generate `PPT_DDL_Auth.md` Part 1: DDL

#### DDL Rules for ppt_* Tables

1. **ALL `ppt_*` PKs use `INT UNSIGNED AUTO_INCREMENT`** (not BIGINT)
2. **FKs to `std_guardians` and `std_students`**: Use `INT UNSIGNED` (verify against TENANT_DDL — these are tenant_db local tables)
3. **FKs to `sys_users`**: Use `BIGINT UNSIGNED` for `created_by` column (platform standard). For `sender_user_id` and `recipient_user_id` in `ppt_messages` — **VERIFY sys_users.id type in TENANT_DDL** before choosing INT vs BIGINT; use whichever matches sys_users.id
4. **Required columns on ALL tables**: `is_active TINYINT(1) NOT NULL DEFAULT 1`, `created_by BIGINT UNSIGNED NULL`, `created_at TIMESTAMP NOT NULL`, `updated_at TIMESTAMP NOT NULL`
5. **Soft delete** (`deleted_at TIMESTAMP NULL`): Required on ppt_messages, ppt_leave_applications, ppt_document_requests. NOT on ppt_parent_sessions (use is_active=0 on logout), ppt_event_rsvps, ppt_consent_form_responses (immutable)
6. **Migration helper**: Use `->unsignedInteger()` (not `->unsignedBigInteger()`) for all `ppt_*` PKs and FKs to std_* tables
7. **`ppt_consent_form_responses.signed_at`**: This is a business timestamp (immutable after signing) — use `TIMESTAMP NOT NULL` (not nullable). This is separate from `created_at`

#### DDL Dependency Order (All 6 tables are Layer 1 — no inter-ppt_ FKs)

All 6 `ppt_*` tables only reference external tables (std_guardians, std_students, sys_users, sys_media, event engine records). They have NO foreign keys to each other. Create in any order.

**Recommended creation order:**
1. `ppt_parent_sessions` — core session state; referenced conceptually by all portal features
2. `ppt_messages` — messaging state
3. `ppt_leave_applications` — leave workflow
4. `ppt_event_rsvps` — event RSVP state
5. `ppt_document_requests` — document request workflow
6. `ppt_consent_form_responses` — consent form state (immutable after signing)

---

For each of the 6 tables, generate complete DDL:

**Table 1: `ppt_parent_sessions`**
Columns: id (INT UNSIGNED PK), guardian_id (INT UNSIGNED NOT NULL FK→std_guardians), active_student_id (INT UNSIGNED NULL FK→std_students), device_token_fcm (VARCHAR(255) NULL), device_token_apns (VARCHAR(255) NULL), device_token_webpush (TEXT NULL), device_type (ENUM('Android','iOS','Web','Unknown') DEFAULT 'Unknown'), notification_preferences_json (JSON NULL), quiet_hours_start (TIME NULL), quiet_hours_end (TIME NULL), last_active_at (TIMESTAMP NULL), is_active (TINYINT(1) DEFAULT 1), created_by (BIGINT UNSIGNED NULL), created_at (TIMESTAMP NOT NULL), updated_at (TIMESTAMP NOT NULL)
Unique: `uq_ppt_session_guardian_device_fcm` (guardian_id, device_token_fcm)
Indexes: guardian_id, active_student_id, is_active

**Table 2: `ppt_messages`**
Columns: id (INT UNSIGNED PK), guardian_id (INT UNSIGNED NOT NULL FK→std_guardians), student_id (INT UNSIGNED NOT NULL FK→std_students), direction (ENUM('Parent_to_Teacher','Teacher_to_Parent') NOT NULL), sender_user_id (INT/BIGINT UNSIGNED NOT NULL FK→sys_users — verify type), recipient_user_id (INT/BIGINT UNSIGNED NOT NULL FK→sys_users — verify type), thread_id (VARCHAR(64) NOT NULL — MD5 hash), subject (VARCHAR(200) NOT NULL), message_body (TEXT NOT NULL), attachment_media_ids_json (JSON NULL), read_at (TIMESTAMP NULL), is_active (TINYINT(1) DEFAULT 1), created_by (BIGINT UNSIGNED NULL FK→sys_users), created_at (TIMESTAMP NOT NULL), updated_at (TIMESTAMP NOT NULL), deleted_at (TIMESTAMP NULL)
Indexes: INDEX `idx_ppt_messages_thread` (thread_id, created_at), FULLTEXT `ft_ppt_messages_search` (subject, message_body)
Note: thread_id computed as MD5(guardian_id || teacher_user_id || student_id) in application layer

**Table 3: `ppt_leave_applications`**
Columns: id (INT UNSIGNED PK), application_number (VARCHAR(30) NOT NULL UNIQUE — format: PPT-LV-YYYYXXXXXXXX), student_id (INT UNSIGNED NOT NULL FK→std_students), guardian_id (INT UNSIGNED NOT NULL FK→std_guardians), from_date (DATE NOT NULL — must be >= tomorrow), to_date (DATE NOT NULL — must be >= from_date), number_of_days (TINYINT UNSIGNED NOT NULL — computed excl. holidays), leave_type (ENUM('Sick','Family','Personal','Festival','Medical','Other') NOT NULL), reason (TEXT NOT NULL — min 20 chars enforced in FormRequest), supporting_doc_media_id (INT UNSIGNED NULL FK→sys_media), status (ENUM('Pending','Approved','Rejected','Withdrawn') DEFAULT 'Pending'), reviewed_by_user_id (INT UNSIGNED NULL FK→sys_users), reviewed_at (TIMESTAMP NULL), reviewer_notes (TEXT NULL), is_active (TINYINT(1) DEFAULT 1), created_by (BIGINT UNSIGNED NULL), created_at (TIMESTAMP NOT NULL), updated_at (TIMESTAMP NOT NULL), deleted_at (TIMESTAMP NULL)
Indexes: INDEX `idx_ppt_leave_student_status` (student_id, status)

**Table 4: `ppt_event_rsvps`**
Columns: id (INT UNSIGNED PK), event_id (INT UNSIGNED NOT NULL — FK to Event Engine event record), guardian_id (INT UNSIGNED NOT NULL FK→std_guardians), student_id (INT UNSIGNED NULL FK→std_students), rsvp_status (ENUM('Attending','Not_Attending','Maybe') NOT NULL DEFAULT 'Attending'), is_volunteer (TINYINT(1) DEFAULT 0), volunteer_role (VARCHAR(150) NULL), rsvp_notes (TEXT NULL), confirmed_at (TIMESTAMP NULL), reminder_sent_at (TIMESTAMP NULL), is_active (TINYINT(1) DEFAULT 1), created_by (BIGINT UNSIGNED NULL), created_at (TIMESTAMP NOT NULL), updated_at (TIMESTAMP NOT NULL)
Unique: `uq_ppt_rsvp_event_guardian` (event_id, guardian_id) — prevents duplicate RSVP (BR-PPT-016 volunteer capacity controlled by EventController)
Note: No deleted_at — RSVPs not soft-deleted; is_volunteer + volunteer_role = NULL when not volunteering

**Table 5: `ppt_document_requests`**
Columns: id (INT UNSIGNED PK), request_number (VARCHAR(30) NOT NULL UNIQUE — format: PPT-DR-YYYYXXXXXXXX), student_id (INT UNSIGNED NOT NULL FK→std_students), guardian_id (INT UNSIGNED NOT NULL FK→std_guardians), document_type (ENUM('TC','MarkSheet','Bonafide','Character','Migration','MedicalFitness','Other') NOT NULL), reason (TEXT NOT NULL), urgency (ENUM('Normal','Urgent') DEFAULT 'Normal'), status (ENUM('Pending','Processing','Ready','Completed','Rejected') DEFAULT 'Pending'), admin_notes (TEXT NULL), fee_required (DECIMAL(8,2) DEFAULT 0.00), fee_paid (TINYINT(1) DEFAULT 0), payment_reference (VARCHAR(100) NULL — Razorpay payment_id; UNIQUE nullable), fulfilled_media_id (INT UNSIGNED NULL FK→sys_media), fulfilled_at (TIMESTAMP NULL), is_active (TINYINT(1) DEFAULT 1), created_by (BIGINT UNSIGNED NULL), created_at (TIMESTAMP NOT NULL), updated_at (TIMESTAMP NOT NULL), deleted_at (TIMESTAMP NULL)
Note: UNIQUE on payment_reference (nullable) — use partial unique index in migration

**Table 6: `ppt_consent_form_responses`**
Columns: id (INT UNSIGNED PK), consent_form_id (INT UNSIGNED NOT NULL — FK to school's consent form record), student_id (INT UNSIGNED NOT NULL FK→std_students), guardian_id (INT UNSIGNED NOT NULL FK→std_guardians), response (ENUM('Signed','Declined') NOT NULL), decline_reason (TEXT NULL — required when response=Declined, enforced in FormRequest), signer_name (VARCHAR(150) NOT NULL), signed_ip (VARCHAR(45) NULL — IPv4/IPv6), signed_at (TIMESTAMP NOT NULL — immutable business timestamp), is_active (TINYINT(1) DEFAULT 1), created_by (BIGINT UNSIGNED NULL), created_at (TIMESTAMP NOT NULL), updated_at (TIMESTAMP NOT NULL)
Unique: `uq_ppt_consent_response` (consent_form_id, student_id, guardian_id) — prevents double-signing (BR-PPT-014)
Note: NO deleted_at — consent responses are IMMUTABLE after creation. Do not add softDeletes here.

---

#### Phase 2A Output
Generate:
1. **`PPT_DDL_v1.sql`** — Complete DDL for all 6 tables (CREATE TABLE statements)
2. **`PPT_Migration.php`** — Single Laravel migration file for all 6 tables (use `Schema::create()` for each)
3. **`PPT_TableSummary.md`** — Table summary: name, purpose, row count rationale, key constraints

---

### Phase 2B Task — Generate `PPT_DDL_Auth.md` Part 2: Custom Middleware

Generate the complete `parent.portal` middleware:

```php
namespace Modules\ParentPortal\app\Http\Middleware;

class EnsureParentPortalAccess
{
    public function handle(Request $request, Closure $next): Response
    {
        // Condition 1: Must be authenticated
        if (! auth()->check()) {
            return redirect()->route('ppt.login');
        }

        // Condition 2: Must be user_type = PARENT
        if (auth()->user()->user_type !== 'PARENT') {
            abort(404);  // 404 not 403 — prevents portal enumeration
        }

        // Condition 3: Must have a guardian record
        $guardian = auth()->user()->guardian;
        if (! $guardian) {
            abort(404);
        }

        // Condition 4: Must have at least 1 linked child with portal access
        $hasAccess = $guardian->studentGuardianJnts()
            ->where('can_access_parent_portal', 1)
            ->exists();
        if (! $hasAccess) {
            abort(404);
        }

        // Share guardian and allowed children with all views
        view()->share('currentGuardian', $guardian);
        view()->share('allowedChildren', $guardian->studentGuardianJnts()
            ->where('can_access_parent_portal', 1)
            ->with('student')
            ->get()
            ->pluck('student'));

        return $next($request);
    }
}
```

Also generate: middleware alias registration in `ParentPortalServiceProvider`:
```php
$router->aliasMiddleware('parent.portal', EnsureParentPortalAccess::class);
```

---

### Phase 2C Task — Generate `PPT_DDL_Auth.md` Part 3: Policies

Generate all 3 Policy classes with full code:

**1. ParentChildPolicy** — Full class:
```php
namespace Modules\ParentPortal\app\Policies;

class ParentChildPolicy
{
    public function viewChildData(User $user, Student $student): bool
    {
        return $user->guardian?->studentGuardianJnts()
            ->where('student_id', $student->id)
            ->where('can_access_parent_portal', 1)
            ->exists() ?? false;
    }

    public function isActiveChild(User $user, Student $student): bool
    {
        return $this->viewChildData($user, $student)
            && optional($user->guardian->activeSession)->active_student_id === $student->id;
    }

    public function viewHealthRecord(User $user, Student $student, $record): bool
    {
        return $this->viewChildData($user, $student)
            && (bool) data_get($record, 'parent_visible', false);
    }

    public function viewCounsellorReport(User $user): bool
    {
        return (bool) app('school_settings')->get('parent_counsellor_report_visibility', false);
    }

    public function payInvoice(User $user, Student $student, $invoice): bool
    {
        return $this->viewChildData($user, $student)
            && $invoice->student_id === $student->id
            && in_array($invoice->status, ['Unpaid', 'Partially Paid', 'Overdue'])
            && $invoice->balance_amount > 0;
    }
}
```

**2. ParentMessagePolicy** — Full class with `composeMessage()` + `viewThread()`
**3. ParentLeavePolicy** — Full class with `apply()` + `withdraw()`

Generate ServiceProvider registration:
```php
Gate::policy(Student::class, ParentChildPolicy::class);
```

---

### Phase 2D Task — Generate `PPT_DDL_Auth.md` Part 4: FormRequests

For each of the 9 FormRequest classes, generate full class code:

**1. `SwitchChildRequest`** (P0 — called on every child switch):
- `authorize()`: verify `$this->student_id` is in guardian's allowed children via `std_student_guardian_jnt` join
- `rules()`: student_id required + integer + exists:std_students,id

**2. `FeePaymentRequest`** (P0 — IDOR guard):
- `authorize()`: check FeeInvoice ownership — `fin_fee_invoices` must be reachable via guardian→active child chain
- `rules()`: invoice_id required + integer, amount numeric + min:0.01

**3. `ComposeMessageRequest`** (P1):
- Full class with MessagingService::getAllowedTeachers() call in `authorize()`
- `rules()` with max attachment sizes
- `prepareForValidation()`: strip_tags on message_body

**4. `ApplyLeaveRequest`** (P1):
- `authorize()`: viewChildData check
- `rules()` with `after:today` on from_date (must be >= tomorrow per BR-PPT-004)
- Custom `messages()` for student-facing error text

**5–9.** EventRsvpRequest, DocumentRequestForm, NotificationPreferencesRequest, ConsentFormSignRequest, PtmBookingRequest — Full classes with authorize() + rules()

For `ConsentFormSignRequest`:
```php
protected function prepareForValidation(): void
{
    // Sanitize signer_name — strip HTML tags
    $this->merge(['signer_name' => strip_tags($this->signer_name)]);
}
```

---

### Phase 2E Task — Generate `PPT_DDL_Auth.md` Part 5: Service Skeletons

For each of the 5 services, generate skeleton class with:
- Full namespace + class declaration
- Constructor dependencies (injected via Laravel container)
- All public method signatures with full docblocks
- Placeholder return statements (to be completed in implementation)

Special attention to `ParentDashboardService::getDashboardData()` — generate the consolidated eager-load pattern:
```php
$guardian->load([
    'studentGuardianJnts.student.academicSession.classSection.class',
    'studentGuardianJnts.student.academicSession.classSection.section',
]);
// Attendance, timetable, homework, fees loaded separately with Cache::tags(['parent', $guardian->id])->remember(300, ...)
```

For `FeePaymentService::verifyAndRecord()` — generate idempotency guard:
```php
// Idempotency: check payment_reference unique before creating fin_transaction
if (PptDocumentRequest::where('payment_reference', $razorpayPaymentId)->exists()) {
    return true; // Already processed — webhook replay
}
```

For `PtmSchedulingService::bookSlot()` — generate DB transaction pattern:
```php
return DB::transaction(function () use ($data) {
    $slot = PtmSlot::lockForUpdate()->findOrFail($data['slot_id']);
    abort_if($slot->is_booked, 409, 'Slot just taken; please choose another');
    // ... booking logic
});
```

---

### Phase 2 Output Files
| File | Location |
|---|---|
| `PPT_DDL_Auth.md` | `{OUTPUT_DIR}/PPT_DDL_Auth.md` |
| `PPT_DDL_v1.sql` | `{OUTPUT_DIR}/PPT_DDL_v1.sql` |
| `PPT_Migration.php` | `{OUTPUT_DIR}/PPT_Migration.php` |
| `PPT_TableSummary.md` | `{OUTPUT_DIR}/PPT_TableSummary.md` |

### Phase 2 Quality Gate
- [ ] All 6 ppt_* tables generated with complete CREATE TABLE DDL
- [ ] All PKs confirmed as `INT UNSIGNED AUTO_INCREMENT` (not BIGINT)
- [ ] sys_users FK type (INT vs BIGINT for sender_user_id/recipient_user_id) verified from TENANT_DDL and documented
- [ ] `ppt_consent_form_responses` has NO `deleted_at` — immutability documented explicitly
- [ ] `uq_ppt_session_guardian_device_fcm` UNIQUE (guardian_id, device_token_fcm) on ppt_parent_sessions
- [ ] `uq_ppt_rsvp_event_guardian` UNIQUE (event_id, guardian_id) on ppt_event_rsvps
- [ ] `uq_ppt_consent_response` UNIQUE (consent_form_id, student_id, guardian_id) on ppt_consent_form_responses
- [ ] `application_number` UNIQUE on ppt_leave_applications (format PPT-LV-YYYYXXXXXXXX)
- [ ] `request_number` UNIQUE on ppt_document_requests (format PPT-DR-YYYYXXXXXXXX)
- [ ] `payment_reference` partial UNIQUE (nullable) on ppt_document_requests — idempotency for Razorpay
- [ ] FULLTEXT index on ppt_messages (subject, message_body) for search (FR-PPT-04)
- [ ] Composite INDEX `idx_ppt_leave_student_status` (student_id, status) on ppt_leave_applications
- [ ] parent.portal middleware generated with three-condition check + 404 (not 401/403) on failure
- [ ] EnsureParentPortalAccess middleware alias registration code generated
- [ ] ParentChildPolicy generated with 5 methods (viewChildData, isActiveChild, viewHealthRecord, viewCounsellorReport, payInvoice)
- [ ] ParentMessagePolicy + ParentLeavePolicy generated with full method code
- [ ] ServiceProvider policy registration code generated
- [ ] All 9 FormRequest classes generated with full authorize() + rules() + prepareForValidation()
- [ ] SwitchChildRequest::authorize() performs allowed-children check (prevents child-swapping IDOR)
- [ ] FeePaymentRequest::authorize() performs invoice ownership check (P0 IDOR prevention)
- [ ] ConsentFormSignRequest includes strip_tags() in prepareForValidation()
- [ ] ApplyLeaveRequest uses `after:today` on from_date (BR-PPT-004: must be >= tomorrow)
- [ ] All 5 service skeletons generated with method signatures + docblocks
- [ ] ParentDashboardService eager-load chain documented (max 5 queries + cache tags)
- [ ] FeePaymentService idempotency guard pattern documented
- [ ] PtmSchedulingService DB::transaction() + lockForUpdate() race condition guard generated
- [ ] Laravel migration file uses `->unsignedInteger()` for ppt_* PKs and std_* FKs

**After Phase 2, STOP and say:**
"Phase 2 (DDL + Authorization Architecture Layer) complete. Outputs:
- `PPT_DDL_Auth.md` — Middleware + Policies + FormRequests + Service skeletons
- `PPT_DDL_v1.sql` — DDL for all 6 ppt_* tables
- `PPT_Migration.php` — Laravel migration
- `PPT_TableSummary.md` — Table summary
Please review and say 'Approved. Proceed to Phase 3' to continue."

---

## PHASE 3 — Complete Development Plan

### Phase 3 Input Files
1. `{OUTPUT_DIR}/PPT_FeatureSpec.md` — Screen inventory (Section 2), BR status (Section 4), FR list (Section 6), Service design (Section 8)
2. `{OUTPUT_DIR}/PPT_DDL_Auth.md` — Middleware, Policy, FormRequest, Service code
3. `{REQUIREMENT_FILE}` — Section 14 (SUG-PPT-01 to SUG-PPT-24 suggestions in priority order)
4. `{AI_BRAIN}/memory/modules-map.md` — Patterns from completed modules

### Phase 3 Task — Generate `PPT_Dev_Plan.md`

Generate the complete implementation blueprint. Organise into 8 sections:

---

#### Section 1 — Controller Inventory

List all 16 controllers to build:
| Controller Class | File Path | Methods | Depends On | Status |
|---|---|---|---|---|

All 16 controllers:
1. **AuthController** — OTP send, OTP verify, password login, logout, first-login password setup
2. **ParentPortalController** — dashboard, children list, switchChild
3. **AttendanceViewController** — index (monthly calendar), subjectWise
4. **TimetableViewController** — index, api
5. **HomeworkViewController** — index, show, api
6. **ResultViewController** — index, show, downloadReportCard, api
7. **FeeViewController** — index, show, pay, razorpayCallback, history, downloadReceipt, api, apiCallback
8. **MessageController** — index, thread, compose, store, reply, markRead, api, apiStore
9. **NotificationController** — index, show, markRead, markAllRead, preferences, savePreferences, api
10. **LeaveController** — index, create, store, show, destroy
11. **ConsentFormController** — index, show, sign
12. **PtmController** — index, slots, book, cancelBooking
13. **EventController** — index, show, rsvp, volunteerSignup, icsDownload, api
14. **HealthReportController** — index, show, download
15. **TransportViewController** — index
16. **DocumentController** — index, download, requestForm, storeRequest, trackRequest
17. **AccountSettingsController** — index, profile, changePassword, devices, logoutDevice, registerToken, removeToken

For each controller document:
- All routes it serves (method + URI + route name)
- Services it uses
- Policies it calls via `$this->authorize()`
- FormRequests it uses
- External module tables it reads
- Build complexity: Simple / Medium / Complex

For **AuthController** — special notes:
- OTP: generate 6-digit code, store hashed in cache with 10-min TTL
- Rate limiter: `RateLimiter::tooManyAttempts('otp-send:'.$mobile, 3)` per hour
- Lockout: after 5 consecutive OTP failures → `RateLimiter::hit('otp-lockout:'.$mobile, 1800)`
- First login: after OTP verify, check if `sys_users.password` is null → redirect to password setup

For **FeeViewController** — note Razorpay webhook:
- `razorpayCallback()` must be `->withoutMiddleware(['parent.portal'])` (public endpoint, no auth)
- `apiCallback()` same — public for Razorpay server-side call

#### Section 2 — Service Inventory (5 services)

For each service:
- Constructor dependencies
- All public methods with full signature, 1-line description, and which controller method(s) it is called from
- Database impact (which tables it reads/writes)
- Caching strategy (if applicable)

For **ParentDashboardService**:
- Performance note: max 5 queries for all dashboard widgets
- Cache: `Cache::tags(['parent', $guardianId])->remember(300, ...)` — tagged for targeted invalidation
- Cache invalidation triggers: fee payment (invalidate 'parent'), leave status change, new message

For **FeePaymentService**:
- Note that `razorpayCallback()` and `apiCallback()` share the same `verifyAndRecord()` service method
- idempotency guard must be checked BEFORE any database write

For **PtmSchedulingService**:
- Race condition handling: DB::transaction + `SELECT...FOR UPDATE` on slot record
- Confirm with concurrent booking test (T-18 in req Section 12)

#### Section 3 — FormRequest Inventory (9 FormRequests)

For each FormRequest:
| Class | Controller@Method | authorize() Logic | Key Rules | Phase |
|---|---|---|---|---|

Reference Phase 2D code; add notes on which inline validation logic in controllers each FormRequest replaces.

#### Section 4 — Blade View Inventory (~45 views to build)

For each screen, list:
- Screen ID (SCR-PPT-xx)
- Proposed view file path under `parentportal::` namespace
- Layout: `parentportal::components.layouts.master`
- Component dependencies (child switcher widget, unread badge component, etc.)
- Data variables passed from controller
- Build complexity

**Shared components to build (not per-screen — build once in P0):**
- `parentportal::components.layouts.master` — base layout with header, child switcher, nav
- `parentportal::components.child-switcher` — dropdown showing all linked children; POST to switch
- `parentportal::components.unread-badge` — notification count badge in nav
- `parentportal::components.fee-status-chip` — coloured chip (green=Paid, orange=Due, red=Overdue)
- `parentportal::components.module-unavailable` — graceful "module not activated" card component

**Mobile-first notes** (from req Section 10):
- All views: Bootstrap 5 or Tailwind responsive
- All touch targets: ≥ 44px height
- Child switcher: fixed top navigation bar (SUG-PPT-09)
- Dashboard "Action required" section: unpaid fees, unsigned consent forms, pending leaves (SUG-PPT-10)

#### Section 5 — Complete Route List

**Web Routes (~75 routes — all under `parent-portal/` prefix, `ppt.*` name prefix, `parent.portal` middleware):**

Consolidate all routes from req Section 6.1 into a table:
| Method | URI | Route Name | Controller@method | Middleware Override | Notes |
|---|---|---|---|---|---|

Special middleware notes:
- `POST /parent-portal/fees/razorpay-callback` → `->withoutMiddleware(['parent.portal'])` (public webhook)
- `POST /parent-portal/auth/otp/send` → `->middleware('throttle:3,1')` (rate limit OTP sends)
- `POST /parent-portal/fees/pay` → `->middleware('throttle:3,5')` (rate limit payment initiation)
- `POST /parent-portal/children/switch` → Add EnsureTenantHasModule:ParentPortal

**API Routes (~18 routes — under `/api/v1/parent/` prefix, `auth:sanctum` + `parent.portal` middleware):**

From req Section 6.2:
- All 18 API endpoints listed from requirement
- Plus: `POST /api/v1/parent/otp/send` and `POST /api/v1/parent/otp/verify` — NO auth middleware (pre-auth endpoints)
- Plus: `POST /api/v1/parent/fees/razorpay-callback` — NO auth middleware (public webhook)

Add planned middleware stack to all routes:
- `EnsureTenantHasModule:ParentPortal` on all routes
- `parent.portal` on all routes except webhook + OTP endpoints
- `throttle:60,1` per-guardian API rate limit (SUG-PPT-22)

#### Section 6 — Implementation Phases (4 priority phases)

**Phase P0 — Foundation: Auth + Middleware + Core Authorization (2 person-days — must deploy first)**
No features can be built safely without this foundation.
Files to create:
- `app/Http/Middleware/EnsureParentPortalAccess.php` — custom `parent.portal` middleware
- `app/Policies/ParentChildPolicy.php` — core IDOR guard
- `app/Policies/ParentMessagePolicy.php`
- `app/Policies/ParentLeavePolicy.php`
- `app/Http/Controllers/AuthController.php` — OTP send/verify, login, logout
- `app/Http/Requests/SwitchChildRequest.php`
- `app/Http/Requests/FeePaymentRequest.php`
- `app/Providers/ParentPortalServiceProvider.php` — register middleware alias + policies
- Routes: auth routes (ppt.login, ppt.otp.verify, ppt.logout) + base structure
- Blade: `master.blade.php`, `components/child-switcher.blade.php`, `auth/login.blade.php`, `auth/otp.blade.php`
- Database migration: all 6 ppt_* tables (`PPT_Migration.php`)
- Seeds: No PPT-owned seeds (data comes from STD module)
- Tests: T-01 (ParentAuthTest), T-02 (OtpRateLimitTest), T-03 (ParentChildAccessTest), T-04 (FeePaymentAuthTest), T-05 (FeePaymentIdempotencyTest), T-06 (SwitchChildTest)

**Phase P1 — Core Portal Features (5 person-days)**
FRs addressed: FR-PPT-01 (dashboard), FR-PPT-06 (attendance), FR-PPT-08 (timetable), FR-PPT-07 (homework), FR-PPT-09 (results), FR-PPT-05 (fee management)
Files to create:
- `app/Services/ParentDashboardService.php`
- `app/Services/FeePaymentService.php`
- `app/Http/Controllers/ParentPortalController.php` — dashboard, children, switchChild
- `app/Http/Controllers/AttendanceViewController.php`
- `app/Http/Controllers/TimetableViewController.php`
- `app/Http/Controllers/HomeworkViewController.php`
- `app/Http/Controllers/ResultViewController.php`
- `app/Http/Controllers/FeeViewController.php`
- `app/Http/Requests/FeePaymentRequest.php`
- Blade views: dashboard, children, attendance calendar, subject-wise attendance, timetable, homework list/detail, results list/detail, report card download, fee summary, payment pages (4 screens: checkout, success, history, receipt)
- Tests: T-07 to T-16 (messaging restriction, fee scenarios, report card gate)

**Phase P2 — Communication + Requests (5 person-days)**
FRs addressed: FR-PPT-04 (messaging), FR-PPT-10 (leave), FR-PPT-11 (consent forms), FR-PPT-12 (PTM), FR-PPT-03 (notification preferences), FR-PPT-17 (notification inbox), FR-PPT-18 (account settings)
Files to create:
- `app/Services/MessagingService.php`
- `app/Services/NotificationPreferenceService.php`
- `app/Services/PtmSchedulingService.php`
- `app/Http/Controllers/MessageController.php`
- `app/Http/Controllers/NotificationController.php`
- `app/Http/Controllers/LeaveController.php`
- `app/Http/Controllers/ConsentFormController.php`
- `app/Http/Controllers/PtmController.php`
- `app/Http/Controllers/AccountSettingsController.php`
- All corresponding FormRequests (ComposeMessageRequest, ApplyLeaveRequest, NotificationPreferencesRequest, ConsentFormSignRequest, PtmBookingRequest)
- Blade views: all messaging, notification, leave, consent form, PTM, account settings screens
- Leave approval event dispatch → attendance module: `event(new LeaveApproved($leaveApplication))` (BR-PPT-017)
- Tests: T-07 through T-24

**Phase P3 — Extended Features + REST API (4 person-days)**
FRs addressed: FR-PPT-13 (events), FR-PPT-14 (health), FR-PPT-15 (transport), FR-PPT-16 (documents), FR-PPT-02 (OTP API), REST API for mobile/PWA
Files to create:
- `app/Http/Controllers/EventController.php` — RSVP, volunteer, .ics download
- `app/Http/Controllers/HealthReportController.php` — health, physical assessment, counsellor reports
- `app/Http/Controllers/TransportViewController.php` — route info, GPS status
- `app/Http/Controllers/DocumentController.php` — document vault, requests, tracking
- `app/Http/Requests/DocumentRequestForm.php`, `EventRsvpRequest.php`
- All API endpoints in `routes/api.php` — 18 endpoints from req Section 6.2
- PWA service worker for offline caching (SUG-PPT-08)
- Push notification registration (FCM/APNs via AccountSettingsController)
- Tests: T-25 through T-33

#### Section 7 — Seeder Execution Order

PPT tables that need seeders:
```
None — ppt_* tables are portal state tables; no seed data required.
```

Test data requirements per phase:
```
Phase P0 tests require:
  - 2 parent users (ParentA + ParentB) with user_type=PARENT
  - std_guardians records for each
  - std_students records for each parent's children
  - std_student_guardian_jnt: ParentA→StudentA (can_access_parent_portal=1),
    ParentB→StudentB (can_access_parent_portal=1)
  - ParentA has ZERO access to StudentB (IDOR test)
  - fin_fee_invoices for StudentA (linked via student_id)
  - Active sys_school_settings record for tenant

Phase P1 tests require:
  - Academic sessions for each student
  - std_attendance records (for calendar rendering)
  - hmw_assignments for student's class/section
  - exm_results for student
  - fin_fee_invoices: Unpaid, PartiallyPaid, Overdue states tested

Phase P2 tests require:
  - Teachers who teach StudentA's class (for messaging allowed-teacher list)
  - timetable assignments linking teachers to StudentA's class
  - sys_activity_logs table available (for audit logging tests)
  - Consent form records in event/activity module (for consent form tests)

Phase P3 tests require:
  - hpc_health_profiles with parent_visible=0 and parent_visible=1 records
  - hpc_counsellor_reports with school setting enabled/disabled
  - tpt_routes + tpt_student_route_jnt for transport tests
  - Event engine records for RSVP tests
```

#### Section 8 — Testing Strategy

**Framework:** Pest for Feature tests; PHPUnit for Unit tests.

**Feature Test Setup:**
```php
uses(Tests\TestCase::class, RefreshDatabase::class);
// ParentA factory: user (user_type=PARENT) + std_guardians + std_student_guardian_jnt (can_access_parent_portal=1) → StudentA
// ParentB factory: user (user_type=PARENT) + std_guardians + std_student_guardian_jnt → StudentB
// IDOR tests: ParentA attempts to access StudentB's data → 403 or 404
// Student user: user without PARENT type → portal returns 404
// Admin user: user without PARENT type → portal returns 404
// FeePaymentService: bind mock via app()->bind(FeePaymentService::class, MockFeePaymentService::class)
// Queue::fake() for notification dispatch
// Event::fake() for leave approval event dispatch
// Mail::fake() for receipt emails
// OTP: mock SMS gateway; inject known OTP via cache (Redis::shouldReceive('setex'))
```

**P0 Security Test Patterns:**
```
IDOR test pattern (ParentChildPolicy):
  $parentA = ParentUser::factory()->withChild($studentA)->create();
  $parentB = ParentUser::factory()->withChild($studentB)->create();
  $invoice = FeeInvoice::factory()->for($studentB)->create();
  $this->actingAs($parentA)
       ->post(route('ppt.fees.pay'), ['invoice_id' => $invoice->id, ...])
       ->assertForbidden();  // ParentChildPolicy blocks access

Child switch IDOR test:
  $this->actingAs($parentA)
       ->post(route('ppt.children.switch'), ['student_id' => $studentB->id])
       ->assertForbidden();  // SwitchChildRequest::authorize() blocks non-owned student
```

**Minimum Coverage Targets:**
- All P0 tests (T-01 to T-06) MUST pass before any P1 work proceeds
- IDOR: ParentA cannot access StudentB's data under any circumstance
- parent.portal middleware: STUDENT/STAFF/ADMIN user types return 404 (not 403)
- parent.portal middleware: parent with can_access_parent_portal=0 returns 404
- OTP rate limiting: 4th OTP request within 1 hour → blocked
- Fee payment idempotency: webhook replay with same payment_id → no duplicate transaction
- Consent form: signing twice for same form+student+guardian → unique constraint error (not 500)
- PTM booking: two parents simultaneously book same slot → only one succeeds (DB transaction test)
- Counsellor report: school setting = 0 → hidden; setting = 1 → visible
- All module-unavailable states: transport/homework/timetable disabled → graceful message, no 500

---

### Phase 3 Output Files
| File | Location |
|---|---|
| `PPT_Dev_Plan.md` | `{OUTPUT_DIR}/PPT_Dev_Plan.md` |

### Phase 3 Quality Gate
- [ ] All 16 controllers listed with all methods + services used + policies called
- [ ] All 5 services listed with all method signatures and which controller methods they serve
- [ ] ParentDashboardService documented: max 5 queries + Cache::tags() strategy
- [ ] All 9 FormRequests listed with authorize() logic and key validation rules
- [ ] All 4 implementation phases have: files to create, FRs covered, test scenarios
- [ ] P0 phase is deployable in isolation — auth + middleware + policies + DDL migration only
- [ ] P0 phase: parent.portal middleware creation explicitly listed as first deliverable
- [ ] P0 IDOR: ParentChildPolicy enforced on EVERY controller method (documented per controller)
- [ ] Leave approval event dispatch (BR-PPT-017) explicitly in P2 phase with event class design
- [ ] Razorpay webhook route: `->withoutMiddleware(['parent.portal'])` documented for both web + API routes
- [ ] OTP endpoints: `otp/send` and `otp/verify` excluded from `parent.portal` middleware (pre-auth)
- [ ] Race condition handling for PTM booking (DB::transaction + lockForUpdate) documented in P2
- [ ] Signed URL pattern (24-hour expiry via Storage::temporaryUrl()) documented in P3 for document downloads
- [ ] Counsellor report gate check (sys_school_settings lookup) documented in P3 HealthReportController
- [ ] All 38 screens assigned to a phase (P0 auth screens, P1 academic/fee, P2 messaging/requests, P3 health/transport/events)
- [ ] All 24 suggestions (SUG-PPT-01 to SUG-PPT-24) assigned to a phase or backlog
- [ ] Test data requirements documented per phase (no PPT seeders — data comes from other modules)
- [ ] IDOR test pattern (ParentA vs ParentB + cross-child resource access) documented in Section 8
- [ ] parent.portal middleware test (non-PARENT user → 404) documented in Section 8
- [ ] Route count totals documented (~75 web + ~18 API = ~93 total after completion)
- [ ] Mobile-first shared components (master layout, child-switcher, unread-badge, fee-status-chip, module-unavailable) explicitly listed as P0 build items
- [ ] Concurrent PTM booking test (T-18) pattern documented (race condition simulation)

**After Phase 3, STOP and say:**
"Phase 3 (Development Plan) complete. Output: `PPT_Dev_Plan.md`. All 3 output files are ready:
1. `{OUTPUT_DIR}/PPT_FeatureSpec.md` — Full feature spec + architecture blueprint (38 screens, 18 FRs, 18 BRs)
2. `{OUTPUT_DIR}/PPT_DDL_Auth.md` — DDL (6 tables) + Middleware + Policies + FormRequests + Service skeletons
3. `{OUTPUT_DIR}/PPT_Dev_Plan.md` — P0 → P1 → P2 → P3 implementation plan
ParentPortal development plan is ready. Build P0 (auth + middleware + ParentChildPolicy + DDL migration) before any feature work begins."

---

## QUICK REFERENCE — PPT Module Controllers vs Services vs Views

| Area | Controller(s) | Service | Key Tables Written | External Tables Read | Status |
|---|---|---|---|---|---|
| Auth (OTP) | AuthController@sendOtp, verifyOtp, login, logout | — | ppt_parent_sessions | sys_users, std_guardians, std_student_guardian_jnt | 🆕 Build P0 |
| Dashboard | ParentPortalController@dashboard | ParentDashboardService@getDashboardData | — | std_students, std_attendance, tt_timetable_cells, hmw_assignments, fin_fee_invoices, ntf_notifications | 🆕 Build P1 |
| Child Switcher | ParentPortalController@switchChild | — | ppt_parent_sessions.active_student_id | std_student_guardian_jnt | 🆕 Build P0 |
| Attendance | AttendanceViewController | — | — | std_attendance, std_subject_attendance | 🆕 Build P1 |
| Timetable | TimetableViewController | — | — | tt_timetable_cells, tt_published_timetables | 🆕 Build P1 |
| Homework | HomeworkViewController | — | — | hmw_assignments, hmw_submissions | 🆕 Build P1 |
| Results | ResultViewController | — | — | exm_results, exm_report_cards | 🆕 Build P1 |
| Fee / Payment | FeeViewController | FeePaymentService | fin_transactions | fin_fee_invoices, fin_fee_installments | 🆕 Build P1 — **IDOR P0** |
| Messaging | MessageController | MessagingService | ppt_messages | sys_users (teachers), tt_timetable_cells | 🆕 Build P2 |
| Notifications | NotificationController | NotificationPreferenceService | ppt_parent_sessions (prefs) | ntf_notifications, ntf_circulars | 🆕 Build P2 |
| Leave | LeaveController | — | ppt_leave_applications | std_students, sys_media | 🆕 Build P2 |
| Consent Forms | ConsentFormController | — | ppt_consent_form_responses | Event/Activity consent form records | 🆕 Build P2 |
| PTM | PtmController | PtmSchedulingService | PTM booking records | PTM event module tables | 🆕 Build P2 |
| Events | EventController | — | ppt_event_rsvps | Event engine event records | 🆕 Build P3 |
| Health | HealthReportController | — | — | hpc_health_profiles, hpc_physical_assessments, hpc_counsellor_reports | 🆕 Build P3 — **gated** |
| Transport | TransportViewController | — | — | tpt_routes, tpt_vehicles, tpt_student_route_jnt | 🆕 Build P3 |
| Documents | DocumentController | — | ppt_document_requests | sys_media | 🆕 Build P3 |
| Settings | AccountSettingsController | — | ppt_parent_sessions (device tokens) | sys_users | 🆕 Build P3 |
| REST API | All above @api methods | All services | Same as web | Same as web | 🆕 Build P3 |

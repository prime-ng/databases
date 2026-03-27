# VSM — Visitor & Security Management Module Development Lifecycle Prompt (v1)

**Purpose:** Consolidated prompt to build 3 output files for the **VSM (VisitorSecurity)** module using `VSM_VisitorSecurity_Requirement.md` as the single source of truth. Execute phases sequentially; Claude stops after each for your review.

**Output Files:**
1. `VSM_FeatureSpec.md` — Feature Specification
2. `VSM_DDL_v1.sql` + Migration + Seeders — Database Schema Design
3. `VSM_Dev_Plan.md` — Complete Development Plan

**Developer:** Brijesh
**Module:** Visitor & Security Management — Complete gate security and visitor lifecycle management for Indian K-12 schools.
Tables: `vsm_*` (13 tables across visitor management, gate passes, contractors, blacklist, guard shifts, patrol, emergency).

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
MODULE_CODE       = VSM
MODULE            = VisitorSecurity
MODULE_DIR        = Modules/VisitorSecurity/
BRANCH            = Brijesh_Main
RBS_MODULE_CODE   = X                              # Visitor & Security in RBS v4.0
DB_TABLE_PREFIX   = vsm_                           # Single prefix — all tables
DATABASE_NAME     = tenant_db

OUTPUT_DIR        = {OLD_REPO}/5-Work-In-Progress/VisitorSecurity/2-Claude_Plan
MIGRATION_DIR     = {LARAVEL_REPO}/database/migrations/tenant
TENANT_DDL        = {DB_REPO}/1-Master_DDLs/tenant_db_v2.sql
REQUIREMENT_FILE  = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V2/VSM_VisitorSecurity_Requirement.md

FEATURE_FILE      = VSM_FeatureSpec.md
DDL_FILE_NAME     = VSM_DDL_v1.sql
DEV_PLAN_FILE     = VSM_Dev_Plan.md
```

---

## HOW TO USE THIS PROMPT

1. Paste this entire document into a new Claude conversation
2. Say: **"Start Phase 1"**
3. Claude reads the required files, generates output, and **STOPS**
4. Review the output; give feedback or say: **"Approved. Proceed to Phase 2"**
5. Repeat for Phase 3

---

## KEY CONTEXT — VSM (VISITOR & SECURITY) MODULE

### What This Module Does

The VSM module provides a **complete gate security and visitor lifecycle management system** for Indian K-12 schools on the Prime-AI SaaS platform. It digitises the entire visitor lifecycle — from pre-registration and walk-in registration through QR code gate pass issuance, check-in/check-out logging, host notifications, blacklist enforcement, student pickup authorisation, contractor/vendor access management, guard shift scheduling, security patrol rounds, and emergency lockdown broadcasts.

**Visitor Management:**
- Pre-registration by host staff: visitor receives QR gate pass via SMS/email before arriving
- Walk-in registration at reception: photo + ID proof captured to sys_media
- Repeat visitor detection: auto-match by mobile_no; auto-fill known fields; "Returning visitor" badge
- Blacklist check on every registration: match by mobile_no OR id_number; block with alert

**Gate Operations:**
- QR scan check-in: decode pass_token → validate → set checkin_time → notify host
- QR scan check-out: record checkout_time, calculate duration_minutes
- Overdue flagging: scheduler every 15 min flags visits where checkin_time + expected_duration_minutes < NOW() AND status=Checked_In
- Printable DomPDF visitor badge: photo, name, purpose, host, valid until

**Real-time Dashboard:**
- Live visitor count (status=Checked_In), overdue alerts, today's total, blacklist hits, recent check-ins
- Auto-refresh every 60 seconds (start with polling; SSE upgrade when scale demands)
- Lockdown banner when vsm_emergency_events.is_lockdown_active=true

**Security Operations:**
- Emergency alert system: one-click broadcast to ALL active sys_users via SMS + in-app push simultaneously
- Lockdown mode: is_lockdown_active=true disables gate pass generation; check-in blocked without admin override
- Student pickup authorisation: verified against std_student guardian list; unauthorised pickup requires supervisor override
- Contractor/vendor access: work order, allowed zones, date-range pass, entry_days_json, auto-expiry

**Guard Management:**
- Guard shift scheduling: no overlap constraint; auto-set Late (>15 min) / Early_Departure
- Patrol rounds: guard scans checkpoint QR codes → completion % = (scanned/total)×100; < 80% → Incomplete

### Architecture Decisions
- **Single Laravel module** (`Modules\VisitorSecurity`) — all 8 controllers in one module
- Stancl/tenancy v3.9 — dedicated DB per tenant — **NO `tenant_id` column** on any table
- Route prefix: `visitor-security/` | Route name prefix: `vsm.`
- Middleware on all routes: `['auth', 'tenant', 'EnsureTenantHasModule:VisitorSecurity']`
- Gate pass token: `Str::uuid()` — UUID v4, never sequential; expires at end of expected_date OR 24h, whichever earlier
- QR generation: `SimpleSoftwareIO/simple-qrcode`; QR embedded in SMS as hosted URL `/visitor-security/gate-passes/{pass_token}/scan`
- Badge printing: DomPDF PDF badge; browser `print()` triggered automatically
- Visitor photos + ID proof: stored in `sys_media` with `model_type=vsm_visitors`; private disk; serve via signed URL
- Check-in concurrency: `DB::transaction()` + `lockForUpdate()` prevents duplicate check-in race (BR-VSM-003)
- Notification integration: VSM dispatches via Notification module (NTF) — never SMS gateway directly
- Emergency broadcast: dedicated queue channel; bypasses rate limiting
- Timezone: overdue scheduler uses school timezone from sys_school_settings via `Carbon::setTimezone()`
- Audit: all check-in, check-out, blacklist-hit, emergency events written to `sys_activity_logs`
- 4 scheduled Artisan jobs registered in `routes/console.php`

### Module Scale (v2)
| Artifact | Count |
|---|---|
| Controllers | 8 (web) + 1 API controller |
| Models | 13 |
| Services | 4 |
| FormRequests | 10 |
| Policies | 8 |
| vsm_* tables | 13 |
| Blade views (estimated) | ~32 |
| Scheduled Jobs | 4 |
| Web routes | ~70 |
| API routes | 12 |

### Complete Table Inventory

**Visitor Core (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 1 | `vsm_visitors` | Master visitor profile | UNIQUE `(mobile_no)` conceptually — match key; INDEX on mobile_no, id_number |
| 2 | `vsm_visits` | Per-visit record with status FSM | UNIQUE `(visit_number)`; INDEX on (expected_date, status), visitor_id, host_user_id, checkin_time |
| 3 | `vsm_gate_passes` | QR pass token per visit | UNIQUE `(visit_id)` (one per visit); UNIQUE `(pass_token)`; INDEX expires_at |

**Access Control (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 4 | `vsm_contractors` | Multi-day contractor access | UNIQUE `(pass_token)`; INDEX on mobile_no, (access_from, access_until), pass_status |
| 5 | `vsm_pickup_auth` | Student pickup authorisation log | INDEX on student_id, visit_id |
| 6 | `vsm_blacklist` | Blacklisted persons | INDEX on mobile_no, id_number |

**Guard Ops (4 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 7 | `vsm_guard_shifts` | Guard shift schedules + attendance | UNIQUE `(guard_user_id, shift_date, shift_start_time)` |
| 8 | `vsm_patrol_checkpoints` | Campus checkpoint definitions | UNIQUE `(qr_token)` |
| 9 | `vsm_patrol_rounds` | Per-patrol summary | INDEX on guard_user_id |
| 10 | `vsm_patrol_checkpoint_log` | Per-checkpoint scan within a round | INDEX on patrol_round_id, checkpoint_id |

**Emergency (2 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 11 | `vsm_emergency_protocols` | SOP templates per emergency type | INDEX on protocol_type |
| 12 | `vsm_emergency_events` | Active emergency events log | INDEX on is_lockdown_active, triggered_at |

**CCTV Integration (1 table):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 13 | `vsm_cctv_events` | Inbound webhook events from CCTV systems | INDEX on (camera_id, event_timestamp) |

**External Tables REFERENCED (VSM reads; never modifies schema):**
| Table | Source | VSM Usage |
|---|---|---|
| `std_students` | StudentProfile (STD) | Pickup authorisation: student lookup |
| `std_guardians` / guardian JNT | StudentProfile (STD) | Pickup auth: verify authorised guardian list |
| `sys_users` | System | Guard assignments, host lookups, emergency broadcast recipients |
| `sys_media` | System | Visitor photos, ID proofs, checkpoint QR images, SOP documents |
| `sys_school_settings` | System | School timezone, data retention policy |
| `sys_activity_logs` | System | Audit trail (write-only) |
| `ntf_notifications` | Notification (NTF) | Dispatch host alerts, emergency broadcasts, QR pass SMS |

### Visitor Lifecycle Core FSM
```
VISITOR REGISTRATION:
vsm_visitors (upsert by mobile_no)
    └── vsm_visits (status: Pre_Registered | Registered)
         └── vsm_gate_passes (pass_token: UUID v4, status: Issued)
              │
              ├── Check-in: status=Checked_In, pass=Used, host notified
              │    └── is_overdue=true (if duration exceeded — scheduler job)
              └── Check-out: status=Checked_Out, duration_minutes calculated
```

---

## PHASE 1 — Feature Specification

### Phase 1 Input Files
Read ALL these files in order before generating any output:

1. `{REQUIREMENT_FILE}` — **Primary and complete source** — VSM v2 requirement (14 FRs, Sections 1–16)
2. `{AI_BRAIN}/memory/project-context.md` — Project context and existing module list
3. `{AI_BRAIN}/memory/modules-map.md` — Existing module inventory (avoid duplication, check STD guardian tables)
4. `{AI_BRAIN}/agents/business-analyst.md` — BA agent instructions (read if file exists)
5. `{TENANT_DDL}` — Verify actual column names for: std_students, std_guardians, std_student_guardian_jnt, sys_users, sys_media (use exact column names when specifying cross-module FKs)

### Phase 1 Task — Generate `VSM_FeatureSpec.md`

Generate a comprehensive feature specification document. Organise it into these 11 sections:

---

#### Section 1 — Module Identity & Scope
- Module code, namespace (`Modules\VisitorSecurity`), route prefix (`visitor-security/`), route name prefix (`vsm.`), DB prefix (`vsm_`), module type
- In-scope features (from req v2 Section 2.3 menu structure):
  - Visitor Management: pre-registration, walk-in, pickup auth, blacklist, repeat visitor detection
  - Gate Operations: check-in/check-out, QR gate passes, overdue flagging, badge printing
  - Contractor Access: time-bound multi-day access management
  - Guard Management: shift scheduling + attendance, patrol rounds + checkpoint QR logging
  - Emergency System: lockdown broadcast, headcount initiation, protocol management
  - Dashboard: live campus occupancy, overdue alerts, real-time stats
  - Reports: visitor log, frequent visitors, guard attendance, blacklist hits, overdue incidents, contractor log
  - CCTV Hooks: webhook ingestion layer (hardware integration out of scope)
- Out-of-scope: student attendance marking (STD module); student profile management (STD module); HR payroll for guards (HRS module); CCTV hardware integration (only webhook ingestion in scope); PPT parent portal pre-registration (optional integration)
- Module scale table (controller / model / service / FormRequest / policy / table counts — current: 0, target: all)

#### Section 2 — Entity Inventory (All 13 Tables)
For each `vsm_*` table, provide:
- Table name, short description (one line)
- Full column list: column name | data type | nullable | default | constraints | comment
- Unique constraints and unique key names
- Indexes (ALL FK columns must have KEY entries, plus frequently filtered columns)
- Cross-module FK references clearly noted

Group tables by domain:
- **Visitor Core** (vsm_visitors, vsm_visits, vsm_gate_passes)
- **Access Control** (vsm_contractors, vsm_pickup_auth, vsm_blacklist)
- **Guard Operations** (vsm_guard_shifts, vsm_patrol_checkpoints, vsm_patrol_rounds, vsm_patrol_checkpoint_log)
- **Emergency Management** (vsm_emergency_protocols, vsm_emergency_events)
- **CCTV Integration** (vsm_cctv_events)

For `vsm_visits`, document all 6 status values: Pre_Registered, Registered, Checked_In, Checked_Out, No_Show, Cancelled
For `vsm_gate_passes`, document all 4 status values: Issued, Used, Expired, Revoked
For `vsm_guard_shifts.attendance_status`, document all 5 values: Scheduled, Present, Absent, Late, Early_Departure
For `vsm_patrol_rounds.status`, document all 3 values: In_Progress, Completed, Incomplete
For `vsm_emergency_events.is_lockdown_active`, document the lockdown gate-pass-block behaviour

Critical columns to highlight:
- `vsm_visits.blacklist_hit TINYINT(1)` — set on check if mobile/id matches vsm_blacklist at registration time
- `vsm_visits.is_overdue TINYINT(1)` — set by FlagOverdueVisitorsJob every 15 min (BR-VSM-004)
- `vsm_gate_passes.pass_token VARCHAR(100) NOT NULL UNIQUE` — UUID v4; never sequential
- `vsm_gate_passes.expires_at TIMESTAMP NOT NULL` — server-side only comparison; NOT client-enforced
- `vsm_contractors.allowed_zones_json JSON` — array of zone names
- `vsm_contractors.entry_days_json JSON` — e.g. ["Mon","Tue","Wed"] (BR-VSM-012)
- `vsm_contractors.pass_token VARCHAR(100) NOT NULL UNIQUE` — reusable within date range (different from visitor single-use)
- `vsm_patrol_checkpoint_log.scanned_at TIMESTAMP NOT NULL` — immutable scan timestamp
- `vsm_emergency_events.is_lockdown_active TINYINT(1)` — blocks gate pass generation when true
- `vsm_emergency_events.notification_count INT UNSIGNED` — count of staff notified

#### Section 3 — Entity Relationship Diagram (text-based)
Show all 13 tables grouped by domain. Use `→` for FK direction (child → parent).

Core relationship chain:
```
vsm_visitors ──1:N── vsm_visits ──1:1── vsm_gate_passes
                          │
               host_user_id ──→ sys_users
                          │
               checkin_photo_media_id ──→ sys_media
                          │
                    vsm_pickup_auth ──→ std_students

vsm_contractors  (standalone, own pass_token)

vsm_blacklist  (checked against vsm_visitors.mobile_no / id_number on every registration)

vsm_guard_shifts ──→ sys_users (guard_user_id)
        │
vsm_patrol_rounds ──1:N── vsm_patrol_checkpoint_log ──→ vsm_patrol_checkpoints
vsm_patrol_rounds ──→ vsm_guard_shifts (nullable)

vsm_emergency_protocols (SOP templates)
vsm_emergency_events ──→ vsm_emergency_protocols (nullable)
                       ──→ sys_users (triggered_by)

vsm_cctv_events ──→ vsm_visits (linked_visit_id — nullable, auto-linked if gate camera)
```

Cross-module FK references to highlight:
- `vsm_visits.host_user_id → sys_users.id` — nullable (walk-in may have no host)
- `vsm_pickup_auth.student_id → std_students.id` — mandatory for pickup auth records
- `vsm_pickup_auth.override_by → sys_users.id` — nullable (only set when supervisor overrides)
- All `created_by` columns → `sys_users.id`
- `sys_media` — VSM writes photos to sys_media; not a FK column, but a polymorphic relationship

#### Section 4 — Business Rules (15 rules)
For each rule, state:
- Rule ID (BR-VSM-001 to BR-VSM-015)
- Rule text (from req v2 Section 8)
- Which table/column it enforces
- Enforcement point: `service_layer` | `db_constraint` | `form_validation` | `model_event` | `scheduled_job`

Critical rules to emphasise:
- BR-VSM-001: Blacklist check mandatory on EVERY registration — match mobile_no OR id_number → block + alert
- BR-VSM-002: Gate pass token = UUID v4; expires at end of expected_date OR 24h, whichever earlier; server-side only
- BR-VSM-003: Only one active (status=Checked_In) visit per visitor at a time — supervisor override required for second
- BR-VSM-004: Overdue flagging by scheduler every 15 min: checkin_time + expected_duration_minutes < NOW() AND status=Checked_In
- BR-VSM-005: Emergency broadcast → ALL active sys_users (staff AND teachers) via SMS + in-app push simultaneously
- BR-VSM-006: Patrol completion = (checkpoints_completed / checkpoints_total) × 100; < 80% → status=Incomplete
- BR-VSM-007: Guard attendance auto-set — Late if actual_start_time > shift_start_time + 15 min; Early_Departure if actual_end_time < shift_end_time - 15 min
- BR-VSM-010: is_lockdown_active=true → gate pass generation disabled; check-in requires admin override
- BR-VSM-011: Unauthorised student pickup requires supervisor override with override_reason and supervisor ID
- BR-VSM-012: Contractor pass valid only within access_from to access_until AND only on days in entry_days_json
- BR-VSM-013: vsm_visitors.visit_count incremented on each check-in (status transitions to Checked_In)

#### Section 5 — Workflow State Machines (5 FSMs)
For each FSM, provide:
- State diagram (ASCII/text format)
- Valid transitions with trigger condition
- Pre-conditions (checked before transition allowed)
- Side effects (DB writes, events fired, notifications)

FSMs to document:

1. **Visitor Visit Lifecycle** (BR-VSM-003, FR-VSM-01 to FR-VSM-04):
   ```
   [Pre_Registered] ──(check-in scan)──► [Checked_In]
         │                                    │
   (no-show: expected_date passed)      (overdue: duration exceeded)
         ▼                                    ▼
     [No_Show]                         [is_overdue=true] ──(check-out)──► [Checked_Out]
                                             │
   [Registered] ──(check-in scan)──► [Checked_In]
         │
   (admin/host cancels)
         ▼
     [Cancelled]
   ```
   Side effects on Checked_In: set checkin_time=NOW(); pass status=Used; visit_count++; host notified; badge PDF available
   Side effects on Checked_Out: set checkout_time=NOW(); duration_minutes computed; is_overdue cleared if set

2. **Gate Pass Status FSM** (FR-VSM-03, BR-VSM-002):
   ```
   [Issued] ──(QR scanned at gate, valid)──► [Used]
      │
      │ (expires_at < NOW — hourly job)
      ▼
   [Expired]
      │
      │ (admin revokes)
   [Revoked]  (can be revoked from any non-Used state)
   ```
   Note: pass_token is UNIQUE — once Used, cannot be reused for another check-in

3. **Emergency Event FSM** (FR-VSM-06, BR-VSM-005, BR-VSM-010):
   ```
   [Triggered]
       │ Notifications dispatched to ALL active sys_users (SMS + in-app, dedicated queue)
       │ if type=Lockdown: is_lockdown_active=true → gate pass generation blocked
       │ Headcount initiated: query present students from ATT module
       ▼
   [Active]
       │
       │ Admin resolves: resolved_at=NOW(), is_lockdown_active=false
       ▼
   [Resolved]
   ```

4. **Guard Shift Attendance FSM** (FR-VSM-10, BR-VSM-007):
   ```
   [Scheduled]
       │ (guard clocks in — actual_start_time recorded)
       ▼
   [Present] — if actual_start <= shift_start + 15 min
   [Late]    — if actual_start >  shift_start + 15 min
       │ (guard clocks out — actual_end_time recorded)
       ▼
   [Complete]         — if actual_end >= shift_end - 15 min
   [Early_Departure]  — if actual_end <  shift_end - 15 min
   ```
   Note: UNIQUE key on (guard_user_id, shift_date, shift_start_time) prevents duplicate shift creation

5. **Pre-Registration + Gate Check-in Full Flow** (FR-VSM-01, FR-VSM-03):
   ```
   Host fills pre-registration form
       │
       ▼
   Blacklist check (BR-VSM-001) ──(match)──► Block + Alert security + Log blacklist_hit=1
       │ (no match)
       ▼
   vsm_visitors upsert by mobile_no (visit_count unchanged at this point)
       │
       ▼
   vsm_visits created (status=Pre_Registered)
       │
       ▼
   QR gate pass generated (pass_token = Str::uuid(), expires in 24h)
       │
       ▼
   SMS + email to visitor via Notification module
       │
   --- VISITOR ARRIVES ---
       │
       ▼
   Guard scans QR at gate
       │
       ▼
   Token validation: status=Issued? expires_at > NOW? Not already Checked_In?
       ├── Fails ──► Error shown to guard with specific reason
       └── Passes ──► DB::transaction() begins
                         checkin_time=NOW(), status=Checked_In
                         pass_token status=Used
                         visit_count++ (vsm_visitors)
                         Optional: gate photo captured (sys_media)
                         Host notified via NTF module
                         Badge PDF available for print
                      DB::transaction() commits
   ```

#### Section 6 — Functional Requirements Summary (14 FRs)
For each FR-VSM-01 to FR-VSM-14:
| FR ID | Name | Tables Used | Key Validations | Related BRs | Depends On | Priority |
|---|---|---|---|---|---|---|

Group by functional area:
- **Core Visitor Management** (FR-VSM-01 Walk-in Reg, FR-VSM-02 Pre-Reg, FR-VSM-03 Check-in, FR-VSM-04 Check-out)
- **Campus Operations** (FR-VSM-05 Dashboard, FR-VSM-06 Emergency)
- **Security Controls** (FR-VSM-07 Pickup Auth, FR-VSM-08 Contractor Access, FR-VSM-09 Blacklist)
- **Guard Management** (FR-VSM-10 Guard Shifts, FR-VSM-11 Patrol Rounds)
- **Analytics & Misc** (FR-VSM-12 Repeat Visitor Detection, FR-VSM-13 CCTV Hooks, FR-VSM-14 Reports)

For FR-VSM-13 (CCTV Hooks) note: webhook ingestion ONLY; hardware integration out of scope; `->withoutMiddleware(['auth'])` or public API key required for webhook endpoint

#### Section 7 — Permission Matrix
| Permission Slug | Admin | Principal | Reception | Guard | Teacher/Staff |
|---|---|---|---|---|---|

Derive permissions from req v2 Section 15.2:
- `tenant.vsm-visitor.view` — Admin, Principal, Reception, Guard
- `tenant.vsm-visitor.create` — Admin, Reception
- `tenant.vsm-visitor.pre-register` — Admin, Principal, Reception, Teacher, Staff
- `tenant.vsm-visitor.update` — Admin, Reception
- `tenant.vsm-visitor.delete` — Admin
- `tenant.vsm-visit.checkin` — Admin, Reception, Guard
- `tenant.vsm-visit.checkout` — Admin, Reception, Guard
- `tenant.vsm-visit.view` — Admin, Principal, Reception, Guard
- `tenant.vsm-contractor.view` — Admin, Reception
- `tenant.vsm-contractor.manage` — Admin
- `tenant.vsm-blacklist.manage` — Admin, Principal
- `tenant.vsm-guard-shift.manage` — Admin
- `tenant.vsm-guard-shift.self` — Guard (own shift clock-in/out only)
- `tenant.vsm-patrol.manage` — Admin, Guard
- `tenant.vsm-emergency.view` — Admin, Principal, Reception, Guard
- `tenant.vsm-emergency.broadcast` — Admin, Principal
- `tenant.vsm-report.view` — Admin, Principal

Note: 8 Policy classes (from req v2 Section 2.4): document which controller/method each policy protects

#### Section 8 — Service Architecture (4 services)
For each service:
```
Service:     ClassName
File:        app/Services/ClassName.php
Namespace:   Modules\VisitorSecurity\app\Services
Depends on:  [other services or modules it calls]
Fires:       [events or notifications dispatched]

Key Methods:
  methodName(TypeHint $param): ReturnType
    └── description of what it does
```

Services to document:

1. **VisitorService** — Core registration + check-in/out + QR generation:
   - `registerWalkIn(StoreVisitorRequest $request): array` — blacklist check → upsert vsm_visitors → create vsm_visits → generate gate pass → notify host; returns [visitor, visit, gate_pass]
   - `preRegister(PreRegisterVisitRequest $request): array` — same flow with status=Pre_Registered; dispatch QR to visitor mobile via NTF
   - `processCheckin(ProcessCheckinRequest $request): VsmVisit` — DB::transaction() + lockForUpdate(); validate pass_token; set checkin_time; increment visit_count; dispatch host notification; optional photo
   - `processCheckout(ProcessCheckoutRequest $request): VsmVisit` — set checkout_time; compute duration_minutes; clear is_overdue if set; gate pass status=Closed
   - `generateGatePass(VsmVisit $visit): VsmGatePass` — Str::uuid() as pass_token; compute expires_at; SimpleSoftwareIO QR generation; store qr_code_path
   - `checkBlacklist(string $mobileNo, ?string $idNumber): ?VsmBlacklist` — match by mobile_no OR id_number; check is_active=1 and valid_until >= TODAY or NULL
   - `sendQrToVisitor(VsmGatePass $pass, string $mobile, ?string $email): void` — dispatch via NTF module SMS + email with hosted QR URL
   - `processPickupAuthorisation(ProcessPickupRequest $request): VsmPickupAuth` — lookup std_guardian list; set is_authorised; require override if no match (BR-VSM-011)

2. **SecurityAlertService** — Emergency broadcast + overdue flagging:
   - `broadcastEmergency(BroadcastEmergencyRequest $request): VsmEmergencyEvent` — create vsm_emergency_events; dispatch job to SMS + in-app push ALL active sys_users; set is_lockdown_active if type=Lockdown; initiate headcount (query ATT module)
   - `resolveEmergency(VsmEmergencyEvent $event): void` — set resolved_at=NOW(); is_lockdown_active=false; notify staff of resolution
   - `flagOverdueVisitors(): int` — called by FlagOverdueVisitorsJob every 15 min; returns count of newly flagged visits; dispatches in-app alert to security desk
   - `isLockdownActive(): bool` — check active vsm_emergency_events.is_lockdown_active; used by gate pass generation guard

3. **PatrolService** — Patrol round management:
   - `startRound(int $guardUserId, ?int $shiftId): VsmPatrolRound` — create vsm_patrol_rounds with status=In_Progress; set checkpoints_total from active checkpoint count
   - `scanCheckpoint(VsmPatrolRound $round, string $qrToken): VsmPatrolCheckpointLog` — resolve qr_token → checkpoint; record timestamp; increment checkpoints_completed; update completion_pct; if round complete: auto-close
   - `completeRound(VsmPatrolRound $round): VsmPatrolRound` — compute completion_pct; set status=Completed or Incomplete (< 80% threshold per BR-VSM-006); alert admin if Incomplete
   - `generateCheckpointQr(VsmPatrolCheckpoint $checkpoint): string` — SimpleSoftwareIO QR for qr_token; store qr_code_path

4. **ContractorAccessService** — Contractor pass management (V2 new):
   - `register(StoreContractorRequest $request): VsmContractor` — blacklist check; create record; generate unique pass_token; notify admin
   - `validateEntry(string $passToken): array` — check pass_token; validate date range (access_from <= today <= access_until); validate day of week in entry_days_json (BR-VSM-012); check pass_status=Active; increment entry_count
   - `revokeAccess(VsmContractor $contractor): void` — set pass_status=Revoked; notify admin
   - `expireOldContracts(): int` — called by daily ExpireContractorPassesJob; returns count expired

Note: Controllers must remain thin — call services and pass result to view. No business logic in controller methods.

#### Section 9 — Integration Contracts (Notifications + Events)

For each outbound notification/event:
| Trigger | Fired By | Target / Channel | Timing | Payload |
|---|---|---|---|---|
- Host arrival alert → VisitorService::processCheckin() → NTF module → in-app + SMS → real-time on check-in
- QR gate pass dispatch → VisitorService::preRegister() / registerWalkIn() → NTF module → SMS + email → at registration
- Emergency broadcast → SecurityAlertService::broadcastEmergency() → NTF module → ALL active sys_users, SMS + in-app → dedicated queue channel (bypasses rate limiting)
- Overdue alert → FlagOverdueVisitorsJob → NTF module → security desk in-app → every 15 min run
- Blacklist hit alert → VisitorService (on check or registration) → NTF module → reception desk in-app → real-time

For each inbound read (VSM reads from these):
| Module | Table Read | Purpose |
|---|---|---|
| STD | std_students (+ guardian JNT) | Pickup authorisation — verify guardian is authorised for student |
| ATT | Attendance tables | Emergency headcount — query present students per section |
| SCH | sys_school_settings | School timezone for overdue scheduler; data retention policy |

Document CCTV webhook contract:
```
POST /api/v1/vsm/cctv/event
Auth: None (webhook secret via X-CCTV-Secret header — validate in controller)
Payload: { camera_id, event_type, timestamp, snapshot_url }
Action: Create vsm_cctv_events record; link to active visit if gate camera during check-in window
Response: { success: true, event_id: N }
```

#### Section 10 — Non-Functional Requirements
From req v2 Section 10 — for each NFR, add "Implementation Note" column:

Critical NFRs:
- Dashboard live count query < 1 second — composite index on `(status, expected_date)` in vsm_visits; cache dashboard aggregates for 60s
- QR scan check-in response < 2 seconds — gate pass lookup by indexed UNIQUE pass_token (VARCHAR); no full-table scan
- Gate pass token MUST be UUID v4 — `Str::uuid()` in VisitorService::generateGatePass()
- Gate pass expiry — server-side comparison against `expires_at` in DB; never trust client
- Visitor ID proof images not publicly accessible — private disk storage; serve via signed URL or controller stream
- Check-in concurrency — `DB::transaction()` + `lockForUpdate()` in VisitorService::processCheckin() (BR-VSM-003)
- Emergency broadcast under load — dedicated queue channel `emergency`; no rate limiting; 3 retries
- Data retention — visitor photos 90-day default; configurable in sys_school_settings; `vsm:purge-old-media` Artisan command
- Timezone — `Carbon::setTimezone(school_timezone)` before any NOW() comparison in overdue scheduler
- Mobile-friendly gate check-in — large touch targets; camera getUserMedia API (HTTPS mandatory); fallback to file upload
- QR generation — `SimpleSoftwareIO/simple-qrcode`; embedded as hosted URL in SMS message

#### Section 11 — Test Plan Outline
From req v2 Section 12 (18 test scenarios):

**Feature Tests (Pest) — 10 test files:**
| File | Key Scenarios | Priority |
|---|---|---|
| VisitorRegistrationTest | Walk-in registration; blacklist check runs; photo uploaded to sys_media | Critical |
| BlacklistBlockTest | Blacklisted mobile_no → blocked; blacklist_hit=1 logged | Critical |
| PreRegistrationQrTest | Pre-register → QR generated; SMS dispatched | Critical |
| GateCheckinTest | QR scan → checkin_time set; pass=Used; host notified | Critical |
| DuplicateCheckinBlockTest | Second check-in attempt → 422 without supervisor override | Critical |
| GateCheckoutTest | Checkout → duration_minutes computed; status=Checked_Out | High |
| OverdueFlaggingTest | Scheduler marks is_overdue=1 after duration; clears on checkout | High |
| EmergencyBroadcastTest | Broadcast dispatched; vsm_emergency_events created; lockdown mode enabled | High |
| LockdownModeTest | is_lockdown_active=true → gate pass generation blocked (403) | High |
| StudentPickupAuthTest | Authorised guardian matched (is_authorised=1); unmatched → override required | High |

**Additional Tests:**
| File | Key Scenarios | Priority |
|---|---|---|
| ContractorAccessTest | Pass valid in date range; expired after access_until; blocked on revoked | High |
| PatrolRoundTest | Checkpoint scan → completion % recalculated; < 80% → status=Incomplete | Medium |
| GuardClockInTest | Clock-in 20 min late → attendance_status=Late auto-set | Medium |
| BlacklistExpiryTest (Unit) | Entry with valid_until < today → is_active=0 after scheduler | Medium |
| GatePassExpiryTest (Unit) | expires_at < NOW → validate blocks check-in | High |
| RepeatVisitorTest | Same mobile_no → existing record matched; visit_count incremented | Medium |
| ContractorEntryDayBlockTest | Entry on day not in entry_days_json → check-in rejected | Medium |
| CctvWebhookTest | POST /api/v1/vsm/cctv/event → vsm_cctv_events created; linked to visit if gate camera | Low |

**Test Setup:**
```php
uses(Tests\TestCase::class, RefreshDatabase::class);
// Actor factories: AdminUser, ReceptionUser, GuardUser, TeacherUser, PrincipalUser
// Visitor factories: VsmVisitorFactory, VsmVisitFactory (with status parameter)
// GatePassFactory: generates UUID v4 pass_token, expires_at
// Notification::fake() for host arrival alerts + emergency broadcast tests
// Queue::fake() for FlagOverdueVisitorsJob and emergency jobs
// Event::fake() for check-in side effects
// For lockdown test: create active vsm_emergency_events with is_lockdown_active=1
// CCTV webhook: use withoutMiddleware(['auth']) + mock X-CCTV-Secret header
```

---

### Phase 1 Output Files
| File | Location |
|---|---|
| `VSM_FeatureSpec.md` | `{OUTPUT_DIR}/VSM_FeatureSpec.md` |

### Phase 1 Quality Gate
- [ ] All 13 vsm_* tables appear in Section 2 entity inventory with full column details
- [ ] All 14 FRs (FR-VSM-01 to FR-VSM-14) appear in Section 6
- [ ] All 15 business rules (BR-VSM-001 to BR-VSM-015) in Section 4 with enforcement point
- [ ] All 5 FSMs documented with ASCII state diagram and side effects
- [ ] All 4 services listed with key method signatures in Section 8
- [ ] `vsm_gate_passes.pass_token` noted as UUID v4 (never sequential) — Str::uuid() in VisitorService
- [ ] `vsm_gate_passes.expires_at` noted as server-side only comparison (BR-VSM-002)
- [ ] `vsm_visits.blacklist_hit` and `vsm_visits.is_overdue` columns documented with their trigger
- [ ] `vsm_contractors.entry_days_json` and BR-VSM-012 documented together
- [ ] Check-in concurrency: DB::transaction() + lockForUpdate() noted in Section 8 and Section 10
- [ ] Emergency broadcast: dedicated queue channel; bypasses rate limiting noted in Section 8 and Section 10
- [ ] **No `tenant_id` column** mentioned anywhere in any table definition
- [ ] Cross-module dependency on STD (std_students, guardian JNT) documented in Section 9 with column verification note
- [ ] Permission matrix covers all 17 permission slugs from req v2 Section 15.2
- [ ] FR-VSM-13 (CCTV Hooks) clearly noted as webhook ingestion ONLY; hardware out of scope
- [ ] Dashboard auto-refresh at 60s (polling first; SSE upgrade noted as future)
- [ ] All 4 scheduled jobs listed with schedule in Section 11 test data or separate sub-section
- [ ] Visitor photo/ID proof storage: sys_media with model_type=vsm_visitors; private disk; signed URL
- [ ] Data retention policy for visitor media (90-day default, configurable) noted in Section 10
- [ ] School timezone handling for overdue scheduler: Carbon::setTimezone() noted in Section 10

**After Phase 1, STOP and say:**
"Phase 1 (Feature Specification) complete. Output saved to `{OUTPUT_DIR}/VSM_FeatureSpec.md`. Please review and say 'Approved. Proceed to Phase 2' to continue."

---

## PHASE 2 — Database Schema Design (DDL + Seeders)

### Phase 2 Input Files
1. `{OUTPUT_DIR}/VSM_FeatureSpec.md` — Entity inventory (Section 2) from Phase 1
2. `{REQUIREMENT_FILE}` — Section 5 (canonical column definitions for all 13 tables)
3. `{AI_BRAIN}/agents/db-architect.md` — DB Architect agent instructions (read if exists)
4. `{TENANT_DDL}` — Existing schema: verify referenced table column names and data types; confirm std_students.id, std_guardians.id, sys_users.id are BIGINT UNSIGNED; check no duplicate tables being created

### Phase 2A Task — Generate DDL (`VSM_DDL_v1.sql`)

Generate CREATE TABLE statements for all 13 tables. Produce one single SQL file.

**14 DDL Rules — all mandatory:**
1. Table prefix: `vsm_` for all tables — no exceptions
2. Every table MUST include: `id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY`, `is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable'`, `created_by BIGINT UNSIGNED NULL COMMENT 'sys_users.id'`, `created_at TIMESTAMP NULL`, `updated_at TIMESTAMP NULL`, `deleted_at TIMESTAMP NULL COMMENT 'Soft delete'`
   - Exception: `vsm_patrol_checkpoint_log` uses only `created_at` (no `updated_at` or `deleted_at` — immutable scan log)
   - Exception: `vsm_cctv_events` uses only `created_at` (immutable webhook event log; no soft delete)
3. Index ALL foreign key columns — every FK column must have a KEY entry
4. Boolean flag columns: prefix `is_` or `has_`
5. JSON columns: suffix `_json` (e.g. `allowed_zones_json`, `entry_days_json`, `responsible_roles_json`, `media_ids_json`)
6. All IDs and FK references: `BIGINT UNSIGNED` (consistency with tenant_db convention)
7. Add COMMENT on every column — describe what it holds, valid values for ENUMs
8. Engine: `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`
9. Use `CREATE TABLE IF NOT EXISTS`
10. FK constraint naming: `fk_vsm_{tableshort}_{column}` (e.g. `fk_vsm_vis_visitor_id`)
11. **Do NOT recreate std_*, sys_* tables** — reference via FK only
12. **No `tenant_id` column** — stancl/tenancy v3.9 uses separate DB per tenant
13. `vsm_gate_passes.pass_token` and `vsm_contractors.pass_token`: `VARCHAR(100) NOT NULL UNIQUE` — UUID v4 enforced at application layer; do NOT add a CHECK constraint
14. `vsm_visitors.visit_count` and `vsm_contractors.entry_count`: `INT UNSIGNED DEFAULT 0` — incremented at application layer (NOT trigger), denormalized for dashboard performance

**DDL Table Order (dependency-safe — define referenced tables before referencing tables):**

Layer 1 — No vsm_* dependencies (may reference sys_* only):
  `vsm_visitors` (→ sys_media nullable),
  `vsm_blacklist` (→ sys_users, sys_media nullable),
  `vsm_emergency_protocols` (no FK deps),
  `vsm_patrol_checkpoints` (no vsm_ FK deps)

Layer 2 — Depends on Layer 1:
  `vsm_visits` (→ vsm_visitors + sys_users + sys_media nullable),
  `vsm_emergency_events` (→ vsm_emergency_protocols nullable + sys_users),
  `vsm_guard_shifts` (→ sys_users)

Layer 3 — Depends on Layer 2:
  `vsm_gate_passes` (→ vsm_visits UNIQUE FK + vsm_visitors),
  `vsm_pickup_auth` (→ vsm_visits + std_students + sys_users nullable + sys_media nullable),
  `vsm_contractors` (no vsm_ FK — standalone),
  `vsm_patrol_rounds` (→ vsm_guard_shifts nullable + sys_users),
  `vsm_cctv_events` (→ vsm_visits nullable)

Layer 4 — Depends on Layer 3:
  `vsm_patrol_checkpoint_log` (→ vsm_patrol_rounds + vsm_patrol_checkpoints)

**Critical unique constraints to include:**
```sql
-- vsm_visits
UNIQUE KEY uq_vsm_visit_number (visit_number)

-- vsm_gate_passes
UNIQUE KEY uq_vsm_gp_visit (visit_id)       -- one pass per visit
UNIQUE KEY uq_vsm_gp_token (pass_token)     -- UUID v4; lookup key at gate

-- vsm_contractors
UNIQUE KEY uq_vsm_con_token (pass_token)    -- reusable token; must be unique

-- vsm_guard_shifts
UNIQUE KEY uq_vsm_gs_guard_shift (guard_user_id, shift_date, shift_start_time)

-- vsm_patrol_checkpoints
UNIQUE KEY uq_vsm_pc_qr_token (qr_token)   -- each physical checkpoint has unique QR
```

**ENUM values (exact, to match application code):**
```
vsm_visitors.id_type:                  'Aadhar','DrivingLicense','Passport','VoterID','Other'
vsm_visits.purpose:                    'PTM','Admission','Meeting','Delivery','Maintenance','Interview','StudentPickup','Contractor','Other'
vsm_visits.status:                     'Pre_Registered','Registered','Checked_In','Checked_Out','No_Show','Cancelled'
vsm_gate_passes.status:                'Issued','Used','Expired','Revoked'
vsm_contractors.id_type:               'Aadhar','DrivingLicense','Passport','VoterID','Other'
vsm_contractors.pass_status:           'Active','Expired','Revoked'
vsm_guard_shifts.attendance_status:    'Scheduled','Present','Absent','Late','Early_Departure'
vsm_patrol_rounds.status:              'In_Progress','Completed','Incomplete'
vsm_emergency_protocols.protocol_type: 'Fire','Earthquake','Lockdown','MedicalEmergency','Evacuation','Other'
vsm_emergency_events.emergency_type:   'Fire','Earthquake','Lockdown','MedicalEmergency','Evacuation','Other'
```

**Critical columns to get right:**
- `vsm_visits.visit_number VARCHAR(30) NOT NULL UNIQUE` — format: VSM-YYYYMMDD-XXXX (generated in VisitorService)
- `vsm_visits.expected_duration_minutes SMALLINT UNSIGNED DEFAULT 60` — used by overdue scheduler
- `vsm_visits.is_overdue TINYINT(1) DEFAULT 0` — set by FlagOverdueVisitorsJob, cleared on check-out
- `vsm_visits.blacklist_hit TINYINT(1) DEFAULT 0` — set at registration if blacklist match found
- `vsm_gate_passes.expires_at TIMESTAMP NOT NULL` — computed as MIN(end of expected_date, issued_at + 24h)
- `vsm_gate_passes.used_at TIMESTAMP NULL` — set when QR scanned at gate
- `vsm_contractors.allowed_zones_json JSON NULL` — array of zone strings
- `vsm_contractors.entry_days_json JSON NULL` — e.g. `["Mon","Tue","Wed","Thu","Fri"]`
- `vsm_blacklist.valid_until DATE NULL` — NULL = permanent blacklist (BR-VSM-014: auto-expire if not NULL and < today)
- `vsm_pickup_auth.is_authorised TINYINT(1) NOT NULL` — 1 if guardian found in std_guardian list; 0 if override
- `vsm_pickup_auth.override_by BIGINT UNSIGNED NULL FK→sys_users` — only set when supervisor overrides
- `vsm_patrol_rounds.completion_pct DECIMAL(5,2) DEFAULT 0.00` — computed: (checkpoints_completed / checkpoints_total) × 100
- `vsm_emergency_events.is_lockdown_active TINYINT(1) DEFAULT 0` — set to 1 when emergency_type=Lockdown
- `vsm_emergency_events.triggered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP` — immutable trigger time
- `vsm_cctv_events.linked_visit_id BIGINT UNSIGNED NULL FK→vsm_visits` — auto-linked if gate camera + active visit within check-in window

**File header comment to include:**
```sql
-- =============================================================================
-- VSM — Visitor & Security Management Module DDL
-- Module: VisitorSecurity (Modules\VisitorSecurity)
-- Table Prefix: vsm_* (13 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: [DATE]
-- Based on: VSM_VisitorSecurity_Requirement.md v2
-- Sub-Modules: Visitor Management, Gate Operations, Contractor Access,
--              Guard Shifts, Patrol Rounds, Emergency System, CCTV Hooks
-- =============================================================================
```

### Phase 2B Task — Generate Laravel Migration (`VSM_Migration.php`)

Single migration file for `database/migrations/tenant/YYYY_MM_DD_000000_create_vsm_tables.php`.
- `up()`: creates all 13 tables in Layer 1 → Layer 4 dependency order using `Schema::create()`
- `down()`: drops all tables in reverse order (Layer 4 → Layer 1)
- Use `Blueprint` column helpers; match ENUM types with `->enum()`, decimal with `->decimal(5, 2)`, JSON with `->json()`
- All FK constraints added in `up()` using `$table->foreign()`
- Note: `vsm_patrol_checkpoint_log` — no `$table->softDeletes()` and no `$table->timestamps()` for updated_at; use `$table->timestamp('created_at')->useCurrent()` only
- Note: `vsm_cctv_events` — same pattern as checkpoint_log; no updated_at/deleted_at

### Phase 2C Task — Generate Seeders (2 seeders + 1 runner)

Namespace: `Modules\VisitorSecurity\Database\Seeders`

**1. `VsmEmergencyProtocolSeeder.php`** — 5 standard emergency protocol templates (`is_system=1`):
```
Lockdown        | title: "Campus Lockdown Protocol"    | responsible_roles_json: ["Admin","Principal","Guard"]
Fire            | title: "Fire Emergency Protocol"     | responsible_roles_json: ["Admin","Principal","Teacher","Guard"]
Earthquake      | title: "Earthquake Response Protocol"| responsible_roles_json: ["Admin","Principal","Teacher"]
MedicalEmergency| title: "Medical Emergency Protocol"  | responsible_roles_json: ["Admin","Principal","Teacher"]
Evacuation      | title: "Evacuation Protocol"         | responsible_roles_json: ["Admin","Principal","Teacher","Guard"]
```
Each protocol description should contain a placeholder SOP: "Step 1: Alert Security. Step 2: Follow designated protocol. (Update with school-specific SOP)"

**2. `VsmPatrolCheckpointSeeder.php`** — 4 default campus checkpoints (`is_system=1`):
```
Main Gate Entrance   | sequence_order: 1 | building: Main Building | qr_token: (UUID v4 per checkpoint)
Back Gate            | sequence_order: 2 | building: Back Boundary  | qr_token: (UUID v4)
Admin Block          | sequence_order: 3 | building: Admin Block     | qr_token: (UUID v4)
Parking Area         | sequence_order: 4 | building: Outdoor         | qr_token: (UUID v4)
```
Note: `qr_token` values must be generated as UUID v4 in seeder code; do NOT use hardcoded strings.

**3. `VsmSeederRunner.php`** (Master seeder, calls all in order):
```php
$this->call([
    VsmEmergencyProtocolSeeder::class,  // no vsm_* dependencies
    VsmPatrolCheckpointSeeder::class,   // no vsm_* dependencies
]);
```

### Phase 2 Output Files
| File | Location |
|---|---|
| `VSM_DDL_v1.sql` | `{OUTPUT_DIR}/VSM_DDL_v1.sql` |
| `VSM_Migration.php` | `{OUTPUT_DIR}/VSM_Migration.php` |
| `VSM_TableSummary.md` | `{OUTPUT_DIR}/VSM_TableSummary.md` |
| `Seeders/VsmEmergencyProtocolSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/VsmPatrolCheckpointSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/VsmSeederRunner.php` | `{OUTPUT_DIR}/Seeders/` |

### Phase 2 Quality Gate
- [ ] All 13 vsm_* tables exist in DDL
- [ ] Standard columns (id, is_active, created_by, created_at, updated_at, deleted_at) on all 11 standard tables
- [ ] `vsm_patrol_checkpoint_log` has NO updated_at, NO deleted_at — immutable scan record
- [ ] `vsm_cctv_events` has NO updated_at, NO deleted_at — immutable webhook event record
- [ ] `uq_vsm_visit_number` UNIQUE on vsm_visits
- [ ] `uq_vsm_gp_visit` UNIQUE `(visit_id)` on vsm_gate_passes — one pass per visit
- [ ] `uq_vsm_gp_token` UNIQUE `(pass_token)` on vsm_gate_passes — UUID v4 lookup key
- [ ] `uq_vsm_con_token` UNIQUE `(pass_token)` on vsm_contractors — reusable but unique
- [ ] `uq_vsm_gs_guard_shift` UNIQUE `(guard_user_id, shift_date, shift_start_time)` on vsm_guard_shifts
- [ ] `uq_vsm_pc_qr_token` UNIQUE `(qr_token)` on vsm_patrol_checkpoints
- [ ] All ENUM columns use exact values from Phase 2A ENUM list
- [ ] `vsm_blacklist.valid_until` is `DATE NULL` (NULL = permanent blacklist)
- [ ] `vsm_pickup_auth.is_authorised TINYINT(1) NOT NULL` (not nullable)
- [ ] `vsm_patrol_rounds.completion_pct DECIMAL(5,2) DEFAULT 0.00` (computed at application layer, not GENERATED column)
- [ ] `vsm_emergency_events.is_lockdown_active TINYINT(1) DEFAULT 0`
- [ ] `vsm_emergency_events.triggered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP`
- [ ] `vsm_gate_passes.expires_at TIMESTAMP NOT NULL` (not nullable — always computed on creation)
- [ ] `vsm_visits.visit_number VARCHAR(30) NOT NULL UNIQUE`
- [ ] `vsm_contractors.allowed_zones_json JSON NULL` and `entry_days_json JSON NULL`
- [ ] **No `tenant_id` column** on any table
- [ ] All FK columns have corresponding KEY index
- [ ] FK naming follows `fk_vsm_` convention throughout
- [ ] Migration down() drops tables in reverse Layer 4→1 order
- [ ] VsmPatrolCheckpointSeeder generates UUID v4 qr_token values in code (not hardcoded)
- [ ] VsmEmergencyProtocolSeeder has all 5 protocol types with responsible_roles_json
- [ ] `VSM_TableSummary.md` has one-line description for all 13 tables

**After Phase 2, STOP and say:**
"Phase 2 (Database Schema Design) complete. Output: `VSM_DDL_v1.sql` + Migration + 3 seeder files. Please review and say 'Approved. Proceed to Phase 3' to continue."

---

## PHASE 3 — Complete Development Plan

### Phase 3 Input Files
1. `{OUTPUT_DIR}/VSM_FeatureSpec.md` — Services (Section 8), permissions (Section 7), tests (Section 11)
2. `{REQUIREMENT_FILE}` — Section 6 (routes), Section 7 (UI screens), Section 12 (tests), Section 15 (FormRequests + permissions + scheduled jobs)
3. `{AI_BRAIN}/memory/modules-map.md` — Patterns from completed modules (especially naming conventions)

### Phase 3 Task — Generate `VSM_Dev_Plan.md`

Generate the complete implementation blueprint. Organise into 8 sections:

---

#### Section 1 — Controller Inventory

For each controller, provide:
| Controller Class | File Path | Methods | FR Coverage |
|---|---|---|---|

For each controller list:
- All public methods with HTTP method + URI + route name
- Which FormRequest each write method uses
- Which Policy / Gate permission is checked

Controllers to define (8 web controllers + 1 API controller):

1. **VisitorSecurityController** — dashboard (FR-VSM-05); methods: dashboard
2. **VisitorController** — visitor registration + history + pickup auth + blacklist (FR-VSM-01, FR-VSM-02, FR-VSM-07, FR-VSM-09, FR-VSM-12):
   - index, create, store (StoreVisitorRequest), show, edit, update, destroy
   - preRegister (GET), storePreRegister (POST) (PreRegisterVisitRequest)
   - sendQr (POST — resend QR to visitor mobile)
   - pickupIndex (GET), processPickup (POST) (ProcessPickupRequest)
   - blacklistIndex (GET), blacklistStore (POST) (StoreBlacklistRequest), blacklistDestroy (DELETE)
3. **VisitController** — visit lifecycle: check-in/out + log (FR-VSM-03, FR-VSM-04):
   - index, today, show
   - checkin (GET — QR scan screen), processCheckin (POST) (ProcessCheckinRequest)
   - checkout (GET), processCheckout (POST) (ProcessCheckoutRequest)
4. **GatePassController** — QR gate pass badge + revoke:
   - badge (GET — DomPDF badge PDF; auto triggers browser print)
   - revoke (POST — admin revoke pass)
5. **ContractorController** — contractor/vendor access management (FR-VSM-08):
   - index, create, store (StoreContractorRequest), show, update, revoke (POST)
6. **GuardShiftController** — guard shift management (FR-VSM-10):
   - index, create, store (StoreGuardShiftRequest), update
   - clockIn (POST — guard records actual_start_time; auto-sets Late status per BR-VSM-007)
   - clockOut (POST — guard records actual_end_time; auto-sets Early_Departure if needed)
7. **PatrolController** — patrol rounds + checkpoints (FR-VSM-11):
   - index, store (start new round), show (active patrol with checkpoint checklist)
   - scanCheckpoint (POST — guard scans checkpoint QR; updates completion %)
   - complete (POST — finalise round; auto-sets Incomplete if < 80%)
   - checkpoints (GET — checkpoint management list), storeCheckpoint (POST) (StorePatrolCheckpointRequest)
8. **EmergencyController** — emergency alerts + headcount + protocols (FR-VSM-06):
   - index (active emergency events), broadcastForm (GET), broadcast (POST) (BroadcastEmergencyRequest)
   - resolve (POST — admin resolves emergency; clears lockdown)
   - protocols (GET — SOP list), storeProtocol (POST)
9. **Api\VsmApiController** — JSON API for guard kiosk/tablet + CCTV webhooks (FR-VSM-05, FR-VSM-11, FR-VSM-13):
   - checkin (POST — QR scan from kiosk), checkout (POST)
   - dashboard (GET — live stats JSON for kiosk screen)
   - patrolScan (POST — guard mobile app checkpoint scan)
   - searchVisitor (GET — typeahead search by mobile/name for kiosk)
   - validatePass (GET — validate pass token; returns pass details or error)
   - contractorCheckin (POST — contractor QR scan at gate)
   - emergencyBroadcast (POST — mobile app trigger)
   - activeVisits (GET — current on-campus visitors)
   - cctvEvent (POST — public webhook; no auth; validate X-CCTV-Secret header)
   - todayShifts (GET — guard's today shifts), guardClock (POST — mobile clock-in/out)

Also add a **ReportController** (not in original 8 but implied by req routes Section 6.1):
- visitorLog (GET), frequentVisitors (GET), guardAttendance (GET)
  Each supports `?format=pdf|csv` query param; PDF via DomPDF, CSV via fputcsv

Note on `cctvEvent`: must use `->withoutMiddleware(['auth', 'tenant'])` with custom header validation middleware — VSM must not require auth for CCTV webhook endpoint

#### Section 2 — Service Inventory (4 services)

For each service:
- Class name, file path, namespace
- Constructor dependencies (injected services/interfaces)
- All public methods with signature and 1-line description
- External modules called (NTF for notifications, ATT for headcount, STD for pickup auth)

Include the check-in sequence as inline pseudocode in `VisitorService`:
```
processCheckin(ProcessCheckinRequest $request): VsmVisit
  Step 1: Resolve pass_token → vsm_gate_passes; verify status=Issued, expires_at > NOW
  Step 2: Load vsm_visits via gate_pass.visit_id; verify status NOT already Checked_In (BR-VSM-003)
  Step 3: Blacklist re-check at gate (BR-VSM-001 belt-and-suspenders)
  Step 4: Check SecurityAlertService::isLockdownActive() (BR-VSM-010)
  Step 5: DB::transaction() begins
  Step 6: vsm_visits: checkin_time=NOW(), status=Checked_In
  Step 7: vsm_gate_passes: status=Used, used_at=NOW()
  Step 8: vsm_visitors: visit_count++ (increment via DB::increment)
  Step 9: Optional: upload gate photo to sys_media; set checkin_photo_media_id
  Step 10: DB::transaction() commits
  Step 11: Dispatch host notification via NTF module (in-app + SMS if staff mobile set)
  Step 12: Log to sys_activity_logs
  Return: updated vsm_visits record
```

Include emergency broadcast sequence as inline pseudocode in `SecurityAlertService`:
```
broadcastEmergency(BroadcastEmergencyRequest $request): VsmEmergencyEvent
  Step 1: Create vsm_emergency_events record
  Step 2: If type=Lockdown: is_lockdown_active=true
  Step 3: Dispatch EmergencyBroadcastJob (dedicated 'emergency' queue, 3 retries)
          → Query ALL active sys_users (staff + teachers)
          → Dispatch SMS + in-app push to each via NTF module
          → Update notification_count
  Step 4: headcount_initiated=true
          → Query ATT module for today's present students
          → Dispatch per-section headcount task to class teachers (in-app)
  Step 5: Log to sys_activity_logs
  Return: vsm_emergency_events record
```

#### Section 3 — FormRequest Inventory (10 FormRequests)

For each FormRequest:
| Class | Controller@Method | Key Validation Rules |
|---|---|---|

All 10 FormRequests (from req v2 Section 15.1):

1. **`StoreVisitorRequest`** — name: required, max:150; mobile_no: required, digits_between:10,15; id_type: nullable, in:Aadhar,DrivingLicense,Passport,VoterID,Other; photo: nullable, image, max:2048
2. **`PreRegisterVisitRequest`** — visitor_name: required; visitor_mobile: required; purpose: required, in:PTM,Admission,Meeting,Delivery,Maintenance,Interview,StudentPickup,Contractor,Other; host_staff_id: required, exists:sys_users,id; expected_date: required, date, after_or_equal:today; expected_time: nullable, date_format:H:i; expected_duration_minutes: nullable, integer, min:15, max:480
3. **`ProcessCheckinRequest`** — pass_token: required_without:visit_id, max:100; visit_id: required_without:pass_token, exists:vsm_visits,id; checkin_photo: nullable, image, max:2048
4. **`ProcessCheckoutRequest`** — visit_id: required, exists:vsm_visits,id (service layer validates status=Checked_In)
5. **`StoreGuardShiftRequest`** — guard_user_id: required, exists:sys_users,id; shift_date: required, date; shift_start_time: required, date_format:H:i; shift_end_time: required, date_format:H:i, after:shift_start_time; post: required, max:100
6. **`BroadcastEmergencyRequest`** — emergency_type: required, in:Lockdown,Fire,Earthquake,MedicalEmergency,Evacuation,Other; message: required, max:500; affected_zones: nullable, max:500
7. **`StoreBlacklistRequest`** — name: required, max:150; reason: required, max:1000; mobile_no: nullable, digits_between:10,15; id_number: nullable, max:50; valid_until: nullable, date, after_or_equal:today; Note: at least one of mobile_no or id_number required (custom validation rule)
8. **`StoreContractorRequest`** — contractor_name: required, max:150; mobile_no: required, digits_between:10,15; access_from: required, date, after_or_equal:today; access_until: required, date, after_or_equal:access_from; allowed_zones_json: nullable, json; entry_days_json: nullable, json; id_proof: nullable, image, max:2048
9. **`ProcessPickupRequest`** — student_id: required, exists:std_students,id; guardian_name: required, max:150; guardian_mobile: required, digits_between:10,15; relationship: nullable, max:50; id_proof: nullable, image, max:2048
10. **`StorePatrolCheckpointRequest`** — name: required, max:100; location_description: nullable, max:500; building: nullable, max:100; sequence_order: nullable, integer, min:0, max:255

#### Section 4 — Blade View Inventory (~32 views)

List all blade views grouped by feature area:
| View File | Route Name | Controller@Method | Description |
|---|---|---|---|

Feature areas and screen counts (SCR-VSM-01 to SCR-VSM-25 from req v2 Section 7):
- Dashboard (1 view): SCR-VSM-01 (live occupancy, overdue list, recent check-ins, quick actions)
- Visitor Management (4 views): SCR-VSM-02 list, SCR-VSM-03 walk-in form, SCR-VSM-04 pre-register, SCR-VSM-05 profile
- Gate Operations (5 views): SCR-VSM-06 check-in (QR scan widget), SCR-VSM-07 check-out, SCR-VSM-08 today's log, SCR-VSM-09 visit detail, SCR-VSM-10 gate pass badge (DomPDF)
- Security Controls (4 views): SCR-VSM-11 pickup auth list, SCR-VSM-12 contractor list, SCR-VSM-13 contractor form, SCR-VSM-14 blacklist
- Guard Management (5 views): SCR-VSM-15 guard shifts (weekly schedule grid), SCR-VSM-16 shift form, SCR-VSM-17 patrol rounds, SCR-VSM-18 active patrol (live checkpoint checklist), SCR-VSM-19 checkpoint management
- Emergency (3 views): SCR-VSM-20 broadcast form (big RED button), SCR-VSM-21 active emergency + headcount progress, SCR-VSM-22 protocols
- Reports (3 views): SCR-VSM-23 visitor log (date range, export), SCR-VSM-24 frequent visitors, SCR-VSM-25 guard attendance
- Shared partials (~5 partials): pagination, export-buttons (PDF/CSV), blacklist-badge, status-badge (visit status coloured chips), overdue-alert-banner

For key screens document:
- SCR-VSM-06 (Gate Check-in): QR scan widget using HTML5 camera getUserMedia API; manual mobile/name search fallback; HTTPS required for camera access; large touch targets for guard tablet kiosk
- SCR-VSM-20 (Emergency Broadcast): type dropdown, zone selector, message textarea; confirmation modal before submit; BIG RED button design; no confirmation timeout — immediate dispatch
- SCR-VSM-21 (Active Emergency): lockdown banner when is_lockdown_active=true; headcount table per section with teacher response status; resolve button for admin/principal
- SCR-VSM-01 (Dashboard): auto-refresh every 60 seconds via AJAX polling (Polling: `setInterval(fetchStats, 60000)`); visitor count widget, overdue count (red), recent 5 check-ins

#### Section 5 — Complete Route List

Consolidate ALL routes from req v2 Section 6 into a single table:
| Method | URI | Route Name | Controller@method | Middleware | FR |
|---|---|---|---|---|---|

Group by Section 6.1 (web) and 6.2 (API).
Middleware on all web routes: `['auth', 'tenant', 'EnsureTenantHasModule:VisitorSecurity']`
Middleware on API routes: `['auth:sanctum', 'tenant']` (except cctvEvent which needs no auth)

Web route count target: ~70 routes
API route count target: 12 routes

Special route notes:
- `GET /visitor-security/gate-passes/{pass_token}/scan` — **public route, no auth** — needed for QR URL in SMS message; shows visitor identity + access status; no sensitive data
- `POST /api/v1/vsm/cctv/event` — **no auth** — validate via `X-CCTV-Secret` header in controller
- All routes use `EnsureTenantHasModule:VisitorSecurity` except public scan + CCTV webhook

#### Section 6 — Implementation Phases (4 phases)

**Phase 1 — Visitor Core** (no cross-module deps beyond sys_*):
FRs: FR-VSM-01, FR-VSM-02, FR-VSM-03, FR-VSM-04, FR-VSM-09, FR-VSM-12
Files to create:
- Migration: VSM_Migration.php (all 13 tables — run once)
- Seeders: VsmEmergencyProtocolSeeder, VsmPatrolCheckpointSeeder, VsmSeederRunner
- Controllers: VisitorSecurityController (dashboard), VisitorController (all visitor + blacklist), VisitController (checkin/out), GatePassController (badge + revoke)
- Services: VisitorService (complete — all check-in/out logic, blacklist check, QR generation, photo upload)
- Models: VsmVisitor, VsmVisit, VsmGatePass, VsmBlacklist, VsmPickupAuth
- FormRequests: StoreVisitorRequest, PreRegisterVisitRequest, ProcessCheckinRequest, ProcessCheckoutRequest, StoreBlacklistRequest, ProcessPickupRequest
- Policies: VisitorPolicy, VisitPolicy, GatePassPolicy, BlacklistPolicy
- Jobs: FlagOverdueVisitorsJob (every 15 min), ExpireGatePassesJob (hourly), ExpireBlacklistEntriesJob (daily)
- Views: SCR-VSM-01 to SCR-VSM-11 + SCR-VSM-14 (~13 views)
- Routes: all visitor + visit + gate pass + blacklist + pickup routes
- Tests: T01 to T07, T10, T15, T16

**Phase 2 — Contractor Access + Guard Management**:
FRs: FR-VSM-08, FR-VSM-10, FR-VSM-11
Files to create:
- Controllers: ContractorController, GuardShiftController, PatrolController
- Services: ContractorAccessService (complete), PatrolService (complete)
- Models: VsmContractor, VsmGuardShift, VsmPatrolRound, VsmPatrolCheckpoint, VsmPatrolCheckpointLog
- FormRequests: StoreContractorRequest, StoreGuardShiftRequest, StorePatrolCheckpointRequest
- Policies: ContractorPolicy, GuardShiftPolicy, PatrolPolicy
- Jobs: ExpireContractorPassesJob (daily midnight)
- Views: SCR-VSM-12 to SCR-VSM-13, SCR-VSM-15 to SCR-VSM-19 (~7 views)
- Routes: all contractor + guard shift + patrol routes
- Tests: T11, T12, T13, T17

**Phase 3 — Emergency System + Reports**:
FRs: FR-VSM-06, FR-VSM-14
Files to create:
- Controllers: EmergencyController, ReportController
- Services: SecurityAlertService (complete — broadcast + lockdown + overdue flagging + headcount initiation)
- Models: VsmEmergencyProtocol, VsmEmergencyEvent
- FormRequests: BroadcastEmergencyRequest
- Policies: EmergencyPolicy
- Jobs: EmergencyBroadcastJob (dedicated 'emergency' queue channel; 3 retries; NOT limited by normal rate limiting)
- Views: SCR-VSM-20 to SCR-VSM-25 (~6 views)
- Routes: all emergency + report routes
- DomPDF: visitor badge (SCR-VSM-10), guard attendance report PDF
- Tests: T08, T09, T14

**Phase 4 — API + CCTV Hooks + Enhancements**:
FRs: FR-VSM-05 (API dashboard), FR-VSM-11 (API patrol scan), FR-VSM-13 (CCTV webhooks)
Files to create:
- Controllers: Api\VsmApiController (all 12 API endpoints)
- Models: VsmCctvEvent
- Routes: api.php (all 12 API routes)
- Public scan route: `GET /visitor-security/gate-passes/{pass_token}/scan` (unauthenticated)
- Tests: T18, + API endpoint tests (kiosk check-in, contractor checkin, dashboard JSON)
- Dashboard polling: JS `setInterval(fetchStats, 60000)` in SCR-VSM-01 view

#### Section 7 — Seeder Execution Order

```
php artisan module:seed VisitorSecurity --class=VsmSeederRunner
  ↓ VsmEmergencyProtocolSeeder    (no dependencies)
  ↓ VsmPatrolCheckpointSeeder     (no dependencies)
```

Artisan scheduled jobs (register in `routes/console.php`):
```
vsm:flag-overdue-visitors     → every 15 minutes (FlagOverdueVisitorsJob)
vsm:expire-gate-passes        → hourly (ExpireGatePassesJob)
vsm:expire-blacklist-entries  → daily at midnight (ExpireBlacklistEntriesJob)
vsm:expire-contractor-passes  → daily at midnight (ExpireContractorPassesJob)
```

Register in `Kernel.php` or `routes/console.php` depending on Laravel version:
```php
$schedule->job(new FlagOverdueVisitorsJob)->everyFifteenMinutes();
$schedule->job(new ExpireGatePassesJob)->hourly();
$schedule->job(new ExpireBlacklistEntriesJob)->dailyAt('00:00');
$schedule->job(new ExpireContractorPassesJob)->dailyAt('00:01');
```

#### Section 8 — Testing Strategy

**Framework:** Pest for Feature tests; PHPUnit for Unit tests.

**Feature Test Setup:**
```php
uses(Tests\TestCase::class, RefreshDatabase::class);
// Actor factories: AdminUser, ReceptionUser, GuardUser, TeacherUser
// VsmVisitorFactory: generates visitor with mobile_no, optional id_number
// VsmVisitFactory(status: 'Checked_In'|'Pre_Registered'|etc.)
// VsmGatePassFactory: generates UUID v4 pass_token, expires_at in future
// Notification::fake() for host arrival + emergency broadcast
// Queue::fake() for FlagOverdueVisitorsJob, EmergencyBroadcastJob
// Storage::fake() for visitor photo uploads
// For lockdown test: create VsmEmergencyEvent with is_lockdown_active=1
```

**Concurrency Test for Check-in:**
```
BR-VSM-003 duplicate check-in test:
  $visit = VsmVisit::factory()->create(['status' => 'Checked_In']);
  $this->actingAs($guardUser)
       ->post(route('vsm.gate.checkin.process'), ['visit_id' => $visit->id])
       ->assertStatus(422)  // Second check-in blocked without supervisor override
```

**Lockdown Gate-Block Test:**
```
$this->actingAs($adminUser)
     ->post(route('vsm.emergency.broadcast'), ['emergency_type' => 'Lockdown', 'message' => 'Test'])
     ->assertSuccessful();

// Now try to generate gate pass — must be blocked
$this->actingAs($receptionUser)
     ->post(route('vsm.visitors.pre-register'), $validPreRegData)
     ->assertStatus(403);  // BR-VSM-010: lockdown blocks gate pass generation
```

**Minimum Test Coverage Targets:**
- All 4 Scheduled jobs: test that they operate correctly on test data; use `$this->artisan()` + time travel
- BR-VSM-001 (blacklist check): fires on both pre-registration AND walk-in registration
- BR-VSM-003 (duplicate check-in): explicitly tested with concurrent simulation
- BR-VSM-006 (patrol < 80% = Incomplete): boundary test at exactly 79.9% and 80.0%
- BR-VSM-007 (guard Late/Early): clock-in exactly 15 min late vs 14 min late boundary test
- BR-VSM-010 (lockdown blocks gate): explicitly tested with active lockdown event
- CCTV webhook (FR-VSM-13): test with valid X-CCTV-Secret header + invalid header (rejects)
- Overdue scheduler: use Carbon::setTestNow() to travel past expected_duration_minutes
- Gate pass expiry: use Carbon::setTestNow() to test expire_at boundary

**Feature Test File Summary:**
List all test files with file path, test count, and key scenarios (18 scenarios from req v2 Section 12).

**Factory Requirements:**
```
VsmVisitorFactory   — mobile_no, optional id_number, visit_count defaults to 0
VsmVisitFactory     — visit_number (VSM-YYYYMMDD-XXXX format), status parameter, expected_date/time
VsmGatePassFactory  — pass_token (Str::uuid()), expires_at = NOW() + 24h, status=Issued
VsmBlacklistFactory — mobile_no or id_number, reason, valid_until (nullable)
VsmContractorFactory — pass_token (Str::uuid()), access_from/until, pass_status=Active
```

---

### Phase 3 Output Files
| File | Location |
|---|---|
| `VSM_Dev_Plan.md` | `{OUTPUT_DIR}/VSM_Dev_Plan.md` |

### Phase 3 Quality Gate
- [ ] All 8 web controllers + 1 API controller + 1 Report controller listed with all methods
- [ ] All 4 services listed with key method signatures (minimum 3 each)
- [ ] VisitorService check-in pseudocode present (12-step sequence including DB::transaction + lockForUpdate)
- [ ] SecurityAlertService emergency broadcast pseudocode present (5-step sequence with dedicated queue)
- [ ] All 10 FormRequests listed with their key validation rules
- [ ] All 14 FRs (FR-VSM-01 to FR-VSM-14) appear in at least one implementation phase
- [ ] All 4 implementation phases have: FRs covered, files to create, test count
- [ ] Seeder execution order documented (both seeders have no inter-dependencies)
- [ ] All 4 Artisan scheduled jobs listed with their schedule (15min / hourly / daily×2)
- [ ] Route list consolidated with middleware and FR reference (~70 web + 12 API routes)
- [ ] Public scan route (`GET .../gate-passes/{pass_token}/scan`) listed as unauthenticated
- [ ] CCTV webhook (`POST /api/v1/vsm/cctv/event`) listed as no-auth with X-CCTV-Secret header note
- [ ] Dashboard 60-second polling JS documented in SCR-VSM-01 view notes
- [ ] View count per area totals approximately 32 views
- [ ] Test strategy includes Queue::fake() for FlagOverdueVisitorsJob + EmergencyBroadcastJob
- [ ] BR-VSM-003 (duplicate check-in) concurrency test pattern documented
- [ ] BR-VSM-010 (lockdown gate-block) test pattern documented
- [ ] Carbon::setTestNow() time-travel approach documented for overdue + expiry tests
- [ ] DomPDF badge generation noted in GatePassController@badge with auto-print JS
- [ ] Emergency broadcast uses dedicated 'emergency' queue channel (not default queue)
- [ ] 4-phase implementation order justified: Phase 1 (core visitor) → Phase 2 (guard/contractor) → Phase 3 (emergency/reports) → Phase 4 (API/CCTV)

**After Phase 3, STOP and say:**
"Phase 3 (Development Plan) complete. Output: `VSM_Dev_Plan.md`. All 3 output files are ready:
1. `{OUTPUT_DIR}/VSM_FeatureSpec.md`
2. `{OUTPUT_DIR}/VSM_DDL_v1.sql` + Migration + 3 Seeders
3. `{OUTPUT_DIR}/VSM_Dev_Plan.md`
Development lifecycle for VSM (Visitor & Security Management) module is ready to begin."

---

## QUICK REFERENCE — VSM Module Tables vs Controllers vs Services

| Domain | vsm_* Tables | Controller(s) | Service(s) |
|---|---|---|---|
| Visitor Core | vsm_visitors, vsm_visits, vsm_gate_passes | VisitorController, VisitController, GatePassController | VisitorService (check-in/out, QR gen, blacklist check, pickup auth) |
| Access Control | vsm_contractors, vsm_pickup_auth, vsm_blacklist | ContractorController (contractors), VisitorController (pickup + blacklist) | ContractorAccessService, VisitorService (blacklist/pickup) |
| Guard Ops | vsm_guard_shifts, vsm_patrol_checkpoints, vsm_patrol_rounds, vsm_patrol_checkpoint_log | GuardShiftController, PatrolController | PatrolService (patrol + checkpoint QR) |
| Emergency | vsm_emergency_protocols, vsm_emergency_events | EmergencyController | SecurityAlertService (broadcast + lockdown + overdue flagging) |
| CCTV | vsm_cctv_events | Api\VsmApiController | — (webhook ingestion only) |
| Dashboard | — (reads vsm_visits live) | VisitorSecurityController | SecurityAlertService::flagOverdueVisitors() |
| Reports | — (reads all vsm_* tables) | ReportController | — (inline queries + DomPDF/fputcsv) |
| API / Kiosk | — | Api\VsmApiController | All 4 services (thin wrappers) |

# Module Knowledge: FrontOffice (FOF)
# Last Updated: 2026-06-27 (update pass — file counts verified against Herd/prime_ai)
# Completion Status: ~55–65% (all controllers/models/policies present; 118 views; 4 services only; 1 test; 0 migrations)

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix | `fof_*` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/FrontOffice_DDL_v1.sql` — 22 tables |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/FOF_FrontOffice_Requirement.md` |
| Routes | **302 lines** in `Modules/FrontOffice/routes/web.php` (221 named route entries; re-verified 2026-06-27) |
| Controllers | **21** actual (**corrected from 16–18 proposed**; extras: `FrontOfficeController` base, `FofMenuController`, `VisitorPurposeController` as standalone) |
| Models | **22** actual (matches DDL table count exactly): Appointment, CertificateRequest, Circular, CircularDistribution, CommunicationLog, DispatchRegister, EarlyDeparture, EmailTemplate, EmergencyContact, FeedbackForm, FeedbackResponse, FofComplaint, GatePass, KeyRegister, LostFound, Notice, PhoneDiary, PostalRegister, SchoolEvent, SmsLog, Visitor, VisitorPurpose |
| Services | **4** actual (**corrected from 6 proposed**): CircularService, EarlyDepartureService, GatePassService, VisitorService — **missing: FeedbackService, CertificateIssuanceService** |
| FormRequests | **10** actual (matches ~10 proposed): AppointmentRequest, DispatchRegisterRequest, EarlyDepartureRequest, IssueGatePassRequest, KeyRegisterRequest, LostFoundRequest, PhoneDiaryRequest, PostalRegisterRequest, RegisterVisitorRequest, StoreVisitorPurposeRequest |
| Policies | **13** actual (**corrected from 4 proposed** — 3× undercount): AppointmentPolicy, CertificateRequestPolicy, CircularPolicy, CommunicationPolicy, EarlyDeparturePolicy, EmergencyContactPolicy, FeedbackFormPolicy, FofComplaintPolicy, GatePassPolicy, NoticePolicy, SchoolEventPolicy, VisitorPolicy, VisitorPurposePolicy |
| Blade Views | **118** actual (corrected from ~28-screen estimate — 4× screen count) |
| Tests | **1 file** (`tests/Feature/AppointmentControllerTest.php`) |
| Jobs | **1** actual: `EarlyDepartureAttSyncJob` (ATT sync is queued — not synchronous as req doc implied) |
| Events | **0** — no Events/ directory |
| Seeders | **3** actual (`FofSeederRunner`, `FofVisitorPurposeSeeder`, `FrontOfficeDatabaseSeeder`) |
| Artisan Commands | **0 confirmed** — `fof:flag-overstay` proposed but not found as Command file |
| Migrations | **0** — module uses DDL directly |
| UI Screens | 28 |
| Business Rules | 15 (BR-FOF-001 to BR-FOF-015) |
| FRD | Not yet generated |

---

## DDL Layer Structure (22 tables)

| Layer | Tables |
|-------|--------|
| Layer 1 (no fof_* deps) | `fof_visitor_purposes`, `fof_emergency_contacts`, `fof_notices`, `fof_school_events`, `fof_email_templates`, `fof_feedback_forms`, `fof_key_register` |
| Layer 2 (deps Layer 1 + cross-module) | `fof_visitors`, `fof_gate_passes`, `fof_early_departures`, `fof_phone_diary`, `fof_postal_register`, `fof_dispatch_register`, `fof_appointments`, `fof_lost_found`, `fof_certificate_requests`, `fof_complaints` |
| Layer 3 (deps Layer 2) | `fof_circulars`, `fof_feedback_responses` |
| Layer 4 (deps Layer 3) | `fof_circular_distributions`, `fof_communication_logs`, `fof_sms_logs` |

---

## Feature Groups

| Phase | Feature Group | FR | Tables |
|-------|------------|-----|--------|
| Core | Visitor Management | FR-FOF-01 | `fof_visitor_purposes`, `fof_visitors` |
| Core | Gate Pass | FR-FOF-02 | `fof_gate_passes` |
| Core | Student Early Departure | FR-FOF-03 | `fof_early_departures` |
| Core | Phone Call Log | FR-FOF-04 | `fof_phone_diary` |
| Core | Postal / Courier Register | FR-FOF-05 | `fof_postal_register` |
| Core | Dispatch Register | FR-FOF-06 | `fof_dispatch_register` |
| Comm | Circular Management | FR-FOF-07 | `fof_circulars`, `fof_circular_distributions` |
| Comm | Digital Notice Board | FR-FOF-08 | `fof_notices` |
| Core | Appointment Scheduling | FR-FOF-09 | `fof_appointments` |
| Support | Lost and Found | FR-FOF-10 | `fof_lost_found` |
| Support | Key Management | FR-FOF-11 | `fof_key_register` |
| Support | Emergency Contacts | FR-FOF-12 | `fof_emergency_contacts` |
| Admin | Certificate Request & Issuance | FR-FOF-13 | `fof_certificate_requests` |
| Admin | Complaint Handling (Front-Office) | FR-FOF-14 | `fof_complaints` |
| Admin | Feedback Collection | FR-FOF-15 | `fof_feedback_forms`, `fof_feedback_responses` |
| Comm | Email / SMS Communication | FR-FOF-16 | `fof_communication_logs`, `fof_email_templates`, `fof_sms_logs` |
| Comm | School Calendar Events | FR-FOF-17 | `fof_school_events` |

---

## Known Gaps & Open Issues

### Implementation Blockers (Prerequisites)

| # | Prerequisite | Owner | Blocks |
|---|-------------|-------|--------|
| P1 | SYS, SCH, STD modules complete | System / SchoolSetup / StudentProfile | Almost all FOF features |
| P2 | NTF module complete | Notification | Circular distribution, gate pass alerts, cert notifications |
| P3 | ATT module complete | Attendance | Early departure sync (FR-FOF-03) |
| P4 | StudentFee (FIN) fee clearance service | StudentFee | TC_Copy / Migration certificate issuance (BR-FOF-005) |
| P5 | CMP module complete | Complaint | Complaint escalation from FOF (FR-FOF-14.2) |
| P6 | VSM module pending | VSM | `vsm_visitor_id` FK on `fof_visitors` currently omitted from DDL |

### FK Omitted in DDL

- `vsm_visitors.id` FK on `fof_visitors.vsm_visitor_id` is **commented out** — VSM module does not yet exist. Must be added once VSM DDL is applied.

### Table Prefix Note

RBS spec (Module M appendix) uses prefix `fro_`. The platform standardizes on `fof_` per the module code (FOF). **Do not confuse** — all actual tables use `fof_*`.

---

## Design Decisions Made

1. **`fof_circular_distributions` is append-only immutable log**: No `deleted_at`, no `updated_by`. Records are never soft-deleted. Captures per-recipient NTF delivery status (Queued/Sent/Delivered/Failed) from the circular distribution event.

2. **Government inspection visitor records are permanently retained**: When `fof_visitor_purposes.is_government_visit = 1`, `VisitorPolicy::delete()` blocks deletion. CBSE/State Board inspection visits must never be deleted. Seeded purpose `GOVT_INSPECTION` has this flag.

3. **Postal register records lock after acknowledgement (BR-FOF-009)**: Once `acknowledged_at` is set, `PostalRegisterController::update()` is blocked. The record is read-only after receipt acknowledgement.

4. **Circular editing blocked after approval (BR-FOF-008)**: `CircularController::update()` blocked when `status` is `Approved` or `Distributed`. A new version must be created. Rejection returns status to `Draft` with notes.

5. **Anonymous feedback enforces NULL user ID (BR-FOF-010)**: `FeedbackController::publicSubmit()` enforces `respondent_user_id = NULL` when `is_anonymous = 1`. Public token-based form URL (`/feedback/{token}`) requires no authentication.

6. **Certificate `cert_number` is UNIQUE but nullable**: MySQL's UNIQUE constraint allows multiple NULL values — `cert_number` is NULL until the certificate is physically issued. Each issued cert gets a type-prefixed number (BON-YYYY-NNN, CHAR-YYYY-NNN, etc.). Uniqueness is enforced at the DB level post-issuance.

7. **Early departure `att_sync_status` must not fail silently (BR-FOF-013)**: `EarlyDepartureService::syncAttendance()` called after store. Failed sync surfaces prominently on receptionist dashboard; retry queue used. ATT must be complete before FOF early departure can be used.

8. **Emergency notices bypass display dates (BR-FOF-014)**: `NoticeBoardController` filters include `is_emergency = 1` regardless of `display_from`/`display_until`. This cannot be toggled.

9. **Only one active gate pass per student at a time (BR-FOF-004)**: Validation query in `IssueGatePassRequest` checks for any existing pass in statuses `Pending_Approval`, `Approved`, or `Exited`. Second pass creation blocked until current one is `Returned` or `Cancelled`.

10. **TC_Copy/Migration certs require fee clearance (BR-FOF-005)**: `CertificateIssuanceService` checks StudentFee module before generating PDF. Outstanding fees block issuance.

11. **Aadhar numbers stored in full; displayed masked (BR-FOF-015)**: `id_proof_number` stored complete in DB (follow tenant encryption policy). UI shows only last 4 digits.

12. **Appointment slot conflict check via composite index**: `idx_fof_apt_slot` on `(with_user_id, appointment_date, start_time, end_time)` supports the slot availability check before booking.

13. **Key re-issue blocked without return (BR-FOF-012)**: `KeyRegisterController::issue()` checks `status` before issuing. Key with status `Issued` or `Overdue` cannot be issued to another person.

14. **FOF vs VSM distinction**: VSM = gate security booth (biometric, vehicle log). FOF = inside campus reception (registers, circulars, certificates). Visitor pre-registered at VSM gate is handed off to FOF via `vsm_visitor_id` FK (once VSM module exists).

---

## Cross-Module Dependencies

### Inbound (FOF reads from / integrates with)

| Module | Tables / Channels | Integration Point |
|--------|------------------|------------------|
| System (SYS) | `sys_users`, `sys_media`, `sys_activity_logs` | Auth, staff lookup, file storage for photos + cert PDFs, audit |
| SchoolSetup (SCH) | `sch_organizations`, `sch_classes`, `sch_sections` | School branding on certs; class/section for circular targeting |
| StudentProfile (STD) | `std_students` | Gate pass FK, early departure FK, certificate request FK |
| Attendance (ATT) | Service call | Early departure logs absence for remaining periods |
| Notification (NTF) | Email + SMS channels | Circular distribution, gate pass parent notification, cert notifications |
| StudentFee (FIN) | Balance check service | TC_Copy/Migration certificate fee clearance before issuance |
| Complaint (CMP) | `cmp_complaints` | FOF complaint escalation creates linked CMP record |
| VSM | `vsm_visitors` | Pre-registered visitor handoff (FK pending VSM creation) |
| GlobalMaster (GLB) | Country/state | Visitor address dropdowns, ID proof types |

### Outbound (Modules that depend on FOF)

| Module | What It Reads |
|--------|--------------|
| PPT (Parent Portal) | `fof_circulars`, `fof_notices`, `fof_school_events`, `fof_certificate_requests` |
| STP (Student Portal) | `fof_notices`, `fof_school_events`; submits cert requests |
| VSM | `fof_visitors` for visitor pass status; posts arrival notifications |

---

## Implementation Sequence (Recommended — per V2 Section 11.3)

| Phase | Components |
|-------|-----------|
| Prerequisites | SYS + SCH + STD complete; NTF complete; ATT complete |
| FOF Phase 1 | Core Registers: Visitor + Gate Pass + Early Departure + Phone Diary + Postal + Dispatch |
| FOF Phase 2 | Communication: Circulars + Notice Board + School Events |
| FOF Phase 3 | Certificates + Complaint Handling |
| FOF Phase 4 | Appointments + Lost & Found + Key Management + Emergency Contacts |
| FOF Phase 5 | Feedback Forms + Bulk Email/SMS Communication |

---

## Artisan Commands

| Command | Purpose | Schedule |
|---------|---------|----------|
| `fof:flag-overstay` | Flag visitors not checked out by school closing time as `Overstay` | Daily at configurable school closing time |

---

## State Machines Summary

| FSM | States |
|-----|--------|
| Visitor | `In` → `Out` / `Overstay` (cron) |
| Gate Pass | `Pending_Approval` → `Approved` / `Rejected` → `Exited` → `Returned` / `Cancelled` |
| Circular | `Draft` → `Pending_Approval` → `Approved` → `Distributed` / `Recalled` |
| Certificate Request | `Pending_Approval` → `Approved` / `Rejected` → `Issued` / `Cancelled` |
| Appointment | `Pending` → `Confirmed` → `Completed` / `No_Show` / `Cancelled` |
| Complaint | `Open` → `In_Progress` → `Resolved` / `Escalated` / `Closed` |
| Lost & Found | `Unclaimed` → `Claimed` / `Disposed` / `Returned_to_Authority` |
| Key | `Available` → `Issued` → `Overdue` / `Returned` / `Lost` |

---

## Known Gaps & Open Issues (as of 2026-06-27)

| Priority | Gap | Detail |
|----------|-----|--------|
| P1 | **Only 1 test file** | `AppointmentControllerTest` only. Gate pass concurrency (BR-FOF-004 — one active pass per student), circular approval FSM, visitor overstay flagging, anonymous feedback null enforcement, and certificate fee-clearance check (BR-FOF-005) are all high-risk without coverage. |
| P1 | **`FeedbackService` not created** | `FeedbackController` likely handles all feedback logic directly — fat controller risk. `FeedbackFormPolicy` exists but no service to encapsulate form lifecycle, token generation, or response aggregation. |
| P1 | **`CertificateIssuanceService` not created** | Design Decision D10 references `CertificateIssuanceService` checking StudentFee module for fee clearance before PDF generation. No such service file found — this logic is likely in `CertificateRequestController` directly. Fee-clearance check for TC_Copy/Migration certs is P1 risk without service isolation. |
| P1 | **`fof:flag-overstay` Artisan command not found** | Proposed as daily cron to auto-flag visitors not checked out by school closing time. Without it, `Overstay` status is never set — visitor FSM terminal state is unreachable. |
| P1 | **0 migrations** | Cannot bootstrap a fresh tenant via `artisan migrate`. 22 tables exist only in DDL. |
| P2 | **0 Events/Listeners** | No Events/ directory. NTF dispatch for gate pass parent alerts, circular distribution, and cert notifications (listed in cross-module map) likely called directly from controllers. |
| P2 | **Controller logic completeness unknown** | 21 controllers present but FSM enforcement, fee-clearance checks, ATT sync, and CMP escalation logic depth unverified. Technical Audit needed. |
| P2 | **`EarlyDepartureAttSyncJob` — ATT dependency** | ATT sync implemented as a queued job (not synchronous as req doc implied). Good design — but requires ATT module to be fully operational. If ATT is not ready, the job fails silently and `att_sync_status` stays `pending`. |
| P3 | **VSM FK still omitted** | `vsm_visitor_id` FK on `fof_visitors` remains commented out — VSM module does not yet exist. |
| P3 | **`FrontOfficeController` scope unknown** | Base controller exists but its role is unclear — navigation hub or GOD controller risk? |

---

## Lessons Learned

- [2026-06-27 | Update] Module was seeded as "0% Greenfield" without filesystem check. Actual: 21 ctrl, 22 models, 4 services, 13 policies, 10 FormRequests, 118 views, 302 route lines — ~55–65% complete. Standard pattern repeated.
- [2026-06-27 | Update] **Policy count: 4 proposed → 13 actual** — biggest proportional seeding error in this category across all modules audited. Req docs rarely list all policy classes; only "notable" ones mentioned. Always `ls app/Policies/`.
- [2026-06-27 | Update] **Services can be OVER-counted AND under-counted.** FOF proposed 6 services; only 4 exist. Two proposed services (`FeedbackService`, `CertificateIssuanceService`) named in design decisions but not created as files. Design Decision references are not the same as implemented files.
- [2026-06-27 | Update] **Views are 4× screen count (118 views vs 28 screens).** Consistent with all other modules in audit. Screen count is not a usable proxy for blade file count.
- [2026-06-27 | Update] **`EarlyDepartureAttSyncJob` as queued Job (not synchronous call)** is the correct pattern for cross-module side effects — avoids blocking the receptionist's save action. Req doc implied synchronous call; actual implementation is better. Always verify implementation class type.

---

## Pending Next Steps

- [ ] Generate FRD → `act as Business Analyst` → "create an FRD for FrontOffice"
- [ ] Create `FeedbackService` — extract token generation, form lifecycle, response aggregation from controller
- [ ] Create `CertificateIssuanceService` — extract certificate PDF generation + FIN fee-clearance check from `CertificateRequestController`
- [ ] Create `fof:flag-overstay` Artisan command (daily scheduler for visitor overstay detection)
- [ ] Create 22 tenant migrations (4-layer order; `vsm_visitor_id` FK migration remains commented until VSM ready)
- [ ] Add tests: gate pass one-active-per-student guard (BR-FOF-004), anonymous feedback null user_id (BR-FOF-010), postal register lock after acknowledgement (BR-FOF-009), visitor overstay FSM
- [ ] Code Gap Analysis → `act as Technical Auditor` — verify controller logic completeness, fee-clearance chain, CMP escalation integration, NTF dispatch pattern

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | Knowledge file seeded from V2 requirement doc (FOF_FrontOffice_Requirement.md v2) + DDL (FrontOffice_DDL_v1.sql). Status incorrectly recorded as 0% Greenfield — actual code not checked at seeding. |
| 2026-06-27 | Business Analyst | Update pass: verified all file counts against prime_ai/Modules/FrontOffice/. Status corrected to ~55–65%. Controllers 16→21, models ~22→22 (confirmed), services 6→4 (FeedbackService + CertificateIssuanceService missing), policies 4→13 (3× undercount), FormRequests ~10→10 (confirmed), views 28-screen estimate→118, routes 302 lines/221 named. Jobs: 1 (EarlyDepartureAttSyncJob as queued — not synchronous). Artisan command `fof:flag-overstay` NOT found as file. 0 Events, 1 test file (AppointmentControllerTest), 0 migrations. |

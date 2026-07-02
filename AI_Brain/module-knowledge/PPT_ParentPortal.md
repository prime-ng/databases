# Module Knowledge — PPT: Parent Portal
**Last Updated:** 2026-06-29 | **Agent:** pa-business-analyst | **Sources:** DDL v2, tenant migrations, live code `ls`, V2 requirement doc, student-parent-portal.md memory, V1 screen specs (12 files)

---

## Module Facts

| Field | Value |
|---|---|
| Module Name | ParentPortal |
| Module Code | PPT |
| Table Prefix | `ppt_` |
| DB Layer | tenant_db |
| Route Prefix | `/parent-portal` |
| Route Name Prefix | `parent-portal.` (NOTE: V2 spec used `ppt.` but live routes use `parent-portal.`) |
| Laravel Namespace | `Modules\ParentPortal` |
| Auth Mechanism | Custom `ParentPortalMiddleware` (NOT Spatie roles; PARENT user_type enforcement) |
| Module Type | Tenant — parent/guardian-facing self-service portal |
| Status | ~40–45% scaffolded (corrected from "0% Greenfield" in V2) |

---

## Component Counts (verified vs live filesystem 2026-06-29)

| Component | modules-map (2026-06-21) | Verified Count | Notes |
|---|---|---|---|
| Controllers | 28 | **28** | 21 web + 5 Api/ + 2 Mobile/ |
| Models | 6 | **6** | ConsentForm, ConsentFormResponse, Event, EventRsvp, ParentDocumentRequest, ParentSession |
| Services | 1 | **1** | ParentContextService only; 4 others planned but absent |
| FormRequests | 0 | **22** | modules-map WRONG — 22 FormRequests exist (see list below) |
| Policies | ~(not counted) | **1** | ConsentFormPolicy only; critical ParentChildPolicy MISSING |
| Middleware | — | **1** | ParentPortalMiddleware |
| Views | 45 | **45** | Confirmed matching |
| Seeders | 1 | **6** | ParentPortalDatabaseSeeder + 5 entity seeders |
| Route files | — | **3** | web.php, api.php, mobile_api.php |
| Route lines (web.php) | 267 | **267** | Confirmed |
| Tests | 0 | **0** | Only Pest.php config + empty Feature/ and Unit/ directories |
| Jobs | 0 | **0** | Confirmed |
| Events | 0 | **0** | EventServiceProvider present but empty |

### Controller Breakdown
**Web (21):** ParentAccountController, ParentAttendanceController, ParentComplaintController, ParentConsentFormController, ParentDashboardController, ParentDocumentController, ParentEventController, ParentFeeController, ParentFeePaymentController, ParentHealthController, ParentHomeworkController, ParentHostelController, ParentLearningController, ParentLeaveController, ParentNotificationController, ParentPortalController, ParentPtmController, ParentResultController, ParentTeacherController, ParentTimetableController, ParentTransportController

**Api/ (5):** ParentAttendanceApiController, ParentDashboardApiController, ParentLeaveApiController, ParentPtmApiController, ParentSessionApiController

**Mobile/ (2):** MobileParentController, MobileParentSessionController

### FormRequest Breakdown (22)
BookParentPtmRequest, CancelParentPtmRequest, LogoutDeviceParentAccountRequest, ParentPortalBaseRequest, PayCallbackParentDocumentRequest, PayInitiateParentDocumentRequest, RescheduleParentPtmRequest, RsvpParentEventRequest, SignParentConsentFormRequest, StoreParentComplaintRequest, StoreParentDocumentRequest, StoreParentLeaveRequest, StoreParentPortalRequest, SwitchChildParentDashboardRequest, UpdateLanguageParentAccountRequest, UpdateNotificationPreferencesParentAccountRequest, UpdateParentPortalRequest, UpdatePasswordParentAccountRequest, UpdateProfileParentAccountRequest, UpdateQuietHoursParentAccountRequest, WithdrawParentDocumentRequest, WithdrawParentLeaveRequest

---

## DDL Table Inventory (Three-Way Reconcile: DDL v2 ↔ Migrations ↔ Models)

**DDL source:** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/2-DDL_Tenant_Consolidated/ParentPortal_DDL_v2.sql`
**Tenant migrations:** 5 files dated 2026-06-16 in `database/migrations/tenant/`

| Table | In DDL v2 | Migration Exists | Model Exists | Purpose |
|---|---|---|---|---|
| `ppt_parent_sessions` | YES | YES (2026_06_16_105227) | YES (ParentSession) | Per-device portal state, active child, FCM/APNs/WebPush tokens, quiet hours |
| `ppt_event_rsvps` | YES | YES (2026_06_16_105226) | YES (EventRsvp) | Parent RSVPs and volunteer sign-ups; UNIQUE(event_id, guardian_id) |
| `ppt_document_requests` | YES | YES (2026_06_16_105225) | YES (ParentDocumentRequest) | Online requests for duplicate certificates; payment_reference UNIQUE (idempotency) |
| `ppt_consent_forms` | YES | YES (2026_06_16_105224) | YES (ConsentForm) | Admin-created digital consent forms; NEW in DDL v2 (not in V2 requirement table list) |
| `ppt_consent_form_responses` | YES | YES (2026_06_16_105228) | YES (ConsentFormResponse) | Immutable parent responses; NO deleted_at by design |
| `ppt_messages` | NO | **MISSING** | NO | V2 planned — teacher messaging; not created in DDL or migrations |
| `ppt_leave_applications` | NO | **MISSING** | NO | V2 planned — leave applications; not created; code (LeaveController + FormRequests) exists without backing table |

**Summary:** 5 tables deployed (DDL v2 + migrations), 2 planned tables absent. V2 requirement listed 6 tables (different set). DDL v2 added `ppt_consent_forms` and dropped `ppt_messages` and `ppt_leave_applications` relative to V2 spec list.

**Event.php model:** Wraps event records from EventEngine or a future shared events table — NOT an owned ppt_ table.

---

## DDL Design Decisions (Confirmed)

| Decision | Detail |
|---|---|
| `ppt_consent_form_responses`: NO deleted_at | Consent responses are legally immutable after signing; hard-delete prevention by DDL design |
| `ppt_event_rsvps`: NO deleted_at | RSVPs updated in-place (rsvp_status changed to Not_Attending to cancel) |
| `ppt_parent_sessions`: NO deleted_at | Sessions deactivated via is_active=0 on logout; stale sessions cleaned by cron |
| `ppt_document_requests`: payment_reference UNIQUE nullable | Razorpay idempotency guard — MySQL UNIQUE on nullable column allows multiple NULLs |
| `ppt_event_rsvps`.event_id | FK to Event Engine event table — event_id has NO FK constraint in DDL (EventEngine table may not exist yet; DDL comment notes this is "on hold" pending an events module) |
| `ppt_parent_sessions` UNIQUE on (guardian_id, device_token_fcm) | Prevents duplicate FCM registrations per guardian per device |

---

## Known Gaps & Open Issues

### P0 — Critical

| ID | Gap | Impact |
|---|---|---|
| GAP-PPT-P0-01 | `ParentChildPolicy` (IDOR prevention) NOT FOUND in module | Every data endpoint must verify guardian→child ownership; without this policy all endpoints are vulnerable to cross-child data access |
| GAP-PPT-P0-02 | `ppt_leave_applications` table MISSING from DDL and migrations | ParentLeaveController, StoreParentLeaveRequest, WithdrawParentLeaveRequest all exist but have no backing table — leave feature will fail at runtime |
| GAP-PPT-P0-03 | 0 tests (33 planned in V2) | IDOR, payment idempotency, OTP rate limiting, child-switch, and double-booking tests all absent; security correctness unverified |
| GAP-PPT-P0-04 | OTP login (FR-PPT-02) — no AuthController found in module | OTP-based passwordless login is a planned P0 feature; no controller, no OTP routes, no rate-limiter implementation found |

### P1 — High

| ID | Gap | Impact |
|---|---|---|
| GAP-PPT-P1-01 | `ppt_messages` table MISSING; no MessageController | Teacher messaging (FR-PPT-04) fully absent; may be delegated to CommonChat module |
| GAP-PPT-P1-02 | Only 1 of 5 planned services (ParentContextService) | ParentDashboardService, FeePaymentService, MessagingService, NotificationPreferenceService, PtmSchedulingService all absent — business logic likely in controllers |
| GAP-PPT-P1-03 | `ParentMessagePolicy` MISSING | If teacher messaging is built, this policy is required to restrict messaging to child's teachers |
| GAP-PPT-P1-04 | `ParentLeavePolicy` MISSING | Leave withdrawal rules not enforced at policy layer |
| GAP-PPT-P1-05 | OTP login infrastructure (SMS gateway, rate-limiter config) not in scope of this module | Requires MSG91/Twilio config and a dedicated AuthController for PPT login |
| GAP-PPT-P1-06 | PTM feature depends on Ptm module (`ptm_events`, `ptm_teacher_slots`, `ptm_bookings` tables) — cross-module FK undocumented | PtmController + FormRequests exist but integration contract not established |
| GAP-PPT-P1-07 | No queued jobs for notifications | Absence alerts, leave status notifications, PTM reminders all require queued dispatch |

### P2 — Medium

| ID | Gap | Impact |
|---|---|---|
| GAP-PPT-P2-01 | PWA service worker / offline caching not implemented | V2 NFR; mobile-first requirement partially unmet |
| GAP-PPT-P2-02 | Fee PDF receipt (DomPDF) — no view template found for invoice PDF | `fees/invoice-pdf.blade.php` exists but PDF generation service not wired |
| GAP-PPT-P2-03 | EnsureTenantHasModule not applied to PPT routes | Module feature-gating (PPT enabled for school) not enforced |
| GAP-PPT-P2-04 | Event model (Event.php) references event table from undefined source | ppt_event_rsvps FK event_id has no DB constraint; EventEngine table status unclear |

---

## Cross-Module Dependencies

### Hard Dependencies (portal cannot function without)
| Source Module | Tables Used | Purpose |
|---|---|---|
| StudentProfile | std_students, std_guardians, std_student_guardian_jnt | Core FK chain: parent→child linkage; can_access_parent_portal flag |
| SystemConfig | sys_users, sys_media, sys_school_settings | Authentication, file storage, visibility flags |
| StudentFee | fin_fee_invoices, fin_fee_installments, fin_transactions | Fee ledger + payment history |
| Payment | Razorpay integration | Online fee payment; duplicate document fee |

### Soft Dependencies (graceful degradation if absent)
| Source Module | Tables Used | Feature Affected |
|---|---|---|
| SmartTimetable / TimetableFoundation | tt_timetable_cells, tt_published_timetables | Child's weekly timetable; shows "not configured" if absent |
| LmsHomework | hmw_assignments, hmw_submissions | Homework tracker; shows empty state if absent |
| LmsExam | exm_results, exm_report_cards | Results + report cards; shows "not available" |
| Hpc | hpc_health_profiles, hpc_physical_assessments, hpc_counsellor_reports | Health reports; section hidden if HPC inactive |
| Transport | tpt_routes, tpt_vehicles, tpt_student_route_jnt | Bus info; shows "module not activated" |
| Notification | ntf_notifications, ntf_circulars | Notification inbox + push dispatch |
| Ptm | ptm_events, ptm_teacher_slots, ptm_bookings | PTM scheduling; ParentPtmController depends on Ptm module tables |
| CommonChat (or ppt_messages) | msg_threads, msg_messages (planned) | Teacher messaging — gap: ppt_messages not built; possibly delegated to CommonChat |
| EventEngine | Event records (FK: ppt_event_rsvps.event_id) | Event calendar RSVP; DDL comment notes event table is on hold |
| SchoolSetup | sch_classes, sch_sections, sch_holidays | Class context, holiday exclusion in leave day count |

---

## Design Decisions Made

| Decision | Detail | Date |
|---|---|---|
| Multi-child active context stored in DB (ppt_parent_sessions), not session only | Enables multi-device sync; parent on phone and tablet see same active child | 2026-03-26 (V2) |
| Custom middleware (`ParentPortalMiddleware`) instead of Spatie roles | PARENT users are not admin-panel users; separate auth flow | 2026-03-26 (V2) |
| Razorpay hosted checkout (not Razorpay.js embed) | PCI-compliant; school does not need PCI certification | 2026-03-26 (V2) |
| ppt_consent_form_responses: NO deleted_at | Consent signatures are legally immutable | 2026-06-04 (DDL v2) |
| ppt_consent_forms added to DDL v2 (not in V2 req list) | Admin needs a table to create/manage forms; previously assumed from EventEngine | 2026-06-04 (DDL v2) |
| Teacher messaging ppt_messages NOT created in DDL | Decision deferred; CommonChat module may handle messaging; ppt_messages on hold | 2026-06-16 (migrations) |
| ppt_leave_applications NOT created in DDL | Leave backing table deferred; may use a shared StudentLeave table or future Attendance module | 2026-06-16 (migrations) |
| Route name prefix is `parent-portal.` not `ppt.` as V2 spec stated | Live code uses `parent-portal.`; V2 spec was aspirational | 2026-06-29 (verified) |

---

## FRD Summary

| Field | Value |
|---|---|
| FRD file | PPT_FRD_Complete_2026-06-29.md (Complete Analysis Pack — no standalone FRD) |
| FRD date | 2026-06-29 |
| REQ count | 20 (REQ-PPT-001 through REQ-PPT-020) |
| BR count | 22 (BR-PPT-001 through BR-PPT-022) |
| RPT count | 6 (RPT-PPT-001 through RPT-PPT-006) |
| ENH count | 8 (ENH-PPT-001 through ENH-PPT-008) |
| Priority split | P0: 6 | P1: 12 | P2: 2 |
| Workflow count | 6 FSMs documented (Login/OTP, Leave, Fee Payment, Document Request, Consent Form, PTM Booking) |

---

## Lessons Learned

- [2026-06-29 | pa-business-analyst] PPT: modules-map listed 0 FormRequests — live filesystem has 22. Always `ls` the Requests/ folder before trusting the map.
- [2026-06-29 | pa-business-analyst] PPT: DDL v2 has 5 tables, not 6. V2 requirement listed 6 (different set). DDL promoted ppt_consent_forms from EventEngine dependency; deferred ppt_messages and ppt_leave_applications. Three-way reconcile (DDL ↔ migration ↔ model) is essential for PPT-class modules.
- [2026-06-29 | pa-business-analyst] PPT: "0% Greenfield" label in V2 requirement doc is misleading — module has 28 controllers, 22 FormRequests, 45 views, 3 route files, 5 DDL tables. Actual completion ~40-45%.
- [2026-06-29 | pa-business-analyst] PPT: The critical ParentChildPolicy (IDOR prevention) is absent — this is the #1 security blocker. All 28 web controllers lack the foundational authorization layer.
- [2026-06-29 | pa-business-analyst] PPT: Leave and messaging features have full controller/FormRequest/view scaffolding but no backing DB tables — classic "UI-first, schema-last" development gap.

---

## Pending Next Steps

1. **P0 — Write ParentChildPolicy** and register it in ParentPortalServiceProvider; apply to every controller method.
2. **P0 — Create ppt_leave_applications migration** (DDL spec in V2 requirement §5.2) and create ParentLeaveApplication model.
3. **P0 — Decide on teacher messaging**: either create ppt_messages table + MessageController, or integrate with CommonChat module; update integration contract.
4. **P0 — Write 33 Pest tests** (V2 §12 test scenarios), especially IDOR, payment idempotency, OTP rate limiting.
5. **P1 — Build ParentDashboardService**: batch-query aggregator (≤5 queries for all dashboard widgets).
6. **P1 — Build FeePaymentService + NotificationPreferenceService + PtmSchedulingService**.
7. **P1 — Establish Ptm module integration contract** (PTM feature in both Ptm and PPT modules).
8. **P1 — Add EnsureTenantHasModule** middleware to PPT route group.
9. **P2 — Wire DomPDF** to fees/invoice-pdf.blade.php and report card download.
10. **P2 — Clarify EventEngine FK** for ppt_event_rsvps.event_id — track against Event/SchoolSetup module.

---

## Version History

| Version | Date | Change | Agent |
|---|---|---|---|
| 1.0 (seed) | 2026-06-29 | Initial seed — DDL v2, migrations, live code verified; 22 FormRequests corrected from 0; 2 missing tables documented; completion revised to 40-45% | pa-business-analyst |

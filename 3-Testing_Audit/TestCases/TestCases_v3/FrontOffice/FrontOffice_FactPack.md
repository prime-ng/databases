# FrontOffice (FOF) — Module Fact Pack

> Built once per Step 0.5. Every per-feature generation agent MUST read this first and trust it,
> reading feature-specific source only to confirm that feature's columns / FormRequest / Blade selectors.
> Sources: `module_list.md`, `FrontOffice_DDL_v1.sql` (22 `CREATE TABLE`), `Modules/FrontOffice/routes/web.php`,
> controllers/models/services/requests under `APP_REPO/Modules/FrontOffice`, and
> `3-Audit_Reports/V1_Jun-2026/FrontOffice_Technical_Audit_2026-06-29.md`.

## 0. Identity (registry row)
| Field | Value |
|-------|-------|
| MODULE_NAME | FrontOffice |
| CODE | FOF |
| PREFIX | `fof_` |
| FOLDER_NAME | FrontOffice (`APP_REPO/Modules/FrontOffice`) |
| DDL_FILE_NAME | `FrontOffice_DDL_v1.sql` (`2-DDL_Tenant_Consolidated/`) |

## 1. Verified prefix + doc-vs-live divergence
- **Prefix `fof_` VERIFIED** against every `CREATE TABLE` in the DDL (22 tables, all `fof_*`). **No prefix divergence** — the registry prefix, DDL prefix, and live model `$table` values agree. No `DOC-FOF-###` prefix defect.
- **DB scope: TENANT-SIDE.** DDL header: `Database: tenant_db (one per tenant, no tenant_id columns)`. All tables `fof_*`. → Tenancy scaffolding REQUIRED (init in `setUp`, end in `tearDown`) per Rule Card #4/§A. This is NOT a prime/central feature (do not use `127.0.0.1:8000`/central base — use `DUSK_TENANT_URL` + `initializeTenantContext()`).
- **0 module migrations** on disk (`Modules/FrontOffice/database/migrations` is empty); live `fof_*` tables come from the consolidated tenant migration set / DDL. Per Rule Card #26, derive schema truth from LIVE `Schema::hasTable/hasColumn`/`SHOW INDEX`, not a module-local migration file, and fail-soft where the DDL lags.
- **`created_by`/`updated_by` are `BIGINT UNSIGNED NOT NULL` with NO FK** to `sys_users` (comment: "no FK constraint") on all tables. `fof_feedback_responses.created_by` has `DEFAULT 0`; others are NOT-NULL-no-default and are set by the controller (auto, not a form input — G48).

## 2. CREATE TABLE list (22 tables) — columns / UNIQUE / FK / soft-delete
> Every row: `id BIGINT UNSIGNED PK AI`; audit cols `created_by`/`updated_by BIGINT UNSIGNED NOT NULL` (no FK), `created_at`/`updated_at TIMESTAMP NULL`, `deleted_at TIMESTAMP NULL` (soft delete) — EXCEPT `fof_circular_distributions` (append-only: NO `updated_by`, NO `deleted_at`). `is_active TINYINT(1) NOT NULL DEFAULT 1` on all. Below lists the distinctive cols, UNIQUE keys, FKs.

**Layer 1 (7 tables — no fof_ deps):**
1. `fof_visitor_purposes` — `name`V100 NN, `code`V30 NN, `is_government_visit`TINY(1) D0, `sort_order`TINYINT-U D0. **UNIQUE** `uq_fof_vp_code(code)`.
2. `fof_emergency_contacts` — `contact_name`V100 NN, `organization`V150 null, `contact_type`ENUM(Hospital,Police,Fire,Ambulance,Transport,Utility,Parent_Emergency,Government,Other) NN, `primary_phone`V15 NN, `alternate_phone`V15 null, `address`V200 null, `notes`TEXT null, `sort_order`TINYINT-U D0. **No UNIQUE.**
3. `fof_notices` — `title`V200 NN, `content`LONGTEXT NN, `category`ENUM(Academic,Administrative,Sports,Cultural,Holiday,Emergency,Other) NN, `audience`ENUM(All,Students,Staff,Parents) D'All', `display_from`DATE NN, `display_until`DATE null, `is_pinned`TINY D0, `is_emergency`TINY D0, `attachment_media_id`INT-U null, `status`ENUM(Active,Archived) D'Active'. **No UNIQUE.** FK `attachment_media_id`→`sys_media` SET NULL.
4. `fof_school_events` — `event_name`V200 NN, `event_type`ENUM(Academic,Sports,Cultural,PTM,Holiday,Exam,Admission,Other) NN, `start_date`DATE NN, `end_date`DATE NN (>= start_date), `description`TEXT null, `venue`V200 null, `audience`ENUM(All,Students,Staff,Parents) D'All', `is_public`TINY D0, `notification_sent`TINY D0. **No UNIQUE.**
5. `fof_email_templates` — `name`V100 NN, `subject`V300 NN, `body`LONGTEXT NN, `module`V50 null. **No UNIQUE.**
6. `fof_feedback_forms` — `title`V200 NN, `description`TEXT null, `questions_json`JSON NN, `token`V64 NN, `is_anonymous_allowed`TINY D0. **UNIQUE** `uq_fof_ff_token(token)`.
7. `fof_key_register` — `key_label`V100 NN, `key_tag_number`V30 NN, `key_type`ENUM(Room,Lab,Vehicle,Cabinet,Store,Other) NN, `issued_to_user_id`INT-U null, `purpose`V200 null, `issued_at`/`expected_return_at`/`returned_at`DATETIME null, `status`ENUM(Available,Issued,Overdue,Lost) D'Available'. **No UNIQUE.** FK `issued_to_user_id`→`sys_users` SET NULL.

**Layer 2 (10 tables):**
8. `fof_visitors` — `pass_number`V25 NN (auto VP-YYYYMMDD-NNN), `vsm_visitor_id`BIGINT-U null (no FK, VSM pending), `visitor_name`V100 NN, `visitor_mobile`V15 NN, `visitor_email`V100 null, `id_proof_type`ENUM(Aadhar,Driving_License,Passport,Voter_ID,PAN,Employee_ID,Other) null, `id_proof_number`V50 null (PII — SEC-FOF-004), `address`V200 null, `organization`V100 null, `purpose_id`BIGINT-U NN, `person_to_meet`V100 null, `meet_user_id`INT-U null, `vehicle_number`V20 null, `accompanying_count`TINYINT-U D0, `photo_media_id`INT-U null, `in_time`DATETIME NN DEFAULT CURRENT_TIMESTAMP, `out_time`DATETIME null, `status`ENUM(In,Out,Overstay) D'In', `notes`TEXT null. **UNIQUE** `uq_fof_vis_pass_number(pass_number)`. FK `purpose_id`→`fof_visitor_purposes` RESTRICT, `meet_user_id`→`sys_users` SET NULL, `photo_media_id`→`sys_media` SET NULL.
9. `fof_gate_passes` — `pass_number`V25 NN (auto GP-), `person_type`ENUM(Student,Staff) NN, `student_id`INT-U null, `staff_user_id`INT-U null, `purpose`ENUM(Medical,Personal,Official,Sports,Family_Emergency,Other) NN, `purpose_details`V200 null, `exit_time`/`expected_return_time`/`actual_return_time`DATETIME null, `parent_notified`TINY D0, `status`ENUM(Pending_Approval,Approved,Rejected,Exited,Returned,Cancelled) D'Pending_Approval', `approved_by`INT-U null, `approved_at`DATETIME null, `rejection_reason`TEXT null. **UNIQUE** `uq_fof_gp_pass_number`. FK `student_id`→`std_students` RESTRICT, `staff_user_id`/`approved_by`→`sys_users` SET NULL.
10. `fof_early_departures` — `departure_number`V25 NN (auto ED-), `student_id`INT-U **NN**, `departure_time`DATETIME NN, `reason`ENUM(Medical,Family_Emergency,Event,Bereavement,Other) NN, `reason_details`V200 null, `collecting_person_name`V100 NN, `collecting_person_relation`ENUM(Father,Mother,Guardian,Sibling,Other) NN, `collecting_id_proof_type`ENUM(Aadhar,Driving_License,Passport,Other) null, `collecting_id_proof_number`V50 null, `parent_authorized`TINY D0, `att_sync_status`ENUM(Pending,Synced,Failed) D'Pending', `att_synced_at`DATETIME null, `notes`TEXT null. **UNIQUE** `uq_fof_ed_departure_number`. FK `student_id`→`std_students` RESTRICT.
11. `fof_phone_diary` — `call_type`ENUM(Incoming,Outgoing) NN, `call_date`DATE NN, `call_time`TIME NN, `caller_name`V100 NN, `caller_number`V15 null, `caller_organization`V100 null, `recipient_name`V100 null, `recipient_user_id`INT-U null, `purpose`V200 **NN**, `message`TEXT null, `action_required`TINY D0, `action_notes`TEXT null, `action_completed`TINY D0, `logged_by`INT-U null. **No UNIQUE.** FK `recipient_user_id`/`logged_by`→`sys_users` SET NULL.
12. `fof_postal_register` — `postal_type`ENUM(Inward,Outward) NN, `postal_number`V30 NN (auto IN-/OUT-YYYY-NNNN), `postal_date`DATE NN, `sender_name`/`sender_address`/`recipient_name`/`recipient_address` null, `document_type`ENUM(Letter,Courier,Parcel,Government_Notice,Cheque,Legal,Other) NN, `subject`V200 NN, `courier_company`/`tracking_number`/`department` null, `assigned_to_user_id`INT-U null, `acknowledgement_by`V100 null, `acknowledged_at`DATETIME null (LOCKS record — BR-FOF-009), `remarks`TEXT null. **UNIQUE** `uq_fof_pr_postal_number`. FK `assigned_to_user_id`→`sys_users` SET NULL.
13. `fof_dispatch_register` — `dispatch_number`V30 NN (auto DSP-YYYY-NNNN), `dispatch_date`DATE NN, `addressee_name`V100 NN, `addressee_address`V200 null, `subject`V200 NN, `document_type`ENUM(Letter,Notice,Legal,Certificate,Report,Circular,Other) NN, `dispatch_mode`ENUM(Hand,Post,Courier,Email,Fax) NN, `reference_number`V100 null, `copy_retained`TINY D1, `dispatched_by`INT-U null, `remarks`TEXT null. **UNIQUE** `uq_fof_dr_dispatch_number`. FK `dispatched_by`→`sys_users` SET NULL.
14. `fof_appointments` — `appointment_number`V25 NN (auto APT-), `appointment_type`ENUM(Parent_Teacher_Meeting,Principal_Meeting,Grievance,Admission_Enquiry,Other) NN, `with_user_id`INT-U **NN**, `visitor_name`V100 NN, `visitor_mobile`V15 NN, `visitor_email`V100 null, `purpose`V300 NN, `appointment_date`DATE NN, `start_time`/`end_time`TIME NN (end>start), `status`ENUM(Pending,Confirmed,Completed,Cancelled,No_Show) D'Pending', `confirmed_by`INT-U null, `confirmed_at`DATETIME null, `cancellation_reason`V300 null, `notes`TEXT null. **UNIQUE** `uq_fof_apt_appointment_number`. Composite KEY `idx_fof_apt_slot(with_user_id,appointment_date,start_time,end_time)` (overlap not enforced — VAL-FOF-001). FK `with_user_id`→`sys_users` RESTRICT, `confirmed_by`→`sys_users` SET NULL.
15. `fof_lost_found` — `item_number`V25 NN (auto LF-YYYY-NNNN), `item_description`V300 NN, `category`ENUM(Electronics,Clothing,Stationery,ID_Card,Money,Jewellery,Books,Sports,Other) NN, `found_date`DATE NN, `found_location`V200 NN, `found_by_name`V100 NN, `found_by_user_id`INT-U null, `photo_media_id`INT-U null, `status`ENUM(Unclaimed,Claimed,Disposed,Returned_to_Authority) D'Unclaimed', `claimant_name`V100 null, `claimant_contact`V15 null, `claimed_date`DATE null, `disposal_notes`TEXT null. **UNIQUE** `uq_fof_lf_item_number`. FK `found_by_user_id`→`sys_users` SET NULL, `photo_media_id`→`sys_media` SET NULL.
16. `fof_certificate_requests` — `request_number`V25 NN (auto CERT-), `student_id`INT-U **NN**, `cert_type`ENUM(Bonafide,Character,Fee_Paid,Study,TC_Copy,Migration,Conduct,Other) NN, `purpose`V200 NN, `copies_requested`TINYINT-U D1, `is_urgent`TINY D0, `applicant_name`V100 null, `applicant_contact`V15 null, `stages_json`JSON null, `status`ENUM(Pending_Approval,Approved,Rejected,Issued,Cancelled) D'Pending_Approval', `approved_by`INT-U null, `approved_at`DATETIME null, `rejection_reason`TEXT null, `cert_number`V30 null (UNIQUE-allows-NULL), `issued_at`DATETIME null, `issued_by`INT-U null, `issued_to`V100 null, `media_id`INT-U null. **UNIQUE** `uq_fof_cr_request_number`, `uq_fof_cr_cert_number`. FK `student_id`→`std_students` RESTRICT, `approved_by`/`issued_by`/`media_id`→`sys_users`/`sys_media` SET NULL.
17. `fof_complaints` — `complaint_number`V30 NN (auto FOF-CMP-YYYY-NNNNN), `complainant_name`V100 NN, `complainant_contact`V15 null, `complaint_type`ENUM(Academic,Facility,Staff_Behavior,Fee,Safety,Transportation,Food,Hygiene,Other) NN, `description`TEXT **NN**, `urgency`ENUM(Normal,Urgent,Critical) D'Normal', `assigned_to_user_id`INT-U null, `status`ENUM(Open,In_Progress,Resolved,Closed,Escalated) D'Open', `resolution_notes`TEXT null, `resolved_at`DATETIME null, `resolved_by`INT-U null, `cmp_complaint_id`INT-U null (escalation link). **UNIQUE** `uq_fof_cmp_complaint_number`. FK `assigned_to_user_id`/`resolved_by`→`sys_users` SET NULL, `cmp_complaint_id`→`cmp_complaints` SET NULL.

**Layer 3 (2 tables):**
18. `fof_circulars` — `circular_number`V30 NN (auto CIR-YYYY-NNNN), `title`V200 NN, `subject`V300 NN, `body`LONGTEXT NN, `audience`ENUM(Parents,Staff,Both,Specific_Class,Specific_Section) NN, `audience_filter_json`JSON null, `effective_date`DATE NN, `expires_on`DATE null, `attachment_media_id`INT-U null, `status`ENUM(Draft,Pending_Approval,Approved,Distributed,Recalled) D'Draft' (edit locked after Approved — BR-FOF-008), `approved_by`/`distributed_by`INT-U null, `approved_at`/`distributed_at`DATETIME null. **UNIQUE** `uq_fof_cir_circular_number`. FK `approved_by`/`distributed_by`→`sys_users`, `attachment_media_id`→`sys_media` SET NULL.
19. `fof_feedback_responses` — `feedback_form_id`BIGINT-U **NN**, `respondent_user_id`INT-U null (NULL=anon), `respondent_name`V100 null, `is_anonymous`TINY D0, `responses_json`JSON NN, `submitted_at`TIMESTAMP NN DEFAULT CURRENT_TIMESTAMP, `created_by`BIGINT-U NN **DEFAULT 0** (anon=0). **No UNIQUE.** FK `feedback_form_id`→`fof_feedback_forms` RESTRICT, `respondent_user_id`→`sys_users` SET NULL.

**Layer 4 (3 tables):**
20. `fof_circular_distributions` — **APPEND-ONLY: NO `updated_by`, NO `deleted_at`.** `circular_id`BIGINT-U NN, `recipient_user_id`INT-U NN, `channel`ENUM(Email,SMS,Push) NN, `status`ENUM(Queued,Sent,Delivered,Failed) D'Queued', `sent_at`/`delivered_at`/`read_at`TIMESTAMP null, `ntf_log_id`BIGINT-U null (no FK). **No UNIQUE.** FK `circular_id`→`fof_circulars` RESTRICT, `recipient_user_id`→`sys_users` RESTRICT.
21. `fof_communication_logs` — `template_id`BIGINT-U null, `channel`ENUM(Email,SMS) NN, `subject`V300 null, `body`TEXT **NN**, `recipient_group`V100 NN, `total_recipients`/`sent_count`/`failed_count`INT-U D0. **No UNIQUE.** FK `template_id`→`fof_email_templates` SET NULL.
22. `fof_sms_logs` — `communication_log_id`BIGINT-U NN, `recipient_user_id`INT-U NN, `mobile_number`V15 NN, `message`TEXT NN, `sms_units`TINYINT-U D1, `status`ENUM(Queued,Sent,Delivered,Failed) D'Queued', `sent_at`/`delivered_at`TIMESTAMP null, `gateway_response`TEXT null. **No UNIQUE.** FK `communication_log_id`→`fof_communication_logs` RESTRICT, `recipient_user_id`→`sys_users` RESTRICT.

**UNIQUE keys → mandatory duplicate-rejection tests (G43):** vp.code, ff.token, vis.pass_number, gp.pass_number, ed.departure_number, pr.postal_number, dr.dispatch_number, apt.appointment_number, lf.item_number, cr.request_number, cr.cert_number, cmp.complaint_number, cir.circular_number. (Most are auto-generated → test the DB UNIQUE independently of the FormRequest — G48/G43.)

## 3. Controller → screen map & routes
- **Route file:** `Modules/FrontOffice/routes/web.php` (WEB routes registered here — Rule Card #24). Also `routes/api.php` (verify registration with `Route::has()` — Rule Card #23).
- **Two route groups:**
  - **Public (no auth):** `Route::middleware('throttle:30,1')->prefix('feedback')->name('fof.feedback.')` → `GET/POST /feedback/{token}` (`public`, `submit`). Used by Feedback feature's anonymous path.
  - **Authenticated + tenant:** `Route::middleware(['auth','verified'])->prefix('front-office')->name('fof.')`. All admin screens live here. URL base `/front-office/...`, route-name base `fof.`.
- **Model-bound RMB** on all detail routes (`{visitor}`, `{gatePass}`, `{cert}`, etc.). Trash/restore/force-delete use `{id}` (int) not RMB. **NOTE:** `trashed`/`restore`/`forceDelete`/`log`/`calendar`/`create` route lines are placed BEFORE `/{param}` to avoid conflicts — derive exact paths from `route:list`, never hand-write (F40).

| Controller | Screen (req file) | Feature | Route-name group | Primary table(s) |
|-----------|-------------------|---------|------------------|------------------|
| VisitorController (+ VisitorPurposeController) | visitor-management | VisitorManagement | `fof.visitors.*`, `fof.visitor-purposes.*` | fof_visitors (+ fof_visitor_purposes) |
| GatePassController | gate-passes | GatePass | `fof.gate-passes.*` | fof_gate_passes |
| EarlyDepartureController | early-departures | EarlyDeparture | `fof.early-departures.*` | fof_early_departures |
| PhoneDiaryController | phone-diary | PhoneDiary | `fof.phone-diary.*` | fof_phone_diary |
| PostalRegisterController (+ DispatchRegisterController) | postal-dispatch | PostalDispatch | `fof.postal-register.*`, `fof.dispatch-register.*` | fof_postal_register (+ fof_dispatch_register) |
| EmergencyContactController | emergency-contacts | EmergencyContact | `fof.emergency-contacts.*` | fof_emergency_contacts |
| CircularController | circulars | Circular | `fof.circulars.*` | fof_circulars (+ fof_circular_distributions) |
| NoticeBoardController (+ SchoolEventController) | notices-events | NoticesEvents | `fof.notices.*`, `fof.school-events.*` | fof_notices (+ fof_school_events) |
| CertificateRequestController | certificate-requests | CertificateRequest | `fof.certificates.*` | fof_certificate_requests |
| ComplaintController | complaints | Complaint | `fof.complaints.*` | fof_complaints |
| AppointmentController | appointments | Appointment | `fof.appointments.*` | fof_appointments |
| LostFoundController | lost-found | LostFound | `fof.lost-found.*` | fof_lost_found |
| KeyRegisterController | key-register | KeyRegister | `fof.keys.*` | fof_key_register |
| FeedbackController | feedback | Feedback | `fof.feedback.*` (+ public `fof.feedback.public/submit`) | fof_feedback_forms (+ fof_feedback_responses) |
| CommunicationController | communication | Communication | `fof.communication.*` | fof_communication_logs / fof_sms_logs / fof_email_templates |
| FrontOfficeDashboardController | reports-dashboard | ReportsDashboard | `fof.dashboard`, `fof.menu.*` | read-only across fof_* |

**Custom (non-CRUD) action verbs by feature** (each maps to a lifecycle/BC-SM TC): visitors `checkout`, `pass`, `toggleStatus`; gate-passes `approve`/`reject`/`exit`/`return`; early-departures `toggleStatus`; phone-diary `complete`; postal-register `acknowledge`; circulars `approve`/`distribute`; certificates `approve`/`reject`/`issue`/`download`/`log`; complaints `resolve`/`escalate`; appointments `confirm`/`cancel`/`complete`/`calendar`; lost-found `claim`; keys `issue`/`return`; feedback `report`/public `publicForm`/`publicSubmit`; communication `emailCompose`/`emailSend`/`emailTemplates`/`emailLogs`/`smsSend`/`smsLogs`. Every entity also has `toggle-status`, `trash/view`, `{id}/restore`, `{id}/force-delete`.

## 4. Permissions & activity log (per-module — do NOT assume the Class/HrStaff set)
- **Permission scheme:** `frontoffice.{entity}.{action}` enforced via **`Gate::authorize('frontoffice.<entity>.<action>')` string gates in every controller method** (114 distinct abilities). Entity slugs use HYPHENS (`frontoffice.dispatch-register.create`, `frontoffice.early-departure.update`, `frontoffice.emergency-contact.view`, `frontoffice.gate-pass.approve`). Actions: `view`/`viewAny`, `create`, `update`, `delete`, `restore`, `forceDelete`, plus workflow verbs (`approve`, `reject`, `issue`, `distribute`, `confirm`, `cancel`, `complete`, `resolve`, `escalate`, `claim`). **Grep the exact ability string per controller method at generation time** — dispatch-register uses `viewAny` while others use `view`.
  - **Permission-negative caveat (SEC-FOF-001):** gates are Spatie PERMISSION strings, NOT model-bound policy calls — so `VisitorPolicy::delete()`'s govt-retention guard is DEAD on the destroy/forceDelete paths. Test the OBSERVED behaviour (govt visitor IS deletable today) and record `DEV`=SEC-FOF-001, do not assert the intended block. Permission negatives still need a non-super-admin + `forgetCachedPermissions()` (Rule Card #31/#37) because `Gate::before` grants Super Admin everything.
- **Activity log:** module-wide helper **`activityLog($model, '<Event>', ['message'=>..., ...])`** (72 call sites). Event strings are **verb past-tense, verbatim per controller** — CONFIRMED from VisitorController: `'Created'`, `'Updated'`, `'Deleted'` (soft AND force both use `'Deleted'`), `'Restored'`, `'CheckedOut'`. Workflow controllers add their own verbs (expect `'Approved'`, `'Rejected'`, `'Issued'`, `'Distributed'`, `'Resolved'`, `'Escalated'`, `'Confirmed'`, `'Cancelled'`, `'Completed'`, `'Claimed'`, `'Returned'`, `'Acknowledged'` etc.). **This is NOT the `Stored`/`ToggelStatus` set and NOT HrStaff's `Trashed`.** Grep each feature's controller for its exact event strings before asserting (HARD RULE #2/#11).
- **Activity-log sink:** tenant-side (tenancy initialized) → the `activityLog()` helper writes via `Modules\GlobalMaster\Models\ActivityLog`, whose **`$table = 'sys_activity_logs'`** (VERIFIED at `Modules/GlobalMaster/app/Models/ActivityLog.php:14`; batch-1 VisitorManagement + CertificateRequest confirmed independently). Assert activity against **`sys_activity_logs`** — NOT `activity_logs` (a same-named tenant migration exists but the model does not bind to it). *(This corrects the earlier draft and diverges from the generic Rule Card #25 `activity_logs` wording — the model `$table` is the runtime truth; flagged for the maintainer to reconcile the general rule.)* Still confirm via the model `$fillable` + `Schema::hasTable` at generation time.

## 5. Tenancy scaffolding choice
- **TENANT-SIDE Dusk** (browser). No committed FrontOffice sibling test exists in `prime_testing/tests/Browser/Modules/` (FOF folder absent). **Mirror the nearest recent tenant-side Dusk sibling** — Vendor / Inventory / Hostel / HrStaff / Complaint (all CRUD-with-lifecycle, tenant-side). Use `extends DuskTestCase`, `initializeTenantContext()` in `setUp`, guarded `tenancy()->end()` in `tearDown` (Rule Card #1–#3). Resolve tenant via `Modules\Prime\Models\Domain` → `tenancy()->initialize($domain->tenant)`. Base URL from `DUSK_TENANT_URL`.
- Users: `App\Models\User` + `User::factory()` (Rule Card #5); supply NOT-NULL-no-default cols on any hand-built user (`emp_code`≤20, `short_name`, `prefered_language`, `user_type`) (#8).
- Endpoint/status assertions: use Laravel HTTP test methods (`getJson`/`postJson` → `assertStatus`/`assertForbidden`), NOT `Browser` (no `assertStatus`) (Rule Card #14).
- `sys_media` FKs (5 tables: notices, visitors.photo, lost_found.photo, certificate.media, circulars.attachment) — guard media/force-delete ops in try/catch; `sys_media` may be absent in test DB (Rule Card #11). Cross-module FKs `std_students` (gate-passes, early-departures, certificates) and `cmp_complaints` (complaints escalation) → wrap dependency access in try/catch + `markTestSkipped` (HARD RULE #9).

## 6. Known audit defects (from FrontOffice_Technical_Audit_2026-06-29.md) — Health 41/100, 0 P0, 9 P1, 6 P2, 3 P3
Carry these into each feature's Gap Analysis as `DEV-###` (audit-equivalent) with a proving test asserting CURRENT behaviour.

| ID | Sev | Feature(s) | Summary |
|----|-----|-----------|---------|
| DAT-FOF-001 | P1 | CertificateRequest | `issue()` has NO StudentFee clearance check for TC_Copy/Migration (BR-FOF-005) |
| BUG-FOF-002 | P1 | Circular | `distribute()` is a status-flip stub — no recipient resolution, no `fof_circular_distributions` rows, no NTF (BR-FOF-018/REQ-FOF-009) |
| SEC-FOF-001 | P1 | VisitorManagement | Govt-retention guard (BR-FOF-007) bypassed — string gate not model-bound policy; govt visitor deletable |
| JOB-FOF-001 | P1 | EarlyDeparture | `EarlyDepartureAttSyncJob` carries no tenant context / no `$timeout`; ATT sync can silently no-op |
| JOB-FOF-002 | P1 | VisitorManagement | `fof:flag-overstay` command never scheduled + not `tenants:run`-wrapped; `Overstay` state unreachable (BR-FOF-002) |
| VAL-FOF-001 | P1 | Appointment | Double-booking / slot overlap (BR-FOF-017) not enforced; `idx_fof_apt_slot` unused |
| SEC-FOF-002 | P1 | Feedback | Anonymous feedback stores `respondent_user_id=auth()->id()` unconditionally; `is_anonymous_allowed` ignored (BR-FOF-010) |
| BUG-FOF-001 | P1 | CertificateRequest, Complaint | `toggleStatus(): JsonResponse` unimported → HTTP 500 on live toggle-status routes (2 controllers) |
| SEC-FOF-003 | P1 | ALL (10 FormRequests) | `authorize(){return true;}` ×10 (D30) — no defense-in-depth fallback |
| DAT-FOF-002 | P2 | ALL with auto-number | Register-number generators use unlocked read-modify-write (race → dup numbers) |
| DAT-FOF-003 | P2 | PostalDispatch | `update()` bypasses acknowledgement lock (BR-FOF-009); locked postal still editable |
| DAT-FOF-004 | P2 | KeyRegister, GatePass | Key issue & gate-pass create lack row locks (BR-FOF-012/BR-FOF-004 race) |
| BUG-FOF-003 | P2 | Complaint | `escalate()` does not create linked CMP record (BR-FOF-020); only flips status |
| SEC-FOF-004 | P2 | VisitorManagement | `id_proof_number` (Aadhaar) stored plaintext, no encrypted cast, no masking accessor (BR-FOF-015) |
| PERF-FOF-001 | P2 | CertificateRequest, KeyRegister, Complaint, Appointment | Unbounded `->get()` / full active-student preload per render |
| DEAD-FOF-001 | P3 | Feedback | Commented-out expiry guards in public feedback (publicForm/publicSubmit) |
| BUG-FOF-004 | P3 | Complaint, CertificateRequest | Register-number formats deviate from BR-FOF-016 spec (CMP-/BON slash/CERT-) |
| ORM-FOF-001 | P3 | EarlyDeparture, VisitorManagement | Background paths write `updated_by=0` (non-existent user) |

## 7. Per-feature complexity tags (sizes read/coverage effort — single-pass, one model)
| Feature | Complexity | Why |
|---------|-----------|-----|
| VisitorManagement | Workflow | FSM In→Out→Overstay, checkout, govt-retention guard, PII, VSM handoff; + visitor-purposes CRUD |
| GatePass | Workflow | FSM Pending_Approval→Approved/Rejected→Exited→Returned/Cancelled; student|staff dual FK; parent NTF |
| EarlyDeparture | Workflow | ATT sync FSM (Pending/Synced/Failed); collecting-person audit; job tenancy defect |
| Circular | Workflow | FSM Draft→Pending_Approval→Approved→Distributed→Recalled; edit-lock after Approved; distribution stub |
| CertificateRequest | Workflow | FSM Pending_Approval→Approved/Rejected→Issued; multi-stage json; PDF issue; fee-gate defect; dup cert_number NULL |
| Complaint | Workflow | FSM Open→In_Progress→Resolved/Closed/Escalated; CMP escalation link |
| Appointment | Workflow | FSM Pending→Confirmed→Completed/Cancelled/No_Show; slot-overlap (unenforced); calendar |
| LostFound | Workflow | FSM Unclaimed→Claimed/Disposed/Returned_to_Authority; claim action |
| KeyRegister | Workflow | FSM Available→Issued→Overdue/Lost→returned; issue/return actions |
| Feedback | Workflow | Public token URL, anonymous submissions, questions_json/responses_json, report |
| Communication | Workflow | Bulk email/SMS send, template placeholders, per-recipient logs, multi-unit SMS |
| PostalDispatch | Workflow | Postal ack-lock FSM (BR-FOF-009) + dispatch CRUD (2 tables, 2 controllers) |
| NoticesEvents | CRUD | Notices (pinning/emergency bypass/display dates) + events (public/NTF) — 2 tables, flag logic, no deep FSM |
| PhoneDiary | CRUD | Call log + action-required/complete toggle |
| EmergencyContact | CRUD | Simple lookup directory, sort_order, contact_type ENUM |
| ReportsDashboard | Light | Read-only KPI dashboard + widget API endpoints; render/filter/permission/empty-state only (no CRUD matrix) |

## 8. Environment prerequisites (note in every Validation Report)
- **FrontOffice = `false` in `prime_testing/modules_statuses.json`** — module DISABLED → all `/front-office/*` routes 404 until enabled (Rule Card #19). This is an ENV prerequisite, not a code fix. MUST be flagged.
- `APP_ENV=testing` for Dusk CSRF bypass (#20); `sys_media` table may be absent (#11); validation 500-vs-422 tolerated (#41); stale route cache → `route:clear` prereq; ChromeDriver alignment (#41).

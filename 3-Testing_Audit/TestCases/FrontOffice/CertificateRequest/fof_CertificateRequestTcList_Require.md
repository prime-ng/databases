# FrontOffice · Certificate Request & Issuance — Test Cases + Manual Spec (Combined)

> Artifact 1 of 5. Combines Feature Information + Business Conditions + Test-Case List + Test-Method Index + Manual Test Steps (workflow/money paths) + Known Source Defects.
> Sources read: `Modules/FrontOffice/app/Http/Controllers/CertificateRequestController.php`, `…/Models/CertificateRequest.php`, `…/Policies/CertificateRequestPolicy.php`, `…/routes/web.php`, `…/resources/views/fof/certificates/*.blade.php`, `FrontOffice_DDL_v1.sql` (`fof_certificate_requests`), requirement `FrontOffice_v1/certificate-requests.md`, `FrontOffice_FactPack.md`, audit `FrontOffice_Technical_Audit_2026-06-29.md`.

---

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | FrontOffice (FOF) |
| Feature | CertificateRequest (Certificate Request & Issuance) |
| Primary table | `fof_certificate_requests` (prefix `fof_`, verified vs DDL `CREATE TABLE`) |
| Controller | `Modules\FrontOffice\Http\Controllers\CertificateRequestController` |
| Model | `Modules\FrontOffice\Models\CertificateRequest` (extends `App\Models\BaseModel`, `SoftDeletes`, `HasFactory`) |
| FormRequest | **NONE** — validation is inline via `$request->validate([...])` in `store()`/`update()`/`reject()`/`issue()` (no `Requests/*` class; SEC-FOF-003/D30 context) |
| URL base | `/front-office/certificates` (auth+verified+tenant middleware group; route-name group `fof.certificates.*`) |
| CRUD type | Workflow (FSM Pending_Approval → Approved/Rejected → Issued; + Cancelled enum, unreachable) |
| Soft delete | Yes (`deleted_at`; model uses `SoftDeletes`) — trash/restore/forceDelete routes present |
| Pagination | Yes (index: pending 20 + recent 20; log 30; trash 20) |
| Activity log | Tenant sink `Modules\GlobalMaster\Models\ActivityLog` (`activity_logs`) via `activityLog($cert, '<event>', [...])` |
| Activity events (verbatim) | `certificate_request_created`, `certificate_request_updated`, `certificate_request_deleted`, `certificate_approved`, `certificate_rejected`, `certificate_issued` |
| DB scope | TENANT-SIDE (tenant init required; not central) |
| Permission scheme | `frontoffice.certificate.{view,create,update,delete,issue,restore,forceDelete}` string gates via `Gate::authorize(...)` |

**Routes (verbatim from `routes/web.php`, prefix `front-office`, name `fof.`):**

| Verb | Path | Name | Method |
|------|------|------|--------|
| GET | `/certificates` | `fof.certificates.index` | index |
| GET | `/certificates/create` | `fof.certificates.create` | create |
| POST | `/certificates` | `fof.certificates.store` | store |
| GET | `/certificates/{cert}` | `fof.certificates.show` | show |
| GET | `/certificates/{cert}/edit` | `fof.certificates.edit` | edit |
| PUT | `/certificates/{cert}` | `fof.certificates.update` | update |
| DELETE | `/certificates/{cert}` | `fof.certificates.destroy` | destroy |
| PATCH | `/certificates/{cert}/approve` | `fof.certificates.approve` | approve |
| PATCH | `/certificates/{cert}/reject` | `fof.certificates.reject` | reject |
| PATCH | `/certificates/{cert}/issue` | `fof.certificates.issue` | issue |
| GET | `/certificates/{cert}/download` | `fof.certificates.download` | download |
| GET | `/certificates/log` | `fof.certificates.log` | log |
| GET | `/certificates/trash/view` | `fof.certificates.trashed` | trashed |
| GET | `/certificates/{id}/restore` | `fof.certificates.restore` | restore |
| DELETE | `/certificates/{id}/force-delete` | `fof.certificates.forceDelete` | forceDelete |
| POST/PATCH | `/certificates/{cert}/toggle-status` | `fof.certificates.toggleStatus` | toggleStatus |

---

## 2. Business Conditions

### BC-DB — DDL-derived (table `fof_certificate_requests`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `request_number` VARCHAR(25), NOT NULL, **UNIQUE** (`uq_fof_cr_request_number`); auto-generated `CERT-YYYYMMDD-NNN` | DDL / Controller `generateRequestNumber` |
| BC-DB-02 | `student_id` INT UNSIGNED, NOT NULL, **FK → std_students RESTRICT** (ON UPDATE CASCADE) | DDL |
| BC-DB-03 | `cert_type` ENUM(Bonafide,Character,Fee_Paid,Study,TC_Copy,Migration,Conduct,Other), NOT NULL | DDL |
| BC-DB-04 | `purpose` VARCHAR(200), NOT NULL | DDL |
| BC-DB-05 | `copies_requested` TINYINT UNSIGNED, NOT NULL, **DEFAULT 1** | DDL |
| BC-DB-06 | `is_urgent` TINYINT(1), NOT NULL, DEFAULT 0 | DDL |
| BC-DB-07 | `status` ENUM(Pending_Approval,Approved,Rejected,Issued,Cancelled), NOT NULL, DEFAULT 'Pending_Approval' | DDL |
| BC-DB-08 | `cert_number` VARCHAR(30), NULLable, **UNIQUE** (`uq_fof_cr_cert_number`); MySQL UNIQUE allows multiple NULLs | DDL / BR-FOF-006 |
| BC-DB-09 | Nullable cols: applicant_name(100), applicant_contact(15), stages_json(JSON), approved_by, approved_at, rejection_reason(TEXT), issued_at, issued_by, issued_to(100), media_id | DDL |
| BC-DB-10 | `created_by`/`updated_by` BIGINT UNSIGNED NOT NULL (no FK) — set by controller (auto) | DDL |
| BC-DB-11 | FKs `approved_by`/`issued_by` → sys_users SET NULL; `media_id` → sys_media SET NULL | DDL |
| BC-DB-12 | `deleted_at` TIMESTAMP NULL (soft delete) | DDL / model |

### BC-VAL — Validation (inline `$request->validate`)

| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | store: `student_id` required\|integer\|exists:std_students,id | Controller store() |
| BC-VAL-02 | store: `cert_type` required\|in:Bonafide,Character,Fee_Paid,Study,TC_Copy,Migration,Conduct,Other | Controller store() |
| BC-VAL-03 | store: `purpose` required\|string\|max:200 | Controller store() |
| BC-VAL-04 | store: `copies_requested` integer\|min:1\|max:10 (**note: max 10, spec says 1–5**) | Controller store() / DEV-FOF-CR-02 |
| BC-VAL-05 | update: adds `status` required\|in:Pending_Approval,Approved,Rejected,Issued; `rejection_reason` nullable\|max:500; `cert_number` nullable\|max:30; `issued_to` nullable\|max:100; `copies_requested` **required** | Controller update() |
| BC-VAL-06 | reject: `rejection_reason` required\|string\|max:500 | Controller reject() |
| BC-VAL-07 | issue: `issued_to` required\|string\|max:100 | Controller issue() |

### BC-AUTH — Authorization

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/show/log/download/trashed gated by `frontoffice.certificate.view` | Controller |
| BC-AUTH-02 | create/store gated by `frontoffice.certificate.create` | Controller |
| BC-AUTH-03 | edit/update/toggleStatus/**approve**/**reject** gated by `frontoffice.certificate.update` | Controller |
| BC-AUTH-04 | destroy gated by `frontoffice.certificate.delete` | Controller |
| BC-AUTH-05 | issue gated by `frontoffice.certificate.issue` | Controller |
| BC-AUTH-06 | restore/forceDelete gated by `frontoffice.certificate.restore` / `.forceDelete` | Controller |
| BC-AUTH-07 | Guest (unauthenticated) is redirected to `/login` (auth middleware) | Route group |

### BC-BIZ — Business rules

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `request_number` auto-generated `CERT-{Ymd}-{NNN}` (lockForUpdate); never a form input | Controller generateRequestNumber / G48 |
| BC-BIZ-02 | `cert_number` auto-generated at issuance `{TYPE3}/{Y}/{NNNN}` (e.g. `BON/2026/0001`) — slash format (BUG-FOF-004) | Controller generateCertNumber |
| BC-BIZ-03 | BR-FOF-005: issuing `TC_Copy`/`Migration` blocked if outstanding StudentFee balance > 0 | Controller issue() (fee-gate PRESENT) |
| BC-BIZ-04 | BR-FOF-006: `cert_number` UNIQUE, NULL until issued | DDL / issue() |
| BC-BIZ-05 | Index groups Pending_Approval (urgent-first) vs recent (non-pending); log = Issued only | Controller index()/log() |

### BC-SM — State machine (status lifecycle)

| ID | From | Trigger | To | Guard | Source |
|----|------|---------|----|-------|--------|
| BC-SM-01 | Pending_Approval | approve() | Approved | only from Pending_Approval; sets approved_by/at | Controller approve() |
| BC-SM-02 | Pending_Approval | reject() | Rejected | only from Pending_Approval; requires rejection_reason | Controller reject() |
| BC-SM-03 | Approved | issue() | Issued | only from Approved; requires issued_to; fee-gate for TC/Migration; sets cert_number/issued_* | Controller issue() |
| BC-SM-04 | !Pending_Approval | approve()/reject() | (rejected) | throws DomainException (HTTP 500) | Controller |
| BC-SM-05 | !Approved | issue() | (rejected) | throws DomainException (HTTP 500) | Controller |
| BC-SM-06 | Issued | download() | (PDF) | abort_if 404 unless Issued | Controller download() |
| BC-SM-07 | any | — | Cancelled | **UNREACHABLE**: enum + lifecycle include Cancelled, no controller transition sets it | DDL/req vs code — DEV-FOF-CR-03 |
| BC-SM-08 | any (Pending→Issued) | update() | Issued | **permissive**: update() whitelists status Issued + accepts cert_number, bypassing issue() fee-gate/auto-number | Controller update() — DEV-FOF-CR-04 |

### BC-REF / BC-INT — References & integration

| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `student_id` RESTRICT → cannot create with non-existent student | DDL |
| BC-INT-01 | Fee-gate reads `FeeStudentAssignment::forStudent()->active()` + `FeeInvoice` `balance_amount` (StudentFee module) | Controller issue() |
| BC-INT-02 | `media_id` → sys_media (PDF); may be absent in test DB (guard) | DDL / FactPack |

### BC-AUTO — Auto-managed fields (never form inputs — G48)

| ID | Field | Set by | Source |
|----|-------|--------|--------|
| BC-AUTO-01 | request_number | store() generateRequestNumber | Controller |
| BC-AUTO-02 | cert_number, issued_by, issued_at | issue() | Controller |
| BC-AUTO-03 | approved_by, approved_at | approve() | Controller |
| BC-AUTO-04 | created_by, updated_by | auth()->id() | Controller |
| BC-AUTO-05 | status | workflow verbs (create defaults Pending_Approval) | Controller |

---

## 3. Test Case List

### Positive (TC-P)

| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-P01 | Config | BC-DB-* | DDL | Full DDL↔app alignment matrix | Table/cols/casts/relations/scopes correct | test_cert_01 | Automated |
| TC-P02 | Config | BC-DB-01/08 | DDL | UNIQUE indexes present | request_number + cert_number UNIQUE | test_cert_02 | Automated |
| TC-P03 | Config | BC-DB-12 | DDL | Soft-delete col+trait independent | Both present | test_cert_03 | Automated |
| TC-P04 | Config | BC-DB nullability | DDL | Null/not-null posture matches DDL | Matches | test_cert_04 | Automated |
| TC-P05 | Biz | BC-BIZ-01/AUTO-01 | Controller | request_number code-managed | Not a form input; CERT- prefix | test_cert_10 | Automated |
| TC-P06 | Biz | BC-DB-05/06/07 | DDL | copies default 1, is_urgent 0, status Pending | Defaults applied | test_cert_11 | Automated |
| TC-P07 | Biz | BC-DB-06 | model | is_urgent boolean persists | true persists | test_cert_12 | Automated |
| TC-P08 | Biz | BC-BIZ-02 | Controller | cert_number generator code-managed | slash format present | test_cert_13 | Automated |
| TC-P09 | SM | BC-SM-01 | Controller | Approve Pending→Approved | approved_at set | test_cert_20 | Automated |
| TC-P10 | SM | BC-SM-02 | Controller | Reject Pending→Rejected | reason stored | test_cert_21 | Automated |
| TC-P11 | SM | BC-SM-03 | Controller | Issue Approved→Issued | cert_number+issued_at set | test_cert_22 | Automated |
| TC-P12 | Val | BC-DB-09 | DDL | Nullable fields accept NULL | Saves | test_cert_31 | Automated |
| TC-P13 | Val | BC-DB-04 | DDL | Exactly-200 purpose accepted | Saves | test_cert_32 | Automated |
| TC-P14 | Val | BC-DB-08 | DDL | Exactly-30 cert_number accepted | Saves | test_cert_33 | Automated |
| TC-P15 | Ref | BC-BIZ-04 | DDL | Multiple NULL cert_numbers allowed | Both save | test_cert_71 | Automated |
| TC-P16 | UI | BC-BIZ-05 | Blade | Index renders (or skip if disabled) | 'Certificate Requests' | test_cert_60 | Automated |
| TC-P17 | UI | — | Blade | Issued log page loads | No 500 | test_cert_61 | Automated |
| TC-P18 | UI | BC-VAL | Blade | Create form exposes real fields | field names present | test_cert_62 | Automated |
| TC-P19 | Log | events | Controller | Activity events verbatim | 6 events present | test_cert_90 | Automated |
| TC-P20 | Log | sink | model | Tenant activity_logs sink correct | table+event col | test_cert_91 | Automated |
| TC-P21 | Tenancy | BC-REF-01 | tenancy | Record scoped to tenant | Visible in tenant | test_cert_93 | Automated |

### Negative (TC-N)

| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N01 | DB | BC-DB-01..04/10 | DDL | Missing each NOT-NULL col rejected | DB constraint error | test_cert_30 | Automated |
| TC-N02 | DB | BC-DB-04 | DDL | Over-length purpose (>200) rejected/truncated | 1406 or ≤200 | test_cert_32 | Automated |
| TC-N03 | DB | BC-DB-01 | DDL | Duplicate request_number rejected | UNIQUE violation | test_cert_70 | Automated |
| TC-N04 | DB | BC-DB-08 | DDL | Duplicate non-null cert_number rejected | UNIQUE violation | test_cert_71 | Automated |
| TC-N05 | Ref | BC-REF-01 | DDL | Invalid student_id rejected | FK 1452 | test_cert_40 | Automated |
| TC-N06 | SM | BC-SM-04/05 | Controller | Illegal transitions guarded | DomainException | test_cert_23 | Automated |
| TC-N07 | SM | BC-SM-06 | Controller | Download requires Issued | abort_if 404 | test_cert_24 | Automated |
| TC-N08 | Auth | BC-AUTH-07 | route | Guest redirected to login | /login or 404 | test_cert_52 | Automated |
| TC-N09 | Auth | BC-AUTH-02/05 | Gate | Non-super-admin denied create/issue | Gate denies | test_cert_51 | Automated |
| TC-N10 | Security | XSS | Blade | Stored XSS in purpose escaped | No raw `<script>` | test_cert_92 | Automated |

### Dependency / Validation source (TC-D)

| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-D01 | Val | BC-VAL-01..04 | Controller | store() rules match DDL enum/range | strings present | test_cert_34 | Automated |
| TC-D02 | Val | BC-VAL-04 | Controller | copies range divergence documented | min:1\|max:10 | test_cert_35 | Automated |
| TC-D03 | Val | BC-VAL-06/07 | Controller | reject/issue require their fields | strings present | test_cert_36 | Automated |
| TC-D04 | Int | BC-INT-01 | Controller | Fee-gate present for TC/Migration | condition present | test_cert_41 | Automated |
| TC-D05 | Int | BC-INT-01 | model | StudentFee dep resolvable or skip | classes exist | test_cert_42 | Automated |
| TC-D06 | Auth | BC-AUTH-01..06 | Controller | All gates called | 7 gate strings | test_cert_50 | Automated |
| TC-D07 | SM | BC-SM-07 | code | Cancelled unreachable via controller | not set | test_cert_25 | Automated |
| TC-D08 | SM | BC-SM-08 | Controller | update() allows status jump (defect) | ruleset present | test_cert_72 | Automated |

---

## 4. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_cert_01_migration_model_and_request_configuration_are_correct | TC-P01 | Schema | 01–09 |
| 2 | test_cert_02_unique_indexes_present_on_live_schema | TC-P02 | Schema | 01–09 |
| 3 | test_cert_03_soft_delete_column_and_trait_are_independent | TC-P03 | Schema | 01–09 |
| 4 | test_cert_04_column_nullability_matches_ddl | TC-P04/TC-N01 | Schema | 01–09 |
| 5 | test_cert_10_request_number_generator_format_is_code_managed | TC-P05 | Biz/Auto | 10–19 |
| 6 | test_cert_11_copies_requested_defaults_to_one | TC-P06 | Biz | 10–19 |
| 7 | test_cert_12_is_urgent_flag_persists | TC-P07 | Biz | 10–19 |
| 8 | test_cert_13_cert_number_generator_is_code_managed | TC-P08 | Biz | 10–19 |
| 9 | test_cert_20_approve_transitions_pending_to_approved | TC-P09 | SM | 20–29 |
| 10 | test_cert_21_reject_transitions_pending_to_rejected | TC-P10 | SM | 20–29 |
| 11 | test_cert_22_issue_transitions_approved_to_issued | TC-P11 | SM | 20–29 |
| 12 | test_cert_23_illegal_transitions_are_guarded_in_source | TC-N06 | SM | 20–29 |
| 13 | test_cert_24_download_requires_issued_status | TC-N07 | SM | 20–29 |
| 14 | test_cert_25_cancelled_status_is_unreachable_via_controller | TC-D07 | SM | 20–29 |
| 15 | test_cert_30_missing_not_null_fields_are_rejected | TC-N01 | Val/DB | 30–39 |
| 16 | test_cert_31_nullable_fields_accept_null | TC-P12 | Val | 30–39 |
| 17 | test_cert_32_purpose_length_boundary | TC-P13/TC-N02 | Val | 30–39 |
| 18 | test_cert_33_cert_number_length_boundary | TC-P14 | Val | 30–39 |
| 19 | test_cert_34_store_validation_rules_match_ddl | TC-D01 | Val | 30–39 |
| 20 | test_cert_35_copies_requested_range_divergence_is_documented | TC-D02 | Val | 30–39 |
| 21 | test_cert_36_workflow_actions_require_their_fields | TC-D03 | Val | 30–39 |
| 22 | test_cert_40_invalid_student_fk_is_rejected | TC-N05 | FK | 40–49 |
| 23 | test_cert_41_issue_has_fee_clearance_guard_for_tc_and_migration | TC-D04 | Int | 40–49 |
| 24 | test_cert_42_studentfee_dependency_is_available_or_skipped | TC-D05 | Int | 40–49 |
| 25 | test_cert_50_controller_methods_call_expected_gates | TC-D06 | Auth | 50–59 |
| 26 | test_cert_51_non_super_admin_without_permission_is_denied | TC-N09 | Auth | 50–59 |
| 27 | test_cert_52_guest_is_redirected_to_login | TC-N08 | Auth | 50–59 |
| 28 | test_cert_60_index_renders_or_skips_when_module_disabled | TC-P16 | UI | 60–69 |
| 29 | test_cert_61_issued_log_page_loads_or_skips | TC-P17 | UI | 60–69 |
| 30 | test_cert_62_create_form_exposes_expected_fields | TC-P18 | UI | 60–69 |
| 31 | test_cert_70_duplicate_request_number_is_rejected | TC-N03 | Edge | 70–79 |
| 32 | test_cert_71_duplicate_cert_number_rejected_but_nulls_allowed | TC-N04/TC-P15 | Edge | 70–79 |
| 33 | test_cert_72_update_allows_direct_status_jump_bypassing_issue_guard | TC-D08 | Edge | 70–79 |
| 34 | test_cert_90_activity_log_events_are_verbatim | TC-P19 | Log | 90–99 |
| 35 | test_cert_91_tenant_activity_log_sink_is_correct | TC-P20 | Log | 90–99 |
| 36 | test_cert_92_stored_xss_in_purpose_is_escaped | TC-N10 | Security | 90–99 |
| 37 | test_cert_93_records_are_scoped_to_initialized_tenant | TC-P21 | Tenancy | 90–99 |

Total: **37 test methods.**

---

## 5. Manual Test Steps (workflow / money paths only)

### MT-1 — Full lifecycle: request → approve → issue (Bonafide, no fee-gate)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as user with `frontoffice.certificate.*`. Go to `/front-office/certificates`. | Certificate Requests screen; "New Request" button visible. |
| 2 | Click New Request; select an active student, cert_type=Bonafide, purpose="School admission proof", copies=1. Submit. | Redirect to show page; success "Certificate request CERT-YYYYMMDD-NNN submitted." DB check: `SELECT status,request_number FROM fof_certificate_requests WHERE id=? ` → `Pending_Approval`, `CERT-…`. Activity: event `certificate_request_created`. |
| 3 | On show page, click Approve. | Success "Request … approved." DB: `status=Approved`, `approved_by`/`approved_at` set. Activity: `certificate_approved`. |
| 4 | In Issue card, enter Issued To="Parent Name", click Issue Certificate. | Success "Certificate BON/YYYY/NNNN issued." DB: `status=Issued`, `cert_number` set, `issued_by`/`issued_at` set. Activity: `certificate_issued`. |
| 5 | Click Print. | `/…/download` opens the print view (HTTP 200). For a non-Issued record the same URL 404s. |

### MT-2 — Fee-gate on TC_Copy / Migration (BR-FOF-005, money path)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a request for a student with **outstanding** fees, cert_type=`TC_Copy`. Approve it. | status=Approved. |
| 2 | Attempt Issue (Issued To supplied). | Blocked: DomainException "Cannot issue certificate: student has outstanding fees of ₹X." (HTTP 500; no state change). DB: `status` still `Approved`, `cert_number` NULL. |
| 3 | Clear the student's fees (all invoices Paid/Cancelled or balance 0). Retry Issue. | Succeeds; status=Issued, cert_number set. |
| 4 | Repeat for cert_type=`Bonafide` with outstanding fees. | Issues successfully (fee-gate applies ONLY to TC_Copy/Migration). |

### MT-3 — Illegal transitions & Cancelled gap

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Take an `Approved` request; call approve() again (PATCH approve). | DomainException "Only Pending_Approval requests can be approved." (500). |
| 2 | Take an `Issued` request; call issue() again. | DomainException "Only Approved requests can be issued." (500). |
| 3 | Attempt to set status=`Cancelled` anywhere in the UI. | No control exists (DEV-FOF-CR-03): Cancelled is defined in DDL/lifecycle but unreachable through the controller. |
| 4 | Via Edit (update()) on a Pending request, set status=`Issued` + cert_number directly. | Update succeeds and jumps to Issued WITHOUT the fee-gate/auto cert_number/issued_by (DEV-FOF-CR-04 — permissive update path). |

---

## 6. Known Source Defects (`DEV-###` / audit-equivalent)

| ID | Sev | Origin | Summary | Current-source verdict | Proving test |
|----|-----|--------|---------|------------------------|--------------|
| DAT-FOF-001 | P1 | Audit | `issue()` missing StudentFee clearance for TC_Copy/Migration (BR-FOF-005) | **REMEDIATED** — fee-gate present (controller lines ~224–239) | test_cert_41 |
| BUG-FOF-001 | P1 | Audit | `toggleStatus(): JsonResponse` unimported → HTTP 500 | **REMEDIATED** — `use Illuminate\Http\JsonResponse;` present (line 10); method returns JSON | (source import verified; tolerate 500-vs-200 at route) |
| BUG-FOF-004 | P3 | Audit | cert_number format deviates from BR-FOF-016 (`{PREFIX}-{YEAR}-{NNN}` dash) | **CONFIRMED** — controller uses slash `{TYPE3}/{Y}/{NNNN}` (e.g. `BON/2026/0001`) | test_cert_13 |
| DEV-FOF-CR-01 | P2 | Cross-ref #10 | Requirement permission keys `frontoffice.certificate-request.*` + `.approve` do NOT match code `frontoffice.certificate.*` (approve/reject gated by `.update`) | CONFIRMED | test_cert_50 |
| DEV-FOF-CR-02 | P3 | Cross-ref #14 | `copies_requested` range: controller `max:10` vs DDL comment / requirement "1–5" | CONFIRMED | test_cert_35 |
| DEV-FOF-CR-03 | P2 | Cross-ref #7 | `Cancelled` status in enum + lifecycle but unreachable via controller (no transition) | CONFIRMED | test_cert_25 |
| DEV-FOF-CR-04 | P2 | Cross-ref #7 | `update()` permits direct status jump to `Issued` + arbitrary `cert_number`, bypassing issue() fee-gate + auto-number + issued_by/at | CONFIRMED | test_cert_72 |
| SEC-FOF-003 | P1 | Audit | No FormRequest for CertificateRequest — validation is inline only (no defense-in-depth `authorize()`) | CONFIRMED (no `Requests/*` class) | test_cert_34/36 (rules asserted in-controller) |
| PERF-FOF-001 | P2 | Audit | index()/create()/edit() preload ALL active students via `->get()` (unbounded) | CONFIRMED (observation) | — (noted) |
| DAT-FOF-002 | P2 | Audit | auto-number race | **MITIGATED** — generators now use `lockForUpdate()` | (source noted) |

# ADM — Admission Management Module
## Feature Specification Document
**Version:** 1.0 | **Date:** 2026-03-27 | **Generated From:** ADM_Admission_Requirement.md v2
**Module Code:** ADM | **Laravel Module:** `Modules\Admission` | **Status:** Greenfield

---

## Section 1 — Module Identity & Scope

### Identity
| Attribute | Value |
|-----------|-------|
| Module Code | ADM |
| Laravel Namespace | `Modules\Admission` |
| Module Directory | `Modules/Admission/` |
| Route Prefix | `admission/` |
| Route Name Prefix | `adm.` |
| DB Table Prefix | `adm_` |
| Database | `tenant_db` (no `tenant_id` column — stancl/tenancy v3.9, DB per tenant) |
| Module Type | Tenant-scoped |
| RBS Module Code | C (Admissions & Student Lifecycle) |
| Implementation Status | 0% — Greenfield / Not Started |

### In-Scope Feature Groups (15 FRs across 7 Phases)
| Phase | Feature Groups |
|-------|---------------|
| Phase 1 | Admission Cycle Config, Seat Capacity, Document Checklist, Quota Config, Lead Capture & Enquiry, Follow-up CRM, Online Application Form |
| Phase 2 | Document Verification, Interview Scheduling, Entrance Test Management, Merit List Generation, Quota-based Seat Allotment, Waitlist Auto-Promotion |
| Phase 3 | Offer Letter, Admission Fee Invoice, Online Payment Webhook Confirmation |
| Phase 4 | Final Enrollment Conversion (WRITES `sys_users` + `std_students` + `std_student_academic_sessions`), Sibling Linking, Auto-Section Assignment, Bulk Enrollment |
| Phase 5 | Withdrawal Recording, Refund Computation, FIN Module Instruction |
| Phase 6 | Promotion Wizard, Alumni Management, Transfer Certificate (TC) with QR |
| Phase 7 | Behavior Incident Management, Admission Analytics Funnel |

### Out of Scope
- Fee collection mechanics (managed by FIN module — ADM only generates the invoice request)
- Online payment gateway key management (managed by PAY module / `sys_settings`)
- Behavior module is in ADM but flagged as a future extraction candidate (see Section 14 of req v2)
- UDISE export, sibling discount auto-trigger, CRM integration (noted as future suggestions in req v2)

### Authoritative Source Role
- **ADM module is the ONLY source that creates new student records**: `EnrollmentService::enrollStudent()` WRITES to `sys_users`, `std_students`, and `std_student_academic_sessions` inside a single `DB::transaction()`

### Module Scale
| Artifact | Count |
|----------|-------|
| Controllers | 14 |
| Models | 20 |
| Services | 6 |
| FormRequests | 12 |
| `adm_*` Tables | 20 |
| Blade Views (estimated) | ~55 |
| Seeders | 2 + 1 runner |
| Jobs | 2 (WaitlistPromotionJob, OfferExpiryJob) |

---

## Section 2 — Entity Inventory (All 20 Tables)

> **DDL Verification Notes (tenant_db_v2.sql):**
> - `sys_users.id` = `INT UNSIGNED` → counselor FKs use `INT UNSIGNED`
> - `sys_media.id` = `INT UNSIGNED` → all media FKs use `INT UNSIGNED`
> - `sch_classes.id` = `INT UNSIGNED`
> - `sch_sections.id` = `INT UNSIGNED`
> - `sch_class_section_jnt.id` = `INT UNSIGNED`
> - `sch_org_academic_sessions_jnt.id` = `SMALLINT UNSIGNED` (FK columns use `INT UNSIGNED` per project convention — consistent with `std_student_academic_sessions` existing pattern)
> - `std_students.id` = `INT UNSIGNED`
> - `std_student_academic_sessions`: `student_id INT UNSIGNED`, `academic_session_id INT UNSIGNED`, `class_section_id INT UNSIGNED`, `roll_no INT UNSIGNED`, `is_current TINYINT(1)`, `session_status_id INT UNSIGNED`
> - `std_guardians.mobile_no` (column name for sibling detection — NOT `phone`)
> - `std_siblings_jnt` — NOT YET in DDL (pending; WRITTEN by EnrollmentService)
> - `fin_invoices` — NOT YET in DDL (pending StudentFee module)
> - Standard ADM columns: `id BIGINT UNSIGNED`, `created_by BIGINT UNSIGNED`, `updated_by BIGINT UNSIGNED`

---

### Group 1: Configuration (4 tables)

#### `adm_admission_cycles`
Annual admission cycle configuration — one per academic year per school.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `academic_session_id` | INT UNSIGNED | NOT NULL | — | FK→sch_org_academic_sessions_jnt | Target academic year |
| `name` | VARCHAR(100) | NOT NULL | — | — | e.g., "Main Admission 2026-27" |
| `cycle_code` | VARCHAR(20) | NOT NULL | — | UNIQUE | e.g., "ADM-2627-M" |
| `start_date` | DATE | NOT NULL | — | — | Enquiry open date |
| `end_date` | DATE | NOT NULL | — | — | Enquiry close date |
| `application_fee` | DECIMAL(10,2) | NOT NULL | 0.00 | — | Application processing fee |
| `admission_no_format` | VARCHAR(100) | NULL | '{YEAR}/{SEQ}' | — | Admission number template |
| `sibling_bonus_score` | TINYINT UNSIGNED | NOT NULL | 5 | — | Merit score bonus for confirmed siblings |
| `age_rules_json` | JSON | NULL | — | — | Min/max age per class on cut-off date |
| `refund_policy_json` | JSON | NULL | — | — | Refund % tiers by days since payment |
| `application_form_url` | VARCHAR(255) | NULL | — | — | Public form slug (e.g., "admission-2627") |
| `status` | ENUM | NOT NULL | 'Draft' | — | 'Draft','Active','Closed','Archived' |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Unique:** `uq_adm_cyc_code` (`cycle_code`)
**Indexes:** `idx_adm_cyc_session` (`academic_session_id`), `idx_adm_cyc_status` (`status`)
**Business Rule:** Only one cycle may be `Active` per `academic_session_id` at a time (enforced in `AdmissionPipelineService::activateCycle()`)

---

#### `adm_document_checklist`
Required document definitions per admission cycle (optionally per class level).

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_admission_cycles | NULL = global template |
| `class_id` | INT UNSIGNED | NULL | — | FK→sch_classes | NULL = applies to all classes |
| `document_name` | VARCHAR(100) | NOT NULL | — | — | e.g., "Birth Certificate" |
| `document_code` | VARCHAR(30) | NOT NULL | — | — | e.g., "BIRTH_CERT" |
| `is_mandatory` | TINYINT(1) | NOT NULL | 1 | — | 1 = must be uploaded before submission |
| `is_system` | TINYINT(1) | NOT NULL | 0 | — | 1 = seeded default template row |
| `accepted_formats` | VARCHAR(100) | NOT NULL | 'pdf,jpg,png' | — | Comma-separated MIME extensions |
| `max_size_kb` | INT UNSIGNED | NOT NULL | 5120 | — | Maximum file size in KB |
| `sort_order` | TINYINT UNSIGNED | NOT NULL | 0 | — | Display order |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_adm_chk_cycle` (`admission_cycle_id`), `idx_adm_chk_class` (`class_id`)

---

#### `adm_quota_config`
Quota type settings per class per admission cycle (fee waiver, reserved seats).

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_admission_cycles | |
| `class_id` | INT UNSIGNED | NOT NULL | — | FK→sch_classes | |
| `quota_type` | ENUM | NOT NULL | — | — | 'General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS' |
| `total_seats` | SMALLINT UNSIGNED | NOT NULL | — | — | Total seats in this quota for this class |
| `reserved_seats` | SMALLINT UNSIGNED | NOT NULL | 0 | — | RTE mandated minimum |
| `application_fee_waiver` | TINYINT(1) | NOT NULL | 0 | — | 1 = fee waived (e.g., RTE, EWS) |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_adm_qcfg_cycle_class` (`admission_cycle_id`, `class_id`), `idx_adm_qcfg_quota` (`quota_type`)

---

#### `adm_seat_capacity`
Per-class per-quota seat budget with real-time allotted/enrolled counters.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_admission_cycles | |
| `class_id` | INT UNSIGNED | NOT NULL | — | FK→sch_classes | |
| `quota_type` | ENUM | NOT NULL | — | — | 'General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS' |
| `total_seats` | SMALLINT UNSIGNED | NOT NULL | — | — | Configured seat budget for this quota |
| `seats_allotted` | SMALLINT UNSIGNED | NOT NULL | 0 | — | Incremented by MeritListService::allotSeat() |
| `seats_enrolled` | SMALLINT UNSIGNED | NOT NULL | 0 | — | Incremented by EnrollmentService::enrollStudent() |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Unique:** `uq_adm_sc_cycle_class_quota` (`admission_cycle_id`, `class_id`, `quota_type`)
**Business Rule (BR-ADM-013):** `MeritListService::allotSeat()` checks `seats_allotted >= total_seats` before creating allotment

---

### Group 2: Enquiry & CRM (2 tables)

#### `adm_enquiries`
Raw leads captured online, walk-in, or via campaign.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_admission_cycles | |
| `enquiry_no` | VARCHAR(20) | NOT NULL | — | UNIQUE | ENQ-YYYY-NNNNN |
| `student_name` | VARCHAR(100) | NOT NULL | — | — | |
| `student_dob` | DATE | NULL | — | — | For age eligibility check |
| `student_gender` | ENUM | NULL | — | — | 'Male','Female','Transgender','Other' |
| `class_sought_id` | INT UNSIGNED | NOT NULL | — | FK→sch_classes | |
| `father_name` | VARCHAR(100) | NULL | — | — | |
| `mother_name` | VARCHAR(100) | NULL | — | — | |
| `contact_name` | VARCHAR(100) | NOT NULL | — | — | Primary contact person |
| `contact_mobile` | VARCHAR(15) | NOT NULL | — | — | Matched against std_guardians.mobile_no for sibling detection |
| `contact_email` | VARCHAR(100) | NULL | — | — | |
| `lead_source` | ENUM | NOT NULL | 'Walk-in' | — | 'Website','Walk-in','Campaign','Referral','Social_Media','Phone','Other' |
| `status` | ENUM | NOT NULL | 'New' | — | 'New','Assigned','Contacted','Interested','Not_Interested','Callback','Converted','Duplicate' |
| `counselor_id` | INT UNSIGNED | NULL | — | FK→sys_users | Assigned counselor |
| `is_sibling_lead` | TINYINT(1) | NOT NULL | 0 | — | 1 = auto-detected sibling (contact_mobile matches std_guardians.mobile_no) |
| `sibling_student_id` | INT UNSIGNED | NULL | — | FK→std_students | Matched existing sibling student |
| `is_duplicate` | TINYINT(1) | NOT NULL | 0 | — | 1 = duplicate submission flag |
| `notes` | TEXT | NULL | — | — | |
| `source_reference` | VARCHAR(100) | NULL | — | — | Campaign code / referral name |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Unique:** `uq_adm_enq_no` (`enquiry_no`)
**Indexes:** `idx_adm_enq_cycle` (`admission_cycle_id`), `idx_adm_enq_status` (`status`), `idx_adm_enq_counselor` (`counselor_id`), `idx_adm_enq_mobile` (`contact_mobile`), `idx_adm_enq_sibling` (`sibling_student_id`)
**Cross-Module FK:** `sibling_student_id → std_students.id` (nullable — auto-detected)

---

#### `adm_follow_ups`
Follow-up activity log per enquiry (calls, meetings, emails).

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `enquiry_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_enquiries | |
| `follow_up_type` | ENUM | NOT NULL | — | — | 'Call','Meeting','Email','SMS','Walk-in' |
| `scheduled_at` | DATETIME | NOT NULL | — | — | |
| `completed_at` | DATETIME | NULL | — | — | |
| `outcome` | ENUM | NOT NULL | 'Pending' | — | 'Pending','Interested','Not_Interested','Callback','Converted' |
| `notes` | TEXT | NULL | — | — | |
| `done_by` | INT UNSIGNED | NULL | — | FK→sys_users | Staff who made the follow-up |
| `reminder_sent` | TINYINT(1) | NOT NULL | 0 | — | 1 = NTF reminder dispatched |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_adm_fu_enquiry` (`enquiry_id`), `idx_adm_fu_scheduled` (`scheduled_at`), `idx_adm_fu_done_by` (`done_by`)

---

### Group 3: Application Pipeline (4 tables)

#### `adm_applications`
Full application record — multi-step wizard data with status FSM.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_admission_cycles | |
| `enquiry_id` | BIGINT UNSIGNED | NULL | — | FK→adm_enquiries | Source enquiry if converted |
| `application_no` | VARCHAR(20) | NOT NULL | — | UNIQUE | APP-YYYY-NNNNN |
| `class_applied_id` | INT UNSIGNED | NOT NULL | — | FK→sch_classes | |
| `quota_type` | ENUM | NOT NULL | 'General' | — | 'General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS' |
| `is_sibling` | TINYINT(1) | NOT NULL | 0 | — | 1 = staff-confirmed sibling (BR-ADM-015) |
| `sibling_student_id` | INT UNSIGNED | NULL | — | FK→std_students | Staff-confirmed sibling reference |
| `is_staff_ward` | TINYINT(1) | NOT NULL | 0 | — | 1 = parent is staff member |
| `student_first_name` | VARCHAR(50) | NOT NULL | — | — | |
| `student_middle_name` | VARCHAR(50) | NULL | — | — | |
| `student_last_name` | VARCHAR(50) | NULL | — | — | |
| `student_dob` | DATE | NOT NULL | — | — | |
| `student_gender` | ENUM | NOT NULL | — | — | 'Male','Female','Transgender','Prefer Not to Say' |
| `student_religion` | VARCHAR(50) | NULL | — | — | |
| `student_caste_category` | ENUM | NULL | — | — | 'General','OBC','SC','ST','EWS','Other' |
| `student_nationality` | VARCHAR(50) | NULL | 'Indian' | — | |
| `student_mother_tongue` | VARCHAR(50) | NULL | — | — | |
| `aadhar_no` | VARCHAR(20) | NULL | — | — | Partial unique enforced at service layer only (not DB UNIQUE) |
| `birth_cert_no` | VARCHAR(50) | NULL | — | — | |
| `prev_school_name` | VARCHAR(100) | NULL | — | — | |
| `prev_class_passed` | VARCHAR(20) | NULL | — | — | |
| `prev_marks_percent` | DECIMAL(5,2) | NULL | — | — | Previous school marks % for merit calculation |
| `prev_tc_no` | VARCHAR(50) | NULL | — | — | |
| `blood_group` | ENUM | NULL | — | — | 'A+','A-','B+','B-','AB+','AB-','O+','O-','Unknown' |
| `known_allergies` | TEXT | NULL | — | — | |
| `father_name` | VARCHAR(100) | NULL | — | — | |
| `father_mobile` | VARCHAR(15) | NULL | — | — | |
| `father_email` | VARCHAR(100) | NULL | — | — | |
| `father_occupation` | VARCHAR(100) | NULL | — | — | |
| `mother_name` | VARCHAR(100) | NULL | — | — | |
| `mother_mobile` | VARCHAR(15) | NULL | — | — | |
| `mother_email` | VARCHAR(100) | NULL | — | — | |
| `guardian_name` | VARCHAR(100) | NULL | — | — | |
| `guardian_mobile` | VARCHAR(15) | NULL | — | — | |
| `guardian_relation` | VARCHAR(50) | NULL | — | — | |
| `address_line1` | VARCHAR(150) | NULL | — | — | |
| `address_line2` | VARCHAR(150) | NULL | — | — | |
| `city` | VARCHAR(50) | NULL | — | — | |
| `state` | VARCHAR(50) | NULL | — | — | |
| `pincode` | VARCHAR(10) | NULL | — | — | |
| `application_fee_paid` | TINYINT(1) | NOT NULL | 0 | — | 1 = application fee confirmed |
| `application_fee_amount` | DECIMAL(10,2) | NULL | — | — | |
| `application_fee_date` | DATE | NULL | — | — | |
| `interview_scheduled_at` | DATETIME | NULL | — | — | |
| `interview_venue` | VARCHAR(100) | NULL | — | — | |
| `interview_notes` | TEXT | NULL | — | — | |
| `interview_score` | DECIMAL(5,2) | NULL | — | — | Used in merit composite score |
| `status` | ENUM | NOT NULL | 'Draft' | — | 'Draft','Submitted','Under_Review','Verified','Shortlisted','Rejected','Waitlisted','Allotted','Enrolled','Withdrawn' |
| `rejection_reason` | TEXT | NULL | — | — | |
| `processed_by` | INT UNSIGNED | NULL | — | FK→sys_users | |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Unique:** `uq_adm_app_no` (`application_no`)
**Indexes:** `idx_adm_app_cycle` (`admission_cycle_id`), `idx_adm_app_status` (`status`), `idx_adm_app_class` (`class_applied_id`), `idx_adm_app_enquiry` (`enquiry_id`), `idx_adm_app_sibling` (`sibling_student_id`)
**Cross-Module FKs:** `sibling_student_id → std_students.id` (nullable — staff-confirmed)
**Note:** `aadhar_no` is NOT UNIQUE at DB level — partial uniqueness enforced in `AdmissionPipelineService` at service layer

---

#### `adm_application_documents`
Uploaded documents per application mapped to document checklist items.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `application_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_applications | |
| `checklist_item_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_document_checklist | |
| `media_id` | INT UNSIGNED | NOT NULL | — | FK→sys_media | Uploaded file reference (sys_media uses INT UNSIGNED) |
| `original_filename` | VARCHAR(255) | NOT NULL | — | — | |
| `verification_status` | ENUM | NOT NULL | 'Pending' | — | 'Pending','Verified','Rejected' |
| `verification_remarks` | TEXT | NULL | — | — | Required if rejected |
| `verified_by` | INT UNSIGNED | NULL | — | FK→sys_users | |
| `verified_at` | TIMESTAMP | NULL | — | — | |
| `is_physically_received` | TINYINT(1) | NOT NULL | 0 | — | 1 = original physically collected at front desk |
| `physical_received_at` | DATE | NULL | — | — | |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Unique:** `uq_adm_doc_app_checklist` (`application_id`, `checklist_item_id`)
**Indexes:** `idx_adm_doc_app` (`application_id`), `idx_adm_doc_media` (`media_id`), `idx_adm_doc_verified_by` (`verified_by`)
**Cross-Module FK:** `media_id → sys_media.id` (INT UNSIGNED — sys_media uses INT not BIGINT)

---

#### `adm_application_stages`
Immutable audit trail of every application status transition.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `application_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_applications | |
| `from_status` | VARCHAR(50) | NOT NULL | — | — | Previous status value |
| `to_status` | VARCHAR(50) | NOT NULL | — | — | New status value |
| `remarks` | TEXT | NULL | — | — | Staff comment or system reason |
| `changed_by` | INT UNSIGNED | NULL | — | FK→sys_users | NULL = system-triggered |
| `changed_at` | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | — | |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_adm_stage_app` (`application_id`), `idx_adm_stage_changed_at` (`changed_at`)

---

#### `adm_withdrawals`
Withdrawal recording with refund eligibility computation.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `application_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_applications | |
| `allotment_id` | BIGINT UNSIGNED | NULL | — | FK→adm_allotments | Set if withdrawn after allotment |
| `withdrawal_date` | DATE | NOT NULL | — | — | |
| `reason` | ENUM | NOT NULL | — | — | 'Personal','Financial','Relocation','School_Change','Medical','Other' |
| `remarks` | TEXT | NULL | — | — | |
| `fee_paid_amount` | DECIMAL(10,2) | NOT NULL | 0.00 | — | Total fees paid before withdrawal |
| `refund_eligible_amount` | DECIMAL(10,2) | NOT NULL | 0.00 | — | Computed per refund_policy_json at withdrawal time |
| `refund_status` | ENUM | NOT NULL | 'Not_Eligible' | — | 'Not_Eligible','Pending','Approved','Paid' |
| `refund_processed_at` | DATE | NULL | — | — | |
| `processed_by` | INT UNSIGNED | NULL | — | FK→sys_users | |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_adm_wd_app` (`application_id`), `idx_adm_wd_allotment` (`allotment_id`), `idx_adm_wd_refund_status` (`refund_status`)

---

### Group 4: Entrance Test (2 tables)

#### `adm_entrance_tests`
Entrance/aptitude test sessions per class per admission cycle.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_admission_cycles | |
| `class_id` | INT UNSIGNED | NOT NULL | — | FK→sch_classes | Warning if class 1 or 2 (NEP 2020, BR-ADM-011) |
| `test_name` | VARCHAR(100) | NOT NULL | — | — | |
| `test_date` | DATE | NOT NULL | — | — | |
| `start_time` | TIME | NOT NULL | — | — | |
| `end_time` | TIME | NOT NULL | — | — | Must be > start_time |
| `venue` | VARCHAR(100) | NULL | — | — | |
| `max_marks` | DECIMAL(6,2) | NOT NULL | — | — | |
| `passing_marks` | DECIMAL(6,2) | NULL | — | — | |
| `subjects_json` | JSON | NULL | — | — | Subject areas with individual max marks |
| `status` | ENUM | NOT NULL | 'Scheduled' | — | 'Scheduled','Completed','Cancelled' |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_adm_et_cycle_class` (`admission_cycle_id`, `class_id`), `idx_adm_et_date` (`test_date`)

---

#### `adm_entrance_test_candidates`
Candidate registration and mark entry per entrance test.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `entrance_test_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_entrance_tests | |
| `application_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_applications | |
| `roll_no` | VARCHAR(20) | NULL | — | — | Test hall roll number |
| `marks_obtained` | DECIMAL(6,2) | NULL | — | — | NULL until marks entered |
| `result` | ENUM | NOT NULL | 'Pending' | — | 'Pass','Fail','Absent','Pending' |
| `subject_marks_json` | JSON | NULL | — | — | Per-subject breakdown |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Unique:** `uq_adm_etc_test_app` (`entrance_test_id`, `application_id`)
**Indexes:** `idx_adm_etc_test` (`entrance_test_id`), `idx_adm_etc_app` (`application_id`)

---

### Group 5: Merit & Allotment (3 tables)

#### `adm_merit_lists`
Merit list header per cycle + class + quota with criteria configuration.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_admission_cycles | |
| `class_id` | INT UNSIGNED | NOT NULL | — | FK→sch_classes | |
| `quota_type` | ENUM | NOT NULL | — | — | 'General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS' |
| `generated_at` | TIMESTAMP | NULL | — | — | Set when generation completes |
| `generated_by` | INT UNSIGNED | NULL | — | FK→sys_users | |
| `status` | ENUM | NOT NULL | 'Draft' | — | 'Draft','Published','Finalized' |
| `criteria_json` | JSON | NULL | — | — | Weightage: {test_pct, interview_pct, academic_pct} — must sum to 100 |
| `sibling_bonus_score` | TINYINT UNSIGNED | NOT NULL | 5 | — | Copied from adm_admission_cycles at generation time |
| `cutoff_score` | DECIMAL(6,2) | NULL | — | — | Below cutoff → Rejected |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_adm_ml_cycle_class_quota` (`admission_cycle_id`, `class_id`, `quota_type`)

---

#### `adm_merit_list_entries`
Individual applicant entries in a merit list with scores and ranking.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `merit_list_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_merit_lists | |
| `application_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_applications | |
| `merit_rank` | SMALLINT UNSIGNED | NOT NULL | — | — | 1 = top ranked |
| `composite_score` | DECIMAL(6,2) | NULL | — | — | Final score after sibling bonus |
| `entrance_score` | DECIMAL(6,2) | NULL | — | — | Weighted entrance marks |
| `interview_score` | DECIMAL(6,2) | NULL | — | — | Weighted interview marks |
| `academic_score` | DECIMAL(6,2) | NULL | — | — | Weighted previous academic marks |
| `sibling_bonus_applied` | TINYINT(1) | NOT NULL | 0 | — | 1 = sibling bonus was added to composite score |
| `merit_status` | ENUM | NOT NULL | 'Shortlisted' | — | 'Shortlisted','Waitlisted','Rejected' |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_adm_mle_list` (`merit_list_id`), `idx_adm_mle_rank` (`merit_list_id`, `merit_rank`), `idx_adm_mle_app` (`application_id`), `idx_adm_mle_status` (`merit_status`)

---

#### `adm_allotments`
Seat allotment records — the bridge between merit list and enrollment.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `merit_list_entry_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_merit_list_entries | |
| `application_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_applications | |
| `admission_no` | VARCHAR(50) | NULL | — | UNIQUE | Assigned on offer letter; nullable until then (MySQL UNIQUE allows multiple NULLs) |
| `allotted_class_id` | INT UNSIGNED | NOT NULL | — | FK→sch_classes | |
| `allotted_section_id` | INT UNSIGNED | NULL | — | FK→sch_sections | Assigned at enrollment or manually set |
| `joining_date` | DATE | NULL | — | — | Expected joining date per offer letter |
| `offer_letter_media_id` | INT UNSIGNED | NULL | — | FK→sys_media | sys_media uses INT UNSIGNED |
| `offer_issued_at` | TIMESTAMP | NULL | — | — | When offer letter PDF was generated |
| `offer_expires_at` | DATE | NULL | — | — | Deadline for parent response (daily job checks this) |
| `admission_fee_paid` | TINYINT(1) | NOT NULL | 0 | — | 1 = admission fee confirmed |
| `admission_fee_amount` | DECIMAL(10,2) | NULL | — | — | |
| `admission_fee_date` | DATE | NULL | — | — | |
| `status` | ENUM | NOT NULL | 'Offered' | — | 'Offered','Accepted','Declined','Expired','Enrolled','Withdrawn' |
| `enrolled_student_id` | INT UNSIGNED | NULL | — | FK→std_students | SET ON ENROLLMENT by EnrollmentService |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Unique:** `uq_adm_allot_admission_no` (`admission_no`) — nullable; allows multiple NULLs
**Indexes:** `idx_adm_allot_app` (`application_id`), `idx_adm_allot_mle` (`merit_list_entry_id`), `idx_adm_allot_status` (`status`), `idx_adm_allot_expires` (`offer_expires_at`), `idx_adm_allot_enrolled_student` (`enrolled_student_id`)
**Cross-Module FKs:**
- `offer_letter_media_id → sys_media.id` (INT UNSIGNED)
- `allotted_section_id → sch_sections.id` (INT UNSIGNED)
- `enrolled_student_id → std_students.id` (INT UNSIGNED — SET ON ENROLLMENT)

---

### Group 6: Promotion (2 tables)

#### `adm_promotion_batches`
Year-end promotion batch header per class transition.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `from_session_id` | INT UNSIGNED | NOT NULL | — | FK→sch_org_academic_sessions_jnt | Current academic session |
| `to_session_id` | INT UNSIGNED | NOT NULL | — | FK→sch_org_academic_sessions_jnt | Next academic session |
| `from_class_id` | INT UNSIGNED | NOT NULL | — | FK→sch_classes | Source class |
| `to_class_id` | INT UNSIGNED | NOT NULL | — | FK→sch_classes | Destination class (same for detention) |
| `criteria_json` | JSON | NULL | — | — | Pass % threshold and exam weights |
| `total_students` | INT UNSIGNED | NOT NULL | 0 | — | Count loaded at batch creation |
| `promoted_count` | INT UNSIGNED | NOT NULL | 0 | — | Updated on confirm |
| `detained_count` | INT UNSIGNED | NOT NULL | 0 | — | Updated on confirm |
| `status` | ENUM | NOT NULL | 'Draft' | — | 'Draft','Confirmed' |
| `processed_by` | INT UNSIGNED | NULL | — | FK→sys_users | |
| `processed_at` | TIMESTAMP | NULL | — | — | When batch was confirmed |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_adm_pb_from_session` (`from_session_id`), `idx_adm_pb_status` (`from_session_id`, `from_class_id`, `status`)

---

#### `adm_promotion_records`
Per-student promotion decision within a batch.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `promotion_batch_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_promotion_batches | |
| `student_id` | INT UNSIGNED | NOT NULL | — | FK→std_students | |
| `from_class_section_id` | INT UNSIGNED | NOT NULL | — | FK→sch_class_section_jnt | Source class+section |
| `to_class_section_id` | INT UNSIGNED | NULL | — | FK→sch_class_section_jnt | NULL if detained/left |
| `new_roll_no` | SMALLINT UNSIGNED | NULL | — | — | Assigned for new session |
| `result` | ENUM | NOT NULL | — | — | 'Promoted','Detained','Transferred','Alumni','Left' |
| `remarks` | TEXT | NULL | — | — | Manual override reason |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_adm_pr_batch` (`promotion_batch_id`), `idx_adm_pr_student` (`promotion_batch_id`, `student_id`)

---

### Group 7: Alumni & TC (1 table)

#### `adm_transfer_certificates`
TC issuance log with QR-verified PDF.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `student_id` | INT UNSIGNED | NOT NULL | — | FK→std_students | |
| `tc_number` | VARCHAR(30) | NOT NULL | — | UNIQUE | TC-YYYY-NNN unique per school-year |
| `issue_date` | DATE | NOT NULL | — | — | |
| `leaving_date` | DATE | NOT NULL | — | — | |
| `class_at_leaving` | VARCHAR(30) | NOT NULL | — | — | e.g., "Class 10" |
| `reason_for_leaving` | TEXT | NULL | — | — | |
| `conduct` | ENUM | NOT NULL | 'Good' | — | 'Excellent','Good','Satisfactory','Poor' |
| `destination_school` | VARCHAR(150) | NULL | — | — | |
| `academic_status` | VARCHAR(100) | NULL | — | — | e.g., "Promoted to Class 9" |
| `fees_cleared` | TINYINT(1) | NOT NULL | 0 | — | 1 = FIN fee clearance confirmed |
| `is_duplicate` | TINYINT(1) | NOT NULL | 0 | — | 1 = re-issue of lost TC |
| `original_tc_id` | BIGINT UNSIGNED | NULL | — | FK→adm_transfer_certificates (self-ref) | Reference for duplicate TC |
| `media_id` | INT UNSIGNED | NULL | — | FK→sys_media | PDF file (sys_media uses INT UNSIGNED) |
| `issued_by` | INT UNSIGNED | NULL | — | FK→sys_users | |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Unique:** `uq_adm_tc_number` (`tc_number`)
**Indexes:** `idx_adm_tc_student` (`student_id`), `idx_adm_tc_year` (`tc_number`)
**Cross-Module FKs:** `media_id → sys_media.id` (INT UNSIGNED), `original_tc_id → adm_transfer_certificates.id` (self-referencing, nullable)

---

### Group 8: Behavior (2 tables)

#### `adm_behavior_incidents`
Disciplinary incident log per enrolled student.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `student_id` | INT UNSIGNED | NOT NULL | — | FK→std_students | |
| `incident_date` | DATE | NOT NULL | — | — | |
| `incident_type` | ENUM | NOT NULL | — | — | 'Bullying','Cheating','Disruption','Absenteeism','Vandalism','Violence','Misconduct','Other' |
| `severity` | ENUM | NOT NULL | — | — | 'Low','Medium','High','Critical' |
| `description` | TEXT | NOT NULL | — | — | |
| `location` | VARCHAR(100) | NULL | — | — | |
| `witnesses_json` | JSON | NULL | — | — | Array of witness names |
| `reported_by` | INT UNSIGNED | NULL | — | FK→sys_users | |
| `parent_notified` | TINYINT(1) | NOT NULL | 0 | — | 1 = NTF auto-dispatched to parent (Critical incidents) |
| `parent_notified_at` | TIMESTAMP | NULL | — | — | |
| `status` | ENUM | NOT NULL | 'Open' | — | 'Open','Action_Taken','Closed','Escalated' |
| `behavior_score_impact` | TINYINT | NOT NULL | 0 | — | Signed TINYINT — negative value = score deduction (e.g., -5 for Medium) |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_adm_bi_student_date` (`student_id`, `incident_date`), `idx_adm_bi_severity` (`severity`), `idx_adm_bi_status` (`status`)
**Note:** `behavior_score_impact` is **signed** TINYINT (NOT UNSIGNED) — must allow negative values

---

#### `adm_behavior_actions`
Corrective actions taken per incident.

| Column | Type | Null | Default | Constraints | Comment |
|--------|------|------|---------|-------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | |
| `incident_id` | BIGINT UNSIGNED | NOT NULL | — | FK→adm_behavior_incidents | |
| `action_type` | ENUM | NOT NULL | — | — | 'Warning','Detention','Suspension','Expulsion','Parent_Meeting','Counseling','Community_Service' |
| `description` | TEXT | NULL | — | — | |
| `start_date` | DATE | NULL | — | — | |
| `end_date` | DATE | NULL | — | — | |
| `parent_meeting_date` | DATETIME | NULL | — | — | |
| `meeting_outcome` | TEXT | NULL | — | — | |
| `action_by` | INT UNSIGNED | NULL | — | FK→sys_users | |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_adm_ba_incident` (`incident_id`), `idx_adm_ba_action_by` (`action_by`)

---

## Section 3 — Entity Relationship Diagram

```
══════════════════════════════════════════════════════════════════════
ADM MODULE — INTERNAL TABLES (adm_*)
══════════════════════════════════════════════════════════════════════

adm_admission_cycles
    │ ← adm_document_checklist (1:M)
    │ ← adm_quota_config (1:M)
    │ ← adm_seat_capacity (1:M)  [seats_allotted / seats_enrolled updated by services]
    │ ← adm_enquiries (1:M)
    │       └── adm_follow_ups (1:M)
    │ ← adm_entrance_tests (1:M)
    │       └── adm_entrance_test_candidates (1:M) →→ adm_applications
    │ ← adm_merit_lists (1:M)
    │       └── adm_merit_list_entries (1:M) →→ adm_applications
    │               └── adm_allotments (1:1)
    └── adm_applications (1:M)
            ├── adm_application_documents (1:M) →→ sys_media [READ]
            ├── adm_application_stages (1:M)  [immutable audit log]
            └── adm_withdrawals (1:1)  →→ adm_allotments [nullable]

adm_promotion_batches
    └── adm_promotion_records (1:M) →→ std_students [READ]

adm_transfer_certificates →→ std_students [READ]
    └── self-ref: original_tc_id (nullable, for duplicate TC)

adm_behavior_incidents →→ std_students [READ]
    └── adm_behavior_actions (1:M)

══════════════════════════════════════════════════════════════════════
CROSS-MODULE REFERENCES (READ only unless marked WRITE)
══════════════════════════════════════════════════════════════════════

SchoolSetup (SCH) — READ:
    adm_admission_cycles.academic_session_id → sch_org_academic_sessions_jnt.id
    adm_document_checklist.class_id          → sch_classes.id (nullable)
    adm_quota_config.class_id                → sch_classes.id
    adm_seat_capacity.class_id               → sch_classes.id
    adm_enquiries.class_sought_id            → sch_classes.id
    adm_entrance_tests.class_id              → sch_classes.id
    adm_merit_lists.class_id                 → sch_classes.id
    adm_allotments.allotted_class_id         → sch_classes.id
    adm_allotments.allotted_section_id       → sch_sections.id (nullable)
    adm_applications.class_applied_id        → sch_classes.id
    adm_promotion_batches.from_session_id    → sch_org_academic_sessions_jnt.id
    adm_promotion_batches.to_session_id      → sch_org_academic_sessions_jnt.id
    adm_promotion_batches.from_class_id      → sch_classes.id
    adm_promotion_batches.to_class_id        → sch_classes.id
    adm_promotion_records.from_class_section_id → sch_class_section_jnt.id
    adm_promotion_records.to_class_section_id   → sch_class_section_jnt.id (nullable)

System (SYS) — READ + WRITE:
    adm_enquiries.sibling_student_id         → std_students.id (nullable READ; auto-detected)
    adm_applications.sibling_student_id      → std_students.id (nullable READ; staff-confirmed)
    adm_allotments.offer_letter_media_id     → sys_media.id (INT UNSIGNED — WRITE on offer gen)
    adm_application_documents.media_id       → sys_media.id (INT UNSIGNED — WRITE on upload)
    adm_transfer_certificates.media_id       → sys_media.id (INT UNSIGNED — WRITE on TC gen)
    adm_counselor_id                         → sys_users.id (READ)

StudentProfile (STD) — READ + ★WRITE ON ENROLLMENT:
    adm_enquiries.sibling_student_id         → std_students.id (READ — auto-detect)
    adm_applications.sibling_student_id      → std_students.id (READ — staff-confirm)
    adm_allotments.enrolled_student_id       → std_students.id (★WRITE — set on enrollment)
    adm_promotion_records.student_id         → std_students.id (READ)
    adm_transfer_certificates.student_id     → std_students.id (READ)
    adm_behavior_incidents.student_id        → std_students.id (READ)

    ★ EnrollmentService::enrollStudent() WRITES:
        → sys_users (CREATE — student login)
        → std_students (CREATE — student record)
        → std_student_academic_sessions (CREATE — enrollment record)
        → std_siblings_jnt (CREATE — if is_sibling=1) [table pending in DDL]

    ★ PromotionService::confirmBatch() WRITES:
        → std_student_academic_sessions (CREATE new session records)

    ★ AlumniController / TransferCertificateService WRITES:
        → std_students.current_status_id → Alumni status
        → std_student_academic_sessions.session_status_id → Left

Finance (FIN) — READ + integration:
    → fin_invoices (CREATE via FIN module service — for application fee and admission fee)
    → FIN balance check via service call (for TC fee clearance — BR-ADM-004)
    [fin_invoices not yet in DDL — pending StudentFee module]

Sibling Detection:
    adm_enquiries.contact_mobile matched against std_guardians.mobile_no [READ]
```

---

## Section 4 — Business Rules (15 Rules)

| Rule ID | Rule | Table/Column | Enforcement Point |
|---------|------|-------------|-------------------|
| **BR-ADM-001** | Age eligibility: configurable min/max age per class on cut-off date (default June 1); warning shown, not hard block | `adm_admission_cycles.age_rules_json` | `form_validation` — StoreEnquiryRequest + StoreApplicationRequest (non-blocking warning) |
| **BR-ADM-002** | **Enrollment is atomic**: `sys_users` + `std_students` + `std_student_academic_sessions` + allotment update created in single `DB::transaction()`; partial records rolled back on any failure | `adm_allotments.enrolled_student_id`, `adm_allotments.status` | `service_layer` — `EnrollmentService::enrollStudent()` in `DB::transaction()` |
| **BR-ADM-003** | Admission number unique within school-year; format school-configurable via `admission_no_format` | `adm_allotments.admission_no` UNIQUE; `std_students.admission_no` UNIQUE | `db_constraint` (UNIQUE) + `service_layer` (format generation) |
| **BR-ADM-004** | TC only after all outstanding fees cleared; blocked at service layer | `adm_transfer_certificates.fees_cleared` | `service_layer` — `TransferCertificateService::issueTc()` calls FIN module balance check before proceeding |
| **BR-ADM-005** | RTE quota: 25% of Class 1 seats reserved for EWS; RTE applicants exempt from application fee | `adm_quota_config.application_fee_waiver = 1` for RTE | `service_layer` — fee waiver check in `AdmissionPipelineService` |
| **BR-ADM-006** | Application fee is non-refundable by default; refund policy per cycle may override | `adm_admission_cycles.refund_policy_json` | `service_layer` — `AdmissionPipelineService::withdrawApplication()` computes refund per JSON policy |
| **BR-ADM-007** | **All mandatory documents must be uploaded** before application can move Submitted → Verified | `adm_document_checklist.is_mandatory`, `adm_application_documents.verification_status` | `service_layer` — `AdmissionPipelineService::verifyApplication()` checks all mandatory docs are Verified |
| **BR-ADM-008** | Roll numbers unique within class section per academic session | `std_student_academic_sessions` — existing UNIQUE on `(student_id, academic_session_id)` | `service_layer` — `EnrollmentService::assignRollNumber()` + `db_constraint` |
| **BR-ADM-009** | Promotion creates new `std_student_academic_sessions` for next year; current year records are NOT modified (is_current set to 0) | `std_student_academic_sessions.is_current` | `service_layer` — `PromotionService::confirmBatch()` appends, sets old `is_current = 0` |
| **BR-ADM-010** | One enrollment per student per academic session | `std_student_academic_sessions` UNIQUE on `(student_id, academic_session_id)` | `db_constraint` + `service_layer` pre-check in `EnrollmentService` |
| **BR-ADM-011** | **NEP 2020**: entrance tests not allowed for Classes 1–2 | `adm_entrance_tests.class_id` | `form_validation` — `StoreEntranceTestRequest` emits non-blocking warning if class ordinal ≤ 2 |
| **BR-ADM-012** | Aadhar number optional but unique when provided | `adm_applications.aadhar_no` | `service_layer` — partial uniqueness check in `AdmissionPipelineService` (NOT a DB UNIQUE constraint due to MySQL NULL handling limitations) |
| **BR-ADM-013** | **Seat capacity guard**: allotment blocked if `seats_allotted >= total_seats` for selected quota | `adm_seat_capacity.seats_allotted`, `adm_seat_capacity.total_seats` | `service_layer` — `MeritListService::allotSeat()` reads `adm_seat_capacity` before insert |
| **BR-ADM-014** | Offer expires after N days (configurable per cycle); expired offers auto-trigger next waitlisted candidate | `adm_allotments.offer_expires_at` | `scheduled_job` — `adm:expire-offers` Artisan command (daily midnight); calls `AdmissionPipelineService::promoteWaitlisted()` |
| **BR-ADM-015** | **Sibling priority**: `+5` bonus score applied in merit ranking; **staff must confirm** (`is_sibling = 1`) before benefit applies; auto-detect alone is insufficient | `adm_applications.is_sibling = 1` (staff-confirmed) | `service_layer` — `MeritListService::computeCompositeScore()` checks `is_sibling = 1` (not merely `adm_enquiries.is_sibling_lead`) |

---

## Section 5 — Workflow State Machines (5 FSMs)

### FSM 1 — Application Lifecycle

```
[Draft]
  │ Trigger: fee paid (if required) + submit action
  │ Pre-condition: at least one guardian mobile provided; application_no assigned
  │ Side-effect: adm_application_stages logged; NTF dispatched to parent
  ▼
[Submitted]
  │ Trigger: staff reviews all documents
  ├─── (all mandatory docs uploaded) ──────────────────────────────► [Verified]
  │         Pre-condition: AdmissionPipelineService::verifyApplication()
  │         checks adm_application_documents for all mandatory items
  │         Side-effect: adm_application_stages logged; NTF dispatched
  │
  └─── (docs incomplete / rejected) ──────────────────────────────► [Draft]
            Pre-condition: staff adds rejection remarks
            Side-effect: stage logged as "Returned"; parent notified with remarks

[Verified]
  │ Trigger: merit list generation + allotment
  ├─── (within seat count) ────────────────────────────────────────► [Shortlisted]
  │         Side-effect: adm_merit_list_entries.merit_status = Shortlisted
  │
  ├─── (beyond seat count) ────────────────────────────────────────► [Waitlisted]
  │         Side-effect: rank-ordered in waitlist
  │
  └─── (below cutoff score / admin reject) ───────────────────────► [Rejected]
            Side-effect: NTF dispatched; stage logged

[Shortlisted]
  │ Trigger: MeritListService::allotSeat()
  │ Pre-condition: seats_allotted < total_seats (BR-ADM-013)
  ▼
[Allotted]
  │ Trigger: offer accepted + admission fee paid
  │ Side-effect: adm_allotments created; offer letter PDF generated (DomPDF → sys_media); NTF dispatched
  ▼
[Enrolled] ✅
  Trigger: EnrollmentService::enrollStudent()
  Pre-condition: adm_allotments.admission_fee_paid = 1
  Side-effect: DB::transaction() — sys_users + std_students + std_student_academic_sessions created;
               adm_allotments.enrolled_student_id set; adm_seat_capacity.seats_enrolled += 1;
               NTF: login credentials sent to parent

[Waitlisted]
  │ Trigger: Offered seat Declined OR Expired (adm:expire-offers job)
  ▼
[Allotted] — promoted via AdmissionPipelineService::promoteWaitlisted()

[Any stage before Enrolled]
  ▼
[Withdrawn] — via WithdrawalController; refund computed; adm_withdrawals created
```

**All transitions logged to `adm_application_stages` with `from_status`, `to_status`, `changed_by`, `changed_at`**

---

### FSM 2 — Enquiry Lead

```
[New]
  │ Trigger: counselor assigned (manual or auto round-robin)
  ▼
[Assigned]
  │ Trigger: counselor makes first contact (follow-up logged)
  ▼
[Contacted]
  ├─── (parent shows interest) ─────────────────────────────────► [Interested]
  │         └─── (form started / converted) ────────────────────► [Converted] ✅
  │                   Side-effect: AdmissionPipelineService::convertToApplication()
  │                   copies enquiry fields to adm_applications (pre-filled Draft)
  │
  ├─── (parent not interested) ─────────────────────────────────► [Not_Interested] (closed)
  │
  ├─── (callback scheduled) ────────────────────────────────────► [Callback]
  │         └─── (rescheduled follow-up) ───────────────────────► [Contacted]
  │
  └─── (detected as duplicate) ─────────────────────────────────► [Duplicate] (merged/closed)
```

**Sibling auto-detect:** On `adm_enquiries` save, `contact_mobile` is matched against `std_guardians.mobile_no`. If match found → `is_sibling_lead = 1`, `sibling_student_id` set.

---

### FSM 3 — Allotment Offer

```
[Offered]
  │ Side-effect: offer letter PDF generated (DomPDF → sys_media);
  │              NTF email+SMS to parent; offer_expires_at set
  │
  ├─── (parent confirms acceptance) ────────────────────────────► [Accepted]
  │         └─── (admission fee paid) ──────────────────────────► enrollment queue
  │                   (adm_allotments.status stays Accepted;
  │                    EnrollmentController@index shows these records)
  │
  ├─── (parent declines) ───────────────────────────────────────► [Declined]
  │         Side-effect: AdmissionPipelineService::promoteWaitlisted() called;
  │                      next Waitlisted candidate promoted → new allotment created;
  │                      adm_seat_capacity.seats_allotted NOT decremented (policy decision)
  │
  └─── (offer_expires_at < TODAY, no response) ─────────────────► [Expired]
            Trigger: adm:expire-offers scheduled job (daily midnight)
            Side-effect: same as Declined — promoteWaitlisted() called
```

---

### FSM 4 — Promotion Batch

```
[Draft]
  │ Created by: PromotionController@preview
  │ Contents: student list from std_student_academic_sessions (is_current=1)
  │           exam results loaded from exm_* tables
  │           auto-classification: Promoted / Detained / Left
  │
  │ Manual overrides allowed while in Draft
  │ Preview (dry-run): shows counts; no DB writes
  │
  │ Trigger: admin clicks "Confirm"
  │ Pre-condition: PromotionConfirmRequest validation; batch not already Confirmed
  ▼
[Confirmed] ✅
  Side-effect: DB::transaction() —
    For each Promoted student:
      → std_student_academic_sessions (CREATE for to_session_id, to_class_section_id, is_current=1)
      → old std_student_academic_sessions (UPDATE is_current=0)
    For each Detained student:
      → std_student_academic_sessions (CREATE for same class, is_current=1)
      → old record is_current=0
    Roll numbers assigned sequentially per new class_section + session
  Idempotency guard: firstOrCreate on (student_id, academic_session_id) prevents duplicates on re-run
```

---

### FSM 5 — Withdrawal & Refund

```
[Not_Eligible] — default if application_fee_paid = 0 OR withdrawal_date beyond policy window

[Pending] — fee was paid AND withdrawal is within refund policy window
  │ refund_eligible_amount computed from adm_admission_cycles.refund_policy_json:
  │   e.g., "100% if withdrawal within 7 days; 50% if 7-30 days; 0% beyond 30 days"
  │ Refund instruction passed to FIN module
  │
  ├─── (finance approves) ──────────────────────────────────────► [Approved]
  │         └─── (refund disbursed) ────────────────────────────► [Paid]
  │
  └─── (beyond refund window) ──────────────────────────────────► [Not_Eligible]
```

**Post-enrollment withdrawal:** `EnrollmentService::withdraw()` also closes `std_student_academic_sessions` (set session_status_id → Withdrawn) and disables `sys_users` account (set is_active = 0).

---

## Section 6 — Functional Requirements Summary (15 FRs)

| FR ID | Name | Phase | Tables Used | Key Validations | Related BRs | Depends On |
|-------|------|-------|-------------|-----------------|-------------|------------|
| **FR-ADM-01** | Admission Cycle & Seat Capacity Config | 1 | adm_admission_cycles, adm_seat_capacity | cycle_code UNIQUE; start < end date; one Active per session | BR-ADM-003, BR-ADM-005, BR-ADM-013 | SCH, SYS |
| **FR-ADM-02** | Lead Capture & Enquiry Management | 1 | adm_enquiries, adm_follow_ups | enquiry_no UNIQUE; mobile required; age warning (non-blocking) | BR-ADM-001, BR-ADM-015 | SCH, STD (sibling detect) |
| **FR-ADM-03** | Admission Application Form | 1 | adm_applications, adm_application_documents, adm_application_stages | application_no UNIQUE; at least one guardian mobile; aadhar service-layer unique | BR-ADM-006, BR-ADM-007, BR-ADM-012 | FR-ADM-01, SYS |
| **FR-ADM-04** | Application Verification & Interview | 2 | adm_applications, adm_application_documents, adm_application_stages | all mandatory docs verified before Verified status | BR-ADM-007 | FR-ADM-03 |
| **FR-ADM-05** | Entrance Test Management | 2 | adm_entrance_tests, adm_entrance_test_candidates | test_date required; end_time > start_time; NEP 2020 warning for Class 1-2 | BR-ADM-011 | FR-ADM-01, FR-ADM-03 |
| **FR-ADM-06** | Merit List Generation & Seat Allotment | 2 | adm_merit_lists, adm_merit_list_entries, adm_allotments | criteria_json weights sum to 100; seat capacity guard | BR-ADM-013, BR-ADM-014, BR-ADM-015 | FR-ADM-04, FR-ADM-05 |
| **FR-ADM-07** | Admission Fee & Payment Confirmation | 3 | adm_allotments | payment webhook idempotency; signature verified | BR-ADM-003 | FR-ADM-06, PAY |
| **FR-ADM-08** | Withdrawal & Refund Workflow | 5 | adm_withdrawals | application not already Withdrawn/Enrolled | BR-ADM-006 | FR-ADM-03, FIN |
| **FR-ADM-09** | Final Enrollment Conversion | 4 | adm_allotments + WRITES sys_users, std_students, std_student_academic_sessions | admission_fee_paid = 1; no existing enrollment for same session | BR-ADM-002, BR-ADM-008, BR-ADM-010 | FR-ADM-07, STD |
| **FR-ADM-10** | Student Promotion (Year-end) | 6 | adm_promotion_batches, adm_promotion_records | batch not already Confirmed (idempotent) | BR-ADM-009 | FR-ADM-09, EXM |
| **FR-ADM-11** | Alumni Management & TC | 6 | adm_transfer_certificates | fee clearance check; TC number unique per year | BR-ADM-004, BR-ADM-003 | FR-ADM-09, FIN |
| **FR-ADM-12** | Behavior Incident Management | 7 | adm_behavior_incidents, adm_behavior_actions | severity valid ENUM; Critical → auto NTF | — | FR-ADM-09 |
| **FR-ADM-13** | Admission Analytics Funnel | 7 | Reads all adm_* tables | — | — | FR-ADM-09 |
| **FR-ADM-14** | Sibling Preference Rules | 1+4 | adm_enquiries, adm_applications + reads std_guardians | is_sibling = 1 required (staff-confirmed); auto-detect alone insufficient | BR-ADM-015 | STD |
| **FR-ADM-15** | Admission Settings & Configuration | 1 | adm_admission_cycles, adm_document_checklist, adm_quota_config, adm_seat_capacity | one Active cycle per session | BR-ADM-001, BR-ADM-005 | SCH |

---

## Section 7 — Permission Matrix

| Permission String | School Admin | Admission Counselor | Front Office | Principal | Finance Staff | Class Teacher |
|-------------------|:---:|:---:|:---:|:---:|:---:|:---:|
| `admission.cycle.viewAny` | ✅ | — | — | ✅ | — | — |
| `admission.cycle.create` | ✅ | — | — | — | — | — |
| `admission.cycle.update` | ✅ | — | — | — | — | — |
| `admission.cycle.delete` | ✅ | — | — | — | — | — |
| `admission.enquiry.viewAny` | ✅ | ✅ | ✅ | ✅ | — | — |
| `admission.enquiry.create` | ✅ | ✅ | ✅ | — | — | — |
| `admission.enquiry.update` | ✅ | ✅ | — | — | — | — |
| `admission.enquiry.assign` | ✅ | — | — | ✅ | — | — |
| `admission.application.viewAny` | ✅ | ✅ | — | ✅ | — | — |
| `admission.application.create` | ✅ | ✅ | — | — | — | — |
| `admission.application.update` | ✅ | ✅ | — | — | — | — |
| `admission.application.verify` | ✅ | ✅ | — | — | — | — |
| `admission.application.approve` | ✅ | — | — | ✅ | — | — |
| `admission.application.reject` | ✅ | — | — | ✅ | — | — |
| `admission.entrance-test.viewAny` | ✅ | ✅ | — | ✅ | — | — |
| `admission.entrance-test.create` | ✅ | ✅ | — | — | — | — |
| `admission.entrance-test.update` | ✅ | ✅ | — | — | — | — |
| `admission.merit-list.viewAny` | ✅ | ✅ | — | ✅ | — | — |
| `admission.merit-list.generate` | ✅ | — | — | ✅ | — | — |
| `admission.merit-list.publish` | ✅ | — | — | ✅ | — | — |
| `admission.allotment.viewAny` | ✅ | ✅ | — | ✅ | — | — |
| `admission.allotment.create` | ✅ | — | — | ✅ | — | — |
| `admission.enrollment.store` | ✅ | — | — | ✅ | — | — |
| `admission.enrollment.bulk` | ✅ | — | — | ✅ | — | — |
| `admission.promotion.viewAny` | ✅ | — | — | ✅ | — | ✅ |
| `admission.promotion.confirm` | ✅ | — | — | ✅ | — | — |
| `admission.alumni.viewAny` | ✅ | — | — | ✅ | — | — |
| `admission.alumni.tc` | ✅ | — | — | ✅ | — | — |
| `admission.behavior.viewAny` | ✅ | — | — | ✅ | — | ✅ |
| `admission.behavior.create` | ✅ | — | — | ✅ | — | ✅ |
| `admission.analytics.view` | ✅ | ✅ | — | ✅ | — | — |
| `admission.fee.confirm` | ✅ | — | — | — | ✅ | — |

> **Public routes** `/apply/{slug}`, `/apply/status/{app_no}`, and `/api/v1/admission/payment/webhook` require **no authentication**.

---

## Section 8 — Service Architecture (6 Services)

### 1. `AdmissionPipelineService`
```
Service:     AdmissionPipelineService
File:        app/Services/AdmissionPipelineService.php
Namespace:   Modules\Admission\app\Services
Depends on:  [no other ADM services; calls FIN module service for fee invoice]
Fires:       NTF dispatch at Submitted, Verified, Shortlisted, Allotted, Enrolled stages

Key Methods:
  activateCycle(AdmissionCycle $cycle): void
    └── Guard: checks no other Active cycle for same academic_session_id;
               transitions status Draft → Active; logs to sys_activity_logs

  convertToApplication(Enquiry $enquiry): Application
    └── Copies enquiry fields to adm_applications (pre-filled Draft);
        copies is_sibling_lead/sibling_student_id to application;
        updates enquiry status → Converted; stage logged

  submitApplication(Application $app): void
    └── Validates application_fee_paid = 1 (if fee required);
        transitions Draft → Submitted; logs adm_application_stages; NTF dispatched

  verifyApplication(Application $app): void
    └── Checks all mandatory adm_document_checklist items have Verified docs (BR-ADM-007);
        raises ValidationException if any mandatory doc missing or Rejected;
        transitions Submitted → Verified; logs stage; NTF dispatched

  withdrawApplication(Application $app, array $data): Withdrawal
    └── Computes refund_eligible_amount from refund_policy_json by days since fee payment;
        creates adm_withdrawals; updates application status → Withdrawn; logs stage;
        passes refund instruction to FIN module

  promoteWaitlisted(MeritList $meritList): ?Allotment
    └── Finds next Waitlisted entry (lowest merit_rank with merit_status=Waitlisted);
        creates new adm_allotments record; updates merit_list_entry merit_status → Shortlisted;
        updates application status → Allotted; dispatches NTF; returns new Allotment or null

  confirmAdmissionFee(Allotment $allotment, array $paymentData): void
    └── Sets adm_allotments.admission_fee_paid = 1; records payment amount/date;
        advances allotment status Accepted; NTF confirmation dispatched
```

---

### 2. `MeritListService`
```
Service:     MeritListService
File:        app/Services/MeritListService.php
Namespace:   Modules\Admission\app\Services
Depends on:  [reads adm_seat_capacity; updates adm_merit_list_entries]
Fires:       NTF dispatch on merit list publish

Key Methods:
  generateMeritList(MeritList $meritList): void
    Step 1: Load all Verified applications for cycle+class+quota
    Step 2: For each application:
              entrance_score   = entrance_test_marks × criteria_json.test_pct / 100
              interview_score  = application.interview_score × criteria_json.interview_pct / 100
              academic_score   = application.prev_marks_percent × criteria_json.academic_pct / 100
              raw_score        = entrance_score + interview_score + academic_score
              if application.is_sibling = 1 (staff-confirmed):
                composite = raw_score + merit_list.sibling_bonus_score  [sibling_bonus_applied = 1]
              else: composite = raw_score
    Step 3: Sort by composite DESC;
              tie-break 1: earlier created_at (earlier application date wins)
              tie-break 2: older student_dob (older student wins)
    Step 4: Classify per adm_seat_capacity.total_seats for this quota:
              rank ≤ seat_count → Shortlisted
              rank > seat_count → Waitlisted
              composite < cutoff_score → Rejected
    Step 5: Create adm_merit_list_entries with merit_rank, composite_score, component scores,
              sibling_bonus_applied flag
    Step 6: Update adm_merit_lists.generated_at, generated_by

  allotSeat(MeritListEntry $entry, array $data): Allotment
    └── Reads adm_seat_capacity for cycle+class+quota (BR-ADM-013);
        raises error if seats_allotted >= total_seats;
        creates adm_allotments; increments seats_allotted;
        updates application status → Allotted; stage logged

  computeCompositeScore(Application $app, array $criteria, float $siblingBonus): float
    └── Standalone scoring calculation; reusable for preview
```

---

### 3. `EnrollmentService`
```
Service:     EnrollmentService
File:        app/Services/EnrollmentService.php
Namespace:   Modules\Admission\app\Services
Depends on:  [no other ADM services]
Fires:       NTF: student login credentials + welcome message to parent

Key Methods:
  enrollStudent(Allotment $allotment, array $options): Student
    Step 1:  Verify allotment.admission_fee_paid = 1 (pre-condition)
    Step 2:  Verify no existing enrollment for same session (BR-ADM-010):
               check std_student_academic_sessions unique on (student_id, academic_session_id)
    Step 3:  DB::transaction() begins
    Step 4:  Create sys_users: name (combined first+last), email (parent email), password (generated),
               user_type = 'STUDENT', emp_code (generated), short_name (unique), is_active = 1
    Step 5:  Create std_students: user_id, admission_no, admission_date, first_name, last_name,
               gender, dob, current_status_id → Active
    Step 6:  Determine section:
               if options.section_id provided → use it
               else autoAssignSection(class_id, academic_session_id)
    Step 7:  Assign roll number: sequential within (class_section_id, academic_session_id)
    Step 8:  Create std_student_academic_sessions:
               student_id, academic_session_id, class_section_id, roll_no,
               is_current = 1, session_status_id → Active
    Step 9:  Update adm_allotments: enrolled_student_id = student.id, status = Enrolled
    Step 10: Update adm_applications: status = Enrolled
    Step 11: If application.is_sibling = 1:
               create std_siblings_jnt (student_id, sibling_student_id)
    Step 12: DB::transaction() commits
    Step 13: Dispatch NTF: student login credentials + welcome message to parent email/mobile
    Step 14: Increment adm_seat_capacity.seats_enrolled += 1 (outside transaction — best-effort)

  autoAssignSection(int $classId, int $academicSessionId): int
    └── Queries sch_class_section_jnt for sections of given class;
        counts current std_student_academic_sessions (is_current=1) per section;
        returns section_id with lowest enrollment count

  assignRollNumber(int $classSectionId, int $academicSessionId): int
    └── MAX(roll_no) + 1 for given (class_section_id, academic_session_id); starts at 1

  bulkEnroll(Collection $allotments, array $options): array
    └── Loops over allotments; calls enrollStudent() per record;
        returns per-student success/failure report (never stops entire batch on one failure)

  withdraw(Student $student, int $academicSessionId): void
    └── Updates std_student_academic_sessions.session_status_id → Withdrawn; is_current = 0;
        disables sys_users.is_active = 0
```

---

### 4. `TransferCertificateService`
```
Service:     TransferCertificateService
File:        app/Services/TransferCertificateService.php
Namespace:   Modules\Admission\app\Services
Depends on:  [calls FIN module balance check service]
Fires:       NTF: TC ready notification (optional)

Key Methods:
  issueTc(Student $student, array $data): TransferCertificate
    └── Step 1: FIN module fee-clearance check (BR-ADM-004) — raises error if outstanding balance
        Step 2: Generate TC number: getNextTcNumber(year)
        Step 3: Render DomPDF TC view with school letterhead, QR code, all TC fields
        Step 4: Store PDF in sys_media; set media_id on record
        Step 5: Create adm_transfer_certificates record; set fees_cleared = 1
        Step 6: Update std_students.current_status_id → Alumni
        Step 7: Update std_student_academic_sessions.session_status_id → Alumni/Left; is_current = 0
        Step 8: Disable sys_users.is_active = 0
        Step 9: Log to sys_activity_logs

  generateQrCode(string $tcNumber): string
    └── Encodes public verification URL as QR code image using SimpleSoftwareIO/simple-qrcode

  getNextTcNumber(int $year): string
    └── MAX(id) of adm_transfer_certificates for current year formatted as TC-YYYY-NNN
        Uses DB lock to prevent race condition on concurrent TC issuance
```

---

### 5. `PromotionService`
```
Service:     PromotionService
File:        app/Services/PromotionService.php
Namespace:   Modules\Admission\app\Services
Depends on:  [reads exm_* tables for pass/fail criteria]
Fires:       NTF: parent notification for detention

Key Methods:
  createBatch(array $params): PromotionBatch
    └── Loads students from std_student_academic_sessions (is_current=1, from_session_id + from_class_id);
        creates adm_promotion_batch; creates adm_promotion_records (status Draft)

  applyPromotionCriteria(PromotionBatch $batch): void
    └── Cross-references exm_* result tables for pass/fail per student;
        updates adm_promotion_records.result = Promoted/Detained/Left;
        marks is_exm_not_ready if LmsExam module unavailable (mock-safe)

  override(PromotionRecord $record, string $result, string $remarks): void
    └── Manual change with reason; logs override in remarks column

  preview(PromotionBatch $batch): array
    └── Dry-run: returns {promoted_count, detained_count, left_count} — NO DB writes

  confirmBatch(PromotionBatch $batch): void
    └── DB::transaction():
          Idempotency: firstOrCreate on (student_id, academic_session_id) for new std_student_academic_sessions
          For Promoted: create new std_student_academic_sessions (to_session, to_class_section, is_current=1);
                        set old record is_current=0 (BR-ADM-009)
          For Detained: create same class new session record (is_current=1); old is_current=0
          For Left/Alumni: update status only; no new session record
          Update batch.status → Confirmed; batch.promoted_count, detained_count
        assignRollNumbers(batch)

  assignRollNumbers(PromotionBatch $batch): void
    └── Sequential roll numbers per new class_section + new academic_session
```

---

### 6. `AdmissionAnalyticsService`
```
Service:     AdmissionAnalyticsService
File:        app/Services/AdmissionAnalyticsService.php
Namespace:   Modules\Admission\app\Services
Depends on:  [reads all adm_* tables]
Fires:       none

Key Methods:
  computeFunnel(int $cycleId): array
    └── Counts per stage: enquiries → submitted applications → verified → shortlisted →
        allotted → enrolled; returns stage-by-stage with conversion rates

  computeLeadSourceBreakdown(int $cycleId): array
    └── Groups adm_enquiries by lead_source; returns count + percentage per source

  computeQuotaFillReport(int $cycleId): array
    └── Joins adm_seat_capacity with adm_allotments counts per class per quota;
        returns total_seats, seats_allotted, seats_enrolled, fill_%

  computeCounselorPerformance(int $cycleId, ?Carbon $from, ?Carbon $to): array
    └── Groups by counselor_id: enquiries assigned, Converted count, conversion rate,
        avg_response_time (first follow-up after assignment)

  computeBehaviorScore(int $studentId, int $academicSessionId): int
    └── Sums behavior_score_impact for student in session; starts at 100 (baseline);
        resets at new session start

  export(string $type, int $cycleId, string $format): StreamedResponse
    └── type: 'funnel'|'quota'|'counselor'|'behavior'
        format: 'csv' (fputcsv) | 'pdf' (DomPDF)
```

---

## Section 9 — Integration Contracts (6 Integrations)

| Integration | ADM Action | External Module | How | Payload | Failure Handling |
|-------------|-----------|-----------------|-----|---------|-----------------|
| **STD enrollment write** | `EnrollmentService::enrollStudent()` creates new student records | StudentProfile (STD) | Direct DB write inside `DB::transaction()` | sys_users + std_students + std_student_academic_sessions rows | Full rollback on any exception; no partial records |
| **FIN application fee invoice** | `AdmissionPipelineService` triggers invoice for application fee | StudentFee (FIN) | Service method call (FIN module's InvoiceService) | cycle_id, student_info, amount | Queued retry; enrollment not blocked if FIN temporarily unavailable |
| **FIN admission fee + TC clearance** | `EnrollmentService` and `TransferCertificateService` check FIN balance | StudentFee (FIN) | FIN module balance check service (read-only) | student_id, academic_session_id | Hard block — enrollment/TC blocked until FIN confirms clearance |
| **PAY webhook** | `AllotmentController@paymentWebhook` confirms fee payment | Payment (PAY) | HTTP POST to `/api/v1/admission/payment/webhook`; signature-verified | razorpay_payment_id, order_id, signature | Idempotent: check `application_fee_paid` before processing; ignore re-deliveries; 3 auto-retries by PAY module |
| **NTF notifications** | `AdmissionPipelineService` at each stage transition | Notification (NTF) | Event dispatch + NTF module processing | stage, application_no, parent email/mobile, template_code | Queue retry on failure; stage transition completes even if NTF fails |
| **LmsExam promotion criteria** | `PromotionService::applyPromotionCriteria()` reads exam results | LmsExam (EXM) | Direct DB read from `exm_*` tables | student_id, academic_session_id | Graceful mock: if EXM not available, classify all as Promoted (pending manual override) |

---

## Section 10 — Non-Functional Requirements

| Category | Requirement | Implementation Note |
|----------|-------------|---------------------|
| **Performance** | Public enquiry form < 2s page load | No auth overhead on public routes; Bootstrap 5 CDN; minimal DB queries (one cycle lookup) |
| **Performance** | Enrollment transaction < 5s | `DB::transaction()` with indexed writes; no N+1 queries; avoid eager-loading in transaction |
| **Performance** | Merit list for 1,000 applicants < 10s | Chunked computation (chunk(200)); composite score computed in-memory using pre-loaded collections; indexed `adm_merit_list_entries` |
| **Storage** | Application documents in private storage | `Storage::disk('private')` — not publicly accessible; served via authenticated download route |
| **Security** | Aadhar numbers encrypted at rest | AES-256 per tenant policy; access restricted via `admission.application.verify` permission gate; never logged |
| **Rate Limiting** | Public form 10 submissions/hour/IP | `throttle:10,1` middleware on public routes |
| **Idempotency** | Payment webhook re-delivery safe | Check `adm_allotments.admission_fee_paid = 1` before processing; return 200 on duplicate delivery without processing |
| **Retry** | Payment webhook 3 auto-retry attempts | Handled by PAY module dispatcher; ADM webhook is idempotent |
| **Audit** | All stage transitions logged | `adm_application_stages` — immutable insert-only log; enrollment + TC + promotion logged to `sys_activity_logs` |
| **Idempotency** | Promotion re-run safe | `firstOrCreate` on `(student_id, academic_session_id)` prevents duplicate `std_student_academic_sessions` |
| **Accessibility** | Public form WCAG 2.1 AA | Bootstrap 5 + ARIA attributes + keyboard-navigable multi-step wizard; progress bar with `aria-valuenow` |
| **Consent** | Parent consent checkbox on public form | PDPB compliance; `adm_applications` includes consent timestamp; required before submission |
| **Availability** | 99.9% uptime during peak season (Feb–May) | Queue-based notifications prevent timeouts; DB::transaction() has timeout guard |

---

## Section 11 — Test Plan Outline

### Feature Tests (Pest) — `tests/Feature/Admission/`

| File | Key Scenarios |
|------|---------------|
| `EnquiryCreationTest.php` | Valid enquiry → ENQ-YYYY-NNNNN assigned; NTF dispatched |
| `AgeEligibilityWarningTest.php` | DOB underage for Class 1 → warning returned, submission NOT blocked |
| `SiblingAutoDetectTest.php` | Enquiry contact_mobile matches std_guardians.mobile_no → is_sibling_lead=1 set |
| `DuplicateMobileEnquiryTest.php` | Same mobile submitted twice in same cycle → is_duplicate warning flag |
| `PublicFormSubmissionTest.php` | Unauthenticated POST to /apply/{slug} → record created; rate-limit enforced (10/hr) |
| `ApplicationNumberGenerationTest.php` | Submit application → APP-YYYY-NNNNN format generated, UNIQUE constraint validated |
| `DuplicateAadharTest.php` | Two applications same Aadhar in same cycle → service-layer uniqueness check rejects second |
| `DocumentUploadTest.php` | Upload PDF against checklist item → sys_media stored; adm_application_documents created |
| `ApplicationStatusTransitionTest.php` | Each FSM stage change → adm_application_stages row logged with correct from_status/to_status |
| `MandatoryDocumentBlockTest.php` | Application with missing mandatory doc cannot advance Submitted → Verified (BR-ADM-007) |
| `QuotaSeatCapacityGuardTest.php` | Allot when seats_allotted >= total_seats → ValidationException (BR-ADM-013) |
| `WaitlistAutoPromotionTest.php` | Allotted student declines → next Waitlisted candidate promoted; NTF dispatched |
| `OfferExpiryJobTest.php` | adm:expire-offers job runs → expired offers set to Expired; next waitlisted promoted |
| `EnrollmentAtomicTest.php` | Successful enrollment → sys_users + std_students + std_student_academic_sessions all created |
| `EnrollmentRollbackTest.php` | DB error mid-transaction → no partial records in any table (BR-ADM-002) |
| `DuplicateEnrollmentTest.php` | Enroll same student twice in same session → UNIQUE violation caught gracefully |
| `AutoSectionBalanceTest.php` | autoAssignSection() → picks section with lowest current enrollment count |
| `WithdrawalRefundComputeTest.php` | Withdraw 3 days after fee payment → 100% refund eligible per policy JSON |
| `BulkPromotionTest.php` | Promote 50 students → all get new std_student_academic_sessions; re-run = no duplicates |
| `DetainedStudentTest.php` | Detained student → new session record for same class created; old is_current=0 |
| `TransferCertificateTest.php` | Issue TC → PDF generated; TC-YYYY-NNN unique; QR code embedded |
| `TCOutstandingFeeBlockTest.php` | Issue TC with outstanding FIN balance → blocked with error (BR-ADM-004) |
| `BehaviorIncidentCriticalTest.php` | Critical incident logged → NTF auto-dispatched to principal + parent (Event::fake()) |
| `PaymentWebhookIdempotencyTest.php` | Same PAY webhook delivered twice → admission_fee_paid set once only |

### Unit Tests (PHPUnit) — `tests/Unit/Admission/`

| File | Key Scenarios |
|------|---------------|
| `MeritListCompositeScoreTest.php` | BR-ADM-015: is_sibling=0 (auto-detect only) → no bonus applied; is_sibling=1 → +5 bonus; criteria_json weights correctly applied |
| `SeatCapacityGuardTest.php` | BR-ADM-013: allotSeat() logic with boundary cases (seats_allotted = total_seats − 1 passes; = total_seats fails) |
| `RefundComputationTest.php` | refund_policy_json tiers: 0 days → 100%; 15 days → 50%; 45 days → 0% |
| `AutoSectionBalanceTest.php` | autoAssignSection() with equal enrollment → deterministic selection |
| `TcNumberUniquenessTest.php` | getNextTcNumber(2026) with existing TC-2026-003 → returns TC-2026-004 |
| `RollNumberAssignmentTest.php` | assignRollNumber() with existing 5 students → returns 6 |

### Test Setup Requirements

```php
// Feature tests
uses(Tests\TestCase::class, RefreshDatabase::class);

// Event faking (NTF dispatch)
Event::fake();

// Queue faking (WaitlistPromotionJob, OfferExpiryJob)
Queue::fake();

// Storage faking (DomPDF PDFs)
Storage::fake('private');

// FIN fee service mock
$this->mock(FinBalanceService::class)->shouldReceive('hasOutstandingBalance')->andReturn(false);

// LmsExam mock for promotion tests
$this->mock(ExamResultService::class)->shouldReceive('getPassFail')->andReturn('Promoted');
```

### Required Factories
```
EnquiryFactory       — generates enquiry_no (ENQ-YYYY-NNNNN), status=New, admission_cycle_id
ApplicationFactory   — generates application_no (APP-YYYY-NNNNN), status=Draft, all student fields
MeritListFactory     — generates merit list for cycle+class+quota with criteria_json
AllotmentFactory     — generates allotment linked to merit_list_entry, status=Offered
```

### Minimum Required Seeders for Tests
- `AdmissionDocumentChecklistSeeder` — required for all Phase 1+ tests
- `AdmissionQuotaSeeder` — required for Phase 2+ (merit + allotment) tests

---

## Phase 1 Quality Gate Verification

- [x] All 20 adm_* tables appear in Section 2 entity inventory
- [x] All 15 FRs (ADM-01 to ADM-15) appear in Section 6
- [x] All 15 business rules (BR-ADM-001 to BR-ADM-015) in Section 4 with enforcement point
- [x] All 5 FSMs documented with ASCII state diagram and side effects
- [x] All 6 services listed with key method signatures in Section 8
- [x] All 6 integration contracts documented in Section 9
- [x] BR-ADM-002 enforcement: `service_layer` — `EnrollmentService::enrollStudent()` in `DB::transaction()`
- [x] BR-ADM-004 enforcement: `TransferCertificateService::issueTc()` calls FIN balance check
- [x] BR-ADM-007 enforcement: `AdmissionPipelineService::verifyApplication()` — mandatory doc check
- [x] BR-ADM-011 (NEP 2020 Classes 1–2 warning) noted as non-blocking warning
- [x] BR-ADM-012 (Aadhar partial unique) noted as service-layer only (NOT DB UNIQUE)
- [x] BR-ADM-013 enforcement: `MeritListService::allotSeat()` — seat capacity guard
- [x] BR-ADM-014 enforcement: `adm:expire-offers` scheduled daily job
- [x] BR-ADM-015 (sibling — staff confirm is_sibling=1 required) explicitly noted
- [x] `adm_allotments.enrolled_student_id → std_students.id` noted as SET ON ENROLLMENT
- [x] `EnrollmentService` noted as WRITING to sys_users + std_students + std_student_academic_sessions
- [x] Payment webhook idempotency documented (Section 9 + Section 10)
- [x] `offer_letter_media_id`, `media_id` → `INT UNSIGNED` (sys_media uses INT not BIGINT)
- [x] **No `tenant_id` column** anywhere in any table definition
- [x] Cross-module column names verified against tenant_db_v2.sql (`std_guardians.mobile_no` for sibling detection; `sys_users.id = INT UNSIGNED`; `std_student_academic_sessions` columns verified)
- [x] Public routes `/apply/{slug}` and `/apply/status/{app_no}` flagged as no-auth + rate-limited
- [x] `std_siblings_jnt` and `fin_invoices` noted as pending in DDL

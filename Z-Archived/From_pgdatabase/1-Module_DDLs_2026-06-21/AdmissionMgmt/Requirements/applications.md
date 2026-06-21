# Applications — Requirements

## What It Does
Multi-step application wizard capturing student personal details, guardian information, address, previous education, document uploads, interview scheduling, and fee payment. Manages the full application lifecycle from Draft to Enrolled via a status FSM with immutable audit trail.

## Database Fields

### `adm_applications`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `admission_cycle_id` | BIGINT UNSIGNED | FK → `adm_admission_cycles.id`. |
| `enquiry_id` | BIGINT UNSIGNED | Nullable FK → `adm_enquiries.id`. Source if converted. |
| `application_no` | VARCHAR(20) | Required. UNIQUE. Format: `APP-YYYY-NNNNN`. |
| `class_applied_id` | INT UNSIGNED | FK → `sch_classes.id`. Required. |
| `quota_type` | ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS') | Default `'General'`. |
| `is_sibling` | BOOLEAN | Default `0`. Staff-confirmed sibling (BR-ADM-015). |
| `sibling_student_id` | INT UNSIGNED | Nullable FK → `std_students.id`. Staff-confirmed sibling. |
| `is_staff_ward` | BOOLEAN | Default `0`. Parent is staff member. |
| `student_first_name` | VARCHAR(50) | Required. |
| `student_middle_name` | VARCHAR(50) | Nullable. |
| `student_last_name` | VARCHAR(50) | Nullable. |
| `student_dob` | DATE | Required. |
| `student_gender` | ENUM('Male','Female','Transgender','Prefer Not to Say') | Required. |
| `student_religion` | VARCHAR(50) | Nullable. |
| `student_caste_category` | ENUM('General','OBC','SC','ST','EWS','Other') | Nullable. |
| `student_nationality` | VARCHAR(50) | Default `'Indian'`. |
| `student_mother_tongue` | VARCHAR(50) | Nullable. |
| `aadhar_no` | VARCHAR(20) | Nullable. Partial unique at service layer (BR-ADM-012). |
| `birth_cert_no` | VARCHAR(50) | Nullable. |
| `prev_school_name` | VARCHAR(100) | Nullable. |
| `prev_class_passed` | VARCHAR(20) | Nullable. |
| `prev_marks_percent` | DECIMAL(5,2) | Nullable. For merit calculation. |
| `prev_tc_no` | VARCHAR(50) | Nullable. |
| `blood_group` | ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-','Unknown') | Nullable. |
| `known_allergies` | TEXT | Nullable. |
| `father_name` / `father_mobile` / `father_email` / `father_occupation` | Various | Nullable. |
| `mother_name` / `mother_mobile` / `mother_email` | Various | Nullable. |
| `guardian_name` / `guardian_mobile` / `guardian_relation` | Various | Nullable. |
| `address_line1` / `address_line2` / `city` / `state` / `pincode` | Various | Nullable. |
| `application_fee_paid` | BOOLEAN | Default `0`. |
| `application_fee_amount` | DECIMAL(10,2) | Nullable. |
| `application_fee_date` | DATE | Nullable. |
| `interview_scheduled_at` | DATETIME | Nullable. |
| `interview_venue` | VARCHAR(100) | Nullable. |
| `interview_notes` | TEXT | Nullable. |
| `interview_score` | DECIMAL(5,2) | Nullable. Used in merit composite score. |
| `status` | ENUM('Draft','Submitted','Under_Review','Verified','Shortlisted','Rejected','Waitlisted','Allotted','Enrolled','Withdrawn') | Default `'Draft'`. |
| `rejection_reason` | TEXT | Nullable. |
| `processed_by` | INT UNSIGNED | Nullable FK → `sys_users.id`. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

**Unique:** `uq_adm_app_no` (`application_no`)

### `adm_application_documents`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `application_id` | BIGINT UNSIGNED | FK → `adm_applications.id`. |
| `checklist_item_id` | BIGINT UNSIGNED | FK → `adm_document_checklist.id`. |
| `media_id` | INT UNSIGNED | FK → `sys_media.id`. Uploaded file. |
| `original_filename` | VARCHAR(255) | Required. |
| `verification_status` | ENUM('Pending','Verified','Rejected') | Default `'Pending'`. |
| `verification_remarks` | TEXT | Nullable. Required if rejected. |
| `verified_by` | INT UNSIGNED | Nullable FK → `sys_users.id`. |
| `verified_at` | TIMESTAMP | Nullable. |
| `is_physically_received` | BOOLEAN | Default `0`. Original physically collected. |
| `physical_received_at` | DATE | Nullable. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |

**Unique:** `uq_adm_doc_app_checklist` (`application_id`, `checklist_item_id`)

### `adm_application_stages`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `application_id` | BIGINT UNSIGNED | FK → `adm_applications.id`. |
| `from_status` | VARCHAR(50) | Required. Previous status value. |
| `to_status` | VARCHAR(50) | Required. New status value. |
| `remarks` | TEXT | Nullable. Staff comment or system reason. |
| `changed_by` | INT UNSIGNED | Nullable FK → `sys_users.id`. NULL = system-triggered. |
| `changed_at` | TIMESTAMP | Default `CURRENT_TIMESTAMP`. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |

## Lifecycle (FSM)

```
Draft → Submitted → Under_Review → Verified → Shortlisted → Allotted → Enrolled
                       ↓              ↓            ↓
                     Rejected      Rejected    Rejected ← Allotted → Withdrawn
                                               Waitlisted → Allotted (auto-promotion)
                                                          → Withdrawn
Enrolled → Withdrawn
```

| Transition | Trigger | Pre-conditions |
|---|---|---|
| `Draft → Submitted` | Parent/Applicant submits form | At least one guardian mobile; app fee paid if required |
| `Submitted → Under_Review` | Staff starts review | — |
| `Under_Review → Verified` | All mandatory docs verified (BR-ADM-007) | All `adm_application_documents.verification_status = Verified` |
| `Verified → Shortlisted` | Eligible for merit evaluation | Entrance test/interview completed if applicable |
| `Shortlisted → Allotted` | Seat assigned via merit list | Seats available in selected quota (BR-ADM-013) |
| `Allotted → Enrolled` | Atomic enrollment transaction | Fee paid; enrollment created (BR-ADM-002) |
| `* → Rejected` | Staff rejects | Reason required |
| `Allotted → Withdrawn` | Parent/staff withdraws | Refund computed per cycle policy |

## Business Rules

**Document Verification (BR-ADM-007)**
- All mandatory documents must be `Verified` before application can move from Under_Review to Verified.
- If any document is rejected, application stays in Under_Review until resubmitted.

**Aadhar Uniqueness (BR-ADM-012)**
- Aadhar number is optional but must be unique when provided.
- Enforced at service layer (not DB UNIQUE — MySQL allows multiple NULLs).

**Interview Scheduling**
- Interview can be scheduled (`interview_scheduled_at`, `interview_venue`) after document verification.
- Interview score feeds into merit list composite score.

**Application Fee**
- Fee must be paid (via PAY module integration) before Draft → Submitted transition if `application_fee > 0`.
- RTE quota applicants are exempt (BR-ADM-005).

## CRUD Operations

**Create (Public)**
- Route: `GET /apply/{slug}` → public application form for the cycle
- Submit: `POST /apply/{slug}` → validates → creates Draft application → stores uploaded documents via Spatie Media Library

**Create (Staff)**
- Route: `GET /admission/applications/create` → staff-assisted form (pre-fills from enquiry if `enquiry_id` provided)
- Submit: `POST /admission/applications`

**List**
- Route: `GET /admission/applications` → filterable table (by status, class, cycle, date range, aadhar search)

**View**
- Route: `GET /admission/applications/{application}` → full detail with documents, stages timeline, fee status

**Update Status**
- Route: `PATCH /admission/applications/{application}/status` → status transition with reason
- Routes for individual transitions: verify, reject, shortlist, schedule-interview, etc.

**Upload Document**
- Route: `POST /admission/applications/{application}/documents` → media upload via Spatie Media Library

**Verify Document**
- Route: `PATCH /admission/applications/documents/{document}/verify` → staff verification

## Permissions

| Operation | Permission Key |
|---|---|
| View applications tab | `tenant.adm.application.viewAny` |
| View application details | `tenant.adm.application.viewAny` |
| Create application | `tenant.adm.application.create` |
| Update application status | `tenant.adm.application.update` |
| Verify documents | `tenant.adm.application.verify` |
| Delete application | `tenant.adm.application.delete` |

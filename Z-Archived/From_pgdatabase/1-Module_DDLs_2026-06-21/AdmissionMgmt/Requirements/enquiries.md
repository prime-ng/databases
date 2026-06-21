# Enquiries & CRM — Requirements

## What It Does
Captures inbound admission leads from website, walk-in, campaigns, and referrals. Provides CRM-style follow-up tracking with counselor assignment, sibling auto-detection via mobile match, and duplicate mobile detection.

## Database Fields

### `adm_enquiries`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `admission_cycle_id` | BIGINT UNSIGNED | FK → `adm_admission_cycles.id`. |
| `enquiry_no` | VARCHAR(20) | Required. UNIQUE. Format: `ENQ-YYYY-NNNNN`. |
| `student_name` | VARCHAR(100) | Required. |
| `student_dob` | DATE | Nullable. For age eligibility check. |
| `student_gender` | ENUM('Male','Female','Transgender','Other') | Nullable. |
| `class_sought_id` | INT UNSIGNED | FK → `sch_classes.id`. Required. |
| `father_name` | VARCHAR(100) | Nullable. |
| `mother_name` | VARCHAR(100) | Nullable. |
| `contact_name` | VARCHAR(100) | Required. Primary contact person. |
| `contact_mobile` | VARCHAR(15) | Required. Matched against `std_guardians.mobile_no` for sibling detection. |
| `contact_email` | VARCHAR(100) | Nullable. |
| `lead_source` | ENUM('Website','Walk-in','Campaign','Referral','Social_Media','Phone','Other') | Default `'Walk-in'`. |
| `status` | ENUM('New','Assigned','Contacted','Interested','Not_Interested','Callback','Converted','Duplicate') | Default `'New'`. |
| `counselor_id` | INT UNSIGNED | Nullable FK → `sys_users.id`. Assigned counselor. |
| `is_sibling_lead` | BOOLEAN | Default `0`. Auto-detected via mobile match. |
| `sibling_student_id` | INT UNSIGNED | Nullable FK → `std_students.id`. Matched sibling. |
| `is_duplicate` | BOOLEAN | Default `0`. Duplicate submission flag. |
| `notes` | TEXT | Nullable. |
| `source_reference` | VARCHAR(100) | Nullable. Campaign code / referral name. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

**Unique:** `uq_adm_enq_no` (`enquiry_no`)

### `adm_follow_ups`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `enquiry_id` | BIGINT UNSIGNED | FK → `adm_enquiries.id`. |
| `follow_up_type` | ENUM('Call','Meeting','Email','SMS','Walk-in') | Required. |
| `scheduled_at` | DATETIME | Required. |
| `completed_at` | DATETIME | Nullable. |
| `outcome` | ENUM('Pending','Interested','Not_Interested','Callback','Converted') | Default `'Pending'`. |
| `notes` | TEXT | Nullable. |
| `done_by` | INT UNSIGNED | Nullable FK → `sys_users.id`. Staff who made the follow-up. |
| `reminder_sent` | BOOLEAN | Default `0`. NTF reminder dispatched. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

## Business Rules

**Sibling Auto-Detection (BR-ADM-015)**
- On `adm_enquiries` save, `contact_mobile` is matched against `std_guardians.mobile_no`.
- If match found → `is_sibling_lead = 1`, `sibling_student_id` set to matched student.
- **Auto-detection alone is insufficient** for merit bonus — staff must confirm `is_sibling = 1` on the application.

**Duplicate Detection**
- Same `contact_mobile` submitted twice within same cycle → `is_duplicate = 1` flag set.
- Warning shown to counselor, not a hard block.

**Enquiry-to-Application Conversion**
- When an enquiry is converted to an application, the `enquiry_id` is linked on the `adm_applications` record.
- Enquiry status changes to `'Converted'`.

**Age Eligibility (BR-ADM-001)**
- `student_dob` checked against cycle's `age_rules_json` → non-blocking warning if outside range.

**Follow-Up Scheduling**
- Follow-ups can be scheduled (future `scheduled_at`) and are periodically checked for reminder dispatch.
- `reminder_sent` flag prevents duplicate NTF dispatches.

## CRUD Operations

**Create**
- Route: `POST /admission/enquiries` → form with student details, guardian contact, class sought, lead source
- Validates: `contact_mobile` required; class_sought_id exists; sibling auto-detect on save
- Auto-generates `enquiry_no` (ENQ-YYYY-NNNNN)

**List**
- Route: `GET /admission/enquiries` → filterable table (by status, counselor, lead source, date range, cycle)
- Actions: View, Assign Counselor, Add Follow-Up, Convert to Application

**View**
- Route: `GET /admission/enquiries/{enquiry}` → detail with sibling info, follow-up timeline

**Update**
- Route: `PUT /admission/enquiries/{enquiry}` → update status, reassign counselor, add notes

**Delete (Soft)**
- Route: `DELETE /admission/enquiries/{enquiry}` → blocked if already converted to application

**Add Follow-Up**
- Route: `POST /admission/enquiries/{enquiry}/follow-ups` → log call/meeting/email with outcome

## Permissions

| Operation | Permission Key |
|---|---|
| View enquiries tab | `tenant.adm.enquiry.viewAny` |
| Create enquiry | `tenant.adm.enquiry.create` |
| Assign counselor | `tenant.adm.enquiry.update` |
| Add follow-up | `tenant.adm.enquiry.update` |
| Convert to application | `tenant.adm.enquiry.update` |
| Delete enquiry | `tenant.adm.enquiry.delete` |

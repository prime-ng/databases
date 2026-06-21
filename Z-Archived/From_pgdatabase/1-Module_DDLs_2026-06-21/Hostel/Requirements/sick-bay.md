# Sick Bay Admissions — Requirements

## What It Does
Sick bay admission log. Tracks students admitted to the hostel sick bay — presenting symptoms, diagnosis, treatment, discharge, and hospital referral. Supports parent notification on admission/discharge.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `student_id` | INT UNSIGNED FK → std_students | Required. |
| `admission_datetime` | DATETIME | Required. |
| `discharge_datetime` | DATETIME | Nullable. |
| `presenting_symptoms` | TEXT | Required. |
| `initial_diagnosis` | VARCHAR(500) | Nullable. |
| `treatment_notes` | TEXT | Nullable. |
| `attending_staff_id` | INT UNSIGNED FK → sys_users | Nullable. |
| `discharge_notes` | TEXT | Nullable. |
| `is_hospital_referred` | TINYINT(1) | Default 0. |
| `hpc_record_id` | BIGINT UNSIGNED | Nullable. Soft FK to HPC. |
| `parent_notified` | TINYINT(1) | Default 0. |
| `medical_consent_received` | TINYINT(1) | Default 0. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Lifecycle**
Admitted → Under Treatment → Discharged / Referred to Hospital

**Parent Notification**
- Sent on: admission (when serious), discharge, hospital referral
- Sick bay admission auto-marks attendance as "In Sick Bay"
- Hospital referral links to HPC module

## CRUD Operations

**Create** — `GET /hostel/sick-bay/create` → form with student, hostel, symptoms | `POST /hostel/sick-bay` → validates → saves → redirects

**List** — `GET /hostel/sick-bay` → paginated table | Filter: hostel, date range | Tab in Daily Operations & Safety

**Current Admissions** — `GET /hostel/sick-bay/current` → shows currently admitted students (no discharge time)

**View** — `GET /hostel/sick-bay/{id}` → full detail with vitals and medications tabs

**Edit** — `GET /hostel/sick-bay/{id}/edit` | `PUT` → updates treatment notes

**Discharge** — `GET /hostel/sick-bay/{id}/discharge` → discharge form | `POST /hostel/sick-bay/{id}/discharge` → records discharge datetime, notes → redirects

**Vitals (nested)** — `POST /hostel/sick-bay/{sickBay}/vitals` → stores vital reading

**Medications (nested)** — `POST /hostel/sick-bay/{sickBay}/medications` → stores medication record

**Delete (Soft)** — `DELETE /hostel/sick-bay/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-sick-bay.viewAny` |
| View details | `tenant.hostel-sick-bay.view` |
| Create | `tenant.hostel-sick-bay.create` |
| Edit/update | `tenant.hostel-sick-bay.update` |
| Discharge | `tenant.hostel-sick-bay.discharge` |
| Soft delete | `tenant.hostel-sick-bay.delete` |
| Restore | `tenant.hostel-sick-bay.restore` |
| Force delete | `tenant.hostel-sick-bay.forceDelete` |

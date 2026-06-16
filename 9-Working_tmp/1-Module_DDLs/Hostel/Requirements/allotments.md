# Room Allotments — Requirements

## What It Does
Maps a student to a specific bed for an academic session. Allotments drive occupancy tracking, fee demand generation, attendance, and parent communication. Supports transfer, vacate, and bulk vacate workflows.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | INT UNSIGNED FK → std_students | Required. |
| `bed_id` | BIGINT UNSIGNED FK → hst_beds | Required. |
| `academic_session_id` | INT UNSIGNED FK → sch_academic_term | Required. |
| `allotment_date` | DATE | Required. |
| `vacating_date` | DATE | Nullable. |
| `meal_plan` | ENUM(full_board, lunch_only, dinner_only, none) | Default 'full_board'. |
| `status` | INT UNSIGNED FK → hst_dynamic_status_masters | Required. |
| `is_alloted` | TINYINT(1) | Default 1. |
| `remarks` | VARCHAR(500) | Nullable. |
| `transfer_from_allotment_id` | BIGINT UNSIGNED FK → hst_allotments | Nullable. Set on transfer. |
| `vacation_reason` | ENUM(graduation, transfer_out, withdrawal, disciplinary, medical, family, other) | Nullable. |
| `vacated_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `is_emergency` | TINYINT(1) | Default 0. Mid-semester emergency placement. |
| `gen_active_bed_id` | BIGINT GENERATED | STORED. Non-null only when `is_alloted = 1`. |
| `gen_active_student_id` | BIGINT GENERATED | STORED. Non-null only when `is_alloted = 1`. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Unique Constraints**
- `gen_active_bed_id` — unique, ensures no two active allotments on the same bed
- `gen_active_student_id` — unique, ensures no two active allotments for the same student

**Allotment Lifecycle**
Draft → Allotted → Active → Vacated / Transferred

**Transfer Workflow**
- Creates a new allotment referencing `transfer_from_allotment_id`
- Sets `vacation_reason` on the old allotment
- Vacate date is set on the old allotment

**Bulk Vacate**
- Filter by hostel, floor, academic session
- Returns count of closed allotments

**Availability Check**
- `GET /hostel/allotments/availability` → grid showing hostel → floor → room → bed availability counts
- Filters by hostel, floor, room type

## CRUD Operations

**Create** — `GET /hostel/allotments/create` → form with student search, bed selector, meal plan | `POST /hostel/allotments` → validates → saves → generates fee demand → audit → redirects to `hostel.allotments.index`

**List** — `GET /hostel/allotments` → paginated with tabs (Allotments/Reservations/RCR/Attendance) | Filters: Hostel, Status | Paginated 15 per page with named pages

**View** — `GET /hostel/allotments/{id}` → loads with student, bed, session relationships

**Edit** — `GET /hostel/allotments/{id}/edit` | `PUT /hostel/allotments/{id}` → validates → updates → redirects

**Delete (Soft)** — `DELETE /hostel/allotments/{id}` → deactivates → soft deletes

**Vacate** — `POST /hostel/allotments/{allotment}/vacate` → records vacating date, reason, vacated_by → audit → redirects

**Transfer** — `GET /hostel/allotments/{allotment}/transfer` → shows transfer form with bed selector | `POST /hostel/allotments/{allotment}/transfer` → vacates old, creates new → redirects

**Bulk Vacate** — `GET /hostel/allotments/bulk-vacate` → form | `POST /hostel/allotments/bulk-vacate` → returns count of vacated allotments

**Get Students (AJAX)** — `GET /hostel/allotments/get-students` → filters students by `class_section_id` → JSON

**Availability** — `GET /hostel/allotments/availability` → grid view

**Toggle Status** — `POST /hostel/allotments/{allotment}/toggle-status` → AJAX JSON

**Restore** — `GET /hostel/allotments/{id}/restore`

**Force Delete** — `DELETE /hostel/allotments/{id}/force-delete` → catches FK integrity constraints

**Trash Page** — `GET /hostel/allotments/trash/view`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-allotment.viewAny` |
| View details | `tenant.hostel-allotment.view` |
| Create/allot | `tenant.hostel-allotment.allot` |
| Edit/manage | `tenant.hostel-allotment.manage` |
| Soft delete | `tenant.hostel-allotment.delete` |
| View trash & restore | `tenant.hostel-allotment.restore` |
| Force delete | `tenant.hostel-allotment.forceDelete` |
| Vacate | `tenant.hostel-allotment.vacate` |
| Transfer | `tenant.hostel-allotment.transfer` |
| Bulk vacate | `tenant.hostel-allotment.bulk-vacate` |

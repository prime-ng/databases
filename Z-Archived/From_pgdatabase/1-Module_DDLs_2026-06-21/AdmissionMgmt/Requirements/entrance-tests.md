# Entrance Tests — Requirements

## What It Does
Schedule and manage entrance/aptitude test sessions per class per admission cycle. Register candidates from verified applications, record marks with subject-wise breakdown, and determine pass/fail/absent results for merit list computation.

## Database Fields

### `adm_entrance_tests`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `admission_cycle_id` | BIGINT UNSIGNED | FK → `adm_admission_cycles.id`. |
| `class_id` | INT UNSIGNED | FK → `sch_classes.id`. Warning if class 1 or 2 (NEP 2020). |
| `test_name` | VARCHAR(100) | Required. |
| `test_date` | DATE | Required. |
| `start_time` | TIME | Required. |
| `end_time` | TIME | Required. Must be > start_time. |
| `venue` | VARCHAR(100) | Nullable. |
| `max_marks` | DECIMAL(6,2) | Required. |
| `passing_marks` | DECIMAL(6,2) | Nullable. |
| `subjects_json` | JSON | Nullable. Subject areas with individual max marks. |
| `status` | ENUM('Scheduled','Completed','Cancelled') | Default `'Scheduled'`. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

### `adm_entrance_test_candidates`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `entrance_test_id` | BIGINT UNSIGNED | FK → `adm_entrance_tests.id`. |
| `application_id` | BIGINT UNSIGNED | FK → `adm_applications.id`. |
| `roll_no` | VARCHAR(20) | Nullable. Test hall roll number. |
| `marks_obtained` | DECIMAL(6,2) | Nullable. NULL until marks entered. |
| `result` | ENUM('Pass','Fail','Absent','Pending') | Default `'Pending'`. |
| `subject_marks_json` | JSON | Nullable. Per-subject breakdown. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

**Unique:** `uq_adm_etc_test_app` (`entrance_test_id`, `application_id`)

## Business Rules

**NEP 2020 Compliance (BR-ADM-011)**
- Entrance tests not allowed for Classes 1–2 (non-blocking warning on test creation).

**Candidate Registration**
- Each candidate can be registered once per test session (unique constraint).
- Candidates registered from Shortlisted/Verified applications only.

**Marks Entry**
- Marks entered after test completion.
- NULL `marks_obtained` → treated as `Absent`.
- `subject_marks_json` allows per-subject breakdown for detailed scoring.

**Result Determination**
- `marks_obtained >= passing_marks` → `Pass`; otherwise → `Fail`.
- Test result weighted component in merit list composite score (`criteria_json.test_pct`).

**Integration with Merit List**
- `MeritListService` reads entrance test marks during composite score computation.
- Cancelled tests: candidates excluded from entrance score component (weight redistributed).

## CRUD Operations

**Create**
- Route: `POST /admission/entrance-tests` → schedule test session with date, time, venue, marks
- Validates: class not 1–2 (warning); end_time > start_time; test_date within cycle window

**List**
- Route: `GET /admission/entrance-tests` → table with test name, date, class, status, candidate count, action buttons

**View**
- Route: `GET /admission/entrance-tests/{test}` → detail with candidate list, marks summary, results breakdown

**Update**
- Route: `PUT /admission/entrance-tests/{test}` → edit test details before test_date; cannot edit after Completed

**Register Candidates**
- Route: `POST /admission/entrance-tests/{test}/candidates` → bulk register candidates from Verified applications
- Auto-assigns roll numbers

**Enter Marks**
- Route: `PATCH /admission/entrance-tests/candidates/{candidate}/marks` → enter marks_obtained, subject_marks_json, auto-compute result

**Delete (Soft)**
- Route: `DELETE /admission/entrance-tests/{test}` → blocked if results entered; deactivate instead
- Candidates with `Pass`/`Fail` result cannot be deleted

## Permissions

| Operation | Permission Key |
|---|---|
| View entrance tests tab | `tenant.adm.test.viewAny` |
| Create test | `tenant.adm.test.manage` |
| Register candidates | `tenant.adm.test.manage` |
| Enter marks | `tenant.adm.test.manage` |
| Update test | `tenant.adm.test.manage` |
| Delete test | `tenant.adm.test.manage` |

# Admission Cycles — Requirements

## What It Does
Manages annual admission campaigns. Each cycle defines the admission window, application fee, seat budgets per quota class, required document checklist, refund policy, and public application form URL. Every admission operation is scoped to a single active cycle.

## Database Fields

### `adm_admission_cycles`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `academic_session_id` | INT UNSIGNED | FK → `sch_org_academic_sessions_jnt.id`. Target academic year. |
| `name` | VARCHAR(100) | Required. e.g., "Main Admission 2026-27". |
| `cycle_code` | VARCHAR(20) | Required. UNIQUE. e.g., "ADM-2627-M". |
| `start_date` | DATE | Required. Enquiry open date. |
| `end_date` | DATE | Required. Enquiry close date. Must be > start_date. |
| `application_fee` | DECIMAL(10,2) | Default `0.00`. |
| `admission_no_format` | VARCHAR(100) | Nullable. Template e.g. `{YEAR}/{SEQ}`. |
| `sibling_bonus_score` | TINYINT UNSIGNED | Default `5`. Merit bonus for confirmed siblings. |
| `age_rules_json` | JSON | Nullable. Min/max age per class on cut-off date. |
| `refund_policy_json` | JSON | Nullable. Refund % tiers by days since payment. |
| `application_form_url` | VARCHAR(255) | Nullable. Public form slug. |
| `status` | ENUM('Draft','Active','Closed','Archived') | Default `'Draft'`. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

**Unique:** `uq_adm_cyc_code` (`cycle_code`)

### `adm_document_checklist`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `admission_cycle_id` | BIGINT UNSIGNED | FK → `adm_admission_cycles.id`. |
| `class_id` | INT UNSIGNED | Nullable FK → `sch_classes.id`. NULL = applies to all classes. |
| `document_name` | VARCHAR(100) | Required. e.g., "Birth Certificate". |
| `document_code` | VARCHAR(30) | Required. e.g., "BIRTH_CERT". |
| `is_mandatory` | BOOLEAN | Default `1`. Must be uploaded before submission. |
| `is_system` | BOOLEAN | Default `0`. Seeded default template row. |
| `accepted_formats` | VARCHAR(100) | Default `'pdf,jpg,png'`. |
| `max_size_kb` | INT UNSIGNED | Default `5120`. |
| `sort_order` | TINYINT UNSIGNED | Default `0`. Display order. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

### `adm_quota_config`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `admission_cycle_id` | BIGINT UNSIGNED | FK → `adm_admission_cycles.id`. |
| `class_id` | INT UNSIGNED | FK → `sch_classes.id`. |
| `quota_type` | ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS') | Required. |
| `total_seats` | SMALLINT UNSIGNED | Required. Total seats in this quota for this class. |
| `reserved_seats` | SMALLINT UNSIGNED | Default `0`. RTE mandated minimum. |
| `application_fee_waiver` | BOOLEAN | Default `0`. 1 = fee waived (e.g., RTE, EWS). |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

### `adm_seat_capacity`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `admission_cycle_id` | BIGINT UNSIGNED | FK → `adm_admission_cycles.id`. |
| `class_id` | INT UNSIGNED | FK → `sch_classes.id`. |
| `quota_type` | ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS') | Required. |
| `total_seats` | SMALLINT UNSIGNED | Required. Configured seat budget. |
| `seats_allotted` | SMALLINT UNSIGNED | Default `0`. Incremented by `MeritListService::allotSeat()`. |
| `seats_enrolled` | SMALLINT UNSIGNED | Default `0`. Incremented by `EnrollmentService::enrollStudent()`. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

**Unique:** `uq_adm_sc_cycle_class_quota` (`admission_cycle_id`, `class_id`, `quota_type`)

## Business Rules

**Cycle Activation**
- Only one cycle may be `Active` per `academic_session_id` at a time (enforced in `AdmissionPipelineService::activateCycle()`).
- `start_date < end_date` — cycle must have positive duration.

**Seat Capacity Guard (BR-ADM-013)**
- `MeritListService::allotSeat()` checks `seats_allotted >= total_seats` before creating allotment.
- Both `seats_allotted` and `seats_enrolled` are atomically incremented counters — never set directly.

**RTE Quota (BR-ADM-005)**
- 25% of Class 1 seats reserved for EWS category.
- RTE applicants are exempt from application fee (`application_fee_waiver = 1`).

**Refund Policy**
- Application fee is non-refundable by default (BR-ADM-006).
- `refund_policy_json` defines refund % tiers (e.g., "100% within 7 days; 50% 7–30 days; 0% beyond 30 days").
- Refund computed at withdrawal time by `AdmissionPipelineService::withdrawApplication()`.

**Age Rules**
- `age_rules_json` stores configurable min/max age per class on cut-off date (default June 1).
- Displayed as a non-blocking warning — not a hard block.

## CRUD Operations

**Create**
- Route: `GET /admission/cycles/create` → form with cycle dates, fee, sibling bonus
- Submit: `POST /admission/cycles` → validates → saves → redirects

**List**
- Route: `GET /admission/cycles` → table with status badges (Draft/Active/Closed/Archived), date range, application count

**View**
- Route: `GET /admission/cycles/{cycle}` → detail with seat capacity summary, quota config, document checklist

**Update**
- Route: `PUT /admission/cycles/{cycle}` → cannot edit an Archived cycle

**Delete (Soft)**
- Route: `DELETE /admission/cycles/{cycle}` → blocked if enquiries or applications exist
- Pre-delete: deactivate (`is_active = false`)

**Activate/Close/Archive**
- Activations: POST route to change status with validation for only-one-active-per-session

## Permissions

| Operation | Permission Key |
|---|---|
| View cycles tab | `tenant.adm.cycles.viewAny` |
| Create cycle | `tenant.adm.cycles.manage` |
| Update cycle | `tenant.adm.cycles.manage` |
| Activate/Close cycle | `tenant.adm.cycles.manage` |
| Delete cycle | `tenant.adm.cycles.manage` |

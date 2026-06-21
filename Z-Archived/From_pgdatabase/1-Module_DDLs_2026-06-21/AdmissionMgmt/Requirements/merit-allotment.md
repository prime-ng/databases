# Merit List & Seat Allotment — Requirements

## What It Does
Generate ranked merit lists per cycle/class/quota using weighted scores from entrance tests, interviews, and previous academics. Allot seats within capacity, manage waitlists with auto-promotion on offer expiry/decline, and apply sibling bonus scores.

## Database Fields

### `adm_merit_lists`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `admission_cycle_id` | BIGINT UNSIGNED | FK → `adm_admission_cycles.id`. |
| `class_id` | INT UNSIGNED | FK → `sch_classes.id`. |
| `quota_type` | ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS') | Required. |
| `generated_at` | TIMESTAMP | Nullable. Set when generation completes. |
| `generated_by` | INT UNSIGNED | Nullable FK → `sys_users.id`. |
| `status` | ENUM('Draft','Published','Finalized') | Default `'Draft'`. |
| `criteria_json` | JSON | Nullable. Weightage: `{test_pct, interview_pct, academic_pct}` — must sum to 100. |
| `sibling_bonus_score` | TINYINT UNSIGNED | Default `5`. Copied from cycle config at generation. |
| `cutoff_score` | DECIMAL(6,2) | Nullable. Below cutoff → Rejected. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

### `adm_merit_list_entries`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `merit_list_id` | BIGINT UNSIGNED | FK → `adm_merit_lists.id`. |
| `application_id` | BIGINT UNSIGNED | FK → `adm_applications.id`. |
| `merit_rank` | SMALLINT UNSIGNED | Required. 1 = top ranked. |
| `composite_score` | DECIMAL(6,2) | Nullable. Final score after sibling bonus. |
| `entrance_score` | DECIMAL(6,2) | Nullable. Weighted entrance marks. |
| `interview_score` | DECIMAL(6,2) | Nullable. Weighted interview marks. |
| `academic_score` | DECIMAL(6,2) | Nullable. Weighted previous academic marks. |
| `sibling_bonus_applied` | BOOLEAN | Default `0`. 1 = bonus was added to composite. |
| `merit_status` | ENUM('Shortlisted','Waitlisted','Rejected') | Default `'Shortlisted'`. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

### `adm_allotments`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `merit_list_entry_id` | BIGINT UNSIGNED | FK → `adm_merit_list_entries.id`. |
| `application_id` | BIGINT UNSIGNED | FK → `adm_applications.id`. |
| `admission_no` | VARCHAR(50) | Nullable. UNIQUE. Assigned on offer letter. |
| `allotted_class_id` | INT UNSIGNED | FK → `sch_classes.id`. Required. |
| `allotted_section_id` | INT UNSIGNED | Nullable FK → `sch_sections.id`. Assigned at enrollment. |
| `joining_date` | DATE | Nullable. Expected joining date. |
| `offer_letter_media_id` | INT UNSIGNED | Nullable FK → `sys_media.id`. PDF offer letter. |
| `offer_issued_at` | TIMESTAMP | Nullable. When offer PDF was generated. |
| `offer_expires_at` | DATE | Nullable. Deadline for parent response. |
| `admission_fee_paid` | BOOLEAN | Default `0`. |
| `admission_fee_amount` | DECIMAL(10,2) | Nullable. |
| `admission_fee_date` | DATE | Nullable. |
| `status` | ENUM('Offered','Accepted','Declined','Expired','Enrolled','Withdrawn') | Default `'Offered'`. |
| `enrolled_student_id` | INT UNSIGNED | Nullable FK → `std_students.id`. Set on enrollment. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

## Business Rules

**Composite Score Computation**
```
composite_score = (entrance_score × test_pct/100) 
                + (interview_score × interview_pct/100) 
                + (academic_score × academic_pct/100)
                + (is_sibling ? sibling_bonus_score : 0)
```
- `criteria_json` weights (`test_pct`, `interview_pct`, `academic_pct`) must sum to 100.
- Sibling bonus (+5 default) only if `is_sibling = 1` (staff-confirmed), not auto-detect alone (BR-ADM-015).

**Tie-Break Rules**
1. Higher composite score
2. Earlier application created_at date
3. Older student_dob

**Seat Capacity Guard (BR-ADM-013)**
- `MeritListService::allotSeat()` checks `seats_allotted < total_seats` before creating allotment.
- Capacity checked per `(admission_cycle_id, class_id, quota_type)`.

**Merit Status Classification**
- Top N (up to `total_seats`): `Shortlisted` → eligible for allotment.
- Next M: `Waitlisted` → auto-promoted when shortlisted candidates decline/expire.
- Below cutoff: `Rejected`.

**Offer Expiry (BR-ADM-014)**
- Offers expire after N days (configurable per cycle or default).
- Daily Artisan command `adm:expire-offers` checks expired offers → marks as `Expired` → triggers `promoteWaitlisted()`.

**Waitlist Auto-Promotion**
- When an offer is `Declined` or `Expired`, next `Waitlisted` candidate is auto-promoted to `Shortlisted` and a new offer is generated.

## CRUD Operations

**Generate Merit List**
- Route: `POST /admission/merit-lists/generate` → accepts cycle, class, quota → runs `MeritListService::generateMeritList()`
- Must be in Draft status after generation for review

**List**
- Route: `GET /admission/merit-lists` → table with cycle, class, quota, status, generated date

**View**
- Route: `GET /admission/merit-lists/{list}` → ranked entries with scores, categorised by merit_status

**Publish/Finalize**
- Route: `PATCH /admission/merit-lists/{list}/publish` → Draft → Published
- Route: `PATCH /admission/merit-lists/{list}/finalize` → Published → Finalized (irreversible)

**Allot Seat**
- Route: `POST /admission/merit-lists/entries/{entry}/allot` → creates allotment with admission_no, offer_expires_at
- Generates offer letter PDF automatically

**Update Allotment Status**
- Route: `PATCH /admission/allotments/{allotment}/status` → accept/decline/expire

## Permissions

| Operation | Permission Key |
|---|---|
| View merit lists tab | `tenant.adm.merit.viewAny` |
| Generate merit list | `tenant.adm.merit.generate` |
| Publish/finalize list | `tenant.adm.merit.publish` |
| Allot seat | `tenant.adm.merit.allot` |
| Update allotment status | `tenant.adm.merit.allot` |

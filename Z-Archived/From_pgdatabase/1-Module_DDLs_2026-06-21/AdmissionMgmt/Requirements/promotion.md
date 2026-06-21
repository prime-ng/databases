# Promotion — Requirements

## What It Does
Year-end promotion wizard that moves students from current academic session to the next. Loads enrolled students, applies pass/fail criteria from exam results (LmsExam module), allows manual overrides, and confirms promotions by creating new `std_student_academic_sessions` records in a single transaction.

## Database Fields

### `adm_promotion_batches`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `from_session_id` | INT UNSIGNED | FK → `sch_org_academic_sessions_jnt.id`. Current session. |
| `to_session_id` | INT UNSIGNED | FK → `sch_org_academic_sessions_jnt.id`. Next session. |
| `from_class_id` | INT UNSIGNED | FK → `sch_classes.id`. Source class. |
| `to_class_id` | INT UNSIGNED | FK → `sch_classes.id`. Destination class (same for detention). |
| `criteria_json` | JSON | Nullable. Pass % threshold and exam weights. |
| `total_students` | INT UNSIGNED | Default `0`. Count loaded at batch creation. |
| `promoted_count` | INT UNSIGNED | Default `0`. Updated on confirm. |
| `detained_count` | INT UNSIGNED | Default `0`. Updated on confirm. |
| `status` | ENUM('Draft','Confirmed') | Default `'Draft'`. |
| `processed_by` | INT UNSIGNED | Nullable FK → `sys_users.id`. |
| `processed_at` | TIMESTAMP | Nullable. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

### `adm_promotion_records`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `promotion_batch_id` | BIGINT UNSIGNED | FK → `adm_promotion_batches.id`. |
| `student_id` | INT UNSIGNED | FK → `std_students.id`. |
| `from_class_section_id` | INT UNSIGNED | FK → `sch_class_section_jnt.id`. Source class+section. |
| `to_class_section_id` | INT UNSIGNED | Nullable FK → `sch_class_section_jnt.id`. NULL if detained/left. |
| `new_roll_no` | SMALLINT UNSIGNED | Nullable. Assigned for new session. |
| `result` | ENUM('Promoted','Detained','Transferred','Alumni','Left') | Required. |
| `remarks` | TEXT | Nullable. Manual override reason. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

## Lifecycle (FSM)

```
Draft (preview) → Confirmed (write to DB)
```

## Business Rules

**Promotion Creates New Records (BR-ADM-009)**
- Promoted: creates new `std_student_academic_sessions` for `to_session` with `is_current=1`.
- Detained: creates new session record for same class (is_current=1).
- Old records are NOT modified — only `is_current` set to 0.
- Idempotency guard: `firstOrCreate` on `(student_id, academic_session_id)` prevents duplicates on re-run.

**Exam Criteria Application**
- `criteria_json` defines pass/fail thresholds.
- Cross-references `exm_*` exam result tables (LmsExam module) for pass/fail determination.
- Graceful fallback: if LmsExam module not installed, all students default to Promoted.

**Manual Overrides**
- Allowed while batch is in `Draft` status.
- Override reason recorded in `remarks`.
- Principal/HOD permission required for manual overrides.

**Batch Creation Flow**
1. Admin selects `from_session`, `to_session`, `from_class`, `to_class`.
2. System loads students from `std_student_academic_sessions` (is_current=1).
3. Cross-references exam results for auto-classification.
4. Auto-classifies: Promoted / Detained / Transferred / Left / Alumni.
5. Manual overrides allowed in Draft.
6. Preview (dry-run) shows counts with NO DB writes.
7. Confirmation commits all changes in single `DB::transaction()`.

**Confirm Batch Side Effects**
- Promoted: create new `std_student_academic_sessions` (to_session, new section, roll_no, is_current=1).
- Detained: create new session record for same class (is_current=1).
- Left/Alumni: update status only; no new session record.
- Roll numbers assigned sequentially per new `(class_section_id, session_id)`.
- NTF dispatched to parents for detention.

## CRUD Operations

**Create Batch**
- Route: `POST /admission/promotion/batches` → create with from/to session/class → auto-loads students

**List**
- Route: `GET /admission/promotion/batches` → table with session, class, status, counts

**View/Preview**
- Route: `GET /admission/promotion/batches/{batch}` → student list with auto-classified results, override buttons
- Preview mode: dry-run with counts, no DB writes

**Update Override**
- Route: `PATCH /admission/promotion/batches/{batch}/students/{student}` → manual override of promotion result

**Confirm Batch**
- Route: `POST /admission/promotion/batches/{batch}/confirm` → commits all changes in single transaction

**Delete (Soft)**
- Route: `DELETE /admission/promotion/batches/{batch}` → only Draft batches can be deleted

## Permissions

| Operation | Permission Key |
|---|---|
| View promotion tab | `tenant.adm.promotion.viewAny` |
| Create batch | `tenant.adm.promotion.manage` |
| Override student result | `tenant.adm.promotion.override` |
| Confirm batch | `tenant.adm.promotion.confirm` |

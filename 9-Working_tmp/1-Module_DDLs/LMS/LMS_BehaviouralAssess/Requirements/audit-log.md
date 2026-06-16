# Audit Log — Requirements

## What It Does
Immutable audit trail recording every change to assessment ratings, assessment status transitions, and incident modifications. Critical for CBSE/ICSE CCE compliance requirements — schools must demonstrate that behavioural ratings were not tampered with after submission.

## Database Fields

### `ba_audit_log`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `entity_type` | ENUM('assessment_rating','assessment','incident') | Required. Type of entity being audited. |
| `entity_id` | BIGINT UNSIGNED | Required. ID of the entity record. |
| `field_name` | VARCHAR(50) | Required. Column that changed (e.g., "rating_level_id", "status"). |
| `old_value` | VARCHAR(255) | Nullable. Previous value (NULL for initial creation). |
| `new_value` | VARCHAR(255) | Required. New value. |
| `changed_by` | BIGINT UNSIGNED | Required. `sys_users.id` who made the change. |
| `changed_at` | TIMESTAMP | Required. Default `CURRENT_TIMESTAMP`. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` | BIGINT UNSIGNED | Required. `sys_users.id`. |
| `created_at` | TIMESTAMP | Laravel standard. |

**Key Design: This table has NO `updated_at`, NO `updated_by`, NO `deleted_at` — audit records are IMMUTABLE and append-only.**

## What Gets Logged

| Entity Type | Field | Trigger | Old → New Example |
|---|---|---|---|
| `assessment_rating` | `rating_level_id` | Observer on `updating` event | `3` → `4` (teacher changed rating) |
| `assessment` | `status` | Observer on `updating` event | `'draft'` → `'submitted'` |
| `incident` | `follow_up_notes` | Observer on incident follow-up | `NULL` → `'Met with parents'` |
| `incident` | `severity` | Observer on severity change | `'moderate'` → `'major'` |

## Audit Observer Logic

**AssessmentRatingObserver**
- Hook: `BaAssessmentRating::updating()`
- Checks if `rating_level_id` was modified.
- If yes, writes a log entry: `entity_type='assessment_rating'`, `entity_id` = rating ID, `field_name='rating_level_id'`, `old_value` = previous level ID, `new_value` = new level ID.
- Logged after the model is saved (to ensure new_value is final).

**AssessmentObserver**
- Hook: `BaAssessment::updating()`
- Checks if `status` was modified.
- Logs status transitions with old and new status values.
- Also logs `reviewer_remarks` changes and `reviewed_by` assignments.

## CRUD Operations
- **Read-only** in the UI — visible in an "Audit Log" tab for administrative review.
- No create, edit, soft-delete, or force-delete operations.
- Query patterns:
  - "Show all changes to a specific rating": `WHERE entity_type='assessment_rating' AND entity_id=<id> ORDER BY changed_at`
  - "Show all audit activity by a teacher": `WHERE changed_by=<user_id>`
  - "Show all changes in a date range": `WHERE changed_at BETWEEN ... AND ...`

## Permissions

| Operation | Permission Key |
|---|---|
| View audit log tab | `tenant.ba.audit.viewAny` |
| View audit details | `tenant.ba.audit.viewAny` |

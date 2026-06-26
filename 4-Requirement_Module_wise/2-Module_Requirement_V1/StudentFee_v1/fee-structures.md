# Fee Structures — Requirements

## What It Does
Defines the complete fee package per class, academic session, and student category. Combines fee groups and heads with specific amounts. Supports effective date ranges, board-type variations, and installments. Each structure has a computed `total_fee_amount` (sum of all head amounts).

Features:
- Per-class, per-session, per-category fee configuration
- Board-type variation (CBSE, ICSE, State, etc.)
- Effective date range for mid-year changes
- Head-level amount configuration with tax inclusion flag
- Auto-computed total fee amount
- Blocks editing if student assignments exist
- Soft-delete with full restore

## Database Fields

**fee_structure_masters**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `academic_session_id` | BIGINT UNSIGNED FK → `glb_academic_sessions` | Required. |
| `class_id` | BIGINT UNSIGNED FK → `sch_classes` | Required. |
| `student_category_id` | BIGINT UNSIGNED FK → `sys_dropdowns` | Required. Student category (General, OBC, SC, ST, etc.). |
| `board_type` | VARCHAR(50) | Nullable. CBSE, ICSE, State Board, etc. |
| `code` | VARCHAR(50) | Required. Auto-generated or manual code. |
| `name` | VARCHAR(200) | Required. Display name. |
| `effective_from` | DATE | Required. When this structure becomes effective. |
| `effective_to` | DATE | Nullable. When this structure expires. Null = no expiry. |
| `total_fee_amount` | DECIMAL(12,2) | Computed. Sum of all fee structure detail amounts. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**fee_structure_details**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `fee_structure_id` | BIGINT UNSIGNED FK → `fee_structure_masters` | Required. CASCADE on delete. |
| `head_id` | BIGINT UNSIGNED FK → `fee_head_masters` | Required. |
| `group_id` | BIGINT UNSIGNED FK → `fee_group_masters` | Nullable. Which group this head belongs to. |
| `amount` | DECIMAL(10,2) | Required. Fee amount for this head in this structure. |
| `is_optional` | BOOLEAN | Default false. Whether this line item can be opted out. |
| `tax_included` | BOOLEAN | Default false. Whether tax is included in the amount. |

## Business Rules

**Total Fee Computation**
- `total_fee_amount` = sum of all `fee_structure_details.amount` where `is_optional = false`
- Optional heads are NOT included in the total (added only if opted during assignment)
- Recalculated on every detail add/remove/update

**Structure Uniqueness**
- One active structure per combination of: `academic_session_id + class_id + student_category_id + board_type`
- Creating a new structure for the same combination deactivates the old one

**Effective Dating**
- `effective_from`: When this structure takes effect for new assignments
- `effective_to`: Null for current structure; set to a date when superseded
- `scopeForSession()`: filters by academic session
- `scopeForClass()`: filters by class
- Helper `isCurrentlyEffective()`: checks if current date is within effective range

**Mid-Year Changes**
- If a structure changes mid-year, existing student assignments retain the old structure unless explicitly updated
- New students join with the latest active structure for their class

**Assignment Protection**
- If any `FeeStudentAssignment` exists for this structure:
  - Structure cannot be updated (blocked in `update()`)
  - Structure cannot be deleted (blocked in `destroy()`)
  - Must be deactivated instead (toggleStatus)

## CRUD Operations

**List Fee Structures**
- Filterable by: academic session, class, student category
- Shows: code, name, class, category, total amount, effective dates, active status
- Warning icon if assignments exist

**Create Fee Structure**
- Select: academic session, class, student category, board type
- Add heads: search/add heads with amount, group assignment, optional toggle
- Auto-compute total as heads are added
- On save: creates structure + all details + default installments

**Show / Edit / Update / Destroy**
- Edit blocked if assignments exist
- Update: full sync of details (delete old, create new from submitted)
- Destroy blocked if assignments exist

**Toggle Active Status / Soft Delete / Restore / Force Delete**

## Permissions

| Operation | Permission Key |
|---|---|
| View fee structures | `tenant.fee-structure-master.viewAny` |
| Create / Update / Delete | `tenant.fee-structure-master.*` |

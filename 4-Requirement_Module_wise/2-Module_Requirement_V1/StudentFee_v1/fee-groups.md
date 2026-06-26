# Fee Groups — Requirements

## What It Does
Groups related fee heads into logical bundles (Academic Core, Annual Charges, Transport, Hostel, Activity & Sports, Exam Package). Groups can be optional or mandatory. Used to simplify fee structure creation by assigning groups instead of individual heads.

Features:
- Optional/mandatory group flag
- Head membership with optional override (is_optional per head in group)
- Default amount per head override within group
- Display order for arrangement
- Soft-delete with full restore/force-delete

## Database Fields

**fee_group_masters**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `code` | VARCHAR(50) | Required. Short code: `ACADEMIC_CORE`, `ANNUAL`, `TRANSPORT`, `HOSTEL`, `ACTIVITY_SPORTS`, `EXAM`. |
| `name` | VARCHAR(200) | Required. Display name. |
| `description` | TEXT | Nullable. |
| `is_mandatory` | BOOLEAN | Default true. Whether group must be included in all structures. |
| `display_order` | INTEGER | Default 0. Sort order. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**fee_group_heads_jnt** (Junction)

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `group_id` | BIGINT UNSIGNED FK → `fee_group_masters` | Required. CASCADE on delete. |
| `head_id` | BIGINT UNSIGNED FK → `fee_head_masters` | Required. CASCADE on delete. |
| `is_optional` | BOOLEAN | Default false. Whether this head is optional within the group. |
| `default_amount` | DECIMAL(10,2) | Nullable. Default amount override for this head. Null = use structure detail amount. |
| `display_order` | INTEGER | Default 0. Sort order within group. |

## Business Rules

**Mandatory Groups**
- If `is_mandatory = true`: the group is automatically included when a fee structure uses this group
- If `is_mandatory = false`: the group can be opted in/out during student assignment
- Scope `mandatory()` filters only mandatory groups

**Head Default Amount Override**
- If `default_amount` is set in the junction: this value is used as the base amount when creating fee structure details
- If `default_amount` is null: the amount comes from the fee structure detail (per-structure pricing)
- Allows group-level pricing defaults while maintaining per-structure flexibility

**Optional Heads within Group**
- A mandatory group can have optional heads (`is_optional = true`)
- These heads can be deselected during student assignment
- An optional group with all mandatory heads is also possible

## CRUD Operations

**List Fee Groups**
- Shows groups with head count, mandatory badge, display order

**Create Fee Group**
- Multi-select heads with: is_optional toggle, default_amount override, display_order
- Heads mapped via FeeGroupHeadsJnt in a DB transaction
- Activity logging

**Show / Edit / Update / Destroy**
- Update: full sync — deletes all existing mappings, re-creates from submitted heads
- Destroy: deactivates + soft deletes

**Toggle Active Status / Soft Delete / Restore / Force Delete**

## Permissions

| Operation | Permission Key |
|---|---|
| View fee groups | `tenant.fee-group-master.viewAny` |
| Create / Update / Delete | `tenant.fee-group-master.*` |

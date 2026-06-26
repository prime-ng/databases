# PTM Batch Slot Templates — Requirements

## What It Does
The time-grid definition for a batch template. These are the individual slot definitions within a batch window - each row represents a specific time slot that can be booked (or a break that cannot be booked).

Most rows are bookable meeting slots. Rows with `is_break = 1` represent mandatory breaks (tea break, lunch, staff meeting) and are never bookable.

These are typically generated programmatically from the batch template's window_start + duration + buffer, but storing them explicitly allows teachers to hand-customize (e.g., add a break in the middle).

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment |
| `batch_template_id` | INT UNSIGNED | FK → `ptm_batches_template`. Required. |
| `ordinal` | TINYINT | Required. Order number (1, 2, 3...) for display and generation. |
| `slot_start_time` | TIME | Required. Wall-clock start time (e.g., 09:00:00). |
| `slot_end_time` | TIME | Required. Wall-clock end time (e.g., 09:10:00). |
| `is_break` | TINYINT(1) | Default: 0. 1 = unbookable break. |
| `break_label` | VARCHAR(50) | Nullable. Name of break (e.g., "Tea break"). Only used when is_break=1. |
| `is_active` | TINYINT(1) | Default: 1. |

## Business Rules

**Slot Timing Validation**
- For non-break rows: `slot_end_time` must be > `slot_start_time`
- For break rows: timing still must be valid (though no booking happens)

**Ordinal Sequence**
- Each batch template has slots in ordinal sequence (1, 2, 3...)
- Used for ordering in UI and generating actual slots

**Break Handling**
- When `is_break = 1`, the slot is BLOCKED and cannot be booked
- Breaks are shown in UI as non-clickable with the break label
- Generated slots will inherit the break status

**Unique Constraints**
- UNIQUE: (`batch_template_id`, `ordinal`) - ensures sequence order
- UNIQUE: (`batch_template_id`, `slot_start_time`) - prevents overlapping times in same batch

**Auto-Generation**
- When a batch template is created/edited, system can auto-generate these rows
- Formula: Start at window_start_time, add (slot_duration + buffer_min), repeat until window_end
- Auto-generate also inserts breaks at configurable intervals (e.g., every 6 slots)

## CRUD Operations

**Auto-Create**
- These rows are usually auto-generated when batch template is created
- No separate create endpoint needed - generated from batch template

**List**
- Route: `GET /ptm/batch-templates/{id}/slots` or view from batch template detail
- Shows all slot definitions in order with timing and break status

**Edit (Manual Override)**
- Route: `GET /ptm/batch-templates/{id}/slots/edit`
- Teachers can manually:
  - Add a break at a specific position
  - Remove a break
  - Adjust timing of specific slots
  - Reorder slots

**Regenerate**
- Button to regenerate all slot definitions from batch template settings
- Warning shown if already assigned to class+sections

## Permissions

| Operation | Permission Key |
|---|---|
| View slot templates | `tenant.ptm.batch-template.view` |
| Update slot templates | `tenant.ptm.batch-template.update` |
# PTM Assignments — Requirements

## What It Does
Applies a batch template to a specific (event, class+section) combination. This is where the actual bookable slots are generated from. The assignment links:

- Which PTM event
- Which class+section (already configured with date/time)
- Which batch template to use
- Which teacher will conduct the meetings
- How slots are allocated (school-allocated or parent-pick)

One class+section can have multiple assignments only when split into sub-batches with different teachers (multi-teacher support).

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment |
| `ptm_event_id` | INT UNSIGNED | FK → `ptm_events`. Required. |
| `event_class_section_id` | INT UNSIGNED | FK → `ptm_event_class_section_jnt`. Required. |
| `batch_template_id` | INT UNSIGNED | FK → `ptm_batches_template`. Required. |
| `primary_teacher_id` | INT UNSIGNED | FK → `sys_users`. Required. Default = class teacher. |
| `allocation_mode` | ENUM | `SCHOOL_ALLOCATED` or `PARENT_PICK`. Default: `SCHOOL_ALLOCATED` |
| `override_buffer_min` | TINYINT | Nullable. Overrides batch template buffer for this assignment. |
| `override_max_participants` | TINYINT | Nullable. Overrides batch template max participants. |
| `is_published` | TINYINT(1) | Default: 0. 0=draft (hidden from parents), 1=visible/bookable. |
| `published_at` | TIMESTAMP | Nullable. When is_published flipped from 0 to 1. |
| `notes` | TEXT | Nullable. Internal notes for staff. |
| `is_active` | TINYINT(1) | Default: 1. |
| `created_by` | INT UNSIGNED | FK → `sys_users`. Nullable. |

## Business Rules

**One Assignment Per Teacher Per Class**
- UNIQUE: (`event_class_section_id`, `primary_teacher_id`)
- Prevents duplicate assignments of same teacher to same class in same event

**Primary Teacher Default**
- Defaults to the class teacher of that class+section
- Admin can override with any other teacher

**Override Fallback**
- If `override_buffer_min` is NULL, uses batch template's `buffer_min`
- If `override_max_participants` is NULL, uses batch template's `max_participants_per_slot`
- If batch template also NULL, uses event's defaults

**Allocation Mode**
- `SCHOOL_ALLOCATED`: School/admins assign slots to students; parents cannot choose
- `PARENT_PICK`: Teachers create slots; parents choose from available slots (first-come, first-served)

**Publication Workflow**
- When `is_published` = 0: slots are generated but hidden from parents
- When `is_published` = 1: slots become visible/bookable, `published_at` set
- Once published, slots are generated in `ptm_slots`

**Ownership**
- Only the assigned primary teacher OR users with `ptm.assignment.manage` permission can modify

## CRUD Operations

**Create**
- Route: `GET /ptm/assignments/create?event_class_section_id=X`
- Select batch template from dropdown
- Select primary teacher (default = class teacher)
- Choose allocation mode
- Submit: `POST /ptm/assignments`

**List**
- Route: `GET /ptm/assignments?event_id=X` or `/ptm/assignments?class_section_id=Y`
- Shows all assignments with teacher, batch, status, published state
- Filter: by event, by class, by teacher, by published status

**View**
- Route: `GET /ptm/assignments/{id}`
- Shows assignment details and list of generated slots

**Edit/Update**
- Route: `GET /ptm/assignments/{id}/edit`
- Can change teacher, batch template, allocation mode, override values
- Cannot change event or class+section (would need new assignment)

**Publish**
- Button to flip `is_published` from 0 to 1
- This triggers slot generation
- Once published, assignment is locked from major edits

**Delete**
- Only allowed if not published and no bookings exist
- Otherwise, mark as inactive

## Permissions

| Operation | Permission Key |
|---|---|
| View assignments | `tenant.ptm.assignment.viewAny` |
| Create assignment | `tenant.ptm.assignment.create` |
| Update assignment | `tenant.ptm.assignment.update` |
| Delete assignment | `tenant.ptm.assignment.delete` |
| Publish assignment | `tenant.ptm.assignment.publish` |
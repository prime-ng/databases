# PTM Blockouts — Requirements

## What It Does
Defines a teacher's global unavailability windows inside a PTM event. These are time periods when the teacher cannot hold meetings due to:

- Lunch break
- Staff meeting
- Personal leave
- Other commitments

Slot generation MUST skip these intervals, and booking MUST reject any attempt to book a slot that overlaps a blockout. This enforces the "No Double-Booking" constraint across all assigned classes for a teacher.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment |
| `ptm_event_id` | INT UNSIGNED | FK → `ptm_events`. Required. Scoped to one event. |
| `teacher_id` | INT UNSIGNED | FK → `sys_users`. Nullable. If NULL, applies to all teachers. |
| `blockout_date` | DATE | Required. The date of unavailability. |
| `start_time` | TIME | Required. Start of blockout (e.g., 12:00:00). |
| `end_time` | TIME | Required. End of blockout (e.g., 13:00:00). |
| `reason` | VARCHAR(100) | Required. Description (e.g., "Lunch", "Staff meeting"). |
| `is_active` | TINYINT(1) | Default: 1. |
| `created_by` | INT UNSIGNED | FK → `sys_users`. Nullable. |

## Business Rules

**Event Scope**
- Blockouts are scoped to a specific event
- Same teacher can have different blockouts in different events

**Teacher-Specific vs Global**
- If `teacher_id` is set: blockout applies only to that specific teacher
- If `teacher_id` is NULL: blockout applies to ALL teachers (e.g., power outage, school-wide holiday)
- Global blockouts prevent any teacher from having slots during that time

**Time Validation**
- `end_time` must be > `start_time`
- Cannot span midnight (obviously)

**Slot Generation Impact**
- When slots are generated for a teacher, system checks all blockouts for that teacher on that date
- Any slot overlapping a blockout is marked as BLOCKED (status = BLOCKED)
- Blocked slots are not visible to parents in PARENT_PICK mode

**Booking Impact**
- When a parent tries to book a slot, system checks if slot overlaps any blockout
- If overlapping a blockout, booking is rejected
- Even for SCHOOL_ALLOCATED mode, blockouts must be respected

**No Double-Booking Enforcement**
- Teacher cannot be scheduled for two different meetings at the same time
- Even if in different classes+sections
- Blockout is one mechanism; UNIQUE constraint on slots is another

**Common Use Cases**
- Individual teacher: "Mrs. Sharma lunch 12-1pm"
- Individual teacher: "Mr. Khan staff meeting 2:30-3pm"
- Global: "School closed for election" (teacher_id = NULL)

## CRUD Operations

**Create**
- Route: `GET /ptm/blockouts/create?event_id=X`
- Select teacher (or leave blank for global)
- Select date within event date range
- Set start and end times
- Enter reason
- Submit: `POST /ptm/blockouts`

**List**
- Route: `GET /ptm/blockouts?event_id=X`
- Shows all blockouts for the event
- Filter: by teacher, by date
- Shows: teacher name (or "All Teachers"), date, time range, reason

**View**
- Route: `GET /ptm/blockouts/{id}`
- Shows blockout details and list of slots that were blocked because of this

**Edit/Update**
- Route: `GET /ptm/blockouts/{id}/edit`
- Can modify date, times, reason
- Cannot change teacher after creation (delete and recreate)

**Delete**
- Route: `DELETE /ptm/blockouts/{id}`
- Removes blockout; affected slots will need to be regenerated
- Warning shown if slots were already generated

## Permissions

| Operation | Permission Key |
|---|---|
| View blockouts | `tenant.ptm.blockout.viewAny` |
| Create blockout | `tenant.ptm.blockout.create` |
| Update blockout | `tenant.ptm.blockout.update` |
| Delete blockout | `tenant.ptm.blockout.delete` |
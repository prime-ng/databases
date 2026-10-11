# PTM Slots — Requirements

## What It Does
The concrete bookable time slots generated from an assignment. Each row represents an actual meeting opportunity with:

- Absolute date and time (e.g., 2026-05-10 09:00:00 to 09:10:00)
- Capacity (how many can book: 1 for 1-on-1, >1 for group)
- Current booking count
- Status (Available/Booked/Full/Blocked/Completed/Cancelled)
- Associated teacher and room/link

Slots are automatically generated when an assignment is published. They can also be created manually for special cases.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment |
| `assignment_id` | INT UNSIGNED | FK → `ptm_assignments`. Required. |
| `assignment_teacher_id` | INT UNSIGNED | FK → `ptm_assignment_teacher_jnt`. Nullable. Used in multi-teacher case. |
| `batch_slot_template_id` | INT UNSIGNED | FK → `ptm_batch_slot_template`. Nullable. Source template row. |
| `teacher_id` | INT UNSIGNED | FK → `sys_users`. Required. Denormalized for fast conflict checks. |
| `slot_start` | DATETIME | Required. Absolute start time (e.g., 2026-05-10 09:00:00). |
| `slot_end` | DATETIME | Required. Absolute end time (e.g., 2026-05-10 09:10:00). |
| `capacity` | TINYINT | Default: 1. Max bookings allowed. |
| `booked_count` | TINYINT | Default: 0. Current confirmed bookings. |
| `status` | ENUM | `AVAILABLE`, `BOOKED`, `FULL`, `BLOCKED`, `COMPLETED`, `CANCELLED` |
| `is_break` | TINYINT(1) | Default: 0. Mirrors break status from template. |
| `room_id` | INT UNSIGNED | FK → `sch_rooms`. Nullable. Inherits from assignment/class. |
| `virtual_link` | VARCHAR(500) | Nullable. Per-slot link override. |
| `is_active` | TINYINT(1) | Default: 1. |

## Business Rules

**No Double-Booking (Teacher Level)**
- UNIQUE: (`teacher_id`, `slot_start`)
- Prevents two slots for the same teacher at the same time across different classes
- System must also check slot_end overlap (e.g., 9:00-9:10 and 9:05-9:15 overlap)

**Status Transitions**
- AVAILABLE: Open for booking, booked_count < capacity
- BOOKED: At least 1 booking but not full
- FULL: booked_count = capacity
- BLOCKED: Cannot be booked (overlaps break or blockout, or is a break slot)
- COMPLETED: Meeting time has passed
- CANCELLED: Cancelled by admin/teacher

**Slot Generation**
- When assignment is published, system iterates through batch_slot_template rows
- For each row, creates a slot at (scheduled_date + slot_start_time)
- If row is a break (is_break=1), status = BLOCKED
- If row overlaps a teacher blockout, status = BLOCKED

**Capacity Logic**
- For 1-on-1 slots: capacity = 1, can have max 1 booking
- For group slots: capacity > 1, can have multiple bookings up to capacity
- When booking added: booked_count increases, status changes from AVAILABLE→BOOKED→FULL

**Room/Link Inheritance**
- If class-section has room, slots inherit that room
- If sub-batch has different room, slots inherit that
- Virtual link similarly inherited but can be overridden per slot

## CRUD Operations

**Auto-Generate**
- Not created manually; generated when assignment is published

**List**
- Route: `GET /ptm/slots?assignment_id=X` or `/ptm/slots?event_id=X`
- Shows all slots for an assignment with timing, capacity, booked count, status
- Filter: by status, by date, by teacher

**View**
- Route: `GET /ptm/slots/{id}`
- Shows slot details and list of bookings for this slot

**Manual Block**
- Admin can manually block a slot (set status = BLOCKED)
- Useful for handling unforeseen circumstances

**Cancel Slot**
- Admin can cancel a slot (status = CANCELLED)
- All existing bookings for this slot are auto-cancelled
- Parents are notified

**View Bookings**
- Shows which students have booked this slot
- For group slots, shows list of all booked students

## Permissions

| Operation | Permission Key |
|---|---|
| View slots | `tenant.ptm.slot.viewAny` |
| View slot details | `tenant.ptm.slot.view` |
| Block/unblock slot | `tenant.ptm.slot.update` |
| Cancel slot | `tenant.ptm.slot.delete` |
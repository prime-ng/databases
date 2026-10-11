# PTM Slot Bookings — Requirements

## What It Does
The actual booking made by a student/parent for a specific slot. Each booking represents:

- Which student (from which class)
- Which slot (which teacher, which time)
- Status of the booking (Confirmed/Cancelled/No-Show/Completed/Rescheduled)
- Parent comments and booking timestamp
- Post-meeting notes from teacher

Bookings are separate from slots because:
- 1-on-1 slots have exactly 1 booking
- Group slots can have multiple bookings (up to capacity)
- Cancellation history is preserved (status change, not row delete)

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment |
| `slot_id` | INT UNSIGNED | FK → `ptm_slots`. Required. |
| `ptm_event_id` | INT UNSIGNED | FK → `ptm_events`. Denormalized for unique key. |
| `teacher_id` | INT UNSIGNED | FK → `sys_users`. Denormalized for unique key. |
| `student_id` | INT UNSIGNED | FK → `std_students`. Required. |
| `booked_by_user_id` | INT UNSIGNED | FK → `sys_users`. Nullable. Parent/staff who placed booking. |
| `parent_comments` | TEXT | Nullable. Parent's message to teacher (e.g., "Discuss math performance"). |
| `status` | ENUM | `CONFIRMED`, `CANCELLED`, `NO_SHOW`, `COMPLETED`, `RESCHEDULED` |
| `booked_at` | TIMESTAMP | When booking was placed. |
| `cancelled_at` | TIMESTAMP | Nullable. When booking was cancelled. |
| `cancel_reason` | VARCHAR(255) | Nullable. Reason for cancellation. |
| `attended` | TINYINT(1) | Nullable. 1=attended, 0=no-show. NULL=not yet happened. |
| `meeting_notes` | TEXT | Nullable. Post-meeting notes captured by teacher. |
| `is_active` | TINYINT(1) | Default: 1. |

## Business Rules

**One Booking Per Student Per Teacher Per Event**
- UNIQUE: (`ptm_event_id`, `student_id`) where status = CONFIRMED
- Student can book one slot with each teacher in an event
- After cancelling, student can book again with same teacher

**One Booking Per Student Per Slot**
- UNIQUE: (`slot_id`, `student_id`) where status = CONFIRMED
- Student cannot book the same slot twice

**Booking Window Validation**
- Booking can only be placed when current time is between event's `booking_window_start` and `booking_window_end`
- Check before allowing any booking action

**Capacity Check**
- Slot must have status AVAILABLE or BOOKED (not FULL)
- Slot's `booked_count` must be < `capacity`
- On successful booking: booked_count increases, status may change to FULL

**Cancellation Lead Time**
- Can only cancel if: current_time <= (slot_start_time - cancellation_lead_time_hrs)
- Example: If slot is at 9:00 AM and lead time is 24 hours, can cancel until 9:00 AM previous day
- If within lead time, cancellation is rejected

**Reschedule vs Cancel**
- If event's `allow_reschedule` = 1: parent can cancel and book another slot
- If `allow_reschedule` = 0: parent can only cancel, cannot book new slot

**Status Workflow**
- CONFIRMED → CANCELLED (when parent cancels or admin cancels)
- CONFIRMED → NO_SHOW (when teacher marks student didn't attend)
- CONFIRMED → COMPLETED (when teacher marks meeting happened)
- CANCELLED → (can create new booking with same teacher if reschedule allowed)

**No-Show Handling**
- Teacher can mark a booking as NO_SHOW after the slot time has passed
- Does not affect slot capacity (that slot is already used)

## CRUD Operations

**Book Slot (Parent-Pick Mode)**
- Route: `POST /ptm/bookings` with slot_id, student_id, optional comments
- Validates: booking window, capacity, one booking per teacher per event
- On success: creates booking, updates slot booked_count and status
- Sends notification if event has `notify_parent_on_book` = 1

**List My Bookings (Parent View)**
- Route: `GET /ptm/my-bookings` or `/ptm/bookings?student_id=X`
- Shows all bookings for the logged-in parent/student
- Shows: event name, teacher, date/time, status

**List Teacher Bookings (Teacher View)**
- Route: `GET /ptm/teacher-bookings?teacher_id=X`
- Shows all bookings for a specific teacher across events
- Filter: by date, by event, by status

**Cancel Booking**
- Route: `POST /ptm/bookings/{id}/cancel` with optional cancel_reason
- Validates cancellation lead time
- On success: updates status to CANCELLED, updates slot booked_count
- Sends notification if event has `notify_parent_on_cancel` = 1

**Mark Attendance (Teacher)**
- Route: `PATCH /ptm/bookings/{id}/attendance` with attended = 1 or 0
- Can mark as attended (COMPLETED) or no-show (NO_SHOW)
- Add meeting notes if needed

**View Booking Details**
- Route: `GET /ptm/bookings/{id}`
- Shows: student details, slot details, booking history, status timeline

## Permissions

| Operation | Permission Key |
|---|---|
| View own bookings | `tenant.ptm.booking.viewAny` (for parents) |
| View teacher bookings | `tenant.ptm.booking.viewTeacher` (for teachers) |
| Create booking | `tenant.ptm.booking.create` |
| Cancel own booking | `tenant.ptm.booking.cancel` (for parents) |
| Cancel any booking | `tenant.ptm.booking.cancelAny` (for admin) |
| Mark attendance | `tenant.ptm.booking.markAttendance` (for teachers) |
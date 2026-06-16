# Slots (Concrete Bookable Time Slots) — Screen Requirements

## What This Screen Does

This screen displays and manages the actual concrete time slots that parents can book. These slots are generated from assignments (which link batch templates to class-sections). Each slot represents a specific date and time when a parent can meet a specific teacher.

Slots are the core entity of the PTM system — they are what parents see, select, and book. Each slot has a status indicating whether it is available, booked, full, blocked, or completed.

---

## When Is This Used?

1. After an assignment is published, slots are auto-generated
2. Admin wants to view all slots for a particular class/teacher
3. Admin needs to manually block a specific slot
4. Admin wants to see slot utilization (how many booked vs available)
5. Teacher wants to see their schedule for the PTM day

---

## Screen Fields

| Field Name | Description | Conditions / Rules |
|---|---|---|
| Assignment | Which assignment this slot belongs to | FK to Assignments. |
| Assignment Teacher (Sub-Batch) | Which sub-batch teacher (if multi-teacher) | Nullable. NULL for single-teacher assignments. |
| Source Template Slot | Which batch slot template entry created this slot | Nullable. NULL if manually created. |
| Teacher | Teacher conducting this meeting | Required. Denormalized for quick conflict checking. |
| Slot Start | Meeting start date and time (absolute) | Required. Format: YYYY-MM-DD HH:MM:SS. |
| Slot End | Meeting end date and time (absolute) | Required. **Must be after Slot Start.** |
| Capacity | Max number of bookings allowed | Required. Default: 1 (1-on-1). |
| Booked Count | Current number of confirmed bookings | Default: 0. Increments on booking, decrements on cancellation. |
| Status | Current availability status | Required. See status types below. |
| Is Break | Whether this is a break slot | Default: No. Mirrors batch template setting. |
| Room | Physical room location | Inherited from class-section or sub-batch. |
| Virtual Link | Online meeting link | Inherited from class-section or sub-batch (for ONLINE mode). |

---

## Slot Status Types

| Status | Meaning | Can Parents Book? | Notes |
|---|---|---|---|
| **AVAILABLE** | Slot is open for booking | Yes | booked_count < capacity |
| **BOOKED** | At least one booking but not full | Yes (capacity remaining) | 0 < booked_count < capacity |
| **FULL** | All bookings taken | No | booked_count = capacity |
| **BLOCKED** | Cannot be booked | No | Overlaps blockout OR is a break slot |
| **COMPLETED** | Meeting time has passed | No | Time is past |
| **CANCELLED** | Slot cancelled by admin/teacher | No | Manually cancelled |

---

## Business Rules & Conditions

### 1. Slot Generation Logic
When an assignment is published:
1. For each non-break slot in the batch slot template:
   - Calculate absolute start: class-section's scheduled_date + template slot_start_time
   - Calculate absolute end: class-section's scheduled_date + template slot_end_time
   - Set teacher from assignment's primary_teacher (or sub-batch teacher)
   - Set capacity from batch template (or assignment override, or event default)
   - Initial status: AVAILABLE
2. For each break slot in the batch slot template:
   - Same calculation but status = BLOCKED and is_break = 1
3. For any slot overlapping with a teacher blockout:
   - Status overridden to BLOCKED

### 2. No Double-Booking (Teacher Level)
- One teacher CANNOT have two slots at the same start time
- Enforced by unique constraint on (teacher_id, slot_start)
- This works across ALL classes — so teacher 45 cannot have a 9:00 AM slot for 10-A AND a 9:00 AM slot for 10-B

### 3. Slot Status Transitions

```
AVAILABLE ──→ BOOKED ──→ FULL
    │                      │
    └── when booking       └── when all capacity used
    increases count
    
AVAILABLE/B/FULL ──→ BLOCKED (manual block or blockout overlap)
BLOCKED ──→ AVAILABLE (when blockout removed)
BOOKED ──→ FULL (when booked_count reaches capacity)
FULL ──→ BOOKED (when a booking is cancelled)
All ──→ COMPLETED (when slot time has passed)
All ──→ CANCELLED (manual cancellation by admin)
```

### 4. Capacity & Booking Count
- When a booking is confirmed: booked_count = booked_count + 1
- When a booking is cancelled: booked_count = booked_count - 1
- If booked_count = 0 → status = AVAILABLE
- If booked_count = capacity → status = FULL
- If 0 < booked_count < capacity → status = BOOKED

### 5. Manual Slot Management
Admin can:
- **Block a slot**: Change status to BLOCKED (slot not available for booking)
- **Cancel a slot**: Change status to CANCELLED (affects existing bookings)
- **Add a slot**: Manually create a new slot (for special cases)

---

## Example View

**Teacher: Mrs. Sharma | Class: 10-A | Date: 10 May 2026**

| Time | Duration | Capacity | Booked | Status | Room |
|---|---|---|---|---|---|
| 09:00-09:10 | 10 min | 1 | 0 | AVAILABLE | Room 101 |
| 09:10-09:20 | 10 min | 1 | 1 | BOOKED | Room 101 |
| 09:20-09:30 | 10 min | 1 | 1 | FULL | Room 101 |
| 09:30-09:40 | 10 min | 3 | 2 | BOOKED | Room 101 |
| 09:40-09:50 | Break | — | — | BLOCKED | — |
| 09:50-10:00 | 10 min | 1 | 0 | BLOCKED | — |
| 10:00-10:10 | 10 min | 1 | 0 | AVAILABLE | Room 101 |

---

## CRUD Operations

### List (View Slots)
- View slots by event, class, teacher, or date
- Filters: Status, Teacher, Date Range, Class
- Show slot timing, status, booking count
- Color-coded status indicators

### Block/Unblock (Toggle Slot)
- Click a slot to block it (prevent bookings)
- Click blocked slot to unblock it (make available again)
- **Note**: Cannot block a slot that has confirmed bookings (must cancel bookings first)

### Manual Add (Create Extra Slot)
- For special cases where an extra slot is needed
- Specify: date, time, teacher, capacity, room

### Cancel Slot
- Cancel an entire slot (affects all confirmed bookings)
- All related bookings are marked CANCELLED
- Requires confirmation due to impact on parents

---

## Important Notes

1. Slots are auto-generated when assignment is published — manual creation is only for exceptions
2. Blocked slots are never visible in the parent booking portal
3. A slot's capacity and status determine whether a parent can book it
4. The unique constraint (teacher_id, slot_start) is the primary defense against teacher double-booking
5. Break slots from batch templates are automatically marked as BLOCKED
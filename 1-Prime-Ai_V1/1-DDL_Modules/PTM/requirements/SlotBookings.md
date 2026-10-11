# Slot Bookings — Screen Requirements

## What This Screen Does

This screen handles the actual booking of parent-teacher meeting slots. It includes both the parent-facing booking portal (where parents select and book slots) and the admin/teacher view (where bookings are managed).

A booking represents a confirmed meeting between a parent/student and a teacher at a specific time slot during a PTM event.

---

## When Is This Used?

1. Parent logs in to book a slot with their child's teacher
2. Admin wants to manually allocate a slot to a student (school-allocated mode)
3. Parent wants to cancel a previously booked slot
4. Teacher marks attendance after the meeting (attended/no-show)
5. Admin views all bookings for reporting purposes

---

## Screen Fields (Booking Record)

| Field Name | Description | Conditions / Rules |
|---|---|---|
| Slot | Which slot was booked | FK to ptm_slots. |
| PTM Event | Which event this booking belongs to | Denormalized from slot/assignment. |
| Teacher | Which teacher was booked | Denormalized from slot. |
| Student | Which student the meeting is for | Required. FK to std_students. |
| Booked By | Who placed the booking (parent/staff) | Parent's user ID or admin user ID. |
| Parent Comments | Optional message from parent (e.g., "Want to discuss math performance") | Optional text. |
| Status | Current booking status | CONFIRMED, CANCELLED, NO_SHOW, COMPLETED, RESCHEDULED. Default: CONFIRMED. |
| Booked At | When the booking was made | Auto-set timestamp. |
| Cancelled At | When it was cancelled | Set when status changes to CANCELLED. |
| Cancel Reason | Why it was cancelled | Optional. E.g., "Parent unavailable". |
| Attended | Whether the student attended | Nullable. 1=attended, 0=no-show, NULL=not yet happened. |
| Meeting Notes | Teacher's notes after the meeting | Optional text. |

---

## Booking Status Types

| Status | Meaning | Can Re-Book? | Notes |
|---|---|---|---|
| **CONFIRMED** | Booking is active and confirmed | No | Normal booking state |
| **CANCELLED** | Parent/admin cancelled this booking | Yes | Slot becomes available again |
| **NO_SHOW** | Student didn't show up for meeting | Yes | Marked by teacher after slot time |
| **COMPLETED** | Meeting happened successfully | No | Normal completion |
| **RESCHEDULED** | Parent moved to another slot | Yes | Old slot becomes available |

---

## Business Rules & Conditions

### 1. One Booking Per Student Per Teacher Per Event
- A student can have only ONE CONFIRMED booking per teacher in one event
- If the student cancels, they can book again (since old status is CANCELLED)
- A student CAN book multiple different teachers in the same event

### 2. Booking Window Check
- Booking is only allowed when:
  - Current time >= booking_window_start
  - Current time <= booking_window_end
- Outside this window, the book button is disabled

### 3. Capacity Check
- Before confirming a booking, system checks:
  - slot.booked_count < slot.capacity
  - slot.status is not FULL or BLOCKED
- If capacity is reached, booking is rejected

### 4. Cancellation Rules
- Parent can cancel a booking ONLY if:
  - Current time + cancellation_lead_time_hrs <= slot_start
  - Example: Lead time is 24 hours, slot is at 10 May 2:00 PM
  - Parent must cancel before 9 May 2:00 PM
- After cancellation:
  - Booking status = CANCELLED
  - Cancelled at = current timestamp
  - Slot's booked_count decreases by 1
  - Slot's status recalculates (FULL → BOOKED, BOOKED → AVAILABLE, etc.)

### 5. Reschedule
- If event allows_reschedule = Yes:
  - Parent can cancel existing booking and book a different slot
  - Old slot is marked CANCELLED (or RESCHEDULED)
  - New slot gets a new CONFIRMED booking
- If allow_reschedule = No:
  - Parent can only cancel (cannot book another slot)

### 6. No Double Slot Occupancy
- A student cannot be CONFIRMED in two different slots at the same time
- System checks before booking

### 7. Booking Locking (Prevent Race Conditions)
- When parent clicks "Book Now", system locks the slot row temporarily
- This prevents two parents from booking the LAST available slot simultaneously
- If slot becomes full during processing, booking is rejected

---

## Parent Booking Flow (PARENT_PICK Mode)

### Step-by-Step Process

1. **Login**
   - Parent logs in to their portal
   - They see list of active PTM events

2. **Select Event**
   - Choose which PTM event to book for
   - Only events within booking window are shown

3. **Select Child**
   - Choose which child/student to book for
   - If parent has multiple children in different classes, they choose one

4. **Select Teacher**
   - See list of teachers assigned to the child's class-section
   - Each teacher shows available slot count

5. **View Available Slots**
   - Click a teacher to see their available slots
   - Slots show: time, duration, status (AVAILABLE/BOOKED/FULL)
   - Blocked/full slots are greyed out or hidden

6. **Choose Slot**
   - Click on an available slot
   - Optionally add a comment/message for the teacher

7. **Confirm Booking**
   - Click "Book Now"
   - System validates:
     - Booking window is still open
     - Slot is still available
     - Student doesn't already have a booking with this teacher
   - If all checks pass → booking confirmed
   - If any check fails → error message shown

8. **Confirmation**
   - Booking confirmed message shown
   - Optional SMS/Email notification sent (if event settings enable it)
   - Booking appears in "My Bookings" section

---

## Admin Booking Flow (SCHOOL_ALLOCATED Mode)

1. Admin selects assignment with SCHOOL_ALLOCATED mode
2. Admin sees list of students in the class-section
3. Admin manually assigns each student to a specific slot
4. Admin can also use auto-allocate: system assigns slots to students automatically
5. Bookings are created with status CONFIRMED
6. Parents see their allocated slot (cannot change it)

---

## Cancellation Flow

1. Parent goes to "My Bookings"
2. Clicks "Cancel" on the booking they want to cancel
3. System checks:
   - Is cancellation lead time still valid?
4. If valid:
   - Ask for cancellation reason (optional)
   - Confirm cancellation
   - Booking status = CANCELLED
   - Slot becomes available
   - Notification sent (if enabled)
5. If not valid:
   - Show error: "Cannot cancel within X hours of the meeting"

---

## Teacher Side (Post-Meeting)

After the meeting takes place:
1. Teacher marks attendance: Attended or No-Show
2. Teacher can add meeting notes
3. Booking status updates:
   - If attended → COMPLETED
   - If not attended → NO_SHOW

---

## Reports & Dashboard Views

### For Admin
- Total bookings per event
- Bookings per teacher
- Booking percentage (booked slots / total slots)
- Attendance rate (attended / total completed meetings)
- Cancellation rate

### For Teacher
- Their schedule for the PTM day
- List of students they need to meet
- Ability to mark attendance and add notes
- No-show students list

### For Parent
- Their confirmed bookings
- Upcoming meetings schedule
- Cancellation option (if within lead time)
- Meeting history

---

## Important Notes

1. A student can book multiple teachers in the same event, but only ONE slot per teacher
2. Cancellation lead time is checked at the time of cancellation, not at the time of booking
3. School-allocated mode bypasses parent selection — admin assigns slots directly
4. Race conditions are handled by locking the slot row during booking
5. Notifications (SMS/Email) depend on event-level settings
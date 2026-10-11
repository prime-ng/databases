# Slots (Concrete Bookable Time Slots) — Business Requirements

## What This Screen Does

This screen represents the actual bookable time slots that parents see and interact with. When an assignment is published, the system generates concrete slot records — each slot has a specific date, start time, end time, assigned teacher, room, and capacity. These are the real meeting opportunities that parents can book.

While batch templates define the pattern, slots are the reality. A batch template might say "10-minute slots from 9-11 AM," but a slot is the actual "10 May 2026, 9:00-9:10 AM with Mrs. Sharma in Room 101."

---

## When This Screen Is Used

- After an assignment is published and slots are auto-generated, admin wants to review them
- Admin needs to manually block a specific slot to prevent booking (for example, if a teacher has a personal errand)
- Admin wants to see slot utilization — how many slots are booked, available, or blocked
- A teacher wants to view their complete schedule for the PTM day
- Admin needs to manually create an extra slot for a special case

---

## Slot Status Types and Their Meaning

Every slot has a status that tells everyone what is happening with it.

**Available** means the slot is open for booking. The number of confirmed bookings is less than the slot's capacity. Parents can book this slot.

**Booked** means at least one parent has booked this slot, but there is still capacity remaining. For example, a group slot with capacity 3 might have 1 booking — it is booked but not yet full.

**Full** means the slot has reached its maximum capacity. No more parents can book this slot. For a one-on-one meeting, full means the slot is taken.

**Blocked** means the slot cannot be booked at all. This happens when the slot overlaps with a teacher's blockout time or when it was marked as a break slot in the batch template. Blocked slots are not visible in the parent booking portal.

**Completed** means the meeting time has passed. The slot is in the past and no longer relevant for booking.

**Cancelled** means the slot was manually cancelled by an admin or teacher. All existing bookings under this slot are affected.

---

## Business Rules and Conditions

**No Teacher Double-Booking**
A teacher can never have two different slots starting at the same time. This is the most important rule in the system. It is enforced across all classes — if Mrs. Sharma has a 9:00 AM slot for 10-A, she cannot also have a 9:00 AM slot for 10-B. This prevents scheduling conflicts.

**Slot Generation When Publishing**
When an assignment is published, the system generates one slot for each non-break entry in the batch slot template. For break entries, a blocked slot is created. The date comes from the class section's scheduled date, and the time comes from the batch template's slot timings. Any slot that overlaps with a teacher blockout is also marked as blocked.

**Booking Count Management**
When a parent books a slot, the booked count increases by one. When a booking is cancelled, the count decreases by one. The slot's status is recalculated automatically — if the count reaches capacity, status becomes full. If it drops below capacity, status becomes available or booked.

**Slot Status Lifecycle**
A slot starts as available when generated. As bookings happen, it moves to booked, then full. Time moves it to completed. Admin interventions can change any slot to blocked or cancelled. These transitions are always one-way in some cases — a completed slot cannot go back to available.

**Manual Slot Management**
Admin can manually block an available or partially booked slot if needed. However, a slot with confirmed bookings cannot be blocked — the bookings must be cancelled first. Admin can also manually create an extra slot outside of the normal generation process for special cases.

---

## Workflow Steps

**Viewing Slots**
A filterable list shows slots by event, class, teacher, or date. Each slot displays its time, duration, teacher, room, capacity, booked count, and status. Statuses are color-coded for quick visual identification — green for available, red for full, grey for blocked, etc.

**Blocking a Slot**
Admin clicks a slot and marks it as blocked. The slot becomes unavailable for booking. If parents were viewing this slot in the portal, it would disappear from their view.

**Unblocking a Slot**
Admin can unblock a previously blocked slot, making it available again. This is useful if a blockout was removed or a break was rescheduled.

**Manually Adding a Slot**
For exceptional cases, admin can manually create a slot by specifying the teacher, date, time, duration, capacity, and room. This slot goes through the same lifecycle as auto-generated slots.

**Cancelling a Slot**
Admin can cancel an entire slot, which affects all confirmed bookings under it. Parents are affected, so this action requires strong confirmation. All related bookings are marked as cancelled.

---

## Example View

For Mrs. Sharma's assignment with 10-A on 10 May 2026 using the 9-11 AM batch template:

The system generates 12 slots from 9:00 AM to 11:00 AM. Slots at 9:40-9:50 is marked as a break (blocked). Two slots overlap with Mrs. Sharma's lunch blockout (12-1 PM is not relevant here since the window ends at 11 AM, but if there were a 10:30-10:45 staff meeting, those slots would be blocked).

Out of 12 slots: 1 break slot (blocked), 1 teacher blockout slot (blocked), 10 available slots.

Parents start booking. By the end of day, 7 slots are booked (some full, some with capacity remaining), 3 slots are still available. Admin can see this utilization and decide whether to open more slots or rearrange the schedule.

After 10 May 2026 passes, all slots from this day become completed. Admin can run reports on how many meetings actually happened versus no-shows.

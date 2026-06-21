# Blockouts (Teacher Unavailability) — Screen Requirements

## What This Screen Does

This screen manages teacher unavailability periods during a PTM event. Teachers can mark time blocks when they are not available for meetings — such as lunch breaks, staff meetings, or personal time.

Blockouts are global constraints: they apply across ALL classes that a teacher is assigned to for that event. If a teacher has a lunch blockout from 12-1 PM, no slots can be booked during that time in any class.

---

## When Is This Used?

1. Teacher wants to mark lunch break (e.g., 12:00-1:00 PM) as unavailable
2. School has a staff meeting scheduled (e.g., 2:30-3:30 PM)
3. A teacher has a personal commitment during the PTM day
4. School-wide event (e.g., assembly, power outage) that affects all teachers

---

## Screen Fields

| Field Name | Description | Conditions / Rules |
|---|---|---|
| PTM Event | Which event this blockout belongs to | Required. Scope is within one event. |
| Teacher | Which teacher is unavailable | **Optional**. If left blank, blockout applies to ALL teachers. |
| Blockout Date | On which date the teacher is unavailable | Required. Must fall within event dates. |
| Start Time | When unavailability starts | Required. |
| End Time | When unavailability ends | Required. **Must be after Start Time.** |
| Reason | Why this blockout exists (e.g., "Lunch", "Staff Meeting") | Required. Shown to admin for reference. |

---

## Business Rules & Conditions

### 1. Scope Types

#### Teacher-Specific Blockout
- Applies only to the selected teacher
- Example: Mrs. Sharma's lunch 12-1 PM — only Mrs. Sharma's slots are blocked
- Other teachers can still have slots during this time

#### Global Blockout (No Teacher Selected)
- Applies to ALL teachers in the event
- Example: "School assembly 10-11 AM" — every teacher's slots are blocked
- Used for school-wide events, power outages, holidays

### 2. Slot Generation Impact
- When assignments are published and slots are generated:
  - Any slot that OVERLAPS with a blockout is marked as BLOCKED
  - These slots cannot be booked by parents
  - The slot still exists in the system but is not available for booking

### 3. Overlap Detection
- A slot is blocked if:
  - slot_start < blockout_end AND slot_end > blockout_start
- Partial overlaps also cause blocking (even if only 1 minute overlaps)

### 4. Multiple Blockouts
- A teacher can have multiple blockouts on the same day
- Example: Lunch 12-1 PM + Staff Meeting 3-4 PM
- All overlapping slots are blocked

### 5. Booking Prevention
- Parents cannot book a slot that overlaps with any applicable blockout
- System checks blockouts at the time of booking
- If a blockout is created after bookings exist, existing bookings are NOT automatically cancelled (only future booking prevented)

---

## Example Scenarios

### Scenario 1: Teacher Lunch Break
- **Teacher**: Mrs. Sharma
- **Date**: 10 May 2026
- **Start**: 12:00 PM
- **End**: 1:00 PM
- **Reason**: "Lunch"

**Impact**: Mrs. Sharma's slot at 12:00-12:10 PM is BLOCKED. Parents cannot book it.

### Scenario 2: School-Wide Assembly
- **Teacher**: (All Teachers — left blank)
- **Date**: 10 May 2026
- **Start**: 10:00 AM
- **End**: 10:30 AM
- **Reason**: "Morning Assembly"

**Impact**: EVERY teacher's slots from 10:00-10:30 AM are BLOCKED. No parent can book any teacher during this time.

### Scenario 3: Multiple Blockouts Same Teacher
- 12:00-1:00 PM → Lunch
- 3:00-3:30 PM → Staff Meeting

Both periods are blocked for that teacher.

---

## CRUD Operations

### Create (Add Blockout)
1. Select PTM event
2. Select teacher (or leave blank for all teachers)
3. Pick date, start time, end time
4. Enter reason
5. Submit → blockout created

### List (View Blockouts)
- Show all blockouts for an event
- Filters: By teacher, by date
- Calendar view or list view
- Show affected slots count

### Edit (Modify Blockout)
- Change time, date, reason
- **Note**: Changing time may affect already generated slots — should regenerate affected slot statuses

### Delete (Remove Blockout)
- Remove the blockout
- Previously blocked slots that were only blocked due to this blockout become AVAILABLE
- If bookings were pending for these slots, they can now be booked

---

## Visual Indicators

In the teacher's schedule view:
- Blocked slots should show with a different color (e.g., red/grey)
- Blockout reason should be visible on hover
- Blockout time ranges should be clearly marked in the day timeline

---

## Important Notes

1. Blockouts are event-specific — they do not carry across events
2. A blank teacher field = applies to ALL teachers
3. Blockouts affect slot AVAILABILITY, not slot EXISTENCE
4. Creating a blockout after slots are generated updates existing slot statuses
5. Blockouts do not affect existing confirmed bookings (those remain valid) — only prevent new bookings
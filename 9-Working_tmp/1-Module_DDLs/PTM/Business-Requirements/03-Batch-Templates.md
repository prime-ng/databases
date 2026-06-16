# Batch Templates — Business Requirements

## What This Screen Does

A Batch Template is a reusable time schedule that teachers or admin create once and apply to multiple classes. It defines how the teacher's available time is divided into meeting slots — for example, "9 AM to 11 AM with 10-minute slots" or "2 PM to 4 PM with 15-minute slots and 2-minute breaks."

Think of a batch template as a reusable stamp. You create it once — say "Morning Batch 9-11 AM, 12 students × 10 minutes each" — and then apply it to 10-A, 10-B, and 10-C without recreating it each time.

---

## When This Screen Is Used

- A teacher wants to define their available time block for PTM meetings
- School wants different slot durations for different grade levels — 15 minutes for primary, 10 minutes for secondary
- A class has many students and needs group slots (multiple students meeting the teacher together in one slot)
- Admin wants to reuse the same time schedule across multiple classes and sections

---

## Business Rules and Conditions

**Unique Template Code**
Every batch template in a school must have a unique code. This helps identify templates easily when applying them to assignments. The system should reject duplicate codes.

**Window Time Must Be Valid**
The window start time must always be before the window end time. For example, 9 AM to 11 AM is valid but 11 AM to 9 AM is not. The difference between start and end determines how many slots can fit in this window.

**Automatic Slot Count Calculation**
When the window time, slot duration, and buffer are defined, the system automatically calculates how many slots will fit. For example, a 2-hour window (120 minutes) with 10-minute slots and no buffer means 12 slots will be generated. If buffer is 2 minutes, each slot effectively takes 12 minutes, so only 10 slots will fit.

**Template Reusability**
A single batch template can be used across multiple class sections. For example, the "Morning 9-11 AM" template can be assigned to 10-A, 10-B, and 5-A simultaneously. The teacher does not need to create separate templates for each class.

**Multiple Templates Per Teacher**
One teacher can have multiple batch templates. A teacher can have a "Morning Batch" for early classes and an "Afternoon Batch" for late classes. Each template is independent.

**Fallback to Event Defaults**
If a template does not specify a buffer time or maximum participants per slot, the event-level default values are used automatically. This ensures the system always has a value to work with.

**Protection Against Deletion**
If a batch template is already being used in an active assignment, it cannot be deleted. The admin must first remove or replace the template in all active assignments before deletion.

---

## Workflow Steps

**Creating a Batch Template**
Teacher or admin opens the create form, enters a template code and name, selects the owner teacher, defines the window start and end times, sets slot duration and optional buffer, optionally sets max participants per slot (1 for individual meetings, more for group meetings), and submits. The system automatically calculates and displays the expected total slots.

**Viewing Templates**
A list shows all templates owned by the teacher or accessible to admin. Each template displays its code, time window, slot duration, and total slots. Admin can filter by teacher or search by template name.

**Editing a Template**
Admin can change the window time, duration, buffer, or capacity. If the template is already assigned to classes, changing these values will affect those assignments when slots are regenerated. The system should warn about this impact.

**Deleting a Template**
Admin can soft-delete a template. If it is linked to any active assignment, deletion is blocked until the assignment is handled.

---

## Example Scenarios

**Secondary Class Template**
A teacher creates a template with code BATCH_SEC_10M named "Secondary 10-min slots 9-11 AM." The window is 9 AM to 11 AM, each slot is 10 minutes with no buffer, and maximum 1 participant per slot. This gives 12 one-on-one meeting slots. This template can be applied to all secondary classes.

**Primary Class Template**
Another template with code BATCH_PRIM_15M named "Primary 15-min slots 9-12 PM" has a 3-hour window (9 AM to 12 PM), 15-minute slots with 2-minute buffer, and 1 participant per slot. This yields 10 slots (180 minutes ÷ 17 minutes). Primary grade teachers use this template for longer, more detailed meetings.

**Group Meeting Template**
A third template with code BATCH_GRP_3 allows 3 students per slot. The window is 9 AM to 10 AM, each slot is 20 minutes with no buffer, and maximum 3 participants. This generates 3 slots, each accommodating up to 3 students together — useful for general announcements or group discussions.

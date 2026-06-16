# Assignments — Business Requirements

## What This Screen Does

An Assignment is the bridge that connects everything together. It links a Batch Template to a specific Class Section within a PTM Event and assigns a teacher to conduct those meetings. This screen also defines how slots will be allocated — whether the school assigns slots to students directly, or parents choose their own slots.

Without an assignment, the batch template and class section exist independently but never connect. The assignment is what makes slot generation possible.

---

## When This Screen Is Used

- After adding classes to an event, admin needs to assign a batch template and teacher to each class
- Admin wants 10-A to use parent-pick mode (parents choose slots) while 10-B uses school-allocated mode
- Admin needs to override the default buffer time or capacity specifically for one class
- Admin is ready to publish the assignment so that slots are generated and visible to parents

---

## Business Rules and Conditions

**One Assignment Per Class-Teacher Pair**
Within a single event, a class section can have only one assignment per teacher. If a class needs multiple teachers, the multi-teacher sub-batch feature is used instead of creating multiple assignments.

**Teacher Ownership**
Only the assigned teacher or a school admin can modify an assignment. Other teachers cannot change slots or bookings of an assignment they do not own.

**Two Allocation Modes**
In School-Allocated mode, the admin manually assigns specific slots to specific students. Parents see their allocated slot but cannot change it. This is useful when the school wants complete control over the schedule.

In Parent-Pick mode, all available slots are displayed to parents, who choose their preferred time on a first-come, first-served basis. This gives parents flexibility but requires them to be proactive.

**Override Fallback Chain**
When determining the actual slot duration, buffer time, or capacity, the system follows a priority order. First, it checks if the assignment itself has an override value. If not, it uses the batch template's value. If the template also does not have a value, it falls back to the event-level default. This ensures there is always a value without requiring redundant data entry.

**Publishing and Slot Generation**
An assignment can be in draft mode (unpublished) or published. When published, the system generates actual concrete slot records based on the batch template's slot grid and the class section's scheduled date. Break slots are marked as blocked. Slots that overlap with teacher blockouts are also marked as blocked.

**Unpublishing Warning**
If an assignment has existing bookings and admin tries to unpublish it, the system should warn about the impact on parents who have already booked. Unpublishing should ideally require cancelling or handling those bookings first.

**Protection Against Deletion**
An assignment with active bookings cannot be deleted. Bookings must be cancelled or the assignment must be unpublished first.

---

## Workflow Steps

**Creating an Assignment**
Admin selects the event, class section, and batch template from dropdowns. The primary teacher is auto-suggested (defaults to the class teacher) but can be changed. Admin chooses the allocation mode — school-allocated or parent-pick. Optional overrides for buffer or max participants can be set. The assignment is created in unpublished (draft) state.

**Viewing Assignments**
A list shows all assignments grouped by event, displaying the class, teacher, batch template, allocation mode, publish status, and booking count. Filters help narrow down by class, teacher, or status.

**Publishing an Assignment**
Admin clicks publish. The system validates that everything is configured properly — class has a date and time, batch template has slots, teacher is assigned. If all good, slots are generated and become visible to parents.

**Modifying an Assignment**
Admin can change the teacher, allocation mode, or override values. If the batch template is changed after publishing, existing slots may need regeneration. The system warns if bookings exist.

**Deleting an Assignment**
Soft delete is allowed only if no active bookings exist. If bookings exist, admin must cancel them first.

---

## Example Scenario

For the Term 1 PTM event, admin creates three assignments:

**Assignment 1 — 10-A with Mrs. Sharma:** Uses the "Morning 9-11 AM" batch template, school-allocated mode. Published. Slots are generated, and admin will manually assign each student of 10-A to a specific time.

**Assignment 2 — 10-B with Mr. Verma:** Uses the same "Morning 9-11 AM" template but with parent-pick mode. Published. Parents of 10-B can log in and choose their preferred slot from the available times.

**Assignment 3 — 5-A with Ms. Gupta:** Uses the "Primary 15-min" template, school-allocated mode. Still in draft (unpublished). Parents cannot see any slots yet. Admin will publish it once ready.

Each assignment operates independently. Even though 10-A and 10-B use the same batch template, their slots are separate because they have different dates and teachers.

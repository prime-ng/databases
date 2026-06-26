# Assignment Teachers (Multi-Teacher Sub-Batches) — Business Requirements

## What This Screen Does

This screen handles situations where a single class section is too large for one teacher to handle, or the school wants to divide students into groups with different teachers. For example, 10-A has 60 students. Mrs. Sharma can only meet 30 students in her available time. So the class is split into Group 1 (Roll 1-30) with Mrs. Sharma and Group 2 (Roll 31-60) with Mr. Verma.

Both groups run at the same time using the same batch template window, but in different rooms and with different teachers. Each teacher gets their own set of slots.

For the normal case where one teacher handles the entire class, this screen is not needed. The primary teacher from the assignment is used directly.

---

## When This Screen Is Used

- A class has too many students for one teacher to meet in the available time window
- School wants to divide students by academic performance or roll numbers for specialized attention
- A subject teacher needs to meet only specific students while the class teacher handles the rest
- School wants parallel sessions — half the class in one room, half in another, with different teachers

---

## Business Rules and Conditions

**Parallel Execution at Same Time**
All sub-batches within an assignment share the same batch template and therefore run during the same time window. If the template says 9 AM to 11 AM, all groups run between 9 and 11 AM simultaneously. Each group has its own teacher, room, and meeting link.

**One Teacher Per Sub-Batch**
A teacher can be assigned to only one sub-batch within the same assignment. However, the same teacher can be in different assignments for different classes. For example, Mrs. Sharma can handle Group 1 of 10-A and also be the primary teacher for 5-B.

**Independent Room and Link Allocation**
Each sub-batch can have its own room and virtual meeting link. This is important because groups run in parallel — they cannot share the same physical space or online link. If no room is specified, the parent class section's room is used.

**Student Filtering**
Each sub-batch defines which students belong to it. This can be based on roll number ranges (Roll 1-15) or specific student IDs. Every student in the class must belong to exactly one sub-batch. No student should be left unassigned or assigned to multiple groups.

**Separate Slot Generation Per Teacher**
When the assignment is published, each sub-batch teacher gets their own complete set of slots. Mrs. Sharma gets 12 slots, and Mr. Verma also gets 12 slots. Students only see and book slots from their assigned teacher. A student in Group 1 cannot book a slot with Mr. Verma.

---

## Workflow Steps

**Adding a Sub-Batch**
From an existing assignment, admin clicks "Add Teacher Group." Admin selects a teacher, optionally provides a group label (like "Group 1 - Roll 1-15"), selects a room or provides a virtual link, and defines the student filter. The sub-batch is created.

**Viewing Sub-Batches**
A list shows all teacher groups within an assignment. Each group displays the teacher name, label, room, and number of students assigned. The total capacity across all groups is also shown.

**Modifying a Sub-Batch**
Admin can change the teacher, room, or student filter. However, if bookings already exist under a sub-batch, changing the teacher would affect those bookings. The system should warn about this.

**Removing a Sub-Batch**
When a sub-batch is removed, the students in that group go back to being under the primary teacher's supervision. This is only allowed if there are no active bookings for that sub-batch.

---

## Example Scenario

10-A has 60 students. The batch template allows only 12 slots per teacher (9-11 AM with 10-minute slots). One teacher can meet only 12 students. But 60 students need meetings.

Admin creates two sub-batches:

**Group 1:** Mrs. Sharma, Roll 1-30, Room 101 — 12 slots generated
**Group 2:** Mr. Verma, Roll 31-60, Room 102 — 12 slots generated

Total capacity: 24 students can be booked across both groups. Still, 36 students remain. The school would need to either add more time windows (afternoon batch) or create more sub-batches with additional teachers.

Students with Roll 10 see only Mrs. Sharma's available slots in Room 101. Students with Roll 35 see only Mr. Verma's slots in Room 102. No cross-group booking is allowed.

# Assignment Teachers (Multi-Teacher Sub-Batches) — Screen Requirements

## What This Screen Does

This screen handles scenarios where a single class-section is split into multiple parallel groups, each managed by a different teacher. For example, 10-A has 60 students — split into Group 1 (Roll 1-30) with Mrs. Sharma and Group 2 (Roll 31-60) with Mr. Verma, both running at the same time in different rooms.

For the simple case where one teacher handles the entire class, this screen is not needed — the primary teacher from the assignment is used directly.

---

## When Is This Used?

1. A class has too many students for one teacher to handle in available time
2. School wants to divide a class into ability-based groups with different teachers
3. Class is split by roll numbers (e.g., Roll 1-15 in Room 101, Roll 16-30 in Room 102)
4. A subject teacher joins for specific student groups only

---

## Screen Fields

| Field Name | Description | Conditions / Rules |
|---|---|---|
| Assignment | Which assignment this sub-batch belongs to | Required. FK to Assignments. |
| Teacher | Teacher assigned to this sub-group | Required. **One teacher per sub-batch. A teacher cannot be in two sub-batches of same assignment.** |
| Sub-Batch Label | Group name (e.g., "Group 1 - Roll 1-15") | Optional. Helps identify this group. |
| Room | Physical room for this group | Optional. Can be different from other groups. |
| Virtual Link | Online meeting link for this group | Optional. Can be different from other groups. |
| Student Filter | Which students belong to this group (e.g., roll numbers 1-15 or specific student IDs) | Optional. JSON format. |

---

## Business Rules & Conditions

### 1. Parallel Execution
- All sub-batches within an assignment run at the SAME time
- They use the same batch template window (e.g., 9-11 AM)
- Each group runs independently in its own room/link

### 2. Teacher Uniqueness
- A teacher can be assigned to only ONE sub-batch within the same assignment
- Same teacher CAN be in different assignments (different classes)

### 3. Room Allocation
- Each sub-batch can have its own room
- If rooms are not specified, the parent class-section room is used
- For online mode, each sub-batch can have its own virtual link

### 4. Student Assignment
- Student filter defines which students belong to which group
- Can be based on roll number range or specific student IDs
- Example filters:
  - `{"roll_from": 1, "roll_to": 15}` — Students with roll 1 to 15
  - `{"student_ids": [12, 15, 17, 20]}` — Specific students
- Each student must belong to exactly ONE sub-batch

### 5. Slot Generation with Sub-Batches
- Slots are generated per teacher (each sub-batch teacher gets their own slot set)
- Each group's slots use that group's teacher_id, room_id, and virtual_link
- The unique constraint (teacher_id, slot_start) prevents any teacher from having overlapping slots

---

## Example Scenario

**Assignment**: 10-A with "Morning 9-11 AM" batch (12 slots × 10 min)

| Group | Teacher | Roll Numbers | Room | Slots Generated |
|---|---|---|---|---|
| Group 1 | Mrs. Sharma | Roll 1-15 | Room 101 | 12 slots (9:00-11:00) |
| Group 2 | Mr. Verma | Roll 16-30 | Room 102 | 12 slots (9:00-11:00) |

**Result**: 
- Mrs. Sharma meets students Roll 1-15 in Room 101 from 9-11 AM
- Mr. Verma meets students Roll 16-30 in Room 102 from 9-11 AM
- Total 24 slots across both groups, handling 30 students

**Student View**: 
- Student with Roll 10 sees only Mrs. Sharma's available slots
- Student with Roll 25 sees only Mr. Verma's available slots

---

## CRUD Operations

### Create (Add Sub-Batch)
1. From an existing assignment, click "Add Teacher Group"
2. Select teacher, room, define student filter
3. Submit → sub-batch created
4. When assignment is published, separate slots generate for this sub-batch teacher

### List (View Sub-Batches)
- Show all teacher groups within an assignment
- Display: Teacher, Label, Room, Student Count
- Total capacity across all groups

### Edit (Modify Sub-Batch)
- Change teacher, room, link, or student filter
- **Note**: Changing teacher after bookings exist may affect existing bookings

### Delete (Remove Sub-Batch)
- Remove a sub-batch (students go back to primary teacher)
- Warning if bookings exist under this sub-batch

---

## Simple vs Multi-Teacher: Comparison

| Scenario | Setup | Slots Generated For |
|---|---|---|
| **Simple** (1 teacher) | Only assignment with primary_teacher | Primary teacher only |
| **Multi-Teacher** (split class) | Assignment + Multiple AssignmentTeacher rows | Each teacher gets own slots |

---

## Important Notes

1. Multi-teacher is optional — use only when class needs to be split
2. Each sub-batch gets its own complete set of slots from the batch template
3. Students are filtered to see only their assigned teacher's slots
4. Cross-batch booking is not allowed (a student in Group 1 cannot book Group 2's teacher)
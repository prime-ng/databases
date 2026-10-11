# Assignments — Screen Requirements

## What This Screen Does

This screen links a Batch Template to a specific class-section within a PTM event. It defines which teacher will conduct the meetings, what allocation mode to use (school-allocated or parent-pick), and whether to override any batch template defaults.

An assignment is the bridge between "what slots exist" (batch template) and "who uses them" (class-section + teacher).

---

## When Is This Used?

1. Admin wants to apply the "Morning 9-11 AM" batch to 10-A with Mrs. Sharma as teacher
2. Admin wants class 10-B to use parent-pick mode (parents choose their own slots)
3. Admin needs to override the default buffer time only for a specific class
4. Admin publishes the assignment so slots become visible to parents
5. Admin splits a class into sub-batches with different teachers (see Assignment Teachers screen)

---

## Screen Fields

| Field Name | Description | Conditions / Rules |
|---|---|---|
| PTM Event | The event this assignment belongs to | Required. Selected automatically from context. |
| Event Class Section | Which class+section in the event | Required. Dropdown showing already added classes. |
| Batch Template | Which batch template to apply | Required. Dropdown showing teacher's templates. |
| Primary Teacher | Main teacher for this class-section | Required. Default is the class teacher. Can be changed. |
| Allocation Mode | How slots will be assigned to parents | Required. SCHOOL_ALLOCATED or PARENT_PICK. Default: SCHOOL_ALLOCATED. |
| Override Buffer (Min) | Custom buffer gap for this class only | Optional. If set, overrides batch template's buffer. |
| Override Max Participants | Custom capacity for this class only | Optional. If set, overrides batch template's capacity. |
| Published | Whether slots are visible to parents | Required. Default: No (0). When set to Yes, slots are generated and visible. |
| Notes | Internal staff notes | Optional. Text area. |

---

## Business Rules & Conditions

### 1. Unique Assignment Per Class-Teacher
- One assignment per (class-section, teacher) within an event
- Example: 10-A with Mrs. Sharma — only one row allowed
- If 10-A needs two teachers, use Assignment Teachers (sub-batches)

### 2. Teacher Ownership
- Only the assigned teacher or admin can modify the assignment
- Other teachers cannot change slots or bookings of someone else's assignment

### 3. Allocation Modes

#### SCHOOL_ALLOCATED Mode
- School decides which student gets which slot
- Admin creates bookings directly for each student
- Parents see their allocated slot but cannot change it
- Used when school wants controlled scheduling

#### PARENT_PICK Mode
- Slots are made available for parents to choose
- Parents select their preferred time from available slots
- First-come, first-served basis
- Used when school wants flexibility for parents

### 4. Override Fallback Chain
When determining buffer, capacity, or duration, the system checks in this order:
1. **Assignment Override** — if set here, use this value
2. **Batch Template** — if not overridden, use template value
3. **Event Default** — if batch template also has no value, use event-level default

### 5. Publish / Unpublish
- **Published = No**: Slots are hidden. Parents cannot see or book them.
- **Published = Yes**: Slots are generated and visible. Parents can book (if within booking window).
- Publishing generates actual slot records in ptm_slots based on batch template.
- Unpublishing should warn if there are existing bookings.

### 6. Slot Generation Trigger
When `is_published` changes from 0 to 1:
- System automatically generates concrete slots (ptm_slots) for each batch slot template entry
- Each slot gets a wall-clock date+time based on the class-section's scheduled date
- Break slots are marked as BLOCKED
- Slots overlapping with teacher blockouts are marked as BLOCKED

---

## Example Scenario

**PTM Event**: Term 1 PTM (10-15 May 2026)

| Assignment | Class | Teacher | Batch Template | Mode | Published |
|---|---|---|---|---|---|
| 1 | 10-A | Mrs. Sharma | Morning 9-11 AM (12×10min) | SCHOOL_ALLOCATED | Yes |
| 2 | 10-B | Mr. Verma | Morning 9-11 AM (12×10min) | PARENT_PICK | Yes |
| 3 | 5-A | Ms. Gupta | Primary 15-min (8×15min) | SCHOOL_ALLOCATED | No (Draft) |

**Assignment 1**: School will allocate specific slots to each student of 10-A.
**Assignment 2**: Parents of 10-B can choose their preferred time from available slots.
**Assignment 3**: Still in draft — parents cannot see or book.

---

## CRUD Operations

### Create (New Assignment)
1. Select event → class-section → batch template
2. Select teacher (default: class teacher)
3. Choose allocation mode
4. Optionally override buffer/capacity
5. Submit → assignment created (unpublished by default)

### List (View Assignments)
- Show all assignments for an event
- Display: Class, Teacher, Template, Mode, Published Status, Booking Count
- Filters: By class, teacher, publish status

### Edit (Modify Assignment)
- Change teacher, mode, overrides
- Change batch template (warning if bookings exist)
- Publish/Unpublish toggle

### Delete
- Soft delete
- Cannot delete if bookings exist (must cancel bookings first or unpublish)

---

## Important Notes

1. Publishing generates slots — make sure batch template and class dates are properly configured
2. Changing allocation mode after parents have started booking may cause confusion
3. If override values are set to NULL, system falls back to template/event defaults
4. Multiple assignments for same class-section are allowed only for multi-teacher scenarios
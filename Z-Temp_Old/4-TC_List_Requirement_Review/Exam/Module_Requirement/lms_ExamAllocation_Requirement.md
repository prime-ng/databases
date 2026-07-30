# Exam Allocation Screen

---

## What Does This Screen Do?

The Exam Allocation screen assigns exam papers to students. It answers: "Who is taking which exam, at what time, and in which room?"

Allocations can be done at 4 levels:
- **CLASS** — Give the same paper to ALL students in a class
- **SECTION** — Give the same paper to ALL students in a specific section (e.g., "Class 10 - Section A")
- **EXAM_GROUP** — Give the same paper to a pre-defined group of students
- **STUDENT** — Give a specific paper to ONE specific student

After creating the exam, papers, paper sets, blueprints, and questions, this is the final setup step before the exam can begin.

---

## Real-Life Example

**Scenario:** Exam coordinator Raj needs to set up "Annual Exam 2026 - Mathematics" for Class 10.

**What Raj does:**
1. Goes to Exam Allocation tab
2. Clicks "Add Allocation"
3. Selects paper: "Annual Exam 2026 - Mathematics (Paper Code: MATH-101)"
4. Selects paper set: "Set A"
5. Chooses allocation type: "CLASS" (all students in Class 10 get this)
6. Selects Class: "Class 10"
7. Sets time: 10:00 AM to 12:00 PM
8. Checks "Conducted in School" → selects Room: "Hall 1"
9. Clicks Create

Now all 120 students in Class 10 are allocated to "Mathematics - Set A" on the scheduled date, from 10 AM to 12 PM, in Hall 1.

Later, Raj discovers that Student "Priya" needs a different set (Set B, for special accommodation). He creates a STUDENT-type allocation just for Priya with Set B.

---

## How the List Page Works

When you open the Exam Allocation tab, you see a list of all allocations, newest first, 10 per page.

### Filters Available

| Filter | What It Does |
|--------|-------------|
| **Exam Paper** | Show allocations for a specific paper |
| **Allocation Type** | CLASS, SECTION, EXAM_GROUP, or STUDENT |
| **Class** | Show allocations for a specific class |
| **Section** | Show allocations for a specific section |
| **Exam** | Show allocations for a specific exam (filters through exam paper) |
| **Scheduled Date** | Show allocations on a specific date |
| **Active/Inactive** | Show only active or inactive allocations |
| **Search** | Search by: location, paper code, paper title, set code, set name, class name, class code, student name, student code |

### What Each Row Shows

Each allocation row shows the paper details, who it's allocated to, the schedule, and the room/location.

---

## How to Create an Allocation

### Step 1 — Choose the Exam Paper

Select an exam paper from the dropdown. **Important:** The dropdown ONLY shows exam papers that have NO existing allocations. Once a paper has allocations, it disappears from this dropdown. (If you need to add more allocations for that paper, you use the "Get Exam Papers" AJAX endpoint with the "unallocated only" option turned off.)

### Step 2 — Choose the Paper Set

Select a specific set (e.g., "Set A", "Set B") for this paper.

### Step 3 — Choose the Allocation Type

This determines who gets the paper:

| Type | What You Need to Select | Result |
|------|------------------------|--------|
| **CLASS** | Just a class | Every student in that class gets this paper |
| **SECTION** | A class AND a section (or class_section_junction) | Only students in that specific section get this paper |
| **EXAM_GROUP** | A pre-defined exam group | Only students in that group get this paper |
| **STUDENT** | A specific student | Only that one student gets this paper |

**Two ways to pick SECTION:** You can either select:
- Option 1: Class + Section (the system auto-finds the junction)
- Option 2: Direct class_section_junction (for advanced users)

### Step 4 — Set the Schedule

| Field | Required? | Details |
|-------|-----------|---------|
| **Scheduled Date** | Optional | If left empty, no specific date is set |
| **Start Time** | Required | Format: HH:MM (24-hour) |
| **End Time** | Required | Must be AFTER start time |

### Step 5 — Choose Location

| If | Then |
|----|------|
| **Conducted in School** is checked | Select a Room from the dropdown (required) |
| **Conducted in School** is NOT checked | Enter a Location text (required, max 100 characters) |

### Step 6 — Save

Click "Create Allocation." The system:
1. Checks permission (create)
2. Validates all fields
3. If SECTION type with class_section_junction → auto-resolves the section_id from the junction record
4. Saves to database inside a transaction
5. Logs the activity: "A new exam allocation was created."
6. Shows success message

---

## How Permission Checks Work (Per Action)

The system checks different permissions depending on what you're doing:

| Action | Permission Checked |
|--------|-------------------|
| View list | `tenant.exam-allocation.viewAny` |
| View details | `tenant.exam-allocation.view` |
| Create form + Save | `tenant.exam-allocation.create` |
| Edit form + Update | `tenant.exam-allocation.update` |
| Soft delete | `tenant.exam-allocation.delete` |
| View trash | `tenant.exam-allocation.restore` |
| Restore | `tenant.exam-allocation.restore` |
| Force delete | `tenant.exam-allocation.forceDelete` |
| Toggle active/inactive | `tenant.exam-allocation.update` |

---

## Editing an Allocation

When you click Edit, the system first checks if the allocation is "in use" — meaning, has the student already taken this exam? If YES, editing is BLOCKED with the message: "This allocation has student attempts associated with it. Therefore cannot be edited."

If NOT used, the edit form opens with pre-filled values. On saving, the same checks run again (in case another user changed it between opening the form and saving).

---

## Deleting an Allocation

Same usage check: if students have attempted the paper, deletion is blocked.

When deletion is allowed:
1. The system sets `is_active = 0` (deactivates it)
2. Then soft-deletes it (sets `deleted_at` timestamp)
3. Logs the activity

---

## Restoring from Trash

When restored:
1. Sets `deleted_at = null`
2. Sets `is_active = 1` (reactivates)
3. Logs the activity: "Exam allocation restored."

---

## Toggling Active/Inactive Status

There's a special AJAX endpoint to toggle the `is_active` flag. This is the only action that is NOT blocked by the usage check. Even if students have attempted the paper, you can still toggle active/inactive.

---

## AJAX Endpoints (Dynamic Dropdowns)

The create form uses several AJAX endpoints to load data dynamically:

### 1. Get Paper Sets for Selected Paper
When you select an exam paper, this endpoint loads the available paper sets.
- Filters: Only active sets, ordered by set_code
- Returns: set ID and display name

### 2. Get Sections for Selected Class
When you select a class, this loads the sections.
- How it works: Finds all section IDs from the class-section junction table, then loads section names
- Returns: section ID and name (with code)

### 3. Get Exam Groups for Selected Class (and optional Section/Exam)
When you select a class, this loads student groups.
- Additional filters: section_id (optional), exam_id (optional)
- Returns: group ID and display name

### 4. Get Students for Selected Class/Section
When you select class and section, this loads students.
- How it works: Uses StudentAcademicSession to find current-year students in that class/section
- Returns: student ID, name, and admission code

### 5. Get Exam Papers (with "unallocated only" option)
This endpoint loads exam papers. By default, it can filter to show ONLY papers without existing allocations. This can be turned off to show all papers.
- Returns: paper ID, title (with code), and class info

---

## Validation Rules (What Gets Checked Before Save)

### Basic Field Validation

| Field | Rule | Error Message |
|-------|------|---------------|
| Exam Paper | Required, must exist | "Exam paper is required" |
| Paper Set | Required, must exist | "Paper set is required" |
| Allocation Type | Required, must be CLASS/SECTION/EXAM_GROUP/STUDENT | "Allocation type is required" |
| Class | Required, must exist | "Class is required" |
| Start Time | Required, format HH:MM | "Start time is required" |
| End Time | Required, format HH:MM, must be after start | "End time must be after start time" |
| Location | Required IF not conducted in school | "Location is required when exam is not conducted in school" |
| Room | Required IF conducted in school | "Room is required when exam is conducted in school" |
| Conducted in School | Optional, yes/no | — |

### Type-Specific Validation

Depending on the allocation type, additional fields are required:

| Type | Extra Required Fields |
|------|---------------------|
| **SECTION** | `class_section_jnt_id` — must exist in junction table, must match the selected class_id, must be active |
| **EXAM_GROUP** | `exam_group_id` — must exist in student groups table |
| **STUDENT** | `student_id` — must exist in students table |
| **CLASS** | No extra fields |

### Smart Field Handling (happens before validation)

Before validation runs, the system does these automatic adjustments:

1. **class_section_jnt_id auto-resolution:** If you selected SECTION type AND provided class_id + section_id (instead of a direct junction ID), the system looks up the class-section junction table and auto-fills `class_section_jnt_id` for you.

2. **conducted_in_school:** The system converts the checkbox value to a proper yes/no boolean.

3. **scheduled_date:** If the date field is empty, it's converted to null (no date specified).

### After-Save Auto-Resolution

When saving a SECTION-type allocation, the controller does one more step:
- It finds the class_section_junction record
- Sets the `section_id` field from the junction's section_id

---

## Usage Check Service — What Blocks Editing/Deletion

The `ExamAllocationUsageCheckService` checks one thing: "Does this allocation have any student attempt records?" If yes:

| Operation | Message |
|-----------|---------|
| Edit | "This allocation has student attempts associated with it. Therefore cannot be edited." |
| Update | "This allocation has student attempts associated with it. Therefore cannot be updated." |
| Delete | "This allocation has student attempts associated with it. Therefore cannot be deleted." |
| Restore | "This allocation has student attempts associated with it. Therefore cannot be restored." |
| Force Delete | "This allocation has student attempts associated with it. Therefore cannot be permanently deleted." |

The one exception: **toggleStatus** (active/inactive toggle) works even when the allocation is in use.

---

## Activity Logging

Every action on an allocation is recorded in the activity log:

| Action | Activity Log Entry |
|--------|-------------------|
| Create | "A new exam allocation was created." |
| Update | "Exam allocation updated." (with old/new field diffs) |
| Soft Delete | "Exam allocation trashed." |
| Restore | "Exam allocation restored." |
| Force Delete | "Exam allocation deleted." |
| Status Toggle | "Exam allocation toggled." |

---

## Error Scenarios

| What Happens | What User Sees |
|-------------|----------------|
| No permission to view | 403 Forbidden |
| No permission to create | 403 Forbidden |
| Missing exam paper | "Exam paper is required" |
| End time before start | "End time must be after start time" |
| SECTION type without junction | "Class section junction is required for section allocation" |
| STUDENT type without student | "Student is required for student allocation" |
| Edit blocked by usage | "This allocation has student attempts associated with it. Therefore cannot be edited." |
| Delete blocked by usage | "This allocation has student attempts associated with it. Therefore cannot be deleted." |
| Room required (in school) but not provided | "Room is required when exam is conducted in school" |
| Location required (not in school) but not provided | "Location is required when exam is not conducted in school" |
| Database save failure | "Failed to create allocation. Please try again." (transaction rollback) |
| Guest user | Redirect to login page |

---

## Table Structure

The main table is `lms_exam_allocations`. Each record stores:

| Data | What It Stores |
|------|----------------|
| Which exam paper | FK to lms_exam_papers |
| Which paper set | FK to lms_exam_paper_sets |
| Which allocation type | CLASS, SECTION, EXAM_GROUP, or STUDENT |
| Target class | FK to sch_classes |
| Target section (optional) | FK to sch_sections |
| Class-section junction (for SECTION type) | FK to sch_class_section_jnt |
| Exam group (for GROUP type) | FK to lms_exam_student_groups |
| Student (for STUDENT type) | FK to std_students |
| Scheduled date | Optional date |
| Start time | Time (HH:MM) |
| End time | Time (HH:MM) |
| Conducted in school? | Yes/No |
| Room (if in school) | FK to sch_rooms |
| Location (if not in school) | Free text, max 100 chars |
| Active status | Yes/No |
| Soft delete timestamp | If deleted |

---

## Business Rules Summary

| # | Rule | What It Means |
|---|------|---------------|
| 1 | **4 allocation types** | CLASS (all), SECTION (section), EXAM_GROUP (group), STUDENT (individual) |
| 2 | **Only unallocated papers shown** | Create form dropdown hides papers that already have allocations |
| 3 | **Auto-resolve section_id** | When using SECTION type, section_id is auto-filled from the junction |
| 4 | **Dual way to pick section** | Provide class_id+section_id (auto-resolve) OR direct junction_id |
| 5 | **Location is conditional** | In school → pick room. Not in school → enter location text |
| 6 | **Usage blocks edit/delete** | If student attempted, edit and delete are blocked |
| 7 | **Toggle bypasses usage check** | Active/inactive toggle works even when in use |
| 8 | **scheduled_date is optional** | Can be left empty (null) |
| 9 | **DB transactions** | Create and update wrapped in transactions (rollback on failure) |
| 10 | **Activity logged** | Every CRUD action is recorded |
| 11 | **Soft delete deactivates first** | Sets is_active=0 before soft-deleting |
| 12 | **Search covers 9 fields** | Location, paper code, paper title, set code, set name, class name, class code, student name, student code |

---

## Related Screens

| Screen | Connection |
|--------|-----------|
| **Exam Paper** | Allocations reference exam_paper_id |
| **Paper Set** | Allocations reference paper_set_id |
| **Exam Student Group** | Target for EXAM_GROUP type |
| **Online Assessment** | Teachers check submissions for allocated students |
| **Student Portal** | Students attempt exams based on allocations |

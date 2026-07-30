# Quest Allocation — Business Requirements

## What This Screen Does

The Quest Allocation screen is where teachers decide who gets a Quest, when they can access it, and how results are managed. Think of it like assigning homework: you pick which Quest to deploy, choose the target group (a whole class, a specific section, a custom group, or an individual student), set a due date, and decide when results should be released.

The screen has three sections:
1. **Allocation Target** — Who receives the Quest
2. **Schedule & Deadlines** — When they can access it
3. **Result & Status Configuration** — How results are published

---

## When This Screen Is Used

- **Deploying a Quest to Students** — After questions are added and scopes are defined, the teacher allocates the Quest to start the assessment
- **Creating Remedial Assignments** — A teacher assigns a practice Quest to a specific student who is falling behind
- **Scheduling Assessments** — Setting future publish dates, due dates, and cut-off dates for timed Quests
- **Managing Multiple Allocations** — A Quest can be allocated to different groups with different schedules

---

## Default Data Load

When a teacher opens the Quest Allocation create page, the system pre-loads:

| What Loads | Where From | Notes |
|------------|-----------|-------|
| Active Quests (unallocated) | `Quest::where('is_active', 1)->whereDoesntHave('allocations')` | Only Quests that haven't been allocated yet (filtered by default) |
| Classes | `SchoolClass::where('is_active', 1)` | For CLASS target type |
| Sections | `Section::where('is_active', 1)->orderBy('name')` | For SECTION target type |
| Groups | `EntityGroup::where('is_active', 1)->orderBy('name')` | For GROUP target type |
| Students | `Student::where('is_active', 1)` | For STUDENT target type (formatted with ID) |

---

## Key Fields at a Glance

### Quest Allocation Record (`lms_quest_allocations`)

**Target Information**
- **Quest ID** — Which Quest is being allocated
- **Allocation Type** — Who gets it: `CLASS`, `SECTION`, `GROUP`, or `STUDENT`
- **Target ID** — The ID of the selected class, section, group, or student
- **Target Table Name** — The database table for the target: `sch_classes`, `sch_class_section_jnt`, `sch_entity_groups`, or `std_students` (auto-set by the system)
- **Assigned By** — The teacher who created the allocation

**Schedule**
- **Published At** — When the Quest becomes visible to students. If left empty, it's published immediately on save.
- **Due Date** — The deadline for completing the Quest. Max 2 years in the future.
- **Cut-off Date** — The hard stop after which submissions are blocked. If not provided, defaults to the same as due_date. Must be on or after due_date.

**Result Configuration**
- **Auto Publish Result** — If ON, results are automatically shown to students after submission
- **Result Publish Date** — When results become visible. Only relevant if Auto Publish Result is ON. Must be on or after the due_date.
- **Is Active** — Master toggle to pause/resume the allocation without deleting it

---

## Business Rules and Conditions

### Rule 1: Target Resolution
The allocation type determines how the target ID is resolved:
- **CLASS** — Targets all students in the selected class
- **SECTION** — Targets students in a specific class + section combination. The system first resolves the ClassSection junction ID from the class_id and section_id provided.
- **GROUP** — Targets students in a custom entity group
- **STUDENT** — Targets a single student

### Rule 2: Quest Must Be Active and Unallocated (by Default)
The Quest dropdown shows only active Quests that don't have any existing allocations. An "Unused Quest" toggle (`filter_unallocated`) can be turned OFF to show all active Quests including already-allocated ones.

### Rule 3: Date Constraints
- `published_at` can be in the past, present, or future (no restriction)
- `due_date` cannot be more than 2 years in the future
- `cut_off_date` must be on or after `due_date`, cannot be more than 2 years in the future
- `result_publish_date` must be on or after `due_date`, cannot be more than 2 years in the future; only settable when `is_auto_publish_result` is ON

### Rule 4: Auto Publish Result Logic
- If `is_auto_publish_result` is OFF → `result_publish_date` is forced to null (cannot be set)
- If `is_auto_publish_result` is ON → `result_publish_date` is optional but if set, must be ≥ due_date
- When auto-publish is enabled on an existing allocation, hidden recommendations are published for all students who have already attempted

### Rule 5: Cut-off Date Default
If `cut_off_date` is not provided but `due_date` is, the system automatically sets `cut_off_date` = `due_date`. This means if the teacher only sets a due date, the cut-off is the same day.

### Rule 6: SECTION Target Resolution
When allocation type is SECTION, the teacher selects a Class and a Section separately. The system finds the `ClassSection` junction record that matches both, and stores that junction's ID as `target_id`. The `target_table_name` is set to `sch_class_section_jnt`.

### Rule 7: Modification Lock (Usage Check)
If any student has already started an attempt for this allocation, editing, soft-deleting, restoring, and force-deleting are blocked. The usage check specifically queries `QuizQuestAttempt` records matching the allocation ID.

### Rule 8: Force-Delete Only Blocks If Attempts Exist
Soft-delete and restore block if ANY attempts exist. Force-delete only blocks if attempts exist (using `hasAttempts` check, not `isUsed`). If no attempts exist but allocations are present, force-delete still proceeds.

### Rule 9: Recommendations Publishing
When `is_auto_publish_result` is enabled (or when the `publishRecommendations` endpoint is called), the system finds all student recommendations linked to this Quest+Allocation that are hidden (`is_published = false`) and publishes them. This triggers the `QuizQuestResultPublished` event which powers the recommendation engine.

---

## Workflow Steps

### Creating an Allocation
1. Teacher navigates to Quest Allocation → Create
2. Selects a Quest from the dropdown (default: only unallocated Quests shown)
3. Selects Allocation Type:
   - **CLASS**: Auto-locks to the Quest's class. No further selection needed.
   - **SECTION**: Shows Class dropdown (auto-filled from Quest) and Section dropdown. Teacher picks a section.
   - **GROUP**: Shows Groups dropdown.
   - **STUDENT**: Shows Section filter first, then Student dropdown (students loaded via relationship).
4. Sets Schedule:
   - Published At (optional, defaults to immediate)
   - Due Date (required for timed Quests)
   - Cut-off Date (optional, defaults to due_date)
5. Sets Result Configuration:
   - Auto Publish Result toggle
   - Result Publish Date (appears only if auto-publish is ON)
   - Active toggle (default: ON)
6. Clicks Save
7. System validates via `QuestAllocationRequest`:
   - Quest exists and is active
   - Allocation type is valid
   - Target exists and is active
   - Dates respect constraints
8. Target table name is auto-set
9. If SECTION type, the ClassSection junction is resolved
10. If cut_off_date empty, defaults to due_date
11. If auto-publish OFF, result_publish_date forced to null
12. Allocation is created, activity logged
13. Redirects to Allocation list tab

### Editing an Allocation
1. Teacher clicks Edit on an allocation
2. System checks usage — if attempts exist, editing is blocked
3. Form loads with existing values pre-filled
4. Teacher makes changes and clicks "Update"
5. Same validation as creation applies
6. If auto-publish was just enabled (was OFF, now ON), hidden recommendations are published
7. Changes are tracked in activity log

### Soft-Deleting an Allocation
1. Teacher clicks Delete on an allocation
2. System checks usage — if attempts exist, deletion is blocked
3. If allowed: is_active → false, soft-deletes the record

### Restoring an Allocation
1. Teacher navigates to Trash and clicks Restore
2. System checks for attempts (using hasAttempts, not isUsed)
3. If allowed: restores the record, sets is_active → true

### Force-Deleting an Allocation
1. Teacher navigates to Trash and clicks "Delete Permanently"
2. System checks for attempts
3. If no attempts: force-deletes the allocation, logs activity

### Toggle Active Status (AJAX)
1. Teacher clicks the status toggle on the list page
2. AJAX request sends is_active boolean
3. System updates and logs activity

### Publish Recommendations
1. Teacher clicks "Publish Recommendations" on an allocation
2. System publishes all hidden recommendations for students who have attempted
3. If auto-publish was off, it's turned on automatically

---

## Example Scenario

Mrs. Sharma, a Grade 10 Science teacher, has completed creating her "Physics Challenge" Quest with 20 questions. Now she needs to deploy it.

She opens Quest Allocation:
1. Selects "Physics Challenge" from the Quest dropdown (it's the only unallocated Quest)
2. Selects Allocation Type = SECTION
3. The Class dropdown auto-fills to "10" (from the Quest)
4. She selects Section = "A"
5. Sets Published At = empty (publish immediately)
6. Sets Due Date = next Friday 11:59 PM
7. Leaves Cut-off Date empty (system will set it to same as due date)
8. Turns ON Auto Publish Result
9. Sets Result Publish Date = one day after due date
10. Leaves Active toggle ON
11. Clicks Save
12. System resolves: Class 10 + Section A → ClassSection junction ID 45
13. Sets target_table_name = "sch_class_section_jnt"
14. Creates the allocation

Later, Mrs. Sharma realizes she set the due date too early. She edits the allocation, changes the due date to the following week. No student has attempted yet, so the edit succeeds.

---

## Related Screens

- **Quest Creation** — Where the parent Quest is created
- **Quest Questions** — Where questions are added before allocation
- **Quest Summary** — Where teachers track student progress for each allocation
- **Dashboard** — Where aggregate allocation metrics are displayed
- **Student Portal** — Where students see and attempt allocated Quests

---

## Requirements

**Controller:** `Modules\LmsQuests\Http\Controllers\QuestAllocationController` (746 lines)
**Model:** `Modules\LmsQuests\Models\QuestAllocation` (table: `lms_quest_allocations`, 175 lines) with SoftDeletes
**Requests:** `QuestAllocationRequest` (complex validation with date constraints, target resolution, SECTION handling)
**Policy:** `QuestAllocationPolicy` (18 permissions: viewAny, view, create, update, delete, restore, forceDelete, status, bulkAllocate, publish, unpublish, sendNotification, viewStatistics, export, import, extendDueDate, viewAttempts)
**Route:** Resource route + AJAX routes for getTargetOptions, getQuests, publishRecommendations

Key controller methods:
- `index(Request)` — Lists allocations with filters (quest_id, allocation_type, target_id, is_active, date_range)
- `create()` — Loads create form with quests (unallocated by default), classes, sections, groups, students
- `store(QuestAllocationRequest)` — Creates allocation with target resolution; handles SECTION junction; defaults cut_off_date
- `show($id)` — Detail view with usage check; resolves target polymorphically (CLASS/SECTION/GROUP/STUDENT)
- `edit($id)` — Edit form with usage check; loads target data for pre-filling
- `update(QuestAllocationRequest, $id)` — Updates with usage check; publishes recommendations if auto-publish newly enabled
- `destroy($id)` — Soft-deletes with usage check
- `trashed()` — Lists soft-deleted allocations
- `restore($id)` — Restores with hasAttempts check; sets is_active=true
- `forceDelete($id)` — Permanently deletes with hasAttempts check
- `toggleStatus(Request, $id)` — AJAX toggle of is_active
- `publishRecommendations($id)` — Publishes hidden recommendations; enables auto-publish if off
- `getTargetOptions(Request)` — AJAX: returns target options for a given allocation type
- `getQuests(Request)` — AJAX: returns quests, optionally filtered to unallocated only

Private helpers:
- `getTargetTable($allocationType)` — Returns DB table name for allocation type
- `getTargetLabel($allocationType, $targetId)` — Human-readable label for activity log
- `getTargetData($allocationType, $targetId)` — Target model instance for edit form
- `publishHiddenRecommendations($type, $assessmentId, $allocationId)` — Publishes hidden recommendations

---

## Who Can Access This Screen

- **Teacher** — Can create, view, and manage allocations for their Quests
- **Head of Department** — Full CRUD access for their department
- **Academic Coordinator** — Full CRUD access
- **Principal** — Read-only access

Permission gates (18 total):
- `tenant.quest-allocation.viewAny` — View list
- `tenant.quest-allocation.view` — View details
- `tenant.quest-allocation.create` — Create allocations
- `tenant.quest-allocation.update` — Edit, toggle status
- `tenant.quest-allocation.delete` — Soft-delete
- `tenant.quest-allocation.restore` — Restore
- `tenant.quest-allocation.forceDelete` — Permanently delete
- `tenant.quest-allocation.status` — Toggle is_active
- `tenant.quest-allocation.bulkAllocate` — Bulk allocate
- `tenant.quest-allocation.publish` — Publish allocations
- `tenant.quest-allocation.unpublish` — Unpublish
- `tenant.quest-allocation.sendNotification` — Send notifications
- `tenant.quest-allocation.viewStatistics` — View stats
- `tenant.quest-allocation.export` — Export
- `tenant.quest-allocation.import` — Import
- `tenant.quest-allocation.extendDueDate` — Extend due dates
- `tenant.quest-allocation.viewAttempts` — View student attempts

---

## How This Screen Works — Logic Flow (Non-Technical)

### Target Selection

When the teacher selects "CLASS," the target is simply the Quest's class — no additional selection needed. The system will show this Quest to all students in that class.

When "SECTION" is selected, the teacher needs to pick a specific section (e.g., Section A of Grade 10). The system resolves this by finding the junction record that links the class to the section. This junction ID is stored, not the section ID directly.

When "GROUP" is selected, the teacher picks from custom entity groups (e.g., "Science Club," "Remedial Group").

When "STUDENT" is selected, the teacher first picks a section to filter students, then picks an individual student from the filtered list.

### Schedule Setting

The "Visible From" date controls when the Quest appears on the student portal. If left empty, it's visible immediately upon save.

The "Due Date" is the deadline. The system prevents setting this more than 2 years in the future.

The "Cut-off Date" is the hard stop — after this, the student cannot submit even if they started. If the teacher doesn't set this, the system copies the due date. The cut-off must be on or after the due date.

### Result Publishing

If "Auto Publish Result" is ON, the system automatically reveals results to students after their submission is graded. The teacher can optionally set a specific date for this (which must be after the due date). If a date is set, results are published on that date; if not, they're published immediately upon grading.

If "Auto Publish Result" is OFF, the teacher must manually publish results later from the Summary screen. The result publish date field is hidden because it's not applicable.

When the allocation is still editable (no attempts exist), all three sections are modifiable. Once a student starts an attempt, editing is completely blocked — the teacher can only toggle active/inactive or delete the allocation (which also requires no attempts).

---

## Validate Before Save

### QuestAllocationRequest

**Base Validation Rules:**
1. **quest_id** — required, exists:lms_quests,id; must be active
2. **allocation_type** — required, in: CLASS, SECTION, GROUP, STUDENT
3. **class_id** — nullable, exists:sch_classes,id
4. **target_id** — required, integer, min:1; must exist in the corresponding target table with is_active=1
5. **published_at** — nullable, date
6. **due_date** — nullable, date; max 2 years in future
7. **cut_off_date** — nullable, date; max 2 years in future; after_or_equal:due_date
8. **result_publish_date** — nullable, date; max 2 years in future; after_or_equal:due_date; prohibited_unless:is_auto_publish_result,true
9. **is_auto_publish_result** — boolean
10. **is_active** — boolean

**Target Existence Validation (dynamic):**
- If allocation_type = SECTION: validates target_id exists in `sch_class_section_jnt` where class_id + section_id match
- If allocation_type = STUDENT: validates target_id exists in `std_students` where is_active=1 AND deleted_at IS NULL
- All types: validates the target record is active

**prepareForValidation:**
- Resolves actual target_id for SECTION/GROUP/STUDENT types from their respective input fields (section_target_id, group_target_id, student_target_id)
- Sets class_id from the Quest's class if not provided
- Converts empty strings to null for all date fields
- Casts is_auto_publish_result and is_active to boolean

**validated() override:**
- Ensures boolean fields are properly typed
- Formats all date fields to `Y-m-d H:i:s` for database storage
- Sets null for empty date fields

---

## Error Handling and Validation Messages

| Scenario | Error Message |
|----------|--------------|
| No Quest selected | "Please select a quest." |
| Invalid allocation type | "Invalid allocation type selected." |
| No target selected | "Please select a target." |
| Invalid target (not active) | "The selected {targetType} is invalid or not active." |
| Due date too far | "Due date cannot be more than 2 years in the future." |
| Cut-off before due date | "Cut-off date must be on or after the due date." |
| Result publish before due date | "Result publish date must be on or after the due date." |
| Result date without auto-publish | "Result publish date cannot be set when auto publish result is disabled." |
| Edit blocked by usage | "Cannot edit this allocation because students have already started attempts." |
| Delete blocked by usage | "Cannot delete this allocation because students have already started attempts." |
| Restore blocked by attempts | "Cannot restore this allocation because students have already started attempts." |
| Force-delete blocked by attempts | "Cannot permanently delete this allocation because students have already attempted." |
| SECTION not found | "The selected class and section combination does not exist or is inactive." |
| Inactive Quest | "The selected quest is not active." |

---

## Success Scenarios

- A teacher allocates a Quest to Class 10, Section A with immediate publishing, a due date of next Friday, and auto-publish results ON. The system resolves the ClassSection junction, sets cut_off_date = due_date, and creates the allocation. Students see the Quest on their portal immediately.

- A teacher allocates a Quest to a single student (Student ID: 1234) as a remedial exercise. The student sees the Quest in their personal assignments list.

- A teacher edits an allocation to change the due date from Friday to the following Monday. No student has attempted yet, so the edit succeeds.

---

## Failure Scenarios

- A teacher tries to set the result publish date before the due date. The validation fails with "Result publish date must be on or after the due date."

- A teacher tries to edit an allocation after 15 students have already started the Quest. The usage check blocks with "Cannot edit this allocation because students have already started attempts."

- A teacher tries to delete an allocation that has 5 submitted attempts. The deletion is blocked.

- A teacher tries to set a due date 3 years in the future. The validation fails with "Due date cannot be more than 2 years in the future."

---

---

## Dependencies module and tables

| Module | Tables |
|--------|--------|
| LmsQuests Core | `lms_quest_allocations` (primary; FK → `lms_quests.id`) |
| LmsQuests Parent | `lms_quests` (FK → `lms_quest_allocations.quest_id`; checked for active status) |
| Academic Setup | `sch_classes` (CLASS target), `sch_class_section_jnt` (SECTION target), `sch_sections` |
| Student Management | `std_students` (STUDENT target), `sch_entity_groups` (GROUP target) |
| Student Portal | `sp_quiz_quest_attempts` (FK → `lms_quest_allocations.id`; used for usage check and stats) |
| Student Portal | `sp_quiz_quest_results` (FK → `sp_quiz_quest_attempts.id` via attempt_id; used for publishing recommendations) |
| Recommendations | `std_student_recommendations` (published/unpublished via publishRecommendations) |

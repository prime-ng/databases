# Quiz Allocation — Business Requirements

## What This Screen Does

The Quiz Allocation screen is the distribution engine that assigns published quizzes to specific groups of students. Think of it as the "shipping" step: once a quiz is created and has questions, the teacher decides WHO gets to take it, WHEN they can see it, and WHEN it's due.

Allocations can target:
- **CLASS** — Every student in a class (e.g., all of "Grade 10")
- **SECTION** — Students in a specific section (e.g., "Grade 10-A")
- **GROUP** — A custom group (e.g., "Remedial Batch 2026")
- **STUDENT** — A single student (e.g., for remedial quizzes)

Each allocation includes scheduling controls: publish date (when quiz becomes visible), due date (deadline), and cut-off date (hard stop). Results can be auto-published on a schedule.

---

## When This Screen Is Used

- **After creating and publishing a quiz** — To assign it to students
- **Scheduled quiz distribution** — Coordinators set publish dates for timed assessments
- **Remedial assignments** — Target specific struggling students with extra practice
- **Date adjustments** — When quiz schedules change, existing allocations can be updated
- **Publishing recommendations** — Manually publish hidden system-generated recommendations

## Default Data Load

This screen is the "Quiz Allocation" tab within Quiz Management (`active_tab=quiz_allocation`). It loads a paginated list of existing allocations (10 per page) via `QuizQueryService@quizAllocationsQuery()`.

Each row displays: quiz title, allocation type (CLASS/SECTION/GROUP/STUDENT), target name (human-readable like "Grade 10-A"), assigner name, published_at date, due_date, cut_off_date, auto-publish flag, is_active, and action buttons.

**Filters available:**
- `quiz_id` — Filter by specific quiz
- `allocation_type` — CLASS/SECTION/GROUP/STUDENT
- `target_id` — Specific target
- `is_active` — Active/inactive
- `date_range` — By published_at date range (format "YYYY-MM-DD - YYYY-MM-DD")

---

## Key Fields at a Glance

### Allocation Table (`lms_quiz_allocations`)
| Field | Type | Details |
|-------|------|---------|
| `quiz_id` | FK → `lms_quizzes` | Which quiz is being allocated |
| `allocation_type` | enum | CLASS, SECTION, GROUP, or STUDENT |
| `target_id` | integer | Dynamic FK — ID in the target table |
| `target_table_name` | varchar | Resolved application-side: sch_classes / sch_class_section_jnt / sch_entity_groups / std_students |
| `published_at` | datetime | When quiz becomes visible to students |
| `due_date` | datetime | Deadline for submission |
| `cut_off_date` | datetime | Hard stop (nullable = no hard stop) |
| `is_auto_publish_result` | boolean | Override quiz-level auto_publish for this allocation |
| `result_publish_date` | datetime | When results become visible (nullable) |
| `assigned_by` | FK → `sys_users` | Who created the allocation |
| `is_active` | boolean | Enable/disable |

### Target Resolution (human-readable names)
| Allocation Type | Target Table | Human Readable |
|----------------|--------------|----------------|
| CLASS | `sch_classes` | Class name (e.g., "Grade 10") |
| SECTION | `sch_class_section_jnt` | Class-Section name (e.g., "Grade 10 - A") |
| GROUP | `sch_entity_groups` | Group name (e.g., "Remedial Batch") |
| STUDENT | `std_students` | Student name |

---

## Complete Validation Flow Before Save

This section explains every check the system performs — in plain language — for each operation on Quiz Allocations. Allocations are like "shipping labels" — they decide WHO gets the quiz and WHEN they can take it.

---

### [A] Creating a New Allocation (Save)

When a teacher assigns a quiz to students by clicking Save:

**Step 1 — Permission Check**
Does the user have permission to allocate quizzes?
- If No → Access Denied
- If Yes → Proceed

**Step 2 — Form Validation**
Did the teacher fill in everything correctly?
- `quiz_id`: Must select a quiz that exists
- `allocation_type`: Must be CLASS, SECTION, GROUP, or STUDENT
- `target_id`: Must select the actual target (a class, a section, a group, or a student)
- `class_id`: Required if type is SECTION (needed to find which section)
- `published_at`: Optional date when quiz becomes visible
- `due_date`: Optional deadline, must be after published_at
- `cut_off_date`: Optional hard stop, must be after due_date
If anything wrong → Show validation error

**Step 3 — Resolve Section Target**
If the teacher picked "SECTION" type:
- The teacher selected a class (e.g., "Grade 10") and a section (e.g., "A")
- The system needs to find the actual junction record that represents "Grade 10 - A"
- It replaces the target_id with this junction ID
- If the junction doesn't exist → 404 error (data inconsistency)

**Why this step?** Sections are stored as class-section pairs. The system needs to translate the human-friendly "Grade 10 - A" into the internal ID the database understands.

**Step 4 — Auto-Set the Target Table Name**
The system records WHICH table contains the actual target:
- CLASS → `sch_classes`
- SECTION → `sch_class_section_jnt` 
- GROUP → `sch_entity_groups`
- STUDENT → `std_students`

**Why?** Because allocations can target different entity types. The system stores the target table name so it knows where to look when resolving student lists later.

**Step 5 — Auto-Fill Date Fields**
- `assigned_by`: Set to whoever is logged in (auto-filled, can't change)
- If "Auto Publish Result" is OFF → Clear `result_publish_date` (no date needed)
- If `cut_off_date` is left empty but `due_date` is set → System copies due_date to cut_off_date

**Real Example:**
> Teacher sets: published_at = March 1, due_date = March 10, cut_off_date = (empty)
> System auto-sets: cut_off_date = March 10
> Students who submit after March 10 are blocked (hard stop at cut-off)

**Step 6 — Create + Log + Redirect**
System saves the allocation, logs the action, and redirects to the allocation list.

---

### [B] Opening an Allocation for Editing (Edit Load)

When teacher clicks Edit on an existing allocation:

**Step 1 — Permission Check**
Does user have permission to edit?

**Step 2 — Usage Check (Critical!)**
The system asks: "Have any students already started or submitted attempts for this quiz through this allocation?"
- If YES → **BLOCKED**: *"Cannot edit this allocation because students have already started attempts."*
- **Why?** If students are already taking the quiz, changing due dates or targets would be unfair. The allocation is "locked" once students engage.

**Step 3 — Load the Form**
If no attempts → Load the edit form with current values pre-filled.

---

### [C] Saving Changes to an Allocation (Update)

When teacher clicks Update:

**Step 1 — Usage Check** (same as Edit)
If students have attempts → BLOCKED

**Step 2 — Save Changes**
- Re-resolve SECTION target if needed
- Re-auto-set dates (same logic as Create)
- Detect what changed (old date → new date, etc.)

**Step 3 — Special: Auto-Publish Recommendations**
If the teacher just ENABLED "Auto Publish Result" (it was OFF, now ON):
- System automatically publishes any hidden recommendations linked to this quiz
- **Why?** When auto-publish is turned on, the system assumes the teacher wants results visible immediately, including any recommended study materials for struggling students

**Step 4 — Log + Redirect**
Record changes in activity log, redirect with success.

---

### [D] Soft Deleting an Allocation (Delete)

When teacher clicks Delete:

**Step 1 — Usage Check**
If students have attempts → BLOCKED

**Step 2 — Soft Delete**
- Sets `is_active = false` (allocation is disabled — quiz no longer available to those students)
- Sets `deleted_at` (can be restored)
- What happens to students who already submitted? Their results remain. They just can't access the quiz anymore if they hadn't started.

---

### [E] Permanently Deleting an Allocation (Force Delete)

When coordinator force-deletes from trash:

**Step 1 — Dependency Check**
The system checks: "Are there any student attempts OR results for this allocation?"
- If YES → **BLOCKED**: *"Cannot permanently delete this allocation because students have already started or submitted attempts for this quiz through this allocation."*

**Step 2 — Permanent Deletion**
If no student data → permanently deleted. Cannot be undone.

---

### [F] Restoring a Deleted Allocation (Restore)

When coordinator restores from trash:
- System finds the soft-deleted allocation
- Restores it + sets `is_active = true`
- Students can now see the quiz again (if dates are still valid)

---

### [G] Toggling Active/Inactive (AJAX Toggle)

When coordinator clicks the toggle:
- System checks permission
- Flips `is_active` flag
- No usage check — you can disable even if students have attempts
- **Use case:** Temporarily hide a quiz from students without deleting

---

### [H] Publishing Recommendations (Manual Action)

When teacher clicks "Publish Recommendations" on an allocation:

**Step 1 — Enable Auto-Publish**
If not already enabled, system sets `is_auto_publish_result = true`

**Step 2 — Publish Hidden Recommendations**
- Finds ALL students who attempted this quiz
- For each student, finds any hidden recommendations that were generated based on this quiz
- Makes them visible (published)

**Real Example:**
> Aarav took the "Science Diagnostic" quiz and scored 40%
> The system automatically generated a recommendation: "Practice: Velocity Problems" but kept it hidden
> Teacher clicks "Publish Recommendations" → Aarav can now see "Practice: Velocity Problems" in his recommendations
> Students who scored above 80% may have different recommendations (or none)

---

## AJAX Endpoints

### getTargetOptions(Request) — GET
| Parameter | Required | Valid Values |
|-----------|----------|--------------|
| `allocation_type` | YES | CLASS, SECTION, GROUP, STUDENT |

Returns: `{ success: true, targets: [{id, name}] }`
- CLASS → All active classes
- SECTION → All active sections
- GROUP → All active entity groups
- STUDENT → All active students (with name + student_id display)

### getQuizzes(Request) — GET
| Parameter | Type | Behavior |
|-----------|------|----------|
| `unallocated_only` | boolean | If true → only quizzes with NO allocations |

Returns: `{ success: true, quizzes: [{id, title, auto_publish_result, class_id, class_name}] }`

---

## Validations (QuizAllocationRequest)

| Field | Rules | Notes |
|-------|-------|-------|
| `quiz_id` | required, exists:lms_quizzes,id | — |
| `allocation_type` | required, in:CLASS,SECTION,GROUP,STUDENT | — |
| `target_id` | required | Validated by allocation_type |
| `class_id` | required_if:allocation_type,SECTION | Needed to resolve ClassSection junction |
| `published_at` | nullable, date | When quiz becomes visible |
| `due_date` | nullable, date, after_or_equal:published_at | Deadline |
| `cut_off_date` | nullable, date, after_or_equal:due_date | Hard stop |
| `is_auto_publish_result` | boolean | Override quiz-level setting |
| `result_publish_date` | nullable, date, after_or_equal:cut_off_date | When results visible |
| `is_active` | boolean | — |

---

## Business Rules Summary

| # | Rule | Enforced At | Behavior |
|---|------|-------------|----------|
| 1 | Only PUBLISHED and active quizzes shown in create form | `create()` | `Quiz::where('is_active', '1')->whereDoesntHave('allocations')` |
| 2 | SECTION type resolves class_section_jnt ID | `store()` + `update()` | Replaces target_id with junction ID |
| 3 | target_table_name auto-set from allocation_type | `store()` + `update()` | Match statement sets table name |
| 4 | assigned_by auto-set to current user | `store()` | — |
| 5 | result_publish_date = null if auto-publish off | `store()` + `update()` | — |
| 6 | cut_off_date defaults to due_date if empty | `store()` + `update()` | — |
| 7 | Edit blocked if students have attempts | `edit()` + `update()` | QuizAllocationUsageCheckService |
| 8 | Delete blocked if students have attempts | `destroy()` | Same usage check |
| 9 | Force delete blocked if attempts OR results exist | `forceDelete()` | Direct check on relations |
| 10 | Soft delete sets is_active=false | `destroy()` | Before ->delete() |
| 11 | Restore sets is_active=true | `restore()` | After ->restore() |
| 12 | Publish recommendations auto-publishes on enable | `update()` | When is_auto_publish_result flips from false to true |

---

## Workflow Steps (Non-Technical)

### Creating an Allocation
1. Go to Quiz Management → "Quiz Allocation" tab → Click "Add New Allocation"
2. Select a quiz from the dropdown (only quizzes with questions and status PUBLISHED appear)
3. Select "Allocation Type":
   - **CLASS**: Pick a class → all students in that class get the quiz
   - **SECTION**: Pick a class, then a section → only students in that section
   - **GROUP**: Pick a custom group → group members get the quiz
   - **STUDENT**: Pick an individual student → only that student
4. Set dates:
   - **Published At**: The date/time when students will first see the quiz
   - **Due Date**: The deadline for submission
   - **Cut-Off Date** (optional): Hard stop — no submissions after this. If empty, same as due date.
5. Set result publishing:
   - Check "Auto Publish Result" if results should be visible automatically
   - Set "Result Publish Date" (only if auto-publish is checked)
6. Click Save → Allocation created. Students will see the quiz on the publish date.

### Editing an Allocation
1. Click "Edit" on any allocation row
2. If students have already started attempts → BLOCKED: "Cannot edit this allocation because students have already started attempts."
3. If no attempts → edit form loads with all current values
4. Change dates, target, or settings
5. Click Update → system saves. If auto-publish was just enabled, hidden recommendations are published.

### Deleting an Allocation
1. Click "Delete" on any row
2. If students have already started → BLOCKED with error message
3. If no attempts → soft deleted. Allocation removed, quiz no longer available to those students.

### Publishing Recommendations
1. Click "Publish Recommendations" on any allocation row
2. System publishes any hidden recommendations linked to this quiz for students who attempted
3. This bypasses the usage-check gate — works even after students have submitted

---

## Example Scenarios (Non-Technical)

**SC-001 — Create Class-Wide Allocation (Non-Technical)**
Ravi, the Grade 10 Science teacher, creates "Science Quiz 1" and clicks "Add New Allocation". He selects:
- Quiz: "Science Quiz 1"
- Allocation Type: "CLASS" → Target: "Grade 10"
- Published At: Monday 8:00 AM
- Due Date: Friday 11:59 PM
- Auto Publish Result: Checked → Result Date: Next Monday
He clicks Save. On Monday at 8 AM, ALL Grade 10 students see "Science Quiz 1" in their Student Portal. They must submit by Friday night. Results appear the following Monday.

**SC-002 — Section-Specific Allocation (Non-Technical)**
Ravi only wants Grade 10-A to take the quiz. He selects Allocation Type "SECTION", picks Class "Grade 10", then Section "A". Only students in Grade 10-A see the quiz. Grade 10-B students don't see it.

**SC-003 — Individual Student Remedial (Non-Technical)**
Ravi creates a "Remedial Practice" quiz for a struggling student, "Aarav Sharma". He selects Allocation Type "STUDENT", searches for Aarav, selects him. Only Aarav sees this extra practice quiz.

**SC-004 — Edit Blocked by Student Attempts (Non-Technical)**
Ravi tries to extend the due date for "Science Quiz 1" but 20 students have already submitted. System blocks: "Cannot edit this allocation because students have already started attempts." He cannot change the dates now.

**SC-005 — Force Delete Blocked (Non-Technical)**
Coordinator tries to force-delete an allocation where students have submitted attempts. System blocks: "Cannot permanently delete this allocation because students have already started or submitted attempts."

**SC-006 — Cut-Off Date Auto-Set (Non-Technical)**
Ravi sets published_at = March 1, due_date = March 10, but leaves cut_off_date blank. System automatically sets cut_off_date = March 10 (same as due_date). Students who submit after March 10 are blocked.

**SC-007 — Publish Recommendations (Non-Technical)**
The system generated remedial recommendations for students who scored poorly. The teacher clicks "Publish Recommendations" on the allocation. System finds all hidden StudentRecommendations for this quiz and publishes them. Students can now see their recommended study materials.

---

## Error Messages Reference

| Scenario | Message | HTTP |
|----------|---------|------|
| Edit/Update blocked | "Cannot edit this allocation because students have already started attempts." | Redirect |
| Delete blocked | "Cannot delete this allocation because students have already started attempts." | Redirect |
| Force delete blocked | "Cannot permanently delete this allocation because students have already started or submitted attempts for this quiz through this allocation." | Redirect |
| Store exception | "Failed to allocate quiz. Please try again." | Redirect with input |
| Update exception | "Failed to update quiz allocation. Please try again." | Redirect with input |
| Delete exception | "Failed to delete quiz allocation. Please try again." | Redirect |
| Restore exception | "Failed to restore quiz allocation. Please try again." | Redirect |
| SECTION junction not found | firstOrFail() throws ModelNotFoundException → 404 | Error page |

---

## Requirements

**Controller:** `Modules\LmsQuiz\Http\Controllers\QuizAllocationController`
**Model:** `QuizAllocation` (table: `lms_quiz_allocations`, soft deletes)
**Requests:** `QuizAllocationRequest`
**Policy:** `QuizAllocationPolicy`
**Usage Check:** `QuizAllocationUsageCheckService`

**Controller Methods:**

| Method | Type | Gate | Key Behavior |
|--------|------|------|-------------|
| `index()` | GET | viewAny | List with quiz/allocation_type/target_id/is_active/date_range filters, paginate 10 |
| `show($id)` | GET | view | Allocation + quiz + assigner + usage details + attempt stats + recent attempts |
| `create()` | GET | create | Load form with quizzes (unallocated only), classes, sections, groups, students |
| `store()` | POST | create | Transactional: resolve target, set dates, activity log |
| `edit($id)` | GET | update | Block if used; load form with current values + target data |
| `update()` | PUT | update | Block if used; auto-publish recommendations on enable; change detection |
| `destroy($id)` | DELETE | delete | Block if used; soft delete + deactivate |
| `trashed()` | GET | restore | List onlyTrashed with quiz + assigner |
| `restore($id)` | GET | restore | Restore + reactivate |
| `forceDelete($id)` | DELETE | forceDelete | Block if attempts/results exist; force delete |
| `toggleStatus()` | AJAX POST | update | JSON toggle |
| `publishRecommendations($id)` | GET | update | Publish hidden StudentRecommendations; set auto_publish |
| `getTargetOptions()` | AJAX GET | — | Dynamic targets by allocation_type |
| `getQuizzes()` | AJAX GET | — | Quizzes list with unallocated_only filter |

---

## Dependencies

| Dependency | Type | Details |
|-----------|------|---------|
| `lms_quiz_allocations` | Primary | Allocation records with soft deletes |
| `lms_quizzes` | FK | quiz_id (no DB FK — app-level) |
| `sys_users` | FK | assigned_by |
| `sch_classes` | Dynamic target | allocation_type=CLASS |
| `sch_class_sections` | Dynamic target | allocation_type=SECTION |
| `sch_entity_groups` | Dynamic target | allocation_type=GROUP |
| `std_students` | Dynamic target | allocation_type=STUDENT |
| `lms_quiz_quest_attempts` | Consumer | Blocks edit/delete if attempts exist |
| `lms_quiz_quest_results` | Consumer | Blocks forceDelete if results exist |
| `std_student_academic_sessions` | Reference | Student population counts |
| `sch_entity_group_members` | Reference | GROUP allocation member count |
| `lms_recommendations` (StudentRecommendation) | Consumer | publishRecommendations updates is_published |

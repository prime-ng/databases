# Quest Scopes — Business Requirements

## What This Screen Does

The Quest Scopes screen is where teachers define the "blueprint" or "syllabus coverage plan" for a Quest. Think of it like creating a checklist: you decide exactly how many questions must come from each lesson and topic in the syllabus. For example, "10 multiple-choice questions from the Mechanics lesson, and 10 from the Optics lesson."

The screen has two modes:
1. **Create Mode** — Add new scope rows for a Quest
2. **Edit Mode** — Modify existing scope rows (add, update, delete rows in bulk)

When scopes are defined, the Quest Questions screen later enforces that the teacher's question selection matches these limits exactly.

---

## When This Screen Is Used

- **After Creating a Quest** — Once the Quest master record is set up, the teacher defines the scope blueprint before adding questions
- **When Adjusting Syllabus Coverage** — If the Quest needs more questions from a particular topic, the teacher edits the scopes
- **Before Adding Questions** — Scopes must be defined first (if the Quest requires them) because the question selection validation checks against scopes

---

## Default Data Load

When a teacher opens the Quest Scopes create page, the system pre-loads:

| What Loads | Where From | Notes |
|------------|-----------|-------|
| Active Quests | `Quest::where('is_active', 1)` | Dropdown to select the parent Quest |
| Question Types | `QuestionType::all()` | MCQ, True/False, etc. — optional per scope |
| Lessons | `Lesson::where('is_active', 1)->orderBy('name')` | All active lessons |
| Topics | `Topic::where('is_active', 1)` | All active topics (for topic hierarchy) |
| Topic Level Types | `TopicLevelType::where('is_active', true)` | Defines multi-level topic hierarchy (L1–L4) |

When a Quest is selected, AJAX loads the Quest's `total_questions` and `total_marks` limits, plus the lessons matching the Quest's class and subject.

---

## Key Fields at a Glance

### Quest Scope Record (`lms_quest_scopes`)

**Core Identity**
- **Quest ID** — Which Quest this scope belongs to
- **Lesson ID** — The specific lesson (mandatory for every scope row)
- **Topic ID** — The specific topic within the lesson (optional). If provided, the scope targets questions from that specific topic only. If empty, the scope covers the entire lesson.
- **Question Type ID** — Optional filter to scope by question type (e.g., "MCQ only")

**Quantity**
- **Target Question Count** — Exactly how many questions must come from this lesson/topic/type combination

**Status**
- **Is Active** — A Yes/No flag to enable/disable the scope without deleting it

### Parent Quest Fields (relevant)

- **Total Questions** — The Quest's total question limit. The sum of all scope `target_question_count` values must equal this number exactly.
- **Total Marks** — The Quest's total marks limit. (Not directly used in scopes, but often displayed alongside.)

---

## Business Rules and Conditions

### Rule 1: Exact Sum Match
The sum of `target_question_count` across all active scope rows must exactly equal the Quest's `total_questions`. The "Create Scopes" submit button is disabled on the frontend until this condition is met.

### Rule 2: No Duplicate Scopes
No two scope rows can have the same combination of `quest_id + lesson_id + topic_id`. If topic_id is NULL for both rows, they are also considered duplicates. This is checked both in the current request (before saving) and against existing records in the database.

### Rule 3: Maximum 20 Scopes Per Quest
The system enforces a hard limit of 20 scope rows per Quest. This includes both existing and new rows.

### Rule 4: Lesson Is Mandatory, Topic Is Optional
Every scope row must have a `lesson_id`. The `topic_id` is optional — a scope can cover an entire lesson without narrowing to a specific topic. This was changed from an earlier requirement that required both.

### Rule 5: 4-Level Topic Hierarchy
Topics can have a parent-child relationship up to 4 levels deep (e.g., Unit → Chapter → Section → Sub-section). The scope form shows cascading dropdowns: selecting a Level 1 topic loads Level 2 options, and so on. The topic ID stored is the leaf-level topic selected.

### Rule 6: Bulk Update with Delete Detection
When editing scopes, the system compares the submitted scope IDs against existing scope IDs. Any existing scope whose ID is NOT in the submitted array is automatically force-deleted (removed permanently). This means the edit form acts as a full replacement of the scope set.

### Rule 7: Update Also Updates Quest Total Questions
When scopes are updated, if the sum of `target_question_count` differs from the Quest's current `total_questions`, the Quest's `total_questions` field is automatically updated to match. This means changing scopes can change the Quest's question limit.

### Rule 8: Modification Lock (Usage Check)
If the Quest has active allocations or student attempts, scopes cannot be edited, deleted, restored, or force-deleted. The usage check looks at both `QuestAllocation` and `QuizQuestAttempt` records linked to the Quest.

### Rule 9: Toggle Affects All Scopes for a Quest
The `toggleStatus` method in the controller updates ALL scope rows for a Quest at once (not just a single scope). Turning the toggle OFF deactivates all scopes for that Quest; turning it ON reactivates all.

### Rule 10: Restore Restores All Scopes for a Quest
When restoring, all soft-deleted scopes for the Quest are restored together (grouped by quest_id in the trash view). Individual scope restoration is not supported — it's all or nothing per Quest.

---

## Workflow Steps

### Creating Scopes
1. Teacher navigates to Quest Scopes → Create
2. Selects a Quest from the dropdown
3. System loads the Quest's total questions and marks limits, plus matching lessons
4. Teacher clicks "Add Scope Row" to add rows dynamically
5. For each row, the teacher:
   a. Selects a Lesson from the dropdown
   b. Optionally drills into the 4-level topic hierarchy to select a specific topic
   c. Optionally selects a Question Type
   d. Enters the Target Question Count (number)
   e. Sets Active/Inactive toggle
6. As rows are added, the footer shows: `Sum of Target Questions / Quest Total Questions`
7. The "Create Scopes" button is disabled until `Sum === Quest Total`
8. Teacher clicks "Create Scopes"
9. System validates:
   - Quest exists and is active
   - At least one scope row
   - No duplicate lessons+topics in the request
   - No conflict with existing scopes for this Quest
   - Max 20 scopes not exceeded
10. Each row is saved using `updateOrCreate` (if a matching scope was soft-deleted, it's restored)
11. Redirects to Quest Scope list tab with success message

### Editing Scopes
1. Teacher navigates to the Quest list and clicks the scope count badge or Edit on any scope
2. System loads all scopes for that Quest
3. Checks usage — if the Quest has allocations/attempts, editing is blocked
4. The edit form shows existing scope rows pre-filled
5. Teacher can:
   - Modify any field in any row
   - Add new rows
   - Existing rows that are NOT in the submitted form will be force-deleted
6. Same validation as creation applies
7. After save, any removed scopes are force-deleted
8. Quest's total_questions is auto-updated if the sum changed
9. Redirects to list with success message

### Deleting Scopes (Single)
1. Teacher clicks Delete on a scope row from the list
2. System checks usage — if the Quest has allocations/attempts, deletion is blocked
3. The scope is set to is_active=false and soft-deleted

### Viewing Scope Details
1. Teacher clicks View on a scope from the list
2. Shows grouped data: all scopes for the Quest
3. Displays: total_scopes, total_questions, total_lessons, total_topics
4. Also shows usage check results (if the Quest is used in allocations/attempts)

---

## Example Scenario

Ms. Johnson, a Grade 8 Science teacher, has created a Quest called "Science Mid-Term" with total_questions = 30 and total_marks = 100.

She opens the Quest Scopes screen and:
1. Selects "Science Mid-Term" from the Quest dropdown
2. The system shows: Quest has 30 total questions, 100 total marks
3. She clicks "Add Scope Row" three times to create three rows:
   - Row 1: Lesson = "Cell Biology", Topic = (none), Target = 10
   - Row 2: Lesson = "Human Body", Topic = "Digestive System", Target = 10
   - Row 3: Lesson = "Plant Life", Topic = "Photosynthesis", Type = MCQ, Target = 10
4. The footer shows: 30 / 30 — the Create button is enabled
5. She clicks "Create Scopes"
6. The system saves all three scopes and redirects to the list

Later, Ms. Johnson realizes she needs 15 questions from Cell Biology instead of 10. She edits the scopes, changes Row 1's target to 15. But now the sum is 35, not 30. She changes Row 2's target to 5 to compensate (sum = 15+5+10 = 30 ✓). She saves. The system updates the scopes and also sets the Quest's total_questions to 30 (unchanged in this case).

---

## Related Screens

- **Quest Creation** — Where the parent Quest's total_questions is set
- **Quest Questions** — Where scope limits are enforced during question selection
- **Quest Allocation** — Usage check prevents scope editing if allocated

---

## Requirements

**Controller:** `Modules\LmsQuests\Http\Controllers\QuestScopeController`
**Model:** `Modules\LmsQuests\Models\QuestScope` (table: `lms_quest_scopes`) with SoftDeletes
**Requests:** `QuestScopeRequest` (validates scopes array, duplicate check, max 20 limit)
**Policy:** `QuestScopePolicy` (permissions: `tenant.quest-scope.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status`, `.bulkAdd`, `.import`, `.export`)
**Route:** Resource route `Route::resource('quest-scope', QuestScopeController::class)` under module prefix, plus AJAX routes for topic hierarchy, lessons-by-quest, quest details

Key controller methods:
- `index(Request)` — Lists scopes with filters (quest_id, lesson_id, is_active); paginated
- `create()` — Loads create form with quests, lessons, question types, topic level types
- `store(Request)` — Bulk store with DB transaction; handles multi-row scopes array; uses updateOrCreate; checks for internal duplicates
- `show($id)` — Groups all scopes by Quest ID; displays aggregate stats + usage check
- `edit($id)` — Loads all scopes for a Quest; checks usage; prepares scope data with parent chain for topic hierarchy
- `update(Request, $id)` — Bulk update with DB transaction; detects and force-deletes removed scopes; auto-updates Quest total_questions
- `destroy($id)` — Soft-deletes a scope with usage check; sets is_active=false
- `trashed()` — Lists soft-deleted scopes grouped by quest_id
- `restore($id)` — Restores all scopes for a Quest with usage check
- `forceDelete($id)` — Permanently deletes all scopes for a Quest with usage check
- `toggleStatus(Request, $id)` — AJAX: toggles is_active for ALL scopes of a Quest at once
- `getQuestDetails($id)` — AJAX: returns Quest total_questions, total_marks, and lessons for class+subject
- `getLessonsByQuest(Request)` — AJAX: returns lessons matching the Quest's subject
- `getTopicHierarchy(Request)` — AJAX: returns topics for a lesson, filtered by level and parent_id (4-level cascading)

---

## Who Can Access This Screen

- **Teacher** — Can create and manage scopes for their Quests
- **Head of Department** — Full CRUD access for their department's subjects
- **Academic Coordinator** — Full CRUD access
- **Principal** — Read-only access

All access is gated by `QuestScopePolicy` methods which map to `tenant.quest-scope.*` permissions.

Permission gates: viewAny, view, create, update, delete, restore, forceDelete, status, bulkAdd, import, export

---

## How This Screen Works — Logic Flow (Non-Technical)

### Creating Scopes

The teacher selects a Quest from a dropdown, and the system immediately shows the Quest's total questions and marks limits. Below is an empty table where the teacher can add rows.

Each row lets the teacher pick a lesson (from a dropdown filtered by the Quest's class and subject), optionally drill into topics using 4 cascading dropdowns, optionally pick a question type, and enter a target question count.

As the teacher adds rows, a running total at the bottom of the table shows the sum of all target counts compared to the Quest's limit. The save button stays disabled until the sum exactly matches the limit — this prevents creating a blueprint that doesn't fill the Quest.

When saved, the system checks for duplicate lesson+topic combinations (both within the current form and against existing records) and enforces a maximum of 20 rows. If everything is valid, each row is saved or restored (if it was previously soft-deleted).

### Editing Scopes

Editing works like a full replacement. The system loads all existing scopes for the Quest into the form. The teacher can add new rows, change values in existing rows, or remove rows (they simply won't be submitted). When saved, the system compares the submitted scope IDs against the existing ones — any existing scope not in the submission is permanently deleted. This is intentional: the edit form always represents the complete set of scopes for the Quest.

### Topic Hierarchy

The scope form supports syllabus topics that are organized in a hierarchy of up to 4 levels. For example:
- Level 1: "Physical Sciences" (broad unit)
- Level 2: "Mechanics" (chapter)
- Level 3: "Forces" (section)
- Level 4: "Newton's Laws" (sub-section)

The teacher selects a lesson first, then picks from each level sequentially. The stored topic_id is always the leaf-level selection.

---

## Create Page — Step-by-Step (Non-Technical)

When a teacher opens the Create Scopes page (`/lms-quests/quest-scope/create`), here is exactly what happens and what they see:

### What Loads on the Page

The system prepares the following before showing the page:

| What Loads | What It Is | Why It's Needed |
|-----------|-----------|----------------|
| List of all active Quests | All Quests that are turned ON | Teacher picks which Quest to set scopes for |
| List of all Question Types | MCQ, True/False, Fill in the Blanks, etc. | Optional — teacher can filter a scope to only one question type |
| List of all active Lessons | All lessons in the syllabus | Each scope row needs a lesson |
| List of all active Topics | All topics in the syllabus | For the 4-level topic hierarchy dropdowns |
| Topic Level Types | The hierarchy structure (e.g., Unit, Chapter, Section) | Defines how the 4 cascading dropdowns work |

### What the Teacher Sees on the Page

**Top section — Quest Selection:**
1. A dropdown labeled "Select Quest" with all active Quests
2. Two read-only boxes: "Quest Total Questions" and "Quest Total Marks" (both show 0 until a Quest is selected)

**Middle section — The Scope Table (empty initially):**
- A table with 6 columns: Lesson, Topic Hierarchy, Question Type, Target Qty, Active, and a delete button
- At the bottom of the table: a footer showing "Total Target Questions / Quest Limit: 0 / 0"

**Bottom section — Buttons:**
- "Add Scope Row" button (green) — to add rows one by one
- "Create Scopes" button (blue) — stays disabled until conditions are met
- A red validation message area

### What Happens When the Teacher Interacts

**Step 1 — Teacher selects a Quest:**
- The system sends an AJAX call (background request, no page reload) to `getQuestDetails` with the selected Quest's ID
- The server responds with:
  - The Quest's **Total Questions** limit (e.g., 30)
  - The Quest's **Total Marks** limit (e.g., 100)
  - A list of **Lessons** that match the Quest's class and subject
- The two read-only boxes update to show the actual limits
- The lesson dropdowns in the scope rows now show the correct lessons

**Step 2 — Teacher clicks "Add Scope Row":**
- A new row appears in the table with:
  - Lesson dropdown (shows all lessons for this Quest's class+subject)
  - 4 cascading topic dropdowns (initially disabled, only Level 1 is enabled once a lesson is picked)
  - Question Type dropdown (optional — "Any Type" is default)
  - Target Quantity input (default 0)
  - Active checkbox (checked by default)
  - Remove button (trash icon)

**Step 3 — Teacher picks a Lesson:**
- The system sends an AJAX call to `getTopicHierarchy` with the lesson_id and level=0 (for Level 1 topics)
- Level 1 dropdown becomes enabled and populated with topics
- The remaining 3 levels stay hidden and disabled

**Step 4 — Teacher picks a Level 1 topic:**
- A hidden field stores the selected topic's ID
- The system sends another AJAX call to `getTopicHierarchy` with the lesson_id, level=1, and parent_id (the selected topic)
- Level 2 dropdown appears and gets populated with child topics
- If the teacher selects a Level 2 topic, Level 3 appears, and so on up to Level 4
- The final leaf-level topic ID is what gets saved

**Step 5 — Teacher enters Target Quantity and repeats:**
- Teacher adds more rows as needed
- Each time the target quantity changes, the footer recalculates:
  - Left side: sum of all target quantities
  - Right side: Quest's total questions limit
  - Example: "15 / 30" means 15 targeted so far, need 15 more

**Step 6 — The "Create Scopes" button behavior:**
- The button stays **disabled** (greyed out) as long as:
  - The sum of target quantities does NOT exactly equal the Quest's total questions
  - Example: Quest has 30 total questions, but sum is 25 → button disabled
- The button becomes **enabled** (clickable) only when:
  - Sum exactly equals the Quest's total questions
  - Example: Quest has 30 total questions, sum is 30 → button enabled
- A red validation message appears showing the shortfall or excess

**Step 7 — Teacher clicks "Create Scopes":**
- The form is submitted to the server
- Server checks:
  1. A Quest is selected
  2. At least one scope row exists
  3. No duplicate lesson+topic combinations in the submitted rows
  4. No conflict with existing scopes in the database
  5. Maximum 20 scopes not exceeded
- If all checks pass:
  - Each row is saved to the database (or restored if it was previously soft-deleted)
  - The teacher is redirected to the Scope List tab with a success message: "3 quest scope(s) added successfully!"
- If any check fails:
  - An error message is shown (e.g., "Maximum 20 scopes allowed per quest.")
  - Nothing is saved

---

## Edit Page — Step-by-Step (Non-Technical)

When a teacher clicks Edit on a scope from the list, here is what happens:

### How the Teacher Gets There

1. The teacher sees the Quest List tab with a "Scope" count badge for each Quest (e.g., "3 Scopes")
2. Clicking the badge or an "Edit" button takes them to the Edit Scopes page

### What Happens Before the Page Loads

1. The system looks up all scopes for that Quest using the Quest ID
2. If no scopes are found, it shows an error: "No scopes found for this quest."
3. If the Quest has allocations or student attempts, editing is blocked with: "Cannot edit this quest scopes because it is already used in allocations or attempts."
4. If allowed, the system loads:
   - All existing scope records with their lesson, topic, and question type details
   - The parent Quest's details (total questions, total marks)
   - All active Question Types
   - All lessons matching the Quest's class and subject
   - All Topic Level Types (for the hierarchy)
   - For each existing scope: the full topic parent chain (e.g., Level 1 → Level 2 → Level 3 → Level 4 IDs)

### What the Teacher Sees on the Edit Page

**Top section — Quest Selection (disabled):**
- The Quest dropdown shows the current Quest and is greyed out (cannot change the Quest during edit)
- A hidden input carries the Quest ID to the server
- Two read-only boxes show the Quest's total questions and total marks

**Middle section — The Scope Table (pre-filled):**
- All existing scope rows are loaded into the table
- Each row shows:
  - Lesson dropdown: pre-selected to the existing scope's lesson
  - 4-level topic hierarchy: pre-populated to the existing scope's topic (with all parent levels restored)
  - Question Type dropdown: pre-selected if one was set
  - Target Quantity: shows the existing value
  - Active checkbox: reflects the current active state
  - A hidden field with the scope's database ID (so the system knows which rows already exist)

**Bottom section — Buttons:**
- "Add Scope Row" — to add new rows
- "Update Scopes" — to save changes

### What Happens When the Teacher Edits

**Adding a new row:** Same as Create — a fresh row appears with empty dropdowns

**Modifying an existing row:** The teacher can change the lesson, topic, question type, target quantity, or active status

**Removing a row:** Clicking the delete (trash) button removes the row from the form. The scope is NOT deleted immediately — it's only removed from the form. When the teacher clicks "Update Scopes," the system compares the submitted row IDs against the existing database IDs. Any existing scope whose ID is NOT in the submitted form gets **permanently deleted** (force-deleted). This means:
- If the teacher removes 2 rows and adds 1 new row, the final result is: old saved rows minus the 2 removed, plus the 1 new
- This is a "full replacement" approach — the edit form always represents the complete set of scopes

**Changing target quantities:**
- The footer shows the running total: "Total Target Questions / Quest Limit"
- The "Update Scopes" button is disabled until the sum exactly matches the Quest's total questions
- If the teacher changes scopes and the new sum differs from the Quest's current total_questions, the system **automatically updates the Quest's total_questions** to match. This means editing scopes can change the Quest's question limit

**Blocked from editing:**
- If any student has started or submitted this Quest, the edit is blocked entirely
- The teacher gets redirected back with an error message
- This protects student data from becoming inconsistent

---

## Validate Before Save

### QuestScopeRequest

**Base Validation Rules:**
1. **quest_id** — required, must exist in lms_quests
2. **scopes** — required, must be array with at least 1 element
3. **scopes.*.lesson_id** — required, must exist in slb_lessons
4. **scopes.*.topic_id** — nullable, must exist in slb_topics (if provided)
5. **scopes.*.question_type_id** — nullable, must exist in slb_question_types (if provided)
6. **scopes.*.target_question_count** — nullable, integer, min:0
7. **scopes.*.is_active** — boolean

**After Validation (`withValidator`):**
1. **Duplicate Check:** For each scope row, check if a scope with the same `quest_id + lesson_id + topic_id` already exists in the database (excluding soft-deleted ones). If yes, add error for that row.
2. **Max 20 Check:** Calculate existing scope count + new scope count; if > 20, add error.

**prepareForValidation:**
- `target_question_count` defaults to 0 if not provided
- `is_active` defaults to 1 (true) if not explicitly checked

### Controller-Level Validation (store method)

In addition to the request validation, the controller also:
1. Checks for duplicate scopes within the same request (internal conflict detection)
2. Uses `updateOrCreate` with `withTrashed()` scope to restore soft-deleted records

---

## Error Handling and Validation Messages

| Scenario | Error Message |
|----------|--------------|
| No Quest selected | "Please select a quest." |
| No scope rows | "Please add at least one scope." |
| Duplicate in request | "Duplicate scope detected in your request for Lesson ID: {N} and Topic ID: {N}" |
| Duplicate in database | "This scope already exists for selected lesson and topic (or without topic)." |
| Max 20 exceeded | "Maximum 20 scopes allowed per quest." |
| No valid rows | "No valid scope rows found. Please select at least Lesson." |
| Missing lesson | "Please select a lesson." |
| Edit blocked by usage | "Cannot edit this quest scopes because it is already used in allocations or attempts." |
| Delete blocked by usage | "Cannot delete this scope because the quest has allocations or student attempts." |
| Restore blocked by usage | "Cannot restore this scope because the quest has allocations or student attempts." |
| Force-delete blocked | "Cannot permanently delete this scope because the quest has allocations or student attempts." |
| Invalid target count | "Target must be a number." / "Target cannot be negative." |
| Conflict on update | "Conflict: Another scope already exists for Lesson ID: {N} and Topic ID: {N}" |

---

## Success Scenarios

- A teacher creates 3 scope rows for a Quest with total_questions = 30: Cell Biology (10), Human Body (10), Plant Life (10). The footer shows 30/30. The Create button is enabled. All three are saved successfully.

- A teacher edits scopes to change the target from 10 to 15 for one row. They adjust another row from 10 to 5 to keep the sum at 30. Save succeeds, and the Quest's total_questions remains 30.

- A teacher deletes a scope from a Quest that has no allocations. The scope soft-deletes successfully.

---

## Failure Scenarios

- A teacher tries to create scopes with sum 25 for a Quest with total_questions = 30. The Create button is disabled. The footer shows "25 / 30." The teacher must add another row or increase an existing row's target.

- A teacher tries to add a 21st scope row. The system rejects with "Maximum 20 scopes allowed per quest."

- A teacher tries to add the same lesson+topic combination twice in the same form. The system detects the duplicate within the request and rejects with a specific error message.

- A teacher tries to edit scopes for a Quest that has already been allocated to a class. The usage check blocks with "Cannot edit this quest scopes because it is already used in allocations or attempts."

---

---

## Dependencies module and tables

| Module | Tables |
|--------|--------|
| LmsQuests Core | `lms_quest_scopes` (primary; FK → `lms_quests.id`, `slb_lessons.id`, `slb_topics.id`, `slb_question_types.id`) |
| LmsQuests Parent | `lms_quests` (FK → `lms_quest_scopes.quest_id`; total_questions auto-updated on scope update) |
| Syllabus | `slb_lessons`, `slb_topics`, `slb_question_types`, `slb_topic_level_types` (for 4-level hierarchy) |
| Student Portal | `sp_quiz_quest_attempts` (checked by usage check service) |
| LmsQuests Allocation | `lms_quest_allocations` (checked by usage check service) |

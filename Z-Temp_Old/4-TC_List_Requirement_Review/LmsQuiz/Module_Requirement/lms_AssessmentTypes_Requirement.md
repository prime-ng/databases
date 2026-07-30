# Assessment Types — Business Requirements

## What This Screen Does

The Assessment Types screen manages the different categories of assessments available in the system. Each type represents a specific educational purpose — like a "Practice" quiz, a "Challenge" quiz, a "Diagnostic" test, etc. Think of it as defining the "flavor" of assessment: two quizzes might have the same questions but different assessment types change how they behave (e.g., Practice allows multiple attempts, Challenge allows only one).

Each assessment type is linked to a Question Usage Type (QUIZ, QUEST, ONLINE_EXAM, OFFLINE_EXAM) which determines which module can use it. For example, a type linked to QUIZ appears in the quiz creation dropdown; a type linked to QUEST appears in the quest creation dropdown.

---

## When This Screen Is Used

- **Initial System Setup** — Configuring the LMS for the first time
- **Adding New Assessment Types** — School introduces new quiz categories (e.g., "Remedial", "Enrichment")
- **Mapping Types to Modules** — Configuring which types are available for quizzes vs quests vs exams

## Default Data Load

This screen is the "Assessment Types" tab within Quiz Management (`active_tab=assessment_type`). It loads a paginated list (10 per page) via `QuizQueryService@assessmentTypesQuery()`.

**Filters available:**
- `search` — Searches `code` and `name` fields
- `assessment_usage_type_id` — Filter by question usage type (QUIZ/QUEST/ONLINE_EXAM/OFFLINE_EXAM)
- `is_active` — Filter by active/inactive status

---

## Key Fields at a Glance

### Table: `lms_assessment_types`
| Field | Type | Details |
|-------|------|---------|
| `code` | varchar(20), UNIQUE | Short identifier like `PRACTICE`, `CHALLENGE`, `DIAGNOSTIC` |
| `name` | varchar(100) | Display name like "Practice Assessment" |
| `description` | text | Optional explanation of the type's purpose |
| `assessment_usage_type_id` | FK → `qns_question_usage_type` | Links to QUIZ/QUEST/ONLINE_EXAM/OFFLINE_EXAM |
| `is_active` | boolean | Enable/disable toggle |

---

## Complete Validation Flow Before Save

This section explains every check the system performs — in plain language — for each operation on Assessment Types. Assessment Types are simple data entries that label what "kind" of assessment a quiz is (Practice, Diagnostic, Challenge, etc.).

---

### [A] Creating a New Assessment Type (Save)

When a coordinator fills the form and clicks Save:

**Step 1 — Permission Check**
Does the user have permission to create assessment types?
- If No → Access Denied
- If Yes → Proceed

**Step 2 — Form Validation**
Did the coordinator fill in everything correctly?
- `code`: Required. Max 20 characters. Must be unique — no other assessment type can have this code. Example: "PRACTICE", "CHALLENGE"
- `name`: Required. Max 100 characters. Display name like "Practice Assessment"
- `assessment_usage_type_id`: Required. Which module can use this (QUIZ for quizzes, QUEST for quests, etc.)
- `description`: Optional. Notes about this assessment type
If anything is wrong → Show validation error and stop

**Step 3 — Create + Log**
System saves the assessment type and logs who created it

**Step 4 — Done**
Redirect to assessment types list with success message

---

### [B] Opening an Assessment Type for Editing (Edit Load)

When a coordinator clicks Edit on an existing type:

**Step 1 — Usage Check**
The system asks: "Is any quiz currently using this assessment type?"
- If YES → **BLOCKED**. Coordinator sees: *"This assessment type is used by: Science Quiz, Math Quiz. Therefore cannot be edited."*
- **Why?** If a type is already in use, changing it could affect existing quizzes

**Step 2 — Permission Check + Load**
If not used → load the form with current values

---

### [C] Saving Changes to an Assessment Type (Update)

When coordinator clicks Update on an existing type:

**Step 1 — Usage Check** (same as Edit)
If used → BLOCKED

**Step 2 — Save + Detect Changes**
- System saves the updated fields
- Checks what changed (e.g., name changed from "Practice" to "Practice Assessment")
- Records only meaningful changes in the activity log
- Redirects with success

---

### [D] Soft Deleting an Assessment Type (Delete)

When coordinator clicks Delete:

**Step 1 — Usage Check**
If any quiz uses this type → BLOCKED: *"Therefore cannot be deleted."*

**Step 2 — Soft Delete**
- Sets `is_active = false` (type is disabled — no longer appears in dropdowns)
- Sets `deleted_at` (can be restored)
- Existing quizzes that use this type are NOT affected — they keep their reference

---

### [E] Permanently Deleting (Force Delete)

When coordinator force-deletes from the trash:

**Step 1 — Dependency Check**
The system checks: "Is this type referenced by any Quiz OR Quest?"
- If YES → **BLOCKED**: *"Cannot permanently delete this assessment type as it is used by: Science Quiz, Math Quest. Please remove these dependencies first."*
- Lists dependent items

**Step 2 — Permanent Deletion**
If no dependencies → permanently deletes the record. Cannot be undone.

---

### [F] Restoring a Deleted Type (Restore)

When coordinator restores from trash:
- System finds the soft-deleted type
- Restores it + sets `is_active = true`

---

### [G] Toggling Active/Inactive (AJAX Toggle)

When coordinator clicks the toggle:
- System checks permission
- Flips `is_active` flag
- Returns JSON response
- No usage check — you can disable a type even if quizzes use it

---

## Validation Rules (AssessmentTypeRequest)

| Field | Rules |
|-------|-------|
| `code` | required, string, max:20, unique:lms_assessment_types |
| `name` | required, string, max:100 |
| `description` | nullable, string |
| `assessment_usage_type_id` | required, exists:qns_question_usage_type,id |
| `is_active` | boolean |

---

## Default Seed Data

The system seeds 7 assessment types via `LmsAssessmentTypeSeeder`:

| Code | Name | Usage Type | Used In |
|------|------|------------|---------|
| FORMATIVE | Formative Assessment | QUIZ | Quiz module |
| SUMMATIVE | Summative Assessment | QUEST | Quest module |
| DIAGNOSTIC | Diagnostic Assessment | QUIZ | Quiz module |
| PRACTICE | Practice Assessment | QUIZ | Quiz module |
| LEARNING_PATH | Learning Path | QUEST | Quest module |
| PROJECT_BASED | Project Based Assessment | QUEST | Quest module |
| MASTER_CHALLENGE | Master Challenge | ONLINE_EXAM | Exam module |

And 4 question usage types (QnsQuestionUsageTypeSeeder):

| Code | Name |
|------|------|
| QUIZ | Quiz |
| QUEST | Quest |
| ONLINE_EXAM | Online Exam |
| OFFLINE_EXAM | Offline Exam |

---

## Business Rules Summary

| # | Rule | Enforced At | Behavior |
|---|------|-------------|----------|
| 1 | Unique `code` | DB unique index | Duplicate blocked with validation |
| 2 | Edit blocked if used by quizzes | `edit()` + `update()` via AssessmentTypeUsageCheckService | Redirect with dependency names |
| 3 | Delete blocked if used by quizzes | `destroy()` via AssessmentTypeUsageCheckService | Back with error |
| 4 | Force delete blocked if used by quizzes OR quests | `forceDelete()` | Back with dependency names (first 3 + "and others") |
| 5 | Soft delete sets is_active=false | `destroy()` | Before ->delete() |
| 6 | Restore sets is_active=true | `restore()` | After ->restore() |
| 7 | Change detection on update | `update()` | getChanges() — excludes updated_at |
| 8 | Usage type scopes module availability | Application level | QUIZ usage → LmsQuiz; QUEST usage → LmsQuests |

---

## Workflow Steps (Non-Technical)

### Creating a New Assessment Type
1. Go to Quiz Management → "Assessment Types" tab → Click "Add New"
2. Enter:
   - **Code**: Short ID like `REMEDIAL`
   - **Name**: Display name like "Remedial Assessment"
   - **Usage Type**: Select "QUIZ" (for quizzes) or "QUEST" (for quests)
   - **Description**: Optional note
3. Toggle "Is Active" as needed
4. Click Save → System creates the type. It now appears in quiz/quest creation dropdowns.

### Editing an Assessment Type
1. Click "Edit" on any row
2. If quizzes are already using this type → BLOCKED: "This assessment type is used by: Quiz A, Quiz B. Therefore cannot be edited."
3. If unused → edit form loads. Modify name, description, usage type
4. Code cannot be changed (locked for uniqueness)

### Deleting an Assessment Type
1. Click "Delete" on any row
2. If quizzes use this type → BLOCKED
3. If unused → soft deleted. Type disappears from dropdowns.

---

## Example Scenarios (Non-Technical)

**SC-001 — Create "Remedial" Type (Non-Technical)**
The school wants a new type for extra practice quizzes. Coordinator creates:
- Code: `REMEDIAL`
- Name: "Remedial Assessment"
- Usage Type: QUIZ
Now when teachers create quizzes, they can select "Remedial Assessment" as the quiz type.

**SC-002 — Edit Blocked by Quiz Usage (Non-Technical)**
Coordinator tries to edit the "PRACTICE" type. System finds 12 quizzes using this type. Blocks with: "This assessment type is used by: Science Quiz 1, Math Practice 2, English Test 3... Therefore cannot be edited."

**SC-003 — Force Delete with Dual Module Dependencies**
Coordinator force-deletes "FORMATIVE". System checks: 2 quizzes found (Science Quiz, Math Quiz) AND 3 quests found (History Quest, Geography Quest, Civics Quest). System blocks: "Cannot permanently delete this assessment type as it is used by: Science Quiz, Math Quiz, History Quest and others."

**SC-004 — Toggle Active Status (Non-Technical)**
Coordinator disables "CHALLENGE" type. It no longer appears in quiz creation dropdowns. Existing quizzes with type "CHALLENGE" remain unchanged.

**SC-005 — Update Type Description (Non-Technical)**
Coordinator renames "PRACTICE" to "Practice Assessment" and adds a description. System detects the change and logs it. The update is immediately visible.

---

## Error Messages Reference

| Scenario | Message | HTTP |
|----------|---------|------|
| Duplicate code | "An assessment type with this code already exists." | 422 |
| Edit blocked | "[usage message] Therefore cannot be edited." | Redirect |
| Update blocked | "[usage message] Therefore cannot be updated." | Redirect |
| Delete blocked | "[usage message] Therefore cannot be deleted." | Redirect |
| Force delete blocked | "Cannot permanently delete this assessment type as it is used by: [names]. Please remove these dependencies first." | Redirect |
| Force delete exception | "Failed to delete the assessment type. Please try again." | Redirect |

---

## Requirements

**Controller:** `Modules\LmsQuiz\Http\Controllers\AssessmentTypeController`
**Model:** `AssessmentType` (table: `lms_assessment_types`, soft deletes)
**Requests:** `AssessmentTypeRequest`
**Policy:** `AssessmentTypePolicy`
**Usage Check:** `AssessmentTypeUsageCheckService`

**Controller Methods:**

| Method | Type | Gate | Key Behavior |
|--------|------|------|-------------|
| `index()` | GET | viewAny | List with search/usage_type/is_active filters, paginate 10 |
| `show($id)` | GET | view | Load with usage type + usage details |
| `create()` | GET | create | Load form with usage types |
| `store()` | POST | create | Create + activity log |
| `edit($id)` | GET | update | Block if used; load form |
| `update()` | PUT | update | Block if used; change detection + activity log |
| `destroy($id)` | DELETE | delete | Block if used; soft delete + deactivate |
| `trashed()` | GET | restore | List onlyTrashed |
| `restore($id)` | GET | restore | Restore + reactivate |
| `forceDelete($id)` | DELETE | forceDelete | Dependency check (Quiz + Quest); force delete |
| `toggleStatus()` | AJAX POST | update | JSON toggle |

---

## Dependencies

| Dependency | Type | Details |
|-----------|------|---------|
| `lms_assessment_types` | Primary | Type definitions with soft deletes |
| `qns_question_usage_type` | FK | assessment_usage_type_id — scopes module availability |
| `lms_quizzes` | Consumer | quiz_type_id FK — blocks edit/delete if referenced |
| `lms_quests` (Quest) | Consumer (external) | quest_type_id FK — blocks forceDelete if referenced |

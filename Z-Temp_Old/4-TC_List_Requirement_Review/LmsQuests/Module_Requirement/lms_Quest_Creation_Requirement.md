# Quest Creation (Master) — Business Requirements

## What This Screen Does

The Quest Creation screen is where teachers build a new practice assessment from scratch. Think of it like setting up a test: you first name it and choose which class and subject it is for (Basic Info tab), then you define the rules — how many questions, total marks, time limit, passing percentage, and 12 behavior switches (Configuration tab).

This is a two-tab wizard that guides the teacher step by step. Nothing is saved to the database until the teacher clicks "Save" at the end.

---

## When This Screen Is Used

- **Start of a New Quest** — After planning what topics to assess, the teacher creates the Quest shell
- **Duplicating an Existing Quest** — Teachers can copy a Quest to reuse its settings and questions
- **Editing a Quest** — If no student has attempted yet, teachers can change the Quest's settings
- **Publishing/Archiving** — Changing the Quest's status from DRAFT to PUBLISHED, or ARCHIVED when no longer needed

---

## Who Can Access This Screen

- **Teacher** — Can create and manage their own Quests
- **Head of Department** — Full access for their department's subjects
- **Academic Coordinator** — Full access for setting up Quest assessments
- **Principal** — Read-only access

All access is controlled by permissions (like `tenant.quest.create`, `tenant.quest.update`, etc.). The server checks these permissions every time an action happens.

**Note:** The authorization method inside the request file returns `true` unconditionally, meaning permission checking relies entirely on the controller-level permission gates.

---

## How This Screen Works — Logic Flow (Non-Technical)

### The 2-Tab Wizard

When the teacher clicks "Add Quest," the system shows the first tab (Basic Information). The academic session (school year) is already filled in since the school year is known. The teacher picks a Class from a dropdown, and the system instantly loads the matching subjects without reloading the page.

The teacher enters the Quest's name, selects its type (Practice Test, Chapter Test, etc.), and sets the status (DRAFT by default). They can add a description and instructions that students will see before starting.

Clicking "Next: Configuration" switches to the second tab where all the test rules live. This tab has:
- Number fields for duration (max 300 minutes), total marks, total questions, passing percentage, negative marks (max 99.99), and max attempts
- A dropdown for difficulty configuration (the Easy/Medium/Hard profile)
- 12 toggle switches that control how the Quest behaves

When the teacher flips certain switches, related fields enable or disable immediately. For example, turning ON "Enforce Timer" makes the duration field editable; turning it OFF grays it out. Turning ON "Allow Multiple Attempts" enables the max attempts field (and makes it required).

### Saving

When the teacher clicks "Save," the system first runs validation to make sure all required fields are filled and values are within their allowed ranges. If a quest code was not entered, the system automatically generates one based on the academic session, class, and subject codes plus random characters. If the generated code happens to already exist, a number is added to make it unique.

The Quest is then saved to the database. An activity log entry is created. The teacher is redirected to the Quest list where they can see their new Quest.

### Editing

When editing, the system first checks if any student has attempted this Quest. If students have already started, the edit is blocked — no changes can be made because existing attempt data would become inconsistent. If no attempts exist, the exact same 2-tab form loads with the existing values filled in.

### Soft-Deleting and Restoring

When a teacher deletes a Quest, the system checks if the Quest has any allocations, questions, or student attempts. If it does, deletion is blocked. If allowed, the Quest is soft-deleted (hidden but not permanently removed), its status is set to ARCHIVED, and its active flag is turned OFF. The teacher can later restore it from the Trash.

### Force-Deleting

When a teacher permanently deletes a Quest from the Trash, the system checks for student attempts. If no attempts exist, the system permanently deletes the Quest along with all its allocations, questions (and their usage logs), and scopes — all in one go. If student attempts exist, force-delete is blocked.

### Duplicating a Quest

Teachers can duplicate a Quest to reuse its settings and questions. The copy gets a new auto-generated quest code.

---

## Validate Before Save

### Quest Request — Validation Rules

The system checks these fields before saving:

**Basic Info:**
- **academic_session_id** — Required, must exist in the sessions table
- **class_id** — Required, must exist in the classes table
- **subject_id** — Required, must exist in the subjects table
- **quest_type_id** — Required (from assessment types)
- **title** — Required, text, max 255 characters
- **status** — Required, must be one of: DRAFT, PUBLISHED, ARCHIVED
- **description** — Optional, text
- **instructions** — Optional, text
- **quest_code** — Optional, text, must be unique (cannot have two active Quests with the same code)

**Configuration:**
- **duration_minutes** — Optional, whole number, minimum 1, maximum 300
- **total_marks** — Required, number, minimum 0, maximum 999999.99
- **total_questions** — Required, whole number, minimum 0, maximum 9999
- **passing_percentage** — Required, number, minimum 0, maximum 100 (default 33.00)
- **negative_marks** — Required, number, minimum 0, maximum 99.99
- **max_attempts** — Required if "Allow Multiple Attempts" is ON, whole number, minimum 1, maximum 10 (default 1)
- **difficulty_config_id** — Optional, must exist in the difficulty configs table

**12 Toggle Switches (all are yes/no):**
1. allow_multiple_attempts — Let students try more than once
2. is_randomized — Shuffle question order for each student
3. question_marks_shown — Show marks per question to students
4. is_system_generated — Flag if the Quest was auto-generated by the system
5. auto_publish_result — Show results to students automatically after submission
6. timer_enforced — Enforce a countdown timer that auto-submits when time runs out
7. show_correct_answer — Show the correct answer after submission
8. show_explanation — Show the solution/explanation after submission
9. ignore_difficulty_config — Skip difficulty rules when adding questions
10. only_unused_questions — Only allow questions never used in another Quest
11. only_authorised_questions — Only allow questions flagged as authorised for assessment
12. is_active — Master on/off switch for the Quest

**Unique Code Check:**
The quest_code must be unique among active Quests (not soft-deleted). On update, the current Quest's ID is excluded from the check. If a duplicate is detected during creation, the system auto-appends a number suffix (`_1`, `_2`, etc.) to make it unique.

---

## Business Rules and Conditions

### Rule 1: Quest Code Auto-Generation
If the teacher does not provide a quest code, the system generates one in the format: `QUEST_{SESSION_CODE}_{CLASS_CODE}_{SUBJECT_CODE}_GEN_{RANDOM6}`. If a duplicate code is detected during creation, the system appends `_1`, `_2`, etc. On update, if the code is changed to a duplicate, the system appends a random 4-character suffix automatically.

### Rule 2: 2-Tab Wizard Flow
Tab 1 (Basic Information) collects session, class, subject, quest type, status, title, description, instructions. Tab 2 (Configuration) collects all numbers and 12 toggle switches. The teacher clicks "Next: Configuration" to move from Tab 1 to Tab 2. Tab 1 fields must be valid before the teacher can proceed.

### Rule 3: Toggle Interdependencies
- If "Allow Multiple Attempts" is OFF → max_attempts is disabled and reset to 1
- If "Enforce Timer" is ON → duration_minutes is enabled. If OFF, duration is disabled
- If "Ignore Difficulty Config" is ON → the difficulty config dropdown is disabled and cleared
- If "Auto Publish Result" is OFF → the auto-publish date feature is disabled

### Rule 4: Immutability After Usage (Usage Check)
If the Quest has any allocations, questions, or student attempts, the system blocks:
- Editing the Quest settings
- Soft-deleting the Quest
- Restoring the Quest

### Rule 5: Cascade on Force Delete
When a Quest is force-deleted, the system also permanently deletes:
- All Quest Allocations
- All Quest Questions (and their usage logs)
- All Quest Scopes
This is done in a single database transaction.

### Rule 6: Status Transitions
- DRAFT → PUBLISHED: Teacher can publish the Quest when ready
- PUBLISHED → ARCHIVED: When the Quest is no longer needed
- ARCHIVED → DRAFT: Can be unarchived back to draft
- Soft-delete sets status to ARCHIVED and is_active to false

### Rule 7: Difficulty Config Validation
When saving the Quest, the difficulty config dropdown value (if selected) is stored. The "ignore_difficulty_config" boolean determines whether this config is enforced when adding questions later. There is no cross-validation between total_questions and difficulty config at creation time (the error appears only when adding questions).

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| Quest Code | Auto-generated if not provided; duplicates get a suffix |
| 2-Tab Flow | Tab 1: Basic info → Tab 2: Configuration |
| Toggle Dependencies | Enabling certain toggles enables/disables related fields |
| Usage Lock | Once students attempt, Quest settings cannot be edited |
| Force Delete Cascade | Permanently deletes Quest + all children (allocations, questions, scopes) |
| Status Transitions | DRAFT → PUBLISHED → ARCHIVED (and back to DRAFT) |
| Difficulty Config | Stored but not validated against total_questions at creation |

---

## Validate Before Save — Error Messages

| Scenario | Error Message |
|----------|--------------|
| Missing title | "Title is required" |
| Total marks exceeds max | "Total marks must not exceed 999999.99" |
| Duration out of range | "Duration must be between 1 and 300 minutes" |
| Negative marks too high | "Negative marks must not exceed 99.99" |
| Class not selected | "Please select a class" |
| Subject not selected | "Please select a subject" |
| Edit blocked by usage | "Cannot edit this quest because it is used in allocations, questions, or has student attempts." |
| Delete blocked by usage | "Cannot delete this quest because it is used in allocations, questions, or has student attempts." |
| Force-delete blocked by attempts | "Cannot permanently delete this quest because it has allocations or student attempts." |
| Duplicate quest code (auto-fix) | System auto-appends suffix to make it unique |

---

## Success Scenarios

- A teacher creates a new Quest with Title = "Algebra Basics", Class = 8, Subject = Mathematics, Total Questions = 25, Total Marks = 50, Time = 30 minutes, Passing = 40%. The system generates code "QUEST_2425_08_MATH_GEN_X7K2P1", saves it as DRAFT, and the teacher sees it in the list.

- A teacher edits a Quest to change its passing percentage from 33 to 50. Since no students have attempted it, the edit succeeds and the activity log records the change.

- A teacher soft-deletes an old Quest that has no allocations or attempts. The Quest disappears from the active list (status → ARCHIVED) and appears in the Trash.

---

## Failure Scenarios

- A teacher tries to edit a Quest that 30 students have already attempted. The usage check blocks the edit with: "Cannot edit this quest because it is used in allocations, questions, or has student attempts."

- A teacher tries to delete a Quest that has 5 questions assigned and 2 active allocations. The delete is blocked because the Quest is in use.

- A teacher enters total_marks = 0 and total_questions = 0 thinking they will fill it later. The system accepts this, but later when they try to add questions, the bulk add fails because marks per question = 0 ÷ 0 = undefined.

- A teacher tries to set duration = 500 minutes. The system rejects with "Duration must be between 1 and 300 minutes."

- A teacher tries to set negative_marks = 50. The system rejects with "Negative marks must not exceed 99.99."

---

## Example Scenario

Mr. Patel, a Grade 10 Physics teacher, wants to create a practice test for his students.

He navigates to Quests and clicks "Add Quest":
1. Tab 1: He selects Class = 10, Subject = Physics, enters Title = "Physics: Motion Practice", Quest Type = "Practice Test", Status = "DRAFT"
2. He clicks "Next: Configuration"
3. Tab 2: He sets Total Marks = 100, Total Questions = 20, Passing Percentage = 33, Duration = 45 minutes
4. He turns ON: Enforce Timer (45 minutes), Show Correct Answer, Show Explanation
5. He turns OFF: Allow Multiple Attempts, Randomize Question Order, Auto Publish Result
6. He leaves difficulty configuration empty for now
7. He clicks "Save"
8. The system generates code "QUEST_2425_10_PHY_GEN_A7B3C9", creates the Quest, and redirects him to the list

Later, he realizes he forgot to set the passing percentage to 40. Since no student has attempted this Quest yet, he clicks Edit, changes the value, and saves.

After a month, when the Quest is no longer needed, he soft-deletes it. It moves to the trash with status ARCHIVED. After confirming no student data is affected, he permanently deletes it from the trash.

---

## Related Screens

- **Quest Questions** — Where teachers add actual questions to this Quest
- **Quest Scopes** — Where topic/lesson scope limits are defined
- **Quest Allocation** — Where the Quest is deployed to students
- **Quest Dashboard** — Where teachers see aggregate stats across all Quests
- **Difficulty Config** — Where difficulty distribution rules are pre-configured

---

---

## Dependencies module and tables

| Module | Tables |
|--------|--------|
| LmsQuests Core | `lms_quests` (primary table; stores all fields: title, code, duration, marks, questions, toggles, status) |
| LmsQuests Children | `lms_quest_scopes` (FK → quests.id), `lms_quest_questions` (FK → quests.id), `lms_quest_allocations` (FK → quests.id) |
| LmsQuiz | `lms_assessment_types` (FK → quests.quest_type_id), `lms_difficulty_distribution_configs` (FK → quests.difficulty_config_id) |
| Student Portal | `sp_quiz_quest_attempts` (FK → quests.id via quest_id; used for usage check) |
| Academic Setup | `sch_org_academic_sessions`, `sch_classes`, `sch_subjects` |
| Syllabus | `slb_lessons` (linked via scope/class/subject) |

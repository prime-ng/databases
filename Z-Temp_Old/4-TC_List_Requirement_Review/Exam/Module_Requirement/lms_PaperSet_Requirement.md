# Exam Paper Set — Screen

---

## What Does This Screen Do?

The Exam Paper Set screen lets an admin create multiple variants (sets) of the same exam paper. A single exam paper — for example, "Class 10 - Mathematics - Final Exam" — can have several sets like Set A, Set B, and Set C. Each set contains different question combinations, which prevents cheating by giving different groups of students different question papers.

Each set has a unique code (like SET_A, SET_B) and a display name (like "Paper Set A", "Paper Set B"). Once a set is created, questions are assigned to it through the Paper Set Questions screen.

This screen also shows how many questions have been assigned to each set and the total marks for that set, computed automatically from its questions.

---

## Real-Life Example

A school is conducting the Class 10 Mathematics final exam in a large hall with 300 students. To prevent copying, the exam controller, Mr. Verma, decides to create three variants of the question paper.

He opens the Paper Set screen for the exam paper "Class 10 Math Final" and clicks "Add Paper Set." He enters:
- Exam Paper: "Class 10 Math Final"
- Set Code: "SET_A"
- Set Name: "Paper Set A"
- Description: "For students with roll numbers 1-100"

He then adds "SET_B" / "Paper Set B" and "SET_C" / "Paper Set C" similarly. Each set is now visible in the table with 0 questions and 0 marks assigned.

The next day, the subject teacher, Ms. Sharma, goes to the Paper Set Questions screen and starts adding questions to Set A. She adds 35 questions worth 70 marks total. The Paper Set screen now shows Set A with "35 Q" and "70 marks" in the table.

Later, Mr. Verma realizes he misspelled "SET_C" as "SET_CC". He tries to edit Set C. The system checks if the set has any questions or allocations. Since Set C is newly created with no questions and no allocations, the edit is allowed and he fixes the code. However, if he tried to edit Set A (which already has 35 questions assigned), the system would block him: "This paper set is used in 35 question(s). Therefore cannot be edited."

The exam happens successfully. After results are published, Mr. Verma wants to clean up. He tries to delete Set A, but the system blocks him: "This paper set is used in 35 question(s), 100 allocation(s). Therefore cannot be deleted." However, Set C was never used — no questions were assigned to it and no students were allocated to it. He can delete it freely.

A year later, the school admin wants to permanently remove old exam data. They find Set A in the active sets and try to permanently delete it. Even though it has historical allocations, the force delete check runs and blocks the operation. They first need to clean up the allocations before they can permanently remove the set.

---

## How It Works

This is the third sub-tab inside the Creation & Allocation tab. When the admin opens it, the system loads all paper sets, 10 per page, newest first.

The screen shows a table with each set's code, name, parent exam paper, exam code, description, question count, and total marks. The question count and marks are computed automatically — the system counts all PaperSetQuestion records for that set and sums up their override_marks.

The admin can filter the list by:
- Exam paper (select from a dropdown of all active exam papers).
- Exam (filter sets whose parent exam paper belongs to a specific exam).
- Status (Active, Inactive, or All).
- Free-text search that looks in set code, set name, description, paper code, and paper title.

**Creating a New Set**

When the admin clicks "Add Paper Set," a form opens with these fields:
- Exam Paper (required): Dropdown of all active exam papers.
- Set Code (required): A short unique code like SET_A, max 20 characters.
- Set Name (required): A display name like "Paper Set A", max 50 characters.
- Description (optional): Free text, max 255 characters.
- Active (checkbox): Whether the set is active. Defaults to checked.

When the admin submits, the system validates:
- Exam paper is required and must exist.
- Set code is required, must be a string, max 20 chars, and must be unique within the same exam paper. If another set already has the same code for this exam paper, the system rejects with: "This set code already exists for this exam paper."
- Set name is required, must be a string, max 50 chars.
- Description is optional, max 255 chars.
- is_active is treated as boolean.

If validation passes, the set is created and an activity log is recorded. The admin is redirected back to the paper sets tab with a success message.

**Viewing a Set**

When the admin clicks "View" on a set, the system shows the set's details including:
- Paper set information (code, name, description, status).
- The parent exam paper and exam details.
- All questions assigned to this set (with their details).
- All allocations using this set.
- Usage information from the ExamPaperSetUsageCheckService — which tells how many questions are assigned and how many allocations exist for this set.

**Editing a Set**

When the admin clicks "Edit," the system first checks if the set is "used." The ExamPaperSetUsageCheckService counts:
- How many questions are assigned to this set (PaperSetQuestion records).
- How many student allocations use this set (ExamAllocation records).

If the total is greater than zero, the system prevents editing and shows an error: "This paper set is currently used in X question(s), Y allocation(s). Therefore cannot be edited."

If the set is not used, the edit form opens with the same fields as the create form, pre-filled with existing values. The admin can change set code, set name, description, and active status. The same validation rules apply for uniqueness of set code.

After editing, the system records an activity log showing exactly what changed (old vs new values for each field), and redirects back with a success message.

**Deleting a Set**

When the admin clicks "Delete," the system first checks usage (questions and allocations). If used, deletion is blocked: "This paper set is used in X question(s), Y allocation(s). Therefore cannot be deleted."

If not used, the system:
1. Sets is_active to false (deactivates it).
2. Saves the record.
3. Calls soft delete (marks deleted_at timestamp).
4. Logs the activity.
5. Redirects with a success message.

**Restoring a Set**

When the admin clicks "Restore" on a trashed set, the system:
1. Restores from soft delete.
2. Sets is_active back to true.
3. Logs the activity.

**Permanently Deleting a Set**

When the admin clicks "Permanent Delete," the system:
1. Checks usage again (questions and allocations). If used, blocks with: "This paper set is used in X question(s), Y allocation(s). Therefore cannot be permanently deleted."
2. Calls force delete (permanently removes the record).
3. Logs the activity.

**Toggling Active Status**

The admin can toggle a set's active/inactive status via an AJAX switch in the table. This updates the is_active field directly without affecting the soft-delete status.

**Computed Attributes**

The model automatically computes:
- total_marks: The sum of all override_marks from the set's PaperSetQuestion records.
- total_questions: The count of all PaperSetQuestion records.

These are displayed in the table but are not stored in the database.

---

## Key Fields

**Exam Paper**: The parent exam paper this set belongs to. Required. Links to the lms_exam_papers table.

**Set Code**: A short unique code within the exam paper (e.g., SET_A, SET_B). Required, max 20 characters, must be unique per exam paper.

**Set Name**: A descriptive name (e.g., "Paper Set A", "Paper Set B"). Required, max 50 characters.

**Description**: Optional free-text description, max 255 characters.

**Is Active**: Whether the set is active and available for use. Default true. Can be toggled via AJAX without going through the full edit flow. Toggling does not check usage protection.

**Total Questions (computed)**: The number of questions currently assigned to this set. Read-only, calculated on the fly by counting PaperSetQuestion records.

**Total Marks (computed)**: The sum of all question marks in this set. Read-only, calculated on the fly by summing override_marks from all PaperSetQuestion records.

---

## Business Rules

**Unique Set Code Per Exam Paper**: The combination of exam_paper_id and set_code must be unique. If the admin tries to create or update a set with a code that already exists for the same exam paper, the system rejects it. This uniqueness is validated by the form request.

**Usage Protection Blocks Edit/Delete**: Before any edit, delete, restore, or force-delete operation, the system checks whether the set has any PaperSetQuestion records or ExamAllocation records. If it does, the operation is blocked. The error message dynamically lists what the set is used in (e.g., "X question(s), Y allocation(s)").

**Usage Check for View**: The show/details page also checks usage and displays it for reference, but does not block viewing.

**Deactivation Before Soft Delete**: When a set is soft-deleted, the system first sets is_active to false, then calls delete(). This means trashed sets are always inactive.

**Restoration Reactivates**: When a set is restored from trash, the system sets is_active back to true.

**Activity Logging**: Every create, update, trash, restore, and force-delete operation is logged with details about who performed it. Updates log exactly which fields changed and what the old and new values were.

**AJAX Toggle Status**: The active/inactive switch in the table uses an AJAX call to update only the is_active field, without going through the full edit flow or usage check.

**Soft Delete with Cascade**: The database has ON DELETE CASCADE on foreign keys, so related PaperSetQuestion records are automatically deleted when a paper set is permanently deleted.

**Computed Fields Not Stored**: The total_marks and total_questions are computed on-demand from the questions relationship. They are not stored in the database.

**General Search**: The free-text search looks across set_code, set_name, description, and the parent exam paper's paper_code and title.

**Exam-Level Filter**: The admin can filter paper sets by exam (not just exam paper), which finds all sets whose parent exam paper belongs to that exam.

**No Cascade Delete Protection**: When an exam paper is deleted, its paper sets are also deleted via database cascade. However, the system does not warn the admin about related paper sets when deleting an exam paper.

**Trashed List Shows All Deleted Sets**: The trash view displays all soft-deleted paper sets with their exam paper details, allowing the admin to restore or permanently delete them.

**Restore Requires No Usage Check**: Unlike edit/delete, restoring a set does not check usage. A set can be restored even if it has questions or allocations, though allocations may reference it.

**Permanent Delete Removes All Traces**: Force delete permanently removes the paper set record along with all related PaperSetQuestion records (via database cascade and the service's explicit deletion pattern).

**Trash/Restore Lifecycle**:
1. Delete → is_active = false, soft delete (appears in trash)
2. Restore → restores soft delete, is_active = true
3. Force Delete → completely removed from database
4. A set in trash is still counted for usage checks (restore doesn't check usage, but subsequent edit/delete after restore will).

**Table Display Features**:
- Questions column shows count as a badge (e.g., "35 Q") and total marks below it.
- Set code and name are shown in bold.
- Exam paper shows both paper_code and title on separate lines.
- Exam code shown as an info badge.
- Description is truncated to 60 characters with ellipsis.
- Action buttons (View, Edit, Delete) are rendered conditionally based on permissions.
- Status toggle switch allows instant activation/deactivation.

**Index Query Eager Loading**: The index query eagerly loads the exam paper, exam (through exam paper), and questions relationships. This prevents N+1 query issues when displaying the table.

**Form Request Validation**: The ExamPaperSetRequest handles authorization separately for each HTTP method (POST → create, PUT/PATCH → update, DELETE → delete). The prepareForValidation method converts is_active from checkbox format to a proper boolean before validation runs.

**No Cascade Deletion of Parent**: When a paper set is deleted, the parent exam paper is not affected. The deletion only affects the set itself and its dependent question records and allocations (via cascade).

**Model Relationships**:
- Belongs to ExamPaper (exam_paper_id)
- Has many PaperSetQuestion (questions in this set)
- Has many ExamAllocation (student allocations using this set)

**Usage Check Service Detail**:
The ExamPaperSetUsageCheckService provides four methods:
- isUsed(id): Returns true if the set has any questions or allocations.
- getUsageCount(id): Returns the total count of questions + allocations.
- getUsageDetails(id): Returns an associative array with separate counts for "Questions" and "Allocations".
- getUsageMessage(id): Returns a human-readable string like "This paper set is used in 35 question(s), 100 allocation(s)."
- throwIfUsed(id, message): Throws a DomainException if the set is used.

**Routing Pattern**:
All routes are under the "lms-exam.paper-set.*" naming convention. The index route is used within the Creation & Allocation tab using the active_tab=paper_set parameter. Standard resource routes (except show) are augmented with trashed, restore, forceDelete, and toggleStatus routes.

**Database Constraints**:
- Unique constraint on (exam_paper_id, set_code) prevents duplicate codes within the same exam paper.
- Foreign key to lms_exam_papers.id with ON DELETE CASCADE ensures related sets are removed when an exam paper is deleted.
- The lms_paper_set_questions table references lms_exam_paper_sets.id with ON DELETE CASCADE for automatic question cleanup.

---

## Validation & Error Messages

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| exam_paper_id | Required, must exist in lms_exam_papers | "Exam paper is required" |
| set_code | Required, string, max 20 chars | "Set code is required" |
| set_code (unique) | Must be unique per exam_paper_id | "This set code already exists for this exam paper" |
| set_name | Required, string, max 50 chars | "Set name is required" |
| description | Optional, string, max 255 chars | (none — Laravel default) |
| is_active | Boolean | (none — Laravel default) |
| Usage (edit) | Questions or Allocations must be 0 | "This paper set is currently used in X question(s), Y allocation(s). Therefore cannot be edited." |
| Usage (delete) | Questions or Allocations must be 0 | "This paper set is currently used in X question(s), Y allocation(s). Therefore cannot be deleted." |
| Usage (update) | Questions or Allocations must be 0 | "This paper set is currently used in X question(s), Y allocation(s). Therefore cannot be updated." |
| Usage (force delete) | Questions or Allocations must be 0 | "This paper set is currently used in X question(s), Y allocation(s). Therefore cannot be permanently deleted." |

---

## Permissions

- `tenant.paper-set.viewAny` — View the list of all paper sets
- `tenant.paper-set.view` — View a specific paper set's details
- `tenant.paper-set.create` — Create new paper sets
- `tenant.paper-set.update` — Edit existing paper sets
- `tenant.paper-set.delete` — Soft-delete (trash) paper sets
- `tenant.paper-set.restore` — Restore trashed paper sets
- `tenant.paper-set.forceDelete` — Permanently delete paper sets
- `tenant.paper-set.status` — Toggle active/inactive status

---

## Related Screens

- **Exam Paper**: The parent entity. Each paper set belongs to exactly one exam paper.
- **Paper Set Questions (lms_PaperQuestion)**: The screen where questions are assigned to paper sets. This is the main consumer of paper set records.
- **Exam Allocation**: Allocations that assign paper sets to specific students or groups. Allocations are what prevent deletion of used sets.
- **Exam Blueprint**: Blueprints are related through the exam paper, not directly through the paper set.

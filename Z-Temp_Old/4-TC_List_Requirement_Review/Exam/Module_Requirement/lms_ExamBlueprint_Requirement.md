# Exam Blueprint Screen

---

## What Does This Screen Do?

The Exam Blueprint screen defines the **structure** of an exam paper — how it's divided into sections, and how many questions and marks each section has.

Think of it like planning a test paper's table of contents:

| Section | Question Type | Questions | Marks Each | Total |
|---------|--------------|-----------|-----------|-------|
| Section A | Multiple Choice (MCQ) | 10 | 1 | 10 |
| Section B | Short Answer | 5 | 2 | 10 |
| Section C | Long Answer | 3 | 5 | 15 |
| **Total** | | **18** | | **35** |

The blueprint ensures the paper is properly structured before questions are added. It also acts as a guide during question selection — teachers know exactly how many of each question type to pick.

---

## Real-Life Example

**Scenario:** Teacher Sharma is setting up the "Annual Exam 2026 - Mathematics" paper. The paper has total_questions = 18 and total_marks = 35.

**What he does:**
1. Goes to Exam Blueprint tab
2. Clicks "Add Blueprint"
3. Selects the Mathematics paper
4. The system automatically shows the paper's limits: "Max 18 questions, Max 35 marks"
5. Adds 3 section rows:
   - Section A: MCQ, 10 questions × 1 mark = 10 marks
   - Section B: Short Answer, 5 questions × 2 marks = 10 marks
   - Section C: Long Answer, 3 questions × 5 marks = 15 marks
6. Clicks "Save"
7. System checks: 18 questions = 18 (✓), 35 marks = 35 (✓)
8. Saved successfully

Later, Teacher Sharma realizes Section B should have 6 questions instead of 5. Since no questions have been added yet, he edits the blueprints and changes it. The new total: 19 questions — but the paper only allows 18. The system rejects the save with: "The sum of total questions (19) must be exactly equal to the Exam Paper's limit of 18."

---

## How the List Page Works

When you open the Blueprint tab, you see blueprints **grouped by exam paper** — each row shows one paper with:
- Paper title
- Number of sections defined
- Sum of all questions across sections
- Sum of all marks across sections

10 rows per page, newest first.

### Filters

| Filter | What It Does |
|--------|-------------|
| **Exam Paper** | Show blueprints for a specific paper |
| **Search** | Search by paper title |

---

## How to Create Blueprints

**Step 1:** Click "Add Blueprint"

**Step 2:** Select an exam paper from the dropdown

**Important:** The dropdown ONLY shows exam papers that do NOT already have blueprints. Once you create blueprints for a paper, that paper disappears from the create dropdown. To change blueprints later, you must edit them.

**Step 3:** The system loads the paper's limits via AJAX (`getPaperDetails` endpoint). You'll see "Max questions: X, Max marks: Y" at the top.

**Step 4:** Add section rows. Each row needs:

| Field | Required? | Details |
|-------|-----------|---------|
| **Section Name** | Yes | Max 50 chars. Must be unique within this paper. |
| **Question Type** | No | Select from available types (MCQ, Short Answer, etc.) |
| **Instruction Text** | No | Any special instructions for this section |
| **Total Questions** | Yes | Min 1, integer |
| **Marks Per Question** | No | Numeric, if known |
| **Total Marks** | Yes | Numeric, min 0 |
| **Ordinal (Order)** | Yes | 1, 2, 3... controls display order |

You can add or remove rows before saving.

**Step 5:** Click "Save Blueprints"

### What Happens on Save

1. Permission checked: `tenant.exam-blueprint.create`
2. Three levels of validation run (see below)
3. If Paper already has blueprints → they are **deleted first** (complete replace)
4. All new blueprint rows are created
5. Activity logged: "Multiple exam blueprints were created for paper: XXX"
6. Entire operation wrapped in a **database transaction** — if anything fails, everything rolls back

---

## How to Edit Blueprints

**Step 1:** Click "Edit" on a paper

**Step 2:** The system checks usage — if ANY of this paper's blueprints are already used in paper set questions, editing is blocked.

**Step 3:** The edit form shows all existing blueprint rows for that paper.

**Step 4:** You can:
- **Update** an existing row (change name, questions, marks, etc.)
- **Add** a new row (creates a new blueprint record)
- **Remove** a row (the old blueprint is **permanently deleted** — not soft-deleted)

**Step 5:** Click "Update Blueprints"

### Smart Merge Logic

The system does NOT do a simple replace like create does. Instead, it uses a "three-way merge":

1. For rows with an ID → **UPDATE** the existing record
2. For rows without an ID → **CREATE** a new record
3. For existing records NOT in the submission → **FORCE DELETE** (permanent, not recoverable)

This means if you remove a section during editing, that blueprint record is gone forever.

---

## How to Delete Blueprints

There are two delete operations:

| Operation | What It Does | Can Be Recovered? |
|-----------|-------------|-------------------|
| **Delete (single)** | Soft-deletes ONE blueprint row | ✅ Yes (from trash) |
| **Bulk Delete** | Soft-deletes ALL blueprints for a paper | ✅ Yes (from trash) |

Both check usage first. If any blueprint is used in paper set questions, deletion is blocked.

---

## The Three Levels of Validation

### Level 1 — Individual Row Rules

| Check | Error Message |
|-------|---------------|
| exam_paper_id is required and exists | — |
| section_name is required, max 50 chars | — |
| total_questions is required, min 1 | — |
| total_marks is required, min 0 | — |
| ordinal is required, min 1 | — |

### Level 2 — Internal Consistency

For each section, if `marks_per_question` is set:

> `total_marks` must equal `total_questions × marks_per_question`

**Example:** If Section A has 10 questions and 1 mark each, total_marks must be 10.
If a teacher enters "10 questions × 1 mark = 15 marks", it's rejected with:
"Total marks (15) must equal Total Questions (10) x Marks Per Question (1)."

### Level 3 — Paper Alignment

Two checks against the parent exam paper's limits:

| Check | Rule | Error Message |
|-------|------|---------------|
| Questions | Σ total_questions across ALL sections = Paper's total_questions | "The sum of total questions (X) must be exactly equal to the Exam Paper's limit of Y." |
| Marks | Σ total_marks across ALL sections = Paper's total_marks | "The sum of total marks (X) must be exactly equal to the Exam Paper's limit of Y." |

**These must be EXACT matches, not "less than or equal."** If the paper allows 35 marks, the blueprint's sections must add up to exactly 35, not 34 or 36.

---

## Usage Protection

The `ExamBlueprintUsageCheckService` checks if this blueprint is used in the `lms_paper_set_questions` table (questions have been added to a paper set using this blueprint section).

If used, the following operations are blocked:

| Operation | Block Message |
|-----------|--------------|
| Edit | "This blueprint is currently being used in paper set questions. Therefore cannot be edited." |
| Update | Same message |
| Delete | Same message |
| Force Delete | Same message |

**Important:** The usage check runs on the FIRST blueprint record submitted. If that one blueprint is used, the entire edit for the paper is blocked — even if other blueprints for the same paper are unused.

---

## Restore and Force Delete

### Restore (from Trash page)

Blueprints can be restored individually or in bulk (all blueprints for a paper restored together).

### Force Delete (from Trash page)

Blueprints can be permanently deleted individually or in bulk. Usage check blocks this if any student attempt data exists.

---

## Toggle Active/Inactive Status

There are two toggle operations:

| Operation | What It Does |
|-----------|-------------|
| **Toggle Status** | Toggles active/inactive for ONE blueprint row |
| **Bulk Toggle Status** | Toggles active/inactive for ALL blueprints of a paper at once |

Toggle status works on both active and inactive blueprints. Logs activity.

---

## Business Rules Summary

| # | Rule | What It Means |
|---|------|---------------|
| 1 | **One paper = one blueprint set** | You can only have one set of blueprints per exam paper. Add new = replace old. |
| 2 | **Total questions must match exactly** | Blueprint sections must sum to the paper's total_questions exactly |
| 3 | **Total marks must match exactly** | Blueprint sections must sum to the paper's total_marks exactly |
| 4 | **Internal consistency** | Each section's total_marks must equal questions × marks_per_question |
| 5 | **Unique section names per paper** | No two sections can have the same name in the same paper |
| 6 | **Replace on create** | Creating blueprints for a paper that already has them → deletes old ones first |
| 7 | **Smart merge on edit** | Edit uses three-way merge: update existing, create new, force-delete removed |
| 8 | **Bulk delete/restore** | Operations available for all blueprints of a paper at once |
| 9 | **Usage blocks everything** | If any blueprint is used in questions, edit/delete/force-delete are blocked |
| 10 | **DB transactions** | All create/update/delete operations are wrapped in transactions |
| 11 | **Activity logged** | Every blueprint operation is recorded |
| 12 | **Removed rows force-deleted** | During edit, removed blueprints are permanently deleted (not recoverable) |

---

## Permission Summary

| Action | Permission Required |
|--------|-------------------|
| View list | `tenant.exam-blueprint.viewAny` |
| View blueprints for a paper | `tenant.exam-blueprint.view` |
| Create | `tenant.exam-blueprint.create` |
| Edit/Update/Toggle | `tenant.exam-blueprint.update` |
| Delete/Bulk Delete | `tenant.exam-blueprint.delete` |
| View trash/Restore | `tenant.exam-blueprint.restore` |
| Force Delete | `tenant.exam-blueprint.forceDelete` |

---

## Related Screens

| Screen | Connection |
|--------|-----------|
| **Exam Paper** | Parent — blueprints reference exam_paper_id |
| **Paper Set Questions** | Consumer — each question references blueprint_id |
| **Exam Creation** | Publication validation (DV3-DV4) validates blueprints against actual questions |
| **Question Selection** | Teachers use blueprints as a guide to pick questions |

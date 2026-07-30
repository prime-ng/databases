# lms_exam_blueprint_TcList

## Module: LmsExam → Creation & Allocation → Exam Blueprint

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Creation & Allocation |
| Feature | Exam Blueprint |
| URL(s) | `/lms-exam/creation-allocation` (index via tab), `/lms-exam/exam-blueprint/create` (create), `/lms-exam/exam-blueprint/store` (store bulk), `/lms-exam/exam-blueprint/{examBlueprint}` (show), `/lms-exam/exam-blueprint/{examBlueprint}/edit` (edit bulk), `/lms-exam/exam-blueprint/{examBlueprint}` (update PUT/PATCH bulk), `/lms-exam/exam-blueprint/{examBlueprint}` (destroy DELETE), `/lms-exam/exam-blueprint/trash/view` (trashed), `/lms-exam/exam-blueprint/bulk-destroy/{paper_id}` (bulkDestroy), `/lms-exam/exam-blueprint/bulk-restore/{paper_id}` (bulkRestore), `/lms-exam/exam-blueprint/bulk-force-delete/{paper_id}` (bulkForceDelete), `/lms-exam/exam-blueprint/{id}/toggle-status` (toggleStatus), `/lms-exam/exam-blueprint/bulk-toggle-status/{paper_id}` (bulkToggleStatus), `/lms-exam/exam-blueprint/paper-details/{id}` (getPaperDetails AJAX) |
| Controller | `Modules\LmsExam\Http\Controllers\ExamBlueprintController` |
| Model(s) | `Modules\LmsExam\Models\ExamBlueprint` |
| Validation (Create) | `Modules\LmsExam\Http\Requests\ExamBlueprintRequest` — validates exam_paper_id, blueprints array (min:1), each row: id, section_name, question_type_id, instruction_text, total_questions, marks_per_question, total_marks, ordinal, is_active; plus `withValidator` callback for internal consistency |
| Validation (Update) | Same `ExamBlueprintRequest` — same rules plus `withValidator` callback |
| Permissions | `tenant.exam-blueprint.viewAny`, `tenant.exam-blueprint.view`, `tenant.exam-blueprint.create`, `tenant.exam-blueprint.update`, `tenant.exam-blueprint.delete`, `tenant.exam-blueprint.restore`, `tenant.exam-blueprint.forceDelete` |
| Soft Deletes | Yes (`ExamBlueprint` uses `SoftDeletes` trait; `store()` deletes existing then recreates; `update()` forceDeletes removed rows) |
| Activity Log | Events: `Blueprint Stored`, `Blueprint Updated`, `Trashed`, `Toggled` |
| Bulk Operations | All CRUD operates on ALL blueprints for an exam paper at once; individual destroy only for one blueprint |
| Unique Constraint | `uq_blueprint_section (exam_paper_id, section_name)` — section name unique per paper |
| Usage Service | `ExamBlueprintUsageCheckService` — checks `lms_paper_set_questions` usage |

---

## 2. Pre-conditions

- Required permissions: `tenant.exam-blueprint.viewAny`, `tenant.exam-blueprint.view`, `tenant.exam-blueprint.create`, `tenant.exam-blueprint.update`, `tenant.exam-blueprint.delete`, `tenant.exam-blueprint.restore`, `tenant.exam-blueprint.forceDelete`
- Required seed data: At least one active `ExamPaper` with `total_questions` and `total_marks` set, one active `QuestionType`
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For blueprint creation tests: Exam paper that does NOT already have blueprints (papers without existing blueprints appear in dropdown)
- For edit tests: Exam paper with at least 2 existing blueprint sections
- For validation tests: Exam paper with total_questions=20, total_marks=50 for alignment checks
- For usage check tests: Blueprint that has been linked in `lms_paper_set_questions`
- For AJAX test: Exam paper with total_questions and total_marks configured

---

## 3. Default Data Load

When the page loads via Creation & Allocation tab (`active_tab=exam_blueprint`), the following data is fetched:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Blueprint Groups Grid | ExamBlueprintController@index() | ExamBlueprint::select(exam_paper_id, sections_count, sum_questions, sum_marks, representative_id)->with(examPaper)->groupBy(exam_paper_id) | Filter: exam_paper_id, search (paper title) | 10/page |
| Exam Papers List | ExamBlueprintController@index() | ExamPaper::where('is_active',true)->get() | is_active=1 | None |
| Exam Papers (create view) | ExamBlueprintController@create() | ExamPaper::where('is_active',true)->whereNotIn('id', existingPaperIds)->get() | is_active=1, no existing blueprints | None |
| Question Types (create view) | ExamBlueprintController@create() | QuestionType::where('is_active',true)->get() | is_active=1 | None |
| Question Types (edit view) | ExamBlueprintController@edit() | QuestionType::where('is_active',true)->get() | is_active=1 | None |
| Exam Papers (edit view) | ExamBlueprintController@edit() | ExamPaper::where('is_active',true)->get() | is_active=1 | None |

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Section names**: Unique per exam paper (e.g., "Section A - {suffix}", "Section B - {suffix}")
- **Total questions per section**: Must be >= 1 (validator min:1)
- **Total marks alignment**: Sum of total_questions must equal paper.total_questions; sum of total_marks must equal paper.total_marks
- **Internal consistency**: For each row, total_marks must equal total_questions × marks_per_question (if marks_per_question set)
- **Pre-test cleanup**: Delete created blueprints by exam_paper_id before/after tests
- **Usage test data**: Create PaperSetQuestion records referencing a blueprint for usage check tests
- **Cleanup**: Blueprints forceDeleted during cleanup (after usage check tests verify blocking)

---

## 5. Business Conditions

### 4.1 Database Schema — `lms_exam_blueprints`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | exam_paper_id | INT UNSIGNED FK | NOT NULL, FK → `lms_exam_papers.id`, ON DELETE CASCADE |
| BC-DB-03 | section_name | VARCHAR(50) | NOT NULL DEFAULT 'Section A', UNIQUE with exam_paper_id |
| BC-DB-04 | question_type_id | INT UNSIGNED FK NULL | FK → `slb_question_types.id` |
| BC-DB-05 | instruction_text | TEXT NULL | Section instructions |
| BC-DB-06 | total_questions | INT UNSIGNED | NOT NULL DEFAULT 0 |
| BC-DB-07 | marks_per_question | DECIMAL(5,2) NULL | Per-question marks |
| BC-DB-08 | total_marks | DECIMAL(8,2) | NOT NULL DEFAULT 0.00 |
| BC-DB-09 | ordinal | TINYINT UNSIGNED | NOT NULL DEFAULT 1 |
| BC-DB-10 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-11 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-12 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-13 | deleted_at | TIMESTAMP NULL | Soft delete |

### 4.2 Validation Rules — `ExamBlueprintRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | exam_paper_id | required, exists:lms_exam_papers,id | — |
| BC-VAL-02 | blueprints | required, array, min:1 | — |
| BC-VAL-03 | blueprints.*.id | nullable, integer, exists:lms_exam_blueprints,id | — |
| BC-VAL-04 | blueprints.*.section_name | required, string, max:50 | — |
| BC-VAL-05 | blueprints.*.question_type_id | nullable, exists:slb_question_types,id | — |
| BC-VAL-06 | blueprints.*.instruction_text | nullable, string | — |
| BC-VAL-07 | blueprints.*.total_questions | required, integer, min:1 | — |
| BC-VAL-08 | blueprints.*.marks_per_question | nullable, numeric, min:0 | — |
| BC-VAL-09 | blueprints.*.total_marks | required, numeric, min:0 | — |
| BC-VAL-10 | blueprints.*.ordinal | required, integer, min:1 | — |
| BC-VAL-11 | blueprints.*.is_active | boolean | — |
| BC-VAL-12 | Internal consistency (withValidator) | total_marks = total_questions × marks_per_question (if marks_per_question > 0) | "Total marks (X) must equal Total Questions (Y) x Marks Per Question (Z)." |
| BC-VAL-13 | Paper questions alignment (withValidator) | Σ total_questions = paper.total_questions | "The sum of total questions (X) must be exactly equal to the Exam Paper's limit of Y." |
| BC-VAL-14 | Paper marks alignment (withValidator) | Σ total_marks = paper.total_marks (within 0.01 tolerance) | "The sum of total marks (X) must be exactly equal to the Exam Paper's limit of Y." |

### 4.3 Validation Rules — `ExamBlueprintRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | exam_paper_id | required, exists:lms_exam_papers,id | — |
| BC-VAL-U02 | blueprints | required, array, min:1 | — |
| BC-VAL-U03 | blueprints.*.id | nullable, integer, exists:lms_exam_blueprints,id | — |
| BC-VAL-U04 | blueprints.*.section_name | required, string, max:50 | — |
| BC-VAL-U05 | blueprints.*.total_questions | required, integer, min:1 | — |
| BC-VAL-U06 | blueprints.*.total_marks | required, numeric, min:0 | — |
| BC-VAL-U07 | blueprints.*.ordinal | required, integer, min:1 | — |
| BC-VAL-U08 | Internal consistency (withValidator) | Same as create — row-level total_marks = total_questions × marks_per_question | "Total marks (X) must equal Total Questions (Y) x Marks Per Question (Z)." |
| BC-VAL-U09 | Paper questions alignment (withValidator) | Σ total_questions = paper.total_questions | "The sum of total questions (X) must be exactly equal to the Exam Paper's limit of Y." |
| BC-VAL-U10 | Paper marks alignment (withValidator) | Σ total_marks = paper.total_marks | "The sum of total marks (X) must be exactly equal to the Exam Paper's limit of Y." |
| BC-VAL-U11 | Usage (controller) | Checked before edit/update/destroy/forceDelete | Dynamic usage message |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.exam-blueprint.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.exam-blueprint.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.exam-blueprint.create | create(), store() | Without → 403 |
| BC-AUTH-04 | tenant.exam-blueprint.update | edit(), update(), toggleStatus(), bulkToggleStatus(), updateOrdinal(), updateMarks(), updateCompulsory() | Without → 403 |
| BC-AUTH-05 | tenant.exam-blueprint.delete | destroy(), bulkDestroy() | Without → 403 |
| BC-AUTH-06 | tenant.exam-blueprint.restore | trashed(), bulkRestore() | Without → 403 |
| BC-AUTH-07 | tenant.exam-blueprint.forceDelete | forceDelete(), bulkForceDelete() | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Bulk store replaces existing | `store()` deletes all existing blueprints for paper (soft delete) then creates new ones |
| BC-BIZ-02 | Bulk store with internal consistency check | `withValidator` validates each row's total_marks = total_questions × marks_per_question (if marks_per_question > 0) |
| BC-BIZ-03 | Bulk store with paper questions alignment | Sum of all total_questions must exactly equal exam_paper.total_questions |
| BC-BIZ-04 | Bulk store with paper marks alignment | Sum of all total_marks must exactly equal exam_paper.total_marks (within 0.01 tolerance) |
| BC-BIZ-05 | Bulk update handles create/edit/delete | Existing IDs updated; new rows (no ID) created; removed IDs forceDeleted |
| BC-BIZ-06 | Bulk update with usage protection | Before processing, usage check runs; if used, update blocked with usage message |
| BC-BIZ-07 | Bulk destroy (soft delete) for paper | All blueprints for exam_paper_id soft-deleted; usage check before |
| BC-BIZ-08 | Bulk restore for paper | All soft-deleted blueprints for exam_paper_id restored |
| BC-BIZ-09 | Bulk forceDelete for paper | All soft-deleted blueprints for exam_paper_id permanently deleted; usage check before |
| BC-BIZ-10 | Individual destroy for one blueprint | Only that specific blueprint soft-deleted; usage check before |
| BC-BIZ-11 | Toggle status individual | Flips is_active on single blueprint; returns JSON response |
| BC-BIZ-12 | Bulk toggle status for paper | Toggles ALL blueprints for exam_paper_id to same new status; returns JSON |
| BC-BIZ-13 | Create dropdown excludes papers with blueprints | Only exam papers without existing blueprints appear in create dropdown |
| BC-BIZ-14 | AJAX getPaperDetails | Returns exam_paper.total_questions and total_marks as JSON |
| BC-BIZ-15 | DB transaction on all write operations | All store/update/destroy/bulkDestroy/bulkRestore/bulkForceDelete wrapped in DB::transaction |
| BC-BIZ-16 | Activity log on blueprint store | activityLog($paper, 'Blueprint Stored') for the exam paper |
| BC-BIZ-17 | Activity log on blueprint update | activityLog($paper, 'Blueprint Updated') for the exam paper |
| BC-BIZ-18 | Activity log on blueprint trash/destroy | activityLog($examBlueprint, 'Trashed') for individual delete |
| BC-BIZ-19 | Activity log on toggle | activityLog($examBlueprint, 'Toggled') with performed_by |
| BC-BIZ-20 | Index groups by exam paper | Select with COUNT, SUM, GROUP BY exam_paper_id; representative_id = MAX(id) |
| BC-BIZ-21 | Trash view also groups by exam paper | Same grouping query but on onlyTrashed() scope |
| BC-BIZ-22 | Show page loads all blueprints for paper | show() loads all blueprints for same exam_paper_id (not just the one passed) |
| BC-BIZ-23 | Show page checks usage | show() calls ExamBlueprintUsageCheckService for isUsed and usageDetails |
| BC-BIZ-24 | Edit form loads existing blueprints | edit() fetches all blueprints for exam_paper_id from the passed blueprint |
| BC-BIZ-25 | Update recalculates counts | After bulk update, remaining blueprints' total_questions and total_marks aggregated |
| BC-BIZ-26 | Internal consistency tolerance | Uses abs(($qCount * $marksPerQ) - $rowTotalM) > 0.01 for floating-point comparison |
| BC-BIZ-27 | Marks alignment tolerance | Uses abs($totalM - $paper->total_marks) > 0.01 for floating-point comparison |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | exam_paper_id | lms_exam_papers (id) | CASCADE |
| BC-REF-02 | question_type_id | slb_question_types (id) | RESTRICT (no CASCADE) |
| BC-REF-03 | exam_blueprint_id (in lms_paper_set_questions) | lms_exam_blueprints (id) | RESTRICT (no CASCADE in DDL; FK exists) |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Blueprint Index Page Loads With All UI Elements | Page loads with exam paper filter, search, blueprint grid grouped by paper, Add Blueprint button | — | — | ⬜ |
| TC-P02 | Filter Blueprints By Exam Paper | Grid displays only blueprints belonging to selected exam paper | — | — | ⬜ |
| TC-P03 | Search Blueprints By Paper Title | Search filters blueprints by exam paper title | — | — | ⬜ |
| TC-P04 | Create Blueprint With Single Section | One blueprint section created for exam paper | — | — | ⬜ |
| TC-P05 | Create Blueprint With Multiple Sections (2-3) | Multiple sections created with correct total_questions and total_marks sums | — | — | ⬜ |
| TC-P06 | Create Blueprint With All Optional Fields | section_name, question_type_id, instruction_text, marks_per_question all saved correctly | — | — | ⬜ |
| TC-P07 | Create Blueprint With is_active=false | Blueprint created as inactive | — | — | ⬜ |
| TC-P08 | Create Blueprint Matching Paper Total Questions Exactly | Sum of total_questions = paper.total_questions; saves successfully | — | — | ⬜ |
| TC-P09 | Create Blueprint Matching Paper Total Marks Exactly | Sum of total_marks = paper.total_marks; saves successfully | — | — | ⬜ |
| TC-P10 | Create Blueprint With Internal Consistency | Each row's total_marks = total_questions × marks_per_question; validation passes | — | — | ⬜ |
| TC-P11 | Create Blueprint Replaces Existing (Store Deletes Before Insert) | Any existing blueprints for paper are deleted; new ones created | — | — | ⬜ |
| TC-P12 | Show Blueprint Details Page With All Sections | Show page displays all sections for the exam paper with section details | — | — | ⬜ |
| TC-P13 | Show Blueprint Details With Usage Information | Show page displays isUsed flag and usage details if blueprint is used in questions | — | — | ⬜ |
| TC-P14 | Load Edit Form With Existing Blueprints | Edit form displays all existing blueprint rows for the paper | — | — | ⬜ |
| TC-P15 | Edit Blueprint — Update Existing Section | Change section_name, total_questions, total_marks; update succeeds | — | — | ⬜ |
| TC-P16 | Edit Blueprint — Add New Section While Keeping Existing | New section added; existing sections preserved | — | — | ⬜ |
| TC-P17 | Edit Blueprint — Remove Existing Section (Force Delete) | Removed section forceDeleted; remaining sections preserved | — | — | ⬜ |
| TC-P18 | Edit Blueprint — Create, Update, Delete Simultaneously | Mix of new, edited, and removed sections processed correctly | — | — | ⬜ |
| TC-P19 | Individual Delete (Soft Delete) Single Section | Selected blueprint section soft-deleted | — | — | ⬜ |
| TC-P20 | Bulk Delete (Soft Delete) All Sections For Paper | All blueprints for paper soft-deleted | — | — | ⬜ |
| TC-P21 | View Trash Page With Grouped Soft-Deleted Blueprints | Trash shows grouped blueprints by exam_paper_id | — | — | ⬜ |
| TC-P22 | Bulk Restore All Sections For Paper | All soft-deleted blueprints for paper restored | — | — | ⬜ |
| TC-P23 | Bulk ForceDelete All Sections For Paper | All soft-deleted blueprints permanently deleted | — | — | ⬜ |
| TC-P24 | Toggle Status Individual — Single Section | is_active toggled on single blueprint; JSON response | — | — | ⬜ |
| TC-P25 | Bulk Toggle Status — All Sections For Paper | ALL blueprints for paper toggled to same status | — | — | ⬜ |
| TC-P26 | AJAX Get Paper Details | getPaperDetails(id) returns total_questions and total_marks | — | — | ⬜ |
| TC-P27 | Create Dropdown Excludes Papers With Existing Blueprints | Only papers without blueprints appear in create dropdown | — | — | ⬜ |
| TC-P28 | Full Lifecycle: Create → Show → Edit (Add/Remove) → Trash → Restore | All transitions succeed; data integrity maintained | — | — | ⬜ |
| TC-P29 | Empty State — No Blueprints For Selected Paper | Grid shows "No blueprints found" | — | — | ⬜ |
| TC-P30 | Create Blueprint With Instruction Text | instruction_text saved as TEXT; displayed correctly in show page | — | — | ⬜ |
| TC-P31 | Create Blueprint With Ordinals Defining Section Order | Ordinals 1, 2, 3 set for sections A, B, C; displayed in correct order | — | — | ⬜ |
| TC-P32 | Edit Blueprint With Marks Per Question Null | marks_per_question can be null; total_marks still required and validated | — | — | ⬜ |
| TC-P33 | Bulk Restore After Bulk Destroy | Bulk destroy then bulk restore; blueprints restored with original data intact | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `exam_paper_id` | Validation error: "The exam paper id field is required." | — | — | ⬜ |
| TC-N02 | Required — Empty `blueprints` Array | Validation error: "The blueprints field is required." | — | — | ⬜ |
| TC-N03 | Required — Missing `section_name` In Row | Validation error: "The blueprints.0.section_name field is required." | — | — | ⬜ |
| TC-N04 | Required — Missing `total_questions` In Row | Validation error: "The blueprints.0.total_questions field is required." | — | — | ⬜ |
| TC-N05 | Required — Missing `total_marks` In Row | Validation error: "The blueprints.0.total_marks field is required." | — | — | ⬜ |
| TC-N06 | Required — Missing `ordinal` In Row | Validation error: "The blueprints.0.ordinal field is required." | — | — | ⬜ |
| TC-N07 | Max Length — `section_name` > 50 Characters | Validation error: "The blueprints.0.section_name must not be greater than 50 characters." | — | — | ⬜ |
| TC-N08 | Invalid — `total_questions` < 1 (Zero) | Validation error: "The blueprints.0.total_questions must be at least 1." | — | — | ⬜ |
| TC-N09 | Invalid — `ordinal` < 1 (Zero) | Validation error: "The blueprints.0.ordinal must be at least 1." | — | — | ⬜ |
| TC-N10 | Invalid — `marks_per_question` Negative | Validation error: "The blueprints.0.marks_per_question must be at least 0." | — | — | ⬜ |
| TC-N11 | Invalid — `total_marks` Negative | Validation error: "The blueprints.0.total_marks must be at least 0." | — | — | ⬜ |
| TC-N12 | Invalid — Non-Existent `exam_paper_id` | Validation error: "The selected exam paper id is invalid." | — | — | ⬜ |
| TC-N13 | Invalid — Non-Existent `question_type_id` | Validation error: "The selected question type id is invalid." | — | — | ⬜ |
| TC-N14 | Business — Internal Consistency Failure (Marks Mismatch) | "Total marks (X) must equal Total Questions (Y) x Marks Per Question (Z)." | — | — | ⬜ |
| TC-N15 | Business — Total Questions Mismatch Paper Limit | "The sum of total questions (X) must be exactly equal to the Exam Paper's limit of Y." | — | — | ⬜ |
| TC-N16 | Business — Total Marks Mismatch Paper Limit | "The sum of total marks (X) must be exactly equal to the Exam Paper's limit of Y." | — | — | ⬜ |
| TC-N17 | Business — Edit Blocked By Usage Check | "This blueprint is currently being used in paper set questions. Therefore cannot be edited." | — | — | ⬜ |
| TC-N18 | Business — Update Blocked By Usage Check | "This blueprint is currently being used in paper set questions. Therefore cannot be updated." | — | — | ⬜ |
| TC-N19 | Business — Delete/Destroy Blocked By Usage Check | "This blueprint is currently being used in paper set questions. Therefore cannot be deleted." | — | — | ⬜ |
| TC-N20 | Business — Bulk Destroy Blocked By Usage Check | "Cannot trash blueprints that are being used in paper questions." | — | — | ⬜ |
| TC-N21 | Business — Bulk ForceDelete Blocked By Usage Check | "Cannot permanently delete blueprints that are being used in paper questions." | — | — | ⬜ |
| TC-N22 | Permission 403 — No Blueprint Permissions | 403 Forbidden on all CRUD endpoints without `tenant.exam-blueprint.*` | — | — | ⬜ |
| TC-N23 | Guest Access Redirect | Redirected to /login for all blueprint routes | — | — | ⬜ |
| TC-N24 | Show Blueprint With Invalid ID (404) | 404 error via findOrFail | — | — | ⬜ |
| TC-N25 | Edit Blueprint With Invalid ID (404) | 404 error via findOrFail | — | — | ⬜ |
| TC-N26 | Bulk Destroy With Invalid Paper ID | 404 or error: No blueprints found | — | — | ⬜ |
| TC-N27 | Bulk Restore With Invalid Paper ID | No blueprints to restore; redirect with success (empty restore) | — | — | ⬜ |
| TC-N28 | Bulk ForceDelete With Invalid Paper ID | No blueprints to delete; redirect with success | — | — | ⬜ |
| TC-N29 | Duplicate Section Name Within Paper | UNIQUE constraint violation at DB level (uq_blueprint_section) | — | — | ⬜ |
| TC-N30 | Toggle Status On Non-Existent Blueprint ID | 404 error via findOrFail | — | — | ⬜ |
| TC-N31 | Bulk Toggle Status With No Blueprints Found | JSON error: "No blueprints found." | — | — | ⬜ |
| TC-N32 | AJAX Get Paper Details With Invalid ID | 404 error via findOrFail | — | — | ⬜ |
| TC-N33 | XSS Injection In Section Name | Stored as literal string; Blade `{{ }}` escapes output; no script execution | — | — | ⬜ |
| TC-N34 | Whitespace-Only Section Name | Required validation catches empty/whitespace-only strings | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create Blueprint → Activity Logged | activityLog('Blueprint Stored') logged for exam paper | — | — | ⬜ |
| TC-D02 | B | Update Blueprint → Activity Logged | activityLog('Blueprint Updated') logged | — | — | ⬜ |
| TC-D03 | C | Delete Blueprint → Activity Logged | activityLog('Trashed') logged for individual delete | — | — | ⬜ |
| TC-D04 | D | Bulk Store → Existing Blueprints Soft-Deleted First | store() calls ExamBlueprint::where('exam_paper_id')->delete() before create | — | — | ⬜ |
| TC-D05 | E | Bulk Update → Removed Blueprints ForceDeleted | Existing IDs not in submitted array get ->forceDelete() | — | — | ⬜ |
| TC-D06 | F | Exam Paper Deletion Cascades To Blueprints (CASCADE) | Deleting exam paper cascades to delete all its blueprints | — | — | ⬜ |
| TC-D07 | G | Blueprint Used In PaperSetQuestion Blocks Operations | Usage check returns isUsed=true; edit/update/destroy/bulkDestroy/bulkForceDelete blocked | — | — | ⬜ |
| TC-D08 | H | Bulk ToggleStatus Updates Only Same-Paper Blueprints | Only blueprints with matching exam_paper_id toggled | — | — | ⬜ |
| TC-D09 | I | DB Transaction Rollback On Failure | store() wraps in DB::beginTransaction/commit/rollback; on exception all reverted | — | — | ⬜ |
| TC-D10 | J | Index Groups By Exam Paper With Aggregates | sections_count = COUNT(*), sum_questions, sum_marks, is_active = MAX(is_active) | — | — | ⬜ |
| TC-D11 | K | DB \| P1 \| lms_exam_blueprints table — UNIQUE KEY uq_blueprint_section — Duplicate section_name | Inserting duplicate (exam_paper_id, section_name) at DB level throws integrity constraint violation | — | — | ⬜ |
| TC-D12 | L | Integration \| P1 \| Controller — Gate::authorize('tenant.exam-blueprint.*') — Authorization | Gate called before each operation; without permissions → 403 Forbidden | — | — | ⬜ |
| TC-D13 | M | Integration \| P1 \| Controller — activityLog — Activity Logged After CRUD | 'Blueprint Stored' after create; 'Blueprint Updated' after update; 'Trashed' after destroy; 'Toggled' after toggle | — | — | ⬜ |
| TC-D14 | N | Unit \| P1 \| ExamBlueprint model — belongsTo ExamPaper Relationship | $blueprint->examPaper returns correct ExamPaper; eager loading works | — | — | ⬜ |
| TC-D15 | O | Unit \| P1 \| ExamBlueprint model — belongsTo QuestionType Relationship | $blueprint->questionType returns correct QuestionType; null when FK null | — | — | ⬜ |
| TC-D16 | P | Unit \| P1 \| ExamBlueprint model — SoftDeletes Trait | delete() sets deleted_at; restore() nullifies; withTrashed() includes; onlyTrashed() filters | — | — | ⬜ |
| TC-D17 | Q | Unit \| P1 \| ExamBlueprint model — \$casts | is_active boolean; marks_per_question decimal:2; total_marks decimal:2 | — | — | ⬜ |
| TC-D18 | R | Integration \| P1 \| ExamBlueprintRequest — withValidator Internal Consistency | withValidator adds error when marks_per_question > 0 and total_marks ≠ qCount × marksPerQ | — | — | ⬜ |
| TC-D19 | S | Integration \| P1 \| ExamBlueprintRequest — withValidator Paper Questions Alignment | withValidator adds error when sum of total_questions ≠ paper.total_questions | — | — | ⬜ |
| TC-D20 | T | Integration \| P1 \| ExamBlueprintRequest — withValidator Paper Marks Alignment | withValidator adds error when sum of total_marks ≠ paper.total_marks (tolerance 0.01) | — | — | ⬜ |
| TC-D21 | U | Integration \| P1 \| ExamBlueprintUsageCheckService — isUsed Check | Returns true when PaperSetQuestion references blueprint; false when none | — | — | ⬜ |
| TC-D22 | V | Integration \| P1 \| Controller — index() Grouped Pagination | Grouped query paginates by exam_paper_id, not individual blueprint ID | — | — | ⬜ |
| TC-D23 | W | Integration \| P1 \| Controller — search Filter on index | search filters by examPaper.title LIKE %search% via whereHas | — | — | ⬜ |
| TC-D24 | X | DEV \| P1 \| store() Deletes Existing Before Create | ExamBlueprint::where('exam_paper_id')->delete() called before foreach create loop | — | — | ⬜ |
| TC-D25 | Y | DEV \| P1 \| update() Merges Create/Update/Delete | foreach processes: existing ID → update; no ID → create; array_diff → forceDelete remaining | — | — | ⬜ |
| TC-D26 | Z | Integration \| P1 \| Bulk Restore After Individual Destroy | Individual destroy followed by bulk restore; only that paper's blueprints restored | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Controller — DB Transactions in All Write Operations | store() uses DB::beginTransaction/commit/rollback; update() uses same; destroy() uses same; bulkDestroy/bulkRestore/bulkForceDelete all use transaction | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Request — withValidator Callback for Complex Validation | ExamBlueprintRequest::withValidator adds after-callback for internal consistency + paper alignment checks | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — Activity Logging After Write Operations | store() logs 'Blueprint Stored'; update() logs 'Blueprint Updated'; destroy() logs 'Trashed'; toggleStatus() logs 'Toggled' | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — Usage Check Service Before Edit/Update/Destroy | edit() calls isUsed() before loading form; update() calls isUsed() before processing; destroy()/bulkDestroy()/bulkForceDelete() call isUsed() | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — Create Endpoint Excludes Papers With Existing Blueprints | create() fetches ExamPaper whereNotIn ids that already have blueprints | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — JSON Response After AJAX Calls | toggleStatus(), bulkToggleStatus(), getPaperDetails() return response()->json() with success flag | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Controller — Index Groups by exam_paper_id with Raw Aggregates | index() uses DB::raw('count(*) as sections_count'), DB::raw('sum(total_questions) as sum_questions'), DB::raw('sum(total_marks) as sum_marks'), DB::raw('MAX(is_active) as is_active'), DB::raw('MAX(id) as representative_id'); groupBy('exam_paper_id') | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | Controller — ForceDelete of Removed Rows in update | update() gets existing IDs, computes diff via array_diff, calls forceDelete on removed | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | Controller — Missing Gate Authorization in toggleStatus/bulkToggleStatus/getPaperDetails | toggleStatus(), bulkToggleStatus(), getPaperDetails() do NOT call Gate::authorize('tenant.exam-blueprint.*'); anyone with route access can call these — verify if intentional or bug | — | — | ◌ |
| TC-CR10 | CR | Code Review | P1 | Controller — bulkDestroy Usage Check Only Checks First Blueprint | bulkDestroy calls isUsed() only on $firstBlueprint->id; if first is unused but others are used, all get trashed anyway | — | — | ◌ |
| TC-CR11 | CR | Code Review | P1 | Controller — store() Deletes Existing Without Usage Check | store() calls ExamBlueprint::where('exam_paper_id')->delete() before creating; no usage check for existing blueprints | — | — | ◌ |
| TC-CR12 | CR | Code Review | P1 | Controller — bulkRestore Without Usage Check | bulkRestore() restores all trashed blueprints for a paper without calling usage check | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Controller — DB Transactions in All Write Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamBlueprintController.php | Controller found in Modules/LmsExam/Http/Controllers/ |
| 2 | Inspect store() method | DB::beginTransaction() before delete+create; DB::commit() after; DB::rollBack() on exception |
| 3 | Inspect update() method | DB::beginTransaction() before processing; DB::commit() after; DB::rollBack() on exception |
| 4 | Inspect destroy() method | DB::beginTransaction() before delete; DB::commit() after; DB::rollBack() on exception |
| 5 | Inspect bulkDestroy() method | DB::beginTransaction() before delete; DB::commit() after; DB::rollBack() on exception |
| 6 | Inspect bulkRestore() method | DB::beginTransaction() before restore; DB::commit() after; DB::rollBack() on exception |
| 7 | Inspect bulkForceDelete() method | DB::beginTransaction() before forceDelete; DB::commit() after; DB::rollBack() on exception |
| 8 | Inspect toggleStatus() method | DB::beginTransaction() before save; DB::commit() after; DB::rollBack() on exception |

#### TC-CR02: Request — withValidator Callback for Complex Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamBlueprintRequest.php | Request found in Modules/LmsExam/Http/Requests/ |
| 2 | Inspect rules() method | Returns array with exam_paper_id required, blueprints required|array|min:1, per-row validation rules |
| 3 | Inspect withValidator() method | after callback defined; finds ExamPaper; loops blueprints; checks internal consistency; checks paper alignment |
| 4 | Verify internal consistency logic | if marksPerQ > 0 and abs(($qCount * $marksPerQ) - $rowTotalM) > 0.01 → add error |
| 5 | Verify paper questions alignment | if $totalQ != $paper->total_questions → add error |
| 6 | Verify paper marks alignment | if abs($totalM - $paper->total_marks) > 0.01 → add error |

#### TC-P04: Create Blueprint With Single Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Exam Blueprint tab | Page loads |
| 2 | Click "Add Blueprint" button | Create form opens with exam paper dropdown |
| 3 | Verify only papers without existing blueprints shown | List filtered correctly |
| 4 | Select exam paper (total_questions=20, total_marks=50) | Paper selected |
| 5 | Add section row: section_name="Section A", total_questions=20, marks_per_question=2.50, total_marks=50.00, ordinal=1 | Row filled |
| 6 | Click "Save Blueprints" | POST to `/lms-exam/exam-blueprint/store` |
| 7 | Check response | "Exam Blueprints saved successfully." |
| 8 | DB check: `SELECT * FROM lms_exam_blueprints WHERE exam_paper_id={id}` | 1 record; section_name='Section A'; total_questions=20; total_marks=50.00 |

#### TC-P05: Create Blueprint With Multiple Sections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open add blueprint form for paper (total_questions=20, total_marks=50) | Form visible |
| 2 | Add 3 section rows | Rows added |
| 3 | Section A: questions=10, marks_per_q=1, total_marks=10, ordinal=1 | Row 1 |
| 4 | Section B: questions=5, marks_per_q=2, total_marks=10, ordinal=2 | Row 2 |
| 5 | Section C: questions=5, marks_per_q=6, total_marks=30, ordinal=3 | Row 3 (sum: 20Q, 50M) |
| 6 | Click "Save Blueprints" | POST to store |
| 7 | Check response | "Exam Blueprints saved successfully." |
| 8 | DB check: 3 records created | All correct |

#### TC-P14: Business — Internal Consistency Failure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open add blueprint form for paper | Form visible |
| 2 | Add section: total_questions=10, marks_per_question=2, total_marks=25 | 10 × 2 = 20 ≠ 25 |
| 3 | Click "Save Blueprints" | Validation fails |
| 4 | Error response | "Total marks (25) must equal Total Questions (10) x Marks Per Question (2)." |

#### TC-N15: Business — Total Questions Mismatch Paper Limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open add blueprint form for paper (total_questions=20) | Form visible |
| 2 | Add section with total_questions=15 | Sum = 15 ≠ 20 |
| 3 | Click "Save Blueprints" | Validation fails |
| 4 | Error response | "The sum of total questions (15) must be exactly equal to the Exam Paper's limit of 20." |

#### TC-N16: Business — Total Marks Mismatch Paper Limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open add blueprint form for paper (total_marks=50) | Form visible |
| 2 | Add section with total_marks=45.00 | Sum = 45 ≠ 50 |
| 3 | Click "Save Blueprints" | Validation fails |
| 4 | Error response | "The sum of total marks (45) must be exactly equal to the Exam Paper's limit of 50." |

#### TC-N17: Business — Edit Blocked By Usage Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create blueprint for paper | Blueprint exists with ID=X |
| 2 | Create PaperSetQuestion linking to blueprint X | Usage created |
| 3 | Navigate to edit for blueprint X | Controller calls isUsed(X) |
| 4 | Error response | "This blueprint is currently being used in paper set questions. Therefore cannot be edited." |
| 5 | Verify redirect back to index | Edit form not shown |

#### TC-P26: AJAX Get Paper Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam paper with total_questions=20, total_marks=50 | Paper exists with ID=X |
| 2 | Call AJAX GET `/lms-exam/exam-blueprint/paper-details/{X}` | JSON response |
| 3 | Verify total_questions=20 | Correct value returned |
| 4 | Verify total_marks=50 | Correct value returned |

#### TC-P27: Create Dropdown Excludes Papers With Existing Blueprints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Paper A (no blueprints), Paper B (has blueprints) | Both papers exist |
| 2 | Navigate to create blueprint | Form loads |
| 3 | Check exam paper dropdown | Paper A visible, Paper B NOT visible |
| 4 | Verify controller logic | create() uses whereNotIn(ids) with ExamBlueprint::pluck('exam_paper_id') |

#### TC-P20: Bulk Delete (Soft Delete) All Sections For Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 blueprints for Paper A | 3 records exist |
| 2 | Click "Delete" bulk action for Paper A | POST to bulkDestroy |
| 3 | Check response | "All blueprints for the paper moved to trash." |
| 4 | DB check: `SELECT COUNT(*) FROM lms_exam_blueprints WHERE exam_paper_id={A_id} AND deleted_at IS NULL` | 0 active records |
| 5 | DB check: `SELECT COUNT(*) FROM lms_exam_blueprints WHERE exam_paper_id={A_id} AND deleted_at IS NOT NULL` | 3 soft-deleted records |

#### TC-P22: Bulk Restore All Sections For Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Continue from TC-P20 (3 blueprints in trash) | Soft-deleted |
| 2 | Navigate to trash view | Grouped view shows Paper A with 3 deleted |
| 3 | Click "Restore" for Paper A | POST to bulkRestore/{A_id} |
| 4 | Check response | "All blueprints for the paper restored." |
| 5 | DB check: deleted_at IS NULL for all 3 | Restored |

#### TC-D11: UNIQUE KEY uq_blueprint_section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create blueprint with section_name="Section A" for Paper X | Record exists |
| 2 | Try to create another blueprint with section_name="Section A" for same Paper X | DB throws integrity constraint violation |
| 3 | Verify UNIQUE KEY in DDL | `UNIQUE KEY uq_blueprint_section (exam_paper_id, section_name)` present |
| 4 | Verify same section name allowed for different paper | Creation succeeds |

#### TC-P11: Create Blueprint Replaces Existing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 blueprints for Paper A (Section X, Section Y) | 2 records exist |
| 2 | Open create form for Paper A | Form loads (Paper A appears in dropdown because...?) |
| 3 | Actually, Paper A should NOT appear if blueprints exist | This tests the case where Paper A still appears or admin uses store directly |
| 4 | Submit store for Paper A with 3 new sections (Section P, Q, R) | Store processes |
| 5 | DB check: Old sections X, Y soft-deleted | deleted_at set |
| 6 | DB check: New sections P, Q, R created | Active records |

#### TC-P24: Toggle Status Individual

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create blueprint with is_active=1 | Active |
| 2 | Call toggleStatus for that blueprint | is_active flips to 0 |
| 3 | Check JSON response | success: true, is_active: false |
| 4 | Call toggleStatus again | is_active flips back to 1 |
| 5 | Check JSON response | success: true, is_active: true |

#### TC-P25: Bulk Toggle Status — All Sections For Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 blueprints for Paper A (is_active=1) | All active |
| 2 | Call bulkToggleStatus for Paper A | All toggled to 0 |
| 3 | Check JSON response | success: true, is_active: false |
| 4 | DB check: all 3 blueprints have is_active=0 | Bulk updated |
| 5 | Call bulkToggleStatus again | All toggled back to 1 |

#### TC-P14: Load Edit Form With Existing Blueprints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 blueprints for Paper A: "Section A" (10Q, 20M), "Section B" (10Q, 30M) | 2 records |
| 2 | Click "Edit" on any blueprint of Paper A | Edit form loads |
| 3 | Verify both "Section A" and "Section B" displayed | Both rows visible with correct data |
| 4 | Verify form allows adding new rows, editing existing, removing rows | All actions available |
| 5 | Verify usage check ran (no usage) | Form loads without block message |

#### TC-P17: Edit Blueprint — Remove Existing Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | While editing Paper A with sections "A" and "B" | Edit form with 2 rows |
| 2 | Remove "Section B" row from form (click remove) | Row removed |
| 3 | Keep "Section A" row unchanged | Row preserved |
| 4 | Submit edit | POST with 1 section (A) |
| 5 | Check response | "Exam Blueprints updated successfully." |
| 6 | DB check: "Section B" forceDeleted | Record permanently removed |
| 7 | DB check: "Section A" still exists | Preserved |

#### TC-P18: Edit Blueprint — Create, Update, Delete Simultaneously

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper A has 3 blueprint sections: S1 (10Q, 20M), S2 (5Q, 10M), S3 (5Q, 20M) | 3 records |
| 2 | Open edit for Paper A | All 3 sections shown |
| 3 | Update S1: change total_questions from 10 to 8, total_marks from 20 to 16 | S1 modified |
| 4 | Keep S2 unchanged | S2 preserved |
| 5 | Remove S3 row from form | S3 removed from UI |
| 6 | Add new section S4: total_questions=7, marks_per_question=2, total_marks=14, ordinal=4 | New row |
| 7 | Submit edit with 3 sections: S1(updated), S2(unchanged), S4(new) | POST |
| 8 | Check response message | Structure implied by code |
| 9 | DB check: S1 updated | Modified |
| 10 | DB check: S2 unchanged | Preserved |
| 11 | DB check: S3 forceDeleted | Permanently gone |
| 12 | DB check: S4 created | New record |

#### TC-P04: Create Blueprint With Single Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Exam Blueprint tab | Page loads |
| 2 | Click "Add Blueprint" button | Create form opens |
| 3 | Verify exam paper dropdown shows only papers without blueprints | Filtered correctly |
| 4 | Select exam paper (total_questions=20, total_marks=50) | Paper selected |
| 5 | Add section: section_name="Section A", total_questions=20, marks_per_question=2.50, total_marks=50.00, ordinal=1 | Row filled |
| 6 | Click "Save Blueprints" | POST to store |
| 7 | Check response | "Exam Blueprints saved successfully." |
| 8 | DB check: `SELECT * FROM lms_exam_blueprints WHERE exam_paper_id={id}` | 1 record with correct values |

#### TC-P05: Create Blueprint With Multiple Sections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select exam paper (total_questions=20, total_marks=50) | Paper selected |
| 2 | Add 3 sections | 3 rows |
| 3 | Section A: questions=10, marks_per_q=1, total_marks=10, ordinal=1 | Row 1 complete |
| 4 | Section B: questions=5, marks_per_q=2, total_marks=10, ordinal=2 | Row 2 complete |
| 5 | Section C: questions=5, marks_per_q=6, total_marks=30, ordinal=3 | Row 3 complete (sum: 20Q, 50M) |
| 6 | Click "Save Blueprints" | POST |
| 7 | Check response | "Exam Blueprints saved successfully." |
| 8 | DB check: 3 records created | All correct |

#### TC-P06: Create Blueprint With All Optional Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Select exam paper | Paper selected |
| 3 | Add section: section_name="Section A - Objective" | Name filled |
| 4 | Select question type (MCQ) | question_type_id set |
| 5 | Enter instruction_text = "Choose the best answer for each question." | Instruction filled |
| 6 | Enter total_questions=10, marks_per_question=1, total_marks=10, ordinal=1 | All numeric fields |
| 7 | Click "Save Blueprints" | POST |
| 8 | DB check: question_type_id set, instruction_text saved | Optional fields saved |

#### TC-P10: Create Blueprint With Internal Consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select exam paper (any total_questions, total_marks) | Paper selected |
| 2 | Add section: total_questions=10, marks_per_question=2, total_marks=20 | 10 × 2 = 20 ✓ |
| 3 | Add section: total_questions=5, marks_per_question=3, total_marks=15 | 5 × 3 = 15 ✓ |
| 4 | Click "Save Blueprints" | Validation passes |
| 5 | Both sections created | Success |

#### TC-P12: Show Blueprint Details Page With All Sections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 blueprints for Paper A: Section A (10Q, 20M), Section B (10Q, 30M) | 2 records |
| 2 | Click "View" on any blueprint row | Show page loads |
| 3 | Verify all 2 sections displayed | Both sections visible |
| 4 | Verify each section shows section_name, question_type, total_questions, marks_per_question, total_marks, ordinal | All fields |
| 5 | Verify total marks and questions summarized | Sum displayed |

#### TC-P19: Individual Delete (Soft Delete) Single Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 blueprints for Paper A | 2 records |
| 2 | Click "Delete" on one specific blueprint (not bulk) | POST to destroy |
| 3 | Check response | "Exam Blueprint deleted successfully." |
| 4 | DB check: that blueprint has deleted_at set | Soft-deleted |
| 5 | DB check: other blueprint for same paper still active | Not affected |

#### TC-P23: Bulk ForceDelete All Sections For Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 blueprints for Paper A (after soft-deleting them first) | In trash |
| 2 | Navigate to trash page | Grouped view shows Paper A |
| 3 | Click "Permanently Delete" | POST to bulkForceDelete |
| 4 | Check response | "All blueprints for the paper permanently deleted." |
| 5 | DB check: `SELECT * FROM lms_exam_blueprints WHERE exam_paper_id={A_id} AND deleted_at IS NOT NULL` | 0 records (all forceDeleted) |

#### TC-P28: Full Lifecycle: Create → Show → Edit → Trash → Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 blueprints for Paper A | Created |
| 2 | Show page: verify all sections displayed | Show works |
| 3 | Edit: change section B's marks from 30 to 25, add section C | Edit + update works |
| 4 | Bulk destroy (trash) all blueprints for Paper A | Moved to trash |
| 5 | Restore all blueprints for Paper A | Restored |
| 6 | Verify data integrity: sections A, B, C exist with correct data | All preserved |

#### TC-P29: Empty State — No Blueprints For Selected Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Blueprint tab with no filters | Page loads |
| 2 | If no blueprints exist, empty message shown | "No blueprints found" |
| 3 | Verify "Add Blueprint" button visible | Button present |
| 4 | Create first blueprint | Created |
| 5 | Verify grid now shows the blueprint | Empty state gone |

#### TC-P30: Create Blueprint With Instruction Text

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with instruction_text = "Answer all questions. Each question carries 1 mark." | Instruction set |
| 2 | DB check: instruction_text saved as TEXT | Correct |
| 3 | Show page: verify instruction text displayed | Visible in view |

#### TC-P31: Create Blueprint With Ordinals Defining Section Order

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create sections with ordinals: Section C (ordinal=3), Section A (ordinal=1), Section B (ordinal=2) | Non-sequential order |
| 2 | DB check: all 3 with correct ordinals | Stored correctly |
| 3 | Show page: sections ordered by ordinal ascending | Section A → B → C |

#### TC-P33: Bulk Restore After Bulk Destroy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 blueprints for Paper A | Active |
| 2 | Bulk destroy (soft delete) | In trash |
| 3 | Navigate to trash, click "Restore" for Paper A | POST to bulkRestore |
| 4 | DB check: deleted_at = NULL for both | Restored |
| 5 | Verify original data: section_name, total_questions, total_marks preserved | Data intact |

#### TC-N01: Required — Missing exam_paper_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to store without exam_paper_id | Missing field |
| 2 | Include blueprints array with 1 valid section | Valid row |
| 3 | Validation error on exam_paper_id | "The exam paper id field is required." |

#### TC-N04: Required — Missing total_questions In Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with blueprints array missing total_questions in one row | Missing field |
| 2 | Validation error | "The blueprints.0.total_questions field is required." |

#### TC-N07: Max Length — section_name > 50 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with section_name of 51 characters | Exceeds max |
| 2 | Validation error | "The blueprints.0.section_name must not be greater than 50 characters." |

#### TC-N11: Invalid — total_marks Negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with total_marks = -10 | Negative |
| 2 | Validation error | "The blueprints.0.total_marks must be at least 0." |

#### TC-N14: Business — Internal Consistency Failure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Section: total_questions=10, marks_per_question=2, total_marks=30 | 10×2=20 ≠ 30 |
| 2 | Validation error via withValidator | "Total marks (30) must equal Total Questions (10) x Marks Per Question (2)." |

#### TC-N15: Business — Total Questions Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper has total_questions=20 | Paper configured |
| 2 | Add single section with total_questions=15 | Sum = 15 ≠ 20 |
| 3 | withValidator validation error | "The sum of total questions (15) must be exactly equal to the Exam Paper's limit of 20." |

#### TC-N16: Business — Total Marks Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper has total_marks=50 | Paper configured |
| 2 | Add section with total_marks=45.00 | Sum = 45 ≠ 50 |
| 3 | withValidator validation error | "The sum of total marks (45) must be exactly equal to the Exam Paper's limit of 50." |

#### TC-N17: Business — Edit Blocked By Usage Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create blueprint | Blueprint exists |
| 2 | Create PaperSetQuestion linking to this blueprint | Usage exists |
| 3 | Navigate to edit | isUsed() returns true |
| 4 | Redirect with error | "This blueprint is currently being used in paper set questions. Therefore cannot be edited." |

#### TC-N21: Business — Bulk ForceDelete Blocked By Usage Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create blueprint linked to PaperSetQuestion | Used blueprint |
| 2 | Soft delete it (bulkDestroy) | In trash |
| 3 | Try bulkForceDelete | Usage check: isUsed() true |
| 4 | Error response | "Cannot permanently delete blueprints that are being used in paper questions." |

#### TC-N22: Permission 403 — No Blueprint Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without tenant.exam-blueprint.* | Restricted user |
| 2 | Access index page | 403 Forbidden |
| 3 | POST to store | 403 Forbidden |
| 4 | Access edit page | 403 Forbidden |
| 5 | DELETE to destroy | 403 Forbidden |

#### TC-D01: Create Blueprint → Activity Logged

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 blueprints for Paper A | Success |
| 2 | Query activity_log table | Entry found |
| 3 | Verify event = 'Blueprint Stored' | Correct event |
| 4 | Verify message contains paper title | Context logged |
| 5 | Verify performed_by = current user | User logged |

#### TC-D04: Bulk Store → Existing Blueprints Soft-Deleted First

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 1 blueprint for Paper A (Section X) | 1 existing |
| 2 | Submit store with 2 new blueprints (Section P, Q) | POST |
| 3 | DB check: Section X has deleted_at set | Existing soft-deleted |
| 4 | DB check: Section P and Q created, active | New records |
| 5 | Verify controller: `ExamBlueprint::where('exam_paper_id')->delete()` called before foreach | Code confirmed |

#### TC-D05: Bulk Update → Removed Blueprints ForceDeleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper A has blueprints S1, S2, S3 (IDs 1, 2, 3) | 3 records |
| 2 | Submit update with only S1 and S2 (remove S3) | POST |
| 3 | DB check: S3 forceDeleted | Permanently removed |
| 4 | DB check: S1, S2 still active | Preserved |
| 5 | Verify controller: `$existingBlueprints->except($submittedBlueprintIds)->each(forceDelete)` | Code confirmed |

#### TC-D06: Exam Paper Deletion Cascades To Blueprints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with 2 blueprints | Paper + 2 blueprints |
| 2 | Delete exam paper | Paper deleted |
| 3 | DB check: blueprints cascaded-deleted | No records found |
| 4 | Verify DDL: ON DELETE CASCADE on fk_eb_exam | Confirmed |

#### TC-D09: DB Transaction Rollback On Failure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST store() with valid data but mock exception after first create | Exception |
| 2 | Verify rollBack() called | Transaction rolled back |
| 3 | DB check: no partial blueprints created | 0 records |

#### TC-D11: UNIQUE KEY uq_blueprint_section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create blueprint with section_name="Section A" for Paper X | Record exists |
| 2 | Try to insert duplicate (exam_paper_id=X, section_name="Section A") at DB level | Integrity constraint violation |
| 3 | Verify UNIQUE KEY in DDL | `UNIQUE KEY uq_blueprint_section (exam_paper_id, section_name)` |
| 4 | Same section_name allowed for different paper | Succeeds |

#### TC-D12: Gate Authorization Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect each controller method | Gate::authorize() called |
| 2 | Verify viewAny on index() | Present |
| 3 | Verify create on create() and store() | Present |
| 4 | Verify update on edit() and update() | Present |
| 5 | Verify delete on destroy() and bulkDestroy() | Present |
| 6 | Test without permission | 403 Forbidden |

#### TC-D14: ExamBlueprint model — belongsTo ExamPaper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper + blueprint | Blueprint exists |
| 2 | Access $blueprint->examPaper | Returns ExamPaper model |
| 3 | Verify relationship type | belongsTo |
| 4 | Test eager loading: ExamBlueprint::with('examPaper')->get() | 1 query |
| 5 | Test with null relation (blueprint without paper) | Not possible (FK NOT NULL) |

#### TC-D15: ExamBlueprint model — belongsTo QuestionType

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create blueprint with question_type_id set | Blueprint with type |
| 2 | Access $blueprint->questionType | Returns QuestionType model |
| 3 | Verify null when question_type_id is null | Returns null |
| 4 | Test eager loading | Works |

#### TC-D18: ExamBlueprintRequest — withValidator Internal Consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamBlueprintRequest.php | File found |
| 2 | Inspect withValidator callback | After validation callback |
| 3 | Verify floor/abs tolerance logic | abs(($qCount * $marksPerQ) - $rowTotalM) > 0.01 |
| 4 | Verify error field indexed: `blueprints.{$index}.total_marks` | Correct field |
| 5 | Verify callback returns early if paper not found | Guard condition |

#### TC-D21: ExamBlueprintUsageCheckService — isUsed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create blueprint NOT used in PaperSetQuestions | No usage |
| 2 | Call isUsed() | Returns false |
| 3 | Create PaperSetQuestion linking to blueprint | Usage created |
| 4 | Call isUsed() | Returns true |
| 5 | Verify getUsageCount() returns 1 | Count correct |
| 6 | Verify getUsageMessage() includes count | Message generated |

### 7.3 Additional Negative Test Cases

#### TC-N15: Bulk Store — Blueprint Marks Exceed Paper Total

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper P1 has total_marks=50 | Paper config set |
| 2 | POST bulkStore with blueprints summing to 60 marks | Exceeds total |
| 3 | withValidator callback catches excess | Validation added |
| 4 | Error response | Total marks limit exceeded |

#### TC-N16: Bulk Store — Duplicate Blueprint Entry

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blueprint exists for Paper P1, QType QT1 | First record |
| 2 | POST bulkStore with same Paper P1, QType QT1 | Duplicate |
| 3 | Validation error | Blueprint for this question type already exists |

#### TC-N17: Bulk Update — Remove Blueprint Referenced In Questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blueprint B1 is used by PaperSetQuestion PSQ1 | Dependency exists |
| 2 | POST bulkUpdate that excludes B1 | Blueprint would be removed |
| 3 | UsageCheckService blocks deletion | Cannot remove, dependency exists |

#### TC-N18: Toggle Status On Non-Existent Blueprint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call toggleStatus with blueprint_id=99999 | Not found |
| 2 | AJAX response | success: false, error message |

#### TC-N19: Bulk Store — Zero Question Count Not Allowed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST bulkStore with blueprints[0].question_count = 0 | Zero count |
| 2 | Validation error | Question count must be at least 1 |

#### TC-N20: Bulk Store — Negative Marks Not Allowed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST bulkStore with blueprints[0].marks_per_question = -5 | Negative marks |
| 2 | Validation error | Marks per question must be positive |

### 7.4 Additional Positive Test Cases

#### TC-P33: Bulk Store With Multiple Blueprint Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to bulk create form | Form loads |
| 2 | Add Blueprint row 1: QType=MCQ, qCount=5, marks=2, total=10 | Row added |
| 3 | Add Blueprint row 2: QType=Short, qCount=3, marks=5, total=15 | Row added |
| 4 | Add Blueprint row 3: QType=Long, qCount=2, marks=10, total=20 | Row added |
| 5 | Verify grand total = 10+15+20 = 45 ≤ paper total | Auto-calculated |
| 6 | Click Store | POST |
| 7 | DB check: 3 blueprint records created | All inserted |
| 8 | Verify activityLog(Stored) created | Logged |

#### TC-P34: Bulk Update With Reorder

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blueprints B1, B2, B3 exist in order | Original order |
| 2 | Navigate to edit form | Form pre-filled |
| 3 | Reorder blueprints via drag-and-drop | Sorting updated |
| 4 | Modify B2 question_count from 5 to 8 | Row updated |
| 5 | Submit bulk update | POST |
| 6 | DB check: B2.question_count = 8, sequencing fixed | Updated |

### 7.5 Code Review Test Cases

#### TC-CR01: Bulk Transaction Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() method | beginTransaction at start |
| 2 | Delete old blueprints | Blueprint::where deleted |
| 3 | Insert new blueprints in loop | Each inserted |
| 4 | commit() / rollBack() | Transaction boundaries correct |

#### TC-CR02: Bulk Update Delta Tracking

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect update() method | db::beginTransaction |
| 2 | Verify old records fetched for audit | Original data retrieved |
| 3 | Compare old vs new for changes | Diff computed |
| 4 | activityLog(Updated) with changes | Changes logged |

#### TC-CR03: Index Filtering Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index() filters | exam_paper_id filter |
| 2 | Verify exam_paper_id filter | where clause |
| 3 | Verify is_active filter | where clause |
| 4 | Verify pagination | 10 per page |
| 5 | Verify with('examPaper') eager load | Relation loaded |

#### TC-CR04: withValidator Internal Consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamBlueprintRequest.php | withValidator defined |
| 2 | Verify question_count * marks calculation | Auto-calc |
| 3 | Verify tolerance check (0.01) for float comparison | Precision handling |
| 4 | Verify paper existence check | Guard clause |

#### TC-CR05: Soft Delete And Restore Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect destroy() | is_active=false before delete |
| 2 | Inspect restore() | is_active=true after restore |
| 3 | Verify global scope on model | Active records only |
| 4 | Verify trash view uses withTrashed | Includes soft-deleted |

#### TC-CR06: Usage Check Integration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect ExamBlueprintUsageCheckService | isUsed method |
| 2 | Verify counts from PaperSetQuestions | hasMany through |
| 3 | Verify getUsageMessage formatting | Human readable |
| 4 | Check integration in destroy() | Used before deletion |

#### TC-P35: View Single Blueprint Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to index page | Grid visible |
| 2 | Click View on blueprint row | Show page loads |
| 3 | Verify exam_paper title | Displayed |
| 4 | Verify question_type name | Displayed |
| 5 | Verify question_count | Displayed |
| 6 | Verify marks_per_question | Displayed |
| 7 | Verify total_marks (calculated) | Displayed |
| 8 | Verify is_active status | Badge shown |

#### TC-P36: Edit Form Loads With Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create blueprint with 3 rows | 3 rows exist |
| 2 | Navigate to edit for exam paper | Edit form loads |
| 3 | Verify blueprints array populated | Pre-filled |
| 4 | Verify each row: qtype, count, marks auto-calculated | Correct |
| 5 | Verify grand total shown | Sum displayed |

#### TC-P37: Bulk Update — Add And Remove Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit 2 existing rows, add 1 new row, remove 1 row | Mixed ops |
| 2 | Submit bulk update | POST |
| 3 | DB check: 2 final rows (1 retained, 1 new) | Correct |

#### TC-P38: Toggle Blueprint Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create blueprint is_active=1 | Active |
| 2 | ToggleStatus via AJAX | Toggled |
| 3 | Verify is_active flips | Works both ways |

#### TC-P39: Restore Deleted Blueprint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete blueprint | In trash |
| 2 | Navigate to trash, click Restore | POST |
| 3 | DB check: deleted_at=null, is_active=1 | Restored |

#### TC-P40: Force Delete Blueprint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete blueprint first | In trash |
| 2 | Click Permanently Delete | forceDelete |
| 3 | DB check: record permanently gone | Removed |

#### TC-P41: Index Filter By Exam Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blueprints for Paper A (2) and Paper B (3) exist | 5 total |
| 2 | Filter Paper A | 2 blueprints shown |
| 3 | Clear filter | All 5 shown |

#### TC-P42: Index Filter By Is Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 4 active + 1 inactive blueprints | Mixed |
| 2 | Filter is_active=1 | 4 shown |
| 3 | Filter is_active=0 | 1 shown |
| 4 | Clear filter | All shown |

#### TC-P43: Filter By Question Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blueprints with QType=MCQ (2), Short (1), Long (1) | 4 total |
| 2 | Filter QType=MCQ | 2 blueprints shown |

#### TC-P44: Trash View Loads Deleted Blueprints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete 2 blueprints | Deleted |
| 2 | Navigate to trash view | 2 deleted shown |
| 3 | Active blueprints not shown | Only trashed |

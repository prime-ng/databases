# lms_exam_scope_TcList

## Module: LmsExam → Creation & Allocation → Exam Scope

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Creation & Allocation |
| Feature | Exam Scope |
| URL(s) | `/lms-exam/creation-allocation` (index via tab), `/lms-exam/exam-scope/create` (create), `/lms-exam/exam-scope/store` (store bulk), `/lms-exam/exam-scope/{id}` (show), `/lms-exam/exam-scope/{id}/edit` (edit bulk), `/lms-exam/exam-scope/{id}/update` (update bulk), `/lms-exam/exam-scope/{id}/destroy` (destroy bulk), `/lms-exam/exam-scope/trash/view` (trashed), `/lms-exam/exam-scope/{id}/restore` (restore bulk), `/lms-exam/exam-scope/{id}/force-delete` (forceDelete bulk), `/lms-exam/exam-scope/{id}/toggle-status` (toggleStatus), `/lms-exam/exam-scope/get-exam-paper-details/{id}` (getExamPaperDetails AJAX), `/lms-exam/exam-scope/get-lessons-by-exam-paper` (getLessonsByExamPaper AJAX), `/lms-exam/exam-scope/get-lessons-by-exam` (getLessonsByExam AJAX), `/lms-exam/exam-scope/get-topic-hierarchy` (getTopicHierarchy AJAX) |
| Controller | `Modules\LmsExam\Http\Controllers\ExamScopeController` |
| Model(s) | `Modules\LmsExam\Models\ExamScope` |
| Validation (Create) | Controller-level in `store()` — validates exam_paper_id, scopes array, each row's lesson_id, topic_id, question_type_id, target_question_count, weightage_percent, is_active |
| Validation (Update) | Controller-level in `update()` — validates exam_paper_id, scopes array, scopes.*.id, scopes.*.lesson_id, scopes.*.topic_id, scopes.*.question_type_id, scopes.*.target_question_count, scopes.*.weightage_percent, scopes.*.is_active |
| Permissions | `tenant.exam-scope.viewAny`, `tenant.exam-scope.view`, `tenant.exam-scope.create`, `tenant.exam-scope.update`, `tenant.exam-scope.delete`, `tenant.exam-scope.restore`, `tenant.exam-scope.forceDelete` |
| Soft Deletes | Yes (`ExamScope` uses `SoftDeletes` trait; `destroy()` soft-deletes all scopes for exam paper) |
| Activity Log | Events: `Created`, `Toggled`, `Trashed`, `Restored`, `Deleted` |
| Bulk Operations | All CRUD operates on ALL scopes for an exam paper at once (not individual scope) |
| Usage Service | `ExamScopeUsageCheckService` — checks allocations, paper sets, blueprints, results, attempts |

---

## 2. Pre-conditions

- Required permissions: `tenant.exam-scope.viewAny`, `tenant.exam-scope.view`, `tenant.exam-scope.create`, `tenant.exam-scope.update`, `tenant.exam-scope.delete`, `tenant.exam-scope.restore`, `tenant.exam-scope.forceDelete`
- Required seed data: At least one active `ExamPaper`, one active `Lesson`, one active `Topic`, one active `QuestionType`
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For bulk store tests: At least 2 lessons, 2 topics, 2 question types available for selection
- For scope validation tests: Exam paper with `total_questions` set (e.g., 10) and `total_marks` set
- For usage check tests: Exam paper with allocations or student attempts created
- For AJAX tests: Exam paper with class_id and subject_id matching active lessons/topics
- For topic hierarchy tests: At least 3 topics with parent-child relationships at different levels

---

## 3. Default Data Load

When the page loads via Creation & Allocation tab (`active_tab=exam_scope`), the following data is fetched and passed to the view:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Exam Scopes Grid | ExamScopeController@index() | ExamScope::with(examPaper,lesson,topic,questionType)->latest() | Filters: exam_paper_id, lesson_id, topic_id, is_active | 10/page |
| Exam Papers List | ExamScopeController@index() | ExamPaper::where('is_active',true)->orderBy('title') | is_active=1 | None |
| All Lessons | ExamScopeController@index() | Lesson::where('is_active',true)->orderBy('name') | is_active=1 | None |
| Topics (create view) | ExamScopeController@create() | Topic::where('is_active','1')->get() | is_active=1 | None |
| Question Types (create view) | ExamScopeController@create() | QuestionType::where('is_active','1')->get() | is_active=1 | None |
| Exam Papers (create view) | ExamScopeController@create() | ExamPaper::where('is_active','1')->get() | is_active=1 | None |
| Lessons (create view) | ExamScopeController@create() | Lesson::where('is_active','1')->orderBy('name')->get() | is_active=1 | None |
| Topic Level Types (create view) | ExamScopeController@create() | TopicLevelType::where('is_active',true)->get() | is_active=1 | None |

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Scope data**: Each scope row uses lesson_id, topic_id, question_type_id from seed data; target_question_count randomized (1-10)
- **Weightage**: Sum of weightage_percent across scopes must be ≤ 100%
- **Bulk operations**: All operations use exam_paper_id as the grouping key — scopes are never created/edited/deleted individually
- **Cleanup approach**: Delete created scopes by exam_paper_id after tests; forceDelete if soft-deleted
- **Pre-test cleanup**: Delete created exam scopes by exam_paper_id before/after tests to avoid collisions
- **AJAX test data**: Ensure exam paper has class_id and subject_id matching at least 2 active lessons and topics

---

## 5. Business Conditions

### 4.1 Database Schema — `lms_exam_scopes`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | exam_paper_id | INT UNSIGNED FK | NOT NULL, FK → `lms_exam_papers.id`, ON DELETE CASCADE |
| BC-DB-03 | lesson_id | INT UNSIGNED FK NULL | FK → `slb_lessons.id` |
| BC-DB-04 | topic_id | INT UNSIGNED FK NULL | FK → `slb_topics.id` |
| BC-DB-05 | question_type_id | INT UNSIGNED FK NULL | FK → `slb_question_types.id` |
| BC-DB-06 | target_question_count | INT UNSIGNED | NOT NULL DEFAULT 0 |
| BC-DB-07 | weightage_percent | DECIMAL(5,2) NULL | Weightage percentage |
| BC-DB-08 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-09 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-10 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-11 | deleted_at | TIMESTAMP NULL | Soft delete |

### 4.2 Validation Rules — Controller-level Create

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | exam_paper_id | required, exists:lms_exam_papers,id | — |
| BC-VAL-02 | scopes | required, array, min:1 | "No valid scope rows found. Please add at least one scope." |
| BC-VAL-03 | scopes.*.lesson_id | nullable, exists:slb_lessons,id | — |
| BC-VAL-04 | scopes.*.topic_id | nullable, exists:slb_topics,id | — |
| BC-VAL-05 | scopes.*.question_type_id | nullable, exists:slb_question_types,id | — |
| BC-VAL-06 | scopes.*.target_question_count | required, integer, min:0 | — |
| BC-VAL-07 | scopes.*.weightage_percent | nullable, numeric, min:0, max:100 | — |
| BC-VAL-08 | scopes.*.is_active | nullable, boolean | — |
| BC-VAL-09 | Total weightage (controller) | Sum of weightage_percent ≤ 100 | "Total weightage cannot exceed 100%. Current total: X%" |
| BC-VAL-10 | Total questions (controller) | Sum must match paper.total_questions (if set) | "Total target questions (X) must match exam paper total questions (Y)." |
| BC-VAL-11 | At least one scope created | $created > 0 | "No valid scope rows found. Please add at least one scope." |

### 4.3 Validation Rules — Controller-level Update

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | exam_paper_id | required, exists:lms_exam_papers,id | — |
| BC-VAL-U02 | scopes | required, array, min:1 | — |
| BC-VAL-U03 | scopes.*.id | nullable, exists:lms_exam_scopes,id | — |
| BC-VAL-U04 | scopes.*.lesson_id | nullable, exists:slb_lessons,id | — |
| BC-VAL-U05 | scopes.*.topic_id | nullable, exists:slb_topics,id | — |
| BC-VAL-U06 | scopes.*.question_type_id | nullable, exists:slb_question_types,id | — |
| BC-VAL-U07 | scopes.*.target_question_count | required, integer, min:0 | — |
| BC-VAL-U08 | scopes.*.weightage_percent | nullable, numeric, min:0, max:100 | — |
| BC-VAL-U09 | scopes.*.is_active | nullable, boolean | — |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.exam-scope.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.exam-scope.view | show(), getExamPaperDetails() | Without → 403 |
| BC-AUTH-03 | tenant.exam-scope.create | create(), store() | Without → 403 |
| BC-AUTH-04 | tenant.exam-scope.update | edit(), update(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.exam-scope.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.exam-scope.restore | trashed(), restore() | Without → 403 |
| BC-AUTH-07 | tenant.exam-scope.forceDelete | forceDelete() | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Bulk store creates multiple scopes | Each row in the scopes array becomes a new ExamScope record with same exam_paper_id |
| BC-BIZ-02 | Total weightage validation | Sum of ALL scopes' weightage_percent for a paper must not exceed 100% |
| BC-BIZ-03 | Total questions validation | Sum of ALL scopes' target_question_count must exactly match exam_paper.total_questions (if set > 0) |
| BC-BIZ-04 | At least one scope required | If $created === 0 (no valid rows), transaction rolled back with error |
| BC-BIZ-05 | Bulk update with create/edit/delete | Submitted scopes array processed: existing IDs updated, new rows created, removed IDs forceDeleted |
| BC-BIZ-06 | Exam paper totals auto-updated on bulk edit | After bulk update, exam paper's total_questions and total_weightage recalculated from remaining scopes |
| BC-BIZ-07 | Bulk destroy (soft delete) | All scopes for exam_paper_id set is_active=false then delete() called on each |
| BC-BIZ-08 | Bulk restore | All soft-deleted scopes for exam_paper_id restored with is_active=true |
| BC-BIZ-09 | Bulk forceDelete | All scopes (including trashed) for exam_paper_id permanently deleted |
| BC-BIZ-10 | Usage check before restore | ExamScopeUsageCheckService checks allocations/sets/blueprints/results/attempts before restore; blocked if used |
| BC-BIZ-11 | Usage check before forceDelete | Same usage check; blocked if exam paper has allocations, paper sets, blueprints, results, or attempts |
| BC-BIZ-12 | toggleStatus toggles all scopes for a paper | Changing is_active on one scope updates ALL scopes for that exam_paper_id |
| BC-BIZ-13 | AJAX getExamPaperDetails returns paper metadata | Returns total_questions, total_marks, class_id, subject_id for AJAX form population |
| BC-BIZ-14 | AJAX getLessonsByExamPaper filters by paper class+subject | Lessons filtered by exam_paper.class_id and exam_paper.subject_id with is_active=1 |
| BC-BIZ-15 | AJAX getLessonsByExam filters by paper subject | Lessons filtered by exam_paper.subject_id with is_active=1 |
| BC-BIZ-16 | AJAX getTopicHierarchy with multi-level support | Returns topics for a lesson, optionally filtered by level and parent_id; ordered by ordinal then name |
| BC-BIZ-17 | Target count = 0 means "all matching questions" | target_question_count = 0 is valid per FRD BR-EXM-011 |
| BC-BIZ-18 | DB transaction on all bulk operations | Every bulk operation wrapped in DB::beginTransaction/commit/rollback |
| BC-BIZ-19 | Activity log on each created scope | Each scope creation logs individual activity with scope details |
| BC-BIZ-20 | Activity log on each trashed scope | Each scope in bulk delete logs individual trash activity |
| BC-BIZ-21 | Activity log on each restored scope | Each scope in bulk restore logs individual restore activity |
| BC-BIZ-22 | Activity log on forceDelete | Each scope in bulk forceDelete logs individual delete activity |
| BC-BIZ-23 | Activity log on toggleStatus | Each scope logs toggle activity |
| BC-BIZ-24 | Error logging on all operations | Database and general exceptions logged via Log::error |
| BC-BIZ-25 | Show page aggregates scope data | show() calculates grouped data: total_scopes, total_questions, total_lessons, total_topics, total_weightage, min/max/avg |
| BC-BIZ-26 | Show page checks usage | show() calls ExamScopeUsageCheckService and passes isUsed + usageDetails to view |
| BC-BIZ-27 | Edit form loads parent chains for topics | Each scope's topic has parent chain built by traversing up through ancestors |
| BC-BIZ-28 | Trash view groups by exam paper | trashed() groups soft-deleted scopes by exam_paper_id with COUNT, MAX(deleted_at) |
| BC-BIZ-29 | Clean string helper for UTF-8 | cleanString() removes invalid UTF-8 and control characters from AJAX responses |
| BC-BIZ-30 | Scope with null weightage stored correctly | weightage_percent > 0 stored as value; otherwise stored as null (default null) |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | exam_paper_id | lms_exam_papers (id) | CASCADE |
| BC-REF-02 | lesson_id | slb_lessons (id) | RESTRICT (no CASCADE) |
| BC-REF-03 | topic_id | slb_topics (id) | RESTRICT (no CASCADE) |
| BC-REF-04 | question_type_id | slb_question_types (id) | RESTRICT (no CASCADE) |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Exam Scope Index Page Loads With All UI Elements | Page loads with exam paper filter, scope grid grouped by paper, Add Scope button | — | — | ⬜ |
| TC-P02 | Filter Exam Scopes By Exam Paper | Grid displays only scopes belonging to selected exam paper | — | — | ⬜ |
| TC-P03 | Filter Exam Scopes By Lesson | Grid filters to show only scopes with selected lesson | — | — | ⬜ |
| TC-P04 | Filter Exam Scopes By Topic | Grid filters to show only scopes with selected topic | — | — | ⬜ |
| TC-P05 | Filter Exam Scopes By Active Status | Grid filters to show only active/inactive scopes | — | — | ⬜ |
| TC-P06 | Create Single Scope Row With All Fields | One scope row created with lesson, topic, question_type, target_question_count, weightage | — | — | ⬜ |
| TC-P07 | Create Multiple Scope Rows Bulk (2-3 Rows) | All rows created within same exam_paper_id in single transaction | — | — | ⬜ |
| TC-P08 | Create Scope With Zero Target Question Count | target_question_count=0 saved; interpreted as "all matching questions" | — | — | ⬜ |
| TC-P09 | Create Scope With Null Weightage | weightage_percent=null saved; scope tracked without weightage | — | — | ⬜ |
| TC-P10 | Create Scope With Only Required Fields (exam_paper_id, target_question_count) | Scope created with optional fields (lesson, topic, question_type, weightage) as null | — | — | ⬜ |
| TC-P11 | Create Scope With is_active=false | Scope created as inactive; hidden from active-only views | — | — | ⬜ |
| TC-P12 | Show Scope Details Page With Grouped Data | Show page displays total_scopes, total_questions, total_lessons, total_topics, total_weightage, min/max/avg | — | — | ⬜ |
| TC-P13 | Show Scope Details With Usage Information | Show page displays isUsed flag and usage details if exam paper has allocations/attempts | — | — | ⬜ |
| TC-P14 | Load Edit Form With All Existing Scopes Pre-Filled | Edit form displays all scopes for exam paper with lesson, topic, question_type, counts, weightage | — | — | ⬜ |
| TC-P15 | Edit Scope — Update Existing Row | Change target_question_count and weightage for an existing scope; updated successfully | — | — | ⬜ |
| TC-P16 | Edit Scope — Add New Row While Keeping Existing | New scope row added; existing rows preserved; total recalculated | — | — | ⬜ |
| TC-P17 | Edit Scope — Remove Existing Row (Deletion) | Removed scope forceDeleted from database; remaining scopes preserved | — | — | ⬜ |
| TC-P18 | Edit Scope — Create, Update, Delete Simultaneously | Mix of new, edited, and removed rows processed correctly in one transaction | — | — | ⬜ |
| TC-P19 | Edit Scope Auto-Updates Exam Paper Totals | After edit, exam paper total_questions and total_weightage updated to match sum of remaining scopes | — | — | ⬜ |
| TC-P20 | Bulk Delete (Soft Delete) All Scopes For Paper | All scopes for exam paper set is_active=false and soft-deleted | — | — | ⬜ |
| TC-P21 | View Trash Page With Grouped Soft-Deleted Scopes | Trash shows grouped scopes by exam_paper_id with total count and last deleted timestamp | — | — | ⬜ |
| TC-P22 | Bulk Restore All Scopes For Paper | All soft-deleted scopes restored with is_active=true | — | — | ⬜ |
| TC-P23 | Bulk ForceDelete All Scopes For Paper | All scopes (including trashed) permanently deleted from database | — | — | ⬜ |
| TC-P24 | Toggle Status — All Scopes Deactivated | Setting is_active=false on any scope toggles ALL scopes for that exam paper to inactive | — | — | ⬜ |
| TC-P25 | Toggle Status — All Scopes Reactivated | Setting is_active=true toggles ALL scopes back to active | — | — | ⬜ |
| TC-P26 | AJAX Get Exam Paper Details | getExamPaperDetails(id) returns total_questions, total_marks, class_id, subject_id as JSON | — | — | ⬜ |
| TC-P27 | AJAX Get Lessons By Exam Paper | getLessonsByExamPaper filters lessons by exam paper's class_id and subject_id, returns JSON | — | — | ⬜ |
| TC-P28 | AJAX Get Lessons By Exam | getLessonsByExam returns lessons for exam paper's subject_id via JSON | — | — | ⬜ |
| TC-P29 | AJAX Get Topic Hierarchy — Root Level | getTopicHierarchy with lesson_id and no parent returns root topics (parent_id IS NULL) | — | — | ⬜ |
| TC-P30 | AJAX Get Topic Hierarchy — With Level Filter | getTopicHierarchy with level parameter returns topics at specified level | — | — | ⬜ |
| TC-P31 | AJAX Get Topic Hierarchy — With Parent ID | getTopicHierarchy with parent_id returns children of that parent | — | — | ⬜ |
| TC-P32 | Full Lifecycle: Create Scopes → Show → Edit (Add/Remove Rows) → Trash → Restore | All transitions succeed; data integrity maintained throughout | — | — | ⬜ |
| TC-P33 | Empty State — No Exam Paper Selected | Grid shows prompt to select an exam paper | — | — | ⬜ |
| TC-P34 | Empty State — No Scopes For Selected Exam Paper | Grid shows "No scopes found" with Add Scope button visible | — | — | ⬜ |
| TC-P35 | Create Scopes With Total Weightage Exactly 100% | Sum of weightage across all scopes = 100%; creation succeeds | — | — | ⬜ |
| TC-P36 | Create Scopes With Total Questions Matching Exam Paper | Sum of target_question_count exactly equals exam_paper.total_questions; creation succeeds | — | — | ⬜ |
| TC-P37 | Show Page Displays Correct Aggregations | total_scopes count, total_questions sum, total_lessons unique count, total_topics unique count, total_weightage sum all correct | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `exam_paper_id` | Validation error: "The exam paper id field is required." or controller 500 | — | — | ⬜ |
| TC-N02 | Required — Empty `scopes` Array | Validation error: "The scopes field is required." | — | — | ⬜ |
| TC-N03 | Required — Missing `target_question_count` In Row | Validation error: "The scopes.0.target_question_count field is required." | — | — | ⬜ |
| TC-N04 | Invalid — Negative `target_question_count` | Validation error: "The scopes.0.target_question_count must be at least 0." | — | — | ⬜ |
| TC-N05 | Invalid — Weightage > 100% In Single Row | Validation error: "The scopes.0.weightage_percent must not be greater than 100." | — | — | ⬜ |
| TC-N06 | Invalid — Negative Weightage | Validation error: "The scopes.0.weightage_percent must be at least 0." | — | — | ⬜ |
| TC-N07 | Invalid — Total Weightage Exceeds 100% | "Total weightage cannot exceed 100%. Current total: X%" — transaction rolled back | — | — | ⬜ |
| TC-N08 | Invalid — Total Questions Mismatch Paper Limit | "Total target questions (X) must match exam paper total questions (Y)." | — | — | ⬜ |
| TC-N09 | Invalid — Non-Existent `exam_paper_id` (FK) | QueryException or controller catches and returns error | — | — | ⬜ |
| TC-N10 | Invalid — Non-Existent `lesson_id` (FK) | Database error or validation error | — | — | ⬜ |
| TC-N11 | Invalid — Non-Existent `topic_id` (FK) | Database error or validation error | — | — | ⬜ |
| TC-N12 | Invalid — Non-Existent `question_type_id` (FK) | Database error or validation error | — | — | ⬜ |
| TC-N13 | Business — No Valid Scope Rows (All Empty) | "No valid scope rows found. Please add at least one scope." | — | — | ⬜ |
| TC-N14 | Permission 403 — No Exam Scope Permissions | 403 Forbidden on all CRUD endpoints for user without `tenant.exam-scope.*` gates | — | — | ⬜ |
| TC-N15 | Guest Access Redirect | Redirected to /login for all exam scope routes | — | — | ⬜ |
| TC-N16 | Show Scope With Non-Existent Exam Paper ID (404) | 404 error: No scopes found for this exam paper | — | — | ⬜ |
| TC-N17 | Edit Scope With Non-Existent Exam Paper ID | Redirected with error "No scopes found for this exam paper." | — | — | ⬜ |
| TC-N18 | Restore With Usage Check — Paper Has Allocations | "Cannot restore this scope because the exam paper has allocations or student attempts." | — | — | ⬜ |
| TC-N19 | ForceDelete With Usage Check — Paper Has Attempts | "Cannot permanently delete this scope because the exam paper has allocations or student attempts." | — | ⬜ | ⬜ |
| TC-N20 | XSS Injection In AJAX Lesson Name | UTF-8 cleaned; no script execution | — | — | ⬜ |
| TC-N21 | Whitespace-Only Row Data | Validation catches empty/null values | — | — | ⬜ |
| TC-N22 | Toggle Status On Non-Existent Scope ID | 404 error: Model not found | — | — | ⬜ |
| TC-N23 | Update Scope With Invalid `scopes.*.id` | Row ignored or error returned; remaining valid rows processed | — | — | ⬜ |
| TC-N24 | Bulk Update With exam_paper_id Mismatch | Scope update skipped when scope.exam_paper_id != submitted exam_paper_id | — | — | ⬜ |
| TC-N25 | AJAX getTopicHierarchy With Invalid Lesson ID | Empty topics array returned | — | — | ⬜ |
| TC-N26 | AJAX getLessonsByExamPaper With Invalid Paper ID | Error JSON with success=false and error message | — | — | ⬜ |
| TC-N27 | AJAX getExamPaperDetails With Invalid ID | 404 error via findOrFail | — | — | ⬜ |
| TC-N28 | Delete (Trash) Already Deleted Scopes | Soft-deleted scopes cannot be trashed again; findOrFail returns 404 | — | — | ⬜ |
| TC-N29 | Restore Non-Existent Scope | 404 error: onlyTrashed findOrFail fails | — | — | ⬜ |
| TC-N30 | ForceDelete Non-Existent Scope | 404 error: withTrashed findOrFail fails | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create Scope → Activity Log Created | activityLog('Created') logged for each scope with scope details | — | — | ⬜ |
| TC-D02 | B | Bulk Delete → Scopes Trashed With is_active=false | Each scope's is_active set to false before soft delete | — | — | ⬜ |
| TC-D03 | C | Bulk Restore → Scopes Restored With is_active=true | Each scope restored and is_active set back to true | — | — | ⬜ |
| TC-D04 | D | Bulk Edit → Removed Scopes ForceDeleted | Scopes not in submitted array get forceDeleted (hard delete) | — | — | ⬜ |
| TC-D05 | E | Exam Paper Deletion Cascades To Scopes (CASCADE) | Deleting an exam paper automatically deletes all its scopes | — | — | ⬜ |
| TC-D06 | F | Lesson Deletion — Scopes Not Affected (No CASCADE) | DDL has no FK CASCADE on lesson_id; FK constraint stops lesson deletion | — | — | ⬜ |
| TC-D07 | G | Bulk Store Wrapped In DB Transaction | On any error, all created scopes rolled back; no partial data | — | — | ⬜ |
| TC-D08 | H | Bulk Edit Updates Exam Paper Totals | After edit, exam_paper.total_questions and total_weightage match new scope sums | — | — | ⬜ |
| TC-D09 | I | ToggleStatus Updates All Scopes For Paper | Changing status on any scope toggles ALL scopes for that exam_paper_id | — | — | ⬜ |
| TC-D10 | J | AJAX getTopicHierarchy Returns Hierarchical Data | Topics returned with level, level_name, parent_id for cascading dropdowns | — | — | ⬜ |
| TC-D11 | K | Usage Check Service Counts All Dependencies | Allocations, paper sets, blueprints, results, attempts all counted | — | — | ⬜ |
| TC-D12 | L | Show Page Aggregates Correctly Across Multiple Scopes | total_lessons = unique lesson count; total_topics = unique topic count | — | — | ⬜ |
| TC-D13 | M | Edit Form Loads Topic Parent Chain | parent_chain array built for each scope's topic showing full ancestry | — | — | ⬜ |
| TC-D14 | N | Scope With All Null Optional Fields Created | lesson_id, topic_id, question_type_id all nullable; created successfully | — | — | ⬜ |
| TC-D15 | O | DB \| P1 \| lms_exam_scopes table with scope record — exam_paper_id FK CASCADE — Exam Paper Deletion | Deleting an exam paper cascades to delete all its scopes | — | — | ⬜ |
| TC-D16 | P | Integration \| P1 \| Controller — findOrFail — show/edit/destroy/restore/forceDelete with Valid and Invalid IDs | Valid ID loads model successfully; Invalid ID throws ModelNotFoundException | — | — | ⬜ |
| TC-D17 | Q | Integration \| P1 \| Controller — Gate::authorize('tenant.exam-scope.*') — Authorization Before CRUD | Gate called before each operation; without permissions → 403 Forbidden | — | — | ⬜ |
| TC-D18 | R | Integration \| P1 \| Controller — activityLog — Activity Logged After CRUD | Create logged as 'Created'; update as 'Updated'; trash as 'Trashed'; restore as 'Restored'; forceDelete as 'Deleted' | — | — | ⬜ |
| TC-D19 | S | Unit \| P1 \| ExamScope model — belongsTo ExamPaper Relationship | $scope->examPaper returns correct ExamPaper model; eager loading works | — | — | ⬜ |
| TC-D20 | T | Unit \| P1 \| ExamScope model — belongsTo Lesson/Topic/QuestionType Relationships | All three belongsTo relationships return correct models; null when FK is null | — | — | ⬜ |
| TC-D21 | U | Unit \| P1 \| ExamScope model — SoftDeletes Trait | delete() sets deleted_at; restore() nullifies; withTrashed() includes soft-deleted; onlyTrashed() filters | — | — | ⬜ |
| TC-D22 | V | Unit \| P1 \| ExamScope model — \$casts — Boolean and Decimal Casting | is_active stored as TINYINT but accessed as boolean; weightage_percent cast to decimal | — | — | ⬜ |
| TC-D23 | W | Integration \| P1 \| Controller — index() Pagination with Filters Combined | All filters (exam_paper_id, lesson_id, topic_id, is_active) work together with pagination | — | — | ⬜ |
| TC-D24 | X | DEV \| P1 \| cleanString Helper Handles UTF-8/Control Characters | cleanString removes invalid UTF-8, control characters [\x00-\x08\x0B\x0C\x0E-\x1F\x7F]; returns trimmed string | — | — | ⬜ |
| TC-D25 | Y | DEV \| P1 \| Bulk Update with All Three Operations (Create+Update+Delete) | Store processes updated rows (existing ID), new rows (no ID), deletes missing rows; correct counts returned in message | — | — | ⬜ |
| TC-D26 | Z | Integration \| P1 \| getExamDetails Returns total_questions and total_marks | AJAX endpoint returns JSON with total_questions and total_marks for the exam paper | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Controller — DB Transactions in All Bulk Operations | store() uses DB::beginTransaction/commit/rollback; update() uses same; destroy() uses same; restore() uses same; forceDelete() uses same; toggleStatus() also in transaction | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — JSON Success Response After AJAX Calls | All AJAX methods (getTopicHierarchy, getLessonsByExamPaper, getLessonsByExam, getExamPaperDetails) return response()->json() with success flag | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — Activity Logging After Each Bulk Operation | activityLog() called after each scope create/trash/restore/delete in the loop; toggleStatus also logs | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — Error Logging All Exceptions | All catch blocks log via Log::error with exception message, user ID, and request data | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — Usage Check Before Destructive Operations | restore() and forceDelete() call ExamScopeUsageCheckService::isUsed() before proceeding | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | All relationship access in Blade uses optional() or null-safe operators; no undefined index errors when relations null | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Controller — Clean String Helper for UTF-8 Safety | cleanString() handles null, invalid UTF-8 via mb_convert_encoding, strips control characters, trims whitespace | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | Controller — Topic Parent Chain Building in Edit | edit() traverses topic ancestors using while loop until parent_id null; builds chain array with id, name, level, level_name | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Controller — DB Transactions in All Bulk Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamScopeController.php | Controller found in Modules/LmsExam/Http/Controllers/ |
| 2 | Inspect store() method | DB::beginTransaction() before loop; DB::commit() after success; DB::rollBack() in all catch/validation failure blocks |
| 3 | Inspect update() method | DB::beginTransaction() before processing; DB::commit() after success; DB::rollBack() on exception |
| 4 | Inspect destroy() method | DB::beginTransaction() before update+delete; DB::commit() after; DB::rollBack() on exception |
| 5 | Inspect restore() method | DB::beginTransaction() before restore loop; DB::commit() after; DB::rollBack() on exception |
| 6 | Inspect forceDelete() method | DB::beginTransaction() before forceDelete loop; DB::commit() after; DB::rollBack() on exception |
| 7 | Inspect toggleStatus() method | No explicit transaction wrapper found; confirm this is intentional |

#### TC-CR02: Controller — JSON Success Response After AJAX Calls

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamScopeController.php | Controller found |
| 2 | Inspect getExamPaperDetails() | Returns response()->json() with total_questions, total_marks, class_id, subject_id |
| 3 | Inspect getLessonsByExamPaper() | Returns response()->json() with success flag and lessons array |
| 4 | Inspect getLessonsByExam() | Returns response()->json() with lessons array mapped to id/name |
| 5 | Inspect getTopicHierarchy() | Returns response()->json() with topics array containing id, name, level_id, level, level_name, parent_id |
| 6 | Test AJAX endpoint via browser | JSON response received with correct structure |

#### TC-CR03: Controller — Activity Logging After Each Bulk Operation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() loop | activityLog($scope, 'Created', ...) called inside foreach after each scope creation |
| 2 | Inspect destroy() loop | activityLog($scope, 'Trashed', ...) called inside foreach after each scope delete |
| 3 | Inspect restore() loop | activityLog($scope, 'Restored', ...) called inside foreach after each scope restore |
| 4 | Inspect forceDelete() loop | activityLog($scope, 'Deleted', ...) called inside foreach |
| 5 | Inspect toggleStatus() loop | activityLog($scope, 'Toggled', ...) called inside foreach |
| 6 | Verify log data includes scope_details, performed_by, message | All context data present in activity log entry |

#### TC-CR04: Controller — Error Logging All Exceptions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() catch blocks | Two catch blocks: QueryException and Throwable; both call Log::error() |
| 2 | Inspect update() catch blocks | Single catch for Throwable; Log::error() with exception, request, user, exam_paper_id |
| 3 | Inspect destroy() catch blocks | Log::error() with exception, user, scope_id |
| 4 | Inspect restore() catch blocks | Log::error() with exception, user, scope_id |
| 5 | Inspect forceDelete() catch blocks | Log::error() with exception, user, scope_id |
| 6 | Verify log context includes user ID | Auth::user()->id passed in all Log::error calls |

#### TC-CR05: Controller — Usage Check Before Destructive Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect restore() method | ExamScopeUsageCheckService instantiated; isUsed($id) called before proceeding |
| 2 | Inspect forceDelete() method | ExamScopeUsageCheckService instantiated; isUsed($id) called before proceeding |
| 3 | Inspect ExamScopeUsageCheckService | isUsed() checks allocations, paper sets, blueprints, results, attempts count > 0 |
| 4 | Verify restore returns error on usage | back()->with('error', message) returned when isUsed() true |
| 5 | Verify forceDelete returns error on usage | back()->with('error', message) returned when isUsed() true |

#### TC-P01: Exam Scope Index Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Expand "LmsExam" from left sidebar | Menu options appear |
| 3 | Click "Creation & Allocation" and select "Exam Scope" tab | Page loads with `active_tab=exam_scope` parameter |
| 4 | Check the exam paper filter dropdown | Dropdown with list of active exam papers present |
| 5 | Check the lesson filter dropdown | Dropdown with list of active lessons present |
| 6 | Check the topic filter | Topic filter input/dropdown present |
| 7 | Check the active status filter | Active/Inactive/All dropdown present |
| 8 | Check the "Add Scope" button | Button visible (if create permission) |
| 9 | Check the scopes grid | Table with columns: Exam Paper, Lesson, Topic, Question Type, Target Count, Weightage, Status, Actions |
| 10 | Check pagination | Pagination controls visible at bottom |

#### TC-P02: Filter Exam Scopes By Exam Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 scopes under Paper A, 2 scopes under Paper B | Scopes exist |
| 2 | Select Paper A from filter dropdown | Page reloads with `?exam_paper_id={A_id}` |
| 3 | Verify grid shows only Paper A scopes | 3 scopes visible, Paper B scopes not shown |
| 4 | Switch to Paper B filter | Grid shows 2 scopes |
| 5 | Clear filter | All 5 scopes visible |

#### TC-P06: Create Single Scope Row With All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Exam Scope tab | Page loads |
| 2 | Click "Add Scope" button | Scope creation form opens |
| 3 | Select an exam paper from dropdown | Exam paper selected |
| 4 | Click "Add Row" button | New scope row appears |
| 5 | Select lesson from dropdown | Lesson selected |
| 6 | Select topic from AJAX-populated hierarchy | Topic selected |
| 7 | Select question type from dropdown | Question type selected |
| 8 | Enter target question count: 5 | Field filled |
| 9 | Enter weightage: 20.00 | Field filled |
| 10 | Click "Save Scopes" | POST to `/lms-exam/exam-scope/store` |
| 11 | Check response | Success message: "1 exam scope(s) added successfully! Total weightage: 20% Total questions: 5" |
| 12 | DB check: `SELECT * FROM lms_exam_scopes WHERE exam_paper_id={id}` | Record exists; lesson_id, topic_id, question_type_id match; target_question_count=5; weightage_percent=20.00 |

#### TC-P07: Create Multiple Scope Rows Bulk

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open add scope form | Form visible |
| 2 | Select exam paper | Paper selected |
| 3 | Add 3 scope rows | Rows added |
| 4 | Row 1: Lesson A, Topic A, MCQ, target=5, weightage=30% | Row filled |
| 5 | Row 2: Lesson B, Topic B, Short Answer, target=3, weightage=20% | Row filled |
| 6 | Row 3: Lesson A, Topic C, Long Answer, target=2, weightage=10% | Row filled |
| 7 | Click "Save Scopes" | POST with scopes array of 3 items |
| 8 | Check response | "3 exam scope(s) added successfully! Total weightage: 60% Total questions: 10" |
| 9 | DB check: `SELECT COUNT(*) FROM lms_exam_scopes WHERE exam_paper_id={id}` | 3 records created |

#### TC-P09: Create Scope With Null Weightage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open add scope form | Form visible |
| 2 | Select exam paper | Paper selected |
| 3 | Add scope row with target_question_count=5, leave weightage blank | Weightage empty |
| 4 | Click "Save Scopes" | Scope created |
| 5 | DB check: `SELECT weightage_percent FROM lms_exam_scopes WHERE id={new_id}` | weightage_percent = NULL |

#### TC-N07: Invalid — Total Weightage Exceeds 100%

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open add scope form | Form visible |
| 2 | Add 2 scope rows | Rows added |
| 3 | Row 1: target=5, weightage=60% | Row filled |
| 4 | Row 2: target=3, weightage=50% | Sum = 110% > 100% |
| 5 | Click "Save Scopes" | POST to store |
| 6 | Error response | "Total weightage cannot exceed 100%. Current total: 110%" |
| 7 | DB check: No scopes created | Transaction rolled back |

#### TC-N08: Invalid — Total Questions Mismatch Paper Limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure exam paper has total_questions=10 | Paper configured |
| 2 | Open add scope form for that paper | Form visible |
| 3 | Add scope with target_question_count=8 | Sum = 8 ≠ 10 |
| 4 | Click "Save Scopes" | POST to store |
| 5 | Error response | "Total target questions (8) must match exam paper total questions (10)." |
| 6 | DB check: No scopes created | Transaction rolled back |

#### TC-P18: Edit Scope — Create, Update, Delete Simultaneously

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 scopes for Paper A | 3 scopes exist: S1(id=1, target=5), S2(id=2, target=3), S3(id=3, target=2) |
| 2 | Navigate to edit for Paper A | All 3 scopes displayed in edit form |
| 3 | Update S1: change target to 10 | S1 updated in form |
| 4 | Keep S2 unchanged | S2 preserved |
| 5 | Remove S3 from the form | S3 row deleted from form |
| 6 | Add new row S4: target=5 | New row added |
| 7 | Submit edit | POST with 3 items: S1(updated), S2(unchanged), S4(new) |
| 8 | Check response | "1 created, 1 updated, 1 deleted successfully!" |
| 9 | DB check: S1 now has target=10 | Updated |
| 10 | DB check: S2 unchanged | Preserved |
| 11 | DB check: S3 forceDeleted | Record does not exist |
| 12 | DB check: S4 exists with target=5 | Created |
| 13 | DB check: exam_paper totals recalculated | 10+3+5 = 18 total_questions |

#### TC-BIZ-10: Usage Check Before Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam paper with scopes, then create allocation for same paper | Scopes + allocation exist |
| 2 | Delete scopes (soft delete) | Scopes in trash |
| 3 | Try to restore scopes | ExamScopeUsageCheckService checks allocations count |
| 4 | Error response | "Cannot restore this scope because the exam paper has allocations or student attempts." |
| 5 | DB check: Scopes still soft-deleted | Not restored |

#### TC-P29: AJAX Get Topic Hierarchy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create root topic "Algebra" (level=0) and child "Linear Equations" (level=1) under lesson L1 | Topics exist |
| 2 | Call AJAX GET `/lms-exam/exam-scope/get-topic-hierarchy?lesson_id={L1_id}&level=0` | JSON with root topics |
| 3 | Verify root topic "Algebra" returned | id, name, level_id, level=0, level_name='Root', parent_id=null |
| 4 | Call with lesson_id={L1_id}&parent_id={Algebra_id} | JSON with child "Linear Equations" |
| 5 | Verify child has parent_id=Algebra_id | Level=1, level_name='Sub-Topic' |

#### TC-P31: AJAX Get Topic Hierarchy With Parent ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create parent topic P1 with child C1 | Hierarchy exists |
| 2 | Call `/lms-exam/exam-scope/get-topic-hierarchy?lesson_id=L1&parent_id=P1` | Returns C1 as child |
| 3 | Verify C1 has parent_id=P1 | Correct parent reference |
| 4 | Call without parent_id | Returns root topics (parent_id IS NULL or 0) |

#### TC-D15: FK CASCADE — Exam Paper Deletion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam paper with 3 scopes | Paper + 3 scopes exist |
| 2 | Delete the exam paper directly from database or admin | Paper deleted |
| 3 | DB check: `SELECT * FROM lms_exam_scopes WHERE exam_paper_id={deleted_id}` | No records found — cascaded delete |
| 4 | Verify CASCADE constraint in DDL | `ON DELETE CASCADE` on `fk_es_exam` foreign key |

#### TC-P02: Filter Exam Scopes By Exam Paper — Detailed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials and navigate to Creation & Allocation tab | Page loads |
| 2 | Click "Exam Scope" tab | active_tab=exam_scope set |
| 3 | Note default exam paper filter is set to "All" | All scopes visible |
| 4 | Select specific exam paper from the dropdown | Page reloads with exam_paper_id query param |
| 5 | Verify grid updates to show only scopes for that paper | Table rows filtered correctly |
| 6 | Open browser developer tools network tab | Filter request visible |
| 7 | Verify GET request includes exam_paper_id parameter | Query parameter sent |
| 8 | Verify response contains only matching records | Server-side filtering works |
| 9 | Clear the filter by selecting "All" | All scopes visible again |

#### TC-P03: Filter Exam Scopes By Lesson

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure seed data has scopes under different lessons (L1, L2) | Scopes exist |
| 2 | Navigate to Exam Scope tab | Page loads |
| 3 | Select lesson L1 from lesson filter dropdown | Page reloads with lesson_id=L1 |
| 4 | Verify only scopes with lesson_id=L1 displayed | Filtered correctly |
| 5 | Select lesson L2 | Only L2 scopes shown |
| 6 | Select "All" | All scopes visible |

#### TC-P08: Create Scope With Zero Target Question Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Exam Scope tab and click "Add Scope" | Create form opens |
| 2 | Select exam paper | Paper selected |
| 3 | Add scope row: select lesson, topic, question type | Row filled |
| 4 | Set target_question_count = 0 | Zero set |
| 5 | Set weightage = 10% | Weightage set |
| 6 | Click "Save Scopes" | POST to store |
| 7 | Check response | "1 exam scope(s) added successfully!" |
| 8 | DB check: target_question_count = 0 | Zero stored — interpreted as "all matching questions" per FRD BR-EXM-011 |

#### TC-P10: Create Scope With Only Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Scope form | Form visible |
| 2 | Select exam paper | Paper selected |
| 3 | Add scope row with ONLY target_question_count = 5 | All optional fields (lesson, topic, question_type, weightage) left empty |
| 4 | Click "Save Scopes" | POST to store |
| 5 | Check response | Success message |
| 6 | DB check: lesson_id = NULL, topic_id = NULL, question_type_id = NULL, weightage_percent = NULL | All optional fields nullable |

#### TC-P12: Show Scope Details Page With Grouped Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 scopes for Paper A: (target=5, weight=20), (target=3, weight=10), (target=2, weight=5) | 3 scopes exist |
| 2 | Click "View" on any scope row for Paper A | Show page loads |
| 3 | Verify groupedData.total_scopes = 3 | Count correct |
| 4 | Verify groupedData.total_questions = 10 | Sum of targets = 5+3+2 |
| 5 | Verify groupedData.total_weightage = 35.00 | Sum of weights = 20+10+5 |
| 6 | Verify groupedData.total_lessons = unique lesson count | Unique lessons counted |
| 7 | Verify groupedData.total_topics = unique topic count | Unique topics counted |
| 8 | Verify groupedData.min_questions = 2 | Minimum target |
| 9 | Verify groupedData.max_questions = 5 | Maximum target |
| 10 | Verify groupedData.avg_questions = 3.33 | Average target |
| 11 | Verify groupedData.avg_weightage = 11.67 | Average weightage |
| 12 | Verify usage check section shows isUsed status | Usage details displayed |

#### TC-P17: Edit Scope — Remove Existing Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 scopes for Paper A | 2 records exist with IDs S1, S2 |
| 2 | Navigate to edit for Paper A | Edit form shows both scopes |
| 3 | Remove S2 row from the form (click X/remove button) | Row removed from UI |
| 4 | Submit the form | POST with only S1 in scopes array |
| 5 | Check response | "0 created, 1 updated, 1 deleted successfully!" |
| 6 | DB check: S1 still exists with original data | Preserved |
| 7 | DB check: S2 forceDeleted | S2 permanently removed |

#### TC-P19: Edit Scope Auto-Updates Exam Paper Totals

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper A has total_questions=10, total_weightage=100 | Paper totals set |
| 2 | Scopes: 3+3+4=10 questions, 30+30+40=100 weight | Totals match |
| 3 | Edit: change scope 1 target to 5 (now total=12) | Edit submitted |
| 4 | DB check: ExamPaper A total_questions = 12 | Auto-updated |
| 5 | DB check: ExamPaper A total_weightage = 100 | Weightage still 100 |
| 6 | Verify controller code: `$examPaper->update(['total_questions' => $totalQuestions])` | Only changed when different |

#### TC-P20: Bulk Delete (Soft Delete) All Scopes For Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 scopes for Paper A | 3 records exist, is_active=1 |
| 2 | Click "Delete" on Paper A's scope group | POST to destroy |
| 3 | Check response | "Exam scope moved to trash!" |
| 4 | DB check: all 3 scopes have is_active=0 | Deactivated |
| 5 | DB check: all 3 scopes have deleted_at NOT NULL | Soft-deleted |
| 6 | Verify scopes no longer appear in active list | Hidden from index |

#### TC-P22: Bulk Restore All Scopes For Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trash view | Soft-deleted scopes shown grouped by paper |
| 2 | Verify Paper A appears with count=3 and last_deleted_at | Grouped data correct |
| 3 | Click "Restore" for Paper A | POST to restore |
| 4 | Check response | "Exam scope restored successfully!" |
| 5 | DB check: all 3 scopes have deleted_at = NULL | Restored |
| 6 | DB check: all 3 scopes have is_active = 1 | Reactivated |
| 7 | Verify scopes appear in active index | Back in grid |

#### TC-P24: Toggle Status — All Scopes Deactivated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 scopes for Paper A with is_active=1 | Both active |
| 2 | Navigate to index page | Scopes visible |
| 3 | Click status toggle on any scope row | AJAX POST to toggleStatus |
| 4 | Check response | success: true, message: "Status updated for selected scopes" |
| 5 | DB check: ALL scopes for Paper A have is_active=0 | Both scopes toggled |
| 6 | Verify grid shows both scopes as inactive | Status badge updated |

#### TC-P25: Toggle Status — All Scopes Reactivated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Continue from previous test (all scopes inactive) | Both inactive |
| 2 | Click status toggle on any scope | Toggle again |
| 3 | Check response | success: true |
| 4 | DB check: ALL scopes for Paper A have is_active=1 | Both reactivated |
| 5 | Verify toggleStatus($request, $id) code | It finds all scopes with same exam_paper_id and updates all |

#### TC-P26: AJAX Get Exam Paper Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam paper with total_questions=20, total_marks=100, class_id=1, subject_id=2 | Paper exists |
| 2 | Call AJAX GET `/lms-exam/exam-scope/get-exam-paper-details/{id}` | HTTP 200 |
| 3 | Verify JSON response contains total_questions=20 | Correct |
| 4 | Verify JSON response contains total_marks=100 | Correct |
| 5 | Verify JSON response contains class_id=1 | Correct |
| 6 | Verify JSON response contains subject_id=2 | Correct |
| 7 | Test with non-existent ID | HTTP 404 via findOrFail |

#### TC-P27: AJAX Get Lessons By Exam Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam paper with class_id=1, subject_id=2 | Paper exists |
| 2 | Create Lesson A (class=1, subject=2) and Lesson B (class=1, subject=1) | 2 lessons exist |
| 3 | Call AJAX POST getLessonsByExamPaper with exam_paper_id | POST |
| 4 | Verify lessons array includes Lesson A | Included (matches both class+subject) |
| 5 | Verify lessons array does NOT include Lesson B | Excluded (subject=1 != 2) |
| 6 | Clean string verification: Lesson name with special chars | UTF-8 cleaned |

#### TC-P30: AJAX Get Topic Hierarchy — With Level Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create lesson L1 with root topic T1 (level=0) and child T2 (level=1) | Hierarchy exists |
| 2 | Call getTopicHierarchy with lesson_id=L1, level=0 | Only root topics returned |
| 3 | Verify T1 returned with level=0, parent_id=null | Correct |
| 4 | Call getTopicHierarchy with lesson_id=L1, level=1 | Only level 1 topics |
| 5 | Verify T2 returned with level=1, parent_id=T1 | Correct |
| 6 | Verify response includes id, name, level_id, level, level_name, parent_id | All fields present |

#### TC-P33: Empty State — No Exam Paper Selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Exam Scope tab with no filters | Page loads |
| 2 | If no exam_paper_id in URL, grid shows all scopes | Or a prompt message |
| 3 | Verify empty state message when no scopes exist | "No scopes found" message displayed |
| 4 | Verify Add Scope button visible (if create permission) | Button enabled |
| 5 | Select an exam paper with no scopes | Empty state shown |

#### TC-P35: Create Scopes With Total Weightage Exactly 100%

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Scope form for exam paper | Form visible |
| 2 | Add 2 scope rows | 2 rows |
| 3 | Row 1: target=5, weightage=60% | Row 1 set |
| 4 | Row 2: target=5, weightage=40% | Row 2 set (total = 100%) |
| 5 | Click "Save Scopes" | POST |
| 6 | Check response | Success: "2 exam scope(s) added successfully! Total weightage: 100% Total questions: 10" |
| 7 | DB check: both scopes created | Records exist |

#### TC-P36: Create Scopes With Total Questions Matching Exam Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Exam paper with total_questions=10 | Paper configured |
| 2 | Add scopes: row1 target=5, row2 target=3, row3 target=2 | Sum = 10 = paper total |
| 3 | Click "Save Scopes" | POST |
| 4 | Check response | Success message |
| 5 | DB check: 3 scopes created with correct targets | All created |

#### TC-N09: Invalid — Non-Existent exam_paper_id (FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Craft POST to `/lms-exam/exam-scope/store` with exam_paper_id=99999 | Invalid ID |
| 2 | Include valid scopes array with one row | Sending valid row data |
| 3 | Submit request | Laravel validation or DB error |
| 4 | Verify response | Error returned; transaction rolled back |

#### TC-N13: Business — No Valid Scope Rows (All Empty)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Scope form | Form visible |
| 2 | Submit with empty scopes array | No rows |
| 3 | Verify store() catches $created === 0 | Controller checks |
| 4 | Error response | "No valid scope rows found. Please add at least one scope." |
| 5 | DB check: No new scopes created | Rolled back |

#### TC-N18: Restore With Usage Check — Paper Has Allocations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam paper with scopes | Scopes exist |
| 2 | Create allocation for same exam paper | Allocation created |
| 3 | Delete scopes (soft delete) | Scopes in trash |
| 4 | Attempt to restore scopes | UsageCheckService checks |
| 5 | Error response | "Cannot restore this scope because the exam paper has allocations or student attempts." |
| 6 | DB check: scopes remain soft-deleted | Not restored |

#### TC-N23: Update Scope With Invalid scopes.*.id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit form for Paper A with 2 scopes S1, S2 | Edit form loaded |
| 2 | Submit with scopes[0][id]=99999 (non-existent), scopes[0][target]=5 | Invalid ID |
| 3 | Verify controller skips (scope not found or exam_paper_id mismatch) | Scope not found |
| 4 | Remaining valid row processed | Other scope updated/counted |
| 5 | Verify response message does not count invalid row | Only valid rows counted |

#### TC-N24: Bulk Update With exam_paper_id Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create scope S1 under Paper A | Scope exists |
| 2 | Submit edit with exam_paper_id = Paper B (different from S1's paper) | Mismatch |
| 3 | Controller checks if($scope && $scope->exam_paper_id == $examPaperId) | Condition fails |
| 4 | Scope S1 skipped | Not updated |
| 5 | Response includes only updated/created/deleted counts | S1 not counted |

#### TC-N27: AJAX getExamPaperDetails With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call AJAX GET `/lms-exam/exam-scope/get-exam-paper-details/99999` | Non-existent |
| 2 | Verify exception thrown | findOrFail throws ModelNotFoundException |
| 3 | Verify HTTP 404 returned | Page or JSON error |

#### TC-D01: Create Scope → Activity Log Created

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 1 scope with lesson, topic, question_type | Success |
| 2 | Query activity_log table | Entry found |
| 3 | Verify event = 'Created' | Correct event |
| 4 | Verify scope_details contains lesson_id, topic_id, target_questions, weightage | Details logged |
| 5 | Verify performed_by = current user name | User logged |
| 6 | Verify log message = 'Exam scope created successfully' | Correct message |

#### TC-D02: Bulk Delete → Scopes Trashed With is_active=false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 scopes with is_active=1 for Paper A | 3 records |
| 2 | Execute destroy route for Paper A | POST |
| 3 | DB check scope 1: is_active=0, deleted_at=timestamp | Deactivated + soft-deleted |
| 4 | DB check scope 2: is_active=0, deleted_at=timestamp | Deactivated + soft-deleted |
| 5 | DB check scope 3: is_active=0, deleted_at=timestamp | Deactivated + soft-deleted |
| 6 | Verify each scope has activityLog('Trashed') | All logged |

#### TC-D05: Exam Paper Deletion Cascades To Scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam paper with 3 scopes | Paper + 3 scopes |
| 2 | Execute DELETE on exam paper from DB or admin | Paper deleted |
| 3 | DB check: `SELECT * FROM lms_exam_scopes WHERE exam_paper_id = {id}` | 0 records (cascaded) |
| 4 | Verify DDL shows ON DELETE CASCADE for fk_es_exam | DDL verified |

#### TC-D07: Bulk Store Wrapped In DB Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare POST with 3 scopes, but mock a DB failure after 2nd scope | Simulate failure |
| 2 | Execute store() | Exception thrown |
| 3 | DB check: `SELECT COUNT(*) FROM lms_exam_scopes WHERE exam_paper_id={id}` | 0 — all rolled back |
| 4 | Verify rollBack() called in catch block | Transaction rolled back |

#### TC-D11: Usage Check Service Counts All Dependencies

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam paper with allocations, sets, blueprints, results, attempts | All exist |
| 2 | Execute ExamScopeUsageCheckService::getUsageDetails(scopeId) | Returns all counts |
| 3 | Verify details['Allocations'] = correct count | Allocations counted |
| 4 | Verify details['Paper Sets'] = correct count | Sets counted |
| 5 | Verify details['Blueprints'] = correct count | Blueprints counted |
| 6 | Verify details['Results'] = correct count | Results counted |
| 7 | Verify details['StudentAttempts'] = correct count | Attempts counted |
| 8 | Verify getUsageMessage() returns all usage categories | Human-readable message |

#### TC-D13: Edit Form Loads Topic Parent Chain

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create topic tree: Root (id=1) → Child (id=2, parent=1) → Grandchild (id=3, parent=2) | Hierarchy depth 3 |
| 2 | Create scope with topic_id = 3 (grandchild) | Scope exists |
| 3 | Open edit form for this scope's exam paper | Edit form loads |
| 4 | Verify scopesData[0].parent_chain array length = 3 | Full chain |
| 5 | Verify chain[0].id=1, chain[0].name='Root', chain[0].level=0, chain[0].level_name='Root' | Root node |
| 6 | Verify chain[1].id=2, chain[1].name='Child', chain[1].level=1 | Child node |
| 7 | Verify chain[2].id=3, chain[2].name='Grandchild', chain[2].level=2 | Grandchild node |

### 7.3 Additional Negative Test Cases

#### TC-N15: Bulk Store — Duplicate Scope For Same Exam Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create scope for Paper P1, Lesson L1, Topic T1, QType QT1 | First scope exists |
| 2 | POST bulk store with same Paper P1, Lesson L1, Topic T1, QType QT1 | Duplicate entry |
| 3 | Controller checks existing scope | Validation error |
| 4 | Response contains duplicate scope message | Scope already exists |

#### TC-N16: Bulk Store — Weightage Sum Exceeds 100%

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare scopes array with 2 rows: weightage_percent=60, weightage_percent=50 | Sum = 110 > 100 |
| 2 | POST bulk store | Validation error |
| 3 | Error message | Weightage sum cannot exceed 100 |

#### TC-N17: Bulk Update — Invalid Scope ID In Scopes Array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST update with scopes[0].id = 99999 (non-existent) | Invalid ID |
| 2 | Controller check fails | Validation error |
| 3 | Error message | Invalid scope reference |

#### TC-N18: Toggle Status On Non-Existent Scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call toggleStatus with scope_id = 99999 | KO AJAX |
| 2 | Response | success: false, not found error |

#### TC-N19: Bulk Destroy With Existing Allocations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam paper P1 with scope S1 and allocation A1 linked | Usage exists |
| 2 | POST destroy for P1 | Usage check blocks |
| 3 | Error redirect | Cannot delete, dependency exists |

#### TC-N20: Bulk Force Delete With Existing Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete first, then try force delete | Scope in trash |
| 2 | ExamScopeUsageCheckService returns hasDependencies=true | Blocked |
| 3 | forceDelete redirects with error | Dependency exists, cannot force delete |

### 7.4 Additional Code Review Test Cases

#### TC-CR01: Bulk Store Uses DB Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect ExamScopeController@store | beginTransaction at start |
| 2 | Verify commit on success | DB::commit() called |
| 3 | Verify rollback on exception | DB::rollBack() in catch |
| 4 | Confirm all scope inserts inside transaction | Atomic operation |

#### TC-CR02: Bulk Update Uses DB Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect ExamScopeController@update | beginTransaction at start |
| 2 | Verify old scopes deleted, new scopes inserted in transaction | All or nothing |
| 3 | Verify commit on success | Present |
| 4 | Verify rollback on failure | Present |

#### TC-CR03: Index Uses Search Scope Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index() method | Filters via ExamScope query |
| 2 | Verify exam_paper_id filter | where condition |
| 3 | Verify lesson_id filter | where condition |
| 4 | Verify topic_id filter | where condition |
| 5 | Verify is_active filter | where condition |
| 6 | Verify search keyword filtering | search scope |

#### TC-CR04: Activity Logging On CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() | activityLog(Stored) called |
| 2 | Inspect update() | activityLog(Updated) called |
| 3 | Inspect destroy() | activityLog(Trashed) called |
| 4 | Inspect restore() | activityLog(Restored) called |
| 5 | Inspect forceDelete() | activityLog(Deleted) called |
| 6 | Inspect toggleStatus() | activityLog(Toggled) called |
| 7 | Verify all use appropriate log type | Correct event types |

#### TC-CR05: Global Scope With Active Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check ExamScope model | boot() method present |
| 2 | Verify addGlobalScope for is_active=1 | Active scope added |
| 3 | Verify trash view explicitly includes soft-deleted | withTrashed() used |
| 4 | Verify trash view includes inactive records | both active and inactive |

### 7.5 AJAX Endpoint Test Cases

#### TC-P46: AJAX Get Exam Paper Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam paper with total_questions=10, total_marks=50 | Paper exists |
| 2 | Call getExamPaperDetails(paperId) | AJAX |
| 3 | Verify JSON includes paper id, title, total_questions, total_marks | All fields present |
| 4 | Call with invalid ID | 404 response |

#### TC-P47: AJAX Get Lessons By Exam Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper P1 has class_id=C1, subject_id=S1 | Config set |
| 2 | Lessons L1, L2 exist for class C1 and subject S1 | 2 lessons |
| 3 | Call getLessonsByExamPaper with exam_paper_id=P1 | AJAX |
| 4 | Verify 2 lessons returned | Both with id, name, code |
| 5 | Filter by subject_id internally | Lessons filtered correctly |

#### TC-P48: AJAX Get Lessons By Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call getLessonsByExam with exam_id=E1 | AJAX |
| 2 | Verify lessons returned for that exam | Correct list |

#### TC-P49: AJAX Get Topic Hierarchy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create topics: T1 (root), T2 (child of T1), T3 (child of T2) | Hierarchy depth=3 |
| 2 | Call getTopicHierarchy with subject_id=S1, lesson_id=L1 | AJAX |
| 3 | Verify nested structure | Hierarchical format |
| 4 | Verify each topic has: id, name, code, level, parent_id, children | Full hierarchy |

#### TC-P50: View Single Exam Scope Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to index page | Grid visible |
| 2 | Create scope record | Record exists |
| 3 | Click View on scope row | Show page loads |
| 4 | Verify exam_paper title | Displayed |
| 5 | Verify lesson name | Displayed |
| 6 | Verify topic name with parent chain | Displayed |
| 7 | Verify question_type | Displayed |
| 8 | Verify target_question_count | Displayed |
| 9 | Verify weightage_percent | Displayed |
| 10 | Verify is_active status badge | Displayed |

#### TC-P51: Edit Form Loads With Current Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit for exam paper | Edit form loads |
| 2 | Verify scopesData populated with all existing scopes | Pre-filled |
| 3 | Verify exam_paper_id pre-selected | Read-only |
| 4 | Verify each scope row shows lesson, topic, qtype, count, weightage | Editable fields |
| 5 | Verify topic parent chain shown for each scope | Hierarchy visible |

#### TC-P52: Bulk Update — Modify Scope Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit form with 2 existing scope rows | Form ready |
| 2 | Change row 1: target_question_count from 5 to 8 | Row updated |
| 3 | Change row 2: weightage_percent from 30 to 25 | Row updated |
| 4 | Submit bulk update | POST |
| 5 | DB check: row 1 count=8, row 2 weightage=25 | Updated |
| 6 | Verify old scope rows deleted and new ones inserted | Replace pattern |

#### TC-P53: Bulk Update — Add New Scope Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit form with 1 existing scope row | Form ready |
| 2 | Click Add Row button | New empty row |
| 3 | Select lesson, topic, qtype, enter count=3, weightage=15 | Row filled |
| 4 | Submit bulk update | POST |
| 5 | DB check: 2 scope records now exist | Added |

#### TC-P54: Bulk Update — Remove Existing Scope Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit form with 2 existing scope rows | Both rows visible |
| 2 | Click Remove on row 2 | Row removed from UI |
| 3 | Submit bulk update | POST |
| 4 | DB check: only 1 scope record remains | Removed |

#### TC-P55: Toggle Scope Status (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create scope with is_active=1 | Active |
| 2 | Call toggleStatus AJAX with scope_id | POST |
| 3 | Response: success=true, is_active=false | Toggled off |
| 4 | Call toggleStatus again | is_active=true back |
| 5 | DB check alternates | Correct |

#### TC-P56: Restore Soft-Deleted Scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete scope | In trash |
| 2 | Navigate to trash view | Deleted scope shown |
| 3 | Click Restore | POST |
| 4 | DB check: deleted_at=null, is_active=1 | Restored |
| 5 | Verify scope appears in index | Visible again |

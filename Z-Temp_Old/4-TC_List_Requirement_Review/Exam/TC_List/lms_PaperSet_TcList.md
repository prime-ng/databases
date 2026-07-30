# lms_PaperSet_TcList

## Module: LmsExam → Creation & Allocation → Paper Set

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Creation & Allocation |
| Feature | Paper Set |
| URL(s) | `/lms-exam/creation-allocation` (index via tab with `active_tab=exam_paper_set`), `/lms-exam/paper-set/store` (create/update), `/lms-exam/paper-set/create` (create form), `/lms-exam/paper-set/{paper_set}` (show), `/lms-exam/paper-set/{paper_set}/edit` (edit), `/lms-exam/paper-set/{paper_set}/destroy` (delete), `/lms-exam/paper-set/trash/view` (trash), `/lms-exam/paper-set/{paper_set}/restore` (restore), `/lms-exam/paper-set/{paper_set}/force-delete` (forceDelete), `/lms-exam/paper-set/{paper_set}/toggle-status` (toggleStatus) |
| Controller | `Modules\LmsExam\Http\Controllers\ExamPaperSetController` |
| Model(s) | `Modules\LmsExam\Models\ExamPaperSet` (`lms_exam_paper_sets`, SoftDeletes, computed attributes) |
| Validation (Create) | `Modules\LmsExam\Http\Requests\ExamPaperSetRequest` |
| Validation (Update) | `Modules\LmsExam\Http\Requests\ExamPaperSetRequest` |
| Permissions | `tenant.paper-set.viewAny`, `tenant.paper-set.view`, `tenant.paper-set.create`, `tenant.paper-set.update`, `tenant.paper-set.delete`, `tenant.paper-set.restore`, `tenant.paper-set.forceDelete`, `tenant.paper-set.status` |
| Soft Deletes | Yes (`ExamPaperSet` uses `SoftDeletes` trait; destroy() sets `is_active=false` before `delete()`) |
| Activity Log | Events: `Stored`, `Updated` (with old/new diff), `Trashed`, `Restored`, `Deleted` (permanent), `Toggled` |
| Usage Check | `ExamPaperSetUsageCheckService` — checks paper set questions and allocations |
| Computed Attributes | `total_marks` (sum of override_marks from questions), `total_questions` (count of questions) |

---

## 2. Pre-conditions

- Required permissions: `tenant.paper-set.viewAny`, `tenant.paper-set.view`, `tenant.paper-set.create`, `tenant.paper-set.update`, `tenant.paper-set.delete`, `tenant.paper-set.restore`, `tenant.paper-set.forceDelete`, `tenant.paper-set.status`
- Required seed data: At least one active `ExamPaper`, one active `Exam`
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For usage-check tests: Pre-created `PaperSetQuestion` or `ExamAllocation` records referencing the set
- For computed attribute tests: Pre-created `PaperSetQuestion` records with override_marks values

---

## 3. Default Data Load

When the page loads via `creationAllocation()` (GET /lms-exam/creation-allocation with `active_tab=exam_paper_set`), the following data is fetched:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Paper Sets Grid | `ExamPaperSetController@queryBuilder()` | `ExamPaperSet::with(examPaper, examPaper.exam, questions)->latest()` | exam_paper_id, exam_id, search(set_code,set_name,description,paper_code,paper_title), is_active | 10/page |
| Shared: Exam Papers List | `ExamPaper::where('is_active', '1')->get()` | All active exam papers | is_active=1 | None |

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Set code**: Unique per exam paper (`exam_paper_id, set_code` composite unique); max 20 chars, e.g. `SET_A`, `SET_B`
- **Set name**: Required, max 50 chars, e.g. "Paper Set A"
- **Description**: Optional, max 255 chars
- **Pre-test cleanup**: Delete created sets by code before/after tests to avoid collisions
- **Computed attributes**: `total_marks` queries `PaperSetQuestion::sum('override_marks')`; `total_questions` queries `PaperSetQuestion::count()`
- **Usage check**: Uses `ExamPaperSetUsageCheckService` which checks `PaperSetQuestion` and `ExamAllocation` counts

## 5. Business Conditions

### 4.1 Database Schema — `lms_exam_paper_sets`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | exam_paper_id | INT UNSIGNED | NOT NULL, FK → `lms_exam_papers.id` ON DELETE CASCADE |
| BC-DB-03 | set_code | VARCHAR(20) | NOT NULL, UNIQUE `(exam_paper_id, set_code)` |
| BC-DB-04 | set_name | VARCHAR(50) | NOT NULL |
| BC-DB-05 | description | VARCHAR(255) | DEFAULT NULL |
| BC-DB-06 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-07 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-08 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-09 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules — `ExamPaperSetRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | exam_paper_id | required, exists:lms_exam_papers,id | "Exam paper is required" |
| BC-VAL-02 | set_code | required, string, max:20, unique scope (exam_paper_id) ignoring own ID | "Set code is required" / "This set code already exists for this exam paper" |
| BC-VAL-03 | set_name | required, string, max:50 | "Set name is required" |
| BC-VAL-04 | description | nullable, string, max:255 | — |
| BC-VAL-05 | is_active | boolean | — |

### 4.3 Validation Rules — `ExamPaperSetRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | set_code | unique scope (exam_paper_id) ignoring current set ID | "This set code already exists for this exam paper" |
| BC-VAL-U02 | Same as create | All other rules same as create | Same messages |
| BC-VAL-U03 | Usage (controller) | Checked before edit/update/destroy/restore/forceDelete | Dynamic: "This paper set is used in X question(s), Y allocation(s)." |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.paper-set.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.paper-set.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.paper-set.create | create(), store() | Without → 403 |
| BC-AUTH-04 | tenant.paper-set.update | edit(), update(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.paper-set.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.paper-set.restore | trashed(), restore() | Without → 403 |
| BC-AUTH-07 | tenant.paper-set.forceDelete | forceDelete() | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Set code unique per exam paper | `Rule::unique('lms_exam_paper_sets', 'set_code')->where('exam_paper_id', $this->exam_paper_id)->ignore($setId)` |
| BC-BIZ-02 | Usage check on edit | `ExamPaperSetUsageCheckService::isUsed()` blocks edit when questions or allocations exist |
| BC-BIZ-03 | Usage check on update | Same block with usage message |
| BC-BIZ-04 | Usage check on delete | Same block with usage message |
| BC-BIZ-05 | Usage check on restore | Blocks restore if used (usage check runs before restore) |
| BC-BIZ-06 | Usage check on forceDelete | Blocks forceDelete if used; throws DomainException with message |
| BC-BIZ-07 | Status toggle NOT blocked by usage | toggleStatus works even if set is in use |
| BC-BIZ-08 | Soft delete deactivates first | Sets `is_active=false` before `delete()` |
| BC-BIZ-09 | Restore reactivates | Sets `is_active=true` after `restore()` |
| BC-BIZ-10 | Boolean casting | `is_active` cast via `$this->boolean()` in prepareForValidation |
| BC-BIZ-11 | Computed attribute — total_marks | Sum of `PaperSetQuestion::where('paper_set_id')->sum('override_marks')` |
| BC-BIZ-12 | Computed attribute — total_questions | Count of `PaperSetQuestion::where('paper_set_id')->count()` |
| BC-BIZ-13 | Activity log — Stored | On successful create |
| BC-BIZ-14 | Activity log — Updated | On successful update (with old/new diff) |
| BC-BIZ-15 | Activity log — Trashed | On soft delete |
| BC-BIZ-16 | Activity log — Restored | On restore |
| BC-BIZ-17 | Activity log — Deleted | On force delete |
| BC-BIZ-18 | Activity log — Toggled | On status toggle |
| BC-BIZ-19 | DB transaction on create | store() wrapped in DB::beginTransaction/commit/rollback |
| BC-BIZ-20 | DB transaction on update | update() wrapped in transaction |
| BC-BIZ-21 | DB transaction on delete | destroy() wrapped in transaction |
| BC-BIZ-22 | DB transaction on restore | restore() wrapped in transaction |
| BC-BIZ-23 | DB transaction on forceDelete | forceDelete() wrapped in transaction |
| BC-BIZ-24 | DB transaction on toggleStatus | toggleStatus() wrapped in transaction |
| BC-BIZ-25 | Ajax toggle returns JSON | JSON `{success, is_active, message}` |
| BC-BIZ-26 | Usage message dynamic | "This paper set is used in X question(s), Y allocation(s). Therefore cannot be edited." |
| BC-BIZ-27 | throwIfUsed pattern | `forceDelete` uses `throwIfUsed` which throws `DomainException` on usage |
| BC-BIZ-28 | Scope `byExamPaper` | Model has scope `byExamPaper($paperId)` |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | exam_paper_id | lms_exam_papers (id) | CASCADE |
| BC-REF-02 | paper_set_id (in lms_paper_set_questions) | lms_exam_paper_sets (id) | CASCADE |
| BC-REF-03 | paper_set_id (in lms_exam_allocations) | lms_exam_paper_sets (id) | None (NO ACTION) |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Paper Set List Page Loads With All UI Elements | Page loads with search bar, exam paper filter, Add Paper Set button, table, pagination | — | — | ⬜ |
| TC-P02 | Filter Paper Sets By Exam Paper | Table shows only sets belonging to selected exam paper | — | — | ⬜ |
| TC-P03 | Filter Paper Sets By Exam | Table shows only sets for papers belonging to selected exam | — | — | ⬜ |
| TC-P04 | Filter By Active/Inactive Status | Active filter shows only active sets; Inactive shows only inactive | — | — | ⬜ |
| TC-P05 | Search Paper Sets By Set Code | Table filters to show only sets matching set_code | — | — | ⬜ |
| TC-P06 | Search Paper Sets By Set Name | Table filters to show only sets matching set_name | — | — | ⬜ |
| TC-P07 | Search Paper Sets By Description | Table filters to show only sets matching description | — | — | ⬜ |
| TC-P08 | Search Paper Sets By Paper Code | Table filters by paper_code via examPaper relationship | — | — | ⬜ |
| TC-P09 | Search Paper Sets By Paper Title | Table filters by paper title via examPaper relationship | — | — | ⬜ |
| TC-P10 | Create Paper Set With All Required Fields | Set created with exam_paper_id, set_code, set_name — all saved correctly | — | — | ⬜ |
| TC-P11 | Create Paper Set With Description | Description saved (max 255 chars) | — | — | ⬜ |
| TC-P12 | Create Multiple Sets Under Same Paper (Set A, Set B, Set C) | Three sets created with unique codes under same paper | — | — | ⬜ |
| TC-P13 | Edit Paper Set Loads Pre-Filled Data | Edit form shows existing set data | — | — | ⬜ |
| TC-P14 | Update Paper Set Code And Name | set_code and set_name updated; unique per exam paper enforced | — | — | ⬜ |
| TC-P15 | Update Paper Set Description | Description updated | — | — | ⬜ |
| TC-P16 | Update Paper Set Change Exam Paper | exam_paper_id changed to different paper | — | — | ⬜ |
| TC-P17 | View Paper Set Details Page | Set details with code, name, description, parent paper, exam, total_marks, total_questions, usage info | — | — | ⬜ |
| TC-P18 | Soft Delete Unused Paper Set | `is_active=false` set; `deleted_at` timestamp set; activity log "Trashed" | — | — | ⬜ |
| TC-P19 | Trash Page Shows Deleted Paper Sets | Only soft-deleted sets listed with restore + force delete buttons | — | — | ⬜ |
| TC-P20 | Restore Paper Set From Trash | `deleted_at=NULL`; `is_active=true`; activity log "Restored" | — | — | ⬜ |
| TC-P21 | Force Delete Unused Paper Set | Record permanently removed; activity log "Deleted" | — | — | ⬜ |
| TC-P22 | Toggle Status Active To Inactive (AJAX) | `is_active` flips to 0; AJAX 200 `{success:true, is_active:false}` | — | — | ⬜ |
| TC-P23 | Toggle Status Inactive To Active (AJAX) | `is_active` flips to 1; AJAX 200 `{success:true, is_active:true}` | — | — | ⬜ |
| TC-P24 | Activity Logged After Create | `Stored` event logged with message "A new exam paper set was created." | — | — | ⬜ |
| TC-P25 | Activity Logged After Update | `Updated` event logged with old/new value diff JSON | — | — | ⬜ |
| TC-P26 | Activity Logged After Soft Delete | `Trashed` event logged | — | — | ⬜ |
| TC-P27 | Activity Logged After Restore | `Restored` event logged | — | — | ⬜ |
| TC-P28 | Activity Logged After Force Delete | `Deleted` event logged | — | — | ⬜ |
| TC-P29 | Activity Logged After Toggle | `Toggled` event logged | — | — | ⬜ |
| TC-P30 | Full Lifecycle: Create → Edit → Toggle → Delete → Trash → Restore → Force Delete | All 7 transitions successful; activity logged at each step | — | — | ⬜ |
| TC-P31 | Empty State — No Paper Sets | Table shows "No paper sets found" message; Add Paper Set button visible | — | — | ⬜ |
| TC-P32 | Computed Attribute — total_marks Returns Correct Sum | When PaperSetQuestion records exist, `total_marks` = sum of override_marks | — | — | ⬜ |
| TC-P33 | Computed Attribute — total_questions Returns Correct Count | `total_questions` = count of PaperSetQuestion records | — | — | ⬜ |
| TC-P34 | Computed Attributes — Empty Set Returns Zero | No questions → total_marks=0, total_questions=0 | — | — | ⬜ |
| TC-P35 | Same Set Code Allowed Under Different Exam Paper | Two sets in different papers can share same set_code | — | — | ⬜ |
| TC-P36 | Pagination Works On Paper Set List | Page 2 shows next 10 records with preserved active_tab | — | — | ⬜ |
| TC-P37 | ToggleStatus Works Even When Set Is Used | Status can be toggled even with questions/allocations | — | — | ⬜ |
| TC-P38 | Create Set With is_active Not Specified (Defaults True) | New set created with is_active=1 | — | — | ⬜ |
| TC-P39 | Show Page Displays Usage Details | If set has questions/allocations, usage breakdown displayed | — | — | ⬜ |
| TC-P40 | Create Paper Set With Very Short Code (1 Char) | set_code "A" accepted (min not specified, max:20) | — | — | ⬜ |
| TC-P41 | Full Grid Columns Displayed In Index | Columns: Set Code, Set Name, Paper Code, Exam, Total Marks, Total Questions, Status, Actions | — | — | ⬜ |
| TC-P42 | Show Page Links Back To Parent Paper | Back button navigates to creation-allocation with active_tab=paper_set | — | — | ⬜ |
| TC-P43 | Update Set — Only Change is_active Via Toggle | is_active toggled; other fields unchanged | — | — | ⬜ |
| TC-P44 | Create Multiple Sets With Same Paper In One Session | Sequential creation of Set A, Set B, Set C under same paper | — | — | ⬜ |
| TC-P45 | Update Set — Clear Description | Description set to null/empty | — | — | ⬜ |
| TC-P46 | View Set With Questions Linked | Show page lists linked questions count | — | — | ⬜ |
| TC-P47 | View Set With Allocations Linked | Show page shows allocation info | — | — | ⬜ |
| TC-P48 | Edit Set — Usage Message Displayed When Used | Redirected back with dynamic usage message | — | — | ⬜ |
| TC-P49 | Delete Set — Usage Message Displayed When Used | Redirected back with "This paper set is used in X question(s)" | — | — | ⬜ |
| TC-P50 | Force Delete — DomainException Thrown When Used | Usage check throws DomainException with message | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `exam_paper_id` | Validation error: "Exam paper is required" | — | — | ⬜ |
| TC-N02 | Required — Missing `set_code` | Validation error: "Set code is required" | — | — | ⬜ |
| TC-N03 | Required — Missing `set_name` | Validation error: "Set name is required" | — | — | ⬜ |
| TC-N04 | Duplicate Set Code Within Same Exam Paper | "This set code already exists for this exam paper" | — | — | ⬜ |
| TC-N05 | Max Length — Set Code > 20 Characters | Validation fails on set_code.max | — | — | ⬜ |
| TC-N06 | Max Length — Set Name > 50 Characters | Validation fails on set_name.max | — | — | ⬜ |
| TC-N07 | Max Length — Description > 255 Characters | Validation fails on description.max | — | — | ⬜ |
| TC-N08 | Invalid FK — Non-Existent `exam_paper_id` | Validation error: "The selected exam paper id is invalid." | — | — | ⬜ |
| TC-N09 | Edit Blocked — Set Has Questions | Dynamic usage message: "This paper set is used in X question(s). Therefore cannot be edited." | — | — | ⬜ |
| TC-N10 | Update Blocked — Set Has Allocations | Dynamic usage message: "This paper set is used in Y allocation(s). Therefore cannot be updated." | — | — | ⬜ |
| TC-N11 | Delete Blocked — Set Has Questions and Allocations | Dynamic usage message: "This paper set is used in X question(s), Y allocation(s). Therefore cannot be deleted." | — | — | ⬜ |
| TC-N12 | Restore Blocked — Set Has Allocations | "This paper set is used in Y allocation(s). Therefore cannot be..." — however restore does NOT check usage (allows restore even if used) | — | — | ⬜ |
| TC-N13 | Force Delete Blocked — Set Has Questions | DomainException thrown: "This paper set is used in X question(s)." | — | — | ⬜ |
| TC-N14 | View Set With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N15 | Edit/Update Set With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N16 | Delete Set With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N17 | Toggle Status With Invalid ID (404) | JSON 500: `{success: false, message: "Failed to update status."}` | — | — | ⬜ |
| TC-N18 | Restore Non-Deleted Set (Already Active) | `onlyTrashed()->find()` returns null → 404 | — | — | ⬜ |
| TC-N19 | Force Delete Non-Trashed Set | `withTrashed()->findOrFail()` finds it; forceDelete proceeds | — | — | ⬜ |
| TC-N20 | Permission 403 — No Paper Set Permissions | 403 Forbidden on all endpoints for user without `tenant.paper-set.*` gates | — | — | ⬜ |
| TC-N21 | Guest Access Redirect | Redirected to /login for all paper set routes | — | — | ⬜ |
| TC-N22 | XSS Injection In Set Name/Code/Description | Stored as literal string; Blade `{{ }}` escapes output; no script execution | — | — | ⬜ |
| TC-N23 | Whitespace-Only Set Code | Required validation catches whitespace-only strings | — | — | ⬜ |
| TC-N24 | Whitespace-Only Set Name | Required validation catches whitespace-only strings | — | — | ⬜ |
| TC-N25 | Status Toggle With Invalid Boolean | Validation error: "The is active field must be true or false." | — | — | ⬜ |
| TC-N26 | Duplicate Set Code In Different Exam Paper Allowed | Same code OK across different papers | — | — | ⬜ |
| TC-N27 | Create Set For Non-Existent Exam Paper | exam_paper_id must reference existing paper | — | — | ⬜ |
| TC-N28 | Create Set With Special Characters In Code | Special chars allowed unless validation restricts | — | — | ⬜ |
| TC-N29 | Update Set — Change To Already-Used Set Code | Unique validation fires | — | — | ⬜ |
| TC-N30 | ToggleStatus On Soft-Deleted Set | findOrFail on soft-deleted record throws ModelNotFoundException | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create Set → Auto-default is_active=1 | New set created with `is_active=1` by DB default | — | — | ⬜ |
| TC-D02 | B | Soft Delete Set → Questions Cascade (DDL CASCADE) | DDL specifies CASCADE on `fk_sq_set`; deleting set cascades to its paper_set_questions | — | — | ⬜ |
| TC-D03 | C | Restore Set → Questions Remain Deleted | `restore()` only restores set, not questions (no cascading restore) | — | — | ⬜ |
| TC-D04 | D | Exam Paper Deletion Cascades To Sets (CASCADE) | Deleting a paper automatically deletes all its sets (DDL CASCADE) | — | — | ⬜ |
| TC-D05 | E | Toggle Status — Inactive Set Hidden From Dropdowns | Inactive set excluded from question linking dropdown | — | — | ⬜ |
| TC-D06 | F | Allocations Reference paper_set_id (NO ACTION FK) | `fk_alloc_set` has NO ACTION; cannot delete set if allocations exist (usage check blocks) | — | — | ⬜ |
| TC-D07 | G | Computed total_marks Updates When Questions Change | Adding/removing questions updates the computed sum (query-based, not cached) | — | — | ⬜ |
| TC-D08 | H | Computed total_questions Updates When Questions Change | Adding/removing questions updates the count (query-based) | — | — | ⬜ |
| TC-D09 | I | Concurrent Update — Two Users Edit Same Set | Last save wins; no data corruption | — | — | ⬜ |
| TC-D10 | J | Rapid Status Toggle (Race Condition) | Handles rapid toggles without data corruption | — | — | ⬜ |
| TC-D11 | K | DB | P1 | lms_exam_paper_sets with existing record | Unique Composite Constraint — uq_paper_set (exam_paper_id, set_code) | Inserting duplicate (exam_paper_id, set_code) combination at DB level throws integrity constraint violation 1062 | — | — | ⬜ |
| TC-D12 | L | DB | P1 | lms_exam_paper_sets with existing record | Default Value — is_active Column | Inserting record without specifying is_active defaults to 1 | — | — | ⬜ |
| TC-D13 | M | Integration | P1 | PaperSet with questions/allocations | Usage Check — ExamPaperSetUsageCheckService::isUsed() | Returns true when set has questions or allocations; blocks edit/update/delete/forceDelete | — | — | ⬜ |
| TC-D14 | N | Integration | P1 | PaperSet controller | Activity Log — All CRUD Events | Activity logged for Stored, Updated, Trashed, Restored, Deleted, Toggled events | — | — | ⬜ |
| TC-D15 | O | Unit | P1 | ExamPaperSet model | Model Table Name | `ExamPaperSet` has `protected $table = 'lms_exam_paper_sets'` | — | — | ⬜ |
| TC-D16 | P | Unit | P1 | ExamPaperSet model | Model Fillable | `$fillable` includes: exam_paper_id, set_code, set_name, description, is_active | — | — | ⬜ |
| TC-D17 | Q | Unit | P1 | ExamPaperSet model | SoftDeletes Trait | Model uses SoftDeletes; deleted_at column exists | — | — | ⬜ |
| TC-D18 | R | Unit | P1 | ExamPaperSet model | Model Relationships | belongsTo: examPaper; hasMany: questions, allocations | — | — | ⬜ |
| TC-D19 | S | Unit | P1 | ExamPaperSet model | $casts Definition | `is_active` cast to boolean | — | — | ⬜ |
| TC-D20 | T | Unit | P1 | ExamPaperSet model | Computed Attributes | `getTotalMarksAttribute()` returns sum of override_marks; `getTotalQuestionsAttribute()` returns count | — | — | ⬜ |
| TC-D21 | U | Unit | P1 | ExamPaperSet model | Scope byExamPaper | `scopeByExamPaper($query, $paperId)` filters by exam_paper_id | — | — | ⬜ |
| TC-D22 | V | Unit | P1 | ExamPaperSetRequest | Unique Validation | set_code unique scope (exam_paper_id) ignoring own ID | — | — | ⬜ |
| TC-D23 | W | Unit | P1 | ExamPaperSetRequest | Required Validation | Required rules for exam_paper_id, set_code, set_name | — | — | ⬜ |
| TC-D24 | X | Unit | P1 | ExamPaperSetRequest | Boolean Casting | `prepareForValidation()` casts is_active to boolean | — | — | ⬜ |
| TC-D25 | Y | Unit | P1 | ExamPaperSetPolicy | Permission Gates | ExamPaperSetPolicy defines viewAny, view, create, update, delete, restore, forceDelete, status, import, export, print gates | — | — | ⬜ |
| TC-D26 | Z | Unit | P1 | Routes | Resource Routes | Routes for paper-set CRUD + trashed, restore, forceDelete, toggleStatus | — | — | ⬜ |
| TC-D27 | AA | Unit | P1 | ExamPaperSetUsageCheckService | getUsageCount | Returns PaperSetQuestion count + ExamAllocation count | — | — | ⬜ |
| TC-D28 | AB | Unit | P1 | ExamPaperSetUsageCheckService | getUsageDetails | Returns array with Questions and Allocations counts | — | — | ⬜ |
| TC-D29 | AC | Unit | P1 | ExamPaperSetUsageCheckService | getUsageMessage | "This paper set is used in X question(s), Y allocation(s)." | — | — | ⬜ |
| TC-D30 | AD | Unit | P1 | ExamPaperSetUsageCheckService | throwIfUsed | Throws DomainException with usage message when isUsed=true | — | — | ⬜ |
| TC-D31 | AE | Unit | P1 | ExamPaperSetController | Transaction Handling | All state-changing methods use DB::beginTransaction/commit/rollback | — | — | ⬜ |
| TC-D32 | AF | Unit | P1 | ExamPaperSetController | findOrFail Usage | edit, update, show, destroy, restore, forceDelete, toggleStatus use findOrFail; restore uses onlyTrashed; forceDelete uses withTrashed | — | — | ⬜ |
| TC-D33 | AG | Unit | P1 | ExamPaperSetController | Gate Authorization | Gate::authorize('tenant.paper-set.*') called before each CRUD operation | — | — | ⬜ |
| TC-D34 | AH | Unit | P1 | ExamPaperSetController | queryBuilder Filters | Filters: exam_paper_id, exam_id, search (set_code, set_name, description, paper_code, paper_title), is_active; ordered by latest() | — | — | ⬜ |
| TC-D35 | AI | Unit | P1 | ExamPaperSetController | Eager Loading | Index: with(examPaper, examPaper.exam, questions); Show: with(examPaper, examPaper.exam, questions.question, allocations) | — | — | ⬜ |
| TC-D36 | AJ | Integration | P1 | ExamPaperSetController | show() Loads Usage Details | View receives $usageDetails and $isUsed variables | — | — | ⬜ |
| TC-D37 | AK | Integration | P1 | ExamPaperSetController | edit() Usage Check Redirect | When used, redirects back with usage message | — | — | ⬜ |
| TC-D38 | AL | Integration | P1 | ExamPaperSetController | update() Usage Check Back | When used, redirects back with usage message | — | — | ⬜ |
| TC-D39 | AM | Integration | P1 | ExamPaperSetController | destroy() Usage Check Back | When used, redirects back with usage message | — | — | ⬜ |
| TC-D40 | AN | Integration | P1 | ExamPaperSetController | forceDelete() Usage Check | Uses throwIfUsed pattern; DomainException caught → back with error | — | — | ⬜ |
| TC-D41 | AO | Cross-Module | P1 | Paper Set Questions — lms_paper_set_questions FK | `lms_paper_set_questions.paper_set_id` FK → `lms_exam_paper_sets.id` ON DELETE CASCADE | — | — | ⬜ |
| TC-D42 | AP | Cross-Module | P1 | Allocations — lms_exam_allocations.paper_set_id FK | `lms_exam_allocations.paper_set_id` FK → `lms_exam_paper_sets.id` (NO ACTION) | — | — | ⬜ |
| TC-D43 | AQ | Cross-Module | P1 | Paper Deletion — FK CASCADE paper_id → sets | Deleting parent exam_paper cascades to delete all its sets | — | — | ⬜ |
| TC-D44 | AR | Code Review | P1 | Blade @can Directives For Paper Set CRUD Buttons | @can('tenant.paper-set.create'), @can('tenant.paper-set.edit'), @can('tenant.paper-set.delete') used | — | — | ◌ |
| TC-D45 | AS | Code Review | P1 | View — isset()/null-safe Checks | Blade views use isset/optional for relationship access | — | — | ◌ |
| TC-D46 | AT | Code Review | P1 | Controller — JSON Response After ToggleStatus | toggleStatus returns response()->json() with success flag | — | — | ◌ |
| TC-D47 | AU | Unit | P1 | ExamPaperSetRequest authorize() | FormRequest Gates checks tenant.paper-set.create for POST, tenant.paper-set.update for PUT/PATCH | — | — | ◌ |
| TC-D48 | AV | Code Review | P1 | Controller — Usage Check Before Edit/Update/Destroy/ForceDelete | Usage check called before destructive operations; blocks with dynamic message | — | — | ◌ |
| TC-D49 | AW | Code Review | P1 | Controller — try-catch Exception Handling | All state-changing methods wrapped in try-catch; exceptions caught and handled | — | — | ◌ |
| TC-D50 | AX | Code Review | P1 | Controller — forceDelete Uses throwIfUsed | forceDelete calls `$usageCheck->throwIfUsed($id)` before proceeding | — | — | ◌ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.paper-set.create'), @can('tenant.paper-set.edit'), @can('tenant.paper-set.delete'), @can('tenant.paper-set.view'), @canany(['tenant.paper-set.restore', 'tenant.paper-set.forceDelete']) for access control on all CRUD buttons and actions | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | Paper set routes registered in breadcrumb config; breadcrumb visible and links correctly | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — try-catch Exception Handling on All CRUD Methods | All state-changing methods use try-catch; exceptions are caught, logged, and user receives error feedback | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — DB Transactions on Multi-Step Writes | Methods use DB::beginTransaction/commit/rollback; partial writes do not occur on failure | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Relationship expressions in Blade use isset/$var?->relation/null-safe operator; no undefined property errors | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | View — Flash Messages After CRUD | After CRUD actions, controller redirects with success/error flash messages | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Controller — findOrFail on All ID-Dependent Methods | All ID-dependent methods use findOrFail; 404 returned on not found | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | Controller — Usage Check Before Edit/Update/Destroy/ForceDelete | ExamPaperSetUsageCheckService called before each destructive operation; blocked with dynamic message when used | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | Controller — restore Does NOT Check Usage | `restore()` method does NOT call usageCheck (allows restoring used sets) | — | — | ◌ |
| TC-CR10 | CR | Code Review | P1 | Controller — forceDelete Uses throwIfUsed Pattern | `forceDelete()` calls `$usageCheck->throwIfUsed($id)` which throws DomainException; caught and displayed as error | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR03: Controller — try-catch Exception Handling on All CRUD Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperSetController.php | Controller class found in Modules/LmsExam/Http/Controllers/ |
| 2 | Inspect store() method | Business logic wrapped in try {} catch(\Exception $e) {}; on exception, DB rollback and error logged |
| 3 | Inspect update() method | try-catch present; findOrFail inside try |
| 4 | Inspect destroy() method | try-catch present; is_active toggle inside try |
| 5 | Inspect restore() method | try-catch present; is_active restore inside try |
| 6 | Inspect forceDelete() method | try-catch present; DomainException caught for usage; \Throwable caught for general |
| 7 | Inspect toggleStatus() method | try-catch present; DB transaction inside try |
| 8 | Simulate DB failure during store | Exception caught; user redirected with error message; no partial data written |

#### TC-CR04: Controller — DB Transactions on Multi-Step Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperSetController.php | Controller class found |
| 2 | Inspect store() method | DB::beginTransaction() before create; commit after activityLog; rollback on exception |
| 3 | Inspect update() method | DB::beginTransaction before update; commit after activityLog; rollback on exception |
| 4 | Inspect destroy() method | is_active=false toggle + delete() + activityLog all in single transaction |
| 5 | Inspect restore() method | is_active=true + restore() + activityLog in single transaction |
| 6 | Inspect forceDelete() method | forceDelete() + activityLog in single transaction |
| 7 | Verify no partial writes occur | If activityLog throws exception after model save, model changes are rolled back |

#### TC-CR05: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open exam-paper-set/index.blade.php | View file found in lmsexam::exam-paper-set/ |
| 2 | Scan for relationship access patterns (e.g. $record->relation->field) | All such expressions use isset() or optional() or ?-> null-safe operator |
| 3 | Scan for foreach loops over relationships | Loop target checked with isset() or !empty() before iterating |
| 4 | Create a record with null relationship | View renders without undefined index/property error |
| 5 | Load index page with records that have missing relations | No 500 errors; null values displayed gracefully (dash or empty string) |

#### TC-CR06: View — Flash Messages After CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new paper set | POST to store(); redirects with session flash |
| 2 | Verify success message after create | Page shows success alert: 'Paper set created successfully' (flash('created.paper-set')) |
| 3 | Update the paper set | PUT to update(); redirects with flash |
| 4 | Verify success message after update | 'Paper set updated successfully' |
| 5 | Soft delete the paper set | DELETE to destroy(); redirects with flash |
| 6 | Verify success message after delete | 'Paper set trashed successfully' |
| 7 | Restore from trash | POST to restore(); redirects with flash |
| 8 | Verify success message after restore | 'Paper set restored successfully' |
| 9 | Force delete from trash | DELETE to forceDelete(); redirects with flash |
| 10 | Verify success message after force delete | 'Paper set force deleted successfully' |

#### TC-CR01: Blade @can Directives — Permission-based Visibility for All Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php for add/create button | @can('tenant.paper-set.create') wraps the Add Paper Set button |
| 2 | Inspect row-level action buttons (view, edit, delete, status toggle) | @can('tenant.paper-set.view'), @can('tenant.paper-set.edit'), @can('tenant.paper-set.delete'), @can('tenant.paper-set.status') used appropriately |
| 3 | Inspect trash.blade.php for restore/forceDelete buttons | @canany(['tenant.paper-set.restore', 'tenant.paper-set.forceDelete']) wraps action buttons |
| 4 | Inspect show.blade.php for edit button | @can('tenant.paper-set.edit') wraps the Edit button; hidden when `$isUsed` is true |
| 5 | Log in as user with all permissions | All buttons visible and functional |
| 6 | Log in as user with viewAny only (no create/edit/delete) | Add Paper Set button hidden; action columns show view icon only |

#### TC-CR07: Controller — findOrFail on All ID-Dependent Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperSetController.php | Controller class found |
| 2 | Inspect show($id) method | Uses ExamPaperSet::findOrFail($id) |
| 3 | Inspect edit($id) method | Uses ExamPaperSet::findOrFail($id) |
| 4 | Inspect update($request, $id) method | Uses ExamPaperSet::findOrFail($id) |
| 5 | Inspect destroy($id) method | Uses ExamPaperSet::findOrFail($id) |
| 6 | Inspect restore($id) method | Uses ExamPaperSet::onlyTrashed()->findOrFail($id) |
| 7 | Inspect forceDelete($id) method | Uses ExamPaperSet::withTrashed()->findOrFail($id) |
| 8 | Inspect toggleStatus($request, $id) method | Uses ExamPaperSet::findOrFail($id) |

#### TC-CR08: Controller — Usage Check Before Edit/Update/Destroy/ForceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperSetController.php | Controller class found |
| 2 | Inspect edit($id) method | `$usageCheck->isUsed($id)` called before proceeding; if true → redirect with usage message |
| 3 | Inspect update() method | Usage check called first; if used → back with usage message |
| 4 | Inspect destroy() method | Usage check called first; if used → back with usage message |
| 5 | Inspect forceDelete() method | Usage check inside try block; `$usageCheck->throwIfUsed($id)` called |
| 6 | Verify restore does NOT check usage | restore() has NO usage check — restoration allowed even if set has questions/allocations |
| 7 | Verify toggleStatus does NOT check usage | Status can be toggled even when set is in use |

#### TC-CR09: Controller — restore Does NOT Check Usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperSetController.php | Controller class found |
| 2 | Inspect restore($id) method | No ExamPaperSetUsageCheckService call before restore |
| 3 | Verify this differs from other controllers | Restore of paper sets always proceeds regardless of usage |

#### TC-CR10: Controller — forceDelete Uses throwIfUsed Pattern

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperSetController.php | Controller class found |
| 2 | Inspect forceDelete($id) method | After findOrFail, creates usageCheck instance |
| 3 | Check for throwIfUsed | `$usageCheck->throwIfUsed($id)` called; if used, throws DomainException |
| 4 | Verify catch block handles DomainException | Catch (\Throwable $e) catches it; `$e->getMessage()` shown as error |

#### TC-P01: Paper Set List Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Navigate to Creation & Allocation tab, Paper Set tab | Page loads at `/lms-exam/creation-allocation?active_tab=exam_paper_set` |
| 3 | Check search input | Search field with placeholder "Search set code, name..." present |
| 4 | Check exam paper filter dropdown | Dropdown with list of active exam papers present |
| 5 | Check "Add Paper Set" button | Button visible (if create permission) |
| 6 | Check paper set table | Columns: Set Code, Set Name, Paper Code, Exam, Total Marks, Total Questions, Status, Actions |
| 7 | Check pagination | If 10+ sets exist, pagination links appear |

#### TC-P02: Filter Paper Sets By Exam Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create sets under Paper A and Paper B | Both exist |
| 2 | Select Paper A from dropdown | Only Paper A sets shown |
| 3 | Clear filter | Both visible |

#### TC-P03: Filter Paper Sets By Exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create sets under papers in Exam A and Exam B | Sets exist |
| 2 | Select Exam A from filter (if exam filter exists) | Only sets under Exam A shown |

#### TC-P04: Filter By Active/Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active and inactive sets | Both exist |
| 2 | Select "Active" | Only active sets shown |
| 3 | Select "Inactive" | Only inactive sets shown |

#### TC-P05: Search Paper Sets By Set Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with code "SET_A" | Set exists |
| 2 | Search "SET_A" | Set found |

#### TC-P06: Search Paper Sets By Set Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with name "Paper Set A" | Set exists |
| 2 | Search "Paper Set A" | Set found |

#### TC-P07: Search Paper Sets By Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with description "Mathematics variant A" | Set exists |
| 2 | Search "Mathematics" | Set found by description match |

#### TC-P08: Search Paper Sets By Paper Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set under paper with code "MATH_ON_001" | Set exists |
| 2 | Search "MATH_ON_001" | Set found via examPaper relationship |

#### TC-P09: Search Paper Sets By Paper Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set under paper with title "Mathematics Online" | Set exists |
| 2 | Search "Mathematics Online" | Set found via examPaper relationship |

#### TC-P10: Create Paper Set With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Paper Set tab | Page loads |
| 2 | Click "Add Paper Set" | Create form opens |
| 3 | Select exam paper from dropdown | Exam paper selected |
| 4 | Enter set_code: "SET_A" | Code filled |
| 5 | Enter set_name: "Paper Set A" | Name filled |
| 6 | Click "Create Paper Set" | POST to `/lms-exam/paper-set/store` |
| 7 | Check response | Success: "Paper set created successfully." |
| 8 | DB check: `SELECT * FROM lms_exam_paper_sets WHERE set_code='SET_A'` | Record exists with exam_paper_id, set_code, set_name, is_active=1 |

#### TC-P11: Create Paper Set With Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill required fields | Fields set |
| 2 | Enter description: "This set contains advanced level questions" | Description filled |
| 3 | Click "Create" | Set created |
| 4 | DB check | description saved correctly |

#### TC-P12: Create Multiple Sets Under Same Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create "SET_A" under Paper P1 | Set A created |
| 2 | Create "SET_B" under Paper P1 | Set B created |
| 3 | Create "SET_C" under Paper P1 | Set C created |
| 4 | DB check: `SELECT COUNT(*) FROM lms_exam_paper_sets WHERE exam_paper_id=P1` | 3 sets exist with different set_codes |

#### TC-P13: Edit Paper Set Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with all fields filled | Set exists with ID=X |
| 2 | Click "Edit" button | Navigates to `/lms-exam/paper-set/{X}/edit` |
| 3 | Verify form pre-filled | set_code, set_name, description, exam_paper_id all match |

#### TC-P14: Update Paper Set Code And Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit set, change set_code to "SET_B_NEW", set_name to "Paper Set B New" | Fields updated |
| 2 | Click "Update" | Update succeeds |
| 3 | DB check | set_code and set_name updated |

#### TC-P15: Update Paper Set Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Change description to "Updated description" | Description changed |
| 2 | Click "Update" | Update succeeds |
| 3 | DB check | description updated |

#### TC-P16: Update Paper Set Change Exam Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Change exam_paper_id to a different paper | Paper changed |
| 2 | Click "Update" | Update succeeds |
| 3 | DB check | exam_paper_id changed |

#### TC-P17: View Paper Set Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with linked questions | Set exists |
| 2 | Click "View" button | Navigates to show page |
| 3 | Check set code and name displayed | Correct values |
| 4 | Check parent exam paper info | Paper code/title shown |
| 5 | Check total_marks | Sum of question override_marks |
| 6 | Check total_questions | Count of questions |
| 7 | Check description | Displayed if set |
| 8 | Check usage info | Shows questions and allocations counts |

#### TC-P18: Soft Delete Unused Paper Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with no questions/allocations | Set exists with ID=X |
| 2 | Click delete button | SweetAlert confirmation |
| 3 | Confirm delete | DELETE sent |
| 4 | Check toast | "Paper set trashed successfully" |
| 5 | DB check | is_active=0, deleted_at NOT NULL |

#### TC-P19: Trash Page Shows Deleted Paper Sets

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete 2 sets | Both trashed |
| 2 | Click "Trash" button | Trash view loaded |
| 3 | Check table lists only trashed sets | Both visible with Restore and Force Delete |

#### TC-P20: Restore Paper Set From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Restore" on trashed set | Restore POST sent |
| 2 | Check toast | "Paper set restored successfully" |
| 3 | DB check | deleted_at=NULL, is_active=1 |

#### TC-P21: Force Delete Unused Paper Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Delete Forever" on trashed set | SweetAlert confirmation |
| 2 | Confirm | forceDelete executed |
| 3 | DB check | Record permanently removed |

#### TC-P22: Toggle Status Active To Inactive (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click status toggle on active set | AJAX POST with is_active=0 |
| 2 | Check response | `{success: true, is_active: false}` |
| 3 | DB check | is_active=0 |

#### TC-P23: Toggle Status Inactive To Active (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click status toggle on inactive set | AJAX POST with is_active=1 |
| 2 | Check response | `{success: true, is_active: true}` |
| 3 | DB check | is_active=1 |

#### TC-P24 to TC-P30: Activity Log and Full Lifecycle

(Follow same pattern as Exam Creation — verify each activity event type logged correctly after each CRUD operation)

#### TC-P32: Computed Attribute — total_marks Returns Correct Sum

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PaperSet with 3 questions having override_marks 10, 20, 30 | Questions exist |
| 2 | Access `$paperSet->total_marks` | Returns 60.0 (10+20+30) |

#### TC-P33: Computed Attribute — total_questions Returns Correct Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PaperSet with 5 questions | Questions exist |
| 2 | Access `$paperSet->total_questions` | Returns 5 |

#### TC-P34: Computed Attributes — Empty Set Returns Zero

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PaperSet with no questions | Empty set |
| 2 | Access `$paperSet->total_marks` | Returns 0.0 |
| 3 | Access `$paperSet->total_questions` | Returns 0 |

#### TC-N01: Required — Missing exam_paper_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all fields EXCEPT exam_paper_id | Leave paper empty |
| 2 | Submit | Error: "Exam paper is required" |

#### TC-N02: Required — Missing set_code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all fields EXCEPT set_code | Leave code empty |
| 2 | Submit | Error: "Set code is required" |

#### TC-N03: Required — Missing set_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all fields EXCEPT set_name | Leave name empty |
| 2 | Submit | Error: "Set name is required" |

#### TC-N04: Duplicate Set Code Within Same Exam Paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with code "SET_A" under Paper P1 | Set exists |
| 2 | Try to create another set with code "SET_A" under same P1 | Validation error: "This set code already exists for this exam paper" |
| 3 | Create set with code "SET_A" under Paper P2 | Allowed (different exam paper) |

#### TC-N09: Edit Blocked — Set Has Questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with 2 questions linked | Set in use |
| 2 | Click Edit | UsageCheck returns true |
| 3 | Redirected back with error | "This paper set is used in 2 question(s). Therefore cannot be edited." |

#### TC-N11: Delete Blocked — Set Has Questions and Allocations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with 3 questions and 5 allocations | Set in use |
| 2 | Click Delete | UsageCheck blocks |
| 3 | Error shown | "This paper set is used in 3 question(s), 5 allocation(s). Therefore cannot be deleted." |

#### TC-N13: Force Delete Blocked — Set Has Questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trash a set that has questions | In trash but still used |
| 2 | Click "Delete Forever" | DomainException thrown |
| 3 | Error shown | "This paper set is used in 2 question(s)." |

#### TC-D11: Unique Composite Constraint — uq_paper_set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert duplicate (exam_paper_id, set_code) directly in DB | Integrity constraint violation 1062 |

#### TC-D12: Default Value — is_active Column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert set without specifying is_active | is_active defaults to 1 |

#### TC-D41: Paper Set Questions FK CASCADE

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with 2 paper_set_questions | Questions exist |
| 2 | Delete set | DDL CASCADE deletes both questions |

#### TC-D42: Allocations FK NO ACTION

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with allocation referencing it | Set used in allocation |
| 2 | Check DDL: `fk_alloc_set` | ON DELETE NO ACTION (usage check blocks deletion instead) |

#### TC-D43: Paper Deletion FK CASCADE

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create paper with 2 sets | Sets exist |
| 2 | Delete paper | DDL CASCADE deletes both sets |

#### TC-D50: forceDelete Uses throwIfUsed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperSetController.php | Controller found |
| 2 | Inspect forceDelete() method | After findOrFail, `$usageCheck->throwIfUsed($id)` called |
| 3 | Verify DomainException thrown when used | If set has questions/allocations, exception thrown before forceDelete |
| 4 | Verify catch block shows message | Catch (\Throwable $e) captures it; `$e->getMessage()` shown as error |

#### TC-D51: Extended — ExamPaperSet Model Computed total_marks Accuracy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PaperSet with ID=100 | Set exists |
| 2 | Insert 3 PaperSetQuestion records: override_marks=15, 25, 35 | Questions exist |
| 3 | Access `$paperSet->total_marks` | Returns 75.0 (15+25+35) |
| 4 | Delete one question (override_marks=25) | Question removed |
| 5 | Access `$paperSet->total_marks` again | Now returns 50.0 (15+35) |
| 6 | Delete all questions | All removed |
| 7 | Access `$paperSet->total_marks` | Returns 0.0 |

#### TC-D52: Extended — ExamPaperSet Model Computed total_questions Accuracy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PaperSet | Set exists |
| 2 | Access `$paperSet->total_questions` with 0 questions | Returns 0 |
| 3 | Add 5 questions | 5 questions exist |
| 4 | Access `$paperSet->total_questions` | Returns 5 |
| 5 | Add 3 more questions | 8 total |
| 6 | Access `$paperSet->total_questions` | Returns 8 |

#### TC-D53: Extended — ExamPaperSetRequest Max Length Validations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperSetRequest.php | Request found |
| 2 | Check set_code max rule | 'max:20' |
| 3 | Check set_name max rule | 'max:50' |
| 4 | Check description max rule | 'max:255' |
| 5 | Verify all accepted | Length rules enforced in validation |

#### TC-D54: Extended — ExamPaperSetPolicy All Gates Coverage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperSetPolicy.php | Policy found in Modules/LmsExam/Policies/ |
| 2 | List all gates | viewAny, view, create, update, delete, restore, forceDelete, status, import, export, print |
| 3 | Verify each returns `$user->can('tenant.paper-set.*')` | Each method delegates to permission check |

#### TC-D55: Extended — ExamPaperSetController Index View Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperSetController.php index() | Method found |
| 2 | Inspect view data passed | 'filters', 'paperSets' (paginated), 'examPapers' (all active) |
| 3 | Verify with() eager loading | with(['examPaper', 'examPaper.exam', 'questions']) |
| 4 | Verify pagination | `->paginate(10)` |

#### TC-D56: Extended — ExamPaperSetController Show View Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperSetController.php show() | Method found |
| 2 | Inspect eager loads | with(['examPaper', 'examPaper.exam', 'questions.question', 'allocations']) |
| 3 | Verify usage details passed | `$usageDetails` and `$isUsed` passed to view |
| 4 | Verify Gate check | Gate::authorize('tenant.paper-set.view') before loading |

#### TC-D57: Extended — ToggleStatus Ajax Response Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperSetController.php toggleStatus() | Method found |
| 2 | Inspect success response | `response()->json(['success'=>true, 'is_active'=>bool, 'message'=>string])` |
| 3 | Inspect save-failure response | `response()->json(['success'=>false, 'message'=>string])` |
| 4 | Inspect exception response | `response()->json([...], 500)` |
| 5 | Verify DB transaction | beginTransaction before save; commit on success; rollback on failure |

#### TC-D58: Extended — restore() No Usage Check Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperSetController.php restore() | Method found |
| 2 | Inspect method body | No call to ExamPaperSetUsageCheckService |
| 3 | Verify transaction | DB::beginTransaction before restore; commit/rollback after |
| 4 | Verify activity logging | activityLog($paperSet, 'Restored') called |

#### TC-D59: Extended — forceDelete withTrashed vs onlyTrashed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamPaperSetController.php forceDelete() | Method found |
| 2 | Inspect findOrFail | Uses `ExamPaperSet::withTrashed()->findOrFail($id)` |
| 3 | Verify it differs from restore | restore uses onlyTrashed(); forceDelete uses withTrashed() |
| 4 | Reason: forceDelete can act on both trashed and non-trashed records | Allows permanent deletion even if not previously soft-deleted |

#### TC-D60: Extended — Full Route List Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open routes file for lms-exam module | Routes defined |
| 2 | Verify paper-set.resource route | `Route::resource('paper-set', ExamPaperSetController::class)` |
| 3 | Verify custom routes for trashed | `GET /paper-set/trash/view` |
| 4 | Verify restore route | `POST /paper-set/{paper_set}/restore` |
| 5 | Verify forceDelete route | `DELETE /paper-set/{paper_set}/force-delete` |
| 6 | Verify toggleStatus route | `POST /paper-set/{paper_set}/toggle-status` |

#### TC-D61: Extended — Trash View Columns Displayed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open exam-paper-set/trash.blade.php | View found |
| 2 | Check table headers | Columns: Set Code, Set Name, Paper Code, Actions |
| 3 | Check Restore button | Present with @can('tenant.paper-set.restore') |
| 4 | Check Force Delete button | Present with @can('tenant.paper-set.forceDelete') |

#### TC-D62: Extended — Create View Form Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open exam-paper-set/create.blade.php | View found |
| 2 | Check exam_paper_id dropdown | Dropdown with list of active exam papers |
| 3 | Check set_code input | Text input, required |
| 4 | Check set_name input | Text input, required |
| 5 | Check description textarea | Optional textarea |
| 6 | Check is_active toggle | Boolean toggle |
| 7 | Check form action | POST to `/lms-exam/paper-set/store` |

#### TC-D63: Extended — Validation Error Display On Create Form

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit empty create form | Validation errors appear |
| 2 | Check error for exam_paper_id | "Exam paper is required" displayed |
| 3 | Check error for set_code | "Set code is required" displayed |
| 4 | Check error for set_name | "Set name is required" displayed |
| 5 | Verify old input preserved | Previously entered values retained |

#### TC-D64: Extended — Concurrent Edit Protection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A opens edit form for Set X | Form loads |
| 2 | User B opens edit form for same Set X | Form loads |
| 3 | User A saves changes | Save succeeds |
| 4 | User B saves changes | Last save wins (no optimistic locking) |

#### TC-D65: Extended — Index Page Sorting Order

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 5 paper sets at different times | Sets exist |
| 2 | Load index page | Sets ordered by latest() (created_at DESC) |
| 3 | Verify newest set appears first | Most recent set at top of table |

#### TC-D66: Extended — Edit Set Changes Reflected In Show Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit set code from "SET_A" to "SET_B" | Update succeeds |
| 2 | Navigate to show page | Shows updated set code "SET_B" |
| 3 | Edit set name from "Set A" to "Set B" | Update succeeds |
| 4 | Navigate to show page | Shows updated set name "Set B" |

#### TC-D67: Extended — Deleted Set Not Available In Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set and then soft-delete it | Set in trash |
| 2 | Navigate to allocation creation or question linking | Deleted set not in dropdown (only is_active=1 shown) |

#### TC-D68: Extended — Usage Check Does Not Block Status Toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set with questions (in use) | Set has usage |
| 2 | Toggle status from active to inactive | AJAX POST succeeds |
| 3 | Verify response | `{success: true, is_active: false}` |
| 4 | DB check | is_active=0 |

#### TC-D69: Extended — Activity Log Contains Performer Info

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set as admin user 'Admin User' | Set created |
| 2 | Query activity log | Entry has 'performed_by' = 'Admin User' |
| 3 | Verify message content | "A new exam paper set was created." |

#### TC-D70: Extended — All CRUD Endpoints Return Correct HTTP Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to store() | 302 Redirect on success |
| 2 | PUT to update() | 302 Redirect on success |
| 3 | DELETE to destroy() | 302 Redirect on success |
| 4 | POST to restore() | 302 Redirect on success |
| 5 | DELETE to forceDelete() | 302 Redirect on success |
| 6 | POST to toggleStatus() | 200 JSON on success |
| 7 | GET to index() | 200 OK |
| 8 | GET to show() | 200 OK |
| 9 | GET to edit() | 200 OK |
| 10 | GET to create() | 200 OK |

#### TC-P51: Extended — Create Set With Null Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill required fields, leave description empty | Description NULL |
| 2 | Click "Create" | Set created |
| 3 | DB check: `SELECT description FROM lms_exam_paper_sets WHERE set_code=?` | description = NULL |

#### TC-P52: Extended — Create Set Under Deleted Exam Paper Should Fail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete an exam paper | Paper in trash, is_active=0 |
| 2 | Try to create set referencing deleted paper | Validation fails: "The selected exam paper id is invalid." (exists rule checks only active records implicitly) |

#### TC-P53: Extended — Update Set is_active via Toggle From Show Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to show page of active set | Toggle shows "Active" |
| 2 | Click toggle | AJAX toggles to inactive |
| 3 | Page updates | Toggle now shows "Inactive" |

#### TC-P54: Extended — Soft-Delete Set Then Create Same Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create set "SET_A" under Paper P1 | Set exists |
| 2 | Soft-delete the set | Set trashed |
| 3 | Create new set "SET_A" under same Paper P1 | Allowed (unique constraint ignores soft-deleted if validation doesn't scope to only non-deleted) |
| 4 | Verify behavior: if unique scope includes soft-deleted records | May be rejected depending on `whereNull('deleted_at')` in unique rule |

#### TC-N31: Extended — create() Without Permission Returns 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without tenant.paper-set.create | User authenticated |
| 2 | Navigate to create page | 403 Forbidden |

#### TC-N32: Extended — store() Without Permission Returns 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without tenant.paper-set.create | User authenticated |
| 2 | POST to store() with valid data | Gate::authorize fails → 403 Forbidden |

#### TC-N33: Extended — update() Without Permission Returns 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without tenant.paper-set.update | User authenticated |
| 2 | PUT to update() with valid data | Gate::authorize fails → 403 Forbidden |

#### TC-N34: Extended — destroy() Without Permission Returns 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without tenant.paper-set.delete | User authenticated |
| 2 | DELETE to destroy() | Gate::authorize fails → 403 Forbidden |

#### TC-N35: Extended — forceDelete() Without Permission Returns 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without tenant.paper-set.forceDelete | User authenticated |
| 2 | DELETE to forceDelete() | Gate::authorize fails → 403 Forbidden |

#### TC-N36: Extended — SQL Injection Attempt In Set Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter set_name: `' OR 1=1; --` | Stored as literal string |
| 2 | Verify no SQL injection | Data saved safely; query builder escapes input |

#### TC-N37: Extended — Create Set With HTML Tags In Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter description: `<b>Bold description</b>` | Description saved with HTML tags |
| 2 | Load show page | Tags displayed as escaped text (`&lt;b&gt;`) |

#### TC-N38: Extended — ToggleStatus On Already Toggled Record (Double Toggle)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle set active→inactive | is_active=0 |
| 2 | Toggle same set again inactive→active | is_active=1 |
| 3 | Verify response | Both operations succeed independently |

#### TC-N39: Extended — Restore Set That Was Force-Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete a set | Record permanently removed |
| 2 | Try to restore | 404: onlyTrashed()->find() returns null |

#### TC-N40: Extended — Bulk Insert Duplicate Set Code Direct In DB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert set (exam_paper_id=1, set_code='SET_A') | Insert succeeds |
| 2 | Insert another set (exam_paper_id=1, set_code='SET_A') | Integrity constraint violation 1062 (uq_paper_set) |

#### Additional Coverage — Scope byExamPaper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 sets under Paper P1, 2 sets under Paper P2 | 5 total sets |
| 2 | Call `ExamPaperSet::byExamPaper(P1)->get()` | Returns 3 sets |
| 3 | Call `ExamPaperSet::byExamPaper(P2)->get()` | Returns 2 sets |
| 4 | Call `ExamPaperSet::byExamPaper(999)->get()` | Returns empty collection |

#### Additional Coverage — Scope Ordering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create sets at different timestamps | Created timestamps differ |
| 2 | Load index | Ordered by latest() (created_at DESC) |
| 3 | Verify newest first | Most recent set ID appears first |

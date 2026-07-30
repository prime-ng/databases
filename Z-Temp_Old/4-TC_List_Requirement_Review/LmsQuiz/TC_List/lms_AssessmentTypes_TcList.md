# Assessment Types — Manual Testing Document (LmsQuiz Module)

## Module: LmsQuiz → Quiz Management → Assessment Types

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuiz |
| Tab Group | Quiz Management |
| Feature | Assessment Types |
| URL(s) | `/lms-quize/assessment-type` (index), `/lms-quize/assessment-type/create` (create), `/lms-quize/assessment-type` (store), `/lms-quize/assessment-type/{assessment_type}` (show/update/destroy), `/lms-quize/assessment-type/{assessment_type}/edit` (edit), `/lms-quize/assessment-type/trash/view` (trashed), `/lms-quize/assessment-type/{id}/restore` (restore), `/lms-quize/assessment-type/{id}/force-delete` (forceDelete), `/lms-quize/assessment-type/{assessment_type}/toggle-status` (toggleStatus) |
| Controller | `Modules\LmsQuiz\Http\Controllers\AssessmentTypeController` |
| Model | `Modules\LmsQuiz\Models\AssessmentType` (table: `lms_assessment_types`) |
| Validation | `Modules\LmsQuiz\Http\Requests\AssessmentTypeRequest` (single class for create + update) |
| Policy | `Modules\LmsQuiz\Policies\AssessmentTypePolicy` (gates: `tenant.assessment-type.*`) |
| Usage Check Service | `Modules\LmsQuiz\Services\AssessmentTypeUsageCheckService` |
| Soft Deletes | Yes — `SoftDeletes` trait on AssessmentType model |
| Activity Log | Yes — Events: Stored, Updated, Trashed, Restored, Deleted, Toggled |
| Import | Not supported |

---

## 2. Pre-conditions

- Required permissions: `tenant.assessment-type.viewAny` (view list), `.create` (create), `.update` (edit/toggle), `.delete` (delete), `.restore` (restore), `.forceDelete` (force delete), `.status` (view status column)
- Required seed data: `qns_question_usage_type` table must have QUIZ, QUEST, ONLINE_EXAM, OFFLINE_EXAM records
- `AssessmentTypeUsageCheckService` checks both `lms_quizzes` and `lms_quests` for usage dependencies
- `code` field is globally unique — enforced by DB unique index + `Rule::unique()` in FormRequest
- `assessment_usage_type_id` FK references `qns_question_usage_type.id`

---

## 3. Default Data Load

When the Assessment Types tab loads via `index()`:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Assessment Types List | AssessmentType::with('usageType') | where search(code/name), where assessment_usage_type_id, where is_active | search, assessment_usage_type_id, is_active | 10 per page |
| Usage Types (dropdown) | QuestionUsageType::where('is_active', 1)->get() | is_active=1 | None | None |
| Single Assessment Type | AssessmentType::with('usageType')->findOrFail($id) | By ID | None | None |
| Usage Details | AssessmentTypeUsageCheckService::getUsageDetails($id) | LmsQuiz + LmsQuests counts | By ID | None |

---

## 4. Test Data Strategy

- **Unique code**: Each assessment type `code` must be globally unique (varchar 50, UNIQUE index)
- **Usage Types**: Pre-seeded — QUIZ, QUEST, ONLINE_EXAM, OFFLINE_EXAM
- **Soft delete**: Verify deleted records can be restored; restore sets `is_active=true`
- **Usage check**: Edit/Update/Destroy blocked if assessment type is referenced by any Quiz or Quest
- **Force delete**: Blocked if Quiz or Quest references exist (displays up to 3 dependency names)
- **Toggle status**: AJAX JSON `{success, is_active, message}`; uses `tenant.assessment-type.update` gate
- **Change detection**: Update logs only changed fields (getChanges(), excludes updated_at)
- **is_active default**: Create form defaults to checked (true)
- **Route-model binding**: Update uses `AssessmentType $assessment_type` parameter

---

## 5. Business Conditions

### 5.1 Database Schema — `lms_assessment_types`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED | PK, auto-increment |
| BC-DB-02 | code | VARCHAR(50) | NOT NULL, UNIQUE |
| BC-DB-03 | name | VARCHAR(100) | NOT NULL |
| BC-DB-04 | description | TEXT | NULLABLE |
| BC-DB-05 | assessment_usage_type_id | BIGINT UNSIGNED | NOT NULL, FK → qns_question_usage_type.id |
| BC-DB-06 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 (cast to boolean) |
| BC-DB-07 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-08 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-09 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules — `AssessmentTypeRequest`

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | code | required, string, max:50, unique:lms_assessment_types (ignore $id on update) | Code field is required + "An assessment type with this code already exists." |
| BC-VAL-02 | name | required, string, max:100 | Name field is required |
| BC-VAL-03 | description | nullable, string, max:255 | — |
| BC-VAL-04 | assessment_usage_type_id | required, exists:qns_question_usage_type,id | Usage type is required (custom attribute name) |
| BC-VAL-05 | is_active | required, boolean | — |
| BC-VAL-06 | prepareForValidation — is_active | Convert checkbox to boolean | If unchecked → false; if checked → true |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior Without |
|-------|-----------|-------------------|-----------------|
| BC-AUTH-01 | tenant.assessment-type.viewAny | index() | 403 Forbidden |
| BC-AUTH-02 | tenant.assessment-type.view | show() | 403 Forbidden |
| BC-AUTH-03 | tenant.assessment-type.create | create(), store() | 403 Forbidden; Create button hidden in blade |
| BC-AUTH-04 | tenant.assessment-type.update | edit(), update(), toggleStatus() | 403 Forbidden; Edit button hidden |
| BC-AUTH-05 | tenant.assessment-type.delete | destroy() | 403 Forbidden; Delete button hidden |
| BC-AUTH-06 | tenant.assessment-type.restore | trashed(), restore() | 403 Forbidden; Trash + Restore buttons hidden |
| BC-AUTH-07 | tenant.assessment-type.forceDelete | forceDelete() | 403 Forbidden; Force Delete button hidden |
| BC-AUTH-08 | tenant.assessment-type.status | (Blade column visibility) | Status column header + toggle hidden |
| BC-AUTH-09 | (Request) tenant.lms-assessment-type.create | AssessmentTypeRequest::authorize() — POST | 403 (note: different gate name from Policy) |
| BC-AUTH-10 | (Request) tenant.lms-assessment-type.update | AssessmentTypeRequest::authorize() — PUT/PATCH | 403 (note: different gate name from Policy) |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create assessment type | Record inserted with validated data; activity log "Stored"; redirect to tab with success flash |
| BC-BIZ-02 | Edit load — not used | Form loads with pre-filled values from existing record |
| BC-BIZ-03 | Edit load — used by quizzes/quests | Blocked; redirect to index with usage error message: "This assessment type is used in: LmsQuiz (X quizzes), LmsQuests (Y quests). Therefore cannot be edited." |
| BC-BIZ-04 | Update — not used | Validated fields saved; change detection via getChanges(); activity log "Updated" with changes array |
| BC-BIZ-05 | Update — used | Blocked; redirect back with usage error |
| BC-BIZ-06 | Update — no changes | No activity log entry created (empty changes check) |
| BC-BIZ-07 | Soft delete — not used | Sets `is_active=false`, then `->delete()`; activity log "Trashed"; redirect with success flash |
| BC-BIZ-08 | Soft delete — used | Blocked; redirect back with usage error |
| BC-BIZ-09 | Restore from trash | `onlyTrashed()->findOrFail($id)`, `->restore()`, then `update(['is_active' => true])`; activity log "Restored" |
| BC-BIZ-10 | Force delete — no dependencies | `withTrashed()->findOrFail($id)`, `->forceDelete()`; activity log "Deleted" |
| BC-BIZ-11 | Force delete — has Quiz references | Blocked; shows error with up to 3 quiz titles + "and others" |
| BC-BIZ-12 | Force delete — has Quest references | Blocked; shows error with up to 3 quest titles + "and others" |
| BC-BIZ-13 | Force delete — has both Quiz + Quest refs | Blocked; shows combined dependency list (first 3) |
| BC-BIZ-14 | Toggle status (AJAX) | POST `{is_active: boolean}`; `findOrFail($id)`, update is_active; returns JSON `{success, is_active, message}` |
| BC-BIZ-15 | Code uniqueness | `Rule::unique('lms_assessment_types', 'code')->ignore($id)` on update; prevents duplicate codes |
| BC-BIZ-16 | Code is editable on update | Code field is NOT locked — user can change code on edit (unique check excludes current record) |
| BC-BIZ-17 | Flash messages | Custom flash keys: `created.assessment-type`, `updated.assessment-type`, `trashed.assessment-type`, `restored.assessment-type`, `force_deleted.assessment-type`, `status_updated.assessment-type` |
| BC-BIZ-18 | Exception on force delete | Caught with try-catch; generic error: "Failed to delete the assessment type. Please try again." |
| BC-BIZ-19 | is_active default on create form | Blade: `old('is_active', true)` — defaults to checked |
| BC-BIZ-20 | Index with search + filters | URL params preserved in pagination: `appends(['active_tab' => 'assessment_type'])` |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) | Notes |
|-------|-----------|------------------|----------------|-------|
| BC-REF-01 | assessment_usage_type_id | qns_question_usage_type (id) | NO ACTION | Cascading delete blocked by service check |
| BC-REF-02 | id (lms_assessment_types) | lms_quizzes (quiz_type_id) | NO ACTION | Usage check blocks edit/delete if referenced |
| BC-REF-03 | id (lms_assessment_types) | lms_quests (quest_type_id) | NO ACTION | Usage check blocks edit/delete if referenced |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Assessment Type List Page Loads With All UI Elements | Page loads with search, usage type filter, status filter, table (Code/Name/Usage Type/Description/Active/Actions), pagination | — | — | ⬜ |
| TC-P02 | Create Assessment Type — All Required Fields | Record created with code, name, assessment_usage_type_id; is_active=true (default); redirect with success flash | — | — | ⬜ |
| TC-P03 | Create Assessment Type — With Description | Description saved as provided | — | — | ⬜ |
| TC-P04 | Create Assessment Type — Inactive (Uncheck is_active) | is_active=false; type excluded from active dropdowns | — | — | ⬜ |
| TC-P05 | Create Assessment Type — Each Usage Type | Select QUIZ, QUEST, ONLINE_EXAM, OFFLINE_EXAM respectively; type appears in correct module dropdown | — | — | ⬜ |
| TC-P06 | Search Assessment Type by Code OR Name | Search "PRAC" shows both "PRACTICE" (matched by code) and "Practice Assessment" (matched by name) | — | — | ⬜ |
| TC-P07 | Filter by Usage Type | Select QUIZ → only types with assessment_usage_type_id=QUIZ shown | — | — | ⬜ |
| TC-P08 | Filter by Active/Inactive | Active filter shows only is_active=1; Inactive shows is_active=0 | — | — | ⬜ |
| TC-P09 | View Assessment Type Details | Show page with table: code, name, usage type, description, status, created_at, updated_at; usage details section if used | — | — | ⬜ |
| TC-P10 | Edit Assessment Type — Change Name Only | Name updated; code unchanged; activity log "Updated" with change detected | — | — | ⬜ |
| TC-P11 | Edit Assessment Type — Change Code | Code updated; unique check excludes current record (passes) | — | — | ⬜ |
| TC-P12 | Edit Assessment Type — Change Usage Type | assessment_usage_type_id updated; type moves to different module | — | — | ⬜ |
| TC-P13 | Edit Assessment Type — Toggle is_active | is_active flipped; redirect with success | — | — | ⬜ |
| TC-P14 | Soft Delete Assessment Type (not used) | is_active=false set first, then deleted_at set; hidden from list; can be restored | — | — | ⬜ |
| TC-P15 | Trash Page Shows Deleted Records | Only soft-deleted records shown; columns: Code, Name, Usage Type, Status, Action (Restore + Force Delete) | — | — | ⬜ |
| TC-P16 | Restore Assessment Type From Trash | deleted_at=NULL; is_active=true back; record visible in main list again | — | — | ⬜ |
| TC-P17 | Toggle Status Active ↔ Inactive (AJAX) | AJAX POST; JSON response `{success: true, is_active: false/true, message: "..."}`; activity log "Toggled" | — | — | ⬜ |
| TC-P18 | Force Delete Assessment Type (no dependencies) | Record permanently removed; cannot be restored | — | — | ⬜ |
| TC-P19 | Pagination (10 Per Page) | With 11+ records, pagination appears; page 2 shows remaining records; active_tab param preserved | — | — | ⬜ |
| TC-P20 | Empty State — No Records | Table shows "No Assessment Types Found" message | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Create — Empty Code | Validation error: code required | — | — | ⬜ |
| TC-N02 | Create — Code Exceeds 50 Characters | Validation error: code max 50 | — | — | ⬜ |
| TC-N03 | Create — Duplicate Code | Validation error: code already exists (unique) | — | — | ⬜ |
| TC-N04 | Create — Empty Name | Validation error: name required | — | — | ⬜ |
| TC-N05 | Create — Name Exceeds 100 Characters | Validation error: name max 100 | — | — | ⬜ |
| TC-N06 | Create — Description Exceeds 255 Characters | Validation error: description max 255 | — | — | ⬜ |
| TC-N07 | Create — No Usage Type Selected | Validation error: assessment_usage_type_id required | — | — | ⬜ |
| TC-N08 | Create — Invalid Usage Type ID | Validation error: assessment_usage_type_id not found | — | — | ⬜ |
| TC-N09 | Edit — Duplicate Code (Another Type's Code) | unique rule detects existing code; validation error | — | — | ⬜ |
| TC-N10 | Edit — Assessment Type Used by Quizzes | Usage check blocks edit; redirect with error: "This assessment type is used in: LmsQuiz (X quizzes). Therefore cannot be edited." | — | — | ⬜ |
| TC-N11 | Edit — Assessment Type Used by Quests | Usage check blocks edit; redirect with error: "This assessment type is used in: LmsQuests (Y quests). Therefore cannot be edited." | — | — | ⬜ |
| TC-N12 | Update — Assessment Type Used by Quizzes | Usage check blocks update; redirect back with error | — | — | ⬜ |
| TC-N13 | Delete — Assessment Type Used by Quizzes/Quests | Usage check blocks delete; redirect back with error | — | — | ⬜ |
| TC-N14 | Force Delete — Has Quiz References | Dependency check finds quizzes; blocked with error listing up to 3 quiz titles | — | — | ⬜ |
| TC-N15 | Force Delete — Has Quest References | Dependency check finds quests; blocked with error listing up to 3 quest titles | — | — | ⬜ |
| TC-N16 | Force Delete — Has Both Quiz + Quest References | Combined dependency list (up to 3); blocked | — | — | ⬜ |
| TC-N17 | View Non-Existent Record (404) | findOrFail throws ModelNotFoundException → 404 | — | — | ⬜ |
| TC-N18 | Edit Non-Existent Record (404) | findOrFail throws ModelNotFoundException → 404 | — | — | ⬜ |
| TC-N19 | Delete Non-Existent Record (404) | findOrFail throws ModelNotFoundException → 404 | — | — | ⬜ |
| TC-N20 | Restore Non-Existent Record (404) | onlyTrashed()->findOrFail returns null → 404 | — | — | ⬜ |
| TC-N21 | Force Delete Non-Existent Record (404) | withTrashed()->findOrFail returns null → 404; caught by try-catch → redirect with error | — | — | ⬜ |
| TC-N22 | Toggle Status Non-Existent Record (404) | findOrFail throws ModelNotFoundException → unhandled 500 | — | — | ⬜ |
| TC-N23 | Toggle Status With Invalid Boolean | Request validation: `is_active required|boolean` → validation error | — | — | ⬜ |
| TC-N24 | Permission 403 — No viewAny | User without tenant.assessment-type.viewAny → 403 on index | — | — | ⬜ |
| TC-N25 | Permission 403 — No create | User without tenant.assessment-type.create → 403 on store/create | — | — | ⬜ |
| TC-N26 | Permission 403 — No update | User without tenant.assessment-type.update → 403 on edit/update/toggleStatus | — | — | ⬜ |
| TC-N27 | Permission 403 — No delete | User without tenant.assessment-type.delete → 403 on destroy | — | — | ⬜ |
| TC-N28 | Permission 403 — No restore | User without tenant.assessment-type.restore → 403 on trashed/restore | — | — | ⬜ |
| TC-N29 | Permission 403 — No forceDelete | User without tenant.assessment-type.forceDelete → 403 on forceDelete | — | — | ⬜ |
| TC-N30 | Guest Access Redirect | Not logged in → redirect to login page | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Edit blocked by Quiz usage | P1 | Create assessment type, link to a quiz, try to edit | Blocked: "This assessment type is used in: LmsQuiz (1 quizzes). Therefore cannot be edited." | — | — | ⬜ |
| TC-D02 | B | Edit blocked by Quest usage | P1 | Create assessment type, link to a quest, try to edit | Blocked: "This assessment type is used in: LmsQuests (1 quests). Therefore cannot be edited." | — | — | ⬜ |
| TC-D03 | C | Delete blocked by Quiz usage | P1 | Create assessment type linked to quiz, try to delete | Blocked with usage error message | — | — | ⬜ |
| TC-D04 | D | Force delete blocked by Quiz | P1 | Create assessment type linked to quiz, soft delete, try force delete | Blocked with dependency names list | — | — | ⬜ |
| TC-D05 | E | Force delete blocked by Quest | P1 | Create assessment type linked to quest, soft delete, try force delete | Blocked with dependency names list | — | — | ⬜ |
| TC-D06 | F | Soft delete — is_active set false | P1 | Soft delete unused type, check DB | is_active = 0, deleted_at NOT NULL | — | — | ⬜ |
| TC-D07 | G | Restore — is_active set true | P1 | Restore soft-deleted type, check DB | deleted_at = NULL, is_active = 1 | — | — | ⬜ |
| TC-D08 | H | Update — change detection | P1 | Update name only, check activity log | Activity log has only 'name' in changes array | — | — | ⬜ |
| TC-D09 | I | Update — no changes = no activity | P1 | Submit update with same values, check activity log | No 'Updated' event logged (changes array empty check) | — | — | ⬜ |
| TC-D10 | J | Toggle — inactive type hidden from quiz create dropdown | P1 | Deactivate type via toggle, open quiz create form | Type not listed in assessment type dropdown | — | — | ⬜ |
| TC-D11 | K | View — show usage details section | P1 | Create type and link to quiz+quest, open show page | Usage details card shows LmsQuiz + LmsQuests counts | — | — | ⬜ |
| TC-D12 | L | View — no usage = no usage section | P1 | Create type with no references, open show page | Usage details section NOT rendered (hidden when totalUsage=0) | — | — | ⬜ |
| TC-D13 | M | Force delete exception handling | P1 | Force delete with DB error, verify rollback | Caught by try-catch; redirect with error message | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Policy — `AssessmentTypePolicy` defines all 8 gates | viewAny, view, create, update, delete, restore, forceDelete, status methods exist | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Request — `AssessmentTypeRequest` authorize uses different gate than Policy | POST: `tenant.lms-assessment-type.create`, PUT: `tenant.lms-assessment-type.update` | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Request — unique code validation ignores current ID on update | `Rule::unique('lms_assessment_types', 'code')->ignore($id)` implemented | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Request — prepareForValidation converts is_active checkbox | `$this->boolean('is_active')` with `$this->has('is_active')` fallback to false | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — store method uses `$request->validated()` | No manual field mapping; mass assignment via model fillable | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — edit/update/destroy blocked by usage check | `AssessmentTypeUsageCheckService::isUsed()` checked before Gate in edit; Gate before update; Gate after find in destroy | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Controller — update with change detection | `$assessment_type->getChanges()` compared with original; activity logged only if !empty($changes) | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | Controller — destroy sets is_active=false before delete | `$assessmentType->update(['is_active' => false]); $assessmentType->delete();` | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | Controller — restore sets is_active=true after restore | `$assessmentType->restore(); $assessmentType->update(['is_active' => true]);` | — | — | ◌ |
| TC-CR10 | CR | Code Review | P1 | Controller — forceDelete checks Quiz + Quest dependencies | `Quiz::where('quiz_type_id', $id)->pluck('title')` + `Quest::where('quest_type_id', $id)->pluck('title')` | — | — | ◌ |
| TC-CR11 | CR | Code Review | P1 | Controller — forceDelete exception handling | try-catch with generic error message | — | — | ◌ |
| TC-CR12 | CR | Code Review | P1 | Controller — toggleStatus validates is_active boolean | `$request->validate(['is_active' => 'required|boolean'])` | — | — | ◌ |
| TC-CR13 | CR | Code Review | P1 | Blade — @can directives for permission-based visibility | index: `@can('tenant.assessment-type.status')` for status column, `@canany` for actions; trash: `@canany` for restore/forceDelete | — | — | ◌ |
| TC-CR14 | CR | Code Review | P1 | Blade — usage check on edit button in show view | `@if(empty($usageDetails['LmsQuiz'] ?? 0) && empty($usageDetails['LmsQuests'] ?? 0))` wraps Edit button | — | — | ◌ |
| TC-CR15 | CR | Code Review | P1 | Blade — breadcrumb implementation | `x-backend.components.breadcrum` used in create, edit, show, trash views with correct links | — | — | ◌ |
| TC-CR16 | CR | Code Review | P1 | Blade — pagination preserves active_tab param | `$assessmentTypes->appends(['active_tab' => request('active_tab', 'assessment_type')])->links()` | — | — | ◌ |
| TC-CR17 | CR | Code Review | P1 | Blade — null-safe access for usageType relationship | `$type->usageType->name ?? '-'` pattern used throughout | — | — | ◌ |
| TC-CR18 | CR | Code Review | P1 | Routes — all CRUD + custom routes registered | resource + trashed/restore/forceDelete/toggleStatus routes present | — | — | ◌ |
| TC-CR19 | CR | Code Review | P1 | Controller — update() activityLog 'Updated' event | After successful update, query `activity_log` table for `subject_type=AssessmentType`, `subject_id=X`, `event='Updated'`; verify `properties` contains changes array with only changed fields | — | — | ◌ |
| TC-CR20 | CR | Code Review | P1 | Controller — restore() activityLog 'Restored' event | After restore, query `activity_log` for `event='Restored'`; verify `properties->message` = "Assessment type restored." | — | — | ◌ |
| TC-CR21 | CR | Code Review | P1 | Controller — forceDelete() activityLog 'Deleted' event | After force delete, query `activity_log` for `event='Deleted'`; verify `properties->message` = "Assessment type permanently deleted." | — | — | ◌ |
| TC-CR22 | CR | Code Review | P1 | Controller — toggleStatus() activityLog 'Toggled' event | After each toggle, query `activity_log` for `event='Toggled'`; verify two distinct log entries for activate and deactivate toggles | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Assessment Type List Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Navigate to LmsQuiz module → Quiz Management tab group → "Assessment Types" tab | Page loads with assessment_type active tab |
| 3 | Check search input field | Placeholder "Search Assessment Type..." |
| 4 | Check Usage Type filter dropdown | Options: All Usage Types, QUIZ, QUEST, ONLINE_EXAM, OFFLINE_EXAM |
| 5 | Check Status filter dropdown | Options: All Status, Active, Inactive |
| 6 | Check table headers | Code, Name, Usage Type, Description, Active (if status permission), Actions (if any action permission) |
| 7 | Check "Add New" button | Button visible (if user has create permission) |
| 8 | Check pagination | If 10+ records exist, pagination links appear |

---

#### TC-P02: Create Assessment Type — All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add New" button | Navigates to create page with breadcrumb: Assessment Types > Create |
| 2 | Enter code: "REMEDIAL" | Field filled |
| 3 | Enter name: "Remedial Assessment" | Field filled |
| 4 | Select Usage Type: "QUIZ" | Dropdown shows "Quiz" |
| 5 | Leave is_active checked (default) | Checkbox checked |
| 6 | Click "Create Assessment Type" button | POST request to store |
| 7 | Check redirect | Redirected to quize index with assessment_type tab |
| 8 | Check success flash | "Assessment type created successfully" (or translated) |
| 9 | DB check: `SELECT * FROM lms_assessment_types WHERE code='REMEDIAL'` | Record exists: name="Remedial Assessment", is_active=1, assessment_usage_type_id=QUIZ.id |
| 10 | Check activity log | "Stored" event with message "Assessment type created." |

---

#### TC-P03: Create Assessment Type — With Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill code="DESC001", name="With Description", select usage type | Required fields set |
| 3 | Enter description: "This is a test assessment type with a description" | Description filled |
| 4 | Click Save | Record created |
| 5 | DB check: description field | "This is a test assessment type with a description" saved |

---

#### TC-P04: Create Assessment Type — Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill code="INACTIVE", name="Inactive Type", select usage type | Required fields set |
| 3 | Uncheck "Assessment Type Active" checkbox | Checkbox unchecked |
| 4 | Click Save | Record created |
| 5 | DB check: `SELECT is_active FROM lms_assessment_types WHERE code='INACTIVE'` | is_active = 0 |

---

#### TC-P05: View Assessment Type Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create assessment type: code="VIEWTEST", name="View Test" | Record exists |
| 2 | Click "View" (eye) icon on that row | Navigates to show page with breadcrumb: Assessment Types > Details |
| 3 | Check Assessment Code row | Shows "VIEWTEST" |
| 4 | Check Assessment Name row | Shows "View Test" |
| 5 | Check Usage Type row | Shows usage type name |
| 6 | Check Description row | Shows description or "-" |
| 7 | Check Status row | Green badge "Active" or Red badge "Inactive" |
| 8 | Check Created At / Last Updated rows | Formatted date displayed |
| 9 | Check "Back" button | Present, links back to tab |
| 10 | Check "Edit" button | Visible only if type not used AND user has update permission |

---

#### TC-P06: Edit Assessment Type — Change Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type: code="EDITTEST", name="Old Name" | Record exists with ID=X |
| 2 | Click "Edit" (pencil) icon on that row | Navigates to edit page with pre-filled data |
| 3 | Change name to "New Name" | Name field updated |
| 4 | Leave code="EDITTEST" unchanged | Code same |
| 5 | Click "Update Assessment Type" button | PUT request sent |
| 6 | Check redirect | Redirected to tab |
| 7 | Check success flash | "Assessment type updated successfully" |
| 8 | DB check: `SELECT name FROM lms_assessment_types WHERE id=X` | name = "New Name" |
| 9 | Activity log: "Updated" event with changes array | Only 'name' field in changes |

---

#### TC-P07: Soft Delete Assessment Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create unused type: code="DELTEST" | Record exists, ID=X |
| 2 | Click delete (trash) icon on that row | Confirmation prompt (SweetAlert) |
| 3 | Confirm deletion | DELETE request to destroy |
| 4 | Check redirect | Redirected to tab |
| 5 | Check flash | "Assessment type moved to trash!" |
| 6 | DB check: `SELECT is_active, deleted_at FROM lms_assessment_types WHERE id=X` | is_active=0, deleted_at NOT NULL |
| 7 | Check activity log | "Trashed" event with message "Assessment type deactivated." |
| 8 | Verify record NOT visible in main list | Hidden from index |

---

#### TC-P08: Trash Page Shows Deleted Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete an assessment type | Record in trash |
| 2 | Click "Trash" button / navigate to `/assessment-type/trash/view` | Trash page loads with breadcrumb: Assessment Types > Trash |
| 3 | Check table headers | Code, Name, Usage Type, Status, Action |
| 4 | Check deleted record | Shows code, name, usage type, "Deleted" badge |
| 5 | Check Restore button | Present (if restore permission) |
| 6 | Check Force Delete button | Present (if forceDelete permission) |
| 7 | Empty state: no deleted records | "No Data Found" message |

---

#### TC-P09: Restore Assessment Type From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash page (type "RESTORETEST" is soft-deleted) | Trash shows the record |
| 2 | Click "Restore" on that row | SweetAlert confirmation |
| 3 | Confirm | Restore succeeds |
| 4 | Check flash | "Assessment type restored successfully" |
| 5 | DB check: `SELECT deleted_at, is_active FROM lms_assessment_types WHERE id=X` | deleted_at=NULL, is_active=1 |
| 6 | Navigate to main list | Record visible again |
| 7 | Activity log: "Restored" event | Message "Assessment type restored." |

---

#### TC-P10: Force Delete Assessment Type (No Dependencies)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create unused type: code="FORCEDEL" then soft delete | Record in trash |
| 2 | Navigate to trash page | Trash shows "FORCEDEL" |
| 3 | Click "Force Delete" | Confirmation prompt |
| 4 | Confirm | Force delete succeeds |
| 5 | Check flash | "Assessment type deleted successfully" |
| 6 | DB check: `SELECT * FROM lms_assessment_types WHERE code='FORCEDEL'` WITH trashed | Record permanently gone |
| 7 | Activity log: "Deleted" event | Message "Assessment type permanently deleted." |

---

#### TC-P11: Toggle Status Active ↔ Inactive (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type: code="TOGGLETEST", is_active=ON | Record active |
| 2 | Click the status toggle switch on that row | AJAX POST to `/assessment-type/{id}/toggle-status` with `{is_active: false}` |
| 3 | Check JSON response | `{success: true, is_active: false, message: "..."}` |
| 4 | DB check: `SELECT is_active FROM lms_assessment_types WHERE id=X` | is_active=0 |
| 5 | Click toggle again | AJAX POST with `{is_active: true}` |
| 6 | DB check | is_active=1 |
| 7 | Activity log: 2 "Toggled" events | Both toggles logged |

---

#### TC-P12: Pagination (10 Per Page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 11+ assessment types | Records exist |
| 2 | Navigate to assessment types list | Page 1 shows first 10 records |
| 3 | Check pagination links | Pagination bar with page 2 |
| 4 | Click page 2 | Remaining records displayed; `active_tab=assessment_type` param preserved in URL |

---

### 7.2 Negative TC Steps

#### TC-N01: Empty Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form, leave code empty, fill other required fields | Code field empty |
| 2 | Click Save | Validation error: code required |

---

#### TC-N02: Code Max 50

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code with 51+ characters | Exceeds max |
| 2 | Click Save | Validation error: code max 50 |

---

#### TC-N03: Duplicate Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type with code="DUPE" | Code taken |
| 2 | Create another type with code="DUPE" | "An assessment type with this code already exists." |

---

#### TC-N04: Empty Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave name empty | Name field empty |
| 2 | Click Save | Validation error: name required |

---

#### TC-N05: Name Max 100

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter name with 101+ characters | Exceeds max |
| 2 | Click Save | Validation error: name max 100 |

---

#### TC-N06: Description Max 255

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter description with 256+ characters | Exceeds max |
| 2 | Click Save | Validation error: description max 255 |

---

#### TC-N07: No Usage Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave usage type unselected | Dropdown empty |
| 2 | Click Save | Validation error: usage type required |

---

#### TC-N08: Invalid Usage Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter invalid assessment_usage_type_id (99999) | Invalid ID |
| 2 | Click Save | "The selected usage type is invalid." |

---

#### TC-N09: Duplicate Code on Edit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type A with code="SHARED" | Code taken |
| 2 | Edit type B, change code to "SHARED" | "An assessment type with this code already exists." |

---

#### TC-N10: Edit Blocked by Quiz Usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type: code="USEDTYPE" | Type created |
| 2 | Create a quiz with quiz_type_id = USEDTYPE.id | Quiz references this type |
| 3 | Click "Edit" on USEDTYPE | Usage check blocks: redirect to index with error "This assessment type is used in: LmsQuiz (1 quizzes). Therefore cannot be edited." |

---

#### TC-N17: View Non-Existent Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open URL: `/lms-quize/assessment-type/99999` | 404 error page |

---

#### TC-N22: Toggle Status Non-Existent Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `/lms-quize/assessment-type/99999/toggle-status` with `{is_active: true}` | 500 error (unhandled ModelNotFoundException) or redirected to 404 |

---

#### TC-N24: Permission 403 — viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.assessment-type.viewAny` | User authenticated |
| 2 | Navigate to assessment types tab | 403 Forbidden |

---

#### TC-N25: Permission 403 — create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without create permission | User authenticated |
| 2 | POST to store | 403 Forbidden |
| 3 | Check Create button visibility | "Add New" button NOT visible |

---

#### TC-N26: Permission 403 — update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without update permission | User authenticated |
| 2 | GET edit page | 403 Forbidden |
| 3 | PUT to update | 403 Forbidden |
| 4 | POST to toggleStatus | 403 Forbidden |
| 5 | Check Edit button visibility | Pencil icon NOT visible |

---

#### TC-N27: Permission 403 — delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without delete permission | User authenticated |
| 2 | DELETE to destroy | 403 Forbidden |
| 3 | Check Delete button visibility | Trash icon NOT visible |

---

#### TC-N28: Permission 403 — restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without restore permission | User authenticated |
| 2 | GET trash page | 403 Forbidden |
| 3 | GET restore route | 403 Forbidden |

---

#### TC-N29: Permission 403 — forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without forceDelete permission | User authenticated |
| 2 | DELETE to forceDelete | 403 Forbidden |

---

### 7.3 Dependency TC Steps

#### TC-D01: Edit Blocked by Quiz Usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type T1: code="QUIZBLOCK" | T1 created |
| 2 | Create a quiz Q1 with quiz_type_id = T1.id | Quiz references T1 |
| 3 | Navigate to assessment types list | T1 visible |
| 4 | Click Edit on T1 | Usage check: Quiz Q1 references this type |
| 5 | Verify block | Redirect with: "This assessment type is used in: LmsQuiz (1 quizzes). Therefore cannot be edited." |

---

#### TC-D06: Soft Delete Sets is_active False

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type T1: code="DELTEST", is_active=1 | is_active=1 |
| 2 | Delete T1 (not used) | Delete succeeds |
| 3 | DB check: `SELECT is_active, deleted_at FROM lms_assessment_types WHERE id=T1` | is_active=0, deleted_at NOT NULL |

---

#### TC-D07: Restore Sets is_active True

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type T1, soft delete | T1 in trash, is_active=0 |
| 2 | Restore T1 | Restore succeeds |
| 3 | DB check: `SELECT is_active, deleted_at FROM lms_assessment_types WHERE id=T1` | is_active=1, deleted_at=NULL |

---

#### TC-D10: Toggle — Inactive Hidden From Quiz Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type T1: code="HIDETEST", is_active=1, usage_type=QUIZ | T1 active |
| 2 | Navigate to quiz create form, check assessment type dropdown | T1 visible |
| 3 | Toggle T1 to inactive (is_active=0) | Toggle success |
| 4 | Refresh quiz create form, check dropdown | T1 NOT visible |
| 5 | Toggle T1 back to active | T1 visible again |

---

#### TC-D11: Show — Usage Details Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type T1: code="USAGESHOW" | T1 created |
| 2 | Create a quiz with quiz_type_id = T1.id | 1 quiz |
| 3 | Create a quest with quest_type_id = T1.id | 1 quest |
| 4 | Open T1 show page | Page loads |
| 5 | Check Usage Details section | Card with "LmsQuiz — Quiz Type — Count: 1 — Used" and "LmsQuests — Quest Type — Count: 1 — Used" |

---

### 7.4 Code Review TC Steps

#### TC-CR19: update() activityLog 'Updated' Event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create assessment type with code="CRUPDATETEST", name="Original Name" | Record exists, ID=X |
| 2 | Open edit form and change name to "Updated Name" | Name changed |
| 3 | Submit update form | PUT request succeeds |
| 4 | Query `activity_log` table: `SELECT * FROM activity_log WHERE subject_type='Modules\LmsQuiz\Models\AssessmentType' AND subject_id=X AND event='Updated'` | One row returned |
| 5 | Inspect `properties` column from the activity log row | JSON contains `changes` object with only `name` field (`old: "Original Name"`, `new: "Updated Name"`); `message` = "Assessment type was updated." |
| 6 | Verify `performed_by` matches the authenticated user's name | User name present in properties |

#### TC-CR20: restore() activityLog 'Restored' Event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create assessment type with code="CRRESTORETEST", soft delete it | Record in trash (deleted_at NOT NULL) |
| 2 | Navigate to trash and click Restore | Restore succeeds |
| 3 | Query `activity_log` table: `SELECT * FROM activity_log WHERE subject_type='Modules\LmsQuiz\Models\AssessmentType' AND subject_id=X AND event='Restored'` | One row returned |
| 4 | Inspect `properties` column | `message` = "Assessment type restored."; `performed_by` = authenticated user name |
| 5 | Verify `properties->attributes` or timestamp | deleted_at cleared in DB; no changes array (restore logs only message) |

#### TC-CR21: forceDelete() activityLog 'Deleted' Event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create assessment type with code="CRFORCEDELTEST", soft delete it | Record in trash |
| 2 | Navigate to trash and click Force Delete | Force delete succeeds |
| 3 | Query `activity_log` table: `SELECT * FROM activity_log WHERE subject_type='Modules\LmsQuiz\Models\AssessmentType' AND subject_id=X AND event='Deleted'` | One row returned |
| 4 | Inspect `properties` column | `message` = "Assessment type permanently deleted."; `performed_by` = authenticated user name |
| 5 | Verify record is permanently removed from `lms_assessment_types` | `SELECT * FROM lms_assessment_types WHERE id=X` returns 0 rows (including trashed) |

#### TC-CR22: toggleStatus() activityLog 'Toggled' Event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create assessment type with code="CRTOGGLETEST", is_active=ON | Record active |
| 2 | Click status toggle to deactivate | AJAX toggle succeeds; is_active=0 |
| 3 | Query `activity_log` table: `SELECT * FROM activity_log WHERE subject_type='Modules\LmsQuiz\Models\AssessmentType' AND subject_id=X AND event='Toggled' ORDER BY id DESC` | One row returned; `message` = "Assessment type status updated." |
| 4 | Click status toggle to reactivate | AJAX toggle succeeds; is_active=1 |
| 5 | Query `activity_log` table again | Two distinct 'Toggled' rows exist for subject_id=X |
| 6 | Compare `properties` between the two rows | Both have `message: "Assessment type status updated."` and `performed_by` set; each logged at its respective timestamp |

---

## 8. Known Issues

| # | Issue | Details |
|---|-------|---------|
| 1 | Request gate name mismatch | `AssessmentTypeRequest::authorize()` uses `tenant.lms-assessment-type.*` but Policy uses `tenant.assessment-type.*` — one of these may fail depending on which Gate is registered |
| 2 | toggleStatus non-existent record returns 500 | `findOrFail()` is NOT wrapped in try-catch in `toggleStatus()` — invalid ID throws unhandled ModelNotFoundException |
| 3 | Description NOT nullable in request | Blade shows description as required (`:required="true"`) but DB allows null; `AssessmentTypeRequest` has `nullable` for description — may cause UI confusion |
| 4 | is_active default in prepareForValidation | `$this->has('is_active') ? $this->boolean('is_active') : false` — if checkbox is present but unchecked, `$this->has('is_active')` is true but `$this->boolean('is_active')` returns false, so it's correct. However, the blade default `old('is_active', true)` may cause confusion |
| 5 | No is_system_generated field | Old TC assumed this field exists; actual model does NOT have it |
| 6 | No image/media upload | Old TC assumed Spatie MediaLibrary; actual views have NO image upload |

---

## 9. Route Reference

| Method | URL | Action | Route Name |
|--------|-----|--------|------------|
| GET | `/lms-quize/assessment-type` | index | `assessment-type.index` |
| GET | `/lms-quize/assessment-type/create` | create | `assessment-type.create` |
| POST | `/lms-quize/assessment-type` | store | `assessment-type.store` |
| GET | `/lms-quize/assessment-type/{assessment_type}` | show | `assessment-type.show` |
| GET | `/lms-quize/assessment-type/{assessment_type}/edit` | edit | `assessment-type.edit` |
| PUT | `/lms-quize/assessment-type/{assessment_type}` | update | `assessment-type.update` |
| DELETE | `/lms-quize/assessment-type/{assessment_type}` | destroy | `assessment-type.destroy` |
| GET | `/lms-quize/assessment-type/trash/view` | trashed | `assessment-type.trashed` |
| GET | `/lms-quize/assessment-type/{id}/restore` | restore | `assessment-type.restore` |
| DELETE | `/lms-quize/assessment-type/{id}/force-delete` | forceDelete | `assessment-type.forceDelete` |
| POST | `/lms-quize/assessment-type/{assessment_type}/toggle-status` | toggleStatus | `assessment-type.toggleStatus` |

---

## 10. Execution Status

| TC ID | Test Name | Type | Status | Date | Tester | Remarks |
|-------|-----------|------|--------|------|--------|---------|
| TC-P01 | List Page Load | Positive | ⬜ | — | — | — |
| TC-P02 | Create All Required | Positive | ⬜ | — | — | — |
| TC-P03 | Create With Description | Positive | ⬜ | — | — | — |
| TC-P04 | Create Inactive | Positive | ⬜ | — | — | — |
| TC-P05 | Create Each Usage Type | Positive | ⬜ | — | — | — |
| TC-P06 | Search | Positive | ⬜ | — | — | — |
| TC-P07 | Filter by Usage Type | Positive | ⬜ | — | — | — |
| TC-P08 | Filter by Status | Positive | ⬜ | — | — | — |
| TC-P09 | View Details | Positive | ⬜ | — | — | — |
| TC-P10 | Edit Name | Positive | ⬜ | — | — | — |
| TC-P11 | Edit Code | Positive | ⬜ | — | — | — |
| TC-P12 | Edit Usage Type | Positive | ⬜ | — | — | — |
| TC-P13 | Edit Toggle is_active | Positive | ⬜ | — | — | — |
| TC-P14 | Soft Delete | Positive | ⬜ | — | — | — |
| TC-P15 | Trash Page | Positive | ⬜ | — | — | — |
| TC-P16 | Restore | Positive | ⬜ | — | — | — |
| TC-P17 | Toggle Status AJAX | Positive | ⬜ | — | — | — |
| TC-P18 | Force Delete | Positive | ⬜ | — | — | — |
| TC-P19 | Pagination | Positive | ⬜ | — | — | — |
| TC-P20 | Empty State | Positive | ⬜ | — | — | — |
| TC-N01 | Empty Code | Negative | ⬜ | — | — | — |
| TC-N02 | Code Max 50 | Negative | ⬜ | — | — | — |
| TC-N03 | Duplicate Code | Negative | ⬜ | — | — | — |
| TC-N04 | Empty Name | Negative | ⬜ | — | — | — |
| TC-N05 | Name Max 100 | Negative | ⬜ | — | — | — |
| TC-N06 | Description Max 255 | Negative | ⬜ | — | — | — |
| TC-N07 | No Usage Type | Negative | ⬜ | — | — | — |
| TC-N08 | Invalid Usage Type | Negative | ⬜ | — | — | — |
| TC-N09 | Duplicate Code on Edit | Negative | ⬜ | — | — | — |
| TC-N10 | Edit Blocked by Quiz | Negative | ⬜ | — | — | — |
| TC-N11 | Edit Blocked by Quest | Negative | ⬜ | — | — | — |
| TC-N12 | Update Blocked by Usage | Negative | ⬜ | — | — | — |
| TC-N13 | Delete Blocked by Usage | Negative | ⬜ | — | — | — |
| TC-N14 | Force Delete — Quiz Refs | Negative | ⬜ | — | — | — |
| TC-N15 | Force Delete — Quest Refs | Negative | ⬜ | — | — | — |
| TC-N16 | Force Delete — Both Refs | Negative | ⬜ | — | — | — |
| TC-N17 | View Invalid ID 404 | Negative | ⬜ | — | — | — |
| TC-N18 | Edit Invalid ID 404 | Negative | ⬜ | — | — | — |
| TC-N19 | Delete Invalid ID 404 | Negative | ⬜ | — | — | — |
| TC-N20 | Restore Invalid ID 404 | Negative | ⬜ | — | — | — |
| TC-N21 | Force Delete Invalid ID 404 | Negative | ⬜ | — | — | — |
| TC-N22 | Toggle Invalid ID 500 | Negative | ⬜ | — | — | — |
| TC-N23 | Toggle Invalid Boolean | Negative | ⬜ | — | — | — |
| TC-N24 | Permission 403 — viewAny | Negative | ⬜ | — | — | — |
| TC-N25 | Permission 403 — create | Negative | ⬜ | — | — | — |
| TC-N26 | Permission 403 — update | Negative | ⬜ | — | — | — |
| TC-N27 | Permission 403 — delete | Negative | ⬜ | — | — | — |
| TC-N28 | Permission 403 — restore | Negative | ⬜ | — | — | — |
| TC-N29 | Permission 403 — forceDelete | Negative | ⬜ | — | — | — |
| TC-N30 | Guest Redirect | Negative | ⬜ | — | — | — |
| TC-D01 | Edit Blocked by Quiz | Dependency | ⬜ | — | — | — |
| TC-D02 | Edit Blocked by Quest | Dependency | ⬜ | — | — | — |
| TC-D03 | Delete Blocked by Quiz | Dependency | ⬜ | — | — | — |
| TC-D04 | Force Delete Blocked by Quiz | Dependency | ⬜ | — | — | — |
| TC-D05 | Force Delete Blocked by Quest | Dependency | ⬜ | — | — | — |
| TC-D06 | Soft Delete — is_active=false | Dependency | ⬜ | — | — | — |
| TC-D07 | Restore — is_active=true | Dependency | ⬜ | — | — | — |
| TC-D08 | Update — Change Detection | Dependency | ⬜ | — | — | — |
| TC-D09 | Update — No Changes | Dependency | ⬜ | — | — | — |
| TC-D10 | Toggle — Inactive Hidden From Dropdown | Dependency | ⬜ | — | — | — |
| TC-D11 | Show — Usage Details | Dependency | ⬜ | — | — | — |
| TC-D12 | Show — No Usage Section | Dependency | ⬜ | — | — | — |
| TC-D13 | Force Delete Exception Handling | Dependency | ⬜ | — | — | — |

**Summary:** 20 Positive ⬜, 30 Negative ⬜, 13 Dependency ⬜, 18 Code Review ◌ = 81 total

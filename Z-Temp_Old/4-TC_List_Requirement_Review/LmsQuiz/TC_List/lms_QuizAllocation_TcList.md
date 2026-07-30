# lms_QuizAllocation_TcList

## Module: LmsQuiz → Quiz Management → Quiz Allocation

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuiz |
| Tab Group | Quiz Management |
| Feature | Quiz Allocation |
| URL(s) | `/lms-quize/quiz-allocation` (resource index/create/store/show/edit/update/destroy), `/lms-quize/quiz-allocation/trash/view` (trashed), `/lms-quize/quiz-allocation/{id}/restore` (restore), `/lms-quize/quiz-allocation/{id}/force-delete` (forceDelete), `/lms-quize/quiz-allocation/{quiz_allocation}/toggle-status` (toggleStatus), `/lms-quize/quiz-allocation/{id}/publish-recommendations` (publishRecommendations), `/lms-quize/quiz-allocation/get-target-options` (AJAX), `/lms-quize/quiz-allocation/get-quizzes` (AJAX) |
| Controller | `Modules\LmsQuiz\Http\Controllers\QuizAllocationController` |
| Model(s) | `QuizAllocation` (`Modules\LmsQuiz\Models\QuizAllocation`) — single table with allocation_type + target_id |
| Validation | `QuizAllocationRequest` (`Modules\LmsQuiz\Http\Requests\QuizAllocationRequest`) — single request |
| Permission Gates | `tenant.quiz-allocation.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete` (no status gate in Policy) |
| Soft Deletes | Yes — `SoftDeletes` trait on QuizAllocation |
| Activity Log | Yes — `activityLog()` called in store, update, destroy, restore, forceDelete, toggleStatus |

---

## 2. Pre-conditions

- Required permission: `tenant.quiz-allocation.viewAny`
- At least one active Quiz must exist (`is_active=1`)
- Target entities must exist (Classes, Sections, Groups, or Students)
- Due date must be future (after_or_equal:now)

---

## 3. Default Data Load

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Allocation List | `QuizAllocation::with(['quiz','assigner'])` | Filters by quiz_id, allocation_type, target_id, is_active, date_range | quiz_id, allocation_type, target_id, is_active, date_range | 10 per page |
| Single Allocation | `QuizAllocation::with(['quiz','assigner'])->findOrFail($id)` | By ID | None |
| Quizzes (dropdown + AJAX) | `Quiz::where('is_active','1')->with('class')->orderBy('title')` | Supports unallocated_only filter | |
| Classes (dropdown) | `SchoolClass::where('is_active','1')->get()` | | |
| Sections (dropdown) | `Section::where('is_active','1')->orderBy('name')->get()` | | |
| Groups (dropdown) | `EntityGroup::where('is_active','1')->orderBy('name')->get()` | | |
| Students (dropdown) | `Student::where('is_active','1')->with('user')->get()` | Formatted as "Name (StudentID)" | |
| Target Options (AJAX) | Varies by allocation_type (CLASS/SECTION/GROUP/STUDENT) | | |
| Quizzes (AJAX) | `Quiz::where('is_active','1')->when(unallocated_only, fn=>whereDoesntHave('allocations'))` | | |
| Usage Details | `QuizAllocationUsageCheckService::getUsageDetails($id)` | Attempt counts, status breakdown, scores | |

---

## 4. Test Data Strategy

- **Single Table Allocation**: No separate targets table. Allocation stores a SINGLE target via `allocation_type` (CLASS/SECTION/GROUP/STUDENT) + `target_id`
- **Date Fields**: `published_at` (optional, when allocation goes live), `due_date` (required, deadline), `cut_off_date` (optional hard cutoff, defaults to due_date), `result_publish_date` (optional)
- **Published Lock**: Once allocation is published (past published_at), the published_at field becomes immutable
- **Auto-Publish Result**: Boolean flag; when true, automatically publishes recommendations for students. When toggled on during update, triggers publishHiddenRecommendations()
- **Usage Check**: `QuizAllocationUsageCheckService` checks for attempts by quiz_allocation_id. Blocks edit/update/destroy if attempts exist
- **Force Delete**: Checks for attempts AND results (via HasManyThrough to QuizQuestResult) before allowing permanent deletion
- **Recommendations Publishing**: `publishRecommendations()` manually triggers publishing of hidden recommendations for a given allocation
- **Allocation Types**: CLASS (target=SchoolClass), SECTION (target=ClassSection junction), GROUP (target=EntityGroup), STUDENT (target=Student)

---

## 5. Business Conditions

### 5.1 Database Schema

Table: `lms_quiz_allocations`

| Column | Type | Constraints | Default | Notes |
|--------|------|-------------|---------|-------|
| id | bigint(20) unsigned | PK, AUTO_INCREMENT | | |
| quiz_id | bigint(20) unsigned | INDEX, FK → lms_quizzes.id | | |
| allocation_type | varchar(20) | | | CLASS, SECTION, GROUP, or STUDENT |
| target_table_name | varchar(100) | | | Resolved table name (sch_classes, sch_class_section_jnt, etc.) |
| target_id | bigint(20) unsigned | | | ID of the target entity |
| assigned_by | bigint(20) unsigned | INDEX | | FK → sys_users.id |
| published_at | datetime | NULLABLE | NULL | When allocation goes live |
| due_date | datetime | | | Required deadline |
| cut_off_date | datetime | NULLABLE | NULL | Hard cutoff (defaults to due_date) |
| is_auto_publish_result | tinyint(1) | | 0 | Auto-publish recommendations |
| result_publish_date | datetime | NULLABLE | NULL | When to publish results |
| is_active | tinyint(1) | | 1 | Boolean |
| created_at | timestamp | | CURRENT_TIMESTAMP | |
| updated_at | timestamp | | ON UPDATE CURRENT_TIMESTAMP | |
| deleted_at | timestamp | NULLABLE | NULL | |

Accessors: `targetName` — resolves human-readable label from allocation_type + target_id. `isPublished()` — checks `published_at <= now()`. `isOverdue()` — checks `due_date < now()`. `isBeforeCutoff()` — checks `now() <= cut_off_date`.

### 5.2 Validation Rules — QuizAllocationRequest

| BC ID | Field | Rule | Notes |
|-------|-------|------|-------|
| BC-VAL-01 | quiz_id | required, exists:lms_quizzes,id + custom: quiz must be active | Custom closure checks `$quiz->is_active` |
| BC-VAL-02 | allocation_type | required, in:CLASS,SECTION,GROUP,STUDENT | |
| BC-VAL-03 | class_id | nullable, exists:sch_classes,id | For SECTION type, used to validate class+section combo |
| BC-VAL-04 | target_id | required, integer, min:1 + exists on target table (with is_active=1) | Target table resolved from allocation_type |
| BC-VAL-05 | target_id (SECTION) | Custom: validates ClassSection junction exists | Checks class_id + section_id in ClassSection table |
| BC-VAL-06 | published_at | nullable, date; if allocation published, locked to original value | Immutable once past published_at |
| BC-VAL-07 | due_date | required, date, after_or_equal:now, max 2 years in future | |
| BC-VAL-08 | cut_off_date | nullable, date, after_or_equal:due_date, max 2 years | |
| BC-VAL-09 | is_auto_publish_result | boolean | |
| BC-VAL-10 | result_publish_date | nullable, date, after_or_equal:due_date; prohibited if auto_publish=false | |
| BC-VAL-11 | is_active | boolean | |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Policy Method | Controller Method | Behavior Without |
|-------|-----------|---------------|-------------------|-----------------|
| BC-AUTH-01 | tenant.quiz-allocation.viewAny | viewAny() | index() | 403 |
| BC-AUTH-02 | tenant.quiz-allocation.view | view() | show() | 403 |
| BC-AUTH-03 | tenant.quiz-allocation.create | create() | create(), store() | 403 |
| BC-AUTH-04 | tenant.quiz-allocation.update | update() | edit(), update(), toggleStatus(), publishRecommendations() | 403 |
| BC-AUTH-05 | tenant.quiz-allocation.delete | delete() | destroy() | 403 |
| BC-AUTH-06 | tenant.quiz-allocation.restore | restore() | trashed(), restore() | 403 |
| BC-AUTH-07 | tenant.quiz-allocation.forceDelete | forceDelete() | forceDelete() | 403 |

Note: Policy does NOT define a `status` gate. toggleStatus() and publishRecommendations() use `tenant.quiz-allocation.update`.

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create allocation — CLASS type | Allocation created with allocation_type=CLASS, target_id=class_id, target_table_name=sch_classes |
| BC-BIZ-02 | Create allocation — SECTION type | Queries ClassSection junction for class_id+section_id; stores the junction ID as target_id |
| BC-BIZ-03 | Create allocation — GROUP type | Allocation created with allocation_type=GROUP, target_id=group_id |
| BC-BIZ-04 | Create allocation — STUDENT type | Allocation created with allocation_type=STUDENT, target_id=student_id |
| BC-BIZ-05 | Create allocation — cut_off_date not provided | Defaults to due_date |
| BC-BIZ-06 | Create allocation — is_auto_publish_result=false | result_publish_date forced to null |
| BC-BIZ-07 | Update allocation — has attempts | Blocked: "Cannot update... students have already started attempts." |
| BC-BIZ-08 | Update allocation — auto_publish_result enabled | Triggers publishHiddenRecommendations() for all students who attempted |
| BC-BIZ-09 | Update allocation — published lock | If allocation.published_at is in the past, the published_at field cannot be changed |
| BC-BIZ-10 | Destroy allocation — has attempts | Blocked: "Cannot delete... students have already started attempts." |
| BC-BIZ-11 | Destroy allocation — no attempts | Soft delete: sets is_active=false, calls delete() |
| BC-BIZ-12 | Restore allocation | Restores; sets is_active=true |
| BC-BIZ-13 | Force delete allocation — has attempts or results | Blocked: "Cannot permanently delete... students have already started or submitted attempts." |
| BC-BIZ-14 | Toggle status (toggleStatus AJAX) | is_active toggled; JSON response |
| BC-BIZ-15 | Publish recommendations (publishRecommendations) | Finds all non-published recommendations for this allocation's students and publishes them |
| BC-BIZ-16 | Show allocation — usage details | Displays attempt stats (total, in-progress, submitted, passed, failed, avg score, avg %) |
| BC-BIZ-17 | GET target options AJAX | Returns filtered targets based on allocation_type |
| BC-BIZ-18 | GET quizzes AJAX | Returns quizzes (optionally unallocated only) with class info |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | quiz_id | lms_quizzes (id) | CASCADE |
| BC-REF-02 | assigned_by | sys_users (id) | — |
| BC-REF-03 | id (lms_quiz_allocations) | lms_quiz_quest_attempts (quiz_allocation_id) | — |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | Status |
|-------|-------------|----------------|--------|
| TC-P01 | Create Allocation — CLASS type | Allocation created with allocation_type=CLASS, target_id=class_id, target_table_name=sch_classes | ⬜ |
| TC-P02 | Create Allocation — SECTION type with class_id | ClassSection junction resolved; target_id=junction_id | ⬜ |
| TC-P03 | Create Allocation — GROUP type | Allocation created with allocation_type=GROUP, target_id=group_id | ⬜ |
| TC-P04 | Create Allocation — STUDENT type | Allocation created with allocation_type=STUDENT, target_id=student_id | ⬜ |
| TC-P05 | Create Allocation — with cut_off_date | cut_off_date saved; independent from due_date | ⬜ |
| TC-P06 | Create Allocation — cut_off_date not provided | Defaults to due_date | ⬜ |
| TC-P07 | Create Allocation — is_auto_publish_result=true | Flag set; result_publish_date can be set | ⬜ |
| TC-P08 | Create Allocation — is_auto_publish_result=false | result_publish_date forced to null | ⬜ |
| TC-P09 | View Allocation List | Paginated list with quiz title, allocation type, target name, dates | ⬜ |
| TC-P10 | View Single Allocation (show) | Details with target name, attempt stats (if allocated) | ⬜ |
| TC-P11 | View Single Allocation — with attempts | Usage details card with attempt breakdown (total, in-progress, passed, failed, avg scores) | ⬜ |
| TC-P12 | Edit Allocation — Change due_date (no attempts) | due_date updated | ⬜ |
| TC-P13 | Edit Allocation — Change target (no attempts) | allocation_type + target_id updated; target_table_name recalculated | ⬜ |
| TC-P14 | Edit Allocation — Enable is_auto_publish_result after creation | Flag enabled; triggers publishHiddenRecommendations() for existing attempts | ⬜ |
| TC-P15 | Soft Delete Allocation (no attempts) | is_active=false; soft-deleted | ⬜ |
| TC-P16 | Restore Allocation | Restored; is_active=true | ⬜ |
| TC-P17 | Force Delete Allocation (no attempts/results) | Permanently deleted | ⬜ |
| TC-P18 | Toggle Status (toggleStatus AJAX) | is_active toggled; JSON response | ⬜ |
| TC-P19 | Publish Recommendations (publishRecommendations) | Hidden recommendations published; success message | ⬜ |
| TC-P20 | AJAX getTargetOptions — CLASS type | Returns class list with id + name | ⬜ |
| TC-P21 | AJAX getQuizzes — unallocated_only=true | Only quizzes without allocations returned | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | Status |
|-------|-------------|----------------|--------|
| TC-N01 | Create — Empty quiz_id | Validation error: Please select a quiz | ⬜ |
| TC-N02 | Create — Quiz is inactive | Validation error: The selected quiz is not active | ⬜ |
| TC-N03 | Create — Invalid quiz_id | Validation error: does not exist | ⬜ |
| TC-N04 | Create — Invalid allocation_type | Validation error: in:CLASS,SECTION,GROUP,STUDENT | ⬜ |
| TC-N05 | Create — Empty target_id | Validation error: Please select a target | ⬜ |
| TC-N06 | Create — Invalid target_id (not in target table) | Validation error: is invalid or not active | ⬜ |
| TC-N07 | Create — SECTION type with invalid class+section combo | Validation error: class and section combination does not exist | ⬜ |
| TC-N08 | Create — Empty due_date | Validation error: Due date is required | ⬜ |
| TC-N09 | Create — due_date in the past | Validation error: must be a future or current date | ⬜ |
| TC-N10 | Create — due_date more than 2 years in future | Validation error: cannot be more than 2 years | ⬜ |
| TC-N11 | Create — cut_off_date before due_date | Validation error: must be on or after due date | ⬜ |
| TC-N12 | Create — cut_off_date more than 2 years | Validation error: cannot be more than 2 years | ⬜ |
| TC-N13 | Create — result_publish_date but auto_publish_result=false | Validation error: result_publish_date cannot be set when auto publish is disabled | ⬜ |
| TC-N14 | Create — result_publish_date before due_date | Validation error: must be on or after due_date | ⬜ |
| TC-N15 | Edit — allocation has attempts (blocked) | Error: "Cannot update... students have already started attempts." | ⬜ |
| TC-N16 | Edit — allocation published, try to change published_at | Validation error: "publish date cannot be changed once the allocation is live." | ⬜ |
| TC-N17 | Destroy — allocation has attempts (blocked) | Error: "Cannot delete... students have already started attempts." | ⬜ |
| TC-N18 | Force Delete — allocation has attempts | Error: "Cannot permanently delete... students have already started or submitted attempts." | ⬜ |
| TC-N19 | Force Delete — allocation has results | Error: "Cannot permanently delete... students have already started or submitted attempts." | ⬜ |
| TC-N20 | View — without permission | 403 Forbidden | ⬜ |
| TC-N21 | Create — without permission | 403 Forbidden | ⬜ |
| TC-N22 | Edit — without permission | 403 Forbidden | ⬜ |
| TC-N23 | Delete — without permission | 403 Forbidden | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Priority | Description | Expected Result | Status |
|-------|----------|----------|-------------|----------------|--------|
| TC-D01 | Cascade — Quiz Delete | P1 | Soft delete quiz → verify allocations cascade-deleted | Allocation.deleted_at set via FK cascade | ⬜ |
| TC-D02 | Business — Published Lock | P1 | Create allocation with past published_at → verify published_at field locked on edit | Update with new published_at fails validation | ⬜ |
| TC-D03 | Business — Recommendations Publishing | P1 | Update allocation with is_auto_publish_result=true → verify hidden recommendations published | StudentRecommendation.is_published flipped to true | ⬜ |
| TC-D04 | Business — Attempt count tracking | P1 | Students attempt quiz → verify show() displays correct attempt stats | Usage details match actual attempt records | ⬜ |
| TC-D05 | Business — Auto-publish on creation | P2 | Create allocation with is_auto_publish_result=true → verify no publish triggered yet | publishHiddenRecommendations only triggers on update flip, not create | ⬜ |
| TC-D06 | Soft Delete — attempts unaffected | P2 | Soft delete allocation with existing attempts → verify attempts NOT cascade-deleted | Attempts retain quiz_allocation_id; allocation hidden | ⬜ |
| TC-D07 | Business — AJAX target filter scoping | P1 | getTargetOptions with allocation_type=STUDENT → verify only active students returned | Inactive or soft-deleted students excluded | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | Status |
|-------|----------|----------|-------------|----------------|--------|
| TC-CR01 | CR | P1 | Request — quiz active check | Custom closure in quiz_id rule checks `$quiz->is_active` | ◌ |
| TC-CR02 | CR | P1 | Request — published_at immutable lock | If allocation published, custom rule compares original published_at with submitted value | ◌ |
| TC-CR03 | CR | P1 | Request — SECTION type validation | Custom rule validates ClassSection junction exists for class_id + section_id combo | ◌ |
| TC-CR04 | CR | P1 | Controller store() — cut_off_date default | If cut_off_date not provided, sets it same as due_date | ◌ |
| TC-CR05 | CR | P1 | Controller store() — auto-publish result_publish_date null | If is_auto_publish_result=false, forces result_publish_date=null | ◌ |
| TC-CR06 | CR | P1 | Controller update() — usage check | Calls QuizAllocationUsageCheckService.isUsed() before allowing update | ◌ |
| TC-CR07 | CR | P1 | Controller update() — recommendation publishing | If auto_publish was just enabled, calls publishHiddenRecommendations() | ◌ |
| TC-CR08 | CR | P1 | Controller destroy() — usage check | Calls isUsed() before soft delete | ◌ |
| TC-CR09 | CR | P1 | Controller forceDelete() — dependency check | Checks `$allocation->attempts()->exists() \|\| $allocation->results()->exists()` | ◌ |
| TC-CR10 | CR | P1 | Controller destroy() — sets inactive before delete | `$allocation->update(['is_active' => false])` then `$allocation->delete()` | ◌ |
| TC-CR11 | CR | P1 | Controller restore() — sets active | `$allocation->restore()` then `$allocation->update(['is_active' => true])` | ◌ |
| TC-CR12 | CR | P2 | Model — targetName accessor | Resolves human-readable name from allocation_type + target_id via switch | ◌ |
| TC-CR13 | CR | P2 | Model — results() HasManyThrough | Goes through QuizQuestAttempt to reach QuizQuestResult | ◌ |
| TC-CR14 | CR | P2 | Request — getTargetTable() | Maps allocation_type to DB table name for exists validation | ◌ |
| TC-CR15 | CR | P1 | Controller store() — activityLog created event | Controller calls activityLog() with event='Created' after successful insert | ◌ |
| TC-CR16 | CR | P1 | Controller restore() — activityLog restored event | Controller calls activityLog() with event='Restored' after successful restore | ◌ |
| TC-CR17 | CR | P1 | Controller forceDelete() — activityLog deleted event | Controller calls activityLog() with event='Deleted' after permanent delete | ◌ |
| TC-CR18 | CR | P1 | Controller toggleStatus() — activityLog toggled event | Controller calls activityLog() with event='Toggled' after status change | ◌ |
 
---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Create CLASS Type Allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials having `tenant.quiz-allocation.create` permission | Dashboard loads |
| 2 | Navigate to Quiz Allocations → Create | Create form loads with quiz dropdown, allocation type, target, and date fields |
| 3 | Select a Quiz (must be active) | Quiz selected |
| 4 | Select Allocation Type = CLASS | Target dropdown populated with active classes |
| 5 | Select a Class from dropdown | Class selected |
| 6 | Set Published At (optional, leave blank or set future date) | Published at set |
| 7 | Set Due Date to a future date (e.g., +7 days) | Due date set |
| 8 | Optionally set Cut-off Date | Cut-off date set |
| 9 | Toggle Auto Publish Result as needed | Flag set |
| 10 | Click Submit | POST request to store |
| 11 | Verify redirect to allocation index | Redirected with success flash message |
| 12 | DB check: `SELECT * FROM lms_quiz_allocations ORDER BY id DESC LIMIT 1` | allocation_type='CLASS', target_id=class_id, target_table_name='sch_classes', is_active=1, assigned_by=current_user |

---

#### TC-P02: Create SECTION Type Allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Quiz Allocations → Create | Create form loads |
| 2 | Select a Quiz (must be active) | Quiz selected |
| 3 | Select Allocation Type = SECTION | Target area shows Class dropdown |
| 4 | Select a Class | Class selected |
| 5 | Select a Section that belongs to the selected class | Section selected; ClassSection junction validated |
| 6 | Set Due Date (future) | Due date set |
| 7 | Submit form | POST to store |
| 8 | DB check: target_id | Set to ClassSection junction ID, target_table_name='sch_class_section_jnt' |

---

#### TC-P03: Create GROUP Type Allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Quiz Allocations → Create | Create form loads |
| 2 | Select a Quiz (must be active) | Quiz selected |
| 3 | Select Allocation Type = GROUP | Target dropdown populated with active groups |
| 4 | Select a Group from dropdown | Group selected |
| 5 | Set Due Date (future) | Due date set |
| 6 | Submit | POST to store |
| 7 | DB check | allocation_type='GROUP', target_id=group_id, target_table_name='sch_entity_groups' |

---

#### TC-P04: Create STUDENT Type Allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Quiz Allocations → Create | Create form loads |
| 2 | Select a Quiz (must be active) | Quiz selected |
| 3 | Select Allocation Type = STUDENT | Target dropdown populated with active students (formatted "Name (StudentID)") |
| 4 | Select a Student from dropdown | Student selected |
| 5 | Set Due Date (future) | Due date set |
| 6 | Submit | POST to store |
| 7 | DB check | allocation_type='STUDENT', target_id=student_id, target_table_name='sch_students' |

---

#### TC-P05: Create Allocation with cut_off_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Quiz Allocations → Create | Create form loads |
| 2 | Select a Quiz, Allocation Type = CLASS, select a Class | Required fields set |
| 3 | Set Due Date to "2026-08-15" | Due date set |
| 4 | Set Cut-off Date to "2026-08-20" (after due_date) | Cut-off date set |
| 5 | Submit | Allocation created |
| 6 | DB check: cut_off_date | cut_off_date = "2026-08-20" (saved independently from due_date) |

---

#### TC-P06: Create Allocation Without cut_off_date (Defaults to due_date)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Quiz Allocations → Create | Create form loads |
| 2 | Select a Quiz, Allocation Type = CLASS, select a Class | Required fields set |
| 3 | Set Due Date to "2026-08-15" | Due date set |
| 4 | Leave Cut-off Date field empty | Cut-off date blank |
| 5 | Submit | Allocation created |
| 6 | DB check: cut_off_date | cut_off_date = "2026-08-15" (defaults to due_date) |

---

#### TC-P07: Create Allocation with is_auto_publish_result=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Quiz Allocations → Create | Create form loads |
| 2 | Select a Quiz, Allocation Type = CLASS, select a Class | Required fields set |
| 3 | Set Due Date (future) | Due date set |
| 4 | Toggle Auto Publish Result = ON | is_auto_publish_result checked |
| 5 | Set Result Publish Date (>= due_date) | Result publish date set |
| 6 | Submit | Allocation created |
| 7 | DB check | is_auto_publish_result=1, result_publish_date saved as provided |

---

#### TC-P08: Create Allocation with is_auto_publish_result=false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Quiz Allocations → Create | Create form loads |
| 2 | Select a Quiz, Allocation Type = CLASS, select a Class | Required fields set |
| 3 | Set Due Date (future) | Due date set |
| 4 | Leave Auto Publish Result = OFF (default) | is_auto_publish_result unchecked |
| 5 | Verify Result Publish Date field is hidden/disabled | Field not editable |
| 6 | Submit | Allocation created |
| 7 | DB check | is_auto_publish_result=0, result_publish_date=NULL |

---

#### TC-P09: View Allocation List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.quiz-allocation.viewAny` permission | Authenticated |
| 2 | Navigate to Quiz Allocations (index) | Index page loads with paginated table |
| 3 | Check table headers present | Quiz Title, Allocation Type, Target Name, Assigned By, Published At, Due Date, Cut-off Date, Status, Actions |
| 4 | Verify each row shows correct allocation data | Quiz title, allocation type badge, target name, assigner, dates, status toggle displayed |
| 5 | Verify pagination (10 per page) | If 10+ allocations exist, pagination links appear |
| 6 | Toggle status on one row | AJAX toggle works |

---

#### TC-P10: View Single Allocation (show)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to allocation list | Index page |
| 2 | Click "View" (eye) icon on an allocation | Show page loads with breadcrumb |
| 3 | Check allocation details displayed | Quiz title, allocation type, target name, assigned_by, published_at, due_date, cut_off_date, status badge |
| 4 | Check "Back" button | Present, links back to index |
| 5 | Check "Edit" button | Visible if user has update permission and allocation has no attempts |

---

#### TC-P11: View Single Allocation with Attempt Stats

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open an allocation that has student attempts | Show page loads |
| 2 | Verify Usage Details / Attempt Stats card visible | Card section present |
| 3 | Check attempt breakdown | Stats: Total Attempts, In Progress, Submitted, Passed, Failed, Avg Score, Avg Percentage |
| 4 | Verify stats match actual attempt data | Counts and scores shown correctly |
| 5 | Check recent attempts list (if any) | Recent attempts listed with student names and scores |

---

#### TC-P12: Edit Allocation — Change due_date (no attempts)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to allocation list | Index page |
| 2 | Click "Edit" (pencil) icon on an allocation with no attempts | Edit form loads with pre-filled data |
| 3 | Change due_date to a new future date (e.g., +14 days) | Due date field updated |
| 4 | Click Update / Submit | PUT request to update |
| 5 | Verify redirect with success flash | "Allocation updated successfully" |
| 6 | DB check: `SELECT due_date FROM lms_quiz_allocations WHERE id=X` | due_date updated to new value |
| 7 | Check activity log | "Updated" event logged with changes array |

---

#### TC-P13: Edit Allocation — Change Target (no attempts)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit an allocation with no attempts (currently CLASS type) | Edit form loads |
| 2 | Change Allocation Type to GROUP | Target dropdown switches to group list |
| 3 | Select a different Group as new target | Group selected |
| 4 | Submit | Allocation updated |
| 5 | DB check | allocation_type='GROUP', target_id=new_group_id, target_table_name='sch_entity_groups' |

---

#### TC-P14: Edit Allocation — Enable is_auto_publish_result After Creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit an allocation created with is_auto_publish_result=false | Edit form loads |
| 2 | Toggle Auto Publish Result to ON | is_auto_publish_result=true |
| 3 | Set result_publish_date (>= due_date) | Date set |
| 4 | Submit | Allocation updated |
| 5 | Verify publishHiddenRecommendations() triggered | All hidden recommendations published |
| 6 | DB check | is_auto_publish_result=1, result_publish_date set |

---

#### TC-P15: Soft Delete Allocation (no attempts)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to allocation list | Index page |
| 2 | Click delete (trash) icon on an allocation with no attempts | SweetAlert confirmation prompt |
| 3 | Confirm deletion | DELETE request to destroy |
| 4 | Check success flash message | "Allocation moved to trash" |
| 5 | DB check: `SELECT is_active, deleted_at FROM lms_quiz_allocations WHERE id=X` | is_active=0, deleted_at NOT NULL |
| 6 | Verify allocation no longer visible in active list | Hidden from index |
| 7 | Check activity log | "Trashed" or "Deleted" event logged |

---

#### TC-P16: Restore Allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trash page (`/lms-quize/quiz-allocation/trash/view`) | Trash page loads with soft-deleted records |
| 2 | Locate a deleted allocation in the trash list | Record shown with "Deleted" status badge |
| 3 | Click "Restore" button on that row | SweetAlert confirmation |
| 4 | Confirm restore | Restore succeeds |
| 5 | Check success flash | "Allocation restored successfully" |
| 6 | DB check: `SELECT deleted_at, is_active FROM lms_quiz_allocations WHERE id=X` | deleted_at=NULL, is_active=1 |
| 7 | Navigate to main list | Record visible and active again |

---

#### TC-P17: Force Delete Allocation (no attempts/results)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete an allocation with no attempts and no results | Allocation in trash |
| 2 | Navigate to Trash page | Trash shows the record with Force Delete button |
| 3 | Click "Force Delete" | SweetAlert confirmation |
| 4 | Confirm | Force delete succeeds |
| 5 | Check flash message | "Allocation permanently deleted" |
| 6 | DB check with trashed | Record permanently removed from database |

---

#### TC-P18: Toggle Status (toggleStatus AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to allocation list | Index page |
| 2 | Click the status toggle switch on an active allocation (is_active=1) | AJAX POST to `/lms-quize/quiz-allocation/{id}/toggle-status` |
| 3 | Check JSON response | `{success: true, is_active: false, message: "Status updated"}` |
| 4 | UI check: status badge changes to Inactive | Badge updates without page reload |
| 5 | DB check: `SELECT is_active FROM lms_quiz_allocations WHERE id=X` | is_active=0 |
| 6 | Click toggle again | AJAX POST with opposite value |
| 7 | JSON response | `{success: true, is_active: true}` |
| 8 | DB check | is_active=1 |

---

#### TC-P19: Publish Recommendations (publishRecommendations)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to allocation list or show page | Allocation with hidden recommendations visible |
| 2 | Click "Publish Recommendations" button | POST to `/lms-quize/quiz-allocation/{id}/publish-recommendations` |
| 3 | Check success response | "Recommendations published successfully" |
| 4 | DB check: `SELECT is_published FROM lms_quiz_recommendations WHERE quiz_allocation_id=X` | Previously hidden recommendations now have is_published=1 |

---

#### TC-P20: AJAX getTargetOptions — CLASS Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Quiz Allocations → Create | Create form loads |
| 2 | Select Allocation Type = CLASS | AJAX GET to `/lms-quize/quiz-allocation/get-target-options?allocation_type=CLASS` |
| 3 | Check returned JSON | Array of classes with id and name |
| 4 | Verify only active classes returned | Inactive/soft-deleted classes excluded |

---

#### TC-P21: AJAX getQuizzes — unallocated_only=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Quiz Allocations → Create | Create form loads |
| 2 | Check quiz dropdown triggers AJAX | GET to `/lms-quize/quiz-allocation/get-quizzes?unallocated_only=1` |
| 3 | Verify only unallocated quizzes returned | Quizzes with NO existing allocations shown |
| 4 | Verify already-allocated quizzes excluded | Quizzes with existing allocations NOT in list |

---

### 7.5 Negative TC Steps

#### TC-N01: Create — Empty quiz_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Quiz Allocations → Create | Create form loads |
| 2 | Leave quiz field empty | No quiz selected |
| 3 | Select Allocation Type, Target, set Due Date | Other fields filled |
| 4 | Submit form | Validation error: "The quiz id field is required" |
| 5 | Verify no record created | DB shows no new allocation |

---

#### TC-N02: Create — Quiz is inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set quiz_id to an inactive quiz ID (is_active=0) via dev tools | Inactive quiz referenced |
| 3 | Fill remaining required fields | Fields set |
| 4 | Submit | Validation error: "The selected quiz is not active" |
| 5 | Verify no record created | DB unchanged |

---

#### TC-N03: Create — Invalid quiz_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set quiz_id to non-existent value (e.g., 99999) via dev tools | ID does not exist |
| 3 | Fill remaining required fields | Fields set |
| 4 | Submit | Validation error: "The selected quiz id is invalid" |

---

#### TC-N04: Create — Invalid allocation_type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set allocation_type to "INVALID" via dev tools | Type not in allowed list |
| 3 | Fill remaining required fields | Fields set |
| 4 | Submit | Validation error: "The selected allocation type is invalid" (rule: in:CLASS,SECTION,GROUP,STUDENT) |

---

#### TC-N05: Create — Empty target_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select Quiz, Allocation Type = CLASS | Fields set |
| 3 | Leave target (Class) dropdown empty | No target selected |
| 4 | Set Due Date | Date set |
| 5 | Submit | Validation error: "The target id field is required" |

---

#### TC-N06: Create — Invalid target_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select Quiz, Allocation Type = CLASS | Fields set |
| 3 | Set target_id to non-existent class ID (e.g., 99999) via dev tools | Class does not exist |
| 4 | Set Due Date | Date set |
| 5 | Submit | Validation error: "The selected target is invalid or not active" |

---

#### TC-N07: Create — SECTION type with invalid class+section combo

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select Quiz | Quiz selected |
| 3 | Select Allocation Type = SECTION | Class field appears |
| 4 | Select a Class (Class A) | Class selected |
| 5 | Select a Section that does NOT belong to Class A | Section belongs to a different class |
| 6 | Set Due Date | Date set |
| 7 | Submit | Validation error: "The selected class and section combination does not exist" |

---

#### TC-N08: Create — Empty due_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select Quiz, Allocation Type, Target | Required fields set |
| 3 | Leave due_date field empty | Due date blank |
| 4 | Submit | Validation error: "The due date field is required" |

---

#### TC-N09: Create — due_date in the past

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select Quiz, Allocation Type, Target | Required fields set |
| 3 | Set due_date to a past date (e.g., yesterday) | Past date entered |
| 4 | Submit | Validation error: "The due date must be a future or current date" |

---

#### TC-N10: Create — due_date more than 2 years in future

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select Quiz, Allocation Type, Target | Required fields set |
| 3 | Set due_date to a date > 2 years from now | Date beyond 2-year limit |
| 4 | Submit | Validation error: "The due date cannot be more than 2 years in the future" |

---

#### TC-N11: Create — cut_off_date before due_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill required fields | Required fields set |
| 3 | Set due_date to "2026-08-15" | Due date set |
| 4 | Set cut_off_date to "2026-08-10" (before due_date) | Cut-off before due |
| 5 | Submit | Validation error: "The cut-off date must be on or after the due date" |

---

#### TC-N12: Create — cut_off_date more than 2 years

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill required fields | Required fields set |
| 3 | Set due_date to current date | Due date set |
| 4 | Set cut_off_date to date > 2 years from due_date | Cut-off beyond limit |
| 5 | Submit | Validation error: "The cut-off date cannot be more than 2 years in the future" |

---

#### TC-N13: Create — result_publish_date with is_auto_publish_result=false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill required fields (Quiz, Type, Target, Due Date) | Required fields set |
| 3 | Leave is_auto_publish_result = OFF | Auto publish disabled |
| 4 | If result_publish_date field is visible, set a date | Date set |
| 5 | Submit | Validation error: "The result publish date cannot be set when auto publish is disabled" |

---

#### TC-N14: Create — result_publish_date before due_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill required fields | Required fields set |
| 3 | Toggle is_auto_publish_result = ON | Auto publish enabled |
| 4 | Set due_date to "2026-08-15" | Due date set |
| 5 | Set result_publish_date to "2026-08-10" (before due_date) | Result publish before due |
| 6 | Submit | Validation error: "The result publish date must be on or after the due date" |

---

#### TC-N15: Edit — allocation has attempts (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to allocation list | Index page |
| 2 | Click "Edit" on an allocation that has student attempts | Usage check runs |
| 3 | Verify edit blocked | Redirect back with error: "Cannot update... students have already started attempts." |
| 4 | Verify record NOT updated | DB unchanged |

---

#### TC-N16: Edit — published allocation, try to change published_at

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation with published_at in the past | Allocation published |
| 2 | Navigate to edit page | Edit form loads |
| 3 | Attempt to change published_at field | Field locked/disabled; if submitted with changed value, validation error: "publish date cannot be changed once the allocation is live." |
| 4 | Verify published_at unchanged in DB | Original published_at preserved |

---

#### TC-N17: Destroy — allocation has attempts (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to allocation list | Index page |
| 2 | Click delete icon on an allocation that has student attempts | Usage check triggers |
| 3 | Verify deletion blocked | Error: "Cannot delete... students have already started attempts." |
| 4 | DB check | Record NOT soft-deleted, is_active still 1 |

---

#### TC-N18: Force Delete — allocation has attempts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete an allocation that has student attempts | Allocation in trash |
| 2 | Navigate to Trash page | Trash shows the record |
| 3 | Click "Force Delete" | Dependency check runs (`$allocation->attempts()->exists()`) |
| 4 | Verify force delete blocked | Error: "Cannot permanently delete... students have already started or submitted attempts." |
| 5 | DB check with trashed | Record still exists (soft-deleted) |

---

#### TC-N19: Force Delete — allocation has results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete an allocation that has existing results | Allocation in trash |
| 2 | Navigate to Trash page | Trash shows the record |
| 3 | Click "Force Delete" | Dependency check runs (`$allocation->results()->exists()`) |
| 4 | Verify force delete blocked | Error: "Cannot permanently delete... students have already started or submitted attempts." |
| 5 | DB check with trashed | Record still exists |

---

#### TC-N20: View — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quiz-allocation.viewAny` permission | Authenticated |
| 2 | Navigate to Quiz Allocations index | 403 Forbidden |
| 3 | Verify allocation tab/menu not visible in navigation | Feature hidden from menu |

---

#### TC-N21: Create — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quiz-allocation.create` permission | Authenticated |
| 2 | Navigate to create page directly | 403 Forbidden |
| 3 | Check index page for "Add New" / Create button | Create button NOT visible |

---

#### TC-N22: Edit — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quiz-allocation.update` permission | Authenticated |
| 2 | Navigate to allocation list | List loads (viewAny granted) |
| 3 | Check Edit (pencil) icon on rows | Edit icon NOT visible |
| 4 | Navigate to edit page directly | 403 Forbidden |
| 5 | Send POST to toggle-status | 403 Forbidden |
| 6 | Send POST to publish-recommendations | 403 Forbidden |

---

#### TC-N23: Delete — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quiz-allocation.delete` permission | Authenticated |
| 2 | Navigate to allocation list | List loads |
| 3 | Check Delete (trash) icon on rows | Delete icon NOT visible |
| 4 | Send DELETE request directly | 403 Forbidden |

---

#### TC-N24: Create — published_at AFTER due_date (server-side gap)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill required fields | Required fields set |
| 3 | Set published_at to "2026-09-01" | Published at set |
| 4 | Set due_date to "2026-08-15" (before published_at) | Due date before published |
| 5 | Submit via direct POST (bypass JS) | **SERVER ACCEPTS** — no server-side validation prevents published_at > due_date |
| 6 | Verify DB record created | published_at='2026-09-01', due_date='2026-08-15' — illogical state: visible from after deadline |

---

#### TC-N25: Create — cut_off_date BEFORE published_at (server-side gap)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill required fields | Required fields set |
| 3 | Set published_at to "2026-09-01" | Published at set |
| 4 | Set due_date to "2026-09-15" | Due date set |
| 5 | Set cut_off_date to "2026-08-20" (before published_at) | Cut-off before visible from |
| 6 | Submit via direct POST (bypass JS) | **SERVER ACCEPTS** — no server-side validation prevents cut_off_date < published_at |
| 7 | Verify DB record created | cut_off_date before the allocation is even visible to students |

---

#### TC-N26: Create — target_id = 0 (below minimum)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select a quiz | Quiz selected |
| 3 | Select allocation_type = CLASS | Class selector shown |
| 4 | Submit POST with target_id=0 (bypass UI) | Validation error on target_id: min:1 |
| 5 | Submit POST with target_id=-1 | Validation error on target_id: min:1 |

---

#### TC-N27: Update — change quiz_id after creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation A1 with quiz_id=Q1 | Allocation exists |
| 2 | Navigate to edit page for A1 | Edit form loads with Q1 selected |
| 3 | Change quiz_id to a different active quiz Q2 | Quiz changed |
| 4 | Submit update | Allocation updated with new quiz_id=Q2 |
| 5 | Verify redirect | Success message: updated |
| 6 | DB check | quiz_id changed from Q1 to Q2 |
| 7 | Verify old quiz Q1 stats unaffected | Q1 allocation count unchanged |

---

### 7.6 Dependency TC Steps

#### TC-D01: Cascade — Quiz Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a Quiz (Q1) | Quiz exists |
| 2 | Create Allocation A1 with quiz_id = Q1.id | Allocation exists referencing Q1 |
| 3 | Soft-delete Quiz Q1 | Quiz soft-deleted |
| 4 | Check Allocation A1 in DB | Allocation.deleted_at set via FK CASCADE |
| 5 | Verify A1 hidden from active list | Allocation no longer appears in index |
| 6 | Verify A1 appears in trash page | Shows in trash view |

---

#### TC-D02: Business — Published Lock

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation with published_at in the past (e.g., 1 day ago) | Allocation is "live" |
| 2 | Navigate to edit page | Edit form loads |
| 3 | Attempt to modify published_at to a different date | Field is disabled/read-only |
| 4 | If bypassed via dev tools: submit with changed published_at | Validation error: "publish date cannot be changed once the allocation is live." |
| 5 | DB check: published_at | Original published_at preserved |

---

#### TC-D03: Business — Recommendations Publishing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation A1 with is_auto_publish_result=false | Allocation created |
| 2 | Students attempt quiz for A1 → hidden recommendations created | `lms_quiz_recommendations` records exist with is_published=0 |
| 3 | Edit A1, toggle is_auto_publish_result=true | Flag enabled |
| 4 | Submit update | Controller calls `publishHiddenRecommendations()` |
| 5 | DB check | All previously hidden recommendations now is_published=1 |

---

#### TC-D04: Business — Attempt Count Tracking

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation A1 | Allocation exists |
| 2 | Have Student S1 attempt quiz → in-progress | 1 in-progress attempt |
| 3 | Have Student S2 attempt and submit → passed | 1 submitted + passed |
| 4 | Have Student S3 attempt and submit → failed | 1 submitted + failed |
| 5 | Navigate to A1 show page | Show page loads |
| 6 | Check Usage Details / Attempt Stats card | Total: 3, In Progress: 1, Submitted: 2, Passed: 1, Failed: 1 |

---

#### TC-D05: Business — Auto-publish on Creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation A1 with is_auto_publish_result=true (on create) | Allocation created |
| 2 | Check if publishHiddenRecommendations() was called during store() | NOT triggered — publishing only triggers on UPDATE flip |
| 3 | Verify no recommendations auto-published on create | Any existing hidden recommendations remain unpublished |

---

#### TC-D06: Soft Delete — attempts unaffected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation A1, students have attempted it | Attempt records exist |
| 2 | Soft-delete A1 | Allocation soft-deleted: is_active=0, deleted_at NOT NULL |
| 3 | DB check: attempts count | Attempt records still exist (same count) |
| 4 | Verify A1 hidden from active list | Not visible in index |

---

#### TC-D07: Business — AJAX Target Filter Scoping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Quiz Allocations → Create | Create form loads |
| 2 | Select Allocation Type = STUDENT | AJAX GET to get-target-options |
| 3 | Check returned JSON | Array of active students |
| 4 | Verify inactive students excluded | Students with is_active=0 NOT in response |
| 5 | Verify soft-deleted students excluded | Students with deleted_at NOT NULL NOT in response |

---

#### TC-D08: Student Portal — is_active=false Blocks Student Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation A1 with is_active=1, published_at in past, cut_off_date in future | A1 visible to student on "My Quizzes" page |
| 2 | Login as a student who matches A1's target (class/section/student) | Student dashboard loads |
| 3 | Navigate to My Quizzes page | A1 listed as available quiz |
| 4 | Click "Attempt" on A1's quiz | Instruction/start page loads (assertAllocation passes) |
| 5 | Admin: toggle A1's is_active to 0 (toggleStatus) | Allocation deactivated |
| 6 | Student refreshes My Quizzes page | A1 no longer listed |
| 7 | Student navigates directly to quiz attempt URL for A1's quiz | 403 Forbidden (assertAllocation fails) |
| 8 | Student tries to resume any in-progress attempt for A1 | 403 Forbidden (assertAllocation fails) |

---

#### TC-D09: Student Portal — cut_off_date Passed Hides Quiz

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation A1 with cut_off_date = tomorrow, published_at = yesterday | A1 active and visible |
| 2 | Login as matching student, navigate to My Quizzes | A1 visible |
| 3 | Manually set A1.cut_off_date to yesterday (past) in DB | cut_off_date in past |
| 4 | Student refreshes My Quizzes page | A1 hidden (cut_off_date filter) |
| 5 | Student navigates directly to quiz attempt URL for A1's quiz | 403 Forbidden (visibleAllocations filter) |

---

#### TC-D10: Student Portal — published_at in Future Hides Quiz

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation A1 with published_at = tomorrow, is_active=1 | Allocation exists but not published |
| 2 | Login as matching student, navigate to My Quizzes | A1 NOT visible |
| 3 | Student navigates directly to quiz attempt URL for A1's quiz | 403 Forbidden |
| 4 | Admin: update A1.published_at to yesterday (or null + re-publish) | Allocation now published |
| 5 | Student refreshes My Quizzes | A1 now visible and can be attempted |

---

#### TC-D11: Student Portal — is_auto_publish_result Controls Result Visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation A1 with is_auto_publish_result=false | Auto-publish off |
| 2 | Matching student attempts and submits quiz for A1 | Quiz submitted |
| 3 | Student navigates to quiz result page | Result NOT visible (is_published=0 in quiz_quest_results) |
| 4 | Admin: update A1.is_auto_publish_result=true | Triggers publishHiddenRecommendations() |
| 5 | Student refreshes result page | Result now visible (is_published=1) |
| 6 | Create allocation A2 with is_auto_publish_result=true | Auto-publish on |
| 7 | Student attempts and submits quiz for A2 | Quiz submitted |
| 8 | Student navigates to A2 result page | Result immediately visible |

---

#### TC-D12: Student Portal — Soft-deleted Allocation Blocks New Attempts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation A1, student has existing in-progress attempt | Attempt exists |
| 2 | Admin soft-deletes A1 | A1.deleted_at set, is_active=0 |
| 3 | Student refreshes My Quizzes | A1 hidden (is_active=0) |
| 4 | Student tries to continue/resume the in-progress attempt | 403 Forbidden (assertAllocation: is_active=false) |
| 5 | Admin restores A1 (restore) | A1.deleted_at=null, is_active=1 |
| 6 | Student refreshes and resumes attempt | Attempt accessible again |

---

### 7.7 Code Review TC Steps

#### TC-CR01: Request — Quiz Active Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizAllocationRequest::rules()` for `quiz_id` rule | Custom closure present in addition to `exists:lms_quizzes,id` |
| 2 | Inspect closure implementation | Closure retrieves `$quiz = Quiz::find($value)` and checks `if (!$quiz || !$quiz->is_active)` → `$fail('The selected quiz is not active.')` |

---

#### TC-CR02: Request — published_at Immutable Lock

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizAllocationRequest` for `published_at` rule condition | Custom rule added specifically for update scenario |
| 2 | Verify published_at lock logic | If allocation is already live (published_at <= now()), submitted value compared with original; mismatch triggers error |
| 3 | Check that create is unaffected | Rule only applies during update |

---

#### TC-CR03: Request — SECTION Type Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizAllocationRequest` for SECTION-specific validation | Custom rule validates class_id + section_id combination |
| 2 | Check implementation | Queries `ClassSection::where('class_id', $classId)->where('section_id', $sectionId)->exists()` |
| 3 | Verify error message | "The selected class and section combination does not exist." |

---

#### TC-CR04: Controller store() — cut_off_date Default

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` method in `QuizAllocationController` | If `cut_off_date` not provided, sets it equal to `due_date` |
| 2 | Check assignment logic | `$data['cut_off_date'] = $data['cut_off_date'] ?? $data['due_date'];` or similar |

---

#### TC-CR05: Controller store() — Auto-publish result_publish_date Null

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` method | Checks `is_auto_publish_result` flag |
| 2 | Verify logic | If false, forces `result_publish_date = null` before save |
| 3 | Check conditional | `if (!$data['is_auto_publish_result']) { $data['result_publish_date'] = null; }` |

---

#### TC-CR06: Controller update() — Usage Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `update()` method | Calls `QuizAllocationUsageCheckService::isUsed($id)` early |
| 2 | Verify early return | If used, redirects back with error; no DB write occurs |

---

#### TC-CR07: Controller update() — Recommendation Publishing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `update()` method after successful save | Checks if `is_auto_publish_result` was just enabled |
| 2 | Verify flip detection | Compares old value from DB with new value from request |
| 3 | Check publishHiddenRecommendations() call | If flipped to true, calls `$allocation->publishHiddenRecommendations()` |

---

#### TC-CR08: Controller destroy() — Usage Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `destroy()` method | Calls `isUsed($id)` before soft delete |
| 2 | Verify early return | If used, redirects with error; record remains with is_active=1 |

---

#### TC-CR09: Controller forceDelete() — Dependency Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `forceDelete()` method | Checks two conditions: `$allocation->attempts()->exists()` OR `$allocation->results()->exists()` |
| 2 | Verify early return | If either dependency exists, redirects with error |

---

#### TC-CR10: Controller destroy() — Sets Inactive Before Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `destroy()` method | First calls `$allocation->update(['is_active' => false])` |
| 2 | Then calls `$allocation->delete()` | is_active set to false BEFORE soft delete |

---

#### TC-CR11: Controller restore() — Sets Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `restore()` method | First calls `$allocation->restore()` (restores soft-deleted record) |
| 2 | Then calls `$allocation->update(['is_active' => true])` | Restore then set is_active=true |

---

#### TC-CR12: Model — targetName Accessor

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizAllocation` model | `getTargetNameAttribute()` accessor defined |
| 2 | Check switch/case logic | Maps allocation_type to model: CLASS→SchoolClass, SECTION→Section, GROUP→EntityGroup, STUDENT→Student |
| 3 | Verify each case resolves a name | `SchoolClass::find($this->target_id)?->name` or similar |

---

#### TC-CR13: Model — results() HasManyThrough

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizAllocation` model | `results()` relationship defined as `HasManyThrough` |
| 2 | Check chain | `QuizAllocation → QuizQuestAttempt → QuizQuestResult` |
| 3 | Verify keys | `hasManyThrough(QuizQuestResult::class, QuizQuestAttempt::class, 'quiz_allocation_id', 'quiz_quest_attempt_id')` |

---

#### TC-CR14: Request — getTargetTable() Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizAllocationRequest` | `getTargetTable()` method maps allocation_type to DB table name |
| 2 | Check mapping | CLASS→'sch_classes', SECTION→'sch_class_section_jnt', GROUP→'sch_entity_groups', STUDENT→'sch_students' |

---

#### TC-CR15: Student — assertAllocation() Security Gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `StudentQuizAttemptController::assertAllocation()` | Private method that checks for matching active allocation |
| 2 | Verify it queries `QuizAllocation::where('quiz_id', $quizId)->where('is_active', true)` | Ensures only active allocations allow access |
| 3 | Verify it matches CLASS type: `allocation_type='CLASS' AND target_table_name='sch_classes' AND target_id=$ctx['classId']` | Class-level allocations grant access |
| 4 | Verify it matches SECTION type: `allocation_type='SECTION' AND target_table_name='sch_sections' AND target_id=$ctx['sectionId']` | Section-level allocations grant access |
| 5 | Verify it matches STUDENT type: `allocation_type='STUDENT' AND target_table_name='std_students' AND target_id=$ctx['studentId']` | Student-level allocations grant access |
| 6 | **Verify GROUP type is NOT handled** | GROUP allocations will cause 403 for students in that group — potential bug |

---

#### TC-CR16: Student — visibleAllocations() Filter Chain

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `StudentQuizAttemptController::visibleAllocations()` or equivalent | Method that returns quizzes visible to student on My Quizzes page |
| 2 | Verify `scopePublished()` applied: `published_at IS NOT NULL AND published_at <= now()` | Future-published allocations excluded |
| 3 | Verify `where('is_active', true)` applied | Deactivated allocations excluded |
| 4 | Verify cut-off filter: `whereNull('cut_off_date')->orWhere('cut_off_date', '>=', now())` | Expired allocations excluded |
| 5 | Verify quiz relationship loaded with `published()` scope: `quiz.status = 'PUBLISHED'` | Only published quizzes shown |
| 6 | Verify `->filter(fn ($a) => $a->quiz !== null)` applied | Dangling allocations (deleted quiz) excluded |

---

#### TC-CR17: Student — hasSubmittedAttempt() Hard Lock

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `StudentQuizAttemptController::hasSubmittedAttempt()` | Method checks if student already has SUBMITTED or TIMEOUT attempt |
| 2 | Verify query: `QuizQuestAttempt::where('student_id', $studentId)->where('quiz_id', $quizId)->whereIn('status', ['SUBMITTED', 'TIMEOUT'])->exists()` | Once submitted/timeout, hard lock active |
| 3 | Verify this is checked BEFORE max_attempts in start/attempt/submit | Hard lock takes priority over attempt cap |
| 4 | Verify ABANDONED status does NOT trigger hard lock | Abandoned attempts can be re-tried (up to max_attempts) |

---

#### TC-CR18: Student — attemptMeta() Attempt Counting

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `StudentQuizAttemptController::attemptMeta()` | Method returns attempt count and breakdown |
| 2 | Verify IN_PROGRESS attempts are counted but NOT counted toward max_attempts cap | Student can have 1 in-progress + additional attempts |
| 3 | Verify SUBMITTED attempts count toward max_attempts cap | Submitted uses an attempt slot |
| 4 | Verify TIMEOUT attempts count toward max_attempts cap | Timed-out uses an attempt slot |
| 5 | Verify ABANDONED attempts count toward max_attempts cap | Abandoned uses an attempt slot |
| 6 | Verify `max_attempts` comes from `Quiz::max_attempts` field (not allocation) | Allocation has no max_attempts field |

---

#### TC-CR19: Student — GROUP Allocation Type Not in assertAllocation()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `assertAllocation()` method in StudentQuizAttemptController | Only handles CLASS, SECTION, STUDENT allocation types |
| 2 | Trace student belonging to a GROUP that has a GROUP-type allocation | No GROUP branch exists in the query |
| 3 | Verify whether `visibleAllocations()` also omits GROUP type | If GROUP omitted from both, students in groups can never see or access group-allocated quizzes |
| 4 | Check if GROUP resolution happens at a higher layer (e.g., middleware) | If not, this is a functional bug |

---

#### TC-CR20: Request — prepareForValidation() Target Resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizAllocationRequest::prepareForValidation()` | Method merges resolved target fields into request |
| 2 | Verify for SECTION: `section_target_id` mapped to `target_id` | `$resolvedTargetId = $this->input('section_target_id')` |
| 3 | Verify for GROUP: `group_target_id` mapped to `target_id` | `$resolvedTargetId = $this->input('group_target_id')` |
| 4 | Verify for STUDENT: `student_target_id` mapped to `target_id` | `$resolvedTargetId = $this->input('student_target_id')` |
| 5 | Verify `class_id` resolved from quiz if not provided: `$quizClassId = Quiz::query()->whereKey($this->input('quiz_id'))->value('class_id')` | Class auto-populated from quiz |

---

#### TC-CR21: Request — prepareForValidation() Empty-to-Null Conversion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `prepareForValidation()` | Converts empty strings to null for optional date fields |
| 2 | Verify `published_at` empty→null | `$this->merge(['published_at' => null])` when submitted as '' |
| 3 | Verify `cut_off_date` empty→null | `$this->merge(['cut_off_date' => null])` when submitted as '' |
| 4 | Verify `result_publish_date` empty→null | `$this->merge(['result_publish_date' => null])` when submitted as '' |
| 5 | Verify `due_date` is NOT converted (required field) | due_date must remain as submitted for required+date validation |
| 6 | Verify boolean fields cast in merge: `is_auto_publish_result` and `is_active` | `$this->boolean()` applied |

---

#### TC-CR22: Request — validated() Casting and Formatting

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizAllocationRequest::validated()` | Method overrides parent to apply type casting and date formatting |
| 2 | Verify booleans: `is_auto_publish_result` cast to `(bool)` | `$validated['is_auto_publish_result'] = (bool)($validated['is_auto_publish_result'] ?? false)` |
| 3 | Verify booleans: `is_active` default `true` | `$validated['is_active'] = (bool)($validated['is_active'] ?? true)` |
| 4 | Verify dates formatted: `published_at` → `'Y-m-d H:i:s'` | `Carbon::parse($validated['published_at'])->format('Y-m-d H:i:s')` |
| 5 | Verify null dates remain null | If not set, field is `null` |

---

#### TC-CR23: Controller store() — Transaction Rollback on Exception

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizAllocationController::store()` | Wrapped in `DB::beginTransaction()` / `DB::commit()` / `DB::rollBack()` |
| 2 | Verify catch block catches `\Throwable` (not just `\Exception`) | Catches all errors including PHP fatal errors |
| 3 | Verify rollback on failure | `DB::rollBack()` called in catch |
| 4 | Verify error logging | `Log::error('Quiz Allocation Store Error: ...')` with exception and request data |
| 5 | Verify user redirected back with input | `return back()->withInput()->with('error', ...)` |

---

#### TC-CR24: Controller update() — Auto-publish Flip Detection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizAllocationController::update()` | Captures original values before update via `$allocation->getOriginal()` |
| 2 | Verify flip detection: `$wasAutoPublish = (bool)($original['is_auto_publish_result'] ?? false)` | Reads original auto-publish state |
| 3 | Verify condition: `if (!$wasAutoPublish && $allocation->is_auto_publish_result)` | Only triggers when flipped FALSE→TRUE |
| 4 | Verify calls `$this->publishHiddenRecommendations('QUIZ', $allocation->quiz_id, $allocation->id)` | Publishing triggered only on flip to true |
| 5 | Verify no action when already TRUE→TRUE or TRUE→FALSE | No publish call in those cases |

---

#### TC-CR25: Controller destroy() — Sets Inactive Before Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizAllocationController::destroy()` | First: `$allocation->update(['is_active' => false])` |
| 2 | Then: `$allocation->delete()` | is_active=0 set BEFORE soft delete occurs |
| 3 | Verify rationale: ensures student access blocked immediately before record moved to trash | Student assertAllocation() checks is_active=true, so changing to false blocks new attempts |

---

#### TC-CR26: Controller publishRecommendations() — Already Auto-published (No-op)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `publishRecommendations()` | Method first checks `is_auto_publish_result` |
| 2 | Verify condition: `if (!$allocation->is_auto_publish_result) { $allocation->update(['is_auto_publish_result' => true]); }` | Only updates DB if currently false (avoids redundant write) |
| 3 | Verify `publishHiddenRecommendations()` called unconditionally after | Always calls publish regardless of prior state |
| 4 | Verify no error when `is_auto_publish_result` already true | No exception; just skips update and calls publishHiddenRecommendations |

---

#### TC-CR27: Controller publishHiddenRecommendations() — Empty Guard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review private `publishHiddenRecommendations()` | Queries student IDs via JOIN: `attempts → results` |
| 2 | Verify guard: `if ($studentIds->isEmpty()) { return; }` | Early return if no students have attempted |
| 3 | Verify update only called when student IDs exist | `StudentRecommendation::where(...)->whereIn('student_id', $studentIds)->update(...)` |
| 4 | Verify `is_published=false` filter prevents redundant updates | Only flips records currently hidden |

---

#### TC-CR28: Controller create() — Unallocated Quiz Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizAllocationController::create()` | Quizzes loaded for dropdown with filter |
| 2 | Verify `whereDoesntHave('allocations')` applied | Only quizzes with NO prior allocations shown in create form |
| 3 | Verify `where('is_active', '1')` applied | Only active quizzes shown |
| 4 | Check if the "filter_unallocated" JS toggle bypasses server-side filter | Server always applies `whereDoesntHave`; JS toggle only switches between server results and AJAX results |

---

#### TC-CR29: Controller index() — date_range Filter Parsing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizAllocationController::index()` | Filter by `date_range` field |
| 2 | Verify split logic: `explode(' - ', $request->date_range)` | Splits into start and end dates |
| 3 | Verify startOfDay/endOfDay applied: `Carbon::parse($start)->startOfDay()` and `Carbon::parse($end)->endOfDay()` | Full-day range coverage |
| 4 | Verify filter applies to `published_at` column | `$q->whereBetween('published_at', [...])` |
| 5 | Verify safe guard: `str_contains($request->date_range, ' - ')` | Prevents invalid format from crashing query |

---

#### TC-CR30: Controller toggleStatus() — Inline Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuizAllocationController::toggleStatus()` | Uses `Illuminate\Http\Request` directly (not QuizAllocationRequest) |
| 2 | Verify inline validation: `$request->validate(['is_active' => 'required|boolean'])` | Validates is_active is boolean before processing |
| 3 | Verify AJAX response on success: `response()->json(['success' => true, 'is_active' => $allocation->is_active, 'message' => ...])` | JSON response with new status |
| 4 | Verify 500 JSON on failure | `response()->json(['success' => false, 'message' => ...], 500)` |

---

#### TC-CR31: Blade JS Validation — Server-Side Gaps

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `create.blade.php` client-side JS validation in `$('#quizAllocationForm').on('submit')` | JS validates date ordering |
| 2 | Verify JS check: `publishedVal > dueDate` → "Published date cannot be after due date" | NOT validated server-side |
| 3 | Verify JS check: `cutVal < publishedVal` → "Cut-off date cannot be before published date" | NOT validated server-side |
| 4 | Check `QuizAllocationRequest::rules()` for corresponding server rules | No rules for published_at vs due_date or cut_off_date vs published_at |
| 5 | Verify bypass impact: direct POST can create allocation with illogical dates | These validations only exist client-side; server will accept invalid date ordering |

---

#### TC-CR15: Controller store() — activityLog Created Event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `QuizAllocationController::store()` for activityLog call | `activityLog($allocation, 'Created', ...)` called after `QuizAllocation::create(...)` |
| 2 | After store() executes, query activity_log table | `SELECT * FROM activity_log WHERE subject_id = {id} AND subject_type = 'Modules\\LmsQuiz\\Models\\QuizAllocation' AND event = 'Created'` returns 1 row |

---

#### TC-CR16: Controller restore() — activityLog Restored Event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `QuizAllocationController::restore()` for activityLog call | `activityLog($allocation, 'Restored', ...)` called after `$allocation->restore()` |
| 2 | After restore() executes, query activity_log table | `SELECT * FROM activity_log WHERE subject_id = {id} AND subject_type = 'Modules\\LmsQuiz\\Models\\QuizAllocation' AND event = 'Restored'` returns 1 row |

---

#### TC-CR17: Controller forceDelete() — activityLog Deleted Event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `QuizAllocationController::forceDelete()` for activityLog call | `activityLog($record, 'Deleted', ...)` called after `$allocation->forceDelete()` |
| 2 | After forceDelete() executes, query activity_log table | `SELECT * FROM activity_log WHERE subject_id = {id} AND subject_type = 'Modules\\LmsQuiz\\Models\\QuizAllocation' AND event = 'Deleted'` returns 1 row |

---

#### TC-CR18: Controller toggleStatus() — activityLog Toggled Event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `QuizAllocationController::toggleStatus()` for activityLog call | `activityLog($allocation, 'Toggled', ...)` called after `$allocation->save()` |
| 2 | After toggleStatus() executes, query activity_log table | `SELECT * FROM activity_log WHERE subject_id = {id} AND subject_type = 'Modules\\LmsQuiz\\Models\\QuizAllocation' AND event = 'Toggled'` returns 1 row |

---

## 8. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | No Quiz status check (only is_active) | Medium | Request checks `$quiz->is_active` but NOT `$quiz->status === 'PUBLISHED'`. A DRAFT quiz could potentially be allocated if is_active=true. |
| KI-02 | No max_attempts field on allocation | Medium | The model has no max_attempts field. Attempt limits are controlled solely by the Quiz's allow_multiple_attempts + max_attempts settings. |
| KI-03 | No allocation title field | Low | Allocations have no title/name. They are identified by quiz title + target name. Makes it hard to distinguish multiple allocations for the same quiz. |
| KI-04 | Single target per allocation | Low | Each allocation can only target one entity (one class, one section, one group, or one student). To allocate to multiple groups, multiple allocations must be created. Old TC incorrectly assumed multi-target support. |
| KI-05 | No start_date — only due_date | Low | No explicit start_date. The old TC assumed one. Start is implicitly published_at or now. |
| KI-06 | edit() runs usage check before Gate authorize | Low | $usageCheck->isUsed($id) before Gate::authorize() — unnecessary query if unauthorized. |
| KI-07 | No dedicated status gate in Policy | Low | QuizAllocationPolicy doesn't define a `status` method, while other module policies do. Controller uses `update` gate for toggleStatus. |
| KI-08 | Student assertAllocation() omits GROUP type | **High** | `StudentQuizAttemptController::assertAllocation()` only checks CLASS, SECTION, and STUDENT allocation types. GROUP-type allocations are NOT matched, so students who belong to a group with a GROUP-allocated quiz will get 403 when trying to access it. This affects both listing (`visibleAllocations()`) and attempt endpoints. Fix required: add GROUP resolution branch that checks student group membership. |
| KI-09 | Request/Controller getTargetTable() mismatch for SECTION | **Medium** | `QuizAllocationRequest::getTargetTable()` returns `sch_sections` for SECTION type, but `QuizAllocationController::getTargetTable()` returns `sch_class_section_jnt`. The Request validates `target_id` against `sch_sections.id`, but the Controller stores the ClassSection junction ID with `target_table_name='sch_class_section_jnt'`. This inconsistency means re-validating stored SECTION records would fail. |
| KI-10 | No server-side published_at vs due_date ordering validation | **Medium** | The Request validates `due_date >= now()` and `cut_off_date >= due_date`, but does NOT validate `published_at <= due_date`. Client-side JS blocks this, but a direct POST bypass can create an allocation visible from after its deadline. |
| KI-11 | No server-side cut_off_date vs published_at ordering validation | **Low** | The Request does not validate `cut_off_date >= published_at`. Client-side JS blocks this, but a direct POST bypass can create an allocation whose cut-off date is before it becomes visible. |
| KI-12 | Blade-level JS validation not mirrored server-side | **Low** | The `create.blade.php` JS validates `published_at ≤ due_date` and `cut_off_date ≥ published_at`, but `QuizAllocationRequest` has no corresponding rules. These are purely client-side protections. Students/admins using API or direct POST can bypass them. |

---

## 9. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/lms-quize/quiz-allocation` | lms-quize.quiz-allocation.index | index() | tenant.quiz-allocation.viewAny |
| GET | `/lms-quize/quiz-allocation/create` | lms-quize.quiz-allocation.create | create() | tenant.quiz-allocation.create |
| POST | `/lms-quize/quiz-allocation` | lms-quize.quiz-allocation.store | store() | Request → tenant.quiz-allocation.create |
| GET | `/lms-quize/quiz-allocation/{quiz_allocation}` | lms-quize.quiz-allocation.show | show() | tenant.quiz-allocation.view |
| GET | `/lms-quize/quiz-allocation/{quiz_allocation}/edit` | lms-quize.quiz-allocation.edit | edit() | tenant.quiz-allocation.update |
| PUT | `/lms-quize/quiz-allocation/{quiz_allocation}` | lms-quize.quiz-allocation.update | update() | Request → tenant.quiz-allocation.update |
| DELETE | `/lms-quize/quiz-allocation/{quiz_allocation}` | lms-quize.quiz-allocation.destroy | destroy() | tenant.quiz-allocation.delete |
| GET | `/lms-quize/quiz-allocation/trash/view` | lms-quize.quiz-allocation.trashed | trashed() | tenant.quiz-allocation.restore |
| GET | `/lms-quize/quiz-allocation/{id}/restore` | lms-quize.quiz-allocation.restore | restore() | tenant.quiz-allocation.restore |
| DELETE | `/lms-quize/quiz-allocation/{id}/force-delete` | lms-quize.quiz-allocation.forceDelete | forceDelete() | tenant.quiz-allocation.forceDelete |
| POST | `/lms-quize/quiz-allocation/{quiz_allocation}/toggle-status` | lms-quize.quiz-allocation.toggleStatus | toggleStatus() | tenant.quiz-allocation.update |
| POST | `/lms-quize/quiz-allocation/{id}/publish-recommendations` | lms-quize.quiz-allocation.publishRecommendations | publishRecommendations() | tenant.quiz-allocation.update |
| GET | `/lms-quize/quiz-allocation/get-target-options` | lms-quize.quiz-allocation.getTargetOptions | getTargetOptions() | — |
| GET | `/lms-quize/quiz-allocation/get-quizzes` | lms-quize.quiz-allocation.get-quizzes | getQuizzes() | — |

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | No Quiz status check (only is_active) | Medium | Request checks `$quiz->is_active` but NOT `$quiz->status === 'PUBLISHED'`. A DRAFT quiz could potentially be allocated if is_active=true. |
| KI-02 | No max_attempts field on allocation | Medium | The model has no max_attempts field. Attempt limits are controlled solely by the Quiz's allow_multiple_attempts + max_attempts settings. |
| KI-03 | No allocation title field | Low | Allocations have no title/name. They are identified by quiz title + target name. Makes it hard to distinguish multiple allocations for the same quiz. |
| KI-04 | Single target per allocation | Low | Each allocation can only target one entity (one class, one section, one group, or one student). To allocate to multiple groups, multiple allocations must be created. Old TC incorrectly assumed multi-target support. |
| KI-05 | No start_date — only due_date | Low | No explicit start_date. The old TC assumed one. Start is implicitly published_at or now. |
| KI-06 | edit() runs usage check before Gate authorize | Low | $usageCheck->isUsed($id) before Gate::authorize() — unnecessary query if unauthorized. |
| KI-07 | No dedicated status gate in Policy | Low | QuizAllocationPolicy doesn't define a `status` method, while other module policies do. Controller uses `update` gate for toggleStatus. |
| KI-08 | Student assertAllocation() omits GROUP type | **High** | `StudentQuizAttemptController::assertAllocation()` only checks CLASS, SECTION, and STUDENT allocation types. GROUP-type allocations are NOT matched, so students who belong to a group with a GROUP-allocated quiz will get 403 when trying to access it. This affects both listing (`visibleAllocations()`) and attempt endpoints. Fix required: add GROUP resolution branch that checks student group membership. |
| KI-09 | Request/Controller getTargetTable() mismatch for SECTION | **Medium** | `QuizAllocationRequest::getTargetTable()` returns `sch_sections` for SECTION type, but `QuizAllocationController::getTargetTable()` returns `sch_class_section_jnt`. The Request validates `target_id` against `sch_sections.id`, but the Controller stores the ClassSection junction ID with `target_table_name='sch_class_section_jnt'`. This inconsistency means re-validating stored SECTION records would fail. |
| KI-10 | No server-side published_at vs due_date ordering validation | **Medium** | The Request validates `due_date >= now()` and `cut_off_date >= due_date`, but does NOT validate `published_at <= due_date`. Client-side JS blocks this, but a direct POST bypass can create an allocation visible from after its deadline. |
| KI-11 | No server-side cut_off_date vs published_at ordering validation | **Low** | The Request does not validate `cut_off_date >= published_at`. Client-side JS blocks this, but a direct POST bypass can create an allocation whose cut-off date is before it becomes visible. |
| KI-12 | Blade-level JS validation not mirrored server-side | **Low** | The `create.blade.php` JS validates `published_at ≤ due_date` and `cut_off_date ≥ published_at`, but `QuizAllocationRequest` has no corresponding rules. These are purely client-side protections. Students/admins using API or direct POST can bypass them. |

---

## 10. Execution Status

| Section | Total TCs | Executed | Passed | Failed | Blocked | Not Executed |
|---------|-----------|----------|--------|--------|---------|--------------|
| Positive (6.1) | 21 | 0 | 0 | 0 | 0 | 21 |
| Negative (6.2) | 27 | 0 | 0 | 0 | 0 | 27 |
| Dependency (6.3) | 12 | 0 | 0 | 0 | 0 | 12 |
| Code Review (6.4) | 31 | 0 | 0 | 0 | 0 | 31 |
| **Total** | **91** | **0** | **0** | **0** | **0** | **91** |

**Legend**: ⬜ = Pending Execution | ✅ = Passed | ❌ = Failed | ⛔ = Blocked | ◌ = Code Review (structure verified, not executed)

---

*TC List generated from actual codebase analysis — all TCs based on verified controller, model, request, policy, service, route, and blade file contents.*

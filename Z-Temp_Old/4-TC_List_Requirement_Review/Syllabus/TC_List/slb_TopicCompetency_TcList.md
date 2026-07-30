# slb_topic_competency_jnt_TcList

## Module: Syllabus → Syllabus Master → Topic-Competency Mapping

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Syllabus Master |
| Feature | Topic-Competency Mapping |
| URL(s) | `/syllabus/master` (index via tab), `/syllabus/topic-competency/create` (create), `/syllabus/topic-competency/store` (store), `/syllabus/topic-competency/{id}` (show), `/syllabus/topic-competency/{id}/edit` (edit), `/syllabus/topic-competency/{id}/update` (update), `/syllabus/topic-competency/{id}/destroy` (destroy), `/syllabus/topic-competency/{id}/restore` (restore), `/syllabus/topic-competency/{id}/force-delete` (forceDelete), `/syllabus/topic-competency/trash/view` (trash), `/syllabus/topic-competency/toggle-status/{id}` (toggleStatus) |
| Controller | `Modules\Syllabus\Http\Controllers\TopicCompetencyController` |
| Model(s) | `Modules\Syllabus\Models\TopicCompetency` |
| Validation (Create) | `Modules\Syllabus\Http\Requests\TopicCompetencyRequest` |
| Validation (Update) | `Modules\Syllabus\Http\Requests\TopicCompetencyRequest` |
| Permissions | `tenant.topic-competency.viewAny`, `tenant.topic-competency.view`, `tenant.topic-competency.create`, `tenant.topic-competency.update`, `tenant.topic-competency.delete`, `tenant.topic-competency.restore`, `tenant.topic-competency.forceDelete` |
| Soft Deletes | Yes (`TopicCompetency` uses `SoftDeletes` trait) |
| Activity Log | Events: `Stored`, `Updated`, `Restored`, `Deleted`, `Force Deleted`, `Toggle Status` |
| Pagination | 10 per page |
| Bulk Store | Accepts `topic_ids[]` + `competencies[]` array format |

---

## 2. Pre-conditions

- Required permissions: `tenant.topic-competency.viewAny`, `tenant.topic-competency.view`, `tenant.topic-competency.create`, `tenant.topic-competency.update`, `tenant.topic-competency.delete`, `tenant.topic-competency.restore`, `tenant.topic-competency.forceDelete`
- Required seed data: At least one active `Topic`, one active `Competencie`
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For bulk tests: Multiple topics and competencies need to exist
- For primary flag tests: At least 2 competencies mapped to the same topic

---

---

## 3. Default Data Load

When the page loads via SyllabusController@master() (GET /syllabus/master), the following data is fetched and passed to the view:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: Classes | SyllabusController@master() | SchoolClass::where('is_active',1)->orderBy('ordinal') | is_active=1 | None |
| Shared: Sections | SyllabusController@master() | Section::where('is_active',1)->orderBy('name') | is_active=1 | None |
| Shared: Subjects | SyllabusController@master() | Subject::where('is_active',1)->orderBy('name') | is_active=1 | None |
| Shared: Academic Sessions | SyllabusController@master() | OrganizationAcademicSession::orderBy('name') | None | None |
| Shared: Books | SyllabusController@master() | BokBook::where('is_active',1)->orderBy('title') | is_active=1 | None |
| Shared: All Lessons | SyllabusController@master() | Lesson::with(class,subject)->orderBy('name') | None | None |
| Shared: Topic Level Types | SyllabusController@master() | TopicLevelType::where('is_active',1)->orderBy('level') | is_active=1 | None |
| Shared: Competency Types | SyllabusController@master() | CompetencyType::where('is_active',1) | is_active=1 | None |
| Shared: All Competencies | SyllabusController@master() | Competencie::all() | None | None |
| Shared: All Topics | SyllabusController@master() | Topic::all() | None | None |
| Topic-Competency Grid | getTopicCompetencies() | TopicCompetency::with(topic.class,subject,competency.competencyType) | search via whereHas(topic,competency), filters(class_id,subject_id,topic_id,competency_id,status) | 10/page (topic_competencies_page) |
## 4. Test Data Strategy

- **Unique suffix**: `now()->format(\'His\') . random_int(100, 999)` via `uniqueSuffix()` method
- **Bulk store**: `store()` accepts `topic_ids` (array) + `competencies` (array of `{competency_id, weightage, is_primary}`)
- **Duplicate skip**: If mapping already exists, silently skipped (not an error)
- **Single primary**: Only first `is_primary=1` per topic is stored; subsequent ignored
- **Pre-test cleanup**: Delete created mappings by topic+competency combo before/after tests
- **Soft deletes**: `destroy()` calls `delete()`, records remain with `deleted_at`
- **UUID**: Not present on this junction table (uses composite unique key)

---

## 5. Business Conditions

### 4.1 Database Schema -- `slb_topic_competency_jnt`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT PK | Auto-increment |
| BC-DB-02 | topic_id | BIGINT FK | NOT NULL, FK \u2192 `slb_topics.id`, ON DELETE CASCADE |
| BC-DB-03 | competency_id | BIGINT FK | NOT NULL, FK \u2192 `slb_competencies.id`, ON DELETE CASCADE |
| BC-DB-04 | weightage | DECIMAL(5,2) | DEFAULT NULL |
| BC-DB-05 | is_primary | TINYINT(1) | DEFAULT 0 |
| BC-DB-06 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-07 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-08 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-09 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-10 | UNIQUE | (topic_id, competency_id) | Prevents duplicate mappings |

### 4.2 Validation Rules -- `TopicCompetencyRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | topic_ids | required, array, min:1 | "Please select at least one topic." |
| BC-VAL-02 | topic_ids.* | integer, exists:slb_topics,id | "One or more selected topics are invalid." |
| BC-VAL-03 | competencies | required, array, min:1 | "Please select at least one competency." |
| BC-VAL-04 | competencies.*.competency_id | required, integer, exists:slb_competencies,id | "Competency is required." / "Selected competency does not exist." |
| BC-VAL-05 | competencies.*.weightage | nullable, numeric, min:0, max:100 | "Weightage must be numeric." / "Weightage cannot exceed 100%." |
| BC-VAL-06 | competencies.*.is_primary | boolean | -- |

### 4.3 Validation Rules -- `TopicCompetencyRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | topic_id | integer, exists:slb_topics,id | -- |
| BC-VAL-U02 | competency_id | integer, exists:slb_competencies,id | -- |
| BC-VAL-U03 | weightage | nullable, numeric, min:0, max:100 | -- |
| BC-VAL-U04 | is_primary | boolean | -- |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.topic-competency.viewAny | index() | Without \u2192 403 |
| BC-AUTH-02 | tenant.topic-competency.view | show() | Without \u2192 403 |
| BC-AUTH-03 | tenant.topic-competency.create | create(), store() | Without \u2192 403 |
| BC-AUTH-04 | tenant.topic-competency.update | edit(), update(), toggleStatus() | Without \u2192 403 |
| BC-AUTH-05 | tenant.topic-competency.delete | destroy() | Without \u2192 403 |
| BC-AUTH-06 | tenant.topic-competency.restore | restore(), trashed() | Without \u2192 403 |
| BC-AUTH-07 | tenant.topic-competency.forceDelete | forceDelete() | Without \u2192 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Bulk store format | `topic_ids[]` \u00d7 `competencies[]` creates N\u00d7M junction records |
| BC-BIZ-02 | Duplicate skip | Existing `(topic_id, competency_id)` combo silently skipped |
| BC-BIZ-03 | Single primary per topic | Only first competency with `is_primary=1` per topic stored; rest ignored |
| BC-BIZ-04 | Soft delete | `destroy()` calls `$entry->delete()` setting `deleted_at` |
| BC-BIZ-05 | Force delete | `forceDelete()` permanently removes record |
| BC-BIZ-06 | Restore from trash | `restore()` restores soft-deleted mapping |
| BC-BIZ-07 | Toggle status | `toggleStatus()` inverts `is_active` |
| BC-BIZ-08 | Activity logging | Stored, Updated, Restored, Deleted, Force Deleted, Toggle Status all logged |
| BC-BIZ-09 | FK CASCADE from topic | When topic deleted, mapping auto-removed |
| BC-BIZ-10 | FK CASCADE from competency | When competency deleted, mapping auto-removed |
| BC-BIZ-11 | prepareForValidation | Normalizes `topic_ids` to unique int array; normalizes `competencies` array |
| BC-BIZ-12 | Screen loads via SyllabusController@master() at GET /syllabus/master with master tab group | Navigating to GET /syllabus/master with appropriate permissions loads the Master tab group; this screen's grid data is fetched and displayed |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | topic_id | slb_topics (id) | CASCADE |
| BC-REF-02 | competency_id | slb_competencies (id) | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Topic-Competency Page Loads | Page loads with topic filter, competency filter, mapping table, Add button | -- | -- | \u2b1c |
| TC-P02 | Filter Mappings By Topic | Table shows only mappings for selected topic | -- | -- | \u2b1c |
| TC-P03 | Filter Mappings By Competency | Table shows only mappings for selected competency | -- | -- | \u2b1c |
| TC-P04 | Map Single Topic To Single Competency | Junction record created with topic_id + competency_id | -- | -- | \u2b1c |
| TC-P05 | Map Single Topic To Multiple Competencies | Multiple junction records created for same topic | -- | -- | \u2b1c |
| TC-P06 | Map Multiple Topics To Single Competency | Junction records for each topic with same competency | -- | -- | \u2b1c |
| TC-P07 | Bulk Mapping (2 Topics \u00d7 3 Competencies) | 6 junction records created in single transaction | -- | -- | \u2b1c |
| TC-P08 | Set Primary Competency For Topic | `is_primary=1` set; first primary honored | -- | -- | \u2b1c |
| TC-P09 | Map With Weightage Value | `weightage` saved as decimal | -- | -- | \u2b1c |
| TC-P10 | Map Without Weightage (Default Null) | `weightage` = NULL in DB | -- | -- | \u2b1c |
| TC-P11 | Update Mapping Weightage | Weightage updated; activity "Updated" logged | -- | -- | \u2b1c |
| TC-P12 | Update Mapping -- Change Primary Flag | is_primary toggled | -- | -- | \u2b1c |
| TC-P13 | View Mapping Detail Page | Shows topic details, competency details, weightage, primary status | -- | -- | \u2b1c |
| TC-P14 | Soft Delete Mapping | `deleted_at` set; mapping no longer visible on list | -- | -- | \u2b1c |
| TC-P15 | Trash Page Shows Deleted Mappings | Trash paginated list with restore + force delete buttons | -- | -- | \u2b1c |
| TC-P16 | Restore Mapping From Trash | `deleted_at` = NULL; visible again; activity "Restored" | -- | -- | \u2b1c |
| TC-P17 | Force Delete Mapping (Permanent) | Record permanently removed; activity "Force Deleted" | -- | -- | \u2b1c |
| TC-P18 | Toggle Status Active \u2194 Inactive | `is_active` flips; JSON 200 with success | -- | -- | \u2b1c |
| TC-P19 | Empty State -- No Mappings For Filter | Table shows "No mappings found" message | -- | -- | \u2b1c |
| TC-P20 | Create Form Loads Topic + Competency Dropdowns | Form shows all active topics and competencies for selection | -- | -- | \u2b1c |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required -- Empty `topic_ids` | "Please select at least one topic." | -- | -- | \u2b1c |
| TC-N02 | Required -- Empty `competencies` | "Please select at least one competency." | -- | -- | \u2b1c |
| TC-N03 | Invalid FK -- Non-Existent `topic_id` | "One or more selected topics are invalid." | -- | -- | \u2b1c |
| TC-N04 | Invalid FK -- Non-Existent `competency_id` | "Selected competency does not exist." | -- | -- | \u2b1c |
| TC-N05 | Invalid Weightage -- Negative | "Weightage must be numeric." or min:0 | -- | -- | \u2b1c |
| TC-N06 | Invalid Weightage -- > 100 | "Weightage cannot exceed 100%." | -- | -- | \u2b1c |
| TC-N07 | Invalid Weightage -- Non-Numeric | "Weightage must be numeric." | -- | -- | \u2b1c |
| TC-N08 | Duplicate Mapping (Same Topic + Same Competency) | Silently skipped (not error), only one record exists | -- | -- | \u2b1c |
| TC-N09 | Second Primary Flag On Same Topic | Second `is_primary=1` ignored; first remains primary | -- | -- | \u2b1c |
| TC-N10 | View Mapping With Invalid ID (404) | 404 error: Model not found | -- | -- | \u2b1c |
| TC-N11 | Edit/Update With Invalid ID (404) | 404 error: Model not found | -- | -- | \u2b1c |
| TC-N12 | Delete With Invalid ID (404) | 404 error: Model not found | -- | -- | \u2b1c |
| TC-N13 | Permission 403 -- No Topic-Competency Permissions | 403 Forbidden on all endpoints | -- | -- | \u2b1c |
| TC-N14 | Guest Access Redirect | Redirected to /login | -- | -- | \u2b1c |
| TC-N15 | Restore Non-Deleted Mapping | `onlyTrashed()->find()` returns null \u2192 404 | -- | -- | \u2b1c |
| TC-N16 | Force Delete Non-Trashed Mapping | `onlyTrashed()->find()` returns null \u2192 404 | -- | -- | \u2b1c |
| TC-N17 | `topic_ids` Contains Duplicate IDs | `prepareForValidation()` deduplicates; no error | -- | -- | \u2b1c |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Topic Deletion Auto-Removes Mapping (CASCADE) | When topic force-deleted, junction record auto-deleted | -- | -- | \u2b1c |
| TC-D02 | A | Competency Deletion Auto-Removes Mapping (CASCADE) | When competency force-deleted, junction record auto-deleted | -- | -- | \u2b1c |
| TC-D03 | B | Topic Soft-Delete \u2192 Mapping Soft-Deleted | Topic model `deleting` event cascades to mapping | -- | -- | \u2b1c |
| TC-D04 | B | Competency Soft-Delete \u2192 Mapping Soft-Deleted | Competency model `deleting` event cascades to mapping | -- | -- | \u2b1c |
| TC-D05 | C | Same Mapping Allowed For Different Topic+Competency | Different combo passes unique constraint | -- | -- | \u2b1c |
| TC-D06 | D | Bulk Store -- Partial Duplicates Handled | 3 competencies to map, 1 duplicate \u2192 2 new records created, 1 skipped | -- | -- | \u2b1c |
| TC-D07 | E | Toggle Status On Inactive Mapping | Inactive mapping excluded | -- | -- | \u2b1c |
| TC-D08 | E | Activity Log -- All Mapping Events Tracked | Stored, Updated, Deleted, Restored, Force Deleted, Toggle Status all logged | -- | -- | \u2b1c |
| TC-D09 | F | DB \| P1 \| slb_topic_competency_jnt with existing junction record — Composite Unique Constraint — uq_tc_topic_competency (topic_id + competency_id) | Inserting duplicate (topic_id, competency_id) combination at DB level throws integrity constraint violation | -- | -- | \u2b1c |
| TC-D10 | G | DB \| P1 \| slb_topic_competency_jnt with existing record — FK CASCADE — topic_id Deletion | Deleting a topic (slb_topics.id) cascades to delete all junction records where topic_id = deleted id | -- | -- | \u2b1c |
| TC-D11 | H | DB \| P1 \| slb_topic_competency_jnt with existing record — FK CASCADE — competency_id Deletion | Deleting a competency (slb_competencies.id) cascades to delete all junction records where competency_id = deleted id | -- | -- | \u2b1c |
| TC-D12 | I | UI/API \| P1 \| Topic-competency assignment form open — DECIMAL(5,2) Precision — weightage Field | weightage field accepts values like 99.99 and -999.99; rejects values exceeding DECIMAL(5,2) precision (e.g., 1000.00 or 1234.56) | -- | -- | \u2b1c |
| TC-D13 | J | DEV \| P1 \| TopicCompetency Model — $table Property — slb_topic_competency_jnt | Model `$table` property maps to correct DB table name `slb_topic_competency_jnt` | -- | -- | \u2b1c |
| TC-D14 | K | DEV \| P1 \| TopicCompetency Model — $fillable Array — Junction Columns | `$fillable` contains all junction columns: topic_id, competency_id, weightage, is_active | -- | -- | \u2b1c |
| TC-D15 | L | DEV \| P1 \| TopicCompetency Model — SoftDeletes Trait | Model uses `SoftDeletes` trait; `deleted_at` column exists and nullable | -- | -- | \u2b1c |
| TC-D16 | M | DEV \| P1 \| TopicCompetency Model — $casts — is_active boolean, weightage decimal | `$casts` defines `is_active => boolean` and `weightage => decimal:2`; values cast correctly at runtime | -- | -- | \u2b1c |
| TC-D17 | N | DEV \| P1 \| TopicCompetency Model — belongsTo topic Relationship | `topic()` returns `$this->belongsTo(Topic::class)`; FK `topic_id` matches DB column | -- | -- | \u2b1c |
| TC-D18 | O | DEV \| P1 \| TopicCompetency Model — belongsTo competency Relationship | `competency()` returns `$this->belongsTo(Competency::class)`; FK `competency_id` matches DB column | -- | -- | \u2b1c |
| TC-D19 | P | DEV \| P1 \| TopicCompetency Controller — findOrFail Usage | `show()`, `edit()`, `update()`, `destroy()` use `findOrFail($id)`; invalid ID returns 404 | -- | -- | \u2b1c |
| TC-D20 | Q | DEV \| P1 \| TopicCompetency Controller — Gate::authorize Before CRUD | `Gate::authorize('tenant.topic-competency.*')` present before each CRUD operation; missing permission returns 403 | -- | -- | \u2b1c |
| TC-D21 | R | DEV \| P1 \| TopicCompetencyRequest — Unique Validation on (topic_id + competency_id) | Request has unique rule on `slb_topic_competency_jnt` for `(topic_id, competency_id)` combination | -- | -- | \u2b1c |
| TC-D22 | S | DEV \| P1 \| TopicCompetencyRequest — Required Fields (topic_id, competency_id) + Nullable weightage | `topic_ids` required, `competencies.*.competency_id` required, `competencies.*.weightage` nullable|numeric|min:0|max:100 | -- | -- | \u2b1c |
| TC-D23 | T | DEV \| P1 \| TopicCompetencyPolicy — All Gates Defined | Policy defines viewAny, view, create, update, delete, restore, forceDelete, status gates; registered in AuthServiceProvider | -- | -- | \u2b1c |
| TC-D24 | U | DEV \| P1 \| TopicCompetency Controller — activityLog() After CRUD | `activityLog(...)` called after store, update, destroy, restore, forceDelete, toggleStatus; all 6 event types logged | -- | -- | \u2b1c |
| TC-D25 | V | DEV \| P1 \| TopicCompetency Controller — destroy() Sets is_active=false Before delete() | `destroy()` sets `is_active = false` before `$mapping->delete()` to mark inactive prior to soft delete | -- | -- | \u2b1c |
| TC-D26 | W | DEV \| P1 \| TopicCompetency Routes — Resource + Extra Routes | Resource routes + view, trashed, restore, forceDelete, toggleStatus all defined and map to correct controller methods | -- | -- | \u2b1c |
| TC-D27 | X | DEV \| P1 \| TopicCompetency — is_active Handled Consistently as Boolean | Model casts as boolean, DB TINYINT(1), request validation boolean rule, toggleStatus inverts correctly, destroy sets false | -- | -- | \u2b1c |
| TC-D28 | Y | DEV \| P1 \| Bulk AJAX Update — topic_ids[] + competencies[] | store() accepts array format topic_ids[] and competencies[][competency_id, weightage]; validates each competency row individually; creates all valid mappings | -- | -- | \u2b1c |
| TC-D29 | Z | DEV \| P1 \| toggleStatus() requires tenant.topic-competency.update permission | Gate::authorize('tenant.topic-competency.update') is called before toggleStatus() logic; missing permission returns 403 | -- | -- | \u2b1c |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.topic-competency.create'), @can('tenant.topic-competency.edit'), @can('tenant.topic-competency.delete'), @can('tenant.topic-competency.status'), @can('tenant.topic-competency.view'), @canany(['tenant.topic-competency.restore', 'tenant.topic-competency.forceDelete']) for access control on all CRUD buttons and actions | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | `syllabus.master` key → `'syllabus/master'` defined in `config/breadcrumb.php`; breadcrumb visible and links correctly to parent screen | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — try-catch Exception Handling on All CRUD Methods | All state-changing methods (store, update, destroy, restore, forceDelete) use try-catch; exceptions are caught, logged, and user receives error feedback; no unhandled \Exception causes 500 | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — DB Transactions on Multi-Step Writes | Methods performing multiple DB operations (create+activityLog, destroy+is_active toggle) use DB::transaction() or beginTransaction/commit/rollback; partial writes do not occur on failure | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Relationship expressions in Blade use isset($var->relation) / optional($var?->relation) / null-safe operator; no undefined index/property errors when relation is null | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | View — Success Flash Messages After Create/Update/Delete | After CRUD actions, controller redirects with success flash; Blade displays success alert with correct action-specific message | — | — | ◌ |


---



## 7. Detailed Test Steps



#### TC-CR03: Controller — try-catch Exception Handling on All CRUD Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller file for this screen | Controller class found in Modules/Syllabus/Http/Controllers/
| 2 | Inspect store() method | Business logic wrapped in try {} catch(\Exception $e) {}; on exception, DB rollback and error logged
| 3 | Inspect update() method | try-catch present; findOrFail inside try; validation errors from FormRequest caught before try block
| 4 | Inspect destroy() method | try-catch present; is_active toggle inside try; activityLog inside try
| 5 | Inspect restore() method | try-catch present; is_active restore inside try
| 6 | Inspect forceDelete() method | try-catch present; onlyTrashed+findOrFail inside try
| 7 | Simulate DB failure during store (e.g. unique constraint violation) | Exception caught; user redirected with error message; no partial data written


#### TC-CR04: Controller — DB Transactions on Multi-Step Writes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller file for this screen | Controller class found
| 2 | Inspect methods that combine create/update + activityLog | Both operations wrapped in DB::transaction(); if activityLog fails, create/update is rolled back
| 3 | Inspect destroy() method | is_active=false toggle + delete() + activityLog all in single transaction
| 4 | Inspect restore() method | is_active=true + restore() + activityLog in single transaction
| 5 | Verify no partial writes occur | If activityLog throws exception after model save, model changes are rolled back


#### TC-CR05: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open index.blade.php for this screen | View file found in lesson-management/partials/
| 2 | Scan for relationship access patterns (e.g. $record->relation->field) | All such expressions use isset() or optional() or ?-> null-safe operator
| 3 | Scan for foreach loops over relationships | Loop target checked with isset() or !empty() before iterating
| 4 | Create a record with null relationship | View renders without undefined index/property error
| 5 | Load index page with records that have missing relations | No 500 errors; null values displayed gracefully (dash or empty string)


#### TC-CR06: View — Success Flash Messages After Create/Update/Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new record | POST to store(); redirects with session flash
| 2 | Verify success message after create | Page shows success alert: ‘Complexity level created successfully’ (or equivalent for this screen)
| 3 | Update the record | PUT/PATCH to update(); redirects with flash
| 4 | Verify success message after update | ‘Complexity level updated successfully’ (or equivalent)
| 5 | Soft delete the record | DELETE to destroy(); redirects with flash
| 6 | Verify success message after delete | ‘Complexity level trashed successfully’ (or equivalent)
| 7 | Restore from trash | POST to restore(); redirects with flash
| 8 | Verify success message after restore | ‘Complexity level restored successfully’ (or equivalent)
| 9 | Force delete from trash | DELETE to forceDelete(); redirects with flash
| 10 | Verify success message after force delete | ‘Complexity level force deleted successfully’ (or equivalent)


#### TC-CR01: Blade @can Directives — Permission-based Visibility for All Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php for add/create button | @can('tenant.topic-competency.create') wraps the Add New button; user without create permission does not see it
| 2 | Inspect row-level action buttons (view, edit, delete, status toggle) | @can('tenant.topic-competency.view'), @can('tenant.topic-competency.edit'), @can('tenant.topic-competency.delete'), @can('tenant.topic-competency.status') used appropriately; expired permissions hide corresponding buttons
| 3 | Inspect trash.blade.php for restore/forceDelete buttons | @canany(['tenant.topic-competency.restore', 'tenant.topic-competency.forceDelete']) wraps action buttons in trash view
| 4 | Inspect view.blade.php for edit button | @can('tenant.topic-competency.edit') wraps the Edit button on show/details page
| 5 | Log in as user with all permissions | All buttons visible and functional |
| 6 | Log in as user with viewAny only (no create/edit/delete) | Add New button hidden; action columns show view icon only or no actions |

#### TC-CR02: Breadcrumb Config — Route Registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File contains routing configuration for the syllabus module |
| 2 | Verify the 'syllabus.master' key exists | Config has 'syllabus.master' => 'syllabus/master' entry
| 3 | Verify its value points to the correct parent screen URL | Value 'syllabus/master' correctly references Master tab view
| 4 | Load the screen via the Master tab tab | Breadcrumb trail shows correct hierarchy and highlights current screen |
| 5 | Click the breadcrumb parent link | Navigates correctly to Master tab page without errors |
### 6.1 Positive TC Steps

#### TC-P01: Topic-Competency Page Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Expand "Syllabus" \u2192 "Syllabus Master" \u2192 "Topic-Competency" tab | Page loads at `tab=topic_competency` |
| 3 | Check topic filter dropdown | Dropdown with active topics present |
| 4 | Check competency filter dropdown | Dropdown with active competencies present |
| 5 | Check "Add Mapping" button | Visible |
| 6 | Check mappings table | Columns: Topic, Competency, Weightage, Primary, Status, Actions |

---

#### TC-P02: Filter Mappings By Topic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping for Topic A and Topic B | Both mappings exist |
| 2 | Select Topic A from filter | Only Topic A mapping shown |
| 3 | Clear filter | Both mappings visible |

---

#### TC-P03: Filter Mappings By Competency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping for Competency X and Competency Y | Both mappings exist |
| 2 | Select Competency X from filter | Only X mappings shown |
| 3 | Clear filter | Both visible |

---

#### TC-P04: Map Single Topic To Single Competency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Topic-Competency tab | Page loads |
| 2 | Click "Add Mapping" | Mapping form opens |
| 3 | Select topic from dropdown | Topic selected |
| 4 | Select competency from dropdown | Competency selected |
| 5 | Click "Save" | AJAX POST to store |
| 6 | Check response | Success: "Mapping created successfully." |
| 7 | DB check: `SELECT * FROM slb_topic_competency_jnt WHERE topic_id={T} AND competency_id={C}` | Record exists with `is_active=1` |

---

#### TC-P05: Map Single Topic To Multiple Competencies

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Mapping form | Form visible |
| 2 | Select Topic T1 | Topic selected |
| 3 | Select Competency C1, C2, C3 | 3 competencies selected |
| 4 | Click "Save" | 3 records created |
| 5 | DB check: `SELECT COUNT(*) FROM slb_topic_competency_jnt WHERE topic_id={T1}` | 3 records |

---

#### TC-P06: Map Multiple Topics To Single Competency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Mapping form | Form visible |
| 2 | Select Topics T1, T2, T3 | 3 topics selected |
| 3 | Select Competency C1 | 1 competency selected |
| 4 | Click "Save" | 3 records created |
| 5 | DB check: `SELECT COUNT(*) FROM slb_topic_competency_jnt WHERE competency_id={C1}` | 3 records |

---

#### TC-P07: Bulk Mapping (2 Topics \u00d7 3 Competencies)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Mapping form | Form visible |
| 2 | Select Topics T1, T2 | 2 topics selected |
| 3 | Select Competencies C1, C2, C3 | 3 competencies selected |
| 4 | Set weights: C1=50, C2=30, C3=20 | Weights entered |
| 5 | Set C1 as primary for all topics | Primary flag set |
| 6 | Click "Save" | POST with `topic_ids=[T1,T2]`, `competencies=[{competency_id:C1, weightage:50, is_primary:1}, ...]` |
| 7 | DB check: 6 junction records created | 2\u00d73 = 6 records |

---

#### TC-P08: Set Primary Competency For Topic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Map Topic T1 to Competency C1 with is_primary=1 | C1 is primary |
| 2 | Verify: `SELECT is_primary FROM slb_topic_competency_jnt WHERE topic_id={T1} AND competency_id={C1}` | is_primary=1 |
| 3 | Map Topic T1 to Competency C2 also with is_primary=1 | C2 primary ignored |
| 4 | DB check: C1 still is_primary=1, C2 is_primary=0 | First primary preserved |

---

#### TC-P09: Map With Weightage Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping with weightage=75.50 | Mapping created |
| 2 | DB check: `SELECT weightage FROM slb_topic_competency_jnt WHERE id={id}` | 75.50 |

---

#### TC-P10: Map Without Weightage (Default Null)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping leaving weightage empty | Null weightage |
| 2 | DB check: `weightage` = NULL | Default null |

---

#### TC-P11: Update Mapping Weightage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping with weightage=50 | Exists |
| 2 | Edit mapping, change weightage to 80 | Updated |
| 3 | DB check: weightage=80.00 | Updated |
| 4 | Activity log: "Updated" event | Logged |

---

#### TC-P12: Update Mapping -- Change Primary Flag

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping for T1\u2192C1 with is_primary=0 | Non-primary |
| 2 | Edit, set is_primary=1 | Updated |
| 3 | DB check: is_primary=1 | Changed |

---

#### TC-P13: View Mapping Detail Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping with weightage=60, is_primary=1 | Mapping exists |
| 2 | Click "View" button on the row | Detail page loads |
| 3 | Check topic name displayed | Correct topic shown |
| 4 | Check competency name displayed | Correct competency shown |
| 5 | Check weightage displayed | "60%" or "60.00" |
| 6 | Check primary badge | "Primary" badge shown |
| 7 | Check status | Active/Inactive badge |

---

#### TC-P14: Soft Delete Mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping: Topic T1 \u2192 Competency C1 | Mapping exists with ID=X |
| 2 | Click delete button on that row | SweetAlert "Are you sure?" |
| 3 | Confirm delete | Soft deleted |
| 4 | DB check: `SELECT deleted_at FROM slb_topic_competency_jnt WHERE id={X}` | `deleted_at` NOT NULL |
| 5 | Activity log: "Deleted" event | Logged |

---

#### TC-P15: Trash Page Shows Deleted Mappings

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a mapping | Mapping trashed |
| 2 | Click "Trash" button | Navigates to trash view |
| 3 | Check table shows deleted mapping | Record visible |
| 4 | Check "Restore" and "Force Delete" buttons | Both present |

---

#### TC-P16: Restore Mapping From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash page, click "Restore" on a trashed mapping | Restore succeeds |
| 2 | DB check: `deleted_at` = NULL | Restored |
| 3 | Navigate back to main list | Mapping visible again |
| 4 | Activity log: "Restored" event logged | Event exists |

---

#### TC-P17: Force Delete Mapping (Permanent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete a mapping, then navigate to trash | Mapping in trash |
| 2 | Click "Force Delete" | Confirmation dialog |
| 3 | Confirm | Record permanently removed |
| 4 | DB check: Record gone | Force deleted |
| 5 | Activity log: "Force Deleted" event | Event exists |

---

#### TC-P18: Toggle Status Active \u2194 Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping with is_active=ON | Active |
| 2 | Click toggle switch | AJAX POST to toggle-status |
| 3 | DB check: is_active=0 | Toggled inactive |
| 4 | Click toggle again | is_active=1 |

---

#### TC-P19: Empty State -- No Mappings For Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Filter by a topic+competency combo with zero mappings | No data |
| 2 | Verify table area | Shows "No mappings found" message |
| 3 | Verify Add Mapping button | Visible and enabled |

---

#### TC-P20: Create Form Loads Topic + Competency Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add Mapping" | Form opens |
| 2 | Check topic dropdown | Lists all active topics |
| 3 | Check competency dropdown (multi-select) | Lists all active competencies |
| 4 | Select topic | Selection registered |
| 5 | Select competencies | Multiple selection allowed |

---

### 6.2 Negative TC Steps

#### TC-N01: Required -- Empty `topic_ids`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Mapping form, leave topic_ids empty | No topics selected |
| 2 | Click "Save" | HTTP 500: "Please select at least one topic." |

---

#### TC-N02: Required -- Empty `competencies`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Mapping, select topic, leave competencies empty | No competencies selected |
| 2 | Click "Save" | HTTP 500: "Please select at least one competency." |

---

#### TC-N03: Invalid FK -- Non-Existent `topic_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set topic_ids = [99999] | Non-existent topic |
| 2 | Click "Save" | HTTP 500: "One or more selected topics are invalid." |

---

#### TC-N04: Invalid FK -- Non-Existent `competency_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set competencies = [{competency_id: 99999}] | Non-existent competency |
| 2 | Click "Save" | HTTP 500: "Selected competency does not exist." |

---

#### TC-N05: Invalid Weightage -- Negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping with weightage = -10 | Negative |
| 2 | Click "Save" | HTTP 500: numeric min validation |

---

#### TC-N06: Invalid Weightage -- > 100

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping with weightage = 150 | > 100 |
| 2 | Click "Save" | HTTP 500: "Weightage cannot exceed 100%." |

---

#### TC-N07: Invalid Weightage -- Non-Numeric

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping with weightage = "abc" | Non-numeric |
| 2 | Click "Save" | HTTP 500: "Weightage must be numeric." |

---

#### TC-N08: Duplicate Mapping (Same Topic + Same Competency)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping for T1\u2192C1 | Record exists |
| 2 | Create same T1\u2192C1 mapping again | Silently skipped (not error) |
| 3 | DB check: `SELECT COUNT(*) FROM slb_topic_competency_jnt WHERE topic_id={T1} AND competency_id={C1}` | Only 1 record |

---

#### TC-N09: Second Primary Flag On Same Topic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Map T1\u2192C1 with is_primary=1 | C1 is primary |
| 2 | Map T1\u2192C2 also with is_primary=1 | C2 primary ignored |
| 3 | DB check: C1.is_primary=1, C2.is_primary=0 | First primary preserved |

---

#### TC-N10: View Mapping With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open URL: `/syllabus/topic-competency/99999` | HTTP 404 |

---

#### TC-N11: Edit/Update With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open URL: `/syllabus/topic-competency/99999/edit` | HTTP 404 |

---

#### TC-N12: Delete With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send DELETE to `/syllabus/topic-competency/99999/destroy` | HTTP 404 |

---

#### TC-N13: Permission 403 -- No Topic-Competency Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without any `tenant.topic-competency.*` permissions | 403 on all CRUD endpoints |

---

#### TC-N14: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate to topic-competency tab | Redirected to login |

---

#### TC-N15: Restore Non-Deleted Mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to restore an active (non-deleted) mapping | 404: `onlyTrashed()` returns null |

---

#### TC-N16: Force Delete Non-Trashed Mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to force delete an active mapping | 404: `onlyTrashed()` returns null |

---

#### TC-N17: `topic_ids` Contains Duplicate IDs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit topic_ids = [1, 1, 2] with duplicate | `prepareForValidation()` deduplicates to [1, 2] |
| 2 | Only 2 mappings created (topic 1 with each competency once) | No duplicate |

---

### 6.3 Dependency TC Steps

#### TC-D01: Topic Deletion Auto-Removes Mapping (CASCADE)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create topic with a mapping to competency C1 | Junction record exists |
| 2 | Force delete the topic | DDL CASCADE removes junction record |
| 3 | DB check: `SELECT * FROM slb_topic_competency_jnt WHERE topic_id={T1}` | No records |

---

#### TC-D02: Competency Deletion Auto-Removes Mapping (CASCADE)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency with a mapping from topic T1 | Junction record exists |
| 2 | Force delete the competency | DDL CASCADE removes junction record |
| 3 | DB check: `SELECT * FROM slb_topic_competency_jnt WHERE competency_id={C1}` | No records |

---

#### TC-D03: Topic Soft-Delete \u2192 Mapping Soft-Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create topic with mapping to competency | Mapping exists |
| 2 | Soft delete the topic | Model `deleting` event fires |
| 3 | DB check: Junction record has `deleted_at` set | Cascaded |

---

#### TC-D04: Competency Soft-Delete \u2192 Mapping Soft-Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency with mapping from topic | Mapping exists |
| 2 | Soft delete the competency | Model `deleting` event fires |
| 3 | DB check: Junction record has `deleted_at` set | Cascaded |

---

#### TC-D05: Same Mapping Allowed For Different Topic+Competency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create mapping T1\u2192C1 | Exists |
| 2 | Create mapping T2\u2192C2 (different combo) | Created (unique constraint scoped to combo) |
| 3 | DB check: Both records exist | No conflict |

---

#### TC-D06: Bulk Store -- Partial Duplicates Handled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Existing mapping: T1\u2192C1 already exists | Duplicate |
| 2 | Submit bulk: topic_ids=[T1], competencies=[C1(dup), C2(new), C3(new)] | 3 requested |
| 3 | DB check: 2 new records created (C2, C3), C1 skipped | Total = 3 (1 old + 2 new) |

---

#### TC-D07: Toggle Status On Inactive Mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create inactive mapping (is_active=0) | Mapping inactive |
| 2 | Toggle status to active | is_active=1 |
| 3 | Verify mapping visible in active filter | Shown |

---

#### TC-D08: Activity Log -- All Mapping Events Tracked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create, update, soft delete, restore, force delete, toggle status a mapping | Activity log entries for Stored, Updated, Deleted, Restored, Force Deleted, Toggle Status |
| 2 | Verify each event has correct description and causer | All present |

---

#### TC-D09: Composite Unique Constraint — uq_tc_topic_competency (topic_id + competency_id)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a junction record with topic_id=T1 and competency_id=C1 via application | Record exists in DB |
| 2 | Attempt to insert another junction record with same topic_id=T1 and competency_id=C1 directly via DB (`INSERT INTO slb_topic_competency_jnt ...`) | Integrity constraint violation thrown by DB |
| 3 | Verify error message: Duplicate entry for key `uq_tc_topic_competency` | SQL error: `Duplicate entry 'T1-C1' for key 'uq_tc_topic_competency'` |

---

#### TC-D10: FK CASCADE — topic_id Deletion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create topic T1 mapped to competency C1 | Junction record exists with topic_id=T1 |
| 2 | Delete the topic record from `slb_topics` where id=T1 | DDL CASCADE constraint fires |
| 3 | DB check: `SELECT * FROM slb_topic_competency_jnt WHERE topic_id=T1` | No records returned (junction record auto-deleted) |

---

#### TC-D11: FK CASCADE — competency_id Deletion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency C1 mapped from topic T1 | Junction record exists with competency_id=C1 |
| 2 | Delete the competency record from `slb_competencies` where id=C1 | DDL CASCADE constraint fires |
| 3 | DB check: `SELECT * FROM slb_topic_competency_jnt WHERE competency_id=C1` | No records returned (junction record auto-deleted) |

---

#### TC-D12: DECIMAL(5,2) Precision — weightage Field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit weightage = 99.99 (valid: 3 integer + 2 decimal digits) | Accepted and stored as 99.99 |
| 2 | Submit weightage = -999.99 (valid: negative within DECIMAL(5,2) range) | Accepted (negative values permitted by DECIMAL(5,2)) |
| 3 | Submit weightage = 1000.00 (exceeds DECIMAL(5,2): 4 integer + 2 decimal = 6 digits > 5) | Rejected — exceeds DECIMAL(5,2) precision |
| 4 | Submit weightage = 1234.56 (exceeds DECIMAL(5,2): 6 total digits) | Rejected — exceeds DECIMAL(5,2) precision |

---

#### TC-D13: Model — $table Property — slb_topic_competency_jnt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/Syllabus/Models/TopicCompetency.php` | Model file loads |
| 2 | Check `protected $table = 'slb_topic_competency_jnt'` property | `$table` matches DB table name |
| 3 | DB check: `SHOW TABLES LIKE 'slb_topic_competency_jnt'` | Table exists |

---

#### TC-D14: Model — $fillable Array — Junction Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicCompetency.php` model | File loaded |
| 2 | Check `protected $fillable` array | Contains `topic_id`, `competency_id`, `weightage`, `is_active` |
| 3 | Cross-reference with DB schema columns | All non-PK/non-timestamp columns present in fillable |

---

#### TC-D15: Model — SoftDeletes Trait Present

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicCompetency.php` model | File loaded |
| 2 | Check `use SoftDeletes;` import statement | `SoftDeletes` trait imported from `Illuminate\Database\Eloquent\SoftDeletes` |
| 3 | Check `use SoftDeletes;` inside class body | Trait used correctly |
| 4 | DB check: `deleted_at` column in `slb_topic_competency_jnt` | Column exists, nullable TIMESTAMP |

---

#### TC-D16: Model — $casts — is_active boolean, weightage decimal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicCompetency.php` model | File loaded |
| 2 | Check `protected $casts` array | Contains `'is_active' => 'boolean'` |
| 3 | Check `$casts` array | Contains `'weightage' => 'decimal:2'` |
| 4 | Verify cast behavior: create mapping with `is_active=1`, retrieve and check type | `$mapping->is_active === true` (boolean) |

---

#### TC-D17: Model — belongsTo topic Relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicCompetency.php` model | File loaded |
| 2 | Check `topic()` method | Returns `$this->belongsTo(Topic::class)` or equivalent |
| 3 | Verify relationship: call `$mapping->topic` | Returns `Topic` model instance |
| 4 | Check foreign key convention | `topic_id` matches FK column |

---

#### TC-D18: Model — belongsTo competency Relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicCompetency.php` model | File loaded |
| 2 | Check `competency()` method | Returns `$this->belongsTo(Competency::class)` or equivalent |
| 3 | Verify relationship: call `$mapping->competency` | Returns `Competency` model instance |
| 4 | Check foreign key convention | `competency_id` matches FK column |

---

#### TC-D19: Controller — findOrFail in edit/update/show/destroy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicCompetencyController.php` | Controller file loaded |
| 2 | Check `show($id)` method | Calls `TopicCompetency::findOrFail($id)` |
| 3 | Check `edit($id)` method | Calls `TopicCompetency::findOrFail($id)` |
| 4 | Check `update($id)` method | Calls `TopicCompetency::findOrFail($id)` |
| 5 | Check `destroy($id)` method | Calls `TopicCompetency::findOrFail($id)` |
| 6 | Verify 404 behavior: request `/syllabus/topic-competency/99999/edit` | HTTP 404 returned |

---

#### TC-D20: Controller — Gate::authorize Before CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicCompetencyController.php` | Controller file loaded |
| 2 | Check `index()` method | `Gate::authorize('tenant.topic-competency.viewAny')` present |
| 3 | Check `create()` / `store()` methods | `Gate::authorize('tenant.topic-competency.create')` present |
| 4 | Check `edit()` / `update()` methods | `Gate::authorize('tenant.topic-competency.update')` present |
| 5 | Check `destroy()` method | `Gate::authorize('tenant.topic-competency.delete')` present |
| 6 | Check `restore()` / `trashed()` methods | `Gate::authorize('tenant.topic-competency.restore')` present |
| 7 | Check `forceDelete()` method | `Gate::authorize('tenant.topic-competency.forceDelete')` present |
| 8 | Check `toggleStatus()` method | `Gate::authorize('tenant.topic-competency.update')` present |

---

#### TC-D21: Request — Unique Validation on (topic_id + competency_id)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicCompetencyRequest.php` | Request file loaded |
| 2 | Check `rules()` method for store | Contains `unique` rule on `slb_topic_competency_jnt` for `(topic_id, competency_id)` combination |
| 3 | Check `rules()` method for update | Contains `unique` rule with ignored current record ID |
| 4 | Verify behavior: create duplicate mapping T1→C1 | App-level duplicate silently skipped; only one record exists |

---

#### TC-D22: Request — Required Fields (topic_id, competency_id) + Nullable weightage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicCompetencyRequest.php` | Request file loaded |
| 2 | Check `rules()` for `topic_ids` | `required`, `array`, `min:1` |
| 3 | Check `rules()` for `competencies.*.competency_id` | `required`, `integer`, `exists:slb_competencies,id` |
| 4 | Check `rules()` for `competencies.*.weightage` | `nullable`, `numeric`, `min:0`, `max:100` |
| 5 | Verify error: submit without topic_ids | HTTP 500: "Please select at least one topic." |
| 6 | Verify: submit weightage as null | Accepted, DB stores NULL |

---

#### TC-D23: Policy — All Gates Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicCompetencyPolicy.php` | Policy file loaded |
| 2 | Check `viewAny()` method | Defined and returns gate check |
| 3 | Check `view()` method | Defined and returns gate check |
| 4 | Check `create()` method | Defined and returns gate check |
| 5 | Check `update()` method | Defined and returns gate check |
| 6 | Check `delete()` method | Defined and returns gate check |
| 7 | Check `restore()` method | Defined and returns gate check |
| 8 | Check `forceDelete()` method | Defined and returns gate check |
| 9 | Check `status()` method | Defined for toggleStatus action |
| 10 | Verify Policy registered in `AuthServiceProvider` | `TopicCompetency::class => TopicCompetencyPolicy::class` mapped |

---

#### TC-D24: Activity — activityLog() Called After CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicCompetencyController.php` | Controller file loaded |
| 2 | Check `store()` method | `activityLog(...)` called after successful creation |
| 3 | Check `update()` method | `activityLog(...)` called after successful update |
| 4 | Check `destroy()` method | `activityLog(...)` called after soft delete |
| 5 | Check `restore()` method | `activityLog(...)` called after restore |
| 6 | Check `forceDelete()` method | `activityLog(...)` called after permanent delete |
| 7 | Check `toggleStatus()` method | `activityLog(...)` called after status toggle |
| 8 | Verify logged events in `activity_log` table | Events: Stored, Updated, Deleted, Restored, Force Deleted, Toggle Status |

---

#### TC-D25: Controller — destroy() Sets is_active=false Before delete()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TopicCompetencyController.php` | Controller file loaded |
| 2 | Check `destroy($id)` method | Retrieves model via `findOrFail($id)` |
| 3 | Check `$mapping->is_active = false` before `$mapping->delete()` | `is_active` set to 0/false prior to soft delete |
| 4 | Verify: create mapping → call destroy → check DB | `deleted_at` set AND `is_active=0` |
| 5 | Verify: restore mapping → check `is_active` value | `is_active` remains 0 after restore (preserved) |

---

#### TC-D26: Routes — Resource + Extra Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `php artisan route:list --path=syllabus/topic-competency` | All routes listed |
| 2 | Check resource routes: index, create, store, show, edit, update, destroy | Default resource routes present |
| 3 | Check `GET /syllabus/topic-competency/{id}/view` route | `view` route exists |
| 4 | Check `GET /syllabus/topic-competency/trash/view` route | `trash`/`trashed` route exists |
| 5 | Check `PATCH /syllabus/topic-competency/{id}/restore` route | `restore` route exists |
| 6 | Check `DELETE /syllabus/topic-competency/{id}/force-delete` route | `forceDelete` route exists |
| 7 | Check `POST /syllabus/topic-competency/toggle-status/{id}` route | `toggleStatus` route exists |
| 8 | Verify each route maps to correct controller method | Route–controller mapping correct |

---

#### TC-D27: Boolean — is_active Handled Consistently as Boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `$casts` in TopicCompetency model | `'is_active' => 'boolean'` defined |
| 2 | Check DB schema `is_active` column | `TINYINT(1)`, NOT NULL DEFAULT 1 |
| 3 | Check `TopicCompetencyRequest` validation for `is_active` | `boolean` rule present |
| 4 | Check `toggleStatus()` in controller | Inverts via `$mapping->is_active = !$mapping->is_active` |
| 5 | Check `destroy()` in controller | Sets `is_active = false` before delete |
| 6 | Verify end-to-end: create → toggle → delete → restore cycle | `is_active` always boolean (0/1) across all states |

---

#### TC-D28: Bulk AJAX Update — topic_ids[] + competencies[]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open TopicCompetencyController.php | Controller file loaded |
| 2 | Inspect store() method | Accepts array format: `topic_ids[]` + `competencies[][competency_id]` and `competencies[][weightage]` |
| 3 | Prepare 3 topics (T1, T2, T3) and 2 competencies (C1, C2) | Test data ready |
| 4 | Submit POST to `/syllabus/topic-competency/store` with topic_ids=[T1, T2] and competencies=[{competency_id: C1, weightage: 50}, {competency_id: C2, weightage: 30}] | 4 junction records created (T1→C1, T1→C2, T2→C1, T2→C2) |
| 5 | Submit same request again | Duplicates silently skipped; no new records created |
| 6 | Submit with invalid competency_id | Individual validation error for that row; other valid rows still created |

---

#### TC-D29: toggleStatus() requires tenant.topic-competency.update permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open TopicCompetencyController.php | Controller file loaded |
| 2 | Inspect toggleStatus() method | `Gate::authorize('tenant.topic-competency.update')` called before toggle logic |
| 3 | Log in as user with all permissions | Mapping list loads |
| 4 | Click toggle status button | Status flips successfully |
| 5 | Log in as user without `tenant.topic-competency.update` permission | Mapping list loads (viewAny), but toggle button hidden or disabled |
| 6 | Directly POST to toggle-status route without permission | HTTP 403 Forbidden |

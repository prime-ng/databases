# slb_resource_matrix_TcList

## Module: Syllabus → Reports → Resource Matrix

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Reports |
| Feature | Resource Matrix |
| URL(s) | `/syllabus/report?tab=resource_matrix` (report.index) |
| Controller | `Modules\Syllabus\Http\Controllers\SyllabusController@report()` |
| Model(s) | `Modules\Syllabus\Models\SyllabusSchedule` |
| Permissions | `tenant.view-resource-matrix.viewAny` |
| Policy | `SyllabusReportPolicy::viewResourceMatrix()` |
| View Partial | `resources/views/report/partials/resource_matrix.blade.php` |
| Pagination | 10 per page, page name `matrix_page` |

---

## 2. Pre-conditions

- Required permissions: `tenant.view-resource-matrix.viewAny`
- Required seed data: At least one active `OrganizationAcademicSession`, multiple `SchoolClass`, `Subject`, `Lesson`, `Topic` records; `SyllabusSchedule` records with eager-loaded `topic.competencies` for resource count computation
- Test user must have the above permission (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Resource Matrix requires `SyllabusSchedule` records with related `Topic` and `Competency` data for `$resourceMeta` computation

---



---

## 3. Default Data Load

When the page loads via SyllabusController@report() (GET /syllabus/report), the following data is fetched:

| Tab | Data Loaded | Source | Filters | Pagination |
|-----|------------|--------|---------|------------|
| All | Shared dropdowns: classes, subjects, academicSessions | SchoolClass::where(is_active,1)->orderBy(ordinal), Subject::where(is_active,1)->orderBy(name), OrganizationAcademicSession::where(is_active,1)->orderBy(name,DESC) | is_active=1 | None |
| All | Dashboard Stats (total, released, overdue, progress %) | SyllabusSchedule::selectRaw(COUNT,SUM) with CASE | academic_session_id, class_id, subject_id | None (single agg row) |
| All | Coverage Bar Chart (subject-wise) | SyllabusSchedule::join(sch_subjects)->selectRaw(COUNT,SUM)->groupBy(subject) | Same scoped filters | None |
| All | Completion Trend (last 15 days) | SyllabusSchedule::where(is_active,1)->where(updated_at,>=,15 days ago)->groupBy(DATE) | Same + is_active=1 | None |
| All | Class-wise Completion | SyllabusSchedule::join(sch_classes)->selectRaw(COUNT,SUM)->groupBy(class) | Same scoped filters | None |
| All | Status Distribution (On Track / Overdue / Released) | Derived from stats aggregation (no extra query) | Same | None |
| Dashboard | Recent Activity (last 10 completed) | SyllabusSchedule::with(topic,lesson,class,subject)->where(is_active,1)->latest(updated_at)->limit(10) | Same + is_active=1 | None (limit 10) |
| Progress Tracker | Grouped progress data | SyllabusSchedule::selectRaw(COUNT,SUM,COALESCE)->with(class,subject)->groupBy(class,subject) | Same scoped filters | 10/page (progress_page) |
| Coverage Audit | Schedule audit with start dates | SyllabusSchedule::with(class,subject,lesson,topic)->whereNotNull(scheduled_start_date)->orderBy(scheduled_start_date) | Same + has start_date | 10/page (audit_page) |
| Resource Matrix | Schedule with topic competencies | SyllabusSchedule::with(class,subject,lesson,topic.competencies) | Same scoped filters | 10/page (matrix_page) |
| Planning Accuracy | Schedule with variance calculation | SyllabusSchedule::selectRaw(DATEDIFF)->where(is_active,1)->whereNotNull(scheduled_end_date)->with(class,subject,lesson,topic,assignedTeacher.user) | Same + is_active=1 + has end_date | 10/page (accuracy_page) |
| Planning Accuracy | Accuracy breakdown (full dataset) | SyllabusSchedule::selectRaw(SUM,CASE) for on_time/slightly_late/very_late | Same + is_active=1 + has end_date | None |
| Planning Accuracy | Teacher accuracy ranking (top 10) | SyllabusSchedule::where(is_active,1)->whereNotNull(assigned_teacher_id)->with(assignedTeacher.user)->get()->groupBy(assigned_teacher_id) | Same + has teacher | None (top 10) |
## 4. Test Data Strategy

- **Matrix data**: Seed 25+ `SyllabusSchedule` records across multiple classes and subjects with eager-loaded `class`, `subject`, `lesson`, `topic.competencies` relations
- **Resource meta**: For each topic, seed varying numbers of competencies to represent `ques` count:
  - Some topics with 0 competencies (no questions)
  - Some topics with 5-10 competencies
  - Some topics with 20+ competencies
- **Resource counts**: The `$resourceMeta` collection hardcodes `video`, `pdf`, `image` to 0 (no dedicated study_materials table); actual values may come from other sources
- **Pagination**: Seed at least 25 schedule records to test 10-per-page pagination
- **Filters**: Data spanning at least 2 classes and 3 subjects
- **Empty state**: A scope with zero schedule records
- **Pre-test cleanup**: Delete created records before/after tests to avoid collisions

---

## 5. Business Conditions

### 4.1 Database Schema — `slb_syllabus_schedule`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | academic_session_id | INT UNSIGNED | NOT NULL, FK → `sch_org_academic_sessions_jnt.id` |
| BC-DB-03 | class_id | INT UNSIGNED | NOT NULL, FK → `sch_classes.id` |
| BC-DB-04 | subject_id | INT UNSIGNED | NOT NULL, FK → `sch_subjects.id` |
| BC-DB-05 | lesson_id | INT UNSIGNED | NOT NULL, FK → `slb_lessons.id` |
| BC-DB-06 | topic_id | INT UNSIGNED | NOT NULL, FK → `slb_topics.id` |
| BC-DB-07 | scheduled_start_date | DATE | NULLABLE |
| BC-DB-08 | scheduled_end_date | DATE | NULLABLE |
| BC-DB-09 | is_active | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-10 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-11 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

### 4.1a Related Tables

| BC ID | Table | Key Columns | Purpose |
|-------|-------|-------------|---------|
| BC-DB-12 | slb_topics | id, lesson_id, name | Topic detail for matrix row |
| BC-DB-13 | slb_topic_competency | id, topic_id, competency_id | Join table for topic ↔ competency mapping |
| BC-DB-14 | slb_competencies | id, name, type_id | Competency data counted as `ques` resource |

### 4.2 Authorization (Policy Gates)

| BC ID | Permission | Policy Method | Behavior |
|-------|-----------|---------------|----------|
| BC-AUTH-01 | tenant.view-resource-matrix.viewAny | viewResourceMatrix() | Without → 403 Forbidden on `/report?tab=resource_matrix` |

### 4.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | `$matrixData` from `SyllabusSchedule` | Queried with `$applyFilters` closure, eager-loaded with `class`, `subject`, `lesson`, `topic.competencies` |
| BC-BIZ-02 | `$resourceMeta` collection | Keyed by `topic.id`, each entry has `video` (default 0), `pdf` (default 0), `image` (default 0), `ques` (count of topic's competencies) |
| BC-BIZ-03 | Paginated at 10 per page (`matrix_page`) | Results split into pages of 10 |
| BC-BIZ-04 | `$applyFilters` closure | Conditionally adds `WHERE` clauses for `academic_session_id`, `class_id`, `subject_id` from query params |
| BC-BIZ-05 | View partial rendering | View rendered from `resources/views/report/partials/resource_matrix.blade.php` receiving both `$matrixData` and `$resourceMeta` |
| BC-BIZ-06 | Resource count display | Each row shows video count, pdf count, image count, and question count for the associated topic |
| BC-BIZ-07 | Screen loads via SyllabusController@report() at GET /syllabus/report with report tab group | Navigating to GET /syllabus/report with appropriate permissions loads the Report tab group; this screen's data is fetched and displayed |

### 4.4 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | academic_session_id | sch_org_academic_sessions_jnt (id) | RESTRICT |
| BC-REF-02 | class_id | sch_classes (id) | CASCADE |
| BC-REF-03 | subject_id | sch_subjects (id) | CASCADE |
| BC-REF-04 | lesson_id | slb_lessons (id) | CASCADE |
| BC-REF-05 | topic_id | slb_topics (id) | CASCADE |
| BC-REF-06 | competency_id (topic_competency) | slb_competencies (id) | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Resource matrix page loads with all UI elements | Page loads at `/report?tab=resource_matrix` with filter bar, matrix table, and pagination | — | — | ⬜ |
| TC-P02 | Matrix table displays correct columns | Columns: Lesson, Topic, Video Count, PDF Count, Image Count, Question Count, Class, Subject | — | — | ⬜ |
| TC-P03 | Question count from topic competencies | `ques` count equals number of competencies linked to each topic via `slb_topic_competency` | — | — | ⬜ |
| TC-P04 | Resource meta correctly keyed by topic ID | Each row shows resource counts matching the correct topic (not misaligned) | — | — | ⬜ |
| TC-P05 | Filter by class scopes data | Selecting a class shows only matrix rows for that class | — | — | ⬜ |
| TC-P06 | Filter by class + subject scopes data | Combined filters scope to matching records | — | — | ⬜ |
| TC-P07 | Pagination works — first page | First 10 matrix rows displayed; page 1 active | — | — | ⬜ |
| TC-P08 | Pagination works — subsequent pages | Clicking page 2 shows next 10 rows | — | — | ⬜ |
| TC-P09 | Eager-loaded relations display correct names | Each row shows human-readable Lesson, Topic, Class, Subject names | — | — | ⬜ |
| TC-P10 | Resource count accuracy with zero-competency topics | Topics with no competencies show `ques` count as 0 | — | — | ⬜ |
| TC-P11 | Resource count accuracy with multiple competencies | Topics with 5 competencies show `ques` count as 5 | — | — | ⬜ |
| TC-P12 | Video/PDF/Image columns display values (default 0 or actual) | Each row shows video, pdf, image counts — 0 if no dedicated study_materials table | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Permission 403 — No viewResourceMatrix permission | User without `tenant.view-resource-matrix.viewAny` gets 403 Forbidden | — | — | ⬜ |
| TC-N02 | Guest access redirect | Unauthenticated user redirected to login | — | — | ⬜ |
| TC-N03 | Empty state — no schedule records for filters | Table shows "No resources found for the selected filters." | — | — | ⬜ |
| TC-N04 | Empty state — no topic-competency mappings | Matrix rows visible but all `ques` counts are 0; appropriate notice shown | — | — | ⬜ |
| TC-N05 | Malformed page parameter | `?matrix_page=-1` or `?matrix_page=abc` defaults to page 1 | — | — | ⬜ |
| TC-N06 | Page exceeding total pages | `?matrix_page=999` shows last page or empty gracefully | — | — | ⬜ |
| TC-N07 | Invalid filter parameters | `?class_id=99999` returns empty table; no 500 error | — | — | ⬜ |
| TC-N08 | Topic with null/empty relation data | Missing topic relation shows graceful fallback instead of error | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Adding competencies to a topic updates ques count | Adding competencies via `slb_topic_competency` and refreshing matrix shows updated count | — | — | ⬜ |
| TC-D02 | A | Removing competencies from a topic reduces ques count | Deleting topic-competency links refreshes to lower count | — | — | ⬜ |
| TC-D03 | B | Creating new schedule record adds row to matrix | New syllabus schedule with topic relation appears in matrix after refresh | — | — | ⬜ |
| TC-D04 | C | Large dataset (100+ records) pagination accuracy | All 100+ matrix rows paginated correctly; no missing/duplicate data | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based tab visibility via viewAny | Report tabs are conditionally rendered via @can('tenant.view-resource-matrix.viewAny') and nav-tab permission attribute; users without viewAny permission cannot see this tab | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | `syllabus.report` key → `'syllabus/report'` defined in `config/breadcrumb.php`; breadcrumb visible and links correctly to parent screen | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Relationship expressions in Blade use isset($var->relation) / optional($var?->relation) / null-safe operator; no undefined index/property errors when relation is null | — | — | ◌ |


---



## 7. Detailed Test Steps

#### TC-CR05: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open report partial blade for this screen | View file found in report/partials/
| 2 | Scan for relationship access patterns (e.g. $record->relation->field) | All such expressions use isset() or optional() or ?-> null-safe operator
| 3 | Scan for foreach loops over relationships | Loop target checked with isset() or !empty() before iterating
| 4 | Load report with records that have missing relations | No 500 errors; null values displayed gracefully (dash or empty string)


#### TC-CR01: Blade @can Directives — Permission-based Tab Visibility via viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect report/index.blade.php | Tab is conditionally rendered via @can('tenant.view-resource-matrix.viewAny')
| 2 | Check nav-tab component permission attribute | Tab's permission parameter matches 'tenant.view-resource-matrix.viewAny'
| 3 | Log in as user with viewAny permission | Resource Matrix tab visible in Report section |
| 4 | Log in as user without viewAny permission | Resource Matrix tab hidden; user cannot access this report |

#### TC-CR02: Breadcrumb Config — Route Registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File contains routing configuration for the syllabus module |
| 2 | Verify the 'syllabus.report' key exists | Config has 'syllabus.report' => 'syllabus/report' entry
| 3 | Verify its value points to the correct parent screen URL | Value 'syllabus/report' correctly references Report tab view
| 4 | Load the screen via the Report tab tab | Breadcrumb trail shows correct hierarchy and highlights current screen |
| 5 | Click the breadcrumb parent link | Navigates correctly to Report tab page without errors |
### 6.1 Positive TC Steps

#### TC-P01: Resource Matrix Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Expand "Syllabus" from left sidebar | Menu options appear |
| 3 | Click "Reports" and select "Resource Matrix" tab | Page loads at `/report?tab=resource_matrix` |
| 4 | Check the filter bar | Dropdowns for Academic Session, Class, Subject present |
| 5 | Check the matrix table | Table with resource count columns visible |
| 6 | Check pagination links | If 10+ records, pagination links present |

---

#### TC-P02: Matrix Table Displays Correct Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to resource matrix | Page loads |
| 2 | Check table header columns | Columns: Lesson, Topic, Video Count, PDF Count, Image Count, Question Count, Class, Subject |
| 3 | Verify column order matches specification | Lesson → Topic → Video Count → PDF Count → Image Count → Question Count → Class → Subject |

---

#### TC-P03: Question Count From Topic Competencies

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Topic A — linked to 3 competencies (C1, C2, C3) | 3 mappings |
| 2 | Seed: Topic B — linked to 0 competencies | No mappings |
| 3 | Seed: Topic C — linked to 8 competencies | 8 mappings |
| 4 | Navigate to resource matrix | Topic A row shows Ques = 3 |
| 5 | Verify Topic B row shows Ques = 0 | No competencies |
| 6 | Verify Topic C row shows Ques = 8 | All competencies counted |

---

#### TC-P04: Resource Meta Correctly Keyed By Topic ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Topic X (id=101) with 4 competencies, Topic Y (id=102) with 2 competencies | Two topics |
| 2 | Navigate to resource matrix | Topic X row shows Ques = 4 |
| 3 | Verify Topic Y row shows Ques = 2 | Counts not swapped |
| 4 | Verify each row's counts match the correct topic | No misalignment |

---

#### TC-P05: Filter By Class Scopes Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class A (10 matrix rows), Class B (8 rows), Class C (5 rows) | 3 classes |
| 2 | Select Class A from filter | 10 rows displayed |
| 3 | Verify no Class B or C rows visible | Scoped correctly |
| 4 | Clear filter, select Class B | 8 rows displayed |

---

#### TC-P06: Filter By Class + Subject Scopes Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class A / Math (5 rows), Class A / Science (3 rows), Class B / Math (4 rows) | Combinations |
| 2 | Select Class A + Math | 5 rows |
| 3 | Select Class A + Science | 3 rows |
| 4 | Select Class B + Math | 4 rows |

---

#### TC-P07: Pagination Works (First Page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 25 matrix rows | 25 records |
| 2 | Navigate to resource matrix — page 1 | 10 rows displayed |
| 3 | Verify page 1 pagination link active | Page 1 highlighted |
| 4 | Verify "Next" link visible | Pagination controls present |

---

#### TC-P08: Pagination Works (Subsequent Pages)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | With 25 rows, click page 2 | Rows 11-20 displayed |
| 2 | Click page 3 | Rows 21-25 displayed |
| 3 | Click "Previous" | Returns to page 2 |
| 4 | Click page 1 | Returns to first 10 rows |

---

#### TC-P09: Eager-Loaded Relations Display Correct Names

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: row linked to Lesson "Algebra Basics", Topic "Linear Equations", Class "Class 9", Subject "Mathematics" | Full relations |
| 2 | Navigate to resource matrix | Row shows "Algebra Basics" (Lesson), "Linear Equations" (Topic), "Class 9" (Class), "Mathematics" (Subject) |

---

#### TC-P10: Resource Count Accuracy With Zero-Competency Topics

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: topic with no entries in `slb_topic_competency` | Zero competencies |
| 2 | Navigate to resource matrix | Row shows Ques = 0 |
| 3 | Verify no error or missing data | Displays zero cleanly |

---

#### TC-P11: Resource Count Accuracy With Multiple Competencies

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: topic linked to 5 competencies via `slb_topic_competency` | 5 mappings |
| 2 | Navigate to resource matrix | Row shows Ques = 5 |
| 3 | Add 3 more competencies to the same topic | Now 8 mappings |
| 4 | Refresh page | Ques = 8 |

---

#### TC-P12: Video/PDF/Image Columns Display Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to resource matrix | Each row has Video, PDF, Image columns |
| 2 | Verify columns are not empty | Values displayed (0 or actual count) |
| 3 | Verify no 500 errors from missing study_materials table | Graceful empty/default values |

---

### 6.2 Negative TC Steps

#### TC-N01: Permission 403 — No viewResourceMatrix Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.view-resource-matrix.viewAny` | Dashboard loads (other tabs may be visible) |
| 2 | Navigate to `/report?tab=resource_matrix` | 403 Forbidden or tab hidden from UI |
| 3 | Verify resource matrix tab not displayed | Tab excluded from user's visible tabs |

---

#### TC-N02: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout completely | — |
| 2 | Navigate to `/report?tab=resource_matrix` | Redirected to login page |

---

#### TC-N03: Empty State — No Schedule Records For Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a class/subject with zero schedule records | No matrix data |
| 2 | Navigate to resource matrix | Table shows: "No resources found for the selected filters. The syllabus may not have been set up for this class and subject yet." |
| 3 | Verify no data rows visible | Empty table |

---

#### TC-N04: Empty State — No Topic-Competency Mappings

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed schedule records but no `slb_topic_competency` entries | Topics exist but no mappings |
| 2 | Navigate to resource matrix | Matrix rows visible (schedule records exist) |
| 3 | Verify all Ques counts = 0 | No competencies mapped |
| 4 | Verify a notice/message about missing mappings | "Question Bank Count is unavailable" or similar notice |

---

#### TC-N05: Malformed Page Parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `?tab=resource_matrix&matrix_page=-1` | Shows first page |
| 2 | Navigate to `?tab=resource_matrix&matrix_page=abc` | Shows first page |
| 3 | No 500 errors | Graceful handling |

---

#### TC-N06: Page Exceeding Total Pages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | With 3 pages of data, navigate to `?matrix_page=999` | Shows last page or empty result set gracefully |
| 2 | No 500 errors | Handled by paginator |

---

#### TC-N07: Invalid Filter Parameters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `?tab=resource_matrix&class_id=99999` | Page loads without 500 error |
| 2 | Table shows empty state | "No resources found" message |
| 3 | Navigate to `?tab=resource_matrix&subject_id=99999` | Same graceful handling |

---

#### TC-N08: Topic With Null/Empty Relation Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: schedule record with topic_id pointing to non-existent topic (orphaned) or deleted topic | Broken relation |
| 2 | Navigate to resource matrix | Row shows graceful fallback (topic name = "Deleted" or "-") |
| 3 | No 500 errors or exception pages | Graceful handling |

---

### 6.3 Dependency TC Steps

#### TC-D01: Adding Competencies Updates Ques Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to resource matrix — note Ques count for Topic X | Ques = 3 |
| 2 | Add 2 new topic-competency mappings for Topic X | Now has 5 |
| 3 | Refresh resource matrix | Ques = 5 |
| 4 | Add 3 more | Ques = 8 |

---

#### TC-D02: Removing Competencies Reduces Ques Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to resource matrix — note Ques count for Topic X | Ques = 8 |
| 2 | Delete 3 topic-competency mappings for Topic X | Now has 5 |
| 3 | Refresh resource matrix | Ques = 5 |
| 4 | Delete remaining 5 | Ques = 0 |

---

#### TC-D03: Creating New Schedule Record Adds Row to Matrix

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to resource matrix — note current row count | Count = X |
| 2 | Create new schedule record with valid topic having 4 competencies | Record created |
| 3 | Refresh resource matrix | Count = X + 1 |
| 4 | Verify new row shows correct lesson, topic, class, subject names | Data matches seed |
| 5 | Verify Ques = 4 for the new row | Competency count correct |

---

#### TC-D04: Large Dataset (100+ Records) Pagination Accuracy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 100+ matrix records across multiple classes and subjects | Large dataset |
| 2 | Navigate to resource matrix | Page 1 shows first 10 rows |
| 3 | Navigate to page 5 | Rows 41-50, correctly ordered |
| 4 | Navigate to last page | Remaining rows displayed |
| 5 | Verify no records skipped or duplicated | Complete dataset covered correctly |

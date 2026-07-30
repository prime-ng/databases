# slb_periods_allocation_TcList

## Module: Syllabus → Planning → Periods Allocation

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Planning |
| Feature | Periods Allocation |
| URL(s) | `GET /syllabus/planning?tab=periods_allocation` (display only) |
| Controller | No dedicated controller — loaded via `SyllabusController@planning()` lines 352-374 |
| Model(s) | `Modules\Syllabus\Models\PeriodsAllocation` (table: `slb_syllabus_periods_allocation`) |
| Validation | None (read-only tab) |
| Policy | None — inherits from planning page gate (`tenant.lesson.viewAny`) |
| Permissions | `tenant.lesson.viewAny` (implicit, no specific permission) |
| Pagination | 25 records per page using `pa_page` parameter |
| Data Source | **Timetable module** (manual entry) or auto-generated from Lesson Scheduling saves |
| Read-Only | Yes — no create/update/delete UI elements |

---

## 2. Pre-conditions

- Required permissions: `tenant.lesson.viewAny` (view)
- Required seed data: `PeriodsAllocation` records in `slb_syllabus_periods_allocation` table
- At least one `OrganizationAcademicSession`, `SchoolClass` with section, `Subject`, active `SubjectStudyFormat`
- Tenant context via `tenancy()->initialize()`
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

When the page loads via SyllabusController@planning() (GET /syllabus/planning) with tab=periods_allocation, default filters: class_section_id=1, subject_id=5, academic_session_id=7.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: dropdowns | planning() | Same as LessonSequencing (classes, sections, classSections, subjects, academicSessions) | --- | None |
| Periods Allocation Grid | planning() | PeriodsAllocation::with(academicSession,class,section,subject,subjectStudyFormat) | class_id, section_id, subject_id, academic_session_id, date_from, date_to | 25/page (pa_page) |

> **Data Source:** Records originate from the **Timetable module** (manual entry) or are auto-generated from Lesson Scheduling saves. The `subjectStudyFormat` is a reference column to the Timetable module's study format config — not the data source. For data creation logic (sync/auto-generation), refer to the Lesson Scheduling TC list and code.

---

## 4. Test Data Strategy

- Create `PeriodsAllocation` records directly in DB for display/filter/pagination tests
- Use consistent date ranges (e.g., Jul 1-31, 2026)
- Pre-test cleanup: Delete created allocation records after tests
- Pagination test: Create 26+ records to test the 25-per-page limit

---

## 5. Business Conditions

### 5.1 Database Schema — `slb_syllabus_periods_allocation`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | academic_session_id | INT UNSIGNED | NOT NULL, FK → `sch_org_academic_sessions_jnt.id`, ON DELETE CASCADE |
| BC-DB-03 | date | DATE | NOT NULL |
| BC-DB-04 | is_school_open_for_study | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-05 | class_id | INT UNSIGNED | NOT NULL, FK → `sch_classes.id`, ON DELETE CASCADE |
| BC-DB-06 | section_id | INT UNSIGNED | NOT NULL, FK → `sch_sections.id`, ON DELETE CASCADE |
| BC-DB-07 | subject_id | INT UNSIGNED | NOT NULL, FK → `sch_subjects.id`, ON DELETE CASCADE |
| BC-DB-08 | subject_study_format_id | INT UNSIGNED | FK → `subject_study_format.id` |
| BC-DB-09 | tot_periods_in_day | INT | NOT NULL |
| BC-DB-10 | tot_periods_in_week | INT | NOT NULL |
| BC-DB-11 | data_created_by | ENUM('MANUAL','AUTO') | NOT NULL |
| BC-DB-12 | notes | VARCHAR(500) | DEFAULT NULL |
| BC-DB-13 | created_by | INT UNSIGNED | FK → users |
| BC-DB-14 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-15 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-16 | UNIQUE KEY | (academic_session_id, date, class_id, section_id, subject_id, subject_study_format_id) | Prevents duplicates |

### 5.2 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | tenant.lesson.viewAny | Without → 403 on planning page |
| BC-AUTH-02 | Guest access | Redirect to /login |

No specific permission for this tab — inherits from parent planning index.

### 5.3 Business Logic (Display Only)

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Tab loads with filters | Table shows PeriodsAllocation records filtered by class/section/subject/date range |
| BC-BIZ-02 | No filters selected | Empty table with prompt to select filters |
| BC-BIZ-03 | Pagination | 25 records per page using `pa_page` parameter |
| BC-BIZ-04 | Manual records show data_created_by='MANUAL' | Badge shows "Manual" |
| BC-BIZ-05 | Auto-generated records show data_created_by='AUTO' | Badge shows "Auto" |
| BC-BIZ-06 | School open status | `is_school_open_for_study` displayed as "Open" or "Closed" badge |
| BC-BIZ-07 | Order by date DESC | Latest dates appear first |
| BC-BIZ-08 | Read-only — no CRUD buttons | Table has no edit/delete actions |
| BC-BIZ-09 | Screen loads via SyllabusController@planning() at GET /syllabus/planning with tab=periods_allocation | Navigating to GET /syllabus/planning with tab=periods_allocation loads this screen's grid data with correct filters applied |

---

## 6. Test Case List

### 6.1 Display & Filter Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Tab loads with filter controls | Class/Section, Subject, date_from, date_to, Apply button visible | — | — | ⬜ |
| TC-P02 | Display records with filters applied | Select class/section/subject/date range → matching records shown | — | — | ⬜ |
| TC-P03 | All columns displayed | date, class, section, subject, study format, periods per day, periods per week, school open, source, notes | — | — | ⬜ |
| TC-P04 | Pagination — 25 per page | 26+ records → 25 on page 1, remaining on page 2 (pa_page=2) | — | — | ⬜ |
| TC-P05 | Source badge — "Manual" | data_created_by='MANUAL' → "Manual" badge | — | — | ⬜ |
| TC-P06 | Source badge — "Auto" | data_created_by='AUTO' → "Auto" badge | — | — | ⬜ |
| TC-P07 | School Open badge — Open | is_school_open_for_study=1 → green "Open" | — | — | ⬜ |
| TC-P08 | School Open badge — Closed | is_school_open_for_study=0 → red "Closed" | — | — | ⬜ |
| TC-P09 | Date range filter | date_from=Jul 1, date_to=Jul 10 → only Jul 1-10 records shown | — | — | ⬜ |
| TC-P10 | Subject filter | Select Subject X → only Subject X records | — | — | ⬜ |
| TC-P11 | Class/Section filter | Select Class A/Sec 1 → only that classroom records | — | — | ⬜ |
| TC-P12 | Order by date DESC | Records shown latest-first | — | — | ⬜ |
| TC-P13 | Notes column displays content | Free-text note visible in table | — | — | ⬜ |
| TC-P14 | No records — empty message | No matching records → empty table with message | — | — | ⬜ |
| TC-P15 | Read-only — no action buttons | No Add/Edit/Delete buttons | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No filters — empty prompt | Load without filters → "Select a class/section and subject" | — | — | ⬜ |
| TC-N02 | No matching records | Apply filters with no data → "No records" | — | — | ⬜ |
| TC-N03 | No permission | User without tenant.lesson.viewAny → 403 | — | — | ⬜ |
| TC-N04 | Guest access | Not logged in → redirect to /login | — | — | ⬜ |
| TC-N05 | No edit/delete routes | Access /planning/periods-allocation/{id}/edit → 404 | — | — | ⬜ |
| TC-N06 | Invalid date range | date_from > date_to → handled gracefully | — | — | ⬜ |

### 6.3 Dependency Test Cases (DDL)

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | G | 6-Column Composite Unique — uq_sylperiods_allocation | Duplicate (academic_session_id, date, class_id, section_id, subject_id, subject_study_format_id) → integrity constraint violation | — | — | ⬜ |
| TC-D02 | H | ENUM Field — data_created_by | data_created_by='INVALID' → DB rejects; 'MANUAL'/'AUTO' accepted | — | — | ⬜ |
| TC-D03 | I | FK SET NULL — created_by Teacher Deletion | Delete teacher referenced in created_by → created_by=NULL | — | — | ⬜ |
| TC-D04 | J | Multi-FK Cascade Chain — 5 Foreign Keys | Delete parent (session/class/section/subject/format) → CASCADE deletes allocation | — | — | ⬜ |
| TC-D05 | K | Date Range Integrity — date within session | date outside academic session range → validation rejects | — | — | ⬜ |
| TC-D06 | L | Default Filter Values Pre-selected on Page Load | On page load, class_section_id=1, subject_id=5, academic_session_id=7 are pre-selected | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Tab visibility via viewAny permission | Tab is wrapped in @can('tenant.lesson.viewAny'); user without permission does not see the Periods Allocation tab | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | `syllabus.planning` key → `'syllabus/planning'` defined in `config/breadcrumb.php`; breadcrumb visible and links correctly to parent screen | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Relationship expressions in Blade use isset($var->relation) / optional($var?->relation) / null-safe operator; no undefined index/property errors when relation is null | — | — | ◌ |


---



## 7. Detailed Test Steps



#### TC-CR05: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open index.blade.php for this screen | View file found in lesson-management/partials/
| 2 | Scan for relationship access patterns (e.g. $record->relation->field) | All such expressions use isset() or optional() or ?-> null-safe operator
| 3 | Scan for foreach loops over relationships | Loop target checked with isset() or !empty() before iterating
| 4 | Create a record with null relationship | View renders without undefined index/property error
| 5 | Load index page with records that have missing relations | No 500 errors; null values displayed gracefully (dash or empty string)


#### TC-CR01: Blade @can Directives — Tab Visibility via viewAny Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open planning/index.blade.php | Tab is wrapped in @can('tenant.lesson.viewAny') |
| 2 | Log in as user with tenant.lesson.viewAny permission | Periods Allocation tab is visible and clickable |
| 3 | Log in as user without tenant.lesson.viewAny | Periods Allocation tab is hidden |
| 4 | Verify no per-action @can directives exist | Periods Allocation view is read-only, no CRUD buttons present |

#### TC-CR02: Breadcrumb Config — Route Registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File contains routing configuration for the syllabus module |
| 2 | Verify the 'syllabus.planning' key exists | Config has 'syllabus.planning' => 'syllabus/planning' entry
| 3 | Verify its value points to the correct parent screen URL | Value 'syllabus/planning' correctly references Planning tab view
| 4 | Load the screen via the Planning tab tab | Breadcrumb trail shows correct hierarchy and highlights current screen |
| 5 | Click the breadcrumb parent link | Navigates correctly to Planning tab page without errors |
### 7.1 Display & Filter TC Steps

#### TC-P01: Tab Loads With Filter Controls

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login, navigate to Planning → Periods Allocation | Tab loads at /planning?tab=periods_allocation |
| 2 | Check filter area | Class/Section, Subject, date_from, date_to, Apply button |

---

#### TC-P02: Display Records With Filters Applied

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class+section, subject, date range | Filters applied |
| 2 | Click "Apply" | Table loads matching PeriodsAllocation records |
| 3 | Verify records match filters | All shown records match class, subject, date range |

---

#### TC-P03: All Columns Displayed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load allocation table | Headers visible |
| 2 | Verify columns | Date, Class, Section, Subject, Study Format, Periods Per Day, Periods Per Week, School Open, Source, Notes |

---

#### TC-P04: Pagination — 25 Per Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 26+ records for same filter scope | Records exist |
| 2 | Apply filters | 25 records on page 1 |
| 3 | Check pagination | Page 2 link with pa_page=2 |
| 4 | Click page 2 | Remaining records shown |

---

#### TC-P05 to TC-P08: Badge Display Tests

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-P05 | Create record with data_created_by='MANUAL' | Load tab with filters | "Manual" badge |
| TC-P06 | Create record with data_created_by='AUTO' | Load tab with filters | "Auto" badge |
| TC-P07 | Create record with is_school_open_for_study=1 | Load tab | Green "Open" |
| TC-P08 | Create record with is_school_open_for_study=0 | Load tab | Red "Closed" |

---

#### TC-P09: Date Range Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create records: Jul 1, Jul 5, Jul 10, Jul 20 | 4 records |
| 2 | Set date_from=Jul 1, date_to=Jul 10, Apply | Jul 1, Jul 5, Jul 10 shown |
| 3 | Verify Jul 20 excluded | Not in results |

---

#### TC-P10: Subject Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create records for Subject X and Subject Y | Both exist |
| 2 | Select Subject X → Apply | Only Subject X records |
| 3 | Select Subject Y → Apply | Only Subject Y records |

---

#### TC-P11: Class/Section Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create records for Class A/Sec 1 and Class B/Sec 2 | Both exist |
| 2 | Select Class A/Sec 1 → Apply | Only Class A/Sec 1 records |

---

#### TC-P12: Order By Date DESC

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create records: Jul 1, Jul 5, Jul 10, Jul 20 | Records created |
| 2 | Apply filters | Order: Jul 20, Jul 10, Jul 5, Jul 1 |

---

#### TC-P13: Notes Column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with notes="Adjusted for holiday" | Notes saved |
| 2 | Load tab | Notes column shows "Adjusted for holiday" |

---

#### TC-P14: No Records — Empty Message

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filters matching no records | Empty table |
| 2 | Verify message | "No records found" or similar |

---

#### TC-P15: No Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load allocation table | No Add/Edit/Delete buttons |
| 2 | Check for action column | No action column exists |

---

### 7.2 Negative TC Steps

#### TC-N01 to TC-N06

| TC ID | Step | Expected |
|-------|------|----------|
| TC-N01 | Navigate to tab without filters | Prompt: "Select a class and subject to view period allocation" |
| TC-N02 | Apply filters with no matching data | "No records" |
| TC-N03 | Login as user without tenant.lesson.viewAny → navigate to planning | 403 |
| TC-N04 | Logout → navigate to /planning | Redirect to /login |
| TC-N05 | Try /planning/periods-allocation/{id}/edit or DELETE | 404 |
| TC-N06 | Set date_from > date_to and Apply | Handled gracefully (empty or ignored) |

---

### 7.3 Dependency TC Steps

#### TC-D01: 6-Column Composite Unique

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert record with unique (academic_session_id, date, class_id, section_id, subject_id, subject_study_format_id) | Success |
| 2 | Insert another with same 6-column values | DB integrity constraint violation |
| 3 | SELECT COUNT for that combination | 1 record |

---

#### TC-D02: ENUM Field — data_created_by

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert with data_created_by='INVALID' | Rejected |
| 2 | Insert with data_created_by='' | Rejected |
| 3 | Insert with data_created_by='MANUAL' | Accepted |
| 4 | Insert with data_created_by='AUTO' | Accepted |

---

#### TC-D03: FK SET NULL — created_by

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation with created_by=teacher_id | Record saved |
| 2 | Delete the teacher | Teacher deleted |
| 3 | Query allocation created_by | NULL |

---

#### TC-D04: Multi-FK Cascade Chain

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation with all FK parents | Records exist |
| 2 | Delete academic session | CASCADE deletes allocation |
| 3 | Repeat for class_id, section_id, subject_id | Each CASCADE deletes |

---

#### TC-D05: Date Within Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Session: Jul 1-31, 2026 | Known range |
| 2 | Create allocation with date=Aug 15 (outside) | Rejected |
| 3 | Create allocation with date=Jul 15 (inside) | Accepted |

---

#### TC-D06: Default Filter Values Pre-selected on Page Load

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `SyllabusController.php` | File loads |
| 2 | Locate the `planning()` method (lines 139-147) | Method found |
| 3 | Check default filter assignment for class_section_id | Default value = 1 |
| 4 | Check default filter assignment for subject_id | Default value = 5 |
| 5 | Check default filter assignment for academic_session_id | Default value = 7 |
| 6 | Navigate to Planning → Periods Allocation tab | Page loads at /planning?tab=periods_allocation |
| 7 | Verify filter dropdowns show pre-selected values | class_section_id=1, subject_id=5, academic_session_id=7 are selected by default |
| 8 | Verify table loads with data matching default filters | Records matching class_section_id=1, subject_id=5, academic_session_id=7 are displayed |

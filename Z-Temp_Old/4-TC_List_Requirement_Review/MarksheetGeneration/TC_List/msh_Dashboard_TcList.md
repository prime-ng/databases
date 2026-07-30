# Marksheet Generation Dashboard — TC_List

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | Dashboard (`msh_dashboard`) — Read-only executive overview screen |
| **Controller** | `Modules\MarksheetGeneration\Http\Controllers\MarksheetGenerationController@dashboard()` — 1 method |
| **Model** | None directly; aggregates counts from 9 models: MarksheetType, ConfigTemplate, MarksheetSchedule, StudentResult, ScheduleClass, SubjectPracticalConfig, StudentSubjectResult, StudentIaMark, StudentCoscholasticResult |
| **Form Request** | None — read-only screen, no forms |
| **Policy** | No explicit Policy class; uses direct `Gate::authorize('tenant.msh-dashboard.view')` |
| **Route Prefix** | `marksheet-generation.dashboard` |
| **Blade Views** | `dashboard.blade.php` — single page with 3 tabs (Overview, Recent Schedules, Recent Results) |
| **DB Tables** | 9 tables: `msh_marksheet_types`, `msh_config_templates`, `msh_marksheet_schedules`, `msh_student_results`, `msh_student_subject_results`, `msh_student_ia_marks`, `msh_student_coscholastic_results`, `msh_schedule_class_jnt`, `msh_subject_practical_configs` |
| **Primary Screen** | Marksheet Generation → Dashboard (executive summary with 12 KPI tiles + recent activity lists) |

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in with `tenant.msh-dashboard.view` permission |
| PC-02 | Database must have all 9 dependency tables with correct schema |
| PC-03 | `msh_marksheet_types` table exists with `is_active`, `name`, `code` columns |
| PC-04 | `msh_config_templates` table exists with `is_active`, `name`, `code` columns |
| PC-05 | `msh_marksheet_schedules` table exists with `is_active`, `config_template_id` FK, `status`, `created_at` |
| PC-06 | `msh_student_results` table exists with `student_id` FK, `class_section_id` FK, `created_at` |
| PC-07 | `msh_schedule_class_jnt` table exists with schedule and class FKs |
| PC-08 | `msh_subject_practical_configs` table exists |
| PC-09 | `msh_student_subject_results` table exists |
| PC-10 | `msh_student_ia_marks` table exists |
| PC-11 | `msh_student_coscholastic_results` table exists |
| PC-12 | `ConfigTemplate` model has `id` PK and `name`, `code`, `is_active` fillable |
| PC-13 | `Student` model has `first_name`, `last_name`, `admission_no` |
| PC-14 | `ClassSection` model has `class()` and `section()` relationships |
| PC-15 | Dashboard route `marksheet-generation.dashboard` registered in `routes/web.php` |
| PC-16 | Three nav tabs defined in blade: Overview, Recent Schedules, Recent Results |
| PC-17 | Browser supports JavaScript for Bootstrap tab switching |
| PC-18 | `<x-backend.layouts.app>` layout available and extends properly |
| PC-19 | Controller imports all 9 model classes with correct `use` statements |
| PC-20 | Dashboard view exists at `marksheetgeneration::dashboard` in module views |
| PC-21 | `x-backend.tab.nav-tab` component available for tab rendering |
| PC-22 | `x-backend.components.breadcrum` component available for breadcrumb |
| PC-23 | `config/breadcrumb.php` has dashboard entry for centralized breadcrumb |
| PC-24 | `config/permissionslist.php` has `msh-dashboard` group with `view` permission |
| PC-25 | `Gate::before` super admin bypass does not interfere with dashboard checks |
| PC-26 | All 9 models extend `Illuminate\Database\Eloquent\Model` |
| PC-27 | `activityLog()` helper not used (read-only screen) |
| PC-28 | No `->paginate()` used — only `->take(5)->get()` for recent lists |
| PC-29 | KPI layout uses `col-xl-3 col-md-6` responsive grid |
| PC-30 | No `Cache::remember()` — all queries hit DB on every page load |

## 3. Default Data Load

| # | Data Load Rule | Source | Data Type |
|---|----------------|--------|-----------|
| DL-01 | `MarksheetType::count()` — total marksheet types | Controller:41 | int |
| DL-02 | `MarksheetType::where('is_active', 1)->count()` — active types | Controller:42 | int |
| DL-03 | `ConfigTemplate::count()` — total config templates | Controller:43 | int |
| DL-04 | `ConfigTemplate::where('is_active', 1)->count()` — active templates | Controller:44 | int |
| DL-05 | `MarksheetSchedule::count()` — total schedules | Controller:45 | int |
| DL-06 | `MarksheetSchedule::where('is_active', 1)->count()` — active schedules | Controller:46 | int |
| DL-07 | `StudentResult::count()` — total student results | Controller:47 | int |
| DL-08 | `ScheduleClass::count()` — total schedule-class junction records | Controller:48 | int |
| DL-09 | `SubjectPracticalConfig::count()` — total subject practical configs | Controller:49 | int |
| DL-10 | `StudentSubjectResult::count()` — total student subject results | Controller:50 | int |
| DL-11 | `StudentIaMark::count()` — total student IA marks | Controller:51 | int |
| DL-12 | `StudentCoscholasticResult::count()` — total coscholastic results | Controller:52 | int |
| DL-13 | `MarksheetSchedule::with('configTemplate')->latest()->take(5)->get()` — recent 5 schedules | Controller:55-58 | Collection |
| DL-14 | `StudentResult::with(['student','classSection.class','classSection.section'])->latest()->take(5)->get()` — recent 5 results | Controller:60-63 | Collection |
| DL-15 | All 12 KPI stats passed as `$stats` associative array | Controller:40-53 | array |
| DL-16 | View receives `compact('stats','recentSchedules','recentResults')` | Controller:65 | 3 variables |
| DL-17 | `$stats` keys match blade variable expectations | Controller:41-52 | array keys |
| DL-18 | No paginators — only Collection objects for recent lists | Controller:57-58,62-63 | Collection |
| DL-19 | Default tab: `request('tab', 'overview')` in blade | Dashboard view | string |
| DL-20 | No academic session filter applied to any COUNT query | Controller:41-52 | raw count |

## 4. Test Data Strategy

| # | Data Strategy | Details | Purpose |
|---|---------------|---------|---------|
| TD-01 | **Zero Configuration** | All 9 tables empty — KPIs = 0, empty states | Initial state |
| TD-02 | **Single Record Each** | 1 record per model — all counts = 1 | Minimum data |
| TD-03 | **Mixed Active/Inactive** | 3 types (2 active, 1 inactive); 3 templates (2 a, 1 i); 3 schedules (2 a, 1 i) | Active vs total |
| TD-04 | **5+ Recent Schedules** | 7 schedules, staggered dates — only 5 newest shown | take(5) limit test |
| TD-05 | **5+ Recent Results** | 7 results, staggered dates — only 5 newest shown | take(5) limit test |
| TD-06 | **Schedule with ConfigTemplate** | 5 schedules, each linked to different template | Relation display |
| TD-07 | **Results with Student** | 5 results linked to different students | Student relation |
| TD-08 | **Results with ClassSection** | 5 results with different class + section | Class-section display |
| TD-09 | **All 12 KPIs Non-Zero** | All 9 tables populated — all counts positive | Full data state |
| TD-10 | **Large Dataset** | 10,000+ StudentResult records | Performance test |
| TD-11 | **Null configTemplate** | config_template_id = null — null-safe access | Null handling |
| TD-12 | **Orphaned student_id** | Non-existent student FK (violates referential integrity but may occur) | Graceful fallback |
| TD-13 | **Null classSection** | class_section_id = null — null-safe access | Null handling |
| TD-14 | **Soft-deleted schedules** | Schedules via onlyTrashed — still counted | Soft delete inclusion |
| TD-15 | **Soft-deleted results** | Results via onlyTrashed — still counted | Soft delete inclusion |
| TD-16 | **All schedules inactive** | is_active=0 for all — active count = 0 | Filter test |
| TD-17 | **Schedule with 100 classes** | ScheduleClass has 100 junction records | Large aggregation |
| TD-18 | **250 subject results** | 25 results × 10 subjects each | Sub-result counts |
| TD-19 | **500 IA marks** | 25 results × 5 IA types × 4 subjects | IA mark counts |
| TD-20 | **100 coscholastic results** | 25 results × 4 categories | Coscholastic counts |

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | `msh_marksheet_types.id` — BIGINT PK AUTO_INCREMENT | Unique ID per marksheet type | Schema |
| BC-DB-02 | `msh_marksheet_types.name` — VARCHAR(255), NOT NULL | Display name | Schema |
| BC-DB-03 | `msh_marksheet_types.code` — VARCHAR(50), UNIQUE | Short code | Schema |
| BC-DB-04 | `msh_marksheet_types.is_active` — TINYINT(1), DEFAULT 1 | Active flag | Schema |
| BC-DB-05 | `msh_marksheet_types.deleted_at` — TIMESTAMP, NULLABLE | Soft delete support | Schema |
| BC-DB-06 | `msh_marksheet_types.created_at` — TIMESTAMP | Record creation | Schema |
| BC-DB-07 | `msh_marksheet_types.updated_at` — TIMESTAMP | Record update | Schema |
| BC-DB-08 | `msh_config_templates.id` — BIGINT PK AUTO_INCREMENT | Unique ID per template | Schema |
| BC-DB-09 | `msh_config_templates.name` — VARCHAR(255), NOT NULL | Display name | Schema |
| BC-DB-10 | `msh_config_templates.code` — VARCHAR(50), UNIQUE | Short code | Schema |
| BC-DB-11 | `msh_config_templates.is_active` — TINYINT(1), DEFAULT 1 | Active flag | Schema |
| BC-DB-12 | `msh_config_templates.deleted_at` — TIMESTAMP, NULLABLE | Soft delete | Schema |
| BC-DB-13 | `msh_config_templates.created_at` — TIMESTAMP | Record creation | Schema |
| BC-DB-14 | `msh_marksheet_schedules.id` — BIGINT PK AUTO_INCREMENT | Unique ID per schedule | Schema |
| BC-DB-15 | `msh_marksheet_schedules.name` — VARCHAR(255), NOT NULL | Display name | Schema |
| BC-DB-16 | `msh_marksheet_schedules.code` — VARCHAR(50), UNIQUE | Short code | Schema |
| BC-DB-17 | `msh_marksheet_schedules.config_template_id` — BIGINT FK → msh_config_templates.id | FK to template | Schema |
| BC-DB-18 | `msh_marksheet_schedules.status` — VARCHAR(50), DEFAULT 'draft' | Workflow status | Schema |
| BC-DB-19 | `msh_marksheet_schedules.is_active` — TINYINT(1), DEFAULT 1 | Active flag | Schema |
| BC-DB-20 | `msh_marksheet_schedules.deleted_at` — TIMESTAMP, NULLABLE | Soft delete | Schema |
| BC-DB-21 | `msh_marksheet_schedules.created_at` — TIMESTAMP | Order by field | Schema |
| BC-DB-22 | `msh_marksheet_schedules.updated_at` — TIMESTAMP | Record update | Schema |
| BC-DB-23 | `msh_student_results.id` — BIGINT PK AUTO_INCREMENT | Unique ID | Schema |
| BC-DB-24 | `msh_student_results.student_id` — BIGINT FK → std_students.id | FK to student | Schema |
| BC-DB-25 | `msh_student_results.class_section_id` — BIGINT FK → sch_class_section_jnt.id | FK to class-section | Schema |
| BC-DB-26 | `msh_student_results.schedule_id` — BIGINT FK → msh_marksheet_schedules.id | FK to schedule | Schema |
| BC-DB-27 | `msh_student_results.grand_total` — DECIMAL(10,2), NULLABLE | Sum of marks | Schema |
| BC-DB-28 | `msh_student_results.overall_percentage` — DECIMAL(5,2), NULLABLE | Percentage | Schema |
| BC-DB-29 | `msh_student_results.overall_grade` — VARCHAR(10), NULLABLE | Grade | Schema |
| BC-DB-30 | `msh_student_results.deleted_at` — TIMESTAMP, NULLABLE | Soft delete | Schema |
| BC-DB-31 | `msh_student_results.created_at` — TIMESTAMP | Order by field | Schema |
| BC-DB-32 | `msh_student_results.updated_at` — TIMESTAMP | Record update | Schema |
| BC-DB-33 | `msh_student_subject_results.id` — BIGINT PK | Subject result | Schema |
| BC-DB-34 | `msh_student_subject_results.student_result_id` — BIGINT FK | FK to student result | Schema |
| BC-DB-35 | `msh_student_subject_results.subject_id` — BIGINT FK | FK to subject | Schema |
| BC-DB-36 | `msh_student_subject_results.marks_obtained` — DECIMAL(8,2) | Marks scored | Schema |
| BC-DB-37 | `msh_student_subject_results.max_marks` — DECIMAL(8,2) | Max marks | Schema |
| BC-DB-38 | `msh_student_subject_results.is_active` — TINYINT(1) | Active flag | Schema |
| BC-DB-39 | `msh_student_subject_results.deleted_at` — TIMESTAMP | Soft delete | Schema |
| BC-DB-40 | `msh_student_ia_marks.id` — BIGINT PK | IA mark | Schema |
| BC-DB-41 | `msh_student_ia_marks.student_result_id` — BIGINT FK | FK to student result | Schema |
| BC-DB-42 | `msh_student_ia_marks.subject_id` — BIGINT FK | FK to subject | Schema |
| BC-DB-43 | `msh_student_ia_marks.ia_type_id` — BIGINT FK | FK to IA type | Schema |
| BC-DB-44 | `msh_student_ia_marks.marks_obtained` — DECIMAL(8,2) | IA marks scored | Schema |
| BC-DB-45 | `msh_student_ia_marks.max_marks` — DECIMAL(8,2) | IA max marks | Schema |
| BC-DB-46 | `msh_student_ia_marks.is_active` — TINYINT(1) | Active flag | Schema |
| BC-DB-47 | `msh_student_ia_marks.deleted_at` — TIMESTAMP | Soft delete | Schema |
| BC-DB-48 | `msh_student_coscholastic_results.id` — BIGINT PK | Coscholastic | Schema |
| BC-DB-49 | `msh_student_coscholastic_results.student_result_id` — BIGINT FK | FK to student result | Schema |
| BC-DB-50 | `msh_student_coscholastic_results.coscholastic_category_id` — BIGINT FK | FK to category | Schema |
| BC-DB-51 | `msh_student_coscholastic_results.grade` — VARCHAR(10) | Grade | Schema |
| BC-DB-52 | `msh_student_coscholastic_results.grade_points` — DECIMAL(4,2) | Grade points | Schema |
| BC-DB-53 | `msh_student_coscholastic_results.is_active` — TINYINT(1) | Active flag | Schema |
| BC-DB-54 | `msh_student_coscholastic_results.deleted_at` — TIMESTAMP | Soft delete | Schema |
| BC-DB-55 | `msh_schedule_class_jnt.id` — BIGINT PK | Junction PK | Schema |
| BC-DB-56 | `msh_schedule_class_jnt.schedule_id` — BIGINT FK | FK to schedule | Schema |
| BC-DB-57 | `msh_schedule_class_jnt.class_id` — BIGINT FK | FK to class | Schema |
| BC-DB-58 | `msh_subject_practical_configs.id` — BIGINT PK | Practical config PK | Schema |
| BC-DB-59 | `msh_subject_practical_configs.subject_id` — BIGINT FK | FK to subject | Schema |
| BC-DB-60 | `msh_subject_practical_configs.is_active` — TINYINT(1) | Active flag | Schema |
| BC-DB-61 | `msh_subject_practical_configs.deleted_at` — TIMESTAMP | Soft delete | Schema |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | Dashboard is read-only — no forms, no POST routes | N/A | Requirement |
| BC-VAL-02 | No user input in dashboard route | No request parameters processed | Controller analysis |
| BC-VAL-03 | Tab selection via query param only | `request('tab', 'overview')` | Dashboard view |
| BC-VAL-04 | No database write operations | Read-only SELECT queries | Controller analysis |
| BC-VAL-05 | No file uploads | No enctype needed | Requirement |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Method | Line | Source |
|----|-----------|-----------------|--------|------|--------|
| BC-AUTH-01 | `tenant.msh-dashboard.view` | `Gate::authorize('tenant.msh-dashboard.view')` | `dashboard()` | 38 | Controller analysis |
| BC-AUTH-02 | Single gate for entire page | No per-tab authorization | `dashboard()` | 38 | Controller analysis |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | 12 KPI counts computed in real-time — no caching | Every page load executes 12 separate COUNT queries | Controller:40-53 |
| BC-BIZ-02 | Recent schedules limited to 5 records | `->take(5)` applied after ordering | Controller:57 |
| BC-BIZ-03 | Recent results limited to 5 records | `->take(5)` applied after ordering | Controller:62 |
| BC-BIZ-04 | Schedules sorted by `created_at` DESC | `->latest()` shortcut | Controller:56 |
| BC-BIZ-05 | Results sorted by `created_at` DESC | `->latest()` shortcut | Controller:61 |
| BC-BIZ-06 | `configTemplate` eager loaded for schedules | `->with('configTemplate')` prevents N+1 | Controller:55 |
| BC-BIZ-07 | student + classSection.class.section eager loaded | Nested eager load prevents N+1 | Controller:60 |
| BC-BIZ-08 | Zero data state renders gracefully | All counts = 0, empty states for tables | Requirement |
| BC-BIZ-09 | Three tabs: Overview, Recent Schedules, Recent Results | Blade nav-tab with tab-pane divs | Dashboard view |
| BC-BIZ-10 | No data entry on dashboard | Read-only, no POST routes, no forms | Requirement |
| BC-BIZ-11 | Schedules show config_template name via relation | `$schedule->configTemplate?->name` (null-safe) | Blade view |
| BC-BIZ-12 | Results show student name + admission via relation | `$result->student?->first_name` etc. | Blade view |
| BC-BIZ-13 | Results show class-section via nested relation | `$result->classSection?->class?->name` | Blade view |
| BC-BIZ-14 | All 12 COUNT queries independent | No JOINs, no subqueries | Controller:41-52 |
| BC-BIZ-15 | `->count()` returns integer, not Collection | Standard Eloquent count | Controller:41-52 |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | MarksheetSchedule → ConfigTemplate | `belongsTo(configTemplate)` | MarksheetSchedule model |
| BC-REL-02 | StudentResult → Student | `belongsTo(student)` | StudentResult model |
| BC-REL-03 | StudentResult → ClassSection | `belongsTo(classSection)` | StudentResult model |
| BC-REL-04 | ClassSection → Class | `belongsTo(class)` | ClassSection model |
| BC-REL-05 | ClassSection → Section | `belongsTo(section)` | ClassSection model |
| BC-REL-06 | MarksheetSchedule → StudentResult | `hasMany(results)` | MarksheetSchedule model |
| BC-REL-07 | StudentResult → StudentSubjectResult | `hasMany(subjectResults)` | StudentResult model |
| BC-REL-08 | StudentResult → StudentIaMark | `hasMany(iaMarks)` | StudentResult model |
| BC-REL-09 | StudentResult → StudentCoscholasticResult | `hasMany(coscholasticResults)` | StudentResult model |
| BC-REL-10 | MarksheetSchedule → ScheduleClass | `hasMany(scheduleClasses)` | MarksheetSchedule model |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | Dashboard uses `<x-backend.layouts.app>` layout | Full backend layout with sidebar, navbar | Dashboard view |
| BC-REF-02 | Three nav tabs: Overview, Recent Schedules, Recent Results | Tab nav via x-backend.tab.nav-tab, default = Overview | Dashboard view |
| BC-REF-03 | KPI tiles: 12 stat tiles with count + label | Bold number + muted label in card | CRUD Rules Sec 10 |
| BC-REF-04 | Recent schedules: name, template, status, created_at | 4-column table inside tab-pane | Dashboard view |
| BC-REF-05 | Recent results: student name, admission, class-section, %, grade | 5-column table inside tab-pane | Dashboard view |
| BC-REF-06 | Single gate for entire page | `tenant.msh-dashboard.view` | Controller:38 |
| BC-REF-07 | No flash messages | Read-only, no session flash | Analysis |
| BC-REF-08 | Overview tab default on first load | `request('tab', 'overview')` | Dashboard view |
| BC-REF-09 | No pagination — fixed `->take(5)` query | No ->paginate, no ->links() | Controller:57,62 |
| BC-REF-10 | Empty state with guidance | "No records found" in empty tables | Requirement |
| BC-REF-11 | Real-time data from live DB — no caching | Direct DB queries every load | Controller:40-53 |
| BC-REF-12 | 12 KPIs from 9 distinct tables | 9 models used, 12 count queries | Controller:41-52 |
| BC-REF-13 | Breadcrumb with empty `:links="[]"` | `<x-backend.components.breadcrum :links="[]" />` | Dashboard view |
| BC-REF-14 | KPI tiles use responsive grid `col-xl-3 col-md-6` | 4 columns on large, 2 on medium | CRUD Rules Sec 10a |
| BC-REF-15 | "View All" badge link in schedule tab | Link to scheduling hub | Dashboard view |
| BC-REF-16 | "View All" badge link in results tab | Link to results hub | Dashboard view |
| BC-REF-17 | Overview tab shows pending/alert items | Count of draft schedules | Dashboard view |
| BC-REF-18 | KPI icons with colored background circles | `bg-*-subtle rounded-circle` CSS | CRUD Rules Sec 10a |
| BC-REF-19 | `fs-2 fw-bold text-dark` for KPI values | Large bold numbers | CRUD Rules Sec 10a |
| BC-REF-20 | `text-muted small` for KPI labels | Small muted labels | CRUD Rules Sec 10a |

### BC-BIZ-DEEP: Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-01 | `MarksheetType::count()` — raw COUNT(*) | Total records in table regardless of is_active |
| BC-BIZ-DEEP-02 | `MarksheetType::where('is_active', 1)->count()` | Only active records counted |
| BC-BIZ-DEEP-03 | `ConfigTemplate::count()` — raw COUNT(*) | All config templates |
| BC-BIZ-DEEP-04 | `ConfigTemplate::where('is_active', 1)->count()` | Only active templates |
| BC-BIZ-DEEP-05 | `MarksheetSchedule::count()` — raw COUNT(*) | All schedules including soft-deleted |
| BC-BIZ-DEEP-06 | `MarksheetSchedule::where('is_active', 1)->count()` | Only active schedules |
| BC-BIZ-DEEP-07 | `StudentResult::count()` — no is_active filter | All results including soft-deleted |
| BC-BIZ-DEEP-08 | `ScheduleClass::count()` — all junction records | All class-schedule assignments |
| BC-BIZ-DEEP-09 | `SubjectPracticalConfig::count()` — all configs | All subject practical configs |
| BC-BIZ-DEEP-10 | `StudentSubjectResult::count()` | All subject results |
| BC-BIZ-DEEP-11 | `StudentIaMark::count()` | All IA marks |
| BC-BIZ-DEEP-12 | `StudentCoscholasticResult::count()` | All coscholastic results |
| BC-BIZ-DEEP-13 | `MarksheetSchedule::with('configTemplate')` eager loads via LEFT JOIN | Each schedule has ->configTemplate attribute |
| BC-BIZ-DEEP-14 | Eager-loaded template fields accessible via null-safe | `$schedule->configTemplate?->name` |
| BC-BIZ-DEEP-15 | `->latest()` = `->orderBy('created_at', 'desc')` | Newest records first |
| BC-BIZ-DEEP-16 | `->take(5)` = `LIMIT 5` in SQL | Maximum of 5 records |
| BC-BIZ-DEEP-17 | 3-level nested eager load: student + classSection.class + classSection.section | Single query with multiple JOINs |
| BC-BIZ-DEEP-18 | Results ordered by `created_at` DESC via `->latest()` | Recent results first |
| BC-BIZ-DEEP-19 | Results limited to 5 via `->take(5)` | Max 5 results displayed |
| BC-BIZ-DEEP-20 | All 12 stats computed sequentially in same method | No queue, no background processing |
| BC-BIZ-DEEP-21 | Stats array keys match blade expectations | `$stats['total_marksheet_types']`, `$stats['active_marksheet_types']`, etc. |
| BC-BIZ-DEEP-22 | 12 COUNT queries are fully independent | No JOINs between the 9 tables |
| BC-BIZ-DEEP-23 | `StudentResult::count()` includes soft-deleted records | No `whereNull('deleted_at')` |
| BC-BIZ-DEEP-24 | `ScheduleClass` count = total junction records | Every schedule-class pairing counted |
| BC-BIZ-DEEP-25 | `SubjectPracticalConfig` count = all rows | No is_active filter on count |
| BC-BIZ-DEEP-26 | Schedules: `->latest()->take(5)->get()` in fluent chain | Method chaining |
| BC-BIZ-DEEP-27 | Results: `->latest()->take(5)->get()` in fluent chain | Method chaining |
| BC-BIZ-DEEP-28 | Recent lists are Eloquent Collection, not Paginator | No ->links() available |
| BC-BIZ-DEEP-29 | View receives exactly 3 variables from compact() | `$stats`, `$recentSchedules`, `$recentResults` |
| BC-BIZ-DEEP-30 | `$stats` array has exactly 12 keys | All 12 KPI keys present |
| BC-BIZ-DEEP-31 | No DB transaction wrapping 12 queries | Each query is auto-committed |
| BC-BIZ-DEEP-32 | Only essential relations eager loaded | 3 relationships total (configTemplate, student, classSection) |
| BC-BIZ-DEEP-33 | Gate::authorize runs BEFORE any DB queries | Line 38 executes before lines 41-52 |
| BC-BIZ-DEEP-34 | No custom 403 error page | Standard Laravel `AuthorizationException` → 403 |
| BC-BIZ-DEEP-35 | View namespace: `marksheetgeneration::dashboard` | Module view namespace |
| BC-BIZ-DEEP-36 | Dashboard is module entry point | First page after navigating to Marksheet Generation |
| BC-BIZ-DEEP-37 | COUNT includes ALL records including soft-deleted | No `->whereNull('deleted_at')` |
| BC-BIZ-DEEP-38 | No `->distinct()` on any COUNT | Simple COUNT(*) for all |
| BC-BIZ-DEEP-39 | Eager loading prevents N+1 for schedules | 1 extra query instead of 6 |
| BC-BIZ-DEEP-40 | Nested eager loading prevents N+1 for results | 1 extra query instead of 16 |
| BC-BIZ-DEEP-41 | `classSection.class` loads class name via belongsTo | `->class->name` |
| BC-BIZ-DEEP-42 | `classSection.section` loads section name via belongsTo | `->section->name` |
| BC-BIZ-DEEP-43 | student relation provides full name + admission_no | `->student->first_name . ' ' . ->student->last_name` |
| BC-BIZ-DEEP-44 | Breadcrumb uses empty `:links="[]"` | All breadcrumb config centralized |
| BC-BIZ-DEEP-45 | Tab state preserved via `?tab=` query parameter | `request('tab', 'overview')` |
| BC-BIZ-DEEP-46 | KPI styled per CRUD Rules Section 10 | Borderless cards, colored icons |
| BC-BIZ-DEEP-47 | No AJAX partial loading | Full page reload on tab switch |
| BC-BIZ-DEEP-48 | 12 COUNT queries per page load | Performance concern for large datasets |
| BC-BIZ-DEEP-49 | No academic session filter applied | Counts across all sessions |
| BC-BIZ-DEEP-50 | No active-student filter | All students including inactive/graduated |
| BC-BIZ-DEEP-51 | Same stats for all users with dashboard.view permission | No role-based filtering |
| BC-BIZ-DEEP-52 | ScheduleClass count counts junction records | Not unique schedules |
| BC-BIZ-DEEP-53 | SubjectPracticalConfig count counts all rows | Each practical = 1 |
| BC-BIZ-DEEP-54 | "View All" badge in schedules tab → scheduling hub | Router link |
| BC-BIZ-DEEP-55 | "View All" badge in results tab → results hub | Router link |
| BC-BIZ-DEEP-56 | Overview tab shows pending schedule count | Draft schedules alert |
| BC-BIZ-DEEP-57 | No explicit tenant_id filter | Multi-tenant via DB isolation |
| BC-BIZ-DEEP-58 | No withTrashed/onlyTrashed scope on counts | All records counted |
| BC-BIZ-DEEP-59 | All models extend `Illuminate\Database\Eloquent\Model` | Standard ORM |
| BC-BIZ-DEEP-60 | `->get()` returns Eloquent\Collection | Not lazy collection |
| BC-BIZ-DEEP-61 | MarksheetType count is independent query | No relation joins |
| BC-BIZ-DEEP-62 | ConfigTemplate count is independent | Simple SELECT COUNT(*) |
| BC-BIZ-DEEP-63 | Schedule count includes all status values | draft, published, completed, etc. |
| BC-BIZ-DEEP-64 | Result count includes all status values | draft, computed, published, withheld |
| BC-BIZ-DEEP-65 | Subject result count is independent table | Separate `msh_student_subject_results` |
| BC-BIZ-DEEP-66 | IA mark count is independent table | Separate `msh_student_ia_marks` |
| BC-BIZ-DEEP-67 | Coscholastic count is independent table | Separate `msh_student_coscholastic_results` |
| BC-BIZ-DEEP-68 | Null-safe `$schedule->configTemplate?->name` in blade | No error if config_template_id is null |
| BC-BIZ-DEEP-69 | Null-safe `$result->student?->first_name` in blade | Graceful fallback for missing student |
| BC-BIZ-DEEP-70 | `->count()` returns scalar integer | Not Collection |
| BC-BIZ-DEEP-71 | 3 tabs not individually gated | All users with dashboard.view see all 3 tabs |
| BC-BIZ-DEEP-72 | No `->filter()`/`->map()` on stats | Raw integers passed directly |
| BC-BIZ-DEEP-73 | `compact()` creates matching variable names | `$stats` accessible as variable in view |
| BC-BIZ-DEEP-74 | No route-model-binding in dashboard | Simple GET route |
| BC-BIZ-DEEP-75 | No `Cache::remember()` | Fully dynamic queries |
| BC-BIZ-DEEP-76 | Eloquent Collection has useful methods | ->count(), ->first(), etc. |
| BC-BIZ-DEEP-77 | `->latest()` is Eloquent shortcut for `orderBy('created_at', 'desc')` | Convenience method |
| BC-BIZ-DEEP-78 | No `->limit()` on sub-result counts | Full table scan |
| BC-BIZ-DEEP-79 | COUNT(*) is lightweight DB operation | No data retrieval |
| BC-BIZ-DEEP-80 | SubjectPracticalConfig counts rows, not unique subjects | Multiple practicals per subject counted |

### CODE-TRACE: Line-by-Line Method Trace

#### CODE-TRACE-01: `dashboard()` — MarksheetGenerationController Lines 36-66

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 38 | `Gate::authorize('tenant.msh-dashboard.view')` | Authorization gate — checks if user has permission |
| 02 | 41 | `'total_marksheet_types' => MarksheetType::count()` | COUNT(*) from msh_marksheet_types |
| 03 | 42 | `'active_marksheet_types' => MarksheetType::where('is_active', 1)->count()` | COUNT WHERE is_active=1 |
| 04 | 43 | `'total_config_templates' => ConfigTemplate::count()` | COUNT(*) from msh_config_templates |
| 05 | 44 | `'active_config_templates' => ConfigTemplate::where('is_active', 1)->count()` | COUNT WHERE is_active=1 |
| 06 | 45 | `'total_schedules' => MarksheetSchedule::count()` | COUNT(*) from msh_marksheet_schedules |
| 07 | 46 | `'active_schedules' => MarksheetSchedule::where('is_active', 1)->count()` | COUNT WHERE is_active=1 |
| 08 | 47 | `'total_results' => StudentResult::count()` | COUNT(*) from msh_student_results |
| 09 | 48 | `'total_schedule_classes' => ScheduleClass::count()` | COUNT(*) from msh_schedule_class_jnt |
| 10 | 49 | `'total_subject_practical' => SubjectPracticalConfig::count()` | COUNT(*) from msh_subject_practical_configs |
| 11 | 50 | `'total_student_subject_results' => StudentSubjectResult::count()` | COUNT(*) from msh_student_subject_results |
| 12 | 51 | `'total_student_ia_marks' => StudentIaMark::count()` | COUNT(*) from msh_student_ia_marks |
| 13 | 52 | `'total_coscholastic_results' => StudentCoscholasticResult::count()` | COUNT(*) from msh_student_coscholastic_results |
| 14 | 55 | `MarksheetSchedule::with('configTemplate')` | Query builder with eager load config |
| 15 | 56 | `->latest()` | ORDER BY created_at DESC |
| 16 | 57 | `->take(5)` | LIMIT 5 |
| 17 | 58 | `->get()` | Execute query → Collection |
| 18 | 60 | `StudentResult::with(['student', 'classSection.class', 'classSection.section'])` | Query builder with 3-level nested eager load |
| 19 | 61 | `->latest()` | ORDER BY created_at DESC |
| 20 | 62 | `->take(5)` | LIMIT 5 |
| 21 | 63 | `->get()` | Execute query → Collection |
| 22 | 65 | `return view('marksheetgeneration::dashboard', compact('stats', 'recentSchedules', 'recentResults'))` | Return view with 3 variables |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | View dashboard with all data | 12 KPIs non-zero, 5 schedules, 5 results | Full render, all sections visible |
| TC-P-02 | View dashboard with zero data | All 9 tables empty | KPIs = 0, empty states |
| TC-P-03 | Total vs active counts difference | 3 types: 2 active, 1 inactive | total=3, active=2 for all |
| TC-P-04 | Recent schedules limited to 5 | 7 schedules exist | Only 5 newest shown |
| TC-P-05 | Recent results limited to 5 | 7 results exist | Only 5 newest shown |
| TC-P-06 | configTemplate relation loads correctly | Schedule → Template via FK | Template name visible |
| TC-P-07 | Student relation loads correctly | Result → Student | Student name + admission visible |
| TC-P-08 | classSection.class relation loads | Result → ClassSection → Class | Class name visible |
| TC-P-09 | classSection.section relation loads | Result → ClassSection → Section | Section name visible |
| TC-P-10 | Switch between all 3 tabs | Click each tab | Correct content panel shown |
| TC-P-11 | Overview tab default on first load | Navigate without ?tab= | Overview active |
| TC-P-12 | Schedule class KPI correctly aggregated | 3 schedules × 5 classes | total_schedule_classes = 15 |
| TC-P-13 | Large dataset | 10,000+ student results | Loads within acceptable time |
| TC-P-14 | Subject practical config count | 8 subjects with practicals | total_subject_practical = 8 |
| TC-P-15 | All 3 sub-result counts | 25 subject results, 30 IA, 12 coscholastic | All three counts correct |
| TC-P-16 | Schedules ordered newest first | 5 schedules at different dates | Most recent first |
| TC-P-17 | Results ordered newest first | 5 results at different dates | Most recent first |
| TC-P-18 | View All links functional | Click badge | Navigates to hub |
| TC-P-19 | KPI tiles responsive layout | Resize to tablet/mobile | 4→2→1 columns |
| TC-P-20 | Breadcrumb renders at top | Page loads | Breadcrumb visible |
| TC-P-21 | Overview tab shows draft count | 2 draft schedules | Pending alert shown |
| TC-P-22 | Single record in every table | 1 record each | All counts = 1 |
| TC-P-23 | is_active=NULL excluded from active counts | NULL treated as falsy | Not counted |
| TC-P-24 | Soft-deleted records included in totals | 5 results, 2 soft-deleted | total_results = 5 |
| TC-P-25 | Null-safe template name | config_template_id = null | "-" or empty display |
| TC-P-26 | Null-safe student name | student_id = null | "-" or empty display |
| TC-P-27 | Null-safe class-section | class_section_id = null | "-" or empty display |
| TC-P-28 | All 12 stats = 0 when empty | Fresh installation | All zero |
| TC-P-29 | All 12 stats non-zero | Full data | All positive |
| TC-P-30 | 50 concurrent users | Load test | 600 COUNT queries total |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Access without permission | No dashboard.view permission | 403 Forbidden |
| TC-N-02 | Schedule limit strictly enforced | - | Never more than 5 |
| TC-N-03 | Null configTemplate handled | config_template_id = null | Graceful null display |
| TC-N-04 | Null student relation handled | student_id = null | Graceful fallback |
| TC-N-05 | Null classSection handled | class_section_id = null | Graceful fallback |
| TC-N-06 | DB connection failure | Database down | 500 error |
| TC-N-07 | Missing table (not migrated) | Schema missing | 500 error |
| TC-N-08 | POST request to dashboard | GET-only route | 405 Method Not Allowed |
| TC-N-09 | Invalid tab parameter | ?tab=invalid_tab | Falls back to Overview |
| TC-N-10 | 100k+ schedule classes | Large data | Loads within timeout |
| TC-N-11 | is_active = NULL in DB | NULL values | COUNT excludes NULL |
| TC-N-12 | Soft-deleted results included in count | 10 total, 2 trashed | count() = 10 (includes trashed) |
| TC-N-13 | Null student first_name | Partial student data | Fallback display |
| TC-N-14 | Null student last_name | Partial student data | Fallback display |
| TC-N-15 | Null admission_no | Partial student data | Fallback display |
| TC-N-16 | All schedules soft-deleted | Deleted flagged not used | Still counted and shown |
| TC-N-17 | Duplicate config_template_id | Same template for all schedules | OK, not a unique constraint |
| TC-N-18 | config_template_id = 0 | Invalid FK | Null relation (constraint violation) |
| TC-N-19 | 50 concurrent users | Load test | 600 COUNT queries |
| TC-N-20 | schedule.name = NULL | Null name in schedule | Display handles null |
| TC-N-21 | Empty schedule list | 0 schedules | "No records" shown |
| TC-N-22 | Empty result list | 0 results | "No records" shown |
| TC-N-23 | Missing view file | dashboard.blade.php deleted | 500 ViewException |
| TC-N-24 | Missing import in controller | Model class not imported | 500 ReflectionException |
| TC-N-25 | Session expired | User logged out | Redirect to login |
| TC-N-26 | Component missing (x-backend.tab.nav-tab) | Component not registered | 500 error |
| TC-N-27 | All 9 tables empty + 0 KPIs | Fresh install | Page loads, 0s displayed |
| TC-N-28 | Very long schedule name (255 chars) | Truncation | CSS handles overflow |
| TC-N-29 | 100+ marksheet types | Large table count | COUNT(*) is fast |
| TC-N-30 | Tab param XSS | ?tab=<script>alert(1)</script> | Auto-escaped |

### TC-D: Destructive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Drop msh_marksheet_types table | Schema removal | 500 error |
| TC-D-02 | Rename msh_config_templates table | Table missing | 500 error |
| TC-D-03 | Remove ConfigTemplate model file | Class not found | 500 error |
| TC-D-04 | Revoke dashboard.view permission mid-session | Permission removed | Next load = 403 |
| TC-D-05 | Delete all Student records | All student FKs orphaned | Null-safe display |
| TC-D-06 | Delete ConfigTemplate class | No with() relation | Null display |
| TC-D-07 | Truncate all 9 tables | All data gone | KPIs = 0 |
| TC-D-08 | Alter column type (created_at→int) | Schema mismatch | 500 error |

### TC-SQ: Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-01 | SQL injection via tab param | No DB interaction from param | No vector |
| TC-SQ-02 | Unauthorized URL access | No dashboard.view | 403 |
| TC-SQ-03 | Role escalation attempt | Low-privilege user | 403 |
| TC-SQ-04 | XSS in DB-stored names | `<script>alert(1)</script>` | Blade auto-escapes |
| TC-SQ-05 | CSRF | No POST routes | No vector |
| TC-SQ-06 | Parameter pollution | Multiple tab params | First/last wins |

### TC-INT: Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-01 | Dashboard reflects config | Create marksheet type → dashboard | total_marksheet_types + 1 |
| TC-INT-02 | Dashboard reflects computation | Compute schedule → dashboard | total_results increases |
| TC-INT-03 | Dashboard → Scheduling hub | Click "View All" in schedules tab | Scheduling hub page |
| TC-INT-04 | Dashboard → Results hub | Click "View All" in results tab | Results hub page |
| TC-INT-05 | Deactivate type → dashboard | MarksheetType toggle inactive | active count - 1, total unchanged |

### TC-CR: Cross-Reference Test Cases

| ID | Test Case | Reference |
|----|-----------|-----------|
| TC-CR-01 | Dashboard KPI matches list page count | MarksheetType index count |
| TC-CR-02 | Dashboard schedule count matches list | MarksheetSchedule list total |
| TC-CR-03 | Dashboard result count matches list | StudentResult list total |
| TC-CR-04 | Active type count matches list filter | MarksheetType list with active filter |
| TC-CR-05 | Recent schedules match DB query | SELECT * ORDER BY created_at DESC LIMIT 5 |
| TC-CR-06 | Recent results match DB query | SELECT * ORDER BY created_at DESC LIMIT 5 |
| TC-CR-07 | ConfigTemplate relation verified | CRUD Rules BC-REL |

---

## 7. Detailed Test Execution Procedures

### TC-P-01: View dashboard with all data populated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-dashboard.view` permission | Authenticated |
| 2 | Navigate to `/marksheet-generation/dashboard` | Page renders |
| 3 | Verify Gate::authorize passes at line 38 | Authorized |
| 4 | Verify 12 KPI stat tiles visible in Overview tab | All 12 displayed |
| 5 | Verify each tile shows correct count | Matches test data |
| 6 | Verify each tile has icon with colored background | Styled per Sec 10 |
| 7 | Switch to "Recent Schedules" tab | Tab activates |
| 8 | Verify 5 schedule entries | ConfigTemplate name visible |
| 9 | Verify schedule template name via eager load | `$schedule->configTemplate?->name` |
| 10 | Switch to "Recent Results" tab | Tab activates |
| 11 | Verify 5 result entries | Student name + admission visible |
| 12 | Verify student name has admission_no below | Pattern CRUD-UI Sec 7h |
| 13 | Verify class-section appears as "Class - Section" | Nested relation |
| 14 | Verify breadcrumb renders at top | Title + empty links |
| 15 | Verify no flash messages | Read-only screen |

### TC-P-02: View dashboard with zero data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure all 9 tables contain 0 rows | Empty database |
| 2 | Login with dashboard.view | Authenticated |
| 3 | Navigate to dashboard | Page loads |
| 4 | Verify all 12 KPIs = 0 | Zero counts displayed |
| 5 | Verify schedule tab shows "No schedules" | Empty state |
| 6 | Verify result tab shows "No results" | Empty state |
| 7 | Verify no PHP warnings or errors | Clean output |
| 8 | Verify Overview tab shows informative empty state | Placeholder content |

### TC-P-10: Switch between all 3 tabs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with dashboard.view | Authenticated |
| 2 | Navigate to dashboard | Overview tab active |
| 3 | Verify URL does not contain ?tab=query | Clean URL |
| 4 | Click "Recent Schedules" tab | Tab activates |
| 5 | Verify URL: ?tab=recent-schedules | Query param present |
| 6 | Verify content changes to schedule table | Schedule list |
| 7 | Click "Recent Results" tab | Tab activates |
| 8 | Verify URL: ?tab=recent-results | Query param present |
| 9 | Verify content changes to result table | Result list |
| 10 | Click "Overview" tab | Returns to overview |
| 11 | Verify all 12 KPIs still visible | Stats reload |

### TC-N-01: Access without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `dashboard.view` permission | Authenticated |
| 2 | Navigate to `/marksheet-generation/dashboard` | Gate::authorize throws |
| 3 | Verify 403 Forbidden response | Error page |
| 4 | Verify no DB COUNT queries executed | Gate stops before queries |
| 5 | Verify error log records the denial | Activity logged |

### TC-P-03: Total vs active count difference

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 MarksheetTypes: 2 active, 1 inactive | 3 records |
| 2 | Create 3 ConfigTemplates: 2 active, 1 inactive | 3 records |
| 3 | Create 3 MarksheetSchedules: 2 active, 1 inactive | 3 records |
| 4 | Navigate to dashboard | Page loads |
| 5 | Verify `total_marksheet_types` = 3, `active_marksheet_types` = 2 | Correct |
| 6 | Verify `total_config_templates` = 3, `active_config_templates` = 2 | Correct |
| 7 | Verify `total_schedules` = 3, `active_schedules` = 2 | Correct |

### TC-P-06: Schedule configTemplate relation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 5 ConfigTemplates with unique names | Templates exist |
| 2 | Create 5 MarksheetSchedules, each linked to different template | Valid FKs |
| 3 | Navigate to dashboard → Schedules tab | Loads |
| 4 | Verify template name displayed per schedule | Name appears |
| 5 | Verify N+1 prevented — only 1 extra query | DB query log |

### TC-D-01: Drop msh_marksheet_types table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Drop `msh_marksheet_types` table | Table removed |
| 2 | Navigate to dashboard | 500 error |
| 3 | Verify error: Base table not found | Specific error |
| 4 | Verify other COUNT queries not reached | Stops at line 41 |

### TC-INT-01: Dashboard reflects configuration changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Record current total_marksheet_types count | Baseline |
| 2 | Create new MarksheetType via config screen | Success |
| 3 | Navigate to dashboard | Count = baseline + 1 |
| 4 | Deactivate MarksheetType via toggle | Active count - 1 |
| 5 | Navigate to dashboard | Active count decreased |

### TC-P-04: Recent schedules limited to 5 — detailed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 7 MarksheetSchedules with different created_at dates | 7 exist |
| 2 | Note created_at values: most recent on 2026-07-22, then -21, -20, -19, -18, -17, -16 | 7 dates |
| 3 | Navigate to dashboard → Recent Schedules tab | Tab activates |
| 4 | Verify exactly 5 schedules shown | Max 5 |
| 5 | Verify the 5 shown are the latest 5 (22, 21, 20, 19, 18) | Newest 5 |
| 6 | Verify the 2 oldest (17, 16) are NOT shown | Hidden |
| 7 | Verify ->latest()->take(5)->get() applied | Correct SQL |

### TC-P-07: Student relation loads correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 5 Students with known first_name, last_name, admission_no | Students exist |
| 2 | Create 5 StudentResults linking to each student | Valid FKs |
| 3 | Navigate to dashboard → Recent Results tab | Tab activates |
| 4 | Verify each row shows student full name | first + last |
| 5 | Verify admission_no displayed below name (#ADM001) | Pattern Sec 7h |
| 6 | Verify N+1 prevented: only 2 queries (results + students) | Query log |

### TC-P-12: Schedule class KPI aggregated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 MarksheetSchedules | 3 schedules |
| 2 | Create 5 ScheduleClass entries (2+2+1) | 5 junction records |
| 3 | Navigate to dashboard | Page loads |
| 4 | Verify total_schedule_classes = 5 | Correct count |
| 5 | Verify total_schedules = 3 | Correct count |

### TC-P-16: Schedules ordered newest first

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 5 schedules with dates: 2026-07-20, 2026-07-18, 2026-07-22, 2026-07-19, 2026-07-21 | 5 records |
| 2 | Navigate to dashboard → Recent Schedules tab | Tab |
| 3 | Verify order: 22, 21, 20, 19, 18 | DESC |
| 4 | Verify ->latest() = ORDER BY created_at DESC | SQL confirms |

### TC-P-18: View All links functional

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to dashboard | Loads |
| 2 | Click "View All" badge in schedules tab | Route to scheduling hub |
| 3 | Verify navigation to scheduling page | Correct URL |
| 4 | Click browser back | Returns to dashboard |
| 5 | Click "View All" badge in results tab | Route to results hub |
| 6 | Verify navigation to results page | Correct URL |

### TC-N-20: Very long schedule name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create schedule with 255 character name | Max length |
| 2 | Navigate to dashboard → Recent Schedules | Tab |
| 3 | Verify name displayed (possibly truncated via CSS) | Overflow handled |
| 4 | Verify no layout breakage | Table intact |

### TC-D-01: Drop msh_marksheet_types table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Drop `msh_marksheet_types` table | Removed |
| 2 | Navigate to dashboard | 500 error |
| 3 | Verify error: "Base table or view not found" | Specific |
| 4 | Verify no subsequent COUNT queries executed | Stops at line 41 |

### TC-CR-01: Dashboard KPI matches list page count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to dashboard → note total_marksheet_types | KPI = X |
| 2 | Navigate to MarksheetType index page | List |
| 3 | Count total records manually | Count = X |
| 4 | Verify dashboard KPI matches manual count | Match |

### TC-CR-02: Dashboard schedule count matches list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to dashboard → note total_schedules | KPI = Y |
| 2 | Navigate to MarksheetSchedule index | List |
| 3 | Verify total matches | Y = Y |

---

### Additional BC-BIZ-DEEP: Deep Business Conditions — Dashboard & Hub

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-81 | `dashboard()` is a standalone method in `MarksheetGenerationController` | Separate from `results()`, `configuration()`, `scheduling()` |
| BC-BIZ-DEEP-82 | `dashboard()` uses `MarkSheetType` model (note capital S in MarkSheet) | `MarkSheetType::count()` — not `MarksheetType` |
| BC-BIZ-DEEP-83 | `configuration()` at line 68 gates `tenant.msh-configuration.view` | Separate permission from dashboard |
| BC-BIZ-DEEP-84 | `configuration()` loads 5 tabbed sections with unique paginator names | mt_page, ct_page, cg_page, eg_page, iact_page |
| BC-BIZ-DEEP-85 | `configuration()` applies filters via `applyFilters()` private helper | Search on name/code columns, status on is_active |
| BC-BIZ-DEEP-86 | `configuration()` paginates at 15 per page | Different from dashboard (no pagination) and results (10/15) |
| BC-BIZ-DEEP-87 | `components()` at line 95 gates `tenant.msh-components.view` | Separate permission |
| BC-BIZ-DEEP-88 | `components()` loads 4 tabbed sections | sc_page, ew_page, ia_page, cc_page — all paginate 15 |
| BC-BIZ-DEEP-89 | `scheduling()` at line 119 gates `tenant.msh-scheduling.view` | Separate permission |
| BC-BIZ-DEEP-90 | `scheduling()` loads 3 tabbed sections | pc_page, sch_page, scd_page — all paginate 15 |
| BC-BIZ-DEEP-91 | `results()` at line 147 gates `tenant.msh-results.view` | Separate permission from dashboard |
| BC-BIZ-DEEP-92 | `results()` loads 4 result tabs + Marksheet Generation tab | 5 tabs total in combined results page |
| BC-BIZ-DEEP-93 | `results()` uses `$makeResultQuery` closure for all 4 result tabs | Shared query builder with per-tab filter params |
| BC-BIZ-DEEP-94 | `results()` Marksheet Gen tab uses academic_session_id, class_id, section_id | Filtered student list for marksheet generation |
| BC-BIZ-DEEP-95 | `results()` mgStudentsQuery paginates at 20 | `paginate(20, ['*'], 'mg_page')` |
| BC-BIZ-DEEP-96 | `results()` mgStudentsQuery has 5-field search | student_qr_code, first_name, middle_name, last_name, admission_no |
| BC-BIZ-DEEP-97 | `applyFilters()` private helper at line 304 | Shared by configuration, components, scheduling |
| BC-BIZ-DEEP-98 | `applyFilters()` handles null search + empty searchable columns | Guard: `if ($search && !empty($searchableColumns))` |
| BC-BIZ-DEEP-99 | `applyFilters()` casts status to int | `$query->where('is_active', (int) $status)` |
| BC-BIZ-DEEP-100 | `applyFilters()` always appends `->latest()` | Latest ordering on all filtered queries |
| BC-BIZ-DEEP-101 | `configuration()` loads currentAcademicSession via OrgAcademicSession::current() | Custom scope for active session |
| BC-BIZ-DEEP-102 | `configuration()` loads LMS exam types filtered by is_active | `ExamType::where('is_active', 1)->orderBy('name')->get()` |
| BC-BIZ-DEEP-103 | `configuration()` loads school classes filtered by is_active | `SchoolClass::where('is_active', 1)->orderBy('name')->get()` |
| BC-BIZ-DEEP-104 | `scheduling()` loads schedule-class junction records | `ScheduleClass::with(['marksheetSchedule', 'classSection'])->latest()->paginate(15)` |
| BC-BIZ-DEEP-105 | `scheduling()` generates schedule mappings for student list | `$mgSchedules = ScheduleClass::with('marksheetSchedule')->get()->map(...)` |
| BC-BIZ-DEEP-106 | `results()` mgStudents loads currentAcademicSession relation | `Student::with(['currentAcademicSession.classSection.class', 'currentAcademicSession.classSection.section'])` |
| BC-BIZ-DEEP-107 | `results()` mgStudents filtered by academic_session_id via whereHas | Nested relationship filter |
| BC-BIZ-DEEP-108 | `results()` mgSchedules mapping returns object with id and name | Non-model stdClass mapping |
| BC-BIZ-DEEP-109 | `results()` returns 21+ variables in compact() | All sub-tab data + filter state + reference lists |
| BC-BIZ-DEEP-110 | `dashboard()` is the only method without any parameter | No $request dependency |
| BC-BIZ-DEEP-111 | No model for dashboard — uses count queries only | 12 independent COUNT(*) queries |
| BC-BIZ-DEEP-112 | `dashboard()` `configTemplate` relation on MarksheetSchedule | `MarksheetSchedule::with('configTemplate')` at line 55 |
| BC-BIZ-DEEP-113 | `dashboard()` `classSection.class` and `classSection.section` nested eager | 3-level deep eager load at line 60 |
| BC-BIZ-DEEP-114 | `dashboard()` `compact('stats', 'recentSchedules', 'recentResults')` | View receives 3 variables |
| BC-BIZ-DEEP-115 | `dashboard()` KPI array keys must match blade template expectations | 12 keys: total_/active_marksheet_types, config_templates, schedules, total_results, etc. |
| BC-BIZ-DEEP-116 | Dashboard overview tab shows pending schedule count | Draft schedules count |
| BC-BIZ-DEEP-117 | Dashboard tabs: Overview, Recent Schedules, Recent Results | Exactly 3 tabs |
| BC-BIZ-DEEP-118 | No academic session filter on dashboard KPIs | Counts across ALL sessions |
| BC-BIZ-DEEP-119 | No is_active filter on total counts (total_*) | Raw COUNT(*) including inactive |
| BC-BIZ-DEEP-120 | `take(5)` limits recent lists to exactly 5 records | SQL LIMIT 5 |

### CODE-TRACE: Additional Method Traces

#### CODE-TRACE-02: `configuration()` — Lines 68-93

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 70 | `Gate::authorize('tenant.msh-configuration.view')` | Auth gate |
| 02 | 72-73 | `$search = $request->input('search'); $status = $request->input('status')` | Read filter params |
| 03 | 74 | `$tab = $request->input('tab', 'marksheet-types')` | Read active tab (default: marksheet-types) |
| 04 | 76 | `$marksheetTypes = $this->applyFilters(MarkSheetType::query(), $tab==='marksheet-types' ? $search : null, ...)->paginate(15, ['*'], 'mt_page')` | Query with tab-scoped filters, paginator name 'mt_page' |
| 05 | 77 | `$configTemplates = $this->applyFilters(ConfigTemplate::query(), ...)->paginate(15, ['*'], 'ct_page')` | Config templates query |
| 06 | 78 | `$classGroups = $this->applyFilters(ClassGroup::with('items'), ...)->paginate(15, ['*'], 'cg_page')` | Class groups with items |
| 07 | 79 | `$examGroups = $this->applyFilters(ExamGroup::with(['academicSession','items']), ...)->paginate(15, ['*'], 'eg_page')` | Exam groups |
| 08 | 80 | `$iaComponentTypes = $this->applyFilters(IaComponentType::query(), ...)->paginate(15, ['*'], 'iact_page')` | IA component types |
| 09 | 82-86 | Reference lists: currentAcademicSession, examTypes, classes, marksheetTypesList, examGroupsList | Dropdown population |
| 10 | 88-92 | `return view('marksheetgeneration::pages.configuration', compact(...))` | Return view with 10 variables |

#### CODE-TRACE-03: `components()` — Lines 95-117

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 97 | `Gate::authorize('tenant.msh-components.view')` | Auth gate |
| 02 | 99-101 | `$search, $status, $tab = $request->input('tab', 'scholastic-components')` | Read filter params |
| 03 | 103 | `$scholasticComponents = ...->paginate(15, ['*'], 'sc_page')` | Scholastic with configTemplate, sourceComponent |
| 04 | 104 | `$examWeightages = ...->paginate(15, ['*'], 'ew_page')` | Exam weightages with configTemplate |
| 05 | 105 | `$iaComponents = ...->paginate(15, ['*'], 'ia_page')` | IA components with configTemplate |
| 06 | 106 | `$coscholasticComponents = ...->paginate(15, ['*'], 'cc_page')` | Coscholastic with configTemplate |
| 07 | 108-111 | Reference lists: configTemplates, sourceComponents, examTypes, iaComponentTypes | Dropdowns |
| 08 | 113-116 | `return view('marksheetgeneration::pages.components', compact(...))` | View with 8 variables |

#### CODE-TRACE-04: `scheduling()` — Lines 119-145

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 121 | `Gate::authorize('tenant.msh-scheduling.view')` | Auth gate |
| 02 | 123-125 | `$search, $status, $tab = $request->input('tab', 'practical-configs')` | Read filter params |
| 03 | 127 | `$practicalConfigs = ...->paginate(15, ['*'], 'pc_page')` | Practical configs with class, subject |
| 04 | 128 | `$schedules = ...->paginate(15, ['*'], 'sch_page')` | Schedules with configTemplate |
| 05 | 130-133 | Reference lists: configTemplates, classes, academicSessions, subjects | Dropdowns |
| 06 | 135-136 | `$scheduleClasses = ScheduleClass::with(...)->latest()->paginate(15, ['*'], 'scd_page')` | Junction records |
| 07 | 137-138 | Reference lists: marksheetSchedules, classSections | Dropdowns |
| 08 | 140-143 | `return view('marksheetgeneration::pages.scheduling', compact(...))` | View with 9 variables |

#### CODE-TRACE-05: `applyFilters()` — Lines 304-319

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 306 | `if ($search && !empty($searchableColumns))` | Guard: only search if columns provided |
| 02 | 307-309 | `$query->where(function($q) use ($search, $searchableColumns) { foreach($cols) { $q->orWhere($col, 'like', "%{$search}%") } })` | Multi-column LIKE search |
| 03 | 311-315 | `if ($status !== null && $status !== '') { $query->where('is_active', (int)$status) }` | Status filter with explicit int cast |
| 04 | 318 | `return $query->latest()` | Always order by created_at DESC |

### Additional Test Cases

#### TC-P: Additional Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-31 | configuration() loading with 5 tabs | Open configuration hub | All 5 tabs with paginated data |
| TC-P-32 | configuration() tab-scoped filters | Search in marksheet-types tab | Only marksheet-types filtered |
| TC-P-33 | configuration() unique paginator names | Page switching between tabs | No cross-tab pagination conflict |
| TC-P-34 | configuration() reference lists loaded | Open config hub | 5 reference lists for dropdowns |
| TC-P-35 | components() loading 4 tabs | Open components hub | Scholastic, Exam Weightages, IA, Coscholastic tabs |
| TC-P-36 | components() eager loads configTemplate + sourceComponent | View scholastic tab | Relation data visible |
| TC-P-37 | scheduling() loading 3 tabs | Open scheduling hub | Practical Configs, Schedules, Schedule Classes tabs |
| TC-P-38 | scheduling() loads ScheduleClass with marksheetSchedule relation | View schedule-class tab | Junction records with relation data |
| TC-P-39 | scheduling() loads academic sessions, classes, subjects | Dropdown population | All 4 reference lists |
| TC-P-40 | results() combined page with 5 tabs | Open results hub | Student, Subject, IA, Coscholastic, Marksheet Gen tabs |
| TC-P-41 | results() mgStudents filtered by academic session | Select session filter | Students filtered by session |
| TC-P-42 | results() mgStudents filtered by class | Select class filter | Students filtered by class |
| TC-P-43 | results() mgStudents filtered by section | Select section filter | Students filtered by section |
| TC-P-44 | results() mgStudents search by qr_code | Search student | Filtered by qr_code match |
| TC-P-45 | results() mgStudents search by first_name | Search student | Filtered by name match |
| TC-P-46 | results() mgStudents paginate 20 | 50 students | Page 1 = 20, Page 2 = 20, Page 3 = 10 |
| TC-P-47 | results() mgSchedules mapping loads | Student list | Schedule name shown per student |
| TC-P-48 | applyFilters() with null search and empty columns | No searchable columns | Returns query unfiltered |
| TC-P-49 | applyFilters() with status=0 filtering inactive | Filter inactive only | is_active=0 results |
| TC-P-50 | applyFilters() with status=1 filtering active | Filter active only | is_active=1 results |

#### TC-N: Additional Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-31 | Access configuration() without permission | No msh-configuration.view | 403 |
| TC-N-32 | Access components() without permission | No msh-components.view | 403 |
| TC-N-33 | Access scheduling() without permission | No msh-scheduling.view | 403 |
| TC-N-34 | Access results() without permission | No msh-results.view | 403 |
| TC-N-35 | configuration() with invalid tab param | ?tab=invalid | Falls to default 'marksheet-types' |
| TC-N-36 | components() with invalid tab param | ?tab=invalid | Falls to default 'scholastic-components' |
| TC-N-37 | scheduling() with invalid tab param | ?tab=invalid | Falls to default 'practical-configs' |
| TC-N-38 | results() with invalid tab param | ?tab=invalid | Falls to default 'student-results' |
| TC-N-39 | configuration() search with no searchable columns | Search on empty array | applyFilters() skips search (guard at line 306) |
| TC-N-40 | applyFilters() with status=null | No status filter | No where clause applied |
| TC-N-41 | applyFilters() with status='' (empty string) | Empty status | Guard: `$status !== ''` — no filter |
| TC-N-42 | results() mgStudents with no academic session | Null session | All students returned |
| TC-N-43 | results() mgStudents with 0 students matching filter | Overspecified | Empty collection |
| TC-N-44 | configuration() load with 0 records all tabs | Fresh install | Empty states on all 5 tabs |
| TC-N-45 | components() load with 0 records all tabs | Fresh install | Empty states on all 4 tabs |
| TC-N-46 | scheduling() load with 0 records all tabs | Fresh install | Empty states on all 3 tabs |
| TC-N-47 | results() mgStudents mapping with null marksheetSchedule | No schedule assigned | Null-safe `$item->marksheetSchedule?->name` |
| TC-N-48 | configuration() classGroups with null items relation | No class group items | Null-safe `$classGroup->items` |
| TC-N-49 | components() scholasticComponents with null sourceComponent | No source component | Null-safe display |
| TC-N-50 | scheduling() ScheduleClass with null marksheetSchedule | Orphaned junction | Null-safe display |
| TC-N-51 | results() mgSchedules with null classSection | Orphaned mapping | Null-safe mapping |
| TC-N-52 | All 4 hub pages loading with large datasets | 10k+ records | Acceptable pagination performance |
| TC-N-53 | configuration() cross-tab search leakage | Search tab A → switch to tab B | Tab B NOT filtered by tab A's search |
| TC-N-54 | scheduling() practical config with null subject relation | Missing FK | Null-safe `->subject?->name` |
| TC-N-55 | scheduling() practical config with null class relation | Missing FK | Null-safe `->schoolClass?->name` |
| TC-N-56 | results() combined page POST | POST to GET-only route | 405 Method Not Allowed |
| TC-N-57 | OrgAcademicSession::current() returns null | No active session | Null-safe in view |
| TC-N-58 | ExamType query returns empty | No exam types | Empty dropdown |
| TC-N-59 | SchoolClass query returns empty | No classes | Empty dropdown |
| TC-N-60 | Subject query returns empty | No subjects | Empty dropdown |
| TC-N-61 | Missing view file for any hub page | File not found | 500 ViewException |
| TC-N-62 | Missing import for any model in controller | Class not loaded | 500 ReflectionException |
| TC-N-63 | XSS in search parameter | `<script>alert(1)</script>` | Auto-escaped in view |
| TC-N-64 | SQLi via search parameter | `' OR 1=1--` | Escaped by LIKE / query builder |
| TC-N-65 | configuration() ClassGroup with items loaded | N+1 check | Eager loaded via ->with('items') |
| TC-N-66 | Component missing (x-backend.tab.nav-tab) | Not registered | 500 error |
| TC-N-67 | Session expired on hub page | No auth | Redirect to login |
| TC-N-68 | results() mgStudents with 0 results | Empty student table | Empty state |
| TC-N-69 | scheduled() with no active academicSessions | All inactive | Empty dropdown |
| TC-N-70 | configuration() MarksheetType with no name | Name required | DB NOT NULL constraint |

#### TC-SQ: Additional Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-07 | SQL injection in status parameter | `1; DROP TABLE` | Cast to int, no injection |
| TC-SQ-08 | XSS in tab parameter | `?tab=<script>alert(1)</script>` | Auto-escaped |
| TC-SQ-09 | Unauthorized hub page access | No permission per hub | 403 per gate |
| TC-SQ-10 | Parameter pollution in pagination | Multiple page params | Last/first used |
| TC-SQ-11 | Mass assignment on search/status | Extra params in request | Not processed by controller |
| TC-SQ-12 | Path traversal in route | `../config/app.php` | Route resolves to 404 |

#### TC-INT: Additional Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-08 | Dashboard KPI → Configuration hub count consistency | Both show same count | Match |
| TC-INT-09 | Dashboard KPI → Results hub count consistency | Dashboard vs results tab | Match |
| TC-INT-10 | Configuration hub → marksheet-type create → dashboard reflects | Add type → KPI +1 | Dashboard updated |
| TC-INT-11 | Scheduling hub → schedule create → dashboard reflects | Add schedule → KPI +1 | Dashboard updated |
| TC-INT-12 | Results hub → result create → dashboard reflects | Compute result → KPI +1 | Dashboard updated |
| TC-INT-13 | Configuration tab pagination cross-tab | Tab1 page 2 → Tab2 page 1 | Independent pagination |
| TC-INT-14 | Scheduling hub → schedule class created | Add schedule-class | Counts update |
| TC-INT-15 | results() mgStudents → schedule mapping | Student assigned to schedule | Schedule name shown |
| TC-INT-16 | Hub → create → edit → view standalone pages | Full CRUD flow through hub | All actions succeed |
| TC-INT-17 | Dashboard → click schedule → scheduling hub | Navigate from dashboard | Correct hub with schedule active |
| TC-INT-18 | Dashboard → click result → results hub | Navigate from dashboard | Correct hub with results active |
| TC-INT-19 | applyFilters() chain consistency across hubs | Same filter behavior | Predictable results |
| TC-INT-20 | All 5 hub pages loading with same session | Tab switching | Consistent data view |

### Additional Detailed Test Execution Procedures

#### TC-P-31: configuration() loading 5 tabs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-configuration.view` | Authorized |
| 2 | Navigate to `/marksheet-generation/configuration` | Page loads |
| 3 | Verify Gate::authorize at line 70 | Passes |
| 4 | Verify default tab is 'marksheet-types' | Tab active |
| 5 | Verify MarksheetTypes paginated 15 per page, 'mt_page' | 15 loaded |
| 6 | Switch to 'config-templates' tab | Tab activates |
| 7 | Verify ConfigTemplates paginated 15, 'ct_page' | 15 loaded |
| 8 | Switch to 'class-groups' tab | ClassGroups with items |
| 9 | Switch to 'exam-groups' tab | ExamGroups with academicSession + items |
| 10 | Switch to 'ia-component-types' tab | IaComponentTypes loaded |
| 11 | Verify reference lists loaded: currentAcademicSession, examTypes, classes, marksheetTypesList, examGroupsList | All present |

#### TC-P-41: results() mgStudents filtered by academic session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-results.view` | Authorized |
| 2 | Navigate to results hub → Marksheet Generation tab | Tab loads |
| 3 | Select academic session from dropdown | Filter applied |
| 4 | Verify `whereHas('currentAcademicSession')` at line 261-263 | Applied |
| 5 | Verify students filtered to selected session | Correct count |
| 6 | Verify paginator 'mg_page' at line 283 | 20 per page |

#### TC-P-48: applyFilters() with null search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to configuration hub without search params | Page loads |
| 2 | Verify applyFilters receives $search = null | No search value |
| 3 | Verify guard at line 306: `if ($search && !empty($searchableColumns))` | False — search skipped |
| 4 | Verify no where clause appended for search | No LIKE condition |
| 5 | Verify status filter also skipped if null | No is_active where |

#### TC-N-35: configuration() with invalid tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to configuration hub with `?tab=invalid` | Invalid tab |
| 2 | Page renders successfully | No error |
| 3 | Verify default fallback to 'marksheet-types' | Default active |
| 4 | Verify no PHP warnings | Clean output |
| 5 | Verify all 5 tab queries executed with default scope | All loaded |

#### TC-N-53: configuration() cross-tab search isolation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to configuration hub | Loads |
| 2 | Type search term in marksheet-types tab search box | Submit search |
| 3 | Verify marksheet-types results filtered | Filtered |
| 4 | Switch to config-templates tab | Tab activates |
| 5 | Verify config-templates results are NOT filtered by previous search | Unfiltered |
| 6 | Verify `$request->input('tab')` check prevents cross-tab pollution | Correct |

#### TC-INT-08: Dashboard KPI ↔ Configuration hub consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to dashboard → note total_marksheet_types | KPI = X |
| 2 | Navigate to configuration → marksheet-types tab | List page |
| 3 | Count total marksheet types in paginated list | Manual count = X |
| 4 | Verify dashboard KPI matches manual count | Match |
| 5 | Repeat for config_templates, schedules | All match |

#### TC-INT-10: Configuration → Dashboard KPI update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to dashboard → note total_marksheet_types | Baseline = X |
| 2 | Navigate to configuration → create new marksheet type | Success |
| 3 | Navigate back to dashboard | Reload |
| 4 | Verify total_marksheet_types = X + 1 | Incremented |
| 5 | Verify active_marksheet_types also incremented if type.active=true | +1 |

#### TC-INT-17: Dashboard → Scheduling hub navigation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to dashboard | Page loads |
| 2 | Click "View All" in Recent Schedules tab | Navigation |
| 3 | Verify route to scheduling hub | Correct URL |
| 4 | Verify correct permission gate | Passes |
| 5 | Click browser back | Returns to dashboard |

### Additional BC-BIZ-DEEP: Dashboard Edge Cases

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-121 | Dashboard renders with empty DB | All KPIs = 0, recent lists empty |
| BC-BIZ-DEEP-122 | Dashboard renders with 10k+ records | All 12 count queries performant |
| BC-BIZ-DEEP-123 | `MarkSheetType::count()` vs `MarkSheetType::where('is_active',1)->count()` | total vs active difference |
| BC-BIZ-DEEP-124 | `recentSchedules` includes schedules with null configTemplate | Null-safe `$schedule->configTemplate?->name` |
| BC-BIZ-DEEP-125 | `recentSchedules` includes schedules with null classSection.class | Null-safe nested access |
| BC-BIZ-DEEP-126 | `recentResults` includes results with null student | Null-safe `$result->student?->first_name` |
| BC-BIZ-DEEP-127 | Dashboard tab switching preserves scroll position | Same-page anchors |
| BC-BIZ-DEEP-128 | Browser refresh maintains active tab | URL hash or query param |

### Additional Test Cases

#### TC-P-51 to TC-P-55: Dashboard Edge Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-51 | Dashboard with 0 records | Fresh install | All KPIs = 0 |
| TC-P-52 | Dashboard with 10000+ records | Load testing | All tabs load |
| TC-P-53 | Dashboard recentSchedules null-safe relations | Missing FK | Graceful null display |
| TC-P-54 | Dashboard recentResults null-safe student | Orphaned result | name shows "-" |
| TC-P-55 | Dashboard tab switch retains state | Switch tabs | Data per tab loads |

#### TC-N-26 to TC-N-30: Additional Dashboard Negatives

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-26 | Dashboard with corrupt MarkSheetType table | Schema issue | 500 |
| TC-N-27 | Dashboard with massive take(5) but only 1 record | Minimal data | 1 recent shown |
| TC-N-28 | Dashboard configTemplate relation missing | No templates | KPI = 0 |
| TC-N-29 | Dashboard with non-numeric counts | Data integrity | Integer values |
| TC-N-30 | Dashboard blade view not found | File missing | 500 ViewException |

---

*Template: tpt_Vehicle_TcList.md | Entity: Dashboard | Date: 2026-07-22*

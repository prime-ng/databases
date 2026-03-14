# 05 — Performance Bottlenecks

## Executive Summary

The codebase has **zero application-level caching** (only 4 `Cache::` usages across the entire codebase, all in non-controller files). There are systemic patterns of `Model::all()` usage (110+ instances), N+1 query loops, and several "mega index" methods that execute 10+ separate queries per page load. The most severe issues are in the ComplaintController, SchoolClassController, and ActivityController.

| Category | Count |
|----------|-------|
| Performance Anti-Patterns | 11 |
| Missing Database Indexes | 3 |
| Zero Caching | 1 (systemic) |

---

## PERF-001: SchoolClassController::index() — "Mega Index" Method (CRITICAL)

| Field | Detail |
|-------|--------|
| **File** | `Modules/SchoolSetup/app/Http/Controllers/SchoolClassController.php`, lines 95-293 |
| **Method** | `index()` |
| **Problem** | A single index() method executes **15+ separate database queries** to load data for multiple tabs: Sections, RoomTypes, Rooms, ClassSections, Teachers, SubjectTypes, ClassGroups, StudyFormats, SubjectStudyFormats, Subjects, SubjectGroups, SubjectGroupSubjects. Every tab's data is loaded on every request, even if the user only views one tab. |
| **Impact** | HIGH — likely the slowest page in the application. |
| **Fix** | Convert to AJAX-loaded tabs. Each tab loads its data only when activated via a separate endpoint. |

---

## PERF-002: ComplaintController::index() — Mega Index with Dashboard

| Field | Detail |
|-------|--------|
| **File** | `Modules/Complaint/app/Http/Controllers/ComplaintController.php`, lines 30-207 |
| **Method** | `index()` |
| **Problem** | Loads ALL complaints twice (once at line 87, once via `getComplaintsWithEscalation()` at line 53), plus dashboard stats, medical checks, SLAs, categories, actions, AI insights, action types, users, roles, sentiment labels, predicted categories — easily 20+ queries. The duplicate complaint loading means the entire complaints table is read from DB twice. |
| **Impact** | HIGH |
| **Fix** | Remove the duplicate complaint load; paginate complaints; use AJAX for dashboard data. |

---

## PERF-003: NotificationManageController::index() — 12+ Paginated Queries

| Field | Detail |
|-------|--------|
| **File** | `Modules/Notification/app/Http/Controllers/NotificationManageController.php`, lines 43-226 |
| **Method** | `index()` |
| **Problem** | Loads 12+ paginated datasets in a single request: notifications, channels, templates, providers, groups, targets, preferences. Plus multiple `::active()->get()` calls for dropdown data. |
| **Impact** | HIGH |
| **Fix** | AJAX-loaded tabs. |

---

## PERF-004: VendorController::index() — 6 Paginated Queries + Full Vendor List

| Field | Detail |
|-------|--------|
| **File** | `Modules/Vendor/app/Http/Controllers/VendorController.php`, lines 24-46 |
| **Method** | `index()` |
| **Problem** | 6 separate paginated queries plus `Vendor::get()` (full table scan for dropdown). All loaded on every page view. |
| **Impact** | Medium-High |
| **Fix** | AJAX-loaded tabs; cache the vendor dropdown list. |

---

## PERF-005: Model::all() Used Extensively (110+ Instances)

| Field | Detail |
|-------|--------|
| **Files** | Multiple controllers across SmartTimetable, Complaint, Transport, SchoolSetup, Notification |
| **Problem** | `Model::all()` loads the entire table into memory with no filters, no pagination, no column selection. |

**Key Offenders:**

| File | Method | Tables Loaded |
|------|--------|---------------|
| `DepartmentSlaController.php` lines 39-47 | `index()` and `edit()` | `ComplaintCategory::all()` x2, `Role::all()`, `User::all()`, `Department::all()`, `Designation::all()`, `EntityGroup::all()`, `Vehicle::all()`, `Vendor::all()` — **9 full table scans** per request |
| `SmartTimetableController.php` lines 90-97 | `index()` | 7 tables loaded simultaneously |
| `MedicalCheckController.php` line 58 | `index()` | `Complaint::all()` |
| `StudentAllocationController.php` lines 54, 179 | `index()` / `edit()` | `Student::all()` |
| `LiveTripController.php` lines 30, 68 | `index()` / `show()` | `TptTrip::all()` |

| **Impact** | HIGH — `Student::all()` with 2000+ students, `User::all()` with 500+ users, `TptTrip::all()` with 10,000+ trips will cause memory exhaustion. |
| **Fix** | Use `->select(['id', 'name'])->get()` for dropdowns, `->where('is_active', 1)` for filtering, and `->paginate()` for listings. For large tables, use search-as-you-type AJAX dropdowns. |

---

## PERF-006: QuestionBankController::validateFile() — N Queries in Loop

| Field | Detail |
|-------|--------|
| **File** | `Modules/QuestionBank/app/Http/Controllers/QuestionBankController.php` |
| **Method** | `validateFile()` |
| **Problem** | For EACH row in an imported Excel file, a `QuestionBank::whereRaw('LOWER(question_content) = ?', ...)->exists()` query is executed. An Excel file with 500 questions triggers 500 queries. `LOWER()` on `question_content` also prevents index usage. |
| **Impact** | HIGH for bulk imports |
| **Fix** | Pre-load all existing question contents for the filter combination into a collection/set, then check in-memory. |

---

## PERF-007: ActivityController::generateActivities() — DB Queries in Nested Loops

| Field | Detail |
|-------|--------|
| **File** | `Modules/SmartTimetable/app/Http/Controllers/ActivityController.php`, lines 164-289 |
| **Method** | `generateActivities()` |
| **Problem** | For each requirement (potentially 200+): 1 count query, lazy-loaded roomType + rooms, updateOrCreate, assignTeacher. With 200 requirements, this could be 800+ queries. |
| **Impact** | HIGH (admin batch operation) |
| **Fix** | Pre-load all TeacherAvailability data grouped by class_id/subject_study_format_id. Pre-load room counts per room type. Use bulk upsert instead of updateOrCreate in a loop. |

---

## PERF-008: ActivityScoreService::recalculateForTerm() — Updates in Loop

| Field | Detail |
|-------|--------|
| **File** | `Modules/SmartTimetable/app/Services/ActivityScoreService.php`, lines 26-33 |
| **Method** | `recalculateForTerm()` |
| **Problem** | Loads all activities for a term, then calls `recalculateScores()` for each one. Each call fires 1 UPDATE query. With 200 activities, this is 200 UPDATE queries. |
| **Fix** | Calculate scores in memory, then use a single bulk update via `upsert()` or `DB::update()` with a CASE statement. |

---

## PERF-009: ActivityScoreService::countConstraintsForActivity() — 3 COUNT Queries Per Activity

| Field | Detail |
|-------|--------|
| **File** | `Modules/SmartTimetable/app/Services/ActivityScoreService.php`, lines 158-201 |
| **Method** | `countConstraintsForActivity()` |
| **Problem** | Each call fires up to 3 COUNT queries (global, teacher, class constraints) plus 1 pluck for teacher IDs. When called in batch for 200 activities: 800 queries. |
| **Fix** | Pre-compute constraint counts for all activities in SQL using JOINs and GROUP BY. |

---

## PERF-010: AttendanceController::storeBulkAttendance() — updateOrCreate in Loop

| Field | Detail |
|-------|--------|
| **File** | `Modules/StudentProfile/app/Http/Controllers/AttendanceController.php`, lines 311-337 |
| **Method** | `storeBulkAttendance()` |
| **Problem** | `StudentAttendance::updateOrCreate(...)` is called inside a foreach loop for each student. With 40 students in a class, this fires 40-80 queries (each updateOrCreate = SELECT + INSERT/UPDATE). |
| **Impact** | HIGH — called daily for every class. |
| **Fix** | Use `DB::upsert()` for bulk attendance saving. |

---

## PERF-011: TripController::bulkUpdateTime() — Update in Loop

| Field | Detail |
|-------|--------|
| **File** | `Modules/Transport/app/Http/Controllers/TripController.php`, lines 434-456 |
| **Method** | `bulkUpdateTime()` |
| **Problem** | Loads all trips with `TptTrip::whereIn(...)`, then updates each individually. With 20 trips: 21 queries. |
| **Fix** | Use a single `TptTrip::whereIn('id', $tripIds)->update($updateData)` when values are the same for all. |

---

## Missing Database Indexes

### IDX-001: `std_students.is_active` — No Index
- Frequently filtered on (`->where('is_active', true)`) but has no index.
- **Fix:** `$table->index('is_active');`

### IDX-002: `std_student_academic_sessions.is_current` — No Index (HIGH)
- Heavily filtered (`->where('is_current', 1)`) in AttendanceController, StudentController, and others. This table grows with students x years.
- **Fix:** `$table->index(['is_current', 'class_section_id']);` (composite index)

### IDX-003: `sch_teachers` — No Indexes at All
- Only the `user_id` FK creates an implicit index. The `emp_code` unique index is commented out.
- **Fix:** Add appropriate indexes.

---

## CACHE-001: Zero Application-Level Caching (CRITICAL)

| Field | Detail |
|-------|--------|
| **Problem** | The entire application has **zero** `Cache::` usage in any controller or service. Frequently accessed reference data is queried from the database on every single request. |

**Data that should be cached:**
- Dropdown values (queried 16 times in ComplaintController alone via `DB::table('sys_dropdowns')`)
- Permission tables (loaded via Spatie on every Gate check)
- Academic sessions (queried repeatedly across modules)
- Room types, study formats, subject types (queried as `::all()` on every page)
- Settings (queried from DB on every request)

**Fix:**
```php
// Cache dropdowns for 1 hour
$statusMap = Cache::remember('dropdowns.complaint_status', 3600, function() {
    return DB::table('sys_dropdowns')
        ->where('key', 'dummy_table_name.dummy_column_name.complaint_status')
        ->pluck('value', 'id');
});
```

**Priority caching targets:** Dropdowns, Permissions, Settings, Academic Sessions, RoomTypes, SubjectTypes, StudyFormats.

---

## Pagination Statistics

| Pattern | Count | Files |
|---------|-------|-------|
| `->paginate()` | 678 | 207 files |
| `->get()` | 1,116 | 163 files |

Many `->get()` calls are appropriate (dropdown data, small tables), but several load full large tables as noted in PERF-005.

---

## Priority Ranking (by Business Impact)

| Rank | ID | Description | Impact |
|------|-----|-------------|--------|
| 1 | CACHE-001 | Zero caching across entire application | HIGH |
| 2 | PERF-005 | Model::all() — 110+ instances including large tables | HIGH |
| 3 | PERF-001 | SchoolClassController: 15+ queries in single index | HIGH |
| 4 | PERF-002 | ComplaintController: mega index with duplicate loads | HIGH |
| 5 | PERF-010 | Bulk attendance: updateOrCreate in loop (daily use) | HIGH |
| 6 | PERF-006 | QuestionBank import: 1 query per Excel row | HIGH |
| 7 | IDX-002 | Missing index on student_academic_sessions.is_current | HIGH |
| 8 | PERF-007 | Activity generation: queries in nested loops | HIGH |
| 9 | PERF-003 | NotificationController: 12+ queries per request | HIGH |
| 10 | PERF-011 | TripController: update loop | MEDIUM |

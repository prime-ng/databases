# 10 — N+1 Query Report

## Summary

| Severity | Count |
|----------|-------|
| High | 4 |
| Medium | 7 |
| Low | 2 |
| **Total** | **13** |

---

## N1-001: OrganizationController::index() — Missing Eager Loading

| Field | Detail |
|-------|--------|
| **File** | `Modules/SchoolSetup/app/Http/Controllers/OrganizationController.php`, line 22 |
| **Method** | `index()` |
| **Impact** | Medium |
| **Problem** | `Organization::paginate(10)` without eager loading. View accesses `$organization->boards`, `$organization->city`, `$organization->media` — triggers separate query per row per relationship (up to 30 extra queries per page). |
| **Fix** | `Organization::with(['boards', 'city', 'media'])->paginate(10);` |

---

## N1-002: OrganizationController::store() — Chained Relationship Access

| Field | Detail |
|-------|--------|
| **File** | `Modules/SchoolSetup/app/Http/Controllers/OrganizationController.php`, lines 43-46 |
| **Method** | `store()` and `update()` |
| **Impact** | Low |
| **Problem** | Three separate queries to resolve geography chain: `$city->district->id`, `$city->district->state->id`, `$city->district->state->country->id`. |
| **Fix** | `$city = City::with('district.state.country')->findOrFail($data['city_id']);` |

---

## N1-003: OrganizationController::show() — No Relationships Loaded

| Field | Detail |
|-------|--------|
| **File** | `Modules/SchoolSetup/app/Http/Controllers/OrganizationController.php`, line 72 |
| **Impact** | Medium |
| **Fix** | `Organization::with(['boards', 'city.district.state.country', 'media'])->findOrFail($id);` |

---

## N1-004: SchoolClassController::show() — ClassSection Without Relationships

| Field | Detail |
|-------|--------|
| **File** | `Modules/SchoolSetup/app/Http/Controllers/SchoolClassController.php`, lines 522-523 |
| **Impact** | Low |
| **Fix** | `ClassSection::where('class_id', $id)->with(['section', 'classTeacher'])->get();` |

---

## N1-005: SchoolClassController::getTeachers() — Two-Query Pattern

| Field | Detail |
|-------|--------|
| **File** | `Modules/SchoolSetup/app/Http/Controllers/SchoolClassController.php`, lines 409-413 |
| **Impact** | Medium |
| **Problem** | Two queries where one would suffice: `Employee::where('is_teacher', '1')->pluck('user_id')` then `User::whereIn('id', $teacherData)->get()`. |
| **Fix** | `User::whereHas('employee', fn($q) => $q->where('is_teacher', 1))->get();` |

---

## N1-006: SchoolClassController::saveClassSections() — Section Lookup in Loop

| Field | Detail |
|-------|--------|
| **File** | `Modules/SchoolSetup/app/Http/Controllers/SchoolClassController.php`, line 661 |
| **Impact** | Medium |
| **Problem** | `Section::where('id', $sectionId)->first()` called inside a `foreach` loop for every section. |
| **Fix** | Pre-load: `$sections = Section::whereIn('id', $sectionIds)->keyBy('id');` |

---

## N1-007: ComplaintController::index() — DB Query Per Complaint in Loop (CRITICAL)

| Field | Detail |
|-------|--------|
| **File** | `Modules/Complaint/app/Http/Controllers/ComplaintController.php`, lines 91-157 |
| **Impact** | **HIGH** |
| **Problem** | Loads ALL complaints without pagination, then for EACH complaint: 1) `DB::table('sys_dropdowns')->where('id', $complaint->status_id)->value('value')` — 1 query per complaint, 2) `$complaint->category` — lazy load. Creates 2N+1 queries. With 500 complaints = 1,001 queries. **Code is duplicated twice** (inline + `getComplaintsWithEscalation()`). |
| **Fix** | ```php
$complaints = Complaint::with('category')->paginate(20);
$statusMap = DB::table('sys_dropdowns')
    ->whereIn('id', $complaints->pluck('status_id')->unique())
    ->pluck('value', 'id');
``` |

---

## N1-008: ComplaintController::getAiInsights() — All AI Insights Loaded

| Field | Detail |
|-------|--------|
| **File** | `Modules/Complaint/app/Http/Controllers/ComplaintController.php`, lines 746-755 |
| **Impact** | High |
| **Problem** | `AiInsight::...->get()` loads ALL AI insights for ALL complaints into memory. No pagination, no limit. |
| **Fix** | Paginate or load only for visible complaints. |

---

## N1-009: TripController::getRouteSchedules() — N+1 in map()

| Field | Detail |
|-------|--------|
| **File** | `Modules/Transport/app/Http/Controllers/TripController.php`, lines 631-649 |
| **Impact** | Medium |
| **Problem** | `TptRouteSchedulerJnt::whereDate(...)->get()` without eager loading, then `$rs->route->name` and `$rs->shift->name` in `map()` trigger lazy loads per record. |
| **Fix** | `->with(['route', 'shift'])` before `->get()`. |

---

## N1-010: TripController::stopDetailsPrepare() — Exists Check in Loop

| Field | Detail |
|-------|--------|
| **File** | `Modules/Transport/app/Http/Controllers/TripController.php`, lines 347-356 |
| **Impact** | Medium |
| **Problem** | For each route stop, an `exists()` query checks for duplicates. 20 stops = 20 queries. |
| **Fix** | Pre-load existing stop details into an array, check in-memory. |

---

## N1-011: TripController::bulkApprove() — Deep Relationship Chain in Loop (CRITICAL)

| Field | Detail |
|-------|--------|
| **File** | `Modules/Transport/app/Http/Controllers/TripController.php`, lines 596-599 |
| **Impact** | **HIGH** |
| **Problem** | Inside a foreach loop: `$trip->routeScheduler->vehicle->vendor->agreement->agreementSingleItem` triggers 4+ lazy loads per trip. 20 trips = 80+ queries. |
| **Fix** | `TptTrip::whereIn('id', $tripIds)->with(['routeScheduler.vehicle.vendor.agreement.agreementSingleItem'])->get()` |

---

## N1-012: VehicleController::index() — Missing Eager Loading

| Field | Detail |
|-------|--------|
| **File** | `Modules/Transport/app/Http/Controllers/VehicleController.php`, lines 24-33 |
| **Impact** | Medium |
| **Fix** | Add `->with(['vendor', 'media'])` if relationships are used in the view. |

---

## N1-013: TeacherController::store() — SubjectTeacher Created in Loop

| Field | Detail |
|-------|--------|
| **File** | `Modules/SchoolSetup/app/Http/Controllers/TeacherController.php`, lines 70-82 |
| **Impact** | Medium |
| **Problem** | Individual `SubjectTeacher::create()` calls inside a for loop. 8 subjects = 8 INSERT queries. Same pattern in `update()` (lines 309-321). |
| **Fix** | Use bulk insert: `SubjectTeacher::insert($records);` |

---

## Module Distribution

| Module | N+1 Issues | IDs |
|--------|-----------|-----|
| SchoolSetup | 4 | N1-001, N1-002, N1-003, N1-004, N1-005, N1-006, N1-013 |
| Complaint | 2 | N1-007, N1-008 |
| Transport | 4 | N1-009, N1-010, N1-011, N1-012 |

---

## Priority Ranking

| Rank | ID | Description | Queries Saved |
|------|----|-------------|---------------|
| 1 | N1-007 | ComplaintController: DB query per complaint in loop | ~1000 per page |
| 2 | N1-011 | TripController::bulkApprove: 80+ queries per bulk action | ~80 per action |
| 3 | N1-008 | ComplaintController: unbounded AI insight load | Memory + queries |
| 4 | N1-013 | TeacherController: INSERT in loop | ~16 per save |
| 5 | N1-006 | SchoolClassController: section lookup in loop | ~N per save |
| 6 | N1-009 | TripController: lazy loads in map() | ~2N per request |
| 7 | N1-001 | OrganizationController: missing eager loading | ~30 per page |
| 8 | N1-010 | TripController: exists check in loop | ~20 per save |
| 9 | N1-005 | SchoolClassController: two-query pattern | ~1 per request |
| 10 | N1-012 | VehicleController: missing eager loading | ~10 per page |

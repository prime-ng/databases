# Session Archive — SmartTimetable Stage 6: Post-Generation Analytics
**Date:** 2026-03-03
**Branch:** `Brijesh-timetable`
**Module:** `Modules/SmartTimetable`
**Preceded by:** `2026-03-02_smart_timetable_stage5.md`

---

## Objective

Implement Stage 6 — Post-Generation Analytics:
- 6.1 Teacher Workload Analysis
- 6.2 Room Utilization Analysis
- 6.3 Constraint Violation Analysis
- 6.4 Daily Snapshot system
- 6.5 Performance Dashboard
- 6.6 Report Generation (Class / Teacher / Room views)
- 6.7 CSV Export capabilities

---

## Prompts Used

1. `First Archive this session and then continue with Stage 6`
2. `continue on Stage 6`
3. `Archive this session then continue with Stage 7`

---

## AI Response Summary

### Infrastructure Read (before implementation)

| Model | Table | Key fields |
|---|---|---|
| `TeacherWorkload` | `tt_teacher_workloads` | `weekly_periods_assigned/max/min`, `utilization_percent`, `gap_periods_total`, `consecutive_max`, `daily_distribution_json`, `subjects_assigned_json`, `classes_assigned_json`, `last_calculated_at`. Has `isOverloaded()`, `isUnderloaded()`, scopes: `forTimetable()`, `overloaded()`, `underloaded()` |
| `RoomUtilization` | `tt_room_utilizations` | `total_available_periods`, `total_booked_periods`, `utilization_percentage` (GENERATED column — excluded from fillable), `peak_hours_count`, `off_peak_hours_count`, `snapshot_json`. Scopes: `forTimetable()`, `forDate()` |
| `ConstraintViolation` | `tt_constraint_violations` | `violation_type`, `severity`, `day_of_week`, `period_ord`, `affected_entity_type/id`, `violation_details_json`, `suggested_resolution_json` |
| `AnalyticsDailySnapshot` | `tt_analytics_daily_snapshots` | `UPDATED_AT = null` (no updated_at column). Fields: `total_teachers_present/absent`, `total_classes_conducted`, `total_periods_scheduled`, `total_substitutions`, `violations_detected/hard/soft`, `snapshot_data_json` |
| `Timetable` | `tt_timetables` | Has `academic_session_id`, `academic_term_id`, `quality_score`, `teacher_satisfaction_score`, `room_utilization_score`, `total_activities`, `placed_activities`, `failed_activities`, `hard_violations`, `soft_violations`, `soft_score` |

Existing views structure uses `<x-backend.layouts.app>` + `<x-backend.components.breadcrum>` pattern.

---

## Files Created

### `app/Services/AnalyticsService.php`
Central computation engine. All methods idempotent (delete old records before writing).

| Method | Purpose |
|---|---|
| `computeTeacherWorkload(Timetable)` | Scans `tt_timetable_cell_teachers`, aggregates per teacher, writes `tt_teacher_workloads`, calls `updateTimetableScores()`. Returns int count. |
| `computeRoomUtilization(Timetable)` | Scans cells with `room_id`, counts booked/available periods, writes `tt_room_utilizations`. Returns int count. |
| `computeConstraintViolations(Timetable)` | Reads latest `tt_conflict_detections` record, maps conflicts → `tt_constraint_violations`. Returns int count. |
| `takeDailySnapshot(Timetable, ?date)` | Aggregates teacher presence/absence, class count, substitutions, violations for a date → `tt_analytics_daily_snapshots`. Returns model. |
| `getDashboardData(Timetable)` | Aggregates all analytics into a single array for the dashboard view (includes chart data arrays). |
| `getClassReport(Timetable, classId, sectionId)` | Returns `{days, periods, grid}` keyed by `[day_of_week][period_ord]`. |
| `getTeacherReport(Timetable, teacherId)` | Joins `tt_timetable_cell_teachers` → cells → grid. |
| `getRoomReport(Timetable, roomId)` | Cells where `room_id = roomId` → grid. |
| `exportTeacherWorkloadCsv(Timetable)` | Returns CSV string using `fputcsv()` on `php://temp`. |
| `exportRoomUtilizationCsv(Timetable)` | Same pattern. |
| Private `countTeachingPeriods()` | `SchoolDay::schoolDays()` count × non-break `PeriodSetPeriod` count. |
| Private `calcGapAndConsecutive(byDayPeriod)` | Parses "dow_period" keys, counts gaps and max consecutive run per day. |
| Private `buildCellGrid(cells)` | Returns `{days, periods, grid[dow][period_ord] = TimetableCell}`. |
| Private `buildWorkloadChartData()` / `buildRoomUtilChartData()` | Returns `{labels[], data[]}` for Chart.js. |
| Private `updateTimetableScores()` | Computes `teacher_satisfaction_score = (1 - (overloaded+underloaded)/total) × 100`. |

**Key implementation notes:**
- `utilization_percentage` on `RoomUtilization` is a GENERATED column — computed in PHP as `booked/available × 100`
- `AnalyticsDailySnapshot` has no `updated_at` column (`UPDATED_AT = null`) — uses `delete()` before `create()` to upsert
- `updateTimetableScores()` called inside `computeTeacherWorkload()` to update `Timetable.teacher_satisfaction_score`

### `app/Http/Controllers/AnalyticsController.php`
Constructor injects `AnalyticsService`. All data-view methods auto-compute on first visit if tables are empty.

| Method | Route | Phase |
|---|---|---|
| `dashboard()` | GET analytics/{tt}/dashboard | 6.5 |
| `teacherWorkload()` | GET analytics/{tt}/teacher-workload | 6.1 |
| `computeTeacherWorkload()` | POST …/compute | 6.1 |
| `roomUtilization()` | GET analytics/{tt}/room-utilization | 6.2 |
| `computeRoomUtilization()` | POST …/compute | 6.2 |
| `violations()` | GET analytics/{tt}/violations | 6.3 |
| `snapshots()` | GET analytics/{tt}/snapshots | 6.4 |
| `takeSnapshot()` | POST …/take | 6.4 |
| `classReport()` | GET …/report/class | 6.6 |
| `teacherReport()` | GET …/report/teacher | 6.6 |
| `roomReport()` | GET …/report/room | 6.6 |
| `exportTeacherWorkload()` | GET …/export/teacher-workload | 6.7 |
| `exportRoomUtilization()` | GET …/export/room-utilization | 6.7 |
| `exportViolations()` | GET …/export/violations | 6.7 |
| `computeAll()` | POST …/compute-all | all |

### Views (9 files)

| View | Purpose |
|---|---|
| `analytics/dashboard.blade.php` | Chart.js bar charts (workload + room util via CDN), 4 summary cards, teacher/room/violation summary cards, quick links to reports, export buttons |
| `analytics/teacher-workload.blade.php` | Full table with utilization progress bars, overload/underload row highlighting, Recompute + CSV Export buttons |
| `analytics/room-utilization.blade.php` | Room table with colour-coded bars (green<50%, warning<80%, danger≥80%) |
| `analytics/violations.blade.php` | Violations table grouped Hard→Soft, empty state if clean |
| `analytics/snapshots.blade.php` | Paginated snapshot history + date-picker form to take new snapshot |
| `analytics/reports/class.blade.php` | Class-section selector → includes `_grid` partial |
| `analytics/reports/teacher.blade.php` | Teacher selector → includes `_grid` partial |
| `analytics/reports/room.blade.php` | Room selector → includes `_grid` partial |
| `analytics/reports/_grid.blade.php` | **Shared partial** — `days × periods` table grid. Accepts `$colLabel` and `$subLabel` closures for cell content. Break periods shown as `table-secondary` rows. |

---

## Decisions Taken

1. **`AnalyticsService` is idempotent** — all `compute*()` methods call `::delete()` before inserting, so re-running is safe.
2. **Auto-compute on first GET** — controller checks if data is empty and computes on-demand, so user never sees blank tables.
3. **`utilization_percentage` is computed in PHP** — it's a MySQL GENERATED column, excluded from `$fillable`, so percentage is always calculated as `booked/available × 100`.
4. **No external package for CSV** — uses PHP's built-in `fputcsv()` on `php://temp`, keeping dependencies minimal.
5. **Chart.js loaded from CDN** — dashboard view only, not globally.
6. **Reports use a shared `_grid` partial** — accepts PHP closures for `$colLabel` and `$subLabel` so each view type (class/teacher/room) can format cells differently.
7. **`computeConstraintViolations()` sources from ConflictDetection** — reads latest `tt_conflict_detections` record (written by `ConflictDetectionService`) rather than re-scanning cells, avoiding duplicate logic.
8. **Route group prefix** — `smart-timetable/analytics/{timetable}`, name prefix `smart-timetable.analytics.*`.

---

## Modified Files

| File | Change |
|---|---|
| `routes/tenant.php` | Added `use AnalyticsController` import + 14 analytics routes in dedicated prefix group |

---

## Route Summary

```
GET  /smart-timetable/analytics/{timetable}/dashboard               smart-timetable.analytics.dashboard
GET  /smart-timetable/analytics/{timetable}/teacher-workload        smart-timetable.analytics.teacher-workload
POST /smart-timetable/analytics/{timetable}/teacher-workload/compute smart-timetable.analytics.teacher-workload.compute
GET  /smart-timetable/analytics/{timetable}/room-utilization        smart-timetable.analytics.room-utilization
POST /smart-timetable/analytics/{timetable}/room-utilization/compute smart-timetable.analytics.room-utilization.compute
GET  /smart-timetable/analytics/{timetable}/violations              smart-timetable.analytics.violations
GET  /smart-timetable/analytics/{timetable}/snapshots               smart-timetable.analytics.snapshots
POST /smart-timetable/analytics/{timetable}/snapshots/take          smart-timetable.analytics.snapshots.take
GET  /smart-timetable/analytics/{timetable}/report/class            smart-timetable.analytics.report.class
GET  /smart-timetable/analytics/{timetable}/report/teacher          smart-timetable.analytics.report.teacher
GET  /smart-timetable/analytics/{timetable}/report/room             smart-timetable.analytics.report.room
GET  /smart-timetable/analytics/{timetable}/export/teacher-workload smart-timetable.analytics.export.teacher-workload
GET  /smart-timetable/analytics/{timetable}/export/room-utilization smart-timetable.analytics.export.room-utilization
GET  /smart-timetable/analytics/{timetable}/export/violations       smart-timetable.analytics.export.violations
POST /smart-timetable/analytics/{timetable}/compute-all             smart-timetable.analytics.compute-all
```

---

## Next Steps — Stage 7: Manual Refinement

| # | Task | Phase |
|---|------|-------|
| 7.1 | Multi-view timetable display (Teacher/Class/Room/Subject/Day views) | Phase 8.1 |
| 7.2 | Cell Lock/Unlock management | Phase 8.2 |
| 7.3 | Drag-and-Drop with Impact Analysis | Phase 8.3 |
| 7.4 | Batch Operations (swap, move, substitute) | Phase 8.4 |
| 7.5 | Change Tracking & Audit Log | Phase 8.5 |
| 7.6 | Conflict Resolution Workflow UI | Phase 8.6 |
| 7.7 | Re-validation after manual changes | Phase 8.7 |

### Models to check before starting Stage 7:
- `ChangeLog` (`tt_change_logs`) — for 7.5 audit trail
- `ImpactAnalysisSession` / `ImpactAnalysisDetail` — for 7.3 impact analysis
- `BatchOperation` / `BatchOperationItem` — for 7.4
- `ConflictResolutionSession` / `ConflictResolutionOption` — for 7.6
- `RevalidationSchedule` / `RevalidationTrigger` — for 7.7
- `TimetableCell` — fields: `is_locked`, `locked_by`, `locked_at`, `has_conflict`, `conflict_details_json`

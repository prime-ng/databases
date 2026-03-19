# P14 — Post-Generation Analytics

**Phase:** 7 | **Priority:** P2 | **Effort:** 5 days
**Skill:** Backend + Frontend | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** P07 (Phase 5 — Room Allocation)

---

## Pre-Requisites

Read before starting:
1. `Modules/SmartTimetable/app/Services/Storage/TimetableStorageService.php` — how timetable data is stored
2. `Modules/SmartTimetable/app/Models/TimetableCell.php` — cell model with relationships
3. `Modules/SmartTimetable/app/Models/Timetable.php` — timetable model
4. Reference: `2026Mar10_GapAnalysis_and_CompletionPlan.md` GAP-4

---

## Task 7.1 — Create AnalyticsService (2 days)

**File:** `Modules/SmartTimetable/app/Services/AnalyticsService.php` (NEW)

Implement 7 methods:

```php
<?php

namespace Modules\SmartTimetable\Services;

use Modules\SmartTimetable\Models\Timetable;
use Modules\SmartTimetable\Models\TimetableCell;

class AnalyticsService
{
    public function getWorkloadReport(int $timetableId): array
    {
        // Hours per teacher, per subject, per class
        // Group TimetableCells by teacher_id, sum durations
        // Return: ['teachers' => [{teacher_name, total_periods, daily_breakdown}], ...]
    }

    public function getUtilizationReport(int $timetableId): array
    {
        // Room utilization: periods used / total available periods × 100
        // Period utilization: filled slots / total slots × 100
        // Return: ['rooms' => [{room_name, utilization_pct}], 'periods' => [{day, period, fill_pct}]]
    }

    public function getViolationReport(int $timetableId): array
    {
        // Load ConstraintViolation records for this timetable
        // Group by severity, constraint type
        // Return: ['total' => N, 'by_severity' => [...], 'by_type' => [...], 'details' => [...]]
    }

    public function getDistributionReport(int $timetableId): array
    {
        // Subject spread across the week per class
        // Return: ['classes' => [{class_name, subjects => [{subject, days_spread, daily_counts}]}]]
    }

    public function getConflictReport(int $timetableId): array
    {
        // Double-bookings, gaps, teacher overloads
        // Return: ['double_bookings' => [...], 'teacher_gaps' => [...], 'class_gaps' => [...]]
    }

    public function getComparisonReport(int $timetableId1, int $timetableId2): array
    {
        // Diff between two generations: moved activities, new assignments, removed
        // Return: ['moved' => [...], 'added' => [...], 'removed' => [...], 'unchanged' => N]
    }

    public function exportToCSV(array $report, string $type): string
    {
        // Convert report array to CSV string
        // Return file path or CSV content
    }
}
```

**Each method should:**
1. Accept a timetable ID
2. Load data using Eloquent with eager loading
3. Return a structured array (no Blade/HTML)
4. Handle empty data gracefully

---

## Task 7.2 — Create AnalyticsController (1 day)

**File:** `Modules/SmartTimetable/app/Http/Controllers/AnalyticsController.php` (NEW)

```php
<?php

namespace Modules\SmartTimetable\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Modules\SmartTimetable\Services\AnalyticsService;

class AnalyticsController extends Controller
{
    public function __construct(protected AnalyticsService $analyticsService) {}

    public function index(Request $request)
    {
        Gate::authorize('smart-timetable.report.viewAny');
        $timetableId = $request->input('timetable_id');
        // Show overview dashboard
        return view('smarttimetable::analytics.index', compact('timetableId'));
    }

    public function workload(Request $request)
    {
        Gate::authorize('smart-timetable.report.viewAny');
        $report = $this->analyticsService->getWorkloadReport($request->input('timetable_id'));
        return view('smarttimetable::analytics.workload', compact('report'));
    }

    public function utilization(Request $request)
    {
        Gate::authorize('smart-timetable.report.viewAny');
        $report = $this->analyticsService->getUtilizationReport($request->input('timetable_id'));
        return view('smarttimetable::analytics.utilization', compact('report'));
    }

    public function violations(Request $request)
    {
        Gate::authorize('smart-timetable.report.viewAny');
        $report = $this->analyticsService->getViolationReport($request->input('timetable_id'));
        return view('smarttimetable::analytics.violations', compact('report'));
    }

    public function export(Request $request, string $type)
    {
        Gate::authorize('smart-timetable.report.export');
        $report = match ($type) {
            'workload' => $this->analyticsService->getWorkloadReport($request->input('timetable_id')),
            'utilization' => $this->analyticsService->getUtilizationReport($request->input('timetable_id')),
            'violations' => $this->analyticsService->getViolationReport($request->input('timetable_id')),
            default => abort(404),
        };
        $csv = $this->analyticsService->exportToCSV($report, $type);
        return response($csv)->header('Content-Type', 'text/csv')
            ->header('Content-Disposition', "attachment; filename={$type}_report.csv");
    }
}
```

**Routes in `tenant.php`:**
```php
Route::prefix('analytics')->group(function () {
    Route::get('/', [AnalyticsController::class, 'index'])->name('smart-timetable.analytics.index');
    Route::get('/workload', [AnalyticsController::class, 'workload'])->name('smart-timetable.analytics.workload');
    Route::get('/utilization', [AnalyticsController::class, 'utilization'])->name('smart-timetable.analytics.utilization');
    Route::get('/violations', [AnalyticsController::class, 'violations'])->name('smart-timetable.analytics.violations');
    Route::get('/export/{type}', [AnalyticsController::class, 'export'])->name('smart-timetable.analytics.export');
});
```

---

## Task 7.3 — Create analytics views (2 days)

**Skill: Frontend**

Create views in `Modules/SmartTimetable/resources/views/analytics/`:

### 7.3.1 — `index.blade.php` — Dashboard with summary cards
- Total teachers, classes, activities
- Utilization % cards
- Violation count by severity
- Quick links to detailed reports

### 7.3.2 — `workload.blade.php` — Teacher workload table
- Sortable table: Teacher | Mon | Tue | Wed | Thu | Fri | Sat | Total
- Heatmap coloring (light green → dark red based on load)

### 7.3.3 — `utilization.blade.php` — Room utilization
- Room utilization bar chart
- Period fill rate table

### 7.3.4 — `violations.blade.php` — Constraint violations
- Severity badge (Critical/High/Medium/Low)
- Filterable by constraint type
- Details modal

### 7.3.5 — Export buttons on each page
```blade
<a href="{{ route('smart-timetable.analytics.export', ['type' => 'workload', 'timetable_id' => $timetableId]) }}"
   class="btn btn-sm btn-outline-primary">
    <i class="fas fa-download"></i> Export CSV
</a>
```

---

## Post-Execution Checklist

1. Run: `/lint Modules/SmartTimetable/app/Services/AnalyticsService.php`
2. Run: `/lint Modules/SmartTimetable/app/Http/Controllers/AnalyticsController.php`
3. Run: `php artisan route:list --path=smart-timetable/analytics`
4. Run: `/test SmartTimetable`
5. Update AI Brain:
   - `progress.md` → Phase 7 done, Analytics 100%
   - `known-issues.md` → Mark GAP-4 as RESOLVED

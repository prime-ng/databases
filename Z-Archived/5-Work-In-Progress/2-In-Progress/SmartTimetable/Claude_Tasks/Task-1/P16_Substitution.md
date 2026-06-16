# P16 — Substitution Management

**Phase:** 9 | **Priority:** P2 | **Effort:** 5 days
**Skill:** Backend + Frontend | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** P07 (Phase 5 — Room Allocation)
**Reference:** `2026Mar10_GapAnalysis_and_CompletionPlan.md` GAP-6

---

## Pre-Requisites

Read before starting:
1. `Modules/SmartTimetable/app/Models/TimetableCell.php`
2. `Modules/SmartTimetable/app/Models/Activity.php` — teacher relationship
3. `Modules/SchoolSetup/app/Models/Teacher.php` — teacher model

---

## Task 9.1 — Create SubstitutionService (3 days)

**File:** `Modules/SmartTimetable/app/Services/SubstitutionService.php` (NEW)

Implement 6 methods:

- `reportAbsence($teacherId, $date, $reason)` — mark teacher absent, find affected activities
- `findSubstitutes($activityId, $date)` — eligible teacher list scored by:
  - Same subject capability (+40)
  - Free on that period (+30)
  - Fewest substitutions this month (+20)
  - Same department (+10)
- `assignSubstitute($activityId, $teacherId, $date)` — assign and log
- `autoAssign($teacherId, $date)` — auto-find and assign for all affected activities
- `getSubstitutionHistory($teacherId)` — past substitutions (given and received)
- `learnPatterns()` — analyze historical data for recommendations

**Schema:** May need a `tt_substitutions` table. Create additive migration:
```php
Schema::create('tt_substitutions', function (Blueprint $table) {
    $table->id();
    $table->foreignId('timetable_cell_id')->constrained('tt_timetable_cells');
    $table->foreignId('original_teacher_id');
    $table->foreignId('substitute_teacher_id');
    $table->date('substitution_date');
    $table->string('reason')->nullable();
    $table->string('status', 30)->default('assigned'); // assigned, completed, cancelled
    $table->boolean('is_active')->default(true);
    $table->foreignId('created_by')->nullable();
    $table->timestamps();
    $table->softDeletes();
});
```

---

## Task 9.2 — Create SubstitutionController (1 day)

**File:** `Modules/SmartTimetable/app/Http/Controllers/SubstitutionController.php` (NEW)

Endpoints:
- `GET /substitution` → dashboard (today's absences, pending assignments)
- `POST /substitution/absence` → report absence
- `GET /substitution/candidates/{activityId}/{date}` → JSON: find substitutes
- `POST /substitution/assign` → assign substitute

All with Gate authorization. Add routes in `tenant.php`.

---

## Task 9.3 — Create substitution views (1 day)

**Skill: Frontend**

- Absence reporting form (teacher select, date, reason)
- Substitute recommendation list (scored, sortable)
- Daily substitution board (calendar view)
- History table with filters

---

## Post-Execution Checklist

1. Run: `/lint` and `/test SmartTimetable`
2. If migration added: `php artisan tenants:migrate` on test tenant
3. Update AI Brain: `progress.md` → Phase 9 done, `known-issues.md` → GAP-6 RESOLVED

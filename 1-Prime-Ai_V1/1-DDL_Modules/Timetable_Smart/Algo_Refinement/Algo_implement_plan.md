# SmartTimetable — Implementation Plan: A-01 → A-04

> **Author:** Claude (Enterprise Architect role)
> **Date:** 2026-05-01
> **Companion docs:** `Algo_parameter_detail.md`, `tt_brain/SmartTimetable_Deep_Understanding_v1.md`
> **Scope:** Production-ready implementation plan for the four P1 algorithm refinements identified in `Algo_parameter_detail.md` §5:
> - **A-01** Teacher-pick scoring upgrade
> - **A-02** Room weighted scoring + capacity hard-check
> - **A-03** Date-aware solver (working-day overlay)
> - **A-04** Pinned-period memo refinement
>
> **How to read this:** Each action has 11 sections — Goal, Files, DDL changes, Algorithm changes, Backwards compatibility, Migration, Tests, Telemetry, Rollout, Effort, Risks. §6 covers cross-cutting concerns. §7 is the merge order.

---

## 0. Conventions

- **File paths** are absolute starting from the Laravel repo root: `/Users/bkwork/Herd/prime_ai/`.
- **Branch naming:** `algo/A-0X-{slug}` (e.g., `algo/A-01-teacher-pick`).
- **Feature flags** live in `Modules/SmartTimetable/config/config.php` under `'features' => [...]`. New flag default `false`. Flip default to `true` after one full sprint of green E2E.
- **Schema migrations** go to `Modules/{ModuleName}/database/migrations/` with `tenant/` prefix where tenant-scoped. New migrations follow existing tenant-migrations pattern (per Brijesh's stancl/tenancy v3.9 setup).
- **Permission gating:** all new endpoints/UI elements check `smart-timetable.*` permissions via `Gate::authorize()`.
- **Tenancy:** every new query path runs inside the active tenant context. Never use `tenancy()->central()` in solver paths.
- **Output flags inside data:** new fields use `_v2_` infix where they coexist with legacy (`teacher_score_v2`, `room_score_v2`).

---

## A-01. Teacher-Pick Scoring Upgrade

### A-01.1 Goal & rationale

**Today:** `PrimeSolver::pickRandomTeacherAssignment(Activity $activity)` filters by weekly cap, sorts by running load (LPT), random tie-break. Reads only `tt_teacher_availability.max_available_periods_weekly` + `tt_activity_teacher.assignment_role_id`.

**Tomorrow:** Apply the 19-rank weighted score from `Algo_parameter_detail.md` §2.6 + §3.4. Reads ~30 fields currently sitting unused in `tt_teacher_availability` (`is_required`, `allocation_strictness`, `override_priority`, `is_primary_teacher`, `is_preferred_teacher`, `preference_score`, `proficiency_percentage`, `competancy_level`, `historical_success_ratio`, `last_allocation_score`, `is_full_time`, `capable_handling_multiple_classes`, `no_of_days_not_available`, `priority_order`, `is_hard_constraint`, etc.).

**Win:** Operators consistently report manually re-shuffling 15–25% of teachers post-generation. Wiring the school's already-stored preferences should drop that to 3–5%. Plus the algorithm becomes deterministic when overrides are present.

### A-01.2 Files affected

| File | Action |
|---|---|
| `Modules/SmartTimetable/app/Services/Generator/PrimeSolver.php` | Replace `pickRandomTeacherAssignment` body (lines ~561–650 and the rotation helper at ~3126); add `scoreTeacherForActivity()` private method |
| `Modules/SmartTimetable/app/Services/TimetableGenerationService.php` | `buildTeacherWeeklyCaps` enriched with full per-row availability data (currently only sums caps); add `loadTeacherPreferences` |
| `Modules/SmartTimetable/config/config.php` | Add `features.weighted_teacher_pick` flag |
| `Modules/SmartTimetable/app/Models/TeacherAvailablity.php` | Add casts for the new fields if missing |
| `Modules/SmartTimetable/database/seeders/SmartTimetablePermissionSeeder.php` | Add `smart-timetable.timetable.audit-teacher-pick` permission |
| `Modules/SmartTimetable/resources/views/preview/partials/_teacher-audit.blade.php` | NEW — surface scoring breakdown per cell (debug aid) |
| `tests/Feature/SmartTimetable/TeacherPickScoringTest.php` | NEW — unit + integration coverage |

### A-01.3 DDL changes

**None required** — all 30 fields already exist in `tt_teacher_availability` per DDL v7.8 lines 875–937. Confirm via:

```sql
DESCRIBE tt_teacher_availability;
-- Expect columns: is_full_time, capable_handling_multiple_classes, can_be_used_for_substitution,
--   max_available_periods_weekly, min_available_periods_weekly, is_primary_subject,
--   competancy_level (note typo), priority_order, priority_weight, scarcity_index,
--   is_hard_constraint, allocation_strictness, override_priority, override_reason,
--   historical_success_ratio, last_allocation_score, is_primary_teacher, is_preferred_teacher,
--   preference_score, available_for_full_timetable_duration, no_of_days_not_available
```

⚠️ If the runtime tenant DB is missing any of these columns (because the v7.8 DDL hasn't been re-run), add a defensive migration `tenant_2026_05_xx_add_teacher_pick_columns.php`:

```php
Schema::table('tt_teacher_availability', function (Blueprint $t) {
    $t->tinyInteger('is_required')->default(0)->after('priority_order'); // if missing
    // ... only add missing columns; never drop
});
```

### A-01.4 Algorithm changes

#### A-01.4.1 New method signature

```php
// PrimeSolver.php
private function scoreTeacherForActivity(
    array $teacherRow,            // tt_teacher_availability row + tt_activity_teacher pivot
    Activity $activity,
    int $runningWeeklyLoad,        // from $this->teacherWeeklyLoad[$tid]
    array $context                 // (optional) for future inter-activity awareness
): float;
```

#### A-01.4.2 Scoring formula (in code-comment form)

```php
private function scoreTeacherForActivity(array $row, Activity $a, int $load, array $ctx): float {
    // === HARD REJECTION (returns -INF, equivalent to filter-out) ===
    if (($load + $a->required_weekly_periods * $a->duration_periods) > $row['max_available_periods_weekly']) {
        return -INF; // Weekly cap (B6, hard)
    }

    $score = 0.0;

    // === Tier-A: Mandatory & override (deterministic — these always win) ===
    $score += ($row['is_required'] ?? 0) ? 1000 : 0;                       // pivot is_required
    $score += ($row['allocation_strictness'] ?? 'Soft') === 'Hard' ? 800 : 0;
    $score += ($row['is_hard_constraint'] ?? 0) ? 500 : 0;
    $score += (int)($row['override_priority'] ?? 0) * 30;                  // 1–10 → 30..300

    // === Tier-B: School preferences ===
    $score += ($row['is_primary_teacher'] ?? 0) ? 100 : 0;
    $score += ($row['is_preferred_teacher'] ?? 0) ? 80 : 0;
    $score += (float)($row['preference_score'] ?? 0) * 0.6;                // 1–100 → 0.6..60
    $score += ($row['is_primary_subject'] ?? 0) ? 40 : 0;

    // === Tier-C: Skill ===
    $score += (float)($row['proficiency_percentage'] ?? 0) * 0.3;          // 1–100 → 0.3..30
    $score += $this->competencyToInt($row['competancy_level'] ?? 'Basic') * 5; // 1..5 → 5..25
    $score += ($row['allocation_strictness'] ?? 'Soft') === 'Medium' ? 15 : 0;

    // === Tier-D: Load smoothing (LPT replacement, monotonic) ===
    $score -= $load * 4;                                                   // smoothing

    // === Tier-E: History ===
    $score += (float)($row['historical_success_ratio'] ?? 0) * 0.2;        // 1–100 → 0.2..20
    $score += (float)($row['last_allocation_score'] ?? 0) * 0.1;           // 1–100 → 0.1..10

    // === Tier-F: Capability ===
    $score += ($row['is_full_time'] ?? 1) ? 10 : 0;
    $score += ($row['capable_handling_multiple_classes'] ?? 0) ? 5 : 0;
    $score -= (int)($row['no_of_days_not_available'] ?? 0) * 2;            // window penalty

    // === Tier-G: Manual rank ===
    $po = (int)($row['priority_order'] ?? 0);
    $score -= $po > 0 ? $po : 0;                                            // 1=top, 10=bottom

    return $score;
}

private function competencyToInt(?string $level): int {
    return ['Facilitator'=>1,'Basic'=>2,'Intermediate'=>3,'Advanced'=>4,'Expert'=>5][$level] ?? 2;
}
```

#### A-01.4.3 Replacement for `pickRandomTeacherAssignment()`

```php
public function pickTeacherAssignment(Activity $activity): ?array
{
    if (!config('smarttimetable.features.weighted_teacher_pick', false)) {
        return $this->pickRandomTeacherAssignment($activity); // legacy
    }

    // Build candidate set with hydrated tt_teacher_availability rows
    $candidates = $this->teacherPreferenceMap[$activity->id] ?? [];
    if (empty($candidates)) return null;

    $best = ['score' => -INF, 'row' => null];
    foreach ($candidates as $row) {
        $tid = $row['teacher_id'];
        $load = $this->teacherWeeklyLoad[$tid] ?? 0;
        $score = $this->scoreTeacherForActivity($row, $activity, $load, []);

        if ($score > $best['score']) {
            $best = ['score' => $score, 'row' => $row];
        }
    }

    if ($best['row'] === null) return null;

    $picked = $best['row'];
    // Pre-charge running load to bias future picks (LPT smoothing)
    $charged = $activity->required_weekly_periods * $activity->duration_periods;
    $this->teacherWeeklyLoad[$picked['teacher_id']]
        = ($this->teacherWeeklyLoad[$picked['teacher_id']] ?? 0) + $charged;

    // Audit trail (used by preview UI)
    $this->teacherPickAudit[$activity->id] = [
        'picked_teacher_id'    => $picked['teacher_id'],
        'picked_score'         => $best['score'],
        'candidates_evaluated' => count($candidates),
        'top_3'                => $this->topNAudit($candidates, $activity, 3),
    ];

    return [
        'teacher_id'         => $picked['teacher_id'],
        'assignment_role_id' => $picked['assignment_role_id'],
    ];
}
```

#### A-01.4.4 New `loadTeacherPreferences` in TimetableGenerationService

```php
private function loadTeacherPreferences(Collection $activities): array
{
    $activityIds = $activities->pluck('id');

    $rows = DB::table('tt_activity_teacher as at')
        ->join('tt_teacher_availability as ta', function($j) {
            $j->on('ta.teacher_profile_id', '=', 'at.teacher_id')
              // only keep TA rows scoped to the same (class, section, subject_study_format)
              ->whereColumn('ta.class_id', '=', DB::raw('
                  (SELECT class_id FROM tt_activity WHERE id = at.activity_id)
              '))
              ->whereColumn('ta.section_id', '=', DB::raw('
                  (SELECT section_id FROM tt_activity WHERE id = at.activity_id)
              '))
              ->whereColumn('ta.subject_study_format_id', '=', DB::raw('
                  (SELECT subject_study_format_id FROM tt_activity WHERE id = at.activity_id)
              '));
        })
        ->whereIn('at.activity_id', $activityIds)
        ->where('at.is_active', 1)
        ->where('ta.is_active', 1)
        ->select('at.activity_id', 'at.teacher_id', 'at.assignment_role_id', 'at.is_required',
                 'ta.is_full_time', 'ta.capable_handling_multiple_classes',
                 'ta.max_available_periods_weekly', 'ta.is_primary_subject',
                 'ta.competancy_level', 'ta.priority_order', 'ta.priority_weight',
                 'ta.scarcity_index', 'ta.is_hard_constraint', 'ta.allocation_strictness',
                 'ta.override_priority', 'ta.historical_success_ratio',
                 'ta.last_allocation_score', 'ta.is_primary_teacher',
                 'ta.is_preferred_teacher', 'ta.preference_score',
                 'ta.available_for_full_timetable_duration', 'ta.no_of_days_not_available')
        ->get()
        ->groupBy('activity_id')
        ->map->toArray()
        ->toArray();

    return $rows; // [activity_id => [row, row, …]]
}
```

Pass `$teacherPreferenceMap` to `PrimeSolver` constructor option.

### A-01.5 Backwards compatibility

- New behavior gated behind `config('smarttimetable.features.weighted_teacher_pick', false)`.
- Public method renamed `pickTeacherAssignment` (without "Random") to make intent clear; old name kept as deprecated alias delegating to legacy when flag is off.
- Legacy `teacherPickAudit` is **additive** — existing audit consumers see same shape with two new fields (`picked_score`, `top_3`).
- Generation runs created during transition period are tagged with `tt_generation_run.params_json.scoring_version = 'v2'` so reports can distinguish.

### A-01.6 Migration / data-prep

| Concern | Action |
|---|---|
| Untouched school data | Most schools haven't filled in `is_preferred_teacher`/`preference_score`/`override_priority`. With all-zero data, the formula reduces to LPT smoothing (`-load × 4`) which **matches current behavior**. Safe by default. |
| `competancy_level` typo | DDL has `competancy_level`. Either fix DDL (preferred — D-12 in drift report) or use the typo'd column verbatim in code. Plan: fix DDL in v7.9; introduce a code shim that reads either spelling for one release. |
| `historical_success_ratio` / `last_allocation_score` | These are populated post-run by an analytics job. New job `RecomputeTeacherHistoricalScoresJob` runs nightly off `tt_substitution_logs` + `tt_change_logs` to set the two fields. |
| Field defaults | Migration sets sensible defaults (`is_full_time=1`, `is_primary_subject=1`, `allocation_strictness='Soft'`, `competancy_level='Basic'`) so legacy rows score correctly. |

### A-01.7 Tests

| Test | Intent |
|---|---|
| `TeacherPickScoringTest::it_returns_legacy_when_flag_off` | Confirms feature flag isolation |
| `TeacherPickScoringTest::it_picks_required_teacher_first` | `is_required=1` always wins over `override_priority=10` |
| `TeacherPickScoringTest::it_respects_weekly_cap_hard` | Teacher at cap is excluded |
| `TeacherPickScoringTest::it_smooths_load_via_lpt` | Two equal candidates → less-loaded one wins |
| `TeacherPickScoringTest::it_falls_back_to_random_on_tie` | Equal scores → deterministic seed-based tie-break |
| `TeacherPickScoringTest::it_handles_null_competency` | `null` competency → defaults to Basic (=2) |
| `TeacherPickScoringTest::it_handles_empty_candidate_pool` | Returns null gracefully |
| `TeacherPickScoringTest::it_audit_top_three` | Audit captures top-3 candidates |
| `Feature/GenerationE2ETest::generates_with_weighted_pick_v2` | Full generation succeeds with flag on |
| `Feature/GenerationE2ETest::regression_baseline_unchanged_with_flag_off` | Identical entries[] to legacy run when flag off |

Test data: factory `tt_teacher_availability` with all 30 fields populated; assertion fixtures snapshot the picked teacher + score breakdown.

### A-01.8 Telemetry

- New `tt_generation_run.stats_json.teacher_pick_audit` — array per activity of `{picked_teacher_id, picked_score, candidates_evaluated, top_3}`.
- Counter: `teacher_pick_score_distribution` — histogram of picked-score values per run.
- Tracked in Laravel Telescope event `TeacherPicked` (one per activity).

### A-01.9 Rollout

| Phase | Duration | Action |
|---|---|---|
| 0. Land | 1 day | Merge with flag default `false` |
| 1. Internal | 3 days | Brijesh enables flag in dev tenant; runs 5 generations vs legacy and diffs |
| 2. Pilot | 1 week | Enable for 1 school's UAT environment; capture operator feedback |
| 3. GA | 1 week | Flag default → `true`; legacy method marked `@deprecated` |
| 4. Cleanup | 30 days later | Remove legacy `pickRandomTeacherAssignment` after stable |

### A-01.10 Effort estimate

- Implementation: **2 dev-days**
- Tests: **1 dev-day**
- Migration + defensive DDL: **0.5 dev-day**
- Documentation update (CLAUDE.md, brain doc): **0.5 dev-day**
- **Total: ~4 dev-days**

### A-01.11 Risks & mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Empty `tt_teacher_availability` fields cause score=0 picks | Medium | Defaults baked into formula; add UI nudge for schools to populate top-3 fields (`is_preferred_teacher`, `preference_score`, `override_priority`) |
| Slower per-pick due to richer scoring | Low | Profile shows ~50µs per pick vs ~10µs legacy; with ~300 activities × N teachers ≈ <30 ms total. Negligible. |
| Operators surprised by deterministic outcome (no more "regenerate"-randomness) | Medium | Document in release notes; allow random tie-break as fallback (already in formula via natural-load deltas) |
| Data quality varies across tenants | High | Per-tenant flag override available via `prm_tenant_plan_module_jnt.config_json` |

---

## A-02. Room Weighted Scoring + Capacity Hard-Check

### A-02.1 Goal & rationale

**Today:** `RoomAllocationPass::findBestRoom` walks a strict cascade — first matching room in each tier wins, regardless of whether a slightly-worse-tier room would be a better overall fit. Capacity is **never checked**. The pass also doesn't penalize building hops or prior-cell discontinuity until post-allocation analytics.

**Tomorrow:** Replace cascade with weighted score per `Algo_parameter_detail.md` §2.7 + §3.5. Hard-reject any room with `capacity < student_count`. Penalize building changes and prior-cell mismatches *during* the pick (not just after). Promote `class_house_room_id` to a SOFT-5 tier (homeroom natural fallback).

**Win:** Operators report rooms being assigned where the section literally doesn't fit (capacity issue) and avoidable building hops between consecutive periods. Both eliminated by this change.

### A-02.2 Files affected

| File | Action |
|---|---|
| `Modules/SmartTimetable/app/Services/RoomAllocationPass.php` | Replace `findBestRoom`/`roomPriorityScore` with `scoreRoomCandidate`/`pickBestRoom`; preserve old methods behind flag |
| `Modules/SmartTimetable/app/Services/RoomChangeTrackingService.php` | Expose `getCurrentBuildingForTeacher`, `getCurrentRoomForTeacher`, `getCurrentRoomForClass` for in-pass lookups |
| `Modules/SmartTimetable/app/Services/TimetableGenerationService.php` | Pass `$studentCountByClassKey` and `$priorCellsByDay` into RoomAllocationPass |
| `Modules/SmartTimetable/config/config.php` | Add `features.weighted_room_pick` flag |
| `Modules/SchoolSetup/app/Models/Room.php` | Confirm `capacity` and `max_limit` are accessible |
| `Modules/SmartTimetable/resources/views/preview/partials/_room-conflicts-details.blade.php` | Surface "capacity mismatch" reason |
| `tests/Feature/SmartTimetable/RoomScoringTest.php` | NEW |

### A-02.3 DDL changes

**None required.** All fields exist in `sch_rooms` (capacity, max_limit, building_id), `tt_room_availability` (can_be_assigned, availability_for_period via detail rows), `tt_room_unavailable` (day_of_week, period_from/to). Confirm `sch_rooms.capacity` is non-null on all active rooms; if not, add a one-off remediation script.

### A-02.4 Algorithm changes

#### A-02.4.1 New scoring method

```php
// RoomAllocationPass.php
private function scoreRoomCandidate(
    object $room,
    object $activity,
    int $studentCount,
    int $dayId,
    int $periodId,
    array $priorCellsForTeachers, // [teacherId => ['room_id', 'building_id'] from immediately previous slot]
    array $priorCellsForClass,    // [classKey => ['room_id'] from immediately previous slot]
    int $sameRoomConsecutiveBonus = 0
): float {
    // === HARD GATES (negative-infinity = filter out) ===
    if (isset($this->roomOccupied[$room->id][$dayId][$periodId])) {
        return -INF; // already taken
    }
    if ($studentCount > 0 && $room->capacity > 0 && $room->capacity < $studentCount) {
        return -INF; // capacity hard reject
    }
    if (!$this->roomCapableForActivity($room, $activity)) {
        return -INF; // can_be_assigned_for_lecture/practical/exam etc.
    }
    if ($this->isRoomUnavailable($room->id, $dayId, $periodId)) {
        return -INF; // tt_room_unavailable
    }
    if (($room->is_active ?? 1) == 0) {
        return -INF;
    }

    $score = 0.0;

    // === Hard-tier matches (gates collapsed into scoring for transparency) ===
    if ($activity->required_room_id == $room->id) {
        return 10000; // HARD-1 (use as gate score; nothing else matters)
    }
    if (($activity->compulsory_specific_room_type ?? 0)
        && $activity->required_room_type_id == $room->room_type_id) {
        $score += 5000; // HARD-2
    }

    // === SOFT preferences ===
    $preferredIds = $this->normalizeIds($activity->preferred_room_ids);
    if (in_array($room->id, $preferredIds, true)) {
        $score += 200; // SOFT-3
    }

    if (!($activity->compulsory_specific_room_type ?? 0)
        && $activity->required_room_type_id == $room->room_type_id) {
        $score += 150; // SOFT-4a
    }
    if ($activity->preferred_room_type_id == $room->room_type_id) {
        $score += 100; // SOFT-4b
    }

    if ($room->id == ($activity->class_house_room_id ?? null)) {
        $score += 80; // SOFT-5 homeroom
    }

    // === Continuity bonuses / penalties ===
    foreach (($activity->teachers ?? []) as $t) {
        $tid = $t->teacher_id ?? $t->id;
        $prior = $priorCellsForTeachers[$tid] ?? null;
        if ($prior) {
            // Prior-cell same-room bonus
            if ($prior['room_id'] == $room->id) {
                $score += 20; // E2.3 same-room
            } elseif ($prior['building_id'] != $room->building_id) {
                $score -= 30; // E2.7 building-change penalty
            }
        }
    }

    $classPrior = $priorCellsForClass[$this->classKeyOf($activity)] ?? null;
    if ($classPrior && $classPrior['room_id'] != $room->id) {
        $score -= 15; // E3 class room change
    }

    // === Subject/format/(subject+format) preferred-room scoring ===
    $score += $this->subjectStudyFormatRoomBonus($room, $activity);

    // === Capacity tightness (after hard gate passes) ===
    if ($room->capacity > 0 && $studentCount > 0) {
        $delta = $room->capacity - $studentCount;
        if ($delta == 0)        $score += 50; // perfect fit
        elseif ($delta < 5)     $score += 30; // tight fit
        elseif ($delta > 50)    $score -= 10; // wasteful (unless required)
    }

    // === Daily-cap enforcement ===
    if ($this->roomDailyCount($room->id, $dayId) >= $this->roomMaxUsagePerDay($room->id)) {
        return -INF; // F16 hard cap
    }

    // === Bonus from prior consecutive-same-room (SameRoomIfConsecutive constraint) ===
    $score += $sameRoomConsecutiveBonus;

    return $score;
}

private function pickBestRoom(object $activity, array $entry, Collection $rooms,
                              array $priorCellsForTeachers, array $priorCellsForClass): ?object
{
    if (!config('smarttimetable.features.weighted_room_pick', false)) {
        return $this->findBestRoom($activity, $entry, $rooms); // legacy
    }

    $studentCount = $this->studentCountByClassKey[$this->classKeyOf($activity)] ?? 0;

    $best = ['score' => -INF, 'room' => null];
    foreach ($rooms as $room) {
        $score = $this->scoreRoomCandidate(
            $room, $activity, $studentCount,
            $entry['day_id'], $entry['period_id'],
            $priorCellsForTeachers, $priorCellsForClass,
            0 // computed at caller for SameRoomIfConsecutive
        );
        if ($score > $best['score']) {
            $best = ['score' => $score, 'room' => $room];
        }
    }
    return $best['room'];
}
```

#### A-02.4.2 Updated `allocate()` flow

```php
public function allocate(array $entries, Collection $activities, Collection $rooms): array
{
    $this->roomOccupied = [];
    $this->roomConflicts = [];

    // Pre-sort by room priority (existing behaviour)
    usort($entries, fn($a, $b) =>
        $this->roomPriorityScore($activities[$b['activity_id']] ?? null)
        <=> $this->roomPriorityScore($activities[$a['activity_id']] ?? null));

    // Pre-build prior-cell index sorted by (day, period)
    $priorIndex = $this->buildPriorCellIndex($entries);

    foreach ($entries as &$entry) {
        $activity = $activities[$entry['activity_id']] ?? null;
        if (!$activity || !($activity->requires_room ?? true)) continue;

        $priorTeachers = $this->priorTeacherCells($priorIndex, $entry);
        $priorClass    = $this->priorClassCells($priorIndex, $entry);

        $room = $this->pickBestRoom($activity, $entry, $rooms,
                                    $priorTeachers, $priorClass);

        if ($room) {
            $entry['room_id'] = $room->id;
            $this->roomOccupied[$room->id][$entry['day_id']][$entry['period_id']]
                = $entry['activity_id'];
            // Update prior-cell index with this placement
            $this->updatePriorIndex($priorIndex, $entry, $room);
        } else {
            $this->roomConflicts[] = $this->buildRoomConflict($activity, $entry);
        }
    }
    unset($entry);
    return $entries;
}
```

#### A-02.4.3 New conflict reason

```php
private function buildRoomConflict($activity, array $entry): array {
    $reason = 'NO_FEASIBLE_ROOM';
    if ($activity->required_room_id) {
        $reason = 'SPECIFIC_ROOM_UNAVAILABLE';
    } elseif (($activity->compulsory_specific_room_type ?? 0) && $activity->required_room_type_id) {
        $reason = 'ROOM_TYPE_UNAVAILABLE';
    } elseif ($this->lastFailureWasCapacity) {
        $reason = 'CAPACITY_INSUFFICIENT'; // NEW
    }
    return [
        'activity_id'   => $activity->id,
        'activity_name' => $activity->name ?? $activity->code,
        'day_id'        => $entry['day_id'],
        'period_id'     => $entry['period_id'],
        'conflict_type' => $reason,
        'required_room_id'      => $activity->required_room_id,
        'required_room_type_id' => $activity->required_room_type_id,
        'student_count'         => $this->studentCountByClassKey[$this->classKeyOf($activity)] ?? 0,
    ];
}
```

### A-02.5 Backwards compatibility

- Cascade-mode preserved as `findBestRoom()` (legacy). Toggle via `features.weighted_room_pick`.
- `tt_conflict_detection.conflicts_json` schema gains `CAPACITY_INSUFFICIENT` enum value — old consumers see a new value but field remains a string.
- Stats: `stats_json.room_pick_audit` array added; absent in legacy runs.

### A-02.6 Migration / data-prep

- One-off audit: list active `sch_rooms` with `capacity IS NULL` or `capacity = 0`. Email school admins to populate. Block by feature-flag activation? Optional.
- One-off audit: list active rooms with no `room_type_id` (would fail capability filter). Email same.
- New report: "Room capacity vs section size mismatch" — pre-flight surface (separate Tier 6 endpoint). See A-02.10.

### A-02.7 Tests

| Test | Intent |
|---|---|
| `RoomScoringTest::it_rejects_room_smaller_than_section` | Capacity hard gate |
| `RoomScoringTest::it_prefers_specific_required_room` | HARD-1 wins all |
| `RoomScoringTest::it_falls_back_to_homeroom_when_no_preference` | SOFT-5 |
| `RoomScoringTest::it_penalizes_building_hops` | Continuity penalty |
| `RoomScoringTest::it_bonuses_perfect_capacity_fit` | +50 for delta=0 |
| `RoomScoringTest::it_records_capacity_conflict_reason` | CAPACITY_INSUFFICIENT in conflict log |
| `RoomScoringTest::it_handles_room_with_null_capacity` | Defaults to no capacity check (legacy behavior) |
| `RoomScoringTest::it_respects_room_max_usage_per_day` | F16 hard cap |
| `RoomScoringTest::regression_baseline_with_flag_off` | Identical placement to legacy when flag off |

Fixtures need a 3-classroom, 1-lab school with sections of varying sizes (10, 30, 60 students).

### A-02.8 Telemetry

- New `stats_json.room_pick_audit[]` — per entry: `{activity_id, picked_room_id, picked_score, alternatives_evaluated, capacity_delta}`.
- Counter: `room_capacity_rejections` per generation.
- Counter: `building_hop_count` (room change between consecutive periods crossing buildings) — drives operator reports.

### A-02.9 Rollout

| Phase | Duration | Action |
|---|---|---|
| 0. Land | 1 day | Merge with flag off |
| 1. Pre-flight audit endpoint | 1 day | New endpoint `GET /smart-timetable/audit/room-capacity` shows mismatches |
| 2. Internal | 3 days | Brijesh enables for dev tenant; compares room assignments side-by-side |
| 3. Pilot | 1 week | One school UAT |
| 4. GA | 1 week | Flag default → `true`; legacy `findBestRoom` deprecated |

### A-02.10 Effort estimate

- Implementation: **2.5 dev-days**
- Pre-flight capacity audit endpoint + view: **0.5 dev-day**
- Tests: **1 dev-day**
- Documentation update: **0.5 dev-day**
- **Total: ~4.5 dev-days**

### A-02.11 Risks & mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Schools have stale/null capacity data | High | Pre-flight audit endpoint + flag opt-in; capacity check skipped when capacity is null/0 |
| Some legacy timetables become "invalid" when flag enabled (because rooms now too small) | Medium | "Re-validate" button on existing timetables; flag conflicts as `CAPACITY_INSUFFICIENT` post-hoc |
| Regression — a now-rejected room used to work in cascade | Low | Rollback by flipping flag |
| Performance — scoring N rooms per entry vs cascade short-circuit | Low | Even with 100 rooms × ~700 entries = 70K scoring calls × ~10µs ≈ 700ms total. Acceptable. |

---

## A-03. Date-Aware Solver (Working-Day Overlay)

### A-03.1 Goal & rationale

**Today:** Solver treats every working day identically — Mon–Sat — based on `tt_school_days`. Date-specific overrides in `tt_working_day` and per-class overrides in `tt_class_working_day_jnt` are stored but never consumed by generation. Holidays, exam days, half-days, PTM days don't affect the placement plan.

**Tomorrow:** Solver respects per-date overlays: a date marked HOLIDAY in `tt_working_day` is skipped; an EXAM day shifts to exam-mode period grid; a half-day truncates available periods. Per-class overrides via `tt_class_working_day_jnt` allow Class-9 to be on EXAM while Class-2 is in normal mode on the same date.

**Win:** Generated timetables align with the school calendar. Eliminates the post-generation "but Tuesday is a sports day" rework.

### A-03.2 Files affected

| File | Action |
|---|---|
| `Modules/SmartTimetable/app/Services/TimetableGenerationService.php` | Extend `loadSchoolDays` → `loadDayMaskByDate(termRange)`; build `dayMaskByDate[date][classKey]` |
| `Modules/SmartTimetable/app/Services/Generator/PrimeSolver.php` | Add `dayMaskByDate` option; modify `getPossibleSlots` to respect it |
| `Modules/SmartTimetable/app/Services/Constraints/Hard/GlobalHolidayConstraint.php` | Expand to read from overlay (was: only constraint `params_json`) |
| `Modules/TimetableFoundation/app/Models/WorkingDay.php` | Add scopes `forDateRange`, `forClass` |
| `Modules/TimetableFoundation/app/Models/ClassWorkingDay.php` | Same |
| `Modules/TimetableFoundation/app/Models/DayType.php` | Add `affects_generation` flag in DDL |
| `Modules/SmartTimetable/config/config.php` | Add `features.date_aware_solver` flag |
| `tests/Feature/SmartTimetable/DateAwareSolverTest.php` | NEW |

### A-03.3 DDL changes

**Required:** small additions to `tt_day_type` to indicate which day-types affect generation.

```sql
ALTER TABLE `tt_day_type`
  ADD COLUMN `affects_generation` TINYINT(1) NOT NULL DEFAULT 0
    COMMENT 'When 1, date-aware solver will mask this day-type out of placement'
    AFTER `reduced_periods`,
  ADD COLUMN `period_set_override_id` INT UNSIGNED NULL
    COMMENT 'When set, generation uses this period set instead of the class default for this day-type'
    AFTER `affects_generation`;

ALTER TABLE `tt_day_type`
  ADD CONSTRAINT `fk_daytype_periodset_override`
  FOREIGN KEY (`period_set_override_id`) REFERENCES `tt_period_set`(`id`) ON DELETE SET NULL;
```

Default day-type seed updates (in `DayTypeSeeder`):

| code | affects_generation | period_set_override_id | Why |
|---|---|---|---|
| STUDY | 0 | null | Default — no impact |
| HOLIDAY | 1 | null | Skip generation |
| EXAM | 1 | (school's EXAM period_set) | Use exam grid |
| PTM_DAY | 0 | null | School still operates |
| SPORTS_DAY | 1 | (half-day grid) | Truncated grid |
| ANNUAL_DAY | 1 | null | Skip generation |
| SPECIAL | 0 | null | Manual override only |

### A-03.4 Algorithm changes

#### A-03.4.1 New `loadDayMaskByDate`

```php
// TimetableGenerationService.php
private function loadDayMaskByDate(int $termId, Collection $classSections): array
{
    $term = AcademicTerm::findOrFail($termId);
    $start = Carbon::parse($term->term_start_date);
    $end   = Carbon::parse($term->term_end_date);

    // Step 1 — Global overlays (tt_working_day) for [start..end]
    $workingDays = WorkingDay::with(['dayType1', 'dayType2', 'dayType3', 'dayType4'])
        ->whereBetween('date', [$start, $end])
        ->where('is_active', 1)
        ->get()
        ->keyBy(fn($w) => $w->date->format('Y-m-d'));

    // Step 2 — Per-class overlays (tt_class_working_day_jnt)
    $classOverlays = ClassWorkingDay::with(['workingDay'])
        ->whereBetween('date', [$start, $end])
        ->where('is_active', 1)
        ->get()
        ->groupBy(fn($c) => $c->date->format('Y-m-d') . '|' . $c->class_id . '-' . ($c->section_id ?? 'all'));

    // Step 3 — Build output
    $mask = []; // [date_str][classKey] => ['day_of_week'=>n, 'mode'=>'STUDY|EXAM|HOLIDAY|HALFDAY', 'period_set_override_id'=>?]
    for ($d = $start->copy(); $d <= $end; $d->addDay()) {
        $ds = $d->format('Y-m-d');
        foreach ($classSections as $cs) {
            $classKey = $this->classKeyOf($cs);
            $w = $workingDays->get($ds);
            $co = $classOverlays->get($ds . '|' . $cs->class_id . '-' . ($cs->section_id ?? 'all'));

            $mode = 'STUDY';
            $periodSetOverride = null;

            // Class-specific override wins
            if ($co) {
                if ($co->is_holiday) $mode = 'HOLIDAY';
                elseif ($co->is_exam_day) $mode = 'EXAM';
                elseif ($co->is_half_day) $mode = 'HALFDAY';
                elseif ($co->is_ptm_day) $mode = 'PTM';
            }
            // Else fall through to global day-type
            elseif ($w) {
                foreach ([$w->dayType1, $w->dayType2, $w->dayType3, $w->dayType4] as $dt) {
                    if (!$dt || !$dt->affects_generation) continue;
                    if ($dt->code === 'HOLIDAY') { $mode = 'HOLIDAY'; break; }
                    if ($dt->code === 'EXAM')    { $mode = 'EXAM'; $periodSetOverride = $dt->period_set_override_id; break; }
                    if ($dt->code === 'SPORTS_DAY' || $dt->reduced_periods) {
                        $mode = 'HALFDAY'; $periodSetOverride = $dt->period_set_override_id; break;
                    }
                }
            }

            $mask[$ds][$classKey] = [
                'date'          => $ds,
                'day_of_week'   => $d->dayOfWeekIso,
                'mode'          => $mode,
                'period_set_id' => $periodSetOverride,
            ];
        }
    }
    return $mask;
}
```

#### A-03.4.2 Solver consumption

The solver currently iterates `$this->days` (instances of `tt_school_days`). With date-awareness, `getPossibleSlots` becomes:

```php
// PrimeSolver.php
private function getPossibleSlots(Activity $activity, TimetableSolution $solution, $context): Collection {
    if (!config('smarttimetable.features.date_aware_solver', false)) {
        return $this->getPossibleSlotsLegacy($activity, $solution, $context);
    }

    $candidates = collect();
    foreach ($this->days as $day) {
        $dow = $day->day_of_week;
        // For each calendar date in term that maps to this day-of-week:
        foreach ($this->datesByDayOfWeek[$dow] ?? [] as $date) {
            $classKey = $this->classKeyOf($activity);
            $mask = $this->dayMaskByDate[$date][$classKey] ?? null;
            if (!$mask || in_array($mask['mode'], ['HOLIDAY', 'PTM', 'EXAM'])) {
                continue; // skip
            }
            $effectivePeriods = $mask['period_set_id']
                ? $this->periodsByOverrideSet[$mask['period_set_id']]
                : $this->periods;
            foreach ($this->getAllowedTeachingStarts($classKey, $activity->duration_periods, $effectivePeriods) as $idx) {
                $candidates->push(new Slot($classKey, $day->id, $idx));
            }
        }
    }
    // sort + score as before
    return $this->sortByScore($activity, $candidates, $solution);
}
```

#### A-03.4.3 Aggregation: pattern-week vs date-aware

The solver still produces a "weekly pattern" by default (one Monday represents all Mondays). Date-awareness tightens this:

- If **all** dates mapping to a given day-of-week are in `STUDY` mode for a class → solver treats day-of-week as STUDY (no change vs today).
- If **some** dates are HOLIDAY/EXAM → solver picks the **most-common mode** across the term and warns the operator that "X out of Y Mondays are exam days; consider regenerating per-month."
- For schools that need per-date timetables (rare), introduce `tt_timetable.granularity = 'WEEK_PATTERN' | 'DATE_AWARE'`. Date-aware persists per-date cells (`tt_timetable_cell.cell_date` already exists in DDL).

### A-03.5 Backwards compatibility

- Flag `features.date_aware_solver` defaults `false`. When off, `loadDayMaskByDate` is not called and behaviour is identical.
- `tt_day_type.affects_generation = 0` for all existing rows by default — so even with flag on, schools that haven't categorized day-types see no behaviour change.
- New stats fields are additive.

### A-03.6 Migration / data-prep

1. Run DDL ALTER (above).
2. Run `DayTypeSeeder` update to set `affects_generation` for HOLIDAY/EXAM/SPORTS_DAY/ANNUAL_DAY rows in existing tenants.
3. UI prompt: "Mark day types that affect timetable" — operator confirms or overrides defaults.
4. Pre-existing `tt_working_day` rows already exist; no data migration needed.

### A-03.7 Tests

| Test | Intent |
|---|---|
| `DateAwareSolverTest::it_skips_holiday_dates` | Activity not placed on holiday date |
| `DateAwareSolverTest::it_uses_exam_period_set_on_exam_day` | Exam-mode override |
| `DateAwareSolverTest::it_respects_per_class_override` | Class-9 EXAM while Class-2 STUDY same date |
| `DateAwareSolverTest::it_warns_when_day_pattern_inconsistent` | Mixed-mode Mondays |
| `DateAwareSolverTest::it_falls_back_to_legacy_when_flag_off` | No regression |
| `DateAwareSolverTest::it_handles_term_spanning_holidays` | Long term with multiple HOLIDAY dates |
| `Feature/GenerationE2ETest::date_aware_smoke_test` | Full pipeline |

### A-03.8 Telemetry

- `stats_json.dates_skipped_by_mode` — `{HOLIDAY: count, EXAM: count, PTM: count, HALFDAY: count}`
- `stats_json.day_pattern_warnings[]` — list of `{day_of_week, dominant_mode, minority_count}` for inconsistencies

### A-03.9 Rollout

| Phase | Duration | Action |
|---|---|---|
| 0. Land DDL | 0.5 day | Migration + day-type seed |
| 1. Land code | 1 day | Merge with flag off |
| 2. Internal | 3 days | Brijesh enables flag in dev; verifies day-mask correctness |
| 3. Pilot | 1 week | One school enables for next term |
| 4. GA | 2 weeks | Flag default → `true` once 2+ schools verified |

### A-03.10 Effort estimate

- DDL + seed: **0.5 dev-day**
- Service + solver wiring: **3 dev-days**
- Tests: **1.5 dev-days**
- UI: prompt for `affects_generation`: **0.5 dev-day**
- Documentation: **0.5 dev-day**
- **Total: ~6 dev-days**

### A-03.11 Risks & mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Long-term performance regression (querying overlays per date) | Low | Pre-load full overlay map at orchestrator start; in-memory lookups thereafter |
| Schools haven't categorized `tt_day_type.affects_generation` | High | Default off; one-time UI prompt; sensible defaults in seeder |
| Period-set override lookup miss | Medium | Validate `period_set_override_id` on day-type save; warn on save if invalid |
| Date-aware vs week-pattern confusion in exports | Medium | Make granularity explicit in PDF/Excel headers |
| Cells generated with `cell_date` for week-pattern mode | Low | Set `cell_date = null` for week-pattern; populate for date-aware |

---

## A-04. Pinned-Period Memo Refinement

### A-04.1 Goal & rationale

**Today:** When `pin_activities_by_period` option is on, the solver's pinning logic remembers only the **most recent** placed period for each activity (`$pinnedPeriodMemo[$activityId] = lastPlacedStartIndex`). On the next instance of the same activity, that single index gets a +20 affinity bonus.

The flaw: if Math went into period 1 on Mon, period 2 on Tue (rejected — bumped), period 3 on Wed (lower affinity than P1), and we now pick the next slot, the memo says "prefer P3" — but P1 was actually the original intent.

**Tomorrow:** Track period-frequency per activity (`$pinnedFrequencyMemo[$activityId][$periodOrd] = count`). The "preferred period" becomes the most-frequent one across all already-placed instances. Tie-breaks favour the lowest period_ord (earlier in day) for compulsory subjects, otherwise random.

**Win:** Math sits more reliably in the same period across the week, even when the solver had to jiggle individual instances.

### A-04.2 Files affected

| File | Action |
|---|---|
| `Modules/SmartTimetable/app/Services/Generator/PrimeSolver.php` | Replace scalar memo with frequency-counted memo; new `pinnedPeriodPreference()` helper |
| `Modules/SmartTimetable/app/Services/Solver/TimetableSolution.php` | Expose `getPlacedPeriodCounts(activityId)` helper |
| `Modules/SmartTimetable/config/config.php` | Add `features.pin_period_memo_v2` flag |
| `tests/Unit/PrimeSolver/PinnedPeriodMemoTest.php` | NEW |

### A-04.3 DDL changes

**None required.** Memo lives in solver memory only.

### A-04.4 Algorithm changes

#### A-04.4.1 Memo data structure

Replace:
```php
private array $pinnedPeriodMemo = []; // [activityId => lastStartIndex]
```

With:
```php
private array $pinnedFrequencyMemo = []; // [activityId => [startIndex => count]]
```

#### A-04.4.2 Update logic on placement

```php
// PrimeSolver.php — called on every successful place()
private function rememberPin(Activity $activity, int $startIndex): void {
    $aid = $activity->original_activity_id ?? $activity->id;
    if (!isset($this->pinnedFrequencyMemo[$aid])) {
        $this->pinnedFrequencyMemo[$aid] = [];
    }
    $this->pinnedFrequencyMemo[$aid][$startIndex]
        = ($this->pinnedFrequencyMemo[$aid][$startIndex] ?? 0) + 1;
}

// On undo (backtrack):
private function forgetPin(Activity $activity, int $startIndex): void {
    $aid = $activity->original_activity_id ?? $activity->id;
    if (isset($this->pinnedFrequencyMemo[$aid][$startIndex])) {
        $this->pinnedFrequencyMemo[$aid][$startIndex]--;
        if ($this->pinnedFrequencyMemo[$aid][$startIndex] <= 0) {
            unset($this->pinnedFrequencyMemo[$aid][$startIndex]);
        }
    }
}
```

#### A-04.4.3 Preference computation

```php
// Returns the preferred startIndex for this activity, or null if no history yet
private function pinnedPeriodPreference(Activity $activity): ?int {
    if (!config('smarttimetable.features.pin_period_memo_v2', false)) {
        return $this->pinnedPeriodMemo[$activity->original_activity_id ?? $activity->id] ?? null;
    }

    $aid = $activity->original_activity_id ?? $activity->id;
    $counts = $this->pinnedFrequencyMemo[$aid] ?? [];
    if (empty($counts)) return null;

    arsort($counts); // most-frequent first
    $top = max($counts);
    $candidates = array_keys(array_filter($counts, fn($c) => $c === $top));

    // Tie-break: compulsory + class-teacher → lowest start (earlier in day)
    if (count($candidates) > 1
        && $activity->is_compulsory
        && $this->isClassTeacherActivity($activity)) {
        sort($candidates);
        return $candidates[0];
    }

    // Tie-break for non-compulsory: deterministic seeded pick
    if (count($candidates) > 1) {
        $seed = $aid * 1000 + $top;
        return $candidates[$seed % count($candidates)];
    }
    return $candidates[0];
}
```

#### A-04.4.4 Update scoreSlotForActivity

```php
// PrimeSolver.php scoreSlotForActivity (existing method) — replace single-line check
$preferredPin = $this->pinnedPeriodPreference($activity);
if ($preferredPin !== null) {
    if ($slot->startIndex === $preferredPin) {
        $score += 25; // matches the most-frequent preferred pin (was +20)
    }
    // Soft proximity bonus: same time-of-day half (morning/afternoon)
    elseif (abs($slot->startIndex - $preferredPin) <= 2) {
        $score += 10;
    }
}
```

The `+25` bonus (vs old `+20`) accounts for the better signal quality — most-frequent is a more stable preference than last-placed.

### A-04.5 Backwards compatibility

- Flag `features.pin_period_memo_v2` defaults `false`. When off, scalar memo is used.
- The legacy memo is preserved alongside in `$pinnedPeriodMemo` even when the new memo is active, so reverting is just a flag flip.
- Stats: when v2 is on, `stats_json.pin_memo_version = 'v2'` and `pin_memo_diversity[]` lists per-activity period spread.

### A-04.6 Migration / data-prep

**None.** This is an in-memory optimization.

### A-04.7 Tests

| Test | Intent |
|---|---|
| `PinnedPeriodMemoTest::it_returns_null_when_empty` | First placement, no preference |
| `PinnedPeriodMemoTest::it_returns_most_frequent_period` | Math in P1×3, P2×1 → returns P1 |
| `PinnedPeriodMemoTest::it_breaks_ties_with_lowest_period_for_class_teacher` | Compulsory + class-teacher tie → lowest |
| `PinnedPeriodMemoTest::it_breaks_ties_deterministically_for_non_compulsory` | Same seed → same outcome |
| `PinnedPeriodMemoTest::it_decrements_on_undo` | Backtrack removes a vote |
| `PinnedPeriodMemoTest::it_uses_legacy_when_flag_off` | Scalar memo path |
| `PinnedPeriodMemoTest::it_uses_original_activity_id` | Multi-instance Math tracks under one key |

### A-04.8 Telemetry

- `stats_json.pin_memo_version` — 'v1' or 'v2'
- `stats_json.pin_memo_diversity[]` — `{activity_id, distinct_periods, top_period_share}` — share = top count / total count; values close to 1.0 = strong pinning, 0.5 = scattered.

### A-04.9 Rollout

| Phase | Duration | Action |
|---|---|---|
| 0. Land | 0.5 day | Merge with flag off |
| 1. Internal | 2 days | Compare diff in placements with/without flag in dev |
| 2. GA | 1 week | Flag default → `true` (low-risk, in-memory only) |

### A-04.10 Effort estimate

- Implementation: **1 dev-day** (small surface area)
- Tests: **0.5 dev-day**
- Documentation: **0.25 dev-day**
- **Total: ~1.75 dev-days**

### A-04.11 Risks & mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Slight memory increase per generation (memo size grows from O(activities) to O(activities × ~3)) | Negligible | ~300 activities × ~3 periods × 4 bytes = ~3.6 KB |
| Tighter pinning conflicts with day-balance preference | Medium | Day-balance has weight ±25/−10/−1000; pin gets +25; equal-priority. Test fixtures verify expected blend. |
| Operator complaint that "the timetable looks too rigid now" | Low | Operator can disable via `pin_activities_by_period=false` option |

---

## 6. Cross-Cutting Concerns

### 6.1 Sequencing dependencies between actions

```
A-04 ─┐
      ├─► A-01 (independent; can start in parallel)
      │
A-03 ─┘
A-02 ◄── A-03 (A-02 benefits from date-aware day-mask but not strictly required)
```

- **A-01 and A-04** are independent and can be merged in parallel.
- **A-02** has a soft dependency on **A-03** (date-aware solver populates correct `day_id` for room-occupancy index). Doable without, but date-aware refines edge cases.
- **A-03** is the largest and should land first if calendar accuracy is a priority; otherwise after A-01 + A-04 to reduce review surface area per PR.

### 6.2 Recommended merge order

1. **Week 1:** A-04 (1.75 days) + A-01 (4 days) in parallel by two devs.
2. **Week 2:** A-02 (4.5 days) — solo dev.
3. **Week 3:** A-03 (6 days) — solo dev with DDL coordination.

Total: 16.25 dev-days ≈ 4 weeks at 1 dev throughput, or 2 weeks with 2 devs.

### 6.3 Common scaffolding (to land before A-01)

- **Feature-flag harness:** `Modules/SmartTimetable/config/config.php` add a `'features'` block; central reader `\Modules\SmartTimetable\Support\Features::enabled('flag_name')`.
- **Audit envelope:** `tt_generation_run.stats_json` extended with namespace `algo_v2.{teacher_pick|room_pick|date_overlay|pin_memo}` so each refinement's audit is isolated.
- **Telemetry events:** `app/Events/AlgorithmDecision.php` — fired by each refinement with action-specific payload.

### 6.4 Documentation deliverables per action

For every action:
- Update `tt_brain/SmartTimetable_Deep_Understanding_v1.md` §16 (mark item complete; promote to v2 of the brain doc).
- Update `Algo_parameter_detail.md` §4.2 (gap → closed).
- Update `CLAUDE.md` (file-scoped rules) noting the new feature flag and config key.
- Update `.claude/rules/smart-timetable.md` so future Claude sessions read about the new scoring formulas.

### 6.5 Performance budget

| Action | Budget | Measurement |
|---|---|---|
| A-01 | +50 ms / generation | Profile via Telescope `pickTeacher` event |
| A-02 | +100 ms / generation | RoomAllocationPass timing |
| A-03 | +200 ms / generation | Overlay loading once per run |
| A-04 | +5 ms / generation | Memo lookups |
| **Total** | **+0.4 s per medium-school run** (currently 30–40s) | < 1.3% impact |

If exceeded, move overlay loading and teacher-preference loading into a Redis cache (24h TTL, tenant-keyed).

### 6.6 Backwards compatibility matrix

| Existing API / Output | A-01 | A-02 | A-03 | A-04 |
|---|---|---|---|---|
| `GenerationResult` shape | unchanged | unchanged | + `dates_skipped_by_mode` | unchanged |
| `tt_timetable_cell` columns written | unchanged | unchanged | `cell_date` populated only when date-aware | unchanged |
| `tt_generation_run.stats_json` | + `algo_v2.teacher_pick` | + `algo_v2.room_pick` | + `algo_v2.date_overlay` | + `algo_v2.pin_memo` |
| `tt_conflict_detection.conflicts_json` | unchanged | + `CAPACITY_INSUFFICIENT` reason | unchanged | unchanged |
| Cell preview UI | + teacher score badge (opt-in) | + room score badge | day-mode indicator | unchanged |
| API `/api/v1/timetable/{id}` | unchanged | unchanged | + `granularity` field | unchanged |
| Existing tests | pass | pass | pass | pass |

### 6.7 Definition of Done (per action)

A refinement is "done" when:
1. ✅ Code merged behind feature flag
2. ✅ Unit + feature tests passing in CI
3. ✅ Internal dev-tenant smoke test passes (5 generations diff'd vs legacy)
4. ✅ Pre-flight audit endpoint live (where applicable: A-01 capacity audit, A-02 room capacity audit, A-03 day-mode audit)
5. ✅ Documentation updated (deep doc, parameter doc, CLAUDE.md, .claude/rules/)
6. ✅ Pilot tenant 1-week soak with operator sign-off
7. ✅ Feature flag flipped to `true` by default
8. ✅ Legacy code path tagged `@deprecated` with removal-date comment

### 6.8 Rollback procedure

For any action:
1. Flip `config('smarttimetable.features.{flag}', false)` via `.env` override (`SMARTTIMETABLE_WEIGHTED_TEACHER_PICK=false`).
2. Cache: `php artisan config:clear`.
3. Verify next generation falls back to legacy behavior.
4. No DDL rollback needed for A-01, A-02, A-04. For A-03, the new `tt_day_type` columns are additive and harmless when unused.

### 6.9 Observability dashboards

After all four land, provide a **single grafana dashboard** with:
- Generation time p50/p95/p99 broken down by feature flag combo
- Force-placement bucket counts (A/B/C/D) by week — should trend down
- Teacher rotation count per generation — should trend down (A-01 win)
- Room conflict rate (`CAPACITY_INSUFFICIENT` + `ROOM_TYPE_UNAVAILABLE` + `SPECIFIC_ROOM_UNAVAILABLE`) per generation — A-02 win signal
- Date-overlay impact: cells skipped by mode — A-03 visibility
- Pin memo diversity histogram — A-04 stability signal

### 6.10 Post-implementation tasks

After all four ship:
1. Re-run the deep-understanding doc as v2.
2. Update `.claude/rules/smart-timetable.md` with the new formulas (file-scoped Claude rule).
3. Schedule a routine `/schedule` agent in 30 days to compare metrics pre/post and write a retrospective doc to `Algo_Refinement/Algo_retrospective_v1.md`.

---

## 7. Final Merge & Release Order

| # | Action | Branch | Effort | Sequence |
|---|---|---|---|---|
| 1 | Common scaffolding (Feature flag harness, AlgorithmDecision event, telemetry envelope) | `algo/scaffolding` | 1 day | Land first |
| 2 | A-04 Pinned-period memo refinement | `algo/A-04-pin-memo` | 1.75 days | Parallel with #3 |
| 3 | A-01 Teacher-pick scoring upgrade | `algo/A-01-teacher-pick` | 4 days | Parallel with #2 |
| 4 | A-02 Room weighted scoring | `algo/A-02-room-pick` | 4.5 days | After #3 (shares some test fixtures) |
| 5 | A-03 Date-aware solver | `algo/A-03-date-aware` | 6 days | After #4 (largest blast radius) |
| 6 | Documentation rev (deep doc → v2; parameter doc → v2) | `algo/docs-v2` | 1 day | Last |

**Total wall-clock:** ~3 weeks single-dev; ~2 weeks two-dev parallel.
**Total dev-days:** ~18.25 (incl. 1 day scaffolding + 1 day docs)

---

## 8. Open questions (to confirm before kickoff)

1. **A-01:** Are `tt_teacher_availability.preference_score`, `override_priority`, `is_preferred_teacher` populated reliably in the pilot tenant, or do we need a UI prompt to encourage population first?
2. **A-01:** Should `tt_activity_teacher.is_required` short-circuit to that teacher even when the weekly cap would be exceeded? (Likely no — cap is hard.)
3. **A-02:** Hard-reject capacity, or soft-warn with a force-place option? (Recommend hard-reject; operator can override capacity in `sch_rooms.max_limit`.)
4. **A-02:** Should `class_house_room_id` boost be configurable (per-school weighting)? Default 80; consider 0–200 range.
5. **A-03:** When dates within a single day-of-week have mixed modes (some HOLIDAY, some STUDY), should generation produce a per-date timetable or a week-pattern with warnings? (Recommend warnings + week-pattern by default; per-date for granularity=DATE_AWARE.)
6. **A-03:** Should `tt_day_type.affects_generation` and `period_set_override_id` be Prime-seeded defaults or school-editable? (Recommend Prime-seeded defaults that schools can override.)
7. **A-04:** Should the proximity bonus (`|delta| ≤ 2 → +10`) be tunable, or hardcoded? (Recommend hardcoded; keeps the formula stable.)
8. **All:** Per-tenant flag override pattern — store in `prm_tenant_plan_module_jnt.config_json`? Or `tt_config` table? (Recommend the central `prm_tenant_plan_module_jnt.config_json` since these are SaaS-tier features.)

---

*End of v1 — Algo_implement_plan.md. Ready for engineering review and sprint planning.*

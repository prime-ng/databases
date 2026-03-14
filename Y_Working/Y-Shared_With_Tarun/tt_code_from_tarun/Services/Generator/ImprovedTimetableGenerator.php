<?php

namespace Modules\SmartTimetable\Services\Generator;

use Illuminate\Support\Collection;
use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Constraints\ConstraintManager;
use Modules\SmartTimetable\Services\Solver\Slot;

class ImprovedTimetableGenerator
{
    protected array $occupied = [];
    protected array $teacherOccupied = [];
    protected array $entries = [];
    protected array $activityPlacements = [];
    protected ConstraintManager $constraintManager;
    protected array $activitiesById = [];

    // Cache teaching periods indices
    protected array $teachingIndices = [];
    protected array $teachingPeriods = [];

    // Stats tracking
    protected array $stats = [
        'activities' => 0,
        'total_periods_needed' => 0,
        'periods_placed' => 0,
        'slot_evaluations' => 0,
        'constraint_checks' => 0,
        'generation_time' => 0,
        'max_attempts_exceeded' => 0,
        'activities_with_no_slots' => 0,
        'activities_partially_placed' => 0,
        'activities_fully_placed' => 0,
    ];

    public function __construct(
        protected Collection $days,
        protected Collection $periods,
        ConstraintManager $constraintManager = null
    ) {
        $this->days = $days->values();
        $this->periods = $periods->values();

        // Pre-calculate teaching periods (skip breaks)
        $this->calculateTeachingPeriods();

        $this->constraintManager = $constraintManager ?? $this->createDefaultConstraintManager();
    }

    /**
     * Calculate teaching periods (skip SBREAK and LUNCH)
     */
    protected function calculateTeachingPeriods(): void
    {
        $this->teachingIndices = [];
        $this->teachingPeriods = [];

        foreach ($this->periods as $index => $period) {
            if (!in_array($period->code, ['SBREAK', 'LUNCH'])) {
                $this->teachingIndices[] = $index;
                $this->teachingPeriods[] = $period;
            }
        }

        \Log::info('Teaching periods calculated', [
            'total_periods' => $this->periods->count(),
            'teaching_periods' => count($this->teachingIndices),
            'break_periods' => $this->periods->count() - count($this->teachingIndices),
            'teaching_indices' => $this->teachingIndices,
        ]);
    }

    /* ============================================================
     |  MAIN GENERATION METHOD
     * ============================================================ */

    public function generate(Collection $activities)
    {

        $startTime = microtime(true);

        $this->stats['started_at'] = now()->toDateTimeString();

        $this->activitiesById = $activities->keyBy('id')->all();

        $startTime = microtime(true);

        $this->resetState();

        // // Check capacity first
        // if (!$this->checkCapacity($activities)) {
        //     \Log::error("Schedule mathematically impossible!");
        //     return [];
        // }

        $this->stats['activities'] = $activities->count();
        $this->stats['total_periods_needed'] = $activities->sum('weekly_periods');

        \Log::info('=== GENERATION START ===', [
            'activities' => $activities->count(),
            'total_periods_needed' => $this->stats['total_periods_needed'],
            'days' => $this->days->count(),
            'total_periods' => $this->periods->count(),
            'teaching_periods_per_day' => count($this->teachingIndices),
            'total_teaching_slots_available' => $this->days->count() * count($this->teachingIndices),
        ]);

        // 1. Sort activities by difficulty
        $sortedActivities = $this->sortByPlacementDifficulty($activities);

        // 2. Place activities (each needs multiple periods)
        foreach ($sortedActivities as $index => $activity) {
            \Log::info("Processing activity {$index}/{$this->stats['activities']}", [
                'activity_id' => $activity->id,
                'class' => $activity->classGroupJnt->class->code ?? 'N/A',
                'section' => $activity->classGroupJnt->section->code ?? 'N/A',
                'weekly_periods' => $activity->weekly_periods,
                'duration_periods' => $activity->duration_periods,
                'teachers_count' => count($activity->activityTeachers ?? []),
            ]);

            $this->placeActivityWithMultiplePeriods($activity);
        }

        // 3. Record final stats
        $this->stats['generation_time'] = microtime(true) - $startTime;
        $this->stats['periods_placed'] = count($this->entries);

        $coverage = $this->stats['total_periods_needed'] > 0
            ? round(($this->stats['periods_placed'] / $this->stats['total_periods_needed']) * 100, 2)
            : 0;

        $this->stats['coverage_percentage'] = $coverage;

        \Log::info('=== GENERATION COMPLETE ===', $this->stats);

        // Log detailed placement summary
        $this->logPlacementSummary($activities);

        $this->stats['finished_at'] = now()->toDateTimeString();
        $this->stats['max_attempts'] = 200;

        return $this->entries;
    }

    protected function placeActivityWithMultiplePeriods(Activity $activity): void
    {
        $periodsNeeded = $activity->weekly_periods;
        $periodsPlaced = 0;
        $maxAttempts = 2000;
        $attempts = 0;
        $backoffCounter = 0;

        $classKey = $this->getClassKey($activity);

        \Log::info("START placing activity {$activity->id}", [
            'class_key' => $classKey,
            'periods_needed' => $periodsNeeded,
            'duration_per_period' => $activity->duration_periods,
        ]);

        while ($periodsPlaced < $periodsNeeded && $attempts < $maxAttempts) {
            // Find a slot
            $slot = $this->findCandidateSlot($activity);

            if ($slot && $this->canPlaceActivity($activity, $slot)) {
                // Place the activity
                $this->commitPlacement($activity, $slot);
                $periodsPlaced += $activity->duration_periods;
                $attempts = 0;
                $backoffCounter = 0;

                \Log::info("✅ Placed period for activity {$activity->id}", [
                    'periods_placed' => $periodsPlaced,
                    'periods_needed' => $periodsNeeded,
                    'slot_day' => $slot->dayId,
                    'slot_start' => $slot->startIndex,
                ]);
            } else {
                $attempts++;
                $backoffCounter++;

                // Every 50 attempts, try a different strategy
                if ($backoffCounter >= 50) {
                    \Log::warning("Backoff for activity {$activity->id}", [
                        'attempts' => $attempts,
                        'periods_placed' => $periodsPlaced,
                        'backoff_counter' => $backoffCounter,
                    ]);

                    // Reset backoff counter
                    $backoffCounter = 0;

                    // Maybe skip this activity temporarily and come back
                    if ($attempts > 100) {
                        \Log::warning("Skipping activity {$activity->id} temporarily", [
                            'activity_id' => $activity->id,
                            'periods_placed' => $periodsPlaced,
                        ]);
                        break;
                    }
                }
            }
        }

        // Update stats
        if ($periodsPlaced === 0) {
            $this->stats['activities_with_no_slots']++;
            \Log::error("❌ NO periods placed for activity {$activity->id}", [
                'periods_needed' => $periodsNeeded,
                'attempts' => $attempts,
            ]);
        } elseif ($periodsPlaced < $periodsNeeded) {
            $this->stats['activities_partially_placed']++;
            \Log::warning("⚠️ PARTIALLY placed activity {$activity->id}", [
                'periods_placed' => $periodsPlaced,
                'periods_needed' => $periodsNeeded,
                'percentage' => round(($periodsPlaced / $periodsNeeded) * 100, 2) . '%',
            ]);
        } else {
            $this->stats['activities_fully_placed']++;
            \Log::info("✅ FULLY placed activity {$activity->id}", [
                'periods_placed' => $periodsPlaced,
            ]);
        }
    }

    /* ============================================================
     |  IMPROVED SLOT FINDING - TEACHING PERIODS ONLY
     * ============================================================ */
    protected function findCandidateSlot(Activity $activity): ?Slot
    {
        $classKey = $this->getClassKey($activity);

        // Use teaching periods only
        $maxTeachingStart = count($this->teachingIndices) - $activity->duration_periods;

        if ($maxTeachingStart < 0) {
            \Log::error("Activity duration too long", [
                'activity_id' => $activity->id,
                'duration' => $activity->duration_periods,
                'available_teaching_periods' => count($this->teachingIndices),
            ]);
            return null;
        }

        // Try ALL days
        $days = $this->getSortedDaysByLoad($classKey);

        foreach ($days as $day) {
            // Generate possible start positions in TEACHING periods
            $teachingStartPositions = $this->getTeachingStartPositions($maxTeachingStart);

            foreach ($teachingStartPositions as $teachingStartIndex) {
                // Convert teaching index to actual period index
                $actualStartIndex = $this->teachingToActualIndex($teachingStartIndex);

                // Verify this is a valid teaching slot
                if (!$this->isTeachingSlot($actualStartIndex, $activity->duration_periods)) {
                    continue;
                }

                // REMARK :: check if activity preferred/avoid period is $this ????
                // REMARK :: IF Class teacher period has to be first or not ??? 

                $slot = new Slot($classKey, $day->id, $actualStartIndex);

                // Quick availability check
                if ($this->isSlotAvailable($slot, $activity)) {
                    \Log::debug("Found available slot", [
                        'day' => $day->id,
                        'teaching_index' => $teachingStartIndex,
                        'actual_index' => $actualStartIndex,
                        'duration' => $activity->duration_periods,
                    ]);
                    return $slot;
                }
                $this->stats['slot_evaluations']++;
            }
        }

        \Log::warning("No available slot found for {$classKey}", [
            'activity_id' => $activity->id,
            'duration' => $activity->duration_periods,
        ]);

        return null;
    }

    /**
     * Convert teaching period index to actual period index
     */
    protected function teachingToActualIndex(int $teachingIndex): int
    {
        if (isset($this->teachingIndices[$teachingIndex])) {
            return $this->teachingIndices[$teachingIndex];
        }

        \Log::error("Invalid teaching index", [
            'teaching_index' => $teachingIndex,
            'teaching_indices' => $this->teachingIndices,
        ]);

        return -1;
    }

    /**
     * Check if slot is in teaching periods only (not breaks)
     */
    protected function isTeachingSlot(int $startIndex, int $duration): bool
    {
        for ($i = 0; $i < $duration; $i++) {
            $periodIndex = $startIndex + $i;

            if ($periodIndex >= $this->periods->count()) {
                return false;
            }

            $period = $this->periods[$periodIndex];
            if (in_array($period->code, ['SBREAK', 'LUNCH'])) {
                return false;
            }
        }

        return true;
    }

    /**
     * Count teaching periods on a specific day for a class
     */
    protected function countTeachingPeriodsOnDay(string $classKey, int $dayId): int
    {
        $count = 0;

        if (isset($this->occupied[$classKey][$dayId])) {
            foreach ($this->occupied[$classKey][$dayId] as $periodId => $occupied) {
                // Only count if it's a teaching period
                $periodIndex = $this->getPeriodIndexById($periodId);
                if ($periodIndex !== null && $this->isTeachingPeriod($periodIndex)) {
                    $count++;
                }
            }
        }

        return $count;
    }

    /**
     * Check if a period index is a teaching period
     */
    protected function isTeachingPeriod(int $periodIndex): bool
    {
        if (!isset($this->periods[$periodIndex])) {
            return false;
        }

        $period = $this->periods[$periodIndex];
        return !in_array($period->code, ['SBREAK', 'LUNCH']);
    }

    /**
     * Get period index by ID
     */
    protected function getPeriodIndexById(int $periodId): ?int
    {
        foreach ($this->periods as $index => $period) {
            if ($period->id == $periodId) {
                return $index;
            }
        }
        return null;
    }

    protected function getTeachingStartPositions(int $maxTeachingStart): array
    {
        // Try ALL positions
        $positions = range(0, $maxTeachingStart);

        // Shuffle to avoid patterns
        shuffle($positions);

        return $positions;
    }
    /**
     * Check if schedule is mathematically possible
     */
    protected function checkCapacity(Collection $activities): bool
    {
        $totalPeriodsNeeded = $activities->sum('weekly_periods');
        $totalTeachingSlots = $this->days->count() * count($this->teachingIndices);
        ;

        \Log::info("Capacity Check", [
            'total_periods_needed' => $totalPeriodsNeeded,
            'total_teaching_slots' => $totalTeachingSlots,
            'days' => $this->days->count(),
            'teaching_periods_per_day' => count($this->teachingIndices),
            'is_possible' => $totalPeriodsNeeded <= $totalTeachingSlots,
        ]);

        return $totalPeriodsNeeded <= $totalTeachingSlots;
    }

    protected function isSlotAvailable(Slot $slot, Activity $activity): bool
    {
        $classKey = $slot->classKey;

        // First check if this is a teaching slot (not break)
        if (!$this->isTeachingSlot($slot->startIndex, $activity->duration_periods)) {
            \Log::debug("Slot is not a teaching slot", [
                'start_index' => $slot->startIndex,
                'duration' => $activity->duration_periods,
            ]);
            return false;
        }

        // Then check if all required periods are free
        for ($i = 0; $i < $activity->duration_periods; $i++) {
            $periodIndex = $slot->startIndex + $i;

            // Check bounds
            if ($periodIndex >= $this->periods->count()) {
                return false;
            }

            $periodId = $this->periods[$periodIndex]->id;

            // Check if period is occupied for this class
            if (isset($this->occupied[$classKey][$slot->dayId][$periodId])) {
                return false;
            }
        }

        return true;
    }

    protected function canPlaceActivity(Activity $activity, Slot $slot): bool
    {
        $this->stats['constraint_checks']++;

        // $context = (object) [
        //     'periods' => $this->periods,
        //     'occupied' => $this->occupied,
        //     'teacherOccupied' => $this->teacherOccupied,
        //     'entries' => $this->entries,
        // ];
        $context = (object) [
            'periods' => $this->periods,
            'occupied' => $this->occupied,
            'teacherOccupied' => $this->teacherOccupied,
            'entries' => $this->entries,
            'activitiesById' => $this->activitiesById, // ✅ ADD THIS
        ];

        $canPlace = $this->constraintManager->checkHardConstraints($slot, $activity, $context);

        if (!$canPlace) {
            \Log::debug("Constraint failed for activity {$activity->id}", [
                'slot' => ['day' => $slot->dayId, 'start' => $slot->startIndex],
            ]);
        }

        return $canPlace;
    }

    protected function commitPlacement(Activity $activity, Slot $slot): void
    {
        $classKey = $slot->classKey;

        // Place for each period of the activity duration
        for ($i = 0; $i < $activity->duration_periods; $i++) {
            $periodIndex = $slot->startIndex + $i;

            // Safety check
            if ($periodIndex >= $this->periods->count()) {
                \Log::error('Period index out of bounds', [
                    'activity_id' => $activity->id,
                    'period_index' => $periodIndex,
                    'total_periods' => $this->periods->count(),
                ]);
                continue;
            }

            $periodId = $this->periods[$periodIndex]->id;

            // Mark as occupied for this class
            $this->occupied[$classKey][$slot->dayId][$periodId] = true;

            // Mark as occupied for teachers
            foreach ($activity->activityTeachers ?? [] as $teacher) {
                $this->teacherOccupied[$teacher->teacher_id][$slot->dayId][$periodId] = true;
            }

            // Add to entries
            $this->entries[] = [
                'day_id' => $slot->dayId,
                'period_id' => $periodId,
                'activity_id' => $activity->id,
                'class_group_jnt_id' => $activity->class_group_jnt_id,
            ];
        }

        // Track this placement
        if (!isset($this->activityPlacements[$activity->id])) {
            $this->activityPlacements[$activity->id] = [];
        }
        $this->activityPlacements[$activity->id][] = $slot;
    }

    /* ============================================================
     |  HELPER METHODS
     * ============================================================ */
    protected function countPeriodsForClass(string $classKey): int
    {
        $total = 0;
        foreach ($this->occupied[$classKey] ?? [] as $day => $periods) {
            $total += count($periods);
        }
        return $total;
    }

    protected function getSortedDaysByLoad(string $classKey): array
    {
        $days = $this->days->all();

        // Sort days by current teaching load (ascending - least loaded first)
        usort($days, function ($a, $b) use ($classKey) {
            $loadA = $this->countTeachingPeriodsOnDay($classKey, $a->id);
            $loadB = $this->countTeachingPeriodsOnDay($classKey, $b->id);
            return $loadA <=> $loadB;
        });

        return $days;
    }

    protected function sortByPlacementDifficulty(Collection $activities): Collection
    {
        return $activities->sortByDesc(function ($activity) {
            $difficulty = 0;

            // More periods = more difficult
            $difficulty += $activity->weekly_periods * 5;

            // Longer duration = more difficult
            $difficulty += $activity->duration_periods * 3;

            // More teachers = more difficult
            $difficulty += count($activity->activityTeachers ?? []) * 2;

            // Higher priority = place earlier
            $difficulty += $activity->priority;

            // Compulsory = place earlier
            $difficulty += $activity->is_compulsory ? 20 : 0;

            return $difficulty;
        })->values();
    }

    protected function getClassKey(Activity $activity): string
    {
        if (!$activity->classGroupJnt) {
            \Log::error('Missing classGroupJnt for activity', ['activity_id' => $activity->id]);
            return 'unknown-unknown';
        }

        $classCode = $activity->classGroupJnt->class->code ?? 'unknown';
        $sectionCode = $activity->classGroupJnt->section->code ?? 'unknown';

        return $classCode . '-' . $sectionCode;
    }

    protected function resetState(): void
    {
        $this->occupied = [];
        $this->teacherOccupied = [];
        $this->entries = [];
        $this->activityPlacements = [];
        $this->stats = [
            'activities' => 0,
            'total_periods_needed' => 0,
            'periods_placed' => 0,
            'slot_evaluations' => 0,
            'constraint_checks' => 0,
            'generation_time' => 0,
            'max_attempts_exceeded' => 0,
            'activities_with_no_slots' => 0,
            'activities_partially_placed' => 0,
            'activities_fully_placed' => 0,
            'coverage_percentage' => 0,
        ];
    }

    protected function createDefaultConstraintManager(): ConstraintManager
    {
        $manager = new ConstraintManager();

        // TEMPORARILY COMMENT OUT ALL CONSTRAINTS for debugging
        // $manager->addConstraint(new \Modules\SmartTimetable\Services\Constraints\Hard\ShortBreakConstraint());

        return $manager;
    }

    /* ============================================================
     |  LOGGING METHODS
     * ============================================================ */
    protected function logPlacementSummary(Collection $activities): void
    {
        $summary = [];

        foreach ($activities as $activity) {
            $activityId = $activity->id;
            $periodsNeeded = $activity->weekly_periods;
            $periodsPlaced = count(array_filter($this->entries, fn($e) => $e['activity_id'] == $activityId));

            $summary[] = [
                'activity_id' => $activityId,
                'class' => $activity->classGroupJnt->class->code ?? 'N/A',
                'section' => $activity->classGroupJnt->section->code ?? 'N/A',
                'periods_needed' => $periodsNeeded,
                'periods_placed' => $periodsPlaced,
                'status' => $periodsPlaced >= $periodsNeeded ? 'FULL' :
                    ($periodsPlaced > 0 ? 'PARTIAL' : 'NONE'),
            ];
        }

        \Log::info('Placement Summary:', $summary);
    }

    public function getStats(): array
    {
        return $this->stats;
    }

    /**
     * Get teaching periods for debugging
     */
    public function getTeachingPeriodsInfo(): array
    {
        return [
            'teaching_indices' => $this->teachingIndices,
            'teaching_periods_count' => count($this->teachingIndices),
            'break_periods_count' => $this->periods->count() - count($this->teachingIndices),
        ];
    }
}
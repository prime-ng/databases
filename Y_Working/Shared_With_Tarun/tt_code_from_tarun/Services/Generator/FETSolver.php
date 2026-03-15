<?php
// File: Modules/SmartTimetable/Services/Generator/FETSolver.php

namespace Modules\SmartTimetable\Services\Generator;

use Illuminate\Support\Collection;
use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Constraints\ConstraintManager;
use Modules\SmartTimetable\Services\Solver\Slot;
use Modules\SmartTimetable\Services\Solver\TimetableSolution;

class FETSolver
{
    private Collection $days;
    private Collection $periods;
    private array $teachingIndices = [];

    private ConstraintManager $constraintManager;

    // Statistics
    private array $stats = [
        'activities' => 0,
        'total_periods_needed' => 0,
        'periods_placed' => 0,
        'slot_evaluations' => 0,
        'constraint_checks' => 0, // Track constraint checks
        'constraint_violations' => 0, // Track violations
        'generation_time' => 0,
        'max_attempts_exceeded' => 0,
        'activities_with_no_slots' => 0,
        'activities_partially_placed' => 0,
        'activities_fully_placed' => 0,
        'coverage_percentage' => 0,
        'started_at' => null,
        'finished_at' => null,
        'max_attempts' => 200,
    ];

    private array $fetStats = [
        'iterations' => 0,
        'backtracks' => 0,
    ];

    private array $config = [
        'max_iterations' => 50000,
        'max_backtracks' => 5000,
    ];

    // UPDATE CONSTRUCTOR: Accept ConstraintManager
    public function __construct(
        Collection $days,
        Collection $periods,
        ConstraintManager $constraintManager = null
    ) {
        $this->days = $days;
        $this->periods = $periods;

        // Use provided constraint manager or create empty one
        $this->constraintManager = $constraintManager ?? new ConstraintManager();

        $this->calculateTeachingPeriods();

        \Log::info('FET Solver initialized', [
            'constraints_loaded' => count($this->constraintManager->getHardConstraints()) +
                count($this->constraintManager->getSoftConstraints()),
            'hard_constraints' => count($this->constraintManager->getHardConstraints()),
            'soft_constraints' => count($this->constraintManager->getSoftConstraints()),
        ]);
    }

    /**
     * Main solving method - returns entries for ALL weekly periods
     */
    public function solve(Collection $activities): array
    {

        $startTime = microtime(true);

        $this->stats['started_at'] = now()->toDateTimeString();
        $this->stats['activities'] = $activities->count();
        $this->stats['total_periods_needed'] = $activities->sum('weekly_periods');

        \Log::info('=== FET SOLVER START ===', [
            'activities' => $this->stats['activities'],
            'total_periods_needed' => $this->stats['total_periods_needed'],
            'days' => $this->days->count(),
            'teaching_periods_per_day' => count($this->teachingIndices),
            'total_teaching_slots' => $this->days->count() * count($this->teachingIndices),
            'constraints_enabled' => count($this->constraintManager->getHardConstraints()) > 0,
        ]);

        $context = $this->createConstraintContext($activities);
        //dd($context);

        // expand activities i.e $expandedActivity = $activity->weekly_peridos X $activty->periods_duration 
        $expandedActivities = $this->expandActivitiesByWeeklyPeriods($activities);

        \Log::info('Activities expanded', [
            'original_activities' => $activities->count(),
            'expanded_instances' => count($expandedActivities),
            'total_instances_needed' => $this->stats['total_periods_needed'],
        ]);

        // PHASE 1: Generate solution WITH constraints
        $solution = $this->generateInitialSolution($expandedActivities, $context);

        // PHASE 2: Convert to entries
        $entries = $this->convertSolutionToEntries($solution, $activities);

        // Calculate statistics
        $this->stats['periods_placed'] = count($entries);
        $this->stats['generation_time'] = microtime(true) - $startTime;
        $this->stats['finished_at'] = now()->toDateTimeString();

        // Calculate coverage percentage
        $coverage = $this->stats['total_periods_needed'] > 0
            ? round(($this->stats['periods_placed'] / $this->stats['total_periods_needed']) * 100, 2)
            : 0;

        $this->stats['coverage_percentage'] = $coverage;

        // Calculate activity placement stats
        $this->calculateActivityPlacementStats($activities, $entries);

        \Log::info('=== FET SOLVER COMPLETE ===', $this->stats);

        return $entries;
    }

    /**
     * Create context for constraint checking
     */
    private function createConstraintContext(Collection $activities): \stdClass
    {
        $activitiesById = $activities->keyBy('id')->all();

        return (object) [
            'periods' => $this->periods,
            'occupied' => [], // Will be populated during generation
            'teacherOccupied' => [], // Will be populated during generation
            'entries' => [], // Will be populated during generation
            'activitiesById' => $activitiesById,
            'days' => $this->days,
            'teachingIndices' => $this->teachingIndices,
        ];
    }

    /**
     * CRITICAL: Expand each activity into multiple instances based on weekly_periods
     * Example: Math with weekly_periods=5 → 5 separate instances to place
     */
    private function expandActivitiesByWeeklyPeriods(Collection $activities): array
    {
        // here we are expandin the activites i.e activiteis X weekly_periods
        $expanded = [];

        foreach ($activities as $activity) {
            $weeklyPeriods = $activity->weekly_periods;
            $duration = $activity->duration_periods;

            // Create a separate instance for each weekly period needed
            for ($i = 1; $i <= $weeklyPeriods; $i++) {
                // Clone the activity but give it a unique identifier
                $instance = clone $activity;
                $instance->instance_id = $activity->id . '-' . $i; // e.g., "1-1", "1-2", etc.
                $instance->instance_number = $i;
                $instance->original_activity_id = $activity->id;
                $instance->duration_periods = $duration; // Keep original duration
                $instance->needs_placement = true;

                $expanded[] = $instance;
            }
        }

        // Shuffle to avoid patterns IMPORTANT...
        shuffle($expanded);

        return $expanded;
    }

    /**
     * Convert solution to entries array
     */
    private function convertSolutionToEntries(TimetableSolution $solution, Collection $originalActivities): array
    {
        $entries = [];
        $placements = $solution->getPlacements();

        foreach ($placements as $instanceId => $slots) {
            // Extract original activity ID from instance ID (e.g., "1-2" → 1)
            $parts = explode('-', $instanceId);
            $originalActivityId = $parts[0] ?? $instanceId;

            $activity = $originalActivities->firstWhere('id', $originalActivityId);
            if (!$activity) {
                continue;
            }

            foreach ($slots as $slot) {
                $duration = $activity->duration_periods;

                // Create one entry for EACH period of the duration
                for ($i = 0; $i < $duration; $i++) {
                    $periodIndex = $slot->startIndex + $i;

                    if ($periodIndex >= $this->periods->count()) {
                        continue;
                    }

                    $period = $this->periods[$periodIndex];

                    $entries[] = [
                        'day_id' => $slot->dayId,
                        'period_id' => $period->id,
                        'activity_id' => $originalActivityId,
                        'class_group_jnt_id' => $activity->class_group_jnt_id,
                        // Note: Same format as your current generator
                    ];
                }
            }
        }

        return $entries;
    }

    /**
     * Calculate activity placement statistics
     */
    private function calculateActivityPlacementStats(Collection $activities, array $entries): void
    {
        // Group entries by activity_id to count placed periods per activity
        $periodsPlacedByActivity = [];
        foreach ($entries as $entry) {
            $activityId = $entry['activity_id'];
            if (!isset($periodsPlacedByActivity[$activityId])) {
                $periodsPlacedByActivity[$activityId] = 0;
            }
            $periodsPlacedByActivity[$activityId]++;
        }

        $fullyPlaced = 0;
        $partiallyPlaced = 0;
        $noSlots = 0;

        foreach ($activities as $activity) {
            $activityId = $activity->id;
            $periodsNeeded = $activity->weekly_periods;
            $periodsPlaced = $periodsPlacedByActivity[$activityId] ?? 0;

            if ($periodsPlaced === 0) {
                $noSlots++;
                \Log::warning('Activity not placed', [
                    'activity_id' => $activityId,
                    'periods_needed' => $periodsNeeded,
                    'periods_placed' => $periodsPlaced,
                ]);
            } elseif ($periodsPlaced < $periodsNeeded) {
                $partiallyPlaced++;
                \Log::warning('Activity partially placed', [
                    'activity_id' => $activityId,
                    'periods_needed' => $periodsNeeded,
                    'periods_placed' => $periodsPlaced,
                    'percentage' => round(($periodsPlaced / $periodsNeeded) * 100, 2) . '%',
                ]);
            } else {
                $fullyPlaced++;
            }
        }

        $this->stats['activities_with_no_slots'] = $noSlots;
        $this->stats['activities_partially_placed'] = $partiallyPlaced;
        $this->stats['activities_fully_placed'] = $fullyPlaced;
    }

    /**
     * Generate initial solution using backtracking
     */


    /**
     * Backtracking algorithm
     */
    private function backtrack(array $activities, int $index, TimetableSolution $solution, $context): bool
    {
        $this->fetStats['iterations']++;

        // Safety limits
        if ($this->fetStats['iterations'] > $this->config['max_iterations']) {
            \Log::warning('FET: Max iterations reached', ['iterations' => $this->fetStats['iterations']]);
            return false;
        }

        // All activities placed
        if ($index >= count($activities)) {
            return true;
        }

        $activity = $activities[$index];
        $possibleSlots = $this->getPossibleSlots($activity, $solution, $context);

        if (empty($possibleSlots)) {
            return false;
        }

        // Try each slot
        foreach ($possibleSlots as $slot) {
            // Check constraints BEFORE placing
            if ($this->canPlaceWithConstraints($activity, $slot, $context)) {
                // Temporarily update context to simulate placement
                $tempContext = $this->simulatePlacement($activity, $slot, clone $context);

                if ($solution->place($activity, $slot)) {
                    // Track slot evaluations
                    $this->stats['slot_evaluations']++;

                    // Recursively try next activity
                    if ($this->backtrack($activities, $index + 1, $solution, $tempContext)) {
                        return true;
                    }

                    // Backtrack
                    $solution->remove($activity, $slot);
                    $this->fetStats['backtracks']++;

                    if ($this->fetStats['backtracks'] > $this->config['max_backtracks']) {
                        \Log::warning('FET: Max backtracks reached', ['backtracks' => $this->fetStats['backtracks']]);
                        return false;
                    }
                }
            }
        }

        return false;
    }

    /**
     * Check if activity can be placed considering ALL constraints
     */
    private function canPlaceWithConstraints($activity, Slot $slot, $context): bool
    {
        $this->stats['constraint_checks']++;

        // First check basic availability (class and teacher conflicts)
        if (!$this->isBasicSlotAvailable($activity, $slot, $context)) {
            return false;
        }

        // Then check all hard constraints
        try {
            $canPlace = $this->constraintManager->checkHardConstraints($slot, $activity, $context);

            if (!$canPlace) {
                $this->stats['constraint_violations']++;
                \Log::debug('Constraint violation', [
                    'activity_id' => $activity->id ?? $activity->original_activity_id ?? 'unknown',
                    'slot' => ['day' => $slot->dayId, 'start' => $slot->startIndex],
                    'class_key' => $slot->classKey,
                ]);
            }

            return $canPlace;

        } catch (\Exception $e) {
            \Log::error('Constraint check failed', [
                'error' => $e->getMessage(),
                'activity_id' => $activity->id ?? 'unknown',
                'slot' => $slot,
            ]);
            return false;
        }
    }

    /**
     * Basic slot availability check (without constraints)
     */
    private function isBasicSlotAvailable($activity, Slot $slot, $context): bool
    {
        $classKey = $slot->classKey;
        $duration = $activity->duration_periods;

        // Check each period
        for ($i = 0; $i < $duration; $i++) {
            $periodIndex = $slot->startIndex + $i;

            // Check bounds
            if ($periodIndex >= $this->periods->count()) {
                return false;
            }

            $period = $this->periods[$periodIndex];
            $periodId = $period->id;

            // Check if class is already occupied in context
            if (isset($context->occupied[$classKey][$slot->dayId][$periodId])) {
                return false;
            }

            // Check if any teacher is already occupied
            if ($activity->activityTeachers) {
                foreach ($activity->activityTeachers as $teacher) {
                    $teacherId = $teacher->teacher_id ?? $teacher->id;
                    if (isset($context->teacherOccupied[$teacherId][$slot->dayId][$periodId])) {
                        return false;
                    }
                }
            }
        }

        return true;
    }

    /**
     * Simulate placement for constraint propagation
     */
    private function simulatePlacement($activity, Slot $slot, $context): \stdClass
    {
        $classKey = $slot->classKey;
        $duration = $activity->duration_periods;

        // Update occupied slots in context
        for ($i = 0; $i < $duration; $i++) {
            $periodIndex = $slot->startIndex + $i;
            $period = $this->periods[$periodIndex];
            $periodId = $period->id;

            // Mark class occupied
            $context->occupied[$classKey][$slot->dayId][$periodId] =
                $activity->instance_id ?? $activity->id;

            // Mark teachers occupied
            if ($activity->activityTeachers) {
                foreach ($activity->activityTeachers as $teacher) {
                    $teacherId = $teacher->teacher_id ?? $teacher->id;
                    $context->teacherOccupied[$teacherId][$slot->dayId][$periodId] =
                        $activity->instance_id ?? $activity->id;
                }
            }
        }

        return $context;
    }

    /**
     * Get all possible slots for an activity instance
     */
    /**
     * Get all possible slots WITH constraint pre-checking
     */
    private function getPossibleSlots($activity, TimetableSolution $solution, $context): array
    {
        $slots = [];
        $duration = $activity->duration_periods;
        $classKey = $this->getClassKey($activity);

        foreach ($this->days as $day) {
            $maxStart = count($this->teachingIndices) - $duration;

            if ($maxStart < 0) {
                continue;
            }

            for ($teachingStart = 0; $teachingStart <= $maxStart; $teachingStart++) {
                $actualStart = $this->teachingToActualIndex($teachingStart);

                if ($actualStart < 0) {
                    continue;
                }

                if (!$this->isTeachingSlot($actualStart, $duration)) {
                    continue;
                }

                $slot = new Slot($classKey, $day->id, $actualStart);

                // Check basic availability first (fast check)
                if (!$this->isBasicSlotAvailable($activity, $slot, $context)) {
                    continue;
                }

                // Check solution availability
                if ($solution->canPlace($activity, $slot)) {
                    $slots[] = $slot;
                }
            }
        }

        // Shuffle to avoid patterns
        shuffle($slots);

        return $slots;
    }

    /**
     * Generate initial solution with constraints
     */
    private function generateInitialSolution(array $expandedActivities, $context): TimetableSolution
    {
        // Order activities by difficulty
        $orderedActivities = $this->orderActivitiesByDifficulty($expandedActivities);

        // Create empty solution
        $solution = new TimetableSolution($this->days, $this->periods);

        // Try backtracking WITH constraints
        if ($this->backtrack($orderedActivities, 0, $solution, $context)) {
            \Log::info('FET: Backtracking solution found', [
                'activity_instances_placed' => $solution->getActivitiesPlaced(),
                'total_instances' => count($expandedActivities),
                'backtracks' => $this->fetStats['backtracks'],
                'constraint_checks' => $this->stats['constraint_checks'],
                'constraint_violations' => $this->stats['constraint_violations'],
            ]);
            return $solution;
        }

        // Fallback to greedy WITH constraints
        \Log::warning('FET: Backtracking failed, using greedy fallback');
        return $this->generateGreedySolution($orderedActivities, $context);
    }

    /**
     * Greedy solution as fallback
     */
    private function generateGreedySolution(array $activities, $context): TimetableSolution
    {
        $solution = new TimetableSolution($this->days, $this->periods);
        $placed = 0;

        foreach ($activities as $activity) {
            $slots = $this->getPossibleSlots($activity, $solution, $context);

            foreach ($slots as $slot) {
                // Check constraints before placing
                if ($this->canPlaceWithConstraints($activity, $slot, $context)) {
                    if ($solution->place($activity, $slot)) {
                        $this->stats['slot_evaluations']++;

                        // Update context for next iterations
                        $context = $this->simulatePlacement($activity, $slot, $context);
                        $placed++;
                        break;
                    }
                }
            }
        }

        \Log::info('Greedy solution generated', [
            'activity_instances_total' => count($activities),
            'activity_instances_placed' => $placed,
            'constraint_checks' => $this->stats['constraint_checks'],
        ]);

        return $solution;
    }

    /**
     * Order activities by difficulty
     */
    private function orderActivitiesByDifficulty(array $activities): array
    {
        $scoredActivities = [];

        foreach ($activities as $activity) {
            $score = 0;

            // Longer duration = more difficult
            $score += $activity->duration_periods * 3;

            // More teachers = more difficult
            $teachersCount = count($activity->activityTeachers ?? []);
            $score += $teachersCount * 2;

            // Compulsory = higher priority
            if ($activity->is_compulsory) {
                $score += 20;
            }

            $scoredActivities[] = [
                'activity' => $activity,
                'score' => $score,
            ];
        }

        // Sort by score descending (most difficult first)
        usort($scoredActivities, function ($a, $b) {
            return $b['score'] <=> $a['score'];
        });

        return array_column($scoredActivities, 'activity');
    }

    /**
     * Get class key from activity
     */
    private function getClassKey($activity): string
    {
        if (!$activity->classGroupJnt) {
            return 'unknown-unknown';
        }

        $classCode = $activity->classGroupJnt->class->code ?? 'unknown';
        $sectionCode = $activity->classGroupJnt->section->code ?? 'unknown';

        return $classCode . '-' . $sectionCode;
    }

    /**
     * Calculate teaching periods
     */
    private function calculateTeachingPeriods(): void
    {
        $this->teachingIndices = []; // Initialize empty array

        foreach ($this->periods as $index => $period) {
            if (!in_array($period->code, ['SBREAK', 'LUNCH'])) { // Add to initialize array only the working periods
                $this->teachingIndices[] = $index;
            }
        }

        \Log::info('Teaching periods calculated', [
            'total_periods' => $this->periods->count(),
            'teaching_periods' => count($this->teachingIndices),
            'break_periods' => $this->periods->count() - count($this->teachingIndices),
        ]);
    }

    private function teachingToActualIndex(int $teachingIndex): int
    {
        return $this->teachingIndices[$teachingIndex] ?? -1;
    }

    private function isTeachingSlot(int $startIndex, int $duration): bool
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

    public function getStats(): array
    {
        return $this->stats;
    }

    public function getFETStats(): array
    {
        return $this->fetStats;
    }
}
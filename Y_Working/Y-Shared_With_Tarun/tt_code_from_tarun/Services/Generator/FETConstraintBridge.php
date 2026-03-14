<?php
// File: Modules/SmartTimetable/Services/Generator/FETConstraintBridge.php

namespace Modules\SmartTimetable\Services\Generator;

use App\Services\Timetable\Constraints\ConstraintApplication;
use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Solver\Slot;
use Modules\SmartTimetable\Services\Solver\TimetableSolution;

class FETConstraintBridge
{
    private ConstraintApplication $constraintApp;

    public function __construct(ConstraintApplication $constraintApp)
    {
        $this->constraintApp = $constraintApp;
    }

    /**
     * Check if activity can be placed at slot considering ALL constraints
     */
    public function canPlaceActivity(Activity $activity, Slot $slot, TimetableSolution $solution): array
    {
        // Convert to format your ConstraintApplication expects
        $ttActivity = $this->convertToTtActivity($activity);

        // TODO: Get constraints from database
        // For now, return basic check

        return [
            'can_place' => $solution->canPlace($activity, $slot),
            'violations' => [],
            'score' => 0,
        ];
    }

    /**
     * Calculate score for entire solution
     */
    public function calculateConstraintScore(TimetableSolution $solution, Collection $activities): float
    {
        $totalScore = 0.0;

        foreach ($activities as $activity) {
            $placements = $solution->getPlacements()[$activity->id] ?? [];

            foreach ($placements as $slot) {
                $check = $this->canPlaceActivity($activity, $slot, $solution);

                if (!$check['can_place']) {
                    $totalScore += 1000; // Heavy penalty for constraint violation
                }

                $totalScore += $check['score'];
            }
        }

        return $totalScore;
    }

    /**
     * Convert Activity to TtActivity format
     */
    private function convertToTtActivity(Activity $activity): \App\Models\TtActivity
    {
        // This is a simplified conversion
        // You'll need to adapt based on your actual models

        $ttActivity = new \App\Models\TtActivity();

        // Map properties
        $ttActivity->id = $activity->id;
        $ttActivity->class_group_id = $activity->class_group_jnt_id;
        $ttActivity->subject_id = $activity->subject_id ?? null;
        $ttActivity->duration_periods = $activity->duration_periods;

        // Add relations if needed
        // $ttActivity->setRelation('teachers', $activity->activityTeachers);

        return $ttActivity;
    }
}
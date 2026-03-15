<?php

namespace Modules\SmartTimetable\Services;

use Illuminate\Support\Collection;
use Modules\SmartTimetable\Models\Activity;

class ActivityScoreService
{
    /**
     * Recalculate scores for all activities in a batch
     */
    public function recalculateBatch(Collection $activities): void
    {
        foreach ($activities as $activity) {
            $activity->recalculateSmartScores();
        }
    }

    /**
     * Recalculate scores for activities in a specific academic session
     */
    public function recalculateForSession(int $academicSessionId): int
    {
        $activities = Activity::where('academic_session_id', $academicSessionId)
            ->where('is_active', true)
            ->get();

        $this->recalculateBatch($activities);

        return $activities->count();
    }

    /**
     * Get activities sorted by placement difficulty
     */
    public function getActivitiesByDifficulty(int $academicSessionId): Collection
    {
        return Activity::where('academic_session_id', $academicSessionId)
            ->where('is_active', true)
            ->hardestFirst()
            ->get();
    }

    /**
     * Update time preferences from requirements
     */
    public function updateTimePreferences(Activity $activity, array $preferredSlots = [], array $avoidSlots = []): Activity
    {
        $activity->preferred_time_slots_json = $preferredSlots;
        $activity->avoid_time_slots_json = $avoidSlots;
        $activity->save();

        return $activity;
    }

    /**
     * Calculate and update constraint count for an activity
     */
    public function updateConstraintCount(Activity $activity): Activity
    {
        $constraintCount = $this->countConstraintsForActivity($activity);
        $activity->constraint_count = $constraintCount;
        $activity->save();

        return $activity;
    }

    /**
     * Count constraints affecting this activity
     */
    private function countConstraintsForActivity(Activity $activity): int
    {
        // This is a simplified version - you'll need to implement based on your constraint logic
        $count = 0;

        // Check for global constraints
        $count += \Modules\SmartTimetable\Models\Constraint::where('target_type', 'GLOBAL')
            ->where('is_active', true)
            ->count();

        // Check for class-specific constraints
        if ($activity->class_group_jnt_id) {
            $count += \Modules\SmartTimetable\Models\Constraint::where('target_type', 'CLASS_GROUP')
                ->where('target_id', $activity->class_group_jnt_id)
                ->where('is_active', true)
                ->count();
        }

        // Check for teacher-specific constraints
        foreach ($activity->teachers as $teacherAssignment) {
            $count += \Modules\SmartTimetable\Models\Constraint::where('target_type', 'TEACHER')
                ->where('target_id', $teacherAssignment->teacher_id)
                ->where('is_active', true)
                ->count();
        }

        // Check for subject-specific constraints
        if ($activity->subject) {
            $count += \Modules\SmartTimetable\Models\Constraint::where('target_type', 'SUBJECT')
                ->where('target_id', $activity->subject->id)
                ->where('is_active', true)
                ->count();
        }

        return $count;
    }
}
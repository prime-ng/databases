<?php
// File: Modules/SmartTimetable/Services/Constraints/Hard/TeacherConflictConstraint.php

namespace Modules\SmartTimetable\Services\Constraints\Hard;

use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Constraints\TimetableConstraint;
use Modules\SmartTimetable\Services\Solver\Slot;

class TeacherConflictConstraint implements TimetableConstraint
{
    public function passes(Slot $slot, Activity $activity, $context): bool
    {
        // Check if any teacher is already teaching at this time

        if (empty($activity->activityTeachers)) {
            return true; // No teachers assigned, no conflict
        }

        $dayId = $slot->dayId;
        $duration = $activity->duration_periods;

        foreach ($activity->activityTeachers as $teacher) {
            $teacherId = $teacher->teacher_id ?? $teacher->id;

            // Check each period of the activity duration
            for ($i = 0; $i < $duration; $i++) {
                $periodIndex = $slot->startIndex + $i;

                if ($periodIndex >= count($context->periods)) {
                    continue;
                }

                $period = $context->periods[$periodIndex];
                $periodId = $period->id;

                // Check if teacher is already occupied at this time
                if (isset($context->teacherOccupied[$teacherId][$dayId][$periodId])) {
                    // Teacher conflict found!
                    \Log::debug('Teacher conflict detected', [
                        'teacher_id' => $teacherId,
                        'day_id' => $dayId,
                        'period_id' => $periodId,
                        'activity_id' => $activity->id,
                        'conflicting_activity' => $context->teacherOccupied[$teacherId][$dayId][$periodId],
                    ]);
                    return false;
                }
            }
        }

        return true;
    }

    public function getDescription(): string
    {
        return 'Teacher cannot teach two classes at the same time';
    }

    public function getWeight(): float
    {
        return 1.0; // Hard constraint
    }

    public function isRelevant(Activity $activity): bool
    {
        return !empty($activity->activityTeachers);
    }
}
<?php

namespace Modules\SmartTimetable\Services\Constraints\Hard;

use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Constraints\TimetableConstraint;
use Modules\SmartTimetable\Services\Solver\Slot;

class TeacherConflictConstraint implements TimetableConstraint
{
    public function passes(Slot $slot, Activity $activity, $context): bool
    {
        // Skip if activity has no teachers
        if (empty($activity->activityTeachers)) {
            return true;
        }

        foreach ($activity->activityTeachers as $teacher) {
            $teacherId = $teacher->teacher_id;

            // Check each period of this activity
            for ($i = 0; $i < $activity->duration_periods; $i++) {
                $periodId = $context->periods[$slot->startIndex + $i]->id;

                // Check if teacher is already occupied at this time
                if (isset($context->teacherOccupied[$teacherId][$slot->dayId][$periodId])) {
                    return false;
                }
            }
        }

        return true;
    }

    public function getDescription(): string
    {
        return 'Teacher cannot be scheduled for multiple activities at the same time';
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
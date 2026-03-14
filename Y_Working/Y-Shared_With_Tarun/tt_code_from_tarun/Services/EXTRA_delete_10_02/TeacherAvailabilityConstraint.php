<?php

namespace Modules\SmartTimetable\Services\Constraints\Hard;

use Illuminate\Support\Collection;
use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Solver\Slot;

class TeacherAvailabilityConstraint implements HardConstraint
{
    public function passes(
        Slot $slot,
        Activity $activity,
        array $entries,
        Collection $periods,
        array $activitiesById
    ): bool {

        $teacherIds = $activity->teachers
            ->pluck('teacher.id')
            ->unique()
            ->toArray();

        if (empty($teacherIds)) {
            return true;
        }

        for ($i = 0; $i < $activity->duration_periods; $i++) {

            $index = $slot->startIndex + $i;

            if (!isset($periods[$index])) {
                return false;
            }

            $periodId = $periods[$index]->id;

            foreach ($entries as $entry) {

                if (
                    $entry['day_id'] !== $slot->dayId ||
                    $entry['period_id'] !== $periodId
                ) {
                    continue;
                }

                $existingActivity = $activitiesById[$entry['activity_id']] ?? null;

                if (!$existingActivity) {
                    continue;
                }

                $busyTeacherIds = $existingActivity->teachers
                    ->pluck('teacher.id')
                    ->unique()
                    ->toArray();

                if (array_intersect($teacherIds, $busyTeacherIds)) {
                    return false;
                }
            }
        }

        return true;
    }
}

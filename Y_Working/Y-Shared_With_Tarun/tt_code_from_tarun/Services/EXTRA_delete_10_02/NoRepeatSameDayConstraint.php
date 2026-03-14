<?php
namespace Modules\SmartTimetable\Services\Constraints\Hard;

use Illuminate\Support\Collection;
use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Solver\Slot;

class NoRepeatSameDayConstraint implements HardConstraint
{
    public function passes(
        Slot $slot,
        Activity $activity,
        array $entries,
        Collection $periods,
        array $activitiesById
    ): bool {
        foreach ($entries as $entry) {
            if (
                $entry['activity_id'] === $activity->id &&
                $entry['day_id'] === $slot->dayId
            ) {
                return false;
            }
        }

        return true;
    }
}
<?php
namespace Modules\SmartTimetable\Services\Constraints\Hard;

use Illuminate\Support\Collection;
use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Solver\Slot;

class PeriodAvailabilityConstraint implements HardConstraint
{
    public function passes(
        Slot $slot,
        Activity $activity,
        array $entries,
        Collection $periods,
        array $activitiesById
    ): bool {
        for ($i = 0; $i < $activity->duration_periods; $i++) {

            $index = $slot->startIndex + $i;

            if (!isset($periods[$index])) {
                return false;
            }

            $period = $periods[$index];

            // ❌ Cannot cross breaks/lunch
            if (in_array($period->periodType->code, ['LUNCH', 'BREAK'], true)) {
                return false;
            }
        }

        return true;
    }
}
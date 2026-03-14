<?php

namespace Modules\SmartTimetable\Services\Constraints\Hard;

use Illuminate\Support\Collection;
use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Solver\Slot;

class PeriodTypeDurationConstraint implements HardConstraint
{
    public function passes(
        Slot $slot,
        Activity $activity,
        array $entries,
        Collection $periods,
        array $activitiesById
    ): bool {

        $startPeriod = $periods[$slot->startIndex];
        $duration = (int) $activity->duration_periods;

        // ❌ Never place anything in BREAK or LUNCH
        if (in_array($startPeriod->periodType->code, ['BREAK', 'LUNCH'])) {
            return false;
        }

        // ✅ Period-type → allowed duration mapping
        $allowedDurationByType = [
            'THEORY' => 1,
            'PRACTICAL' => 2,
            'ACTIVITY' => 3,
        ];

        $periodType = $startPeriod->periodType->code;

        // ❌ Unknown period type
        if (!isset($allowedDurationByType[$periodType])) {
            return false;
        }

        // ✅ Allow ONLY if duration matches period type
        return $allowedDurationByType[$periodType] === $duration;
    }
}

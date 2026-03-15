<?php

namespace Modules\SmartTimetable\Services\Constraints\Soft;

use Modules\SmartTimetable\Models\Activity;
use Illuminate\Support\Collection;
use Modules\SmartTimetable\Services\Solver\Slot;

class PriorityTimeConstraint implements SoftConstraint
{
    public function score(
        Slot $slot,
        Activity $activity,
        array $grid,
        Collection $periods
    ): int {
        $maxStart = $periods->count() - $activity->duration_periods;
        if ($maxStart <= 0) {
            return 0;
        }

        $ratio = min(max($activity->priority, 0), 100) / 100;
        $preferred = (int) round((1 - $ratio) * $maxStart);

        return -abs($slot->startIndex - $preferred) * 5;
    }
}
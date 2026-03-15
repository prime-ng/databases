<?php

namespace Modules\SmartTimetable\Services\Constraints\Hard;

use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Constraints\TimetableConstraint;
use Modules\SmartTimetable\Services\Solver\Slot;

class LunchBreakConstraint implements TimetableConstraint
{
    public function passes(
        Slot $slot,
        Activity $activity,
        $context
    ): bool {
        // Get periods as array
        $periods = $context->periods;
        if ($periods instanceof \Illuminate\Support\Collection) {
            $periods = $periods->values()->all();
        }

        // Check each period
        for ($i = 0; $i < $activity->duration_periods; $i++) {
            $periodIndex = $slot->startIndex + $i;

            if (!isset($periods[$periodIndex])) {
                return false;
            }

            $period = $periods[$periodIndex];

            // Check period CODE, not periodType->code
            if ($period->code === 'LUNCH') { // Your lunch period code
                return false;
            }
        }

        return true;
    }

    public function getDescription(): string
    {
        return 'Cannot schedule during lunch break periods (LUNCH)';
    }

    public function getWeight(): float
    {
        return 1.0;
    }

    public function isRelevant(Activity $activity): bool
    {
        return true;
    }
}
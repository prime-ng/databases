<?php

namespace Modules\SmartTimetable\Services\Constraints\Hard;

use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Constraints\TimetableConstraint;
use Modules\SmartTimetable\Services\Solver\Slot;

class BreakConstraint implements TimetableConstraint
{
    private array $breakCodes;

    /**
     * @param array $breakCodes Array of period codes to block (e.g., ['SBREAK', 'LUNCH'])
     */
    public function __construct(array $breakCodes = ['SBREAK', 'LUNCH'])
    {
        $this->breakCodes = $breakCodes;
    }

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

            // Check if period code is in break codes
            if (in_array($period->code, $this->breakCodes)) {
                return false;
            }
        }

        return true;
    }

    public function getDescription(): string
    {
        return 'Cannot schedule during break periods (' . implode(', ', $this->breakCodes) . ')';
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
<?php

namespace Modules\SmartTimetable\Services\Constraints\Soft;

use Modules\SmartTimetable\Models\Activity;
use Illuminate\Support\Collection;
use Modules\SmartTimetable\Services\Solver\Slot;

interface SoftConstraint
{
    public function score(
        Slot $slot,
        Activity $activity,
        array $grid,
        Collection $periods
    ): int;
}
<?php

namespace Modules\SmartTimetable\Services\Constraints\Hard;

use Illuminate\Support\Collection;
use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Solver\Slot;

interface HardConstraint
{
    // An interface is a contract, i.e any class that implements this interface mush have these methods
    // It will not have any logic, properties, just the method signaure.
    // Why interface here 
    // Because soon we'll have multiple Hard cosntraints like TeacherConflictConstraints, LabBlockConstraints etc.

    public function passes(
        Slot $slot,
        Activity $activity,
        array $entries,
        Collection $periods,
        array $activitiesById
    ): bool;

}
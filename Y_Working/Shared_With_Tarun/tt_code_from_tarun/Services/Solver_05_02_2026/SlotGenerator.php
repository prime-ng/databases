<?php

namespace Modules\SmartTimetable\Services\Solver;

use Illuminate\Support\Collection;
use Modules\SmartTimetable\Models\Activity;

class SlotGenerator
{
    public function generate(Activity $activity, Collection $days, Collection $periods): Collection
    {
        // return type Collection , A Laravel Class , it provides many help full methods which we can use on collection
        // Initiallize a simple collection
        $slots = collect();
        // return $periods;
        // return $days;

        // set max 
        $maxStart = $periods->count() - $activity->duration_periods;

        if ($maxStart < 0) {
            return $slots;
        }
        foreach ($days as $day) {
            for ($start = 0; $start <= $maxStart; $start++) {
                $slots->push(new Slot($day->id, $start));
            }
        }
        return $slots;
    }
}
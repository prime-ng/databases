<?php

namespace Modules\SmartTimetable\Services\Solver;

use Modules\SmartTimetable\Models\Activity;
use Illuminate\Support\Collection;

class SlotEvaluator
{
    public function evaluate(
        Collection $slots,
        Activity $activity,
        array $grid,
        Collection $periods,
        array $hardConstraints,
        array $softConstraints
    ): ?Slot {
        $bestSlot = null;
        $bestScore = PHP_INT_MIN;

        foreach ($slots as $slot) {

            foreach ($hardConstraints as $constraint) {
                if (!$constraint->passes($slot, $activity, $grid, $periods)) {
                    continue 2;
                }
            }

            $score = 0;
            foreach ($softConstraints as $constraint) {
                $score += $constraint->score($slot, $activity, $grid, $periods);
            }

            if ($score > $bestScore) {
                $bestScore = $score;
                $bestSlot = $slot;
            }
        }

        return $bestSlot;
    }
}

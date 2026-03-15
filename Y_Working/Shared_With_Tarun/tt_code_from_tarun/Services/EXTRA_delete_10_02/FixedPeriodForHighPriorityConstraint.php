<?php

namespace Modules\SmartTimetable\Services\Constraints\Hard;

use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Constraints\TimetableConstraint;
use Modules\SmartTimetable\Services\Solver\Slot;

class FixedPeriodForHighPriorityConstraint implements TimetableConstraint
{
    protected int $priorityThreshold = 80;

    public function passes(Slot $slot, Activity $activity, $context): bool
    {
        if ($activity->priority < $this->priorityThreshold) {
            return true; // Not high priority → ignore
        }

        $entries = $context->entries;
        $periods = $context->periods;

        $lockedStartIndex = null;

        foreach ($entries as $entry) {
            if ($entry['activity_id'] !== $activity->id) {
                continue;
            }

            // Resolve the startIndex of the first placement
            foreach ($periods as $index => $period) {
                if ($period->id === $entry['period_id']) {
                    $lockedStartIndex = $index;
                    break 2;
                }
            }
        }

        $placements = 0;
        $lockedStartIndex = null;

        foreach ($entries as $entry) {
            if ($entry['activity_id'] !== $activity->id) {
                continue;
            }

            foreach ($periods as $index => $period) {
                if ($period->id === $entry['period_id']) {
                    $placements++;
                    $lockedStartIndex ??= $index;
                    break;
                }
            }
        }

        // 🔑 Only lock after 2 placements
        if ($placements < 2) {
            return true;
        }

        return $slot->startIndex === $lockedStartIndex;


        // Enforce same slot across the week
        return $slot->startIndex === $lockedStartIndex;
    }

    public function getDescription(): string
    {
        return 'High priority activities must be scheduled in the same period across the week';
    }

    public function getWeight(): float
    {
        return 1.0;
    }

    public function isRelevant(Activity $activity): bool
    {
        return $activity->priority >= $this->priorityThreshold;
    }
}

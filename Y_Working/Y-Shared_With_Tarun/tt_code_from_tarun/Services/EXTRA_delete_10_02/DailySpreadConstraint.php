<?php

namespace Modules\SmartTimetable\Services\Constraints\Hard;

use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Constraints\TimetableConstraint;
use Modules\SmartTimetable\Services\Solver\Slot;

class DailySpreadConstraint implements TimetableConstraint
{
    /**
     * Maximum consecutive periods allowed for a class
     */
    private int $maxConsecutivePeriods;

    public function __construct(array $parameters = [])
    {
        $this->maxConsecutivePeriods = $parameters['max_consecutive'] ?? 3;
    }

    public function passes(
        Slot $slot,
        Activity $activity,
        $context
    ): bool {
        $classKey = $slot->classKey;
        $dayId = $slot->dayId;

        // Get periods already placed on this day for this class
        $occupiedPeriods = $context->occupied[$classKey][$dayId] ?? [];

        if (empty($occupiedPeriods)) {
            return true; // No periods yet, placement is fine
        }

        // Convert occupied periods to indexes
        $occupiedIndexes = $this->getOccupiedIndexes($occupiedPeriods, $context);

        // Check if new placement would create too many consecutive periods
        for ($i = 0; $i < $activity->duration_periods; $i++) {
            $newIndex = $slot->startIndex + $i;

            // Check consecutive periods before and after
            $consecutiveBefore = $this->countConsecutive($newIndex, $occupiedIndexes, -1);
            $consecutiveAfter = $this->countConsecutive($newIndex, $occupiedIndexes, 1);

            $totalConsecutive = $consecutiveBefore + $consecutiveAfter + 1;

            if ($totalConsecutive > $this->maxConsecutivePeriods) {
                return false;
            }
        }

        return true;
    }

    /**
     * Convert period IDs to period indexes
     */
    private function getOccupiedIndexes(array $occupiedPeriods, $context): array
    {
        $indexes = [];
        $periods = $context->periods;

        foreach ($occupiedPeriods as $periodId => $isOccupied) {
            if ($isOccupied) {
                // Find the index of this period ID
                foreach ($periods as $index => $period) {
                    if ($period->id == $periodId) {
                        $indexes[] = $index;
                        break;
                    }
                }
            }
        }

        sort($indexes);
        return $indexes;
    }

    /**
     * Count consecutive occupied periods in a direction
     */
    private function countConsecutive(int $startIndex, array $occupiedIndexes, int $direction): int
    {
        $count = 0;
        $currentIndex = $startIndex + $direction;

        while (in_array($currentIndex, $occupiedIndexes)) {
            $count++;
            $currentIndex += $direction;
        }

        return $count;
    }

    public function getDescription(): string
    {
        return "Prevents more than {$this->maxConsecutivePeriods} consecutive periods for a class on the same day";
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
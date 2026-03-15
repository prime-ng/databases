<?php

namespace Modules\SmartTimetable\Services\Constraints\Hard;

use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Constraints\TimetableConstraint;
use Modules\SmartTimetable\Services\Solver\Slot;

class HighPriorityFixedPeriodConstraint implements TimetableConstraint
{
    /**
     * Store locked period for each activity
     * Format: [activity_id => period_index]
     */
    protected static array $lockedPeriods = [];

    /**
     * Store locked day for each activity (optional)
     * Format: [activity_id => [day_id1, day_id2, ...]]
     */
    protected static array $scheduledDays = [];

    public function passes(
        Slot $slot,
        Activity $activity,
        $context
    ): bool {
        // 🔕 Constraint applies only to selected activities
        if (!$this->appliesTo($activity)) {
            return true;
        }

        // 🔐 First placement → lock the period index
        if (!isset(self::$lockedPeriods[$activity->id])) {
            // Store the locked period index
            self::$lockedPeriods[$activity->id] = $slot->startIndex;
            // Track which day this was placed on
            self::$scheduledDays[$activity->id] = [$slot->dayId];
            \Log::info('HighPriority activity locked to period', [
                'activity_id' => $activity->id,
                'locked_period_index' => $slot->startIndex,
                'day_id' => $slot->dayId,
                'activity_priority' => $activity->priority,
            ]);
            return true;
        }

        // ❌ Enforce same period index across all days
        $expectedPeriodIndex = self::$lockedPeriods[$activity->id];

        if ($slot->startIndex !== $expectedPeriodIndex) {
            \Log::debug('HighPriority activity rejected - wrong period', [
                'activity_id' => $activity->id,
                'expected_period' => $expectedPeriodIndex,
                'attempted_period' => $slot->startIndex,
                'day_id' => $slot->dayId,
            ]);
            return false;
        }

        // Optional: Check if already scheduled on this day
        if (in_array($slot->dayId, self::$scheduledDays[$activity->id] ?? [])) {
            \Log::debug('HighPriority activity already scheduled on this day', [
                'activity_id' => $activity->id,
                'day_id' => $slot->dayId,
            ]);
            return false;
        }

        // ✅ Valid placement - track this day
        self::$scheduledDays[$activity->id][] = $slot->dayId;
        return true;
    }

    protected function appliesTo(Activity $activity): bool
    {
        // Apply to high priority, compulsory activities
        $isHighPriority = $activity->priority >= 80; // Reduced from 90
        $isFrequent = $activity->weekly_periods >= 3; // Reduced from 5

        return $activity->is_compulsory && $isHighPriority && $isFrequent;
    }

    /**
     * Get the preferred period for a high-priority activity
     * This can be used by the generator to prioritize certain periods
     */
    public function getPreferredPeriod(Activity $activity): ?int
    {
        if (!$this->appliesTo($activity)) {
            return null;
        }

        // If already locked, return the locked period
        if (isset(self::$lockedPeriods[$activity->id])) {
            return self::$lockedPeriods[$activity->id];
        }

        // Default: prefer middle periods (10 AM - 2 PM equivalent)
        // Period indices: 0-9, lunch at 6, break at 3
        // Good teaching periods: 0-2 (morning), 4-5 (pre-lunch), 8-9 (afternoon)
        $preferredPeriods = [2, 4, 8, 1, 5, 0, 9]; // In order of preference

        return $preferredPeriods[0] ?? 2; // Default to period 2 (3rd period)
    }

    /**
     * Reset locked periods (call this at start of each generation)
     */
    public static function reset(): void
    {
        self::$lockedPeriods = [];
        self::$scheduledDays = [];
        \Log::info('HighPriorityFixedPeriodConstraint reset');
    }

    /**
     * Get all locked periods for debugging
     */
    public static function getLockedPeriods(): array
    {
        return self::$lockedPeriods;
    }

    public function getDescription(): string
    {
        return 'High-priority compulsory activities must be scheduled at the same period across all days';
    }

    public function getWeight(): float
    {
        return 1.0; // Hard constraint
    }

    public function isRelevant(Activity $activity): bool
    {
        return $this->appliesTo($activity);
    }
}
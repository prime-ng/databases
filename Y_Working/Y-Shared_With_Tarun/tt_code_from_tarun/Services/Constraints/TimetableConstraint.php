<?php

namespace Modules\SmartTimetable\Services\Constraints;

use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Solver\Slot;

interface TimetableConstraint
{
    /**
     * Check if this constraint is satisfied
     */
    public function passes(Slot $slot, Activity $activity, $context): bool;

    /**
     * Get a human-readable description of the constraint
     * Optional, but useful for debugging
     */
    public function getDescription(): string;

    /**
     * Get the weight/importance of this constraint
     * For soft constraints, higher weight = more important
     * For hard constraints, typically returns 1.0
     */
    public function getWeight(): float;

    /**
     * Check if this constraint is relevant for the given activity
     * Optional optimization to skip irrelevant constraints
     */
    public function isRelevant(Activity $activity): bool;
}
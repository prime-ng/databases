<?php

namespace Modules\SmartTimetable\Services\Constraints\Soft;

use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Constraints\TimetableConstraint;
use Modules\SmartTimetable\Services\Solver\Slot;

class GenericSoftConstraint implements TimetableConstraint
{
    private array $meta = [];
    private array $params = [];

    public function __construct(array $params = [])
    {
        $this->params = $params;
        $this->meta = $params['_constraint_meta'] ?? [];
    }

    public function passes(Slot $slot, Activity $activity, $context): bool
    {
        // Default implementation for soft constraints
        // In practice, you might want specific implementations for different constraint types
        return true;
    }

    public function getDescription(): string
    {
        return $this->meta['description'] ?? 'Generic Soft Constraint';
    }

    public function getWeight(): float
    {
        return ($this->meta['weight'] ?? 50) / 100.0;
    }

    public function isRelevant(Activity $activity): bool
    {
        return $this->appliesToContext($this->buildActivityContext($activity));
    }

    public function appliesToContext(array $context): bool
    {
        // Same logic as GenericHardConstraint
        $targetType = $this->meta['target_type'] ?? 'GLOBAL';
        $targetId = $this->meta['target_id'] ?? null;

        if ($targetType === 'GLOBAL') {
            return $this->checkDayApplication($context);
        }

        if (!isset($context[$targetType])) {
            return false;
        }

        if ($targetId !== null) {
            $targetIds = (array) $context[$targetType];
            if (!in_array($targetId, $targetIds)) {
                return false;
            }
        }

        return $this->checkDayApplication($context);
    }

    private function buildActivityContext(Activity $activity): array
    {
        // Same as GenericHardConstraint
        $context = [
            'ACTIVITY' => [$activity->id],
        ];

        // ... build context based on activity
        return $context;
    }

    private function checkDayApplication(array $context): bool
    {
        $appliesToDays = $this->meta['applies_to_days'] ?? [];

        if (empty($appliesToDays)) {
            return true;
        }

        if (isset($context['day_id']) && !in_array($context['day_id'], $appliesToDays)) {
            return false;
        }

        return true;
    }
}
<?php

namespace Modules\SmartTimetable\Services\Constraints\Hard;

use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Constraints\TimetableConstraint;
use Modules\SmartTimetable\Services\Solver\Slot;

class GenericHardConstraint implements TimetableConstraint
{
    private array $meta = [];
    private array $params = [];

    public function __construct(array $params = [])
    {
        $this->params = $params;
        $this->meta = $params['_constraint_meta'] ?? [];
    }

    /**
     * Default passes method - can be overridden by specific constraints
     * For now, returns true to allow placement (should be implemented per constraint type)
     */
    public function passes(Slot $slot, Activity $activity, $context): bool
    {
        // Default implementation - check for basic break periods
        if (isset($this->params['period_codes'])) {
            $periods = $context->periods;
            if ($periods instanceof \Illuminate\Support\Collection) {
                $periods = $periods->values()->all();
            }

            for ($i = 0; $i < $activity->duration_periods; $i++) {
                $periodIndex = $slot->startIndex + $i;

                if (!isset($periods[$periodIndex])) {
                    return false;
                }

                $period = $periods[$periodIndex];
                if (in_array($period->code, (array) $this->params['period_codes'])) {
                    return false;
                }
            }
        }

        return true;
    }

    public function getDescription(): string
    {
        return $this->meta['description'] ?? 'Generic Hard Constraint';
    }

    public function getWeight(): float
    {
        return ($this->meta['weight'] ?? 100) / 100.0;
    }

    public function isRelevant(Activity $activity): bool
    {
        return $this->appliesToContext($this->buildActivityContext($activity));
    }

    public function appliesToContext(array $context): bool
    {
        // Check target type
        $targetType = $this->meta['target_type'] ?? 'GLOBAL';
        $targetId = $this->meta['target_id'] ?? null;

        // Global constraints apply to everything
        if ($targetType === 'GLOBAL') {
            return $this->checkDayApplication($context);
        }

        // Check if context has this target type
        if (!isset($context[$targetType])) {
            return false;
        }

        // If specific target ID, check match
        if ($targetId !== null) {
            $targetIds = (array) $context[$targetType];
            if (!in_array($targetId, $targetIds)) {
                return false;
            }
        }

        // Check day application
        return $this->checkDayApplication($context);
    }

    private function buildActivityContext(Activity $activity): array
    {
        $context = [
            'ACTIVITY' => [$activity->id],
        ];

        if ($activity->classGroupJnt) {
            $context['CLASS'] = [$activity->classGroupJnt->class_id];
            $context['CLASS_GROUP'] = [$activity->class_group_jnt_id];

            if ($activity->classGroupJnt->subjectStudyFormat) {
                $context['SUBJECT'] = [$activity->classGroupJnt->subjectStudyFormat->subject_id];
                $context['STUDY_FORMAT'] = [$activity->classGroupJnt->subjectStudyFormat->study_format_id];
            }
        }

        if ($activity->class_subgroup_id) {
            $context['CLASS_SUBGROUP'] = [$activity->class_subgroup_id];
        }

        if ($activity->activityTeachers) {
            $context['TEACHER'] = $activity->activityTeachers
                ->pluck('teacher_id')
                ->toArray();
        }

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
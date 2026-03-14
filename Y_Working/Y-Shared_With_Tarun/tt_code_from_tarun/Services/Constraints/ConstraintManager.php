<?php

namespace Modules\SmartTimetable\Services\Constraints;

use Illuminate\Support\Collection;
use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Solver\Slot;

class ConstraintManager
{
    /**
     * @var array<TimetableConstraint> Hard constraints that MUST be satisfied
     */
    private array $hardConstraints = [];

    /**
     * @var array<TimetableConstraint> Soft constraints (preferences) that should be satisfied
     */
    private array $softConstraints = [];

    /**
     * Cache for constraint evaluation results
     */
    private array $evaluationCache = [];

    /**
     * Context for current generation (academic session, etc.)
     */
    private array $generationContext = [];

    /**
     * Constructor with optional generation context
     */
    public function __construct(array $generationContext = [])
    {
        $this->generationContext = $generationContext;
    }

    /**
     * Add a constraint to the manager
     */
    public function addConstraint(TimetableConstraint $constraint, bool $isHard = true): void
    {
        if ($isHard) {
            $this->hardConstraints[] = $constraint;
        } else {
            $this->softConstraints[] = $constraint;
        }
    }

    /**
     * Check if a slot satisfies all hard constraints for an activity
     */
    public function checkHardConstraints(Slot $slot, Activity $activity, $context): bool
    {
        $cacheKey = $this->getCacheKey('hard', $slot, $activity);

        if (isset($this->evaluationCache[$cacheKey])) {
            return $this->evaluationCache[$cacheKey];
        }

        // Build context array for this specific check
        $contextArray = $this->buildContextArray($slot, $activity, $context);

        // Merge with generation context
        $fullContext = array_merge($this->generationContext, $contextArray);

        // Check each hard constraint
        foreach ($this->hardConstraints as $constraint) {
            // Check if constraint applies to this context
            if (!$this->constraintApplies($constraint, $fullContext)) {
                continue;
            }

            if (!$constraint->passes($slot, $activity, $context)) {
                $this->evaluationCache[$cacheKey] = false;

                \Log::debug('Hard constraint violation', [
                    'activity_id' => $activity->id,
                    'constraint' => get_class($constraint),
                    'slot' => ['day' => $slot->dayId, 'start' => $slot->startIndex],
                ]);

                return false;
            }
        }

        $this->evaluationCache[$cacheKey] = true;
        return true;
    }

    /**
     * Evaluate soft constraints and return a score
     */
    public function evaluateSoftConstraints(Slot $slot, Activity $activity, $context): float
    {
        $cacheKey = $this->getCacheKey('soft', $slot, $activity);

        if (isset($this->evaluationCache[$cacheKey])) {
            return $this->evaluationCache[$cacheKey];
        }

        $contextArray = $this->buildContextArray($slot, $activity, $context);
        $fullContext = array_merge($this->generationContext, $contextArray);

        $score = 0.0;

        foreach ($this->softConstraints as $constraint) {
            if (!$this->constraintApplies($constraint, $fullContext)) {
                continue;
            }

            if ($constraint->passes($slot, $activity, $context)) {
                $score += $constraint->getWeight();
            }
        }

        $this->evaluationCache[$cacheKey] = $score;
        return $score;
    }

    /**
     * Check if a constraint applies to the current context
     */
    private function constraintApplies(TimetableConstraint $constraint, array $context): bool
    {
        if (!method_exists($constraint, 'appliesToContext')) {
            return true;
        }

        return $constraint->appliesToContext($context);
    }

    /**
     * Build detailed context array for constraint checking
     */
    private function buildContextArray(Slot $slot, Activity $activity, $context): array
    {
        $contextArray = [
            'day_id' => $slot->dayId,
            'day_of_week' => $slot->dayId,
            'period_index' => $slot->startIndex,
            'class_key' => $slot->classKey,
            'activity_id' => $activity->id,
        ];

        // Add class information
        if ($activity->classGroupJnt) {
            $contextArray['CLASS'] = [$activity->classGroupJnt->class_id];
            $contextArray['SECTION'] = [$activity->classGroupJnt->section_id];
            $contextArray['CLASS_GROUP'] = [$activity->class_group_jnt_id];

            if ($activity->classGroupJnt->subjectStudyFormat) {
                $contextArray['SUBJECT'] = [$activity->classGroupJnt->subjectStudyFormat->subject_id];
                $contextArray['STUDY_FORMAT'] = [$activity->classGroupJnt->subjectStudyFormat->study_format_id];
            }
        }

        // Add subgroup if exists
        if ($activity->class_subgroup_id) {
            $contextArray['CLASS_SUBGROUP'] = [$activity->class_subgroup_id];
        }

        // Add teacher information
        if ($activity->activityTeachers) {
            $contextArray['TEACHER'] = $activity->activityTeachers
                ->pluck('teacher_id')
                ->toArray();
        }

        // Add room information
        if ($activity->preferred_room_type_id) {
            $contextArray['ROOM_TYPE'] = [$activity->preferred_room_type_id];
        }

        return $contextArray;
    }

    /**
     * Get all violated constraints for debugging
     */
    public function getViolations(Slot $slot, Activity $activity, $context): array
    {
        $violations = [];
        $contextArray = $this->buildContextArray($slot, $activity, $context);
        $fullContext = array_merge($this->generationContext, $contextArray);

        // Check hard constraints
        foreach ($this->hardConstraints as $constraint) {
            if (!$this->constraintApplies($constraint, $fullContext)) {
                continue;
            }

            if (!$constraint->passes($slot, $activity, $context)) {
                $violations[] = [
                    'type' => 'hard',
                    'description' => $constraint->getDescription(),
                    'constraint' => get_class($constraint),
                    'weight' => $constraint->getWeight(),
                ];
            }
        }

        return $violations;
    }

    /**
     * Get all constraints (both hard and soft)
     */
    public function getConstraints(): array
    {
        return array_merge($this->hardConstraints, $this->softConstraints);
    }


    /**
     * Get all soft constraints
     */
    public function getSoftConstraints(): array
    {
        return $this->softConstraints;
    }

    /**
     * Get all hard constraints
     */
    public function getHardConstraints(): array
    {
        return $this->hardConstraints;
    }


    /**
     * Clear the evaluation cache
     */
    public function clearCache(): void
    {
        $this->evaluationCache = [];
    }

    /**
     * Create a cache key for constraint evaluation
     */
    private function getCacheKey(string $type, Slot $slot, Activity $activity): string
    {
        return sprintf(
            '%s-%s-%d-%d-%d',
            $type,
            $slot->classKey,
            $slot->dayId,
            $slot->startIndex,
            $activity->id
        );
    }
}
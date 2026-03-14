<?php

namespace Modules\SmartTimetable\Services\Constraints\Hard;

use Illuminate\Support\Collection;
use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Constraints\TimetableConstraint;
use Modules\SmartTimetable\Services\Solver\Slot;

class NoSameSubjectSameDayConstraint implements TimetableConstraint
{
    public function passes(Slot $slot, Activity $activity, $context): bool
    {
        $entries = $context->entries;

        $subjectId = $activity->classGroupJnt
            ->subjectStudyFormat
            ->subject_id;

        $classKey = $slot->classKey;
        $dayId = $slot->dayId;

        foreach ($entries as $entry) {

            // Same day?
            if ($entry['day_id'] !== $dayId) {
                continue;
            }

            $placedActivityId = $entry['activity_id'];
            if ($placedActivityId === $activity->id) {
                continue;
            }

            $placedActivity = $activity->getRelation('classGroupJnt')
                ? null
                : null;

            // We already have activity object in memory via generator
            // So we can safely resolve it like this:
            $placedActivity = $context->activitiesById[$placedActivityId] ?? null;
            if (!$placedActivity) {
                continue;
            }

            // Same class–section?
            $placedClassKey =
                $placedActivity->classGroupJnt->class->code . '-' .
                $placedActivity->classGroupJnt->section->code;

            if ($placedClassKey !== $classKey) {
                continue;
            }

            // Same subject?
            $placedSubjectId =
                $placedActivity->classGroupJnt
                    ->subjectStudyFormat
                    ->subject_id;

            if ($placedSubjectId === $subjectId) {
                return false; // ❌ Already placed this subject today
            }
        }

        return true;
    }

    public function getDescription(): string
    {
        return 'Same subject cannot be scheduled more than once per day for a class';
    }

    public function getWeight(): float
    {
        return 1.0; // Hard constraint
    }

    public function isRelevant(Activity $activity): bool
    {
        return true;
    }
}

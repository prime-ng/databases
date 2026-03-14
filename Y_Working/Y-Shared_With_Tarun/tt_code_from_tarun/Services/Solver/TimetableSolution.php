<?php
// File: Modules/SmartTimetable/Services/Solver/TimetableSolution.php

namespace Modules\SmartTimetable\Services\Solver;

use Illuminate\Support\Collection;
use Modules\SmartTimetable\Models\Activity;

class TimetableSolution
{
    private array $placements = [];
    private array $occupied = [];
    private array $teacherOccupied = [];

    private int $activitiesPlaced = 0;
    private int $periodsPlaced = 0;

    public function __construct(
        private Collection $days,
        private Collection $periods
    ) {
    }

    /**
     * Place activity at slot
     */
    public function place($activity, Slot $slot): bool
    {
        if (!$this->canPlace($activity, $slot)) {
            return false;
        }

        $classKey = $slot->classKey;
        $duration = $activity->duration_periods;
        $activityId = $activity->instance_id ?? $activity->id;

        // Mark periods as occupied
        for ($i = 0; $i < $duration; $i++) {
            $periodIndex = $slot->startIndex + $i;

            // Check bounds
            if ($periodIndex >= $this->periods->count()) {
                $this->remove($activity, $slot); // Clean up any placed periods
                return false;
            }

            $period = $this->periods[$periodIndex];
            $periodId = $period->id;

            // Mark class occupied
            $this->occupied[$classKey][$slot->dayId][$periodId] = $activityId;

            // Mark teachers occupied - CRITICAL FOR CONSTRAINT CHECKING
            if ($activity->activityTeachers) {
                foreach ($activity->activityTeachers as $teacher) {
                    $teacherId = $teacher->teacher_id ?? $teacher->id;
                    $this->teacherOccupied[$teacherId][$slot->dayId][$periodId] = $activityId;
                }
            }
        }

        // Store placement
        if (!isset($this->placements[$activityId])) {
            $this->placements[$activityId] = [];
        }
        $this->placements[$activityId][] = $slot;

        $this->activitiesPlaced++;
        $this->periodsPlaced += $duration;

        return true;
    }


    /**
     * Check if activity can be placed
     */
    public function canPlace(Activity $activity, Slot $slot): bool
    {
        $classKey = $slot->classKey;
        $duration = $activity->duration_periods;

        // Check each period
        for ($i = 0; $i < $duration; $i++) {
            $periodIndex = $slot->startIndex + $i;

            // Check bounds
            if ($periodIndex >= $this->periods->count()) {
                return false;
            }

            $period = $this->periods[$periodIndex];
            $periodId = $period->id;

            // Check class occupied
            if (isset($this->occupied[$classKey][$slot->dayId][$periodId])) {
                return false;
            }

            // Check teachers occupied
            if ($activity->activityTeachers) {
                foreach ($activity->activityTeachers as $teacher) {
                    $teacherId = $teacher->teacher_id ?? $teacher->id;
                    if (isset($this->teacherOccupied[$teacherId][$slot->dayId][$periodId])) {
                        return false;
                    }
                }
            }
        }

        return true;
    }

    /**
     * Remove activity from slot
     */
    public function remove(Activity $activity, Slot $slot): void
    {
        $classKey = $slot->classKey;
        $duration = $activity->duration_periods;

        for ($i = 0; $i < $duration; $i++) {
            $periodIndex = $slot->startIndex + $i;

            if ($periodIndex >= $this->periods->count()) {
                continue; // Skip invalid periods
            }

            $period = $this->periods[$periodIndex];
            $periodId = $period->id;

            // Unmark class occupied
            unset($this->occupied[$classKey][$slot->dayId][$periodId]);

            // Unmark teachers occupied
            if ($activity->activityTeachers) {
                foreach ($activity->activityTeachers as $teacher) {
                    $teacherId = $teacher->teacher_id ?? $teacher->id;
                    unset($this->teacherOccupied[$teacherId][$slot->dayId][$periodId]);
                }
            }
        }

        // Remove from placements
        if (isset($this->placements[$activity->id])) {
            $this->placements[$activity->id] = array_filter(
                $this->placements[$activity->id],
                function ($s) use ($slot) {
                    return !($s->dayId == $slot->dayId && $s->startIndex == $slot->startIndex);
                }
            );

            if (empty($this->placements[$activity->id])) {
                unset($this->placements[$activity->id]);
                $this->activitiesPlaced--;
            }
        }

        // Update periods placed
        $this->periodsPlaced = max(0, $this->periodsPlaced - $duration);
    }

    /**
     * Convert to array for database
     */
    public function toArray(): array
    {
        $entries = [];

        foreach ($this->placements as $activityId => $slots) {
            foreach ($slots as $slot) {
                // We need activity to know duration - for now assume 1
                $duration = 1;

                for ($i = 0; $i < $duration; $i++) {
                    $periodIndex = $slot->startIndex + $i;

                    if ($periodIndex >= $this->periods->count()) {
                        continue;
                    }

                    $period = $this->periods[$periodIndex];

                    $entries[] = [
                        'day_id' => $slot->dayId,
                        'period_id' => $period->id,
                        'activity_id' => $activityId,
                        'class_key' => $slot->classKey,
                        'period_index' => $periodIndex,
                    ];
                }
            }
        }

        return $entries;
    }

    /**
     * Get placements
     */
    public function getPlacements(): array
    {
        return $this->placements;
    }

    /**
     * Get activities placed count
     */
    public function getActivitiesPlaced(): int
    {
        return $this->activitiesPlaced;
    }

    /**
     * Get periods placed count
     */
    public function getPeriodsPlaced(): int
    {
        return $this->periodsPlaced;
    }

    /**
     * Clone solution
     */
    public function __clone()
    {
        $this->placements = unserialize(serialize($this->placements));
        $this->occupied = unserialize(serialize($this->occupied));
        $this->teacherOccupied = unserialize(serialize($this->teacherOccupied));
    }
}
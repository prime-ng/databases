<?php

namespace Modules\SmartTimetable\Services\Solver;

use Modules\SmartTimetable\Models\ClassGroupJnt;

class Slot
{
    public string $classKey;
    public int $dayId;
    public int $startIndex;

    public function __construct(string $classKey, int $dayId, int $startIndex)
    {
        $this->classKey = $classKey;
        $this->dayId = $dayId;
        $this->startIndex = $startIndex;
        // Add extra info for sorting
    }
}
<?php
// File: Modules/SmartTimetable/Services/Solver/Slot.php

namespace Modules\SmartTimetable\Services\Solver;

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
    }
}
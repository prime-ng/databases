<?php

namespace Modules\SmartTimetable\Services\Constraints;

use Modules\SmartTimetable\Services\Constraints\Hard\LunchBreakConstraint;
use Modules\SmartTimetable\Services\Constraints\Hard\ShortBreakConstraint;

class ConstraintResolver
{
    public static function resolve(string $typeCode): ?string
    {
        return match ($typeCode) {
            'LUNCH_BREAK' => LunchBreakConstraint::class,
            'SHORT_BREAK' => ShortBreakConstraint::class,
            default => null,
        };
    }
}
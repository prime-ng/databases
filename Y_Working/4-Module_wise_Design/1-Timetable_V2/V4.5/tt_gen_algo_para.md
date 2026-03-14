# TIMETABLE GENERATION ALGORITHM PARAMETERS

## Input Parameters for Generation Algorithm

```php
class TimetableGenerationParameters {
    // 1. ACTIVITY PARAMETERS (from tt_activity)
    public $activities = [
        'id' => 'int',
        'difficulty_score' => 'int (0-100)',
        'required_weekly_periods' => 'int',
        'is_compulsory' => 'boolean',
        'preferred_periods' => 'array',  // JSON decoded
        'avoid_periods' => 'array',
        'spread_evenly' => 'boolean',
        'allow_consecutive' => 'boolean',
        'max_consecutive' => 'int',
        'required_room_type_id' => 'int',
        'required_room_id' => 'int'
    ];

    // 2. TEACHER PARAMETERS (from tt_teacher_availability)
    public $teachers = [
        'id' => 'int',
        'max_available_periods_weekly' => 'int',
        'min_available_periods_weekly' => 'int',
        'current_allocated' => 'int',
        'proficiency_percentage' => 'int',
        'priority_weight' => 'int',
        'unavailable_periods' => 'array'  // From tt_teacher_unavailable
    ];

    // 3. SLOT PARAMETERS (from tt_slot_requirement + tt_period_set_period_jnt)
    public $slots = [
        'day_of_week' => 'int (1-7)',
        'period_ord' => 'int',
        'class_id' => 'int',
        'section_id' => 'int',
        'slot_type' => 'string',  // teaching/exam/free
        'start_time' => 'time',
        'end_time' => 'time',
        'is_available' => 'boolean'
    ];

    // 4. ROOM PARAMETERS (from tt_room_availability)
    public $rooms = [
        'id' => 'int',
        'room_type_id' => 'int',
        'capacity' => 'int',
        'unavailable_periods' => 'array'  // From tt_room_unavailable
    ];

    // 5. CONSTRAINT PARAMETERS (from tt_constraint)
    public $constraints = [
        'hard_constraints' => 'array',   // weight = 100%
        'soft_constraints' => 'array',   // weight < 100%
        'teacher_constraints' => 'array',
        'room_constraints' => 'array',
        'time_constraints' => 'array'
    ];

    // 6. ALGORITHM CONTROL PARAMETERS
    public $algorithm = [
        'strategy_id' => 'int',
        'max_recursion_depth' => 'int (default: 14)',
        'max_placement_attempts' => 'int (default: 2000)',
        'tabu_list_size' => 'int (default: 100)',
        'timeout_seconds' => 'int (default: 300)',
        'activity_sorting' => 'string (difficulty_score DESC)',
        'slot_selection' => 'string (conflict_count ASC)',
        'full_search_depth' => 'int (default: 4)',
        'best_only_depth' => 'int (default: 5)'
    ];
}
```

## Output Parameters (Generation Result)

```php
class GenerationResult {
    public $success = true;
    public $timetable_id = 123;
    public $stats = [
        'total_activities' => 500,
        'placed_activities' => 495,
        'failed_activities' => 5,
        'hard_violations' => 0,
        'soft_violations' => 12,
        'quality_score' => 95.5,
        'generation_time' => 45.2,  // seconds
        'recursion_depth_used' => 12,
        'placement_attempts' => 1850
    ];
    public $conflicts = [
        ['activity_id' => 456, 'reason' => 'No teacher available', 'suggestions' => [...]]
    ];
    public $cells = [];  // Placed timetable cells
}
```


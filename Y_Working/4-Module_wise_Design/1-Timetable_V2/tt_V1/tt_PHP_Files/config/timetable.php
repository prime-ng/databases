<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Timetable Module Configuration
    |--------------------------------------------------------------------------
    |
    | This file contains configuration options for the Timetable Generator module.
    | These settings control the behavior of the timetable generation algorithm,
    | constraint evaluation, and various module features.
    |
    */

    'generation' => [

        /*
        |--------------------------------------------------------------------------
        | Default Generation Parameters
        |--------------------------------------------------------------------------
        */
        'default_mode' => env('TIMETABLE_DEFAULT_MODE', 'STANDARD'),
        'default_optimization_level' => env('TIMETABLE_OPTIMIZATION_LEVEL', 'BALANCED'),
        'max_generation_time' => env('TIMETABLE_MAX_GENERATION_TIME', 300), // seconds
        'max_iterations' => env('TIMETABLE_MAX_ITERATIONS', 1000),

        /*
        |--------------------------------------------------------------------------
        | Algorithm Settings
        |--------------------------------------------------------------------------
        */
        'algorithm' => [
            'population_size' => env('TIMETABLE_POPULATION_SIZE', 50),
            'mutation_rate' => env('TIMETABLE_MUTATION_RATE', 0.1),
            'crossover_rate' => env('TIMETABLE_CROSSOVER_RATE', 0.8),
            'elitism_count' => env('TIMETABLE_ELITISM_COUNT', 5),
        ],

        /*
        |--------------------------------------------------------------------------
        | Constraint Settings
        |--------------------------------------------------------------------------
        */
        'constraints' => [
            'hard_constraint_weight' => env('TIMETABLE_HARD_CONSTRAINT_WEIGHT', 1000),
            'soft_constraint_weight' => env('TIMETABLE_SOFT_CONSTRAINT_WEIGHT', 1),
            'max_hard_violations' => env('TIMETABLE_MAX_HARD_VIOLATIONS', 0),
        ],

    ],

    'scheduling' => [

        /*
        |--------------------------------------------------------------------------
        | Time Settings
        |--------------------------------------------------------------------------
        */
        'working_days' => ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
        'max_periods_per_day' => env('TIMETABLE_MAX_PERIODS_PER_DAY', 8),
        'max_consecutive_periods' => env('TIMETABLE_MAX_CONSECUTIVE_PERIODS', 4),
        'min_break_periods' => env('TIMETABLE_MIN_BREAK_PERIODS', 1),

        /*
        |--------------------------------------------------------------------------
        | Resource Limits
        |--------------------------------------------------------------------------
        */
        'max_teacher_workload' => env('TIMETABLE_MAX_TEACHER_WORKLOAD', 6),
        'max_class_periods' => env('TIMETABLE_MAX_CLASS_PERIODS', 8),
        'room_utilization_target' => env('TIMETABLE_ROOM_UTILIZATION_TARGET', 80), // percentage

    ],

    'database' => [

        /*
        |--------------------------------------------------------------------------
        | Table Settings
        |--------------------------------------------------------------------------
        */
        'tables' => [
            'modes' => 'tim_timetable_modes',
            'period_sets' => 'tim_period_sets',
            'period_set_periods' => 'tim_period_set_periods',
            'generation_runs' => 'tim_generation_runs',
            'timetable_cells' => 'tim_timetable_cells',
            'timetable_cell_teachers' => 'tim_timetable_cell_teachers',
            'constraints' => 'tim_constraints',
            'class_mode_rules' => 'tim_class_mode_rules',
            'teacher_assignment_roles' => 'tim_teacher_assignment_roles',
            'substitution_log' => 'tim_substitution_log',
        ],

        /*
        |--------------------------------------------------------------------------
        | Foreign Key Mappings
        |--------------------------------------------------------------------------
        */
        'foreign_keys' => [
            'school_classes' => 'sch_school_classes',
            'users' => 'sch_users',
            'rooms' => 'sch_rooms',
            'academic_sessions' => 'sch_academic_sessions',
        ],

    ],

    'api' => [

        /*
        |--------------------------------------------------------------------------
        | API Settings
        |--------------------------------------------------------------------------
        */
        'pagination' => [
            'generation_runs_per_page' => env('TIMETABLE_API_GENERATION_RUNS_PER_PAGE', 20),
            'timetable_cells_per_page' => env('TIMETABLE_API_TIMETABLE_CELLS_PER_PAGE', 100),
        ],

        'rate_limiting' => [
            'generation_start_max_attempts' => env('TIMETABLE_API_GENERATION_START_MAX_ATTEMPTS', 5),
            'generation_start_decay_minutes' => env('TIMETABLE_API_GENERATION_START_DECAY_MINUTES', 60),
        ],

    ],

    'logging' => [

        /*
        |--------------------------------------------------------------------------
        | Logging Configuration
        |--------------------------------------------------------------------------
        */
        'channels' => [
            'timetable' => [
                'driver' => 'single',
                'path' => storage_path('logs/timetable.log'),
                'level' => env('TIMETABLE_LOG_LEVEL', 'info'),
            ],
        ],

        'log_generation_stats' => env('TIMETABLE_LOG_GENERATION_STATS', true),
        'log_constraint_violations' => env('TIMETABLE_LOG_CONSTRAINT_VIOLATIONS', true),

    ],

    'features' => [

        /*
        |--------------------------------------------------------------------------
        | Feature Flags
        |--------------------------------------------------------------------------
        */
        'enable_substitution' => env('TIMETABLE_ENABLE_SUBSTITUTION', true),
        'enable_optimization' => env('TIMETABLE_ENABLE_OPTIMIZATION', true),
        'enable_statistics' => env('TIMETABLE_ENABLE_STATISTICS', true),
        'enable_audit_trail' => env('TIMETABLE_ENABLE_AUDIT_TRAIL', true),

    ],

    'notifications' => [

        /*
        |--------------------------------------------------------------------------
        | Notification Settings
        |--------------------------------------------------------------------------
        */
        'email_notifications' => env('TIMETABLE_EMAIL_NOTIFICATIONS', false),
        'notify_on_generation_complete' => env('TIMETABLE_NOTIFY_GENERATION_COMPLETE', true),
        'notify_on_generation_failure' => env('TIMETABLE_NOTIFY_GENERATION_FAILURE', true),

    ],

];
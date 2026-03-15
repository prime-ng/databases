<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Modules\SmartTimetable\Models\ConstraintType;

class ConstraintTypeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $types = [

            /*
            |--------------------------------------------------------------------------
            | TEACHER CONSTRAINTS
            |--------------------------------------------------------------------------
            */

            [
                'code' => 'TEACHER_NOT_AVAILABLE',
                'name' => 'Teacher Not Available',
                'description' => 'Teacher is unavailable during specific days or periods',
                'category' => 'TEACHER',
                'scope' => 'TEACHER',
                'default_weight' => 100,
                'is_hard_capable' => true,
                'param_schema' => [
                    'days' => [
                        'type' => 'array',
                        'required' => true,
                        'label' => 'Unavailable Days',
                    ],
                    'periods' => [
                        'type' => 'array',
                        'required' => false,
                        'label' => 'Unavailable Periods',
                    ],
                ],
            ],

            [
                'code' => 'NO_TEACHER_GAPS',
                'name' => 'No Gaps for Teacher',
                'description' => 'Avoid idle gaps between teacher lessons',
                'category' => 'TEACHER',
                'scope' => 'TEACHER',
                'default_weight' => 70,
                'is_hard_capable' => false,
                'param_schema' => null,
            ],

            /*
            |--------------------------------------------------------------------------
            | CLASS / STUDENT CONSTRAINTS
            |--------------------------------------------------------------------------
            */

            [
                'code' => 'MAX_LESSONS_PER_DAY',
                'name' => 'Maximum Lessons Per Day',
                'description' => 'Limits the number of lessons per day',
                'category' => 'TIME',
                'scope' => 'CLASS',
                'default_weight' => 80,
                'is_hard_capable' => false,
                'param_schema' => [
                    'max_lessons' => [
                        'type' => 'integer',
                        'required' => true,
                        'label' => 'Maximum Lessons',
                        'min' => 1,
                    ],
                ],
            ],

            [
                'code' => 'NO_CONSECUTIVE_SAME_SUBJECT',
                'name' => 'No Consecutive Same Subject',
                'description' => 'Avoid scheduling the same subject consecutively',
                'category' => 'STUDENT',
                'scope' => 'CLASS_SUBJECT',
                'default_weight' => 60,
                'is_hard_capable' => false,
                'param_schema' => null,
            ],

            /*
            |--------------------------------------------------------------------------
            | ROOM CONSTRAINTS
            |--------------------------------------------------------------------------
            */

            [
                'code' => 'ROOM_CAPACITY_LIMIT',
                'name' => 'Room Capacity Limit',
                'description' => 'Room must have sufficient capacity',
                'category' => 'ROOM',
                'scope' => 'ROOM',
                'default_weight' => 100,
                'is_hard_capable' => true,
                'param_schema' => [
                    'min_capacity' => [
                        'type' => 'integer',
                        'required' => true,
                        'label' => 'Minimum Capacity',
                        'min' => 1,
                    ],
                ],
            ],

            /*
            |--------------------------------------------------------------------------
            | PERIOD / BREAK HARD CONSTRAINTS
            |--------------------------------------------------------------------------
            */

            [
                'code' => 'LUNCH_BREAK_FIXED',
                'name' => 'Lunch Break (Fixed)',
                'description' => 'Lunch break period must not contain any teaching activity',
                'category' => 'TIME',
                'scope' => 'GLOBAL', // ✅ FIXED
                'default_weight' => 100,
                'is_hard_capable' => true,
                'param_schema' => [
                    'period_type_code' => [
                        'type' => 'string',
                        'required' => true,
                        'allowed' => ['LUNCH'],
                    ],
                ],
            ],

            [
                'code' => 'SHORT_BREAK_FIXED',
                'name' => 'Short Break (Fixed)',
                'description' => 'Short break periods must not contain any teaching activity',
                'category' => 'TIME',
                'scope' => 'GLOBAL', // ✅ FIXED
                'default_weight' => 100,
                'is_hard_capable' => true,
                'param_schema' => [
                    'period_type_code' => [
                        'type' => 'string',
                        'required' => true,
                        'allowed' => ['BREAK'],
                    ],
                ],
            ],

            /*
            |--------------------------------------------------------------------------
            | GLOBAL / ACTIVITY CONSTRAINTS
            |--------------------------------------------------------------------------
            */

            [
                'code' => 'ACTIVITY_TIME_WINDOW',
                'name' => 'Activity Time Window',
                'description' => 'Activity must be scheduled within a time range',
                'category' => 'TIME',
                'scope' => 'ACTIVITY',
                'default_weight' => 90,
                'is_hard_capable' => true,
                'param_schema' => [
                    'start_time' => [
                        'type' => 'time',
                        'required' => true,
                        'label' => 'Start Time',
                    ],
                    'end_time' => [
                        'type' => 'time',
                        'required' => true,
                        'label' => 'End Time',
                    ],
                ],
            ],
        ];

        foreach ($types as $type) {
            ConstraintType::updateOrCreate(
                ['code' => $type['code']],
                [
                    'name' => $type['name'],
                    'description' => $type['description'],
                    'category' => $type['category'],
                    'scope' => $type['scope'],
                    'default_weight' => $type['default_weight'],
                    'is_hard_capable' => $type['is_hard_capable'],
                    'param_schema' => $type['param_schema'],
                    'is_system' => true,
                    'is_active' => true,
                ]
            );
        }
    }
}

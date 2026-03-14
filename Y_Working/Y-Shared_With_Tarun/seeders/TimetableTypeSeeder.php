<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Modules\SmartTimetable\Models\TimetableType;

class TimetableTypeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        TimetableType::insert([
            [
                'code' => 'REGULAR',
                'name' => 'Regular School Day',
                'description' => 'Standard teaching day with classes and breaks',

                'shift_id' => null,
                'default_period_set_id' => null,
                'day_type_id' => null,

                'effective_from_date' => null,
                'effective_to_date' => null,

                'school_start_time' => '08:00',
                'school_end_time' => '14:30',

                'assembly_duration_min' => 15,
                'short_break_duration_min' => 10,
                'lunch_duration_min' => 30,

                'has_exam' => false,
                'has_teaching' => true,

                'ordinal' => 1,
                'is_default' => true,
                'is_system' => true,
                'is_active' => true,

                'created_at' => now(),
                'updated_at' => now(),
            ],

            [
                'code' => 'EXAM',
                'name' => 'Examination Day',
                'description' => 'Exam-focused timetable with no regular teaching periods',

                'shift_id' => null,
                'default_period_set_id' => null,
                'day_type_id' => null,

                'effective_from_date' => null,
                'effective_to_date' => null,

                'school_start_time' => '09:00',
                'school_end_time' => '13:00',

                'assembly_duration_min' => null,
                'short_break_duration_min' => null,
                'lunch_duration_min' => null,

                'has_exam' => true,
                'has_teaching' => false,

                'ordinal' => 2,
                'is_default' => false,
                'is_system' => true,
                'is_active' => true,

                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}

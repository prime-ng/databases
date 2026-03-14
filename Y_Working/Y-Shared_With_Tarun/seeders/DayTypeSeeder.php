<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Modules\SmartTimetable\Models\DayType;

class DayTypeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $dayTypes = [
            [
                'code' => 'WD',
                'name' => 'Working Day',
                'description' => 'Regular full working academic day',
                'is_working_day' => true,
                'reduced_periods' => false,
                'ordinal' => 1,
            ],
            [
                'code' => 'HD',
                'name' => 'Half Day',
                'description' => 'Working day with reduced periods',
                'is_working_day' => true,
                'reduced_periods' => true,
                'ordinal' => 2,
            ],
            [
                'code' => 'SD',
                'name' => 'Short Day',
                'description' => 'Shortened timetable due to special conditions',
                'is_working_day' => true,
                'reduced_periods' => true,
                'ordinal' => 3,
            ],
            [
                'code' => 'EX',
                'name' => 'Exam Day',
                'description' => 'Examination day (no regular teaching)',
                'is_working_day' => true,
                'reduced_periods' => false,
                'ordinal' => 4,
            ],
            [
                'code' => 'PTM',
                'name' => 'PTM Day',
                'description' => 'Parent Teacher Meeting day',
                'is_working_day' => false,
                'reduced_periods' => false,
                'ordinal' => 5,
            ],
            [
                'code' => 'H',
                'name' => 'Holiday',
                'description' => 'School closed for holiday',
                'is_working_day' => false,
                'reduced_periods' => false,
                'ordinal' => 6,
            ],
            [
                'code' => 'F',
                'name' => 'Festival',
                'description' => 'Festival holiday',
                'is_working_day' => false,
                'reduced_periods' => false,
                'ordinal' => 7,
            ],
            [
                'code' => 'PD',
                'name' => 'Preparation Day',
                'description' => 'Teacher preparation or training day',
                'is_working_day' => false,
                'reduced_periods' => false,
                'ordinal' => 8,
            ],
            [
                'code' => 'EM',
                'name' => 'Emergency Closure',
                'description' => 'Emergency closure (weather, safety)',
                'is_working_day' => false,
                'reduced_periods' => false,
                'ordinal' => 9,
            ],
        ];

        foreach ($dayTypes as $type) {
            DayType::updateOrCreate(
                ['code' => $type['code']],
                array_merge($type, ['is_active' => true])
            );
        }
    }
}

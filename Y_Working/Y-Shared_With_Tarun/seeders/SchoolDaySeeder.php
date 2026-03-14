<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Modules\SmartTimetable\Models\SchoolDay;

class SchoolDaySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $days = [
            [
                'code' => 'MON',
                'name' => 'Monday',
                'short_name' => 'Mon',
                'day_of_week' => 1,
                'ordinal' => 1,
                'is_school_day' => true,
            ],
            [
                'code' => 'TUE',
                'name' => 'Tuesday',
                'short_name' => 'Tue',
                'day_of_week' => 2,
                'ordinal' => 2,
                'is_school_day' => true,
            ],
            [
                'code' => 'WED',
                'name' => 'Wednesday',
                'short_name' => 'Wed',
                'day_of_week' => 3,
                'ordinal' => 3,
                'is_school_day' => true,
            ],
            [
                'code' => 'THU',
                'name' => 'Thursday',
                'short_name' => 'Thu',
                'day_of_week' => 4,
                'ordinal' => 4,
                'is_school_day' => true,
            ],
            [
                'code' => 'FRI',
                'name' => 'Friday',
                'short_name' => 'Fri',
                'day_of_week' => 5,
                'ordinal' => 5,
                'is_school_day' => true,
            ],
            [
                'code' => 'SAT',
                'name' => 'Saturday',
                'short_name' => 'Sat',
                'day_of_week' => 6,
                'ordinal' => 6,
                'is_school_day' => true,
            ],
            [
                'code' => 'SUN',
                'name' => 'Sunday',
                'short_name' => 'Sun',
                'day_of_week' => 7,
                'ordinal' => 7,
                'is_school_day' => false,
            ],
        ];

        foreach ($days as $day) {
            SchoolDay::updateOrCreate(
                ['day_of_week' => $day['day_of_week']], // unique key
                array_merge($day, [
                    'is_active' => true,
                ])
            );
        }
    }
}

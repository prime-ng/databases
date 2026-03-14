<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Modules\SmartTimetable\Models\PeriodType;

class PeriodTypeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $now = Carbon::now();

        $types = [

            [
                'code' => 'ORAL',
                'name' => 'Oral Class',
                'counts_as_teaching' => true,
                'description' => 'Oral-based teaching (Nursery, LKG, UKG)',
            ],
            [
                'code' => 'THEORY',
                'name' => 'Theory / Lecture',
                'counts_as_teaching' => true,
                'description' => 'Standard classroom lecture',
            ],
            [
                'code' => 'PRACTICAL',
                'name' => 'Practical / Lab',
                'counts_as_teaching' => true,
                'description' => 'Lab or hands-on practical session',
            ],
            [
                'code' => 'ACTIVITY',
                'name' => 'Activity',
                'counts_as_teaching' => true,
                'description' => 'Games, Art, Music, Dance, Yoga, Hobby',
            ],
            [
                'code' => 'LIBRARY',
                'name' => 'Library Period',
                'counts_as_teaching' => true,
                'description' => 'Reading / Library-based learning',
            ],

            /* ---------- Non-Teaching Periods ---------- */

            [
                'code' => 'BREAK',
                'name' => 'Short Break',
                'counts_as_teaching' => false,
                'description' => 'Short recess break',
            ],
            [
                'code' => 'LUNCH',
                'name' => 'Lunch Break',
                'counts_as_teaching' => false,
                'description' => 'Lunch / mid-day break',
            ],
        ];

        foreach ($types as $type) {
            DB::table('tt_period_types')->updateOrInsert(
                ['code' => $type['code']],
                [
                    'name' => $type['name'],
                    'counts_as_teaching' => $type['counts_as_teaching'],
                    'description' => $type['description'],
                    'created_at' => $now,
                    'updated_at' => $now,
                ]
            );
        }

        $this->command->info('✅ PeriodTypeSeeder executed successfully.');
    }
}

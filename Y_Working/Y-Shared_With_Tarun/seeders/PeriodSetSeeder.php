<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class PeriodSetSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $now = Carbon::now();

        $periodSets = [

            // /* ---------- Pre-Primary (Nursery / LKG / UKG) ---------- */
            // [
            //     'code' => 'PRE_PRIMARY_5',
            //     'name' => 'Pre-Primary (5 Periods)',
            //     'description' => 'Nursery, LKG, UKG – oral, activity-based shorter day',
            //     'total_periods' => 5,
            //     'teaching_periods' => 5,
            //     'start_time' => '08:30:00',
            //     'end_time' => '12:00:00',
            //     'applicable_class_ids' => json_encode([-2, -1, 0]),
            //     'is_default' => false,
            //     'is_active' => true,
            // ],

            // /* ---------- Primary (Classes 1–5) ---------- */
            // [
            //     'code' => 'PRIMARY_6',
            //     'name' => 'Primary School (6 Periods)',
            //     'description' => 'Classes 1–5 with balanced academics and activities',
            //     'total_periods' => 6,
            //     'teaching_periods' => 6,
            //     'start_time' => '08:30:00',
            //     'end_time' => '13:30:00',
            //     'applicable_class_ids' => json_encode([1, 2, 3, 4, 5]),
            //     'is_default' => false,
            //     'is_active' => true,
            // ],

            // /* ---------- Middle School (Classes 6–8) ---------- */
            // [
            //     'code' => 'MIDDLE_7',
            //     'name' => 'Middle School (7 Periods)',
            //     'description' => 'Classes 6–8 with theory + labs + activities',
            //     'total_periods' => 7,
            //     'teaching_periods' => 7,
            //     'start_time' => '08:00:00',
            //     'end_time' => '14:00:00',
            //     'applicable_class_ids' => json_encode([6, 7, 8]),
            //     'is_default' => false,
            //     'is_active' => true,
            // ],

            /* ---------- Secondary (Classes 9–10) ---------- */
            [
                'code' => 'SECONDARY_8',
                'name' => 'Secondary School (8 Periods)',
                'description' => 'Classes 9–10 with theory + practical focus',
                'total_periods' => 8,
                'teaching_periods' => 8,
                'start_time' => '08:00:00',
                'end_time' => '14:40:00',
                'applicable_class_ids' => json_encode([9, 10]),
                'is_default' => true, // ✅ DEFAULT DAY STRUCTURE
                'is_active' => true,
            ],

            /* ---------- Senior Secondary (Classes 11–12) ---------- */
            // [
            //     'code' => 'SENIOR_9',
            //     'name' => 'Senior Secondary (9 Periods)',
            //     'description' => 'Classes 11–12 with extended practical & lab sessions',
            //     'total_periods' => 9,
            //     'teaching_periods' => 9,
            //     'start_time' => '08:00:00',
            //     'end_time' => '15:30:00',
            //     'applicable_class_ids' => json_encode([11, 12]),
            //     'is_default' => false,
            //     'is_active' => true,
            // ],

            // /* ---------- Half Day / Special ---------- */
            // [
            //     'code' => 'HALF_DAY_4',
            //     'name' => 'Half Day (4 Periods)',
            //     'description' => 'Events, exams, PTMs, special schedules',
            //     'total_periods' => 4,
            //     'teaching_periods' => 4,
            //     'start_time' => '08:00:00',
            //     'end_time' => '11:30:00',
            //     'applicable_class_ids' => null,
            //     'is_default' => false,
            //     'is_active' => true,
            // ],
        ];

        foreach ($periodSets as $set) {
            DB::table('tt_period_sets')->updateOrInsert(
                ['code' => $set['code']],
                [
                    'name' => $set['name'],
                    'description' => $set['description'],
                    'total_periods' => $set['total_periods'],
                    'teaching_periods' => $set['teaching_periods'],
                    'start_time' => $set['start_time'],
                    'end_time' => $set['end_time'],
                    'applicable_class_ids' => $set['applicable_class_ids'],
                    'is_default' => $set['is_default'],
                    'is_active' => $set['is_active'],
                    'created_at' => $now,
                    'updated_at' => $now,
                ]
            );
        }

        /* ---------- Ensure ONLY one default ---------- */
        DB::table('tt_period_sets')
            ->where('code', '!=', 'SECONDARY_8')
            ->update(['is_default' => false]);

        $this->command->info('✅ PeriodSetSeeder executed successfully.');
    }
}

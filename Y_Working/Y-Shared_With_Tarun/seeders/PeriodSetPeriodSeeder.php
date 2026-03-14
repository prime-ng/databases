<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class PeriodSetPeriodSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $periodSet = DB::table('tt_period_sets')
            ->where('code', 'SECONDARY_8')
            ->first();

        if (!$periodSet) {
            throw new \RuntimeException(
                'PeriodSet with code SECONDARY_8 not found.'
            );
        }

        /* ---------- Load Period Types ---------- */
        $periodTypes = DB::table('tt_period_types')
            ->pluck('id', 'code')
            ->toArray();

        /* ---------- Required Period Types ---------- */
        foreach (['THEORY', 'ACTIVITY', 'PRACTICAL', 'BREAK', 'LUNCH'] as $requiredCode) {
            if (!isset($periodTypes[$requiredCode])) {
                throw new \RuntimeException(
                    "PeriodType '{$requiredCode}' not found."
                );
            }
        }

        /*
        |--------------------------------------------------------------------------
        | Period Structure (Secondary – 8 Periods)
        |--------------------------------------------------------------------------
        | Ordinal includes breaks for sequencing
        */
        $periods = [
            ['THEORY', 'P1', '1', 1, '08:00', '08:45'],
            ['THEORY', 'P2', '2', 2, '08:45', '09:30'],
            ['THEORY', 'P3', '3', 3, '09:30', '10:15'],
            ['BREAK', 'SBREAK', '4', 4, '10:15', '10:30'],
            ['PRACTICAL', 'P4', '5', 5, '10:30', '11:15'],
            ['THEORY', 'P5', '6', 6, '11:15', '12:00'],
            ['LUNCH', 'P7', '7', 7, '12:00', '12:30'],
            ['ACTIVITY', 'P6', '8', 8, '12:30', '13:15'],
            ['PRACTICAL', 'P7', '9', 9, '13:15', '14:00'],
            ['THEORY', 'P8', '10', 10, '14:00', '14:40'],
        ];

        /* ---------- Insert / Replace ---------- */
        foreach ($periods as [$type, $code, $short, $ord, $start, $end]) {

            DB::table('tt_period_set_period_jnt')
                ->where('period_set_id', $periodSet->id)
                ->where('code', $code)
                ->delete();

            DB::table('tt_period_set_period_jnt')->insert([
                'period_set_id' => $periodSet->id,
                'period_type_id' => $periodTypes[$type],
                'code' => $code,
                'short_name' => $short,
                'period_ord' => $ord,
                'start_time' => $start,
                'end_time' => $end,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        $this->command->info('✅ PeriodSetPeriodSeeder executed successfully for SECONDARY_8.');
    }
}

<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class AcademicSessionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $startYear = 2020;
        $endYear = 2050;

        $sessions = [];

        for ($year = $startYear; $year < $endYear; $year++) {
            $shortName = $year . '-' . substr($year + 1, 2);
            $name = "Session - $shortName";

            $startDate = Carbon::create($year, 4, 1)->toDateString();   // Assuming session starts on April 1st
            $endDate = Carbon::create($year + 1, 3, 31)->toDateString(); // Ends on March 31st next year

            $sessions[] = [
                'short_name' => $shortName,
                'name' => $name,
                'start_date' => $startDate,
                'end_date' => $endDate,
                'is_current' => ($year == 2026) ? 1 : 0, // Example: mark 2025-26 as active by default
                'created_at' => now(),
                'updated_at' => now(),
            ];
        }
        DB::connection('global_master_mysql')->table('glb_academic_sessions')->insert($sessions);
    }
}

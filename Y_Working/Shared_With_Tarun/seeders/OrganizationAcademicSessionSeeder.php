<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Carbon\Carbon;
use Modules\SchoolSetup\Models\Organization;

class OrganizationAcademicSessionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Fetch all organizations to create sessions for
        $organizations = Organization::all();
        $academicSessionIds = DB::table('glb_academic_sessions')->pluck('id')->toArray();

        foreach ($organizations as $organization) {
            // Define 2-3 academic sessions per organization
            $sessionCount = rand(2, 3);

            for ($i = 1; $i <= $sessionCount; $i++) {
                // Generate short_name like "2023-24" by incrementing years
                $startYear = 2022 + $i;
                $endYear = $startYear + 1;
                $shortName = "$startYear-" . substr($endYear, 2);

                // Session display name
                $name = "Session - $shortName";

                // Calculate start and end date for the session
                // Typically academic year start July 1, end June 30 next year
                $startDate = Carbon::create($startYear, 7, 1);
                $endDate = Carbon::create($endYear, 6, 30);

                // Set is_current true for last session only
                $isCurrent = ($i === $sessionCount) ? 1 : 0;

                $academicSessionId = $academicSessionIds[array_rand($academicSessionIds)];

                DB::table('sch_org_academic_sessions_jnt')->insert([
                    'organization_id' => $organization->id,
                    'academic_session_id' => $academicSessionId,
                    'short_name' => $shortName,
                    'name' => $name,
                    'start_date' => $startDate->toDateString(),
                    'end_date' => $endDate->toDateString(),
                    'is_current' => $isCurrent,
                    'is_active' => 1,
                    'current_flag' => $isCurrent,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }
    }
}

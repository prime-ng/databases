<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Modules\Prime\Models\AcademicSession;
use Modules\SmartTimetable\Models\ClassGroupRequirement;

class ClassGroupRequirementSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        /*
        |--------------------------------------------------------------------------
        | Fetch required foreign keys safely
        |--------------------------------------------------------------------------
        */

        $classGroupId = DB::table('sch_class_groups')->value('id');
        $classSubgroupId = DB::table('tt_class_subgroups')->value('id');
        $academicSessionId = AcademicSession::current()->first();
        /*
        |--------------------------------------------------------------------------
        | Guard: Seeder requires at least one group & subgroup
        |--------------------------------------------------------------------------
        */

        if (!$classGroupId || !$classSubgroupId) {
            $this->command?->warn(
                'Skipping ClassGroupRequirementSeeder: missing class group or subgroup.'
            );
            return;
        }

        /*
        |--------------------------------------------------------------------------
        | 1. Class Group Requirement
        |--------------------------------------------------------------------------
        */

        ClassGroupRequirement::create([
            'class_group_id' => $classGroupId,
            'class_subgroup_id' => null,
            'academic_session_id' => $academicSessionId->id,

            'weekly_periods' => 30,
            'min_periods_per_week' => 25,
            'max_periods_per_week' => 35,

            'min_per_day' => 4,
            'max_per_day' => 7,
            'min_gap_periods' => 1,

            'allow_consecutive' => true,
            'max_consecutive' => 3,

            'preferred_periods_json' => [
                'MON' => [1, 2, 3],
                'TUE' => [2, 3, 4],
            ],

            'avoid_periods_json' => [
                'FRI' => [7, 8],
            ],

            'spread_evenly' => true,
            'priority' => 80,
            'is_active' => true,
        ]);

        /*
        |--------------------------------------------------------------------------
        | 2. Class Subgroup Requirement
        |--------------------------------------------------------------------------
        */

        ClassGroupRequirement::create([
            'class_group_id' => $classGroupId,
            'class_subgroup_id' => null,
            'academic_session_id' => $academicSessionId->id,

            'weekly_periods' => 12,
            'min_periods_per_week' => 10,
            'max_periods_per_week' => 14,

            'min_per_day' => 2,
            'max_per_day' => 4,
            'min_gap_periods' => 0,

            'allow_consecutive' => false,
            'max_consecutive' => 2,

            'preferred_periods_json' => [
                'WED' => [3, 4],
            ],

            'avoid_periods_json' => null,

            'spread_evenly' => true,
            'priority' => 60,
            'is_active' => true,
        ]);
    }
}

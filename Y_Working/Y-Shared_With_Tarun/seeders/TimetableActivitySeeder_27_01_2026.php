<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Modules\Prime\Models\AcademicSession;
use Modules\SmartTimetable\Models\Activity;
use RuntimeException;

class TimetableActivitySeeder extends Seeder
{
    public function run(): void
    {
        /*
        |--------------------------------------------------------------------------
        | Academic Session (REQUIRED)
        |--------------------------------------------------------------------------
        */
        $academicSessionId = AcademicSession::where('is_current', true)->value('id');

        if (!$academicSessionId) {
            $this->command->warn('No active academic session found. Skipping ActivitySeeder.');
            return;
        }

        /*
        |--------------------------------------------------------------------------
        | Active Class Groups
        |--------------------------------------------------------------------------
        */
        $classGroups = DB::table('sch_class_groups_jnt')
            ->where('is_active', true)
            ->get(['id', 'name', 'code', 'rooms_type_id']);

        if ($classGroups->isEmpty()) {
            $this->command->warn('No class groups found. Skipping ActivitySeeder.');
            return;
        }

        /*
        |--------------------------------------------------------------------------
        | Room Types (for random preference)
        |--------------------------------------------------------------------------
        */
        $roomTypeIds = DB::table('sch_rooms_type')
            ->where('is_active', true)
            ->pluck('id')
            ->toArray();

        if (empty($roomTypeIds)) {
            $this->command->warn('No room types found. Skipping ActivitySeeder.');
            return;
        }

        /*
        |--------------------------------------------------------------------------
        | Generate Activities (1 per Class Group)
        |--------------------------------------------------------------------------
        */
        foreach ($classGroups as $cg) {

            Activity::updateOrCreate(
                [
                    'class_group_jnt_id' => $cg->id,
                    'class_subgroup_id' => null,
                ],
                [
                    /* ---------- Identity ---------- */

                    'uuid' => Str::uuid()->getBytes(),

                    'code' => Str::upper(
                        "ACT-{$cg->code}"
                    ),

                    'name' => "{$cg->name} Activity",
                    'description' => "Auto-generated activity for {$cg->name}",

                    /* ---------- Context ---------- */

                    'academic_session_id' => $academicSessionId,

                    /* ---------- Load & Duration ---------- */

                    'duration_periods' => collect([1, 2])->random(),
                    'weekly_periods' => rand(5, 6),

                    'split_allowed' => (bool) rand(0, 1),
                    'is_compulsory' => true,

                    'priority' => collect([50, 60, 70, 80, 90, 100])->random(),
                    'difficulty_score' => collect([50, 60, 70, 80, 90, 100])->random(),

                    /* ---------- Room Preferences ---------- */

                    'requires_room' => true,
                    'preferred_room_type_id' => collect($roomTypeIds)->random(),
                    'preferred_room_ids' => null,

                    /* ---------- Status ---------- */

                    'status' => 'ACTIVE',
                    'is_active' => true,

                    'created_by' => null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }

        $this->command->info('✅ ActivitySeeder completed: one activity per class group created.');

    }

}

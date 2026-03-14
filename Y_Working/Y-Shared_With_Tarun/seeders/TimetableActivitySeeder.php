<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Modules\Prime\Models\AcademicSession;
use Modules\SchoolSetup\Models\Teacher;
use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Models\TeacherAssignmentRole;
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
            $this->command->error('❌ No active academic session found.');
            return;
        }

        /*
        |--------------------------------------------------------------------------
        | Class Groups
        |--------------------------------------------------------------------------
        */
        $classGroups = DB::table('tt_class_groups_jnt')
            ->where('is_active', true)
            ->get();

        if ($classGroups->isEmpty()) {
            $this->command->error('❌ No active class groups found.');
            return;
        }

        /*
        |--------------------------------------------------------------------------
        | Room Type (default)
        |--------------------------------------------------------------------------
        */
        $defaultRoomTypeId = DB::table('sch_rooms_type')
            ->where('is_active', true)
            ->value('id');

        if (!$defaultRoomTypeId) {
            $this->command->error('❌ No active room type found.');
            return;
        }

        /*
        |--------------------------------------------------------------------------
        | Teacher Roles
        |--------------------------------------------------------------------------
        */
        $roles = TeacherAssignmentRole::where('is_active', true)
            ->pluck('id', 'code')
            ->toArray();

        if (!isset($roles['PRIMARY'])) {
            $this->command->error('❌ PRIMARY teacher role not found.');
            return;
        }

        $primaryRoleId = $roles['PRIMARY'];

        /*
        |--------------------------------------------------------------------------
        | Class-wise Teachers (FROM PDF)
        |--------------------------------------------------------------------------
        */
        // $classTeachers = [
        //     '7-A' => [
        //         'Urmil Joshi',
        //         'Radha Bhatt',
        //         'Parul Agarwal',
        //         'Shilpi Negi',
        //         'Radha Pilkhwal',
        //         'Sangeeta Kholia',
        //         'Neetu Tiwari',
        //         'Pragati Bisht',
        //         'Aman Chaurasiya',
        //         'Manorma Tewari',
        //         'Smita Sah',
        //         'Neeru Joshi Goel',
        //     ],
        //     '7-B' => [
        //         'Urmil Joshi',
        //         'Santosh Gaurav Rawat',
        //         'Parul Agarwal',
        //         'Meenu Amit Maurya',
        //         'Radha Bhatt',
        //         'Sangeeta Kholia',
        //         'Neetu Tiwari',
        //         'Pragati Bisht',
        //         'Aman Chaurasiya',
        //         'Manorma Tewari',
        //         'Priyanka Agarwal Mittal',
        //         'Neeru Joshi Goel',
        //     ],
        //     '8-A' => [
        //         'Urmil Joshi',
        //         'Radha Bhatt',
        //         'Priyanka Agarwal Mittal',
        //         'Meenu Amit Maurya',
        //         'Robin Kumar Arya',
        //         'Smita Sah',
        //         'Ankit Pathak',
        //         'Bhawana Kafaltiya',
        //         'Aman Chaurasiya',
        //         'Manorma Tewari',
        //         'Sangeeta Kholia',
        //         'Neeru Joshi Goel',
        //     ],
        //     '8-B' => [
        //         'Pooja Joshi',
        //         'Robin Kumar Arya',
        //         'Priyanka Agarwal Mittal',
        //         'Ankit Pathak',
        //         'Sangeeta Kholia',
        //         'Meenu Amit Maurya',
        //         'Pragati Bisht',
        //         'Aman Chaurasiya',
        //         'Manorma Tewari',
        //         'Smita Sah',
        //         'Neeru Joshi Goel',
        //     ],
        // ];

        /*
        |--------------------------------------------------------------------------
        | Create Activities + Assign Teachers
        |--------------------------------------------------------------------------
        */
        foreach ($classGroups as $cg) {

            /*
            |--------------------------------------------------
            | Create ONE activity per class group
            |--------------------------------------------------
            */
            $activity = Activity::updateOrCreate(
                [
                    'class_group_jnt_id' => $cg->id,
                    'class_subgroup_id' => null,
                ],
                [
                    'uuid' => Str::uuid()->getBytes(),
                    'code' => $cg->code,
                    'name' => $cg->name,
                    'description' => "Complete academic workload for {$cg->name}",
                    'academic_session_id' => $academicSessionId,

                    'weekly_periods' => 6,
                    'duration_periods' => 1,

                    'split_allowed' => false,
                    'is_compulsory' => true,

                    'priority' => rand(1, 10) * 10,
                    'difficulty_score' => rand(1, 10) * 10,

                    'requires_room' => true,
                    'preferred_room_type_id' => $defaultRoomTypeId,

                    'status' => 'ACTIVE',
                    'is_active' => true,

                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );

            // /*
            //     |--------------------------------------------------------------------------
            //     | Assign ONE random teacher to this activity (MINIMAL & SAFE)
            //     |--------------------------------------------------------------------------
            //     */

            // // Fetch ONE random teacher ID from tenant DB
            // $teacherId = DB::table('sch_teachers')->inRandomOrder()->value('id');

            // if (!$teacherId) {
            //     $this->command->warn('⚠️ No teachers found in sch_teachers table.');
            //     continue;
            // }

            // // PRIMARY role ID (must exist)
            // if (!isset($primaryRoleId)) {
            //     $this->command->error('❌ PRIMARY assignment role ID missing.');
            //     continue;
            // }

            // // Insert (or ignore duplicate safely)
            // DB::table('tt_activity_teachers')->insertOrIgnore([
            //     'activity_id' => $activity->id,
            //     'teacher_id' => $teacherId,
            //     'assignment_role_id' => $primaryRoleId,
            //     'ordinal' => 1,
            //     'is_required' => true,
            //     'is_active' => true,
            //     'created_at' => now(),
            //     'updated_at' => now(),
            // ]);

            // $this->command->line(
            //     "✅ Teacher {$teacherId} assigned to activity {$activity->id}"
            // );
        }

        $this->command->info('🎉 Real-life activities successfully seeded.');
    }

    protected function extractClassCode(string $name): ?string
    {
        // Normalize
        $name = strtoupper(trim($name));

        // Match: CLASS VII(A)
        if (!preg_match('/CLASS\s*([IVX]+)\s*\(\s*([A-Z])\s*\)/', $name, $m)) {
            return null;
        }

        $roman = $m[1];
        $section = $m[2];

        $romanMap = [
            'I' => 1,
            'II' => 2,
            'III' => 3,
            'IV' => 4,
            'V' => 5,
            'VI' => 6,
            'VII' => 7,
            'VIII' => 8,
            'IX' => 9,
            'X' => 10,
            'XI' => 11,
            'XII' => 12,
        ];

        return $romanMap[$roman] . '-' . $section ?? null;
    }
}

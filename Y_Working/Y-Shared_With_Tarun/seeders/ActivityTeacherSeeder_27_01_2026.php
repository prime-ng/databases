<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Modules\SchoolSetup\Models\Teacher;
use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Models\TeacherAssignmentRole;

class ActivityTeacherSeeder extends Seeder
{
    private const MAX_ACTIVITIES_PER_TEACHER = 6;
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $this->command->info('Seeding tt_activity_teachers with workload limits...');

        /*
        |----------------------------------------------------------------------
        | Fetch roles
        |----------------------------------------------------------------------
        */

        $roles = TeacherAssignmentRole::where('is_active', true)
            ->pluck('id', 'code')
            ->toArray();

        if (!isset($roles['PRIMARY'])) {
            $this->command->error('PRIMARY assignment role not found.');
            return;
        }

        $assistantRoleId = $roles['ASSISTANT'] ?? null;

        /*
        |----------------------------------------------------------------------
        | Fetch teachers and initialize load counter
        |----------------------------------------------------------------------
        */

        $teachers = Teacher::pluck('id')->values();

        if ($teachers->isEmpty()) {
            $this->command->warn('No active teachers found.');
            return;
        }

        // Track current load per teacher
        $teacherLoad = DB::table('tt_activity_teachers')
            ->select('teacher_id', DB::raw('COUNT(*) as cnt'))
            ->groupBy('teacher_id')
            ->pluck('cnt', 'teacher_id')
            ->toArray();

        /*
        |----------------------------------------------------------------------
        | Assign teachers to activities
        |----------------------------------------------------------------------
        */

        Activity::where('is_active', true)
            ->chunk(100, function ($activities) use ($teachers, &$teacherLoad, $roles, $assistantRoleId) {

                foreach ($activities as $activity) {

                    // Skip if already assigned
                    $alreadyAssigned = DB::table('tt_activity_teachers')
                        ->where('activity_id', $activity->id)
                        ->exists();

                    if ($alreadyAssigned) {
                        continue;
                    }

                    // Find eligible teachers (load < MAX)
                    $eligibleTeachers = $teachers->filter(function ($teacherId) use ($teacherLoad) {
                        return ($teacherLoad[$teacherId] ?? 0) < self::MAX_ACTIVITIES_PER_TEACHER;
                    });

                    if ($eligibleTeachers->isEmpty()) {
                        $this->command->warn(
                            "No eligible teachers left for activity ID {$activity->id}"
                        );
                        continue;
                    }

                    // Pick 1 or 2 teachers
                    // Pick exactly ONE eligible teacher
                    $teacherId = $eligibleTeachers->shuffle()->first();

                    DB::table('tt_activity_teachers')->insert([
                        'activity_id' => $activity->id,
                        'teacher_id' => $teacherId,
                        'assignment_role_id' => $roles['PRIMARY'],
                        'is_required' => true,
                        'ordinal' => 1,
                        'is_active' => true,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);

                    // Increment teacher load
                    $teacherLoad[$teacherId] = ($teacherLoad[$teacherId] ?? 0) + 1;
                }
            });

        $this->command->info('Activity-teacher assignments seeded successfully.');
    }
}

<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Modules\SchoolSetup\Models\StudyFormat;
use Modules\SchoolSetup\Models\Subject;
use Modules\SchoolSetup\Models\Teacher;
use Modules\SmartTimetable\Models\ClassGroupJnt;

class ClassTeacherSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $now = Carbon::now();

        /*
        |--------------------------------------------------------------------------
        | STEP 1: Create sch_teachers from users with role 'Teacher'
        |--------------------------------------------------------------------------
        */

        $teacherUsers = User::role('Teacher')->get();

        if ($teacherUsers->isEmpty()) {
            $this->command->warn('No users found with role Teacher. Seeder aborted.');
            return;
        }

        $teacherIds = [];

        foreach ($teacherUsers as $user) {
            $teacher = Teacher::updateOrCreate(
                [
                    'user_id' => $user->id,
                ],
                [
                    'joining_date' => $now->copy()->subYears(rand(1, 10)),
                    'total_experience_years' => rand(1, 20),
                    'highest_qualification' => 'Graduate',
                    'specialization' => 'General',
                    'last_institution' => 'Auto Seeded School',
                    'skills' => 'Teaching, Classroom Management',
                    'notes' => 'Auto-created from Teacher role user',
                    'created_at' => $now,
                    'updated_at' => $now,
                ]
            );

            $teacherIds[] = $teacher->id;
        }

        /*
        |--------------------------------------------------------------------------
        | STEP 2: Seed subject–teacher eligibility (GLOBAL, NOT per class)
        |--------------------------------------------------------------------------
        */

        $subjects = Subject::where('is_active', true)->get();
        //$studyFormats = $subjects->subjectStudyFormats;

        foreach ($subjects as $subject) {
            foreach ($subject->subjectStudyFormats as $studyFormat) {

                // Pick 2–3 teachers as eligible (not all!)
                $eligibleTeachers = collect($teacherIds)
                    ->shuffle()
                    ->take(rand(2, 3));

                foreach ($eligibleTeachers as $index => $teacherId) {
                    DB::table('sch_subject_teachers')->updateOrInsert(
                        [
                            'teacher_id' => $teacherId,
                            'subject_id' => $subject->id,
                            'study_format_id' => $studyFormat->id,
                        ],
                        [
                            'priority' => $index === 0 ? 'PRIMARY' : 'SECONDARY',
                            'proficiency' => rand(50, 95),
                            'notes' => 'Auto-seeded subject eligibility',
                            'effective_from' => $now->toDateString(),
                            'effective_to' => null,
                            'is_active' => true,
                            'created_at' => $now,
                            'updated_at' => $now,
                        ]
                    );
                }
            }
        }
    }
}

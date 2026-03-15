<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Modules\SchoolSetup\Models\RoomType;
use Modules\SchoolSetup\Models\SubjectGroup;
use Modules\SchoolSetup\Models\SubjectStudyFormatClass;
use Modules\SmartTimetable\Models\ClassGroupJnt;

class SubjectGroupSubjectSeeder extends Seeder
{/**
 * Run the database seeds.
 */
    public function run(): void
    {
        // Get all subject groups
        $subjectGroups = SubjectGroup::all();

        // Get all class group jnt entries
        $classGroupJnts = SubjectStudyFormatClass::with(['subjectStudyFormat.subject', 'subjectTypes'])->get();

        // Arrays for random data generation
        $compulsoryOptions = [true, false];
        $priorityOptions = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
        $roomTypeIds = RoomType::pluck('id')->toArray();

        $data = [];

        foreach ($subjectGroups as $subjectGroup) {
            foreach ($classGroupJnts as $classGroupJnt) {
                // Check if required relations exist
                if (
                    !$classGroupJnt->subjectStudyFormat ||
                    !$classGroupJnt->subjectStudyFormat->subject ||
                    !$classGroupJnt->subjectTypes
                ) {
                    continue;
                }

                // For each subject group X classGroup jnt entry, create 1 entry
                $isCompulsory = Arr::random($compulsoryOptions);

                // Generate period constraints based on subject type or random
                $minPeriods = $isCompulsory ? rand(3, 8) : rand(1, 4);
                $maxPeriods = $minPeriods + rand(0, 4);

                // Generate per-day constraints
                $maxPerDay = rand(1, 3);
                $minPerDay = rand(0, 1);

                // Create entry
                $data[] = [
                    'subject_group_id' => $subjectGroup->id,
                    'class_group_id' => $classGroupJnt->id,
                    'subject_id' => $classGroupJnt->subjectStudyFormat->subject->id,
                    'subject_type_id' => $classGroupJnt->subject_type_id,
                    'subject_study_format_id' => $classGroupJnt->sub_stdy_frmt_id ?? rand(1, 2),
                    'is_compulsory' => $isCompulsory,
                    'min_periods_per_week' => $minPeriods,
                    'max_periods_per_week' => $maxPeriods,
                    'max_per_day' => $maxPerDay,
                    'min_per_day' => $minPerDay,
                    'min_gap_periods' => $isCompulsory ? rand(0, 2) : null,
                    'allow_consecutive' => rand(0, 1) == 1,
                    'max_consecutive' => rand(1, 3),
                    'priority' => Arr::random($priorityOptions),
                    'compulsory_room_type' => $isCompulsory ? (count($roomTypeIds) > 0 ? Arr::random($roomTypeIds) : null) : null,
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];

                // Insert in batches to avoid memory issues
                if (count($data) >= 500) {
                    DB::table('sch_subject_group_subject_jnt')->insert($data);
                    $data = [];
                }
            }
        }

        // Insert remaining data
        if (!empty($data)) {
            DB::table('sch_subject_group_subject_jnt')->insert($data);
        }

        $this->command->info('Subject Group Subject JNT seeder completed successfully!');
        $this->command->info('Total records inserted: ' . count($data));
    }
}

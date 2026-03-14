<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Modules\SchoolSetup\Models\StudyFormat;
use Modules\SchoolSetup\Models\Subject;

class SubjectStudyFormatJntSeeder extends Seeder
{
    public function run(): void
    {
        DB::transaction(function () {
            $this->seedSubjects();
            $this->seedStudyFormats();
            $this->seedSubjectStudyFormats();
        });

        $this->command->info('✅ AcademicStructureSeeder completed successfully.');
    }

    protected function seedSubjects(): void
    {
        $subjects = [
            ['short_name' => 'ENG', 'name' => 'English', 'code' => 'ENG'],
            ['short_name' => 'HIN', 'name' => 'Hindi', 'code' => 'HIN'],
            ['short_name' => 'MAT', 'name' => 'Maths', 'code' => 'MAT'],
            ['short_name' => 'SCI', 'name' => 'Science', 'code' => 'SCI'],
            ['short_name' => 'SOC', 'name' => 'Social Science', 'code' => 'SOC'],
            ['short_name' => 'SAN', 'name' => 'Sanskrit', 'code' => 'SAN'],
            //['short_name' => 'GK', 'name' => 'G.K.', 'code' => 'GK'],
            ['short_name' => 'COMP', 'name' => 'Computer Science', 'code' => 'COMP'],
            ['short_name' => 'FRE', 'name' => 'French', 'code' => 'FRE'],
            ['short_name' => 'LIB', 'name' => 'Library', 'code' => 'LIB'],
            //['short_name' => 'VAL', 'name' => 'Value Education', 'code' => 'VAL'],
            //['short_name' => 'ART', 'name' => 'Art', 'code' => 'ART'],
            ['short_name' => 'GAM', 'name' => 'Games', 'code' => 'GAM'],
            //['short_name' => 'ENGN', 'name' => 'English Novel', 'code' => 'ENGN'],
            //['short_name' => 'ROB', 'name' => 'Robotics', 'code' => 'ROB'],
            //['short_name' => 'AST', 'name' => 'Astro', 'code' => 'AST'],
            //['short_name' => 'HOB', 'name' => 'Hobby', 'code' => 'HOB'],
        ];

        foreach ($subjects as $subject) {
            DB::table('sch_subjects')->updateOrInsert(
                ['code' => $subject['code']],
                [
                    'short_name' => $subject['short_name'],
                    'name' => $subject['name'],
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }
    }

    protected function seedStudyFormats(): void
    {
        $formats = [
            ['code' => 'TH', 'short_name' => 'Theory', 'name' => 'Theory'],
            ['code' => 'PR', 'short_name' => 'Practical', 'name' => 'Practical'],
            ['code' => 'LAB', 'short_name' => 'Lab', 'name' => 'Lab / Activity'],
            ['code' => 'LIB', 'short_name' => 'Library', 'name' => 'Library'],
            //['code' => 'ART', 'short_name' => 'Art', 'name' => 'Art'],
            ['code' => 'SPT', 'short_name' => 'Sports', 'name' => 'Sports'], // Uncommented this line
            //['code' => 'HOB', 'short_name' => 'Hobby', 'name' => 'Hobby'],
        ];

        foreach ($formats as $format) {
            DB::table('sch_study_formats')->updateOrInsert(
                ['code' => $format['code']],
                [
                    'short_name' => $format['short_name'],
                    'name' => $format['name'],
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }
    }

    protected function seedSubjectStudyFormats(): void
    {
        $mapping = [
            'English' => ['TH'],
            'Hindi' => ['TH'],
            'Maths' => ['TH'],
            'Science' => ['TH'],
            'Social Science' => ['TH'],
            'Sanskrit' => ['TH'],
            //'G.K.' => ['TH'],
            'French' => ['TH'],
            //'Value Education' => ['TH'],
            //'English Novel' => ['TH'],

            'Computer Science' => ['TH', 'PR'],

            //'Robotics' => ['LAB'],
            //'Astro' => ['LAB'],

            'Library' => ['LIB'],
            //'Art' => ['ART'],
            'Games' => ['SPT'],
            //'Hobby' => ['HOB'],
        ];

        $subjects = DB::table('sch_subjects')->get(['id', 'name', 'code']);
        $formats = DB::table('sch_study_formats')->get(['id', 'code', 'name']);

        foreach ($subjects as $subject) {
            if (!isset($mapping[$subject->name])) {
                $this->command->warn("⚠️ No study format for subject: {$subject->name}");
                continue;
            }

            foreach ($mapping[$subject->name] as $formatCode) {
                $format = $formats->firstWhere('code', $formatCode);

                if (!$format) {
                    $this->command->error("❌ Format '{$formatCode}' not found for subject: {$subject->name}");
                    continue;
                }

                DB::table('sch_subject_study_format_jnt')->updateOrInsert(
                    [
                        'subject_id' => $subject->id,
                        'study_format_id' => $format->id,
                    ],
                    [
                        'subj_stdformat_code' => "{$subject->code}-{$format->code}",
                        'name' => "{$subject->name} {$format->name}",
                        'is_active' => true,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]
                );
            }
        }
    }
}

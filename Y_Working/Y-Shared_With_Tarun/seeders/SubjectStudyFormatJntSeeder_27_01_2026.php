<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class SubjectStudyFormatJntSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        /*
        |--------------------------------------------------------------------------
        | Load Active Subjects
        |--------------------------------------------------------------------------
        */
        $subjects = DB::table('sch_subjects')
            ->where('is_active', true)
            ->get(['id', 'name', 'code']);

        if ($subjects->isEmpty()) {
            $this->command->warn('No active subjects found. Skipping SubjectStudyFormatSeeder.');
            return;
        }

        /*
        |--------------------------------------------------------------------------
        | Load Active Study Formats
        |--------------------------------------------------------------------------
        */
        $studyFormats = DB::table('sch_study_formats')
            ->where('is_active', true)
            ->get(['id', 'name', 'code', 'short_name']);

        if ($studyFormats->isEmpty()) {
            $this->command->warn('No active study formats found. Skipping SubjectStudyFormatSeeder.');
            return;
        }

        /*
        |--------------------------------------------------------------------------
        | Generate Subject × StudyFormat combinations (1–3 formats per subject)
        |--------------------------------------------------------------------------
        */
        foreach ($subjects as $subject) {

            $selectedFormats = $studyFormats
                ->shuffle()
                ->take(rand(1, min(2, $studyFormats->count())));

            foreach ($selectedFormats as $format) {

                DB::table('sch_subject_study_format_jnt')->updateOrInsert(
                    [
                        'subject_id' => $subject->id,
                        'study_format_id' => $format->id,
                    ],
                    [
                        'subj_stdformat_code' => "{$subject->code}-{$format->code}", // optional
                        'name' => "{$subject->name} {$format->name}",
                        'is_active' => true,
                        'updated_at' => now(),
                        'created_at' => now(),
                    ]
                );
            }
        }

        $this->command->info('✅ SubjectStudyFormatSeeder completed successfully.');
    }

    protected function generateCode(string $subjectCode, object $format): string
    {
        $subject = strtoupper(substr($subjectCode, 0, 3));
        $format = strtoupper(substr($format->code, 0, 3));

        return "{$subject}-{$format}";
    }
}

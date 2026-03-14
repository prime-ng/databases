<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class SubjectStudyFormatClassSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        /*
        |--------------------------------------------------------------------------
        | Load Required Masters
        |--------------------------------------------------------------------------
        */
        $classes = DB::table('sch_classes')->where('is_active', true)->get();
        $sections = DB::table('sch_sections')->where('is_active', true)->get();

        $subjectStudyFormats = DB::table('sch_subject_study_format_jnt')
            ->where('is_active', true)
            ->get();

        $subjectTypes = DB::table('sch_subject_types')
            ->pluck('id', 'code'); // MAJOR, MINOR, OPTIONAL

        $roomTypes = DB::table('sch_rooms_type')
            ->pluck('id', 'code'); // CLASSROOM, LAB

        if (
            $classes->isEmpty() ||
            $sections->isEmpty() ||
            $subjectStudyFormats->isEmpty()
        ) {
            $this->command->warn('Missing master data. Skipping ClassGroupSeeder.');
            return;
        }

        /*
        |--------------------------------------------------------------------------
        | Generate Class Groups
        |--------------------------------------------------------------------------
        */
        foreach ($classes as $class) {
            foreach ($sections as $section) {

                foreach ($subjectStudyFormats as $ssf) {

                    // --- Decide subject type (simple default rule)
                    $subjectTypeId = $subjectTypes['MAJOR']
                        ?? array_values($subjectTypes->toArray())[0];

                    // --- Decide room type (Practical → LAB, else CLASSROOM)
                    $roomTypeId = str_contains(strtoupper($ssf->name), 'PRACTICAL')
                        ? ($roomTypes['LAB'] ?? array_values($roomTypes->toArray())[0])
                        : ($roomTypes['CLASSROOM'] ?? array_values($roomTypes->toArray())[0]);

                    $name = "{$class->name}({$section->name}) - {$ssf->name}";
                    $code = strtoupper(Str::slug(
                        "{$class->code}-{$section->code}-{$ssf->subj_stdformat_code}",
                        '_'
                    ));

                    DB::table('sch_class_groups_jnt')->updateOrInsert(
                        [
                            'class_id' => $class->id,
                            'section_id' => $section->id,
                            'sub_stdy_frmt_id' => $ssf->id,
                            'subject_type_id' => $subjectTypeId,
                        ],
                        [
                            'rooms_type_id' => $roomTypeId,
                            'name' => Str::limit($name, 50, ''),
                            'code' => $code,
                            'is_active' => true,
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]
                    );
                }
            }
        }
    }
}

<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Modules\SchoolSetup\Models\Organization;
use Modules\SchoolSetup\Models\RoomType;
use Modules\SchoolSetup\Models\SchoolClass;
use Modules\SchoolSetup\Models\Section;
use Modules\SchoolSetup\Models\Subject;
use Modules\SchoolSetup\Models\SubjectGroup;
use Modules\SchoolSetup\Models\SubjectStudyFormat;
use Modules\SchoolSetup\Models\SubjectType;
use Modules\SmartTimetable\Models\ClassGroupJnt;

class SubjectGroupSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        /*
        |--------------------------------------------------------------------------
        | Step 1: Create Subject Groups for each Class + Section combination
        |--------------------------------------------------------------------------
        */
        $this->command->info('Creating subject groups...');

        $classes = SchoolClass::where('is_active', true)->get();
        $sections = Section::where('is_active', true)->get();

        if ($classes->isEmpty() || $sections->isEmpty()) {
            $this->command->error('No active classes or sections found. Please seed classes and sections first.');
            return;
        }

        $subjectGroups = [];
        $subjectGroupCounter = 1;

        foreach ($classes as $class) {
            foreach ($sections as $section) {
                $subjectGroups[] = [
                    'class_id' => $class->id,
                    'section_id' => $section->id,
                    'short_name' => $class->code . '-' . $section->code,
                    'code' => 'GRP-' . str_pad($class->id, 3, '0', STR_PAD_LEFT) . '-' . str_pad($section->id, 3, '0', STR_PAD_LEFT),
                    'name' => 'Subject Group for ' . $class->name . ' - ' . $section->name,
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];

                $subjectGroupCounter++;
            }
        }

        // Insert subject groups
        $chunks = array_chunk($subjectGroups, 100);
        foreach ($chunks as $chunk) {
            DB::table('sch_subject_groups')->insert($chunk);
        }

        $this->command->info('Created ' . count($subjectGroups) . ' subject groups.');

        /*
        |--------------------------------------------------------------------------
        | Step 2: Load required master data for junction table
        |--------------------------------------------------------------------------
        */
        $this->command->info('Loading master data...');

        // Get all created subject groups with their relationships
        $createdSubjectGroups = DB::table('sch_subject_groups')
            ->join('sch_classes', 'sch_subject_groups.class_id', '=', 'sch_classes.id')
            ->join('sch_sections', 'sch_subject_groups.section_id', '=', 'sch_sections.id')
            ->select(
                'sch_subject_groups.id as subject_group_id',
                'sch_subject_groups.class_id',
                'sch_subject_groups.section_id',
                'sch_classes.code as class_code',
                'sch_sections.code as section_code'
            )
            ->get();

        // Get active class groups
        $classGroups = ClassGroupJnt::with(['class', 'section', 'subjectStudyFormat', 'subjectType'])
            ->where('is_active', true)
            ->get();

        if ($classGroups->isEmpty()) {
            $this->command->error('No active class groups found. Please run ClassGroupSeeder first.');
            return;
        }

        // Get subjects
        $subjects = Subject::where('is_active', true)->get();

        // Get subject types
        $subjectTypes = SubjectType::all()->keyBy('id');

        // Get subject study formats
        $subjectStudyFormats = SubjectStudyFormat::where('is_active', true)->get();

        // Get room types
        $roomTypes = RoomType::all()->keyBy('id');

        /*
        |--------------------------------------------------------------------------
        | Step 3: Create junction table entries
        |--------------------------------------------------------------------------
        */
        $this->command->info('Creating subject group assignments...');

        $subjectGroupAssignments = [];
        $assignmentCounter = 0;

        // Configuration for different subject types
        $subjectTypeConfig = [
            'MAJ' => [ // MAJOR subjects
                'is_compulsory' => true,
                'min_periods_per_week' => 5,
                'max_periods_per_week' => 7,
                'min_per_day' => 1,
                'max_per_day' => 2,
                'min_gap_periods' => 0,
                'allow_consecutive' => true,
                'max_consecutive' => 2,
                'priority' => 10,
            ],
            'MIN' => [ // MINOR subjects
                'is_compulsory' => true,
                'min_periods_per_week' => 2,
                'max_periods_per_week' => 4,
                'min_per_day' => 0,
                'max_per_day' => 1,
                'min_gap_periods' => 1,
                'allow_consecutive' => false,
                'max_consecutive' => 1,
                'priority' => 30,
            ],
            'OPT' => [ // OPTIONAL subjects
                'is_compulsory' => false,
                'min_periods_per_week' => 1,
                'max_periods_per_week' => 3,
                'min_per_day' => 0,
                'max_per_day' => 1,
                'min_gap_periods' => 2,
                'allow_consecutive' => false,
                'max_consecutive' => 1,
                'priority' => 40,
            ],
            'ELEC' => [ // ELECTIVE subjects
                'is_compulsory' => false,
                'min_periods_per_week' => 3,
                'max_periods_per_week' => 5,
                'min_per_day' => 0,
                'max_per_day' => 2,
                'min_gap_periods' => 1,
                'allow_consecutive' => true,
                'max_consecutive' => 2,
                'priority' => 20,
            ],
            'ADD' => [ // ADDITIONAL subjects
                'is_compulsory' => false,
                'min_periods_per_week' => 1,
                'max_periods_per_week' => 2,
                'min_per_day' => 0,
                'max_per_day' => 1,
                'min_gap_periods' => 0,
                'allow_consecutive' => false,
                'max_consecutive' => 1,
                'priority' => 50,
            ],
        ];

        foreach ($createdSubjectGroups as $subjectGroup) {
            // Find class groups that belong to this class and section
            $matchingClassGroups = $classGroups->filter(function ($classGroup) use ($subjectGroup) {
                return $classGroup->class_id == $subjectGroup->class_id
                    && $classGroup->section_id == $subjectGroup->section_id;
            });

            if ($matchingClassGroups->isEmpty()) {
                continue;
            }

            // Assign 3-7 subjects to each subject group (random)
            $numSubjectsToAssign = rand(3, 7);
            $selectedClassGroups = $matchingClassGroups->random(min($numSubjectsToAssign, $matchingClassGroups->count()));

            foreach ($selectedClassGroups as $classGroup) {
                // Get configuration based on subject type
                $subjectTypeCode = $classGroup->subjectType->code ?? 'MAJ';
                $config = $subjectTypeConfig[$subjectTypeCode] ?? $subjectTypeConfig['MAJ'];

                // Get a random subject that matches the study format
                $matchingSubjects = $subjects->filter(function ($subject) use ($classGroup) {
                    // You might want to add more specific matching logic here
                    return $subject->is_active;
                });

                $subject = $matchingSubjects->isNotEmpty() ? $matchingSubjects->random() : $subjects->first();

                // Get matching subject study format
                $subjectStudyFormat = $subjectStudyFormats->firstWhere('subject_id', $subject->id)
                    ?? $subjectStudyFormats->first();

                // Determine room type (LAB for practical subjects, otherwise random)
                $roomTypeId = null;
                if (str_contains(strtoupper($classGroup->subjectStudyFormat->name ?? ''), 'PRACTICAL')) {
                    $labRoom = $roomTypes->firstWhere('code', 'LAB');
                    $roomTypeId = $labRoom ? $labRoom->id : $roomTypes->random()->id;
                } elseif ($config['is_compulsory']) {
                    $roomTypeId = $roomTypes->random()->id;
                }

                $subjectGroupAssignments[] = [
                    'subject_group_id' => $subjectGroup->subject_group_id,
                    'class_group_id' => $classGroup->id,
                    'subject_id' => $subject->id,
                    'subject_type_id' => $classGroup->subject_type_id,
                    'subject_study_format_id' => $subjectStudyFormat ? $subjectStudyFormat->id : null,
                    'is_compulsory' => $config['is_compulsory'],
                    'min_periods_per_week' => $config['min_periods_per_week'],
                    'max_periods_per_week' => $config['max_periods_per_week'],
                    'min_per_day' => $config['min_per_day'],
                    'max_per_day' => $config['max_per_day'],
                    'min_gap_periods' => $config['min_gap_periods'],
                    'allow_consecutive' => $config['allow_consecutive'],
                    'max_consecutive' => $config['max_consecutive'],
                    'priority' => $config['priority'],
                    'compulsory_room_type' => $roomTypeId,
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];

                $assignmentCounter++;
            }
        }

        // Insert junction table entries
        $junctionChunks = array_chunk($subjectGroupAssignments, 100);
        foreach ($junctionChunks as $chunk) {
            DB::table('sch_subject_group_subject_jnt')->insert($chunk);
        }

        /*
        |--------------------------------------------------------------------------
        | Step 4: Generate statistics and output
        |--------------------------------------------------------------------------
        */
        $this->command->info('Generating statistics...');

        $stats = [
            'Total Subject Groups Created' => count($subjectGroups),
            'Total Subject Group Assignments' => $assignmentCounter,
            'Average Subjects per Group' => count($subjectGroups) > 0 ? round($assignmentCounter / count($subjectGroups), 2) : 0,
        ];

        // Distribution by subject type
        $typeDistribution = DB::table('sch_subject_group_subject_jnt as sgsj')
            ->join('sch_subject_types as st', 'sgsj.subject_type_id', '=', 'st.id')
            ->select('st.code', DB::raw('count(*) as count'))
            ->groupBy('st.code')
            ->orderBy('count', 'desc')
            ->get();

        $this->command->info('==============================================');
        $this->command->info('SUBJECT GROUP SEEDER COMPLETE');
        $this->command->info('==============================================');

        foreach ($stats as $label => $value) {
            $this->command->info(sprintf("%-30s: %s", $label, $value));
        }

        $this->command->info("\nSubject Type Distribution:");
        foreach ($typeDistribution as $type) {
            $percentage = $assignmentCounter > 0 ? round(($type->count / $assignmentCounter) * 100, 2) : 0;
            $this->command->info(sprintf("  %-15s: %d (%.1f%%)", $type->code, $type->count, $percentage));
        }

        // Show sample data
        $this->command->info("\nSample Subject Group Assignments:");
        $sampleAssignments = DB::table('sch_subject_group_subject_jnt as sgsj')
            ->join('sch_subject_groups as sg', 'sgsj.subject_group_id', '=', 'sg.id')
            ->join('sch_classes as c', 'sg.class_id', '=', 'c.id')
            ->join('sch_sections as sec', 'sg.section_id', '=', 'sec.id')
            ->join('sch_subject_types as st', 'sgsj.subject_type_id', '=', 'st.id')
            ->select(
                'sg.code as subject_group_code',
                'c.name as class_name',
                'sec.name as section_name',
                'st.name as subject_type',
                'sgsj.is_compulsory'
            )
            ->limit(5)
            ->get();

        foreach ($sampleAssignments as $assignment) {
            $compulsory = $assignment->is_compulsory ? 'Compulsory' : 'Optional';
            $this->command->info(sprintf(
                "  %s (%s - %s): %s (%s)",
                $assignment->subject_group_code,
                $assignment->class_name,
                $assignment->section_name,
                $assignment->subject_type,
                $compulsory
            ));
        }

        $this->command->info("\n✅ Subject groups and assignments seeded successfully!");
    }
}

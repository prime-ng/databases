<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Modules\SchoolSetup\Models\ClassGroup;
use Modules\SchoolSetup\Models\RoomType;
use Modules\SchoolSetup\Models\SchoolClass;
use Modules\SchoolSetup\Models\Section;
use Modules\SchoolSetup\Models\SubjectStudyFormat;
use Modules\SchoolSetup\Models\SubjectType;

class ClassGroupSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get all active classes and subjects directly from database
        $classes = DB::table('sch_classes')
            ->where('is_active', true)
            ->get(['id', 'name', 'short_name', 'code']);

        $subjects = DB::table('sch_subjects')
            ->where('is_active', true)
            ->get(['id', 'name', 'short_name', 'code']);

        $classGroups = [];
        $now = now();

        foreach ($classes as $class) {
            foreach ($subjects as $subject) {
                $classGroups[] = [
                    'class_label' => $this->generateClassLabel($class, $subject),
                    'subject_id' => $subject->id,
                    'short_name' => $this->generateShortName($class, $subject),
                    'description' => "{$class->name} - {$subject->name} Group",
                    'is_major' => true,
                    'is_active' => true,
                    'created_at' => $now,
                    'updated_at' => $now,
                ];
            }
        }
        // Insert in chunks
        $chunks = array_chunk($classGroups, 100);
        foreach ($chunks as $chunk) {
            DB::table('sch_class_groups')->insert($chunk);
        }
    }

    /**
     * Generate class label (max 10 characters)
     */
    private function generateClassLabel($class, $subject): string
    {
        $label = substr($class->code, 0, 3) . '-' . substr($subject->code, 0, 6);
        return strtoupper($label);
    }

    /**
     * Generate short name (max 20 characters)
     */
    private function generateShortName($class, $subject): string
    {
        $classShort = $class->short_name ?? substr($class->name, 0, 5);
        $subjectShort = $subject->short_name ?? substr($subject->name, 0, 10);

        $shortName = trim($classShort . ' ' . $subjectShort);

        return substr($shortName, 0, 20);
    }
}

<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use Modules\Prime\Models\AcademicSession;
use Modules\SmartTimetable\Models\Timetable;

class TimetableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $academicSessionId = AcademicSession::current()->first()->id;
        // Timetable::create([
        //     'code' => 'TT_2025_REG_V1',
        //     'name' => 'Regular Timetable 2025 (v1)',
        //     'description' => 'Initial draft timetable for academic year 2025',

        //     'academic_session_id' => $academicSessionId,
        //     'timetable_type_id' => 1,
        //     'period_set_id' => 1,

        //     'effective_from' => '2025-04-01',
        //     'effective_to' => null,

        //     'generation_method' => Timetable::GEN_MANUAL,
        //     'version' => 1,

        //     'status' => Timetable::STATUS_DRAFT,

        //     'constraint_violations' => 0,
        //     'soft_score' => null,
        //     'stats_json' => null,

        //     'is_active' => true,
        //     'created_by' => 1,
        // ]);

        // Timetable::create([
        //     'code' => 'TT_2025_REG_V2',
        //     'name' => 'Regular Timetable 2025 (v2)',
        //     'description' => 'Auto-generated and published timetable',

        //     'academic_session_id' => $academicSessionId,
        //     'timetable_type_id' => 1,
        //     'period_set_id' => 1,

        //     'effective_from' => '2025-04-01',

        //     'generation_method' => Timetable::GEN_FULL_AUTO,
        //     'version' => 2,
        //     'parent_timetable_id' => 1,

        //     'status' => Timetable::STATUS_PUBLISHED,
        //     'published_at' => now(),
        //     'published_by' => 1,

        //     'constraint_violations' => 3,
        //     'soft_score' => 92.50,
        //     'stats_json' => [
        //         'teachers' => 28,
        //         'classes' => 18,
        //         'periods' => 240,
        //     ],

        //     'is_active' => true,
        //     'created_by' => 1,
        // ]);
    }
}

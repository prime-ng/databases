<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class ComplaintCategorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $now = Carbon::now();


        //DB::table('cmp_complaint_categories')->truncate();

        /*
        |--------------------------------------------------------------------------
        | Fetch dropdown IDs
        |--------------------------------------------------------------------------
        */
        $severity = DB::table('sys_dropdowns')
            ->where('type', 'students.severity_level')
            ->pluck('id');

        $priority = DB::table('sys_dropdowns')
            ->where('type', 'students.priority_score')
            ->pluck('id');

        /*
        |--------------------------------------------------------------------------
        | Parent Categories
        |--------------------------------------------------------------------------
        */
        $parents = [
            'ACADEMIC' => [
                'name' => 'Academic Issues',
                'description' => 'Issues related to academics, classes, exams, or faculty',
                'severity' => 'MEDIUM',
                'priority' => 'P3',
            ],
            'INFRA' => [
                'name' => 'Infrastructure',
                'description' => 'Infrastructure and facility related issues',
                'severity' => 'HIGH',
                'priority' => 'P2',
            ],
            'DISCIPLINE' => [
                'name' => 'Discipline & Conduct',
                'description' => 'Misconduct, bullying, or discipline related complaints',
                'severity' => 'HIGH',
                'priority' => 'P2',
            ],
            'HEALTH' => [
                'name' => 'Health & Safety',
                'description' => 'Medical, safety, or emergency related complaints',
                'severity' => 'CRITICAL',
                'priority' => 'P1',
            ],
        ];

        $parentIds = [];

        foreach ($parents as $code => $data) {
            $parentIds[$code] = DB::table('cmp_complaint_categories')->insertGetId([
                'parent_id' => null,
                'name' => $data['name'],
                'code' => $code,
                'description' => $data['description'],
                'severity_level_id' => $severity[$data['severity']] ?? null,
                'priority_score_id' => $priority[$data['priority']] ?? null,
                'expected_resolution_hours' => 48,
                'escalation_hours_l1' => 12,
                'escalation_hours_l2' => 24,
                'escalation_hours_l3' => 36,
                'escalation_hours_l4' => 48,
                'escalation_hours_l5' => 72,
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }

        /*
        |--------------------------------------------------------------------------
        | Sub Categories
        |--------------------------------------------------------------------------
        */
        $subCategories = [
            // Academic
            [
                'parent' => 'ACADEMIC',
                'name' => 'Exam Schedule Issue',
                'code' => 'EXAM_SCHEDULE',
                'severity' => 'MEDIUM',
                'priority' => 'P3',
            ],
            [
                'parent' => 'ACADEMIC',
                'name' => 'Faculty Related Issue',
                'code' => 'FACULTY',
                'severity' => 'HIGH',
                'priority' => 'P2',
            ],

            // Infrastructure
            [
                'parent' => 'INFRA',
                'name' => 'Classroom Facilities',
                'code' => 'CLASSROOM',
                'severity' => 'MEDIUM',
                'priority' => 'P3',
            ],
            [
                'parent' => 'INFRA',
                'name' => 'Hostel / Accommodation',
                'code' => 'HOSTEL',
                'severity' => 'HIGH',
                'priority' => 'P2',
            ],

            // Discipline
            [
                'parent' => 'DISCIPLINE',
                'name' => 'Ragging / Bullying',
                'code' => 'RAGGING',
                'severity' => 'CRITICAL',
                'priority' => 'P1',
            ],

            // Health
            [
                'parent' => 'HEALTH',
                'name' => 'Medical Emergency',
                'code' => 'MEDICAL',
                'severity' => 'CRITICAL',
                'priority' => 'P1',
            ],
        ];

        foreach ($subCategories as $sub) {
            DB::table('cmp_complaint_categories')->insert([
                'parent_id' => $parentIds[$sub['parent']],
                'name' => $sub['name'],
                'code' => $sub['code'],
                'description' => null,
                'severity_level_id' => $severity[$sub['severity']] ?? null,
                'priority_score_id' => $priority[$sub['priority']] ?? null,
                'expected_resolution_hours' => 24,
                'escalation_hours_l1' => 6,
                'escalation_hours_l2' => 12,
                'escalation_hours_l3' => 18,
                'escalation_hours_l4' => 24,
                'escalation_hours_l5' => 48,
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
    }
}

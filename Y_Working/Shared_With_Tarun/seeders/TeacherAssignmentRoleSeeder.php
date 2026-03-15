<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class TeacherAssignmentRoleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $roles = [
            [
                'code' => 'PRIMARY',
                'name' => 'Primary Instructor',
                'description' => 'Main teacher responsible for the activity',
                'is_primary_instructor' => true,
                'counts_for_workload' => true,
                'allows_overlap' => false,
                'workload_factor' => 1.00,
                'ordinal' => 1,
            ],
            [
                'code' => 'ASSISTANT',
                'name' => 'Assistant Teacher',
                'description' => 'Supports the primary instructor',
                'is_primary_instructor' => false,
                'counts_for_workload' => true,
                'allows_overlap' => true,
                'workload_factor' => 0.50,
                'ordinal' => 2,
            ],
            [
                'code' => 'CO_TEACHER',
                'name' => 'Co-Teacher',
                'description' => 'Shares teaching responsibility equally',
                'is_primary_instructor' => false,
                'counts_for_workload' => true,
                'allows_overlap' => false,
                'workload_factor' => 1.00,
                'ordinal' => 3,
            ],
            [
                'code' => 'OBSERVER',
                'name' => 'Observer',
                'description' => 'Observes the class without teaching responsibility',
                'is_primary_instructor' => false,
                'counts_for_workload' => false,
                'allows_overlap' => true,
                'workload_factor' => 0.00,
                'ordinal' => 4,
            ],
            [
                'code' => 'SUBSTITUTE',
                'name' => 'Substitute Teacher',
                'description' => 'Temporarily replaces the primary instructor',
                'is_primary_instructor' => true,
                'counts_for_workload' => true,
                'allows_overlap' => false,
                'workload_factor' => 1.00,
                'ordinal' => 5,
            ],
        ];

        foreach ($roles as $role) {
            DB::table('tt_teacher_assignment_roles')->updateOrInsert(
                ['code' => $role['code']],
                array_merge($role, [
                    'is_system' => true,
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ])
            );
        }

        $this->command->info('Teacher assignment roles seeded successfully.');
    }
}

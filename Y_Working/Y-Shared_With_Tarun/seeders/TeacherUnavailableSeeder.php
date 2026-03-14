<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class TeacherUnavailableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $now = Carbon::now();

        DB::table('tt_teacher_assignment_roles')->insert([
            /*
            |--------------------------------------------------------------------------
            | 1. Primary Instructor
            |--------------------------------------------------------------------------
            */
            [
                'code' => 'PRIMARY',
                'name' => 'Primary Instructor',
                'description' => 'Main teacher responsible for the activity',
                'is_primary_instructor' => true,
                'counts_for_workload' => true,
                'allows_overlap' => false,
                'workload_factor' => 1.00,
                'ordinal' => 1,
                'is_system' => true,
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ],

            /*
            |--------------------------------------------------------------------------
            | 2. Assistant Instructor
            |--------------------------------------------------------------------------
            */
            [
                'code' => 'ASSISTANT',
                'name' => 'Assistant Instructor',
                'description' => 'Supports the primary instructor',
                'is_primary_instructor' => false,
                'counts_for_workload' => true,
                'allows_overlap' => true,
                'workload_factor' => 0.50,
                'ordinal' => 2,
                'is_system' => true,
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ],

            /*
            |--------------------------------------------------------------------------
            | 3. Co-Instructor
            |--------------------------------------------------------------------------
            */
            [
                'code' => 'CO_INSTRUCTOR',
                'name' => 'Co-Instructor',
                'description' => 'Shares teaching responsibility equally',
                'is_primary_instructor' => false,
                'counts_for_workload' => true,
                'allows_overlap' => false,
                'workload_factor' => 1.00,
                'ordinal' => 3,
                'is_system' => true,
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ],

            /*
            |--------------------------------------------------------------------------
            | 4. Observer
            |--------------------------------------------------------------------------
            */
            [
                'code' => 'OBSERVER',
                'name' => 'Observer',
                'description' => 'Present but does not teach or count toward workload',
                'is_primary_instructor' => false,
                'counts_for_workload' => false,
                'allows_overlap' => true,
                'workload_factor' => 0.00,
                'ordinal' => 4,
                'is_system' => true,
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ],
        ]);
    }
}

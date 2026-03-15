<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Modules\Prime\Models\AcademicSession;

class ConstraintSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $now = Carbon::now();

        /*
        |--------------------------------------------------------------------------
        | Resolve required foreign keys safely
        |--------------------------------------------------------------------------
        */

        $constraintTypes = DB::table('tt_constraint_types')
            ->whereIn('code', [
                'TEACHER_NOT_AVAILABLE',
                'MAX_LESSONS_PER_DAY',
                'LUNCH_BREAK_FIXED',
                'SHORT_BREAK_FIXED',
            ])
            ->pluck('id', 'code')
            ->toArray();

        // Academic session (required)
        $academicSession = AcademicSession::current()->firstOrFail();

        // Bail out if required constraint types are missing
        $required = [
            'TEACHER_NOT_AVAILABLE',
            'MAX_LESSONS_PER_DAY',
            'LUNCH_BREAK_FIXED',
            'SHORT_BREAK_FIXED',
        ];

        foreach ($required as $code) {
            if (!isset($constraintTypes[$code])) {
                $this->command->warn(
                    "ConstraintSeeder skipped: missing constraint type {$code}"
                );
                return;
            }
        }

        /*
        |--------------------------------------------------------------------------
        | Seed Constraints
        |--------------------------------------------------------------------------
        */

        $constraints = [

            /*
            |--------------------------------------------------------------------------
            | GLOBAL SOFT CONSTRAINT
            |--------------------------------------------------------------------------
            */

            [
                'uuid' => Str::uuid()->getBytes(),
                'constraint_type_id' => $constraintTypes['MAX_LESSONS_PER_DAY'],
                'name' => 'Max Lessons Per Day (Global)',
                'description' => 'Limits maximum lessons per day for all classes',
                'academic_session_id' => $academicSession->id,

                'target_type' => 'GLOBAL',
                'target_id' => null,

                'is_hard' => false,
                'weight' => 80,

                'params_json' => json_encode([
                    'max_lessons' => 6,
                ]),

                'effective_from' => null,
                'effective_to' => null,
                'applies_to_days_json' => json_encode(['MON', 'TUE', 'WED', 'THU', 'FRI']),

                'status' => 'ACTIVE',
                'is_active' => true,

                'created_by' => null,
                'created_at' => $now,
                'updated_at' => $now,
            ],

            /*
            |--------------------------------------------------------------------------
            | HARD CONSTRAINT — LUNCH BREAK (GLOBAL)
            |--------------------------------------------------------------------------
            */

            [
                'uuid' => Str::uuid()->getBytes(),
                'constraint_type_id' => $constraintTypes['LUNCH_BREAK_FIXED'],
                'name' => 'Lunch Break (No Teaching)',
                'description' => 'Lunch break must not contain any teaching activity',
                'academic_session_id' => $academicSession->id,

                'target_type' => 'GLOBAL',
                'target_id' => null,

                'is_hard' => true,
                'weight' => 100,

                'params_json' => json_encode([
                    'period_type_code' => 'LUNCH',
                ]),

                'effective_from' => null,
                'effective_to' => null,
                'applies_to_days_json' => null,

                'status' => 'ACTIVE',
                'is_active' => true,

                'created_by' => null,
                'created_at' => $now,
                'updated_at' => $now,
            ],

            /*
            |--------------------------------------------------------------------------
            | HARD CONSTRAINT — SHORT BREAK (GLOBAL)
            |--------------------------------------------------------------------------
            */

            [
                'uuid' => Str::uuid()->getBytes(),
                'constraint_type_id' => $constraintTypes['SHORT_BREAK_FIXED'],
                'name' => 'Short Break (No Teaching)',
                'description' => 'Short break periods must not contain teaching activity',
                'academic_session_id' => $academicSession->id,

                'target_type' => 'GLOBAL',
                'target_id' => null,

                'is_hard' => true,
                'weight' => 100,

                'params_json' => json_encode([
                    'period_type_code' => 'BREAK',
                ]),

                'effective_from' => null,
                'effective_to' => null,
                'applies_to_days_json' => null,

                'status' => 'ACTIVE',
                'is_active' => true,

                'created_by' => null,
                'created_at' => $now,
                'updated_at' => $now,
            ],

            /*
            |--------------------------------------------------------------------------
            | TEACHER-SPECIFIC HARD CONSTRAINT (EXAMPLE)
            |--------------------------------------------------------------------------
            */

            [
                'uuid' => Str::uuid()->getBytes(),
                'constraint_type_id' => $constraintTypes['TEACHER_NOT_AVAILABLE'],
                'name' => 'Teacher Unavailable on Monday',
                'description' => 'Teacher not available on Monday periods',
                'academic_session_id' => $academicSession->id,

                'target_type' => 'TEACHER',
                'target_id' => 1, // ⚠️ example only

                'is_hard' => true,
                'weight' => 100,

                'params_json' => json_encode([
                    'days' => ['MON'],
                    'periods' => [],
                ]),

                'effective_from' => null,
                'effective_to' => null,
                'applies_to_days_json' => json_encode(['MON']),

                'status' => 'ACTIVE',
                'is_active' => true,

                'created_by' => null,
                'created_at' => $now,
                'updated_at' => $now,
            ],
        ];

        /*
        |--------------------------------------------------------------------------
        | Insert (re-runnable safe)
        |--------------------------------------------------------------------------
        */

        DB::table('tt_constraints')->insert($constraints);

        $this->command->info('ConstraintSeeder executed successfully with hard break constraints.');
    }
}

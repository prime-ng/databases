<?php

namespace Modules\HrStaff\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class HrsLeavePolicySeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        // Insert global default policy (academic_year_id = NULL = applies to all years)
        $exists = DB::table('hrs_leave_policies')
            ->whereNull('academic_year_id')
            ->where('is_active', 1)
            ->exists();

        if (! $exists) {
            DB::table('hrs_leave_policies')->insert([
                'academic_year_id'       => null,
                'max_backdated_days'     => 3,
                'min_advance_days'       => 0,
                'approval_levels'        => 2,
                'optional_holiday_count' => 2,
                'is_active'              => 1,
                'created_by'             => 1,
                'updated_by'             => 1,
                'created_at'             => $now,
                'updated_at'             => $now,
            ]);
        }
    }
}

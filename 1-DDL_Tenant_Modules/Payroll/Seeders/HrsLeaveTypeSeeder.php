<?php

namespace Modules\HrStaff\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class HrsLeaveTypeSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();
        $types = [
            [
                'code'                       => 'CL',
                'name'                       => 'Casual Leave',
                'days_per_year'              => 12.0,
                'carry_forward_days'         => 0,
                'applicable_to'             => 'all',
                'is_paid'                    => 1,
                'requires_medical_cert'      => 0,
                'medical_cert_threshold_days'=> 3,
                'half_day_allowed'           => 1,
                'gender_restriction'         => 'all',
                'min_service_months'         => 0,
                'max_consecutive_days'       => null,
            ],
            [
                'code'                       => 'EL',
                'name'                       => 'Earned Leave',
                'days_per_year'              => 15.0,
                'carry_forward_days'         => 30,
                'applicable_to'             => 'all',
                'is_paid'                    => 1,
                'requires_medical_cert'      => 0,
                'medical_cert_threshold_days'=> 3,
                'half_day_allowed'           => 0,
                'gender_restriction'         => 'all',
                'min_service_months'         => 6,
                'max_consecutive_days'       => null,
            ],
            [
                'code'                       => 'SL',
                'name'                       => 'Sick Leave',
                'days_per_year'              => 12.0,
                'carry_forward_days'         => 0,
                'applicable_to'             => 'all',
                'is_paid'                    => 1,
                'requires_medical_cert'      => 1,
                'medical_cert_threshold_days'=> 3,
                'half_day_allowed'           => 0,
                'gender_restriction'         => 'all',
                'min_service_months'         => 0,
                'max_consecutive_days'       => null,
            ],
            [
                'code'                       => 'ML',
                'name'                       => 'Maternity Leave',
                'days_per_year'              => 180.0,
                'carry_forward_days'         => 0,
                'applicable_to'             => 'all',
                'is_paid'                    => 1,
                'requires_medical_cert'      => 0,
                'medical_cert_threshold_days'=> 3,
                'half_day_allowed'           => 0,
                'gender_restriction'         => 'female',
                'min_service_months'         => 0,
                'max_consecutive_days'       => 180,
            ],
            [
                'code'                       => 'PL',
                'name'                       => 'Paternity Leave',
                'days_per_year'              => 15.0,
                'carry_forward_days'         => 0,
                'applicable_to'             => 'all',
                'is_paid'                    => 1,
                'requires_medical_cert'      => 0,
                'medical_cert_threshold_days'=> 3,
                'half_day_allowed'           => 0,
                'gender_restriction'         => 'male',
                'min_service_months'         => 0,
                'max_consecutive_days'       => 15,
            ],
            [
                'code'                       => 'CO',
                'name'                       => 'Compensatory Off',
                'days_per_year'              => 0.0,
                'carry_forward_days'         => 7,
                'applicable_to'             => 'all',
                'is_paid'                    => 1,
                'requires_medical_cert'      => 0,
                'medical_cert_threshold_days'=> 3,
                'half_day_allowed'           => 1,
                'gender_restriction'         => 'all',
                'min_service_months'         => 0,
                'max_consecutive_days'       => null,
            ],
            [
                'code'                       => 'LWP',
                'name'                       => 'Leave Without Pay',
                'days_per_year'              => 0.0,
                'carry_forward_days'         => 0,
                'applicable_to'             => 'all',
                'is_paid'                    => 0,
                'requires_medical_cert'      => 0,
                'medical_cert_threshold_days'=> 3,
                'half_day_allowed'           => 0,
                'gender_restriction'         => 'all',
                'min_service_months'         => 0,
                'max_consecutive_days'       => null,
            ],
        ];

        foreach ($types as $type) {
            DB::table('hrs_leave_types')->updateOrInsert(
                ['code' => $type['code']],
                array_merge($type, [
                    'is_active'  => 1,
                    'created_by' => 1,
                    'updated_by' => 1,
                    'created_at' => $now,
                    'updated_at' => $now,
                ])
            );
        }
    }
}

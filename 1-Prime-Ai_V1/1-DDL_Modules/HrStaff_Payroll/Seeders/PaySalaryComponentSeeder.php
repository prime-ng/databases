<?php

namespace Modules\HrStaff\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class PaySalaryComponentSeeder extends Seeder
{
    /**
     * 14 standard salary components:
     *   Earnings (7):            BASIC, DA, HRA, CONV, MEDICAL, LTA, SPECIAL
     *   Deductions (5):          PF_EMP, ESI_EMP, PT, TDS, LWP_DED
     *   Employer Contributions (2): PF_ERR, ESI_ERR
     */
    public function run(): void
    {
        $now = now();

        $components = [
            // ---- EARNINGS ----
            [
                'code'             => 'BASIC',
                'name'             => 'Basic Pay',
                'component_type'   => 'earning',
                'calculation_type' => 'fixed',
                'default_value'    => 0.0000,
                'is_taxable'       => 1,
                'is_statutory'     => 0,
                'display_order'    => 1,
            ],
            [
                'code'             => 'DA',
                'name'             => 'Dearness Allowance',
                'component_type'   => 'earning',
                'calculation_type' => 'percentage_of_basic',
                'default_value'    => 0.0000,
                'is_taxable'       => 1,
                'is_statutory'     => 0,
                'display_order'    => 2,
            ],
            [
                'code'             => 'HRA',
                'name'             => 'House Rent Allowance',
                'component_type'   => 'earning',
                'calculation_type' => 'percentage_of_basic',
                'default_value'    => 25.0000,
                'is_taxable'       => 1,
                'is_statutory'     => 0,
                'display_order'    => 3,
            ],
            [
                'code'             => 'CONV',
                'name'             => 'Conveyance Allowance',
                'component_type'   => 'earning',
                'calculation_type' => 'fixed',
                'default_value'    => 0.0000,
                'is_taxable'       => 1,
                'is_statutory'     => 0,
                'display_order'    => 4,
            ],
            [
                'code'             => 'MEDICAL',
                'name'             => 'Medical Allowance',
                'component_type'   => 'earning',
                'calculation_type' => 'fixed',
                'default_value'    => 0.0000,
                'is_taxable'       => 1,
                'is_statutory'     => 0,
                'display_order'    => 5,
            ],
            [
                'code'             => 'LTA',
                'name'             => 'Leave Travel Allowance',
                'component_type'   => 'earning',
                'calculation_type' => 'fixed',
                'default_value'    => 0.0000,
                'is_taxable'       => 1,
                'is_statutory'     => 0,
                'display_order'    => 6,
            ],
            [
                'code'             => 'SPECIAL',
                'name'             => 'Special Allowance',
                'component_type'   => 'earning',
                'calculation_type' => 'fixed',
                'default_value'    => 0.0000,
                'is_taxable'       => 1,
                'is_statutory'     => 0,
                'display_order'    => 7,
            ],

            // ---- DEDUCTIONS ----
            [
                'code'             => 'PF_EMP',
                'name'             => 'PF Employee (12%)',
                'component_type'   => 'deduction',
                'calculation_type' => 'statutory',
                'default_value'    => 12.0000,
                'is_taxable'       => 0,
                'is_statutory'     => 1,
                'display_order'    => 10,
            ],
            [
                'code'             => 'ESI_EMP',
                'name'             => 'ESI Employee (0.75%)',
                'component_type'   => 'deduction',
                'calculation_type' => 'statutory',
                'default_value'    => 0.7500,
                'is_taxable'       => 0,
                'is_statutory'     => 1,
                'display_order'    => 11,
            ],
            [
                'code'             => 'PT',
                'name'             => 'Profession Tax',
                'component_type'   => 'deduction',
                'calculation_type' => 'statutory',
                'default_value'    => 0.0000,
                'is_taxable'       => 0,
                'is_statutory'     => 1,
                'display_order'    => 12,
            ],
            [
                'code'             => 'TDS',
                'name'             => 'Income Tax (TDS)',
                'component_type'   => 'deduction',
                'calculation_type' => 'statutory',
                'default_value'    => 0.0000,
                'is_taxable'       => 0,
                'is_statutory'     => 1,
                'display_order'    => 13,
            ],
            [
                'code'             => 'LWP_DED',
                'name'             => 'Loss of Pay Deduction',
                'component_type'   => 'deduction',
                'calculation_type' => 'manual',
                'default_value'    => 0.0000,
                'is_taxable'       => 0,
                'is_statutory'     => 0,
                'display_order'    => 14,
            ],

            // ---- EMPLOYER CONTRIBUTIONS ----
            [
                'code'             => 'PF_ERR',
                'name'             => 'PF Employer (12%)',
                'component_type'   => 'employer_contribution',
                'calculation_type' => 'statutory',
                'default_value'    => 12.0000,
                'is_taxable'       => 0,
                'is_statutory'     => 1,
                'display_order'    => 20,
            ],
            [
                'code'             => 'ESI_ERR',
                'name'             => 'ESI Employer (3.25%)',
                'component_type'   => 'employer_contribution',
                'calculation_type' => 'statutory',
                'default_value'    => 3.2500,
                'is_taxable'       => 0,
                'is_statutory'     => 1,
                'display_order'    => 21,
            ],
        ];

        foreach ($components as $component) {
            DB::table('pay_salary_components')->updateOrInsert(
                ['code' => $component['code']],
                array_merge($component, [
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

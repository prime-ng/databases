<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class BillingCycleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $billingCycles = [
            [
                'short_name' => 'monthly',
                'name' => 'Monthly',
                'months_count' => 1,
                'description' => 'Monthly billing cycle',
                'is_active' => true,
            ],
            [
                'short_name' => 'quarterly',
                'name' => 'Quarterly',
                'months_count' => 3,
                'description' => 'Quarterly billing cycle (3 months)',
                'is_active' => true,
            ],
            [
                'short_name' => 'half_yearly',
                'name' => 'Half-Yearly',
                'months_count' => 6,
                'description' => 'Half Yearly billing cycle (6 months)',
                'is_active' => true,
            ],
            [
                'short_name' => 'yearly',
                'name' => 'Yearly',
                'months_count' => 12,
                'description' => 'Annual billing cycle (12 months)',
                'is_active' => true,
            ]
        ];

        DB::table('prm_billing_cycles')->insert($billingCycles);
    }
}

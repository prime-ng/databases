<?php

namespace Modules\Accounting\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CostCenterSeeder extends Seeder
{
    /**
     * Seed acc_cost_centers with 10 school department cost centers.
     */
    public function run(): void
    {
        $now = now();

        $costCenters = [
            ['name' => 'Primary Wing',    'code' => 'CC-PRI', 'category' => 'Department', 'is_active' => 1, 'created_at' => $now],
            ['name' => 'Middle Wing',     'code' => 'CC-MID', 'category' => 'Department', 'is_active' => 1, 'created_at' => $now],
            ['name' => 'Senior Wing',     'code' => 'CC-SNR', 'category' => 'Department', 'is_active' => 1, 'created_at' => $now],
            ['name' => 'Administration',  'code' => 'CC-ADM', 'category' => 'Department', 'is_active' => 1, 'created_at' => $now],
            ['name' => 'Transport',       'code' => 'CC-TPT', 'category' => 'Department', 'is_active' => 1, 'created_at' => $now],
            ['name' => 'Sports',          'code' => 'CC-SPT', 'category' => 'Department', 'is_active' => 1, 'created_at' => $now],
            ['name' => 'Library',         'code' => 'CC-LIB', 'category' => 'Department', 'is_active' => 1, 'created_at' => $now],
            ['name' => 'Science Lab',     'code' => 'CC-SCI', 'category' => 'Department', 'is_active' => 1, 'created_at' => $now],
            ['name' => 'Computer Lab',    'code' => 'CC-CMP', 'category' => 'Department', 'is_active' => 1, 'created_at' => $now],
            ['name' => 'Hostel',          'code' => 'CC-HST', 'category' => 'Department', 'is_active' => 1, 'created_at' => $now],
        ];

        DB::table('acc_cost_centers')->insert($costCenters);
    }
}

<?php

namespace Modules\HrStaff\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class HrsPtSlabSeeder extends Seeder
{
    /**
     * Profession Tax slabs for HP, KA, MH.
     * max_salary = 999999999.00 for the open-ended top slab.
     */
    public function run(): void
    {
        $now = now();

        $slabs = [
            // Himachal Pradesh (HP) — 2 slabs
            ['state_code' => 'HP', 'min_salary' => 0.00,     'max_salary' => 10000.00,      'pt_amount' => 0.00],
            ['state_code' => 'HP', 'min_salary' => 10001.00,  'max_salary' => 999999999.00,  'pt_amount' => 200.00],

            // Karnataka (KA) — 2 slabs
            ['state_code' => 'KA', 'min_salary' => 0.00,     'max_salary' => 15000.00,      'pt_amount' => 0.00],
            ['state_code' => 'KA', 'min_salary' => 15001.00,  'max_salary' => 999999999.00,  'pt_amount' => 200.00],

            // Maharashtra (MH) — 3 slabs
            ['state_code' => 'MH', 'min_salary' => 0.00,     'max_salary' => 7500.00,       'pt_amount' => 0.00],
            ['state_code' => 'MH', 'min_salary' => 7501.00,   'max_salary' => 10000.00,      'pt_amount' => 175.00],
            ['state_code' => 'MH', 'min_salary' => 10001.00,  'max_salary' => 999999999.00,  'pt_amount' => 200.00],
        ];

        foreach ($slabs as $slab) {
            DB::table('hrs_pt_slabs')->updateOrInsert(
                [
                    'state_code'  => $slab['state_code'],
                    'min_salary'  => $slab['min_salary'],
                ],
                array_merge($slab, [
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

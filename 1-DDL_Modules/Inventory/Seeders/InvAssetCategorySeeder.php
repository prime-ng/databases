<?php

namespace Modules\Inventory\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Seeds 5 system asset categories with WDV depreciation rates per Income Tax Act
 * (Schedule II, Companies Act 2013 / IT Act block rates for school context).
 *
 * Income Tax Act WDV rates used:
 *   - Computers & peripherals:      40% (Block 5 — Computers including peripherals)
 *   - Furniture & fixtures:         10% (Block 1 — Furniture and fittings)
 *   - Electrical/Electronic equip:  15% (Block 4 — Plant & Machinery general rate)
 *   - Lab equipment:                15% (Block 4)
 *   - Vehicles:                     15% (Block 6 — Motor cars other than for hire)
 *
 * is_active set to 1; no is_system column on inv_asset_categories — protected via Policy.
 */
class InvAssetCategorySeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        $categories = [
            [
                'name'              => 'IT Equipment & Computers',
                'code'              => 'IT-ASSET',
                'depreciation_rate' => 40.00,
                'useful_life_years' => 3,
            ],
            [
                'name'              => 'Furniture & Fixtures',
                'code'              => 'FURN-ASSET',
                'depreciation_rate' => 10.00,
                'useful_life_years' => 10,
            ],
            [
                'name'              => 'Electrical & Electronic Equipment',
                'code'              => 'ELEC-ASSET',
                'depreciation_rate' => 15.00,
                'useful_life_years' => 7,
            ],
            [
                'name'              => 'Laboratory Equipment',
                'code'              => 'LAB-ASSET',
                'depreciation_rate' => 15.00,
                'useful_life_years' => 7,
            ],
            [
                'name'              => 'Vehicles & Transport',
                'code'              => 'VEH-ASSET',
                'depreciation_rate' => 15.00,
                'useful_life_years' => 7,
            ],
        ];

        foreach ($categories as $category) {
            DB::table('inv_asset_categories')->insertOrIgnore([
                'name'              => $category['name'],
                'code'              => $category['code'],
                'depreciation_rate' => $category['depreciation_rate'],
                'useful_life_years' => $category['useful_life_years'],
                'is_active'         => 1,
                'created_by'        => 1,
                'updated_by'        => 1,
                'created_at'        => $now,
                'updated_at'        => $now,
            ]);
        }
    }
}

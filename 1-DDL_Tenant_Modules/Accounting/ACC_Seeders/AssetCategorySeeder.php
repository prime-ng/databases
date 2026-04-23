<?php

namespace Modules\Accounting\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class AssetCategorySeeder extends Seeder
{
    /**
     * Seed acc_asset_categories with 5 standard school asset categories.
     */
    public function run(): void
    {
        $now = now();

        $categories = [
            [
                'name'                => 'Furniture & Fixtures',
                'code'                => 'AST-FUR',
                'depreciation_method' => 'SLM',
                'depreciation_rate'   => 10.00,
                'useful_life_years'   => 10,
                'is_active'           => 1,
                'created_at'          => $now,
            ],
            [
                'name'                => 'IT Equipment',
                'code'                => 'AST-IT',
                'depreciation_method' => 'WDV',
                'depreciation_rate'   => 40.00,
                'useful_life_years'   => 3,
                'is_active'           => 1,
                'created_at'          => $now,
            ],
            [
                'name'                => 'Vehicles',
                'code'                => 'AST-VEH',
                'depreciation_method' => 'WDV',
                'depreciation_rate'   => 15.00,
                'useful_life_years'   => 8,
                'is_active'           => 1,
                'created_at'          => $now,
            ],
            [
                'name'                => 'Building',
                'code'                => 'AST-BLD',
                'depreciation_method' => 'SLM',
                'depreciation_rate'   => 5.00,
                'useful_life_years'   => 30,
                'is_active'           => 1,
                'created_at'          => $now,
            ],
            [
                'name'                => 'Lab Equipment',
                'code'                => 'AST-LAB',
                'depreciation_method' => 'SLM',
                'depreciation_rate'   => 15.00,
                'useful_life_years'   => 7,
                'is_active'           => 1,
                'created_at'          => $now,
            ],
        ];

        DB::table('acc_asset_categories')->insert($categories);
    }
}

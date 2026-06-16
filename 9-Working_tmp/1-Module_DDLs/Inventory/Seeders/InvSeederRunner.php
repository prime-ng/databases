<?php

namespace Modules\Inventory\Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * INV module seed runner.
 * Calls all Inventory seeders in dependency order:
 *   1. InvUomSeeder          — Layer 1: units of measure (no deps)
 *   2. InvStockGroupSeeder   — Layer 2: stock groups (requires UOM for default_uom_id)
 *   3. InvGodownSeeder       — Layer 3: storage locations (no seeder deps, standalone)
 *   4. InvAssetCategorySeeder — Layer 1: asset categories (no deps)
 *
 * Usage:
 *   php artisan tenants:seed --class=Modules\\Inventory\\Database\\Seeders\\InvSeederRunner
 */
class InvSeederRunner extends Seeder
{
    public function run(): void
    {
        $this->call([
            InvUomSeeder::class,
            InvStockGroupSeeder::class,
            InvGodownSeeder::class,
            InvAssetCategorySeeder::class,
        ]);
    }
}

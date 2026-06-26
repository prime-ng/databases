<?php

namespace Modules\Cafeteria\Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * CafSeederRunner — Master seeder for the Cafeteria module.
 *
 * Runs all CAF seeders in dependency-safe order.
 * Safe to re-run — all child seeders use upsert.
 *
 * Execution:
 *   Single tenant:
 *     php artisan tenants:artisan "db:seed --class=Modules\\Cafeteria\\Database\\Seeders\\CafSeederRunner" --tenant=TENANT_ID
 *
 *   All tenants:
 *     php artisan tenants:artisan "db:seed --class=Modules\\Cafeteria\\Database\\Seeders\\CafSeederRunner"
 *
 * Seeder order:
 *   1. CafMenuCategorySeeder — 5 meal categories (no dependencies)
 */
class CafSeederRunner extends Seeder
{
    public function run(): void
    {
        $this->call([
            CafMenuCategorySeeder::class,   // L1 — no caf_* dependencies; must run first
        ]);
    }
}

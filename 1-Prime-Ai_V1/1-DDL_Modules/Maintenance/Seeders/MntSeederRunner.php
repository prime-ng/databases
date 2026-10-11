<?php

namespace Modules\Maintenance\Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * MntSeederRunner
 *
 * Master seeder for the Maintenance module.
 * Run via: php artisan tenants:seed --class=MntSeederRunner
 *
 * Execution order (dependency-safe):
 *   1. MntAssetCategorySeeder — no table dependencies
 */
class MntSeederRunner extends Seeder
{
    public function run(): void
    {
        $this->call([
            MntAssetCategorySeeder::class,
        ]);
    }
}

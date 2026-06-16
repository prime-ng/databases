<?php

namespace Modules\VisitorSecurity\Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * VsmSeederRunner
 *
 * Master seeder for the VisitorSecurity module.
 * Run via: php artisan module:seed VisitorSecurity --class=VsmSeederRunner
 *
 * Execution order (dependency-safe):
 *   1. VsmEmergencyProtocolSeeder — no vsm_* table dependencies
 *   2. VsmPatrolCheckpointSeeder  — no vsm_* table dependencies
 */
class VsmSeederRunner extends Seeder
{
    public function run(): void
    {
        $this->call([
            VsmEmergencyProtocolSeeder::class,
            VsmPatrolCheckpointSeeder::class,
        ]);
    }
}

<?php

namespace Database\Seeders\Tenant\Hostel;

use Illuminate\Database\Seeder;

/**
 * HstSeederRunner
 *
 * Master seeder for the HST (Hostel Management) module.
 * Call this from the tenant DatabaseSeeder to seed all HST reference data.
 *
 * Usage in TenantDatabaseSeeder.php:
 *   $this->call(HstSeederRunner::class);
 *
 * Or run directly via artisan (inside tenant context):
 *   php artisan tenants:artisan "db:seed --class=Database\\Seeders\\Tenant\\Hostel\\HstSeederRunner" --tenant=<tenant_id>
 *
 * Copy to: database/seeders/tenant/Hostel/HstSeederRunner.php
 *
 * Seeder order:
 *   1. HstRoomTypeSeeder  — Room type labels → sys_settings (hostel.room_type_labels.*)
 *   2. HstIncidentTypeSeeder — Incident types → sys_settings (hostel.incident_types)
 */
class HstSeederRunner extends Seeder
{
    public function run(): void
    {
        $this->command->info('--- HST Hostel Module Seeders ---');

        $this->call([
            HstRoomTypeSeeder::class,
            HstIncidentTypeSeeder::class,
        ]);

        $this->command->info('--- HST Seeders Complete ---');
    }
}

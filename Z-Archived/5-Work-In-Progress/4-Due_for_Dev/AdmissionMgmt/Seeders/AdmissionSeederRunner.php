<?php

namespace Modules\Admission\Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * Master seeder for the Admission module.
 *
 * Runs all ADM seeders in dependency order.
 * Safe to re-run — all child seeders use upsert or are informational.
 *
 * Usage:
 *   php artisan db:seed --class="Modules\Admission\Database\Seeders\AdmissionSeederRunner"
 *
 * Or call from DatabaseSeeder:
 *   $this->call(AdmissionSeederRunner::class);
 */
class AdmissionSeederRunner extends Seeder
{
    public function run(): void
    {
        $this->command->info('');
        $this->command->info('┌─────────────────────────────────────────┐');
        $this->command->info('│   ADM — Admission Module Seeder Runner  │');
        $this->command->info('└─────────────────────────────────────────┘');

        $this->call([
            AdmissionDocumentChecklistSeeder::class,  // Global template documents (8 rows, upsert-safe)
            AdmissionQuotaSeeder::class,              // Quota type reference output (no DB inserts)
        ]);

        $this->command->info('');
        $this->command->info('ADM module seeding complete.');
    }
}

<?php

namespace Modules\Certificate\Database\Seeders;

use Illuminate\Database\Seeder;

class CrtSeederRunner extends Seeder
{
    /**
     * Master seeder for the Certificate module.
     * Runs all CRT seeders in dependency order.
     *
     * Usage:
     *   php artisan module:seed Certificate --class=CrtSeederRunner
     *
     * For test runs (minimum):
     *   php artisan module:seed Certificate --class=CrtCertificateTypeSeeder
     *
     * For Phase 2+ tests (generation requires default template):
     *   php artisan module:seed Certificate --class=CrtSeederRunner
     */
    public function run(): void
    {
        $this->call([
            CrtCertificateTypeSeeder::class,  // no dependencies — must run first
            CrtTemplateSeeder::class,          // depends on CrtCertificateTypeSeeder (uses certificate_type_id)
        ]);
    }
}

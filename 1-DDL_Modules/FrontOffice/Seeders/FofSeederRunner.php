<?php

namespace Modules\FrontOffice\Database\Seeders;

use Illuminate\Database\Seeder;

class FofSeederRunner extends Seeder
{
    /**
     * Master seeder for the FrontOffice module.
     *
     * Usage:
     *   php artisan db:seed --class="Modules\FrontOffice\Database\Seeders\FofSeederRunner"
     *
     * Or register in DatabaseSeeder.php:
     *   $this->call(FofSeederRunner::class);
     */
    public function run(): void
    {
        $this->call([
            FofVisitorPurposeSeeder::class,   // fof_visitor_purposes — 8 purposes; no dependencies
        ]);
    }
}

<?php

namespace Modules\BehaviouralAssessment\Database\Seeders;

use Illuminate\Database\Seeder;

class BaSeederRunner extends Seeder
{
    /**
     * Master seeder — calls all BA seeders in order.
     * No inter-seeder dependencies (all 3 target independent Layer 1 tables).
     *
     * Usage:
     *   php artisan module:seed BehaviouralAssessment --class=BaSeederRunner
     */
    public function run(): void
    {
        $this->call([
            BaRatingScaleSeeder::class,    // ba_rating_scales + ba_rating_levels (no deps)
            BaCategorySeeder::class,       // ba_categories + ba_criteria (no deps)
            BaInterventionSeeder::class,   // ba_interventions (no deps)
        ]);
    }
}

<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class StateSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Fetch countries from global_master_mysql
        $countries = DB::connection('global_master_mysql')
            ->table('glb_countries')
            ->pluck('id', 'name');

        $totalStates = 0;

        foreach ($countries as $countryName => $countryId) {
            $states = $this->generateLoremStates($countryId);

            foreach ($states as $state) {
                DB::connection('global_master_mysql')
                    ->table('glb_states')
                    ->updateOrInsert(
                        ['country_id' => $countryId, 'name' => $state['name']],
                        $state
                    );
            }

            $totalStates += count($states);
        }
    }

    private function generateLoremStates($countryId)
    {
        $stateNames = [
            'Lorem State ' . Str::random(3),
            'Ipsum State ' . Str::random(3),
            'Dolor State ' . Str::random(3),
            'Sit Amet State ' . Str::random(3),
            'Consectetur State ' . Str::random(3),
            'Adipiscing State ' . Str::random(3),
            'Elit State ' . Str::random(3),
        ];

        $states = [];

        foreach ($stateNames as $name) {
            $states[] = [
                'country_id' => $countryId,
                'name' => $name,
                'short_name' => strtoupper(Str::substr($name, 0, 3)) . '.' . rand(100, 990009),
                'global_code' => null,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ];
        }

        return $states;
    }
}

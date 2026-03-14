<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Modules\GlobalMaster\Models\District;


class DistrictSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $districtNames = ['Lorem', 'Ipsum', 'Dolor', 'Sit', 'Amet']; // Dummy district names

        // Get countries and states from global_master_mysql
        $countries = DB::connection('global_master_mysql')
            ->table('glb_countries')
            ->get();

        $states = DB::connection('global_master_mysql')
            ->table('glb_states')
            ->select('id', 'name', 'country_id')
            ->get()
            ->groupBy('country_id');



        foreach ($countries as $country) {
            $countryStates = $states->get($country->id, collect());

            foreach ($countryStates as $state) {
                // Create 3 to 5 districts for each state
                $districtCount = rand(3, 5);

                for ($i = 0; $i < $districtCount; $i++) {
                    $districtName = $districtNames[$i % count($districtNames)] . ' ' . $state->name . ' ' . ($i + 1);
                    $shortName = strtoupper(substr(str_replace(' ', '', $districtName), 0, 10));
                    $globalCode = 'IN-' . strtoupper(substr($state->name, 0, 3)) . ($i + 1);

                    DB::connection('global_master_mysql')
                        ->table('glb_districts')
                        ->insertOrIgnore([
                            'state_id' => $state->id,
                            'name' => $districtName,
                            'short_name' => $shortName,
                            'global_code' => $globalCode,
                            'is_active' => true,
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]);
                }
            }
        }
    }
}

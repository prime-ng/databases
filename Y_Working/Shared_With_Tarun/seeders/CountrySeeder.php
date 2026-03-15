<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CountrySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $countries = [
            [
                'name' => 'United States',
                'short_name' => 'US',
                'global_code' => 'US',
                'currency_code' => 'USD',
                'is_active' => true,
            ],
            [
                'name' => 'China',
                'short_name' => 'CN',
                'global_code' => 'CN',
                'currency_code' => 'CNY',
                'is_active' => false,
            ],
            [
                'name' => 'Japan',
                'short_name' => 'JP',
                'global_code' => 'JP',
                'currency_code' => 'JPY',
                'is_active' => false,
            ],
            [
                'name' => 'Germany',
                'short_name' => 'DE',
                'global_code' => 'DE',
                'currency_code' => 'EUR',
                'is_active' => false,
            ],
            [
                'name' => 'India',
                'short_name' => 'IN',
                'global_code' => 'IN',
                'currency_code' => 'INR',
                'is_active' => true,
            ],
            [
                'name' => 'United Kingdom',
                'short_name' => 'GB',
                'global_code' => 'GB',
                'currency_code' => 'GBP',
                'is_active' => false,
            ],
            [
                'name' => 'France',
                'short_name' => 'FR',
                'global_code' => 'FR',
                'currency_code' => 'EUR',
                'is_active' => false,
            ],
            [
                'name' => 'Italy',
                'short_name' => 'IT',
                'global_code' => 'IT',
                'currency_code' => 'EUR',
                'is_active' => false,
            ],
            [
                'name' => 'Canada',
                'short_name' => 'CA',
                'global_code' => 'CA',
                'currency_code' => 'CAD',
                'is_active' => false,
            ],
            [
                'name' => 'South Korea',
                'short_name' => 'KR',
                'global_code' => 'KR',
                'currency_code' => 'KRW',
                'is_active' => false,
            ],
        ];

        foreach ($countries as $country) {
            DB::connection('global_master_mysql')->table('glb_countries')->updateOrInsert(
                ['name' => $country['name']],
                $country
            );
        }
    }
}

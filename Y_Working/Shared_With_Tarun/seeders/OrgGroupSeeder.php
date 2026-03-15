<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;


class OrgGroupSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('sch_organization_groups')->insert([
            [
                'short_name' => 'PRIME',
                'name' => 'PrimeGurukul',
                'description' => 'Prime Gurukul main organization group',
                'address_1' => '123 Main St',
                'address_2' => 'Suite 101',
                'area' => 'Central Business District',
                'city_id' => 1,
                'pincode' => '560001',
                'website_url' => 'https://www.primegurukul.com',
                'email' => 'contact@primegurukul.com',
                'is_active' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'short_name' => 'ALPHA',
                'name' => 'Alpha Education Group',
                'description' => 'Alpha group for online education',
                'address_1' => '456 Education Blvd',
                'address_2' => null,
                'area' => 'Tech Park',
                'city_id' => 4,
                'pincode' => '110011',
                'website_url' => 'https://www.alphaedu.org',
                'email' => 'info@alphaedu.org',
                'is_active' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'short_name' => 'BETA',
                'name' => 'Beta Training Center',
                'description' => 'Training and workshops by Beta group',
                'address_1' => '789 Workshop Way',
                'address_2' => 'Building B',
                'area' => 'Industrial Area',
                'city_id' => 7,
                'pincode' => '220022',
                'website_url' => 'https://www.betatraining.com',
                'email' => 'support@betatraining.com',
                'is_active' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'short_name' => 'GAMMA',
                'name' => 'Gamma Learning Hub',
                'description' => 'Community learning initiatives by Gamma',
                'address_1' => '321 Learn St',
                'address_2' => null,
                'area' => 'Downtown',
                'city_id' => 10,
                'pincode' => '330033',
                'website_url' => 'https://www.gammalearning.com',
                'email' => 'contact@gammalearning.com',
                'is_active' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}

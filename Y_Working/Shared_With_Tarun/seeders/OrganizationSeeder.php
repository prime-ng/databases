<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Modules\GlobalMaster\Models\AcademicSession;
use Modules\GlobalMaster\Models\Board;
use Modules\GlobalMaster\Models\City;
use Modules\SchoolSetup\Models\Organization;
use Modules\SchoolSetup\Models\OrganizationGroup;

class OrganizationSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $orgGroups = OrganizationGroup::all();
        $boards = Board::all();
        $sessionIds = AcademicSession::pluck('id')->toArray();

        foreach ($orgGroups as $group) {
            // Add a random number of organizations (2 to 4) for each org group
            $count = rand(2, 4);


            for ($i = 1; $i <= $count; $i++) {

                $city = City::findOrFail(rand(3, 5));
                $city_id = $city->id;
                $district_id = $city->district->id;
                $state_id = $city->district->state->id;
                $country_id = $city->district->state->country->id;

                // Generate realistic dummy data; you can customize as needed
                $organization = Organization::create([
                    'organization_group_id' => $group->id,
                    'short_name' => strtoupper(Str::random(5)) . $i,
                    'school_name' => $group->name . " School $i",
                    'udise_code' => 'UDISE' . rand(1000, 9999),
                    'affiliation_no' => 'AFF' . rand(10000, 99999),
                    'email' => 'contact' . $i . '@' . strtolower(Str::slug($group->short_name)) . '.com',
                    'website_url' => 'https://www.' . strtolower(Str::slug($group->short_name)) . ".org$i",
                    'address_1' => '123 Main St',
                    'address_2' => null,
                    'area' => 'Central Area',
                    'city_id' => $city_id,
                    'pincode' => '560001',
                    'phone_1' => '1234567890',
                    'phone_2' => null,
                    'whatsapp_number' => '9876543210',
                    'longitude' => null,
                    'latitude' => null,
                    'timezone' => 'Asia/Kolkata',
                    'locale' => 'en_IN',
                    'currency' => 'INR',
                    'current_session_code' => null,
                    'start_date' => now()->subYears(rand(1, 5)),
                    'status' => 'ACTIVE',
                    'is_active' => 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
            $randomBoardIds = $boards->random(rand(1, 3))->pluck('id')->toArray();
            $syncData = [];
            foreach ($randomBoardIds as $boardId) {
                // Pick a random session ID
                $randomSessionId = $sessionIds[array_rand($sessionIds)];

                // Build sync array for pivot fields
                $syncData[$boardId] = ['academic_sessions_id' => $randomSessionId];
            }
            $organization->boards()->sync($syncData);
        }
    }
}

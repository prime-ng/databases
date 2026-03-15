<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use Modules\Prime\Models\Domain;
use Modules\Prime\Models\Tenant;
use Modules\Prime\Services\TenantPlanAssigner;

class TenantSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $tenantId = Str::uuid()->toString();
        // Create tenant
        $tenant = Tenant::create([
            'id' => $tenantId,
            'tenant_group_id' => 1, // adjust if you have group 1
            'code' => 'TEST001',
            'short_name' => 'Test School',
            'name' => 'Test School Tenant',
            'udise_code' => 'UD123456',
            'affiliation_no' => 'AFF123',
            'email' => 'test@tenant.com',
            'website_url' => 'https://testtenant.com',
            'address_1' => 'Address Line 1',
            'address_2' => 'Address Line 2',
            'area' => 'City Area',
            'city_id' => 1, // must match an existing city row
            'pincode' => '000000',
            'phone_1' => '9999999999',
            'phone_2' => null,
            'whatsapp_number' => '9999999999',
            'longitude' => 77.1234567,
            'latitude' => 31.1234567,
            'locale' => 'en_IN',
            'currency' => 'INR',
            'established_date' => now()->subYears(5),
            'is_active' => true,
            'data' => [
                'notes' => 'This is a test tenant created via seeder.'
            ],
        ]);

        // Assign domain
        Domain::create([
            'domain' => 'test.localhost', // your dev domain
            'tenant_id' => $tenant->id,
        ]);

        /* -----------------------------------------
     | Assign Plan to Tenant
     -----------------------------------------*/
        app(TenantPlanAssigner::class)->assign($tenant, [
            'plan_id' => 1,
            'billing_cycle_id' => 1,
            'start_date' => now()->startOfMonth(),
            'end_date' => now()->addYear()->endOfMonth(),
            'monthly_rate' => 1500,
            'rate_per_cycle' => 1500,
            'included_modules' => [1, 2, 3, 4, 5],
            'is_trial' => true,
        ]);
    }
}

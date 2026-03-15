<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Modules\Billing\Models\BillingCycle;
use Modules\GlobalMaster\Models\Module;
use Modules\GlobalMaster\Models\Plan;

class PlanSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run()
    {
        /**
         * ---------------------------------------------------------
         * 1️⃣ FETCH REQUIRED DATA
         * ---------------------------------------------------------
         */

        // Active billing cycles
        $billingCycles = BillingCycle::where('is_active', true)
            ->pluck('id')
            ->toArray();

        if (empty($billingCycles)) {
            $this->command->error('❌ No active billing cycles found.');
            return;
        }

        // All active modules
        $modules = Module::all();

        if ($modules->isEmpty()) {
            $this->command->error('❌ No modules found in the system.');
            return;
        }

        /**
         * ---------------------------------------------------------
         * 2️⃣ PLAN DEFINITIONS
         * ---------------------------------------------------------
         */

        $allMenusPlan = [
            'plan_code' => 'ALL_MENUS',
            'version' => 999,
            'name' => 'All Menus (Developer)',
            'description' => 'Developer plan with access to all modules and all menus',
            'price_monthly' => null,
            'price_yearly' => null,
            'currency' => 'INR',
            'trial_days' => 30,
            'is_active' => true,
        ];

        $plans = [
            [
                'plan_code' => 'BASIC',
                'version' => 1,
                'name' => 'Basic Plan',
                'description' => 'Basic plan with essential features',
                'price_monthly' => 100.00,
                'price_yearly' => 1000.00,
                'currency' => 'INR',
                'trial_days' => 7,
                'is_active' => true,
            ],
            [
                'plan_code' => 'STANDARD',
                'version' => 1,
                'name' => 'Standard Plan',
                'description' => 'Standard plan with core modules',
                'price_monthly' => 200.00,
                'price_yearly' => 2000.00,
                'currency' => 'INR',
                'trial_days' => 10,
                'is_active' => true,
            ],
            [
                'plan_code' => 'PRO',
                'version' => 2,
                'name' => 'Pro Plan',
                'description' => 'Professional plan with advanced features',
                'price_monthly' => 300.00,
                'price_yearly' => 3000.00,
                'currency' => 'INR',
                'trial_days' => 14,
                'is_active' => true,
            ],
            [
                'plan_code' => 'ENTERPRISE',
                'version' => 3,
                'name' => 'Enterprise Plan',
                'description' => 'Enterprise plan with full features',
                'price_monthly' => null,
                'price_yearly' => 10000.00,
                'currency' => 'INR',
                'trial_days' => 30,
                'is_active' => true,
            ],
        ];

        /**
         * ---------------------------------------------------------
         * 3️⃣ PREPARE MODULE PIVOT DATA (ALL MODULES)
         * ---------------------------------------------------------
         */

        $allModulesPivot = [];

        foreach ($modules as $module) {
            $allModulesPivot[$module->id] = [
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ];
        }

        /**
         * ---------------------------------------------------------
         * 4️⃣ CREATE / UPDATE ALL_MENUS (DEV PLAN)
         * ---------------------------------------------------------
         */

        $allMenusPlan['billing_cycle_id'] = collect($billingCycles)->random();

        $devPlan = Plan::updateOrCreate(
            [
                'plan_code' => $allMenusPlan['plan_code'],
                'version' => $allMenusPlan['version'],
            ],
            $allMenusPlan
        );

        $devPlan->modules()->syncWithoutDetaching($allModulesPivot);


        /**
         * ---------------------------------------------------------
         * 5️⃣ CREATE / UPDATE ALL OTHER PLANS
         * ---------------------------------------------------------
         */

        foreach ($plans as $planData) {

            $planData['billing_cycle_id'] = collect($billingCycles)->random();

            $plan = Plan::updateOrCreate(
                [
                    'plan_code' => $planData['plan_code'],
                    'version' => $planData['version'],
                ],
                $planData
            );

            // Assign ALL modules to this plan
            $plan->modules()->syncWithoutDetaching($allModulesPivot);
        }



    }
}

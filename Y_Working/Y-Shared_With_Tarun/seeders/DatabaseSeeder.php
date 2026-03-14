<?php

namespace Database\Seeders;

use App\Models\User;
// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Modules\GlobalMaster\Database\Seeders\DropdownSeeder;
use Modules\GlobalMaster\Database\Seeders\LanguageSeeder;
use Modules\Prime\Database\Seeders\TenantGroupSeeder;
use Modules\SystemConfig\Database\Seeders\SettingSeeder;

class DatabaseSeeder extends Seeder
{
    /**
     * 
     * Central Seeder 
     * This seeder will run when we run seeder in  central application
     * 
     */
    public function run(): void
    {
        $this->call([
            MenuSeeder::class,
            TenantMenuSeeder::class,
            CountrySeeder::class,
            StateSeeder::class,
            DistrictSeeder::class,
            CitySeeder::class,
            BoardSeeder::class,
            AcademicSessionSeeder::class,
            TenantGroupSeeder::class,
            RolePermissionSeeder::class,
            ModuleSeeder::class,
            BillingCycleSeeder::class,
            PlanSeeder::class,
            UserSeeder::class,
            DropdownSeeder::class,
            SettingSeeder::class,
            TenantSeeder::class,
            //ScheduleSeeder::class
        ]);
    }
}

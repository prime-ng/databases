<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Modules\Scheduler\Enums\SchedulerType;
use Modules\Scheduler\Models\Schedule;

class ScheduleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        Schedule::create([
            'name' => 'Prime Test Job',
            'schedule_type' => SchedulerType::PRIME,
            'job_key' => 'prime_test_job',
            'cron_expression' => '* * * * *', // Every night at 2 AM
            'payload' => [
                'report_scope' => 'prime',
                'frequency' => 'daily',
            ],
            'is_active' => true,
        ]);

        /*
        |--------------------------------------------------------------------------
        | TENANT SCHEDULES (ALL TENANTS)
        |--------------------------------------------------------------------------
        */

        Schedule::create([
            'name' => 'Tenant Test Job',
            'schedule_type' => SchedulerType::TENANT,
            'tenant_id' => null, // null = all tenants
            'job_key' => 'tenant_test_job',
            'cron_expression' => '* * * * *', // Every night at 2 AM
            'payload' => [
                'report_scope' => 'tenant',
                'frequency' => 'daily',
            ],
            'is_active' => true,
        ]);
    }
}

<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ShiftSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $now = now();

        DB::table('tt_shifts')->insert([
            /*
            |--------------------------------------------------------------------------
            | Morning Shift
            |--------------------------------------------------------------------------
            */
            [
                'code' => 'MORNING',
                'name' => 'Morning Shift',
                'description' => 'Regular morning academic shift',
                'default_start_time' => '08:00:00',
                'default_end_time' => '14:00:00',
                'ordinal' => 1,
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ],

            /*
            |--------------------------------------------------------------------------
            | Afternoon Shift
            |--------------------------------------------------------------------------
            */
            [
                'code' => 'AFTERNOON',
                'name' => 'Afternoon Shift',
                'description' => 'Post-lunch academic shift',
                'default_start_time' => '12:00:00',
                'default_end_time' => '18:00:00',
                'ordinal' => 2,
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ],

            /*
            |--------------------------------------------------------------------------
            | Evening / Activity Shift
            |--------------------------------------------------------------------------
            */
            [
                'code' => 'EVENING',
                'name' => 'Evening Shift',
                'description' => 'Sports, activities, and special classes',
                'default_start_time' => '16:00:00',
                'default_end_time' => '20:00:00',
                'ordinal' => 3,
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ],
        ]);
    }
}

<?php

namespace Modules\Cafeteria\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * CafMenuCategorySeeder
 *
 * Seeds the 5 standard meal categories into caf_menu_categories.
 * Safe to re-run — uses upsert on (name) to avoid duplicate rows.
 *
 * Run via:
 *   php artisan tenants:artisan "db:seed --class=Modules\\Cafeteria\\Database\\Seeders\\CafMenuCategorySeeder"
 */
class CafMenuCategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            [
                'name'             => 'Breakfast',
                'code'             => 'BRK',
                'meal_time'        => 'Breakfast',
                'meal_start_time'  => '08:00:00',
                'description'      => 'Morning meal — served at breakfast counter',
                'display_order'    => 1,
                'is_active'        => 1,
                'created_at'       => now(),
                'updated_at'       => now(),
            ],
            [
                'name'             => 'Lunch',
                'code'             => 'LNC',
                'meal_time'        => 'Lunch',
                'meal_start_time'  => '13:00:00',
                'description'      => 'Midday meal — main meal of the day',
                'display_order'    => 2,
                'is_active'        => 1,
                'created_at'       => now(),
                'updated_at'       => now(),
            ],
            [
                'name'             => 'Snacks',
                'code'             => 'SNK',
                'meal_time'        => 'Snacks',
                'meal_start_time'  => '16:00:00',
                'description'      => 'Evening snacks — light refreshments',
                'display_order'    => 3,
                'is_active'        => 1,
                'created_at'       => now(),
                'updated_at'       => now(),
            ],
            [
                'name'             => 'Dinner',
                'code'             => 'DIN',
                'meal_time'        => 'Dinner',
                'meal_start_time'  => '19:30:00',
                'description'      => 'Evening meal — served at dinner counter (hostel)',
                'display_order'    => 4,
                'is_active'        => 1,
                'created_at'       => now(),
                'updated_at'       => now(),
            ],
            [
                'name'             => 'Tuck Shop',
                'code'             => 'TUK',
                'meal_time'        => 'Tuck_Shop',
                'meal_start_time'  => '10:30:00',
                'description'      => 'Tuck shop / canteen counter — snacks and beverages anytime',
                'display_order'    => 5,
                'is_active'        => 1,
                'created_at'       => now(),
                'updated_at'       => now(),
            ],
        ];

        DB::table('caf_menu_categories')->upsert(
            $categories,
            ['name'],                                          // unique key for conflict detection
            ['code', 'meal_time', 'meal_start_time', 'description', 'display_order', 'is_active', 'updated_at']
        );
    }
}

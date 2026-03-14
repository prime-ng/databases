<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class SchoolClassSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $now = Carbon::now();

        $classes = [
            // Pre-Primary
            // ['name' => 'Nursery', 'short_name' => 'Nur', 'ordinal' => 1, 'code' => 'NUR'],
            // ['name' => 'LKG', 'short_name' => 'LKG', 'ordinal' => 2, 'code' => 'LKG'],
            // ['name' => 'UKG', 'short_name' => 'UKG', 'ordinal' => 3, 'code' => 'UKG'],

            // // Primary
            // ['name' => 'Class I', 'short_name' => 'I', 'ordinal' => 4, 'code' => '01'],
            // ['name' => 'Class II', 'short_name' => 'II', 'ordinal' => 5, 'code' => '02'],
            // ['name' => 'Class III', 'short_name' => 'III', 'ordinal' => 6, 'code' => '03'],
            // ['name' => 'Class IV', 'short_name' => 'IV', 'ordinal' => 7, 'code' => '04'],
            // ['name' => 'Class V', 'short_name' => 'V', 'ordinal' => 8, 'code' => '05'],

            // Middle
            //['name' => 'Class VI', 'short_name' => 'VI', 'ordinal' => 9, 'code' => '06'],
            ['name' => 'Class VII', 'short_name' => 'VII', 'ordinal' => 10, 'code' => '07'],
            ['name' => 'Class VIII', 'short_name' => 'VIII', 'ordinal' => 11, 'code' => '08'],

            // // // Secondary
            ['name' => 'Class IX', 'short_name' => 'IX', 'ordinal' => 12, 'code' => '09'],
            ['name' => 'Class X', 'short_name' => 'X', 'ordinal' => 13, 'code' => '10'],

            // // // Senior Secondary
            //['name' => 'Class XI', 'short_name' => 'XI', 'ordinal' => 14, 'code' => '11'],
            // ['name' => 'Class XII', 'short_name' => 'XII', 'ordinal' => 15, 'code' => '12'],
        ];

        foreach ($classes as $class) {
            DB::table('sch_classes')->insert([
                'name' => $class['name'],
                'short_name' => $class['short_name'],
                'ordinal' => $class['ordinal'],
                'code' => $class['code'],
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
    }
}

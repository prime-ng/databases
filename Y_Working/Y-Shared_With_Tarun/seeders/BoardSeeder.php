<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class BoardSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $boards = [
            ['name' => 'Central Board of Secondary Education', 'short_name' => 'CBSE', 'is_active' => true],
            ['name' => 'Council for the Indian School Certificate Examinations', 'short_name' => 'ICSE', 'is_active' => true],
            ['name' => 'Uttar Pradesh Board of High School and Intermediate Education', 'short_name' => 'UPMSP', 'is_active' => true],
            ['name' => 'Board of Secondary Education, Rajasthan', 'short_name' => 'RBSE', 'is_active' => true],
            ['name' => 'Maharashtra State Board of Secondary and Higher Secondary Education', 'short_name' => 'MSBSHSE', 'is_active' => true],
            ['name' => 'West Bengal Board of Secondary Education', 'short_name' => 'WBBSE', 'is_active' => true],
            ['name' => 'Punjab School Education Board', 'short_name' => 'PSEB', 'is_active' => true],
            ['name' => 'Board of School Education, Haryana', 'short_name' => 'HBSE', 'is_active' => true],
            ['name' => 'Board of School Education, Himachal Pradesh', 'short_name' => 'HPBOSE', 'is_active' => true],
            ['name' => 'Andhra Pradesh Board of Secondary Education', 'short_name' => 'BSEAP', 'is_active' => true],
        ];

        foreach ($boards as $board) {
            DB::connection('global_master_mysql')->table('glb_boards')->insert($board);
        }
    }
}

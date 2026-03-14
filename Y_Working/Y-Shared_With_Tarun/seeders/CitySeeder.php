<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CitySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $cities = [
            ['district_id' => 1, 'name' => 'Lorem City One', 'short_name' => 'LC1', 'global_code' => 'G001', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 2, 'name' => 'Ipsum City Two', 'short_name' => 'IC2', 'global_code' => 'G002', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 3, 'name' => 'Dolor City Three', 'short_name' => 'DC3', 'global_code' => 'G003', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 4, 'name' => 'Sit Amet City Four', 'short_name' => 'SM4', 'global_code' => 'G004', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 5, 'name' => 'Consectetur City Five', 'short_name' => 'CC5', 'global_code' => 'G005', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 6, 'name' => 'Adipiscing Elit City Six', 'short_name' => 'AE6', 'global_code' => 'G006', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 7, 'name' => 'Sed Do City Seven', 'short_name' => 'SD7', 'global_code' => 'G007', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 8, 'name' => 'Eiusmod City Eight', 'short_name' => 'EC8', 'global_code' => 'G008', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 9, 'name' => 'Tempor Incididunt City Nine', 'short_name' => 'TC9', 'global_code' => 'G009', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 10, 'name' => 'Labore Et City Ten', 'short_name' => 'LE10', 'global_code' => 'G010', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 11, 'name' => 'Dolore Magna City Eleven', 'short_name' => 'DM11', 'global_code' => 'G011', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 12, 'name' => 'Aliqua City Twelve', 'short_name' => 'AQ12', 'global_code' => 'G012', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 13, 'name' => 'Ut Enim City Thirteen', 'short_name' => 'UE13', 'global_code' => 'G013', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 14, 'name' => 'Minim Veniam City Fourteen', 'short_name' => 'MV14', 'global_code' => 'G014', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 15, 'name' => 'Quis Nostrum City Fifteen', 'short_name' => 'QN15', 'global_code' => 'G015', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 16, 'name' => 'Explicabo City Sixteen', 'short_name' => 'EX16', 'global_code' => 'G016', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 17, 'name' => 'Sed Ut perspiciatis City Seventeen', 'short_name' => 'SUP17', 'global_code' => 'G017', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 18, 'name' => 'Atque Earum City Eighteen', 'short_name' => 'AE18', 'global_code' => 'G018', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 19, 'name' => 'Neque Porro City Nineteen', 'short_name' => 'NP19', 'global_code' => 'G019', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
            ['district_id' => 20, 'name' => 'Quisquam Est City Twenty', 'short_name' => 'QE20', 'global_code' => 'G020', 'default_timezone' => 'Asia/Kolkata', 'is_active' => true],
        ];

        foreach ($cities as $city) {
            DB::connection('global_master_mysql')->table('glb_cities')->insert($city);
        }
    }
}

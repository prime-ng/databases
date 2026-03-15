<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Modules\SchoolSetup\Models\SchoolClass;
use Modules\SchoolSetup\Models\Subject;
use Modules\SchoolSetup\Models\SubjectGroup;

class SubjectSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // $subjects = [
        //     ['code' => 'ART', 'name' => 'Art'],
        //     ['code' => 'CONV', 'name' => 'Conversation'],
        //     ['code' => 'DAN', 'name' => 'Dance'],
        //     ['code' => 'ENG', 'name' => 'English'],
        //     ['code' => 'EVS', 'name' => 'EVS'],
        //     ['code' => 'GAM', 'name' => 'Games'],
        //     ['code' => 'HIN', 'name' => 'Hindi'],
        //     ['code' => 'MAT', 'name' => 'Maths'],
        //     ['code' => 'ABA', 'name' => 'Abacus'],
        //     ['code' => 'COMP', 'name' => 'Computer'],
        //     ['code' => 'GK', 'name' => 'GK'],
        //     ['code' => 'LIB', 'name' => 'Library'],
        //     ['code' => 'MUS', 'name' => 'Music'],
        //     ['code' => 'VAL', 'name' => 'Value Education'],
        //     ['code' => 'AST', 'name' => 'Astro Pathshala'],
        //     ['code' => 'FRE', 'name' => 'French'],
        //     ['code' => 'ROB', 'name' => 'Robotics'],
        //     ['code' => 'SCI', 'name' => 'Science'],
        //     ['code' => 'SOC', 'name' => 'Social Science'],
        //     ['code' => 'SAN', 'name' => 'Sanskrit'],
        //     ['code' => 'HOB', 'name' => 'Hobby'],
        //     ['code' => 'BIO', 'name' => 'Biology'],
        //     ['code' => 'CHE', 'name' => 'Chemistry'],
        //     ['code' => 'PHY', 'name' => 'Physics'],
        //     ['code' => 'IT', 'name' => 'IT'],
        //     ['code' => 'YOG', 'name' => 'Yoga'],
        //     ['code' => 'ACC', 'name' => 'Accountancy'],
        //     ['code' => 'BUS', 'name' => 'Business Studies'],
        //     ['code' => 'ECO', 'name' => 'Economics'],
        //     ['code' => 'HIS', 'name' => 'History'],
        //     ['code' => 'IP', 'name' => 'IP'],
        //     ['code' => 'OPT', 'name' => 'Optional'],
        //     ['code' => 'POL', 'name' => 'Political Science'],
        //     ['code' => 'SKL', 'name' => 'Skill'],
        //     ['code' => 'SOCIO', 'name' => 'Sociology'],
        // ];

        // $subjects = [
        //     ['code' => 'ENG', 'name' => 'English'],
        //     ['code' => 'HIN', 'name' => 'Hindi'],
        //     ['code' => 'MAT', 'name' => 'Maths'],
        //     ['code' => 'SOC', 'name' => 'Social Science'],
        //     ['code' => 'SAN', 'name' => 'Sanskrit'],
        //     ['code' => 'SCI', 'name' => 'Science'],
        //     ['code' => 'COMP', 'name' => 'Computer Science'],
        //     ['code' => 'FRE', 'name' => 'French'],
        //     ['code' => 'LIB', 'name' => 'Library'],
        //     ['code' => 'GAM', 'name' => 'Games'],
        // ];


        // foreach ($subjects as $s) {
        //     Subject::firstOrCreate(
        //         ['code' => $s['code']],
        //         [
        //             'short_name' => $s['code'],
        //             'name' => $s['name'],
        //             'is_active' => true,
        //         ]
        //     );
        // }
    }
}

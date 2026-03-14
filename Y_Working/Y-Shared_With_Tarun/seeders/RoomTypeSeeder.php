<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class RoomTypeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $roomTypes = [
            [
                'code' => 'CLASSRM',
                'short_name' => 'Classroom',
                'name' => 'Standard Classroom',
                'description_tags' => 'theory,lecture,regular',
            ],
            [
                'code' => 'SCI_LAB',
                'short_name' => 'Science Lab',
                'name' => 'Science Laboratory',
                'description_tags' => 'science,practical,physics,chemistry,biology',
            ],
            [
                'code' => 'COMP_LB',
                'short_name' => 'Computer Lab',
                'name' => 'Computer Laboratory',
                'description_tags' => 'computer,practical,it',
            ],
            [
                'code' => 'MATH_LB',
                'short_name' => 'Math Lab',
                'name' => 'Mathematics Laboratory',
                'description_tags' => 'math,activity',
            ],
            [
                'code' => 'MUSICRM',
                'short_name' => 'Music Room',
                'name' => 'Music Room',
                'description_tags' => 'music,vocal,instrument',
            ],
            [
                'code' => 'ART_RM',
                'short_name' => 'Art Room',
                'name' => 'Art & Craft Room',
                'description_tags' => 'art,craft,drawing',
            ],
            [
                'code' => 'SPORTS',
                'short_name' => 'Sports Area',
                'name' => 'Sports & Playground Area',
                'description_tags' => 'sports,pt,games,physical',
            ],
            [
                'code' => 'LIBRARY',
                'short_name' => 'Library',
                'name' => 'Library & Reading Room',
                'description_tags' => 'library,reading,quiet',
            ],
            [
                'code' => 'ACT_RM',
                'short_name' => 'Activity Room',
                'name' => 'Multi-purpose Activity Room',
                'description_tags' => 'activity,club,value-education',
            ],
        ];

        foreach ($roomTypes as $roomType) {
            DB::table('sch_rooms_type')->updateOrInsert(
                ['code' => $roomType['code']],
                [
                    'short_name' => $roomType['short_name'],
                    'name' => $roomType['name'],
                    'description_tags' => $roomType['description_tags'],
                    'is_active' => true,
                    'updated_at' => now(),
                    'created_at' => now(),
                ]
            );
        }

        $this->command->info('✅ RoomTypeSeeder completed successfully.');
    }
}

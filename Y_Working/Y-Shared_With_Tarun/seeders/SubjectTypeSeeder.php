<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class SubjectTypeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $subjectTypes = [
            [
                'code' => 'MAJ',
                'short_name' => 'Major',
                'name' => 'Major Subject',
            ],
            [
                'code' => 'MIN',
                'short_name' => 'Minor',
                'name' => 'Minor Subject',
            ]
        ];

        foreach ($subjectTypes as $type) {
            DB::table('sch_subject_types')->updateOrInsert(
                ['code' => $type['code']],
                [
                    'short_name' => $type['short_name'],
                    'name' => $type['name'],
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }

        $this->command->info('✅ SubjectTypeSeeder completed successfully.');
    }
}

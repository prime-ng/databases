<?php

namespace Modules\BehaviouralAssessment\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class BaInterventionSeeder extends Seeder
{
    /**
     * Seed the 9 predefined intervention types (3 reward + 4 corrective + 2 counselling).
     */
    public function run(): void
    {
        $now = now();
        $userId = 1; // System user

        $interventions = [
            // Reward (3)
            ['name' => 'Award/Certificate',   'description' => 'Formal recognition through certificate or award for positive behaviour',        'intervention_type' => 'reward',      'sort_order' => 1],
            ['name' => 'Public Recognition',   'description' => 'Public acknowledgement in assembly or class for exemplary behaviour',           'intervention_type' => 'reward',      'sort_order' => 2],
            ['name' => 'Extra Privileges',     'description' => 'Granting additional privileges as positive reinforcement',                      'intervention_type' => 'reward',      'sort_order' => 3],

            // Corrective (4)
            ['name' => 'Verbal Warning',       'description' => 'Verbal caution to the student about the behaviour',                             'intervention_type' => 'corrective',  'sort_order' => 4],
            ['name' => 'Written Warning',      'description' => 'Formal written warning documented in student record',                           'intervention_type' => 'corrective',  'sort_order' => 5],
            ['name' => 'Detention',            'description' => 'Student required to stay after school hours as a corrective measure',            'intervention_type' => 'corrective',  'sort_order' => 6],
            ['name' => 'Suspension',           'description' => 'Temporary suspension from school for serious behavioural violations',            'intervention_type' => 'corrective',  'sort_order' => 7],

            // Counselling (2)
            ['name' => 'Parent Meeting',       'description' => 'Meeting with parents/guardians to discuss behavioural concerns and action plan', 'intervention_type' => 'counselling', 'sort_order' => 8],
            ['name' => 'Counselling Referral',  'description' => 'Referral to school counsellor for behavioural support and guidance',            'intervention_type' => 'counselling', 'sort_order' => 9],
        ];

        foreach ($interventions as $intervention) {
            DB::table('ba_interventions')->insert([
                'name'              => $intervention['name'],
                'description'       => $intervention['description'],
                'intervention_type' => $intervention['intervention_type'],
                'sort_order'        => $intervention['sort_order'],
                'is_active'         => true,
                'created_by'        => $userId,
                'updated_by'        => $userId,
                'created_at'        => $now,
                'updated_at'        => $now,
            ]);
        }
    }
}

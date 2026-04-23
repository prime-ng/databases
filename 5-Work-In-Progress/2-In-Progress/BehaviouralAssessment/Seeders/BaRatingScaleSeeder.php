<?php

namespace Modules\BehaviouralAssessment\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class BaRatingScaleSeeder extends Seeder
{
    /**
     * Seed the default 5-Point Behavioural Scale with 5 levels and grade boundaries.
     */
    public function run(): void
    {
        $now = now();
        $userId = 1; // System user

        // 1. Create the default rating scale
        $scaleId = DB::table('ba_rating_scales')->insertGetId([
            'name'                  => '5-Point Behavioural Scale',
            'description'           => 'Default 5-point scale for behavioural assessment: Outstanding to Unsatisfactory',
            'grade_boundaries_json' => json_encode([
                ['grade' => 'A+', 'min' => 4.50, 'max' => 5.00],
                ['grade' => 'A',  'min' => 3.50, 'max' => 4.49],
                ['grade' => 'B+', 'min' => 2.50, 'max' => 3.49],
                ['grade' => 'B',  'min' => 1.50, 'max' => 2.49],
                ['grade' => 'C',  'min' => 1.00, 'max' => 1.49],
            ]),
            'is_default'  => true,
            'is_active'   => true,
            'created_by'  => $userId,
            'updated_by'  => $userId,
            'created_at'  => $now,
            'updated_at'  => $now,
        ]);

        // 2. Create the 5 rating levels (sort_order 1 = lowest)
        $levels = [
            ['sort_order' => 1, 'label' => 'Unsatisfactory',    'numeric_value' => 1.0, 'description' => 'Rarely meets expectations'],
            ['sort_order' => 2, 'label' => 'Needs Improvement', 'numeric_value' => 2.0, 'description' => 'Occasionally meets expectations'],
            ['sort_order' => 3, 'label' => 'Good',              'numeric_value' => 3.0, 'description' => 'Meets expectations consistently'],
            ['sort_order' => 4, 'label' => 'Very Good',         'numeric_value' => 4.0, 'description' => 'Frequently exceeds expectations'],
            ['sort_order' => 5, 'label' => 'Outstanding',       'numeric_value' => 5.0, 'description' => 'Consistently exceeds expectations'],
        ];

        foreach ($levels as $level) {
            DB::table('ba_rating_levels')->insert([
                'rating_scale_id' => $scaleId,
                'label'           => $level['label'],
                'numeric_value'   => $level['numeric_value'],
                'description'     => $level['description'],
                'sort_order'      => $level['sort_order'],
                'is_active'       => true,
                'created_by'      => $userId,
                'updated_by'      => $userId,
                'created_at'      => $now,
                'updated_at'      => $now,
            ]);
        }
    }
}

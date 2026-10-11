<?php

namespace Modules\HrStaff\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class PaySalaryStructureSeeder extends Seeder
{
    /**
     * 3 default salary structures, each with components via pay_salary_structure_components.
     *
     * Teaching Staff Structure  (applicable_to = teaching)
     * Non-Teaching Structure    (applicable_to = non_teaching)
     * Contractual Structure     (applicable_to = contractual)
     */
    public function run(): void
    {
        $now = now();

        $structures = [
            [
                'name'          => 'Teaching Staff Structure',
                'description'   => 'Standard structure for teaching staff. Includes PF, ESI, PT, TDS.',
                'applicable_to' => 'teaching',
                'components'    => [
                    // Mandatory components
                    ['code' => 'BASIC',   'is_mandatory' => true,  'sequence_order' => 1],
                    ['code' => 'PF_EMP',  'is_mandatory' => true,  'sequence_order' => 10],
                    ['code' => 'ESI_EMP', 'is_mandatory' => true,  'sequence_order' => 11],
                    ['code' => 'PT',      'is_mandatory' => true,  'sequence_order' => 12],
                    ['code' => 'TDS',     'is_mandatory' => true,  'sequence_order' => 13],
                    ['code' => 'PF_ERR',  'is_mandatory' => true,  'sequence_order' => 20],
                    ['code' => 'ESI_ERR', 'is_mandatory' => true,  'sequence_order' => 21],
                    // Optional components
                    ['code' => 'HRA',     'is_mandatory' => false, 'sequence_order' => 3],
                    ['code' => 'DA',      'is_mandatory' => false, 'sequence_order' => 2],
                    ['code' => 'CONV',    'is_mandatory' => false, 'sequence_order' => 4],
                    ['code' => 'MEDICAL', 'is_mandatory' => false, 'sequence_order' => 5],
                    ['code' => 'LTA',     'is_mandatory' => false, 'sequence_order' => 6],
                    ['code' => 'SPECIAL', 'is_mandatory' => false, 'sequence_order' => 7],
                ],
            ],
            [
                'name'          => 'Non-Teaching Structure',
                'description'   => 'Standard structure for non-teaching staff. Includes PF, ESI, PT, TDS.',
                'applicable_to' => 'non_teaching',
                'components'    => [
                    // Mandatory components (same as teaching)
                    ['code' => 'BASIC',   'is_mandatory' => true,  'sequence_order' => 1],
                    ['code' => 'PF_EMP',  'is_mandatory' => true,  'sequence_order' => 10],
                    ['code' => 'ESI_EMP', 'is_mandatory' => true,  'sequence_order' => 11],
                    ['code' => 'PT',      'is_mandatory' => true,  'sequence_order' => 12],
                    ['code' => 'TDS',     'is_mandatory' => true,  'sequence_order' => 13],
                    ['code' => 'PF_ERR',  'is_mandatory' => true,  'sequence_order' => 20],
                    ['code' => 'ESI_ERR', 'is_mandatory' => true,  'sequence_order' => 21],
                    // Optional components
                    ['code' => 'HRA',     'is_mandatory' => false, 'sequence_order' => 3],
                    ['code' => 'DA',      'is_mandatory' => false, 'sequence_order' => 2],
                    ['code' => 'CONV',    'is_mandatory' => false, 'sequence_order' => 4],
                    ['code' => 'MEDICAL', 'is_mandatory' => false, 'sequence_order' => 5],
                    ['code' => 'LTA',     'is_mandatory' => false, 'sequence_order' => 6],
                    ['code' => 'SPECIAL', 'is_mandatory' => false, 'sequence_order' => 7],
                ],
            ],
            [
                'name'          => 'Contractual Structure',
                'description'   => 'Simplified structure for contractual staff. No PF/ESI; includes TDS and LWP deduction.',
                'applicable_to' => 'contractual',
                'components'    => [
                    // Mandatory components
                    ['code' => 'BASIC',   'is_mandatory' => true,  'sequence_order' => 1],
                    ['code' => 'TDS',     'is_mandatory' => true,  'sequence_order' => 13],
                    ['code' => 'LWP_DED', 'is_mandatory' => true,  'sequence_order' => 14],
                    // Optional components
                    ['code' => 'CONV',    'is_mandatory' => false, 'sequence_order' => 4],
                    ['code' => 'SPECIAL', 'is_mandatory' => false, 'sequence_order' => 7],
                ],
            ],
        ];

        foreach ($structures as $structureDef) {
            $components = $structureDef['components'];
            unset($structureDef['components']);

            // Upsert the structure
            $existing = DB::table('pay_salary_structures')
                ->where('name', $structureDef['name'])
                ->where('is_active', 1)
                ->first();

            if ($existing) {
                $structureId = $existing->id;
            } else {
                $structureId = DB::table('pay_salary_structures')->insertGetId(
                    array_merge($structureDef, [
                        'is_active'  => 1,
                        'created_by' => 1,
                        'updated_by' => 1,
                        'created_at' => $now,
                        'updated_at' => $now,
                    ])
                );
            }

            // Insert junction records
            foreach ($components as $comp) {
                $componentId = DB::table('pay_salary_components')
                    ->where('code', $comp['code'])
                    ->value('id');

                if (! $componentId) {
                    continue;
                }

                DB::table('pay_salary_structure_components')->updateOrInsert(
                    [
                        'structure_id' => $structureId,
                        'component_id' => $componentId,
                    ],
                    [
                        'sequence_order'      => $comp['sequence_order'],
                        'calculation_formula' => null,
                        'is_mandatory'        => $comp['is_mandatory'] ? 1 : 0,
                        'is_active'           => 1,
                        'created_by'          => 1,
                        'updated_by'          => 1,
                        'created_at'          => $now,
                        'updated_at'          => $now,
                    ]
                );
            }
        }
    }
}

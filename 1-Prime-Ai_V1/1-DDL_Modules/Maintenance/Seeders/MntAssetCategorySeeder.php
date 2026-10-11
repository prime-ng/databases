<?php

namespace Modules\Maintenance\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * MntAssetCategorySeeder
 *
 * Seeds 9 standard maintenance asset categories per MNT_Maintenance_Requirement.md v2 Section 15.1.
 *
 * Notes:
 *   - auto_assign_role_id = NULL — school admin maps roles per deployment
 *   - sla_escalation_json = NULL — school admin configures escalation thresholds
 *   - priority_keywords_json uses only High and Critical keys;
 *     Low/Medium are never listed (they are defaults/fallbacks, not keywords)
 *   - created_by / updated_by = 1 (system super-admin seeder convention)
 */
class MntAssetCategorySeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        $categories = [
            [
                'name'                   => 'Electrical',
                'code'                   => 'ELEC',
                'description'            => 'Electrical systems, wiring, switchboards, lighting, and power outlets',
                'default_priority'       => 'Medium',
                'sla_hours'              => 8,
                'auto_assign_role_id'    => null,
                'priority_keywords_json' => json_encode([
                    'High'     => ['short circuit', 'no power', 'power failure', 'tripping'],
                    'Critical' => ['electrocution', 'fire', 'sparks'],
                ]),
                'sla_escalation_json'    => null,
                'is_active'              => 1,
                'created_by'             => 1,
                'updated_by'             => 1,
                'created_at'             => $now,
                'updated_at'             => $now,
            ],
            [
                'name'                   => 'Plumbing',
                'code'                   => 'PLMB',
                'description'            => 'Water supply, drainage, taps, pipes, and sanitation systems',
                'default_priority'       => 'Medium',
                'sla_hours'              => 12,
                'auto_assign_role_id'    => null,
                'priority_keywords_json' => json_encode([
                    'High'     => ['water leakage', 'tap dripping', 'drain blocked'],
                    'Critical' => ['flooding', 'burst pipe', 'sewage overflow'],
                ]),
                'sla_escalation_json'    => null,
                'is_active'              => 1,
                'created_by'             => 1,
                'updated_by'             => 1,
                'created_at'             => $now,
                'updated_at'             => $now,
            ],
            [
                'name'                   => 'IT/Computer',
                'code'                   => 'ITCP',
                'description'            => 'Computers, printers, projectors, servers, and network infrastructure',
                'default_priority'       => 'Medium',
                'sla_hours'              => 24,
                'auto_assign_role_id'    => null,
                'priority_keywords_json' => json_encode([
                    'High'     => ['system not working', 'printer down', 'projector'],
                    'Critical' => ['server down', 'internet down'],
                ]),
                'sla_escalation_json'    => null,
                'is_active'              => 1,
                'created_by'             => 1,
                'updated_by'             => 1,
                'created_at'             => $now,
                'updated_at'             => $now,
            ],
            [
                'name'                   => 'Carpentry',
                'code'                   => 'CRPT',
                'description'            => 'Furniture, doors, windows, and woodwork',
                'default_priority'       => 'Low',
                'sla_hours'              => 48,
                'auto_assign_role_id'    => null,
                'priority_keywords_json' => json_encode([
                    'High' => ['broken furniture', 'door stuck', 'window broken'],
                ]),
                'sla_escalation_json'    => null,
                'is_active'              => 1,
                'created_by'             => 1,
                'updated_by'             => 1,
                'created_at'             => $now,
                'updated_at'             => $now,
            ],
            [
                'name'                   => 'Cleaning',
                'code'                   => 'CLNG',
                'description'            => 'Housekeeping, cleaning, and sanitation services',
                'default_priority'       => 'Low',
                'sla_hours'              => 4,
                'auto_assign_role_id'    => null,
                'priority_keywords_json' => json_encode([
                    'High'     => ['not cleaned', 'dirty'],
                    'Critical' => ['biohazard', 'vomit', 'spillage'],
                ]),
                'sla_escalation_json'    => null,
                'is_active'              => 1,
                'created_by'             => 1,
                'updated_by'             => 1,
                'created_at'             => $now,
                'updated_at'             => $now,
            ],
            [
                'name'                   => 'HVAC',
                'code'                   => 'HVAC',
                'description'            => 'Air conditioning, ventilation, and heating systems',
                'default_priority'       => 'Medium',
                'sla_hours'              => 24,
                'auto_assign_role_id'    => null,
                'priority_keywords_json' => json_encode([
                    'High'     => ['AC not cooling', 'AC dripping'],
                    'Critical' => ['AC not working at all', 'fire from AC'],
                ]),
                'sla_escalation_json'    => null,
                'is_active'              => 1,
                'created_by'             => 1,
                'updated_by'             => 1,
                'created_at'             => $now,
                'updated_at'             => $now,
            ],
            [
                'name'                   => 'Fire Safety',
                'code'                   => 'FIRE',
                'description'            => 'Fire extinguishers, smoke alarms, sprinklers, and fire exit maintenance',
                'default_priority'       => 'High',
                'sla_hours'              => 4,
                'auto_assign_role_id'    => null,
                'priority_keywords_json' => json_encode([
                    'High'     => ['extinguisher expired', 'alarm fault'],
                    'Critical' => ['fire detected', 'smoke alarm'],
                ]),
                'sla_escalation_json'    => null,
                'is_active'              => 1,
                'created_by'             => 1,
                'updated_by'             => 1,
                'created_at'             => $now,
                'updated_at'             => $now,
            ],
            [
                'name'                   => 'Civil/Structural',
                'code'                   => 'CVIL',
                'description'            => 'Building structure, walls, ceilings, floors, and civil infrastructure',
                'default_priority'       => 'Medium',
                'sla_hours'              => 48,
                'auto_assign_role_id'    => null,
                'priority_keywords_json' => json_encode([
                    'High'     => ['crack in wall', 'ceiling damage'],
                    'Critical' => ['roof collapse risk', 'structural damage'],
                ]),
                'sla_escalation_json'    => null,
                'is_active'              => 1,
                'created_by'             => 1,
                'updated_by'             => 1,
                'created_at'             => $now,
                'updated_at'             => $now,
            ],
            [
                'name'                   => 'Sports/Ground',
                'code'                   => 'SPRT',
                'description'            => 'Sports equipment, playground, ground maintenance, and outdoor facilities',
                'default_priority'       => 'Low',
                'sla_hours'              => 72,
                'auto_assign_role_id'    => null,
                'priority_keywords_json' => json_encode([
                    'High' => ['equipment damaged', 'ground waterlogged'],
                ]),
                'sla_escalation_json'    => null,
                'is_active'              => 1,
                'created_by'             => 1,
                'updated_by'             => 1,
                'created_at'             => $now,
                'updated_at'             => $now,
            ],
        ];

        DB::table('mnt_asset_categories')->insertOrIgnore($categories);
    }
}

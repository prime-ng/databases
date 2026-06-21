<?php

namespace Modules\VisitorSecurity\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * VsmEmergencyProtocolSeeder
 *
 * Seeds 5 standard emergency protocol templates per VSM_VisitorSecurity_Requirement.md v2 Section 15.3.
 *
 * Notes:
 *   - is_active = 1 (all system protocols active by default)
 *   - responsible_roles_json uses role name strings (not IDs) for portability
 *   - description contains placeholder SOP; school admin should update with school-specific procedures
 *   - created_by / updated_by = 1 (system super-admin seeder convention)
 */
class VsmEmergencyProtocolSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        $protocols = [
            [
                'protocol_type'          => 'Lockdown',
                'title'                  => 'Campus Lockdown Protocol',
                'description'            => 'Step 1: Alert Security. Step 2: Lock all entry and exit gates immediately. Step 3: All students and staff move to designated safe rooms. Step 4: No one enters or exits campus until lockdown is lifted by authorised admin. Step 5: Guard notifies police/emergency services. (Update with school-specific SOP)',
                'responsible_roles_json' => json_encode(['Admin', 'Principal', 'Guard']),
                'media_ids_json'         => null,
                'is_active'              => 1,
                'created_by'             => 1,
                'updated_by'             => 1,
                'created_at'             => $now,
                'updated_at'             => $now,
            ],
            [
                'protocol_type'          => 'Fire',
                'title'                  => 'Fire Emergency Protocol',
                'description'            => 'Step 1: Alert Security and trigger fire alarm. Step 2: Evacuate all students and staff via designated exit routes. Step 3: Teachers account for all students at assembly points. Step 4: No re-entry until fire brigade clears. Step 5: Call fire brigade (101) immediately. (Update with school-specific SOP)',
                'responsible_roles_json' => json_encode(['Admin', 'Principal', 'Teacher', 'Guard']),
                'media_ids_json'         => null,
                'is_active'              => 1,
                'created_by'             => 1,
                'updated_by'             => 1,
                'created_at'             => $now,
                'updated_at'             => $now,
            ],
            [
                'protocol_type'          => 'Earthquake',
                'title'                  => 'Earthquake Response Protocol',
                'description'            => 'Step 1: Alert Security. Step 2: Students and staff duck, cover, and hold under sturdy furniture during tremor. Step 3: After tremor stops, evacuate to open ground away from buildings. Step 4: Teachers conduct headcount at assembly point. Step 5: Do not re-enter buildings until structural safety is confirmed. (Update with school-specific SOP)',
                'responsible_roles_json' => json_encode(['Admin', 'Principal', 'Teacher']),
                'media_ids_json'         => null,
                'is_active'              => 1,
                'created_by'             => 1,
                'updated_by'             => 1,
                'created_at'             => $now,
                'updated_at'             => $now,
            ],
            [
                'protocol_type'          => 'MedicalEmergency',
                'title'                  => 'Medical Emergency Protocol',
                'description'            => 'Step 1: Alert Security and school nurse/first aider. Step 2: Call ambulance (108) immediately for serious emergencies. Step 3: Keep patient calm and do not move unnecessarily. Step 4: Notify parents/guardians. Step 5: Accompany student to hospital with responsible staff. (Update with school-specific SOP)',
                'responsible_roles_json' => json_encode(['Admin', 'Principal', 'Teacher']),
                'media_ids_json'         => null,
                'is_active'              => 1,
                'created_by'             => 1,
                'updated_by'             => 1,
                'created_at'             => $now,
                'updated_at'             => $now,
            ],
            [
                'protocol_type'          => 'Evacuation',
                'title'                  => 'Evacuation Protocol',
                'description'            => 'Step 1: Alert Security. Step 2: Follow designated evacuation route maps posted in each classroom. Step 3: Teachers lead students to primary assembly point in orderly manner. Step 4: Conduct roll-call at assembly point; report missing students to Principal immediately. Step 5: Security guards manage entry/exit gates to prevent re-entry. (Update with school-specific SOP)',
                'responsible_roles_json' => json_encode(['Admin', 'Principal', 'Teacher', 'Guard']),
                'media_ids_json'         => null,
                'is_active'              => 1,
                'created_by'             => 1,
                'updated_by'             => 1,
                'created_at'             => $now,
                'updated_at'             => $now,
            ],
        ];

        DB::table('vsm_emergency_protocols')->insertOrIgnore($protocols);
    }
}

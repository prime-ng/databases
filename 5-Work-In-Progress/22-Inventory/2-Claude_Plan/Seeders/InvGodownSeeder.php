<?php

namespace Modules\Inventory\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Seeds 5 system godowns (storage locations) covering typical school stores.
 * is_system=1 prevents deletion from UI.
 * in_charge_employee_id=NULL at seed time — assigned post onboarding via UI.
 */
class InvGodownSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        $godowns = [
            [
                'name'    => 'Main Store',
                'code'    => 'MAIN',
                'address' => 'Ground Floor, Administrative Block',
            ],
            [
                'name'    => 'IT Store',
                'code'    => 'IT-STORE',
                'address' => 'Computer Lab Block',
            ],
            [
                'name'    => 'Sports Store',
                'code'    => 'SPORT',
                'address' => 'Sports Complex',
            ],
            [
                'name'    => 'Science Lab Store',
                'code'    => 'SCI-LAB',
                'address' => 'Science Block, Ground Floor',
            ],
            [
                'name'    => 'General Store',
                'code'    => 'GEN',
                'address' => 'Service Block',
            ],
        ];

        foreach ($godowns as $godown) {
            DB::table('inv_godowns')->insertOrIgnore([
                'name'                    => $godown['name'],
                'code'                    => $godown['code'],
                'parent_id'               => null,
                'address'                 => $godown['address'],
                'in_charge_employee_id'   => null,
                'is_system'               => 1,
                'is_active'               => 1,
                'created_by'              => 1,
                'updated_by'              => 1,
                'created_at'              => $now,
                'updated_at'              => $now,
            ]);
        }
    }
}

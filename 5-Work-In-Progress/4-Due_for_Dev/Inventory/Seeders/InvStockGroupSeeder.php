<?php

namespace Modules\Inventory\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Seeds 10 system stock groups covering common school inventory categories.
 * default_uom_id resolved dynamically from inv_units_of_measure seeded by InvUomSeeder.
 * is_system=1 prevents deletion from UI.
 * Run AFTER InvUomSeeder.
 */
class InvStockGroupSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        // Resolve UOM IDs seeded by InvUomSeeder
        $pcs = DB::table('inv_units_of_measure')->where('symbol', 'Pcs')->value('id');
        $kg  = DB::table('inv_units_of_measure')->where('symbol', 'Kg')->value('id');
        $ltr = DB::table('inv_units_of_measure')->where('symbol', 'L')->value('id');

        $groups = [
            ['name' => 'Stationery',         'code' => 'STAT',    'default_uom_id' => $pcs,  'sequence' => 1],
            ['name' => 'IT Equipment',        'code' => 'IT-EQP',  'default_uom_id' => $pcs,  'sequence' => 2],
            ['name' => 'Furniture',           'code' => 'FURN',    'default_uom_id' => $pcs,  'sequence' => 3],
            ['name' => 'Electrical',          'code' => 'ELEC',    'default_uom_id' => $pcs,  'sequence' => 4],
            ['name' => 'Plumbing',            'code' => 'PLMB',    'default_uom_id' => $pcs,  'sequence' => 5],
            ['name' => 'Sports Equipment',    'code' => 'SPORT',   'default_uom_id' => $pcs,  'sequence' => 6],
            ['name' => 'Medical Supplies',    'code' => 'MED',     'default_uom_id' => $pcs,  'sequence' => 7],
            ['name' => 'Cleaning Materials',  'code' => 'CLEAN',   'default_uom_id' => $ltr,  'sequence' => 8],
            ['name' => 'Lab Equipment',       'code' => 'LAB',     'default_uom_id' => $pcs,  'sequence' => 9],
            ['name' => 'Books & Curriculum',  'code' => 'BOOK',    'default_uom_id' => $pcs,  'sequence' => 10],
        ];

        foreach ($groups as $group) {
            DB::table('inv_stock_groups')->insertOrIgnore([
                'name'           => $group['name'],
                'code'           => $group['code'],
                'alias'          => null,
                'parent_id'      => null,
                'default_uom_id' => $group['default_uom_id'],
                'sequence'       => $group['sequence'],
                'is_system'      => 1,
                'is_active'      => 1,
                'created_by'     => 1,
                'updated_by'     => 1,
                'created_at'     => $now,
                'updated_at'     => $now,
            ]);
        }
    }
}

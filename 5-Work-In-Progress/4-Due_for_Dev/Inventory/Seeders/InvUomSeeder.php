<?php

namespace Modules\Inventory\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Seeds 10 system UOMs required for Inventory module operation.
 * is_system=1 prevents deletion from UI.
 * created_by/updated_by = 1 (system user).
 */
class InvUomSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        $uoms = [
            ['name' => 'Pieces',       'symbol' => 'Pcs',  'decimal_places' => 0],
            ['name' => 'Kilogram',     'symbol' => 'Kg',   'decimal_places' => 3],
            ['name' => 'Litre',        'symbol' => 'L',    'decimal_places' => 3],
            ['name' => 'Box',          'symbol' => 'Box',  'decimal_places' => 0],
            ['name' => 'Carton',       'symbol' => 'Ctn',  'decimal_places' => 0],
            ['name' => 'Metre',        'symbol' => 'm',    'decimal_places' => 2],
            ['name' => 'Square Metre', 'symbol' => 'sqm',  'decimal_places' => 2],
            ['name' => 'Cubic Metre',  'symbol' => 'cum',  'decimal_places' => 3],
            ['name' => 'Dozen',        'symbol' => 'Doz',  'decimal_places' => 0],
            ['name' => 'Pack',         'symbol' => 'Pck',  'decimal_places' => 0],
        ];

        foreach ($uoms as $uom) {
            DB::table('inv_units_of_measure')->insertOrIgnore([
                'name'           => $uom['name'],
                'symbol'         => $uom['symbol'],
                'decimal_places' => $uom['decimal_places'],
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

<?php

namespace Modules\HrStaff\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class HrsIdCardTemplateSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        $exists = DB::table('hrs_id_card_templates')
            ->where('is_default', 1)
            ->where('is_active', 1)
            ->exists();

        if (! $exists) {
            DB::table('hrs_id_card_templates')->insert([
                'name'        => 'Default',
                'layout_json' => json_encode([
                    'fields'       => ['photo', 'name', 'designation', 'department', 'emp_code', 'qr_code'],
                    'dimensions'   => ['width' => '85.6mm', 'height' => '53.98mm'],
                    'color_scheme' => 'blue',
                    'logo_position'=> 'top_left',
                    'qr_data'      => 'emp_code',
                ]),
                'is_default'  => 1,
                'is_active'   => 1,
                'created_by'  => 1,
                'updated_by'  => 1,
                'created_at'  => $now,
                'updated_at'  => $now,
            ]);
        }
    }
}

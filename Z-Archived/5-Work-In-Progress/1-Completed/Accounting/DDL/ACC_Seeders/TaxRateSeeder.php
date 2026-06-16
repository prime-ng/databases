<?php

namespace Modules\Accounting\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class TaxRateSeeder extends Seeder
{
    /**
     * Seed acc_tax_rates with 5 standard Indian GST rates.
     */
    public function run(): void
    {
        $now = now();

        $taxRates = [
            [
                'name'           => 'CGST 9%',
                'type'           => 'CGST',
                'rate'           => 9.00,
                'is_interstate'  => 0,
                'is_active'      => 1,
                'created_at'     => $now,
            ],
            [
                'name'           => 'SGST 9%',
                'type'           => 'SGST',
                'rate'           => 9.00,
                'is_interstate'  => 0,
                'is_active'      => 1,
                'created_at'     => $now,
            ],
            [
                'name'           => 'IGST 18%',
                'type'           => 'IGST',
                'rate'           => 18.00,
                'is_interstate'  => 1,
                'is_active'      => 1,
                'created_at'     => $now,
            ],
            [
                'name'           => 'CGST 2.5%',
                'type'           => 'CGST',
                'rate'           => 2.50,
                'is_interstate'  => 0,
                'is_active'      => 1,
                'created_at'     => $now,
            ],
            [
                'name'           => 'SGST 2.5%',
                'type'           => 'SGST',
                'rate'           => 2.50,
                'is_interstate'  => 0,
                'is_active'      => 1,
                'created_at'     => $now,
            ],
        ];

        DB::table('acc_tax_rates')->insert($taxRates);
    }
}

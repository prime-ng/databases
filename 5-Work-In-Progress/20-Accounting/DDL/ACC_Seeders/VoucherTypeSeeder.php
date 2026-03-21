<?php

namespace Modules\Accounting\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class VoucherTypeSeeder extends Seeder
{
    /**
     * Seed acc_voucher_types with 10 standard voucher types.
     */
    public function run(): void
    {
        $now = now();

        $voucherTypes = [
            [
                'name'        => 'Payment Voucher',
                'code'        => 'PAYMENT',
                'category'    => 'accounting',
                'prefix'      => 'PAY-',
                'is_system'   => 1,
                'is_active'   => 1,
                'created_at'  => $now,
            ],
            [
                'name'        => 'Receipt Voucher',
                'code'        => 'RECEIPT',
                'category'    => 'accounting',
                'prefix'      => 'RCV-',
                'is_system'   => 1,
                'is_active'   => 1,
                'created_at'  => $now,
            ],
            [
                'name'        => 'Contra Voucher',
                'code'        => 'CONTRA',
                'category'    => 'accounting',
                'prefix'      => 'CNT-',
                'is_system'   => 1,
                'is_active'   => 1,
                'created_at'  => $now,
            ],
            [
                'name'        => 'Journal Voucher',
                'code'        => 'JOURNAL',
                'category'    => 'accounting',
                'prefix'      => 'JRN-',
                'is_system'   => 1,
                'is_active'   => 1,
                'created_at'  => $now,
            ],
            [
                'name'        => 'Sales Voucher',
                'code'        => 'SALES',
                'category'    => 'accounting',
                'prefix'      => 'SAL-',
                'is_system'   => 1,
                'is_active'   => 1,
                'created_at'  => $now,
            ],
            [
                'name'        => 'Purchase Voucher',
                'code'        => 'PURCHASE',
                'category'    => 'accounting',
                'prefix'      => 'PUR-',
                'is_system'   => 1,
                'is_active'   => 1,
                'created_at'  => $now,
            ],
            [
                'name'        => 'Credit Note',
                'code'        => 'CREDIT_NOTE',
                'category'    => 'accounting',
                'prefix'      => 'CN-',
                'is_system'   => 1,
                'is_active'   => 1,
                'created_at'  => $now,
            ],
            [
                'name'        => 'Debit Note',
                'code'        => 'DEBIT_NOTE',
                'category'    => 'accounting',
                'prefix'      => 'DN-',
                'is_system'   => 1,
                'is_active'   => 1,
                'created_at'  => $now,
            ],
            [
                'name'        => 'Stock Journal',
                'code'        => 'STOCK_JOURNAL',
                'category'    => 'inventory',
                'prefix'      => 'STJ-',
                'is_system'   => 1,
                'is_active'   => 1,
                'created_at'  => $now,
            ],
            [
                'name'        => 'Payroll Voucher',
                'code'        => 'PAYROLL',
                'category'    => 'payroll',
                'prefix'      => 'PRL-',
                'is_system'   => 1,
                'is_active'   => 1,
                'created_at'  => $now,
            ],
        ];

        DB::table('acc_voucher_types')->insert($voucherTypes);
    }
}

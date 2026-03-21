<?php

namespace Modules\Accounting\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DefaultLedgerSeeder extends Seeder
{
    /**
     * Seed acc_ledgers with 11 default system ledgers.
     * Depends on AccountGroupSeeder having run first.
     */
    public function run(): void
    {
        $now   = now();
        $table = 'acc_ledgers';

        // Helper to resolve account_group_id by group name
        $groupId = function (string $groupName): int {
            return DB::table('acc_account_groups')
                ->where('name', $groupName)
                ->value('id');
        };

        $ledgers = [
            [
                'name'             => 'Profit & Loss A/c',
                'code'             => 'LED-PL',
                'account_group_id' => $groupId('Suspense Account'),
                'opening_balance'  => 0.00,
                'balance_type'     => 'Credit',
                'as_of_date'       => now()->startOfYear()->format('Y-m-d'),
                'is_cash_account'  => 0,
                'is_system'        => 1,
                'is_active'        => 1,
                'created_at'       => $now,
            ],
            [
                'name'             => 'Cash A/c',
                'code'             => 'LED-CASH',
                'account_group_id' => $groupId('Cash-in-Hand'),
                'opening_balance'  => 0.00,
                'balance_type'     => 'Debit',
                'as_of_date'       => now()->startOfYear()->format('Y-m-d'),
                'is_cash_account'  => 1,
                'is_system'        => 1,
                'is_active'        => 1,
                'created_at'       => $now,
            ],
            [
                'name'             => 'Petty Cash',
                'code'             => 'LED-PCASH',
                'account_group_id' => $groupId('Cash-in-Hand'),
                'opening_balance'  => 0.00,
                'balance_type'     => 'Debit',
                'as_of_date'       => now()->startOfYear()->format('Y-m-d'),
                'is_cash_account'  => 1,
                'is_system'        => 1,
                'is_active'        => 1,
                'created_at'       => $now,
            ],
            [
                'name'             => 'GST Payable',
                'code'             => 'LED-GST',
                'account_group_id' => $groupId('Duties & Taxes'),
                'opening_balance'  => 0.00,
                'balance_type'     => 'Credit',
                'as_of_date'       => now()->startOfYear()->format('Y-m-d'),
                'is_cash_account'  => 0,
                'is_system'        => 1,
                'is_active'        => 1,
                'created_at'       => $now,
            ],
            [
                'name'             => 'TDS Payable',
                'code'             => 'LED-TDS',
                'account_group_id' => $groupId('Duties & Taxes'),
                'opening_balance'  => 0.00,
                'balance_type'     => 'Credit',
                'as_of_date'       => now()->startOfYear()->format('Y-m-d'),
                'is_cash_account'  => 0,
                'is_system'        => 1,
                'is_active'        => 1,
                'created_at'       => $now,
            ],
            [
                'name'             => 'PF Payable',
                'code'             => 'LED-PF',
                'account_group_id' => $groupId('Provisions'),
                'opening_balance'  => 0.00,
                'balance_type'     => 'Credit',
                'as_of_date'       => now()->startOfYear()->format('Y-m-d'),
                'is_cash_account'  => 0,
                'is_system'        => 1,
                'is_active'        => 1,
                'created_at'       => $now,
            ],
            [
                'name'             => 'ESI Payable',
                'code'             => 'LED-ESI',
                'account_group_id' => $groupId('Provisions'),
                'opening_balance'  => 0.00,
                'balance_type'     => 'Credit',
                'as_of_date'       => now()->startOfYear()->format('Y-m-d'),
                'is_cash_account'  => 0,
                'is_system'        => 1,
                'is_active'        => 1,
                'created_at'       => $now,
            ],
            [
                'name'             => 'PT Payable',
                'code'             => 'LED-PT',
                'account_group_id' => $groupId('Duties & Taxes'),
                'opening_balance'  => 0.00,
                'balance_type'     => 'Credit',
                'as_of_date'       => now()->startOfYear()->format('Y-m-d'),
                'is_cash_account'  => 0,
                'is_system'        => 1,
                'is_active'        => 1,
                'created_at'       => $now,
            ],
            [
                'name'             => 'Salary Payable',
                'code'             => 'LED-SAL',
                'account_group_id' => $groupId('Provisions'),
                'opening_balance'  => 0.00,
                'balance_type'     => 'Credit',
                'as_of_date'       => now()->startOfYear()->format('Y-m-d'),
                'is_cash_account'  => 0,
                'is_system'        => 1,
                'is_active'        => 1,
                'created_at'       => $now,
            ],
            [
                'name'             => 'Transport Fee Income',
                'code'             => 'LED-TPTFEE',
                'account_group_id' => $groupId('Transport Fee Income'),
                'opening_balance'  => 0.00,
                'balance_type'     => 'Credit',
                'as_of_date'       => now()->startOfYear()->format('Y-m-d'),
                'is_cash_account'  => 0,
                'is_system'        => 1,
                'is_active'        => 1,
                'created_at'       => $now,
            ],
            [
                'name'             => 'Fine Income',
                'code'             => 'LED-FINE',
                'account_group_id' => $groupId('Indirect Income'),
                'opening_balance'  => 0.00,
                'balance_type'     => 'Credit',
                'as_of_date'       => now()->startOfYear()->format('Y-m-d'),
                'is_cash_account'  => 0,
                'is_system'        => 1,
                'is_active'        => 1,
                'created_at'       => $now,
            ],
        ];

        foreach ($ledgers as $ledger) {
            DB::table($table)->insert($ledger);
        }
    }
}

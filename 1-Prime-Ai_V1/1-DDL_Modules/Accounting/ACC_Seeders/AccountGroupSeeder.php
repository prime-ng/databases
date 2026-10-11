<?php

namespace Modules\Accounting\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class AccountGroupSeeder extends Seeder
{
    /**
     * Seed acc_account_groups with Tally's 28 standard groups + 5 school-specific.
     * Parents are inserted first so parent_id lookups resolve correctly.
     */
    public function run(): void
    {
        $table = 'acc_account_groups';
        $now   = now();

        // ─── Phase 1: Top-level groups (no parent) ───────────────────

        $topLevel = [
            // Balance Sheet
            ['name' => 'Capital Account',       'code' => 'A01', 'parent_id' => null, 'group_type' => 'Liabilities', 'nature' => 'Credit',  'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 1],
            ['name' => 'Current Assets',        'code' => 'A03', 'parent_id' => null, 'group_type' => 'Assets',      'nature' => 'Debit',   'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 3],
            ['name' => 'Fixed Assets',          'code' => 'A10', 'parent_id' => null, 'group_type' => 'Assets',      'nature' => 'Debit',   'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 10],
            ['name' => 'Investments',           'code' => 'A11', 'parent_id' => null, 'group_type' => 'Assets',      'nature' => 'Debit',   'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 11],
            ['name' => 'Current Liabilities',   'code' => 'A12', 'parent_id' => null, 'group_type' => 'Liabilities', 'nature' => 'Credit',  'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 12],
            ['name' => 'Secured Loans',         'code' => 'A16', 'parent_id' => null, 'group_type' => 'Liabilities', 'nature' => 'Credit',  'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 16],
            ['name' => 'Unsecured Loans',       'code' => 'A17', 'parent_id' => null, 'group_type' => 'Liabilities', 'nature' => 'Credit',  'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 17],

            // P&L
            ['name' => 'Sales Account',         'code' => 'A19', 'parent_id' => null, 'group_type' => 'Income',  'nature' => 'Credit',  'affects_gross_profit' => 1, 'is_system' => 1, 'sequence' => 19],
            ['name' => 'Purchase Account',      'code' => 'A20', 'parent_id' => null, 'group_type' => 'Expense', 'nature' => 'Debit',   'affects_gross_profit' => 1, 'is_system' => 1, 'sequence' => 20],
            ['name' => 'Direct Income',         'code' => 'A21', 'parent_id' => null, 'group_type' => 'Income',  'nature' => 'Credit',  'affects_gross_profit' => 1, 'is_system' => 1, 'sequence' => 21],
            ['name' => 'Direct Expenses',       'code' => 'A22', 'parent_id' => null, 'group_type' => 'Expense', 'nature' => 'Debit',   'affects_gross_profit' => 1, 'is_system' => 1, 'sequence' => 22],
            ['name' => 'Indirect Income',       'code' => 'A23', 'parent_id' => null, 'group_type' => 'Income',  'nature' => 'Credit',  'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 23],
            ['name' => 'Indirect Expenses',     'code' => 'A24', 'parent_id' => null, 'group_type' => 'Expense', 'nature' => 'Debit',   'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 24],
            ['name' => 'Suspense Account',      'code' => 'A25', 'parent_id' => null, 'group_type' => 'Liabilities', 'nature' => 'Credit',  'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 25],
            ['name' => 'Misc Expenses (Asset)', 'code' => 'A26', 'parent_id' => null, 'group_type' => 'Assets',      'nature' => 'Debit',   'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 26],
            ['name' => 'Branch/Divisions',      'code' => 'A27', 'parent_id' => null, 'group_type' => 'Liabilities', 'nature' => 'Credit',  'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 27],
        ];

        foreach ($topLevel as $group) {
            DB::table($table)->insert(array_merge($group, [
                'is_active'  => 1,
                'created_at' => $now,
            ]));
        }

        // ─── Phase 2: Child groups (need parent_id lookup) ──────────

        $children = [
            // Balance Sheet children
            ['name' => 'Reserves & Surplus',       'code' => 'A02', 'parent_code' => 'A01', 'group_type' => 'Liabilities', 'nature' => 'Credit', 'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 2],
            ['name' => 'Bank Accounts',            'code' => 'A04', 'parent_code' => 'A03', 'group_type' => 'Assets',      'nature' => 'Debit',  'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 4],
            ['name' => 'Cash-in-Hand',             'code' => 'A05', 'parent_code' => 'A03', 'group_type' => 'Assets',      'nature' => 'Debit',  'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 5],
            ['name' => 'Sundry Debtors',           'code' => 'A06', 'parent_code' => 'A03', 'group_type' => 'Assets',      'nature' => 'Debit',  'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 6],
            ['name' => 'Stock-in-Hand',            'code' => 'A07', 'parent_code' => 'A03', 'group_type' => 'Assets',      'nature' => 'Debit',  'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 7],
            ['name' => 'Deposits (Asset)',         'code' => 'A08', 'parent_code' => 'A03', 'group_type' => 'Assets',      'nature' => 'Debit',  'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 8],
            ['name' => 'Loans & Advances (Asset)', 'code' => 'A09', 'parent_code' => 'A03', 'group_type' => 'Assets',      'nature' => 'Debit',  'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 9],
            ['name' => 'Sundry Creditors',         'code' => 'A13', 'parent_code' => 'A12', 'group_type' => 'Liabilities', 'nature' => 'Credit', 'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 13],
            ['name' => 'Duties & Taxes',           'code' => 'A14', 'parent_code' => 'A12', 'group_type' => 'Liabilities', 'nature' => 'Credit', 'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 14],
            ['name' => 'Provisions',               'code' => 'A15', 'parent_code' => 'A12', 'group_type' => 'Liabilities', 'nature' => 'Credit', 'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 15],
            ['name' => 'Bank OD Accounts',         'code' => 'A18', 'parent_code' => 'A16', 'group_type' => 'Liabilities', 'nature' => 'Credit', 'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 18],
        ];

        foreach ($children as $group) {
            $parentCode = $group['parent_code'];
            unset($group['parent_code']);

            $group['parent_id'] = DB::table($table)->where('code', $parentCode)->value('id');

            DB::table($table)->insert(array_merge($group, [
                'is_active'  => 1,
                'created_at' => $now,
            ]));
        }

        // ─── Phase 3: School-specific groups (children of P&L groups) ─

        $schoolGroups = [
            ['name' => 'Fee Income',                  'code' => 'S01', 'parent_code' => 'A21', 'group_type' => 'Income',  'nature' => 'Credit', 'affects_gross_profit' => 1, 'is_system' => 1, 'sequence' => 28],
            ['name' => 'Transport Fee Income',        'code' => 'S02', 'parent_code' => 'A21', 'group_type' => 'Income',  'nature' => 'Credit', 'affects_gross_profit' => 1, 'is_system' => 1, 'sequence' => 29],
            ['name' => 'Teaching Staff Expenses',     'code' => 'S03', 'parent_code' => 'A22', 'group_type' => 'Expense', 'nature' => 'Debit',  'affects_gross_profit' => 1, 'is_system' => 1, 'sequence' => 30],
            ['name' => 'Non-Teaching Staff Expenses',  'code' => 'S04', 'parent_code' => 'A24', 'group_type' => 'Expense', 'nature' => 'Debit',  'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 31],
            ['name' => 'Administrative Expenses',     'code' => 'S05', 'parent_code' => 'A24', 'group_type' => 'Expense', 'nature' => 'Debit',  'affects_gross_profit' => 0, 'is_system' => 1, 'sequence' => 32],
        ];

        foreach ($schoolGroups as $group) {
            $parentCode = $group['parent_code'];
            unset($group['parent_code']);

            $group['parent_id'] = DB::table($table)->where('code', $parentCode)->value('id');

            DB::table($table)->insert(array_merge($group, [
                'is_active'  => 1,
                'created_at' => $now,
            ]));
        }
    }
}

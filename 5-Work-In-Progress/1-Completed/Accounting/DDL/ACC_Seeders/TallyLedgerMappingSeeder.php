<?php

namespace Modules\Accounting\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class TallyLedgerMappingSeeder extends Seeder
{
    /**
     * Seed acc_tally_ledger_mappings for all ledgers created by DefaultLedgerSeeder.
     * Each ledger gets a mapping row with its Tally-equivalent name and parent group.
     * Depends on AccountGroupSeeder and DefaultLedgerSeeder having run first.
     */
    public function run(): void
    {
        $now   = now();
        $table = 'acc_tally_ledger_mappings';

        // Define mappings: ledger_code => tally_group_name
        // tally_ledger_name defaults to the same name as our ledger
        $mappingDefinitions = [
            'LED-PL'     => ['tally_group' => 'Suspense Account'],
            'LED-CASH'   => ['tally_group' => 'Cash-in-Hand'],
            'LED-PCASH'  => ['tally_group' => 'Cash-in-Hand'],
            'LED-GST'    => ['tally_group' => 'Duties & Taxes'],
            'LED-TDS'    => ['tally_group' => 'Duties & Taxes'],
            'LED-PF'     => ['tally_group' => 'Provisions'],
            'LED-ESI'    => ['tally_group' => 'Provisions'],
            'LED-PT'     => ['tally_group' => 'Duties & Taxes'],
            'LED-SAL'    => ['tally_group' => 'Provisions'],
            'LED-TPTFEE' => ['tally_group' => 'Direct Income'],
            'LED-FINE'   => ['tally_group' => 'Indirect Income'],
        ];

        // Fetch all seeded ledgers in one query
        $ledgers = DB::table('acc_ledgers')
            ->whereIn('code', array_keys($mappingDefinitions))
            ->get(['id', 'name', 'code']);

        $mappings = [];

        foreach ($ledgers as $ledger) {
            $def = $mappingDefinitions[$ledger->code];

            $mappings[] = [
                'ledger_id'          => $ledger->id,
                'tally_ledger_name'  => $ledger->name,
                'tally_group_name'   => $def['tally_group'],
                'mapping_type'       => 'auto',
                'sync_direction'     => 'export_only',
                'is_active'          => 1,
                'created_at'         => $now,
            ];
        }

        // Bulk insert all mappings
        if (! empty($mappings)) {
            DB::table($table)->insert($mappings);
        }
    }
}

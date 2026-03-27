<?php

namespace Modules\FrontOffice\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class FofVisitorPurposeSeeder extends Seeder
{
    public function run(): void
    {
        $purposes = [
            [
                'name'                => 'Parent Meeting',
                'code'                => 'PARENT_MTG',
                'is_government_visit' => 0,
                'sort_order'          => 1,
                'is_active'           => 1,
                'created_by'          => 1,
                'updated_by'          => 1,
            ],
            [
                'name'                => 'Government Inspection',
                'code'                => 'GOVT_INSPECTION',
                'is_government_visit' => 1,  // BR-FOF-007: permanent retention; delete blocked by VisitorPolicy
                'sort_order'          => 2,
                'is_active'           => 1,
                'created_by'          => 1,
                'updated_by'          => 1,
            ],
            [
                'name'                => 'Job Interview',
                'code'                => 'JOB_INTERVIEW',
                'is_government_visit' => 0,
                'sort_order'          => 3,
                'is_active'           => 1,
                'created_by'          => 1,
                'updated_by'          => 1,
            ],
            [
                'name'                => 'Delivery / Courier',
                'code'                => 'DELIVERY',
                'is_government_visit' => 0,
                'sort_order'          => 4,
                'is_active'           => 1,
                'created_by'          => 1,
                'updated_by'          => 1,
            ],
            [
                'name'                => 'Sales Visit',
                'code'                => 'SALES_VISIT',
                'is_government_visit' => 0,
                'sort_order'          => 5,
                'is_active'           => 1,
                'created_by'          => 1,
                'updated_by'          => 1,
            ],
            [
                'name'                => 'Alumni Visit',
                'code'                => 'ALUMNI',
                'is_government_visit' => 0,
                'sort_order'          => 6,
                'is_active'           => 1,
                'created_by'          => 1,
                'updated_by'          => 1,
            ],
            [
                'name'                => 'Emergency',
                'code'                => 'EMERGENCY',
                'is_government_visit' => 0,
                'sort_order'          => 7,
                'is_active'           => 1,
                'created_by'          => 1,
                'updated_by'          => 1,
            ],
            [
                'name'                => 'Other',
                'code'                => 'OTHER',
                'is_government_visit' => 0,
                'sort_order'          => 99,
                'is_active'           => 1,
                'created_by'          => 1,
                'updated_by'          => 1,
            ],
        ];

        DB::table('fof_visitor_purposes')->upsert(
            $purposes,
            ['code'],                                    // unique key for conflict detection
            ['name', 'is_government_visit', 'sort_order', 'is_active', 'updated_by']  // columns to update on conflict
        );

        $this->command->info('FofVisitorPurposeSeeder: 8 visitor purposes seeded (upsert on code).');
        $this->command->line('  ✓ GOVT_INSPECTION seeded with is_government_visit=1 (BR-FOF-007)');
    }
}

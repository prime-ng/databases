<?php

namespace Modules\Certificate\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CrtCertificateTypeSeeder extends Seeder
{
    /**
     * Seed 5 standard certificate types.
     * Uses upsert on ['code'] — safe to re-run.
     * created_by / updated_by default to 1 (first admin user).
     */
    public function run(): void
    {
        $now = now();

        $types = [
            [
                'name'              => 'Bonafide Certificate',
                'code'              => 'BON',
                'category'          => 'administrative',
                'requires_approval' => 1,
                'validity_days'     => 180,
                'serial_format'     => '{TYPE_CODE}-{YYYY}-{SEQ6}',
                'description'       => 'Proof of current enrollment. Required by banks, embassies, and government offices.',
                'is_active'         => 1,
                'created_by'        => 1,
                'updated_by'        => 1,
                'created_at'        => $now,
                'updated_at'        => $now,
            ],
            [
                'name'              => 'Transfer Certificate',
                'code'              => 'TC',
                'category'          => 'legal',
                'requires_approval' => 1,
                'validity_days'     => null,
                'serial_format'     => '{TYPE_CODE}-{YYYY}-{SEQ4}',
                'description'       => 'Legally mandated document issued when a student leaves the school. Triggers TC register entry and student status update.',
                'is_active'         => 1,
                'created_by'        => 1,
                'updated_by'        => 1,
                'created_at'        => $now,
                'updated_at'        => $now,
            ],
            [
                'name'              => 'Character Certificate',
                'code'              => 'CHR',
                'category'          => 'character',
                'requires_approval' => 1,
                'validity_days'     => 365,
                'serial_format'     => '{TYPE_CODE}-{YYYY}-{SEQ6}',
                'description'       => 'Attests to the student\'s character and conduct during their period of study.',
                'is_active'         => 1,
                'created_by'        => 1,
                'updated_by'        => 1,
                'created_at'        => $now,
                'updated_at'        => $now,
            ],
            [
                'name'              => 'Merit Certificate',
                'code'              => 'MRT',
                'category'          => 'achievement',
                'requires_approval' => 0,
                'validity_days'     => null,
                'serial_format'     => '{TYPE_CODE}-{YYYY}-{SEQ6}',
                'description'       => 'Achievement certificate for academic merit. Admin-initiated; no approval workflow required.',
                'is_active'         => 1,
                'created_by'        => 1,
                'updated_by'        => 1,
                'created_at'        => $now,
                'updated_at'        => $now,
            ],
            [
                'name'              => 'Sports Certificate',
                'code'              => 'SPT',
                'category'          => 'achievement',
                'requires_approval' => 0,
                'validity_days'     => null,
                'serial_format'     => '{TYPE_CODE}-{YYYY}-{SEQ6}',
                'description'       => 'Achievement certificate for sports participation or excellence. Admin-initiated; no approval workflow.',
                'is_active'         => 1,
                'created_by'        => 1,
                'updated_by'        => 1,
                'created_at'        => $now,
                'updated_at'        => $now,
            ],
        ];

        DB::table('crt_certificate_types')->upsert(
            $types,
            ['code'],  // unique key to match on
            [          // columns to update on conflict
                'name',
                'category',
                'requires_approval',
                'validity_days',
                'serial_format',
                'description',
                'is_active',
                'updated_by',
                'updated_at',
            ]
        );

        $this->command?->info('CrtCertificateTypeSeeder: 5 certificate types seeded.');
    }
}

<?php

namespace Modules\Admission\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Seeds default global document checklist templates.
 *
 * Rows have is_system=1 and admission_cycle_id=NULL, making them
 * global templates that apply across all cycles until overridden.
 * These are the 8 standard documents required for Indian school admissions.
 *
 * Run via: AdmissionSeederRunner (or directly for fresh installs)
 * Safe to re-run — uses upsert on document_code.
 */
class AdmissionDocumentChecklistSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        $documents = [
            [
                'document_name'    => 'Birth Certificate',
                'document_code'    => 'BIRTH_CERT',
                'is_mandatory'     => 1,
                'accepted_formats' => 'pdf,jpg,png',
                'max_size_kb'      => 5120,
                'sort_order'       => 1,
            ],
            [
                'document_name'    => 'Aadhar Card',
                'document_code'    => 'AADHAR',
                'is_mandatory'     => 1,
                'accepted_formats' => 'pdf,jpg,png',
                'max_size_kb'      => 2048,
                'sort_order'       => 2,
            ],
            [
                'document_name'    => 'Passport Size Photo',
                'document_code'    => 'PHOTO',
                'is_mandatory'     => 1,
                'accepted_formats' => 'jpg,png',
                'max_size_kb'      => 512,
                'sort_order'       => 3,
            ],
            [
                'document_name'    => 'Previous School Transfer Certificate',
                'document_code'    => 'PREV_TC',
                'is_mandatory'     => 1,
                'accepted_formats' => 'pdf,jpg,png',
                'max_size_kb'      => 5120,
                'sort_order'       => 4,
            ],
            [
                'document_name'    => 'Previous School Report Card',
                'document_code'    => 'REPORT_CARD',
                'is_mandatory'     => 1,
                'accepted_formats' => 'pdf,jpg,png',
                'max_size_kb'      => 5120,
                'sort_order'       => 5,
            ],
            [
                'document_name'    => 'Caste Certificate',
                'document_code'    => 'CASTE_CERT',
                'is_mandatory'     => 0,
                'accepted_formats' => 'pdf,jpg,png',
                'max_size_kb'      => 5120,
                'sort_order'       => 6,
            ],
            [
                'document_name'    => 'Address Proof',
                'document_code'    => 'ADDRESS_PROOF',
                'is_mandatory'     => 1,
                'accepted_formats' => 'pdf,jpg,png',
                'max_size_kb'      => 5120,
                'sort_order'       => 7,
            ],
            [
                'document_name'    => 'Income Certificate',
                'document_code'    => 'INCOME_CERT',
                'is_mandatory'     => 0,
                'accepted_formats' => 'pdf,jpg,png',
                'max_size_kb'      => 5120,
                'sort_order'       => 8,
            ],
        ];

        foreach ($documents as $doc) {
            DB::table('adm_document_checklist')->upsert(
                [
                    'admission_cycle_id' => null,          // Global template
                    'class_id'           => null,          // Applies to all classes
                    'document_name'      => $doc['document_name'],
                    'document_code'      => $doc['document_code'],
                    'is_mandatory'       => $doc['is_mandatory'],
                    'is_system'          => 1,             // Seeded template — cannot be deleted by admin
                    'accepted_formats'   => $doc['accepted_formats'],
                    'max_size_kb'        => $doc['max_size_kb'],
                    'sort_order'         => $doc['sort_order'],
                    'is_active'          => 1,
                    'created_by'         => 1,
                    'updated_by'         => 1,
                    'created_at'         => $now,
                    'updated_at'         => $now,
                ],
                ['document_code'],                         // Unique key for upsert
                [                                          // Columns to update on duplicate
                    'document_name',
                    'is_mandatory',
                    'accepted_formats',
                    'max_size_kb',
                    'sort_order',
                    'updated_at',
                ]
            );
        }

        $this->command->info('AdmissionDocumentChecklistSeeder: 8 global template documents seeded.');
    }
}

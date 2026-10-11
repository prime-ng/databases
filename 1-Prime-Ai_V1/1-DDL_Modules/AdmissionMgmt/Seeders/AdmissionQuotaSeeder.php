<?php

namespace Modules\Admission\Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * Informational reference seeder for the 8 admission quota types.
 *
 * There is no standalone quota_types table — quota_type is an ENUM on
 * adm_quota_config and adm_seat_capacity. This seeder outputs the
 * quota type definitions as CLI reference for admins configuring
 * their first admission cycle.
 *
 * To configure quota seats for a cycle, use:
 *   AdmissionCycle → Seat Configuration → Add Quota
 * which inserts rows into adm_quota_config and adm_seat_capacity.
 */
class AdmissionQuotaSeeder extends Seeder
{
    /**
     * The 8 admission quota types with policy descriptions.
     * Referenced by: adm_quota_config.quota_type, adm_seat_capacity.quota_type,
     *                adm_merit_lists.quota_type, adm_applications.quota_type
     */
    public const QUOTA_TYPES = [
        'General' => [
            'label'       => 'General',
            'description' => 'Open merit seats — no reserved allocation; largest quota in most schools.',
            'fee_waiver'  => false,
            'regulated'   => false,
        ],
        'Government' => [
            'label'       => 'Government',
            'description' => 'Seats allocated as per state government directives (varies by state policy).',
            'fee_waiver'  => false,
            'regulated'   => true,
        ],
        'Management' => [
            'label'       => 'Management',
            'description' => 'School management discretionary seats; full fee applicable.',
            'fee_waiver'  => false,
            'regulated'   => false,
        ],
        'RTE' => [
            'label'       => 'Right to Education (RTE)',
            'description' => '25% mandatory seats for EWS/disadvantaged children per RTE Act 2009; zero fee.',
            'fee_waiver'  => true,
            'regulated'   => true,
        ],
        'NRI' => [
            'label'       => 'NRI / Foreign National',
            'description' => 'Seats reserved for children of NRI or foreign national parents; higher fee band.',
            'fee_waiver'  => false,
            'regulated'   => false,
        ],
        'Staff_Ward' => [
            'label'       => 'Staff Ward',
            'description' => 'Reserved for children of current school staff; typically fee concession applies.',
            'fee_waiver'  => false,
            'regulated'   => false,
        ],
        'Sibling' => [
            'label'       => 'Sibling',
            'description' => 'Priority seats for siblings of currently enrolled students; merit bonus +5 (configurable).',
            'fee_waiver'  => false,
            'regulated'   => false,
        ],
        'EWS' => [
            'label'       => 'Economically Weaker Section (EWS)',
            'description' => 'Income-based reserved seats; income certificate required; partial or full fee waiver.',
            'fee_waiver'  => true,
            'regulated'   => true,
        ],
    ];

    public function run(): void
    {
        $this->command->info('');
        $this->command->info('=== ADM Quota Types Reference ===');
        $this->command->info('quota_type ENUM is used in: adm_quota_config, adm_seat_capacity, adm_merit_lists, adm_applications');
        $this->command->info('');

        $headers = ['Quota Type', 'Label', 'Fee Waiver', 'Regulated', 'Description'];
        $rows = [];

        foreach (self::QUOTA_TYPES as $key => $quota) {
            $rows[] = [
                $key,
                $quota['label'],
                $quota['fee_waiver'] ? 'Yes' : 'No',
                $quota['regulated'] ? 'Yes (statutory)' : 'No',
                $quota['description'],
            ];
        }

        $this->command->table($headers, $rows);
        $this->command->info('');
        $this->command->info('To configure seats: Admin → Admission → Cycle Setup → Seat Configuration');
        $this->command->info('AdmissionQuotaSeeder: 8 quota types documented (no DB inserts — ENUM-based).');
    }
}

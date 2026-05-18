<?php

namespace Modules\HrStaff\Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * HrsSeederRunner — Master seeder for HrStaff module.
 *
 * Execution order is dependency-safe:
 *   1. HrsLeaveTypeSeeder         → hrs_leave_types (7 leave types)
 *   2. HrsLeavePolicySeeder       → hrs_leave_policies (1 global default)
 *   3. HrsPtSlabSeeder            → hrs_pt_slabs (7 slabs: HP×2, KA×2, MH×3)
 *   4. HrsIdCardTemplateSeeder    → hrs_id_card_templates (1 default template)
 *   5. PaySalaryComponentSeeder   → pay_salary_components (14 standard components)
 *   6. PaySalaryStructureSeeder   → pay_salary_structures + pay_salary_structure_components
 *                                   (3 structures with junction records)
 *
 * Usage:
 *   php artisan module:seed HrStaff
 *   -- or --
 *   php artisan db:seed --class="Modules\HrStaff\Database\Seeders\HrsSeederRunner"
 */
class HrsSeederRunner extends Seeder
{
    public function run(): void
    {
        $this->call([
            HrsLeaveTypeSeeder::class,
            HrsLeavePolicySeeder::class,
            HrsPtSlabSeeder::class,
            HrsIdCardTemplateSeeder::class,
            PaySalaryComponentSeeder::class,
            PaySalaryStructureSeeder::class,
        ]);
    }
}

<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Modules\GlobalMaster\Models\Module;
use Modules\SystemConfig\Models\Menu;

class ModuleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        /**
         * ---------------------------------------------------------
         * 1️⃣ MODULE DEFINITIONS
         * ---------------------------------------------------------
         */
        $modules = [
            [
                'parent_id' => null,
                'name' => 'STUDENT',
                'version' => 1,
                'is_sub_module' => false,
                'description' => 'Student information management module',
                'is_core' => true,
                'default_visible' => true,
                'available_perm_view' => true,
                'available_perm_add' => true,
                'available_perm_edit' => true,
                'available_perm_delete' => true,
                'available_perm_export' => true,
                'available_perm_import' => true,
                'available_perm_print' => true,
                'is_active' => true,
            ],
            [
                'parent_id' => null,
                'name' => 'FINANCE',
                'version' => 1,
                'is_sub_module' => false,
                'description' => 'Finance and accounting module',
                'is_core' => true,
                'default_visible' => true,
                'available_perm_view' => true,
                'available_perm_add' => true,
                'available_perm_edit' => true,
                'available_perm_delete' => true,
                'available_perm_export' => true,
                'available_perm_import' => false,
                'available_perm_print' => true,
                'is_active' => true,
            ],
            [
                'parent_id' => null,
                'name' => 'LIBRARY',
                'version' => 1,
                'is_sub_module' => false,
                'description' => 'Library management and book tracking',
                'is_core' => false,
                'default_visible' => true,
                'available_perm_view' => true,
                'available_perm_add' => true,
                'available_perm_edit' => false,
                'available_perm_delete' => false,
                'available_perm_export' => true,
                'available_perm_import' => false,
                'available_perm_print' => true,
                'is_active' => true,
            ],
            [
                'parent_id' => null,
                'name' => 'ATTENDANCE',
                'version' => 1,
                'is_sub_module' => false,
                'description' => 'Attendance tracking for students and staff',
                'is_core' => true,
                'default_visible' => true,
                'available_perm_view' => true,
                'available_perm_add' => true,
                'available_perm_edit' => true,
                'available_perm_delete' => false,
                'available_perm_export' => true,
                'available_perm_import' => true,
                'available_perm_print' => true,
                'is_active' => true,
            ],
            [
                'parent_id' => null,
                'name' => 'EXAMS',
                'version' => 1,
                'is_sub_module' => false,
                'description' => 'Examination scheduling and results module',
                'is_core' => true,
                'default_visible' => false,
                'available_perm_view' => true,
                'available_perm_add' => true,
                'available_perm_edit' => true,
                'available_perm_delete' => true,
                'available_perm_export' => true,
                'available_perm_import' => true,
                'available_perm_print' => true,
                'is_active' => true,
            ],
        ];

        /**
         * ---------------------------------------------------------
         * 2️⃣ CREATE / UPDATE MODULES
         * ---------------------------------------------------------
         */
        foreach ($modules as $moduleData) {
            Module::updateOrCreate(
                [
                    'parent_id' => $moduleData['parent_id'],
                    'name' => $moduleData['name'],
                    'version' => $moduleData['version'],
                ],
                $moduleData
            );
        }

        /**
         * ---------------------------------------------------------
         * 3️⃣ ASSIGN MENUS TO MODULES (Many-to-Many)
         * ---------------------------------------------------------
         */

        // Fetch all active tenant menus
        $menus = Menu::where('menu_for', 'tenant')
            ->where('is_active', true)
            ->whereNotNull('parent_id')
            ->get();


        if ($menus->count() < 3) {
            $this->command->warn('⚠️ Not enough menus to assign to modules.');
            return;
        }

        Module::where('is_active', true)->each(function ($module) use ($menus) {

            // Pick at least 3 random menus
            $selectedMenus = $menus->random(
                min(3, $menus->count())
            );

            $pivotData = [];

            foreach ($selectedMenus as $index => $menu) {
                $pivotData[$menu->id] = [
                    'sort_order' => $index + 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            // Attach menus without removing existing ones
            $module->menus()->syncWithoutDetaching($pivotData);

            $this->command->info(
                "🔗 Assigned {$selectedMenus->count()} menus to module: {$module->name}"
            );
        });

        $this->command->info('🎉 Module ↔ Menu mapping completed.');
    }
}

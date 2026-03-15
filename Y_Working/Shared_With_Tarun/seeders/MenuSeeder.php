<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use Modules\SystemConfig\Models\Menu;

class MenuSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {

        $menus = [

            // 1. Core Configuration (category)
            [
                'code' => Str::slug('Core configuration', '_'),
                'title' => 'Core configuration',
                'slug' => Str::slug('Core configuration'),
                'description' => 'Core system configuration and management',
                'menu_for' => 'prime',
                'icon' => 'fa-solid fa-cog',
                'is_category' => true,
                'parent_id' => null,
                'sort_order' => 1,
                'visible_by_default' => true,
                'permission' => 'prime.setting.viewAny',
                'route' => 'central-127.0.0.1.dashboard.core-configuration',
                'is_active' => true,
                'children' => [
                    // Menu Mgmt.
                    [
                        'code' => Str::slug('Menu Mgmt.', '_'),
                        'title' => 'Menu Mgmt.',
                        'slug' => Str::slug('Menu Mgmt.'),
                        'description' => 'Create & Manage Menu Items',
                        'menu_for' => 'prime',
                        'icon' => 'fa-solid fa-bars',
                        'is_category' => false,
                        'parent_id' => null,
                        'sort_order' => 1,
                        'route' => 'central-127.0.0.1.system-config.menu.index',
                        'visible_by_default' => true,
                        'permission' => 'prime.menu.viewAny',
                        'is_active' => true,
                    ],

                    // System Config
                    [
                        'code' => Str::slug('System Config', '_'),
                        'title' => 'System Config',
                        'slug' => Str::slug('System Config'),
                        'description' => 'Global system settings and preferences',
                        'menu_for' => 'prime',
                        'icon' => 'fa-solid fa-sliders',
                        'is_category' => false,
                        'parent_id' => null,
                        'sort_order' => 2,
                        'route' => 'central-127.0.0.1.system-config.setting.index',
                        'visible_by_default' => true,
                        'permission' => 'prime.setting.viewAny',
                        'is_active' => true,
                    ],

                    // Dropdown Menus
                    [
                        'code' => Str::slug('Dropdown Menus', '_'),
                        'title' => 'Dropdown Menus',
                        'slug' => Str::slug('Dropdown Menus'),
                        'description' => 'Manage reusable dropdown lists',
                        'menu_for' => 'prime',
                        'icon' => 'fa-solid fa-list',
                        'is_category' => false,
                        'parent_id' => null,
                        'sort_order' => 3,
                        'route' => 'central-127.0.0.1.global-master.dropdown.index',
                        'visible_by_default' => true,
                        'permission' => 'prime.dropdown.viewAny',
                        'is_active' => true,
                    ],

                    // View Activities
                    [
                        'code' => Str::slug('View Activities', '_'),
                        'title' => 'View Activities',
                        'slug' => Str::slug('View Activities'),
                        'description' => 'Audit logs and activity viewer',
                        'menu_for' => 'prime',
                        'icon' => 'fa-solid fa-eye',
                        'is_category' => false,
                        'parent_id' => null,
                        'sort_order' => 4,
                        'route' => 'central-127.0.0.1.global-master.activity-log.index',
                        'visible_by_default' => true,
                        'permission' => 'prime.activity-log.viewAny',
                        'is_active' => true,
                    ],

                    // Language Mgmt.
                    [
                        'code' => Str::slug('Language Mgmt.', '_'),
                        'title' => 'Language Mgmt.',
                        'slug' => Str::slug('Language Mgmt.'),
                        'description' => 'Manage translations and locales',
                        'menu_for' => 'prime',
                        'icon' => 'fa-solid fa-language',
                        'is_category' => false,
                        'parent_id' => null,
                        'sort_order' => 5,
                        'route' => 'central-127.0.0.1.global-master.language.index',
                        'visible_by_default' => true,
                        'permission' => 'prime.language.viewAny',
                        'is_active' => true,
                    ],

                    // Location Mgmt (moved under Core configuration)
                    [
                        'code' => Str::slug('Location Mgmt', '_'),
                        'title' => 'Location Mgmt',
                        'slug' => Str::slug('Location Mgmt'),
                        'description' => 'Manage locations, regions and zones',
                        'menu_for' => 'prime',
                        'icon' => 'fa-solid fa-location-dot',
                        'is_category' => false,
                        'parent_id' => null,
                        'sort_order' => 6,
                        'route' => 'central-127.0.0.1.global-master.location-setup.index',
                        'visible_by_default' => true,
                        'permission' => 'prime.country.viewAny',
                        'is_active' => true,
                    ],
                ],
            ],
            // end::Core Configuration


            // 2. Foundational Setup (category)
            [
                'code' => Str::slug('Foundational Setup', '_'),
                'title' => 'Foundational Setup',
                'slug' => Str::slug('Foundational Setup'),
                'description' => 'Base entities and role/session/module setup',
                'menu_for' => 'prime',
                'icon' => 'fa-solid fa-layer-group',
                'is_category' => true,
                'parent_id' => null,
                'sort_order' => 2,
                'visible_by_default' => true,
                'route' => 'central-127.0.0.1.dashboard.foundational-setup',
                'permission' => 'prime.role-permission.viewAny',
                'is_active' => true,
                'children' => [

                    // Roles & Permission (Prime)
                    [
                        'code' => Str::slug('Roles & Permission', '_'),
                        'title' => 'Roles & Permission',
                        'slug' => Str::slug('Roles & Permission'),
                        'description' => 'Manage roles, permissions and assignments',
                        'menu_for' => 'prime',
                        'icon' => 'fa-solid fa-user-shield',
                        'is_category' => false,
                        'parent_id' => null,
                        'sort_order' => 1,
                        'route' => 'central-127.0.0.1.prime.user-role-prm.index',
                        'visible_by_default' => true,
                        'permission' => 'prime.role-permission.viewAny',
                        'is_active' => true,
                    ],

                    // Session & Board Setup
                    [
                        'code' => Str::slug('Session & Board Setup', '_'),
                        'title' => 'Session & Board Setup',
                        'slug' => Str::slug('Session & Board Setup'),
                        'description' => 'Configure academic/business sessions and boards',
                        'menu_for' => 'prime',
                        'icon' => 'fa-solid fa-calendar-check',
                        'is_category' => false,
                        'parent_id' => null,
                        'sort_order' => 2,
                        'route' => 'central-127.0.0.1.prime.session-board-setup.index',
                        'visible_by_default' => true,
                        'permission' => 'prime.academic-session.viewAny',
                        'is_active' => true,
                    ],

                    // Sales Plan & Module Mgmt.
                    [
                        'code' => Str::slug('Sales Plan & Module Mgmt', '_'),
                        'title' => 'Sales Plan & Module Mgmt.',
                        'slug' => Str::slug('Sales Plan & Module Mgmt'),
                        'description' => 'Sales plans and module configuration',
                        'menu_for' => 'prime',
                        'icon' => 'fa-solid fa-chart-line',
                        'is_category' => false,
                        'parent_id' => null,
                        'sort_order' => 3,
                        'route' => 'central-127.0.0.1.prime.sales-plan-mgmt.index',
                        'visible_by_default' => true,
                        'permission' => 'prime.billing-cycle.viewAny',
                        'is_active' => true,
                    ],
                ],
            ],
            // end::Foundational Setup


            // 3. Subscription & Billing (category)
            [
                'code' => Str::slug('Subscription & Billing', '_'),
                'title' => 'Subscription & Billing',
                'slug' => Str::slug('Subscription & Billing'),
                'description' => 'Tenant subscriptions and billing workflows',
                'menu_for' => 'prime',
                'icon' => 'fa-solid fa-file-invoice-dollar',
                'is_category' => true,
                'parent_id' => null,
                'sort_order' => 3,
                'visible_by_default' => true,
                'permission' => 'prime.tenant.viewAny',
                'route' => 'central-127.0.0.1.dashboard.subscription-billing',
                'is_active' => true,
                'children' => [
                    // Tenant & Subscription Mgmt.
                    [
                        'code' => Str::slug('Tenant & Subscription Mgmt', '_'),
                        'title' => 'Tenant & Subscription Mgmt.',
                        'slug' => Str::slug('Tenant & Subscription Mgmt'),
                        'description' => 'Manage tenants, plans and subscriptions',
                        'menu_for' => 'prime',
                        'icon' => 'fa-solid fa-building',
                        'is_category' => false,
                        'parent_id' => null,
                        'sort_order' => 1,
                        'route' => 'central-127.0.0.1.prime.tenant-management.index',
                        'visible_by_default' => true,
                        'permission' => 'prime.tenant.viewAny',
                        'is_active' => true,
                    ],

                    // Invoicing
                    [
                        'code' => Str::slug('Invoicing', '_'),
                        'title' => 'Invoicing',
                        'slug' => Str::slug('Invoicing'),
                        'description' => 'Generate and manage invoices',
                        'menu_for' => 'prime',
                        'icon' => 'fa-solid fa-file-invoice',
                        'is_category' => false,
                        'parent_id' => null,
                        'sort_order' => 2,
                        'route' => 'central-127.0.0.1.billing.billing-management.index',
                        'visible_by_default' => true,
                        'permission' => '',
                        'is_active' => true,
                    ],
                ],
            ],
            // end::Subscription & Billing

        ];

        foreach ($menus as $parentData) {
            $children = $parentData['children'] ?? [];
            unset($parentData['children']);
            $parent = Menu::create(array_merge($parentData, ['parent_id' => null]));

            foreach ($children as $childData) {
                Menu::create(array_merge($childData, ['parent_id' => $parent->id]));
            }
        }
    }
}

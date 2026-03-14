<?php

namespace Database\Seeders;

use App\Helpers\PermissionHelper;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Modules\SchoolSetup\Models\Organization;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;


class RolePermissionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */

    public function run(): void
    {
        $roles = [
            [
                'name' => 'Super Admin',
                'short_name' => 'super_admin',
                'description' => 'Full system access, manages roles & permissions',
                'is_system' => 1,
            ],
            [
                'name' => 'Manager',
                'short_name' => 'manager',
                'description' => 'Oversees company operations and manages teams',
                'is_system' => 0,
            ],
            [
                'name' => 'Accounting',
                'short_name' => 'accounting',
                'description' => 'Handles company finances, bookkeeping, and accounts',
                'is_system' => 0,
            ],
            [
                'name' => 'Invoicing',
                'short_name' => 'invoicing',
                'description' => 'Manages billing, invoicing, and payment processing',
                'is_system' => 0,
            ],
            [
                'name' => 'Student',
                'short_name' => 'student',
                'description' => 'Student',
                'is_system' => 0,
            ],
            [
                'name' => 'Parent',
                'short_name' => 'parent',
                'description' => 'Parent',
                'is_system' => 0,
            ],
        ];

        // Get all permissions from config
        $permissions = PermissionHelper::flatten('prime');

        // Create permissions
        foreach ($permissions as $permission) {
            Permission::firstOrCreate(['name' => $permission]);
        }

        // Create roles and assign permissions (no organization_id)
        foreach ($roles as $roleData) {
            $role = Role::firstOrCreate(
                ['name' => $roleData['name']],
                [
                    'guard_name' => 'web',
                    'short_name' => $roleData['short_name'],
                    'description' => $roleData['description'],
                    'is_system' => $roleData['is_system'],
                ]
            );
            $role->syncPermissions($permissions);
        }
    }
}

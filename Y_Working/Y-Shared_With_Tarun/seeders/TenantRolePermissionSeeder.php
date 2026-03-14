<?php

namespace Database\Seeders;

use App\Helpers\PermissionHelper;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Modules\SchoolSetup\Models\Permission;
use Modules\SchoolSetup\Models\Role;

class TenantRolePermissionSeeder extends Seeder
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
                'name' => 'Principal',
                'short_name' => 'principal',
                'description' => 'Head of the school, oversees all operations',
                'is_system' => 0,
            ],
            [
                'name' => 'Vice Principal',
                'short_name' => 'vice_principal',
                'description' => 'Supports principal, handles academics & discipline',
                'is_system' => 0,
            ],
            [
                'name' => 'Teacher',
                'short_name' => 'teacher',
                'description' => 'Handles classroom teaching and student management',
                'is_system' => 0,
            ],
            [
                'name' => 'Staff',
                'short_name' => 'staff',
                'description' => 'General non-teaching school staff (admin, clerical, etc.)',
                'is_system' => 0,
            ],
            [
                'name' => 'Accountant',
                'short_name' => 'accountant',
                'description' => 'Handles school finances, fees, and accounts',
                'is_system' => 0,
            ],
            [
                'name' => 'Librarian',
                'short_name' => 'librarian',
                'description' => 'Manages library resources and inventory',
                'is_system' => 0,
            ],
            [
                'name' => 'Parent',
                'short_name' => 'parent',
                'description' => 'Access to ward/student data and reports',
                'is_system' => 0,
            ],
            [
                'name' => 'Student',
                'short_name' => 'student',
                'description' => 'Access to personal academic data and coursework',
                'is_system' => 0,
            ],
        ];

        // Get all permissions from config
        $permissions = PermissionHelper::flatten(role: 'tenant');

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

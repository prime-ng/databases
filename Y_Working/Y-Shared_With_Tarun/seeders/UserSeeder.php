<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Modules\SchoolSetup\Models\Organization;
use Spatie\Permission\Models\Role;


class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $usersData = [
            'Super Admin' => [
                ['name' => 'Super Admin', 'email' => 'superadmin@prime.com', 'short_name' => 'SUADM', 'is_super_admin' => true],
            ],
            'Manager' => [
                ['name' => 'Manager User', 'email' => 'manager@prime.com', 'short_name' => 'MGR']
            ],
            'Accounting' => [
                ['name' => 'Accounting User', 'email' => 'accounting@prime.com', 'short_name' => 'ACC']
            ],
            'Invoicing' => [
                ['name' => 'Invoicing User', 'email' => 'invoicing@prime.com', 'short_name' => 'INV'],
            ],
        ];

        $password = Hash::make('password');
        $superAdminCreated = false;

        foreach ($usersData as $roleName => $users) {
            $role = Role::where('name', $roleName)->first();
            if (!$role) {
                continue; // Skip if role does not exist
            }

            foreach ($users as $userData) {
                // Check if user is super admin and if it is already created
                if (($userData['is_super_admin'] ?? false) == true) {
                    if ($superAdminCreated) {
                        continue; // Skip creating more than one super admin globally
                    } else {
                        $superAdminCreated = true; // Mark super admin created
                    }
                }

                $user = User::firstOrCreate(
                    ['email' => $userData['email']],
                    [
                        'name' => $userData['name'],
                        'short_name' => $userData['short_name'] . '-' . rand(1000, 5000),
                        'password' => $password,
                        'emp_code' => rand(100, 99999),
                        'is_active' => true,
                        'is_super_admin' => $userData['is_super_admin'] ?? false,
                    ]
                );
                $user->assignRole($role);
            }
        }

    }
}

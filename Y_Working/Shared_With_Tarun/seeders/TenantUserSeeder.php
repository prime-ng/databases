<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Modules\SchoolSetup\Models\Role;

class TenantUserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $usersData = [
            'Super Admin' => [
                ['name' => 'Root User', 'email' => 'root@tenant.com', 'short_name' => 'ROOT', 'is_super_admin' => true],
            ],
            'Principal' => [
                ['name' => 'Principal User', 'email' => 'principal@tenant.com', 'short_name' => 'PRIN1'],
            ],
            'Vice Principal' => [
                ['name' => 'Vice Principal User', 'email' => 'viceprincipal@tenant.com', 'short_name' => 'VPRIN1'],
            ],
            'Head of Department' => [
                ['name' => 'Head Dept User', 'email' => 'headdpt1@tenent.com', 'short_name' => 'HOD1'],
            ],
            'Senior Teacher' => [
                ['name' => 'Senior Teacher One', 'email' => 'seniorteacher1@primeai.com', 'short_name' => 'SRTEA1'],
                ['name' => 'Senior Teacher Two', 'email' => 'seniorteacher2@primeai.com', 'short_name' => 'SRTEA2'],
            ],
            'Teacher' => [
                ['name' => 'Ankit Rai', 'email' => 'ankit.rai@primeai.com', 'short_name' => 'TEA01'],
                ['name' => 'Pallavi Bhandari', 'email' => 'pallavi.bhandari@primeai.com', 'short_name' => 'TEA02'],
                ['name' => 'Vijay Pandey', 'email' => 'vijay.pandey@primeai.com', 'short_name' => 'TEA03'],
                ['name' => 'Pooja Joshi', 'email' => 'pooja.joshi@primeai.com', 'short_name' => 'TEA04'],
                ['name' => 'Geetika Oli', 'email' => 'geetika.oli@primeai.com', 'short_name' => 'TEA05'],
                // ['name' => 'Astropathshala', 'email' => 'astropathshala@primeai.com', 'short_name' => 'TEA06'],
                // ['name' => 'Ankita Chaudhary', 'email' => 'ankita.chaudhary@primeai.com', 'short_name' => 'TEA07'],
                // ['name' => 'Ayushi Kanwal', 'email' => 'ayushi.kanwal@primeai.com', 'short_name' => 'TEA08'],
                // ['name' => 'Gaurav Kumar', 'email' => 'gaurav.kumar@primeai.com', 'short_name' => 'TEA09'],
                // ['name' => 'Urmil Joshi', 'email' => 'urmil.joshi@primeai.com', 'short_name' => 'TEA10'],

                // ['name' => 'Radha Bhatt', 'email' => 'radha.bhatt@primeai.com', 'short_name' => 'TEA11'],
                // ['name' => 'Priyanka Agarwal Mittal', 'email' => 'priyanka.mittal@primeai.com', 'short_name' => 'TEA12'],
                // ['name' => 'Meenu Amit Maurya', 'email' => 'meenu.maurya@primeai.com', 'short_name' => 'TEA13'],
                // ['name' => 'Robin Kumar Arya', 'email' => 'robin.arya@primeai.com', 'short_name' => 'TEA14'],
                // ['name' => 'Smita Sah', 'email' => 'smita.sah@primeai.com', 'short_name' => 'TEA15'],

                // ['name' => 'Ankit Pathak', 'email' => 'ankit.pathak@primeai.com', 'short_name' => 'TEA16'],
                // ['name' => 'Bhawana Kafaltiya', 'email' => 'bhawana.kafaltiya@primeai.com', 'short_name' => 'TEA17'],
                // ['name' => 'Aman Chaurasiya', 'email' => 'aman.chaurasiya@primeai.com', 'short_name' => 'TEA18'],
                // ['name' => 'Manorma Tewari', 'email' => 'manorma.tewari@primeai.com', 'short_name' => 'TEA19'],
                // ['name' => 'Sangeeta Kholia', 'email' => 'sangeeta.kholia@primeai.com', 'short_name' => 'TEA20'],

                // ['name' => 'Neeru Joshi Goel', 'email' => 'neeru.goel@primeai.com', 'short_name' => 'TEA21'],
                // ['name' => 'Santosh Gaurav Rawat', 'email' => 'santosh.rawat@primeai.com', 'short_name' => 'TEA22'],
                // ['name' => 'Parul Agarwal', 'email' => 'parul.agarwal@primeai.com', 'short_name' => 'TEA23'],
                // ['name' => 'Neetu Tiwari', 'email' => 'neetu.tiwari@primeai.com', 'short_name' => 'TEA24'],
                // ['name' => 'Pragati Bisht', 'email' => 'pragati.bisht@primeai.com', 'short_name' => 'TEA25'],

                // ['name' => 'Radha Pilkhwal', 'email' => 'radha.pilkhwal@primeai.com', 'short_name' => 'TEA26'],
                // ['name' => 'Shilpi Negi', 'email' => 'shilpi.negi@primeai.com', 'short_name' => 'TEA27'],
            ],
            'Staff Clerk' => [
                ['name' => 'Staff Clerk One', 'email' => 'staffclerk1@primeai.com', 'short_name' => 'SCLK1'],
                ['name' => 'Staff Clerk Two', 'email' => 'staffclerk2@primeai.com', 'short_name' => 'SCLK2'],
            ],
            'Librarian' => [
                ['name' => 'Librarian One', 'email' => 'librarian1@primeai.com', 'short_name' => 'LIB1'],
                ['name' => 'Librarian Two', 'email' => 'librarian2@primeai.com', 'short_name' => 'LIB2'],
            ],
            'Accountant' => [
                ['name' => 'Accountant One', 'email' => 'accountant1@primeai.com', 'short_name' => 'ACC1'],
                ['name' => 'Accountant Two', 'email' => 'accountant2@primeai.com', 'short_name' => 'ACC2'],
            ],
            'Receptionist' => [
                ['name' => 'Receptionist One', 'email' => 'receptionist1@primeai.com', 'short_name' => 'RECP1'],
                ['name' => 'Receptionist Two', 'email' => 'receptionist2@primeai.com', 'short_name' => 'RECP2'],
            ],
            // 'Student' => [
            //     ['name' => 'Student One', 'email' => 'student1@primeai.com', 'short_name' => 'STDNT1'],
            //     ['name' => 'Student Two', 'email' => 'student2@primeai.com', 'short_name' => 'STDNT2'],
            // ],
            'Parent' => [
                ['name' => 'Parent One', 'email' => 'parent1@primeai.com', 'short_name' => 'PRNT1'],
                ['name' => 'Parent Two', 'email' => 'parent2@primeai.com', 'short_name' => 'PRNT2'],
            ]
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
                        'emp_code' => rand(100, 99999),
                        'password' => $password,
                        'is_active' => true,
                        'is_super_admin' => $userData['is_super_admin'] ?? false,
                    ]
                );
                $user->assignRole($role);
            }
        }
        // $teacherRole = Role::where('name', 'Teacher')->first();

        // if ($teacherRole) {

        //     $existingTeacherCount = User::role('Teacher')->count();

        //     $targetTeacherCount = 300;
        //     $toCreate = max(0, $targetTeacherCount - $existingTeacherCount);

        //     for ($i = 1; $i <= $toCreate; $i++) {

        //         $index = $existingTeacherCount + $i;

        //         $email = "teacher{$index}@primeai.com";

        //         User::firstOrCreate(
        //             ['email' => $email],
        //             [
        //                 'name' => "Teacher {$index}",
        //                 'short_name' => 'TEA' . str_pad($index, 3, '0', STR_PAD_LEFT),
        //                 'emp_code' => 100000 + $index,
        //                 'password' => $password,
        //                 'is_active' => true,
        //                 'is_super_admin' => false,
        //             ]
        //         )->assignRole($teacherRole);
        //     }
        // }
    }
}

<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Faker\Factory as Faker;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Modules\SchoolSetup\Models\ClassSection;
use Modules\SchoolSetup\Models\Role;
use Modules\SchoolSetup\Models\SchoolClass;
use Modules\SchoolSetup\Models\Section;
use Modules\StudentProfile\Models\Student;
use Modules\StudentProfile\Models\StudentDetail;

class StudentSeeder extends Seeder
{
    private $faker;
    private $studentsPerClassSection = [];

    public function __construct()
    {
        $this->faker = Faker::create('en_IN');
    }

    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // First, create class-section entries if they don't exist
        $this->createClassSectionEntries();

        // Check if students already exist
        if (Student::count() > 0) {
            $this->command->info('Students already exist. Skipping StudentSeeder.');
            return;
        }

        // Get active classes and sections
        $classSections = $this->getClassSections();

        if (empty($classSections)) {
            $this->command->error('No active classes and sections found. Please run ClassSeeder first.');
            return;
        }

        $totalStudents = 0;
        $now = now();

        foreach ($classSections as $classId => $classInfo) {
            $className = $classInfo['name'];
            $classCode = $classInfo['code'];

            foreach ($classInfo['sections'] as $sectionId => $sectionName) {
                // Generate 30-35 students per class-section
                $numStudents = rand(30, 35);
                $this->studentsPerClassSection["{$classId}_{$sectionId}"] = $numStudents;

                $this->command->info("Generating {$numStudents} students for {$className} - {$sectionName}");

                for ($i = 1; $i <= $numStudents; $i++) {
                    try {
                        // Create user first
                        $user = $this->createUser($classCode, $sectionName, $i);

                        // Create student record
                        $student = $this->createStudent($user, $classId, $sectionId, $now);

                        // Create student details
                        $this->createStudentDetails($student, $user, $classId, $sectionId);

                        $totalStudents++;

                    } catch (\Exception $e) {
                        $this->command->error("Failed to create student {$i} for {$className}-{$sectionName}: " . $e->getMessage());
                        continue;
                    }
                }

                $this->command->info("✅ Created {$numStudents} students for {$className} - {$sectionName}");

                // Update the class_section table with student count
                $this->updateClassSectionStudentCount($classId, $sectionId, $numStudents);
            }
        }

        $this->command->info("🎉 Successfully created {$totalStudents} students across all classes.");
    }

    /**
     * Create class-section entries if they don't exist
     */
    private function createClassSectionEntries(): void
    {
        // Check if class-section entries already exist
        if (ClassSection::count() > 0) {
            $this->command->info('Class-section entries already exist. Skipping creation.');
            return;
        }

        $this->command->info('Creating class-section entries...');

        // Get all active classes
        $classes = SchoolClass::where('is_active', true)->get();

        // Get all active sections
        $sections = Section::where('is_active', true)->get();

        if ($classes->isEmpty() || $sections->isEmpty()) {
            $this->command->warn('Cannot create class-section entries. Classes or sections not found.');
            return;
        }

        // Get teachers for assignment
        $teachers = User::whereHas('roles', function ($query) {
            $query->whereIn('name', ['Teacher', 'Senior Teacher']);
        })->where('is_active', true)->get();

        $records = [];
        $now = now();
        $counter = 0;
        $teacherIndex = 0;
        $teacherCount = $teachers->count();

        // Create ALL combinations: every class × every section
        foreach ($classes as $class) {
            foreach ($sections as $section) {
                // Assign teachers if available
                $classTeacherId = null;
                $assistantTeacherId = null;

                if ($teacherCount > 0) {
                    $classTeacherId = $teachers[$teacherIndex % $teacherCount]->id;
                    $teacherIndex++;

                    if ($teacherCount > 1) {
                        $assistantTeacherId = $teachers[$teacherIndex % $teacherCount]->id;
                        $teacherIndex++;
                    }
                }

                // Determine capacity based on class level
                $capacity = $this->getClassCapacity($class->code);

                $records[] = [
                    'class_id' => $class->id,
                    'section_id' => $section->id,
                    'class_section_code' => "{$class->code}-{$section->code}",
                    'capacity' => $capacity,
                    'total_student' => 0, // Start with 0, will be updated later
                    'class_teacher_id' => $classTeacherId,
                    'assistance_class_teacher_id' => $assistantTeacherId,
                    'is_active' => true,
                    'created_at' => $now,
                    'updated_at' => $now,
                ];

                $counter++;

                if ($counter % 10 === 0) {
                    $this->command->info("Created {$counter} class-section entries...");
                }
            }
        }

        // Insert in batches
        foreach (array_chunk($records, 50) as $batch) {
            ClassSection::insert($batch);
        }

        $this->command->info("✅ Created {$counter} class-section entries.");
    }

    /**
     * Update class_section table with actual student count
     */
    private function updateClassSectionStudentCount(int $classId, int $sectionId, int $studentCount): void
    {
        try {
            $classSection = ClassSection::where('class_id', $classId)
                ->where('section_id', $sectionId)
                ->first();

            if ($classSection) {
                $classSection->total_student = $studentCount;
                $classSection->save();
            }
        } catch (\Exception $e) {
            $this->command->warn("Failed to update class-section student count: " . $e->getMessage());
        }
    }

    /**
     * Get all active classes with their sections
     */
    private function getClassSections(): array
    {
        // First, try to get from existing class_section table
        $existingClassSections = ClassSection::with(['class', 'section'])
            ->where('is_active', true)
            ->get();

        if ($existingClassSections->count() > 0) {
            $this->command->info('Using existing class-section entries...');

            $classSections = [];
            foreach ($existingClassSections as $cs) {
                if (!$cs->class || !$cs->section) {
                    continue;
                }

                $classId = $cs->class_id;
                $sectionId = $cs->section_id;

                if (!isset($classSections[$classId])) {
                    $classSections[$classId] = [
                        'id' => $classId,
                        'name' => $cs->class->name,
                        'code' => $cs->class->code,
                        'short_name' => $cs->class->short_name,
                        'sections' => []
                    ];
                }

                $classSections[$classId]['sections'][$sectionId] = $cs->section->name;
            }

            return $classSections;
        }

        // Fallback: Get from classes and sections tables
        $this->command->info('No existing class-section entries, creating student distribution...');

        $classes = SchoolClass::where('is_active', true)
            ->get(['id', 'name', 'code', 'short_name']);

        $sections = Section::where('is_active', true)
            ->pluck('name', 'id');

        $classSections = [];

        foreach ($classes as $class) {
            // Get 1-3 random sections for each class
            $sectionIds = $sections->keys()->shuffle()->take(rand(1, min(3, $sections->count())));

            foreach ($sectionIds as $sectionId) {
                $classSections[$class->id] = [
                    'id' => $class->id,
                    'name' => $class->name,
                    'code' => $class->code,
                    'short_name' => $class->short_name,
                    'sections' => $sectionIds->mapWithKeys(function ($id) use ($sections) {
                        return [$id => $sections[$id]];
                    })->toArray()
                ];
                break; // Only take one section combination per class
            }
        }

        return $classSections;
    }

    /**
     * Create user account for student
     */
    private function createUser(string $classCode, string $sectionName, int $studentNumber): User
    {
        $firstName = $this->faker->firstName();
        $lastName = $this->faker->lastName();
        $email = strtolower("{$firstName}.{$lastName}.{$classCode}{$studentNumber}@school.edu");

        // Remove spaces and special characters from email
        $email = preg_replace('/[^a-zA-Z0-9@.]/', '', $email);

        // Ensure email is unique
        $baseEmail = $email;
        $counter = 1;
        while (User::where('email', $email)->exists()) {
            $email = str_replace("@school.edu", "{$counter}@school.edu", $baseEmail);
            $counter++;
        }

        $userData = [
            'name' => "{$firstName} {$lastName}",
            'short_name' => strtoupper(substr($firstName, 0, 3) . substr($lastName, 0, 2) . $studentNumber),
            'emp_code' => "STD" . str_pad($studentNumber, 4, '0', STR_PAD_LEFT),
            'email' => $email,
            'password' => Hash::make('student123'),
            'is_active' => true,
            'is_super_admin' => false,
            'email_verified_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ];

        $user = User::create($userData);

        // Assign Student role
        $studentRole = Role::where('name', 'Student')->first();
        if ($studentRole) {
            $user->assignRole($studentRole);
        }

        return $user;
    }

    /**
     * Create student record
     */
    private function createStudent(User $user, int $classId, int $sectionId, $now): Student
    {
        $admissionYear = date('Y');
        $admissionNo = "ADM{$admissionYear}" . str_pad($user->id, 6, '0', STR_PAD_LEFT);

        $firstName = explode(' ', $user->name)[0];
        $lastName = count(explode(' ', $user->name)) > 1 ? explode(' ', $user->name)[1] : $this->faker->lastName();

        // Random gender
        $genders = ['Male', 'Female'];
        $gender = $genders[array_rand($genders)];

        // Generate random date of birth (5-17 years old)
        $dob = $this->faker->dateTimeBetween('-17 years', '-5 years')->format('Y-m-d');

        // Admission date (1-2 years before current date)
        $admissionDate = $this->faker->dateTimeBetween('-2 years', '-1 year')->format('Y-m-d');

        // Generate Aadhar ID (12 digits)
        $aadharId = $this->generateAadharId();

        $studentData = [
            'user_id' => $user->id,
            'admission_no' => $admissionNo,
            'admission_date' => $admissionDate,
            'student_qr_code' => 'QR' . strtoupper(uniqid()),
            'student_id_card_type' => 'QR',
            'smart_card_id' => 'SC' . strtoupper(uniqid()),
            'aadhar_id' => $aadharId,
            'apaar_id' => 'APAAR' . strtoupper(uniqid()),
            'birth_cert_no' => 'BC' . date('Y') . str_pad(rand(1, 99999), 5, '0', STR_PAD_LEFT),
            'first_name' => $firstName,
            'middle_name' => $this->faker->boolean(30) ? $this->faker->firstName() : null,
            'last_name' => $lastName,
            'gender' => $gender,
            'dob' => $dob,
            'photo_file_name' => null,
            'media_id' => null,
            'current_status_id' => 1,
            'is_active' => true,
            'note' => 'Generated by seeder',
            'created_at' => $now,
            'updated_at' => $now,
        ];

        return Student::create($studentData);
    }

    /**
     * Create student details
     */
    private function createStudentDetails(Student $student, User $user, int $classId, int $sectionId): void
    {
        $mobile = $this->generateIndianMobileNumber();

        // Get random city from global database
        $city = DB::connection('global_master_mysql')
            ->table('glb_cities')
            ->inRandomOrder()
            ->first(['id', 'name']);

        $cityId = $city->id ?? 1;

        // Parse student name
        $nameParts = explode(' ', $student->first_name . ' ' . $student->middle_name . ' ' . $student->last_name);
        $firstName = $nameParts[0];
        $fatherName = $this->faker->firstNameMale() . ' ' . $this->faker->lastName();
        $motherName = $this->faker->firstNameFemale() . ' ' . $this->faker->lastName();

        // Height and weight based on age
        $age = date_diff(date_create($student->dob), date_create())->y;
        $height = $this->calculateHeight($age, $student->gender);
        $weight = $this->calculateWeight($age, $student->gender);

        $studentDetails = [
            'student_id' => $student->id,
            'mobile' => $mobile,
            'email' => $user->email,
            'student_address' => $this->faker->address(),
            'city_id' => $cityId,
            'pin' => $this->faker->postcode(),
            'religion' => $this->getRandomReligion(),
            'cast' => $this->getRandomCast(),
            'dob' => $student->dob,
            'current_address' => $this->faker->address(),
            'permanent_address' => $this->faker->address(),
            'student_photo' => null,
            'right_to_edu' => $this->faker->boolean(80),
            'bank_account_no' => $this->generateBankAccount(),
            'bank_name' => $this->getRandomBank(),
            'ifsc_code' => $this->generateIFSC(),
            'upi_id' => strtolower($firstName) . rand(100, 999) . '@upi',
            'father_name' => $fatherName,
            'father_phone' => $this->generateIndianMobileNumber(),
            'father_occupation' => $this->getRandomOccupation(),
            'father_email' => strtolower(str_replace(' ', '.', $fatherName)) . '@email.com',
            'mother_name' => $motherName,
            'mother_phone' => $this->generateIndianMobileNumber(),
            'mother_occupation' => $this->getRandomOccupation(),
            'mother_email' => strtolower(str_replace(' ', '.', $motherName)) . '@email.com',
            'guardian_is' => $this->faker->randomElement(['Father', 'Mother', 'Grandfather', 'Grandmother', 'Uncle', 'Aunt']),
            'guardian_name' => $this->faker->name(),
            'guardian_relation' => $this->faker->randomElement(['Father', 'Mother', 'Grandparent', 'Uncle', 'Aunt']),
            'guardian_phone' => $this->generateIndianMobileNumber(),
            'guardian_occupation' => $this->getRandomOccupation(),
            'guardian_address' => $this->faker->address(),
            'guardian_email' => $this->faker->email(),
            'previous_school_detail' => $this->faker->boolean(50) ? $this->faker->sentence() : null,
            'height' => $height,
            'weight' => $weight,
            'measurement_date' => $this->faker->dateTimeBetween('-6 months')->format('Y-m-d'),
            'extra_info' => json_encode([
                'class_id' => $classId,
                'section_id' => $sectionId,
                'blood_group' => $this->getRandomBloodGroup(),
                'allergies' => $this->faker->boolean(20) ? $this->faker->words(3, true) : null,
                'hobbies' => $this->faker->words(3, true),
                'emergency_contact' => $this->generateIndianMobileNumber(),
            ]),
            'created_at' => now(),
            'updated_at' => now(),
        ];

        StudentDetail::create($studentDetails);
    }

    /**
     * Determine capacity based on class level
     */
    private function getClassCapacity(string $classCode): int
    {
        return match ($classCode) {
            'NUR', 'LKG', 'UKG' => 25,
            '01', '02', '03' => 30,
            '04', '05' => 35,
            '06', '07', '08' => 40,
            '09', '10' => 40,
            '11', '12' => 35,
            default => 40,
        };
    }

    /**
     * Helper methods for generating Indian-specific data
     */
    private function generateAadharId(): string
    {
        $firstDigit = rand(2, 9);
        $remaining = str_pad(rand(0, 99999999999), 11, '0', STR_PAD_LEFT);
        return $firstDigit . $remaining;
    }

    private function generateIndianMobileNumber(): string
    {
        $prefixes = ['6', '7', '8', '9'];
        $prefix = $prefixes[array_rand($prefixes)];
        $number = $prefix . str_pad(rand(0, 999999999), 9, '0', STR_PAD_LEFT);
        return '+91' . $number;
    }

    private function generateBankAccount(): string
    {
        return str_pad(rand(0, 999999999999), 12, '0', STR_PAD_LEFT);
    }

    private function generateIFSC(): string
    {
        $banks = ['SBIN', 'HDFC', 'ICIC', 'AXIS', 'PNB', 'BOB', 'UBIN', 'IOBA'];
        $bank = $banks[array_rand($banks)];
        $branch = str_pad(rand(0, 999), 3, '0', STR_PAD_LEFT);
        return $bank . $branch . 'N';
    }

    private function getRandomBank(): string
    {
        $banks = [
            'State Bank of India',
            'HDFC Bank',
            'ICICI Bank',
            'Axis Bank',
            'Punjab National Bank',
            'Bank of Baroda',
            'Union Bank of India',
            'Indian Overseas Bank',
            'Canara Bank',
            'Bank of India'
        ];
        return $banks[array_rand($banks)];
    }

    private function getRandomReligion(): string
    {
        $religions = ['Hindu', 'Muslim', 'Christian', 'Sikh', 'Buddhist', 'Jain', 'Other'];
        return $religions[array_rand($religions)];
    }

    private function getRandomCast(): string
    {
        $casts = ['General', 'OBC', 'SC', 'ST', 'Other'];
        return $casts[array_rand($casts)];
    }

    private function getRandomOccupation(): string
    {
        $occupations = [
            'Farmer',
            'Teacher',
            'Engineer',
            'Doctor',
            'Business',
            'Government Employee',
            'Private Employee',
            'Lawyer',
            'Accountant',
            'Shopkeeper',
            'Driver',
            'Housewife'
        ];
        return $occupations[array_rand($occupations)];
    }

    private function getRandomBloodGroup(): string
    {
        $bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
        return $bloodGroups[array_rand($bloodGroups)];
    }

    private function calculateHeight(int $age, string $gender): string
    {
        if ($age <= 5) {
            $height = rand(80, 110);
        } elseif ($age <= 10) {
            $height = rand(120, 145);
        } elseif ($age <= 15) {
            $height = $gender === 'Male' ? rand(150, 170) : rand(145, 165);
        } else {
            $height = $gender === 'Male' ? rand(165, 185) : rand(155, 175);
        }
        return "{$height} cm";
    }

    private function calculateWeight(int $age, string $gender): string
    {
        if ($age <= 5) {
            $weight = rand(12, 20);
        } elseif ($age <= 10) {
            $weight = rand(22, 40);
        } elseif ($age <= 15) {
            $weight = $gender === 'Male' ? rand(42, 60) : rand(40, 55);
        } else {
            $weight = $gender === 'Male' ? rand(55, 75) : rand(45, 65);
        }
        return "{$weight} kg";
    }
}

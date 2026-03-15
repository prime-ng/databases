<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Modules\GlobalMaster\Database\Seeders\DropdownSeeder;
use Modules\SchoolSetup\Database\Seeders\BuildingSeeder;
use Modules\SchoolSetup\Database\Seeders\ClassSectionSeeder;
use Modules\SchoolSetup\Database\Seeders\SectionSeeder;
use Modules\SchoolSetup\Database\Seeders\StudyFormatSeeder;
use Modules\SystemConfig\Database\Seeders\SettingSeeder;

class TenantDatabaseSeeder extends Seeder
{
    /**
     * 
     * Tenant Seeder 
     * This seeder will sun when we create a new tenant.
     * 
     */
    public function run(): void
    {
        $this->call([
                //TenantMenuSeeder::class,
            TenantRolePermissionSeeder::class,
            TenantUserSeeder::class,
            DropdownSeeder::class,
            SettingSeeder::class,
            ComplaintCategorySeeder::class,
            SchoolDaySeeder::class,
            RoomTypeSeeder::class,
            BuildingSeeder::class,
            DayTypeSeeder::class,
            PeriodTypeSeeder::class,
            SchoolClassSeeder::class,
            StudyFormatSeeder::class,
            SectionSeeder::class,
                //SubjectSeeder::class,
            SubjectTypeSeeder::class,
            SubjectStudyFormatJntSeeder::class,
            SubjectGroupSeeder::class,
                //ClassSectionSeeder::class,
            PeriodSetSeeder::class,
            PeriodSetPeriodSeeder::class,
            ConstraintTypeSeeder::class,
            ConstraintSeeder::class,
            TeacherUnavailableSeeder::class,
            SubjectStudyFormatClassSeeder::class,
                //ClassGroupJntSeeder::class,
            SubjectGroupSubjectSeeder::class,
            StudentSeeder::class,
                //ClassSubgroupSeeder::class,
            ShiftSeeder::class,
                //RoomUnavaliableSeeder::class,
                //ClassGroupRequirementSeeder::class,
            TeacherAssignmentRoleSeeder::class,
                //TimetableActivitySeeder::class,
            TimetableTypeSeeder::class,
                //TimetableSeeder::class,
            ClassTeacherSeeder::class,
            //ActivityTeacherSeeder::class,
            //ClassGroupSeeder::class
        ]);
    }
}

# PROMPT: Complete Attendance Data Integration — HPC Module
**Task ID:** P2_23
**Issue IDs:** GAP-8
**Priority:** P2-Medium
**Estimated Effort:** 2 days
**Prerequisites:** All P0 and P1 tasks must be complete

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
```

---

## CONTEXT

The HPC form Page 1 has a 12-month attendance table (working_days × present × percentage × reasons). Currently, basic attendance query exists in HpcController but: there's no `working_days` source table/config, absence reasons are not categorized, and transport module attendance is not integrated. Attendance is ~30% complete.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Http/Controllers/HpcController.php` — existing attendance query in `hpc_form()`
2. `{LARAVEL_REPO}/Modules/StudentProfile/app/Models/` — `Student.php`, attendance-related models
3. `{LARAVEL_REPO}/Modules/SchoolSetup/app/Models/` — look for working days config or academic calendar

---

## STEPS

1. Identify the attendance source table (likely `std_attendance_details` or similar)
2. Create or locate a working days configuration (per month, per academic session)
3. Build attendance data aggregation: group by month → count present days, calculate percentage
4. Categorize absence reasons (medical, family, unexcused, etc.) from existing data
5. Auto-populate the 12-month attendance table in `hpc_form()` from `std_attendance_details`
6. Pass aggregated attendance data to PDF templates

---

## ACCEPTANCE CRITERIA

- 12-month attendance table auto-populates from student attendance records
- Working days per month are sourced from configuration (not hardcoded)
- Absence reasons are categorized
- Teachers can still manually override attendance values if needed
- PDF renders attendance table correctly

---

## DO NOT

- Do NOT modify the attendance module or its tables
- Do NOT create a new attendance tracking system — use existing data
- Do NOT implement transport module integration (future task)

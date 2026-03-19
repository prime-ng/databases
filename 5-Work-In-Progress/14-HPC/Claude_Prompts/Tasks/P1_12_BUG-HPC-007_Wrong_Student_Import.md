# PROMPT: Fix Wrong Student Model Import — HPC Module
**Task ID:** P1_12
**Issue IDs:** BUG-HPC-007
**Priority:** P1-High
**Estimated Effort:** 10 minutes
**Prerequisites:** None

---

## CONFIGURATION
```
MODULE_PATH    = /Users/bkwork/Herd/prime_ai/Modules/Hpc
```

---

## CONTEXT

`StudentHpcSnapshot` model imports `Modules\SchoolSetup\Models\Student` but the SchoolSetup module does NOT have a Student model. The correct model is `Modules\StudentProfile\Models\Student`.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Models/StudentHpcSnapshot.php`

---

## STEPS

1. Replace `use Modules\SchoolSetup\Models\Student;` with `use Modules\StudentProfile\Models\Student;`
2. Verify the relationship method using Student works correctly

---

## ACCEPTANCE CRITERIA

- Import points to `Modules\StudentProfile\Models\Student`
- No `SchoolSetup\Models\Student` references remain in HPC module

---

## DO NOT

- Do NOT change the Student model itself
- Do NOT modify the relationship logic

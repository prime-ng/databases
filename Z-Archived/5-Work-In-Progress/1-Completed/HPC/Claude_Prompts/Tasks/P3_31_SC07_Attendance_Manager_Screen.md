# PROMPT: Build Attendance Manager Screen — HPC Module
**Task ID:** P3_31
**Issue IDs:** SC-07
**Priority:** P3-Low
**Estimated Effort:** 2 days
**Prerequisites:** P2_23 (Attendance Data Complete)

---

## CONFIGURATION
```
MODULE_PATH    = /Users/bkwork/Herd/prime_ai/Modules/Hpc
ROUTES_FILE    = /Users/bkwork/Herd/prime_ai/routes/tenant.php
```

---

## CONTEXT

Blueprint screen SC-07 defines a dedicated Attendance Manager for HPC: a calendar view showing per-student attendance, bulk mark/edit, absence categorization, and working days configuration. Currently attendance is a basic query on Page 1 — no dedicated management screen.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Http/Controllers/HpcController.php` — existing attendance queries
2. Student attendance models in StudentProfile module

---

## STEPS

1. Create `HpcAttendanceController` with index (calendar view), bulkMark, configure (working days)
2. Create views: calendar grid (months × students), bulk edit modal, working days config
3. Add routes: `GET /hpc/attendance`, `POST /hpc/attendance/bulk-mark`, `GET /hpc/attendance/config`
4. Fetch attendance from `std_attendance_details`, display in monthly grid
5. Allow bulk marking and absence categorization

---

## ACCEPTANCE CRITERIA

- Calendar grid shows 12 months × students with attendance status
- Bulk mark attendance for multiple students
- Working days configurable per month
- Absence reasons categorized
- Data feeds into HPC Page 1 attendance table

---

## DO NOT

- Do NOT replace the StudentProfile attendance system — this is HPC-specific view only
- Do NOT modify student attendance tables

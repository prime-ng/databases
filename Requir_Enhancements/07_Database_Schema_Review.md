# 07 — Database Schema Review

## Scope

| Database | Tables | Status |
|----------|--------|--------|
| `global_db` | 12 | Reviewed |
| `prime_db` | 27 | Reviewed |
| `tenant_db` | 368 | Reviewed |

**Analyzed:** DDL files in `1-master_dbs/1-DDLs/`, 15 migration files, 5 model files

---

## Summary of Findings

| Severity | Count | Categories |
|----------|-------|------------|
| CRITICAL | 14 | Syntax errors, wrong FK references, missing student_id |
| HIGH | 13 | Missing FKs, missing unique indexes, model mismatches |
| MEDIUM | 12 | Missing indexes, ENUMs, JSON normalization, naming |
| LOW | 10 | VARCHAR sizing, missing timestamps, conventions |
| **TOTAL** | **49** | |

---

## Section 1: Syntax Errors & DDL Bugs

### DB-001: Duplicate column `is_active` in `sys_users`
- **Table:** `sys_users` (prime_db.sql)
- **Problem:** `is_active` is defined twice. MySQL will reject this DDL.
- **Severity:** CRITICAL
- **Fix:** Remove the duplicate column declaration.

### DB-002: Duplicate unique key name in `sys_roles`
- **Table:** `sys_roles` (prime_db.sql)
- **Problem:** Two UNIQUE KEYs both named `uq_roles_name_guardName`. Also missing a comma between them.
- **Severity:** CRITICAL
- **Fix:** Rename the second key to `uq_roles_shortName_guardName` and add the missing comma.

### DB-003: Trailing comma in `sys_users` PRIMARY KEY block
- **Table:** `sys_users` (prime_db.sql)
- **Problem:** Trailing comma after the last UNIQUE KEY before closing parenthesis causes syntax error.
- **Severity:** CRITICAL

### DB-004: Trailing comma in `sys_settings`
- **Table:** `sys_settings` (prime_db.sql)
- **Problem:** Trailing comma after UNIQUE KEY causes syntax error.
- **Severity:** CRITICAL

### DB-005: Missing comma in `sys_dropdown_table`
- **Table:** `sys_dropdown_table` (prime_db.sql)
- **Problem:** Missing comma between PRIMARY KEY and UNIQUE KEY.
- **Severity:** CRITICAL

### DB-006: Trailing comma in `prm_plans`
- **Table:** `prm_plans` (prime_db.sql)
- **Problem:** Trailing comma after CONSTRAINT declaration.
- **Severity:** CRITICAL

### DB-007: Trailing comma in `bil_tenant_invoices`
- **Table:** `bil_tenant_invoices` (prime_db.sql)
- **Problem:** Trailing comma after last CONSTRAINT.
- **Severity:** CRITICAL

### DB-008: Invalid column order in `bil_tenant_invoicing_payments`
- **Table:** `bil_tenant_invoicing_payments` (prime_db.sql)
- **Problem:** `'payment_status' NOT NULL VARCHAR(20)` — NOT NULL placed before data type, invalid SQL syntax.
- **Severity:** CRITICAL
- **Fix:** Change to `'payment_status' VARCHAR(20) NOT NULL DEFAULT 'SUCCESS'`.

### DB-009: Generated column references wrong column name
- **Table:** `prm_tenant_plan_jnt` (prime_db.sql)
- **Problem:** `current_flag` generated column references `org_id` but the actual column is `tenant_id`.
- **Severity:** CRITICAL

### DB-010: FK references wrong column name
- **Table:** `prm_tenant_plan_rates` (prime_db.sql)
- **Problem:** FK references `organization_plan_id` but the actual column is `tenant_plan_id`.
- **Severity:** CRITICAL

### DB-011: FK references wrong table names
- **Table:** `bil_tenant_invoicing_modules_jnt` (prime_db.sql)
- **Problem:** UNIQUE KEY references `tenant_invoicing_id` but column is `tenant_invoice_id`. FK references `bil_tenant_invoice` (singular) but table is `bil_tenant_invoices` (plural).
- **Severity:** CRITICAL

### DB-012: FK references wrong table names in payments
- **Table:** `bil_tenant_invoicing_payments` (prime_db.sql)
- **Problem:** FK references `tenant_invoicing_id` and table `bil_tenant_invoicing`, but actual column is `tenant_invoice_id` and table is `bil_tenant_invoices`.
- **Severity:** CRITICAL

### DB-013: Trigger references wrong table name
- **Table:** `sys_users` triggers (prime_db.sql)
- **Problem:** Triggers reference table `users` instead of `sys_users`.
- **Severity:** HIGH

---

## Section 2: Data Type Issues

### DT-001: `prm_plans.billing_cycle_id` type mismatch
- **Problem:** `SMALLINT NOT NULL` (signed) references `prm_billing_cycles.id` which is `SMALLINT UNSIGNED`. InnoDB FK requires identical types.
- **Severity:** HIGH

### DT-002: `prm_tenant_domains.tenant_id` type mismatch
- **Problem:** `INT NOT NULL` (signed) references `prm_tenant.id` which is `INT UNSIGNED`. FK will fail.
- **Severity:** HIGH

### DT-003: VARCHAR(255) used for short values
- **Tables:** Multiple (`guard_name`, `mime_type`, `disk`)
- **Severity:** LOW
- **Fix:** Reduce to appropriate sizes: `guard_name` VARCHAR(20), `mime_type` VARCHAR(100).

### DT-004: Excessive boolean columns in vehicle inspection
- **Table:** `tpt_daily_vehicle_inspection` — 14 individual boolean columns for checklist items.
- **Severity:** MEDIUM
- **Fix:** Normalize to `tpt_inspection_items` + `tpt_inspection_results` tables.

### DT-005: `tpt_trip.status` is VARCHAR instead of FK to dropdown
- **Severity:** MEDIUM
- **Fix:** Change to `status_id INT UNSIGNED` with FK to `sys_dropdown_table`.

### DT-006: Unbounded status/remark columns
- **Table:** `tpt_student_fee_detail` — `status` and `remark` both VARCHAR(255).
- **Severity:** LOW

### DT-007: Time stored as INTEGER
- **Table:** `tpt_pickup_points_route_jnt` — `arrival_time`, `departure_time`, `estimated_time` stored as integers.
- **Severity:** MEDIUM
- **Fix:** Use TIME data type.

---

## Section 3: Missing Indexes

| ID | Table | Column | Severity |
|----|-------|--------|----------|
| IDX-001 | `glb_cities` | `district_id` | LOW |
| IDX-002 | `glb_menus` | `parent_id` | MEDIUM |
| IDX-003 | `glb_modules` | `parent_id` | MEDIUM |
| IDX-004 | `sys_activity_logs` | `event` | MEDIUM |
| IDX-005 | `tpt_vehicle` | `vehicle_type_id`, `fuel_type_id`, etc. | MEDIUM |
| IDX-006 | `tpt_student_fee_detail` | `std_academic_sessions_id` | HIGH |
| IDX-007 | `std_student_academic_sessions` | `session_status_id` | MEDIUM |
| IDX-008 | `bil_tenant_email_schedules` | `invoice_id` | HIGH |
| IDX-009 | `tpt_live_trip` | `trip_id` | LOW |

---

## Section 4: Missing Foreign Key Constraints

| ID | Table.Column | Should Reference | Severity |
|----|-------------|------------------|----------|
| FK-001 | `tpt_vehicle.vendor_id` | `vnd_vendors.id` | HIGH |
| FK-002 | `tpt_student_fee_detail.std_academic_sessions_id` | `std_student_academic_sessions.id` | HIGH |
| FK-003 | `std_students.current_status_id` | `sys_dropdown_table.id` (commented out) | HIGH |
| FK-004 | `std_students.media_id` | `sys_media.id` (commented out) | MEDIUM |
| FK-005 | `std_student_academic_sessions.session_status_id` | `sys_dropdowns.id` (commented out) | HIGH |
| FK-006 | `std_student_academic_sessions.house` | Unknown (no FK, unclear semantics) | MEDIUM |
| FK-007 | `std_student_academic_sessions.reason_quit` | `sys_dropdowns.id` (no FK) | MEDIUM |
| FK-008 | `bil_tenant_email_schedules.invoice_id` | `bil_tenant_invoices.id` | HIGH |
| FK-009 | `bil_tenant_invoicing_audit_logs.performed_by` | `users` (should be `sys_users`) | CRITICAL |
| FK-010 | `prm_module_plan_jnt.module_id` | `sys_modules` (should be `glb_modules`) | CRITICAL |

---

## Section 5: Junction Table Issues

| ID | Table | Problem | Severity |
|----|-------|---------|----------|
| JNT-001 | `glb_menu_model_jnt` | No UNIQUE constraint on `(menu_id, module_id)` — allows duplicates | HIGH |
| JNT-002 | `glb_menu_model_jnt` | Missing timestamps | LOW |
| JNT-003 | `prm_module_plan_jnt` | No UNIQUE constraint on `(plan_id, module_id)` | HIGH |
| JNT-004 | `prm_tenant_plan_module_jnt` | No UNIQUE constraint on `(module_id, tenant_plan_id)` | HIGH |
| JNT-005 | `sch_class_section_jnt` | `ordinal` has global UNIQUE instead of per-class UNIQUE | HIGH |

---

## Section 6: ENUM vs Reference Table Inconsistencies

| ID | Table.Column | Current | Should Be | Severity |
|----|-------------|---------|-----------|----------|
| ENUM-001 | `std_students.gender` | ENUM('Male','Female','Other','Prefer Not to Say') | FK to `sys_dropdown_table` | MEDIUM |
| ENUM-002 | `std_students.student_id_card_type` | ENUM('QR','RFID','NFC','Barcode') | FK to dropdown | LOW |
| ENUM-003 | `tpt_student_event_log.event_type` | ENUM('BOARD','ALIGHT') | Consistent but inconsistent with platform pattern | LOW |
| ENUM-004 | `tpt_pickup_points_route_jnt.pickup_drop` | ENUM('Pickup','Drop') | Inconsistent case convention | LOW |
| ENUM-005 | Multiple | Mixed VARCHAR/ENUM/FK for status columns | Standardize on FK to `sys_dropdown_table` | MEDIUM |

---

## Section 7: Model vs Database Mismatches

| ID | Model | Problem | Severity |
|----|-------|---------|----------|
| MDL-001 | `Teacher` | Fillable includes `emp_code`, `max_periods_per_week`, etc. but migration lacks these columns | HIGH |
| MDL-002 | `TptStudentEventLog` | Empty `$fillable`, no `$table`, no relationships, no SoftDeletes — model is unusable | HIGH |
| MDL-003 | `TptTrip` | `driver()` and `helper()` reference `DriverHelper::class` but FK points to `tpt_personnel` | MEDIUM |
| MDL-004 | `Vehicle` | Has `vendor()` relationship but migration has no FK — orphan records possible | HIGH |

---

## Section 8: Missing Timestamps / Soft Deletes

| Table | Issue | Severity |
|-------|-------|----------|
| `glb_languages` | Missing `created_at`, `updated_at` | MEDIUM |
| `prm_billing_cycles` | Missing `created_at`, `updated_at`, `deleted_at` | LOW |
| `tpt_student_event_log` | **Missing `student_id` column** — table is unusable without it | CRITICAL |
| `bil_tenant_invoicing_modules_jnt` | Missing timestamps | LOW |

---

## Top 5 Priorities for Immediate Fix

1. **Fix all 12 syntax errors in DDL files** (DB-001 through DB-012) — these prevent the DDL from executing
2. **Fix FK references to non-existent tables** (FK-009, FK-010) — `sys_modules` doesn't exist, `users` should be `sys_users`
3. **Add `student_id` to `tpt_student_event_log`** (TS-003) — table is unusable without it
4. **Uncomment/enable FK constraints** (FK-003, FK-005) on NOT NULL columns in student tables
5. **Add composite unique indexes to junction tables** (JNT-001, JNT-003, JNT-004) to prevent duplicate entries

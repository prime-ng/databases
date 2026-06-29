## Mode D — Platform Systemic Sweep: GENERATED-Column Degradation (D36) — 2026-06-29

### Executive Summary
The DDL masters define a number of columns as MySQL `GENERATED ALWAYS AS (<expr>) STORED|VIRTUAL`. A platform-wide sweep of the live tenant migrations (`/Users/bkwork/Herd/prime_ai/database/migrations/tenant/`, ~700 files) shows that **exactly one** generated column is correctly implemented as generated — `sys_users.super_admin_flag`. Only **2** migrations use `storedAs/virtualAs` at all (the second is a template). Every other generated column from the DDL ships as a plain writable column or is absent. This is now registered as **D36**. Two of these were already found as module P0/P1s (Hostel allotment, Inventory variance, Hostel mess-bill); this sweep adds **~14 newly-discovered degradations** across PTM, StudentFee, Vendor, SchoolSetup, StudentProfile, EmployeeSetup, and Timetable.

### Method
```bash
# DDL side — all GENERATED columns:
grep -rinE "GENERATED ALWAYS AS|AS \(.*\) (STORED|VIRTUAL)" 2-DDL_Tenant_Consolidated/*.sql 0-DDL_Masters/tenant_db_v4.sql
# Migration side — who actually implements generated columns:
grep -rlE "storedAs|virtualAs" database/migrations/tenant/          # -> only 2 files
# Per column — does its create migration declare it storedAs/virtualAs, plain, or absent?
```
Guardrail applied: the column-name check collides on common names; each candidate was re-confirmed against the column's **own module DDL** before being called a degradation (see Excluded section).

### Headline metric
| | Count |
|---|---|
| Generated columns defined in DDL masters (distinct, real) | ~19 |
| Correctly generated in live migrations | **1** (`sys_users.super_admin_flag`) |
| Degraded to plain column | ~16 |
| Absent from migrations entirely | 2 (`cht_*.dm_pair_hash`, `tt_*.no_of_days_not_available`) |
| Tenant migrations using `storedAs/virtualAs` at all | 2 of ~700 |

### Confirmed degradations (DDL = GENERATED, migration = plain), by failure mode

**Mode 1 — uniqueness key degraded (UNIQUE now enforces nothing → duplicates/races):**
| Module | Table.Column | DDL expr | Impact | Code |
|--------|--------------|----------|--------|------|
| Hostel | `hst_allotments.gen_active_bed_id` / `gen_active_student_id` | `IF(is_alloted=1, bed_id, NULL)` | **P0** concurrent bed/student double-allotment | DAT-HST-001 (registered) |
| PTM | `ptm_slot_bookings.active_booking_key` | `CASE WHEN status='CONFIRMED' THEN student_id` | double-confirmed-booking uniqueness broken | **MIG-PTM-001 (new)** |
| SchoolSetup | `sch_academic_term.current_flag`, `sch_org_academic_sessions_jnt.current_flag` | `IF(is_current=1, …)` | >1 "current" term/session possible | **MIG-SCC-001 (new)** |
| StudentProfile | `std_student_academic_sessions.current_flag` | `IF(is_current=1, student_id, NULL)` | >1 "current" session per student | **MIG-STD-001 (new)** |
| EmployeeSetup | `sch_employees_profile.active_flag`, `sch_employee_shift_assignments.active_flag`, `sch_teacher_capabilities.active_flag` | `CASE WHEN is_active=1 AND deleted_at IS NULL` | duplicate "active" rows | (Employee module code — confirm; tracked under D36) |

**Mode 2 — computed balance/total degraded (NOT NULL insert fails / value drifts):**
| Module | Table.Column | DDL expr | Impact | Code |
|--------|--------------|----------|--------|------|
| Hostel | `hst_mess_bills.total_amount` | `base + diet − leave − optout + adj` | insert fails (1364) / wrong bill | MIG-HST-001 (registered) |
| StudentFee | `fee_invoices.balance_amount` | `total_amount − paid_amount` | invoice balance wrong/driftable (financial) | **MIG-FIN-001 (new)** |
| Vendor | `vnd_invoices.balance_due` | `net_payable − amount_paid` | AP balance wrong (financial) | **MIG-VND-001 (new)** |
| EmployeeSetup | `sch_employee_leave_balance.available_balance` | `opening + carry_forward − total_used` | leave balance wrong (D26) | (Employee code — confirm; tracked under D36) |

**Mode 3 — derived/read-only column degraded (now plain-writable → integrity drift):**
| Module | Table.Column | DDL expr | Impact | Code |
|--------|--------------|----------|--------|------|
| Inventory | `inv_stock_adjustment_items.variance_qty` | `physical_qty − system_qty` | stock variance writable/wrong | MIG-INV-001 (registered) |
| Timetable | `tt_period_set.total_periods` | `duration_periods × weekly_periods` | timetable totals wrong | **MIG-TT-001 (new)** |
| Timetable | `tt_room_availability.available_for_full_timetable_duration`, a TIMESTAMPDIFF `duration_minutes` | derived | availability/duration wrong | MIG-TT-001 (new, same family) |

**Absent entirely (column not created by any migration):**
- CommonChat `cht_*.dm_pair_hash` (DM-pair dedup key) — module likely unbuilt; flag when CommonChat ships.
- Timetable `tt_*.no_of_days_not_available`.

### Excluded (name-collision false positives — verified legitimately plain in their own DDLs)
- `total_amount` appears plain in 11 migrations, but only `hst_mess_bills` declares it GENERATED. `acc_vouchers`, `acc_recurring_templates`, `acc_expense_claims`, `caf_orders`, `caf_pos_transactions`, `inv_purchase_orders`, `inv_purchase_order_items`, `tpt_student_fee_detail`, `fee_invoices(total_amount)` carry an ordinary `total_amount` in their DDLs — **not** defects.
- `duration_minutes` is a user-entered field in `lms_exam_papers`, `lms_quests`, `lms_quizzes`, `slb_topics` — only the Timetable TIMESTAMPDIFF variant is generated.

### Recommended fix order
1. **P0** — `hst_allotments` generated keys + row locks (already DAT-HST-001).
2. **Financial Mode-2** — `fee_invoices.balance_amount`, `vnd_invoices.balance_due`, `sch_employee_leave_balance.available_balance`: restore `storedAs(...)` (or compute in a locked service); these drive money/leave decisions.
3. **Uniqueness Mode-1** — `ptm_slot_bookings.active_booking_key`, `current_flag` (3 tables), `active_flag` (3 tables): restore generated column + keep the UNIQUE index.
4. **Mode-3** — `inv_…variance_qty`, `tt_…` derived columns.
5. Platform: add a CI check that every DDL `GENERATED ALWAYS` column has a matching `storedAs/virtualAs` in its migration.

*Read-only sweep. Pattern registered as D36 in `state/decisions.md`; new instance codes appended to `lessons/known-issues.md`.*

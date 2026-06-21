# Transport Tab 9: Fee & Fine Management

This screen manages the financial side of student transport — monthly fee generation, late payment fines, fee collection, and payment reconciliation. It works alongside the student route allocation to charge the correct fare based on the student's assigned stops.

---

## How It Works

The screen has three sub-sections.

**Fine Master:** The administrator configures fine slabs for late payment. Each slab defines a range of delayed days (from X days to Y days), a fine type (Fixed amount or Percentage of the fee), and the fine rate. The administrator can optionally restrict a student from transport if fines are overdue using the `student_restricted` flag.

**Student Fee Details:** The system generates monthly fee records for each student allocated to transport. Each record shows the base fare (from the student's route allocation), any applicable fine, the total amount, the due date, and the payment status (Pending, Paid, Overdue). The fine is automatically calculated based on the Fine Master rules when payment is delayed beyond the due date.

**Fee Collection & Reconciliation:** When a student pays, the administrator records the payment with the payment date, delay days (computed), paid amount, payment mode, and status. Each payment has a `reconciled` flag — 0 means the payment is recorded but not yet verified against the bank statement; 1 means it is reconciled. A payment log (`std_student_pay_log`) records all financial transactions for audit purposes.

---

## Important Business Rules

- Monthly fee records are generated based on the student's route allocation fare. If no route allocation exists, no fee record is created.
- The fine is calculated based on the number of days past the due date, matched against the Fine Master slabs. If the delay falls within multiple slabs, the highest applicable slab is used.
- A student with `student_restricted` = 1 cannot board the transport until all overdue fines are paid.
- The `total_delay_days` in the fee collection record is computed as the difference between the payment date and the due date.
- Fine calculation is separate for each monthly fee record — fines do not accumulate across months.
- The `waved_fine_amount` in the Student Fine Detail allows the administrator to waive part or all of the fine.
- The `net_fine_amount` is computed as: fine_amount - waved_fine_amount.
- Payment reconciliation is a separate step performed by the accounts team. Unreconciled payments appear in a reconciliation report.
- All financial transactions are logged in `std_student_pay_log` with the module name 'Transport' for audit trail.

---

## Database Columns & Behavior

### tpt_fine_master
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `std_academic_sessions_id` — INT UNSIGNED, NOT NULL. FK to the academic sessions table.
- `fine_from_days` — TINYINT, default 0. Start of the fine slab (in days past due date).
- `fine_to_days` — TINYINT, default 0. End of the fine slab.
- `fine_type` — ENUM('Fixed','Percentage'), default 'Fixed'. How the fine is calculated.
- `fine_rate` — DECIMAL(5,2), default 0.00. If Fixed = amount; if Percentage = percentage of fee.
- `student_restricted` — TINYINT(1), default 0. 1 = restrict student if fine applies.
- `Remark` — VARCHAR(512), nullable.
- `created_at`, `deleted_at` — Timestamp fields.

### tpt_student_fee_detail
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `std_academic_sessions_id` — INT UNSIGNED, NOT NULL.
- `month` — DATE, NOT NULL. The month this fee is for (stored as first date of the month).
- `amount` — DECIMAL(10,2), NOT NULL. Base fare from route allocation.
- `fine_amount` — DECIMAL(10,2), default 0.00. Computed fine.
- `total_amount` — DECIMAL(10,2), NOT NULL. amount + fine_amount.
- `due_date` — DATE, NOT NULL. Payment due date.
- `Remark` — VARCHAR(512), nullable.
- `status` — VARCHAR(20), NOT NULL, default 'Pending'. Payment status.
- `created_at`, `deleted_at` — Timestamp fields.

### tpt_student_fine_detail
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `student_fee_detail_id` — INT UNSIGNED, NOT NULL. FK to tpt_student_fee_detail.
- `fine_master_id` — INT UNSIGNED, NOT NULL. FK to tpt_fine_master.
- `fine_days` — TINYINT, default 0. Number of days delayed.
- `fine_type` — ENUM('Fixed','Percentage'), default 'Fixed'. Copied from fine master.
- `fine_rate` — DECIMAL(5,2), default 0.00. Copied from fine master.
- `fine_amount` — DECIMAL(10,2), default 0.00. Computed fine amount.
- `waved_fine_amount` — DECIMAL(10,2), default 0.00. Amount waived by administrator.
- `net_fine_amount` — DECIMAL(10,2), default 0.00. fine_amount - waved_fine_amount.
- `Remark` — VARCHAR(512), nullable.
- `created_at`, `deleted_at` — Timestamp fields.

### tpt_student_fee_collection
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `student_fee_detail_id` — INT UNSIGNED, NOT NULL. FK to tpt_student_fee_detail.
- `payment_date` — DATE, NOT NULL. When payment was made.
- `total_delay_days` — INT, default 0. Days past due date.
- `paid_amount` — DECIMAL(10,2), NOT NULL. Amount paid.
- `payment_mode` — VARCHAR(20), NOT NULL. Mode of payment (Cash, Cheque, Online, etc.).
- `status` — VARCHAR(20), NOT NULL. Payment status.
- `reconciled` — TINYINT(1), default 0. 0 = Not Reconciled, 1 = Reconciled.
- `remarks` — VARCHAR(512), nullable.
- `created_at`, `deleted_at` — Timestamp fields.

### std_student_pay_log
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `student_id` — INT UNSIGNED, NOT NULL. FK to std_students.
- `academic_session_id` — INT UNSIGNED, NOT NULL. FK to sch_org_academic_sessions_jnt.
- `module_name` — VARCHAR(50), NOT NULL. Always 'Transport' for this module.
- `activity_type` — VARCHAR(50), NOT NULL. Type of financial activity.
- `amount` — DECIMAL(10,2), nullable. Transaction amount.
- `log_date` — DATETIME, NOT NULL. When the transaction occurred.
- `reference_id` — INT UNSIGNED, nullable. ID of the source record.
- `reference_table` — VARCHAR(100), nullable. Table name of the source record.
- `description` — VARCHAR(512), nullable. Free-text description.
- `triggered_by` — INT UNSIGNED, nullable. FK to sys_users. Who triggered the action.
- `is_system_generated` — TINYINT(1), default 0. 1 = system auto-generated.
- `created_at`, `deleted_at` — Timestamp fields.

---

## Deep Analysis

### Business Workflows & State Machines

- **Fine Master Configuration:** Admin sets fine slabs per academic session → Define day ranges + fine type (Fixed/Percentage) + rate → Optionally set `student_restricted` flag.
- **Monthly Fee Generation:** System process iterates over active student route allocations → Create `tpt_student_fee_detail` per student per month → Base fare from allocation → Due date calculated from academic calendar.
- **Fine Calculation:** When fee becomes overdue → Compute `total_delay_days` → Match against fine master slabs → Highest applicable slab used → Insert `tpt_student_fine_detail` → Update `fine_amount` and `total_amount` on fee detail.
- **Fee Collection:** Admin records payment → Capture payment_date, paid_amount, payment_mode → Compute `total_delay_days` → Set status → Payment is recorded; reconciliation happens separately.
- **Payment Reconciliation:** Accounts team marks `reconciled = 1` after bank statement matches.
- **Audit Logging:** All financial transactions create an entry in `std_student_pay_log` with module_name = 'Transport'.

### Validation Rules & Edge Cases

- **Slab coverage:** Fine slabs for a given academic session must not overlap; `fine_from_days` and `fine_to_days` ranges should be contiguous.
- **Highest slab rule:** If a delay falls into multiple slab ranges, the highest `fine_to_days` slab applies (not sum of slabs).
- **Restricted student:** If `student_restricted = 1` and fine is unpaid, the student cannot board. Enforced at boarding-log application level.
- **Fee without allocation:** No route allocation → no fee record is generated. Edge case: student deactivated mid-month — fee record still created for the partial month.
- **Fine waiver:** `waved_fine_amount` ≤ `fine_amount`; `net_fine_amount` = `fine_amount - waved_fine_amount` — must be non-negative.
- **Payment immutability:** Once `reconciled = 1`, the payment record should not be editable.
- **Due date comparison:** `total_delay_days` = `DATEDIFF(payment_date, due_date)`; if payment_date < due_date, delay is 0 (no fine).
- **Percentage fine:** If `fine_type = 'Percentage'`, `fine_amount = amount * (fine_rate / 100)`.

### Integration Points

- **tpt_student_route_allocation_jnt** — Base fare source for fee generation.
- **tpt_fine_master** — Fine slab configuration.
- **tpt_student_fee_detail** — Monthly fee records.
- **tpt_student_fine_detail** — Computed fine per fee record.
- **tpt_student_fee_collection** — Payment records.
- **std_student_pay_log** — Audit trail (module_name = 'Transport').
- **std_students** — Student identity.
- **sch_org_academic_sessions_jnt** — Academic session scope.

### Permissions Matrix

| Role | Manage Fine Slabs | View Fees | Record Payment | Waive Fine | Reconcile Payment | View Audit Log |
|---|---|---|---|---|---|---|
| Super Admin | Full | Full | Full | Full | Full | Full |
| School Admin | Full | Full | Full | Full | Full | Full |
| Transport Manager | No | Full | Yes | No | No | No |
| Accounts Team | No | Full | Yes | No | Yes | Full |
| Driver / Helper | No | No | No | No | No | No |

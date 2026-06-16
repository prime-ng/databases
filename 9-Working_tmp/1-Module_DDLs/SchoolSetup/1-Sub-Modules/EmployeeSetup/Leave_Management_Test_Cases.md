# Leave Management — Test Cases Guide
**Module:** Employee Setup → Leave Management  
**Version:** v5.0 DDL  
**Tabs Covered:** (1) Leave Application | (2) Leave Approver  

---

## 📋 Pre-Requisites (Setup Before Testing)

> Run these SQL inserts in the **tenant DB** before starting any test case.

### Step 1 — Seed Leave Types

```sql
INSERT INTO `sch_staff_leave_types`
  (`code`, `name`, `is_paid`, `is_carry_forwardable`, `requires_doc`,
   `allows_half_day`, `requires_approval`, `min_days_per_application`,
   `max_days_per_application`, `min_advance_notice_days`, `is_active`)
VALUES
  ('CL',  'Casual Leave',      1, 0, 0, 1, 1, 0.5, 3,    0, 1),
  ('SL',  'Sick Leave',        1, 0, 1, 1, 1, 0.5, 7,    0, 1),
  ('EL',  'Earned Leave',      1, 1, 0, 1, 1, 1.0, 15,   7, 1),
  ('LWP', 'Leave Without Pay', 0, 0, 0, 0, 1, 1.0, NULL, 0, 1);
```

### Step 2 — Seed Leave Balance (employee_id = 1)

```sql
INSERT INTO `sch_employee_leave_balance`
  (`employee_id`, `academic_year`, `leave_type_id`,
   `opening_balance`, `carry_forward`, `total_used`, `total_pending`)
VALUES
  (1, '2025-26', 1, 12.00, 0.00, 2.00, 0.00),  -- CL: 10 remaining
  (1, '2025-26', 2, 10.00, 0.00, 0.00, 0.00),  -- SL: 10 remaining
  (1, '2025-26', 3, 20.00, 5.00, 3.00, 0.00);  -- EL: 22 remaining
```

### Step 3 — Seed Approval Policy (2-Level: Manager → HR)

```sql
-- Policy master
INSERT INTO `sch_leave_approval_policies`
  (`name`, `applies_to_role_id`, `applies_to_leave_type_id`, `priority`, `is_active`)
VALUES ('Default 2-Level Policy', NULL, NULL, 10, 1);

-- Level 1 — Reporting Manager
INSERT INTO `sch_leave_approval_policy_levels`
  (`policy_id`, `level_number`, `level_name`, `approval_mode`,
   `escalation_after_hours`, `is_active`)
VALUES (1, 1, 'Reporting Manager', 'ANY_ONE', 24, 1);

-- Level 2 — HR
INSERT INTO `sch_leave_approval_policy_levels`
  (`policy_id`, `level_number`, `level_name`, `approval_mode`,
   `escalation_after_hours`, `is_active`)
VALUES (1, 2, 'HR Department', 'ANY_ONE', 48, 1);

-- L1 approver: user_id = 2 (Manager)
INSERT INTO `sch_leave_approval_level_approvers`
  (`level_id`, `approver_type`, `approver_user_id`, `is_active`)
VALUES (1, 'USER', 2, 1);

-- L2 approver: user_id = 3 (HR)
INSERT INTO `sch_leave_approval_level_approvers`
  (`level_id`, `approver_type`, `approver_user_id`, `is_active`)
VALUES (2, 'USER', 3, 1);
```

---

## 👤 Test Actors

| Actor | user_id | employee_id | Role |
|-------|---------|-------------|------|
| Rahul Sharma | 1 | 1 | Teacher (Applicant) |
| Amit Singh | 2 | 2 | Reporting Manager (L1 Approver) |
| Priya HR | 3 | 3 | HR Staff (L2 Final Approver) |

---

# TAB 1 — Leave Application

> **Logged in as:** Rahul Sharma (employee_id = 1)

---

## TC-LA-01 — Apply Casual Leave (Normal Flow)

**Scenario:** Employee applies 2-day CL with sufficient balance.

| Field | Value |
|-------|-------|
| Leave Type | Casual Leave (CL) |
| From Date | 2026-05-15 |
| To Date | 2026-05-16 |
| Total Days | 2 |
| Is Half Day | No |
| Reason | Personal work at home |

**Expected DB Insert:**
```sql
INSERT INTO `sch_employee_leave_applications`
  (`employee_id`, `academic_session_id`, `leave_type_id`, `from_date`, `to_date`,
   `total_days`, `is_half_day`, `is_emergency`, `reason`, `status`,
   `approval_policy_id`, `current_level_number`, `applied_by`)
VALUES (1, 1, 1, '2026-05-15', '2026-05-16', 2.0, 0, 0,
        'Personal work at home', 'Submitted', 1, 1, 1);
```

**Expected Result:**
- ✅ `status = Submitted`
- ✅ `current_level_number = 1`
- ✅ `pending_with_user_id = 2` (Amit Singh)
- ✅ `total_pending` in balance +2.0

**Verify:**
```sql
SELECT id, status, current_level_number, pending_with_user_id
FROM sch_employee_leave_applications
WHERE employee_id = 1 ORDER BY id DESC LIMIT 1;
```

---

## TC-LA-02 — Apply Half Day Leave

| Field | Value |
|-------|-------|
| Leave Type | Casual Leave (CL) |
| From Date | 2026-05-20 |
| To Date | 2026-05-20 |
| Is Half Day | Yes |
| Half Day Slot | Morning |
| Total Days | 0.5 |
| Reason | Doctor appointment |

**Expected Result:**
- ✅ `is_half_day = 1`, `half_day_slot = Morning`
- ✅ `total_days = 0.5`
- ✅ Balance `total_pending` +0.5

---

## TC-LA-03 — Apply Sick Leave with Document Upload

| Field | Value |
|-------|-------|
| Leave Type | Sick Leave (SL) |
| From Date | 2026-05-10 |
| To Date | 2026-05-12 |
| Total Days | 3 |
| Document | Medical_Certificate.pdf |
| Reason | High fever |

**Expected Result:**
- ✅ Application created, `status = Submitted`
- ✅ Doc record in `sch_employee_leave_application_docs`

**Verify Doc:**
```sql
SELECT * FROM sch_employee_leave_application_docs
WHERE leave_application_id = (
  SELECT MAX(id) FROM sch_employee_leave_applications WHERE employee_id = 1
);
```

---

## TC-LA-04 ❌ — Insufficient Leave Balance (Negative)

**Scenario:** Employee has 10 CL, applies for 15 days.

| Field | Value |
|-------|-------|
| Leave Type | Casual Leave (CL) |
| Total Days | 15 |

**Expected Result:**
- ❌ Validation error: `"Insufficient balance. Available: 10, Requested: 15"`
- ❌ No insert in `sch_employee_leave_applications`

---

## TC-LA-05 — Save as Draft

**Scenario:** Employee fills form but saves as draft, does NOT submit.

**Expected Result:**
- ✅ `status = Draft`
- ✅ `submitted_at = NULL`
- ✅ `pending_with_user_id = NULL`
- ✅ Balance NOT affected
- ✅ No notification to approver

---

## TC-LA-06 — Cancel a Submitted Application

**Pre-condition:** TC-LA-01 application exists (`status = Submitted`).

**Action:** Rahul cancels with reason.

**Expected Result:**
- ✅ `status = Cancelled`
- ✅ `cancelled_by = 1`, `cancelled_at = NOW()`
- ✅ `cancellation_reason` saved
- ✅ `total_pending` in balance reset to 0

---

## TC-LA-07 — View Leave Balance

**Expected Query:**
```sql
SELECT
  lt.name AS leave_type,
  elb.opening_balance + elb.carry_forward AS total_entitled,
  elb.total_used,
  elb.total_pending,
  elb.available_balance
FROM sch_employee_leave_balance elb
JOIN sch_staff_leave_types lt ON lt.id = elb.leave_type_id
WHERE elb.employee_id = 1
  AND elb.academic_year = '2025-26'
  AND elb.is_active = 1
  AND elb.deleted_at IS NULL;
```

**Expected Output:**
| Leave Type | Total Entitled | Used | Pending | Available |
|---|---|---|---|---|
| Casual Leave | 12 | 2 | 0 | 10 |
| Sick Leave | 10 | 0 | 0 | 10 |
| Earned Leave | 25 | 3 | 0 | 22 |

---

## TC-LA-08 — Backdated Sick Leave (Allowed)

**Scenario:** SL has `allows_back_dated = 1`. Apply for yesterday.

**Expected Result:** ✅ Accepted, `status = Submitted`

---

## TC-LA-09 ❌ — Backdated CL (Not Allowed - Negative)

**Scenario:** CL has `allows_back_dated = 0`. Apply for 3 days ago.

**Expected Result:**
- ❌ Error: `"Casual Leave does not allow backdated applications"`
- ❌ No insert

---

## TC-LA-10 ❌ — Earned Leave Without Advance Notice (Negative)

**Scenario:** EL requires `min_advance_notice_days = 7`. Apply for tomorrow.

**Expected Result:**
- ❌ Error: `"Earned Leave requires at least 7 days advance notice"`

---

---

# TAB 2 — Leave Approver

> **L1 Login:** Amit Singh (user_id = 2)  
> **L2 Login:** Priya HR (user_id = 3)

---

## TC-AP-01 — Manager Approves (L1 Approval)

**Pre-condition:** TC-LA-01 done. Application `status = Submitted`, L1 pending.

**Action:** Amit clicks Approve.

**Expected L1 approval row update:**
```sql
UPDATE sch_employee_leave_approvals
SET action = 'Approved', acted_at = NOW(), remarks = 'Approved.'
WHERE leave_application_id = 1 AND level_number = 1;
```

**Expected application update:**
```sql
UPDATE sch_employee_leave_applications
SET status = 'Under Review',
    current_level_number = 2,
    pending_with_user_id = 3
WHERE id = 1;
```

**Expected Result:**
- ✅ Moves to L2 (Priya HR)
- ✅ Priya notified

---

## TC-AP-02 — HR Final Approval (L2)

**Pre-condition:** TC-AP-01 done. Application at L2.

**Action:** Priya clicks Approve.

**Expected Result:**
- ✅ `status = Approved`
- ✅ `final_reviewed_by = 3`, `final_reviewed_at = NOW()`
- ✅ `total_used` in balance +2.0
- ✅ `total_pending` = 0
- ✅ `sch_employee_attendance` rows: `status = On Leave` for 2026-05-15 & 16

**Verify Balance:**
```sql
SELECT total_used, total_pending, available_balance
FROM sch_employee_leave_balance
WHERE employee_id = 1 AND leave_type_id = 1 AND academic_year = '2025-26';
-- Expected: total_used=4.0, total_pending=0, available_balance=8.0
```

---

## TC-AP-03 — Manager Rejects (L1 Rejection)

**Action:** Amit clicks Reject with reason.

**Expected Result:**
- ✅ L1 `action = Rejected`
- ✅ Application `status = Rejected`
- ✅ `final_reviewed_by = 2`
- ✅ `total_pending` reset to 0
- ✅ No L2 triggered
- ✅ Rahul notified of rejection

---

## TC-AP-04 — Manager Requests Info

**Action:** Amit selects "Request Info" + types message.

**Expected Insert:**
```sql
INSERT INTO `sch_employee_leave_application_remarks`
  (`leave_application_id`, `remark_type`, `message`,
   `is_from_approver`, `remarked_by`)
VALUES (1, 'Info_Request',
        'Please clarify if this is planned or emergency.', 1, 2);
```

**Expected Result:**
- ✅ Application `status = Info Requested`
- ✅ Rahul notified to respond

---

## TC-AP-05 — Employee Responds to Info Request

**Action:** Rahul replies to remark.

**Expected Insert:**
```sql
INSERT INTO `sch_employee_leave_application_remarks`
  (`leave_application_id`, `remark_type`, `message`,
   `is_from_approver`, `remarked_by`, `parent_remark_id`)
VALUES (1, 'Response',
        'It is a planned family event. Classes covered.', 0, 1, <remark_id>);
```

**Expected Result:**
- ✅ `is_from_approver = 0`
- ✅ Linked via `parent_remark_id`
- ✅ Application back to `Under Review`
- ✅ Manager re-notified

---

## TC-AP-06 — Auto Escalation After 24 Hours

**Pre-condition:** L1 `escalation_after_hours = 24`. No action in 24h.

**Expected (via cron job):**
```sql
-- L1 row marked Escalated
UPDATE sch_employee_leave_approvals
SET action = 'Escalated', escalated_at = NOW(), escalated_to_level = 2
WHERE leave_application_id = 1 AND level_number = 1;

-- Application jumps to L2
UPDATE sch_employee_leave_applications
SET current_level_number = 2, pending_with_user_id = 3
WHERE id = 1;
```

**Expected Result:**
- ✅ L1 `action = Escalated`
- ✅ Priya HR notified

---

## TC-AP-07 — Partial Approval

**Scenario:** Employee applies 5-day EL, HR approves only 3 days.

**Action:** Priya sets `approved_days = 3`.

**Expected Result:**
- ✅ `approved_days = 3` in application
- ✅ `total_used` +3 (NOT +5)
- ✅ Rahul notified with approved day count

---

## TC-AP-08 — Approver Dashboard — Pending List

**Query (for Amit Singh, user_id = 2):**
```sql
SELECT
  ela.id,
  e.emp_code,
  CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
  lt.name AS leave_type,
  ela.from_date, ela.to_date, ela.total_days,
  ela.status, ela.current_level_number
FROM sch_employee_leave_applications ela
JOIN sch_employees e ON e.id = ela.employee_id
JOIN sch_staff_leave_types lt ON lt.id = ela.leave_type_id
WHERE ela.pending_with_user_id = 2
  AND ela.status IN ('Submitted','Under Review','Info Requested')
  AND ela.deleted_at IS NULL
ORDER BY ela.created_at ASC;
```

---

## TC-AP-09 — Read Receipt on Remark

**Action:** Amit reads employee remark.

**Expected Update:**
```sql
UPDATE sch_employee_leave_application_remarks
SET read_at = NOW(), read_by = 2
WHERE id = <remark_id> AND read_at IS NULL;
```

---

## TC-AP-10 ❌ — Approve Already Cancelled Application (Negative)

**Pre-condition:** Application `status = Cancelled`.

**Action:** Manager tries to approve.

**Expected Result:**
- ❌ Error: `"This application is cancelled and cannot be approved"`
- ❌ No DB changes

---

## 🔍 Useful Verification Queries

### Employee's all applications
```sql
SELECT ela.id, lt.code, ela.from_date, ela.to_date,
       ela.total_days, ela.status, ela.current_level_number
FROM sch_employee_leave_applications ela
JOIN sch_staff_leave_types lt ON lt.id = ela.leave_type_id
WHERE ela.employee_id = 1 AND ela.deleted_at IS NULL
ORDER BY ela.created_at DESC;
```

### Full approval trail
```sql
SELECT level_number, level_name, approver_user_id,
       action, acted_at, remarks
FROM sch_employee_leave_approvals
WHERE leave_application_id = 1
ORDER BY level_number ASC;
```

### All remarks thread
```sql
SELECT remark_type, message, is_from_approver,
       remarked_by, created_at, read_at
FROM sch_employee_leave_application_remarks
WHERE leave_application_id = 1 AND deleted_at IS NULL
ORDER BY created_at ASC;
```

---

## 📊 Test Summary

| TC ID | Tab | Scenario | Type |
|-------|-----|----------|------|
| TC-LA-01 | Application | Apply CL normal | ✅ Positive |
| TC-LA-02 | Application | Half day leave | ✅ Positive |
| TC-LA-03 | Application | SL with doc upload | ✅ Positive |
| TC-LA-04 | Application | Insufficient balance | ❌ Negative |
| TC-LA-05 | Application | Save as draft | ✅ Positive |
| TC-LA-06 | Application | Cancel submitted | ✅ Positive |
| TC-LA-07 | Application | View balance | ✅ Positive |
| TC-LA-08 | Application | Backdated SL allowed | ✅ Positive |
| TC-LA-09 | Application | Backdated CL blocked | ❌ Negative |
| TC-LA-10 | Application | EL no advance notice | ❌ Negative |
| TC-AP-01 | Approver | L1 Manager approves | ✅ Positive |
| TC-AP-02 | Approver | L2 HR final approval | ✅ Positive |
| TC-AP-03 | Approver | L1 rejection | ✅ Positive |
| TC-AP-04 | Approver | Request info | ✅ Positive |
| TC-AP-05 | Approver | Employee responds | ✅ Positive |
| TC-AP-06 | Approver | Auto escalation | ✅ Positive |
| TC-AP-07 | Approver | Partial approval | ✅ Positive |
| TC-AP-08 | Approver | Pending dashboard | ✅ Positive |
| TC-AP-09 | Approver | Read receipt | ✅ Positive |
| TC-AP-10 | Approver | Approve cancelled | ❌ Negative |

---
*Source: `Employee_setup_ddl_v5.sql` — Section 5 Leave Management*

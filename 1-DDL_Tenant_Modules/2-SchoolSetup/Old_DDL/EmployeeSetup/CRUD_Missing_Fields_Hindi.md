# CRUD में Missing Fields — Section-wise विश्लेषण (हिंदी)

> **तारीख:** 2026-05-08
> **उद्देश्य:** हर CRUD form की तुलना `DataDictionary_EmpSetup.md` (v5) से करना और missing fields + calculations बताना।
> **प्रतीक:** ❌ = Missing (CRUD form में नहीं है) | ⚡ = Missing Calculation | ⚠️ = Field Name Mismatch

---

## 📑 विषय-सूची

| # | Section | Tab/CRUD |
|---|---------|----------|
| 1 | Staff Leave Types | `leave-master → staff-leave-types` |
| 2 | Staff Leave Config | `leave-master → staff-leave-config` |
| 3 | Leave Applications | `leave-master → leave-applications` |
| 4 | Leave Approvals | `leave-master → leave-approvals` |
| 5 | Leave Docs | `leave-master → leave-docs` |
| 6 | Leave Remarks | `leave-master → leave-remarks` |
| 7 | Leave Balance | `leave-master → leave-balance` |
| 8 | Approval Policies | `leave-master → approval-policies` |
| 9 | Policy Levels | `leave-master → policy-levels` |
| 10 | Level Approvers | `leave-master → level-approvers` |
| 11 | Holidays | `leave-master → holidays` |
| 12 | Shifts | `leave-master → shifts` |
| 13 | Shift Assignments | `leave-master → shift-assignments` |
| 14 | Employee Attendance Dashboard | `employee-attendance` |

---

## 1. Staff Leave Types
**Table:** `sch_staff_leave_types` | **View:** `leave-master/staff-leave-types/create.blade.php`

### ✅ Form में मौजूद Fields
`code`, `name`, `min_days_per_application`, `max_days_per_application`, `min_advance_notice_days`, `max_consecutive_days`, `min_doc_required_days`, `display_order`, `color_hex`, `is_active`, `is_paid`, `allows_half_day`, `is_carry_forwardable`, `is_encashable`, `requires_doc`, `requires_substitute`, `allows_back_dated`, `is_system`, `description`

### ❌ Missing Fields

| # | Column Name | Type | क्या करता है (Hindi) | CRUD में क्यों ज़रूरी |
|---|-------------|------|---------------------|----------------------|
| 1 | `requires_approval` | TINYINT(1) | छुट्टी apply करने पर **supervisor approval ज़रूरी है या नहीं** | अगर `0` है तो leave auto-approve हो जाएगी। यह toggle form में नहीं है — default behaviour अनपेक्षित हो सकता है |

---

## 2. Staff Leave Config
**Table:** `sch_staff_leave_config` | **View:** `leave-master/staff-leave-config/create.blade.php`

### ✅ Form में मौजूद Fields
`leave_type_id`, `applies_to_role_id`, `applies_to_department_id`, `applies_to_designation_id`, `applies_to_employment_type`, `annual_entitlement`, `accrual_method`, `max_carry_forward`, `is_active`

### ❌ Missing Fields (7 fields!)

| # | Column Name | Type | क्या करता है (Hindi) | CRUD में क्यों ज़रूरी |
|---|-------------|------|---------------------|----------------------|
| 1 | `accrual_start_offset_months` | TINYINT | Joining के बाद **कितने महीने बाद** leave accrual शुरू हो (Probation handling) | बिना इसके नए employee को day-1 से ही leave मिल जाएगी |
| 2 | `is_carry_forwardable` | TINYINT(1) | बची हुई leaves **अगले साल carry forward** होंगी या नहीं | बिना इसके year-rollover job को पता नहीं चलेगा कि balance carry करना है |
| 3 | `is_encashable_at_separation` | TINYINT(1) | Employee के resignation/retirement पर leaves **cash में बदली** जा सकती हैं | Full & Final settlement में encashment calculate नहीं होगा |
| 4 | `max_encashable_days` | DECIMAL(5,2) | अधिकतम कितने दिन encash हो सकते हैं | बिना cap के unlimited encashment हो सकता है |
| 5 | `available_during_probation` | TINYINT(1) | **Probation period** में यह leave उपलब्ध है या नहीं | बिना इसके probation employee भी leave ले सकेगा |
| 6 | `probation_entitlement_pro_rata` | TINYINT(1) | Probation में **pro-rata** (अनुपातिक) entitlement दी जाए या नहीं | अगर `1` तो: `entitlement = annual × probation_months / 12` |
| 7 | `priority` | TINYINT | Multiple matching rules में **कौन-सी rule जीतेगी** (lower = higher priority) | बिना priority के policy matcher confused होगा |

### ⚡ Missing Calculations

| # | Calculation | Formula | कब चलेगी |
|---|-------------|---------|-----------|
| 1 | Monthly Pro-Rata Accrual | `monthly_accrual = annual_entitlement / 12` | जब `accrual_method = 'Monthly_Pro_Rata'` |
| 2 | Accrual Start Date | `accrual_begins = joining_date + accrual_start_offset_months` | Probation handling |
| 3 | Carry Forward Cap | `carry_forward = MIN(remaining_balance, max_carry_forward)` | Year-rollover job |
| 4 | F&F Encashment | `encash_days = MIN(balance, max_encashable_days)` | Separation settlement |
| 5 | Probation Entitlement | `entitlement = annual × probation_months / 12` | जब `probation_entitlement_pro_rata = 1` |

---

## 3. Leave Applications
**Table:** `sch_employee_leave_applications` | **View:** `leave-master/leave-applications/create.blade.php`

### ✅ Form में मौजूद Fields
`employee_id`, `academic_session_id`, `leave_type_id`, `approval_policy_id`, `from_date`, `to_date`, `total_days`, `status`, `is_half_day`, `half_day_slot`, `is_emergency`, `is_active`, `reason`

### ❌ Missing Fields

| # | Column Name | Type | क्या करता है (Hindi) | CRUD में क्यों ज़रूरी |
|---|-------------|------|---------------------|----------------------|
| 1 | `applied_by` | INT FK (NOT NULL) | किसने apply किया — **employee खुद या admin ने behalf पर** | DB में NOT NULL है, बिना इसके INSERT fail होगा! |
| 2 | `current_level_number` | TINYINT | अभी कौन-से approval level पर pending है | Workflow tracking — "मेरी leave कहाँ है" |
| 3 | `pending_with_user_id` | INT FK | अभी **किस user** के पास approve करने के लिए है | Approver dashboard filter |
| 4 | `approved_days` | DECIMAL(4,1) | Manager ने कितने दिन **approve** किए (partial approval) | Balance debit: `balance.total_used += approved_days` |

> **नोट:** `applied_by` backend controller में `auth()->id()` से auto-set होना चाहिए।

### ⚡ Missing Calculations

| # | Calculation | Formula | कब चलेगी |
|---|-------------|---------|-----------|
| 1 | Total Days (auto) | `total_days = working_days(from_date, to_date) − holidays − weekends; halve if is_half_day` | Form submit पर (server-side) |
| 2 | Advance Notice Check | `(from_date - today) >= leave_type.min_advance_notice_days` | Validation |
| 3 | Balance Debit | `balance.total_used += approved_days` | Approval पर |
| 4 | Balance Pending | `balance.total_pending += total_days` | Submit पर |

---

## 4. Leave Approvals
**Table:** `sch_employee_leave_approvals` | **View:** `leave-master/leave-approvals/create.blade.php`

### ✅ Form में मौजूद Fields
`leave_application_id`, `policy_level_id`, `level_number`, `level_name`, `approver_user_id`, `action`, `acted_at`, `escalation_deadline`, `is_active`, `remarks`

### ❌ Missing Fields

| # | Column Name | Type | क्या करता है (Hindi) | CRUD में क्यों ज़रूरी |
|---|-------------|------|---------------------|----------------------|
| 1 | `escalated_at` | TIMESTAMP | Escalation **कब हुआ** | Audit trail — SLA tracking |
| 2 | `escalated_to_level` | TINYINT | Escalation **किस level** पर गया | Workflow engine needs this |

### ⚡ Missing Calculations

| # | Calculation | Formula |
|---|-------------|---------|
| 1 | Escalation Deadline | `deadline = pending_at + level.escalation_after_hours` |

---

## 5. Leave Docs
**Table:** `sch_employee_leave_application_docs` | **View:** `leave-master/leave-docs/create.blade.php`

### ✅ Form में मौजूद Fields
`leave_application_id`, `document_name`, `file` (upload), `document_type_id`, `is_in_response_to_request`, `request_remark_id`, `is_active`, `description`

### ❌ Missing Fields

| # | Column Name | Type | क्या करता है (Hindi) | CRUD में क्यों ज़रूरी |
|---|-------------|------|---------------------|----------------------|
| 1 | `uploaded_by` | INT FK (NOT NULL) | **किसने upload** किया | DB में NOT NULL — backend में `auth()->id()` set करना ज़रूरी |

---

## 6. Leave Remarks
**Table:** `sch_employee_leave_application_remarks` | **View:** `leave-master/leave-remarks/create.blade.php`

### ✅ Form में मौजूद Fields
`leave_application_id`, `approval_level_id`, `remark_type`, `parent_remark_id`, `is_from_approver`, `is_resolved`, `old_status`, `new_status`, `is_active`, `message`

### ❌ Missing Fields

| # | Column Name | Type | क्या करता है (Hindi) | CRUD में क्यों ज़रूरी |
|---|-------------|------|---------------------|----------------------|
| 1 | `remarked_by` | INT FK (NOT NULL) | **किसने remark** लिखा | DB NOT NULL — backend में set ज़रूरी |
| 2 | `resolved_at` | TIMESTAMP | Request **कब resolve** हुई | SLA tracking |
| 3 | `read_at` | TIMESTAMP | Recipient ने **कब पढ़ा** | Read receipts |
| 4 | `read_by` | INT FK | **किसने** पढ़ा | Read receipts |

---

## 7. Leave Balance
**Table:** `sch_employee_leave_balance` | **View:** `leave-master/leave-balance/create.blade.php`

### ✅ Form में मौजूद Fields
`employee_id`, `academic_year`, `leave_type_id`, `opening_balance`, `carry_forward`, `total_used`, `total_pending`, `manual_adjustment`, `is_active`, `adjustment_reason`

### ❌ Missing Fields — कोई नहीं ✅
> `available_balance` DB STORED GENERATED column है — auto-computed

### ⚡ Important Calculations (system में होनी चाहिए)

| # | Calculation | Formula | कब |
|---|-------------|---------|-----|
| 1 | Available Balance | `available_balance = opening_balance + carry_forward − total_used` | STORED column (auto) |
| 2 | Year-start Seed | `opening_balance = config.annual_entitlement` | Year-rollover job |
| 3 | Carry Forward | `carry_forward = MIN(prior_year_remaining, config.max_carry_forward)` | Year-rollover job |
| 4 | Total Used Update | `total_used = SUM(approved_days WHERE status='Approved')` | Leave approval पर |
| 5 | Total Pending Update | `total_pending = SUM(total_days WHERE status IN ('Submitted','Under Review',...))` | Leave submit पर |

---

## 8. Approval Policies
**Table:** `sch_leave_approval_policies` | **View:** `leave-master/approval-policies/create.blade.php`

### ⚠️ Field Name Mismatches (बड़ी समस्या!)

| # | Form `name=""` | DB Column Name | समस्या |
|---|---------------|---------------|--------|
| 1 | `leave_type_id` | `applies_to_leave_type_id` | ❌ Name mismatch — Controller में mapping ज़रूरी |
| 2 | `role_id` | `applies_to_role_id` | ❌ Name mismatch |
| 3 | `department_id` | `applies_to_department_id` | ❌ Name mismatch |
| 4 | `designation_id` | `applies_to_designation_id` | ❌ Name mismatch |

### ⚠️ HTML Bug
```html
Line 83: </form>   ← पहला close (सही)
Line 86: </form>   ← दूसरा close (DUPLICATE!)
Line 87: </div>    ← Extra
Line 88: </div>    ← Extra
```
Form और div tags **दो बार close** हो रहे हैं — broken HTML!

---

## 9. Policy Levels
**Table:** `sch_leave_approval_policy_levels` | **View:** `leave-master/policy-levels/create.blade.php`

### ❌ Missing Fields — **कोई नहीं** ✅ (सब fields covered!)

---

## 10. Level Approvers
**Table:** `sch_leave_approval_level_approvers` | **View:** `leave-master/level-approvers/create.blade.php`

### ⚠️ Field Name Mismatch

| # | Form `name=""` | DB Column Name |
|---|---------------|---------------|
| 1 | `user_id` | `approver_user_id` |

### ⚠️ ENUM Value Mismatch (`approver_type` dropdown)

| Form Value | DB ENUM Value | समस्या |
|-----------|--------------|--------|
| `DEPARTMENT` | `DEPARTMENT_HEAD` | ❌ Wrong value — DB reject करेगा |
| (missing) | `REPORTING_TO` | ❌ Option ही नहीं है dropdown में |

---

## 11. Holidays ✅
सब fields covered — कोई missing नहीं।

## 12. Shifts ✅
सब fields covered। **Suggestion:** `working_hours` auto-calculate करो: `(end_time − start_time) − break/60`

## 13. Shift Assignments ✅
सब fields covered। `active_flag` auto-generated है।

---

## 14A. Staff Attendance Types (Master)
**Table:** `sch_staff_attendance_types` | **View:** `employee/attendance-type/create.blade.php`

### ✅ Form में मौजूद Fields
`code`, `name`, `display_order`, `is_present`, `is_active`

### ❌ Missing Fields (7 fields!)

| # | Column Name | Type | क्या करता है (Hindi) | CRUD में क्यों ज़रूरी |
|---|-------------|------|---------------------|----------------------|
| 1 | `category` | ENUM('Attendance','Leave','Holiday','Other') | Type को **group** करता है (reports के लिए) | Reports/filters में grouping काम नहीं करेगी |
| 2 | `can_be_half_day` | TINYINT(1) | क्या यह type **Half Day** mark करने देता है | Half-day logic इस flag पर depend करता है |
| 3 | `affects_payroll` | TINYINT(1) | **Payroll calculation** में count होगा या नहीं | Holiday type payroll exclude करना हो तो यह flag ज़रूरी |
| 4 | `payroll_percentage` | DECIMAL(5,2) | Daily pay का **कितना %** मिलेगा (100=full, 50=half, 0=none) | Half Day → 50%, Absent → 0% — payroll engine को ज़रूरी |
| 5 | `requires_approval` | TINYINT(1) | Supervisor approval **ज़रूरी है या नहीं** इस status पर | Absent/Late पर approval enforce करना हो तो |
| 6 | `color_hex` | VARCHAR(7) | Calendar/UI में **रंग** दिखाना (#FF5733) | Dashboard में status-wise color coding |
| 7 | `icon_class` | VARCHAR(50) | CSS icon class (`fas fa-check`, `fas fa-times`) | UI buttons में icon show करना |

> **DDL Line 25-48:** `sch_staff_attendance_types` — इसमें `is_system` field भी है (built-in types को delete/modify से बचाता है) जो form में नहीं है लेकिन backend default handle कर सकता है।

### ⚡ Calculations (जब इस form का use होगा)

| # | Calculation | Formula | कहाँ Execute |
|---|------------|---------|-------------|
| 1 | Payroll Deduction | `day_pay = daily_salary × payroll_percentage / 100` | ⚙️ Payroll Service |
| 2 | Half Day Auto-Mark | `if attendance_type.can_be_half_day AND hours < threshold → Half Day` | ⏰ Day-close Engine |
| 3 | Approval Routing | `if attendance_type.requires_approval → create approval request` | ⚙️ Attendance Store Controller |

---

## 14B. Employee Attendance (Bulk Marking Dashboard)
**Table:** `sch_employee_attendance` | **View:** `employee/employee_attendance/index.blade.php`

यह **bulk attendance form** है — सारे employees की list दिखती है, radio buttons से status select करके "Save Attendance" press करते हैं।

### ✅ Form Submit में भेजे जाने वाले Fields
`attendance_date`, `manual_check_in`, `manual_check_out`, `attendance[emp_id][status]` (status_type_id), `attendance[emp_id][check_in_time]`, `attendance[emp_id][check_out_time]`, `attendance[emp_id][remarks]`, `attendance[emp_id][leave_application_id]`

### ❌ Missing Fields (DB Table vs Form)

| # | Column Name | Type | क्या करता है (Hindi) | CRUD में क्यों ज़रूरी |
|---|-------------|------|---------------------|----------------------|
| 1 | `shift_id` | INT FK | उस दिन **कौन-सी shift** applicable थी | Late/early/half-day calculate करने के लिए shift चाहिए |
| 2 | `attendance_source` | ENUM | Attendance कहाँ से आई (Biometric/Manual/QR/App) | Audit trail — Manual vs Biometric पता चलना चाहिए |
| 3 | `device_id` | VARCHAR(100) | Biometric/RFID terminal ID | Multi-device environments में tracking |
| 4 | `check_in_lat/lng` | DECIMAL(10,7) | Check-in **GPS location** | Geo-fenced apps — school premises verify |
| 5 | `check_out_lat/lng` | DECIMAL(10,7) | Check-out **GPS location** | Same as above |
| 6 | `working_hours` | DECIMAL(5,2) | कुल **net working hours** | Day-close engine calculate करेगा |
| 7 | `late_minutes` | SMALLINT | **कितने minutes late** आया | Grace period check |
| 8 | `early_minutes` | SMALLINT | **कितने minutes early** गया | Grace period check |
| 9 | `is_overtime` | TINYINT(1) | **Overtime** किया या नहीं | Payroll OT calculation |
| 10 | `overtime_hours` | DECIMAL(4,2) | कितने **OT hours** | Payroll OT payment |
| 11 | `is_holiday` | TINYINT(1) | क्या वह दिन **holiday** था | Holiday calendar से denormalize |
| 12 | `is_weekend` | TINYINT(1) | क्या **weekend** था | Calendar logic |
| 13 | `marked_by` | INT FK | **किसने** attendance mark की | Audit — `auth()->id()` backend में set |
| 14 | `auto_marked` | TINYINT(1) | System ने auto-mark किया या Manual | Biometric vs Manual distinction |

> **नोट:** Fields 1-12 ज़्यादातर **day-close engine** (⏰ Scheduler) calculate करता है, form से नहीं भरे जाते। लेकिन `shift_id`, `attendance_source`, `marked_by` controller में set होने चाहिए।

### ⚡ Calculations (Day-close Engine + Store Controller)

| # | Calculation | Formula | कहाँ Execute | Example (Hindi) |
|---|------------|---------|-------------|-----------------|
| 1 | Shift Lookup | Employee → active shift_assignment → shift_id | ⚙️ Store Controller | Teacher को Morning shift → shift_id=1 |
| 2 | Check-in | `MIN(punch_at WHERE type='In')` | ⏰ Nightly Engine | 3 punches: 8:05,12:30,13:00 → check_in=8:05 |
| 3 | Check-out | `MAX(punch_at WHERE type='Out')` | ⏰ Nightly Engine | Out: 12:00,17:30 → check_out=17:30 |
| 4 | Working Hours | `(check_out − check_in) − break/60` | ⏰ Nightly Engine | 17:30−8:05=9.42hrs − 0.5hr = 8.92hrs |
| 5 | Late Minutes | `MAX(0, check_in − shift.start − grace_late)` | ⏰ Nightly Engine | Shift 8:00, grace=10, in 8:25 → late=15min |
| 6 | Early Minutes | `MAX(0, shift.end − grace_early − check_out)` | ⏰ Nightly Engine | Shift end 17:00, grace=10, out 16:30 → early=20min |
| 7 | Half Day | `if present_min < half_day_threshold_minutes` | ⏰ Nightly Engine | 180min < 240min → Half Day |
| 8 | Overtime | `MAX(0, working_hours − profile.work_hours_daily)` | ⏰ Nightly Engine | Worked 10hrs, daily=8 → OT=2hrs |
| 9 | Holiday Check | `EXISTS(sch_holidays WHERE date=attendance_date)` | ⏰ Nightly Engine | 15-Aug → Holiday |
| 10 | Weekend Check | `DAYOFWEEK(date) IN (1,7)` | ⏰ Nightly Engine | Sunday → Weekend |
| 11 | Leave Check | `EXISTS(leave_applications WHERE from<=date AND to>=date AND status='Approved')` | ⏰ Nightly Engine | Approved leave exists → On Leave |

**Status Decision Logic:**
```
IF holiday(date)             → 'Holiday', is_holiday=1
ELIF weekend(date)           → 'Weekend', is_weekend=1
ELIF approved_leave(date)    → 'On Leave', leave_application_id=X
ELIF total_punches = 0       → 'Absent'
ELIF present_min < threshold → 'Half Day'
ELIF late_minutes > 0        → 'Late'
ELSE                         → 'Present'
```

---

## 14C. Attendance Punches (Read-only Dashboard)
**Table:** `sch_employee_attendance_punches` | **View:** `employee/employee_attendance/punches.blade.php`

यह **read-only listing** है — punches सिर्फ दिखाई जाती हैं, form से create नहीं होती (Biometric/QR/Scanner से आती हैं)।

### ✅ Dashboard में दिखाए जाने वाले Fields
`employee` (name), `punch_at`, `punch_type`, `attendance_source`, `device_id`, `latitude/longitude`, `is_invalid`

### ❌ Missing Display Fields (DDL में हैं, UI में नहीं दिखते)

| # | Column Name | Type | क्या करता है (Hindi) | दिखाना क्यों ज़रूरी |
|---|-------------|------|---------------------|---------------------|
| 1 | `attendance_id` | INT FK | किस **attendance record** से linked है | Punch → Daily summary mapping देखना |
| 2 | `device_location` | VARCHAR(150) | Device का **physical location name** | "Main Gate", "Back Gate" — कहाँ से punch हुई |
| 3 | `ip_address` | VARCHAR(45) | Punch करने वाले की **IP** | WebCheckIn fraud detection |
| 4 | `user_agent` | VARCHAR(255) | **Browser/App** info | Mobile vs Desktop identify |
| 5 | `is_within_geofence` | TINYINT(1) | **Geo-fence** के अंदर था या बाहर | Location fraud — school premises check |
| 6 | `is_processed` | TINYINT(1) | Day-close engine ने **process** किया या नहीं | Unprocessed punches → cron stuck indicator |
| 7 | `invalidation_reason` | VARCHAR(255) | Invalid mark **क्यों** हुआ | Admin को reason दिखाना |
| 8 | `raw_payload` | JSON | Vendor device का **full data** | Debugging/forensic |

### ⚠️ ENUM Mismatch (punch_type filter dropdown)

| Form Filter Values | DB ENUM Values | Missing |
|-------------------|---------------|---------|
| `In`, `Out`, `Break_In`, `Break_Out` | `In`, `Out`, `Break_Out`, `Break_In`, `Tour_Out`, `Tour_In`, `Unknown` | ❌ `Tour_Out`, `Tour_In`, `Unknown` missing |

### ⚡ Calculations (Punch Aggregation — Nightly Engine)

| # | Calculation | Formula | कहाँ Execute |
|---|------------|---------|-------------|
| 1 | Total Punches | `COUNT(*) WHERE employee_id=X AND DATE(punch_at)=Y` | ⏰ Nightly |
| 2 | Check-in | `MIN(punch_at WHERE punch_type='In')` | ⏰ Nightly |
| 3 | Check-out | `MAX(punch_at WHERE punch_type='Out')` | ⏰ Nightly |
| 4 | Break Duration | `SUM(Break_In_time − Break_Out_time)` | ⏰ Nightly |
| 5 | Geofence Validate | `distance(punch.lat/lng, school.lat/lng) <= geofence_radius` | ⚙️ Punch Store |
| 6 | Duplicate Detect | `if same employee, same punch_type within 1 min → is_invalid=1` | ⚙️ Punch Store |
| 7 | Mark Processed | `UPDATE SET is_processed=1, attendance_id=X` | ⏰ Nightly |

---

## 14D. Attendance Corrections (Approve/Reject Dashboard)
**Table:** `sch_employee_attendance_corrections` | **View:** `employee/employee_attendance/corrections.blade.php`

यह **listing + approve/reject modal** dashboard है — employee correction request करता है, manager approve/reject करता है।

### ✅ Dashboard में दिखाए जाने वाले Fields
`employee`, `attendance.date`, `correction_type`, `requested_check_in`, `requested_check_out`, `requested_status`, `reason`, `status`, `reviewed_by` (as `approvedBy`)

### ❌ Missing Fields

| # | Column Name | Type | क्या करता है (Hindi) | CRUD में क्यों ज़रूरी |
|---|-------------|------|---------------------|----------------------|
| 1 | `supporting_doc_media_id` | INT FK | Employee ने **proof document** upload किया | Doctor certificate, tour order — verify करने के लिए |
| 2 | `review_remarks` | VARCHAR(500) | Manager के **approval/rejection remarks** | Approve/Reject modal में है, लेकिन listing में नहीं दिखता |
| 3 | `reviewed_at` | TIMESTAMP | **कब review** किया गया | SLA tracking — कितने time में respond किया |
| 4 | `applied_at` | TIMESTAMP | Correction **attendance record में कब apply** हुई | Audit — approve ≠ apply (cron may delay) |
| 5 | `created_by` | INT FK | **किसने** correction request create की | Audit trail |

### ⚠️ Approve Controller में Missing Logic

Approve modal सिर्फ `review_remarks` लेता है, लेकिन approve होने पर **attendance record update** logic missing:

```php
// Approve Controller में ज़रूरी logic:
$correction = EmployeeAttendanceCorrection::find($id);
$correction->update([
    'status' => 'Approved',
    'reviewed_by' => auth()->id(),
    'reviewed_at' => now(),
    'review_remarks' => $request->review_remarks,
]);

// ✅ Attendance record भी update करो:
$attendance = $correction->attendance;
if ($correction->requested_check_in) $attendance->check_in_time = $correction->requested_check_in;
if ($correction->requested_check_out) $attendance->check_out_time = $correction->requested_check_out;
if ($correction->requested_status) $attendance->status = $correction->requested_status;
$attendance->save();

$correction->update(['applied_at' => now()]); // ← mark applied
```

### ⚡ Calculations (Correction Apply — Controller)

| # | Calculation | Formula | कहाँ Execute |
|---|------------|---------|-------------|
| 1 | Re-calc Working Hours | `(new_check_out − new_check_in) − break/60` | ⚙️ Approve Controller |
| 2 | Re-calc Late Minutes | `MAX(0, new_check_in − shift.start − grace)` | ⚙️ Approve Controller |
| 3 | Re-calc Early Minutes | `MAX(0, shift.end − grace − new_check_out)` | ⚙️ Approve Controller |
| 4 | Re-calc Half Day | `if new_present_min < threshold → Half Day` | ⚙️ Approve Controller |
| 5 | Re-calc Overtime | `MAX(0, new_working_hours − daily_limit)` | ⚙️ Approve Controller |

---

## 📊 Summary — कुल Missing Items (Updated)

| CRUD Section | Missing Fields | Name Mismatches | Calculations | Bugs |
|-------------|:-:|:-:|:-:|:-:|
| Staff Leave Types | 1 | 0 | 0 | 0 |
| **Staff Leave Config** | **7** | 0 | **5** | 0 |
| Leave Applications | 4 | 0 | 4 | 0 |
| Leave Approvals | 2 | 0 | 1 | 0 |
| Leave Docs | 1 | 0 | 0 | 0 |
| Leave Remarks | 4 | 0 | 0 | 0 |
| Leave Balance | 0 | 0 | 5 | 0 |
| **Approval Policies** | 0 | **4** | 0 | **1** |
| Policy Levels | 0 | 0 | 0 | 0 |
| **Level Approvers** | 0 | **1+ENUM** | 0 | 0 |
| Holidays | 0 | 0 | 0 | 0 |
| Shifts | 0 | 0 | 1 | 0 |
| Shift Assignments | 0 | 0 | 0 | 0 |
| **14A: Staff Attn Types** | **7** | 0 | **3** | 0 |
| **14B: Daily Attendance** | **14** | 0 | **11** | 0 |
| **14C: Punches** | **8** | **ENUM** | **7** | 0 |
| **14D: Corrections** | **5** | 0 | **5** | 0 |
| **TOTAL** | **53** | **6+** | **47** | **1** |

---

## 🚨 Priority Action Items

### P0 — तुरंत ठीक करो (INSERT Fail / Data Loss)
1. **Staff Leave Config** — 7 fields missing (priority, probation, encashment, carry-forward controls)
2. **Leave Applications** — `applied_by` NOT NULL → INSERT fail
3. **Leave Docs** — `uploaded_by` NOT NULL → INSERT fail
4. **Leave Remarks** — `remarked_by` NOT NULL → INSERT fail
5. **Approval Policies** — HTML duplicate closing tags → broken form

### P1 — जल्दी ठीक करो (Wrong Data)
6. **Approval Policies** — 4 field name mismatches (`role_id` ≠ `applies_to_role_id`)
7. **Level Approvers** — `user_id` ≠ `approver_user_id` + ENUM mismatch (`DEPARTMENT` ≠ `DEPARTMENT_HEAD`)
8. **Staff Leave Types** — `requires_approval` toggle missing

### P2 — UX Improvement
9. **Shifts** — `working_hours` auto-calculate
10. **Leave Applications** — `total_days` auto-calculate from date range

---

## 🔢 Appendix — Detailed Calculation Reference (कहाँ और कैसे execute होगी)

> DDL: `Employee_setup_ddl_v5.sql` | Dictionary: `DataDictionary_EmpSetup.md (v5)` से verified

### Legend
- **🖥️ Form JS** = JavaScript में CRUD form पर real-time calculate
- **⚙️ Controller** = Laravel Controller/Service में server-side
- **⏰ Scheduler** = Cron Job / Nightly Engine
- **💾 DB Stored** = MySQL STORED GENERATED column (auto)

---

### A. Staff Leave Config — Calculations (7 missing fields से जुड़ी)

| # | Calculation | Formula | कहाँ Execute | Real-world Example (Hindi) |
|---|------------|---------|-------------|---------------------------|
| 1 | Monthly Accrual | `monthly = annual_entitlement / 12` | ⏰ Monthly Cron | अगर `annual_entitlement=12` तो हर महीने 1 leave credit होगी |
| 2 | Quarterly Accrual | `quarterly = annual_entitlement / 4` | ⏰ Quarterly Cron | `annual=12` → हर तिमाही 3 leaves |
| 3 | Accrual Start | `start_date = joining_date + accrual_start_offset_months` | ⚙️ Controller | Teacher 1-Jan-2026 join, offset=3 → accrual April-2026 से शुरू |
| 4 | Carry Forward | `cf = MIN(remaining, max_carry_forward)` | ⏰ Year-rollover Job | बची 8 leaves, max_cf=5 → सिर्फ 5 carry होंगी |
| 5 | F&F Encashment | `days = MIN(balance, max_encashable_days)` | ⚙️ Separation Controller | Resign पर 15 balance, max_encash=10 → 10 दिन cash |
| 6 | Probation Pro-rata | `entitlement = annual × probation_months / 12` | ⚙️ Controller (onboard) | 6 month probation, annual=12 → 6 leaves मिलेंगी |
| 7 | Policy Match | Filter rows → smallest `priority` wins | ⚙️ Service | Role=Teacher, Dept=Science → priority 5 row जीतेगी over priority 10 |

**⚠️ अगर ये 7 fields CRUD में नहीं हैं तो:**
- Probation employee को पूरी leave मिलेगी (गलत)
- Year-end carry forward unlimited होगा (गलत)
- F&F में encashment cap नहीं लगेगा (पैसों का नुकसान)

---

### B. Leave Application — Calculations

| # | Calculation | Formula | कहाँ Execute | Example |
|---|------------|---------|-------------|---------|
| 1 | Total Days Auto | `working_days(from, to) − holidays − weekends` | ⚙️ Store Controller | 1-May से 7-May (Sat-Sun छोड़ो, 1 holiday) = 4 दिन |
| 2 | Half Day | `if is_half_day then total_days = total_days / 2` | ⚙️ Store Controller | 1 working day + half_day = 0.5 |
| 3 | Advance Notice | `(from_date − today) >= leave_type.min_advance_notice_days` | ⚙️ Validation | CL min_notice=1, आज apply कल के लिए → ✅ OK |
| 4 | Max Days Check | `total_days <= leave_type.max_days_per_application` | ⚙️ Validation | ML max=90, apply 91 days → ❌ Reject |
| 5 | Max Consecutive | `consecutive <= leave_type.max_consecutive_days` | ⚙️ Validation | SL max_consecutive=3, apply 4 → ❌ Reject |
| 6 | Doc Required | `if total_days > leave_type.min_doc_required_days AND requires_doc` | ⚙️ Validation | SL > 2 days → document upload mandatory |
| 7 | Balance Check | `available_balance >= total_days` | ⚙️ Validation | Balance 3, apply 5 → ❌ Insufficient |
| 8 | Pending Update | `balance.total_pending += total_days` | ⚙️ Store Controller | Submit होते ही pending बढ़ जाएगा |
| 9 | Balance Debit | `balance.total_used += approved_days` | ⚙️ Approve Controller | Approve होने पर used बढ़ेगा |
| 10 | Emergency Bypass | `if is_emergency then skip min_advance_notice_days` | ⚙️ Validation | Emergency flag ON → notice check skip |

**`applied_by` (NOT NULL) → Controller में ज़रूरी:**
```php
// Store Controller में:
$data['applied_by'] = auth()->id();  // ← यह line ज़रूरी है!
```

---

### C. Leave Balance — Calculations

| # | Calculation | Formula | कहाँ Execute | Example |
|---|------------|---------|-------------|---------|
| 1 | Available Balance | `opening + carry_forward − total_used` | 💾 DB Stored Column | opening=12, cf=3, used=5 → available=10 |
| 2 | Year Seed | `opening = config.annual_entitlement` | ⏰ Year-rollover Job | April-1 पर सब employees को entitlement seed |
| 3 | Carry Forward | `cf = MIN(prior_remaining, config.max_carry_forward)` | ⏰ Year-rollover Job | Prior year 8 बचे, max_cf=5 → cf=5 |
| 4 | Manual Adjust | `available affected by manual_adjustment` | ⚙️ HR Admin Controller | HR ने +2 adjust किया → available बढ़ गया |

> **DDL Line 882 confirm:** `available_balance DECIMAL(5,2) GENERATED ALWAYS AS (opening_balance + carry_forward - total_used) STORED`

---

### D. Leave Approvals — Calculations

| # | Calculation | Formula | कहाँ Execute | Example |
|---|------------|---------|-------------|---------|
| 1 | Escalation Deadline | `deadline = created_at + level.escalation_after_hours` | ⚙️ Store Controller | Level 1 created 10AM, escalation=24hrs → deadline 10AM next day |
| 2 | Auto-Escalate | `if now() > deadline then action='Escalated'` | ⏰ Hourly Cron | Deadline बीत गया → auto escalate to Level 2 |

---

### E. Attendance Day-Close Engine — Calculations

| # | Calculation | Formula | कहाँ Execute | Example |
|---|------------|---------|-------------|---------|
| 1 | Check-in | `MIN(punch_at WHERE type='In')` | ⏰ Nightly Engine | 3 punches: 8:05, 12:30, 13:00 → check_in=8:05 |
| 2 | Check-out | `MAX(punch_at WHERE type='Out')` | ⏰ Nightly Engine | Out punches: 12:00, 17:30 → check_out=17:30 |
| 3 | Working Hours | `(check_out − check_in) − break/60` | ⏰ Nightly Engine | 17:30−8:05=9.42hrs − 0.5hr break = 8.92hrs |
| 4 | Late Minutes | `MAX(0, check_in − shift.start − grace_late)` | ⏰ Nightly Engine | Shift 8:00, grace=10min, check_in 8:25 → late=15min |
| 5 | Early Minutes | `MAX(0, shift.end − grace_early − check_out)` | ⏰ Nightly Engine | Shift end 17:00, grace=10, out 16:30 → early=20min |
| 6 | Half Day | `if present_minutes < half_day_threshold` | ⏰ Nightly Engine | Present 3hrs (180min) < threshold 240min → Half Day |
| 7 | Overtime | `MAX(0, working_hours − profile.work_hours_daily)` | ⏰ Nightly Engine | Worked 10hrs, daily=8 → OT=2hrs |
| 8 | Payroll Amount | `daily_pay × attendance_type.payroll_percentage / 100` | ⚙️ Payroll Engine | Half Day → 50% → ₹500 daily × 50% = ₹250 |

**Status Decision Logic (Nightly Engine):**
```
IF holiday(date)             → status = 'Holiday'
ELIF weekend(date)           → status = 'Weekend'
ELIF approved_leave(date)    → status = 'On Leave'
ELIF punches = 0             → status = 'Absent'
ELIF present_min < threshold → status = 'Half Day'
ELIF late_minutes > 0        → status = 'Late'
ELSE                         → status = 'Present'
```

---

### F. Shift — Calculation (Form-level सुधार)

| # | Calculation | Formula | कहाँ Execute | Example |
|---|------------|---------|-------------|---------|
| 1 | Working Hours Auto | `(end_time − start_time) − break_minutes/60` | 🖥️ Form JS (onChange) | Start 8:00, End 16:00, Break 30min → 7.5hrs |

**Suggested JS for create form:**
```javascript
// shifts/create.blade.php में add करो:
document.querySelectorAll('[name=start_time],[name=end_time],[name=break_duration_minutes]')
  .forEach(el => el.addEventListener('change', () => {
    const s = document.querySelector('[name=start_time]').value;
    const e = document.querySelector('[name=end_time]').value;
    const b = document.querySelector('[name=break_duration_minutes]').value || 0;
    if (s && e) {
      const diff = (new Date('1970-01-01T'+e) - new Date('1970-01-01T'+s)) / 3600000;
      document.querySelector('[name=working_hours]').value = (diff - b/60).toFixed(2);
    }
  }));
```

---

### G. Approval Policies — Name Mapping Fix (Controller में)

```php
// approval-policies StoreController में mapping:
$policy = SchLeaveApprovalPolicy::create([
    'name'                      => $request->name,
    'applies_to_role_id'        => $request->role_id,         // ⚠️ form=role_id, DB=applies_to_role_id
    'applies_to_department_id'  => $request->department_id,    // ⚠️ mismatch
    'applies_to_designation_id' => $request->designation_id,   // ⚠️ mismatch
    'applies_to_leave_type_id'  => $request->leave_type_id,    // ⚠️ mismatch
    'priority'                  => $request->priority,
]);
```

**बेहतर fix:** Form `name=""` attributes को DB column names से match करो:
```html
<!-- FIX: role_id → applies_to_role_id -->
<select name="applies_to_role_id" ...>
```

---

### H. Level Approvers — ENUM Fix

```html
<!-- CURRENT (WRONG): -->
<option value="DEPARTMENT">Department</option>
<!-- MISSING option -->

<!-- FIX: -->
<option value="DEPARTMENT_HEAD">Department Head</option>  <!-- DB ENUM value -->
<option value="REPORTING_TO">Reporting Manager</option>   <!-- Missing option -->
```

**DDL Line 685 confirm:** `ENUM('USER','ROLE','DESIGNATION','DEPARTMENT_HEAD','REPORTING_TO')`

---

> **Source:** `Employee_setup_ddl_v5.sql` (Lines 25-1133) + `DataDictionary_EmpSetup.md (v5)` vs actual blade files — 2026-05-08
> **DDL verified:** सारी calculations DDL SQL constraints और comments से cross-verified हैं।

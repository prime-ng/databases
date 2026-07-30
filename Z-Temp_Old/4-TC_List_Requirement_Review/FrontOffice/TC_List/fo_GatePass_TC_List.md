# fo_GatePass — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Gate Passes (Leave Campus + Approval Workflow)
**DB scope:** TENANT-side (`fof_gate_passes`) · **Test style:** Browser Dusk
**Primary table:** `fof_gate_passes` · **Module URL prefix:** `/front-office/visitor-management?tab=gate-passes`
**Test file:** `fo_GatePass_TestCas.php`
**Tab:** Gate Passes (third tab of Visitor Management)

Controller: `FofMenuController::visitorManagement()`, `GatePassController`
Request: `IssueGatePassRequest`
Policy: `GatePassPolicy`

Routes: gate-passes CRUD + approve/reject/exit/return + toggleStatus + trash/restore/forceDelete

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_gate_passes`: id, pass_number, person_type (Student/Staff), student_id (FK), staff_user_id (FK), purpose (enum), purpose_details, exit_time, expected_return_time, actual_return_time, parent_notified, status (enum: Pending_Approval/Approved/Exited/Returned/Rejected/Cancelled), approved_by (FK), approved_at, rejection_reason, is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |
| BC-DB-02 | Model: SoftDeletes, casts: exit_time, expected_return_time, actual_return_time, approved_at→datetime, parent_notified→boolean, is_active→boolean. Scopes: active(), pending(), activePass(). Relations: student() (withTrashed), staff(), approvedBy() | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `person_type` required in:Student,Staff | FR |
| BC-VAL-02 | `student_id` required_if:Student exists:std_students,id | FR |
| BC-VAL-03 | `staff_user_id` required_if:Staff exists:sys_users,id | FR |
| BC-VAL-04 | `purpose` required in:Medical,Personal,Official,Sports,Family_Emergency,Other | FR |
| BC-VAL-05 | `expected_return_time` nullable date | FR |
| BC-VAL-06 | BR-FOF-004: No duplicate active pass per student (POST) | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.gate-pass.viewAny` → `frontoffice.gate-pass.view` | Policy |
| BC-AUTH-02 | create/store gate `frontoffice.gate-pass.create` | Policy |
| BC-AUTH-03 | view/show gate `frontoffice.gate-pass.view` | Policy |
| BC-AUTH-04 | update/edit/toggle gate `frontoffice.gate-pass.create` (policy uses create for update) | Policy |
| BC-AUTH-05 | approve gate `frontoffice.gate-pass.approve` | View |
| BC-AUTH-06 | delete gate `frontoffice.gate-pass.create` (policy uses create for delete) | Policy |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Pending section: Pass No, Person Details, Purpose, Requested time, Active toggle, Action (Approve + Reject) | View |
| BC-BIZ-02 | Active section (Approved/Exited): Pass No, Person Details, Purpose, Exit Time, Exp. Return, Status badge, Active, Action | View |
| BC-BIZ-03 | History section (Returned/Rejected/Cancelled): Pass No, Person Details, Purpose, Date, Status, Active, Action | View |
| BC-BIZ-04 | Approve → status=Approved, approved_by+approved_at set | Ctrl |
| BC-BIZ-05 | Reject → modal with rejection_reason required → status=Rejected | Ctrl |
| BC-BIZ-06 | Exit → status=Exited | Ctrl |
| BC-BIZ-07 | Return → status=Returned, actual_return_time set | Ctrl |
| BC-BIZ-08 | Search across pass_number, purpose, person_type, student name, staff name | Ctrl |
| BC-BIZ-09 | Status filter: All / Active / Inactive | View |
| BC-BIZ-10 | One active pass per student → duplicate blocked (BR-FOF-004) | Val |
| BC-BIZ-11 | Empty states per section: "No active gate passes", "No history found" | View |
| BC-BIZ-12 | History paginated 15 per page (gp_page) | Ctrl |
| BC-BIZ-13 | Status toggle Ajax → JSON success | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FOFP-P10 | Positive | View | Pending section: Pass No, Person Details, Purpose, Requested time, Active, Approve/Reject buttons | Rendered | test_fo_gp_10 | Automated |
| TC-FOFP-P11 | Positive | View | Active section: Pass No, Person, Purpose, Exit Time, Exp Return, Status badge, Mark Exited/Returned | Rendered | test_fo_gp_11 | Automated |
| TC-FOFP-P12 | Positive | View | History section: paginated list of completed passes | Section | test_fo_gp_12 | Automated |
| TC-FOFP-P13 | Positive | Ctrl | Approve pending pass → status=Approved, approved_by set | Approved | test_fo_gp_13 | Automated |
| TC-FOFP-P14 | Positive | Ctrl | Reject with reason → status=Rejected | Rejected | test_fo_gp_14 | Automated |
| TC-FOFP-P15 | Positive | Ctrl | Mark Exited (Approved→Exited) | Exited | test_fo_gp_15 | Automated |
| TC-FOFP-P16 | Positive | Ctrl | Mark Returned (Exited→Returned) | Returned | test_fo_gp_16 | Automated |
| TC-FOFP-P17 | Positive | Val | Create gate pass for student → stored | Created | test_fo_gp_17 | Automated |
| TC-FOFP-N18 | Negative | Val | Duplicate active pass for same student → blocked (BR-FOF-004) | Blocked | test_fo_gp_18 | Automated |
| TC-FOFP-N19 | Negative | Val | Reject without reason → textarea required validation | Error | test_fo_gp_19 | Automated |
| TC-FOFP-P20 | Positive | View | Empty state for sections when no data | Empty | test_fo_gp_20 | Automated |
| TC-FOFP-N21 | Negative | Auth | Without approve permission → 403 | 403 | test_fo_gp_21 | Automated |
<｜｜DSML｜｜parameter name="filePath" string="true">C:\laragon\www\PG\prime_testing\Doc_Analysis\4-TC_List_Requirement_Review\FrontOffice\TC_Lists\fo_GatePass_TC_List.md
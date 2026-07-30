# fo_EarlyDeparture — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Early Departures (Student Pre-Dismissal + Attendance Sync)
**DB scope:** TENANT-side (`fof_early_departures`) · **Test style:** Browser Dusk
**Primary table:** `fof_early_departures` · **Module URL prefix:** `/front-office/visitor-management?tab=early-departures`
**Test file:** `fo_EarlyDeparture_TestCas.php`
**Tab:** Early Departures (fourth tab of Visitor Management)

Controller: `FofMenuController::visitorManagement()`, `EarlyDepartureController`
Request: `EarlyDepartureRequest`
Policy: `EarlyDeparturePolicy`

Routes: early-departures CRUD + toggleStatus + trash/restore/forceDelete

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_early_departures`: id, departure_number, student_id (FK), departure_time (datetime), reason (enum: Medical/Family_Emergency/Event/Bereavement/Other), reason_details, collecting_person_name, collecting_person_relation (enum: Father/Mother/Guardian/Sibling/Other), collecting_id_proof_type, collecting_id_proof_number, parent_authorized (boolean), att_sync_status (enum: Pending/Synced/Failed), att_synced_at, notes, is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |
| BC-DB-02 | Model: SoftDeletes, casts: departure_time→datetime, att_synced_at→datetime, parent_authorized→boolean, is_active→boolean. Scopes: active(), pendingSync(). Relations: student() (withTrashed) | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `student_id` required exists:std_students,id | FR |
| BC-VAL-02 | `departure_time` required date before_or_equal:now | FR |
| BC-VAL-03 | `reason` required in:Medical,Family_Emergency,Event,Bereavement,Other | FR |
| BC-VAL-04 | `collecting_person_name` required string max:100 | FR |
| BC-VAL-05 | `collecting_person_relation` required in:Father,Mother,Guardian,Sibling,Other | FR |
| BC-VAL-06 | `collecting_id_proof_type` nullable in:Aadhar,Driving_License,Passport,Other | FR |
| BC-VAL-07 | `parent_authorized` boolean (prepared) | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.early-departure.viewAny` → `frontoffice.early-departure.view` | Policy |
| BC-AUTH-02 | create/store gate `frontoffice.early-departure.create` | Policy |
| BC-AUTH-03 | view/show gate `frontoffice.early-departure.view` | Policy |
| BC-AUTH-04 | update/toggle gate `frontoffice.early-departure.update` | Policy |
| BC-AUTH-05 | delete gate `frontoffice.early-departure.delete` | Policy |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Table: Departure No, Student, Departure Time (h:i A), Reason, Collected By (name + relation), Sync Status, Active, Action | View |
| BC-BIZ-02 | Sync badges: Synced (green-success), Failed (red-danger), Pending Sync (yellow-warning) | View |
| BC-BIZ-03 | Synced records show att_synced_at timestamp below badge | View |
| BC-BIZ-04 | Search across departure_number, reason, collector name, student name | Ctrl |
| BC-BIZ-05 | Status filter: All / Active / Inactive | View |
| BC-BIZ-06 | Paginated 20 per page (dep_page) | Ctrl |
| BC-BIZ-07 | Status toggle Ajax → JSON success | Ctrl |
| BC-BIZ-08 | Future departure_time blocked by before_or_equal:now | Val |
| BC-BIZ-09 | Empty state: "No early departures today" | View |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FOED-P10 | Positive | View | Table: Departure No, Student, Departure Time, Reason, Collected By, Sync Status, Active, Action | Rendered | test_fo_ed_10 | Automated |
| TC-FOED-P11 | Positive | View | Sync badges: Synced (green), Failed (red), Pending (yellow) | Badges | test_fo_ed_11 | Automated |
| TC-FOED-P12 | Positive | View | Synced record shows synced_at timestamp | Timestamp | test_fo_ed_12 | Automated |
| TC-FOED-P13 | Positive | Ctrl | Create departure → stored, redirect | Created | test_fo_ed_13 | Automated |
| TC-FOED-P14 | Positive | Ctrl | Update departure → updated | Updated | test_fo_ed_14 | Automated |
| TC-FOED-P15 | Positive | Ctrl | Soft delete → trashed | Deleted | test_fo_ed_15 | Automated |
| TC-FOED-P16 | Positive | View | Paginated 20 per page | Paginated | test_fo_ed_16 | Automated |
| TC-FOED-P17 | Positive | View | Empty state "No early departures today" | Empty | test_fo_ed_17 | Automated |
| TC-FOED-N18 | Negative | Val | Future departure_time → before_or_equal error | Error | test_fo_ed_18 | Automated |
| TC-FOED-N19 | Negative | Val | Invalid relation → in:Father,Mother,Guardian,Sibling,Other | Error | test_fo_ed_19 | Automated |
| TC-FOED-N20 | Negative | Auth | Without update permission → 403 on edit | 403 | test_fo_ed_20 | Automated |
<｜｜DSML｜｜parameter name="filePath" string="true">C:\laragon\www\PG\prime_testing\Doc_Analysis\4-TC_List_Requirement_Review\FrontOffice\TC_Lists\fo_EarlyDeparture_TC_List.md
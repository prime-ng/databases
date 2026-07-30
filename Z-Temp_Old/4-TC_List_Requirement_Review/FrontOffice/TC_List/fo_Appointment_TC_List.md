# fo_Appointment — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Appointments (Visitor Scheduling + Status Workflow)
**DB scope:** TENANT-side (`fof_appointments`) · **Test style:** Browser Dusk
**Primary table:** `fof_appointments` · **Module URL prefix:** `/front-office/visitor-management?tab=appointments`
**Test file:** `fo_Appointment_TestCas.php`
**Tab:** Appointments (fifth tab of Visitor Management)

Controller: `FofMenuController::visitorManagement()`, `AppointmentController`
Request: `AppointmentRequest`
Policy: `AppointmentPolicy`

Routes: appointments CRUD + confirm/complete/cancel + toggleStatus + trash/restore/forceDelete

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_appointments`: id, appointment_number, appointment_type (enum dynamically read), with_user_id (FK→sys_users), visitor_name, visitor_mobile, visitor_email, purpose, appointment_date (date), start_time (time), end_time (time), status (enum: Scheduled/Confirmed/Completed/Cancelled/No_Show), confirmed_by (FK), confirmed_at, cancellation_reason, notes, is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |
| BC-DB-02 | Model: SoftDeletes, casts: appointment_date→date, start_time→datetime:H:i, end_time→datetime:H:i, confirmed_at→datetime, is_active→boolean. Scopes: active(), upcoming(). Relations: staff(), confirmedBy(). Static: appointmentTypeOptions(), normalizeAppointmentType() | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `appointment_type` required in: (DB enum values) | FR |
| BC-VAL-02 | `with_user_id` required integer exists:sys_users,id | FR |
| BC-VAL-03 | `visitor_name` required string max:100 | FR |
| BC-VAL-04 | `visitor_mobile` required string max:15 | FR |
| BC-VAL-05 | `visitor_email` nullable email max:100 | FR |
| BC-VAL-06 | `purpose` required string max:300 | FR |
| BC-VAL-07 | `appointment_date` required date after_or_equal:today (POST) / required date (PUT) | FR |
| BC-VAL-08 | `start_time` required | FR |
| BC-VAL-09 | `end_time` required after:start_time | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.appointment.viewAny` → `frontoffice.appointment.view` | Policy |
| BC-AUTH-02 | create/store gate `frontoffice.appointment.create` | Policy |
| BC-AUTH-03 | view/show gate `frontoffice.appointment.view` | Policy |
| BC-AUTH-04 | update gate `frontoffice.appointment.update` | Policy |
| BC-AUTH-05 | delete gate `frontoffice.appointment.delete` | Policy |
| BC-AUTH-06 | confirm gate `frontoffice.appointment.confirm` | View |
| BC-AUTH-07 | cancel gate `frontoffice.appointment.cancel` | View |
| BC-AUTH-08 | complete gate `frontoffice.appointment.complete` | View |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Upcoming section: Number, Visitor (name + mobile), Meeting With (staff), Type badge, Purpose, Date & Time, Status badge, Actions | View |
| BC-BIZ-02 | Past section: Number, Visitor, Type & Purpose, Date, Status badge, Actions (view/delete only) | View |
| BC-BIZ-03 | Scheduled → Confirm, Complete, Cancel buttons | View |
| BC-BIZ-04 | Confirmed → Complete, Cancel buttons | View |
| BC-BIZ-05 | Cancel uses SweetAlert confirmation | View |
| BC-BIZ-06 | Confirm → sets confirmed_by + confirmed_at, status=Confirmed | Ctrl |
| BC-BIZ-07 | Complete → status=Completed | Ctrl |
| BC-BIZ-08 | Cancel → status=Cancelled | Ctrl |
| BC-BIZ-09 | Create modal opens with visitor fields, staff select, type dropdown, date/time, purpose | View |
| BC-BIZ-10 | Validation errors shown inside modal; modal reopens automatically | View |
| BC-BIZ-11 | Legacy type mapping: Parent_Teacher_Meeting→Parent_Meeting | Model |
| BC-BIZ-12 | Search across appointment_number, visitor_name/mobile/email, type, purpose, status, staff name | Ctrl |
| BC-BIZ-13 | Status filter: All / Active / Inactive | View |
| BC-BIZ-14 | Past paginated 15 per page (apt_page) | Ctrl |
| BC-BIZ-15 | Empty states: "No upcoming appointments", "No past appointments found" | View |
| BC-BIZ-16 | Status toggle Ajax → JSON success | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FOAP-P10 | Positive | View | Upcoming section: Number, Visitor, Staff, Type, Purpose, Date&Time, Status, Actions | Rendered | test_fo_ap_10 | Automated |
| TC-FOAP-P11 | Positive | View | Past section: paginated with read-only actions | Section | test_fo_ap_11 | Automated |
| TC-FOAP-P12 | Positive | Ctrl | Confirm Scheduled → confirmed_by+confirmed_at set, status=Confirmed | Confirmed | test_fo_ap_12 | Automated |
| TC-FOAP-P13 | Positive | Ctrl | Complete Confirmed → status=Completed | Completed | test_fo_ap_13 | Automated |
| TC-FOAP-P14 | Positive | Ctrl | Cancel Scheduled → status=Cancelled, SweetAlert confirmed | Cancelled | test_fo_ap_14 | Automated |
| TC-FOAP-P15 | Positive | View | Create modal with all required fields | Modal | test_fo_ap_15 | Automated |
| TC-FOAP-P16 | Positive | View | Modal reopens on validation error with inline messages | Reopened | test_fo_ap_16 | Automated |
| TC-FOAP-P17 | Positive | Ctrl | Create appointment → stored, redirect | Created | test_fo_ap_17 | Automated |
| TC-FOAP-N18 | Negative | Val | end_time before start_time → after validation error | Error | test_fo_ap_18 | Automated |
| TC-FOAP-N19 | Negative | Val | Past appointment_date on create → after_or_equal:today error | Error | test_fo_ap_19 | Automated |
| TC-FOAP-P20 | Positive | View | Upcoming empty state "No upcoming appointments" | Empty | test_fo_ap_20 | Automated |
| TC-FOAP-P21 | Positive | Model | Legacy type mapping works (PTM→Parent_Meeting) | Mapped | test_fo_ap_21 | Automated |
| TC-FOAP-N22 | Negative | Auth | Without confirm permission → confirm button hidden | Hidden | test_fo_ap_22 | Automated |
<｜｜DSML｜｜parameter name="filePath" string="true">C:\laragon\www\PG\prime_testing\Doc_Analysis\4-TC_List_Requirement_Review\FrontOffice\TC_Lists\fo_Appointment_TC_List.md
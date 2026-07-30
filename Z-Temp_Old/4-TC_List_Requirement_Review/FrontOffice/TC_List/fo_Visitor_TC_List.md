# fo_Visitor — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Visitors (Check-In/Out + Pass Printing + Govt Visit Protection)
**DB scope:** TENANT-side (`fof_visitors`, `fof_visitor_purposes`) · **Test style:** Browser Dusk
**Primary table:** `fof_visitors` · **Module URL prefix:** `/front-office/visitor-management?tab=visitors`
**Test file:** `fo_Visitor_TestCas.php`
**Tab:** Visitors (default tab of Visitor Management)

Controller: `FofMenuController::visitorManagement()`, `VisitorController`
Request: `RegisterVisitorRequest`
Policy: `VisitorPolicy`

Routes: visitors CRUD + checkout, pass, toggleStatus, trash/restore/forceDelete

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_visitors`: id, pass_number, vsm_visitor_id, visitor_name, visitor_mobile, visitor_email, id_proof_type (enum), id_proof_number, address, organization, purpose_id (FK), person_to_meet, meet_user_id (FK), vehicle_number, accompanying_count, photo_media_id, in_time (datetime), out_time (datetime), status, notes, is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |
| BC-DB-02 | Model: SoftDeletes + HasMedia, casts: in_time→datetime, out_time→datetime, is_active→boolean, accompanying_count→integer. Scopes: active(), onCampus(). Relations: purpose() belongsTo | Model |
| BC-DB-03 | Photo stored via Spatie Media Library collection `visitor_photo` (singleFile) | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `visitor_name` required string max:100 | FR |
| BC-VAL-02 | `visitor_mobile` required string regex:/^[0-9]{10,15}$/ | FR |
| BC-VAL-03 | `visitor_email` nullable email max:100 | FR |
| BC-VAL-04 | `id_proof_type` nullable in:Aadhar,Driving_License,Passport,Voter_ID,PAN,Employee_ID,Other | FR |
| BC-VAL-05 | `purpose_id` required exists:fof_visitor_purposes,id | FR |
| BC-VAL-06 | `photo` nullable image mimes:jpeg,png,jpg,webp max:2048 | FR |
| BC-VAL-07 | `accompanying_count` integer min:0 max:20 | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab default active (tab=visitors) gate `frontoffice.visitor.view` | Ctrl |
| BC-AUTH-02 | create/store gate `frontoffice.visitor.create` | Policy |
| BC-AUTH-03 | view/show gate `frontoffice.visitor.view` | Policy |
| BC-AUTH-04 | update/edit gate `frontoffice.visitor.update` | Policy |
| BC-AUTH-05 | checkout gate `frontoffice.visitor.checkout` | View |
| BC-AUTH-06 | delete gate `frontoffice.visitor.delete` (+ govt check) | Policy |
| BC-AUTH-07 | Status column visibility gate `frontoffice.visitor.update` | View |
| BC-AUTH-08 | Action column visibility gate `frontoffice.visitor.view/update/delete` | View |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Table: Pass Number (badge), Visitor Details (name + mobile + org), Purpose, In Time (h:i A), Person to Meet, Status badge, Status toggle, Actions | View |
| BC-BIZ-02 | Status badges: "On Campus" (green-success), "Overstay" (red-danger), "Checked Out" (grey-secondary) | View |
| BC-BIZ-03 | Check In visitors: Check Out button + Print Pass button visible | View |
| BC-BIZ-04 | Check Out: PATCH → sets out_time, SweetAlert confirm | Ctrl |
| BC-BIZ-05 | Print Pass: opens popup window with pass view + auto-print | View |
| BC-BIZ-06 | Search across pass_number, name, mobile, org, person_to_meet, status, purpose name/code | Ctrl |
| BC-BIZ-07 | Status filter: All / Active / Inactive | View |
| BC-BIZ-08 | Paginated 20 per page (vis_page) | Ctrl |
| BC-BIZ-09 | Status toggle Ajax → JSON success | Ctrl |
| BC-BIZ-10 | Govt-linked visitor delete → 403 forbidden (BR-FOF-007) | Policy |
| BC-BIZ-11 | Empty state: "No visitors found" | View |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FOFR-P10 | Positive | View | Default tab=visitors loads with table | Default tab | test_fo_fr_10 | Automated |
| TC-FOFR-P11 | Positive | View | Table: Pass Number, Visitor Details, Purpose, In Time, Person to Meet, Status, Actions | Rendered | test_fo_fr_11 | Automated |
| TC-FOFR-P12 | Positive | View | Status badges: On Campus (green), Overstay (red), Checked Out (grey) | Badges | test_fo_fr_12 | Automated |
| TC-FOFR-P13 | Positive | View | In-campus visitors show Check Out + Print Pass buttons | Actions | test_fo_fr_13 | Automated |
| TC-FOFR-P14 | Positive | Ctrl | Check Out → sets out_time, redirect | Checked out | test_fo_fr_14 | Automated |
| TC-FOFR-P15 | Positive | Ctrl | Print Pass → window.open to pass view | Pass | test_fo_fr_15 | Automated |
| TC-FOFR-P16 | Positive | View | Search filters across multiple fields | Search | test_fo_fr_16 | Automated |
| TC-FOFR-P17 | Positive | View | Paginated 20 per page | Paginated | test_fo_fr_17 | Automated |
| TC-FOFR-P18 | Positive | View | Empty state "No visitors found" | Empty | test_fo_fr_18 | Automated |
| TC-FOFR-P19 | Positive | Ctrl | Create visitor with photo → stored + media uploaded | Created | test_fo_fr_19 | Automated |
| TC-FOFR-N20 | Negative | Auth | Delete govt-linked visitor → 403 | Blocked | test_fo_fr_20 | Automated |
| TC-FOFR-N21 | Negative | Val | Invalid mobile format → regex validation error | Error | test_fo_fr_21 | Automated |
<｜｜DSML｜｜parameter name="filePath" string="true">C:\laragon\www\PG\prime_testing\Doc_Analysis\4-TC_List_Requirement_Review\FrontOffice\TC_Lists\fo_Visitor_TC_List.md
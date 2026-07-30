# fo_VisitorPurpose — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Visitor Purposes (Predefined Visit Reasons + Govt Visit Protection)
**DB scope:** TENANT-side (`fof_visitor_purposes`) · **Test style:** Browser Dusk
**Primary table:** `fof_visitor_purposes` · **Module URL prefix:** `/front-office/visitor-management?tab=visitor-purposes`
**Test file:** `fo_VisitorPurpose_TestCas.php`
**Tab:** Visitor Purposes (first tab of Visitor Management)

Controller: `FofMenuController::visitorManagement()`, `VisitorPurposeController`
Request: `StoreVisitorPurposeRequest`
Policy: `VisitorPurposePolicy`
Routes (`fof.` prefix): visitor-purposes CRUD + toggle-status + trash/restore/forceDelete

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_visitor_purposes`: id, name (VARCHAR 100), code (VARCHAR 30 UNIQUE), is_government_visit (TINYINT 1), sort_order (TINYINT), is_active (TINYINT 1), created_by, updated_by, created_at, updated_at, deleted_at | Model |
| BC-DB-02 | Model: SoftDeletes, fillable 6 fields, casts: is_government_visit→boolean, is_active→boolean, sort_order→integer. Scopes: active(), ordered(). Relations: visitors() hasMany | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `name` required string max:100 | FR |
| BC-VAL-02 | `code` required string max:30 unique:fof_visitor_purposes (ignore current ID) | FR |
| BC-VAL-03 | `is_government_visit` nullable boolean | FR |
| BC-VAL-04 | `sort_order` nullable integer min:0 max:255 | FR |
| BC-VAL-05 | `is_active` nullable boolean | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.visitor-purpose.viewAny` | View |
| BC-AUTH-02 | create/store gate `frontoffice.visitor-purpose.create` | Policy |
| BC-AUTH-03 | view gate `frontoffice.visitor-purpose.view` | Policy |
| BC-AUTH-04 | update/toggle gate `frontoffice.visitor-purpose.update` | Policy |
| BC-AUTH-05 | delete gate `frontoffice.visitor-purpose.delete` (+ govt check) | Policy |
| BC-AUTH-06 | restore gate `frontoffice.visitor-purpose.restore` | Policy |
| BC-AUTH-07 | forceDelete gate `frontoffice.visitor-purpose.forceDelete` (+ govt check) | Policy |
| BC-AUTH-08 | Status column visibility gate `frontoffice.visitor-purpose.update` | View |
| BC-AUTH-09 | Action column visibility gate `frontoffice.visitor-purpose.view/update/delete` | View |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Table: Code (badge), Name, Sort Order, Govt Visit (Yes/No badge), Status toggle, Actions | View |
| BC-BIZ-02 | Search by name, code, sort_order; special: "yes"/"government"→govt=true search | Ctrl |
| BC-BIZ-03 | Status filter: All / Active (1) / Inactive (0) | View |
| BC-BIZ-04 | Sort by sort_order then name by default | Ctrl |
| BC-BIZ-05 | Paginated 20 per page (vp_page) | Ctrl |
| BC-BIZ-06 | Status toggle Ajax → JSON {success, message, is_active} | Ctrl |
| BC-BIZ-07 | Govt purpose delete → 403 forbidden | Policy |
| BC-BIZ-08 | Govt purpose forceDelete → 403 forbidden | Policy |
| BC-BIZ-09 | Non-govt purpose soft delete → success | Ctrl |
| BC-BIZ-10 | Empty state: "No purposes found" | View |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FOFP-P10 | Positive | View | Table with Code badge, Name, Sort Order, Govt Visit badge, Status toggle, Actions | Rendered | test_fo_fp_10 | Automated |
| TC-FOFP-P11 | Positive | View | Search by name or code | Search | test_fo_fp_11 | Automated |
| TC-FOFP-P12 | Positive | View | Status filter Active/Inactive | Filter | test_fo_fp_12 | Automated |
| TC-FOFP-P13 | Positive | View | Govt Visit = Yes (warning badge), No (secondary badge) | Badges | test_fo_fp_13 | Automated |
| TC-FOFP-P14 | Positive | View | Sorted by sort_order then name | Sorted | test_fo_fp_14 | Automated |
| TC-FOFP-P15 | Positive | View | Paginated 20 per page | Paginated | test_fo_fp_15 | Automated |
| TC-FOFP-P16 | Positive | View | Empty state "No purposes found" | Empty | test_fo_fp_16 | Automated |
| TC-FOFP-P17 | Positive | Ctrl | Create purpose → stored, redirect to tab | Created | test_fo_fp_17 | Automated |
| TC-FOFP-P18 | Positive | Ctrl | Update purpose → updated, redirect | Updated | test_fo_fp_18 | Automated |
| TC-FOFP-P19 | Positive | Ctrl | Toggle status → Ajax success | Toggled | test_fo_fp_19 | Automated |
| TC-FOFP-P20 | Positive | Ctrl | Soft delete non-govt purpose → trashed | Deleted | test_fo_fp_20 | Automated |
| TC-FOFP-N21 | Negative | Auth | Delete government purpose → 403 | Blocked | test_fo_fp_21 | Automated |
| TC-FOFP-N22 | Negative | Auth | Delete without permission → 403 | 403 | test_fo_fp_22 | Automated |
| TC-FOFP-N23 | Negative | Val | Duplicate code → validation error | Error | test_fo_fp_23 | Automated |
<｜｜DSML｜｜parameter name="filePath" string="true">C:\laragon\www\PG\prime_testing\Doc_Analysis\4-TC_List_Requirement_Review\FrontOffice\TC_Lists\fo_VisitorPurpose_TC_List.md
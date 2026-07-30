# adm_Alumni — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Alumni (View-only list + Student Toggle)
**DB scope:** TENANT-side (`std_students` via promotion records) · **Test style:** Browser Dusk
**Module URL prefix:** `/admission/promotions-alumni?tab=alumni`
**Test file:** `adm_Alumni_TestCas.php`
**Tab:** Alumni (second tab of Promotions & Alumni)

Controller:
- `AlumniController` — toggleStudentStatus (active/inactive)
- `AdmMenuController::promotionsAlumni()` — loads alumni list

Routes (`adm.` prefix):
- `GET /admission/promotions-alumni` — tabbed page (alumni tab)
- `POST /admission/alumni/{student}/toggle-status` — toggle active (JSON)

**DDL references:** `adm_promotion_records.result = 'Alumni'`, `std_students`

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Alumni list sourced from `std_students` where student has promotion record with result='Alumni' from confirmed `adm_promotion_batches` | View |
| BC-DB-02 | `std_students` table: id, admission_no, first_name, middle_name, last_name, gender, is_active (etc.) | Cross-module |
| BC-DB-03 | `tc_issued` boolean column on `std_students` — set to true when TC is issued | Migration |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible with `tenant.adm-promotion.viewAny` OR `tenant.adm-tc.viewAny` | MenuCtrl |
| BC-AUTH-02 | toggleStudentStatus gate checked inline (generic permission) | Ctrl |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Alumni list: students with result=Alumni from confirmed batches, filtered by search (name/admission_no), status (active/alumni), class, gender | MenuCtrl |
| BC-BIZ-02 | "TC Issued" badge shown if student has tc_issued=true | View |
| BC-BIZ-03 | "Issue TC" button opens TC modal (redirect to TCs tab) | View |
| BC-BIZ-04 | toggleStudentStatus: toggles is_active via AJAX, returns JSON | Ctrl |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | No confirmed promotion batches → empty alumni list | View |
| BC-EDG-02 | Toggle already-inactive student → activates | Ctrl |

---

## 2. Test Case List

### Screen 1: Alumni Tab (GET /admission/promotions-alumni?tab=alumni)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAL-P10 | Positive | View | Alumni tab: search/filters (status, class, gender), table (Name, Admission No, Class, Active toggle, TC badge, Issue TC button) | Rendered | test_adm_al_10 | Automated |
| TC-ADMAL-P11 | Positive | View | "TC Issued" badge shown when student has tc_issued=true | Badge | test_adm_al_11 | Automated |
| TC-ADMAL-P12 | Positive | View | "Issue TC" button visible for students without TC | Button | test_adm_al_12 | Automated |
| TC-ADMAL-P13 | Positive | View | Filters: search by name/admission_no, class dropdown, gender dropdown | Filters | test_adm_al_13 | Automated |
| TC-ADMAL-P14 | Positive | View | Empty state when no alumni | Empty | test_adm_al_14 | Automated |
| TC-ADMAL-P20 | Positive | Ctrl | Toggle student is_active on/off returns JSON | JSON | test_adm_al_20 | Automated |

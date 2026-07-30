# fo_KeyRegister — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Key Register (Key Inventory + Issue/Return)
**DB scope:** TENANT-side (`fof_key_register`) · **Test style:** Browser Dusk
**Primary table:** `fof_key_register` · **Module URL prefix:** `/front-office/registers?tab=keys`
**Test file:** `fo_KeyRegister_TestCas.php`
**Tab:** Keys (fifth tab of Registers)

Controller: `FofMenuController::registers()`, `KeyRegisterController`
Model: `KeyRegister`
Request: `KeyRegisterRequest`
Policy: `KeyRegisterPolicy`

Routes: keys CRUD + issue/return + toggleStatus + trash/restore/forceDelete

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_key_register`: id, key_label, key_tag_number, key_type (Room/Lab/Vehicle/Cabinet/Store/Other), status (Available/Issued/Overdue/Lost), issued_to_user_id (FK), purpose, issued_at, expected_return_at (datetime), returned_at, is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `key_label` required string max:200 | FR |
| BC-VAL-02 | `key_tag_number` nullable string max:50 | FR |
| BC-VAL-03 | `expected_return_at` required on issue (datetime-local) | View |
| BC-VAL-04 | `claimant_name` required on claim (claim modal) | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.key-register.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `frontoffice.key-register.create` | Policy |
| BC-AUTH-03 | update/issue/return gate `frontoffice.key-register.update` | Policy |
| BC-AUTH-04 | delete gate `frontoffice.key-register.delete` | Policy |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Three sections: Overdue (red danger) → Issued (blue primary) → Available (green success) | View |
| BC-BIZ-02 | Overdue: red border, "Overdue" badge, red expected_return_at | View |
| BC-BIZ-03 | Issued: blue primary border, "Issued" badge, Return button | View |
| BC-BIZ-04 | Available: green success border, "Available" badge, Issue button | View |
| BC-BIZ-05 | Issue modal: expected_return_at (datetime-local) required | View |
| BC-BIZ-06 | Return modal: optional remarks | View |
| BC-BIZ-07 | Register modal: key_label required, key_tag_number optional | View |
| BC-BIZ-08 | Card shows: key_label (bold) + key_tag_number (monospace) | View |
| BC-BIZ-09 | Search across key_label, key_tag_number, status | Ctrl |
| BC-BIZ-10 | Empty states: "No available keys found" / "No keys currently issued" | View |
| BC-BIZ-11 | Status toggle Ajax → JSON success | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FOKR-P10 | Positive | View | Overdue (red) → Issued (blue) → Available (green) sections | Sections | test_fo_kr_10 | Automated |
| TC-FOKR-P11 | Positive | View | Overdue shows red border + "Overdue" badge | Overdue | test_fo_kr_11 | Automated |
| TC-FOKR-P12 | Positive | View | Available shows Issue button | Button | test_fo_kr_12 | Automated |
| TC-FOKR-P13 | Positive | Ctrl | Issue key → status=Issued, issued_at set | Issued | test_fo_kr_13 | Automated |
| TC-FOKR-P14 | Positive | Ctrl | Return key → status=Available, returned_at set | Returned | test_fo_kr_14 | Automated |
| TC-FOKR-P15 | Positive | Ctrl | Register new key → stored | Created | test_fo_kr_15 | Automated |
| TC-FOKR-P16 | Positive | Ctrl | Soft delete → trashed | Deleted | test_fo_kr_16 | Automated |
| TC-FOKR-P17 | Positive | View | Card shows key_label + key_tag_number | Card | test_fo_kr_17 | Automated |
| TC-FOKR-P18 | Positive | View | Empty states for all three sections | Empty | test_fo_kr_18 | Automated |
| TC-FOKR-N19 | Negative | Val | Issue without expected_return_at → validation error | Error | test_fo_kr_19 | Automated |
| TC-FOKR-N20 | Negative | Val | Missing key_label → validation error | Error | test_fo_kr_20 | Automated |

# fo_PostalRegister — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Postal Register (Inward/Outward Mail)
**DB scope:** TENANT-side (`fof_postal_register`) · **Test style:** Browser Dusk
**Primary table:** `fof_postal_register` · **Module URL prefix:** `/front-office/registers?tab=postal`
**Test file:** `fo_PostalRegister_TestCas.php`
**Tab:** Postal (first tab of Registers, with Inward/Outward sub-tabs)

Controller: `FofMenuController::registers()`, `PostalRegisterController`
Model: `PostalRegister`
Request: `PostalRegisterRequest`
Policy: `PostalRegisterPolicy`

Routes: postal-register CRUD + acknowledge + toggleStatus + trash/restore/forceDelete

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_postal_register`: id, postal_type (Inward/Outward), postal_number, postal_date, document_type (Letter/Courier/Parcel/Government_Notice/Cheque/Legal/Other), subject, sender_name, sender_address, recipient_name, recipient_address, courier_company, tracking_number, acknowledged_at, acknowledgement_by (FK), department, assigned_to_user_id (FK), remarks, is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `postal_type` required in:Inward,Outward | FR |
| BC-VAL-02 | `postal_date` required date | FR |
| BC-VAL-03 | `document_type` required in:Letter,Courier,Parcel,Government_Notice,Cheque,Legal,Other | FR |
| BC-VAL-04 | `subject` required string max:255 | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.postal-register.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `frontoffice.postal-register.create` | Policy |
| BC-AUTH-03 | update/acknowledge gate `frontoffice.postal-register.update` | Policy |
| BC-AUTH-04 | delete gate `frontoffice.postal-register.delete` | Policy |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Inward Mail sub-tab (active by default) + Outward Mail sub-tab | View |
| BC-BIZ-02 | Card-style: postal number badge, date, From/To, Doc Type, Subject, Acknowledge/Status/Actions | View |
| BC-BIZ-03 | Acknowledge button shown for unacknowledged inward mail | View |
| BC-BIZ-04 | Acknowledged shows green "Ack. dd Mmm" badge | View |
| BC-BIZ-05 | Outward shows tracking number | View |
| BC-BIZ-06 | Search across postal_number, tracking_number, sender/recipient, subject, department | Ctrl |
| BC-BIZ-07 | Create modal: Type, Date, Document Type, Subject, From/To, Addresses, Courier, Tracking, Department, Staff, Remarks | View |
| BC-BIZ-08 | Empty states: "No inward mail entries found" / "No outward mail entries found" | View |
| BC-BIZ-09 | Status toggle Ajax → JSON success | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FOPR-P10 | Positive | View | Inward (active) + Outward sub-tabs rendered | Sub-tabs | test_fo_pr_10 | Automated |
| TC-FOPR-P11 | Positive | View | Card: postal number, date, From, Doc Type, Subject, actions | Card | test_fo_pr_11 | Automated |
| TC-FOPR-P12 | Positive | Ctrl | Create inward entry via modal → stored | Created | test_fo_pr_12 | Automated |
| TC-FOPR-P13 | Positive | Ctrl | Create outward entry → stored | Created | test_fo_pr_13 | Automated |
| TC-FOPR-P14 | Positive | Ctrl | Acknowledge inward mail → acknowledged_at set | Ack'd | test_fo_pr_14 | Automated |
| TC-FOPR-P15 | Positive | View | Acknowledged shows green date badge | Badge | test_fo_pr_15 | Automated |
| TC-FOPR-P16 | Positive | View | Outward shows tracking number | Shown | test_fo_pr_16 | Automated |
| TC-FOPR-P17 | Positive | Ctrl | Soft delete → trashed | Deleted | test_fo_pr_17 | Automated |
| TC-FOPR-P18 | Positive | View | Empty states for inward/outward | Empty | test_fo_pr_18 | Automated |
| TC-FOPR-N19 | Negative | Val | Missing subject/document_type → validation error | Error | test_fo_pr_19 | Automated |

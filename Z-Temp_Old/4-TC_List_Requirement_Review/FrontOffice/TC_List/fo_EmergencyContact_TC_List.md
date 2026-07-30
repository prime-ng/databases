# fo_EmergencyContact — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Emergency Contacts (Directory)
**DB scope:** TENANT-side (`fof_emergency_contacts`) · **Test style:** Browser Dusk
**Primary table:** `fof_emergency_contacts` · **Module URL prefix:** `/front-office/compliance?tab=emergency`
**Test file:** `fo_EmergencyContact_TestCas.php`
**Tab:** Emergency Contacts (third tab of Compliance)

Controller: `FofMenuController::compliance()`, `EmergencyContactController`
Model: `EmergencyContact`
Policy: `EmergencyContactPolicy`

Routes: emergency-contacts CRUD + toggleStatus + trash/restore/forceDelete

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_emergency_contacts`: id, contact_name, organization, contact_type (Hospital/Police/Fire/Transport/Ambulance/Other), primary_phone, alternate_phone, address, notes, sort_order, is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `contact_name` required string max:200 | FR |
| BC-VAL-02 | `contact_type` required in:Hospital,Police,Fire,Transport,Ambulance,Other | FR |
| BC-VAL-03 | `primary_phone` required string max:20 | FR |
| BC-VAL-04 | `alternate_phone` nullable string max:20 | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.emergency-contact.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `frontoffice.emergency-contact.create` | Policy |
| BC-AUTH-03 | update gate `frontoffice.emergency-contact.update` | Policy |
| BC-AUTH-04 | delete gate `frontoffice.emergency-contact.delete` | Policy |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Contacts grouped by type: Hospital, Police, Fire, Transport, Ambulance, Other | View |
| BC-BIZ-02 | Each group header has type-specific icon (hospital/shield/fire/truck-medical/phone) | View |
| BC-BIZ-03 | Card: contact_name (bold), contact_type (muted), primary_phone (bold green + icon), alternate_phone (muted + icon), address, Status toggle, Actions | View |
| BC-BIZ-04 | Cards have red danger left border | View |
| BC-BIZ-05 | Create modal: contact_name, type, primary_phone, alternate_phone, address | View |
| BC-BIZ-06 | Search across contacts | Ctrl |
| BC-BIZ-07 | Status filter: All / Active (1) / Inactive (0) | View |
| BC-BIZ-08 | Empty state: "No emergency contacts added yet" | View |
| BC-BIZ-09 | Status toggle Ajax → JSON success | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FOEC-P10 | Positive | View | Grouped by type: Hospital, Police, Fire, Transport, Ambulance, Other | Groups | test_fo_ec_10 | Automated |
| TC-FOEC-P11 | Positive | View | Type-specific icons per group header | Icons | test_fo_ec_11 | Automated |
| TC-FOEC-P12 | Positive | View | Card: name, type, primary phone (green bold + icon), alternate phone, address | Card | test_fo_ec_12 | Automated |
| TC-FOEC-P13 | Positive | View | Cards have red danger left border | Border | test_fo_ec_13 | Automated |
| TC-FOEC-P14 | Positive | Ctrl | Create emergency contact → stored | Created | test_fo_ec_14 | Automated |
| TC-FOEC-P15 | Positive | Ctrl | Update contact → updated | Updated | test_fo_ec_15 | Automated |
| TC-FOEC-P16 | Positive | Ctrl | Soft delete → trashed | Deleted | test_fo_ec_16 | Automated |
| TC-FOEC-P17 | Positive | View | Empty state "No emergency contacts added yet" | Empty | test_fo_ec_17 | Automated |
| TC-FOEC-N18 | Negative | Val | Missing primary_phone → validation error | Error | test_fo_ec_18 | Automated |
| TC-FOEC-N19 | Negative | Val | Invalid contact_type → validation error | Error | test_fo_ec_19 | Automated |

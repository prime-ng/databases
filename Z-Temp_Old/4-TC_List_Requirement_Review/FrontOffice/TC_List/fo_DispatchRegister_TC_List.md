# fo_DispatchRegister — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Dispatch Register (Outgoing Dispatches)
**DB scope:** TENANT-side (`fof_dispatch_register`) · **Test style:** Browser Dusk
**Primary table:** `fof_dispatch_register` · **Module URL prefix:** `/front-office/registers?tab=dispatch`
**Test file:** `fo_DispatchRegister_TestCas.php`
**Tab:** Dispatch (second tab of Registers)

Controller: `FofMenuController::registers()`, `DispatchRegisterController`
Model: `DispatchRegister`
Request: `DispatchRegisterRequest`
Policy: `DispatchRegisterPolicy`

Routes: dispatch-register CRUD + toggleStatus + trash/restore/forceDelete

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_dispatch_register`: id, dispatch_number, dispatch_date, dispatch_mode (Hand/Post/Courier/Email/Fax/Other), document_type (Letter/Notice/Circular/Report/Legal/Other), addressee_name, addressee_address, reference_number, subject, copy_retained (boolean), dispatched_by (FK), remarks, is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `dispatch_date` required date | FR |
| BC-VAL-02 | `dispatch_mode` required in:Hand,Post,Courier,Email,Fax,Other | FR |
| BC-VAL-03 | `document_type` required in:Letter,Notice,Circular,Report,Legal,Other | FR |
| BC-VAL-04 | `addressee_name` required string max:200 | FR |
| BC-VAL-05 | `subject` required string max:255 | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.dispatch-register.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `frontoffice.dispatch-register.create` | Policy |
| BC-AUTH-03 | update gate `frontoffice.dispatch-register.update` | Policy |
| BC-AUTH-04 | delete gate `frontoffice.dispatch-register.delete` | Policy |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Card-style: dispatch number badge, date, Addressee (bold), Subject, Mode badge + Doc Type, Ref. No., Status toggle, Actions | View |
| BC-BIZ-02 | Search across dispatch_number, reference_number, addressee, subject, mode, document_type | Ctrl |
| BC-BIZ-03 | Create modal: Date, Mode, Doc Type, Addressee, Reference No, Subject, Remarks | View |
| BC-BIZ-04 | Empty state: "No dispatch entries found" | View |
| BC-BIZ-05 | Status toggle Ajax → JSON success | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FODR-P10 | Positive | View | Card: dispatch number, date, addressee, subject, mode + doc type badges | Card | test_fo_dr_10 | Automated |
| TC-FODR-P11 | Positive | View | Dispatch mode badge + Document type badge | Badges | test_fo_dr_11 | Automated |
| TC-FODR-P12 | Positive | Ctrl | Create dispatch via modal → stored | Created | test_fo_dr_12 | Automated |
| TC-FODR-P13 | Positive | Ctrl | Edit dispatch → updated | Updated | test_fo_dr_13 | Automated |
| TC-FODR-P14 | Positive | Ctrl | Soft delete → trashed | Deleted | test_fo_dr_14 | Automated |
| TC-FODR-P15 | Positive | View | Empty state "No dispatch entries found" | Empty | test_fo_dr_15 | Automated |
| TC-FODR-N16 | Negative | Val | Missing addressee → validation error | Error | test_fo_dr_16 | Automated |
| TC-FODR-N17 | Negative | Val | Invalid dispatch_mode → validation error | Error | test_fo_dr_17 | Automated |

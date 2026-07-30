# fo_PhoneDiary — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Phone Diary (Call Log + Action Tracking)
**DB scope:** TENANT-side (`fof_phone_diary`) · **Test style:** Browser Dusk
**Primary table:** `fof_phone_diary` · **Module URL prefix:** `/front-office/registers?tab=phone-diary`
**Test file:** `fo_PhoneDiary_TestCas.php`
**Tab:** Phone Diary (third tab of Registers)

Controller: `FofMenuController::registers()`, `PhoneDiaryController`
Model: `PhoneDiary`
Request: `PhoneDiaryRequest`
Policy: `PhoneDiaryPolicy`

Routes: phone-diary CRUD + complete + toggleStatus + trash/restore/forceDelete

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_phone_diary`: id, call_type (Incoming/Outgoing), call_date (date), call_time (time), caller_name, caller_number, caller_organization, recipient_name, recipient_user_id (FK), purpose, message, action_required (boolean), action_notes, action_completed (boolean), action_completed_at, logged_by (FK), is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |
| BC-DB-02 | Model: SoftDeletes. Scope: actionPending() (action_required && !action_completed) | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `call_type` required in:Incoming,Outgoing | FR |
| BC-VAL-02 | `call_date` required date | FR |
| BC-VAL-03 | `call_time` required | FR |
| BC-VAL-04 | `caller_name` required string max:100 | FR |
| BC-VAL-05 | `purpose` required string max:200 | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.phone-diary.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `frontoffice.phone-diary.create` | Policy |
| BC-AUTH-03 | update gate `frontoffice.phone-diary.update` | Policy |
| BC-AUTH-04 | delete gate `frontoffice.phone-diary.delete` | Policy |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Header shows pending action count badge (yellow) | View |
| BC-BIZ-02 | Card: Date + Time, Call Type badge, Caller name + number, Purpose, Action badge (Resolved/Pending/—), Mark Done, Status toggle, Actions | View |
| BC-BIZ-03 | Incoming badge (green), Outgoing badge (blue) | View |
| BC-BIZ-04 | Action Pending → yellow border; Resolved → green border | View |
| BC-BIZ-05 | Mark Done button for action_required && !action_completed | View |
| BC-BIZ-06 | Action Notes shown below Pending badge | View |
| BC-BIZ-07 | Create modal: Type, Date, Time, Caller Name, Number, Organization, Purpose, Message, Action Required checkbox + notes (JS toggle) | View |
| BC-BIZ-08 | Filter by call_type: All / Incoming / Outgoing | View |
| BC-BIZ-09 | Search across caller_name, caller_number, organization, purpose, message, action_notes | Ctrl |
| BC-BIZ-10 | Empty state: "No call log entries found" | View |
| BC-BIZ-11 | Status toggle Ajax → JSON success | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FOPD-P10 | Positive | View | Pending action count badge in header | Badge | test_fo_pd_10 | Automated |
| TC-FOPD-P11 | Positive | View | Card: date/time, call type badge, caller, purpose, action status, buttons | Card | test_fo_pd_11 | Automated |
| TC-FOPD-P12 | Positive | View | Incoming (green) / Outgoing (blue) badges | Badges | test_fo_pd_12 | Automated |
| TC-FOPD-P13 | Positive | Ctrl | Create call log via modal → stored | Created | test_fo_pd_13 | Automated |
| TC-FOPD-P14 | Positive | Ctrl | Mark Done → action_completed set | Completed | test_fo_pd_14 | Automated |
| TC-FOPD-P15 | Positive | View | Yellow border for pending action, green for resolved | Borders | test_fo_pd_15 | Automated |
| TC-FOPD-P16 | Positive | View | Action Required checkbox shows/hides notes field via JS | Toggle | test_fo_pd_16 | Automated |
| TC-FOPD-P17 | Positive | Ctrl | Soft delete → trashed | Deleted | test_fo_pd_17 | Automated |
| TC-FOPD-P18 | Positive | View | Empty state "No call log entries found" | Empty | test_fo_pd_18 | Automated |
| TC-FOPD-N19 | Negative | Val | Missing caller_name/purpose → validation error | Error | test_fo_pd_19 | Automated |

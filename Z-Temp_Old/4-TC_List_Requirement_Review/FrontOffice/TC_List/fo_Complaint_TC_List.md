# fo_Complaint — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Complaints (Registration + Resolution + Escalation)
**DB scope:** TENANT-side (`fof_complaints`) · **Test style:** Browser Dusk
**Primary table:** `fof_complaints` · **Module URL prefix:** `/front-office/compliance?tab=complaints`
**Test file:** `fo_Complaint_TestCas.php`
**Tab:** Complaints (first tab of Compliance)

Controller: `FofMenuController::compliance()`, `ComplaintController`
Model: `FofComplaint`
Policy: `ComplaintPolicy`

Routes: complaints CRUD + resolve/escalate + toggleStatus + trash/restore/forceDelete

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_complaints`: id, complaint_number, complainant_name, complainant_contact, complaint_type (Academic/Facility/Staff_Behavior/Fee/Safety/Transportation/Food/Hygiene/Other), description, urgency (Normal/Urgent/Critical), status (Open/In_Progress/Resolved/Closed/Escalated), resolution_notes, resolved_by, resolved_at, cmp_complaint_id, assigned_to_user_id, is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |
| BC-DB-02 | Model: SoftDeletes. Scopes: active(), open() (status in Open,In_Progress). Casts: resolved_at→datetime, is_active→boolean | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `complainant_name` required string max:200 | FR |
| BC-VAL-02 | `complaint_type` required in:Academic,Facility,Staff_Behavior,Fee,Safety,Transportation,Food,Hygiene,Other | FR |
| BC-VAL-03 | `urgency` required in:Normal,Urgent,Critical | FR |
| BC-VAL-04 | `description` required string | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.complaint.viewAny` → `frontoffice.complaint.view` | Policy |
| BC-AUTH-02 | create/store gate `frontoffice.complaint.create` | Policy |
| BC-AUTH-03 | update gate `frontoffice.complaint.update` | Policy |
| BC-AUTH-04 | delete gate `frontoffice.complaint.delete` | Policy |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Open/In_Progress section (warning/primary borders) + Closed/Resolved section (success/danger borders) | View |
| BC-BIZ-02 | Card: complaint_number, date, complainant name + contact, type badge, urgency badge, status badge, Resolve + Escalate buttons, Status toggle, Actions | View |
| BC-BIZ-03 | Urgency badges: Critical (danger), Urgent (warning), Normal (info) | View |
| BC-BIZ-04 | Resolve sets status=Resolved, resolved_by, resolved_at | Ctrl |
| BC-BIZ-05 | Escalate creates CmpComplaint link, sets cmp_complaint_id | Ctrl |
| BC-BIZ-06 | Status filter: All/Open/In_Progress/Resolved/Escalated/Closed | View |
| BC-BIZ-07 | Search across complainant name, complaint_number, description | Ctrl |
| BC-BIZ-08 | Empty state: "No closed complaints" | View |
| BC-BIZ-09 | Create modal: complainant_name, type, urgency, description | View |
| BC-BIZ-10 | Status toggle Ajax → JSON success | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FOCM-P10 | Positive | View | Open (warning/primary) + Closed (success/danger) sections | Sections | test_fo_cm_10 | Automated |
| TC-FOCM-P11 | Positive | View | Card: number, date, complainant, type, urgency, status, buttons | Card | test_fo_cm_11 | Automated |
| TC-FOCM-P12 | Positive | View | Urgency badges: Critical (red), Urgent (yellow), Normal (teal) | Badges | test_fo_cm_12 | Automated |
| TC-FOCM-P13 | Positive | Ctrl | Register complaint → stored | Created | test_fo_cm_13 | Automated |
| TC-FOCM-P14 | Positive | Ctrl | Resolve complaint → status=Resolved, resolved_at set | Resolved | test_fo_cm_14 | Automated |
| TC-FOCM-P15 | Positive | Ctrl | Escalate complaint → cmp_complaint_id set | Escalated | test_fo_cm_15 | Automated |
| TC-FOCM-P16 | Positive | View | Status filter: All/Open/In_Progress/Resolved/Escalated/Closed | Filter | test_fo_cm_16 | Automated |
| TC-FOCM-P17 | Positive | View | Closed section empty state "No closed complaints" | Empty | test_fo_cm_17 | Automated |
| TC-FOCM-N18 | Negative | Val | Missing complainant_name/description → validation error | Error | test_fo_cm_18 | Automated |

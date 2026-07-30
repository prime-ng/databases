# fo_Circular — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Circulars (Approval Workflow)
**DB scope:** TENANT-side (`fof_circulars`) · **Test style:** Browser Dusk
**Primary table:** `fof_circulars` · **Module URL prefix:** `/front-office/communication?tab=circulars`
**Test file:** `fo_Circular_TestCas.php`
**Tab:** Circulars (first tab of Communication)

Controller: `FofMenuController::communication()`, `CircularController`
Model: `Circular`, `CircularDistribution`
Policy: `CircularPolicy`

Routes: circulars CRUD + approve/distribute/recall + toggleStatus + trash/restore/forceDelete

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_circulars`: id, circular_number, title, subject, body, audience (All_Parents/All_Staff/All_Students/Custom), audience_filter_json, effective_date, expires_on, attachment_media_id, status (Draft/Pending_Approval/Approved/Distributed/Recalled), approved_by, approved_at, distributed_by, distributed_at, is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |
| BC-DB-02 | Model: SoftDeletes, HasMedia (circular_attachment, singleFile), casts: audience_filter_json→array, effective_date→date, expires_on→date, approved_at→datetime, distributed_at→datetime, is_active→boolean. Scopes: active(). Method: isLocked() | Model |
| BC-DB-03 | `fof_circular_distributions`: circular_id, recipient_user_id, channel, status, sent_at, delivered_at, read_at (append-only, no SoftDeletes) | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `title` required string max:200 | FR |
| BC-VAL-02 | `subject` nullable string max:200 | FR |
| BC-VAL-03 | `body` required | FR |
| BC-VAL-04 | `audience` required in:All_Parents,All_Staff,All_Students,Custom | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.circular.viewAny` → `frontoffice.circular.view` | Policy |
| BC-AUTH-02 | create/store gate `frontoffice.circular.create` | Policy |
| BC-AUTH-03 | update gate `frontoffice.circular.update` | Policy |
| BC-AUTH-04 | delete gate `frontoffice.circular.delete` | Policy |
| BC-AUTH-05 | approve gate `frontoffice.circular.approve` | View |
| BC-AUTH-06 | distribute gate `frontoffice.circular.distribute` | View |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Table: Number, Title & Subject, Audience badge, Effective Date, Expiry Date, Status badge, Active toggle, Actions | View |
| BC-BIZ-02 | Status badges: Pending_Approval (yellow), Approved (green), Distributed (blue), Recalled (red), Draft (gray) | View |
| BC-BIZ-03 | Pending_Approval → Approve button shown; Approved → Distribute button shown | View |
| BC-BIZ-04 | isLocked() when Approved/Distributed → edit disabled | View |
| BC-BIZ-05 | Search by title, circular_number | Ctrl |
| BC-BIZ-06 | Status filter: All/Draft/Pending_Approval/Approved/Distributed/Recalled | View |
| BC-BIZ-07 | Empty state: "No circulars found" | View |
| BC-BIZ-08 | Status toggle Ajax → JSON success | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FOCI-P10 | Positive | View | Table: Number, Title, Audience, Effective/Expiry, Status, Active, Actions | Rendered | test_fo_ci_10 | Automated |
| TC-FOCI-P11 | Positive | View | Status badges: Draft/Pending/Approved/Distributed/Recalled colors | Badges | test_fo_ci_11 | Automated |
| TC-FOCI-P12 | Positive | Ctrl | Create circular as Draft → stored | Created | test_fo_ci_12 | Automated |
| TC-FOCI-P13 | Positive | Ctrl | Approve Pending_Approval → approved_by+approved_at, status=Approved | Approved | test_fo_ci_13 | Automated |
| TC-FOCI-P14 | Positive | Ctrl | Distribute Approved → status=Distributed | Distributed | test_fo_ci_14 | Automated |
| TC-FOCI-P15 | Positive | Ctrl | Recall Distributed → status=Recalled | Recalled | test_fo_ci_15 | Automated |
| TC-FOCI-P16 | Negative | Val | Missing required fields → validation errors | Errors | test_fo_ci_16 | Automated |
| TC-FOCI-N17 | Negative | Val | Invalid audience → in:All_Parents,... error | Error | test_fo_ci_17 | Automated |
| TC-FOCI-N18 | Negative | BIZ | Edit Approved circular → blocked (isLocked) | Blocked | test_fo_ci_18 | Automated |
| TC-FOCI-P19 | Positive | View | Empty state "No circulars found" | Empty | test_fo_ci_19 | Automated |

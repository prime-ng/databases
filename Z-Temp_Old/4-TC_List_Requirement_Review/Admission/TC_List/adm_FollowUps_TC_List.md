# adm_FollowUps — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Follow-Ups (Enquiry CRM Activity)
**DB scope:** TENANT-side (`adm_follow_ups`) · **Test style:** Browser Dusk
**Primary table:** `adm_follow_ups` · **Module URL prefix:** `/admission/enquiries/{id}/follow-ups`
**Test file:** `adm_FollowUps_TestCas.php`

Controller: `FollowUpController` (CRUD + complete)

Routes (`adm.` prefix):
- `GET /admission/enquiries/{enquiry}/follow-ups` — list
- `POST /admission/enquiries/{enquiry}/follow-ups` — schedule/store
- `PUT /admission/follow-ups/{followUp}` — update
- `POST /admission/follow-ups/{followUp}/complete` — mark completed
- `DELETE /admission/follow-ups/{followUp}` — soft delete

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_follow_ups`: id (BIGINT PK AI), enquiry_id (BIGINT UNSIGNED FK → adm_enquiries ON DELETE CASCADE), follow_up_type (ENUM('Call','Meeting','Email','SMS','Walk-in') NOT NULL), scheduled_at (DATETIME NOT NULL), completed_at (DATETIME NULL), outcome (ENUM('Pending','Interested','Not_Interested','Callback','Converted') DEFAULT 'Pending'), notes (TEXT NULL), done_by (INT UNSIGNED FK → sys_users NULL), reminder_sent (TINYINT 1 DEFAULT 0), is_active, created_by, updated_by, created_at, updated_at, deleted_at. Indexes: idx_adm_fu_enquiry, idx_adm_fu_scheduled, idx_adm_fu_done_by, idx_adm_fu_outcome | DDL |
| BC-DB-02 | Model `FollowUp`: SoftDeletes, casts: scheduled_at→datetime, completed_at→datetime, reminder_sent→boolean, is_active→boolean. Relations: enquiry() belongsTo, doneBy() belongsTo User | Model |

### BC-VAL — Validation
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `follow_up_type` required in:Call,Meeting,Email,SMS,Walk-in | FR |
| BC-VAL-02 | `scheduled_at` required datetime after_or_equal:now | FR |
| BC-VAL-03 | `outcome` nullable in:Pending,Interested,Not_Interested,Callback,Converted | FR |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | CRUD gate `tenant.adm-follow-up.*` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Follow-ups shown as timeline within enquiry detail | View |
| BC-BIZ-02 | Type badges: Call=primary, Meeting=info, Email=success, SMS=warning, Walk-in=secondary | View |
| BC-BIZ-03 | Outcome badges: Pending=warning, Interested=success, Not_Interested=danger, Callback=info, Converted=primary | View |
| BC-BIZ-04 | Scheduled follow-ups highlighted if scheduled_at in future | View |
| BC-BIZ-05 | Complete: sets completed_at=now, done_by=auth | Ctrl |
| BC-BIZ-06 | Overdue badge if scheduled_at past and completed_at NULL | View |
| BC-BIZ-07 | Reminder_sent flag set by NTF notification job | Job |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | No follow-ups → empty state | View |
| BC-EDG-02 | Complete already-completed → allowed | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMFU-P10 | Positive | Ctrl | Schedule follow-up → stored with status=Pending | Created | test_adm_fu_10 | Automated |
| TC-ADMFU-P11 | Positive | View | Timeline: type badge, datetime, outcome, notes, action buttons | Rendered | test_adm_fu_11 | Automated |
| TC-ADMFU-P12 | Positive | Ctrl | Complete → completed_at set, outcome updated | Done | test_adm_fu_12 | Automated |
| TC-ADMFU-P13 | Positive | View | Overdue badge for past-due incomplete follow-ups | Overdue | test_adm_fu_13 | Automated |
| TC-ADMFU-P14 | Positive | View | Empty state | Empty | test_adm_fu_14 | Automated |
| TC-ADMFU-N15 | Negative | Val | Missing follow_up_type/scheduled_at → required error | Error | test_adm_fu_15 | Automated |

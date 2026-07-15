# Assessment Period — Manual Testing Guide

**Aligned to:** `bha_AssessmentPeriod_TestCas.php` (59 automated methods, `test_period_NN_*`). Every manual case below maps to its automated method.

---

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment (live table prefix `ba_`) |
| Feature / Screen | AssessmentPeriod — "Periods" setup tab (`06-Periods*`) |
| Primary URL | `/behavioural-assessment/setup?tab=periods` (list) · `/behavioural-assessment/assessment-periods/create` (create) · `.../{id}/edit` (edit) · `.../trash` |
| App route alias | `assessment-periods` |
| Controller | `Modules\BehaviouralAssessment\Http\Controllers\BaAssessmentPeriodController` |
| FormRequest | `BaAssessmentPeriodRequest` |
| Policy | `BaAssessmentPeriodPolicy` |
| Model | `BaAssessmentPeriod` (table `ba_assessment_periods`) |
| Runtime table | `ba_assessment_periods` (DDL-doc says `bha_` — divergence DOC-BA-001) |
| CRUD type | Full CRUD + lifecycle transitions (close/reopen/lock/unlock) + toggle-status |
| Soft delete | Yes (`deleted_at`); trash + restore + force-delete |
| Pagination | Yes (setup periods pane) |
| Activity log | **NONE** — no `activityLog()` call, no observer. Do NOT expect audit-trail rows. |
| Permission prefix | `tenant.behavioural-assessment.assessment-periods.{viewAny\|view\|create\|update\|delete\|restore\|forceDelete\|status\|close\|reopen\|lock\|unlock}` |
| DB scope | Tenant-side (database-per-tenant) |

### Prerequisites
1. BehaviouralAssessment module **enabled** in `modules_statuses.json`.
2. At least one `sch_org_academic_sessions_jnt` row exists (required FK for create).
3. Optionally one `sch_academic_term` row (for term-scoped periods).
4. A tenant admin user with all 12 assessment-period permissions (or super-admin).
5. Migrations applied: `ba_assessment_periods` table present with `status` ENUM('open','closed','locked'), `is_active` TINYINT, soft-deletes.

---

## 2. Business Conditions (with messages & flows)

### Lifecycle state machine (status)
```
            close()               lock()
  (create) ────────▶ open ──────▶ closed ──────▶ locked
   status=open        ▲   reopen()   │  ▲   unlock()  │
                      └──────────────┘  └─────────────┘
                                       (locked→closed, admin override)
```
Legal transitions and their SUCCESS flash:
| From | Action | To | Flash |
|------|--------|----|-------|
| open | close() | closed | "Period closed. New assessments blocked; existing drafts remain editable." |
| closed | reopen() | open | "Period reopened." |
| closed | lock() | locked | "Period locked. No further edits allowed." |
| locked | unlock() | closed | "Period unlocked (set to closed)." |

Illegal transitions — status stays unchanged, ERROR flash:
| Attempt | Error flash |
|---------|-------------|
| close() on closed/locked | "Only open periods can be closed." |
| reopen() on open/locked | "Only closed periods can be reopened." |
| lock() on open/locked | "Only closed periods can be locked. Close the period first." |
| unlock() on open/closed | "Period is not locked." |

### Other flash messages
| Action | Message |
|--------|---------|
| create success | "Assessment period created successfully." |
| update success | "Assessment period updated successfully." |
| destroy blocked | "Cannot delete this assessment period because it has active assessments or computed scores." |
| destroy success | "Assessment period moved to trash." |
| restore success | "Assessment period restored." |
| forceDelete blocked | "Cannot permanently delete this assessment period because it has associated assessments or computed scores (active or trashed)." |
| forceDelete success | "Assessment period permanently deleted." |
| toggle-status | "Assessment period activated." / "Assessment period deactivated." |

### Validation (FormRequest)
- academic_session_id: required, exists in `sch_org_academic_sessions_jnt`.
- academic_term_id: nullable, exists in `sch_academic_term` when provided.
- name: required, max 100.
- start_date: required date; end_date: required, `after_or_equal:start_date`; deadline: required, `gte:end_date`.
- is_active: nullable boolean, defaults true.
- `status` is NOT accepted — a posted status is ignored (store always forces `open`).

### Known gaps to observe (not blockers)
- **PER-GAP-01:** overlapping periods in the same session are accepted (no overlap rule).
- **PER-GAP-02:** duplicate period names are accepted (no unique rule).
- **BUG-BA-002 residual:** a LOCKED period can still be edited/deactivated/deleted by a direct request — the lock is enforced only in the edit Blade (CSS `pe-none` + hidden submit).

---

## 3. Test Cases (step-by-step)

### Config / schema truth
**TC-CFG01 — Schema & config truth (test_period_01)**
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect DB: `SHOW TABLES LIKE 'ba_assessment_periods'` | table exists |
| 2 | `SHOW COLUMNS FROM ba_assessment_periods` | id, academic_session_id, academic_term_id, name, start_date, end_date, deadline, status, is_active, created_by, updated_by, timestamps, deleted_at |
| 3 | Check `status` column type | ENUM contains 'open','closed','locked' |
| 4 | Open model / FormRequest | fillable + rules match §2 |

**TC-CFG02 — Prefix divergence (test_period_02):** confirm `ba_assessment_periods` exists and `bha_assessment_periods` does NOT (DOC-BA-001).

**TC-CFG03 — Scopes/helper (test_period_03):** `open()`/`active()` scopes return only open+active rows; `isLocked()` true only for status=locked.

### Positive / business
**TC-P01 — Create (test_period_10)**
| Step | Action | Expected |
|------|--------|----------|
| 1 | Go to create page, fill valid session + name + dates | form accepts |
| 2 | Submit | success flash; redirect |
| 3 | `SELECT status,is_active,created_by FROM ba_assessment_periods WHERE name=...` | status='open', is_active=1, created_by=your id |

**TC-P02 — Posted status ignored (test_period_11):** POST with `status=locked` → row still `open`.
**TC-P03 — Update (test_period_12):** edit name + deadline → persisted; updated_by=your id.
**TC-P04 — Independent period (test_period_13):** create with empty term → `academic_term_id` NULL.
**TC-P05 — index redirect (test_period_14):** visit `/assessment-periods` → 200/302 to setup periods tab.
**TC-P06 — show redirect (test_period_15):** visit `/assessment-periods/{id}` → 200/302 to edit.
**TC-P07 — list (test_period_16):** setup periods tab shows the period name.
**TC-D01 — Delete restriction metadata (test_period_17):** FK from ba_assessments/ba_computed_scores to period is RESTRICT/NO ACTION.

### State machine
| TC | Method | Action | Expected |
|----|--------|--------|----------|
| TC-SM01 | test_period_20 | Create period | status=open |
| TC-SM02 | test_period_21 | close() an open period | →closed |
| TC-SM03 | test_period_22 | reopen() a closed period | →open |
| TC-SM04 | test_period_23 | lock() a closed period | →locked |
| TC-SM05 | test_period_24 | unlock() a locked period | →closed |
| TC-SM06 | test_period_25 | close() a closed & a locked period | unchanged + error flash |
| TC-SM07 | test_period_26 | reopen() an open & a locked period | unchanged + error flash |
| TC-SM08 | test_period_27 | lock() an open period; unlock() a non-locked period | unchanged + error flash |
| TC-SM09 | test_period_28 | Verify routes close/reopen/lock/unlock registered; `status` absent from FormRequest; lock guards closed→locked; store hardcodes open | all true (BUG-BA-002 remediated) |
| TC-SM10 | test_period_29 | Direct PUT edit / toggle-status / DELETE on a LOCKED period | **succeeds** — proves BUG-BA-002 residual (no server isLocked guard) |

### Negative / validation
| TC | Method | Input | Expected |
|----|--------|-------|----------|
| TC-N01 | test_period_30 | empty payload | 422 for session, name, start_date, end_date, deadline |
| TC-N02 | test_period_31 | name 101 chars | 422 name |
| TC-N03 | test_period_32 | academic_session_id=987654321 | 422 academic_session_id |
| TC-N04 | test_period_33 | academic_term_id=987654321 | 422 academic_term_id |
| TC-N05 | test_period_34 | end_date < start_date | 422 end_date |
| TC-N06 | test_period_35 | deadline < end_date | 422 deadline |
| TC-N07 | test_period_36 | non-date strings | 422 start_date |
| TC-N08 | test_period_37 | name = "   " | 422 name (trimmed) |
| TC-S01 | test_period_38 | name with `<script>alert(1)</script>` | stored; edit page renders it escaped (no raw script tag) |
| TC-N09 | test_period_39 | duplicate name + overlapping dates, same session | both accepted → proves PER-GAP-01/02 |

### Integration / FK & lifecycle
| TC | Method | Action | Expected |
|----|--------|--------|----------|
| TC-D02 | test_period_40 | delete a period | hidden from default scope; in trash; is_active=0 |
| TC-D03 | test_period_41 | restore from trash | back in default scope |
| TC-D04 | test_period_42 | force-delete a trashed period | row physically gone |
| TC-D05 | test_period_43 | restore a force-deleted id | 404 |
| TC-D06 | test_period_44 | inspect FK metadata | session FK RESTRICT, term FK SET NULL |
| TC-D07 | test_period_45 | full lifecycle create→close→lock→unlock→delete→restore→forceDelete | every stage as expected |

### Permissions
| TC | Method | Actor / action | Expected |
|----|--------|----------------|----------|
| TC-N10 | test_period_50 | guest visits create | redirect to /login |
| TC-N11 | test_period_51 | limited user POST store | 403 |
| TC-N12 | test_period_52 | limited user PUT update | 403 |
| TC-N13 | test_period_53 | limited user DELETE destroy | 403 |
| TC-N14 | test_period_54 | limited user POST toggle-status | 403 |
| TC-N15 | test_period_55 | limited user POST lock | 403 |
| TC-P08 | test_period_56 | inspect Policy | all 12 permission strings present |
| TC-P09 | test_period_57 | toggle-status twice | JSON success; message "…deactivated." then "…activated."; is_active flips |

### UI / UX
| TC | Method | Action | Expected |
|----|--------|--------|----------|
| TC-P10 | test_period_60 | search by name | matched row shown |
| TC-P11 | test_period_61 | filter status=locked | locked row + "Locked" label |
| TC-P12 | test_period_62 | search a non-matching term | "No assessment periods found." |
| TC-P13 | test_period_63 | open trash page | trashed period name shown |
| TC-P14 | test_period_64 | open create + edit pages | breadcrumb "Assessment Periods" |
| TC-P15 | test_period_65 | open edit page of a LOCKED period | banner "This period is locked."; form CSS-disabled (`pe-none`); "Update Assessment Period" submit hidden |

### Edge
| TC | Method | Action | Expected |
|----|--------|--------|----------|
| TC-N16 | test_period_70 | show/edit/toggle/close on id 987654321 | 404 |
| TC-P16 | test_period_71 | deadline == end_date | accepted |
| TC-P17 | test_period_72 | end_date == start_date | accepted |
| TC-P18 | test_period_73 | omit is_active on create | is_active defaults true |

### Tenancy / security
| TC | Method | Action | Expected |
|----|--------|--------|----------|
| TC-T01 | test_period_90 | check tenant context | tenancy initialized; table present |
| TC-T02 | test_period_91 | second tenant present | cross-tenant isolation checkable (else skipped) |
| TC-S02 | test_period_92 | inspect FormRequest authorize() | returns bare `true` (SEC-BA-002) |
| TC-S03 | test_period_93 | POST create with created_by/updated_by=999999 | audit cols = your auth id, not 999999 |

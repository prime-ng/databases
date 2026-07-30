# fo_SchoolEvent — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** School Events (Event Calendar)
**DB scope:** TENANT-side (`fof_school_events`) · **Test style:** Browser Dusk
**Primary table:** `fof_school_events` · **Module URL prefix:** `/front-office/communication?tab=school-events`
**Test file:** `fo_SchoolEvent_TestCas.php`
**Tab:** School Events (third tab of Communication)

Controller: `FofMenuController::communication()`, `SchoolEventController`
Model: `SchoolEvent`
Policy: `SchoolEventPolicy`

Routes: school-events CRUD + toggleStatus + trash/restore/forceDelete

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_school_events`: id, event_name, description, event_type, start_date (date), end_date (date), venue, audience, is_public (boolean), notification_sent (boolean), is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |
| BC-DB-02 | Model: SoftDeletes, casts: start_date→date, end_date→date, is_public→boolean, notification_sent→boolean, is_active→boolean. Scopes: active(), upcoming() (start_date >= today) | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `event_name` required string max:200 | FR |
| BC-VAL-02 | `description` nullable string | FR |
| BC-VAL-03 | `event_type` nullable string max:100 | FR |
| BC-VAL-04 | `start_date` required date | FR |
| BC-VAL-05 | `end_date` nullable date after_or_equal:start_date | FR |
| BC-VAL-06 | `venue` nullable string max:200 | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.school-event.viewAny` → `frontoffice.school-event.view` | Policy |
| BC-AUTH-02 | create/store gate `frontoffice.school-event.create` | Policy |
| BC-AUTH-03 | update gate `frontoffice.school-event.update` | Policy |
| BC-AUTH-04 | delete gate `frontoffice.school-event.delete` | Policy |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Upcoming section (green header) with count, Past section (gray header) | View |
| BC-BIZ-02 | Table: Title & Description, Type badge, Start & End Date, Time & Venue, Audience, Public badge, Active toggle, Actions | View |
| BC-BIZ-03 | Venue shown with location-dot icon | View |
| BC-BIZ-04 | Public events show "Yes" badge (info-subtle) | View |
| BC-BIZ-05 | Search across event_name, description, venue | Ctrl |
| BC-BIZ-06 | Status filter: All / Active (1) / Inactive (0) | View |
| BC-BIZ-07 | Past events paginated with hasPages() check | View |
| BC-BIZ-08 | Empty state: "No school events found" | View |
| BC-BIZ-09 | Status toggle Ajax → JSON success | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FOSE-P10 | Positive | View | Upcoming section (green) + Past section (gray) | Sections | test_fo_se_10 | Automated |
| TC-FOSE-P11 | Positive | View | Table columns: Title, Type, Dates, Venue, Audience, Public, Active, Actions | Rendered | test_fo_se_11 | Automated |
| TC-FOSE-P12 | Positive | View | Venue shown with location-dot icon | Icon | test_fo_se_12 | Automated |
| TC-FOSE-P13 | Positive | View | Public event shows "Yes" badge | Badge | test_fo_se_13 | Automated |
| TC-FOSE-P14 | Positive | Ctrl | Create event → stored | Created | test_fo_se_14 | Automated |
| TC-FOSE-P15 | Positive | Ctrl | Update event → updated | Updated | test_fo_se_15 | Automated |
| TC-FOSE-P16 | Positive | Ctrl | Soft delete → trashed | Deleted | test_fo_se_16 | Automated |
| TC-FOSE-P17 | Positive | Model | scopeUpcoming: start_date >= today included | Included | test_fo_se_17 | Automated |
| TC-FOSE-P18 | Positive | Model | scopeUpcoming: past start_date excluded | Excluded | test_fo_se_18 | Automated |
| TC-FOSE-P19 | Positive | View | Empty state "No school events found" | Empty | test_fo_se_19 | Automated |
| TC-FOSE-N20 | Negative | Val | end_date before start_date → after_or_equal error | Error | test_fo_se_20 | Automated |

# fo_Notice — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Notices (Notice Board)
**DB scope:** TENANT-side (`fof_notices`) · **Test style:** Browser Dusk
**Primary table:** `fof_notices` · **Module URL prefix:** `/front-office/communication?tab=notices`
**Test file:** `fo_Notice_TestCas.php`
**Tab:** Notices (second tab of Communication)

Controller: `FofMenuController::communication()`, `NoticeBoardController`
Model: `Notice`
Policy: `NoticeBoardPolicy`

Routes: notices CRUD + toggleStatus + trash/restore/forceDelete

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_notices`: id, title, content, category, audience, is_pinned (boolean), is_emergency (boolean), display_from (date), display_until (date), attachment_media_id, is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |
| BC-DB-02 | Model: SoftDeletes, HasMedia (notice_attachment, singleFile), casts: is_pinned→boolean, is_emergency→boolean, is_active→boolean, display_from→date, display_until→date. Scopes: active(), visible() | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `title` required string max:200 | FR |
| BC-VAL-02 | `content` required | FR |
| BC-VAL-03 | `category` nullable string max:100 | FR |
| BC-VAL-04 | `is_pinned` boolean | FR |
| BC-VAL-05 | `is_emergency` boolean | FR |
| BC-VAL-06 | `display_from` nullable date | FR |
| BC-VAL-07 | `display_until` nullable date after_or_equal:display_from | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.notice.viewAny` → `frontoffice.notice.view` | Policy |
| BC-AUTH-02 | create/store gate `frontoffice.notice.create` | Policy |
| BC-AUTH-03 | update gate `frontoffice.notice.update` | Policy |
| BC-AUTH-04 | delete gate `frontoffice.notice.delete` | Policy |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Table: Title (with emergency badge if applicable), Category badge, Audience badge, Display Period, Pinned badge, Active toggle, Actions | View |
| BC-BIZ-02 | Emergency notices show red badge with exclamation | View |
| BC-BIZ-03 | Pinned notices show blue badge with thumbtack icon | View |
| BC-BIZ-04 | BR-FOF-014: emergency notices visible regardless of display_until | Model scope |
| BC-BIZ-05 | Display period: "display_from — display_until" or "display_from onwards" | View |
| BC-BIZ-06 | Search by title | Ctrl |
| BC-BIZ-07 | Status filter: All / Active (1) / Inactive (0) | View |
| BC-BIZ-08 | Empty state: "No notices posted" | View |
| BC-BIZ-09 | Status toggle Ajax → JSON success | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FONO-P10 | Positive | View | Table: Title, Category, Audience, Display Period, Pinned, Active, Actions | Rendered | test_fo_no_10 | Automated |
| TC-FONO-P11 | Positive | View | Emergency badge (red + icon) on emergency notices | Badge | test_fo_no_11 | Automated |
| TC-FONO-P12 | Positive | View | Pinned badge (blue + thumbtack) on pinned notices | Badge | test_fo_no_12 | Automated |
| TC-FONO-P13 | Positive | Ctrl | Create notice → stored | Created | test_fo_no_13 | Automated |
| TC-FONO-P14 | Positive | Ctrl | Update notice → updated | Updated | test_fo_no_14 | Automated |
| TC-FONO-P15 | Positive | Ctrl | Soft delete → trashed | Deleted | test_fo_no_15 | Automated |
| TC-FONO-P16 | Positive | Model | scopeVisible: emergency visible past display_until | Visible | test_fo_no_16 | Automated |
| TC-FONO-P17 | Positive | Model | scopeVisible: non-emergency respects display_until | Hidden | test_fo_no_17 | Automated |
| TC-FONO-P18 | Negative | Val | Missing title/content → validation errors | Errors | test_fo_no_18 | Automated |
| TC-FONO-P19 | Positive | View | Empty state "No notices posted" | Empty | test_fo_no_19 | Automated |

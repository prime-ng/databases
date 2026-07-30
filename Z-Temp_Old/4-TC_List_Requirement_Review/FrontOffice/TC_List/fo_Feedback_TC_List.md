# fo_Feedback — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Feedback (Dynamic Forms + Public Submission)
**DB scope:** TENANT-side (`fof_feedback_forms`, `fof_feedback_responses`) · **Test style:** Browser Dusk
**Primary tables:** `fof_feedback_forms`, `fof_feedback_responses` · **Module URL prefix:** `/front-office/communication?tab=feedback`
**Test file:** `fo_Feedback_TestCas.php`
**Tab:** Feedback (fourth tab of Communication)

Controller: `FofMenuController::communication()`, `FeedbackController`
Models: `FeedbackForm`, `FeedbackResponse`
Policy: `FeedbackPolicy`

Routes: feedback CRUD + report + public/submit/thankyou + toggleStatus + trash/restore/forceDelete

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_feedback_forms`: id, title, description, questions_json (json), token, is_anonymous_allowed (boolean), is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |
| BC-DB-02 | `fof_feedback_responses`: id, feedback_form_id (FK), respondent_user_id, respondent_name, is_anonymous (boolean), responses_json (json), submitted_at, created_at, updated_at, deleted_at | Model |
| BC-DB-03 | Model: SoftDeletes, BaseModel. Casts: questions_json→array, is_anonymous_allowed→boolean, is_active→boolean. Relations: responses() HasMany | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `title` required string max:200 | FR |
| BC-VAL-02 | `description` nullable string | FR |
| BC-VAL-03 | `questions_json` required array (valid JSON) | FR |
| BC-VAL-04 | `is_anonymous_allowed` boolean | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.feedback.viewAny` → `frontoffice.feedback.view` | Policy |
| BC-AUTH-02 | create/store gate `frontoffice.feedback.create` | Policy |
| BC-AUTH-03 | update gate `frontoffice.feedback.update` | Policy |
| BC-AUTH-04 | delete gate `frontoffice.feedback.delete` | Policy |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Table: Title & Description, Questions count badge, Anonymous badge, Responses count, Expiry, Active toggle, Actions | View |
| BC-BIZ-02 | Questions count: "X Questions" badge (bg-light) | View |
| BC-BIZ-03 | Anonymous Yes: info-subtle badge with shield icon; No: plain badge | View |
| BC-BIZ-04 | Response count shown as centered number | View |
| BC-BIZ-05 | Report button (chart-bar icon) → route('fof.feedback.report') | View |
| BC-BIZ-06 | Public link button (link icon) → route('fof.feedback.public', token) in new tab | View |
| BC-BIZ-07 | Public form uses token; fallback to id if token null | View |
| BC-BIZ-08 | Search by title, description | Ctrl |
| BC-BIZ-09 | Status filter: All / Active (1) / Inactive (0) | View |
| BC-BIZ-10 | Empty state: "No feedback forms found" | View |
| BC-BIZ-11 | Status toggle Ajax → JSON success | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FOFB-P10 | Positive | View | Table: Title, Questions, Anonymous, Responses, Expiry, Active, Actions | Rendered | test_fo_fb_10 | Automated |
| TC-FOFB-P11 | Positive | View | Questions count badge shows correct count from JSON | Badge | test_fo_fb_11 | Automated |
| TC-FOFB-P12 | Positive | View | Anonymous Yes shows shield icon badge | Badge | test_fo_fb_12 | Automated |
| TC-FOFB-P13 | Positive | View | Responses count shown (withCount loaded) | Number | test_fo_fb_13 | Automated |
| TC-FOFB-P14 | Positive | Ctrl | Create form with questions_json → stored | Created | test_fo_fb_14 | Automated |
| TC-FOFB-P15 | Positive | Ctrl | Update form → updated | Updated | test_fo_fb_15 | Automated |
| TC-FOFB-P16 | Positive | Ctrl | Soft delete → trashed | Deleted | test_fo_fb_16 | Automated |
| TC-FOFB-P17 | Positive | View | Report button links to route('fof.feedback.report') | Link | test_fo_fb_17 | Automated |
| TC-FOFB-P18 | Positive | View | Public link opens token URL in new tab | Link | test_fo_fb_18 | Automated |
| TC-FOFB-P19 | Positive | View | Empty state "No feedback forms found" | Empty | test_fo_fb_19 | Automated |
| TC-FOFB-N20 | Negative | Val | Missing title → validation error | Error | test_fo_fb_20 | Automated |
| TC-FOFB-N21 | Negative | Val | Invalid questions_json → validation error | Error | test_fo_fb_21 | Automated |

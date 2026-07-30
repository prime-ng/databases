# fo_CommunicationLog — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Email & SMS Logs (Communication History)
**DB scope:** TENANT-side (`fof_communication_logs`, `fof_sms_logs`, `fof_email_templates`) · **Test style:** Browser Dusk
**Primary tables:** `fof_communication_logs`, `fof_sms_logs` · **Module URL prefix:** `/front-office/communication?tab=email-sms`
**Test file:** `fo_CommunicationLog_TestCas.php`
**Tab:** Email & SMS Logs (fifth tab of Communication)

Controller: `FofMenuController::communication()`, `CommunicationController`
Models: `CommunicationLog`, `SmsLog`, `EmailTemplate`
Policy: `CommunicationPolicy`

Routes: communication email.send, sms.send, email.logs, sms.logs, email.templates + template toggleStatus

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_communication_logs`: id, channel (Email/SMS), subject, body, recipient_group, template_id, total_recipients, sent_count, failed_count, sent_at, is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |
| BC-DB-02 | `fof_sms_logs`: id, communication_log_id (FK), recipient_user_id, mobile_number, message, sms_units, status, gateway_response, sent_at, created_at, updated_at, deleted_at | Model |
| BC-DB-03 | `fof_email_templates`: id, name, subject, body, module, is_active, created_at, updated_at, deleted_at | Model |
| BC-DB-04 | Model: SoftDeletes. Casts: total_recipients→int, sent_count→int, failed_count→int, is_active→boolean. Relation: smsLogs() HasMany | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `recipient_group` (email) required in:All_Parents,All_Staff,All_Students,Custom | View |
| BC-VAL-02 | `recipient_group` (sms) required in:All_Parents,All_Staff,All_Students,Custom_Numbers | View |
| BC-VAL-03 | `subject` (email) required max:255 | View |
| BC-VAL-04 | `body` (email) required | View |
| BC-VAL-05 | `body` (sms) required max:160 | View |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.communication.viewAny` → `frontoffice.communication.view` | Policy |
| BC-AUTH-02 | create/send gate `frontoffice.communication.create` | Policy |
| BC-AUTH-03 | Channel filter (All / Email / SMS) | View |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Two-column layout: Recent Emails (left), Recent SMS (right) | View |
| BC-BIZ-02 | Email card: Subject, To (recipient_group), Status badge, Sent time (diffForHumans) | View |
| BC-BIZ-03 | SMS card: Message, To (recipient_group), Status badge, Sent time (diffForHumans) | View |
| BC-BIZ-04 | Compose modal with Email/SMS channel tabs (nav-pills) | View |
| BC-BIZ-05 | Email pane: recipient_group dropdown, subject, body textarea | View |
| BC-BIZ-06 | SMS pane: recipient_group dropdown, body textarea (max 160) | View |
| BC-BIZ-07 | SMS body has form hint "Max 160 characters per SMS" | View |
| BC-BIZ-08 | "View all email logs" link → route('fof.communication.email.logs') | View |
| BC-BIZ-09 | "View all SMS logs" link → route('fof.communication.sms.logs') | View |
| BC-BIZ-10 | Empty states: "No emails sent yet." / "No SMS sent yet." | View |
| BC-BIZ-11 | Channel filter (All/Email/SMS) + search | View |
| BC-BIZ-12 | Logs paginated within compact card layout | View |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FOCL-P10 | Positive | View | Two-column layout: Email left, SMS right | Layout | test_fo_cl_10 | Automated |
| TC-FOCL-P11 | Positive | View | Email card: Subject, Recipient Group, Status, Sent time | Card | test_fo_cl_11 | Automated |
| TC-FOCL-P12 | Positive | View | SMS card: Message, Recipient Group, Status, Sent time | Card | test_fo_cl_12 | Automated |
| TC-FOCL-P13 | Positive | View | Compose modal opens with Email/SMS pill tabs | Modal | test_fo_cl_13 | Automated |
| TC-FOCL-P14 | Positive | Ctrl | Send email via modal → stored in communication log | Sent | test_fo_cl_14 | Automated |
| TC-FOCL-P15 | Positive | Ctrl | Send SMS via modal → stored in communication log | Sent | test_fo_cl_15 | Automated |
| TC-FOCL-P16 | Positive | View | "View all" links to full log pages | Links | test_fo_cl_16 | Automated |
| TC-FOCL-P17 | Negative | Val | SMS body > 160 chars → max validation error | Error | test_fo_cl_17 | Automated |
| TC-FOCL-P18 | Negative | Val | Missing subject (email) → validation error | Error | test_fo_cl_18 | Automated |
| TC-FOCL-P19 | Positive | View | Empty states: "No emails sent yet." / "No SMS sent yet." | Empty | test_fo_cl_19 | Automated |
| TC-FOCL-P20 | Positive | View | Channel filter (All/Email/SMS) filters logs | Filtered | test_fo_cl_20 | Automated |

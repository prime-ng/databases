# Complaint Management Module - Testing & QA (Deliverable F)

## 1. Developer Checklist

### 1.1 SLA Engine
- [ ] **Calculation**: Verify `resolution_due_at` = `created_at` + `category.sla_hours`.
- [ ] **Escalation Job**: Verify cron job correctly identifies expired tickets (`resolution_due_at < NOW()`) and bumps `current_level`.
- [ ] **Holiday Handling**: Start date + 24 hours should skip Sundays (if configured).

### 1.2 Access Control
- [ ] **Complainant**: Can ONLY see tickets where `complainant_user_id` matches theirs.
- [ ] **Assignee**: Can see tickets where `assigned_to_user_id` matches theirs OR `assigned_to_role_id` matches.
- [ ] **Admin**: Can see ALL tickets.

---

## 2. QA Test Cases (Table-Driven)

| ID | Scenario | Pre-Condition | Steps | Expected Result | Severity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-01** | **Lodge Public Complaint** | User Not Logged In | 1. Open Public Portal.<br>2. Fill Form (Name, Mobile, Issue).<br>3. Submit. | Ticket Created. `is_anonymous`=0. Complainant Name stored. | High |
| **TC-02** | **SLA Calculation Support** | Category SLA = 4h | 1. Create Ticket at 10:00 AM. | `resolution_due_at` should be 02:00 PM same day. | Critical |
| **TC-03** | **Auto Escalation** | Ticket Open > 24h | 1. Mock time to +25h.<br>2. Run `php artisan sla:check`. | Ticket `current_level` changes 1->2. Assigned to L2 Role. | Critical |
| **TC-04** | **Restricted Media** | User is Student | 1. Try to view `cmp_medical_checks` file. | 403 Forbidden. (Only Safety Officer can view medical files). | Medium |
| **TC-05** | **Re-open Ticket** | Ticket Closed | 1. User clicks "Reopen".<br>2. Add Reason. | Status -> In Progress. `resolution_due_at` recalculated (e.g. +2h). | High |
| **TC-06** | **AI Sentiment** | AI Service Down | 1. Create Ticket.<br>2. AI API fails. | Ticket Created successfully. `sentiment_score` is NULL (Graceful degradation). | Low |

---

## 3. Security Testing
- **IDOR**: Try to access `GET /complaints/105` as a user who didn't create it. Expect 403.
- **XSS**: Input `<script>alert(1)</script>` in Complaint Description. Expect sanitized output.

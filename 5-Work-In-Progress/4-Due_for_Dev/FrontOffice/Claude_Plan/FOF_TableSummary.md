# FOF — Front Office Module Table Summary
**Module:** FrontOffice | **Prefix:** `fof_*` | **Database:** `tenant_db`
**Total Tables:** 22 | **Generated:** 2026-03-27

---

## Table Inventory (22 tables)

| # | Table | One-Line Description |
|---|-------|---------------------|
| 1 | `fof_visitor_purposes` | Lookup master for visit purposes (seeded); `is_government_visit` flag drives permanent retention per BR-FOF-007 |
| 2 | `fof_visitors` | Visitor register replacing paper visitor book; VP-YYYYMMDD-NNN pass number; In/Out/Overstay lifecycle |
| 3 | `fof_gate_passes` | Student/staff early exit authorizations with GP-YYYYMMDD-NNN; approval FSM; parent NTF per BR-FOF-003 |
| 4 | `fof_early_departures` | Mid-day student pickup by parent/guardian; ED-YYYYMMDD-NNN; ATT sync status tracked per BR-FOF-013 |
| 5 | `fof_phone_diary` | Incoming/outgoing call log with action-required flag and follow-up completion tracking |
| 6 | `fof_postal_register` | Inward/outward mail register (IN-YYYY-NNNN / OUT-YYYY-NNNN); locked after acknowledgement per BR-FOF-009 |
| 7 | `fof_dispatch_register` | Official outgoing correspondence log (DSP-YYYY-NNNN); dispatch mode and reference tracking |
| 8 | `fof_emergency_contacts` | External emergency contact directory (hospital, police, fire, transport) with type-based grouping |
| 9 | `fof_circulars` | School circulars with Draft→Approved→Distributed FSM; edit locked after Approved per BR-FOF-008 |
| 10 | `fof_circular_distributions` | Append-only per-recipient delivery log for circulars (Email/SMS/Push); no soft delete |
| 11 | `fof_notices` | Digital notice board with pinning, emergency bypass, display date control, and audience targeting |
| 12 | `fof_school_events` | Public-facing school calendar events (PTM, Sports Day, Annual Function) with NTF blast flag |
| 13 | `fof_appointments` | Meeting slot scheduling (parent-teacher, principal); slot conflict index; APT-YYYYMMDD-NNN |
| 14 | `fof_lost_found` | Lost and found item register (LF-YYYY-NNNN); status tracks Unclaimed→Claimed/Disposed |
| 15 | `fof_key_register` | Physical key issue/return log with overdue status; NULL issued_to_user_id = key available |
| 16 | `fof_certificate_requests` | Certificate requests (Bonafide/TC/Migration etc.); FIN fee check; DomPDF issuance; cert_number UNIQUE NULL |
| 17 | `fof_complaints` | Front-office lightweight complaint intake (FOF-CMP-YYYY-NNNNN); escalates to CMP module |
| 18 | `fof_feedback_forms` | Feedback form definitions with JSON questions and public token URL; anonymous support |
| 19 | `fof_feedback_responses` | Individual form responses; supports anonymous submissions (respondent_user_id NULL per BR-FOF-010) |
| 20 | `fof_email_templates` | Reusable email templates with `{{placeholder}}` syntax for bulk communication |
| 21 | `fof_communication_logs` | Bulk email/SMS campaign audit log with total/sent/failed recipient counters |
| 22 | `fof_sms_logs` | Per-recipient SMS delivery tracking with gateway response; sms_units for multi-part messages |

---

## Dependency Layer Map

```
Layer 1 (7 tables — no fof_* deps)
  fof_visitor_purposes
  fof_emergency_contacts
  fof_notices               → sys_media (attachment_media_id)
  fof_school_events
  fof_email_templates
  fof_feedback_forms
  fof_key_register          → sys_users (issued_to_user_id)

Layer 2 (10 tables — deps on Layer 1 + cross-module)
  fof_visitors              → fof_visitor_purposes, sys_users, sys_media
  fof_gate_passes           → std_students, sys_users (×2)
  fof_early_departures      → std_students
  fof_phone_diary           → sys_users (×2)
  fof_postal_register       → sys_users
  fof_dispatch_register     → sys_users
  fof_appointments          → sys_users (×2)
  fof_lost_found            → sys_users, sys_media
  fof_certificate_requests  → std_students, sys_users (×2), sys_media
  fof_complaints            → sys_users (×2), cmp_complaints

Layer 3 (2 tables — deps on Layer 2)
  fof_circulars             → sys_users (×2), sys_media
  fof_feedback_responses    → fof_feedback_forms, sys_users

Layer 4 (3 tables — deps on Layer 3)
  fof_circular_distributions → fof_circulars, sys_users
  fof_communication_logs    → fof_email_templates
  fof_sms_logs              → fof_communication_logs, sys_users
```

---

## Cross-Module FK Type Reference

| FK Column | Host Table | References | Type | Note |
|-----------|-----------|------------|------|------|
| `purpose_id` | fof_visitors | fof_visitor_purposes.id | BIGINT UNSIGNED | Internal fof_* ref |
| `feedback_form_id` | fof_feedback_responses | fof_feedback_forms.id | BIGINT UNSIGNED | Internal fof_* ref |
| `circular_id` | fof_circular_distributions | fof_circulars.id | BIGINT UNSIGNED | Internal fof_* ref |
| `template_id` | fof_communication_logs | fof_email_templates.id | BIGINT UNSIGNED | Internal fof_* ref |
| `communication_log_id` | fof_sms_logs | fof_communication_logs.id | BIGINT UNSIGNED | Internal fof_* ref |
| `meet_user_id`, `staff_user_id`, `approved_by`, etc. | various | sys_users.id | **INT UNSIGNED** | sys_users PK = INT |
| `student_id` | fof_gate_passes, fof_early_departures, fof_certificate_requests | std_students.id | **INT UNSIGNED** | std_students PK = INT |
| `photo_media_id`, `attachment_media_id`, `media_id` | various | sys_media.id | **INT UNSIGNED** | sys_media PK = INT |
| `cmp_complaint_id` | fof_complaints | cmp_complaints.id | **INT UNSIGNED** | cmp_complaints PK = INT |
| `vsm_visitor_id` | fof_visitors | vsm_visitors.id | BIGINT UNSIGNED | FK omitted — VSM module pending |

---

## Cross-Module WRITE Relationships

| Trigger | FOF Action | External Module | Notes |
|---------|-----------|-----------------|-------|
| `fof_early_departures` saved | `EarlyDepartureService::syncAttendance()` | ATT | Marks student absent for remaining periods; retry on failure via `EarlyDepartureAttSyncJob`; updates `att_sync_status` |
| `fof_circulars` Distributed | `CircularService::distribute()` | NTF | Dispatches email+SMS per resolved recipient; creates `fof_circular_distributions` rows |
| `fof_gate_passes` created (Student) | `GatePassService::createPass()` | NTF | Dispatches parent notification; sets `parent_notified=1` |
| `fof_certificate_requests` TC_Copy/Migration issued | `CertificateIssuanceService::issue()` | FIN | Fee clearance check before issuance; blocks if outstanding fees exist |
| `fof_complaints` escalated | `ComplaintController::escalate()` | CMP | Creates CMP complaint; sets `cmp_complaint_id`; status → Escalated |

---

## Special Design Notes

| Rule | Table | Design Decision |
|------|-------|----------------|
| BR-FOF-007 — Govt visit permanent retention | `fof_visitor_purposes.is_government_visit` | `VisitorPolicy::delete()` blocks deletion when purpose has `is_government_visit=1` |
| BR-FOF-006 — Cert number unique | `fof_certificate_requests.cert_number` | `VARCHAR(30) NULL UNIQUE` — MySQL UNIQUE allows multiple NULLs; NULL until cert issued |
| BR-FOF-013 — ATT sync failure alert | `fof_early_departures.att_sync_status` | `ENUM(Pending,Synced,Failed)` + front desk flash alert + `EarlyDepartureAttSyncJob` 3 retries |
| Append-only distribution log | `fof_circular_distributions` | No `deleted_at`, no `updated_by` — immutable per-send log |
| Anonymous feedback | `fof_feedback_responses.respondent_user_id` | `INT UNSIGNED NULL`; `created_by DEFAULT 0` for anonymous rows |

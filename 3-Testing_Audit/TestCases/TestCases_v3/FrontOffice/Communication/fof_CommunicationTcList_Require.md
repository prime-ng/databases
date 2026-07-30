# FrontOffice :: Communication — Test Case List & Manual Test Spec (COMBINED)

> Combined artifact: Feature Information + Business Conditions + Test Case List + Test Method Index + Manual Test Steps (workflow/complex only) + Known Source Defects.
> Sources read: `communication.md` (screen requirement), `FrontOffice_DDL_v1.sql` (tables 5, 21, 22), `CommunicationController.php`, `routes/web.php`, models `CommunicationLog`/`EmailTemplate`/`SmsLog`, blades `fof/communication/*`, `FrontOffice_FactPack.md`, `FrontOffice_Technical_Audit_2026-06-29.md`, `app/Helpers/activityLog.php`.

---

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | FrontOffice (FOF) |
| Feature | Communication (Email & SMS) |
| Prefix | `fof_` (verified vs DDL `CREATE TABLE`) |
| Primary tables | `fof_communication_logs`, `fof_email_templates`, `fof_sms_logs` |
| Controller | `Modules\FrontOffice\Http\Controllers\CommunicationController` (also `FofMenuController@communication` for the `email-sms` tab) |
| Models | `CommunicationLog`, `EmailTemplate`, `SmsLog` (all `extends BaseModel`, `SoftDeletes`, `$table` verified) |
| Validation | **INLINE `$request->validate()`** in the controller — NO FormRequest class exists for Communication |
| Routes (name base `fof.`, path base `/front-office`) | `communication.email.compose` (GET), `communication.email.send` (POST), `communication.email.templates` (GET), `communication.email.templates.toggleStatus` (POST\|PATCH), `communication.email.logs` (GET), `communication.sms.send` (POST), `communication.sms.logs` (GET), `menu.communication` (GET) |
| CRUD type | Action-log style: send actions create `fof_communication_logs` rows; templates are list + toggle only (NO create/edit/delete); logs are read-only lists |
| Soft delete | Yes on all three models/tables (`deleted_at`) — but NO trash/restore/force-delete routes are registered for Communication |
| Pagination | Templates 20/page; email logs & sms logs 25/page |
| Activity log | Sink `sys_activity_logs` via `activityLog()` → `Modules\GlobalMaster\Models\ActivityLog`. Events **verbatim**: `email_queued` (emailSend), `sms_queued` (smsSend). `toggleStatus` logs NOTHING. |
| Permissions | `frontoffice.communication.create` (compose/send), `frontoffice.communication.view` (templates/logs/menu), `frontoffice.communication.update` (toggle). String `Gate::authorize()`; Super Admin bypass via `Gate::before`. |
| DB scope | TENANT-SIDE (all `fof_*`; tenancy init required) |

**Inline validation rules (verbatim):**
- `emailSend`: `recipient_group` required\|string\|max:100; `subject` required\|string\|**max:255**; `body` required\|string; `template_id` nullable\|integer\|exists:fof_email_templates,id
- `smsSend`: `recipient_group` required\|string\|max:100; `body` required\|string\|**max:1000**

**Programmatically-managed (G48 — NOT form inputs):** `channel`, `subject`(null for SMS), `template_id`(null for SMS), `total_recipients`/`sent_count`/`failed_count`(always 0), `created_by`/`updated_by`(= `auth()->id()`). `fof_sms_logs` rows are NOT created by the controller at all (queue-job territory, absent).

---

## 2. Business Conditions

### BC-DB — DDL constraints (one testable fact each; G43–G46)
| ID | Fact | Source |
|----|------|--------|
| BC-DB-01 | `fof_communication_logs` columns/types/defaults match model + LIVE schema | DDL-communication_logs |
| BC-DB-02 | CL NOT-NULL-no-default: `channel`, `body`, `recipient_group` → missing rejected | DDL-communication_logs |
| BC-DB-03 | CL nullable: `template_id`, `subject`, `sent_at` → omission persists | DDL-communication_logs |
| BC-DB-04 | CL defaults: `total_recipients=0`, `sent_count=0`, `failed_count=0`, `is_active=1` | DDL-communication_logs |
| BC-DB-05 | CL `subject` VARCHAR(300), `recipient_group` VARCHAR(100) → over-length rejected/truncated, exact ok | DDL-communication_logs |
| BC-DB-06 | CL `channel` ENUM('Email','SMS') → invalid rejected | DDL-communication_logs |
| BC-DB-07 | CL `template_id` FK → `fof_email_templates` ON DELETE SET NULL | DDL-communication_logs |
| BC-DB-08 | CL NO UNIQUE key (duplicates permitted) | DDL-communication_logs |
| BC-DB-09 | `fof_email_templates` NOT-NULL-no-default: `name`, `subject`, `body` → missing rejected | DDL-email_templates |
| BC-DB-10 | ET nullable `module`; default `is_active=1` | DDL-email_templates |
| BC-DB-11 | ET sized: `name`(100), `subject`(300), `module`(50) | DDL-email_templates |
| BC-DB-12 | `fof_sms_logs` NOT-NULL-no-default: `communication_log_id`, `recipient_user_id`, `mobile_number`, `message` | DDL-sms_logs |
| BC-DB-13 | SL defaults: `sms_units=1`, `status='Queued'`, `is_active=1` | DDL-sms_logs |
| BC-DB-14 | SL `mobile_number` VARCHAR(15) → boundary | DDL-sms_logs |
| BC-DB-15 | SL `status` ENUM('Queued','Sent','Delivered','Failed') → invalid rejected | DDL-sms_logs |
| BC-DB-16 | SL `communication_log_id` FK RESTRICT; `recipient_user_id` FK → `sys_users` RESTRICT | DDL-sms_logs |
| BC-DB-17 | All three tables have `deleted_at` + `SoftDeletes` (asserted independently) | DDL / model |

### BC-VAL — validation
| ID | Fact | Source |
|----|------|--------|
| BC-VAL-01 | emailSend rejects missing `recipient_group`/`subject`/`body` | Controller-emailSend |
| BC-VAL-02 | emailSend `subject` capped at 255 (< DDL 300) | Controller-emailSend / DEV-FOF-COM-01 |
| BC-VAL-03 | smsSend rejects missing `recipient_group`/`body` | Controller-smsSend |
| BC-VAL-04 | smsSend `body` capped at 1000 (≠ 640 spec) | Controller-smsSend / DEV-FOF-COM-02 |
| BC-VAL-05 | `template_id` must exist in `fof_email_templates` (nullable) | Controller-emailSend |

### BC-AUTH — authorization
| ID | Fact | Source |
|----|------|--------|
| BC-AUTH-01 | Guest → redirect `/login` | routes middleware auth |
| BC-AUTH-02 | `create` required for compose/emailSend/smsSend | Controller gates |
| BC-AUTH-03 | `view` required for templates/emailLogs/smsLogs/menu | Controller gates |
| BC-AUTH-04 | `update` required for toggleStatus | Controller gate |
| BC-AUTH-05 | Super Admin bypasses all gates (`Gate::before`) — negatives need a non-super-admin + cache flush | Rule Card #31 |

### BC-BIZ — business rules
| ID | Fact | Source |
|----|------|--------|
| BC-BIZ-01 | emailSend creates a CL with `channel='Email'` | Controller-emailSend |
| BC-BIZ-02 | smsSend creates a CL with `channel='SMS'`, `subject=NULL` | Controller-smsSend |
| BC-BIZ-03 | `scopeActive()` (CL & ET) excludes `is_active=0` | Models |
| BC-BIZ-04 | emailLogs shows only `channel='Email'`; smsLogs only `channel='SMS'` | Controller queries |
| BC-BIZ-05 | Email template picker loads only active templates (compose) | Controller-emailCompose |
| BC-BIZ-06 | BR-FOF-011 multi-unit SMS (ceil(len/160), max 4=640) is NOT implemented | Screen-BR / DEV-FOF-COM-02 |

### BC-SM — state machine
| ID | State → Trigger → Next | Source |
|----|-----------------------|--------|
| BC-SM-01 | ET `is_active=1` → toggleStatus → `is_active=0` (legal) | Controller-toggleStatus |
| BC-SM-02 | ET `is_active=0` → toggleStatus → `is_active=1` (legal reverse) | Controller-toggleStatus |
| BC-SM-03 | SL `status` accepts Queued/Sent/Delivered/Failed (legal set) | DDL-sms_logs |
| BC-SM-04 | SL `status` rejects any value outside the ENUM (illegal) | DDL-sms_logs |
| BC-SM-05 | CL `channel` accepts Email/SMS, rejects other (illegal) | DDL-communication_logs |

### BC-REF / BC-INT — integration/FK
| ID | Fact | Source |
|----|------|--------|
| BC-REF-01 | Invalid `template_id` on CL rejected (FK) | DDL FK |
| BC-REF-02 | Deleting a template SET NULLs `CL.template_id` | DDL FK |
| BC-REF-03 | Parent CL cannot be hard-deleted while SL children exist (RESTRICT) | DDL FK |
| BC-REF-04 | Invalid `recipient_user_id` on SL rejected (FK → sys_users) | DDL FK |

### BC-AUTO — auto-managed (G48)
| ID | Fact | Source |
|----|------|--------|
| BC-AUTO-01 | `created_by`/`updated_by` = `auth()->id()` on send | Controller |
| BC-AUTO-02 | Counters (`total_recipients`/`sent_count`/`failed_count`) forced to 0 (stub) | Controller / DEV-FOF-COM-04 |
| BC-AUTO-03 | Activity `email_queued`/`sms_queued` written to `sys_activity_logs` | Helper |

### BC-EDG / BC-SEC
| ID | Fact | Source |
|----|------|--------|
| BC-EDG-01 | CL `body` TEXT / ET `body` LONGTEXT accept long content | DDL |
| BC-EDG-02 | Soft delete + restore round-trip works at model level | Models |
| BC-SEC-01 | Stored XSS in CL `subject` is escaped on logs page | Security |

---

## 3. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01/17 | DDL | Full DDL↔app alignment (3 tables) | All assertions pass | test_01 | Ready |
| TC-P02 | BC-DB-03 | DDL | CL nullable cols omitted persist | Row saved, cols NULL | test_03 | Ready |
| TC-P03 | BC-DB-04 | DDL | CL defaults applied | Counters 0, active 1 | test_04 | Ready |
| TC-P04 | BC-DB-10 | DDL | ET nullable module + default active | module NULL, active 1 | test_06 | Ready |
| TC-P05 | BC-DB-13 | DDL | SL defaults applied | units 1, status Queued | test_08 | Ready |
| TC-P06 | BC-DB casts | DDL | Casts typed values | int/bool/datetime | test_09 | Ready |
| TC-P07 | BC-BIZ-01 | Ctrl | emailSend → Email CL | channel Email | test_10 | Ready |
| TC-P08 | BC-BIZ-02 | Ctrl | smsSend → SMS CL | channel SMS, subj NULL | test_11 | Ready |
| TC-P09 | BC-BIZ-03 | Model | CL active scope | inactive excluded | test_12 | Ready |
| TC-P10 | BC-BIZ-04 | Ctrl | Channel query separation | correct partition | test_13 | Ready |
| TC-P11 | BC-BIZ-05 | Model | ET active scope | inactive excluded | test_14 | Ready |
| TC-P12 | BC-SM-01 | Ctrl | Toggle deactivate | active→inactive JSON ok | test_20 | Ready |
| TC-P13 | BC-SM-02 | Ctrl | Toggle reactivate | inactive→active | test_21 | Ready |
| TC-P14 | BC-SM-03 | DDL | SL status legal set | all 4 accepted | test_22 | Ready |
| TC-P15 | BC-SM-05 | DDL | CL channel legal set | Email/SMS accepted | test_24 | Ready |
| TC-P16 | BC-DB-11 | DDL | ET name/subject/module exact-length ok | persisted intact | test_34/35/36 | Ready |
| TC-P17 | BC-DB-05 | DDL | CL recipient_group/subject exact ok | persisted intact | test_37/38 | Ready |
| TC-P18 | BC-DB-14 | DDL | SL mobile_number exactly 15 ok | persisted | test_39 | Ready |
| TC-P19 | BC-REF-02 | DDL | Template delete SET NULLs CL | template_id NULL | test_41 | Ready |
| TC-P20 | BC-AUTO-01 | Ctrl | created_by/updated_by set on send | = acting user | test_45 | Ready |
| TC-P21 | BC-AUTH pages | Ctrl | compose/templates/logs/menu render | forms/rows visible | test_60/61/62/63/64 | Ready |
| TC-P22 | BC-EDG-02 | Model | ET soft-delete + restore | deleted_at set→null | test_71 | Ready |
| TC-P23 | BC-EDG-01 | DDL | TEXT/LONGTEXT long content | stored intact | test_73 | Ready |
| TC-P24 | BC-DB-13 | DDL | SL multi-unit sms_units persists | stores 4 | test_74 | Ready |
| TC-P25 | BC-AUTO-03 | Helper | Activity email_queued written | row in sys_activity_logs | test_91 | Ready |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-DB-02 | DDL | CL missing channel/body/recipient_group | DB rejects | test_02 | Ready |
| TC-N02 | BC-DB-09 | DDL | ET missing name/subject/body | DB rejects | test_05 | Ready |
| TC-N03 | BC-DB-12 | DDL | SL missing required cols | DB/FK rejects | test_07 | Ready |
| TC-N04 | BC-SM-04 | DDL | SL invalid status | not stored canonically | test_23 | Ready |
| TC-N05 | BC-SM-05 | DDL | CL invalid channel | not stored canonically | test_24 | Ready |
| TC-N06 | BC-VAL-01 | Ctrl | emailSend missing fields | {302,422,419,404,500} | test_30 | Ready |
| TC-N07 | BC-VAL-03 | Ctrl | smsSend missing fields | {302,422,419,404,500} | test_32 | Ready |
| TC-N08 | BC-DB-11 | DDL | ET over-length name/subject/module | rejected/truncated | test_34/35/36 | Ready |
| TC-N09 | BC-DB-05 | DDL | CL over-length recipient_group/subject | rejected/truncated | test_37/38 | Ready |
| TC-N10 | BC-DB-14 | DDL | SL over-length mobile_number | rejected/truncated | test_39 | Ready |
| TC-N11 | BC-REF-01 | DDL | CL invalid template_id | FK error | test_40 | Ready |
| TC-N12 | BC-REF-03 | DDL | Delete CL with SL child | RESTRICT blocks | test_42 | Ready |
| TC-N13 | BC-REF-04 | DDL | SL invalid recipient_user_id | FK error | test_43 | Ready |
| TC-N14 | BC-AUTH-01 | routes | Guest hits compose | redirect /login | test_50 | Ready |
| TC-N15 | BC-AUTH-02 | Ctrl | Limited user compose | 403 | test_51 | Ready |
| TC-N16 | BC-AUTH-03 | Ctrl | Limited user templates/logs | 403 | test_52 | Ready |
| TC-N17 | BC-AUTH-02 | Ctrl | Limited user emailSend | 403/419 | test_53 | Ready |
| TC-N18 | BC-AUTH-02 | Ctrl | Limited user smsSend | 403/419 | test_54 | Ready |
| TC-N19 | BC-AUTH-04 | Ctrl | Limited user toggle | 403/419 | test_55 | Ready |
| TC-N20 | BC-SEC-01 | Sec | Stored XSS in subject | escaped on logs page | test_90 | Ready |
| TC-N21 | BC-DB-08 | DDL | No UNIQUE index on any table | uniqueIndexCount=0 | test_01 | Ready |

### Dependency (TC-D)
| TC ID | Sub | BC | Description | Method |
|-------|-----|----|-------------|--------|
| TC-D01 | FK-SET-NULL | BC-REF-02 | template delete SET NULL on CL | test_41 |
| TC-D02 | FK-RESTRICT | BC-REF-03 | CL delete blocked by SL child | test_42 |
| TC-D03 | FK cross-module | BC-REF-04 | SL→sys_users FK enforced | test_43 |
| TC-D04 | FK-declared | BC-DB-07/16 | SHOW CREATE TABLE FK inspection | test_44 |
| TC-D05 | activity-sink | BC-AUTO-03 | sys_activity_logs write path | test_91 |

### DEV proving tests (TC-DEV)
| TC ID | Defect | Description | Method |
|-------|--------|-------------|--------|
| TC-DEV01 | DEV-FOF-COM-01 | subject max:255 < DDL 300 | test_31 |
| TC-DEV02 | DEV-FOF-COM-02 | multi-unit SMS unimplemented; body max 1000 | test_15/33 |
| TC-DEV03 | DEV-FOF-COM-03 | permission keys diverge from requirement (.email/.sms) | test_92 |
| TC-DEV04 | DEV-FOF-COM-04 | send is a stub (no Mail dispatch, no SmsLog rows, counters 0) | test_93 (+10 counters) |
| TC-DEV05 | DEV-FOF-COM-05 | template CRUD incomplete (no store/update/destroy) | test_94 |

---

## 4. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_communication_01_migration_model_and_config_are_correct | TC-P01/N21 | Schema | 01-09 |
| 2 | test_communication_02_comm_log_required_columns_reject_missing | TC-N01 | Schema/Neg | 01-09 |
| 3 | test_communication_03_comm_log_nullable_columns_accept_omitted | TC-P02 | Schema/Pos | 01-09 |
| 4 | test_communication_04_comm_log_defaults_applied_on_create | TC-P03 | Schema/Pos | 01-09 |
| 5 | test_communication_05_email_template_required_columns_reject_missing | TC-N02 | Schema/Neg | 01-09 |
| 6 | test_communication_06_email_template_nullable_and_default | TC-P04 | Schema/Pos | 01-09 |
| 7 | test_communication_07_sms_log_required_columns_reject_missing | TC-N03 | Schema/Neg | 01-09 |
| 8 | test_communication_08_sms_log_defaults_applied_on_create | TC-P05 | Schema/Pos | 01-09 |
| 9 | test_communication_09_casts_return_typed_values | TC-P06 | Schema | 01-09 |
| 10 | test_communication_10_email_send_creates_email_channel_log | TC-P07 | BC-BIZ | 10-19 |
| 11 | test_communication_11_sms_send_creates_sms_channel_log | TC-P08 | BC-BIZ | 10-19 |
| 12 | test_communication_12_active_scope_excludes_inactive_logs | TC-P09 | BC-BIZ | 10-19 |
| 13 | test_communication_13_channel_query_separation | TC-P10 | BC-BIZ | 10-19 |
| 14 | test_communication_14_template_active_scope_excludes_inactive | TC-P11 | BC-BIZ | 10-19 |
| 15 | test_communication_15_sms_multiunit_rule_is_not_implemented | TC-DEV02 | BC-BIZ/DEV | 10-19 |
| 16 | test_communication_20_template_toggle_status_deactivates | TC-P12 | BC-SM | 20-29 |
| 17 | test_communication_21_template_toggle_status_reactivates | TC-P13 | BC-SM | 20-29 |
| 18 | test_communication_22_sms_log_status_enum_accepts_legal_states | TC-P14 | BC-SM | 20-29 |
| 19 | test_communication_23_sms_log_status_enum_rejects_illegal | TC-N04 | BC-SM/Neg | 20-29 |
| 20 | test_communication_24_comm_log_channel_enum_boundary | TC-P15/N05 | BC-SM | 20-29 |
| 21 | test_communication_30_email_send_rejects_missing_required | TC-N06 | BC-VAL | 30-39 |
| 22 | test_communication_31_email_send_subject_max_255_divergence | TC-DEV01 | BC-VAL/DEV | 30-39 |
| 23 | test_communication_32_sms_send_rejects_missing_required | TC-N07 | BC-VAL | 30-39 |
| 24 | test_communication_33_sms_send_body_cap_exceeds_spec | TC-DEV02 | BC-VAL/DEV | 30-39 |
| 25 | test_communication_34_template_name_length_boundary | TC-P16/N08 | BC-VAL | 30-39 |
| 26 | test_communication_35_template_subject_length_boundary | TC-P16/N08 | BC-VAL | 30-39 |
| 27 | test_communication_36_template_module_length_boundary | TC-P16/N08 | BC-VAL | 30-39 |
| 28 | test_communication_37_comm_log_recipient_group_length_boundary | TC-P17/N09 | BC-VAL | 30-39 |
| 29 | test_communication_38_comm_log_subject_length_boundary | TC-P17/N09 | BC-VAL | 30-39 |
| 30 | test_communication_39_sms_log_mobile_number_length_boundary | TC-P18/N10 | BC-VAL | 30-39 |
| 31 | test_communication_40_comm_log_template_fk_enforced | TC-N11 | BC-REF | 40-49 |
| 32 | test_communication_41_template_delete_sets_log_template_id_null | TC-P19/D01 | BC-REF | 40-49 |
| 33 | test_communication_42_sms_log_parent_delete_restricted | TC-N12/D02 | BC-REF | 40-49 |
| 34 | test_communication_43_sms_log_recipient_fk_enforced | TC-N13/D03 | BC-REF | 40-49 |
| 35 | test_communication_44_foreign_keys_declared | TC-D04 | BC-REF | 40-49 |
| 36 | test_communication_45_created_by_is_set_by_controller_on_send | TC-P20 | BC-AUTO | 40-49 |
| 37 | test_communication_50_guest_redirected_to_login | TC-N14 | BC-AUTH | 50-59 |
| 38 | test_communication_51_compose_requires_create_permission | TC-N15 | BC-AUTH | 50-59 |
| 39 | test_communication_52_view_pages_require_view_permission | TC-N16 | BC-AUTH | 50-59 |
| 40 | test_communication_53_email_send_requires_create_permission | TC-N17 | BC-AUTH | 50-59 |
| 41 | test_communication_54_sms_send_requires_create_permission | TC-N18 | BC-AUTH | 50-59 |
| 42 | test_communication_55_toggle_status_requires_update_permission | TC-N19 | BC-AUTH | 50-59 |
| 43 | test_communication_60_compose_page_loads | TC-P21 | UI | 60-69 |
| 44 | test_communication_61_templates_page_lists_records | TC-P21 | UI | 60-69 |
| 45 | test_communication_62_email_logs_page_lists_records | TC-P21 | UI | 60-69 |
| 46 | test_communication_63_sms_logs_page_loads | TC-P21 | UI | 60-69 |
| 47 | test_communication_64_menu_email_sms_tab_loads | TC-P21 | UI | 60-69 |
| 48 | test_communication_70_comm_log_soft_and_force_delete | TC-P22 | Edge | 70-79 |
| 49 | test_communication_71_email_template_soft_delete_and_restore | TC-P22 | Edge | 70-79 |
| 50 | test_communication_72_sms_log_soft_delete | TC-P22 | Edge | 70-79 |
| 51 | test_communication_73_text_columns_accept_long_content | TC-P23 | Edge | 70-79 |
| 52 | test_communication_74_sms_units_multi_unit_persists | TC-P24 | Edge | 70-79 |
| 53 | test_communication_90_stored_xss_in_subject_is_escaped | TC-N20 | Security | 90-99 |
| 54 | test_communication_91_email_send_writes_activity_log | TC-P25/D05 | Security/Audit | 90-99 |
| 55 | test_communication_92_permission_keys_diverge_from_requirement | TC-DEV03 | DEV | 90-99 |
| 56 | test_communication_93_send_is_a_stub_no_dispatch | TC-DEV04 | DEV | 90-99 |
| 57 | test_communication_94_template_crud_is_incomplete | TC-DEV05 | DEV | 90-99 |

**Total: 57 test methods.**

---

## 5. Manual Test Steps (workflow / defect-sensitive flows only)

### MT-1 — Email bulk send (BC-BIZ-01, BC-AUTO)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin with `frontoffice.communication.create`; go to `/front-office/communication/email/compose` | Compose form loads (recipient group, subject, body) |
| 2 | Select `All_Parents`, subject `Test`, body `Hello`, submit | Redirect to `menu.communication?tab=email-sms` with "Email queued for dispatch." |
| 3 | DB check | `SELECT channel,total_recipients,sent_count,created_by FROM fof_communication_logs ORDER BY id DESC LIMIT 1` → `Email, 0, 0, <admin id>` (counters 0 = stub, DEV-FOF-COM-04) |
| 4 | Activity check | `SELECT event,user_id FROM sys_activity_logs WHERE subject_type LIKE '%CommunicationLog' ORDER BY id DESC LIMIT 1` → `email_queued, <admin id>` |

### MT-2 — SMS send + multi-unit gap (BC-BIZ-02, DEV-FOF-COM-02)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/front-office/communication/sms/send` group `All_Staff`, body 700 chars | Accepted (max:1000) — but per BR-FOF-011 this SHOULD be capped at 640/4 units → DEFECT confirmed |
| 2 | DB check | `SELECT channel,subject FROM fof_communication_logs ORDER BY id DESC LIMIT 1` → `SMS, NULL` |
| 3 | Per-recipient check | `SELECT COUNT(*) FROM fof_sms_logs` → unchanged (controller writes NO sms_logs rows — DEV-FOF-COM-04) |

### MT-3 — Template toggle (BC-SM-01/02)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed an active template; open `/front-office/communication/email/templates` | Template listed with a status switch |
| 2 | Toggle the switch (POST `.../{id}/toggle-status`) | JSON `{success:true,is_active:false}`; `SELECT is_active FROM fof_email_templates WHERE id=<id>` → 0 |
| 3 | Toggle again | `is_active` → 1 (no activity log recorded — by design in this controller) |

### MT-4 — Permission negative (BC-AUTH, Rule Card #31)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create a non-super-admin user, strip roles/permissions, `forgetCachedPermissions()` | User has no communication abilities |
| 2 | GET compose as that user | HTTP 403 / "This action is unauthorized" |
| 3 | POST emailSend as that user | HTTP 403 |

---

## 6. Known Source Defects (DEV — carried to Gap Analysis with proving tests)

| ID | Sev | Summary | Proving test |
|----|-----|---------|--------------|
| DEV-FOF-COM-01 | P3 | `emailSend` validates `subject` `max:255` while DDL column & requirement allow VARCHAR(300) → users cannot use the full 300 chars | test_31 |
| DEV-FOF-COM-02 | P2 | BR-FOF-011 multi-unit SMS (`ceil(len/160)`, max 4 = 640) UNIMPLEMENTED; no `SendBulkSmsRequest`, no `sms_units` calc; body capped at 1000 (>640) | test_15, test_33 |
| DEV-FOF-COM-03 | P2 | Permission keys diverge from requirement: controller uses `frontoffice.communication.{create,view,update}`, requirement specifies `.email` / `.sms` | test_92 |
| DEV-FOF-COM-04 | P1 | `emailSend`/`smsSend` are STUBS: counters forced to 0, no recipient resolution, `Mail` imported but never dispatched, `fof_sms_logs` never written by the controller (per-recipient tracking absent) — cf. BUG-FOF-002 pattern | test_93, test_10 |
| DEV-FOF-COM-05 | P2 | Email-template management is list + toggle only; NO store/update/destroy despite requirement "CRUD for email templates" | test_94 |
| SEC-FOF-003 (module) | P1 | Note: unlike the 10 other FOF FormRequests, Communication has NO FormRequest — validation is inline; no defense-in-depth authorize() layer exists | documented (n/a — no FormRequest to prove) |
| BUG-FOF-001 (module) | — | NOT applicable here: `CommunicationController::toggleStatus(): JsonResponse` IS imported (line 8) → toggle route works (unlike Certificate/Complaint) | verified in source |

**Module-enable prerequisite:** FrontOffice = `false` in `prime_testing/modules_statuses.json` → all `/front-office/*` routes 404 until enabled. Browser-layer TCs `markTestSkipped` on 404; the DB/model-layer TCs (schema, defaults, FK, ENUM, boundaries, DEV source probes) run regardless.

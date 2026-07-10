# Email Schedule — Test Case List & Business Conditions (`bil_EmailScheduleTcList_Require`)

| Field | Value |
|-------|-------|
| Module | Billing (BIL) |
| Feature / Screen | EmailSchedule (`email-schedule.md`) |
| Prefix | `bil_` (primary table `bil_tenant_email_schedules`) |
| DB scope | **PRIME / CENTRAL** (`prime_db`) — runs on `127.0.0.1`, no tenant scaffolding |
| Controller | `Modules\Billing\Http\Controllers\EmailScheduleController` (index / show / destroy only) |
| Model | `Modules\Billing\Models\BillTenantEmailSchedule` (no SoftDeletes; default timestamps) |
| Job / Mail | `SendInvoiceEmailJob` (ShouldQueue), `InvoiceMail` (Mailable) |
| Routes | `central.billing.email-schedule.{index,show,destroy}` → `/billing/email-schedule` (root `routes/web.php:417`, `->only([...])`) |
| Gates | `prime.email-schedule.viewAny` · `prime.email-schedule.view` · `prime.email-schedule.delete` |
| Activity log | `activityLog($schedule,'Cancelled',...)` → `sys_central_activity_logs` (`Modules\Prime\Models\ActivityLog`) |
| Test file | `bil_EmailSchedule_TestCas.php` (37 methods) |

> **DDL GAP (must-flag):** `bil_tenant_email_schedules` is **absent from the module DDL `Billing_DDL_v1.sql`**. Its schema authority is the master `0-DDL_Masters/prime_db_v4.sql` (per the Billing audit). All schema assertions are therefore made **defensively** (`Schema::hasTable`/`hasColumn`, `markTestSkipped` when absent).

---

## 1. Business Conditions

### BC-DB — Schema (Model = column source of truth; DDL gap noted)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `bil_tenant_email_schedules` exists (defensive — DDL gap) | Model:$table / Audit-reconcile |
| BC-DB-02 | Columns: `id`, `invoice_id`, `schedule_time`, `status`, `created_at`, `updated_at` | Model / Screen-DB |
| BC-DB-03 | Fillable = `['invoice_id','schedule_time','status']` exactly | Model:15-19 |
| BC-DB-04 | Model uses **no** SoftDeletes (default timestamps only) | Model:9-13 / Audit-reconcile |
| BC-DB-05 | `invoice_id` has **no** DB foreign key (orphan ids persist) | Audit DATA-BIL-003 / Screen-DB |

### BC-VAL — Validation
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | No FormRequest on this screen (index/show/destroy only; no create/update) | Controller |
| BC-VAL-02 | Non-existent / non-numeric `{emailSchedule}` → 404 (route-model binding) | Route / Controller |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `index()` gated by `prime.email-schedule.viewAny` | Controller:20 / Screen-PM |
| BC-AUTH-02 | `show()` gated by `prime.email-schedule.view` | Controller:43 / Screen-PM |
| BC-AUTH-03 | `destroy()` gated by `prime.email-schedule.delete` | Controller:54 / Screen-PM |
| BC-AUTH-04 | View button gated by `@can('prime.email-schedule.view')`; cancel by `.delete` | index.blade:71,78 |
| BC-AUTH-05 | Guest → redirect `/login`; limited user → 403 | middleware `auth,verified` + Gate |

### BC-BIZ — Business logic / behaviour
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Index eager-loads `invoice.tenant`, orders `schedule_time DESC`, paginates 15 | Controller:25-33 |
| BC-BIZ-02 | Search matches `invoice.invoice_no` OR `invoice.tenant.name` (LIKE) | Controller:27-30 / Screen-Filter |
| BC-BIZ-03 | Status filter = exact match, applied only when non-null & non-empty | Controller:31 |
| BC-BIZ-04 | `destroy()` sets `status='cancelled'` + success flash + activity log `Cancelled` | Controller:52-59 |
| BC-BIZ-05 | `SendInvoiceEmailJob` is queueable; `$tries=3`, `$backoff=[60,300,900]`, `$timeout=120` | Job:24-26 |
| BC-BIZ-06 | `InvoiceMail` subject = `"Invoice - {invoice_no}"`, attaches PDF | Mail:24-32 |
| BC-BIZ-07 | Show loads `invoice.tenant` + `invoice.billingCycle`; renders schedule + invoice cards | Controller:44 / show.blade |

### BC-SM — State machine (status lifecycle)
| ID | State → Trigger → Next | Implemented? | Source |
|----|------------------------|--------------|--------|
| BC-SM-01 | `pending` → cancel (destroy) → `cancelled` | **Yes** | Controller:55 |
| BC-SM-02 | `pending` → job success → `sent` | **No (DEV-BIL-ES-001)** | Screen-SM / Job (no write) |
| BC-SM-03 | `pending` → job failure → `failed` | **No (DEV-BIL-ES-001)** | Screen-SM / Job.failed() (audit-log only) |
| BC-SM-04 | Cancel restricted to `pending` server-side | **No (DEV-BIL-ES-003)** | Screen-BR / Controller (no guard) |

### BC-INT / BC-REF — Integration
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | `invoice()` belongsTo `BilTenantInvoice` (`invoice_id`) | Model:24-27 |
| BC-REF-01 | Missing invoice → view null-coalesces (`—` / "No linked invoice found.") | index/show.blade |

### BC-EDG / BC-CFG
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Unmapped status value → raw badge (switch default) | index/show.blade |
| BC-EDG-02 | Special-char / long search does not 500 | Controller (bindings) |
| BC-CFG-01 | Pagination fixed at 15/page | Controller:33 |
| BC-CFG-02 | Status options: pending/sent/failed/cancelled | index.blade:20-24 |

---

## 2. Known Source Defects (mapped to Billing audit `2026-06-29`)

| DEV ID | Audit ref | Description | Proving test |
|--------|-----------|-------------|--------------|
| DEV-BIL-ES-001 | JOB-BIL-001 / BR-BIL-030 | `SendInvoiceEmailJob` never transitions schedule to `sent`/`failed` (no reference to the schedule model) | `test_..._23` |
| DEV-BIL-ES-002 | DATA-BIL-003 | `invoice_id` has no FK; table absent from module DDL | `test_..._42`, `test_..._01` |
| DEV-BIL-ES-003 | (cross-ref #7) | `destroy()` has no server-side `pending` guard (BR "only pending" not enforced) | `test_..._22` |
| OBS-BIL-ES-004 | P3 typo note | Screen doc / audit reference legacy class `BillTenatEmailSchedule`; real model is correctly named `BillTenantEmailSchedule` | (documented) |

---

## 3. Test Case List

### Positive (`TC-P`)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-BIZ-01 | Controller | Index loads | Heading + table | `_10` | Auto |
| TC-P02 | BC-DB-02 | Screen-DB | Columns render | Invoice No/Tenant/Time/Status | `_11` | Auto |
| TC-P03 | BC-BIZ-01 | Controller | Order desc | Newer before older | `_12` / `_81` | Auto |
| TC-P04 | BC-BIZ-07 | show.blade | Show details | Schedule + invoice cards | `_13` | Auto |
| TC-P05 | BC-SM-01 | Controller | Cancel pending | status=cancelled | `_14` | Auto |
| TC-P06 | BC-BIZ-04 | activityLog | Cancel logs `Cancelled` | central log row | `_15` | Auto |
| TC-P07 | BC-CFG-02 | index.blade | All badges render | pending/sent/failed/cancelled | `_20` | Auto |
| TC-P08 | BC-INT-01 | show.blade | Related invoice shows | invoice_no visible | `_40` | Auto |
| TC-P09 | BC-AUTH-01 | Controller | Super admin index OK | 200 + heading | `_50` | Auto |
| TC-P10 | BC-BIZ-02/03 | Controller | Filter narrows | matching only | `_62`,`_63` | Auto |
| TC-P11 | BC-CFG-01 | Controller | Paginate 15 | perPage=15 | `_80` | Auto |
| TC-P12 | BC-BIZ-05 | Job | Job retry config | tries/backoff/timeout | `_04` | Auto |
| TC-P13 | BC-BIZ-06 | Mail | Mail subject | `Invoice - {no}` | `_05` | Auto |

### Negative (`TC-N`)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-VAL-02 | Route | Show invalid id | 404 | `_30` | Auto |
| TC-N02 | BC-VAL-02 | Route | Show non-numeric id | 404 | `_31` | Auto |
| TC-N03 | BC-AUTH-05 | middleware | Guest index | redirect /login | `_32` | Auto |
| TC-N04 | BC-AUTH-01 | Gate | Limited user index | 403 | `_51` | Auto |
| TC-N05 | BC-AUTH-02 | Gate | Limited user show | 403 | `_52` | Auto |
| TC-N06 | BC-EDG-02 | bindings | Special-char search | no 500 | `_70` | Auto |
| TC-N07 | BC-EDG-02 | bindings | Long search | no 500 | `_71` | Auto |
| TC-N08 | BC-SM-02/03 | Screen-SM | sent/failed not persisted | DEV proven | `_23` | Auto (DEV) |
| TC-N09 | BC-SM-04 | Screen-BR | cancel-guard absent | DEV proven | `_22` | Auto (DEV) |

### Dependency / State / Security (`TC-D` / `TC-S`)
| TC ID | Cat | BC | Source | Description | Expected | Method |
|-------|-----|----|--------|-------------|----------|--------|
| TC-D01 | E | BC-REF-01 | show.blade | Missing invoice placeholder | "No linked invoice found." | `_41` |
| TC-D02 | C | BC-DB-05 | Audit | No FK on invoice_id | orphan id persists (DEV) | `_42` |
| TC-D03 | F | BC-SM-01 | Controller | pending→cancelled lifecycle | status flips | `_14` |
| TC-D04 | A | BC-AUTH-04 | index.blade | Cancel only for pending | absent for sent | `_21` |
| TC-S01 | — | BC-AUTH-05 | Gate | IDOR 404 | non-existent → 404 | `_30` |
| TC-S02 | — | BC-EDG-01 | Blade | Reflected XSS escaped | payload not in source | `_91` |
| TC-S03 | — | BC-DB-03 | Model | Mass-assignment guard | `id` ignored | `_92` |
| TC-T01 | — | E21 | base | Central host | 127.0.0.1 | `_90` |

---

## 4. Test Method Index

| # | Method | TC Map | Band |
|---|--------|--------|------|
| 1 | `_01_schema_and_model_configuration_are_correct` | BC-DB-01..03 | 01-09 |
| 2 | `_02_routes_are_registered_index_show_destroy_only` | BC-VAL-01 | 01-09 |
| 3 | `_03_model_has_no_soft_deletes` | BC-DB-04 | 01-09 |
| 4 | `_04_send_invoice_email_job_is_queueable_with_retry_config` | TC-P12 | 01-09 |
| 5 | `_05_invoice_mail_subject_and_attachment_wiring` | TC-P13 | 01-09 |
| 6 | `_10_index_loads_and_shows_heading` | TC-P01 | 10-19 |
| 7 | `_11_index_renders_expected_columns` | TC-P02 | 10-19 |
| 8 | `_12_index_orders_by_schedule_time_desc` | TC-P03 | 10-19 |
| 9 | `_13_show_displays_schedule_details` | TC-P04 | 10-19 |
| 10 | `_14_cancel_pending_schedule_sets_status_cancelled` | TC-P05 / TC-D03 | 10-19 |
| 11 | `_15_cancel_writes_central_activity_log` | TC-P06 | 10-19 |
| 12 | `_20_status_badges_render_for_all_states` | TC-P07 | 20-29 |
| 13 | `_21_cancel_button_visible_only_for_pending` | TC-D04 | 20-29 |
| 14 | `_22_destroy_does_not_enforce_pending_state_dev` | TC-N09 | 20-29 |
| 15 | `_23_job_does_not_persist_sent_or_failed_transition_dev` | TC-N08 | 20-29 |
| 16 | `_30_show_invalid_id_returns_404` | TC-N01 / TC-S01 | 30-39 |
| 17 | `_31_show_non_numeric_id_returns_404` | TC-N02 | 30-39 |
| 18 | `_32_guest_is_redirected_to_login` | TC-N03 | 30-39 |
| 19 | `_40_show_renders_related_invoice_when_present` | TC-P08 | 40-49 |
| 20 | `_41_schedule_with_missing_invoice_renders_placeholder` | TC-D01 | 40-49 |
| 21 | `_42_invoice_id_column_has_no_db_foreign_key_dev` | TC-D02 | 40-49 |
| 22 | `_50_super_admin_can_access_index` | TC-P09 | 50-59 |
| 23 | `_51_limited_user_forbidden_on_index` | TC-N04 | 50-59 |
| 24 | `_52_limited_user_forbidden_on_show` | TC-N05 | 50-59 |
| 25 | `_60_search_input_and_status_filter_present` | TC-P10 | 60-69 |
| 26 | `_61_status_filter_options_are_complete` | BC-CFG-02 | 60-69 |
| 27 | `_62_status_filter_narrows_results` | TC-P10 | 60-69 |
| 28 | `_63_search_filters_out_non_matching_rows` | TC-P10 | 60-69 |
| 29 | `_64_empty_state_message_when_no_matches` | BC-REF-01 | 60-69 |
| 30 | `_70_special_character_search_does_not_error` | TC-N06 | 70-79 |
| 31 | `_71_long_search_term_is_handled` | TC-N07 | 70-79 |
| 32 | `_72_unknown_status_value_shows_raw_badge` | BC-EDG-01 | 70-79 |
| 33 | `_80_index_paginates_at_fifteen_per_page` | TC-P11 | 80-89 |
| 34 | `_81_default_order_is_schedule_time_desc` | TC-P03 | 80-89 |
| 35 | `_90_runs_on_central_host` | TC-T01 | 90-99 |
| 36 | `_91_search_input_is_escaped_against_xss` | TC-S02 | 90-99 |
| 37 | `_92_mass_assignment_limited_to_fillable` | TC-S03 | 90-99 |

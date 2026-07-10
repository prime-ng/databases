# Email Schedule — Test Case List & Business Conditions

- **Module:** Billing  **Feature:** EmailSchedule  **Prefix:** `bil_`
- **Primary table:** `bil_tenant_email_schedules` (central `prime_db`; **no tenant init**)
- **Screen file:** `Billing_v1/email-schedule.md`
- **Controllers:** `EmailScheduleController` (index/show/destroy) + `BillingManagementController::sendEmail/scheduleEmail`
- **Job:** `Modules\Billing\Jobs\SendInvoiceEmailJob` (queued)  **Mail:** `Modules\Billing\Mail\InvoiceMail`
- **Model:** `Modules\Billing\Models\BillTenantEmailSchedule` (HasFactory, **no SoftDeletes**, fillable `invoice_id, schedule_time, status`, relation `invoice()`)
- **Index route:** `GET /billing/email-schedule` (name `central.billing.email-schedule.index`)
- **V1 methods:** 16  **V2 methods:** 50  (V2 ≥ 2× V1 ✔)

> **Source truth vs audit/requirement drift (documented, not invented around):**
> 1. **DDL gap** — `bil_tenant_email_schedules` is **absent from `Billing_DDL_v1.sql`**; it is created only by the Prime-module migration `2025_12_03_094529_create_bil_tenant_email_schedules_table.php` (columns: `id, invoice_id (unsignedInteger, NO FK), schedule_time (timestamp), status (string default 'pending'), timestamps`). DDL is out of sync with the migration.
> 2. **JOB-BIL-001 (audit P2) is REMEDIATED in current source** — the job now declares `$tries=3`, `$backoff=[60,300,900]`, `$timeout=120`, defines `failed()`, and the controller passes `auth()->id()` into the constructor. Tests assert the present (fixed) behaviour; source wins over the stale audit.
> 3. **DATA-BIL-003 (audit P2) confirmed** — `invoice_id` has no FK (orphan ids insert).
> 4. **Class-name typo NOT in code** — the real class is `BillTenantEmailSchedule` (correct). The audit/requirement spelling `BillTenatEmailSchedule` is a narrative typo only.
> 5. **Cancel is a status update, not a soft delete** — `destroy()` sets `status='cancelled'` (screen doc's "soft-deletes the record" is inaccurate).
> 6. **Cancel confirmation is a native `confirm()` dialog**, not SweetAlert2 (screen doc says SweetAlert2).
> 7. **Send/Schedule endpoints have NO FormRequest validation** (candidate DEV-EMS-002).

---

## 1. Business Conditions

### BC-DB (schema)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `bil_tenant_email_schedules` has `id, invoice_id, schedule_time, status, created_at, updated_at` | Migration `2025_12_03_094529` |
| BC-DB-02 | `status` is `VARCHAR` default `'pending'` | Migration |
| BC-DB-03 | No `deleted_at` column; model has no SoftDeletes | Migration + Model |
| BC-DB-04 | `invoice_id` is `unsignedInteger` with **no FK constraint** | Migration; Audit-DATA-BIL-003 |
| BC-DB-05 | Table absent from `Billing_DDL_v1.sql` (DDL/migration drift) | DDL-Billing_DDL_v1 |

### BC-VAL (validation)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `destroy` invalid id → 404 (route-model binding) | routes web.php:412 |
| BC-VAL-02 | `show` invalid id → 404 | routes web.php:412 |
| BC-VAL-03 | `scheduleEmail`/`sendEmail` have **no FormRequest** — missing `id`/`schedule_time` not rejected with 422 | BillingManagementController:543-595 (DEV-EMS-002) |

### BC-AUTH (permissions)
| ID | Gate → method | Source |
|----|---------------|--------|
| BC-AUTH-01 | `prime.email-schedule.viewAny` → `index` | EmailScheduleController:20; Screen-PM |
| BC-AUTH-02 | `prime.email-schedule.view` → `show` | EmailScheduleController:43 |
| BC-AUTH-03 | `prime.email-schedule.delete` → `destroy` | EmailScheduleController:54 |
| BC-AUTH-04 | `prime.billing-management.email-schedule` → `sendEmail` + `scheduleEmail` | BillingManagementController:545,563 |
| BC-AUTH-05 | Guest → redirect `/login`; non-super-admin without permission → 403 | middleware `auth,verified` + Gate |

### BC-BIZ (business rules / logs)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Immediate send: `POST /billing/billing-management/send-email` `ids[]` → `SendInvoiceEmailJob::dispatch($id, auth()->id())` per id; JSON `{status:true, message:'Emails queued successfully!'}` | Screen-BR Immediate; Ctrl:543 |
| BC-BIZ-02 | Schedule: `POST .../schedule-email` `id`+`schedule_time` → create schedule `status='pending'` + `dispatch()->delay()`; JSON `{status:true, message:'Email scheduled successfully for {d M Y h:i A}'}` | Screen-BR Scheduled; Ctrl:561 |
| BC-BIZ-03 | Schedule writes `InvoicingAuditLog` `action_type='Email Scheduled'` | Ctrl:569 |
| BC-BIZ-04 | Schedule writes `activityLog(..., 'Store', ...)` (table `sys_activity_logs`) | Ctrl:587 |
| BC-BIZ-05 | Cancel: `DELETE /email-schedule/{id}` → `status='cancelled'`, `activityLog(..., 'Cancelled', ...)`, redirect index with flash `Email schedule cancelled successfully.` | Ctrl:52-60 |
| BC-BIZ-06 | Job `handle()` writes `InvoicingAuditLog action_type='Notice Sent'` + `activityLog($invoice,'Store',...)` + sends `InvoiceMail` (subject `Invoice - {invoice_no}`) | Job:34-58 |
| BC-BIZ-07 | Job `failed()` writes `InvoicingAuditLog action_type='EMAIL_FAILED'` | Job:60-69 |
| BC-BIZ-08 | Job reliability config present: `$tries=3`, `$backoff=[60,300,900]`, `$timeout=120`; `performedById` captured at dispatch | Job:24-32 (JOB-BIL-001 remediated) |
| BC-BIZ-09 | Index paginates 15, orders `schedule_time DESC`, eager loads `invoice.tenant` | Ctrl:25-33 |

### BC-SM (state machine)  — status lifecycle
| ID | State → Trigger → Next | Source |
|----|------------------------|--------|
| BC-SM-01 | `pending` → cancel (destroy) → `cancelled` | Ctrl:55; Screen-SM |
| BC-SM-02 | `pending` → job delivered → `sent` | Screen-BR; Job |
| BC-SM-03 | `pending` → job failed → `failed` | Screen-BR failed handling |
| BC-SM-04 | Only `pending` rows render the Cancel action (index + show) | index.blade:77; show.blade:56 |

### BC-INT / BC-REF (integration)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | `invoice()` belongsTo `BilTenantInvoice` (`invoice_id`) | Model:24 |
| BC-INT-02 | Show eager-loads `invoice.tenant` + `invoice.billingCycle` | Ctrl:44 |
| BC-INT-03 | Search filters across `invoice.invoice_no` OR `invoice.tenant.name` (whereHas OR) | Ctrl:27-30; Screen-Filter |
| BC-REF-01 | `invoice_id` has NO FK → orphan ids allowed; blade degrades to `—` | Migration; Audit-DATA-BIL-003 |

### BC-EDG (edge)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Ordering `schedule_time DESC` (newest first) | Ctrl:32 |
| BC-EDG-02 | Unknown/whitespace/long search or unknown status filter must not error | Ctrl:27-31 |
| BC-EDG-03 | Orphan invoice_id show/index page renders without 500 (null-safe blade) | show.blade:80-108 |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | V1 | V2 |
|-------|----|--------|-------------|----------|----|----|
| TC-P01 | BC-DB-01/03 | Migration | Schema/model config truth | columns + no SoftDeletes | 01 | 01-04,06 |
| TC-P02 | BC-BIZ-09 | Ctrl | Index loads with table | 200 + "Email Schedules" | 02 | 60 |
| TC-P03 | BC-BIZ-09 | index.blade | Breadcrumb "Email Schedule Management" | visible | 03 | — |
| TC-P04 | BC-INT-03 | index.blade | Search + status controls present | inputs present | 04 | 61,64 |
| TC-P05 | BC-BIZ-09 | index.blade | Empty state / rows | "No Email Schedules Found" or rows | 05 | 62 |
| TC-P06 | BC-BIZ-02 | Ctrl | Schedule creates pending record | pending row + msg | 11 | 10,11,12 |
| TC-P07 | BC-BIZ-03 | Ctrl | Schedule writes 'Email Scheduled' audit | audit row | — | 13 |
| TC-P08 | BC-BIZ-04 | Ctrl | Schedule writes 'Store' activity log | log row | — | 14 |
| TC-P09 | BC-BIZ-01 | Ctrl | Send queues job + message | JSON queued | 12 | 15,16 |
| TC-P10 | BC-BIZ-05 | Ctrl | Cancel sets 'cancelled' + flash | status cancelled | 09 | 17,19,20 |
| TC-P11 | BC-BIZ-05 | Ctrl | Cancel writes 'Cancelled' activity log | log row | 10 | 18 |
| TC-P12 | BC-INT-01/02 | show.blade | Show page + related invoice | details visible | 08 | 41 |
| TC-P13 | BC-INT-01 | Model | invoice() relation returns invoice | not null | 15 | 40 |
| TC-P14 | BC-EDG-01 | Ctrl | Ordering schedule_time DESC | newest first | — | 70 |
| TC-P15 | BC-BIZ-09 | Ctrl | Pagination = 15 | perPage 15 | 16 | 71 |
| TC-P16 | BC-SM-04 | show.blade | Cancel button present for pending | visible | — | 24 |
| TC-P17 | BC-INT-03 | Ctrl | Cross-table search matches invoice_no | match | — | 73 |
| TC-P18 | BC-AUTH-01..04 | Ctrl src | Gate keys referenced in controllers | strings present | — | 52,53 |

### State-machine (TC-SM)
| TC ID | BC | Source | Description | Expected | V1 | V2 |
|-------|----|--------|-------------|----------|----|----|
| TC-SM01 | BC-SM-01 | Ctrl | pending → cancelled | status cancelled | 09 | 20 |
| TC-SM02 | BC-SM-02 | Model | pending → sent representable | status sent | — | 21 |
| TC-SM03 | BC-SM-03 | Model | pending → failed representable | status failed | — | 22 |
| TC-SM04 | BC-SM-04 | index.blade | sent row hides cancel action | missing form | — | 23 |
| TC-SM05 | BC-SM-04 | show.blade | cancelled show hides cancel button | dont-see | — | 25 |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | V1 | V2 |
|-------|----|--------|-------------|----------|----|----|
| TC-N01 | BC-VAL-01 | routes | destroy invalid id | 404 | — | 30 |
| TC-N02 | BC-VAL-02 | routes | show invalid id | 404 | — | 31 |
| TC-N03 | BC-VAL-03 | Ctrl | schedule without id (no validation) | current behaviour (no hard-500) | — | 32 |
| TC-N04 | BC-EDG-02 | Ctrl | XSS in search not reflected | escaped | — | 33 |
| TC-N05 | BC-EDG-02 | Ctrl | whitespace search reachable | 200 | — | 34 |
| TC-N06 | BC-EDG-02 | Ctrl | unknown status filter reachable | 200 | — | 35 |
| TC-N07 | BC-EDG-02 | Ctrl | long search string safe | 200 | 07 | 72 |
| TC-N08 | BC-AUTH-05 | middleware | guest → login (index/show) | redirect | 13 | 50,51,90 |
| TC-N09 | BC-AUTH-05 | Gate | limited user forbidden | 403/redirect | — | 54 |
| TC-N10 | BC-SM-04 | routes | GET must not cancel (verb) | still pending | — | 91 |
| TC-N11 | BC-EDG-02 | index.blade | stored XSS invoice_no escaped | escaped | — | 92 |

### Dependency (TC-D)
| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 |
|-------|-----|----|--------|-------------|----------|----|----|
| TC-D01 | C/D | BC-REF-01 | Migration | orphan invoice_id inserts (no FK) | insert ok | — | 05 |
| TC-D02 | E | BC-REF-01 | show.blade | orphan invoice_id degrades gracefully | no 500 | — | 42 |
| TC-D03 | E | BC-BIZ-06 | Job src | job handle audit action 'Notice Sent' | string present | — | 43 |
| TC-D04 | E | BC-BIZ-07 | Job src | job failed audit action 'EMAIL_FAILED' | string present | — | 44 |
| TC-D05 | F | BC-BIZ-08 | Job | job retry config present (JOB-BIL-001) | tries/backoff/timeout/failed | 14 | (V1) |

### Known Source Defects (audit-equivalent)
| ID | Sev | Description | Status in current source | Proving test |
|----|-----|-------------|--------------------------|--------------|
| DEV-EMS-001 / DATA-BIL-003 | P2 | `schedule.invoice_id` has no FK constraint (orphan ids) | Confirmed present | V2-05, V2-42 |
| DEV-EMS-002 | P2 | `sendEmail`/`scheduleEmail` have no FormRequest validation | Confirmed present | V2-32 |
| DEV-EMS-003 / DDL-gap | P2 | `bil_tenant_email_schedules` absent from `Billing_DDL_v1.sql` (schema drift) | Confirmed present | V2-06, V1-01 |
| JOB-BIL-001 | P2 | Job lacked retry config / `failed()` / captured performer | **Remediated** in current source | V1-14, V2-16,43,44 |
| DEV-EMS-004 | P3 | Requirement/audit class-name typo `BillTenatEmailSchedule` | Not in code (code is correct) | V1-01 |
| DEV-EMS-005 | P3 | `prime.email-schedule.*` gate keys referenced but seeded only under billing-management group (verify) | Verify in source | V2-52,54 |

---

## 3. V2 Method Index
| # | Method | TC | Cat | Band |
|---|--------|----|----|------|
| 01 | table_and_columns_exist | TC-P01 | Schema | 01-09 |
| 02 | model_fillable_matches_source | TC-P01 | Schema | 01-09 |
| 03 | model_table_binding | TC-P01 | Schema | 01-09 |
| 04 | model_has_no_soft_deletes | TC-P01 | Schema | 01-09 |
| 05 | invoice_id_has_no_foreign_key_data_bil_003 | TC-D01 | Schema/FK | 01-09 |
| 06 | ddl_gap_documented_migration_is_source_of_truth | TC-P01 | Schema | 01-09 |
| 10 | schedule_email_creates_pending | TC-P06 | BIZ | 10-19 |
| 11 | schedule_email_message_format | TC-P06 | BIZ | 10-19 |
| 12 | schedule_email_dispatches_delayed_job | TC-P06 | BIZ | 10-19 |
| 13 | schedule_email_writes_email_scheduled_audit_log | TC-P07 | BIZ | 10-19 |
| 14 | schedule_email_writes_store_activity_log | TC-P08 | BIZ | 10-19 |
| 15 | send_email_queues_job_and_returns_message | TC-P09 | BIZ | 10-19 |
| 16 | send_email_captures_performed_by | TC-P09 | BIZ | 10-19 |
| 17 | destroy_sets_status_cancelled | TC-P10 | BIZ | 10-19 |
| 18 | destroy_writes_cancelled_activity_log | TC-P11 | BIZ | 10-19 |
| 19 | destroy_redirects_with_success_flash | TC-P10 | BIZ | 10-19 |
| 20 | pending_to_cancelled_transition | TC-SM01 | SM | 20-29 |
| 21 | pending_to_sent_is_representable | TC-SM02 | SM | 20-29 |
| 22 | pending_to_failed_is_representable | TC-SM03 | SM | 20-29 |
| 23 | only_pending_shows_cancel_button_on_index | TC-SM04 | SM | 20-29 |
| 24 | cancel_button_present_for_pending_on_show | TC-P16 | SM | 20-29 |
| 25 | cancel_button_absent_for_cancelled_on_show | TC-SM05 | SM | 20-29 |
| 30 | destroy_invalid_id_returns_404 | TC-N01 | VAL | 30-39 |
| 31 | show_invalid_id_returns_404 | TC-N02 | VAL | 30-39 |
| 32 | schedule_email_without_id_does_not_500 | TC-N03 | VAL | 30-39 |
| 33 | search_input_is_escaped_no_reflected_xss | TC-N04 | VAL/SEC | 30-39 |
| 34 | whitespace_search_reachable | TC-N05 | VAL | 30-39 |
| 35 | unknown_status_filter_value_reachable | TC-N06 | VAL | 30-39 |
| 40 | invoice_relationship_eager_loads | TC-P13 | INT | 40-49 |
| 41 | show_renders_related_invoice_details | TC-P12 | INT | 40-49 |
| 42 | orphan_invoice_id_renders_dash_not_error | TC-D02 | REF | 40-49 |
| 43 | job_handle_uses_notice_sent_audit_action | TC-D03 | INT | 40-49 |
| 44 | job_failed_uses_email_failed_audit_action | TC-D04 | INT | 40-49 |
| 50 | guest_redirected_from_index | TC-N08 | AUTH | 50-59 |
| 51 | guest_redirected_from_show | TC-N08 | AUTH | 50-59 |
| 52 | controller_gates_reference_expected_permissions | TC-P18 | AUTH | 50-59 |
| 53 | send_and_schedule_gate_on_billing_management_permission | TC-P18 | AUTH | 50-59 |
| 54 | limited_user_forbidden_from_index | TC-N09 | AUTH | 50-59 |
| 60 | index_table_columns_present | TC-P02 | UI | 60-69 |
| 61 | status_dropdown_has_all_states | TC-P04 | UI | 60-69 |
| 62 | empty_state_text_when_no_rows | TC-P05 | UI | 60-69 |
| 63 | show_back_button_present | TC-P12 | UI | 60-69 |
| 64 | search_control_submits_via_get | TC-P04 | UI | 60-69 |
| 70 | ordering_is_schedule_time_desc | TC-P14 | EDG | 70-79 |
| 71 | pagination_size_is_15 | TC-P15 | EDG | 70-79 |
| 72 | long_search_string_is_safe | TC-N07 | EDG | 70-79 |
| 73 | cross_table_search_matches_invoice_no | TC-P17 | EDG | 70-79 |
| 90 | idor_direct_show_requires_auth | TC-N08 | SEC | 90-99 |
| 91 | destroy_requires_delete_verb | TC-N10 | SEC | 90-99 |
| 92 | stored_xss_invoice_no_is_escaped_on_index | TC-N11 | SEC | 90-99 |

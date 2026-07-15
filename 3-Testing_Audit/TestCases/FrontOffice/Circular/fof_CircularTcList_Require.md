# FrontOffice → Circular — Combined Test Spec (TcList + Manual Steps)

> ONE screen = ONE requirement = ONE test file (`fof_Circular_TestCas.php`, 42 methods).
> Every BC/TC carries a `Source` tag. Activity sink = **`sys_activity_logs`** (Fact Pack §4-corrected).
> Prefix `fof_` verified against DDL `CREATE TABLE fof_circulars`.

---

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | FrontOffice (FOF) |
| Feature | Circular |
| Primary table | `fof_circulars` (+ `fof_circular_distributions`, append-only) |
| URL base | `/front-office/circulars` (group `prefix('front-office')->name('fof.')`, middleware `auth,verified`) |
| Controller | `Modules\FrontOffice\Http\Controllers\CircularController` |
| Service | `Modules\FrontOffice\Services\CircularService` (create/update/submitForApproval/approve/distribute/recall) |
| Models | `Circular` (SoftDeletes, InteractsWithMedia), `CircularDistribution` (BaseModel, append-only — no SoftDeletes/updated_by) |
| Validation | **Inline `$request->validate()` in controller `store`/`update`** — NO dedicated FormRequest (so SEC-FOF-003 `authorize(){return true}` does NOT apply here) |
| Policy | `CircularPolicy` exists but controller uses **string gates** `Gate::authorize('frontoffice.circular.{action}')`, not policy binding (policy effectively dead — same pattern as SEC-FOF-001) |
| Migrations | consolidated tenant set (`database/migrations/tenant/`); module `database/migrations` empty |
| CRUD type | Page-based CRUD (create/edit are full pages, not modals) + workflow actions |
| Soft delete | Yes (`deleted_at` + `SoftDeletes` on `Circular`) |
| Pagination | Index 20/page (`->paginate(20)->withQueryString()`); trash 15/page |
| Activity log | `activityLog($model, $event, $props)` → `sys_activity_logs` (cols: `subject_type, subject_id, user_id, event, properties, ip_address, user_agent`) |

**Routes (verified — never hand-written):** `fof.circulars.` index(GET `/circulars`), create(GET `/create`), store(POST `/circulars`), show(GET `/{circular}`), edit(GET `/{circular}/edit`), update(PUT `/{circular}`), destroy(DELETE `/{circular}`), approve(PATCH `/{circular}/approve`), distribute(PATCH `/{circular}/distribute`), toggleStatus(POST|PATCH `/{circular}/toggle-status`), trashed(GET `/trash/view`), restore(GET `/{id}/restore`), forceDelete(DELETE `/{id}/force-delete`). **No `recall` route** (see DEV-FOF-C03).

**Form fields (create/edit Blade):** `title`, `subject`, `body` (textarea), `audience` (select), `audience_filter_json[classes][]` / `audience_filter_json[sections][]` (checkboxes, shown only for Specific_*), `effective_date`, `expires_on`, `attachment` (file), `action` (submit buttons: `value=submit` / `value=draft`).

**Activity event strings (VERIFIED verbatim — NOT the generic Created/Updated set):**
`circular_created`, `circular_updated`, `circular_submitted`, `circular_approved`, `circular_distributed`, `circular_recalled` (all snake_case, from `CircularService`); `Restored` (restore) and `Deleted` (forceDelete only) from the controller. **Soft `destroy()` and `toggleStatus()` write NO activity log** (DEV-FOF-C04).

---

## 2. Business Conditions

### BC-DB — DDL constraints (`Source: DDL-fof_circulars` / `DDL-fof_circular_distributions`)
| ID | Fact | TC |
|----|------|----|
| BC-DB-01 | Table `fof_circulars` exists with the 21 documented columns | TC-P01 |
| BC-DB-02 | UNIQUE `uq_fof_cir_circular_number(circular_number)` | TC-N01 |
| BC-DB-03 | NOT-NULL-no-default: `circular_number, title, subject, body, audience, effective_date, created_by, updated_by` | TC-N02 |
| BC-DB-04 | Nullable: `audience_filter_json, expires_on, attachment_media_id, approved_by/at, distributed_by/at` | TC-P04 |
| BC-DB-05 | `status` DEFAULT `'Draft'`; `is_active` DEFAULT `1` | TC-P05 |
| BC-DB-06 | `title` VARCHAR(200), `subject` VARCHAR(300), `circular_number` VARCHAR(30) | TC-N03 / TC-P06 |
| BC-DB-07 | `audience` ENUM(`Parents,Staff,Both,Specific_Class,Specific_Section`) — **no `All`** | TC-N05 (DEV-FOF-C02) |
| BC-DB-08 | FK `attachment_media_id`→`sys_media` SET NULL; `approved_by`/`distributed_by`→`sys_users` SET NULL | TC-D03 |
| BC-DB-09 | `deleted_at` column + `SoftDeletes` trait (assert independently) | TC-P01 |
| BC-DB-10 | `fof_circular_distributions` append-only: no `deleted_at`, no `updated_by`; FK `circular_id`→`fof_circulars` RESTRICT, `recipient_user_id`→`sys_users` RESTRICT | TC-P01 / TC-D02 |

### BC-VAL — Validation (`Source: CircularController::store/update`)
| ID | Rule | TC |
|----|------|----|
| BC-VAL-01 | `title` required, max:200 | TC-N06 / TC-N03 |
| BC-VAL-02 | `subject` required, max:300 | TC-N06 / TC-N03 |
| BC-VAL-03 | `body` required | TC-N06 |
| BC-VAL-04 | `audience` required, `in:All,Parents,Staff,Both,Specific_Class,Specific_Section` (**allows `All` — DDL diverges**) | TC-N05 |
| BC-VAL-05 | `effective_date` required date | TC-N06 |
| BC-VAL-06 | `expires_on` nullable, `after_or_equal:effective_date` | TC-N07 |
| BC-VAL-07 | `attachment` nullable file, max:10240 KB | (manual) |

### BC-AUTH — Authorization (`Source: CircularController Gate::authorize`)
| ID | Fact | TC |
|----|------|----|
| BC-AUTH-01 | Guest → redirect `/login` | TC-P50 |
| BC-AUTH-02 | `frontoffice.circular.view` gates index/show | TC-S51 |
| BC-AUTH-03 | `.create` gates create/store | TC-S52 |
| BC-AUTH-04 | `.approve` gates approve | TC-S53 |
| BC-AUTH-05 | `.distribute` gates distribute | TC-S54 |
| BC-AUTH-06 | `.delete` gates destroy | TC-S55 |
| BC-AUTH-07 | `.update` gates edit/update/toggleStatus; `.restore` gates restore/trashed; `.forceDelete` gates forceDelete | TC-S53–55 (representative) |

### BC-BIZ — Business rules (`Source: Screen-BR / CircularService`)
| ID | Fact | TC |
|----|------|----|
| BC-BIZ-01 | `circular_number` auto `CIR-YYYY-NNN` (service, lockForUpdate) — user cannot set it | TC-P10 |
| BC-BIZ-02 | New circular starts `status=Draft` | TC-P10 / TC-P05 |
| BC-BIZ-03 | `audience_filter_json` nulled unless audience is `Specific_Class`/`Specific_Section` | TC-P11 |
| BC-BIZ-04 | Edit/update locked after `Approved` (also `Distributed`) — `isLocked()` → abort 422 (BR-FOF-008) | TC-P12 |
| BC-BIZ-05 | `distribute()` inserts `fof_circular_distributions` rows (channel Email, status Queued) but performs **no real NTF dispatch** | TC-P13 (DEV-FOF-C01) |

### BC-SM — State machine (`Source: Screen-SM / CircularService`)
| ID | State → Trigger → Next | Legal? | TC |
|----|----------------------|--------|----|
| BC-SM-01 | Draft → submitForApproval → Pending_Approval | legal | TC-SM20 |
| BC-SM-02 | Pending_Approval → approve → Approved (+approved_by/at) | legal | TC-SM21 |
| BC-SM-03 | Approved → distribute → Distributed (+distributed_by/at, rows) | legal | TC-SM22 |
| BC-SM-04 | Distributed → recall → Recalled | legal (service) but **no route** | TC-SM26 (DEV-FOF-C03) |
| BC-SM-05 | Draft → approve → ✗ DomainException "Only Pending_Approval" | illegal | TC-SM23 |
| BC-SM-06 | Pending_Approval → distribute → ✗ DomainException "Only Approved" | illegal | TC-SM24 |
| BC-SM-07 | non-Draft → submitForApproval → ✗ DomainException "Only Draft" | illegal | TC-SM25 |

### BC-REF/BC-INT — Integration (`Source: DDL FK / CircularService`)
| ID | Fact | TC |
|----|------|----|
| BC-REF-01 | `Circular::distributions()` HasMany → `CircularDistribution` | TC-D01 |
| BC-INT-01 | Distribution `recipient_user_id` FK RESTRICT → bogus id rejected | TC-D02 |
| BC-INT-02 | Recipient resolution reads SchoolSetup `User`/`ClassSection` + StudentProfile `Guardian`/`StudentAcademicSession` (cross-module → guard) | TC-P13/P22 (skip-guarded) |

### BC-AUTO — Programmatically-managed (G48, never a form input)
`circular_number`, `status`, `approved_by/at`, `distributed_by/at`, `created_by/updated_by` — all set by the service/controller, never accepted from the user.

---

## 3. Test Case List

### Positive
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01/09/10 | DDL | Full DDL↔app alignment matrix; soft-delete col+trait independent | All assertions pass | test_circular_01 | ✅ |
| TC-P04 | BC-DB-04 | DDL | Nullable columns accept null | Row saves | test_circular_04 | ✅ |
| TC-P05 | BC-DB-05 | DDL | Defaults `status=Draft`, `is_active=1` (refresh) | Defaults applied | test_circular_04 | ✅ |
| TC-P06 | BC-DB-06 | DDL | Exactly-200 title / 300 subject accepted | Persists at length | test_circular_05 | ✅ |
| TC-P10 | BC-BIZ-01/02 | Service | Service create → CIR number, Draft, `circular_created` log | Number+status+log | test_circular_10 | ✅ |
| TC-P11 | BC-BIZ-03 | Controller | filter_json kept only for Specific_* | Nulled/kept per audience | test_circular_11 | ✅ |
| TC-P12 | BC-BIZ-04 | Service | Update on Approved aborts 422 | Locked | test_circular_12 | ✅ |
| TC-P13 | BC-BIZ-05 | Service/Audit | distribute writes Queued rows, no NTF | Rows Queued, sent_at NULL | test_circular_13 | ✅ |
| TC-SM20 | BC-SM-01 | Service | Draft→Pending | status+`circular_submitted` | test_circular_20 | ✅ |
| TC-SM21 | BC-SM-02 | Service | Pending→Approved | status+approved_at+log | test_circular_21 | ✅ |
| TC-SM22 | BC-SM-03 | Service | Approved→Distributed | status+distributed_at | test_circular_22 | ✅ |
| TC-D01 | BC-REF-01 | Model | distributions() HasMany | Relationship valid | test_circular_40 | ✅ |
| TC-D03 | BC-DB-08 | DDL | attachment optional (SET NULL) | Saves null | test_circular_42 | ✅ |
| TC-P50 | BC-AUTH-01 | Route | Guest redirected to login | `/login` | test_circular_50 | ✅ |
| TC-P60 | BC-BIZ | Blade | Index loads + lists circular | Sees number | test_circular_60 | ✅ |
| TC-P61 | — | Controller | Status filter | Draft row shown | test_circular_61 | ✅ |
| TC-P62 | — | Controller | Search by title | Match shown | test_circular_62 | ✅ |
| TC-P63 | — | Blade | Create page fields present | Inputs present | test_circular_63 | ✅ |
| TC-P64 | — | Blade | Show displays number | Sees number | test_circular_64 | ✅ |
| TC-P65 | BC-DB-09 | Controller | Trash lists soft-deleted | Sees number | test_circular_65 | ✅ |
| TC-P71 | — | Controller | Restore logs `Restored` | Restored + log | test_circular_71 | ✅ |
| TC-P72 | — | Controller | Force delete logs `Deleted` | Gone + log | test_circular_72 | ✅ |
| TC-P90 | — | Helper | Activity sink = sys_activity_logs | Row present | test_circular_90 | ✅ |

### Negative
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-DB-02 | DDL G43 | Duplicate `circular_number` | Refused | test_circular_02 | ✅ |
| TC-N02 | BC-DB-03 | DDL G44 | Missing each NOT-NULL col | Refused | test_circular_03 | ✅ |
| TC-N03 | BC-DB-06 | DDL G45 | Over-length title/subject | Refused/truncated | test_circular_05 | ✅ |
| TC-N05 | BC-DB-07 | DDL/Ctrl | audience=`All` (validation allows, ENUM lacks) | Refused/coerced | test_circular_33 | ✅ |
| TC-N06 | BC-VAL-01..05 | Controller | store missing required | No create | test_circular_30 | ✅ |
| TC-N06b | BC-VAL-01/02 | Controller | store over-length | No create | test_circular_31 | ✅ |
| TC-N07 | BC-VAL-06 | Controller | expires_on < effective_date | No create | test_circular_32 | ✅ |
| TC-SM23 | BC-SM-05 | Service | approve Draft | DomainException | test_circular_23 | ✅ |
| TC-SM24 | BC-SM-06 | Service | distribute Pending | DomainException | test_circular_24 | ✅ |
| TC-SM25 | BC-SM-07 | Service | submit non-Draft | DomainException | test_circular_25 | ✅ |
| TC-D02 | BC-INT-01 | DDL | Distribution bogus recipient FK | Refused | test_circular_41 | ✅ |
| TC-S51 | BC-AUTH-02 | Gate | No view perm → 403 | 403/302 | test_circular_51 | ✅ |
| TC-S52 | BC-AUTH-03 | Gate | No create perm → 403 | 403/302 | test_circular_52 | ✅ |
| TC-S53 | BC-AUTH-04 | Gate | No approve perm → 403 | 403/302 | test_circular_53 | ✅ |
| TC-S54 | BC-AUTH-05 | Gate | No distribute perm → 403 | 403/302 | test_circular_54 | ✅ |
| TC-S55 | BC-AUTH-06 | Gate | No delete perm → 403 | 403/302 | test_circular_55 | ✅ |
| TC-N70 | — | Defect | Soft delete → no activity log | No log (DEV-FOF-C04) | test_circular_70 | ✅ |
| TC-N73 | — | Defect | toggle-status → no activity log | No log (DEV-FOF-C04) | test_circular_73 | ✅ |
| TC-S74 | — | Security | Stored XSS in title escaped | Escaped | test_circular_74 | ✅ |
| TC-S91 | — | Security | Unknown id → 404 (IDOR) | 404/403/302 | test_circular_91 | ✅ |
| TC-SM26 | BC-SM-04 | Defect | recall has no route | Route absent (DEV-FOF-C03) | test_circular_26 | ✅ |

---

## 4. Test Method Index (42 methods)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_circular_01_migration_model_and_request_configuration_are_correct | TC-P01 | Schema | 01–09 |
| 2 | test_circular_02_duplicate_circular_number_is_rejected | TC-N01 | Schema/UNIQUE | 01–09 |
| 3 | test_circular_03_required_columns_reject_missing_values | TC-N02 | Schema/NOTNULL | 01–09 |
| 4 | test_circular_04_nullable_columns_and_defaults | TC-P04/P05 | Schema | 01–09 |
| 5 | test_circular_05_varchar_length_boundaries | TC-N03/P06 | Schema/length | 01–09 |
| 6 | test_circular_10_service_create_generates_number_status_and_activity | TC-P10 | BizRule | 10–19 |
| 7 | test_circular_11_audience_filter_json_kept_only_for_specific_audience | TC-P11 | BizRule | 10–19 |
| 8 | test_circular_12_update_is_locked_after_approved | TC-P12 | BizRule | 10–19 |
| 9 | test_circular_13_distribute_writes_queued_rows_without_ntf_dispatch | TC-P13 | BizRule/Defect | 10–19 |
| 10 | test_circular_20_draft_to_pending_approval | TC-SM20 | StateMachine | 20–29 |
| 11 | test_circular_21_pending_to_approved | TC-SM21 | StateMachine | 20–29 |
| 12 | test_circular_22_approved_to_distributed | TC-SM22 | StateMachine | 20–29 |
| 13 | test_circular_23_illegal_approve_from_draft_rejected | TC-SM23 | StateMachine | 20–29 |
| 14 | test_circular_24_illegal_distribute_from_pending_rejected | TC-SM24 | StateMachine | 20–29 |
| 15 | test_circular_25_illegal_submit_from_non_draft_rejected | TC-SM25 | StateMachine | 20–29 |
| 16 | test_circular_26_recall_transition_has_no_route_exposure | TC-SM26 | StateMachine/Defect | 20–29 |
| 17 | test_circular_30_store_rejects_missing_required_fields | TC-N06 | Validation | 30–39 |
| 18 | test_circular_31_store_rejects_over_length_fields | TC-N06b | Validation | 30–39 |
| 19 | test_circular_32_expires_on_before_effective_date_rejected | TC-N07 | Validation | 30–39 |
| 20 | test_circular_33_audience_all_diverges_from_ddl_enum | TC-N05 | Validation/Defect | 30–39 |
| 21 | test_circular_40_distributions_relationship | TC-D01 | Integration | 40–49 |
| 22 | test_circular_41_distribution_recipient_fk_is_enforced | TC-D02 | Integration | 40–49 |
| 23 | test_circular_42_attachment_media_is_optional | TC-D03 | Integration | 40–49 |
| 24 | test_circular_50_guest_is_redirected_to_login | TC-P50 | Auth | 50–59 |
| 25 | test_circular_51_user_without_view_permission_forbidden | TC-S51 | Auth | 50–59 |
| 26 | test_circular_52_user_without_create_permission_forbidden | TC-S52 | Auth | 50–59 |
| 27 | test_circular_53_user_without_approve_permission_forbidden | TC-S53 | Auth | 50–59 |
| 28 | test_circular_54_user_without_distribute_permission_forbidden | TC-S54 | Auth | 50–59 |
| 29 | test_circular_55_user_without_delete_permission_forbidden | TC-S55 | Auth | 50–59 |
| 30 | test_circular_60_index_loads_for_admin | TC-P60 | UI | 60–69 |
| 31 | test_circular_61_index_status_filter | TC-P61 | UI | 60–69 |
| 32 | test_circular_62_index_search_by_title | TC-P62 | UI | 60–69 |
| 33 | test_circular_63_create_page_loads_with_fields | TC-P63 | UI | 60–69 |
| 34 | test_circular_64_show_page_displays_circular | TC-P64 | UI | 60–69 |
| 35 | test_circular_65_trash_view_lists_soft_deleted | TC-P65 | UI | 60–69 |
| 36 | test_circular_70_soft_delete_writes_no_activity_log | TC-N70 | Edge/Defect | 70–79 |
| 37 | test_circular_71_restore_logs_restored | TC-P71 | Edge | 70–79 |
| 38 | test_circular_72_force_delete_logs_deleted | TC-P72 | Edge | 70–79 |
| 39 | test_circular_73_toggle_status_flips_flag_without_activity_log | TC-N73 | Edge/Defect | 70–79 |
| 40 | test_circular_74_xss_in_title_is_escaped_on_show | TC-S74 | Security | 70–79 |
| 41 | test_circular_90_activity_sink_is_sys_activity_logs | TC-P90 | Tenancy | 90–99 |
| 42 | test_circular_91_unknown_id_returns_404 | TC-S91 | Security | 90–99 |

---

## 5. Manual Test Steps (workflow / money / multi-step only)

### MT-1 — Full lifecycle Draft → Distributed (BC-SM-01..03)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin with `frontoffice.circular.*`; open `/front-office/circulars/create` | Create form loads (title, subject, body, audience, effective_date, attachment) |
| 2 | Fill fields; audience=Staff; click **Submit for approval** (`action=submit`) | Redirect to communication tab; toast "Circular CIR-YYYY-NNN submitted for approval" |
| 3 | DB: `SELECT status FROM fof_circulars WHERE circular_number='CIR-…'` | `Pending_Approval` |
| 4 | Activity: `SELECT event FROM sys_activity_logs WHERE subject_id=? ORDER BY id` | rows `circular_created`, `circular_submitted` |
| 5 | Open show page; click **Approve Circular** (PATCH approve) | Toast "…approved"; status badge Approved |
| 6 | DB: `status, approved_by, approved_at` | `Approved`, causer id, timestamp set |
| 7 | Attempt to open `/…/{id}/edit` | HTTP 422 "Circular cannot be edited after it has been approved" (BR-FOF-008) |
| 8 | Click **Mark Distributed** (PATCH distribute) | Toast "…marked as distributed"; status Distributed |
| 9 | DB: `SELECT status,sent_at,ntf_log_id FROM fof_circular_distributions WHERE circular_id=?` | rows (per recipient) `status=Queued, channel=Email, sent_at=NULL, ntf_log_id=NULL` — **no real dispatch (DEV-FOF-C01)** |
| 10 | Activity | `circular_approved`, `circular_distributed` present |

### MT-2 — Illegal transition guard (BC-SM-05/06)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create a Draft circular | status Draft |
| 2 | Directly PATCH `/…/{id}/distribute` (skip approval) | DomainException "Only Approved circulars can be distributed"; status unchanged |
| 3 | PATCH `/…/{id}/approve` on a Draft | DomainException "Only Pending_Approval…"; status stays Draft |

### MT-3 — Recall gap (DEV-FOF-C03)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Distribute a circular (status Distributed) | Index shows a "Recalled" filter option |
| 2 | Look for a Recall control on the show page / any route | **None exists** — `CircularService::recall()` is unreachable; Recalled state can never be entered via the app |

---

## 6. Known Source Defects (Circular)

| ID | Sev | Summary | Proving test |
|----|-----|---------|--------------|
| DEV-FOF-C01 (=BUG-FOF-002, **partially remediated**) | P1 | `distribute()` now resolves recipients and inserts `fof_circular_distributions` rows, but performs NO real NTF dispatch: channel hard-coded `Email`, status stays `Queued`, `sent_at`/`ntf_log_id` never set. Distribution is recorded but never delivered. | test_circular_13 |
| DEV-FOF-C02 | P2 | Controller `store/update` validation `in:All,…` accepts `audience=All`, but the DDL `audience` ENUM has no `All` → DB rejects/truncates. Cross-layer enum mismatch (Cross-Ref #1). | test_circular_33 |
| DEV-FOF-C03 | P2 | `CircularService::recall()` (Distributed→Recalled) has no route/controller exposure; the Recalled state is unreachable even though the index offers the filter. Dead code / incomplete FSM. | test_circular_26 |
| DEV-FOF-C04 | P3 | Soft `destroy()` and `toggleStatus()` write no `activityLog` — inconsistent with create/update/approve/distribute/restore/forceDelete. Audit-trail gap. | test_circular_70, test_circular_73 |
| DEV-FOF-C05 | P3 | `CircularPolicy` exists but the controller authorizes via **string permission gates**, not policy binding → the policy methods are dead (same pattern as SEC-FOF-001). No dedicated FormRequest (inline validation), so SEC-FOF-003 does not apply here. | (documented; string-gate 403 proven by TC-S51..55) |

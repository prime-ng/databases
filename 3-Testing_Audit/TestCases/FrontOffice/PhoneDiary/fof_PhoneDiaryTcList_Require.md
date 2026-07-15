# FrontOffice :: PhoneDiary — Combined Test-Case List & Manual-Test Spec

> Combined artifact (Feature Info + Business Conditions + TC List + Method Index + Manual Steps + Known Defects).
> Prefix `fof_` verified against DDL `CREATE TABLE fof_phone_diary`. Tenant-side Dusk. One comprehensive suite: `fof_PhoneDiary_TestCas.php` (39 methods, `php -l` clean).

---

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | FrontOffice (FOF) |
| Feature / Screen | PhoneDiary (`phone-diary.md`) — incoming/outgoing call log with follow-up tracking |
| Primary table | `fof_phone_diary` |
| Controller | `Modules\FrontOffice\Http\Controllers\PhoneDiaryController` |
| Model | `Modules\FrontOffice\Models\PhoneDiary` (extends `App\Models\BaseModel`, `SoftDeletes`) |
| FormRequest | `Modules\FrontOffice\Http\Requests\PhoneDiaryRequest` |
| Routes (name base) | `fof.phone-diary.*` under prefix `/front-office`, middleware `auth,verified` (+ tenant) |
| URL base | `/front-office/phone-diary` |
| CRUD type | Full CRUD + soft-delete + trash/restore/force-delete + custom `complete` + `toggle-status` |
| Soft delete | YES (`deleted_at`, `SoftDeletes` trait) |
| Pagination | index 30/page; trash 20/page |
| Activity log | **NONE** — controller performs no `activityLog()` calls (**DEV-FOF-PD-002**) |
| UNIQUE keys | **NONE** on `fof_phone_diary` (G43 not applicable — proven by test_05) |
| Module status | **DISABLED** in `prime_testing/modules_statuses.json` (env prerequisite — see Validation Report) |

### Routes (from `Modules/FrontOffice/routes/web.php` — never hand-written)
| Verb | Path | Name | Method | Gate |
|------|------|------|--------|------|
| GET | `/front-office/phone-diary` | `fof.phone-diary.index` | `index` | `frontoffice.phone-diary.viewAny` |
| POST | `/front-office/phone-diary` | `fof.phone-diary.store` | `store` | `frontoffice.phone-diary.create` |
| GET | `/front-office/phone-diary/{phoneDiary}` | `fof.phone-diary.show` | `show` | `frontoffice.phone-diary.viewAny` |
| GET | `/front-office/phone-diary/{phoneDiary}/edit` | `fof.phone-diary.edit` | `edit` | `frontoffice.phone-diary.update` |
| PUT | `/front-office/phone-diary/{phoneDiary}` | `fof.phone-diary.update` | `update` | `frontoffice.phone-diary.update` |
| DELETE | `/front-office/phone-diary/{phoneDiary}` | `fof.phone-diary.destroy` | `destroy` | `frontoffice.phone-diary.delete` |
| PATCH | `/front-office/phone-diary/{phoneDiary}/complete` | `fof.phone-diary.complete` | `complete` | `frontoffice.phone-diary.update` |
| POST/PATCH | `/front-office/phone-diary/{phoneDiary}/toggle-status` | `fof.phone-diary.toggleStatus` | `toggleStatus` | `frontoffice.phone-diary.update` |
| GET | `/front-office/phone-diary/trash/view` | `fof.phone-diary.trashed` | `trashed` | `frontoffice.phone-diary.viewAny` |
| GET | `/front-office/phone-diary/{id}/restore` | `fof.phone-diary.restore` | `restore` | `frontoffice.phone-diary.restore` |
| DELETE | `/front-office/phone-diary/{id}/force-delete` | `fof.phone-diary.forceDelete` | `forceDelete` | `frontoffice.phone-diary.forceDelete` |

> Note: `store`/`update`/`destroy`/`complete` redirect to `fof.menu.registers?tab=phone-diary`. `show` gate is `viewAny` (no distinct `view` ability defined — **DEV-FOF-PD-004**, low).

---

## 2. Business Conditions

### BC-DB (DDL constraints — `fof_phone_diary`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `fof_phone_diary` exists with all 21 columns; model `$table` matches | DDL-fof_phone_diary |
| BC-DB-02 | `call_type` ENUM('Incoming','Outgoing') NOT NULL (no default) → required | DDL |
| BC-DB-03 | `call_date` DATE NOT NULL → required | DDL |
| BC-DB-04 | `call_time` TIME NOT NULL → required | DDL |
| BC-DB-05 | `caller_name` VARCHAR(100) NOT NULL → required + max 100 | DDL |
| BC-DB-06 | `purpose` VARCHAR(200) NOT NULL → required + max 200 | DDL |
| BC-DB-07 | `caller_number` VARCHAR(15) NULL → nullable + max 15 | DDL |
| BC-DB-08 | `caller_organization` VARCHAR(100) NULL → nullable + max 100 | DDL |
| BC-DB-09 | `recipient_name` VARCHAR(100) NULL → nullable + max 100 | DDL |
| BC-DB-10 | `recipient_user_id` INT UNSIGNED NULL, FK→sys_users SET NULL | DDL |
| BC-DB-11 | `message` TEXT NULL; `action_notes` TEXT NULL → long free text | DDL |
| BC-DB-12 | `action_required` TINYINT(1) NOT NULL DEFAULT 0 | DDL |
| BC-DB-13 | `action_completed` TINYINT(1) NOT NULL DEFAULT 0 | DDL |
| BC-DB-14 | `is_active` TINYINT(1) NOT NULL DEFAULT 1 | DDL |
| BC-DB-15 | `logged_by` INT UNSIGNED NULL, FK→sys_users SET NULL (controller-set) | DDL |
| BC-DB-16 | `created_by`/`updated_by` BIGINT UNSIGNED NOT NULL (no FK, controller-set — G48) | DDL |
| BC-DB-17 | `deleted_at` present + `SoftDeletes` trait (asserted independently) | DDL/Model |
| BC-DB-18 | **NO UNIQUE key** — duplicate logical rows are allowed | DDL |

### BC-VAL (FormRequest — `PhoneDiaryRequest`)
| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | `call_type` required, `in:Incoming,Outgoing` | Request |
| BC-VAL-02 | `call_date` required, date | Request |
| BC-VAL-03 | `call_time` required, string (no `date_format` — **DEV-FOF-PD-005**, weak) | Request |
| BC-VAL-04 | `caller_name` required, max:100 | Request |
| BC-VAL-05 | `purpose` required, max:200 | Request |
| BC-VAL-06 | `caller_number` nullable max:15; `caller_organization` nullable max:100; `recipient_name` nullable max:100 | Request |
| BC-VAL-07 | `recipient_user_id` nullable, integer, `exists:sys_users,id` | Request |
| BC-VAL-08 | `action_required`/`action_completed` boolean (coerced in `prepareForValidation`); `action_completed` only on PUT/PATCH | Request |

### BC-AUTH (permission gates)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/show/trashed require `frontoffice.phone-diary.viewAny` | Controller |
| BC-AUTH-02 | store requires `frontoffice.phone-diary.create` | Controller |
| BC-AUTH-03 | edit/update/complete/toggleStatus require `frontoffice.phone-diary.update` | Controller |
| BC-AUTH-04 | destroy requires `.delete`; restore `.restore`; forceDelete `.forceDelete` | Controller |
| BC-AUTH-05 | Guest → redirect to `/login` | Middleware `auth` |
| BC-AUTH-06 | `Gate::before` grants Super Admin all → negatives need a fresh non-super-admin (#31) | Rule Card |

### BC-BIZ (business rules)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `scopeActionPending` = `action_required=1 AND action_completed=0` | Model |
| BC-BIZ-02 | `scopeActive` = `is_active=1` | Model |
| BC-BIZ-03 | index KPI `pendingActions = PhoneDiary::active()->actionPending()->count()` | Controller |
| BC-BIZ-04 | index search across caller_name/number/organization/recipient_name/purpose/message/action_notes | Controller |
| BC-BIZ-05 | index `call_type` filter | Controller |
| BC-BIZ-06 | `logged_by`/`created_by`/`updated_by` = `auth()->id()` on store (auto — G48) | Controller |

### BC-SM (action lifecycle)
| State | Trigger | Next State | Source |
|-------|---------|-----------|--------|
| action_required=1, completed=0 | `complete` (PATCH) | action_completed=1 | Controller |
| is_active=1 | `toggle-status` | is_active=0 (and back) | Controller |
| active | `destroy` | soft-deleted (deleted_at set) | Controller |
| trashed | `restore` | active (deleted_at null) | Controller |
| trashed | `forceDelete` | permanently removed | Controller |

### BC-REF / BC-INT
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `recipient_user_id` FK→sys_users enforced; invalid id rejected | DDL/Request |
| BC-REF-02 | FKs declared ON DELETE SET NULL | DDL |

### BC-AUTO
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTO-01 | is_active/action_required/action_completed DB defaults applied when omitted | DDL |
| BC-AUTO-02 | logged_by/created_by/updated_by set programmatically (never a form input) | Controller |

---

## 3. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01/17 | DDL | Schema/model/soft-delete alignment | Table+cols+casts+trait correct | `test_phonediary_01_*` | Auto |
| TC-P02 | BC-DB-07..11 | DDL | Nullable cols omitted still persist | Row saved, cols NULL | `test_phonediary_03_*` | Auto |
| TC-P03 | BC-AUTO-01 | DDL | Defaults applied when omitted | is_active=1, flags=0 | `test_phonediary_04_*` | Auto |
| TC-P04 | BC-DB-18 | DDL | Duplicate logical rows allowed | Both rows persist | `test_phonediary_05_*` | Auto |
| TC-P05 | BC-DB-12..14 | Model | Casts return typed values | bool/date types | `test_phonediary_06_*` | Auto |
| TC-P06 | BC-BIZ-01 | Model | actionPending scope | Only pending rows | `test_phonediary_10_*` | Auto |
| TC-P07 | BC-BIZ-02 | Model | active scope | Excludes inactive | `test_phonediary_11_*` | Auto |
| TC-P08 | BC-BIZ-03 | Controller | Pending KPI count | Increments | `test_phonediary_12_*` | Auto |
| TC-P09 | BC-SM | Controller | complete → completed | action_completed=1 | `test_phonediary_20_*` | Auto |
| TC-P10 | BC-SM | Controller | toggle-status flips is_active | JSON success, flipped | `test_phonediary_21_*` | Auto |
| TC-P11 | BC-VAL-01 | Request | call_type accepts both values | Persist | `test_phonediary_36_*` | Auto |
| TC-P12 | BC-DB-05/06/07/08/09 | DDL | Exactly-n string persists intact | Stored full | `test_phonediary_30..34` | Auto |
| TC-P13 | BC-AUTO-02 | Controller | logged_by/created_by auto-set on store | = acting user | `test_phonediary_42_*` | Auto |
| TC-P14 | BC-BIZ-04 | Controller | Index lists & search filters | Match shown, others hidden | `test_phonediary_60/61` | Auto |
| TC-P15 | BC-BIZ-05 | Controller | call_type filter | Filter applies | `test_phonediary_62_*` | Auto |
| TC-P16 | BC-AUTH-01 | Controller | Show page displays details | Sees caller/purpose | `test_phonediary_63_*` | Auto |
| TC-P17 | BC-SM | Controller | Edit loads + update persists | New caller_name saved | `test_phonediary_64_*` | Auto |
| TC-P18 | BC-SM | Controller | Soft delete → trash | deleted_at set | `test_phonediary_70_*` | Auto |
| TC-P19 | BC-SM | Controller | Trash page lists deleted | Sees row | `test_phonediary_71_*` | Auto |
| TC-P20 | BC-SM | Controller | Restore | deleted_at null | `test_phonediary_72_*` | Auto |
| TC-P21 | BC-SM | Controller | Force delete | Row gone | `test_phonediary_73_*` | Auto |
| TC-P22 | BC-DB-11 | DDL | TEXT cols accept long content | Stored intact | `test_phonediary_75_*` | Auto |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-DB-02..06 | DDL | Missing each NOT-NULL col rejected | DB error (23000/NOT NULL) | `test_phonediary_02_*` | Auto |
| TC-N02 | BC-DB-05 | DDL | caller_name > 100 rejected/truncated | ≤100 or error | `test_phonediary_30_*` | Auto |
| TC-N03 | BC-DB-07 | DDL | caller_number > 15 rejected/truncated | ≤15 or error | `test_phonediary_31_*` | Auto |
| TC-N04 | BC-DB-08 | DDL | caller_organization > 100 | ≤100 or error | `test_phonediary_32_*` | Auto |
| TC-N05 | BC-DB-09 | DDL | recipient_name > 100 | ≤100 or error | `test_phonediary_33_*` | Auto |
| TC-N06 | BC-DB-06 | DDL | purpose > 200 | ≤200 or error | `test_phonediary_34_*` | Auto |
| TC-N07 | BC-VAL-01 | DDL | Invalid call_type ENUM | Not stored canonical | `test_phonediary_35_*` | Auto |
| TC-N08 | BC-VAL-04/05 | Request | Store missing required fields | Non-2xx (302/422/500) | `test_phonediary_37_*` | Auto |
| TC-N09 | BC-REF-01 | DDL | Invalid recipient_user_id FK | FK violation | `test_phonediary_40_*` | Auto |
| TC-N10 | BC-AUTH-05 | Middleware | Guest redirected to login | `/login` | `test_phonediary_50_*` | Auto |
| TC-N11 | BC-AUTH-01 | Controller | No viewAny → 403 | Forbidden | `test_phonediary_51_*` | Auto |
| TC-N12 | BC-AUTH-02 | Controller | No create → store 403 | Forbidden | `test_phonediary_52_*` | Auto |
| TC-N13 | BC-AUTH-01 | Controller | Non-existent id → 404 | 404 | `test_phonediary_74_*` | Auto |
| TC-N14 | BC-SEC | Security | Stored XSS escaped on show | No raw `<script>` | `test_phonediary_90_*` | Auto |

### Dependency / Integration (TC-D)
| TC ID | BC | Source | Description | Method | Status |
|-------|----|--------|-------------|--------|--------|
| TC-D01 | BC-REF-02 | DDL | FKs declared ON DELETE SET NULL | `test_phonediary_41_*` | Auto |
| TC-D02 | BC-AUTO-02 | Controller | logged_by set by controller (not user) | `test_phonediary_42_*` | Auto |

### Security / Defect probes (TC-S / DEV)
| TC ID | BC | Source | Description | Method | Status |
|-------|----|--------|-------------|--------|--------|
| TC-S01 | BC-SEC | Security | Stored XSS escaped | `test_phonediary_90_*` | Auto |
| TC-S02 | DEV-FOF-PD-002 | Audit-eq | No activity logging (proves gap) | `test_phonediary_91_*` | Auto |
| TC-S03 | DEV-FOF-PD-001 | SEC-FOF-003 | FormRequest authorize()=true (proves gap) | `test_phonediary_92_*` | Auto |

---

## 4. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_phonediary_01_migration_model_and_request_configuration_are_correct | TC-P01 | Schema/DDL | 01-09 |
| 2 | test_phonediary_02_required_notnull_columns_reject_missing_values | TC-N01 | DDL negative (G44) | 01-09 |
| 3 | test_phonediary_03_nullable_columns_accept_omitted_values | TC-P02 | DDL positive (G44) | 01-09 |
| 4 | test_phonediary_04_column_defaults_applied_on_create | TC-P03 | Defaults | 01-09 |
| 5 | test_phonediary_05_no_unique_constraint_allows_duplicate_rows | TC-P04 | UNIQUE (G43) | 01-09 |
| 6 | test_phonediary_06_casts_return_typed_values | TC-P05 | Model casts | 01-09 |
| 7 | test_phonediary_10_action_pending_scope_filters_correctly | TC-P06 | BC-BIZ | 10-19 |
| 8 | test_phonediary_11_active_scope_excludes_inactive | TC-P07 | BC-BIZ | 10-19 |
| 9 | test_phonediary_12_pending_actions_count_is_consistent | TC-P08 | BC-BIZ | 10-19 |
| 10 | test_phonediary_20_complete_endpoint_marks_action_completed | TC-P09 | BC-SM | 20-29 |
| 11 | test_phonediary_21_toggle_status_flips_is_active | TC-P10 | BC-SM | 20-29 |
| 12 | test_phonediary_30_caller_name_length_boundary | TC-N02/P12 | Validation (G45) | 30-39 |
| 13 | test_phonediary_31_caller_number_length_boundary | TC-N03/P12 | Validation (G45) | 30-39 |
| 14 | test_phonediary_32_caller_organization_length_boundary | TC-N04/P12 | Validation (G45) | 30-39 |
| 15 | test_phonediary_33_recipient_name_length_boundary | TC-N05/P12 | Validation (G45) | 30-39 |
| 16 | test_phonediary_34_purpose_length_boundary | TC-N06/P12 | Validation (G45) | 30-39 |
| 17 | test_phonediary_35_call_type_enum_rejects_invalid | TC-N07 | Validation | 30-39 |
| 18 | test_phonediary_36_call_type_enum_accepts_valid_values | TC-P11 | Validation | 30-39 |
| 19 | test_phonediary_37_store_rejects_missing_required_field | TC-N08 | Validation | 30-39 |
| 20 | test_phonediary_40_recipient_user_id_fk_is_enforced | TC-N09 | FK/Integration | 40-49 |
| 21 | test_phonediary_41_foreign_keys_defined_as_set_null | TC-D01 | FK/Integration | 40-49 |
| 22 | test_phonediary_42_logged_by_is_set_by_controller_on_store | TC-D02/P13 | Auto-managed (G48) | 40-49 |
| 23 | test_phonediary_50_guest_redirected_to_login | TC-N10 | Auth | 50-59 |
| 24 | test_phonediary_51_index_requires_viewany_permission | TC-N11 | Auth (F37) | 50-59 |
| 25 | test_phonediary_52_store_requires_create_permission | TC-N12 | Auth (F37) | 50-59 |
| 26 | test_phonediary_60_index_page_loads_and_lists_records | TC-P14 | UI/UX | 60-69 |
| 27 | test_phonediary_61_search_filters_results | TC-P14 | UI/UX | 60-69 |
| 28 | test_phonediary_62_call_type_filter_applies | TC-P15 | UI/UX | 60-69 |
| 29 | test_phonediary_63_show_page_displays_details | TC-P16 | UI/UX | 60-69 |
| 30 | test_phonediary_64_edit_page_loads_and_updates | TC-P17 | UI/UX + SM | 60-69 |
| 31 | test_phonediary_70_soft_delete_moves_to_trash | TC-P18 | Edge/SM | 70-79 |
| 32 | test_phonediary_71_trash_page_shows_deleted | TC-P19 | Edge/SM | 70-79 |
| 33 | test_phonediary_72_restore_from_trash | TC-P20 | Edge/SM | 70-79 |
| 34 | test_phonediary_73_force_delete_is_permanent | TC-P21 | Edge/SM | 70-79 |
| 35 | test_phonediary_74_show_404_for_nonexistent_record | TC-N13 | Edge | 70-79 |
| 36 | test_phonediary_75_text_columns_accept_long_content | TC-P22 | Edge | 70-79 |
| 37 | test_phonediary_90_stored_xss_in_caller_name_is_escaped | TC-N14/S01 | Security | 90-99 |
| 38 | test_phonediary_91_controller_has_no_activity_logging_documents_gap | TC-S02 | DEV probe | 90-99 |
| 39 | test_phonediary_92_formrequest_authorize_returns_true_documents_dev | TC-S03 | DEV probe | 90-99 |

---

## 5. Manual Test Steps (complex/workflow paths only)

Simple CRUD/validation cases are fully specified by the Expected column in §3. Steps below cover the follow-up lifecycle and permission gate a human tester genuinely needs.

### MT-01 — Log a call with a follow-up action, then mark it done
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/front-office/phone-diary`, open the "Log New Call" form | Quick-add form visible (call_type, call_date, call_time, caller_name, caller_number, purpose) |
| 2 | Fill Incoming / today / now / "John Doe" / "9998887776" / "Fee query", tick **Action Required**, add action note, submit | Redirect to registers `?tab=phone-diary`, banner "Call log entry added." |
| 3 | DB check | `SELECT action_required, action_completed, logged_by FROM fof_phone_diary WHERE caller_name='John Doe'` → `1, 0, <your user id>` |
| 4 | On the row, click **Mark Done** (posts to `phone-diary.complete`) | Banner "Action marked as completed." |
| 5 | DB check | `action_completed = 1` for that row |
| 6 | Activity log check | **No** `activity_logs` row is written for this flow — this is the documented gap **DEV-FOF-PD-002** |

### MT-02 — Permission gate (non-super-admin without create)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create a tenant user with no roles/permissions; ensure not super-admin | User exists, `is_super_admin=0` |
| 2 | Clear permission cache, log in as that user, POST to `/front-office/phone-diary` | HTTP 403 (Gate `frontoffice.phone-diary.create` denies) |
| 3 | Grant `frontoffice.phone-diary.create`, clear cache, retry | Store succeeds |

### MT-03 — Toggle status (JSON)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/front-office/phone-diary/{id}/toggle-status` with CSRF + `X-Requested-With` | JSON `{success:true, is_active:false}` |
| 2 | DB check | `is_active` flipped |

---

## 6. Known Source Defects (DEV-###)

| ID | Sev | Description | Proving test |
|----|-----|-------------|--------------|
| DEV-FOF-PD-001 | P1 | `PhoneDiaryRequest::authorize()` blanket-returns `true` — instance of module-wide **SEC-FOF-003** (no defense-in-depth) | `test_phonediary_92_*` |
| DEV-FOF-PD-002 | P2 | `PhoneDiaryController` performs **no** `activityLog()` calls — diverges from the module's 72-call-site convention; create/update/delete/complete/toggle are unaudited | `test_phonediary_91_*` |
| DEV-FOF-PD-004 | P3 | `show()` authorizes `frontoffice.phone-diary.viewAny` (no distinct `.view` ability) — inconsistent with other read paths | (documented; index gate covered by `test_51`) |
| DEV-FOF-PD-005 | P3 | `call_time` validated only as `['required','string']` (no `date_format:H:i`) — arbitrary strings pass the FormRequest and are only caught by the DB TIME column | `test_phonediary_02_*` (DB layer) |

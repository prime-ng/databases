# FrontOffice :: KeyRegister — Combined TC List + Manual Test Spec

> Artifact 1 of 5. Combined requirements + manual-testing document.
> Feature = screen `key-register.md`. Primary table `fof_key_register` (prefix `fof_`).
> One comprehensive Dusk suite: `fof_KeyRegister_TestCas.php` (53 test methods).

---

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | FrontOffice (FOF) |
| Feature / Screen | KeyRegister — Key Management Register (issue / return workflow) |
| Primary table | `fof_key_register` |
| URL (index) | `/front-office/keys` (route `fof.keys.index`); also surfaced via `fof.menu.registers?tab=keys` |
| Controller | `Modules\FrontOffice\Http\Controllers\KeyRegisterController` |
| FormRequest | `Modules\FrontOffice\Http\Requests\KeyRegisterRequest` (validates `key_label`, `key_tag_number`, `is_active` only) |
| Model | `Modules\FrontOffice\Models\KeyRegister` (`$table = fof_key_register`, `SoftDeletes`, scopes `active`/`available`/`overdue`, `isAvailable()`) |
| CRUD type | Modal/page CRUD + workflow verbs `issue`, `return`, `toggleStatus` + trash/restore/force-delete |
| Soft delete | YES (`deleted_at`; model uses `SoftDeletes`) |
| Pagination | 20/page (available/issued/overdue panels), 15/page (trash) |
| Activity log | `sys_activity_logs` (GlobalMaster\ActivityLog). Events: `Updated`, `Deleted`, `Restored`, `key_issued`, `key_returned`. **store() and toggleStatus() log NOTHING** (DEV-FOF-KR-005). |
| DB scope | TENANT-SIDE (tenancy init required) |
| Test style | Browser Dusk (`extends DuskTestCase`), mirrors FrontOffice\PhoneDiary sibling |

**Routes (verified from `Modules/FrontOffice/routes/web.php`, group `auth`+`verified`, prefix `/front-office`, name `fof.`):**

| Verb | Path | Name | Method | Gate |
|------|------|------|--------|------|
| GET | `/keys` | `fof.keys.index` | index | `frontoffice.key-register.viewAny` |
| POST | `/keys` | `fof.keys.store` | store | `frontoffice.key-register.create` |
| GET | `/keys/{key}` | `fof.keys.show` | show | `frontoffice.key-register.viewAny` |
| GET | `/keys/{key}/edit` | `fof.keys.edit` | edit | `frontoffice.key-register.update` |
| PUT | `/keys/{key}` | `fof.keys.update` | update | `frontoffice.key-register.update` |
| DELETE | `/keys/{key}` | `fof.keys.destroy` | destroy | `frontoffice.key-register.delete` |
| PATCH | `/keys/{key}/issue` | `fof.keys.issue` | issue | `frontoffice.key-register.update` |
| PATCH | `/keys/{key}/return` | `fof.keys.return` | return | `frontoffice.key-register.update` |
| POST/PATCH | `/keys/{key}/toggle-status` | `fof.keys.toggleStatus` | toggleStatus | `frontoffice.key-register.update` |
| GET | `/keys/trash/view` | `fof.keys.trashed` | trashed | `frontoffice.key-register.viewAny` |
| GET | `/keys/{id}/restore` | `fof.keys.restore` | restore | `frontoffice.key-register.restore` |
| DELETE | `/keys/{id}/force-delete` | `fof.keys.forceDelete` | forceDelete | `frontoffice.key-register.forceDelete` |

> No `routes/api.php` entry for keys (the requirement's `GET /api/v1/front-office/keys/overdue` is NOT registered — DEV-FOF-KR-007). Overdue is only computed inside `index()`.

---

## 2. Business Conditions

### BC-DB (DDL constraints — `fof_key_register`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `id` BIGINT UNSIGNED PK AI | DDL-fof_key_register |
| BC-DB-02 | `key_label` VARCHAR(100) NOT NULL (no default) → required + max-100 | DDL |
| BC-DB-03 | `key_tag_number` VARCHAR(30) NOT NULL (no default) → required + max-30 | DDL |
| BC-DB-04 | `key_type` ENUM(Room,Lab,Vehicle,Cabinet,Store,Other) NOT NULL (no default) → required | DDL |
| BC-DB-05 | `issued_to_user_id` INT UNSIGNED NULL, FK→sys_users ON DELETE SET NULL | DDL |
| BC-DB-06 | `purpose` VARCHAR(200) NULL | DDL |
| BC-DB-07 | `issued_at` / `expected_return_at` / `returned_at` DATETIME NULL | DDL |
| BC-DB-08 | `status` ENUM(Available,Issued,Overdue,Lost) NOT NULL DEFAULT 'Available' | DDL |
| BC-DB-09 | `is_active` TINYINT(1) NOT NULL DEFAULT 1 | DDL |
| BC-DB-10 | `created_by` / `updated_by` BIGINT UNSIGNED NOT NULL (no FK) | DDL |
| BC-DB-11 | `deleted_at` TIMESTAMP NULL (soft delete) — trait asserted independently | DDL |
| BC-DB-12 | **NO DB UNIQUE index** (only non-unique idx on status/issued_to). App-level unique on key_tag_number only. | DDL / FormRequest |

### BC-VAL (FormRequest / endpoint validation)

| ID | Rule | Message / behaviour | Source |
|----|------|--------------------|--------|
| BC-VAL-01 | `key_label` required, string, max:100 | 422/redirect on fail | Request::rules |
| BC-VAL-02 | `key_tag_number` required, string, max:30, unique(fof_key_register,key_tag_number) ignore self | "This Key Tag Number is already registered in the system." | Request::rules/messages |
| BC-VAL-03 | `is_active` nullable, boolean | — | Request::rules |
| BC-VAL-04 | **`key_type` is NOT validated** (missing from rules) | → store 500 (DEV-FOF-KR-001) | Request::rules |
| BC-VAL-05 | issue(): `expected_return_at` required, date, after:now | abort/redirect on fail | Controller::issue |
| BC-VAL-06 | issue(): `issued_to_user_id` nullable, integer | — | Controller::issue |

### BC-AUTH (permission gate ↔ method)

| ID | Gate | Methods | Source |
|----|------|---------|--------|
| BC-AUTH-01 | `frontoffice.key-register.viewAny` | index, show, trashed | Controller |
| BC-AUTH-02 | `frontoffice.key-register.create` | store | Controller |
| BC-AUTH-03 | `frontoffice.key-register.update` | edit, update, issue, return, toggleStatus | Controller |
| BC-AUTH-04 | `frontoffice.key-register.delete` | destroy | Controller |
| BC-AUTH-05 | `frontoffice.key-register.restore` | restore | Controller |
| BC-AUTH-06 | `frontoffice.key-register.forceDelete` | forceDelete | Controller |
| BC-AUTH-07 | `Gate::before` grants Super Admin all → negatives need a non-super-admin + cache flush | #31 |
| BC-AUTH-08 | Requirement doc lists `frontoffice.visitor.view/create` — WRONG; real gates are `frontoffice.key-register.*` (DEV-FOF-KR-008) | Screen-PM vs Controller |

### BC-BIZ (business logic / auto-behaviour / activity events)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | store() forces `status='Available'` + `created_by`/`updated_by`=auth id (G48 auto) | Controller::store |
| BC-BIZ-02 | store() writes NO activity log (DEV-FOF-KR-005) | Controller::store |
| BC-BIZ-03 | update() sets `updated_by`=auth id and logs `Updated` | Controller::update |
| BC-BIZ-04 | destroy() soft-deletes and logs `Deleted` | Controller::destroy |
| BC-BIZ-05 | restore() logs `Restored`; forceDelete() logs `Deleted` | Controller |
| BC-BIZ-06 | issue() logs `key_issued` (lowercase); return() logs `key_returned` (lowercase) — diverges from module past-tense convention (DEV-FOF-KR-004) | Controller |
| BC-BIZ-07 | scopeActive / scopeAvailable / scopeOverdue filter rows; isAvailable() reads status | Model |
| BC-BIZ-08 | index() overdue panel = status='Issued' AND expected_return_at < now (computed, not persisted) | Controller::index |
| BC-BIZ-09 | issue() wraps update in `DB::transaction` + `lockForUpdate()` (DAT-FOF-004 remediated) | Controller::issue |

### BC-SM (state-machine transitions — status lifecycle)

| ID | State | Trigger | Next State | Enforcement | Source |
|----|-------|---------|-----------|-------------|--------|
| BC-SM-01 | Available | issue() (valid expected_return_at) | Issued | sets issued_at/expected_return_at; log `key_issued` | Screen-SM / Controller |
| BC-SM-02 | Issued/Overdue/Lost | issue() | (blocked) | `abort_if(status!=='Available',422)` — BR-FOF-012 | Screen-SM / Controller |
| BC-SM-03 | Issued | return() | Available | clears issued_to/issued_at/expected_return_at; sets returned_at; log `key_returned` | Screen-SM / Controller |
| BC-SM-04 | Overdue | return() | Available | allowed (in_array Issued,Overdue) | Screen-SM / Controller |
| BC-SM-05 | Available | return() | (blocked) | `abort_if(!in_array(status,[Issued,Overdue]),422)` | Screen-SM / Controller |
| BC-SM-06 | Issued | (overdue detection) | Overdue (display only) | computed in index; NEVER persisted (no job) — DEV-FOF-KR-006 | Screen-SM |
| BC-SM-07 | any | mark Lost | Lost | **NO route/method exists** — unreachable via app (DEV-FOF-KR-006) | Screen-SM |

### BC-REF (FK integrity)

| ID | FK | Referenced | onDelete | Source |
|----|----|-----------|----------|--------|
| BC-REF-01 | `issued_to_user_id` | `sys_users.id` | SET NULL | DDL |

### BC-EDG (edge/boundary)

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | over-length key_label(100)/key_tag_number(30)/purpose(200) rejected or truncated | DDL/#45 |
| BC-EDG-02 | invalid key_type/status ENUM rejected at DB | DDL |
| BC-EDG-03 | show 404 for non-existent id | RMB |
| BC-EDG-04 | stored XSS in key_label escaped on show | Security |

---

## 3. Test Case List

### Positive (TC-P)

| TC ID | Cat | BC | Source | Description | Expected Result | Method | Status |
|-------|-----|----|--------|-------------|-----------------|--------|--------|
| TC-P01 | Config | BC-DB-01..12 | DDL | DDL↔app alignment matrix | table/cols/model/casts/soft-delete/no-unique all align | test_01 | Auto |
| TC-P02 | Positive | BC-DB-05..08 | DDL | nullable cols omitted persist | row saved; nullable cols NULL | test_03 | Auto |
| TC-P03 | Positive | BC-DB-08,09 | DDL | defaults applied | status=Available, is_active=1 | test_04 | Auto |
| TC-P04 | Positive | BC-DB-07 | DDL | datetime + bool casts typed | Carbon / bool | test_05 | Auto |
| TC-P05 | Positive | BC-DB-04 | DDL | key_type accepts all 6 ENUM values | each persists | test_06 | Auto |
| TC-P06 | Positive | BC-DB-08 | DDL | status accepts all 4 ENUM values | each persists | test_08 | Auto |
| TC-P07 | Positive | BC-BIZ-07 | Model | active/available/overdue scopes | correct filtering | test_10,11,12 | Auto |
| TC-P08 | Positive | BC-BIZ-07 | Model | isAvailable() helper | true only for Available | test_13 | Auto |
| TC-P09 | Positive | BC-BIZ-08 | Controller | overdue detection query | past-due issued detected | test_14 | Auto |
| TC-P10 | Positive | BC-SM-01,06 | Screen-SM | issue Available→Issued + log | status Issued; key_issued log | test_20 | Auto |
| TC-P11 | Positive | BC-SM-03 | Screen-SM | return Issued→Available + log | status Available; key_returned log | test_22 | Auto |
| TC-P12 | Positive | BC-SM-04 | Screen-SM | return Overdue→Available | status Available | test_24 | Auto |
| TC-P13 | Positive | BC-SM-01,03 | Screen-SM | full issue→return lifecycle | Available again | test_25 | Auto |
| TC-P14 | Positive | BC-VAL-01..03 | DDL | key_label/tag/purpose exactly-n | persists intact | test_30,31,32 | Auto |
| TC-P15 | Positive | BC-BIZ-03 | Controller | update sets updated_by + Updated log | acting user; log present | test_42 | Auto |
| TC-P16 | Positive | Screen | Blade | index lists an available key | key_label visible | test_60 | Auto |
| TC-P17 | Positive | Screen | Controller | search by label / tag | match shown, others hidden | test_61,62 | Auto |
| TC-P18 | Positive | Screen | Blade | show page details | label + tag visible | test_63 | Auto |
| TC-P19 | Positive | BC-BIZ-03 | Controller | edit loads + update persists label | new label saved | test_64 | Auto |
| TC-P20 | Positive | BC-BIZ-04,05 | Controller | soft-delete/trash/restore/force | lifecycle + logs | test_70,71,72,73 | Auto |
| TC-P21 | Positive | BC-AUTH-03 | Controller | toggle-status JSON flips is_active | success:true; flipped | test_75 | Auto |

### Negative (TC-N)

| TC ID | Cat | BC | Source | Description | Expected Result | Method | Status |
|-------|-----|----|--------|-------------|-----------------|--------|--------|
| TC-N01 | Negative | BC-DB-02,03,04,10 | DDL/G44 | missing NOT-NULL col rejected | DB error (1364/23000) | test_02 | Auto |
| TC-N02 | Negative | BC-DB-04 | DDL | invalid key_type ENUM | not stored canonical / rejected | test_07 | Auto |
| TC-N03 | Negative | BC-SM-02 | Screen-SM | issue non-Available key blocked | 422 (tolerant); status unchanged | test_21 | Auto |
| TC-N04 | Negative | BC-SM-05 | Screen-SM | return Available key blocked | 422 (tolerant); status unchanged | test_23 | Auto |
| TC-N05 | Negative | BC-VAL-01 | Request | store missing key_label | non-2xx | test_33 | Auto |
| TC-N06 | Negative | BC-VAL-02 | Request | store missing key_tag_number | non-2xx | test_34 | Auto |
| TC-N07 | Negative | BC-VAL-02/G43 | Request | duplicate key_tag_number (form) | rejected; no 2nd row | test_35 | Auto |
| TC-N08 | Negative | BC-VAL-05 | Controller | issue missing/past expected_return_at | rejected; status unchanged | test_37 | Auto |
| TC-N09 | Negative | BC-EDG-01 | DDL/#45 | over-length label/tag/purpose | rejected or truncated ≤ n | test_30,31,32 | Auto |
| TC-N10 | Negative | BC-EDG-03 | RMB | show non-existent id | 404 | test_74 | Auto |
| TC-N11 | Security | BC-EDG-04 | Sec | stored XSS key_label | escaped on show | test_90 | Auto |

### Dependency (TC-D)

| TC ID | Sub | BC | Source | Description | Expected Result | Method | Status |
|-------|-----|----|--------|-------------|-----------------|--------|--------|
| TC-D01 | C/D | BC-REF-01 | DDL | issued_to_user_id FK enforced | FK error (or skip if absent) | test_40 | Auto |
| TC-D02 | D | BC-REF-01 | DDL | FK declared SET NULL | schema shows set null | test_41 | Auto |
| TC-D03 | B | BC-BIZ-04 | Controller | soft-delete preserves; restore recovers; force removes | lifecycle correct | test_70,72,73 | Auto |
| TC-D04 | G | BC-DB-12 | DDL | DB allows duplicate tag (no unique idx) | 2 rows persist | test_36 | Auto |

### Permissions / Tenancy / Security (TC-T / TC-S / TC-AUTH)

| TC ID | Cat | BC | Source | Description | Expected Result | Method | Status |
|-------|-----|----|--------|-------------|-----------------|--------|--------|
| TC-S01 | Auth | — | Controller | guest → login | redirect /login | test_50 | Auto |
| TC-S02 | Auth | BC-AUTH-01 | #31/F37 | index requires viewAny (non-super-admin) | 403 | test_51 | Auto |
| TC-S03 | Auth | BC-AUTH-02 | #31/F37 | store requires create | 403 | test_52 | Auto |
| TC-S04 | Auth | BC-AUTH-03 | #31/F37 | issue requires update | 403; not issued | test_53 | Auto |
| TC-S05 | Auth | BC-AUTH-04 | #31/F37 | destroy requires delete | 403; not deleted | test_54 | Auto |

### State-machine (TC-SM) — enumerated

| TC ID | BC-SM | Legal? | Method |
|-------|-------|--------|--------|
| TC-SM01 | BC-SM-01 | legal | test_20 |
| TC-SM02 | BC-SM-02 | illegal | test_21 |
| TC-SM03 | BC-SM-03 | legal | test_22 |
| TC-SM04 | BC-SM-04 | legal | test_24 |
| TC-SM05 | BC-SM-05 | illegal | test_23 |
| TC-SM06 | BC-SM-01→03 | round-trip | test_25 |
| TC-SM07 | BC-SM-06 (Overdue display only) | doc | test_14 + Gap |
| TC-SM08 | BC-SM-07 (Lost unreachable) | doc | test_93/Gap (DEV-FOF-KR-006) |

### DEV-defect proving tests

| TC ID | Defect | Description | Method |
|-------|--------|-------------|--------|
| TC-DEV01 | DEV-FOF-KR-001 | store broken — key_type never set → no row / 500 | test_91 |
| TC-DEV02 | DEV-FOF-KR-001/002 | FormRequest omits key_type; store() does not set it (source) | test_92 |
| TC-DEV03 | DEV-FOF-KR-002 | Blade sends location/description (non-existent cols) | test_91 (payload) |
| TC-DEV04 | DEV-FOF-KR-003 | issue leaves issued_to_user_id NULL (no UI field) | test_26 |
| TC-DEV05 | DEV-FOF-KR-004 | app unique but no DB unique index | test_01, test_36 |
| TC-DEV06 | DEV-FOF-KR-005 | store() has no activityLog | test_93 |
| TC-DEV07 | SEC-FOF-003 | FormRequest authorize() returns true | test_94 |
| TC-DEV08 | DAT-FOF-004 (remediated) | issue() uses transaction+lockForUpdate; BR-FOF-012 guard | test_95 |

---

## 4. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_keyregister_01_migration_model_and_request_configuration_are_correct | TC-P01, TC-DEV05 | Config/G46 | 01-09 |
| 2 | test_keyregister_02_required_notnull_columns_reject_missing_values | TC-N01 | Negative/G44 | 01-09 |
| 3 | test_keyregister_03_nullable_columns_accept_omitted_values | TC-P02 | Positive/G44 | 01-09 |
| 4 | test_keyregister_04_column_defaults_applied_on_create | TC-P03 | Positive | 01-09 |
| 5 | test_keyregister_05_casts_return_typed_values | TC-P04 | Positive | 01-09 |
| 6 | test_keyregister_06_key_type_enum_accepts_valid_values | TC-P05 | Positive | 01-09 |
| 7 | test_keyregister_07_key_type_enum_rejects_invalid | TC-N02 | Negative | 01-09 |
| 8 | test_keyregister_08_status_enum_accepts_valid_values | TC-P06 | Positive | 01-09 |
| 9 | test_keyregister_10_active_scope_excludes_inactive | TC-P07 | BizRule | 10-19 |
| 10 | test_keyregister_11_available_scope_filters_status | TC-P07 | BizRule | 10-19 |
| 11 | test_keyregister_12_overdue_scope_filters_status | TC-P07 | BizRule | 10-19 |
| 12 | test_keyregister_13_is_available_helper_reflects_status | TC-P08 | BizRule | 10-19 |
| 13 | test_keyregister_14_overdue_detection_query_matches_past_due_issued_keys | TC-P09, TC-SM07 | BizRule | 10-19 |
| 14 | test_keyregister_20_issue_transitions_available_to_issued | TC-P10, TC-SM01 | SM | 20-29 |
| 15 | test_keyregister_21_issue_blocked_when_not_available | TC-N03, TC-SM02 | SM | 20-29 |
| 16 | test_keyregister_22_return_transitions_issued_to_available | TC-P11, TC-SM03 | SM | 20-29 |
| 17 | test_keyregister_23_return_blocked_when_available | TC-N04, TC-SM05 | SM | 20-29 |
| 18 | test_keyregister_24_return_allowed_from_overdue | TC-P12, TC-SM04 | SM | 20-29 |
| 19 | test_keyregister_25_full_issue_return_lifecycle | TC-P13, TC-SM06 | SM | 20-29 |
| 20 | test_keyregister_26_issue_leaves_issued_to_user_null_documents_dev | TC-DEV04 | SM/DEV | 20-29 |
| 21 | test_keyregister_30_key_label_length_boundary | TC-P14, TC-N09 | Validation/G45 | 30-39 |
| 22 | test_keyregister_31_key_tag_number_length_boundary | TC-P14, TC-N09 | Validation/G45 | 30-39 |
| 23 | test_keyregister_32_purpose_length_boundary | TC-P14, TC-N09 | Validation/G45 | 30-39 |
| 24 | test_keyregister_33_store_rejects_missing_key_label | TC-N05 | Validation | 30-39 |
| 25 | test_keyregister_34_store_rejects_missing_key_tag_number | TC-N06 | Validation | 30-39 |
| 26 | test_keyregister_35_duplicate_key_tag_number_rejected_by_formrequest | TC-N07 | Validation/G43 | 30-39 |
| 27 | test_keyregister_36_db_allows_duplicate_tag_no_unique_index | TC-D04, TC-DEV05 | Validation/G43 | 30-39 |
| 28 | test_keyregister_37_issue_requires_future_expected_return_at | TC-N08 | Validation | 30-39 |
| 29 | test_keyregister_40_issued_to_user_id_fk_is_enforced | TC-D01 | FK | 40-49 |
| 30 | test_keyregister_41_issued_to_user_fk_is_set_null | TC-D02 | FK | 40-49 |
| 31 | test_keyregister_42_update_sets_updated_by_to_acting_user | TC-P15 | FK/G48 | 40-49 |
| 32 | test_keyregister_50_guest_redirected_to_login | TC-S01 | Auth | 50-59 |
| 33 | test_keyregister_51_index_requires_viewany_permission | TC-S02 | Auth | 50-59 |
| 34 | test_keyregister_52_store_requires_create_permission | TC-S03 | Auth | 50-59 |
| 35 | test_keyregister_53_issue_requires_update_permission | TC-S04 | Auth | 50-59 |
| 36 | test_keyregister_54_destroy_requires_delete_permission | TC-S05 | Auth | 50-59 |
| 37 | test_keyregister_60_index_page_loads_and_lists_records | TC-P16 | UI | 60-69 |
| 38 | test_keyregister_61_search_filters_results | TC-P17 | UI | 60-69 |
| 39 | test_keyregister_62_search_by_tag_number_matches | TC-P17 | UI | 60-69 |
| 40 | test_keyregister_63_show_page_displays_details | TC-P18 | UI | 60-69 |
| 41 | test_keyregister_64_edit_page_loads_and_updates | TC-P19 | UI | 60-69 |
| 42 | test_keyregister_70_soft_delete_moves_to_trash | TC-P20, TC-D03 | Lifecycle | 70-79 |
| 43 | test_keyregister_71_trash_page_shows_deleted | TC-P20 | Lifecycle | 70-79 |
| 44 | test_keyregister_72_restore_from_trash | TC-P20, TC-D03 | Lifecycle | 70-79 |
| 45 | test_keyregister_73_force_delete_is_permanent | TC-P20, TC-D03 | Lifecycle | 70-79 |
| 46 | test_keyregister_74_show_404_for_nonexistent_record | TC-N10 | Edge | 70-79 |
| 47 | test_keyregister_75_toggle_status_flips_is_active | TC-P21 | Lifecycle | 70-79 |
| 48 | test_keyregister_90_stored_xss_in_key_label_is_escaped | TC-N11 | Security | 90-99 |
| 49 | test_keyregister_91_store_create_flow_is_broken_missing_key_type | TC-DEV01, TC-DEV03 | DEV | 90-99 |
| 50 | test_keyregister_92_formrequest_omits_key_type_documents_dev | TC-DEV02 | DEV | 90-99 |
| 51 | test_keyregister_93_store_has_no_activity_log_documents_dev | TC-DEV06 | DEV | 90-99 |
| 52 | test_keyregister_94_formrequest_authorize_returns_true_documents_dev | TC-DEV07 | DEV | 90-99 |
| 53 | test_keyregister_95_issue_uses_row_lock_and_status_guard | TC-DEV08 | DEV | 90-99 |

---

## 5. Manual Test Steps (workflow / state-machine cases only)

> Simple CRUD/validation cases are fully covered by the Expected-Result column in section 3.
> Manual steps are provided only for the issue/return workflow and the broken-create defect.

### MT-01 — Issue a key (Available → Issued) [BC-SM-01]

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed an available key (status='Available') | Row visible in the "Available" panel of `/front-office/keys` |
| 2 | Open the Issue form for that key; set `expected_return_at` to a future datetime; submit (PATCH `/keys/{id}/issue`) | Redirect back with success "Key '…' issued." |
| 3 | DB check | `SELECT status, issued_at, expected_return_at FROM fof_key_register WHERE id=?` → status='Issued', issued_at set, expected_return_at set |
| 4 | Activity check | `SELECT event FROM sys_activity_logs WHERE subject_type='Modules\\FrontOffice\\Models\\KeyRegister' AND subject_id=?` → contains `key_issued` (lowercase) |
| 5 | Note (DEV-FOF-KR-003) | `issued_to_user_id` remains NULL — the issue form captures no user |

### MT-02 — Issue blocked when not Available [BC-SM-02 / BR-FOF-012]

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed a key with status='Issued' | — |
| 2 | Submit the issue endpoint again | HTTP 422 "Key is not available for issue." (tolerant: 422/500/302) |
| 3 | DB check | status still 'Issued'; no new issued_at overwrite expected |

### MT-03 — Return a key (Issued/Overdue → Available) [BC-SM-03/04]

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed an issued key (status='Issued', issued_to set, expected_return_at set) | Visible in "Issued" panel |
| 2 | Submit Return (PATCH `/keys/{id}/return`) | Redirect back "Key '…' returned." |
| 3 | DB check | status='Available', returned_at set, issued_to_user_id/issued_at/expected_return_at all NULL |
| 4 | Activity check | `sys_activity_logs` event = `key_returned` (lowercase) |
| 5 | Repeat with status='Overdue' | Same result (return tolerates Issued OR Overdue) |

### MT-04 — Return blocked when Available [BC-SM-05]

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed an Available key | — |
| 2 | Submit Return | HTTP 422 "Key is not currently issued." (tolerant) |
| 3 | DB check | status unchanged 'Available' |

### MT-05 — Create flow is broken (DEV-FOF-KR-001)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open `/front-office/keys`, fill the Add-Key form (key_label + key_tag_number; the form also sends `location`/`description`) and submit | **No key created** — HTTP 500 (MySQL 1364: `key_type` has no default). Tolerant set {500,422,302}. |
| 2 | DB check | `SELECT COUNT(*) … WHERE key_label=?` → 0 rows |
| 3 | Root cause | FormRequest never validates `key_type`; store() array_merge never sets it; `key_type` is NOT-NULL-no-default. Blade sends `location`/`description` which map to no column. |

---

## 6. Known Source Defects (proved by this suite)

| ID | Sev | Summary | Proving test(s) |
|----|-----|---------|-----------------|
| DEV-FOF-KR-001 | P1 | Create flow broken: `key_type` NOT-NULL-no-default never validated/set → store 500, no row | test_91, test_92, test_02 |
| DEV-FOF-KR-002 | P2 | Blade create/edit fields `location`/`description` map to no column (real cols key_type/purpose) → input dropped | test_91, test_92 |
| DEV-FOF-KR-003 | P2 | issue() captures no `issued_to_user_id` (no UI field) and ignores `purpose` → always NULL, diverges from Issue Flow | test_26 |
| DEV-FOF-KR-004 | P2 | App-level unique on key_tag_number but NO DB UNIQUE index → direct duplicates possible | test_01, test_36 |
| DEV-FOF-KR-005 | P2 | store()/toggleStatus() write NO activity log (inconsistent with other verbs) | test_93 |
| DEV-FOF-KR-006 | P3 | `Overdue` never persisted (computed only; no job); `Lost` unreachable (no setter) | test_14 + Gap |
| DEV-FOF-KR-007 | P3 | Requirement's `GET /api/v1/front-office/keys/overdue` endpoint NOT registered | Gap (routes) |
| DEV-FOF-KR-008 | P3 | Requirement permission matrix names `frontoffice.visitor.*`; real gates are `frontoffice.key-register.*` | Gap (BC-AUTH-08) |
| SEC-FOF-003 | P1 | FormRequest `authorize()` returns true (module-wide D30) | test_94 |
| DAT-FOF-004 | — | Audit-flagged key-issue race REMEDIATED: issue() uses DB::transaction + lockForUpdate | test_95 |

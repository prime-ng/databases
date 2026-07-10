# glb_Language — Test Case List & Business Conditions

**Module:** GlobalMaster (central / prime-side)
**Feature / Screen:** Language (platform reference language master)
**Primary table:** `glb_languages` (prefix `glb_`) — real table on `global_master_mysql`, exposed as a VIEW on the central `mysql` connection
**DB scope:** CENTRAL (prime-side) — **no tenant init**; cross-tenant isolation N/A
**Live controller under test:** `Modules\Prime\Http\Controllers\LanguageController` (serves the `central.global-master.language.*` routes)
**Test style:** Browser Dusk, central pattern — `namespace Tests\Browser\Modules\Prime\GlobalMaster`, `extends PrimeDuskTestCase` (physical `prm_PrimeDuskTestCase_TestCas`, forces `http://127.0.0.1:8000`), Billing central helpers reused in-file
**Requirement sources:** `_global_db_v4.sql` (DDL), `GLB_FRD_Complete_2026-06-29.md` (FRD), `GlobalMaster_Complete_Audit_2026-06-29.md` (audit). No dedicated `GlobalMaster_v1/language.md` screen file exists — the DDL + FRD + controller are the primary requirement source for this feature.

> **CRITICAL ROUTING RECONCILIATION (read first).** Two `LanguageController` classes exist:
> - `Modules\Prime\Http\Controllers\LanguageController` — imported by **root** `routes/web.php` (line 10) and registered inside `Route::domain(config('app.domain'))->name("central.")->…->prefix('global-master')->name('global-master.')`. **This is the LIVE controller for `central.global-master.language.*`** and the one these tests exercise. It renders `prime::language.*` views and uses `Modules\Prime\Models\Language`.
> - `Modules\GlobalMaster\Http\Controllers\LanguageController` — registered by the GlobalMaster module provider under `global-master.language.*` (no `central.` prefix), renders `globalmaster::language.*`, uses `Modules\Prime\Models\Language` (wrong model for its own module). The GlobalMaster module is **disabled** in `modules_statuses.json`, so these routes 404 in the test env.
> The audit's **SEC-GLB-010** (ungated create/store/edit/update) and **SEC-GLB-005** (`global-master.*` gate-prefix mismatch) were filed against the **GlobalMaster** controller. The **live Prime** controller correctly gates every method with `prime.language.*`. Tests therefore assert the **live** (gated) behaviour and document the divergence. See "Known Source Defects".

---

## 1. Business Conditions

### BC-DB — Schema (Source: DDL `glb_languages` / migration `2025_11_10_061519_create_languages_table.php`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `glb_languages` exists (real table on `global_master_mysql`; VIEW on central `mysql`) | DDL-glb_languages |
| BC-DB-02 | `id` INT UNSIGNED AUTO_INCREMENT PK | DDL-glb_languages |
| BC-DB-03 | `code` VARCHAR(10) NOT NULL, UNIQUE (`uq_glb_languages_code`) | DDL-glb_languages |
| BC-DB-04 | `name` VARCHAR(50) NOT NULL — UNIQUE **in the migration** (`->unique()`), NOT in the consolidated DDL spec (drift) | Migration L21 / DDL-glb_languages |
| BC-DB-05 | `native_name` VARCHAR(50) NULLABLE | DDL-glb_languages |
| BC-DB-06 | `direction` ENUM('LTR','RTL') DEFAULT 'LTR' | DDL-glb_languages |
| BC-DB-07 | `is_active` TINYINT(1) DEFAULT 1 | DDL-glb_languages |
| BC-DB-08 | `deleted_at`, `created_at`, `updated_at` present **in the migration** (`softDeletes()`+`timestamps()`) but **absent from the consolidated DDL spec** → DDL is stale; running DB has them, so SoftDeletes works | Migration L25-26 vs DDL-glb_languages |
| BC-DB-09 | `glb_translations.language_id` FK → `glb_languages(id)` ON DELETE CASCADE | DDL-glb_translations |

### BC-VAL — Validation (Source: `Modules\GlobalMaster\Http\Requests\LanguageRequest`)

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | `code` required | `required` | Req-rules |
| BC-VAL-02 | `code` string, max 10 | `string|max:10` | Req-rules |
| BC-VAL-03 | `code` unique in `glb_languages.code`, ignore self on update | `Rule::unique(...)->ignore($id)` | Req-rules |
| BC-VAL-04 | `name` required | `required` | Req-rules |
| BC-VAL-05 | `name` string, max 50 | `string|max:50` | Req-rules |
| BC-VAL-06 | `name` unique in `glb_languages.name`, ignore self on update | `Rule::unique(...)->ignore($id)` | Req-rules |
| BC-VAL-07 | `native_name` nullable, string, max 50 | `nullable|string|max:50` | Req-rules |
| BC-VAL-08 | `direction` required, in LTR/RTL (case-sensitive; matches DDL ENUM exactly) | `required|Rule::in(['LTR','RTL'])` | Req-rules |
| BC-VAL-09 | `is_active` required boolean; `prepareForValidation()` coerces checkbox `'on'`→true else false (so it is never truly "missing") | `required|boolean` + prepareForValidation | Req-rules |
| BC-VAL-10 | No `messages()` override → default Laravel validation messages | Req |
| BC-VAL-11 | `authorize()` returns bare `true` (no FormRequest-level authorization → D30, no defense-in-depth) | Req-authorize | Audit-D30 |

### BC-AUTH — Authorization (Source: live `Modules\Prime\Http\Controllers\LanguageController` + `Modules\GlobalMaster\Policies\LanguagePolicy`)

| ID | Controller method | Gate (LIVE Prime controller) | Source |
|----|-------------------|------------------------------|--------|
| BC-AUTH-01 | `index` | `prime.language.viewAny` | Ctrl L19 |
| BC-AUTH-02 | `create` / `store` | `prime.language.create` | Ctrl L30,40 |
| BC-AUTH-03 | `show` | `prime.language.view` | Ctrl L51 |
| BC-AUTH-04 | `edit` / `update` | `prime.language.update` (update authorizes twice — harmless duplicate) | Ctrl L61,72,74 |
| BC-AUTH-05 | `destroy` | `prime.language.delete` | Ctrl L84 |
| BC-AUTH-06 | `trashedlanguage` / `restore` | `prime.language.restore` | Ctrl L102,110 |
| BC-AUTH-07 | `forceDelete` | `prime.language.forceDelete` | Ctrl L125 |
| BC-AUTH-08 | `toggleStatus` | `prime.language.update` | Ctrl L144 |
| BC-AUTH-09 | Guest (unauthenticated) → redirected to `/login` (route group `['auth','verified']`) | Route middleware | Web-group |

### BC-BIZ — Business logic / activity log (Source: live Prime controller + `activityLog()` helper + `config/flash.php`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `store` creates via `Language::create($request->validated())`, redirects to `central.global-master.language.index` with `flash('created.language')` → "Language was created successfully." | Ctrl L42-43 |
| BC-BIZ-02 | `store` does **NOT** write an activity-log entry | Ctrl store |
| BC-BIZ-03 | `update` sets fields, redirects to index with **raw literal `'update.language'`** (BUG-GLB-006 — `flash()` not called; user sees the untranslated key) | Ctrl L76 |
| BC-BIZ-04 | `update` does **NOT** write an activity-log entry | Ctrl update |
| BC-BIZ-05 | `destroy` sets `is_active=false`, saves, soft-deletes, logs event **`'Trashed'`**, redirects to index with `flash('trashed.language')` → "Language was moved to trash." | Ctrl L84-96 |
| BC-BIZ-06 | `restore` restores from trash, logs event **`'Restored'`**, redirects to `.trashed` with `flash('restored.language')` | Ctrl L108-120 |
| BC-BIZ-07 | `forceDelete` permanently deletes, logs event **`'Stored'`** (BUG-GLB-006 — mislabeled; should be `'Deleted'`), redirects to `.trashed` with `flash('force_deleted.language')` | Ctrl L123-135 |
| BC-BIZ-08 | `toggleStatus` validates `is_active|required|boolean`, sets status, logs event **`'Toggled'`**, returns JSON `{success,is_active,message: flash('status_updated.language')}` | Ctrl L142-172 |
| BC-BIZ-09 | Central activity log routes to `Modules\Prime\Models\ActivityLog` (connection `mysql`, table `sys_central_activity_logs`) because tenancy is not initialized; `user_id = Auth::id()`, `properties` cast array | Helper L35-39, Model |
| BC-BIZ-10 | Index paginates 11/page; trash paginates 10/page; empty index shows "Not Data Found" | Ctrl L21,104 / Blade |

### BC-REF — Referential integrity (Source: DDL)

| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `glb_translations.language_id` → `glb_languages(id)` ON DELETE CASCADE (force-deleting a language removes dependent translations) | DDL-glb_translations |

### BC-SM — Status / soft-delete lifecycle (Source: controller lifecycle)

| ID | State | Trigger | Next state | Source |
|----|-------|---------|-----------|--------|
| BC-SM-01 | Active | `toggleStatus(is_active=0)` | Inactive | Ctrl toggleStatus |
| BC-SM-02 | Inactive | `toggleStatus(is_active=1)` | Active | Ctrl toggleStatus |
| BC-SM-03 | Active/Inactive | `destroy` | Trashed (soft-deleted, is_active=0) | Ctrl destroy |
| BC-SM-04 | Trashed | `restore` | Active-again (restored) | Ctrl restore |
| BC-SM-05 | Trashed | `forceDelete` | Removed (hard-deleted) | Ctrl forceDelete |

### BC-EDG — Edge cases

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `code` exactly 10 chars accepted; 11 rejected | BC-VAL-02 |
| BC-EDG-02 | `name` exactly 50 chars accepted; 51 rejected | BC-VAL-05 |
| BC-EDG-03 | No `trim` rule → leading/trailing whitespace stored verbatim | Req-rules |
| BC-EDG-04 | Invalid/nonexistent id on `edit`/`destroy`/`restore`/`forceDelete` → `findOrFail` 404 | Ctrl findOrFail |
| BC-EDG-05 | Model default `direction` falls back to DB default `'LTR'` when omitted at the model layer | DDL default |

### BC-CFG — Configuration

| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | Flash templates from `config/flash.php`: `created`/`updated`/`trashed`/`restored`/`force_deleted`/`status_updated` with `:resource`→"Language" | config/flash.php |

---

## 2. Test Case List

### Positive (TC-P)

| TC ID | Category | BC | Source | Description | Expected Result | V1 | V2 | Status |
|-------|----------|----|--------|-------------|-----------------|----|----|--------|
| TC-P01 | Schema | BC-DB-01..08 | DDL/Migration | Schema/model/request configuration correct | Table, columns, SoftDeletes, fillable, rules all present | 01 | 01,03,04 | ✅ |
| TC-P02 | Render | BC-AUTH-01 | Ctrl | Index renders for admin | 200, "Language Management", table | 02 | 60,65 | ✅ |
| TC-P03 | Render | BC-AUTH-02 | Ctrl | Create page renders | Form with name/code/native_name/direction/is_active | 03 | 66 | ✅ |
| TC-P04 | Create | BC-BIZ-01 | Ctrl | Store creates language | Row persisted, redirect to index, "created" flash | 04 | 10,11 | ✅ |
| TC-P05 | Render | BC-AUTH-04 | Ctrl | Edit page renders prefilled | Fields populated with current values | 05 | — | ✅ |
| TC-P06 | Update | BC-BIZ-03 | Ctrl | Update persists changes | Row updated in DB | 06 | 12 | ✅ |
| TC-P07 | Delete | BC-BIZ-05,SM-03 | Ctrl | Destroy soft-deletes + logs Trashed | deleted_at set, is_active=0, event 'Trashed' | 08 | 14,15,22 | ✅ |
| TC-P08 | Trash list | BC-BIZ-10 | Ctrl | Trashed page lists soft-deleted | Row visible in trash view | 09 | — | ✅ |
| TC-P09 | Restore | BC-BIZ-06,SM-04 | Ctrl | Restore recovers + logs Restored | deleted_at null, event 'Restored' | 10 | 16,23 | ✅ |
| TC-P10 | Force delete | BC-BIZ-07,SM-05 | Ctrl | Force delete removes + logs Stored | Row gone, event 'Stored' | 11 | 17,24 | ✅ |
| TC-P11 | Toggle | BC-BIZ-08,SM-01/02 | Ctrl | Toggle status endpoint | JSON success, is_active flipped, event 'Toggled' | 12 | 18,20,21 | ✅ |
| TC-P12 | Activity | BC-BIZ-09 | Helper | Central activity log row written with user_id | Row in sys_central_activity_logs | 18 | 15,16,17,18 | ✅ |
| TC-P13 | UI | BC-BIZ-10 | Blade | Search filters by name | Matching row shown | — | 62 | ✅ |
| TC-P14 | UI | BC-BIZ-10 | Ctrl | Pagination present when > 11 | Pagination links render | — | 64 | ✅ |
| TC-P15 | Lifecycle | BC-SM-01..05 | Ctrl | Full lifecycle | create→toggle→delete→restore→forceDelete all succeed | — | 25 | ✅ |
| TC-P16 | Routes | — | Web | Central routes registered | `central.global-master.language.*` resolve | — | 02 | ✅ |

### Negative (TC-N)

| TC ID | Category | BC | Source | Description | Expected Result | V1 | V2 | Status |
|-------|----------|----|--------|-------------|-----------------|----|----|--------|
| TC-N01 | Validation | BC-VAL-01 | Req | code required | Validation error on code | 13 | 30 | ✅ |
| TC-N02 | Validation | BC-VAL-04 | Req | name required | Validation error on name | 14 | 31 | ✅ |
| TC-N03 | Validation | BC-VAL-08 | Req | direction required | Validation error on direction | 16 | 32 | ✅ |
| TC-N04 | Validation | BC-VAL-02 | Req | code max 10 enforced | 11 chars rejected | — | 33 | ✅ |
| TC-N05 | Validation | BC-VAL-05 | Req | name max 50 enforced | 51 chars rejected | — | 34 | ✅ |
| TC-N06 | Validation | BC-VAL-07 | Req | native_name max 50 enforced | 51 chars rejected | — | 35 | ✅ |
| TC-N07 | Validation | BC-VAL-07 | Req | native_name nullable accepts empty | Empty native_name accepted | — | 36 | ✅ |
| TC-N08 | Validation | BC-VAL-03 | Req | duplicate code rejected | Unique error on code | 15 | 37 | ✅ |
| TC-N09 | Validation | BC-VAL-06 | Req | duplicate name rejected | Unique error on name | — | 38 | ✅ |
| TC-N10 | Validation | BC-VAL-08 | Req | invalid direction value rejected | Rejected (not LTR/RTL) | — | 39 | ✅ |
| TC-N11 | Validation | BC-VAL-03 | Req | code unique ignores self on update | Same code on own record accepted | — | 39b | ✅ |
| TC-N12 | Edge/404 | BC-EDG-04 | Ctrl | invalid id on edit → 404 | 404 Not Found | — | 73 | ✅ |
| TC-N13 | Edge/404 | BC-EDG-04 | Ctrl | invalid id on destroy → 404 | 404 Not Found | — | 74 | ✅ |
| TC-N14 | Edge/404 | BC-EDG-04 | Ctrl | restore nonexistent → 404 | 404 Not Found | — | 75 | ✅ |
| TC-N15 | AuthZ | BC-AUTH-09 | Web | Guest redirected to /login | Redirect to login | 17 | 50,94 | ✅ |
| TC-S01 | Security | BC-AUTH-01 | Ctrl | index requires viewAny (limited user 403) | 403 | — | 51 | ✅ |
| TC-S02 | Security | BC-AUTH-02 | Ctrl | create/store require create gate (limited 403) — SEC-GLB-010 reconciled | 403 | — | 52,53 | ✅ |
| TC-S03 | Security | BC-AUTH-04 | Ctrl | edit/update require update gate (limited 403) | 403 | — | 54 | ✅ |
| TC-S04 | Security | BC-AUTH-05 | Ctrl | destroy requires delete gate (limited 403) — SEC-GLB-005 reconciled | 403 | — | 55 | ✅ |
| TC-S05 | Security | BC-AUTH-06/07 | Ctrl | restore/forceDelete require gates (limited 403) | 403 | — | 56 | ✅ |
| TC-S06 | Security | BC-AUTH-08 | Ctrl | toggleStatus requires update gate (limited 403) | 403 | — | 57 | ✅ |
| TC-S07 | Security | BC-VAL-11 | Req | FormRequest authorize=true (D30, no defense-in-depth) | authorize() returns true | — | 58 | ✅ |
| TC-S08 | Security | BC-EDG-03 | Blade | XSS in name escaped on render | `<script>` not executed | — | 90,92 | ✅ |
| TC-S09 | Security | BC-EDG-03 | Blade | XSS in native_name escaped on render | `<script>` not executed | — | 91 | ✅ |
| TC-S10 | Security | BC-EDG-04 | Ctrl | IDOR cross-id access → 404 | 404 | — | 93 | ✅ |
| TC-S11 | Security | model fillable | Model | Mass-assignment only fillable fields | Extra field ignored | — | 95 | ✅ |

### Dependency (TC-D)

| TC ID | Sub | BC | Source | Description | Expected Result | V1 | V2 | Status |
|-------|-----|----|--------|-------------|-----------------|----|----|--------|
| TC-D01 | B | BC-SM-03..05 | Ctrl | Soft-delete preserves row; force-delete removes | Trashed row recoverable; forced row gone | 08/11 | 22,23,24 | ✅ |
| TC-D02 | F | BC-SM-01..05 | Ctrl | Full lifecycle multi-step | All steps pass | — | 25 | ✅ |
| TC-D03 | E | BC-REF-01 | DDL | glb_translations FK CASCADE (defensive) | Force-delete cascades translations (skip if table absent) | — | 40,41,42 | ✅ |
| TC-D04 | G | BC-VAL-03/06 | Req | Concurrent duplicate code/name uniqueness | Second insert rejected | — | 37,38 | ✅ |

### State-machine transition cases (BC-SM)

| TC ID | Transition | V2 | Status |
|-------|-----------|----|--------|
| TC-SM-01 | Active → Inactive (toggle) | 20 | ✅ |
| TC-SM-02 | Inactive → Active (toggle) | 21 | ✅ |
| TC-SM-03 | Active → Trashed (destroy) | 22 | ✅ |
| TC-SM-04 | Trashed → Active (restore) | 23 | ✅ |
| TC-SM-05 | Trashed → Removed (forceDelete) | 24 | ✅ |

---

## 3. Known Source Defects (audit-equivalent, with proving tests)

| ID | Sev | Description | Live-repro on central route? | Proving test (V2) | Notes |
|----|-----|-------------|------------------------------|-------------------|-------|
| **BUG-GLB-006a** | P1 | `forceDelete()` logs activity event `'Stored'` (mislabeled — should be `'Deleted'`/`'ForceDelete'`); corrupts audit trail (BR-GLB-031) | **YES** (Prime ctrl L132) | `test_language_17_force_delete_logs_stored_event_bug` | Asserts current literal `'Stored'` |
| **BUG-GLB-006b** | P1 | `update()` flash is raw literal `'update.language'` (`flash()` not called) → user sees untranslated key | **YES** (Prime ctrl L76) | `test_language_13_update_flash_is_literal_update_language_bug` | Asserts page shows `update.language` |
| **BUG-GLB-006c** | P1 | GlobalMaster ctrl imports `Modules\Prime\Models\Language` (wrong model for its own module) | **NO** — GlobalMaster ctrl only (dead route); live Prime ctrl correctly uses `Modules\Prime\Models\Language` | Documented (verify-in-source) | Live central controller is correct |
| **SEC-GLB-010** | P0 | Audit: `create/store/edit/update` ungated in **GlobalMaster** ctrl | **NO** — live Prime ctrl gates all with `prime.language.*` | `test_language_52/53/54_*` assert live 403 for limited user | Reconciled: repro only on the disabled GlobalMaster module route |
| **SEC-GLB-005** | P1 | `global-master.*` gate-prefix mismatch on destroy/restore/forceDelete/toggleStatus in **GlobalMaster** ctrl → permission likely nonexistent → 403 | **NO** — live Prime ctrl uses correct `prime.language.*` | `test_language_55/56/57_*` assert live 403 for limited user | Reconciled: mismatch only in GlobalMaster ctrl |
| **D30 / SEC** | P2 | `LanguageRequest::authorize()` returns bare `true` (no defense-in-depth) | YES (shared request class) | `test_language_58_request_authorize_returns_true_no_defense_in_depth` | Systemic across all 10 GLB FormRequests |
| **DUP-WEB-001** | P2 | `central.global-master.language.*` registered twice in root `web.php` (blocks at L426 & L571) + module `global-master.language.*` → route-name collision | YES | Cross-ref finding (Gap Analysis) | Later block silently wins |
| **DATA/MIG drift** | P2 | Consolidated DDL `_global_db_v4.sql` omits `deleted_at`/`created_at`/`updated_at`/`name` UNIQUE that the migration adds → DDL spec stale | N/A (spec doc) | `test_language_01/03` assert migration truth | Running DB is correct; update the DDL spec |
| **MODEL drift** | P3 | Two `Language` models: `Prime\Models\Language` (no `$casts`) vs `GlobalMaster\Models\Language` (`is_active`→boolean cast). Prime model returns `is_active` as raw `"0"/"1"` | YES (live model) | `test_language_03` documents | Blade truthiness hazard |

---

## 4. V2 Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 01 | test_language_01_schema_model_and_request_configuration_are_correct | TC-P01 | Schema | 01-09 |
| 02 | test_language_02_central_routes_are_registered | TC-P16 | Schema/Routes | 01-09 |
| 03 | test_language_03_model_soft_deletes_connection_and_casts_drift | TC-P01,MODEL drift | Schema | 01-09 |
| 04 | test_language_04_request_rules_contain_expected_constraints | TC-P01 | Schema | 01-09 |
| 05 | test_language_05_migration_adds_softdeletes_and_timestamps | BC-DB-08 | Schema | 01-09 |
| 10 | test_language_10_store_persists_all_fields | TC-P04 | BizRule | 10-19 |
| 11 | test_language_11_store_redirects_index_with_created_flash | TC-P04 | BizRule | 10-19 |
| 12 | test_language_12_update_persists_changes | TC-P06 | BizRule | 10-19 |
| 13 | test_language_13_update_flash_is_literal_update_language_bug | BUG-GLB-006b | BizRule | 10-19 |
| 14 | test_language_14_destroy_sets_inactive_then_soft_deletes | TC-P07 | BizRule | 10-19 |
| 15 | test_language_15_destroy_logs_trashed_event | TC-P07,P12 | BizRule | 10-19 |
| 16 | test_language_16_restore_logs_restored_event | TC-P09,P12 | BizRule | 10-19 |
| 17 | test_language_17_force_delete_logs_stored_event_bug | BUG-GLB-006a,TC-P10 | BizRule | 10-19 |
| 18 | test_language_18_toggle_status_logs_toggled_event | TC-P11,P12 | BizRule | 10-19 |
| 19 | test_language_19_store_and_update_do_not_log_activity | BC-BIZ-02/04 | BizRule | 10-19 |
| 20 | test_language_20_active_to_inactive_via_toggle | TC-SM-01 | StateMachine | 20-29 |
| 21 | test_language_21_inactive_to_active_via_toggle | TC-SM-02 | StateMachine | 20-29 |
| 22 | test_language_22_active_to_trashed_via_destroy | TC-SM-03 | StateMachine | 20-29 |
| 23 | test_language_23_trashed_to_active_via_restore | TC-SM-04 | StateMachine | 20-29 |
| 24 | test_language_24_trashed_to_removed_via_force_delete | TC-SM-05 | StateMachine | 20-29 |
| 25 | test_language_25_full_lifecycle_create_toggle_delete_restore_forcedelete | TC-P15,D02 | StateMachine | 20-29 |
| 30 | test_language_30_code_is_required | TC-N01 | Validation | 30-39 |
| 31 | test_language_31_name_is_required | TC-N02 | Validation | 30-39 |
| 32 | test_language_32_direction_is_required | TC-N03 | Validation | 30-39 |
| 33 | test_language_33_code_max_10_enforced | TC-N04 | Validation | 30-39 |
| 34 | test_language_34_name_max_50_enforced | TC-N05 | Validation | 30-39 |
| 35 | test_language_35_native_name_max_50_enforced | TC-N06 | Validation | 30-39 |
| 36 | test_language_36_native_name_nullable_accepts_empty | TC-N07 | Validation | 30-39 |
| 37 | test_language_37_duplicate_code_rejected | TC-N08,D04 | Validation | 30-39 |
| 38 | test_language_38_duplicate_name_rejected | TC-N09,D04 | Validation | 30-39 |
| 39 | test_language_39_invalid_direction_value_rejected | TC-N10 | Validation | 30-39 |
| 39b | test_language_39b_code_unique_ignores_self_on_update | TC-N11 | Validation | 30-39 |
| 40 | test_language_40_translations_fk_exists_defensive | TC-D03 | Integration | 40-49 |
| 41 | test_language_41_force_delete_cascades_translations_defensive | TC-D03 | Integration | 40-49 |
| 42 | test_language_42_soft_delete_keeps_translations_defensive | TC-D03 | Integration | 40-49 |
| 50 | test_language_50_guest_redirected_to_login_on_index | TC-N15 | AuthZ | 50-59 |
| 51 | test_language_51_index_requires_viewany_gate | TC-S01 | AuthZ | 50-59 |
| 52 | test_language_52_create_requires_create_gate | TC-S02,SEC-GLB-010 | AuthZ | 50-59 |
| 53 | test_language_53_store_requires_create_gate | TC-S02,SEC-GLB-010 | AuthZ | 50-59 |
| 54 | test_language_54_edit_update_requires_update_gate | TC-S03,SEC-GLB-010 | AuthZ | 50-59 |
| 55 | test_language_55_destroy_requires_delete_gate | TC-S04,SEC-GLB-005 | AuthZ | 50-59 |
| 56 | test_language_56_restore_forcedelete_require_gates | TC-S05,SEC-GLB-005 | AuthZ | 50-59 |
| 57 | test_language_57_toggle_status_requires_update_gate | TC-S06,SEC-GLB-005 | AuthZ | 50-59 |
| 58 | test_language_58_request_authorize_returns_true_no_defense_in_depth | TC-S07,D30 | AuthZ | 50-59 |
| 60 | test_language_60_index_lists_seeded_language | TC-P02 | UI/UX | 60-69 |
| 61 | test_language_61_search_miss_shows_no_data | BC-BIZ-10 | UI/UX | 60-69 |
| 62 | test_language_62_search_filters_by_name | TC-P13 | UI/UX | 60-69 |
| 63 | test_language_63_status_filter_control_present | BC-BIZ-10 | UI/UX | 60-69 |
| 64 | test_language_64_pagination_present_when_over_11 | TC-P14 | UI/UX | 60-69 |
| 65 | test_language_65_breadcrumb_language_management | TC-P02 | UI/UX | 60-69 |
| 66 | test_language_66_create_form_has_direction_options | TC-P03 | UI/UX | 60-69 |
| 70 | test_language_70_code_whitespace_stored_verbatim | BC-EDG-03 | Edge | 70-79 |
| 71 | test_language_71_boundary_code_exactly_10_accepted | BC-EDG-01 | Edge | 70-79 |
| 72 | test_language_72_boundary_name_exactly_50_accepted | BC-EDG-02 | Edge | 70-79 |
| 73 | test_language_73_invalid_id_returns_404_on_edit | TC-N12 | Edge | 70-79 |
| 74 | test_language_74_invalid_id_returns_404_on_destroy | TC-N13 | Edge | 70-79 |
| 75 | test_language_75_restore_nonexistent_returns_404 | TC-N14 | Edge | 70-79 |
| 76 | test_language_76_direction_defaults_ltr_at_db_layer | BC-EDG-05 | Edge | 70-79 |
| 90 | test_language_90_xss_in_name_is_escaped_on_render | TC-S08 | Security | 90-99 |
| 91 | test_language_91_xss_in_native_name_is_escaped_on_render | TC-S09 | Security | 90-99 |
| 92 | test_language_92_stored_xss_payload_persisted_literally | TC-S08 | Security | 90-99 |
| 93 | test_language_93_idor_cross_id_access_returns_404 | TC-S10 | Security | 90-99 |
| 94 | test_language_94_guest_cannot_store | TC-N15 | Security | 90-99 |
| 95 | test_language_95_mass_assignment_only_fillable_fields | TC-S11 | Security | 90-99 |
| 96 | test_language_96_cross_tenant_isolation_not_applicable_central | (deliberate skip) | Tenancy | 90-99 |

**V1 methods:** 18 · **V2 methods:** 65 · **Ratio:** 3.6× (gate ≥ 2× satisfied).

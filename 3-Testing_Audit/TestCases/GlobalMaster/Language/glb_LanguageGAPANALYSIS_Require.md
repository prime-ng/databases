# GlobalMaster :: Language — Gap Analysis (`glb_`)

- Module: **GlobalMaster** (CENTRAL / prime-side)
- Screen: **Language**  |  Table: `glb_languages`  |  Live path: `/global-master/language`
- Test file: `glb_Language_TestCas.php` — **40 automated methods**
- Live controller: `Modules\Prime\Http\Controllers\LanguageController` (HARD RULE 13)

---

## 1. Category → Test mapping

| Category | Bands | Methods | TCs |
| --- | --- | --- | --- |
| Schema / Model / Request truth | 01–09 | 9 | TC-01…TC-09 |
| Business flow + activity truth | 10–19 | 10 | TC-10…TC-19 |
| Validation / negative | 30–39 | 10 | TC-30…TC-39 |
| Lifecycle (soft-delete/restore/force) | 40–49 | 2 | TC-40, TC-41 |
| Permissions / access | 50–59 | 3 | TC-50, TC-51, TC-52 |
| UI (pagination/trash) | 60–69 | 2 | TC-60, TC-61 |
| Security (XSS/IDOR/mass-assign) | 90–99 | 4 | TC-90…TC-93 |
| **Total** | | **40** | |

---

## 2. Coverage Summary

| Surface | Covered? | Evidence |
| --- | --- | --- |
| `index` (list, paginate 11) | ✅ | TC-10, TC-60 |
| `create` + `store` | ✅ | TC-11, TC-12, TC-19 |
| `edit` + `update` | ✅ | TC-13 |
| `destroy` (soft delete) | ✅ | TC-15, TC-40 |
| `trashedlanguage` (trash list) | ✅ | TC-61, TC-40 |
| `restore` | ✅ | TC-16, TC-41, TC-40 |
| `forceDelete` | ✅ | TC-17, TC-40 |
| `toggleStatus` | ✅ | TC-14, TC-18 |
| All 5 validation rules | ✅ | TC-30…TC-38 |
| Soft-delete column (`deleted_at`) | ✅ | TC-02 |
| Timestamps columns | ✅ | TC-03 |
| Activity events (Trashed/Restored/Stored/Toggled) | ✅ | TC-15/16/17/18 |
| Gate prefix on live route | ✅ (documented) | TC-52 |
| Guest / auth gating | ✅ | TC-50, TC-51 |
| XSS escaping | ✅ | TC-90, TC-91 |
| IDOR / invalid id | ✅ | TC-39, TC-92 |
| Mass-assignment guard | ✅ | TC-93 |
| **Dead duplicate controller behaviour** | ⚠️ documented only | DEV-GLB-L03/L04 — not runtime-reachable on central |

---

## 3. Eleven-check Cross-Reference Findings

| # | Check | Result | Detail |
| --- | --- | --- | --- |
| 1 | Table name prefix matches DDL | ✅ | `glb_languages` (DDL + migration + model agree) |
| 2 | Model connection correct | ✅ | `global_master_mysql` (TC-07) |
| 3 | Fillable matches request fields | ✅ | code, name, native_name, direction, is_active (TC-08) |
| 4 | Migration vs DDL parity | ❌ | **DEV-GLB-L01** — DDL omits `created_at/updated_at/deleted_at`; migration adds `softDeletes()+timestamps()` |
| 5 | Live route → controller binding | ✅ | root `routes/web.php` binds **Prime** `LanguageController` to `central.global-master.language.*` |
| 6 | Gates match policy abilities | ✅ (live) / ❌ (dead) | Live controller uses `prime.language.*`; **DEV-GLB-L03** dead controller mixes `global-master.language.*` |
| 7 | Activity events correct string | ❌ | **DEV-GLB-L02** — `forceDelete` logs `Stored` not a delete event (TC-17) |
| 8 | Activity sink correct | ✅ | `sys_central_activity_logs` via Prime `ActivityLog` (connection `mysql`) |
| 9 | Validation rules enforced | ✅ | required/max/unique/in all exercised (TC-30…TC-38) |
| 10 | Controller duplication | ❌ | **DEV-GLB-L04** — two `LanguageController` classes share one request + model |
| 11 | Success-flash correctness | ⚠️ | `update()` flashes literal `'update.language'` (not `flash('updated.language')`) in BOTH controllers |

---

## 4. Source-tagged Coverage-Score table

Legend — **Source**: `Migration`, `Model`, `Request`, `Controller`, `View`, `Middleware`, `Policy`, `ActivityLog`, `DDL`.

| TC | Method | Category | Source | Score |
| --- | --- | --- | --- | --- |
| TC-01 | table_exists | Schema | Migration/DDL | 1.0 |
| TC-02 | soft_deletes_column_exists | Schema | Migration | 1.0 |
| TC-03 | timestamps_columns_exist | Schema | Migration | 1.0 |
| TC-04 | expected_columns_exist | Schema | Migration/DDL | 1.0 |
| TC-05 | code_column_is_varchar | Schema | DDL/Migration | 1.0 |
| TC-06 | direction_column_is_enum | Schema | Migration | 1.0 |
| TC-07 | model_connection_and_table | Model | Model | 1.0 |
| TC-08 | model_fillable_matches | Model | Model | 1.0 |
| TC-09 | model_uses_soft_deletes | Model | Model | 1.0 |
| TC-10 | index_loads | Business | Controller/View | 1.0 |
| TC-11 | create_page_loads | Business | View | 1.0 |
| TC-12 | create_flow_persists | Business | Controller | 1.0 |
| TC-13 | update_flow_persists | Business | Controller | 1.0 |
| TC-14 | status_toggle_updates_is_active | Business | Controller | 1.0 |
| TC-15 | soft_delete_logs_trashed_event | Business | Controller/ActivityLog | 1.0 |
| TC-16 | restore_logs_restored_event | Business | Controller/ActivityLog | 1.0 |
| TC-17 | force_delete_logs_stored_event_bug | Business | Controller/ActivityLog | 1.0 (DEV-GLB-L02) |
| TC-18 | toggle_logs_toggled_event | Business | Controller/ActivityLog | 1.0 |
| TC-19 | store_logs_nothing | Business | Controller | 1.0 |
| TC-30 | create_requires_code | Validation | Request | 1.0 |
| TC-31 | create_requires_name | Validation | Request | 1.0 |
| TC-32 | create_requires_direction | Validation | Request | 1.0 |
| TC-33 | code_max_10_rejected | Validation | Request | 1.0 |
| TC-34 | name_max_50_rejected | Validation | Request | 1.0 |
| TC-35 | duplicate_code_rejected | Validation | Request | 1.0 |
| TC-36 | duplicate_name_rejected | Validation | Request | 1.0 |
| TC-37 | direction_not_in_enum_rejected | Validation | Request | 1.0 |
| TC-38 | native_name_nullable_persists_blank | Validation | Request | 1.0 |
| TC-39 | invalid_id_edit_returns_404 | Validation | Controller | 1.0 |
| TC-40 | full_lifecycle_delete_restore_force | Lifecycle | Controller | 1.0 |
| TC-41 | restore_recovers_record | Lifecycle | Controller | 1.0 |
| TC-50 | guest_redirected_to_login | Permissions | Middleware | 1.0 |
| TC-51 | index_requires_authentication_http | Permissions | Middleware | 1.0 |
| TC-52 | gate_prefix_is_prime_language_on_live_route | Permissions | Controller/Policy | 0.8 (documentary) |
| TC-60 | pagination_eleven_per_page | UI | Controller/View | 1.0 |
| TC-61 | trash_page_loads | UI | Controller/View | 1.0 |
| TC-90 | xss_on_name_is_escaped | Security | View | 1.0 |
| TC-91 | xss_on_native_name_is_escaped | Security | View | 1.0 |
| TC-92 | idor_show_missing_returns_not_found | Security | Controller | 1.0 |
| TC-93 | mass_assignment_guarded | Security | Model | 1.0 |

**Aggregate coverage score:** 39.8 / 40 ⇒ **≈ 99.5%** of enumerated behaviours have an automated or documentary assertion.

---

## 5. Gaps & remaining risks

| Gap | Reason | Mitigation |
| --- | --- | --- |
| Dead-duplicate controller (`Modules\GlobalMaster\...\LanguageController`) not runtime-tested | It is not registered on any live central route (DEV-GLB-L04) | Documented in TC-52 + defects; would need a route to exercise |
| Per-ability 403 denial not fully automated | Test runner authenticates as super-admin (all gates pass) | Gate names asserted (TC-52); manual MT-15 covers 403 |
| `update()` literal-flash defect | Cosmetic, non-blocking | Documented (cross-ref #11) |
| Client `required` vs server `nullable` on `native_name` | Minor UI/server divergence | TC-38 exercises the server rule |

---

## 6. GLB defect register

| ID | Type | Proven by | Status |
| --- | --- | --- | --- |
| DEV-GLB-L01 | DDL vs migration divergence (docs) | TC-02, TC-03 | Confirmed in source |
| DEV-GLB-L02 | Wrong activity event string (`Stored`) | TC-17 | Confirmed in source (both controllers) |
| DEV-GLB-L03 | Mixed gate prefixes + literal flash in dead controller | TC-52 (documented) | Confirmed in source (dead controller) |
| DEV-GLB-L04 | Duplicate `LanguageController` classes | Documented | Confirmed in source |

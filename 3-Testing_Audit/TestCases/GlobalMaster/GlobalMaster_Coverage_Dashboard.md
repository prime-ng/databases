# GlobalMaster — Coverage Dashboard (report mode)

**Module:** GlobalMaster (GLB) · **DB scope:** CENTRAL / prime-side · **Test style:** browser Dusk on `http://127.0.0.1:8000` (mirrors committed Prime/Billing central pattern) · **Generated:** 2026-Jul-10
**Run:** module mode → 5 features × 7 artifacts = 35 files + Feature Inventory + this dashboard + RTM.

## Per-feature summary

| Feature | Test file | Prefix (DDL-verified) | Screen type | Methods | php -l | Category coverage (Neg / Pos / Dep) | Live controller (RULE 13) | Open GLB defects |
|---------|-----------|-----------------------|-------------|--------:|:------:|-------------------------------------|---------------------------|------------------|
| Country | `glb_Country_TestCas.php` | `glb_` (`glb_countries`) | CRUD + toggle-cascade | 46 | ✅ clean | 100% / 94% / 100% | GlobalMaster (own) | DEV-GLB-C01, C02, C03 |
| Language | `glb_Language_TestCas.php` | `glb_` (`glb_languages`) | CRUD + soft-delete | 40 | ✅ clean | 100% / ≥90% / ≥90% | Prime (GLB own = dead dup) | DEV-GLB-L01, L02, L03, L04 |
| Dropdown | `sys_Dropdown_TestCas.php` | **`sys_`** (`sys_dropdown_table`) ⚠ | Tabbed CRUD + junction | 40 | ✅ clean | 100% / ≥90% / ≥90% (guarded) | Prime (GLB own = dead) | DEV-GLB-D01, D02, D03, D04 |
| SessionBoardSetup | `glb_SessionBoardSetup_TestCas.php` | `glb_` (`glb_academic_sessions` + `glb_boards`) | Read-only composite | 26 | ✅ clean | Read-focused (no CUD) | Prime (`/prime/session-board-setup`) | DEV-GLB-S01, S02, S03 |
| ActivityLog | `sys_ActivityLog_TestCas.php` | **`sys_`** (`sys_central_activity_logs`) ⚠ no DDL | Read-only audit viewer | 23 | ✅ clean | Read-focused (no CUD) | Prime | DEV-GLB-A01, A02, A03(x-ref) |
| **TOTAL** | 5 suites (1 each) | — | 3 CRUD + 2 read-only | **175** | 5/5 clean | Neg 100% on P0/P1 | — | 17 (16 owned + 1 x-ref) |

⚠ **Prefix flags:** Dropdown and ActivityLog resolve to **`sys_`**, not the module registry's `glb_`, because their primary tables live in the central/prime DB (`sys_dropdown_table`, `sys_central_activity_logs`) — verified against `_prime_db_v4.sql` / the Prime model. `sys_central_activity_logs` has **no consolidated DDL** (schema from a central migration only).

## Validation verdicts
| Feature | Verdict | Notes |
|---------|---------|-------|
| Country | PASS WITH NOTES | env prereq (enable GlobalMaster+Prime); short_name uniqueness gap proven |
| Language | PASS WITH NOTES | Prime serves central; forceDelete wrong-event bug proven |
| Dropdown | PASS WITH NOTES | complex screen; soft-delete guarded by `deleted_at` presence; orphaned model proven |
| SessionBoardSetup | PASS WITH NOTES | read-only; write methods are stubs; `is_active` column mismatch found |
| ActivityLog | PASS WITH NOTES | read-only; no-DDL gap; schema asserted via model + Schema::hasTable guard |

## Defect register (GLB-owned, discovered this run)
| ID | Feature | Severity | Description | Proving test |
|----|---------|----------|-------------|--------------|
| DEV-GLB-C01 | Country | High | `short_name`/`global_code` DB-UNIQUE but not validated → raw QueryException 500 | `test_country_36_duplicate_short_name_raises_db_error` |
| DEV-GLB-C02 | Country | Minor | `default_timezone` validated but no column / not fillable (dead rule) | `test_country_43_default_timezone_is_a_dead_rule` |
| DEV-GLB-C03 | Country | Medium | toggleStatus cascades to states/districts but logs `Toggled` for country only | `test_country_16_toggle_status_cascades_to_children` |
| DEV-GLB-L01 | Language | Low (doc) | `_global_db_v4.sql` glb_languages stale vs migration (omits timestamps/deleted_at) | `Schema::hasColumn` truth (TC-02/03) |
| DEV-GLB-L02 | Language | Medium | `forceDelete()` logs event `'Stored'` instead of a delete event | TC-17 (force-delete event assert) |
| DEV-GLB-L03 | Language | Medium | GlobalMaster's dead LanguageController uses mixed `prime.*`/`global-master.*` gates + literal `'update.language'` flash | reconciliation section |
| DEV-GLB-L04 | Language | Medium | Two `LanguageController` classes on one request+model (dup) | reconciliation section |
| DEV-GLB-D01 | Dropdown | Medium | Orphaned duplicate `Models/Dropdown.php` (FQCN collision, not PSR-4-loaded) | `_03` |
| DEV-GLB-D02 | Dropdown | High | GlobalMaster's own `store()` reads validated keys (org_id/key/type) its request never returns → undefined keys | `_06` |
| DEV-GLB-D03 | Dropdown | Medium | Request `value max:255` > DB `varchar(100)` (Prime live = max:100 divergence) | `_04`, `_34` |
| DEV-GLB-D04 | Dropdown | High | SoftDeletes on `sys_dropdown_table` whose DDL has no `deleted_at` | `_05`, `_43` (guarded) |
| DEV-GLB-S01 | SessionBoardSetup | Medium | resource write methods are non-functional stubs (read-only screen) | reconciliation section |
| DEV-GLB-S02 | SessionBoardSetup | Low | dual divergent controllers (Prime live vs GLB dead), different gates/paginate | reconciliation section |
| DEV-GLB-S03 | SessionBoardSetup | High | controller/view filter on `is_active` but `glb_academic_sessions` has only `is_current`/`current_flag` → status filter targets a non-existent column | `test_sessionboardsetup_*` (documented) |
| DEV-GLB-A01 | ActivityLog | Low (gap) | `sys_central_activity_logs` has no consolidated DDL (central migration only) | `test_activitylog_01` (Schema::hasTable guard) |
| DEV-GLB-A02 | ActivityLog | Medium | resource write methods are gated non-functional stubs; dual controllers (paginate 20 vs 10) | `_51`/`_52` |
| DEV-GLB-A03 | ActivityLog | x-ref | Language `forceDelete` `'Stored'` event visible in the sink (owned by Language) | cross-reference only |

## Environment prerequisites (all features)
- Enable **GlobalMaster** AND **Prime** in `prime_testing/modules_statuses.json` (both currently `false` → 404). Not a code fix.
- `APP_ENV=testing`; run on `http://127.0.0.1:8000` (central base `fail()`s otherwise).
- Central DB connections `global_master_mysql` (glb_*) + `mysql` (sys_central_*); Dropdown needs `sys_dropdown_needs` + junction seed data.
- Tests were authored but **not executed** (no browser env in this run).

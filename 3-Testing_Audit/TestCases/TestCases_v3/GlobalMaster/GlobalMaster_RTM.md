# GlobalMaster — Requirements Traceability Matrix (report mode)

**Module:** GlobalMaster (GLB) · **Generated:** 2026-Jul-10
**Traceability chain:** Source (routes/controller/DDL/FRD — no `GlobalMaster_v1` folder exists) → BC-xx → TC-P/N/D/T/S → `test_method()` → (optional) DEV-GLB-###.
Requirement basis: real registered `central.global-master.*` / `central.prime.*` routes + module controllers/views + `_global_db_v4.sql` / `_prime_db_v4.sql`. Full BC/TC IDs live in each feature's `*TcList_Require.md`; this RTM is the roll-up index.

## Feature 1 — Country (`glb_countries`, prefix `glb_`) — 46 methods
| Source | BC (representative) | TC band | Methods (representative) | Status |
|--------|--------------------|---------|--------------------------|--------|
| DDL-glb_countries | BC-DB (cols, unique name/short_name/global_code, softDeletes) | test_01 | `test_country_01_*` config truth | Covered |
| Controller store/update/destroy | BC-BIZ (activity Stored/Updated/Trashed/Restored/Deleted/Toggled) | 10-17 | create/update/show/edit/activity issued_by | Covered |
| Controller toggleStatus | BC-BIZ cascade to glb_states/glb_districts | 10-17 | `test_country_16_toggle_status_cascades_to_children` (DEV-GLB-C03) | Covered |
| CountryRequest rules() | BC-VAL (name req/max50/unique, short_name req/max10, is_active bool) | 30-39 | required/max/duplicate/XSS/whitespace/404/403/guest | Covered (Neg 100%) |
| DDL unique short_name/global_code | BC-VAL gap | 30-39 | `test_country_36_duplicate_short_name_raises_db_error` (DEV-GLB-C01) | Covered (proves defect) |
| DDL FK glb_states→glb_countries RESTRICT | BC-REF | 40-45 | delete-blocked-while-referenced, soft-delete lifecycle | Covered |
| Policy prime.country.* | BC-AUTH | 50-52 | limited-user 403 + hidden buttons | Covered |
| Views index | BC-UIX | 60-63 | pagination 10/page, search, empty state | Covered |
| — | BC-SEC | 90-95 | XSS, IDOR 404, mass-assign | Covered |

## Feature 2 — Language (`glb_languages`, prefix `glb_`) — 40 methods
| Source | BC | TC band | Methods | Status |
|--------|----|---------|---------|--------|
| DDL/migration glb_languages | BC-DB (code/name/native/direction/is_active, softDeletes via migration) | test_01 | `test_language_01_*` | Covered |
| LanguageRequest | BC-VAL (code req/max10/unique, name req/max50/unique, direction in LTR/RTL, is_active bool) | 30-39 | required/max/duplicate/direction-not-in/XSS/404/403/guest | Covered (Neg 100%) |
| Prime controller destroy/restore/forceDelete/toggle | BC-BIZ (Trashed/Restored/**Stored**/Toggled) | 10-19 | activity asserts incl. `forceDelete='Stored'` (DEV-GLB-L02) | Covered (proves defect) |
| soft-delete lifecycle | BC-REF/lifecycle | 40-49 | delete→trash→restore→forceDelete | Covered |
| Policy prime.language.* | BC-AUTH | 50-59 | 403 + reconciliation (dead ctrl mixed gates, DEV-GLB-L03) | Covered |
| Views index | BC-UIX | 60-69 | paginate 11/page, empty state | Covered |
| RULE 13 | BC-INT (Prime serves central; dead dup ctrl DEV-GLB-L04) | 50-59 | reconciliation section | Covered |

## Feature 3 — Dropdown (`sys_dropdown_table`, prefix `sys_`) — 40 methods
| Source | BC | TC band | Methods | Status |
|--------|----|---------|---------|--------|
| DDL sys_dropdown_table | BC-DB (ordinal/key160/value100/type enum/additional_info json/unique key+ordinal,key+value) | 01-09 | config truth; SoftDeletes guarded (DEV-GLB-D04) | Covered (guarded) |
| Prime store validate | BC-VAL (key req/max160/unique, value req/max100, type in enum) | 30-39 | required/max/duplicate/enum/missing-need-redirect/XSS/404/403/guest | Covered |
| Request value max:255 vs col 100 | BC-VAL divergence | 30-39 | `_04`, `_34` (DEV-GLB-D03) | Covered (proves defect) |
| store ordinal auto + junction | BC-BIZ/BC-AUTO | 10-19 | ordinal auto-increment, junction create, activity | Covered |
| junction cascade | BC-INT (DropdownNeed) | 40-49 | delete/restore/forceDelete junction (markTestSkipped-guarded) | Covered (defensive) |
| PSR-4 model | BC-DB (orphan dup DEV-GLB-D01; GLB store broken DEV-GLB-D02) | 01-09 | `_03`, `_06` | Covered (proves defects) |
| Policy prime.dropdown.* | BC-AUTH | 50-59 | 403 | Covered |
| Prime tabbed view | BC-UIX | 60-69 | tab render, list paginate 10, search | Covered |
| — | BC-SEC | 90-99 | XSS, IDOR, mass-assign, injection search | Covered |

## Feature 4 — SessionBoardSetup (`glb_academic_sessions` + `glb_boards`, prefix `glb_`) — 26 methods (read-only composite)
| Source | BC | TC band | Methods | Status |
|--------|----|---------|---------|--------|
| DDL both tables | BC-DB (session single-current via current_flag UNIQUE; board name/short_name unique) | 01-07 | schema/model/scopeCurrent | Covered |
| index() search+status+paginate | BC-BIZ/BC-UIX | 60-69 | render both lists, search filters both, status filter, paginate 10/4, fragments | Covered |
| Session single-current / start<end / no-overlap | BC-BIZ (read-only x-ref) | 10-14 | documented (management out of scope) | Documented |
| Gate prime.session-board-setup.viewAny | BC-AUTH | 30-31, 50-51 | guest→/login, 403 | Covered |
| resource write methods = stubs | BC-INT (DEV-GLB-S01/S02) | 50-59 | reconciliation | Documented |
| controller/view `is_active` vs `is_current` | BC-VAL defect (DEV-GLB-S03) | doc | status filter targets missing column | Covered (proves defect) |

## Feature 5 — ActivityLog (`sys_central_activity_logs`, prefix `sys_`, no DDL) — 23 methods (read-only viewer)
| Source | BC | TC band | Methods | Status |
|--------|----|---------|---------|--------|
| Prime ActivityLog model | BC-DB (subject_type/id, user_id, event, properties json, ip/agent; connection mysql; NO SoftDeletes) | 01-09 | getTable/fillable/casts/morphTo/belongsTo; Schema::hasTable guard (DEV-GLB-A01) | Covered (gap noted) |
| index latest+paginate(20)+search | BC-BIZ/BC-UIX | 10-19, 60-69 | ordering, properties render, paginate 20, search subject/event/user/all, empty | Covered |
| activityLog() sink integration | BC-INT | 10-19 | seed a row → asserts it renders | Covered |
| Gate prime.activity-log.viewAny | BC-AUTH | 30-39, 50-59 | guest→/login, 403, XSS-safe render | Covered |
| write methods = stubs; dual ctrl | BC-INT (DEV-GLB-A02) | 50-59 | `_51`/`_52` reconciliation | Documented |
| Language `'Stored'` in sink | BC x-ref (DEV-GLB-A03) | 70-79 | cross-reference only | Noted |

## Coverage roll-up
- **175** test methods across 5 single-file suites (46/40/40/26/23). All `php -l` clean; exactly one `.php` per screen (no V1/V2).
- Negative coverage 100% on P0/P1 CRUD features (Country/Language/Dropdown); read-only features (SessionBoardSetup/ActivityLog) covered on applicable dimensions (render/search/permissions/empty-state) with create/edit/delete correctly excluded (stubs).
- 16 GLB-owned defects + 1 cross-reference, each with a proving/observing test and traced to real source.
- Every BC and TC in the per-feature TcList carries a `Source` tag; each feature's Gap Analysis includes the 11-check Cross-Reference Findings table and the Source-tagged Coverage-Score table.

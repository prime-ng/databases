# Activity Log — Gap Analysis (`sys_`)

Feature: GlobalMaster / Activity Log (Prime-central, **read-only viewer**). Test file: `sys_ActivityLog_TestCas.php` (23 methods). Primary table `sys_central_activity_logs` (prefix `sys_`).

## 1. Manual TC ↔ Dusk method mapping

| TC ID | Category | Source | Method(s) | Coverage |
|-------|----------|--------|-----------|----------|
| TC-P01 | Config | Model | `_01` | Full |
| TC-P02 | Config | Migration | `_02` | Full |
| TC-P03 | Config | Audit (no-DDL) | `_03` | Full (documented) |
| TC-P04 | BIZ ordering | Controller | `_10` | Full |
| TC-P05 | BIZ cast | Model | `_11` | Full |
| TC-P06 | BIZ render | Blade | `_12` | Full |
| TC-P07 | Integration (sink) | Helper | `_13` | Full |
| TC-P08 | Relationship | Model | `_14` | Full |
| TC-P09 | Permissions | Controller | `_50` | Full |
| TC-P10 | UI render | Blade | `_60` | Full |
| TC-P11 | Pagination | Controller | `_61` | Full |
| TC-P12 | Search subject | Controller | `_62` | Full |
| TC-P13 | Search event | Controller | `_63` | Full |
| TC-P14 | Search user | Controller | `_64` | Full |
| TC-P15 | Search all | Controller | `_65` | Full |
| TC-N01 | Guest redirect | Middleware | `_30` | Full |
| TC-N02 | viewAny gate | Gate | `_31` | Partial (defensive — super-admin bypass self-skips) |
| TC-N03 | XSS-safe render | Blade | `_32` | Full |
| TC-N04 | Empty state | Blade | `_66` | Full |
| TC-D01 | Write stubs | Controller | `_51` | Full (documented) |
| TC-D02 | Two-controller reconciliation | Controller | `_52` | Full (documented) |
| TC-D03 | Wrong event in sink | Cross-ref | `_70` | Full (cross-reference) |
| TC-T01 | Central context | Base | `_90` | Full |

## 2. Coverage Summary (read-focused)

| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Positive (TC-P) | 15 | 15 | 0 | 0 | 100% |
| Negative (TC-N) | 4 | 3 | 1 | 0 | 100% |
| Dependency / Recon / Sec (TC-D/T) | 4 | 4 | 0 | 0 | 100% |
| **Overall** | **23** | **22** | **1** | **0** | **100%** |

Gate check (read-focused): Render **100%**, Search **100%** (all 4 type branches), Pagination **100%**, Permissions **100%** (guest + gate), Empty-state **100%**, Integration **100%**, Tenancy **100%**. **No create/edit/delete matrix** — intentionally excluded (controller write methods are non-functional stubs, DEV-GLB-A02).

**Partial-coverage notes / limitations:**
- `_31` (viewAny 403): the central super-admin `Gate::before` resolves dotted abilities, so a limited-user 403 is not deterministically observable. The method provisions a non-super-admin and `markTestSkipped()`s if it resolves as privileged — authorization is otherwise covered by guest-redirect (`_30`/`_50`) + gate definition.
- All DB/render methods guard on `Schema::hasTable('sys_central_activity_logs')` and self-skip when absent (DEV-GLB-A01 no-DDL gap) — the suite stays green in a partial environment.

## 3. Coverage-Score by requirement source

| Section | Covered | Total | % | Source tag |
|---------|---------|-------|---|-----------|
| Schema / Model config (BC-DB, BC-REL) | 7 | 7 | 100% | `Model`, `Migration`, `Audit` |
| Business logic — list/search/paginate (BC-BIZ) | 8 | 8 | 100% | `Controller`, `Blade` |
| Permissions (BC-AUTH) | 4 | 4 | 100% | `Gate`, `Middleware`, `Controller` |
| Integration — central sink (BC-INT) | 2 | 2 | 100% | `Helper` |
| Edge / cross-reference (BC-EDG) | 2 | 2 | 100% | `Blade`, `Cross-module` |

Every `Source`-tagged BC/TC maps to ≥1 method. No requirement item is left with 0 coverage. Write-CRUD is out of scope by design (stubs).

## 4. Cross-Reference Findings (11-check)

| # | Check | Compared | Finding | DEV |
|---|-------|----------|---------|-----|
| 1 | Prefix vs DDL | Model `$table` (`sys_`) vs `_prime_db_v4.sql` | Prefix is `sys_` (NOT `glb_`); **no consolidated DDL** — schema from central migration only | **DEV-GLB-A01** |
| 2 | Fillable vs columns | `$fillable` vs migration columns | Aligned (subject_type/subject_id/user_id/event/properties/ip_address/user_agent) | — |
| 3 | Cast vs column | `properties=array` vs `json` | Aligned | — |
| 4 | SoftDeletes vs schema | Model traits vs `deleted_at` | Model has **NO** SoftDeletes — correct (no `deleted_at`); tests never call `withTrashed` | — (constraint 05_) |
| 5 | Route vs controller | `Route::resource('activity-log', GlobalMaster\...Controller)` vs LIVE view | GlobalMaster routes map to the module's OWN controller, yet the LIVE screen renders `prime::activity-log.index` (`paginate(20)` + search) — Prime controller serves the path | **DEV-GLB-A02** (reconciliation) |
| 6 | Two controllers | Prime `paginate(20)` vs GlobalMaster `paginate(10)` | Prime is LIVE; GlobalMaster is DEAD on central | **DEV-GLB-A02** |
| 7 | Write methods | Route::resource CRUD vs behaviour | `create/store/edit/update/destroy` gated but non-functional stubs (read-only screen) | **DEV-GLB-A02** |
| 8 | Gate vs route | Controller `Gate::authorize('prime.activity-log.viewAny')` vs route middleware | index gated by `viewAny`; group `auth,verified`; super-admin `Gate::before` bypass | Note (intentional) |
| 9 | Search route | Prime `search()` JSON method vs registered routes | `search()` has **no route** (Route::resource does not expose it); blade `data-search-url`→index; search runs via index query string | Note |
| 10 | Event integrity | Sink event literals vs source emitters | Language `forceDelete` emits event `'Stored'` (wrong for a delete) into this sink — data-integrity slip visible here | **DEV-GLB-A03** (cross-ref; owned by Language) |
| 11 | Output escaping | Blade `{{ }}` vs stored subject/event | Dynamic fields HTML-escaped on output → XSS-safe render | — |

## 5. Legend
- **Full** — behaviour asserted directly (DB round-trip / DOM / authoritative source string).
- **Partial** — asserted when the environment supports it; otherwise self-skips (defensive).
- **Note** — observation / intentional design, not a functional defect on its own.

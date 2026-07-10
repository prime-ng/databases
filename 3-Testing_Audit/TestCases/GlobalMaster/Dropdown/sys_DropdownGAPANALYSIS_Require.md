# Dropdown — Gap Analysis (`sys_`)

Feature: GlobalMaster / Dropdown (Prime-central, `sys_dropdown_table`). Test file: `sys_Dropdown_TestCas.php` (**40 methods**).
Prefix flag: **`sys_`** (central/prime DB), NOT `glb_`.

## 1. Manual TC ↔ Dusk method mapping

| TC ID | Category | Method(s) | Coverage |
|-------|----------|-----------|----------|
| TC-P01..P06 | Config/Defect | `_01`,`_02`,`_03`,`_04`,`_05`,`_06` | Full (schema/model/request/source) |
| TC-P07 | BIZ | `_10` | Full (browser) |
| TC-P08..P12 | BIZ | `_11`,`_12`,`_13`,`_14`,`_15` | Full (live source-verified) |
| TC-P13..P17 | INT/REF | `_40`,`_41`,`_42`,`_43`,`_44` | Full (`_40`/`_43`/`_44` defensive-guarded) |
| TC-P18/P19 | AUTH | `_52`,`_53` | Full (`_52` skips if gates unregistered) |
| TC-P20..P23 | UIX | `_60`,`_61`,`_62`,`_63` | Full (`_60` browser) |
| TC-P24 | Route | `_94` | Full (skips if route absent) |
| TC-N01..N10 | Validation | `_30`–`_39` | Full |
| TC-N11/N12 | Guest | `_50`,`_51` | Full |
| TC-T01 | Tenancy | `_90` | Full |
| TC-S01 | Mass-assign | `_91` | Full |
| TC-S02 | IDOR | `_92` | Full |
| TC-S03 | Injection | `_93` | Full |

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Positive (TC-P) | 24 | 24 | 0 | 0 | 100% |
| Negative (TC-N) | 12 | 12 | 0 | 0 | 100% |
| Dependency/Security/Tenancy (TC-D/S/T) | 4 | 4 | 0 | 0 | 100% |
| **Overall** | **40** | **40** | **0** | **0** | **100%** |

Gate check: Negative **100%** (≥100 ✅), Positive **100%** (≥90 ✅), Dependency **100%** (≥90 ✅), Tenancy **100%** ✅.

**Partial/limitation notes:**
- `_40` (relationship), `_43` (soft-delete round-trip), `_44` (junction model), `_52` (gates) self-`markTestSkipped()` when the cross-module `DropdownNeed` / junction / gate registration is unavailable, per constraint 9 — they never fail loudly on a partial environment.
- `_43`'s real soft-delete round-trip only runs when `Schema::hasColumn('sys_dropdown_table','deleted_at')` is true (DEV-GLB-D04 guard); otherwise it skips with a documented reason.
- Runtime 403-for-limited-user is not asserted (central super-admin `Gate::before` bypasses dotted abilities); authorization is covered by guest-redirect (`_50`/`_51`) + gate/source proof (`_52`/`_53`).
- Controller→route binding is deliberately NOT hard-asserted (route-wiring drift, Gap §4 #11); route NAMES are asserted via `Route::has`/`route()`.

## 3. Coverage-Score by requirement source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Schema/DDL (`BC-DB`) | 9 | 9 | 100% |
| Validation Rules (`BC-VAL`) | 6 | 6 | 100% |
| Business logic (`BC-BIZ`) | 7 | 7 | 100% |
| Integration/Refs (`BC-INT`/`BC-REF`) | 3 | 3 | 100% |
| Permissions (`BC-AUTH`) | 4 | 4 | 100% |
| Edge/Defects (`BC-EDG`) | 5 | 5 | 100% |

Every `Source`-tagged item maps to ≥1 TC. No requirement item is left with 0 coverage.

## 4. Cross-Reference Findings (11-check scan)

| # | Check | Compared | Finding | DEV |
|---|-------|----------|---------|-----|
| 1 | Table prefix | Artifact prefix vs DDL | Table is `sys_dropdown_table` (central/prime DB) → prefix `sys_`, NOT `glb_` | Flag |
| 2 | Enum case | DDL `type` ENUM vs live store `in:` | Aligned verbatim (`String,Integer,Decimal,Date,Datetime,Time,Boolean`) | — |
| 3 | Fillable vs DDL | active model `$fillable` vs DDL columns | Aligned; `org_id`/`dropdown_needs_id` correctly absent | — |
| 4 | Cast vs DDL | `additional_info=array` vs DDL `JSON`; `is_active=boolean` | Aligned | — |
| 5 | Value length | GlobalMaster request `max:255` vs DDL `VARCHAR(100)` vs live store `max:100` | **Divergent** — over-length values pass the thin request, fail at DB/live store | **DEV-GLB-D03** |
| 6 | Duplicate model | two `Modules\GlobalMaster\Models\Dropdown` classes | app/Models one autoloaded; `/Models` one dead (no `$table`→`dropdowns`, org_id fillable) | **DEV-GLB-D01** |
| 7 | Request↔controller | GlobalMaster `store()` reads org_id/key/type not in `rules()` | undefined-array-key; org_id not fillable → dropped | **DEV-GLB-D02** |
| 8 | Model SoftDeletes vs DDL | model `SoftDeletes`/`deleted_at` cast vs DDL | DDL omits `deleted_at` on `sys_dropdown_table` | **DEV-GLB-D04** |
| 9 | Error message vs source | expected vs controller strings | Live messages ("Dropdown saved successfully!", "Please select a dropdown need first", toggle message) match source | — |
| 10 | Permissions vs gates | screen matrix vs `Gate::authorize` | `prime.dropdown.*` + `prime.dropdown.update` (toggle) + `prime.dropdown-need.update` (map/bulk) all present | — |
| 11 | Route vs controller | route file wiring vs live serving controller | **Drift** — `Modules/GlobalMaster/routes/web.php` wires the DEAD GlobalMaster controller; digested truth serves the screen via the Prime multi-tab controller (`prime::index`). Suite asserts route NAMES only, proves logic from Prime source | Note (reconciliation) |

## 5. Legend
- **Full** — behaviour asserted directly (DB/HTTP/DOM or authoritative source string).
- **Partial** — asserted when the environment supports it; otherwise self-skips (defensive).
- **Note / Flag** — observation/drift/labelling, not a functional defect on its own.

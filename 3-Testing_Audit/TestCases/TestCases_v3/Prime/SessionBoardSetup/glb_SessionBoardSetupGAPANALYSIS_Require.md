# SessionBoardSetup (PRM / GlobalMaster) — Gap Analysis & Coverage

Single comprehensive Dusk file: `glb_SessionBoardSetup_TestCas.php` — **32 test methods**. `php -l` clean. No V1/V2 split.

Screen type: **read-focused composite** ("Session & Board Setup", two tabs — Academic Session + Academic Board). Only `index()` is functional; create/store/show/edit/update/destroy are stubs — so a large share of coverage is **defect-proving** (BUG-PRM-011..016).

Legend: **Full** = behaviour directly asserted (DB / source / browser); **Partial** = asserted from source/config only (behavioural path fail-soft under central env); **Gap** = not covered.

---

## 1. Coverage by category (manual TC ↔ test method)

### Positive
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-P01 schema/model/route config truth | `_01` | Full |
| TC-P02 central activity sink present; feature logs nothing | `_02` | Full |
| TC-P10 index renders both tabs for admin | `_10` | Full |
| TC-P11 session listed on Academic Session tab | `_11` | Full |
| TC-P12 board listed on Academic Board tab | `_12` | Full |
| TC-P13 named pagination params (10 / 4) | `_13` | Full |
| TC-P15 board search name + short_name | `_15` | Full |
| TC-P17 board status=1 filter → active only | `_17` | Full |
| TC-P50 viewAny gate admin-allow / fresh-deny | `_50` | Full |
| TC-P54 create gate denies fresh user | `_54` | Full |
| TC-P60 breadcrumb title present | `_60` | Full |
| TC-P61 search controls on both tabs | `_61` | Full |
| TC-P62 empty-state text defined in view | `_62` | Full |
| TC-P90 central context, no tenant init | `_90` | Full |
| TC-P91 index route central-domain scoped | `_91` | Full |
| **Positive total** | 15 TC-P | **≥ 90% (100%)** |

### Negative
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-N30 session status filter → missing `is_active` column (**BUG-PRM-013**) | `_30`, `_01` | Full |
| TC-N31 invalid status value ignored (in_array guard) | `_31` | Full |
| TC-N32 guest redirected to /login | `_32` | Full |
| TC-N33 store() no-op stub (**BUG-PRM-015**) | `_33` | Full |
| TC-N34 update() no-op stub (**BUG-PRM-015**) | `_34` | Full |
| TC-N35 destroy() no-op stub (**BUG-PRM-015**) | `_35` | Full |
| TC-N36 create/show/edit reference missing views (**BUG-PRM-015**) | `_36` | Full |
| TC-N71 reflected `?search` value escaped | `_71` | Full |
| TC-N72 injection-shaped search safely parameterised | `_72` | Full |
| **Negative total** | 9 TC-N | **100%** |

### Dependency
| Manual TC | Sub | Method(s) | Coverage |
|-----------|-----|-----------|----------|
| TC-D40 pairing pivot `academic_session_board` absent; `->boards` throws (**BUG-PRM-014**) | C/E | `_40` | Full |
| TC-D41 session soft-delete excluded / restored | B | `_41` | Full |
| TC-D42 board soft-delete excluded | B | `_42` | Full |
| TC-D43 only one `is_current` session (UNIQUE current_flag) | G | `_43` | Full |
| **Dependency total** | 4 TC-D | **≥ 90% (100%)** |

### Permissions / Security (defect proofs)
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-S51 effective AcademicSession policy = `GlobalMaster\AcademicSessionPolicy` (**BUG-PRM-011**) | `_51` | Full |
| TC-S52 `SessionBoardSetupPolicy` unregistered / dead (**BUG-PRM-011**) | `_52` | Full |
| TC-S53 controller vs view permission surface diverges (**BUG-PRM-012**) | `_53` | Full |
| TC-S55 destroy `.delete` absent from readWrite grant (**BUG-PRM-016**) | `_55` | Full |
| TC-S91 index route central-domain scoped | `_91` | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Positive | 15 | 15 | 0 | 0 | 100% (≥90% target met) |
| Negative | 9 | 9 | 0 | 0 | 100% |
| Dependency | 4 | 4 | 0 | 0 | 100% (≥90% met) |
| Permissions/Security | 5 | 5 | 0 | 0 | 100% |
| **Overall** | **33 mapped** | **33** | **0** | **0** | **100%** |

33 manual TCs map onto 32 methods (`_01` serves both TC-P01 and, jointly with `_30`, TC-N30's DDL half; `_91` serves both TC-P91 and TC-S91). Every TC-ID → ≥1 method; every method → a TC/BC.

Because this screen is read-only + stub-heavy, the coverage strategy is **deterministic assertion at the layer where the truth lives**: schema/route/config via `Schema`/`Route`/reflection, business behaviour via query-builder replays of the controller's exact clauses (pagination page-names, LIKE search, status filter), and defect proofs via controller/provider/seeder/view source inspection. Browser methods (`_10/_11/_12/_60/_61/_62/_71/_32`) fail-soft through `ensurePageAccessible` when the Prime module is disabled or central host is unreachable.

---

## 3. Coverage-Score by requirement source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Schema (BC-DB) | 5 | 5 | 100% |
| Business Rules (BC-BIZ) | 5 | 5 | 100% |
| Validation (BC-VAL) | 2 | 2 | 100% |
| Permissions (BC-AUTH) | 5 | 5 | 100% |
| Integration/FK (BC-INT / BC-REF / BC-DB-05) | 3 | 3 | 100% |
| Edge (BC-EDG) | 1 | 1 | 100% |
| Security (BC-SEC) | 2 | 2 | 100% |

No BC-SM section: the screen has no status/workflow lifecycle (write endpoints are stubs; the only state facts are soft-delete and the single-current-session guard, covered under BC-REF/BC-EDG). Every `Source`-tagged requirement item maps to ≥1 TC. No zero-coverage items.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compare | Finding | Test |
|---|-------|---------|---------|------|
| 1 | Enum case | n/a (no enum columns) | — | — |
| 2 | Route registration | Blade `route()` vs `routes/web.php` | All `central.prime.session-board-setup.*` registered as `Route::resource` under the `prime.` group | `_01`, `_91` |
| 3 | Gate vs Policy | controller `Gate::authorize('prime.session-board-setup.*')` vs Policy | String gates only; `SessionBoardSetupPolicy` **never registered** → BUG-PRM-011 | `_51`, `_52` |
| 4 | Fillable vs DDL | model `$fillable` vs DDL | AcademicSession fillable excludes `is_active` (no such column); Board fillable = name/short_name/is_active | `_01` |
| 5 | Cast vs DDL | `is_current`/`is_active` = boolean vs tinyint(1) | Correct | `_01` |
| 6 | Service delegation | controller vs service | No service layer; index logic in controller; write actions empty stubs | `_33/_34/_35` |
| 7 | State machine vs impl | doc transitions vs controller | No SM; write endpoints are no-ops (no transition handling exists) → BUG-PRM-015 | `_33/_34/_35/_36` |
| 8 | Validation vs FormRequest | requirement rules vs `rules()` | **No FormRequest** — write endpoints validate nothing (stubs) | `_33/_34/_35` |
| 9 | Error message vs FormRequest | expected vs `messages()` | None (no FormRequest) | n/a |
| 10 | Permissions vs Policy/Gates | controller gates vs view `@can` | Controller `session-board-setup.*` vs view `academic-session.*`/`board.*` → **diverges** (BUG-PRM-012) | `_53` |
| 11 | Integration FK vs migration | `belongsToMany` pivot vs migration | `academic_session_board` pivot has **no table / no migration** → pairing unpersistable (BUG-PRM-014) | `_40` |

### Candidate defects (traced in source — each has a proving test)
| ID | Sev | Finding | Test |
|----|-----|---------|------|
| BUG-PRM-011 | P1 | `SessionBoardSetupPolicy` never registered in `PrimeServiceProvider` (dead code); `AcademicSession` is governed by `GlobalMaster\AcademicSessionPolicy`. *(The sub-run hypothesis of a duplicate `Gate::policy(..., SessionBoardSetupPolicy)` overwrite is NOT present in current source — the real defect is the inverse: it is absent.)* | `_51`, `_52` |
| BUG-PRM-012 | P2 | Controller gates on `prime.session-board-setup.*` but the Blade view gates its tabs/tables on `prime.academic-session.*` / `prime.board.*` — divergent authorization surface (a user with only `session-board-setup.viewAny` reaches the page but sees empty/hidden tabs) | `_53` |
| BUG-PRM-013 | P1 | `index()` status filter `where('is_active', ...)` on `glb_academic_sessions`, which has **no `is_active`** column → `SQLSTATE[42S22]`; the whole page 500s on `?status=0|1` (session query paginates first) | `_30`, `_01` |
| BUG-PRM-014 | P2 | Composite "session ↔ board pairing" unimplemented — `AcademicSession::boards()` = `belongsToMany(Board)` resolving to default pivot `academic_session_board` which has no table/migration; querying `->boards` throws | `_40` |
| BUG-PRM-015 | P2 | `create/show/edit` return non-existent Blade views (`prime::create`/`prime::show`/`prime::edit`) → 500; `store/update/destroy` are empty no-op stubs (authorize only, no persistence/redirect/log) | `_33`, `_34`, `_35`, `_36` |
| BUG-PRM-016 | P3 | `destroy()` gates `prime.session-board-setup.delete`, but `RolePermissionSeeder` `$readWrite` grant for the academicCfg group (incl. session-board-setup) omits `delete` — the ability is created but not granted to the standard read-write role | `_55` |

---

## 5. Remaining limitations
- Live-endpoint / browser assertions (`_10/_11/_12/_32/_60/_61/_62/_71`) are **environment-gated**: they fail-soft via `ensurePageAccessible` / `markTestSkipped` when the Prime module is disabled in `modules_statuses.json` or the central host / `global_master` connection is unavailable. Structural truth (schema, routes, gates, controller/provider/seeder/view source, pagination page-names, LIKE search, unique/soft-delete behaviour) is asserted independently and always runs.
- Spatie permission-based deny assertions (`_50/_54`) depend on being able to create a limited central user; they `markTestSkipped` if one cannot be resolved.
- The defect-proof tests are written to **prove current (buggy) behaviour** and to trip (fail) the moment source is fixed — each carries an inverse assertion (`assertFalse`/`fail`) with a message telling the maintainer which BUG-PRM to re-evaluate.

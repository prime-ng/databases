# SessionBoardSetup — Gap Analysis (glb_)

- **Screen:** Session & Board Setup — READ-ONLY composite (Academic Sessions + Boards)
- **Live path:** `/prime/session-board-setup` (served by `Modules\Prime\Http\Controllers\SessionBoardSetupController`)
- **Test file:** `glb_SessionBoardSetup_TestCas.php` (26 methods)
- **Prefix:** `glb_` · **Tables:** `glb_academic_sessions`, `glb_boards`

---

## 1. Requirement → Test mapping

| BC / TC | Requirement | Test method | Source |
| --- | --- | --- | --- |
| BC-DB-01 | glb_academic_sessions schema | `_01` | DDL glb_academic_sessions |
| BC-DB-02 | glb_boards schema | `_02` | DDL glb_boards |
| BC-MDL-01 | AcademicSession model config | `_03` | AcademicSession model |
| BC-MDL-02 | Board model config | `_04` | Board model |
| BC-DB-03 | current_flag generated + UNIQUE | `_05` | DDL |
| BC-DB-04 | board name/short_name UNIQUE | `_06` | DDL |
| BC-DB-05 | no own table (composite) | `_07` | reconciliation |
| BC-BIZ-01 | single current session | `_10` | DDL + scopeCurrent |
| BC-BIZ-02 | start<end / no-overlap (trigger) | `_11` | DDL comment |
| BC-BIZ-03 | board is_active boolean | `_12` | Board casts |
| DEV-GLB-S03 | sessions is_active column absent | `_13` | DDL + Prime controller |
| DEV-GLB-S02 | dual-controller reconciliation | `_14` | both controllers |
| BC-AUTH-01 | guest → /login | `_30` | auth middleware |
| BC-AUTH-02 | 403 without viewAny | `_31` | Gate::authorize |
| BC-PERM-01 | both tabs visible (admin) | `_50` | view nav-tab |
| BC-PERM-02 | tab panes present | `_51` | view |
| BC-UI-01 | renders at prime path | `_60` | HARD RULE 13 |
| BC-UI-02 | screen title | `_61` | view breadcrum |
| BC-UI-03 | both lists render | `_62` | view |
| BC-UI-04 | search + status filter present | `_63` | view search-bar |
| BC-UI-05 | search filters sessions | `_64` | controller search |
| BC-UI-06 | sessions page size 10 | `_65` | paginate(10) |
| BC-UI-07 | boards page size 4 | `_66` | paginate(4) |
| BC-UI-08 | distinct page param names | `_67` | page-name/fragment |
| BC-UI-09 | empty-state messages | `_68` | view @empty |
| DEV-GLB-S01 | read-only, write methods stubs | `_69` | controller |

---

## 2. Coverage Summary (READ-FOCUSED)

| Category | Applicable | Covered | Notes |
| --- | --- | --- | --- |
| Schema / model truth | 7 | 7 (100%) | both glb_ tables + both models |
| Business rules | 3 | 3 (100%) | documented (read-only screen; enforced on mgmt screens) |
| Negative / auth | 2 | 2 (100% of applicable) | guest redirect + 403 |
| Permission / visibility | 2 | 2 (100%) | tab + pane gating |
| Read UI (render/search/filter/pagination/empty) | 10 | 10 (100%) | includes both paginators + fragments |
| Reconciliation / defects | 3 | 3 (100%) | S01 / S02 / S03 |
| **Create / Edit / Delete / Restore** | **0** | **N/A** | **intentionally excluded — write methods are stubs (DEV-GLB-S01)** |
| **Total** | **26** | **26** | |

**Read-focused rationale:** the resource is a `Route::resource` but only `index()` is functional. The create/store/show/edit/update/destroy methods are permission-gated stubs performing no persistence, so a create/edit/delete matrix would test dead code. Negative coverage is 100% of the *applicable* surface (auth + read).

---

## 3. Cross-Reference Findings (11-check)

| # | Check | Result | Evidence |
| --- | --- | --- | --- |
| 1 | Live route → controller reconciled | PASS | `central.prime.session-board-setup.*` → Prime `SessionBoardSetupController@index`, path `/prime/session-board-setup` |
| 2 | Correct path under test | PASS | `INDEX_PATH = '/prime/session-board-setup'` |
| 3 | Table prefix correct | PASS | both tables `glb_` (glb_academic_sessions, glb_boards) |
| 4 | Model ↔ table binding | PASS | AcademicSession→glb_academic_sessions, Board→glb_boards, conn `global_master_mysql` |
| 5 | Gate coverage | PASS | index gated `prime.session-board-setup.viewAny`; 403 test `_31` |
| 6 | SoftDeletes columns present | PASS | deleted_at on both tables; models use SoftDeletes |
| 7 | Pagination page-size fidelity | PASS | sessions 10 / boards 4 asserted (`_65`,`_66`) |
| 8 | Fragment / page-name fidelity | PASS | `academicsession_page`/`academicboard_page` + fragments (`_67`) |
| 9 | Dual-controller reconciliation | DOCUMENTED | DEV-GLB-S02 (`_14`) — GlobalMaster controller dead on central |
| 10 | Column-reference integrity | DEFECT | DEV-GLB-S03 (`_13`) — controller/view use `is_active` absent on sessions table |
| 11 | Write-path integrity | DEFECT | DEV-GLB-S01 (`_69`) — resource write methods are non-functional stubs |

---

## 4. Source-tagged Coverage-Score table

| Area | Score | Source tag |
| --- | --- | --- |
| glb_academic_sessions schema/model | 100% | `DDL glb_academic_sessions`, `AcademicSession model` |
| glb_boards schema/model | 100% | `DDL glb_boards`, `Board model` |
| current_flag single-current | 100% | `DDL uq_glb_acadSession_currentFlag` |
| board uniqueness | 100% | `DDL uq_glb_academicBoard_name/_shortName` |
| business rules (documented) | 100% | `DDL comment`, `scopeCurrent`, `Board casts` |
| auth / negative | 100% (applicable) | `Gate::authorize`, `auth middleware` |
| permission / tab visibility | 100% | `view nav-tab @can` |
| read UI (render/search/filter) | 100% | `Prime SessionBoardSetupController@index`, `prime::session-board-setup.index` |
| pagination + fragments | 100% | `paginate(10,'academicsession_page')`, `paginate(4,'academicboard_page')` |
| reconciliation / defects | 100% | `DEV-GLB-S01/S02/S03` |
| create/edit/delete | N/A (excluded) | `DEV-GLB-S01 stubs` |

---

## 5. Defects & reconciliation detail

### DEV-GLB-S01 — Read-only resource with stub write methods
`create/store/show/edit/update/destroy` are permission-gated but return unrelated views (`prime::create`, `prime::show`, `prime::edit`) or do nothing. No persistence. The screen is effectively read-only despite being a `Route::resource`. **No CRUD tests generated.** Covered/documented by `_69`.

### DEV-GLB-S02 — Divergent dual controllers
`Modules\Prime\Http\Controllers\SessionBoardSetupController` (LIVE) vs `Modules\GlobalMaster\Http\Controllers\SessionBoardSetupController` (DEAD, wired under `global-master.session-board-setup`). Divergences: gates (`prime.session-board-setup.viewAny` vs `Gate::any(['prime.board.viewAny'])`), views (`prime::` vs `globalmaster::`), paginate sizes (10/4 vs 10/10). Only the Prime controller is reachable on central. Documented by `_14`.

### DEV-GLB-S03 — Non-existent column referenced for session status
LIVE controller: `$academicSessionQuery->where('is_active', $request->get('status') === '1')` and view `$session->is_active`. But `glb_academic_sessions` has **no `is_active`** — its status flag is `is_current` (+ generated `current_flag`). The Academic Session status filter targets a missing column (DB error / no-op). Session status should reference `is_current`. Documented + asserted by `_13`.

### BC-BIZ (cross-reference only)
Single-current (`current_flag` UNIQUE), `start_date < end_date`, no-overlap (trigger, not in DDL), and board name/short_name uniqueness are enforced on the Academic Session / Board management screens. This composite only reads them.

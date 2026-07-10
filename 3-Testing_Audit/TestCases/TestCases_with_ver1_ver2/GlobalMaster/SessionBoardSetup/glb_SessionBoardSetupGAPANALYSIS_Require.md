# glb_SessionBoardSetup — Gap Analysis & Coverage

**Feature:** GlobalMaster :: Session & Board Setup (composite, read-only hub)
**V1 methods:** 14 | **V2 methods:** 41 | **Ratio:** 2.93× (≥ 2× gate satisfied)

> Screen type is **read-focused / partly broken**. There is no create/edit/delete flow to cover (write surface is non-functional and documented as defects), so the standard positive/negative CRUD matrix is deliberately reduced. Coverage targets are applied to the categories that exist: render, config, permissions, and the defect set.

---

## 1. Manual TC ↔ Dusk method mapping

### Positive / config / render
| Manual TC | V1 method(s) | V2 method(s) | Coverage |
|-----------|--------------|--------------|----------|
| TC-P01 tables+columns | 01 | 01, 02 | Full |
| TC-P02 unique keys | 01 | 03, 04 | Full |
| TC-P03 model config | 03, 04 | 06, 07 | Full |
| TC-P04 route registered | 01 | 08 | Full |
| TC-P05 index load/view | 30 (source) | 10, 11 | Full |
| TC-P06 both tabs | 12 | 12, 60 | Full |
| TC-P07 empty state | — | 61 | Full |
| TC-P08 pagination | — | 62 | Full |
| TC-P09 admin render | 11 | 56 | Full |
| TC-P10 relationships | — | 40, 41, 42 | Full |

### Negative / authorization / security
| Manual TC | V1 method(s) | V2 method(s) | Coverage |
|-----------|--------------|--------------|----------|
| TC-N01 guest redirect | 10 | 55 | Full |
| TC-N02 index gate 403 | 50 | 50 | Full (source-proven; live 403 requires enabled module) |
| TC-N03 session tab @can | — | 51 | Full |
| TC-N04 board tab @can | — | 52 | Full |
| TC-N05 policy keys | — | 53, 54 | Full |
| TC-N06 reflected XSS escape | — | 90 | Full (browser, env-gated) |

### Dependency / defect
| Manual TC | V1 method(s) | V2 method(s) | Coverage |
|-----------|--------------|--------------|----------|
| TC-D01 write stubs no-op | 30 | 30, 31, 32 | Full |
| TC-D02 missing views | 09 | 33, 34, 35 | Full |
| TC-D03 BUG-GLB-001 recon | 07 | 70 | Full |
| TC-D04 DATA-GLB-002 phantom is_active | 05 | 71, 72 | Full |
| TC-D05 BUG-GLB-003 single-current | 06 | 73 | Full |
| TC-D06 BUG-GLB-004 route mismatch | — | 74, 76 | Full |
| TC-D07 BUG-GLB-005 dual controller | 08 | 75 | Full |
| TC-D08 cross-tenant N/A | — | 92 | Full (documented skip) |
| TC-D09 store route no-op | 30 | 91 | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive / config / render | 10 | 10 | 0 | 0 | 100% |
| Negative / authorization / security | 6 | 6 | 0 | 0 | 100% |
| Dependency / defect | 9 | 9 | 0 | 0 | 100% |
| **Total** | **25** | **25** | **0** | **0** | **100%** |

Targets (adapted to read-only composite): Negative 100% ✅ · Positive ≥ 90% ✅ (100%) · Dependency ≥ 90% ✅ (100%).

---

## 3. Coverage-Score by requirement Source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR` / BC-BIZ) | 5 | 5 | 100% |
| State-Machine transitions (`Screen-SM`) | 0 | 0 | N/A (no workflow; single-current is a DB invariant, covered under BC-EDG-03) |
| Validation Rules (`Screen-VR`) | 0 | 0 | N/A (no FormRequest — write surface non-functional) |
| Integration Points (`Screen-IP` / BC-REF) | 3 | 3 | 100% |
| Permissions (`Screen-PM` / BC-AUTH) | 5 | 5 | 100% |
| Schema (`DDL` / BC-DB) | 7 | 7 | 100% |
| Defects (`Audit` / BC-EDG) | 6 | 6 | 100% |

Every `Source`-tagged requirement item maps to ≥ 1 TC. No zero-coverage items.

---

## 4. Cross-Reference Findings (defect scan)

| # | Check | Compared | Finding | Defect | Proving test |
|---|-------|----------|---------|--------|--------------|
| 2 | Route registration | Blade `route('central.global-master.*')` vs GlobalMaster routes (`global-master.*`) | Name-prefix mismatch — `central.global-master.academic-session.*` not registered by the module | **BUG-GLB-004** | V2 74, 76 |
| 2b | Route registration | Root web.php (`Prime\SessionBoardSetupController`) vs GlobalMaster routes (`GlobalMaster\SessionBoardSetupController`) | Two controllers bind the `session-board-setup` resource | **BUG-GLB-005** | V1 08, V2 75 |
| 3 | Gate vs Policy | GM `Gate::any(['prime.board.viewAny'])` vs BoardPolicy | Gate keys on board perm even for the session tab; asymmetric with session `@can` | Note (documented, not a bug) | V2 50, 51, 52 |
| 4 | Fillable vs DDL | AcademicSession `$fillable` vs `glb_academic_sessions` | No `is_active` in table or fillable, but view reads `$session->is_active` | **DATA-GLB-002** | V1 05, V2 71, 72 |
| 5 | Cast vs DDL | Board `is_active` cast boolean vs tinyint(1) | Correct | — | V2 07 |
| 6 | Service delegation | Controller body | No service layer; logic inline (trivial) | — | — |
| 7 | State machine vs impl | Single-current invariant vs `store()` | Invariant DB-only (`current_flag` UNIQUE); `store()` no-op | **BUG-GLB-003** | V1 06, V2 73 |
| 8 | Validation vs FormRequest | Expected write validation vs actual | No FormRequest exists; write surface non-functional | **BUG-GLB-006** | V1 09, V2 30-35 |
| 10 | Permissions vs Policy | `prime.board.*` / `prime.academic-session.*` vs Policies | Keys align with policies | — | V2 53, 54 |
| — | Model resolution | Audit claim (`GlobalMaster\Models\AcademicSession`) vs live import (`Prime\Models\AcademicSession`) | Audit-predicted 500 does NOT reproduce; live controller imports the existing Prime model | **BUG-GLB-001 (reconciled: not reproduced)** | V1 07, V2 70 |
| — | View vs controller | `create/show/edit` views vs on-disk | Views missing → 500 on those routes | **BUG-GLB-006** | V1 09, V2 33-35 |

---

## 5. Remaining limitations / notes

- **Live 403/render assertions are environment-gated.** Browser cases (55, 56, 60, 90) and route-registration probes (08, 76, 91) self-skip with `markTestSkipped` until GlobalMaster **and** Prime are enabled in `modules_statuses.json` and Chrome is driving `127.0.0.1:8000`. The deterministic core (schema, model, source-shape, class-existence) runs regardless.
- **Index-introspection helper** uses Doctrine with a `SHOW INDEX` fallback for environments without `doctrine/dbal`.
- **No CRUD matrix** is intentional: store/update/destroy are empty stubs and create/show/edit views are missing — proven, not assumed.
- **Cross-tenant isolation is N/A** (single central `global_master` DB) — documented as a deliberate skip (test 92), not a coverage gap.

## Legend
Full = behaviour asserted end-to-end (or fully source-proven for non-functional surfaces). Partial = asserted with an environmental caveat. Gap = no coverage.

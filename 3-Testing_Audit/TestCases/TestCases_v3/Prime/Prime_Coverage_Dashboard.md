# Prime (PRM) — Module Coverage Dashboard

**Module:** Prime | **Code:** PRM | **Registry PREFIX (hint):** `prm_` | **Folder:** `Modules/Prime` | **DDL:** `_prime_db_v4.sql` (+ `_global_db_v4.sql` for glb_ screens)
**Generated:** 2026-Jul-10 | **Mode:** report (module roll-up — aggregated from on-disk feature artifacts; no suite regenerated)
**DB scope:** CENTRAL / core (`prime_db`). Central console — no tenant init. Browser host `http://127.0.0.1:8000`.
**Source of numbers:** each feature's `*Validation_Report.md` (verdict, method count) + `*GAPANALYSIS_Require.md` (coverage %, defect register). Method counts verified by counting `public function test*` in each single test file.

> **DDL-verified prefix note (carried from `Prime_Feature_Inventory.md`):** the registry lists Prime `prm_`, but 8 in-scope screens are `sys_` and 5 are `glb_` (their primary tables live in `_prime_db_v4.sql` sys_ area / `_global_db_v4.sql` global_master). Each file prefix follows the DDL table rule (HARD RULE 4), not the module code.

---

## 1. Module totals

| Metric | Value |
|--------|-------|
| Features aggregated | **20 / 20** |
| Single test files (one `{prefix}_{Feature}_TestCas.php` each, no V1/V2) | 20 |
| **Total test methods across all 20 features** | **797** |
| Validation verdict — PASS | **0** |
| Validation verdict — **PASS WITH NOTES** | **20 / 20** |
| Validation verdict — FAIL / blocked | 0 |
| Features at 100% overall Full coverage | 15 |
| Features at ≥96% (below 100%, gates still met) | 5 (Board, Dropdown, TenantGroup, TenantManagement, + Email’s single mail-send partial) |
| Open (unfixed) source-defect candidates traced with proving tests | ~95 across the module (see per-feature column) |
| Audit defects proven REMEDIATED / regression-guarded | 10 (RolePermission, Tenant ×5, User ×4) |
| Audit defects NOT REPRODUCED / REFUTED (documented honestly per HARD RULE 1) | 6 (D25-PRM-001, D25-PRM-002, DEP-PRM-001, GAP-PRM-001, SEC-PRM-002, BUG-PRM-009) |

---

## 2. Per-feature dashboard

Coverage columns are **% Full** by category from each Gap Analysis §2. "Overall" is the feature's mapped-TC Full% roll-up. Verdict is verbatim from the feature Validation Report §Final Verdict.

| # | Feature | Prefix | Methods | Positive % | Negative % | Dependency / Security % | Overall Full % | Verdict | Open defects (proving-test-backed) |
|---|---------|--------|:------:|:----:|:----:|:----:|:----:|:----:|-------------------------------------|
| 1 | AcademicSession | `glb_` | 35 | 100 | 100 | 100 | 100 | PASS WITH NOTES | BUG-PRM-012, BUG-PRM-013, BUG-PRM-011 (P1); BR-PRM-021 (P2); BUG-PRM-014 (P3) — *D25-PRM-001 not reproduced (superseded by 012)* |
| 2 | ActivityLog | `sys_` | 25 | 100 | 100 | 100 | 100 | PASS WITH NOTES | DEV-PRM-AL-001 (search ungated), -002 (route dup ×3), -003 (missing search route), -004 (orphaned CRUD/view ns), -005 |
| 3 | Board | `glb_` | 60 | 100 (57/59 full) | 100 | 100 | ~97 | PASS WITH NOTES | DEV-PRM-BOARD-01…06 (dual Request/Model, stricter-than-DDL rules, toggle-logs-before-save, trashed-unique reservation) |
| 4 | Dropdown | `sys_` | 41 | 92 | 100 | 100 | 97.6 | PASS WITH NOTES | DEV-DROPDOWN-001…008 (deleted_at gap, destroy scope bug, junction inconsistency, unique-key design, enum narrower than DDL, no-activity-log) |
| 5 | DropdownMgmt | `sys_` | 37 | 100 | 100 | 100 | 100 | PASS WITH NOTES | DEV-DDM-001…007 (destroy stub, missing views, mixed junctions, unreachable deleteBulk, no unique guard, unused scaffold, fillable typo) |
| 6 | DropdownNeed | `sys_` | 51 | 100 | 100 | 100 | 100 | PASS WITH NOTES | BUG-PRM-DDNEED-001/003/004/005/006; PERF-PRM-001 — *SEC-PRM-004 re-scoped, TEN-PRM-001 remediated, BUG-PRM-DUP corrected* |
| 7 | Email | `prm_` | 16 | ~93 (1 partial) | 100 | 100 | 100 | PASS WITH NOTES | DEV-PRM-EMAIL-001 (hardcoded recipient / GET side-effect), -002 (policy User-class mismatch) — *SEC-PRM-002 refuted (env-guarded)* |
| 8 | Language | `glb_` | 48 | 100 | 100 | 100 | 100 | PASS WITH NOTES | DEV-LANG-002/003/004/005/006/007/009/010 (route group ×2, forceDelete logs Stored, unresolved flash, restore keeps inactive, redundant policy) |
| 9 | Menu | `glb_` | 52 | 100 | 100 | 100 | 100 | PASS WITH NOTES | DEV-PRM-MENU-001…005 (route param mismatch, unique scope, schema drift, inverted rule, dead field); PERF-PRM-002 (Navbar N+1); DUP-PRM-001 |
| 10 | Notification | `prm_` | 33 | 100 | 100 | 100 | 100 | PASS WITH NOTES | DEV-PRM-NTF-001 (delete gate w/o define), -002 (ctor arg ignored) — *SEC-PRM-002 refuted (env-guarded)* |
| 11 | RolePermission | `sys_` | 47 | 100 | 100 | 100 | 100 | PASS WITH NOTES | DEV-PRM-010 (destroy logs Toggled), -011 (force-delete = hard delete; trash stubbed), -012 (validates non-existent `permissions` table) — *SEC-PRM-001 remediated; DEP-PRM-001 not reproduced* |
| 12 | SalesPlanAndModuleMgmt | `prm_` | 35 | 100 | 100 | 100 | 100 | PASS WITH NOTES | DEV-PRM-SPM-001…007 (CRUD stubs, missing views, permission-vocab split, dead policy, pivot table name mismatch, fillable/DDL drift) — *GAP-PRM-001 refuted* |
| 13 | SessionBoardSetup | `glb_` | 32 | 100 | 100 | 100 | 100 | PASS WITH NOTES | BUG-PRM-011 (policy unregistered), -012 (divergent gate surface), -013 (is_active 500), -014 (unimplemented pairing/missing pivot), -015 (missing views + no-op writes), -016 (delete ability ungranted) |
| 14 | Setting | `sys_` | 37 | 100 | 100 | 100 | 100 | PASS WITH NOTES | DEV-001 (search ungated → BR-PRM-022 fails), -002 (store no-op), -003 (destroy no-op), -004/-005 (missing create/show views), -006 (organization_id absent), -007 (dead all()), -008 (no activity log) |
| 15 | Tenant | `prm_` | 50 | 100 | 100 | 100 | 100 | PASS WITH NOTES | BUG-PRM-TENANT-001 (NEW P1 — routes bind to missing controller methods) — *5 audit defects FIXED w/ regression tests: BUG-PRM-006, BUG-PRM-STUB-001, GAP-PRM-003, MIG-PRM-001, GAP-PRM-001* |
| 16 | TenantDomain | `prm_` | 47 | 100 | 100 | 100 | 100 | PASS WITH NOTES | BUG-PRM-002 (hard delete, no SoftDeletes), -003 (max:255 > DDL col), -004 (encrypted pwd overflow) — *BUG-PRM-001 remediated (db_password encrypted cast)* |
| 17 | TenantGroup | `prm_` | 39 | 96 | 100 | 100 | 96 (Pos) | PASS WITH NOTES | D25-PRM-003 (update no activity log), -004 (index renders cities/broken listing), -005 (redirect anchor typo), -006 (name uniqueness only in Request), -007 (toggle logs before save) — *D25-PRM-002 not reproduced* |
| 18 | TenantManagement | `prm_` | 24 | 92 | 100 | 100 | 96 | PASS WITH NOTES | BUG-PRM-TM-001…005 (read/stat/doc-drift candidates) — *BUG-PRM-009 verified N/A (clean)* |
| 19 | User | `sys_` | 44 | 100 | 100 | 100 | 100 | PASS WITH NOTES | BUG-PRM-N01…N04 (NEW: index undefined-var, 2FA field mismatch, image rule/key mismatch, media collection); FILL-PRM-001 + BUG-PRM-009 (residual) — *4 P0/P1 audit defects REMEDIATED: SEC-PRM-003, BUG-PRM-002, BUG-PRM-010, GAP-PRM-004* |
| 20 | UserRolePrm | `sys_` | 44 | 100 | 100 | 100 | 100 | PASS WITH NOTES | DEV-URP-001 (gate reuse), -002 (search ungated), -003 (missing views 500), -004 (empty CRUD → no persistence), -005 (no activity log), -006 (raw wildcards) |

**Method-count reconciliation:** 35+25+60+41+37+51+16+48+52+33+47+35+32+37+50+47+39+24+44+44 = **797**.

---

## 3. Coverage-gate compliance (all features)

Every feature meets the standing gates: **Negative = 100%**, **Positive ≥ 90%**, **Dependency ≥ 90%**. Tenancy-isolation gate is **N/A for all 20** (Prime is a single central-DB console — cross-tenant isolation surface does not apply; central scope is proven per feature via `mysql` connection + `127.0.0.1` host assertions, typically the `_90/_91/_93` band).

| Gate | Threshold | Features meeting | Notes |
|------|-----------|:---------------:|-------|
| Negative / Validation | 100% | 20 / 20 | every negative TC has ≥1 method |
| Positive | ≥ 90% | 20 / 20 | lows: Dropdown 92, TenantManagement 92, TenantGroup 96 |
| Dependency / Integration | ≥ 90% | 20 / 20 | Language dependency is 100% via defensive env-guarded assertions |
| Tenancy isolation | N/A | 20 / 20 | central single-DB module |

---

## 4. Verdict distribution & notes character

All 20 feature Validation Reports close at **PASS WITH NOTES** — there is **no plain PASS and no FAIL** in the module. The recurring "notes" (not coverage gaps) are:

1. **Environment-gated execution.** Prime is currently `false` in `prime_testing/modules_statuses.json`; route/browser/HTTP methods `markTestSkipped` until the module is enabled (+ ChromeDriver, reachable central DB). Structural/source-truth assertions always run.
2. **Defect proofs asserted at source/schema level** where the failing path raises a DB error or the screen is a stub — the tests prove *current* behaviour and are written to trip on fix.
3. **Prefix divergence** (`glb_`/`sys_` vs registry `prm_`) intentionally follows the DDL-table rule.
4. **Audit reconciliation:** several assigned audit defects were REMEDIATED, NOT REPRODUCED, or REFUTED against current source and documented honestly rather than asserted as still-broken.

---

## 5. Defect roll-up by disposition

| Disposition | Count (approx.) | Examples |
|-------------|:---------------:|----------|
| **Open (unfixed, proven in current source)** | ~95 | DEV-PRM-AL/BOARD/MENU/NTF/SPM/URP-*, DEV-DROPDOWN/DDM/LANG-*, DEV-001…008 (Setting), BUG-PRM-DDNEED-*, BUG-PRM-011…016 (SessionBoardSetup), BUG-PRM-TM-*, BUG-PRM-N01…N04 (User), BUG-PRM-002/003/004 (TenantDomain), D25-PRM-003…007 (TenantGroup), BUG-PRM-TENANT-001 (Tenant) |
| **Remediated (regression-guarded)** | 10 | SEC-PRM-001, SEC-PRM-003, BUG-PRM-002 (User fillable), BUG-PRM-010, GAP-PRM-004, BUG-PRM-006, BUG-PRM-STUB-001, GAP-PRM-003, MIG-PRM-001, BUG-PRM-001 |
| **Not reproduced / Refuted (documented)** | 6 | D25-PRM-001, D25-PRM-002, DEP-PRM-001, GAP-PRM-001, SEC-PRM-002, BUG-PRM-009 |
| **Residual (low-sev, still present)** | 2 | FILL-PRM-001 (User remember_token fillable), BUG-PRM-009 (User rand() stat stub) |

> Highest-severity **open** items to prioritise for dev triage: **BUG-PRM-TENANT-001** (P1, routes → missing methods), **BUG-PRM-012/013** (P1, AcademicSession create/toggle break), **BUG-PRM-N01** (P1, User index undefined-var), **SEC-PRM-004** context (DropdownNeed), the SessionBoardSetup **BUG-PRM-013/015** page-500s, and the SalesPlan/DropdownMgmt/UserRolePrm/Setting **CRUD-stub** clusters.

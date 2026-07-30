# TestCase Agent Rebuild — Plan v2 (2026-07-24)

> **Update log — 2026-07-24 (owner changes, folded in):**
> 1. Recommendation test folders are now **space-free** (`RecommendationMasters/RecommendationModes`, …). Gold-file namespace remains **flat** (`Tests\Browser\Modules\Recommendation`) — verified unchanged.
> 2. Input folders fully normalized (verified): **all 31 requirement folders = `Module_Requirement/`** (0 stale `Requirement_Docs`), **all 30 TcList folders = `TC_List/`** (0 `TC_Lists`). Agents read requirements from `…/{Module}/Module_Requirement/` and TcLists from `…/{Module}/TC_List/`. **Only leftover variance:** the TcList *file* suffix (`*_TcList.md` 333 vs `*_TC_List.md` 109) — glob at file level. See §4 Item-A.
> 3. Folder/feature names are now **PascalCase, no spaces** — so tab-group and feature folders are legal path/namespace segments.

> **Decision (locked with owner):** Build **two NEW, separate agents** to the new gold standard, and **keep the existing `testcase-creator` agent untouched** as an A/B comparison baseline.
> - **Agent A — `tclist-author`** — Requirement + DDL + real source → a 12-section reviewed-style TcList. *(For FUTURE requirement additions/enhancements; not the urgent need — the current reviewed TcLists are treated as final.)*
> - **Agent B — `testcase-scripter`** — a **human-reviewed TcList (PRIMARY input)** + real-source re-verification → one comprehensive **V2 Dusk `.php`** test file, and it annotates the TcList's `Covered By` columns. *(This is the URGENT deliverable.)*
>
> This document answers the three goals in the request: (1) is the approach right; (2) enhance vs new; (3) the build plan.

---

## 0. Evidence this plan is built on (read/verified 2026-07-24)

| Source | What it established |
|--------|--------------------|
| `~/.claude/agents/testcase-creator/AGENT.md` + `Testing-Plan/03_…Agent_Prompt.md` | The **existing** agent: 5-artifact output, band-numbered methods, generates its OWN BC/TC list, reads the **OLD** input path `2-Module_Requirement_V1/{MODULE}_v1/`. |
| `Enhancement_v2/GAP_Analysis_TC_Creation_Process.md` | Sameer's team standard vs existing agent — 12-section TcList, `Covered By` traceability, MANUALTESTING merge, V1/V2, tab nesting, **DDL-first**, **dual-source (TcList is PRIMARY)**. |
| Verified GOLD sample: `prime_testing/tests/Browser/Modules/Recommendation/Recommendation Masters/Recommendation Modes/` | Target output = **2 files** (`…TcList.md` + `…V2_TestCas.php`). Test file = **57 sequential methods** `test_rec_mode_01..57` (3 schema + CRUD + toggle + search/filter + soft-delete lifecycle + pagination + validation negatives + XSS/whitespace + guest/403/button-vis + 4×404 + FK cascade + full lifecycle + activity-log + race/concurrent + tab-nav). |
| Refined INPUT sample: `prime_testing/Doc_Analysis/4-TC_List_Requirement_Review/Exam/TC_List/lms_ExamType_TcList.md` | Reviewed TcLists **already match** the 12-section gold format → Stage A is largely done; the immediate gap is Stage B (generator). |
| `0-Prime_Ai_Detail/module_list.md` | The **only** prefix authority. `REC=rec_`, `EXM=lms_`, `QNS=qns_`. Sameer's hardcoded prefix table (`qbn_`, `lex_`) is **wrong** — must not be used. |

---

## 1. Goal 1 — Is the approach right?  → **YES, with 4 refinements**

The core of the new approach is sound and directly fixes the original complaint ("Claude generates test cases that aren't required"):

**Why it's right:** The root cause was that the old agent *invented* its own test list in the same pass it wrote code, with no human gate. The new pipeline **decouples**:

```
Requirement + DDL ──►[Agent A: tclist-author]──► TcList.md ──►[HUMAN REVIEW]──► approved TcList.md ──►[Agent B: testcase-scripter]──► V2 .php
                                                                                          (PRIMARY, authoritative)
```

The human-review gate on the TcList is exactly the control that was missing. Making the approved TcList the **PRIMARY, authoritative input** to the generator (dual-source mandate: *every* TC in the list must map to a test method or generation FAILS and reports the gap) means the generator can no longer over- or under-produce — it implements the approved scope, nothing else.

**4 refinements to make it robust:**

1. **`module_list.md` is the single source of identity/prefix — forbid every hardcoded prefix table.** Sameer's `AGENTS.md` prefix table is factually wrong (`qbn_`/`lex_` vs real `qns_`/`lms_`). Both new agents must resolve `MODULE_NAME/CODE/PREFIX/FOLDER_NAME/DDL_FILE_NAME` from `module_list.md` and STOP-and-ask if a module isn't found.
2. **Normalize the input folder/file-naming drift.** The reviewed inputs are already inconsistent: `Exam/TC_List/…_TcList.md` vs `Accounting/TC_Lists/…_TC_List.md`. Agents must **glob** (`*TcList*.md` / `*TC_List*.md`, `TC_List*/` / `TC_Lists/`) — never hardcode one spelling. Recommend a one-time cleanup pass to standardize, but the agents must tolerate both regardless.
3. **Keep "verify against real source" even though the TcList is primary.** The TcList is authoritative for *scope* (what to test), but selectors/routes/permission strings/activity-log messages/column facts must still be re-read from live source at generation time (a TcList can drift from code). Mismatch → raise a `DEV-###`, don't silently trust either side.
4. **Preserve the hard-won environment knowledge.** The existing agent's `05_Known_Test_Failure_Constraints.md` (48-rule Rule Card) + `05a_Constraints_Evidence_Appendix.md` encode ~months of real Dusk/tenancy/env facts (Dusk `Browser` has no `assertStatus`; `glb_languages` is a VIEW; Super-Admin `Gate::before` bypass; `sys_users` NOT-NULL columns; etc.). These are **standard-agnostic** and must be **referenced (not copied)** by both new agents.

---

## 2. Goal 2 — Enhance existing vs new?  → **New (2 separate agents), existing KEPT for comparison**

Per owner decision, we do **not** modify `testcase-creator`; it stays as one arm of an A/B comparison. We add two new agents built to the gold standard.

**Rationale this is safe (not wasteful):**
- The genuinely valuable, hard-to-rebuild asset is the **Rule Card (05_/05a_)** — pure environment truth, independent of output format. The new agents **reference the same 05_/05a_ files**, so none of that knowledge is lost or duplicated.
- What the new agents drop from the old one is only the parts that *conflict* with the gold standard: 5-artifact output, band numbering, requirement-first read order, self-invented test list. Those are format/workflow choices, not knowledge.
- Keeping `testcase-creator` intact gives the owner three comparable outputs (old single-pass agent vs new author+generator pipeline) to evaluate quality objectively before standardizing.

**Shared-SSOT strategy (critical to avoid drift across 3 agents):** Both new agents are thin **loaders** (like the current `AGENT.md`) that pull their role live from versioned prompt files under `Testing-Plan/`. Shared constraint files are referenced by all three agents:

```
~/.claude/agents/tclist-author/AGENT.md          → loads 1-TC_Creation/08_TcList_Author_Agent_Prompt.md
~/.claude/agents/testcase-scripter/AGENT.md      → loads 1-TC_Creation/07_TestCase_Scripter_Agent_Prompt.md
~/.claude/agents/testcase-creator/AGENT.md        → (UNCHANGED) loads Testing-Plan/03_…
SHARED, referenced by all:  00_…Conventions.md · 05_Rule Card · 05a_Evidence Appendix · module_list.md · gold sample
```

---

## 3. Goal 3 — The build plan

### 3.1 Canonical contracts (the gold standard, extracted from the verified sample)

**Filename convention (LOCKED):**
- TcList: `{PREFIX}{Feature}_TcList.md`  (PREFIX from `module_list.md`, e.g. `rec_RecommendationMode_TcList.md`).
- Test file: `{PREFIX}{Feature}V{N}_TestCas.php`  → class name = filename (no extension).
- **Filename prefix = `module_list.md` PREFIX column, ALWAYS.** The `lms_rec_…` samples are to be **corrected to `rec_…`** going forward. (Legacy `lms_rec_` files are not renamed retroactively unless asked.)

**Output location (folder nesting mirrors tabs; namespace stays flat per module):**
```
prime_testing/tests/Browser/Modules/{FOLDER_NAME}/{TabGroup}/{Feature}/{PREFIX}{Feature}V{N}_TestCas.php
namespace Tests\Browser\Modules\{FOLDER_NAME};     // flat — NOT per tab group
class {PREFIX}{Feature}V{N}_TestCas extends DuskTestCase
```
`{TabGroup}` and `{Feature}` are **PascalCase, no spaces** (e.g. `RecommendationMasters/RecommendationModes`) — matches the current on-disk gold sample.

**V1/V2 versioning:** no existing file → create `V1`; `V1` exists → create `V2` as an upgrade (keep both; V2 supplements, never deletes V1). Some modules may carry a "modify V1 only" instruction — honor per-module overrides.

**Test file skeleton (from the verified Recommendation sample):**
- `use App\Models\User; …ActivityLog; Modules\Prime\Models\Domain; Tests\DuskTestCase;`
- `setUp()` → tenant init (`initializeTenantContext()`), resolve admin from `DUSK_ADMIN_EMAIL`, one-time screenshot clean; `tearDown()` → `tenancy()->end()`.
- Path constants (INDEX/TRASH/CREATE/VIEW), tab/pane selectors.
- Method naming: **sequential** `test_{prefix}_{feature}_{NN}_{descr}` (e.g. `test_rec_mode_31_duplicate_mode_name_create`).
- SweetAlert2 helpers (`navigateToEditRecord()`, `acceptSweetAlertIfPresent()`), screenshot-on-failure per `browse()`, unique suffix per record, cleanup via `forceDelete()` in `finally` (children→parent FK order).

**Mandatory coverage checklist (the "not-invented, not-missing" gate):**
- **3 schema** — `test_01` full DDL↔model↔request alignment matrix; `test_02` DB NOT-NULL rejects missing (loop); `test_03` DB nullable accepts null. Soft-delete asserted **independently** (column AND trait).
- **≥16 positive** — incl. create all-fields / required-only / default-applied, show, edit-prefill, updates, toggle both directions, search by **name AND description**, filter active/inactive, soft-delete lifecycle, restore, force-delete, empty-trash, pagination (index **and** trash), seed-count.
- **≥12 negative** — required, max-length, duplicate (create + blocked-on-update-different + allowed-on-update-same), invalid enum/boolean, whitespace-only, XSS, guest→`/login`, **real 403** via HTTP method + `forgetCachedPermissions()` + fresh non-super-admin, button-visibility, 4×404 (show/edit/delete/toggle) + restore/forceDelete 404 + toggle-soft-deleted→404, restore-already-active, force-delete-non-deleted.
- **≥4 dependency** — FK cascade/restrict, activity-log persistence after force-delete, concurrent edit / rapid-toggle race, tab-navigation preserves filter/search state. Cross-module paths guarded with `try/catch + markTestSkipped`.
- **ENUM values from DDL only** (never placeholder `'Test'`/`'Produce'`); **permission strings from the controller's `Gate::authorize()`**, not the seeder; **activity-log messages verbatim** from source.

**TcList = 12 sections** (§1 Feature Info incl. Tab Group · §2 Pre-conditions · §3 Test Data Strategy/Default Data Load · §4 Business Conditions with `Covered By` on every BC table + §4.2 Indexes BC-IDX + §4.3 FK BC-REF · §5 TC List with V2-Test + Status columns · §6 step-by-step per TC · §7 V2 Test-Method Index · §8 Coverage Summary · §9 Route Reference · §10 Dev Issues (DEV-###) · §11 Known Issues · §12 Execution Status).

### 3.2 Agent B — `testcase-scripter`  (URGENT — build first)

**Input (PRIMARY):** approved TcList from `Doc_Analysis/4-TC_List_Requirement_Review/{Module}/TC_List/` (folder now canonical). File-name suffix still varies → glob `*_TcList.md` | `*_TC_List.md`.
**Also reads:** `module_list.md` (identity/prefix), DDL from `2-DDL_Tenant_Consolidated/{DDL_FILE_NAME}*.sql`, real source under `prime_ai/Modules/{FOLDER_NAME}` (Model→Controller→FormRequest→Routes→Policy→Views→Service — DDL-first for schema facts), the gold sample once, and `05_/05a_` Rule Card.
**Workflow:**
1. Resolve module from `module_list.md` (STOP-and-ask if absent).
2. Parse the approved TcList → the authoritative TC set (IDs, scope, steps).
3. Re-verify each referenced fact against live source (selectors, routes, permission strings, activity-log messages, columns). Divergence → `DEV-###` (never silently trust one side).
4. Emit the V2 `.php` (write-first for crash-resilience) implementing **every** TC; obey the 48-rule Rule Card.
5. Annotate the TcList `Covered By` columns + §7 method index + §8 coverage; §12 execution status = Pending.
6. **Dual-source gate:** if any TC in the list has no method (or any method has no TC), FAIL and report the delta. `php -l` clean.
**Output (2 files):** `{PREFIX}{Feature}V{N}_TestCas.php` + updated `{PREFIX}{Feature}_TcList.md`, in the tab-nested folder.
**Does NOT execute tests** unless `execute=true`; records prerequisites (module enabled in `modules_statuses.json`, `APP_ENV=testing`).

### 3.3 Agent A — `tclist-author`  (FUTURE — build second)

**Input:** `Doc_Analysis/4-TC_List_Requirement_Review/{Module}/Module_Requirement/{…}_Requirement.md` (canonical — ALWAYS `Module_Requirement`, no `Requirement_Docs` fallback) + DDL + real source.
**Read order:** **DDL first** (absolute source of truth) → Model → Controller → FormRequest → Routes → Policy/Permission seeder → Views → Service → Requirement.
**Workflow:** decompose into BCs (BC-DB/IDX/REF/VAL/AUTH/BIZ/SM/INT) → enumerate TCs scoped **strictly to the screen** (this is where "no unnecessary tests" is enforced — scope to the actual controller methods/routes/DDL, not speculative features) → write the 12-section TcList with empty `Covered By` (filled later by Agent B) and §12 Pending.
**Output (1 file):** `{PREFIX}{Feature}_TcList.md` for human review. Existing reviewed TcList present → produce a diff/enhancement, never blind-overwrite.

### 3.4 Build phases

| Phase | Deliverable | Notes |
|-------|-------------|-------|
| **P1 ✅ DONE (2026-07-24)** | `1-TC_Creation/07_TestCase_Scripter_Agent_Prompt.md` + `~/.claude/agents/testcase-scripter/AGENT.md` loader | Encodes §3.1 contracts + dual-source gate; references 00_/05_/05a_/module_list (incl. `REVIEW_FOLDER`). Role prompt relocated to `…/TestCase_Agent_Refinement/1-TC_Creation/` (2026-07-24); loader repointed. |
| **P3 ✅ DONE (2026-07-24)** | `1-TC_Creation/08_TcList_Author_Agent_Prompt.md` + `~/.claude/agents/tclist-author/AGENT.md` loader | 12-section TcList contract (matches gold `RecommendationMode` TcList); DDL-first; scope-strict; `Covered By` left empty for Stage B. Role prompt relocated to `…/TestCase_Agent_Refinement/1-TC_Creation/` (2026-07-24); loader repointed. *(Prompt numbered 08, not 06.)* |
| **P2 — NEXT** | **Pilot the pipeline on 1–2 modules that have reviewed TcLists but are NOT Recommendation** (e.g. LmsExam `ExamType`, Accounting `Ledger`): run `testcase-scripter` on the existing reviewed TcList → V2 `.php`. | Compare against the Recommendation gold sample for structural/idiom parity. Do NOT pilot on Recommendation (that's the reference). Optionally also run `tclist-author` on the same screen and diff its TcList vs the human-reviewed one. |
| **P4** | One-time input normalization pass (TcList **file** suffix `_TcList`/`_TC_List`) + confirm `module_list.md` REVIEW_FOLDER/prefixes across all modules. Also decide Dropdown: keep `dd_` override vs add a `DropDown` registry row. | Folders already normalized (`Module_Requirement/`, `TC_List/`); agents still glob the file suffix defensively regardless. |
| **P5** | A/B comparison rubric doc (old `testcase-creator` single-pass vs new author→scripter pipeline) on the pilot modules. | Lets the owner pick the standard on evidence. |

### Deliverables built so far (P1 + P3)
Three agents now coexist for comparison, all sharing the `00_/05_/05a_` constraint files + `module_list.md`:
- `testcase-creator` (existing, UNCHANGED) — single-pass 5-artifact baseline.
- `tclist-author` (NEW, Stage A) — Requirement+DDL+source → 12-section reviewable TcList (`08_`).
- `testcase-scripter` (NEW, Stage B) — approved TcList → V2 Dusk `.php` + Covered-By annotation (`07_`).
> New agents are picked up at the START of a Claude session (loaders scanned then). Use a fresh session to invoke `tclist-author` / `testcase-scripter`.

### 3.5 Acceptance criteria (per generated screen)
- 2 files only, correct names/prefix (from `module_list.md`), correct tab-nested folder, flat module namespace, class=filename.
- Coverage checklist met (3 schema + ≥16 pos + ≥12 neg + ≥4 dep); every approved TC ↔ ≥1 method (dual-source gate green).
- `php -l` clean; selectors/routes/permissions/activity-log strings all traced to live source; ENUMs from DDL; 403 uses fresh non-super-admin + `forgetCachedPermissions()`; cleanup in FK order.
- TcList `Covered By` fully populated; §7/§8 present; DEV-### raised for any layer divergence.

---

## 4. Open items — RESOLVED (2026-07-24)

### Item 1 — Namespace vs folder nesting → **RESOLVED: flat namespace at module level, folder nested by tab group**
**Decision (unchanged by the 2026-07-24 space removal):** `namespace Tests\Browser\Modules\{FOLDER_NAME};` (flat) regardless of how deep the folder is nested; `class {PREFIX}{Feature}V{N}_TestCas` (= filename); file placed at `…/Modules/{FOLDER_NAME}/{TabGroup}/{Feature}/` (PascalCase, no spaces).
**Why (evidence):**
- The **verified gold sample keeps a flat namespace** (`Tests\Browser\Modules\Recommendation`) — confirmed still flat after the owner removed folder spaces on 2026-07-24. We match the gold sample.
- Folders are now space-free (`RecommendationMasters/…`), so a nested namespace is *technically* possible; we still choose **flat** for gold-sample parity and simplicity. (The repo has both historical patterns: Recommendation = flat; Hostel/Inventory/Vendor = nested. We standardize on flat.)
- Dusk/PHPUnit discovers Browser tests by **directory scan + `require` (by path)**, not by PSR-4 FQN resolution (autoload is only `Tests\ => tests/`, no root `phpunit*.xml` maps subfolders). So a flat namespace with a nested path loads fine; the only requirement is a **globally unique class name**, which `{PREFIX}{Feature}V{N}` guarantees (Feature unique within a module; prefix from `module_list.md`).
**Agent rule:** never build the namespace from the folder path; always `Tests\Browser\Modules\{FOLDER_NAME}`. Feature/tab-group folder names are PascalCase & space-free. Assert class-name uniqueness before writing.

### Item 2 — Legacy `lms_rec_*` sample files → **RESOLVED: leave as-is; new files use `module_list.md` PREFIX; version-detect by FEATURE glob**
**Decision:** Do **not** rename the existing verified `lms_rec_*` reference files (they are the approved gold reference; renaming risks breaking references for zero functional gain, and Recommendation is a *reference* module, not a generation target). All **newly generated** files use the `module_list.md` PREFIX (`rec_*`, `lms_*`, `qns_*`).
**Required guard (prevents a real bug):** the generator's V1/V2 detection must glob by **feature**, not just by the new prefix — `*{Feature}*_TestCas.php` in the target folder — so it recognizes an existing `lms_rec_RecommendationModeV2_TestCas.php` and does not create a duplicate `rec_RecommendationModeV1`. If any prior version exists under any prefix → next file is `V{max+1}`.

### Item 3 — `Z-Support_Docs` → **RESOLVED: reference-only, and ONLY for Agent A (author); NEVER an input to Agent B (generator)**
**What they are:** team **code-review checklists** (`Gaurav_list.md`, `Shailesh_list.md`, `Category_List.md`) + `Prime_Routes_Policy_Permission_Test_Checklist(_Simple).md`. They are cross-cutting quality checklists, not per-screen test specs.
**Decision:**
- **Agent B (generator): must NOT read these.** Pulling extra tests from a global checklist is exactly the over-generation behaviour that caused the original complaint. Agent B implements the approved TcList and nothing else.
- **Agent A (author): may consult them at TcList-authoring time** (pre-review) as a completeness aid to ensure BC-AUTH / BC-R / route-model-binding-404 / tenancy-middleware coverage is considered — but any resulting TC still lands in the TcList and passes human review before it can become a test. So the human gate still governs scope.

### Item 4 — Report/dashboard screens → **RESOLVED: keep the "lighter render-focused subset" rule (confirmed needed)**
**Evidence:** the reviewed inputs contain many read-only screens — Cafeteria `DailySalesReport`/`MealAttendanceReport`/`StockConsumptionReport`/`MealCardLedgerReport`, LmsQuests `Dashboard`/`Summary`/`Activity-Log`, Exam `Dashboard`/`ExamSummary`/`HWPerformanceAnalysis`/`LMSActivityDashboard`, SystemConfig `ActivityLog`.
**Decision:** for report/dashboard/summary/activity-log screens the agents emit a **lighter subset** — render, filters, date-range, export/print, permissions (403/guest), empty-state, pagination — and **omit** the create/edit/delete/soft-delete/toggle CRUD matrix (there is no CRUD). The TcList §5 for such a screen is scoped accordingly, and Agent B honors whatever the approved TcList contains (a read-only TcList simply has no CRUD TCs to implement).

### Item-A (input-folder spellings) → **RESOLVED — folders normalized (owner, 2026-07-24)**
- **Requirement folder = `Module_Requirement/` ALWAYS** — verified: all 31 modules use it, **zero** stale `Requirement_Docs/` remain. File suffix: uniform `*_Requirement.md` (479 files). No glob needed.
- **TcList folder = `TC_List/` ALWAYS** — verified: all 30 modules use it, **zero** `TC_Lists/` remain.
- **Only remaining variance = the TcList FILE-name suffix:** `*_TcList.md` (333) vs `*_TC_List.md` (109). Agents must still glob at the **file** level (`*_TcList.md` | `*_TC_List.md`); the containing folder is always `TC_List/`. (Optional P4: normalize the file suffix too; agents glob regardless.)
- **Module-identity check (2026-07-24):** `Studentprofile` → renamed to **`StudentProfile`** = exact match to `module_list.md` (MODULE_NAME/FOLDER_NAME `StudentProfile`). ✅ RESOLVED. `"Addmission Management"` → renamed to `AddmissionManagement` (space removed) but **still does not match the registry** (registry: MODULE_NAME `Admission Mgmt.`, CODE `ADM`, FOLDER_NAME `Admission`) and retains the double-d typo. **Action:** rename input folder to **`Admission`** (= FOLDER_NAME, also the app `Modules/Admission` dir).
- **Design rule — review-folder name ≠ registry identity (general):** several input folders are named by business area, not the registry: `Exam`→`LmsExam`, `Homework`→`LmsHomework`, `Dropdown`→(GlobalMaster/Prime), `AddmissionManagement`→`Admission`. Therefore an agent **must NOT** assume the `4-TC_List_Requirement_Review/{X}/` folder name equals MODULE_NAME/FOLDER_NAME. Resolution contract: the caller supplies a `module_list.md` MODULE_NAME (or CODE); the agent resolves the 5 identity fields from the registry, then locates the review-input folder by an explicit **alias map** (registry ⇄ review-folder). Add this alias map to `module_list.md` (a new `REVIEW_FOLDER` column) or as a small side-table the agents read — pick one before P1 so both agents share it.

---

*Plan location: `3-Testing_Audit/Testing_Prompt/TestCase_Agent_Refinement/Enhancement_v2/00_Agent_Rebuild_Plan_v2.md`. Companion team drafts in the same folder: `TC_Creation_Process.md` (existing-agent behaviour), `GAP_Analysis_TC_Creation_Process.md` (gap list), `Test_Rules_v1.md`.*

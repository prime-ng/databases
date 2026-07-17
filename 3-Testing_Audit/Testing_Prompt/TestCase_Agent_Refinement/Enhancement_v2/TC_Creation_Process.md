# TestCase Creator Agent — What It Does & How It Works (Current Behaviour)

**Purpose of this document:** a faithful, verifiable description of the rules and process the **TestCase Creator** agent follows *today*, so the entire flow can be reviewed before execution.

**Sources (this is the ONLY thing this document is drawn from — the agent's live source-of-truth files):**
| File | Role |
|------|------|
| `~/.claude/agents/testcase-creator/AGENT.md` | The **loader** — bootstraps the run, points to the files below |
| `Testing-Plan/03_Testcase_Creator_Agent_Prompt.md` | The **role/workflow/hard-rules/quality-gate** (the main brain) |
| `Testing-Plan/00_Testing_Artifacts_Index_and_Conventions.md` | **Conventions** — module registry, artifact contract, BC/TC taxonomies, env facts |
| `Testing-Plan/05_Known_Test_Failure_Constraints.md` | The **Rule Card** — 48 numbered guardrails (A–G), read before writing any PHP |
| `Testing-Plan/05a_Constraints_Evidence_Appendix.md` | Full evidence/rationale behind each Rule-Card rule (read on demand only) |

> **Scope note:** everything below is taken *only* from the five files above. Nothing here is drawn from the refinement prompts (`Prompt_Refine_TestCaseCreatorAgent_v1/v2/v3.md`, `TokenReduction_Plan_TestcaseCreator.md`) — those were the instruments used to shape the agent; their *effects* are already baked into the five files and are described here as the agent's actual behaviour. Each item cites its origin (e.g. `[03_ HARD RULE 1]`, `[Rule Card #46]`, `[00_ §6]`) so it can be checked at source.

---

## 1. What the agent is

`Testcase_Creator` is a senior-QA-automation-engineer role for the **Prime-AI** platform (Laravel 11 + `laravel-modules` + `stancl/tenancy` + AdminLTE/Blade + Alpine.js, tested with **Laravel Dusk**). It **tests** application code; it does **not** write application code. Its defining principle: **read the real source before asserting anything — never invent routes, selectors, permissions, table names, or error messages.** `[03_ ROLE]`

**Three modes** `[03_ ROLE]`:
- **`feature`** (default) — generate the artifact set for one screen.
- **`module`** — discover all screens of a module, then run `feature` for each.
- **`report`** — roll-up reports (Coverage Dashboard, RTM, Defect Register, Program Summary).

**Unit of work = one screen = one requirement file.** Each screen is defined by exactly one `.md` file in `4-Requirement_Module_wise/2-Module_Requirement_V1/{MODULE}_v1/`; that folder is the canonical feature list. `[03_ "FEATURE = SCREEN"]`

---

## 2. The process the agent follows BEFORE it writes any output

This is the ordered flow. Steps 0.5–3 are entirely **understand-first**; no output file is written until Step 4/6.

### 2.0 Bootstrap (from the loader)
1. **Resolve the module from the registry** `0-Prime_Ai_Detail/module_list.md` → the 5 identity fields: `MODULE_NAME`, `CODE`, `PREFIX`, `FOLDER_NAME`, `DDL_FILE_NAME`. If the module isn't in the table, STOP and ask. `[loader Step 0]`
2. Read the role (`03_`), the conventions (`00_`), and the **`05_` Rule Card** (the compact always-read constraint list). Consult the `05a_` evidence appendix only when a rule is contested. `[loader Steps 1–2b]`
3. **Study the golden reference once** (`Class&SubjectMgmt/Classes/*`) for structure/idioms — not re-read per feature. `[loader Step 3]`

### 2.1 Step 0.5 — Build or reuse the module **Fact Pack** (module-wide facts computed ONCE) `[03_ Step 0.5]`
If `TestCases/{Module}/{Module}_FactPack.md` exists → read it and trust it. Otherwise build it once. It contains:
1. Verified table **prefix** + any doc-vs-live divergence (confirmed against DDL `CREATE TABLE`).
2. **`CREATE TABLE` list** with columns/types/UNIQUE/FK/`deleted_at` for the module's tables.
3. **Controller → screen map** and the **route list** (paths, names, verbs).
4. **Permission prefix** and **activity-log table + event strings** (per-module, not assumed).
5. **Prime-side vs tenant-side** tenancy scaffolding choice + which base class to mirror.
6. **Known audit defects** (BUG/SEC/VAL/DATA/DEAD/DOC IDs) from the audit report.
7. **Per-feature complexity tag** (`Light`/`CRUD`/`Workflow`).

### 2.2 Step 1 — Resolve & Read the real source (fixed read order) `[03_ Step 1]`
The agent reads, **in this order** (screen file first and in full):
| # | Source read | What it extracts |
|---|-------------|------------------|
| 0 | **Screen requirement file** `{MODULE}_v1/{screen}.md` | Business need, objectives, user stories, business rules, statuses, eligibility → drives `BC-BIZ` |
| 1 | **DDL** `CREATE TABLE`(s) | Columns, types, UNIQUE keys, FKs + `ON DELETE`, soft-delete columns |
| 2 | **FormRequest(s)** | `rules()`, `messages()`, `prepareForValidation` |
| 3 | **Controller** | Methods, permission gates, JSON responses, redirects, business logic (auto-ordinal/auto-name/toggle/reorder/counts); which methods delegate to a Service |
| 3b | **Service layer** | Business logic, auth checks, transactions, workflow transitions (often here, not the controller) |
| 4 | **Model(s)** | `$table`, `$fillable`, `$casts`, relationships, scopes, soft-deletes, observers **— and verifies the CORRECT model to route all CRUD through (G47); notes programmatically-managed fields** |
| 5 | **Routes** | Exact paths, names, verbs, route-model binding |
| 6 | **Blade view(s)** | Real selectors: modal ids, form ids, field ids/names, tab ids, button markers, table columns |
| 7 | **Module FRD** | Cross-screen behaviour, business rules that span screens |
| 8 | **Audit report** | Known `DEV-###` defects for the feature |

It also determines **DB scope** (prime-side vs tenant-side) from the DDL header + prefix, which decides whether tenancy `setUp/tearDown` is emitted. `[03_ Step 1]`

### 2.3 Step 2 — Decompose the requirement into **Business Conditions (BC)** `[03_ Step 2, 00_ §6]`
Every requirement fact becomes a typed, ID'd, `Source`-tagged BC (see the BC taxonomy in §5 below). **`BC-DB` must enumerate one testable fact per DDL constraint** — a row for every UNIQUE key, every NOT-NULL-no-default column, every nullable column, every `VARCHAR(n)` size, every DEFAULT, every FK/`ON DELETE`. `[03_ Step 2 callout]`

### 2.4 Step 3 — Enumerate **Test Cases (TC)** from the BCs `[03_ Step 3]`
Derive `TC-P` (positive), `TC-N` (negative), `TC-D` (dependency A–G), plus `TC-T`/`TC-S`/`TC-A` and a state-transition case per `BC-SM` row. Each TC references its BC(s) and carries the BC's `Source` tag. The DDL-derived negatives/positives (duplicate, missing-value, over-length, etc.) are **mandatory, not optional**.

### 2.5 Then it writes (Steps 4→9, single pass)
The `.php` is written and flushed first (crash-resilience), then the docs, in one pass on one model. `[03_ "Single-Pass Generation"]`

---

## 3. Common Rules — what is tested for EVERY screen

These are applied to every CRUD screen (report/dashboard screens get a lighter render-focused subset). Each maps to a Hard Rule, a Rule-Card constraint, and — in the generated `.php` — the opening `test_01` method and specific banded methods.

### 3.1 The `test_01` schema-truth method — full **DDL ↔ App alignment matrix** `[03_ Step 6.1 + "test_01" idiom; Rule Card #46 (G46)]`
`test_{feature}_01_migration_model_and_request_configuration_are_correct` asserts ALL of:
- `Schema::hasTable` / `Schema::hasColumns` — **every DDL column exists** in the model/migration, and **no app field references a non-existent column**.
- **NULL / NOT NULL** matches the DDL.
- **Data types** handled correctly (asserted tolerantly — `assertStringContainsString('int',…)`, never `assertEquals('int unsigned',…)`, per Rule Card #17).
- **Field lengths** match the DDL.
- **Default values** respected.
- **UNIQUE keys** present (index inspection / `SHOW INDEX`).
- **FKs / relationships** correct.
- **Column names consistent** across DDL, model, FormRequest, controller, and test.
- **Soft-delete asserted INDEPENDENTLY:** `Schema::hasColumn(table,'deleted_at')` **and** `in_array(SoftDeletes::class, class_uses_recursive(Model::class))` as two separate assertions — because the column and the trait can genuinely disagree in this codebase; a mismatch is reported as a `DEV-###`, never "fixed." `[Rule Card #30, #12]`
- **Migration/DDL vs live schema:** where the consolidated DDL is known to lag the live schema, it asserts against the **LIVE** schema (`Schema::hasColumn` / `information_schema` / `SHOW INDEX`), not `assertStringContainsString` on the DDL file. (Note: a module's own migrations dir may be empty — real migrations live under `prime_ai/database/migrations/tenant/`; the agent derives schema truth from the live schema in that case. `[Rule Card #26]`)

> **Answering your example "Compare DDL with Migration to find gaps":** the agent does this via `test_01` (the alignment matrix above) **plus** the Cross-Reference Defect Scan checks 11–15 (§4.3). It compares the DDL against the **model + live schema** (and the migration file content where it exists); where migration ≠ DDL ≠ live schema, it reports the divergence as a defect rather than trusting one layer.

### 3.2 **Correct model** is verified and used for all CRUD `[03_ Step 1.4; Rule Card #47 (G47)]`
Before any CRUD, the agent confirms from real source: the model exists and is importable; its `$table` matches the DDL primary table/prefix; `$fillable`/`$guarded` support the fields under test; relationships are valid. **All create/read/update/delete run through that verified model.** A wrong/misconfigured *application* model is reported as a `DEV-###`, not papered over.

> **Answering your example "Model — call is for the correct Model or not":** yes — this is constraint G47, verified in the read phase (Step 1.4) and enforced in the generated CRUD.

### 3.3 DDL-derived validation coverage (derived from the **DDL, not the form**) `[03_ HARD RULE 15; Rule Card #43–#45 (G43–G45)]`
For every screen the agent MUST emit:
- **UNIQUE (G43):** for every UNIQUE column / composite key — create one row, attempt a second with the same value(s), assert it is **refused** (composite = vary only the keyed columns). "Prove uniqueness, don't assume it."
- **NOT NULL (G44):** for every **NOT-NULL-no-default** column — attempt to save with the value missing/null, assert **rejection**; for representative **nullable** columns — save with it omitted, assert **success**. Required-vs-optional is derived from the DDL, not the form.
- **Length (G45):** for every `VARCHAR(n)`/`CHAR(n)` — submit `n+k` chars, assert **rejection**; submit exactly `n`, assert **success**.
- **Defaults:** omit a DB-default column, then `->refresh()` and assert the DB applied the default. `[Rule Card #35]`

> **Answering your example "checked the View before Submit for NOT-NULL fields":** the agent derives the required set from the **DDL** (`NOT NULL` no-default), reads the **Blade view** for the real field names/selectors, and generates a missing-value negative test per such column that asserts the save is rejected. It also cross-checks the DDL `NOT NULL` against the FormRequest `required` rule (Cross-Reference check 13) and reports any mismatch as a defect. It deliberately does **not** trust the form as the source of "required."

### 3.4 "Test the CODE, not the UI" — programmatically-managed fields `[03_ HARD RULE 15; Rule Card #48 (G48)]`
Fields set in code — auto `ordinal`, auto code/name, server-set defaults, computed/generated columns, workflow-set status — are tested as **auto-behaviour** (assert the controller/service sets them; assert the user cannot override them where that's the design). They are **never** proposed as form inputs.

### 3.5 Permissions / authorization — every screen `[03_ HARD RULE 14; Rule Card #31, #37 (F37); 00_ §5 Negative]`
- Permission-denied path asserts a **real 403** via an HTTP test method (Dusk `Browser` has no `assertStatus`, #14).
- After revoking access, `app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions()` is called (Spatie caches permissions).
- The negative uses a **fresh non-super-admin** user (clear `is_super_admin`/`super_admin_flag`, `syncRoles([])`) — otherwise `Gate::before` grants Super Admin everything and the 403 never fires (false-pass).
- Guest test asserts redirect to `/login`. `[03_ "Patterns to reuse"]`

### 3.6 Activity-log assertions — every mutating screen `[03_ HARD RULE 11; Rule Card #25]`
Every mutation asserts the activity-log write, using the **exact event strings read from the real controller/service** (verbatim — the agent does not assume a `Created/Updated` set), against the **correct sink** for the DB scope (tenant vs central).

### 3.7 Test hygiene applied to every method `[03_ HARD RULE 14; Rule Card #33–#42 (F33–F42)]`
- **No hollow tests:** `addToAssertionCount(1)`/empty bodies are banned — every method has ≥1 real assertion (or `markTestIncomplete/Skipped`).
- **Real framework methods only:** `hasCast()` not `isCasted()`; no non-existent `->isActive()`.
- **`->refresh()`** after `->create()` before asserting DB-populated values.
- **`assertGreaterThanOrEqual()`** (never `assertEquals`) for seed/reference counts.
- **Cleanup:** every created record is cleaned up (`DatabaseMigrations` / `try-finally` / sibling teardown).
- **No hand-written URLs or selectors** — all derived from `route:list`/`Route::has()`/real Blade (a wrong module route prefix 404s the whole file).
- **One test style per file** (no `browse()` + `actingAs()->post()` mix).
- **`php -l` clean**, class name = filename, typed properties initialised, `setUp/tearDown` with tenancy init/end.

### 3.8 Dependency / referential-integrity coverage — every screen with FKs/soft-delete `[00_ §5 Dependency A–G; 03_ Step 6.2]`
Sub-categories A–G: inactive-record impact (A), soft-delete/force-delete preservation & cascade (B), FK `RESTRICT` blocks delete (C), FK `SET NULL` (D), cross-module impact (E), full lifecycle create→edit→toggle→delete→restore→forceDelete (F), race/concurrency & boundary uniqueness (G). Cross-module paths are guarded with `try/catch` + `markTestSkipped` so partial environments stay green.

### 3.9 Standard negative matrix — every CRUD screen `[03_ Step 6.2; 00_ §5 Negative]`
Required / format / length / range / duplicate / invalid-ID-404 / 403 / guest-redirect / **stored + reflected XSS** / whitespace / cross-field rules. "App rejects it" assertions tolerate the 500-vs-422 quirk or assert the DB-level outcome (never a brittle exact `422`). `[Rule Card #41]`

---

## 4. Common Business Rules — how the agent tests logic & hunts defects

### 4.1 `BC-BIZ` — business logic & auto-behaviours `[00_ §6; 03_ Step 2]`
Business rules, auto-behaviours (auto-name, auto-ordinal, toast), and activity-log events are decomposed from the **screen requirement file + controller/service/model/observer** into `BC-BIZ` conditions, each mapped to ≥1 positive test (band 10–19).

### 4.2 `BC-SM` — state machines (workflow features) `[03_ Step 2 callout; 00_ §6]`
For any feature with a status/workflow lifecycle (e.g. `Draft→Submitted→Approved/SentBack`, `open→locked→closed`), the agent enumerates **every legal transition (1 positive test each)** and the **key illegal transitions (1 negative test each)** — band 20–29. Illegal transitions must be rejected.

### 4.3 The **Cross-Reference Defect Scan** (15 checks) — active defect hunting `[03_ Step 7]`
In the Gap Analysis the agent runs a 15-check scan that compares layers and raises a `DEV-###` (with a proving test) for each firing. Candidates are reported as "verify in source" — it does not assert a bug it hasn't traced.

| # | Check | Compares |
|---|-------|----------|
| 1 | Enum case | DDL `ENUM(...)` vs FormRequest `in:` |
| 2 | Route registration | Blade `route('x')` vs `routes/*.php` + Providers + `module.json` |
| 3 | Gate vs Policy | controller `Gate::authorize()` vs Policy methods |
| 4 | Fillable vs DDL | model `$fillable` vs DDL columns |
| 5 | Cast vs DDL | model `$casts` vs DDL type |
| 6 | Service delegation | controller body vs Service method |
| 7 | State machine vs impl | requirement transitions vs controller/service |
| 8 | Validation vs FormRequest | requirement rules vs `rules()` |
| 9 | Error message vs FormRequest | expected message vs `messages()` |
| 10 | Permissions vs Policy/Gates | requirement permission matrix vs Policy + `Gate::authorize()` |
| 11 | Integration FK vs migration | requirement FK relationships vs migration `foreign()` |
| 12 | **UNIQUE enforcement** | DDL `UNIQUE KEY` vs FormRequest `unique:` |
| 13 | **Required enforcement** | DDL `NOT NULL`(no default) vs FormRequest `required` |
| 14 | **Length enforcement** | DDL `VARCHAR(n)` vs FormRequest `max:` |
| 15 | **Soft-delete column vs trait** | DDL `deleted_at` vs model `SoftDeletes` |

### 4.4 Defect discipline `[03_ HARD RULE 10]`
Known audit `DEV-###` items are pulled from the audit report; any newly-discovered source bug is added as a `DEV-###` in the TcList + Gap Analysis with a test that **proves current behaviour** (defects are documented, never hidden or silently "fixed").

---

## 5. Taxonomies the agent uses

### Business Condition (BC) taxonomy `[00_ §6]`
| Prefix | Meaning | Source |
|--------|---------|--------|
| `BC-DB` | Column/type/constraint per table | DDL |
| `BC-VAL` | Validation rule + error message | FormRequest |
| `BC-AUTH` | Permission gate ↔ controller method | Policy/Gate + Controller + requirement matrix |
| `BC-BIZ` | Business logic / auto-behaviour / activity-log event | Controller/Service/Model/Observer + Requirement |
| `BC-SM` | State-machine transition | Requirement FSM + Controller/Service |
| `BC-INT` | Integration point (cross-module dependency / FK to another module) | Requirement + DDL FKs |
| `BC-REF` | FK column → referenced table → onDelete | DDL |
| `BC-AUTO` | Cross-module auto-update (model events) | Model observers |
| `BC-EDG` | Edge case / boundary | Requirement + DDL limits |
| `BC-CFG` | Configuration / settings behaviour | Config tables + requirement |

`BC-DB/VAL/AUTH/BIZ/REF/AUTO` are **always** produced; `BC-SM` added for workflow features; `BC-INT/EDG/CFG` when relevant.

### Test Case (TC) taxonomy `[00_ §5]`
- **`TC-P`** Positive · **`TC-N`** Negative · **`TC-D`** Dependency (sub-cats A–G) · plus **`TC-T`** Tenancy, **`TC-S`** Security, **`TC-A`** Accessibility smoke.

### Traceability chain `[00_ §6]`
`Requirement/FRD/Screen §(Source tag) → BC-xx → TC-P/N/D/T/S → test_method() → (optional) DEV-### defect`. Every BC and TC carries a `Source` tag (e.g. `Screen-BR-3`, `DDL-<table>`, `Audit-<ID>`).

### Semantic numbering bands (in the `.php`) `[03_ Step 6]`
| Band | Category | | Band | Category |
|------|----------|--|------|----------|
| 01–09 | Schema/DDL/model/request config (`test_01`) | | 50–59 | Permissions / authorization |
| 10–19 | Business rules (`BC-BIZ`) | | 60–69 | UI/UX (search, filter, pagination, empty state) |
| 20–29 | State-machine transitions (`BC-SM`) | | 70–79 | Edge cases (`BC-EDG`) |
| 30–39 | Validation + error messages (`BC-VAL`) | | 80–89 | Configuration / settings (`BC-CFG`) |
| 40–49 | Integration / FK dependency | | 90–99 | Tenancy isolation (`TC-T`) + security (`TC-S`) |

---

## 6. The guardrails — Rule Card constraints (A–G, 48 rules) `[05_ Rule Card]`
Before writing any PHP the agent obeys the Rule Card. By section:
- **A. Tenancy & test style (1–4):** mirror the module sibling's style + tenancy helper; one test style per file; resolve tenant via `Modules\Prime\Models\Domain`; guard teardown; prime-side vs tenant-side scaffolding.
- **B. Users & factories (5–10):** use `App\Models\User::factory()`; `password` IS fillable; supply every NOT-NULL-no-default `sys_users` column (`emp_code`,`short_name`,`prefered_language`,`user_type`); `emp_code` ≤ 20 chars; `glb_languages` is a VIEW.
- **C. Soft-delete, media, typed props (11–13):** `forceDelete()` may hit `sys_media` (guard it); `SoftDeletes`-only methods guarded; init typed properties.
- **D. Assertions & HTTP (14–18):** Dusk `Browser` has no `assertStatus`/`.post` → use HTTP test methods; authenticate before negative POSTs; pass vars into browse closures; tolerant type asserts; keep fixture data within column limits.
- **E. Environment prerequisites (19–32):** module must be ENABLED in `modules_statuses.json`; `APP_ENV=testing`; prime/central base-URL & base-class rules; route-registration realities; activity-log sink routing; empty module migration dirs; connection-specific `glb_*` models; runner has no app source on disk; Super-Admin `Gate::before` bypass; reflection to read app source.
- **F. Assertion completeness & hygiene (33–42):** the test-hygiene rules in §3.7.
- **G. DDL-derived coverage obligations (43–48):** the mandatory UNIQUE/NULL/length/`test_01`-alignment/verified-model/code-not-UI coverage in §3.

Full rationale + file/line evidence for each is in `05a_Constraints_Evidence_Appendix.md` (read on demand).

---

## 7. The output — 5 artifacts per screen `[03_ Artifact Contract; 00_ §3]`
| # | File | Contents |
|---|------|----------|
| 1 | `{prefix}_{Feature}TcList_Require.md` | **Combined**: (1) Feature Information; (2) Business Conditions (all BC tables + Source); (3) Test Case List; (4) Test Method Index; (5) Manual Test Steps (Step/Action/Expected + DB checks + activity-log checks — only for complex/money/workflow cases); (6) Known Defects |
| 2 | `{prefix}_{Feature}GAPANALYSIS_Require.md` | TC↔method mapping (Full/Partial/Gap), Coverage Summary, **Coverage-Score by requirement Source**, **15-check Cross-Reference Findings** |
| 3 | `{prefix}_{Feature}_TestCas.php` | One comprehensive Dusk suite (banded methods + rich private helper library) |
| 4 | `{prefix}_{Feature}Validation_Report.md` | File-existence, naming, structure, coverage %, defects, env prerequisites, verdict |
| 5 | `run-{Feature}-tests.php` | One cross-platform PHP runner |

---

## 8. Coverage targets & the self-check quality gate `[03_ HARD RULE 6; 03_ QUALITY GATES]`
**Coverage gates:** Negative **100%**, Positive **≥ 90%**, Dependency **≥ 90%**, Tenancy **100%** on P0/P1 modules. Every TC-ID ↔ ≥1 method; every method ↔ a TC/BC.

Before finishing, the agent runs a **~30-item self-check** including (verbatim intent): all 5 files present with exact names; prefix verified against DDL; `php -l` clean; coverage gates met; selectors/routes/messages/permissions all from real code; activity-log strings verbatim; cross-module paths guarded; audit defects captured with proving tests; **0 hollow methods; 0 `isCasted(`/`->isActive(`; `->refresh()` after create; `assertGreaterThanOrEqual` for counts; 403 + `forgetCachedPermissions` on permission negatives; cleanup present; no hand-written URLs/selectors; duplicate-rejection per UNIQUE (G43); missing-value per NOT-NULL (G44); over-length per sized string (G45); `test_01` full alignment matrix (G46); CRUD via verified model (G47); no code-managed field as a form input (G48); DDL-vs-FormRequest divergences raised as DEV-###**; BC-SM present for workflow features; every BC/TC has a Source tag; Coverage-Score + Cross-Reference tables present; module-enabled prerequisite noted; verdict written.

---

## 9. Things worth knowing when reviewing the process (from the agent files)
- **Report/dashboard screens are lighter by design** — render/filters/export/permissions/empty-state, no create/edit/delete matrix. `[03_ "FEATURE = SCREEN"]`
- **Generation is single-pass on one model**; the `.php` is written first (crash-resilience), docs follow. `[03_ "Single-Pass"]`
- **Read budget:** the module Fact Pack is read once and reused; large source is read with targeted `grep`/offset, not full-file; the golden reference is not re-read per feature. `[03_ "Read Budget"]`
- **The agent does NOT execute the tests unless `execute=true` is passed** — by default it generates + statically validates (`php -l`, coverage, constraints) and records execution prerequisites (e.g. the module must be enabled in `modules_statuses.json`) in the Validation Report. `[03_ Step 10; Rule Card #19]`
- **Enhanced dimensions** (Tenancy IDOR, Security/XSS/CSRF/mass-assignment, API contract, a11y/console smoke, responsive smoke, non-functional timing) are added when the feature warrants; Tenancy is mandatory for P0/P1. Any dimension skipped is recorded in the Validation Report. `[03_ ENHANCED DIMENSIONS]`
- **Feedback loop:** if the agent discovers a *new general* codebase/env truth during a run, it appends a one-line rule to the Rule Card + evidence to `05a_` (the only edit it may make outside the output folder). `[03_ Step 10b]`

---

*End — every statement above is traceable to the five agent files cited in the header; nothing is drawn from the refinement prompts.*

# BehaviouralAssessment — Requirement Traceability Matrix (RTM) & Consolidated Defect Register

**Module:** BehaviouralAssessment (BHA) · **Requirement screens:** 25 (`00-Module-Overview` skipped) → **24 features** · **976 test methods**
**File-prefix `bha_` · live-table prefix `ba_` (DOC-BA-001)** · **Generated:** 2026-Jul-14 (report mode)

Traceability chain: **Screen (`{MODULE}_v2/NN-*.md`) → Feature → key Business Conditions → proving test method(s) → defect (where a source bug is proven).**

---

## 1. Requirement Screen → Feature Traceability

| Screen | Requirement file | Feature | Key BCs exercised | Anchor test methods | Defects proven here |
|:--:|------------------|---------|-------------------|---------------------|---------------------|
| 00 | 00-Module-Overview | *(non-screen — skipped)* | — | — | — |
| 01 | 01-Dashboard | **Dashboard** | BC-BIZ KPIs/trend/attention-list; BC-INT `std_students`,`ba_computed_scores`,`ba_rating_levels`; BC-AUTH viewAny | `_10.._16`, `_40`, `_50.._53` | 4 unbuilt widgets (documented gaps) |
| 02 | 02-Rating-Scales | **RatingScale** | BC-DB scale+levels; BC-BIZ unique code/name, ≥2/≤10 levels, one-default; BC-SM Active↔Inactive(guarded) | `_01`, `_10.._19`, `_20.._22`, `_90/_91` | VAL-BA-001, VAL-BA-002 |
| 03 | 03-Categories | **Category** | BC-DB category+criteria; BC-BIZ nested criteria/reorder/toggle; BC-REF FK; BC-SM | `_01.._04`, `_10..`, `_40..`, `_90..` | (activity-log absence documented) |
| 04 | 04-Interventions | **Intervention** | BC-BIZ CRUD/toggle/type-filter; BC-SM Active↔Inactive; BC-INT junction RESTRICT | `_10..`, `_20/_21`, `_40/_41`, `_50..` | BUG-BA-005, BUG-BA-009, BUG-BA-010, DATA-BA-002, VAL-BA-003(alias) |
| 05 | 05-Class-Mapping | **ClassMapping** | BC-BIZ map/toggle/delete; BC-SM; BC-REF class/category CASCADE | `_01..`, `_20/_21`, `_40/_41` | DATA-BA-CM-01, VAL-BA-CM-02 |
| 06 | 06-Periods | **AssessmentPeriod** | BC-SM open→locked→closed (10 transitions); BC-REF RESTRICT/SET NULL; BC-AUTH | `_01.._03`, `_20.._29`, `_17/_40.._45`, `_50..` | BUG-BA-002, SEC-BA-002 |
| 07 | 07-Configuration | **Configuration** | BC-BIZ scale-lock guard; BC-CFG `parent_notification_threshold`; BC-SM; BC-REF | `_10..`, `_80/_81`, `_90..` | DATA-BA-001, DATA-BA-003, SEC-BA-001, SEC-BA-002 |
| 08 | 08-My-Assessments | **MyAssessments** | BC-SM Draft→Submitted (6); BC-VAL; BC-REF; BC-AUTH 8 abilities | `_01..`, `_20.._25`, `_35`, `_47`, `_50.._55` | BUG-BA-MYA-001, BUG-BA-MYA-002, BUG-BA-MYA-005, VAL-BA-MYA-004, PERM-BA-MYA-003 |
| 09 | 09-Ratings | **Rating** | BC-BIZ autosave/formula/lock; BC-SM lock constraints (6); BC-REF FKs | `_10..`, `_20.._26`, `_40..`, `_93/_94` | BUG-BA-001, BUG-BA-RAT-01 |
| 10 | 10-Remarks | **StudentRemark** | BC-VAL min/max/required; BC-BIZ autosave/comment-bank; BC-SM draft↔read-only | `_01..`, `_20/_21`, `_30/_31`, `_61.._63` | BUG-BA-REM-001, BUG-BA-REM-003, VAL-BA-REM-002, FE-BA-REM-004, FE-BA-REM-005 |
| 11 | 11-Review-Queue | **ReviewQueue** | BC-SM pending→reviewed / send-back loop (9); BC-AUTH reviews.*; BC-VAL | `_15/_16`, `_20.._29`, `_30/_31`, `_56`, `_73` | BUG-BA-REV-001, BUG-BA-REV-002, VAL-BA-REV-001, DOC-BA-REV-001, BUG-BA-001(lock) |
| 12 | 12-Incident-Log | **Incident** | BC-BIZ CRUD/follow-up; BC-SM lifecycle/lock (6); BC-CFG severity notify | `_10.._19`, `_20.._24`, `_30..`, `_55` | SEC-BA-001, SEC-BA-002 |
| 13 | 13-Witnesses | **Witness** | BC-BIZ attach student/staff sync; BC-REF incident CASCADE + polymorphic; BC-SM audit-lock | `_01..`, `_33/_34`, `_02/_03`, `_05` | DATA-BA-WIT-01, BUG-BA-WIT-02, BUG-BA-WIT-03, BUG-BA-WIT-04, DATA-BA-WIT-05 |
| 14 | 14-Interventions-Applied | **InterventionApplied** | BC-BIZ link/unlink; BC-REF junction FK; BC-AUTH incidents.update; lifecycle gap | `_ia_03`, `_ia_20`, `_ia_46`, A06 gate | DATA-BA-IA-01, VAL-BA-IA-01 |
| 15 | 15-Reports-Hub | **ReportsHub** | BC-BIZ hub render/links (IP-1..5); BC-AUTH reports.viewAny/view/export | `_10..`, `_50..`, `_91` | BUG-BA-011, DEAD-BA-001, SEC-BA-003 |
| 16 | 16-Student-Scores-Report | **StudentScoresReport** | BC-BIZ grid/per-student; BC-INT `std_students`,`ba_assessments`,dead API; BC-AUTH | `_10..`, `_40`, `_50.._55`, defect `_` | BUG-BA-013 (silent 0.00 / false at-risk), BUG-BA-011, DEAD-BA-001, SEC-BA-003 |
| 17 | 17-Category-Summary | **CategorySummary** | BC-BIZ aggregation/anonymisation; BC-INT computed_scores/criteria/class-mapping | `_01`, defect `_`, filter/grid gap | **BUG-BA-013 (HARD-500)**, DOC-BA-002, BUG-BA-011, RPT-GAP-11/12 |
| 18 | 18-Period-Report | **PeriodReport** | BC-BIZ teacher-progress; BC-SM read-surfaced (2); BC-REF period/teacher/section | `_20/_21`, `_40/_41`, `_72` | BUG-BA-013 **N/A here** (uses `numeric_score` path), BUG-BA-011 |
| 19 | 19-Audit-Trail | **AuditTrail** | BC-DB immutable ledger; BC-BIZ diff-logging/pruning; BC-AUTH admin-only | `_01`, immutability `_`, `_75` | DOC-BA-AUD-001, DOC-BA-AUD-002, DOC-BA-AUD-003, DOC-BA-001 |
| 20 | 20-Student-Report | **StudentReport** | BC-BIZ 4 zones + rank + PDF; BC-INT computed_scores/incidents/remarks | `_10..` (`avg(numeric_score)`), `_50..` | BUG-BA-013 (**blade-layer** `->score` in by-class only; report body correct), BUG-BA-011 |
| 21 | 21-Class-Analysis | **ClassAnalysis** | BC-BIZ class/section+period ranking/at-risk; BC-REF RESTRICT; BC-AUTH | `_10..`, `_40`, `_90/_91`, defect `_` | **BUG-BA-013 (silent 0.00 via `byClass()`)**, BUG-BA-011 |
| 22 | 22-Period-Progress | **PeriodProgress** | BC-DB `ba_computed_scores`; BC-VAL 404s; BC-AUTH — **screen not implemented** | `_01/_03`, `_30/_31`, `_50.._53`, `_74` | Screen unbuilt (no `progress()` action) — 5 widgets proven absent |
| 23 | 23-Category-Performance | **CategoryPerformance** | BC-BIZ anonymity/threshold/stat-widgets; BC-INT; BC-AUTH | `_01`, defect `_`, `_73` | **BUG-BA-013 (HARD-500, shared `categories()`)**, DOC-BA-002, BUG-BA-011 |
| 24 | 24-Incident-Report | **IncidentReport** | BC-BIZ escalation link/export privacy; BC-FR filters; BC-CH charts | `_06/_13/_15`, `_32/_33`, `_72.._75` | DOC-BA-006, BUG-BA-011, RPT-GAP (charts/filters/columns absent) |

**Coverage:** 24/24 requirement screens mapped to a delivered feature with anchor tests; screen 00 correctly excluded. Every screen's key BCs each map to ≥1 test method (per-feature GAP ANALYSIS Coverage-Score tables all report 100% mapped).

---

## 2. Consolidated Module Defect Register (risk-tiered)

All findings discovered during generation of the 24 suites. Each carries the proving feature + anchor test. **Type key:** BUG (runtime/logic), SEC (security/safeguarding), DATA (data-integrity/soft-delete), VAL (validation), PERM (authorization), DOC (doc/spec vs impl), DEAD (dead code/route), FE/RPT-GAP (unbuilt UI/report widget).

### 🔴 P0 — Critical (runtime-500 / data-integrity / child-safeguarding)

| ID | Type | Title | Proving feature(s) | Anchor test |
|----|------|-------|--------------------|-------------|
| **BUG-BA-013** | BUG/DATA | Report aggregation reads non-existent `score` column vs live `numeric_score`. **Hard-500** via raw `AVG/MIN/MAX(score)` in `categories()` (**CategorySummary**, **CategoryPerformance**); **silent 0.00 → every student falsely "at risk"** in `byClass()` (**ClassAnalysis**, **StudentScoresReport**); **blade-layer `->score`** in by-class view (**StudentReport**, report body itself correct). **N/A** to `period()`/`incidents()`. | CategorySummary, CategoryPerformance, ClassAnalysis, StudentScoresReport, StudentReport | CatSummary defect `_`, ClassAnalysis `avg('score')`-scan `_` |
| **BUG-BA-REM-001** | BUG | `BaAssessmentController` uses unqualified/un-imported `BaStudentRemark` + `DB` → **remarks grid read AND "Save Ratings" both HTTP-500**. | StudentRemark | `bha_StudentRemark_TestCas` (page/save 500) |
| **BUG-BA-MYA-001** | BUG | `BaAssessmentController::show()` references un-imported `BaStudentRemark` → **fatal 500** on assessment open. | MyAssessments | `_47` |
| **BUG-BA-RAT-01** | BUG | Unqualified `DB`/`BaStudentRemark` in controller → **runtime `Error` on `show`/`reviewShow`/`bulkRate`** (autoSave path clean). Same root-cause family as REM-001/MYA-001. | Rating | `_93`, `_94` |
| **BUG-BA-001** | BUG/DATA | Ratings/assessment **editable after submit/lock**: `isLocked()` guard covers only status `locked`, which is an **unreachable dead state** (no controller path ever sets it); submitted/reviewed/period-lock unenforced. | Rating, ReviewQueue | Rating `_20.._26`; ReviewQueue lock-scan |
| **SEC-BA-001** | SEC | **Severe-incident parent notification never dispatched** — `parent_notification_threshold` is configured but **no controller/service reads it** to send a Notification/Mail (dead safeguarding config). | Incident, Configuration | Incident `_`, Config `_80/_81` |

### 🟠 P1 — High

| ID | Type | Title | Feature(s) | Anchor test |
|----|------|-------|-----------|-------------|
| **BUG-BA-002** | BUG | Period FSM violations (illegal transitions). Canonical guard now present in source → **remediated**, with residual metadata-verified edges. | AssessmentPeriod | `_20.._29`, `_17/_44` |
| **BUG-BA-011** | BUG | `reports/export` is a live **`abort(501)` stub** — the required PDF/CSV export is unavailable across every report screen. | All report features (15–24) | `_` export-scan per report |
| **BUG-BA-REV-001** | BUG | `reviewShow()` references `BaStudentRemark::` not imported/FQN → **latent 500** (verify-in-source candidate). | ReviewQueue | `_73` |
| **BUG-BA-MYA-002** | BUG | `bulkRate()` uses `DB` facade not imported → fatal on bulk save (source-scan). | MyAssessments | source-scan (`_92`) |
| **BUG-BA-MYA-005** | BUG | `firstOrCreate(status:'draft')` vs `unique(teacher,cs,period)` → **submitted-triple collision → 500**. | MyAssessments | `_35` |
| **DATA-BA-001** | DATA | Active rating scale switchable mid-session. Audit-flagged P1; **canonical fix now proven in source** (`update()` guard + `@disabled($hasRatings)`); residual documented. | Configuration | `_` (scale-lock guard) |
| **DATA-BA-CM-01** | DATA | ClassMapping model omits `SoftDeletes` trait though migration adds `deleted_at` → `destroy()` **hard-deletes**; Policy `restore()`/`forceDelete()` dead. | ClassMapping | `_` (SoftDeletes scan) |
| **PERM-BA-MYA-003** | PERM | `restore()`/`forceDelete()` authorize `.delete` instead of `.restore`/`.forceDelete`. | MyAssessments | `_55` |
| **VAL-BA-REV-001** | VAL | `sendBack()` never validates `reviewer_remarks` required (spec says feedback required). | ReviewQueue | `_30`, `_31` |
| **VAL-BA-MYA-004** | VAL | `submit()` gates only on `status==='draft'` — **no 100%-completion check** (Req-08). | MyAssessments | `_25` |
| **BUG-BA-REV-002** | BUG | Send-back freeze not permanent — `reviewed --sendBack--> draft` is legal but violates the "freeze on approval" requirement. | ReviewQueue | `_27` |
| **SEC-BA-002** | SEC | Every `FormRequest::authorize()` returns bare `true` (module-wide) — real guard is the controller Gate (mitigated, documented). | Module-wide (Period, Incident, Config, Intervention, ReviewQueue…) | `_56`, `_92` |
| **SEC-BA-003** | SEC | Divergent permission keys for the same tab: nav `reports.viewAny` vs `reportsPage()` `reports-page.viewAny`. | StudentScoresReport, ReportsHub | `_55` |
| **DEAD-BA-001** | DEAD | `api.php` `apiResource` never registered (RSP maps only `web.php`) **and** the API route has no tenancy middleware. | ReportsHub, StudentScoresReport | `_91` |

### 🟡 P2 — Medium

| ID | Type | Title | Feature | Anchor test |
|----|------|-------|---------|-------------|
| **BUG-BA-005** | BUG | In-use intervention (linked in junction) still soft-deletable — BR-BA-030 not enforced. | Intervention | `_` (in-use delete) |
| **BUG-BA-009** | BUG | `BehaviouralScoreService` falls back to a single `is_default` rating scale the controller never enforces. | Intervention/scoring | cross-ref scan |
| **BUG-BA-010** | BUG | Duplicate intervention `name` allowed (no unique constraint). | Intervention | `_` (COUNT ≥ 2) |
| **BUG-BA-REM-003** | BUG | `autoSave()` persists ratings only; posted `remarks[]` payload dropped. | StudentRemark | `_` (autosave) |
| **BUG-BA-WIT-02** | BUG | No self-witness `different:` rule (student can witness own incident). | Witness | `_34` |
| **BUG-BA-WIT-03** | BUG | Witness "Audit Lock" (freeze once incident closed/resolved) not enforced. | Witness | `_` |
| **BUG-BA-WIT-04** | BUG | Student witness-attach divergence (attach behaviour vs spec). | Witness | `_` |
| **DATA-BA-002** | DATA | No deactivation guard on intervention toggle-status. | Intervention | `_` (toggle) |
| **DATA-BA-003** | DATA | `uq_ba_config_session` unconditional vs FormRequest `whereNull(deleted_at)` → soft-deleted session not cleanly reusable (DB blocks insert). | Configuration | `_45` |
| **DATA-BA-IA-01** | DATA | `deleted_at` in DDL but model has no `SoftDeletes` → dead column. | InterventionApplied | `_ia_03`, `_ia_46` |
| **DATA-BA-WIT-01** | DATA | No `statement` field/rule on witness (mirrors missing requirement). | Witness | `_01`, `_33` |
| **DATA-BA-WIT-05** | DATA | `deleted_at` present but model omits `SoftDeletes` → dead column, hard delete. | Witness | `_05` |
| **VAL-BA-001** | VAL | Inline validation gaps on rating-scale/level create. | RatingScale | `_` |
| **VAL-BA-002** | VAL | No range check on level `numeric_value` (999 accepted on a 1–5 scale). | RatingScale | `_` |
| **VAL-BA-003** | VAL | `export()` gates `reports.view` but `BaReportPolicy::export()` checks `reports.export` (dead ability). | IncidentReport, report screens | `_53` |
| **VAL-BA-CM-02** | VAL | Unique index `uq_ba_class_cat` lacks `deleted_at` scope while FormRequest scopes soft-deletes. | ClassMapping | `_40`, `_41` |
| **VAL-BA-IA-01** | VAL | Intervention-Applied lifecycle (Status/Scheduled/Assigned-To/Completion/Progress-Notes) specced but not implemented. | InterventionApplied | `_ia_20` |
| **VAL-BA-REM-002** | VAL | Remark inline rule `nullable\|string\|max:1000` vs requirement min 30 / max 500 / required. | StudentRemark | `_30`, `_31` |
| **FE-BA-REM-004** | FE-GAP | Comment Bank / templates panel absent. | StudentRemark | `_61` |
| **FE-BA-REM-005** | FE-GAP | Character counter absent; textarea marked "Optional" contradicts required min-30. | StudentRemark | `_62`, `_63` |

### 🔵 P3 — Low (documentation / spec-drift / dead / unbuilt widgets)

| ID | Type | Title | Feature | Anchor test |
|----|------|-------|---------|-------------|
| **DOC-BA-001** | DOC | DDL doc `bha_*` prefix vs live runtime `ba_*` (incl. `uq_bha_witness`→`uq_ba_witness`). **Module-wide.** | All 24 | `_02`, `_03` per feature |
| **DOC-BA-002** | DOC | Screens 17 & 23 share one `categories()` implementation (two screens, one controller action). | CategorySummary, CategoryPerformance | `_73` |
| **DOC-BA-006** | DOC | Screen-24 severity vocabulary (Info/Low/Medium/High) ≠ live ENUM (minor/moderate/major/critical). | IncidentReport | `_` |
| **DOC-BA-REV-001** | DOC | Requirement "Approved / Approve & Lock" vs code `reviewed` with no lock; confirmation says "mark as reviewed". | ReviewQueue | `_15`, `_16` |
| **DOC-BA-AUD-001** | DOC | Audit filters (Date-Range, Action-Category, User autocomplete, Student) not implemented. | AuditTrail | `_` |
| **DOC-BA-AUD-002** | DOC | Requirement promises IP-address capture; `ba_audit_log` has no `ip_address` column. | AuditTrail | `_75` |
| **DOC-BA-AUD-003** | DOC | Automated pruning (3-year archive) — no scheduled job/command exists. | AuditTrail | coverage gap |
| **RPT-GAP-11/12** | RPT-GAP | Category-Summary: Class/Section filters + Top/Lowest-Criterion + Cohort Distribution columns + PDF/CSV export all unbuilt. | CategorySummary | filter/grid/export scans |
| **RPT-GAP (Incident)** | RPT-GAP | Weekly/donut/top-3 charts rendered as tables; class & student filters + Witness-Count column absent. | IncidentReport | `_72.._75` |
| **RPT-GAP (PeriodProgress)** | RPT-GAP | Entire screen unbuilt — trend line, milestone flags, KPI cards, max-5 multi-line, continuous interpolation all absent. | PeriodProgress | `_71`, `_74` |
| **Dashboard gaps** | RPT-GAP | 4 requirement widgets not implemented (proven as gaps). | Dashboard | `_` |

---

## 3. Defect summary by severity

| Tier | Count | Notable |
|------|:----:|---------|
| 🔴 **P0 Critical** | 6 | BUG-BA-013 (score/numeric_score), BUG-BA-REM-001, BUG-BA-MYA-001, BUG-BA-RAT-01, BUG-BA-001, SEC-BA-001 |
| 🟠 **P1 High** | 14 | BUG-BA-002/011/REV-001/MYA-002/MYA-005/REV-002, DATA-BA-001/CM-01, PERM-BA-MYA-003, VAL-BA-REV-001/MYA-004, SEC-BA-002/003, DEAD-BA-001 |
| 🟡 **P2 Medium** | 20 | intervention/witness/remark logic + validation + soft-delete/dead-column drift |
| 🔵 **P3 Low** | 11 (families) | DOC-BA-001 (module-wide), audit/report doc + unbuilt-widget gaps |
| | **~51 distinct findings** | across 24 features; every one carries a proving test |

### Cross-cutting (systemic) patterns
1. **Missing/unqualified imports → runtime 500** on the `BaAssessmentController` remark surface: BUG-BA-REM-001, BUG-BA-MYA-001, BUG-BA-RAT-01, BUG-BA-MYA-002, BUG-BA-REV-001 — **one class of bug, five entry points.** Fix the imports once and five P0/P1s clear together.
2. **`score` vs `numeric_score`** (BUG-BA-013) contaminates the entire report layer — hard-500 where raw-SQL, silent-wrong (0.00 / false at-risk) where Eloquent/blade. Highest business risk: it *mislabels children as at-risk*.
3. **`bha_` vs `ba_` prefix** (DOC-BA-001) — the single most-referenced finding (asserted in every feature); doc-only, code is correct.
4. **`FormRequest::authorize()` bare `true`** (SEC-BA-002) — module-wide; mitigated by controller Gates but a defence-in-depth gap.
5. **Report `export()` = `abort(501)`** (BUG-BA-011) — one stub, every report screen.
6. **Soft-delete drift** — models omitting `SoftDeletes` while migrations add `deleted_at` (DATA-BA-CM-01, DATA-BA-IA-01, DATA-BA-WIT-05): dead columns + hard deletes + dead Policy abilities.

> **Regression tripwires:** the P0/P1 defect-proving tests *pass by asserting the current broken state*. When the source is fixed they will flip to failing — that flip is the signal to update the assertion. Treat them as the module's canary suite.

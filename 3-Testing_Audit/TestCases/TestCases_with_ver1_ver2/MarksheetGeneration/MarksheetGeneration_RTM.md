# MarksheetGeneration (MSH) — Requirements Traceability Matrix (RTM)

**Generated:** 2026-Jul-09 · **Mode:** report (module roll-up)
**Chain:** FRD/Screen §(Source) → BC → TC → V1/V2 method → (optional) defect
**Sources:** `MarksheetGeneration_V2/*.md` (5 screens), FRD `MSH_FRD_Complete_2026-06-29.md`, DDL `MarksheetGeneration_DDL_v1.sql` (23 tables), Audit `MarksheetGeneration_Complete_Audit_2026-06-29.md`

## 1. FRD REQ → Feature → Coverage

| REQ ID | Requirement | Feature (artifact set) | Primary table(s) | Coverage | Notes / defect |
|--------|-------------|------------------------|------------------|----------|----------------|
| REQ-MSH-001 | Class Group management | ConfigurationTemplates | `msh_class_groups`, `msh_class_group_items_jnt` | Full | junction sync via DB-table (ClassGroupService) |
| REQ-MSH-002 | Template Configuration | ConfigurationTemplates | `msh_config_templates` | Full | DEV-MSH-CT-01 (is_locked guard), DEV-MSH-CT-02 (JSON branch) |
| REQ-MSH-003 | Exam Group management | ConfigurationTemplates | `msh_exam_groups`, `msh_exam_group_items_jnt` | Full | BUG-MSH-003 (edit() no binding) proven |
| REQ-MSH-004 | Marksheet Schedule CRUD | SchedulingAndLifecycle | `msh_marksheet_schedules` | Full | BUG-MSH-101 (ScheduleClass SoftDeletes) |
| REQ-MSH-005 | Automated Computation | SchedulingAndLifecycle | schedules + result tables | Full | BR-MSH-026/027, PERF-MSH-002 |
| REQ-MSH-006 | Review lifecycle | SchedulingAndLifecycle | `msh_marksheet_schedules` | Full (BC-SM) | COMPUTED→REVIEWED |
| REQ-MSH-007 | Publish lifecycle | SchedulingAndLifecycle | schedules + config_templates | Full (BC-SM) | REVIEWED→PUBLISHED + template lock (BR-MSH-037) |
| REQ-MSH-008 | Lock lifecycle | SchedulingAndLifecycle | `msh_marksheet_schedules` | Full (BC-SM) | PUBLISHED→LOCKED |
| REQ-MSH-009 | Unlock with reason | SchedulingAndLifecycle | `msh_marksheet_schedules` | Full (BC-SM) | reason required (BR-MSH-039) |
| REQ-MSH-010 | Student Result view/edit | StudentResultsAndPrint | `msh_student_results` | Full | SEC-MSH-001/002 proven |
| REQ-MSH-011 | Student Subject Result | StudentResultsAndPrint | `msh_student_subject_results` | Full | |
| REQ-MSH-012 | PDF/Print generation | StudentResultsAndPrint | `msh_student_results` (print/pdf views) | Full (read-focused) | html2pdf.js print route |
| REQ-MSH-013 | Withhold/Declare | StudentResultsAndPrint | `msh_student_results` | Full (BC-SM) | DECLARED↔WITHHELD |
| REQ-MSH-014 | Coscholastic Results | StudentResultsAndPrint | `msh_student_coscholastic_results` | Full | is_auto_from_ba |
| REQ-MSH-015 | IA Mark entry | StudentResultsAndPrint | `msh_student_ia_marks` | Full | teacher entry |
| REQ-MSH-016 | Subject Practical Config | SchedulingAndLifecycle | `msh_subject_practical_configs` | Full | theory/practical split |
| REQ-MSH-017 | Precheck | SchedulingAndLifecycle | schedules + cross-module reads | Full | PERF-MSH-001 (N+1), DEP-MSH-001 |
| REQ-MSH-018 | Dashboard | Dashboard | aggregates `msh_*` | Full (read-focused) | BUG-MSH-001 (P0), PERF-MSH-003 |

All 18 FRD REQs traced to a feature with ≥1 TC. API contract (`routes/api.php`) is dead → covered by BUG-MSH-001 proving tests (assert current 404/dead behaviour), not by positive API tests.

## 2. Key Business Rules → BC/TC → defect

| BR ID | Rule | Feature | Enforcement (as-built) | Coverage / defect |
|-------|------|---------|------------------------|-------------------|
| BR-MSG-002 | Scholastic weightages sum = 100 | ComponentsAndWeightages | only on `update()` (service); `store()` bypasses | BUG-MSH-C01 (create), BUG-MSH-C03 (500 not 422) |
| BR-MSG-003 | Exam weightages sum = 100 | ComponentsAndWeightages | validator is dead code | BUG-MSH-C02 |
| BR-MSG-019 | Null-safe weightage | ComponentsAndWeightages / Scheduling | ENFORCED (WeightageApplier) | Full |
| BR-MSG-025 | Best-of-N exam type | SchedulingAndLifecycle | ENFORCED | Full |
| BR-MSG-027 | Locked config-template immutable | ConfigurationTemplates | NOT implemented at controller/service | DEV-MSH-CT-01 |
| BR-MSH-026 | Compute only DRAFT/COMPUTED | SchedulingAndLifecycle | PARTIAL (is_locked only, not status) | BR-MSH-026 proven |
| BR-MSH-027 | No concurrent computation | SchedulingAndLifecycle | NOT enforced | BR-MSH-027 proven |
| BR-MSH-037 | Publish locks template | SchedulingAndLifecycle | ENFORCED | Full (BC-SM) |
| BR-MSH-039 | Unlock requires reason + audit | SchedulingAndLifecycle | ENFORCED | Full (BC-SM) |
| BR-MSH-050 | Weightage = 100 before compute | Components / Scheduling | NOT enforced (count only in precheck) | BR-MSH-050 proven |

## 3. State-machine transitions (BC-SM) — SchedulingAndLifecycle

| From | Trigger | To | Legal? | Test |
|------|---------|----|--------|------|
| DRAFT | compute | COMPUTED | legal | V2 (band 20-29) |
| COMPUTED | review | REVIEWED | legal | V2 |
| REVIEWED | publish | PUBLISHED (+template locked) | legal | V2 |
| PUBLISHED | lock | LOCKED | legal | V2 |
| PUBLISHED/LOCKED | unlock (reason) | COMPUTED | legal | V2 |
| DRAFT | review/publish/lock | — | illegal (rejected) | V2 negative |
| COMPUTED | publish | — | illegal | V2 negative |
| REVIEWED | lock | — | illegal | V2 negative |
| locked schedule | compute | — | illegal (blocked) | V2 negative |

StudentResultsAndPrint BC-SM: `DECLARED ↔ WITHHELD` (withhold/declare) — legal + illegal-when-locked covered.

## 4. Defect Register (module-scoped; MSH prefixes only)

| Code | Sev | Origin | Feature | Proving test | Status |
|------|-----|--------|---------|--------------|--------|
| BUG-MSH-001 | P0 | Audit A-2 | Dashboard | V1 test_13; V2 test_58/59/72 | confirmed |
| SEC-MSH-001 | P1 | Audit A-3 | StudentResultsAndPrint | V2 test_51 | confirmed |
| SEC-MSH-002 | P1 | Audit A-3 | StudentResultsAndPrint | V2 test_52 | confirmed |
| SEC-MSH-003 | P1 | Audit A-4 (19/19) | ALL | per-feature request tests | confirmed |
| PERF-MSH-001 | P1 | Audit A-9/C | SchedulingAndLifecycle | V2 test_74 | confirmed |
| BR-MSH-026 | P1 | Audit C-1 | SchedulingAndLifecycle | V2 test_29 | confirmed |
| BR-MSH-027 | P1 | Audit C-2 | SchedulingAndLifecycle | V2 test_71 | confirmed |
| D39-MSH | P1 | Audit A-11 | ALL (env) | documented + explicit grant | confirmed |
| BUG-MSH-003 | P2 | Audit A-3 | ConfigurationTemplates | V1 test_16; V2 test_56 | confirmed |
| PERF-MSH-002 | P2 | Audit A-6 | SchedulingAndLifecycle | V2 test_73 | confirmed |
| PERF-MSH-003 | P2 | Audit A-9 | StudentResults / Dashboard | V2 test_46 | confirmed |
| BR-MSH-050 | P2 | Audit C-3 | Components / Scheduling | V2 test_72 | confirmed |
| DEP-MSH-001 | P2 | Audit G-7 | SchedulingAndLifecycle | V1 test_16 / V2 test_44 | confirmed |
| DOC-MSH-001 | P3 | Audit D-1 | (docs) | Inventory note | confirmed |
| DOC-MSH-002 | P3 | Audit D-3 | SchedulingAndLifecycle | V1 test_01 / V2 test_02 | confirmed |
| PERF-MSH-004 | P3 | Audit D-5 | StudentResults / Scheduling | V2 test_45 | confirmed |
| BUG-MSH-101 | P1 | NEW (discovered) | SchedulingAndLifecycle | V1 test_18; V2 test_04/16 | verify in source |
| DEV-MSH-CT-01 | P2 | NEW | ConfigurationTemplates | V2 test_21 | verify in source |
| DEV-MSH-CT-02 | P3 | NEW | ConfigurationTemplates | Gap §4 | verify in source |
| BUG-MSH-C01 | P2 | NEW | ComponentsAndWeightages | V2 test_80 | verify in source |
| BUG-MSH-C02 | P2 | NEW | ComponentsAndWeightages | V2 test_82/83 | verify in source |
| BUG-MSH-C03 | P3 | NEW | ComponentsAndWeightages | V2 test_81 | verify in source |
| BUG-MSH-C04 | P3 | NEW | ComponentsAndWeightages | V2 test_72 | verify in source |
| BUG-MSH-SR-01 | P3 | NEW | StudentResultsAndPrint | index ability-naming assertions | verify in source |

## 5. Traceability integrity

- Every FRD REQ (18/18) → a feature with ≥1 TC. ✔
- Every feature's BC/TC carries a `Source` tag; every `Source`-tagged requirement item has ≥1 TC (per-feature Gap Analysis Coverage-Score tables). ✔
- Every audit finding with an MSH prefix mapped to ≥1 proving test (or documented env prereq). ✔
- No cross-module defect prefixes used (only BUG-/SEC-/PERF-/BR-/DEP-/DOC-/DEV-MSH). ✔
- DDL gaps flagged: DOC-MSH-001 (23 vs 22 tables), DOC-MSH-002 (`sys_dropdowns` vs `sys_dropdown_table`), `msh_computation_logs` has no `deleted_at` (no SoftDeletes). ✔

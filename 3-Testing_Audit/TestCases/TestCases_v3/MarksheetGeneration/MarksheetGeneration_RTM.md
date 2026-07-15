# MarksheetGeneration (MSH) — Requirements Traceability Matrix (RTM)

**Generated:** 2026-Jul-10 · **Mode:** report
**Sources:** FRD `MSH_FRD_Complete_2026-06-29.md`, screen BRDs `MarksheetGeneration_V2/*.md`, DDL `MarksheetGeneration_DDL_v1.sql`, audit `MarksheetGeneration_Complete_Audit_2026-06-29.md`, and the 5 per-feature TcList/GapAnalysis artifacts in this run folder.

**Traceability chain:** Requirement/FRD/Screen → BC-xx → TC-P/N/D/SM/T/S → `test_*()` → (optional) audit defect.

## REQ → Feature → BC/TC → Test method → Status

| REQ (FRD) | Screen (BRD) | Feature | Key BC group | TC classes | Representative test method(s) | Audit defect | Status |
|-----------|--------------|---------|--------------|-----------|-------------------------------|--------------|--------|
| REQ-MSH-001 Class Group mgmt | 02 Configuration | ConfigurationTemplates | BC-DB/VAL/BIZ (class_groups + items_jnt) | P/N/D | class-group CRUD + toggle/trash/restore/forceDelete | — | Covered |
| REQ-MSH-002 Template config | 02 Configuration | ConfigurationTemplates | BC-DB/VAL/REF (config_templates, class_config_jnt) | P/N/D | config-template CRUD, grading_schema SET NULL, class-assignment | — | Covered |
| REQ-MSH-003 Exam Group mgmt | 02 Configuration | ConfigurationTemplates | BC-DB/VAL/REF (exam_groups + items_jnt) | P/N/D | exam-group CRUD; edit()-no-binding proof | BUG-MSH-003 | Covered (defect proven) |
| (masters) Marksheet Type / IA Component Type | 02 Configuration | ConfigurationTemplates | BC-DB/VAL/BIZ | P/N/D | marksheet-type + ia-component-type CRUD | — | Covered |
| REQ (weightage config) | 03 Components | ComponentsAndWeightages | BC-DB/VAL/BIZ (4 template child tables) | P/N/D | scholastic/exam-weightage/IA/coscholastic CRUD | — | Covered |
| BR-MSH-009/012/050 weightage=100 | 03 Components | ComponentsAndWeightages | BC-BIZ (sum=100) | N/D | `test_16/17/18` (sum≠100 accepted — validator is dead code) | BR-MSH-050 | Covered (gap proven) |
| REQ-MSH-004 Schedule CRUD | 04 Scheduling | SchedulingAndLifecycle | BC-DB/VAL/REF (marksheet_schedules, schedule_class_jnt) | P/N/D | schedule CRUD, schedule-class mapping | — | Covered |
| REQ-MSH-005 Automated computation | 04 Scheduling | SchedulingAndLifecycle | BC-BIZ/SM | P/N | compute dispatch (`ComputeDispatched`), precheck | PERF-MSH-001/002, BR-MSH-050 | Covered |
| REQ-MSH-006 Review lifecycle | 04 Scheduling | SchedulingAndLifecycle | BC-SM (COMPUTED→REVIEWED) | P/N (SM) | review transition + illegal-from-DRAFT | REVIEW-GATE-GAP | Covered |
| REQ-MSH-007 Publish lifecycle | 04 Scheduling | SchedulingAndLifecycle | BC-SM (REVIEWED→PUBLISHED, locks template) | P/N (SM) | publish transition, BR-MSH-037 template lock | — | Covered |
| REQ-MSH-008 Lock lifecycle | 04 Scheduling | SchedulingAndLifecycle | BC-SM (PUBLISHED→LOCKED) | P/N (SM) | lock transition | — | Covered |
| REQ-MSH-009 Unlock w/ reason | 04 Scheduling | SchedulingAndLifecycle | BC-SM/VAL (unlock_reason required) | P/N | unlock (`Unlocked`), required-reason, reverts to COMPUTED | DOC-MSH-003 | Covered (doc-vs-impl noted) |
| BR-MSH-026 compute FSM guard | 04 Scheduling | SchedulingAndLifecycle | BC-SM | N | `test_29` (REVIEWED recomputable — is_locked-only guard) | BR-MSH-026 | Covered (defect proven) |
| BR-MSH-027 concurrent compute | 04 Scheduling | SchedulingAndLifecycle | BC-BIZ | N | `test_71` (double-dispatch not blocked) | BR-MSH-027 | Covered (defect proven) |
| REQ-MSH-016 Subject Practical Config | 04 Scheduling | SchedulingAndLifecycle | BC-DB/VAL (theory/practical split) | P/N/D | practical-config CRUD | — | Covered |
| REQ-MSH-017 Precheck | 04 Scheduling | SchedulingAndLifecycle | BC-BIZ/INT | P/N | `test_74` N+1, `test_44` StudentPortal guard | PERF-MSH-001, DEP-MSH-001 | Covered |
| REQ-MSH-010 Student Result view/edit | 05 Results | StudentResultsAndPrint | BC-DB/VAL/AUTH | P/N/D | result CRUD; `test_51/52` wrong gates | SEC-MSH-001/002 | Covered (defects proven) |
| REQ-MSH-011 Student Subject Result | 05 Results | StudentResultsAndPrint | BC-DB/REF | P/N/D | subject-result CRUD | — | Covered |
| REQ-MSH-013 Withhold/Declare | 05 Results | StudentResultsAndPrint | BC-BIZ (DECLARED/WITHHELD) | P/N | withhold (`Withheld`, reason required) / declare (`Declared`) | — | Covered |
| REQ-MSH-014 Coscholastic results | 05 Results | StudentResultsAndPrint | BC-DB/VAL | P/N/D | coscholastic-result CRUD, is_auto_from_ba | — | Covered |
| REQ-MSH-015 IA Mark entry | 05 Results | StudentResultsAndPrint | BC-DB/VAL | P/N/D | ia-mark CRUD | — | Covered |
| REQ-MSH-012 PDF/Print generation | 05 Results | StudentResultsAndPrint | BC-BIZ/INT (Template::render MARKSHEET_PRINT) | P | print/pdf/export render assertions | PERF-MSH-003/004 | Covered |
| REQ-MSH-018 Dashboard | 01 Dashboard | Dashboard | BC-AUTH/render | P/N | stat widgets, 4-pillar nav, recent tabs, empty state | PERF-MSH-003 | Covered |
| (API contract) | 01 Dashboard | Dashboard | BC-INT | N | `test_dashboard_58/59/72` dead-API proof | BUG-MSH-001 | Covered (dead-API proven) |
| SEC-MSH-003 FormRequest authorize | ALL | ALL | BC-AUTH (D30) | N | per-feature `authorize()==true` proofs | SEC-MSH-003 | Covered (systemic) |
| D39 permission seeding | ALL | ALL | BC-AUTH (env) | — | documented env prereq in each Validation Report | D39-MSH | Documented (env) |

## Coverage roll-up

- **FRD REQ items (REQ-MSH-001…018):** all 18 traced to ≥1 feature with ≥1 test method. Covered.
- **Lifecycle BRs (BR-MSH-026/027/037/039/050):** traced; the two enforcement gaps (026, 027) and the weightage-sum gap (050) carry defect-proving tests.
- **Audit defects (16 registered + 5 discovered):** every one mapped to an owning feature and a proving test (or documented as an environment/documentation item). See Feature Inventory for the full table.
- **Requirement items with 0 TC:** none. Discovered gaps (BUG-MSH-101, DEV-MSH-C03/C04, REVIEW-GATE-GAP, DOC-MSH-003) are additive findings beyond the requirement baseline, each with a proving/documenting test.

## Notes

- Status column "Covered (defect proven)" = the test asserts the **current defective behaviour** and must be inverted when the source is remediated.
- DOC-MSH-002 corrected in this run: the FSM `status_id` FK targets **`sys_dropdown_table`** (the audit's `sys_dropdowns` claim is based on a no-op rename migration).

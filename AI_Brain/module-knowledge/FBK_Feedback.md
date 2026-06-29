# Module Knowledge — Feedback (FBK)

> **Status:** SEEDED 2026-06-29 (Business Analyst). First knowledge file for this module.
> Seeded from the **live tree** (Modules/Feedback code, tenant migrations, models, seeders) and
> three-way reconciled against DDL v2/v3 and AI_Brain decision **D27**. Every count below was
> verified against the filesystem — nothing is assumed.

---

## Module Facts

| Fact | Value | Source (verified) |
|------|-------|-------------------|
| Module name / code / prefix | Feedback / **FBK** / **`fbk_`** | conventions.md Master Reference |
| DB layer | **Tenant** (per-school isolation; no `tenant_id` column) | DDL header; database-per-tenant |
| Module folder | `Modules/Feedback` | filesystem |
| Tables (own) | **11** `fbk_*` tables | DDL v3 (`CREATE TABLE` count = 11) + 11 create-migrations |
| Tenant migrations | **12** (11 × create + 1 × alter: `scope_type_id` → nullable) | `database/migrations/tenant/*fbk*` |
| Controllers | **10** (9 × `Fbk*` + 1 × `ConsentFormController`) | `ls app/Http/Controllers` |
| Models | **11** (`Fbk*`) | `ls app/Models` (1:1 with tables) |
| Services | **6** (Eligibility, Response, Summary, Cycle, Template, Anonymity) | `ls app/Services` (1066 LOC total) |
| FormRequests | **1** (`StoreConsentFormRequest`) | `ls app/Http/Requests` |
| Seeders | **4** (Database, MasterData, Dropdown, DemoData) | `ls database/seeders` |
| Views (Blade) | **51** | `find resources/views -name '*.blade.php'` |
| Policies (module/central) | **0** dedicated `Fbk*` policy classes found | `ls app/Policies` grep (see Gap G3) |
| Event listeners | **0** (empty `EventServiceProvider`) | `EventServiceProvider.php` |
| FRD status | **Complete FRD created 2026-06-29** — `FBK_FRD_Complete_2026-06-29.md` | this session |

### Canonical schema = DDL **v3** (ENUM-free), NOT v2
- **DDL files (OLD_REPO `1-DDL_Modules/_Feedback/`):** `DDL/StudentFeedback_ddl_v3.sql` (current) ;
  `Old_DDL/StudentFeedback_ddl_v2.sql` (superseded) ; `Old_DDL/StudentFeedback_ddl_v1.sql` (Student/Parent→Teacher only).
- **Reconciliation result:** the **live tenant migrations + models + dropdown seeder all follow v3**
  — every v2 `ENUM(...)` column is replaced by a `*_id INT UNSIGNED` FK into `sys_dropdown_table`
  (per **D29**). The `modules-map.md` line that cites `..._ddl_v2.sql` as the scaffold basis is
  **stale**; the built schema is v3. v2 is retained only for the business-rule/use-case narrative.
- Verified dropdown-driven columns (seeded by `FbkDropdownSeeder`): `fbk_relationship_types.respondent_kind` /
  `.context_required`, `fbk_templates.respondent_kind` / `.overall_rating_method`, `fbk_questions.respondent_kind` /
  `.question_type`, `fbk_cycles.status`, `fbk_responses.respondent_kind` / `.status`,
  `fbk_answers.question_type_snapshot`, `fbk_cycle_feedback_types.scope_type`, `fbk_target_types.linked_entity_table`.
- Model confirmation: `FbkResponse` casts `respondent_kind_id` and `status_id` as `belongsTo(Dropdown::class)`.

---

## DDL Table Inventory (11 `fbk_*` tables — v3)

| # | Table | Layer | Purpose |
|---|-------|-------|---------|
| 1 | `fbk_target_types` | Reference master | What can be rated (Teacher, Student, Driver, Canteen staff, Department…). `linked_entity_table` says which base table a target lives in. |
| 2 | `fbk_relationship_types` | Reference master | Valid `(respondent_kind × target_type × context)` tuples = authorisation whitelist. Carries `is_peer_relationship`, `is_self_relationship`, `nep_2020_mandated`, `default_anonymous_to_target`. |
| 3 | `fbk_categories` | Reference master | Question themes (Teaching, Hygiene, Safety…); optional `applicable_target_type_id` scope. |
| 4 | `fbk_templates` | Template layer | Reusable question-set; `overall_rating_method`, `rating_scale_max`, `version`, `is_locked`, `applicable_relationship_codes_json`. |
| 5 | `fbk_questions` | Template layer | Questions in a template; `question_type`, `weight`, `is_reverse_scored`, `options_json`. |
| 6 | `fbk_cycles` | Cycle layer | Collection window; `academic_session_id`, `start/end_date`, `status` FSM, anonymity + visibility defaults. |
| 7 | `fbk_cycle_feedback_types` | Cycle layer (junction) | One cycle × many flows = `(relationship_type + template)`; per-flow anonymity, `min_responses_for_visibility`, scope, `target_population_mode` (Auto/Manual). |
| 8 | `fbk_cycle_targets` | Cycle layer | Explicit eligible-target enumeration + participation counters (expected/received/submitted). |
| 9 | `fbk_responses` | Transactional | One submission per `(respondent × target × cft)`. Polymorphic respondent (4 FKs) + target (4 FKs); 7 generated `_uq` COALESCE cols power the dedup UNIQUE index; `status` FSM. |
| 10 | `fbk_answers` | Transactional | One row per `(response × question)`; snapshots `question_type`, `category_id`, `weight` at submit. |
| 11 | `fbk_summary` | Aggregate | Materialised per `(cft × target × slice)`; participation %, averages, distributions (JSON), k-anonymity publish flag. 6 generated `_uq` cols. |

**Polymorphic pattern (D27):** Target identity = exactly one of `target_user_id` / `target_student_id` /
`target_employee_id` / `target_department_id` (driven by `target_type.linked_entity_table`).
Respondent identity = always-populated `respondent_user_id` + exactly one of
`respondent_student_id` / `respondent_guardian_id` / `respondent_employee_id`.

**External dependencies (FKs):** `sys_users`, `sch_employees`, `sch_class_section_jnt`, `sch_subjects`,
`sch_departments`, `sch_org_academic_sessions_jnt`, `std_students`, `std_guardians`,
`std_student_academic_sessions`, `tt_activity` / `tt_activity_teacher`, `sys_dropdown_table`.

---

## Built Surface (live code)

- **Controllers (9 Fbk + 1 Consent):** `FbkDashboardController`, `FbkMenuController` (tabbed pages:
  cycles/templates/responses/analytics/setup), `FbkCycleController` (CRUD + FSM activate/close/publish/cancel),
  `FbkCycleFeedbackTypeController` (modal CRUD + `populateTargets`), `FbkTemplateController`
  (CRUD + clone + question CRUD/reorder), `FbkResponseController` (respond index/form/saveDraft/submit/withdraw),
  `FbkTargetTypeController`, `FbkRelationshipTypeController`, `FbkCategoryController` (setup masters, show/store/update/destroy + trash/restore/forceDelete/toggle),
  `ConsentFormController` (see anomaly A1).
- **Services:** `FbkEligibilityService` (444 LOC — context resolvers per `context_required`),
  `FbkResponseService` (191 — submit/draft/withdraw + rating calc), `FbkSummaryService` (125 — aggregate recompute),
  `FbkCycleService` (121 — FSM), `FbkTemplateService` (100 — clone/lock), `FbkAnonymityService` (85 — anonymity/k-anonymity enforcement).
- **Routes:** `routes/web.php` (all `feedback.*` named, tenancy middleware via Pattern B RouteServiceProvider);
  `routes/admin.php` (consent-forms resource); `routes/api.php`.
- **Permissions referenced (Gate::authorize):** `tenant.feedback.viewAny`, `tenant.consent-forms.{viewAny,view,create,update,delete,restore,forceDelete}`.

---

## Known Gaps & Open Issues

> **Technical Auditor Mode X — 2026-06-29 (live tree updated 2026-06-27).** Health 54/100 (Amber), no P0.
> Full report: `3-Audit_Reports/V1_Jun-2026/Feedback_Complete_Audit_2026-06-29.md`. Codes in `lessons/known-issues.md`.
>
> **Snapshot corrections (live code wins):**
> - This file's "0 dedicated Fbk* policy classes / no policies" — confirmed (only ParentPortal `ConsentFormPolicy` is
>   registered in `FeedbackServiceProvider::registerPolicies()`); but G3's worry was partly resolved differently — all
>   9 admin controllers now gate with `can:tenant.feedback.viewAny` (constructor middleware, added 2026-06-27).
> - "0 tests" → **CORRECTED**: 9 Browser test files exist (`tests/Browser/Modules/Feedback/*`, ~6,230 LOC). Pest
>   unit/feature dirs hold only `.gitkeep`.
> - The prior 2026-06-21 dual-P0 (SEC-FBK-001 zero-authz, SEC-FBK-002/DEAD-FBK-001 eligibility-never-called) are now
>   **REMEDIATED** in live code.
>
> **Open P1 (new codes):**
> - **BUG-FBK-003** — eligibility + auto-population broken: `FbkEligibilityService` reads `$relationship->context_required`
>   but the attribute is `context_required_id` (dropdown FK). `match()` always defaults → every submit 403, 0 targets
>   populated. v2-string-ENUM vs v3-dropdown-FK service drift. (`FbkEligibilityService.php:82,102`.)
> - **SEC-FBK-004** — `tenant.feedback.*` / `tenant.consent-forms.*` permissions NOT seeded anywhere → module is
>   super-admin-only (Gate::before bypass). Resolves G3/Q4/RISK-FBK-003. See D39.
> - **SEC-FBK-005** — peer/NEP anonymity not locked at config (`enforceAnonymityRules()` never called); admin can save a
>   peer flow non-anonymous. Child-safety. Mitigant: CFT defaults anonymous=true, no target-facing read path yet.
> - **BUG-FBK-004** — reverse scoring (BR-013) never applied in `computeOverallRating`.
> - **SEC-FBK-003** — coarse authz: one `viewAny` permission gates all mutations.
> - **VAL-FBK-001** — answer payload mass-assigned into `fbk_answers` with no validation (confirmed).
>
> **Confirmed answers to FRD open questions:** Q1 anonymity NOT enforced on read (service is dead code, DEAD-FBK-002);
> Q2 no scheduler (JOB-FBK-001); Q3 recompute (BR-019) IS fired inline on submit/withdraw (ENFORCED); Q4 perms unseeded;
> Q5 0 Pest tests but 9 Browser tests.
>
> **Positive:** D36 generated dedup columns correct (13 `_uq` cols `GENERATED ALWAYS … VIRTUAL` + `uq_fbk_r_dedup`/
> `uq_fbk_s_dedup`) — beats platform baseline (1/19). D29-clean (0 enum). Full tenancy stack on every route (Layer 6 Green).
> Dropdown table is `sys_dropdowns` (Prime/Dropdown.php:13) — the `sys_dropdown_table` name in FRD/DDL comments is a doc alias.

- **A1 (Anomaly — cross-module ownership) [P1, verify].** `ConsentFormController` lives in the **Feedback**
  module but operates on **ParentPortal** models `Modules\ParentPortal\Models\ConsentForm` /
  `ConsentFormResponse`, backed by tables `ppt_consent_forms` / `ppt_consent_form_responses`
  (migrations `2026_06_16_1052*`, `ppt_` prefix — owned by ParentPortal, not Feedback). So the Feedback
  module hosts the **admin authoring/results UI** for consent forms while ParentPortal owns the data + the
  parent-facing response flow. This is a real module-boundary crossover — flag for the Enterprise Architect.
  Consent Forms are **not** `fbk_*` and are documented in the FRD as a distinct sub-area (REQ-FBK-013/014).
- **A2 (Naming collision — not this module).** `fof_feedback_forms` / `fof_feedback_responses` migrations
  exist but carry the **FrontOffice** `fof_` prefix — a separate, unrelated feedback feature. Do **not**
  fold them into FBK.
- **G3 (Authorization) [P1, verify].** No dedicated `Fbk*` policy classes were found in `app/Policies`, and a
  grep of `database/seeders` + `app` found **no seeding** of the `tenant.feedback.*` / `tenant.consent-forms.*`
  permission strings the controllers `Gate::authorize` against. Either the permissions are seeded by a global
  RBS/permission seeder not located in this scan, or authorization currently relies on a super-admin bypass.
  Needs a Technical Auditor confirmation before sign-off.
- **G4 (Scheduler) [P2].** Cycle FSM `Draft→Active` (on `start_date`) and `Active→Closed` (on `end_date`) are
  documented as scheduler-driven (BR R15). No Feedback-owned scheduled job was confirmed in this scan —
  verify whether the platform Scheduler module triggers transitions or they are manual-only today.
- **G5 (Summary recompute trigger) [P2].** `EventServiceProvider` is empty (0 listeners); summary/participation
  recompute (BR R19) must therefore be invoked inline by `FbkResponseService`/`FbkSummaryService` rather than
  event-driven — confirm it fires on every submit/withdraw.

---

## Design Decisions Made (recorded in AI_Brain)

- **D27 (2026-04-09)** — Generic Feedback module: 11-table polymorphic schema; NEP-2020 Teacher→Student &
  Student→Peer flows; hardcoded peer anonymity (child safety, R7–R8); k-anonymity `min_responses_for_visibility`
  (default 3); template snapshot strategy; 22 business rules; 12 use cases.
- **D29 (2026-04-09)** — ENUM→`sys_dropdown_table` FK. v3 implements this; the live schema is v3.

---

## Cross-Module Dependencies

| Direction | Module | Data / mechanism |
|-----------|--------|------------------|
| Inbound (reads) | SchoolSetup | classes, sections, `sch_class_section_jnt` (class/assistant teacher), subjects, departments, employees, academic session |
| Inbound (reads) | StudentProfile | students, guardians, `std_student_guardian_jnt` (portal-access flag), `std_student_academic_sessions` |
| Inbound (reads) | SmartTimetable | `tt_activity` / `tt_activity_teacher` (subject-teacher eligibility) |
| Inbound (reads) | Transport / Hostel | route/hostel context (via `context_json`) for staff-feedback eligibility |
| Inbound (reads) | SystemConfig | `sys_users`, `sys_dropdown_table` (all status/kind/type value sets) |
| Crossover | ParentPortal | Consent Forms — Feedback hosts admin UI over `ppt_consent_form*` tables (anomaly A1) |
| Outbound (should feed) | Notification | cycle-open / reminder / publish alerts (workflow notifications — confirm wiring) |

---

## Lessons Learned

- `[2026-06-29 | Business Analyst]` FBK: `modules-map.md` cited the **v2** DDL as the scaffold basis, but the
  live migrations/models/dropdown-seeder are all **v3** (ENUM-free). Always reconcile DDL→migration→model→seeder
  before trusting a modules-map DDL pointer.
- `[2026-06-29 | Business Analyst]` FBK: A controller in module X can own a feature whose **tables and models
  belong to module Y** (ConsentForm: Feedback controller → ParentPortal `ppt_` tables). Don't equate
  "controllers in the folder" with "tables in the prefix". Three sources (routes, controller `use` statements,
  migration prefix) were needed to untangle it.
- `[2026-06-29 | Business Analyst]` FBK: Gate strings present in controllers ≠ permissions seeded. Grep the
  seeders before claiming authorization coverage.
- `[2026-06-29 | Technical Auditor]` FBK: a service can silently break when the schema migrates from v2 string-ENUMs
  to v3 dropdown-FKs — `FbkEligibilityService` still `match($relationship->context_required)` (string) while the model
  only has `context_required_id`, so the attribute is null and the whole submit/populate spine fails closed
  (BUG-FBK-003). When auditing a v3-converted module, grep services for bare `->context_required` / `->status` /
  `->respondent_kind` (missing `_id`) — those are the v2-era string compares that the dropdown-FK migration broke.
- `[2026-06-29 | Technical Auditor]` FBK: existence of a well-written service (FbkAnonymityService — peer-lock,
  k-anon, identity-strip) does NOT mean a rule is enforced. It was injected into one controller and called from
  nowhere (DEAD-FBK-002). Always trace the call graph from a routed action to the service method, not just confirm
  the method exists.
- `[2026-06-29 | Technical Auditor]` FBK: confirmed the unseeded-permission → super-admin-only pattern (D39); this
  module's `can:tenant.feedback.*` resolves only via Gate::before, so non-super-admin roles get 403 platform-wide.

---

## Pending Next Steps (post-FRD handoffs)

1. **DDL/Schema gap** → DB Architect / Technical Auditor (Mode A): confirm v3 migrations match v3 DDL exactly,
   incl. all 13 generated `_uq` columns (7 on responses + 6 on summary) and dedup UNIQUE indexes.
2. **Code gap** → Technical Auditor (Mode B): verify eligibility resolvers for every `context_required`,
   rating calc (R12–R14), anonymity/k-anonymity (R7–R11), template locking (R18), summary recompute (R19).
3. **Authorization** → Technical Auditor (Mode C): resolve G3 (permission seeding / policy classes).
4. **Module boundary** → Enterprise Architect: decide correct home for Consent Forms (A1).
5. **Test coverage** → Testing Architect: 0 tests confirmed (`Tests` count not present in module dir scan).

---

## Version History

| Date | Agent | Change |
|------|-------|--------|
| 2026-06-29 | Business Analyst | Seeded from live tree; v3 reconciliation; Complete FRD (`FBK_FRD_Complete_2026-06-29.md`) created. |
| 2026-06-29 | Technical Auditor | Mode X Complete Audit. Health 54/100 (Amber), no P0. Reconciled 2026-06-21 codes vs 2026-06-27 live tree (SEC-FBK-001/002, DEAD-FBK-001 remediated). New: BUG-FBK-003/004/005/006, SEC-FBK-003/004/005, VAL-FBK-003, DEAD-FBK-002, JOB-FBK-001, ORM-FBK-001. Answered FRD Q1-Q5. Added D39 (unseeded-permission pattern). |

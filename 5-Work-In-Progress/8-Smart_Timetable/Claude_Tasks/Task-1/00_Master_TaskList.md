# SmartTimetable — Master Task List (Skill-Categorized)

**Generated:** 2026-03-15
**Source:** `2026Mar14_DevelopmentPlan_v2.md` + `2026Mar14_GapAnalysis_Updated_v2.md`
**Module Completion:** ~60% → target 95%+
**Total Effort:** ~69 working days across 19 phases
**Total Prompt Files:** 21 (P01–P21)

---

## Skill Legend

| Skill | Description | Slash Command |
|-------|------------|---------------|
| **Backend** | PHP code: controllers, services, models, middleware | — |
| **Frontend** | Blade views, Alpine.js, CSS, AdminLTE components | `/frontend` |
| **Schema** | Migrations, seeders, database changes | `/schema` |
| **Testing** | Writing + running Pest tests | `/test` |
| **Review** | Code review for security, tenancy, performance | `/review` |
| **Cleanup** | Dead code removal, refactoring, FormRequests | `/lint` |

---

## Execution Order & Prompt File Map

### Group 1 — P0 Priority (MUST DO FIRST)

| # | Prompt File | Phase | Tasks | Skill(s) | Effort | Dependency |
|---|-------------|-------|-------|----------|--------|-----------|
| P01 | `P01_BugFixes.md` | 1 | 1.1–1.9 | Backend | 0.5 day | None |
| P02 | `P02_Security_Middleware.md` | 2 | 2.1–2.2 | Backend | 0.75 day | None |
| P03 | `P03_Security_MainController.md` | 2 | 2.3 | Backend | 0.5 day | None |
| P04 | `P04_Security_Controllers.md` | 2 | 2.4–2.7 | Backend + Schema | 1.5 days | None |

### Group 2 — P1 Priority (Core Features)

| # | Prompt File | Phase | Tasks | Skill(s) | Effort | Dependency |
|---|-------------|-------|-------|----------|--------|-----------|
| P05 | `P05_ActivityConstraints.md` | 3 | 3.1–3.7 | Backend | 2 days | Phase 1 |
| P06 | `P06_Performance.md` | 4 | 4.1–4.6 | Backend | 2 days | None |
| P07 | `P07_RoomAllocation.md` | 5 | 5.1–5.4 | Backend + Frontend | 3 days | Phase 1 |
| P08 | `P08_StubsViewsCleanup.md` | 6 | 6.1–6.4 | Backend + Frontend + Cleanup | 2 days | Phase 2 |

### Group 3 — P1 Priority (Constraint System)

| # | Prompt File | Phase | Tasks | Skill(s) | Effort | Dependency |
|---|-------------|-------|-------|----------|--------|-----------|
| P09 | `P09_ConstraintArchitecture.md` | 11 | 11.1–11.6 | Backend | 3 days | Phase 3 |
| P10 | `P10_TeacherConstraints.md` | 12 | 12.1–12.5 | Backend + Schema | 5 days | Phase 11 |
| P11 | `P11_ClassConstraints.md` | 13 | 13.1–13.4 | Backend + Schema | 4 days | Phase 11 |
| P12 | `P12_InterActivity_Part1.md` | 15 | 15.1–15.5 | Backend | 5 days | Phase 11 |
| P13 | `P13_InterActivity_Part2.md` | 15 | 15.6–15.8 | Backend | 3 days | Phase 11 |

### Group 4 — P2 Priority (Feature Additions)

| # | Prompt File | Phase | Tasks | Skill(s) | Effort | Dependency |
|---|-------------|-------|-------|----------|--------|-----------|
| P14 | `P14_Analytics.md` | 7 | 7.1–7.3 | Backend + Frontend | 5 days | Phase 5 |
| P15 | `P15_Refinement.md` | 8 | 8.1–8.3 | Backend + Frontend | 4 days | Phase 5 |
| P16 | `P16_Substitution.md` | 9 | 9.1–9.3 | Backend + Frontend | 5 days | Phase 5 |
| P17 | `P17_API_Async.md` | 10 | 10.1–10.4 | Backend + Frontend | 3 days | Phase 5 |
| P18 | `P18_RoomConstraints.md` | 14 | 14.1–14.5 | Backend | 5 days | Phase 5, 11 |
| P19 | `P19_GlobalPolicy_DBClasses.md` | 16+17 | 16.1–16.2, 17.1–17.4 | Backend | 6 days | Phase 11 |

### Group 5 — P3 Priority (Quality)

| # | Prompt File | Phase | Tasks | Skill(s) | Effort | Dependency |
|---|-------------|-------|-------|----------|--------|-----------|
| P20 | `P20_Testing.md` | 18 | 18.1–18.4 | Testing | 5 days | Phase 12–17 |
| P21 | `P21_CodeQuality.md` | 19 | 19.1–19.4 | Cleanup + Schema | 3 days | Phase 6 |

---

## Full Task / Sub-Task Breakdown (by Skill)

### SKILL: Backend (PHP Code Changes)

#### Phase 1 — Critical Bug Fixes (P01)
- [x] Task 1.1: Fix `set_time_limit` bug → `SmartTimetableController.php:2591`
- [ ] Task 1.2: Remove `saveGeneratedTimetable()` → `SmartTimetableController.php:2843`
- [ ] Task 1.3: Fix `violatesNoConsecutiveRule()` → `FETSolver.php:636-639`
- [ ] Task 1.4: Fix `Shift` model reference → `TimetableTypeController.php:11,29,181`
- [ ] Task 1.5: Fix `SchoolShiftController::edit()` view ref → `SchoolShiftController.php:66`
- [ ] Task 1.6: Fix or remove `PeriodController` → `PeriodController.php`
- [ ] Task 1.7: Remove duplicate route registrations → `tenant.php:1846,1864`
- [ ] Task 1.8: Remove `test-seeder` debug route → `tenant.php:1767`
- [ ] Task 1.9: Fix `FETConstraintBridge` references → `FETConstraintBridge.php`

#### Phase 2 — Security Hardening (P02, P03, P04)
- [ ] Task 2.1: Add `EnsureTenantHasModule` middleware → `tenant.php:1766`
- [ ] Task 2.2: Protect destructive `truncate()` operations → 3 controllers
- [ ] Task 2.3: Add auth to SmartTimetableController → `SmartTimetableController.php` (all methods)
- [ ] Task 2.4: Add auth to 14 remaining controllers → Multiple files
- [ ] Task 2.5: Implement `SmartTimetablePolicy` → `app/Policies/SmartTimetablePolicy.php`
- [ ] Task 2.6: Register permissions in seeder → New seeder
- [ ] Task 2.7: Remove `$request->all()` from logs → 2 controllers

#### Phase 3 — Activity Constraints (P05)
- [ ] Task 3.1: Fix multi-period consecutive bug → `FETSolver.php:634`
- [ ] Task 3.2: Per-activity consecutive override → `FETSolver.php:492`
- [ ] Task 3.3: Per-activity daily cap override → `FETSolver.php:679`
- [ ] Task 3.4: Min-gap enforcement → `FETSolver.php` (new method)
- [ ] Task 3.5: Soft constraint slot scoring → `FETSolver.php::scoreSlotForActivity()`
- [ ] Task 3.6: Integrate scoring into getPossibleSlots → `FETSolver.php:838`
- [ ] Task 3.7: Auto-populate constraint fields on Activity → `ActivityController.php`

#### Phase 4 — Performance (P06)
- [ ] Task 4.1: Convert session storage to plain arrays → `SmartTimetableController.php`
- [ ] Task 4.2: Batch `updateOrCreate` in TeacherAvailability → `TeacherAvailabilityController.php`
- [ ] Task 4.3: Batch `updateOrCreate` in ActivityController → `ActivityController.php`
- [ ] Task 4.4: Replace `::all()` with scoped queries → `SmartTimetableController.php:93-100`
- [ ] Task 4.5: Gate excessive logging behind config flag → `FETSolver.php`
- [ ] Task 4.6: Concurrent generation protection → `SmartTimetableController.php::generateWithFET()`

#### Phase 5 — Room Allocation (P07)
- [ ] Task 5.1: Implement RoomAllocationPass service → `Services/RoomAllocationPass.php`
- [ ] Task 5.2: Wire into generateWithFET() → `SmartTimetableController.php`
- [ ] Task 5.4: Room conflict detection → Post-gen verification

#### Phase 6 — Stub Controllers (P08)
- [ ] Task 6.1: Implement TimetableController → `TimetableController.php`
- [ ] Task 6.2: Implement WorkingDayController stubs → `WorkingDayController.php`

#### Phase 11 — Constraint Architecture (P09)
- [ ] Task 11.1: Create ConstraintRegistry → `Services/Constraints/ConstraintRegistry.php` (NEW)
- [ ] Task 11.2: Create ConstraintContext value object → `Services/Constraints/ConstraintContext.php` (NEW)
- [ ] Task 11.3: Create ConstraintEvaluator → `Services/Constraints/ConstraintEvaluator.php` (NEW)
- [ ] Task 11.4: Wire Constraint Group evaluation → `ConstraintManager.php`
- [ ] Task 11.5: Wire FETConstraintBridge to DatabaseConstraintService → `FETConstraintBridge.php`
- [ ] Task 11.6: Add priority-ordered evaluation → `ConstraintManager.php`

#### Phase 12 — Teacher Constraints (P10)
- [ ] Task 12.1: Simple teacher constraints (5 classes) → `Services/Constraints/`
- [ ] Task 12.2: Study-format-aware teacher constraints (4 classes) → `Services/Constraints/`
- [ ] Task 12.3: Interval/time-window teacher constraints (6 classes) → `Services/Constraints/`
- [ ] Task 12.4: Global-teacher variants B2 → Scope variations
- [ ] Task 12.5: Register + seed types

#### Phase 13 — Class Constraints (P11)
- [ ] Task 13.1: Simple class constraints (5 classes) → `Services/Constraints/`
- [ ] Task 13.2: Study-format-aware class constraints (6 classes) → `Services/Constraints/`
- [ ] Task 13.3: School-specific class constraints (2 classes) → `Services/Constraints/`
- [ ] Task 13.4: Global-class variants C2 → Scope variations

#### Phase 14 — Room Constraints (P18)
- [ ] Task 14.1: Remaining room availability constraints (3 rules)
- [ ] Task 14.2: Teacher room preferences E2 (10 rules, RoomChangeTrackingService)
- [ ] Task 14.3: Student room preferences E3 (10 rules, mirror E2)
- [ ] Task 14.4: Subject/StudyFormat room preferences E4 (6 rules)
- [ ] Task 14.5: Seed constraint types + register

#### Phase 15 — Inter-Activity Constraints (P12, P13)
- [ ] Task 15.1: Activity group infrastructure in FETSolver
- [ ] Task 15.2: Same-time / same-day / same-hour H1-H3
- [ ] Task 15.3: Consecutive / ordered / grouped H5-H7
- [ ] Task 15.4: Not-overlapping H4
- [ ] Task 15.5: Day/period pinning and exclusion H20-H22
- [ ] Task 15.6: Gap and scheduling rules H9-H16
- [ ] Task 15.7: Room-related inter-activity H17-H18
- [ ] Task 15.8: School-specific inter-activity H19

#### Phase 16 — Global Policy (P19)
- [ ] Task 16.1: Remaining global constraints G5-G9
- [ ] Task 16.2: Activity-level fields expansion (15 fields)

#### Phase 17 — DB Constraint Classes (P19)
- [ ] Task 17.1: Teacher DB constraint PHP classes (7 classes)
- [ ] Task 17.2: Class DB constraint PHP classes (6 classes)
- [ ] Task 17.3: Room + Activity + Global DB classes (remaining)
- [ ] Task 17.4: Reconcile CONSTRAINT_CLASS_MAP duplicates

#### Phase 7 — Analytics (P14)
- [ ] Task 7.1: Create AnalyticsService (7 methods)
- [ ] Task 7.2: Create AnalyticsController (5 endpoints)

#### Phase 8 — Refinement (P15)
- [ ] Task 8.1: Create RefinementService (8 methods)
- [ ] Task 8.2: Create RefinementController (5 endpoints)

#### Phase 9 — Substitution (P16)
- [ ] Task 9.1: Create SubstitutionService (6 methods)
- [ ] Task 9.2: Create SubstitutionController (4 endpoints)

#### Phase 10 — API & Async (P17)
- [ ] Task 10.1: Create TimetableApiController (6 REST endpoints)
- [ ] Task 10.2: Create GenerateTimetableJob (queue job)
- [ ] Task 10.3: Status polling endpoint

---

### SKILL: Frontend (Blade/Alpine.js Views)

#### Phase 5 — Room Allocation (P07)
- [ ] Task 5.3: Show room assignments in timetable views

#### Phase 6 — Missing Views (P08)
- [ ] Task 6.3: Create `slot-requirement/show.blade.php`, `shift/edit.blade.php`, `period/` views

#### Phase 7 — Analytics (P14)
- [ ] Task 7.3: Dashboard with charts, workload heatmap, violation list, export buttons

#### Phase 8 — Refinement (P15)
- [ ] Task 8.3: Drag-and-drop timetable grid, right-click context menu, impact preview modal

#### Phase 9 — Substitution (P16)
- [ ] Task 9.3: Absence reporting form, substitute recommendation list, daily board

#### Phase 10 — API Progress (P17)
- [ ] Task 10.4: Alpine.js polling progress bar

---

### SKILL: Schema (Migrations / Seeders)

#### Phase 2 — Security (P04)
- [ ] Task 2.6: SmartTimetable permission seeder

#### Phase 12 — Teacher Constraints (P10)
- [ ] Task 12.5: ConstraintType seed entries for B1.8–B1.22 + B2

#### Phase 13 — Class Constraints (P11)
- [ ] Task 13.4: ConstraintType seed entries for C1.6–C1.18 + C2

#### Phase 19 — Code Quality (P21)
- [ ] Task 19.3: Add SoftDeletes migration for 40 models

---

### SKILL: Testing (Pest 4.x)

#### Phase 18 (P20)
- [ ] Task 18.1: Unit tests for FETSolver (8+ test cases)
- [ ] Task 18.2: Unit tests for ConstraintManager + ConstraintEvaluator (8+ test cases)
- [ ] Task 18.3: Unit tests for new constraint PHP classes (2 per category)
- [ ] Task 18.4: Feature tests for key controllers (3 controllers)

---

### SKILL: Cleanup (Refactoring / Dead Code)

#### Phase 6 (P08)
- [ ] Task 6.4: Delete dead code (backup controller, copy directories, variant views)

#### Phase 19 (P21)
- [ ] Task 19.1: Split SmartTimetableController into 4 controllers
- [ ] Task 19.2: Convert 16 controllers inline validation to FormRequests
- [ ] Task 19.4: Delete debug methods, backup files, copy directories

---

## Milestone Checkpoints

| Milestone | After Prompts | Completion % | Capability |
|-----------|--------------|-------------|-----------|
| **Safe for Demo** | P01–P04 | ~70% | No crashes, auth on all routes |
| **School Deployable** | + P05–P08 | ~80% | Activity constraints, rooms, stubs |
| **Constraint Foundation** | + P09 | ~82% | Plugin system, evaluator, groups |
| **Core Constraints** | + P10–P13 | ~90% | 110+ constraint rules enforced |
| **Full Features** | + P14–P19 | ~95% | Analytics, refinement, substitution, API |
| **Production Ready** | + P20–P21 | ~98% | Tests, code quality, cleanup |

---

## Quick Reference: Suggested Weekly Execution

```
Week 1:  P01 + P02 + P03 + P04 (bugs + security) — Model: Sonnet
Week 2:  P05 + P06 (activity constraints + performance) — Model: Sonnet
Week 3:  P07 + P08 (room allocation + stubs) — Model: Sonnet
Week 4:  P09 (constraint architecture) — Model: Opus
Week 5:  P10 (teacher constraints) — Model: Sonnet
Week 6:  P11 + P12 (class constraints + inter-activity pt1) — Model: Sonnet
Week 7:  P13 + P19 (inter-activity pt2 + global/DB classes) — Model: Sonnet
Week 8:  P14 (analytics) — Model: Sonnet
Week 9:  P15 + P18 (refinement + room constraints) — Model: Sonnet
Week 10: P16 + P17 (substitution + API) — Model: Sonnet
Week 11: P20 (testing) — Model: Sonnet
Week 12: P21 (code quality) — Model: Sonnet
```

P01 + P02 + P03 + P04 (bugs + security)
P05 + P06 (activity constraints + performance)
P07 + P08 (room allocation + stubs)
P09 (constraint architecture)
P10 (teacher constraints)t
P11 + P12 (class constraints + inter-activity pt1)
P13 + P19 (inter-activity pt2 + global/DB classes)
P14 (analytics)
P15 + P18 (refinement + room constraints)
P16 + P17 (substitution + API)
P20 (testing)
P21 (code quality)
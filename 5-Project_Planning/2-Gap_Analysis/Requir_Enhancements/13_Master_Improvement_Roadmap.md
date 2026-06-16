# 13 — Master Improvement Roadmap

## Executive Summary

This roadmap consolidates all findings from the 12-phase engineering audit into a prioritized action plan. The audit identified **8 bugs**, **12 security issues**, **49 database schema issues**, **13 N+1 query problems**, **11 performance anti-patterns**, **8 oversized controllers**, and significant architectural gaps (zero caching, missing service layer, circular dependencies).

---

## Severity Distribution

| Category | Critical | High | Medium | Low | Total |
|----------|----------|------|--------|-----|-------|
| Bugs | 2 | 1 | 3 | 2 | 8 |
| Security | 4 | 4 | 4 | 0 | 12 |
| Database Schema | 14 | 13 | 12 | 10 | 49 |
| N+1 Queries | 0 | 4 | 7 | 2 | 13 |
| Performance | 0 | 7 | 4 | 0 | 11 |
| Code Quality | 3 | 4 | 5 | 3 | 15 |
| Controller Size | 2 | 3 | 2 | 1 | 8 |
| Architecture | 0 | 5 | 4 | 2 | 11 |
| **TOTAL** | **25** | **41** | **41** | **20** | **127** |

---

## Phase 1: CRITICAL — Immediate Action (Week 1)

**Goal:** Fix production-breaking bugs and critical security vulnerabilities.

### 1.1 Security Fixes (Day 1-2)

| # | Action | Reference | Effort |
|---|--------|-----------|--------|
| 1 | Remove `is_super_admin`, `super_admin_flag`, `remember_token` from User `$fillable` | SEC-002 | 15 min |
| 2 | Move payment webhook route outside auth middleware group | SEC-004 | 15 min |
| 3 | Add gateway whitelist + reject unknown gateways in webhook handler | SEC-005 | 30 min |
| 4 | Remove or protect `seeder/run` route with auth + super-admin check | SEC-008 | 15 min |
| 5 | Change `$request->all()` to `$request->validated()` in TenantController | SEC-001 | 15 min |
| 6 | Add `Gate::authorize()` to all SmartTimetableController methods | SEC-009 | 2 hours |
| 7 | Move `PaymentWebhook::create()` after signature verification | SEC-012 | 15 min |
| 8 | Change `env('APP_DOMAIN')` to `config('app.domain')` in routes/web.php | SEC-011 | 30 min |

### 1.2 Bug Fixes (Day 2-3)

| # | Action | Reference | Effort |
|---|--------|-----------|--------|
| 9 | Add missing model imports in AppServiceProvider (TptVehicleFuel, AttendanceDevice, TptFineMaster) | BUG-001 | 15 min |
| 10 | Fix duplicate policy registrations — redesign policy mapping approach | BUG-002 | 4 hours |
| 11 | Uncomment MigrateDatabase + CreateRootUser in TenancyServiceProvider | BUG-004 | 15 min |
| 12 | Fix wrong permission check `prime.tenant-group.update` → `prime.tenant.update` | BUG-005 | 15 min |
| 13 | Add null-safe operator in Student::currentFeeAssignemnt() | BUG-007 | 5 min |

### 1.3 Production Crash Prevention (Day 1)

| # | Action | Reference | Effort |
|---|--------|-----------|--------|
| 14 | Remove `dd()` calls from ComplaintController (lines 393, 819) | DC-006 | 5 min |
| 15 | Remove `dd($e)` from LmsExamController, add proper error handling | DC-006 | 15 min |
| 16 | Remove all test/debug routes from tenant.php | SEC-010 | 30 min |

**Phase 1 Total Effort: ~2-3 days**

---

## Phase 2: HIGH — Foundation Fixes (Week 2-4)

**Goal:** Fix database integrity, add caching, begin controller refactoring.

### 2.1 Database Schema Fixes (Week 2)

| # | Action | Reference | Effort |
|---|--------|-----------|--------|
| 17 | Fix all 12 DDL syntax errors in prime_db.sql | DB-001 to DB-012 | 4 hours |
| 18 | Fix FK references to non-existent tables (`sys_modules` → `glb_modules`, `users` → `sys_users`) | FK-009, FK-010 | 1 hour |
| 19 | Add `student_id` column to `tpt_student_event_log` | TS-003 | 30 min |
| 20 | Fix FK type mismatches (signed vs unsigned) in prm_plans, prm_tenant_domains | DT-001, DT-002 | 1 hour |
| 21 | Uncomment/enable FK constraints on NOT NULL columns | FK-003, FK-005 | 30 min |
| 22 | Add composite unique indexes to junction tables | JNT-001, JNT-003, JNT-004 | 1 hour |
| 23 | Fix `sch_class_section_jnt.ordinal` unique constraint to per-class | JNT-005 | 30 min |
| 24 | Add missing FK for `tpt_vehicle.vendor_id` | FK-001 | 15 min |
| 25 | Fix Teacher model fillable vs migration mismatch | MDL-001 | 1 hour |

### 2.2 Application Caching (Week 2-3)

| # | Action | Reference | Effort |
|---|--------|-----------|--------|
| 26 | Implement caching for dropdown values (1 hour TTL) | CACHE-001 | 4 hours |
| 27 | Cache academic sessions per tenant | CACHE-001 | 2 hours |
| 28 | Cache permission/role lookups (Spatie config) | CACHE-001 | 1 hour |
| 29 | Cache room types, study formats, subject types | CACHE-001 | 2 hours |
| 30 | Cache settings per tenant | CACHE-001 | 1 hour |

### 2.3 Critical N+1 Fixes (Week 3)

| # | Action | Reference | Effort |
|---|--------|-----------|--------|
| 31 | Fix ComplaintController: add pagination + pre-load dropdown values | N1-007 | 2 hours |
| 32 | Fix TripController::bulkApprove: eager load relationship chain | N1-011 | 1 hour |
| 33 | Fix AttendanceController: replace updateOrCreate loop with DB::upsert | PERF-010 | 2 hours |
| 34 | Fix QuestionBankController: pre-load for import validation | PERF-006 | 2 hours |
| 35 | Add composite index on `std_student_academic_sessions(is_current, class_section_id)` | IDX-002 | 15 min |

### 2.4 Dead Code Cleanup (Week 3)

| # | Action | Reference | Effort |
|---|--------|-----------|--------|
| 36 | Delete all backup/copy controller files (7 files) | DC-002 | 15 min |
| 37 | Delete `EXTRA_delete_10_02/` directory (14 files) | DC-003 | 5 min |
| 38 | Delete backup/copy files (6 files) | DC-001 | 10 min |
| 39 | Remove misplaced files from Controllers directories | DC-004, DC-005 | 5 min |
| 40 | Remove Faker import from production controllers | CQ-003 | 5 min |
| 41 | Remove large commented-out code blocks | DC-005 | 30 min |

**Phase 2 Total Effort: ~2-3 weeks**

---

## Phase 3: MEDIUM — Architecture Improvements (Week 5-10)

**Goal:** Refactor God controllers, create service layer, resolve module coupling.

### 3.1 Controller Refactoring (Week 5-7)

| # | Action | Reference | Effort |
|---|--------|-----------|--------|
| 42 | Split SmartTimetableController into 5 controllers + 3 services | CTRL-001 | 5 days |
| 43 | Split StudentController into 6 controllers | CTRL-002 | 3 days |
| 44 | Extract ActivityGenerationService from ActivityController | CTRL-003 | 2 days |
| 45 | Extract ComplaintEscalationService, remove duplicate logic | CTRL-004, CQ-005 | 1 day |
| 46 | Fix LmsExamController error handling, extract ExamPaperService | CTRL-005 | 1 day |
| 47 | Remove `SET FOREIGN_KEY_CHECKS=0` from ActivityController | ARCH-004 | 1 day |

### 3.2 Performance Optimization (Week 7-8)

| # | Action | Reference | Effort |
|---|--------|-----------|--------|
| 48 | Convert SchoolClassController::index to AJAX-loaded tabs | PERF-001 | 2 days |
| 49 | Convert NotificationManageController::index to AJAX tabs | PERF-003 | 1 day |
| 50 | Replace `Model::all()` with filtered/paginated queries (110+ instances) | PERF-005 | 3 days |
| 51 | Fix ActivityScoreService batch operations | PERF-008, PERF-009 | 1 day |
| 52 | Fix ActivityController::generateActivities query optimization | PERF-007 | 2 days |

### 3.3 Code Quality (Week 8-9)

| # | Action | Reference | Effort |
|---|--------|-----------|--------|
| 53 | Extract activity logging boilerplate into trait | CQ-004 | 1 day |
| 54 | Extract change tracking boilerplate into trait | CQ-004 | 1 day |
| 55 | Extract toggle status boilerplate into trait | CQ-004 | 4 hours |
| 56 | Replace `central-127.0.0.1` hardcoded routes | CQ-001 | 2 hours |
| 57 | Replace hardcoded dropdown IDs with constants | CQ-002 | 1 hour |
| 58 | Standardize authorization patterns across modules | CQ-006 | 2 days |

### 3.4 Module Architecture (Week 9-10)

| # | Action | Reference | Effort |
|---|--------|-----------|--------|
| 59 | Resolve SchoolSetup ↔ SmartTimetable circular dependency | ARCH-003 | 2 days |
| 60 | Replace session storage with DB-backed temporary storage for timetable generation | ARCH-005 | 1 day |
| 61 | Add FormRequest classes for complex inline validations | ARCH-006 | 3 days |
| 62 | Implement constructor/method injection in all controllers with services | ARCH-007 | 1 day |

**Phase 3 Total Effort: ~5-6 weeks**

---

## Phase 4: LOW — Enhancement & Polish (Week 11+)

**Goal:** Database normalization, testing, API improvements, monitoring.

### 4.1 Database Improvements

| # | Action | Reference | Effort |
|---|--------|-----------|--------|
| 63 | Standardize ENUM columns to FK references to `sys_dropdown_table` | ENUM-001 to ENUM-005 | 3 days |
| 64 | Add missing indexes (IDX-001 to IDX-009) | Multiple | 1 day |
| 65 | Add missing FK constraints for commented-out FKs | FK-003 to FK-008 | 1 day |
| 66 | Normalize JSON columns in `sch_teachers` if reporting needed | JSON-001 | 2 days |
| 67 | Fix naming inconsistencies (house → house_id, reason_quit → reason_quit_id) | NAME-002, NAME-003 | 1 hour |
| 68 | Add timestamps to tables missing them | TS-001, TS-002 | 1 hour |
| 69 | Populate TptStudentEventLog model properly | MDL-002 | 1 hour |

### 4.2 Testing

| # | Action | Reference | Effort |
|---|--------|-----------|--------|
| 70 | Add feature tests for critical auth flows | ARCH testing gap | 3 days |
| 71 | Add feature tests for payment webhook handling | SEC-004, SEC-005 | 2 days |
| 72 | Add unit tests for new services (from Phase 3) | ARCH-001 | 5 days |
| 73 | Add multi-tenant data isolation tests | Architecture | 3 days |

### 4.3 API & Infrastructure

| # | Action | Reference | Effort |
|---|--------|-----------|--------|
| 74 | Add event-driven cross-module communication | ARCH event gaps | 5 days |
| 75 | Add API documentation (OpenAPI/Swagger) | ARCH-008 | 3 days |
| 76 | Add API response transformers | ARCH-008 | 3 days |
| 77 | Fix `#tanent` typo across codebase | CQ-007 | 15 min |

**Phase 4 Total Effort: ~4-5 weeks**

---

## Timeline Summary

```
Week 1       ████ Phase 1: Critical Fixes (Security + Bugs + dd() removal)
Week 2-4     ████████████ Phase 2: Foundation (DB schema + Caching + N+1 + Dead code)
Week 5-10    ████████████████████████ Phase 3: Architecture (Refactoring + Performance + Quality)
Week 11+     ████████████████ Phase 4: Enhancement (Testing + API + Polish)
```

---

## Key Metrics to Track

| Metric | Current | Target (Phase 2) | Target (Phase 4) |
|--------|---------|-------------------|-------------------|
| Critical security issues | 4 | 0 | 0 |
| Active `dd()` in production | 3 | 0 | 0 |
| DDL syntax errors | 12 | 0 | 0 |
| Application cache usage | 0 | 5+ cache layers | 10+ cache layers |
| Controllers > 500 lines | 5 | 3 | 0 |
| Modules with services | 6 | 8 | 12+ |
| Test coverage | ~0% | 10% | 40%+ |
| N+1 query issues | 13 | 5 | 0 |
| Model::all() instances | 110+ | 50 | <10 |
| Dead code files | 27+ | 0 | 0 |

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Security breach via SEC-002/SEC-005 | High | Critical | Phase 1, Day 1 |
| Payment failures via SEC-004 | Certain | High | Phase 1, Day 1 |
| Data corruption via unprotected seeder route | Medium | High | Phase 1, Day 1 |
| Memory exhaustion from Model::all() | Medium | High | Phase 2 caching + Phase 3 optimization |
| Session overflow from timetable generation | Low | Medium | Phase 3 |
| Regression from controller refactoring | Medium | Medium | Add tests before refactoring |

---

## Files Reference

| Report | File | Key Findings |
|--------|------|-------------|
| Project Structure | `01_Project_Structure.md` | 29 modules, 381 models, 283 controllers |
| Module Analysis | `02_Module_Analysis.md` | Module inventory and dependencies |
| Route-Controller-Model Map | `03_Route_Controller_Model_Map.md` | Complete endpoint mapping |
| Bug Report | `04_Bug_Report.md` | 8 bugs (2 critical) |
| Performance Bottlenecks | `05_Performance_Bottlenecks.md` | 11 anti-patterns, zero caching |
| Security Audit | `06_Security_Audit.md` | 12 issues (4 critical) |
| Database Schema Review | `07_Database_Schema_Review.md` | 49 issues (14 critical DDL errors) |
| Code Quality Report | `08_Code_Quality_Report.md` | Dead code, dd() calls, boilerplate |
| Controller Refactoring | `09_Controller_Refactoring_Report.md` | 8 oversized controllers |
| N+1 Query Report | `10_N_Plus_One_Query_Report.md` | 13 N+1 issues |
| Architecture Review | `11_Architecture_Review.md` | Missing service layer, circular deps |
| System Diagrams | `12_System_Diagrams.md` | 8 Mermaid diagrams |
| Master Roadmap | `13_Master_Improvement_Roadmap.md` | This file |

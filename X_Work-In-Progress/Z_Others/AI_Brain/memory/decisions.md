# Architectural Decisions Log

## Confirmed Decisions

### D1: Multi-Tenancy — stancl/tenancy v3.9 with Database-per-Tenant
- **Why:** Complete data isolation for each school. Regulatory compliance for Indian schools (data sovereignty). Simpler backup/restore per tenant. No risk of cross-tenant data leakage.
- **Trade-off:** Higher infrastructure cost (one DB per school), more complex migration management.
- **Alternative considered:** Shared DB with `tenant_id` column — rejected due to data isolation requirements.

### D2: Modular Architecture — nwidart/laravel-modules v12.0
- **Why:** ~40 planned modules. Each module is self-contained with its own models, controllers, routes, migrations. Enables independent development and testing. Clear separation of concerns.
- **Trade-off:** Slightly more boilerplate per module, module interdependency management needed.

### D3: 3-Layer Database Architecture
- **Why:** Separation of shared reference data (global_db), SaaS management (prime_db), and school data (tenant_db). Global masters shared without duplication. Central billing independent of tenant databases.
- **global_db:** Countries, states, boards, languages, menus, modules
- **prime_db:** Tenants, plans, billing, central users/roles
- **tenant_db:** Per-school everything (students, teachers, timetable, fees, etc.)

### D4: RBAC — Spatie Laravel Permission v6.21
- **Why:** Mature, well-documented, polymorphic role/permission assignment. Supports both central and tenant-scoped roles. Gate and middleware integration.
- **Implementation:** Roles and permissions exist in BOTH central (prime_db) and tenant (tenant_db) databases.

### D5: UUID-based Tenant Identification
- **Why:** Prevents enumeration attacks, globally unique across all environments, no conflicts during tenant migration.
- **Generator:** `Stancl\Tenancy\UUIDGenerator`

### D6: Domain-based Tenant Routing
- **Why:** Each school gets its own subdomain (e.g., `schoolname.prime-ai.com`). Clean URL structure, easy to manage with DNS.
- **Middleware:** `InitializeTenancyByDomain`

### D7: Table Prefix Convention
- **Why:** With 368+ tables in tenant_db, prefixes provide immediate module identification. `tt_` for timetable, `std_` for students, `sch_` for school setup, etc.
- **Junction tables:** Suffixed with `_jnt` for easy identification.

### D8: Soft Deletes Everywhere
- **Why:** Audit trail requirements. Schools need to recover accidentally deleted records. Regulatory compliance for attendance and exam records.
- **Implementation:** `is_active` boolean + `deleted_at` timestamp on every table.

### D9: DomPDF for PDF Generation
- **Why:** No external service dependency, works server-side, sufficient for report cards, fee receipts, and HPC documents.
- **Package:** `barryvdh/laravel-dompdf` v3.1

### D10: Razorpay for Payment Processing
- **Why:** Most popular payment gateway in India. Supports UPI, cards, net banking, wallets. Well-documented PHP SDK.
- **Package:** `razorpay/razorpay` v2.9

### D11: SmartTimetable — FET-inspired Solver
- **Why:** FET (Free Timetabling Software) algorithm is proven for school timetabling. CSP backtracking with greedy fallback, rescue pass, and forced placement. Handles complex constraints.
- **Architecture:** Activity-based scheduling with 10-stage implementation plan.

### D12: Database Queue Driver (Current)
- **Why:** Simpler infrastructure for initial deployment. No Redis dependency needed.
- **Future:** Will migrate to Redis queue driver when scaling requires it.

### D17: SmartTimetable Constraint Model/Migration Mismatches — Audit & Fix Strategy
- **Mismatch A:** ConstraintCategory/ConstraintScope pointed to non-existent tables. **Fix:** Both now use `tt_constraint_category_scope` with `addGlobalScope` for `type`. ConstraintCategoryScope is the raw combined-table model.
- **Mismatch B:** ConstraintType fillable had columns not in DB (`is_hard_capable`, `parameter_schema`, etc.). **Fix:** Migration 1 adds them additively; old `is_hard_constraint`/`param_schema` kept.
- **Mismatch C:** Constraint model column names differed from DB (`academic_term_id` vs `academic_session_id`, etc.). **Fix (model-side):** Updated model to use actual DB column names. Migration 2 adds alias columns for compat.
- **Rule:** Corrective migrations are additive only — no drops, no renames.

### D16: SmartTimetable Constraint Management — Static Catalogue View Pattern
- **Why:** The constraint management page is a documentation/configuration catalogue, not CRUD over a single DB table. Different tabs represent different constraint categories each with different columns and semantics.
- **Pattern:** One route + one controller method returning 8 empty `collect()` vars. Index blade uses 8-tab nav-tab. Each tab `@include`s its own `partials/{slug}/_list.blade.php`. Static `@php` sample rows in each partial — replace with DB data when constraint engine is wired.
- **PHP Class column (db-constraints tab):** Badge `Registered` (bg-primary) if wired in `CONSTRAINT_CLASS_MAP`, `Not wired` (bg-warning text-dark) if not.
- **Read-only tabs:** `engine-rules` (always-on hardcoded, no Add/Trash) and `activity-constraints` (fields on `tt_activities`, no Action col).

---

## Future Decisions (Pending)

### Pending: Event Engine Architecture
- Need to decide: Event-driven vs scheduled polling for cross-module communication
- Status: Module at 20% completion

### Pending: Analytics Pipeline
- Need to decide: Real-time vs batch processing for student analytics
- Options: Laravel Jobs + Cache vs dedicated analytics service

### Pending: Student/Parent Portal
- Need to decide: Same Laravel app with role-based views vs separate SPA
- Options: Blade views vs Vue.js/React SPA

### Pending: Accounting Module
- Need to decide: Build custom vs integrate with existing accounting software
- Double-entry bookkeeping requirements

### Pending: Redis Migration
- When to move queue, cache, and session drivers from database to Redis
- Dependent on production traffic patterns

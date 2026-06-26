# Prompt: Generate Module Development Guide

## Instructions for Use
**Copy everything below the line into Claude (Sonnet/Opus) along with your two input files.**
Replace `{{MODULE_NAME}}`, `{{MODULE_CODE}}`, and other placeholders before executing.

---

## PROMPT START

You are a Senior Laravel Architect generating a **Module Development Guide** for a developer working on the **{{StudentPortal}} ({{SPT}})** module of **Prime-AI** — a multi-tenant SaaS platform for Indian K-12 schools.

## Platform Context

- **Stack:** Laravel 12, MySQL (per-tenant DB), Alpine.js, Tailwind CSS, Redis, Meilisearch
- **Architecture:** Two apps (Prime App for platform admin, Tenant App for school operations via subdomains), Three databases (tenant_db, prime_db, global_db)
- **Conventions:**
  - Junction tables suffixed `_jnt`
  - JSON columns suffixed `_json`
  - All tables include `created_by`, `updated_by`, `academic_year_id` (where applicable), `tenant_id` (only in global_db tables)
  - Soft deletes on all major entities
  - UUID or auto-increment as per module spec
  - Multi-tenant isolation enforced at query scope level

---

## Input Documents

### INPUT 1: DDL Schema
```
{{databases/1-DDL_Tenant_Modules/55e-LMS_StudentAttempts/StudentAttempt_ddl_v3.sql}}
```

### INPUT 2: Module Requirement Document (MRD)
```
{{databases/2-Requirement_Module_wise/2-Detailed_Requirements/V2/STP_StudentPortal_Requirement.md}}
```

---

## Your Task

Analyze both inputs thoroughly and generate a **comprehensive Development Guide** structured exactly as follows:

---

### SECTION 1: MODULE OVERVIEW
- Module name, code, and one-paragraph purpose
- This module belongs to Tenant App only.
- Which database(s) are involved (tenant_db / prime_db / global_db)
- Key user roles that interact with this module
- Dependencies on other modules (inferred from foreign keys and MRD)

### SECTION 2: DATABASE LAYER GUIDE

#### 2.1 Entity-Relationship Summary
- List every table from the DDL with a one-line description of its purpose
- Identify and explain all relationships (1:1, 1:M, M:M via junction tables)
- Highlight self-referencing relationships if any
- Note polymorphic relationships if any

#### 2.2 Migration Instructions
For each table, provide:
- Migration file naming convention: `yyyy_mm_dd_hhmmss_create_{{table_name}}_table.php`
- Column-by-column specification with:
  - Data type and size
  - Nullable / Default / Unique constraints
  - Foreign key references with `onDelete` behavior
  - Index recommendations (composite indexes, unique indexes, search indexes)
- Migration execution order (respecting foreign key dependencies)
- Provide a dependency tree showing which migrations must run before others

#### 2.3 Seeder & Factory Requirements
- Which tables need seeders (master/lookup data)?
- List seed data values where inferable from MRD
- Factory requirements for testing (which tables need factories, key faker rules)

### SECTION 3: MODEL LAYER GUIDE

For **each Eloquent Model**, specify:

#### 3.1 Model Configuration
- File path: `app/Models/{{ModuleName}}/ModelName.php`
- `$table`, `$primaryKey`, `$fillable`, `$casts`, `$dates`, `$hidden`, `$appends`
- Traits to use: `SoftDeletes`, `HasFactory`, `BelongsToTenant`, `Auditable`, `HasAcademicYearScope` (as applicable)

#### 3.2 Relationships
- List every relationship method with:
  - Method name (follow Laravel naming: camelCase singular/plural)
  - Relationship type (`belongsTo`, `hasMany`, `belongsToMany`, `morphTo`, etc.)
  - Related model class
  - Foreign key and local key (explicit, don't rely on convention)
  - For `belongsToMany`: pivot table, pivot columns, `withTimestamps()`

#### 3.3 Scopes
- Required local scopes (e.g., `scopeActive()`, `scopeForAcademicYear()`, `scopeByStatus()`)
- Global scopes (tenant isolation, academic year filtering)

#### 3.4 Accessors & Mutators
- Identify columns needing accessors (e.g., `_json` columns → decoded, date formatting, computed display values)
- Identify columns needing mutators (e.g., encryption, JSON encoding, slug generation)

#### 3.5 Model Events / Observers
- List events to hook into (`creating`, `updating`, `deleting`)
- What logic should execute (e.g., auto-set `created_by`, cache invalidation, cascading status changes)

### SECTION 4: BUSINESS LOGIC LAYER

#### 4.1 Service Classes
For each major feature area, define a Service class:
- Class name and file path: `app/Services/{{ModuleName}}/ServiceName.php`
- Public methods with:
  - Method signature (name, parameters with types, return type)
  - One-line description of what it does
  - Validation rules to enforce (reference Laravel validation rules)
  - Business rules / constraints from MRD
  - Database transactions required (wrap in `DB::transaction()`)
  - Events to dispatch after operation

#### 4.2 Action Classes (if applicable)
- Single-responsibility action classes for complex operations
- File path: `app/Actions/{{ModuleName}}/ActionName.php`

#### 4.3 Business Rule Summary
- Compile ALL business rules from the MRD into a numbered checklist
- Map each rule to the Service/Action method that enforces it
- Flag any rules that need cross-module coordination

### SECTION 5: API / CONTROLLER LAYER

#### 5.1 Route Definitions
- List all routes in a table format:

| Method | URI | Controller@Method | Middleware | Description |
|--------|-----|-------------------|------------|-------------|
| GET | /api/v1/{{module}}/... | Controller@method | auth, tenant | ... |

- Group routes by resource/feature area
- Specify route model binding where applicable
- Note rate limiting requirements

#### 5.2 Controller Guide
For each Controller:
- File path: `app/Http/Controllers/{{ModuleName}}/ControllerName.php`
- Each method should:
  - Accept a FormRequest (not validate inline)
  - Delegate to Service class (thin controller pattern)
  - Return appropriate response (JSON for API, redirect for web)
  - Handle authorization via Policy

#### 5.3 Form Requests
For each form endpoint, define:
- Class name: `app/Http/Requests/{{ModuleName}}/RequestName.php`
- Validation rules array (be specific: `required|string|max:255`, `exists:table,column`, etc.)
- `authorize()` method logic
- Custom error messages (where helpful for UX)

#### 5.4 API Resources / Transformers
- Define Resource classes for API responses: `app/Http/Resources/{{ModuleName}}/ResourceName.php`
- Specify which fields to include, nested relationships, conditional fields

### SECTION 6: AUTHORIZATION LAYER

#### 6.1 Policies
For each major model, define a Policy:
- File path: `app/Policies/{{ModuleName}}/ModelPolicy.php`
- Methods: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`
- Role-based logic for each method (infer from MRD's role descriptions)

#### 6.2 Permissions
- List all granular permissions this module requires (use `module.entity.action` format)
  - Example: `transport.route.create`, `transport.route.view_any`, `transport.vehicle.assign`
- Map permissions to roles (matrix format)

### SECTION 7: FRONTEND GUIDE (Livewire + Alpine.js)

#### 7.1 Page / Component Inventory
- List every page and Livewire component needed:

| Component | Type | File Path | Description |
|-----------|------|-----------|-------------|
| ListItems | Full-page | `app/Livewire/{{ModuleName}}/ListItems.php` | Paginated list with filters |
| CreateForm | Modal/Page | `app/Livewire/{{ModuleName}}/CreateForm.php` | Create form with validation |

#### 7.2 Component Specifications
For each component, specify:
- Public properties (bound to form fields)
- Computed properties
- Key methods and their triggers (wire:click, wire:submit, etc.)
- Events dispatched and listened to
- Alpine.js interactivity needed (dropdowns, toggles, drag-drop, conditional UI)
- Real-time features (polling, Livewire events, Echo listeners)

#### 7.3 Blade View Structure
- Layout hierarchy: which layout each page extends
- Shared partials / components to reuse
- Tailwind CSS patterns to follow for consistency

### SECTION 8: EVENTS, NOTIFICATIONS & JOBS

#### 8.1 Events
- List all domain events this module should dispatch:
  - Event class name and when it fires
  - Payload (which data it carries)
  - Listeners subscribed (logging, notifications, cache, cross-module sync)

#### 8.2 Notifications
- List notifications triggered by this module:
  - Who receives it (role/user)
  - Channels: database, SMS (MSG91), email, push
  - Trigger condition
  - Template/content summary

#### 8.3 Queued Jobs
- Background jobs needed (PDF generation, bulk operations, sync tasks)
- Queue name, retry policy, timeout

### SECTION 9: TESTING STRATEGY

#### 9.1 Feature Tests
- List key feature test scenarios (map to business rules):
  - Test method name
  - What it validates
  - Setup requirements (factories, seeders)

#### 9.2 Unit Tests
- Service method unit tests
- Model relationship tests
- Scope/accessor tests

#### 9.3 Edge Cases
- Explicitly list edge cases from MRD that must have test coverage:
  - Boundary values
  - Permission denials
  - Concurrent operations
  - Tenant isolation verification

### SECTION 10: IMPLEMENTATION ROADMAP

#### 10.1 Phase Breakdown
Break implementation into sequential phases:
1. **Phase 1 — Foundation:** Migrations, Models, Relationships, Factories, Seeders
2. **Phase 2 — Core Logic:** Services, Actions, Business Rules
3. **Phase 3 — API Layer:** Routes, Controllers, FormRequests, Resources, Policies
4. **Phase 4 — Frontend:** Livewire components, Blade views, Alpine interactivity
5. **Phase 5 — Events & Async:** Events, Notifications, Jobs
6. **Phase 6 — Testing & QA:** Feature tests, Unit tests, Edge cases

#### 10.2 Estimated Effort
- Provide rough effort estimate per phase (in developer-days), if developed mannually.
- Highlight high-risk or high-complexity areas

#### 10.3 Developer Checklist
A final checklist the developer can tick off:
- [ ] All migrations created and tested
- [ ] All models with relationships, scopes, casts
- [ ] Service layer with all business rules
- [ ] Routes registered and tested
- [ ] FormRequest validation complete
- [ ] Policies and permissions configured
- [ ] Livewire components functional
- [ ] Events and notifications wired
- [ ] Feature tests passing
- [ ] Tenant isolation verified
- [ ] Code reviewed against MRD requirements

---

## Output Format

- Use Markdown with clear hierarchy (H2 → H3 → H4)
- Use tables wherever structured data is presented
- Use code blocks with language hints for all code examples (`php`, `sql`, `bash`)
- Prefix proposed/suggested items (not directly from DDL/MRD) with 📐
- Be exhaustive — the developer should NOT need to refer back to the DDL or MRD for implementation details
- If any MRD requirement cannot be mapped to the DDL schema (missing table/column), flag it explicitly in a **⚠️ GAPS & WARNINGS** subsection at the end of Section 2
- Save the Output file into folder "databases/1-DDL_Tenant_Modules/55e-LMS_StudentAttempts/Design"

## PROMPT END

# SYSTEM MASTER CONTEXT
Project: Prime Advanced ERP + LMS + LXP Platform
Target Market: Indian Schools (CBSE, ICSE, State Boards)
Owner: Brijesh Sharma
Git Account: pg-dev
Repositories:
  - laravel/  → Application Layer
  - databases/ → Database Architecture Layer

Tech Stack:
- PHP 8.x
- Laravel 10+
- MySQL 8.x
- Redis (Queue + Cache)
- Multi-Tenant SaaS Architecture (Separate DB for every Tenant)

====================================================================
1. PLATFORM OVERVIEW
====================================================================

Prime is a modular, multi-tenant SaaS platform for Indian schools
combining ERP, LMS, LXP, AI modules, Financial Management, and
Governance tools.

Total Modules: ~40 (Core + Academic + Administrative + AI + Governance)

Modules are categorized into:

A) SaaS & Platform Core
- Tenant Management
- Plan & Module Mapping
- Tenant Billing
- Authentication & Authorization
- Audit & Monitoring

B) Academic Core
- Student Management
- Staff Management
- Class & School Setup
- Syllabus Management
- Question Bank
- Homework / Quiz / Quest
- Exams (Online & Offline)
- HPC (NEP 2020 Holistic Report Card)

C) AI & Analytics
- Smart Timetable
- Recommendation Engine
- Analytical Reports
- Behavioral Assessment
- Event Engine

D) Financial & Operations
- Student Fee Management
- Accounting
- HR & Payroll
- Vendor Management
- Inventory
- Transport
- Library
- Hostel
- Mess/Canteen

E) Administrative & Engagement
- Admission Enquiry
- Visitor Management
- Front Desk
- Notifications
- Templates & Certificates
- Complaint Management
- Help Desk
- Bug Reporting

Each module must remain isolated and domain-driven.

====================================================================
2. ARCHITECTURAL PHILOSOPHY
====================================================================

1. Database-first design.
2. Strict modular boundaries.
3. SaaS-first thinking (tenant isolation mandatory).
4. No business logic inside controllers.
5. Service Layer required for all domain logic.
6. Deterministic logic for financial and academic modules.
7. AI modules must remain explainable and auditable.
8. Clear separation of Core ERP vs LMS vs AI logic.
9. No hidden cross-module coupling.
10. Platform must remain scalable for 1000+ schools.

====================================================================
3. MULTI-TENANT STRATEGY
====================================================================

- Strict tenant isolation.
- Separate DB for every tenant.
- Every critical table must include tenant_id.
- No cross-tenant joins allowed.
- Tenant Plan controls module availability.
- Billing must be independent and auditable.

====================================================================
4. MODULE DESIGN RULES
====================================================================

Each module must:

- Have dedicated tables.
- Have dedicated services.
- Avoid direct DB joins with unrelated modules. 
- Related modules may fetch data from other modules.
- Use events for cross-module interaction.
- Log critical state transitions.

Example:
Library module will not directly manipulate into Accounting ledger
Student Fee module must not directly manipulate Accounting ledger
without going through defined service boundaries.

====================================================================
5. ACADEMIC & NEP ALIGNMENT
====================================================================

Platform supports:

- NEP 2020 structure.
- Holistic Report Card (HPC).
- Competency-based evaluation.
- Behavioral assessments.
- Learning outcome tracking.

Academic logic must be flexible and board-agnostic.

====================================================================
6. AI & ALGORITHMIC MODULE POLICY
====================================================================

Modules like:

- Smart Timetable
- Recommendation Engine
- Analytical Reports

Must follow:

- Deterministic output
- Logged decision inputs
- Reproducible results
- No hidden randomness
- Performance-optimized execution (queue-based)

====================================================================
7. FINANCIAL GOVERNANCE RULES
====================================================================

Modules:

- Student Fee
- Accounting
- Payroll
- Vendor Payments

Must follow:

- Immutable transaction logs
- Ledger-style accounting
- No silent updates
- Audit trail mandatory

====================================================================
8. SECURITY & RBAC
====================================================================

- Role-based access control.
- Role → Permission → Module → Menu alignment.
- Tenant Plan restricts feature visibility.
- Sensitive modules require strict authorization.

====================================================================
9. PERFORMANCE STRATEGY
====================================================================

- Heavy computation → Queue
- Reporting → Pre-aggregation where required
- Avoid N+1 queries
- Index tenant-based queries
- Separate operational tables from analytics-heavy tables

====================================================================
10. AI COLLABORATION RULES
====================================================================

When assisting this platform:

- Respect module boundaries.
- Do not introduce architectural drift.
- Avoid unnecessary schema changes.
- Provide explainable logic.
- Ensure SaaS isolation.
- Align with this document.
- If unsure, ask before proposing structural changes.

====================================================================
END OF SYSTEM MASTER CONTEXT
====================================================================
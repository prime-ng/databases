---
globs: ["Modules/Hpc/**", "database/migrations/tenant/*hpc*"]
---

# HPC (Holistic Progress Card) Module Rules

## Key Decision (D13)
DomPDF template pattern — merged single-file approach:
- **NO** Blade components (`<x-hpc-form.*>`) in PDF templates
- **NO** Bootstrap classes — use inline styles only
- **NO** flexbox/grid — use `<table>` for all layouts
- **NO** JavaScript
- One merged `*_pdf.blade.php` per template form
- Contains: `$css` array, helper closures, full `<!DOCTYPE html>` document

## Key Facts (updated 2026-03-16 from comprehensive gap analysis)

### Module Stats
- Controllers: 15 (HpcController ~2297 lines — god controller)
- Models: 26 (all use SoftDeletes)
- Services: 2 (HpcReportService 788 lines, HpcPdfDataService 165 lines)
- FormRequests: 14 (7 return true in authorize())
- Jobs: 1 (SendHpcReportEmail)
- Mailables: 1 (HpcReportMail)
- Blade views: ~232 (138 form partials + 4 PDF templates + CRUD views)
- Routes: 89 references in tenant.php
- Migrations: 11 (Schema-1 only; 15 Schema-2 tables MISSING migrations)
- Tests: 0
- Seeders: 0

### Template Coverage
- T1 Foundation: 18 pages (BV1-BV3, Gr 1-2) → first_pdf.blade.php
- T2 Preparatory: 30 pages (Gr 3-5) → second_pdf.blade.php
- T3 Middle: 46 pages (Gr 6-8) → third_pdf.blade.php
- T4 Secondary: 44 pages (Gr 9-12) → fourth_pdf.blade.php
- Total: 138 pages, ~1,695 fields, all seeded and renderable

### Blueprint Screens (4/20 done)
- DONE: SC-02 (Circular Goals), SC-03 (Learning Outcomes), SC-06 (Part-A Entry), SC-19 (Bulk Generator)
- PARTIAL: SC-01 (Template Builder — missing imports), SC-05 (Dashboard — basic), SC-08 (Evaluation — basic CRUD), SC-18 (Report Preview)
- NOT STARTED: SC-04, SC-07, SC-09-SC-17, SC-20 (12 screens)

### Data Provider Reality
- TEACHER + SYSTEM sections: Working (74 pages, 54%)
- STUDENT sections: 35 sections across all templates — 0% have student input mechanism
- PARENT sections: 9 sections — 0% have parent input mechanism
- PEER sections: 14 sections — 0% have peer input mechanism

### Open Gaps (from 2026-03-14, ALL still open as of 2026-03-16)
- GAP-1: No Student Self-Service Portal (0%)
- GAP-2: No Parent Data Collection (0%)
- GAP-3: No Peer Assessment Workflow (0%)
- GAP-4: No Role-Based Section Locking (0%)
- GAP-5: No Approval Workflow (5%)
- GAP-6: No LMS/Exam Auto-Feed (0%)
- GAP-7: No Eval-to-Report Auto-Feed (0%)
- GAP-8: Attendance Data Partial (~30%)

## Key Tables
- `hpc_learning_outcomes`, `hpc_student_evaluations`, `hpc_parameters`
- `hpc_performance_descriptors`, `hpc_circular_goals`
- `hpc_knowledge_graph_validations`, `hpc_reports`

## Emoji Assets
Use local public folder: `asset('emoji/happy.png')`, `asset('emoji/no.png')`, etc.

## Before Working on HPC
1. Read `{HPC_GAP_ANALYSIS}`
2. Check P0 items — if security fixes are not done, do those FIRST
3. Never add features before fixing SEC-HPC-001 (auth) and BUG-HPC-001 (imports)

---
globs: ["Modules/Hpc/**", "database/migrations/tenant/*hpc*"]
---

# HPC (Holistic Progress Card) Module Rules

## Module Context
- 11 controllers, 15 models
- Table prefix: `hpc_*` (~12 tables)
- Route prefix: `/hpc/*`
- Status: ~95% complete

## Key Decision (D13)
DomPDF template pattern — merged single-file approach:
- **NO** Blade components (`<x-hpc-form.*>`) in PDF templates
- **NO** Bootstrap classes — use inline styles only
- **NO** flexbox/grid — use `<table>` for all layouts
- **NO** JavaScript
- One merged `*_pdf.blade.php` per template form
- Contains: `$css` array, helper closures, full `<!DOCTYPE html>` document

## PDF Templates
- `first_pdf.blade.php` — Template 1, Grades 3-5
- `second_pdf.blade.php` — Template 2, Grades 3-5 variant
- `third_pdf.blade.php` — Template 3, Grades 6-8, 46 pages

## Key Tables
- `hpc_learning_outcomes`, `hpc_student_evaluations`, `hpc_parameters`
- `hpc_performance_descriptors`, `hpc_circular_goals`
- `hpc_knowledge_graph_validations`, `hpc_reports`

## Emoji Assets
Use local public folder: `asset('emoji/happy.png')`, `asset('emoji/no.png')`, etc.

# PROMPT: Build Credit Framework Calculator — HPC Module
**Task ID:** P3_35
**Issue IDs:** SC-20
**Priority:** P3-Low
**Estimated Effort:** 3 days
**Prerequisites:** All P2 tasks must be complete

---

## CONFIGURATION
```
MODULE_PATH    = /Users/bkwork/Herd/prime_ai/Modules/Hpc
```

---

## CONTEXT

HPC report credit pages (T1 pages 16-18, T2 pages 29-30, T3 pages 45-46, T4 pages 43-44) require NCrF (National Credit Framework) calculations. Currently teachers manually calculate credit points. A service should auto-calculate based on: template type, grade level, subject/domain scores, and NCrF reference tables.

---

## PRE-READ (Mandatory)

1. Gap analysis credit page field inventory
2. NCrF reference table structure (in PDF page 16 of each template)
3. `{MODULE_PATH}/app/Services/HpcReportService.php`

---

## STEPS

1. Create `HpcCreditCalculatorService` with:
   - `calculateCredits($studentId, $templateId, $gradeLevel)` — returns credit table data
   - NCrF level mapping: grade → NCF level → credit points formula
2. Create `hpc_credit_config` table: template_id, grade, domain/subject, max_credits, ncf_level
3. Seed the config table with NCrF reference data from the official PDFs
4. Integrate into form loading: auto-populate credit page fields
5. Integrate into PDF generation: calculate and render credit tables
6. Create admin screen for managing credit configuration

---

## ACCEPTANCE CRITERIA

- Credit points auto-calculated based on assessment scores and NCrF formula
- Credit configuration is admin-editable (not hardcoded)
- Credit pages in PDF render correctly with calculated values
- Teachers can override calculated credits if needed
- Works for all 4 templates and all grade levels

---

## DO NOT

- Do NOT hardcode NCrF formulas — use configurable reference table
- Do NOT modify assessment or evaluation logic

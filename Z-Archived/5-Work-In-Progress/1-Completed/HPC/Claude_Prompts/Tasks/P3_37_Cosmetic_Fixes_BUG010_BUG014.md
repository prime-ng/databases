# PROMPT: Fix Cosmetic Issues — HPC Module
**Task ID:** P3_37
**Issue IDs:** BUG-HPC-010, BUG-HPC-014
**Priority:** P3-Low
**Estimated Effort:** 1 day
**Prerequisites:** All P2 tasks must be complete

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
```

---

## CONTEXT

Two low-priority cosmetic issues:
1. **BUG-HPC-010:** Two models use redundant `hpc_` prefix in table names: `HpcLevels` → `hpc_hpc_levels`, `StudentHpcSnapshot` → `hpc_student_hpc_snapshot`. Violates naming convention.
2. **BUG-HPC-014:** Individual PDF URLs in `generateReportPdf()` JSON response use `tenant_asset()` which may not resolve in all deployment configs. Should use route-based download or remove since ZIP is the primary delivery.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Models/HpcLevels.php` — check `$table` property
2. `{MODULE_PATH}/app/Models/StudentHpcSnapshot.php` — check `$table` property
3. `{MODULE_PATH}/app/Http/Controllers/HpcController.php` — `generateReportPdf()` for tenant_asset usage

---

## STEPS

### BUG-HPC-010 (Table names)
1. Create migration to rename `hpc_hpc_levels` → `hpc_levels` and `hpc_student_hpc_snapshot` → `hpc_student_snapshot`
2. Update model `$table` properties
3. Update any direct table references in queries

### BUG-HPC-014 (tenant_asset URLs)
4. In `generateReportPdf()`, find where `tenant_asset()` builds individual PDF URLs
5. Either replace with a route-based download URL or remove individual URLs from JSON response (ZIP download is primary)

---

## ACCEPTANCE CRITERIA

- Table names follow `hpc_{entity}` convention (no double `hpc_hpc_`)
- Models point to correct table names
- PDF generation JSON response uses valid URLs or omits individual URLs
- All existing data preserved (migration renames, not drops)

---

## DO NOT

- Do NOT drop and recreate tables — use `Schema::rename()`
- Do NOT change the ZIP download flow
- Do NOT modify PDF template rendering

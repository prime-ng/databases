# PROMPT: Add created_by to $fillable in 18 HPC Models — HPC Module
**Task ID:** P1_14
**Issue IDs:** BUG-HPC-011
**Priority:** P1-High
**Estimated Effort:** 1 hour
**Prerequisites:** None

---

## CONFIGURATION
```
MODULE_PATH    = /Users/bkwork/Herd/prime_ai/Modules/Hpc
```

---

## CONTEXT

18 of 26 HPC models are missing `created_by` from their `$fillable` array. The `created_by` column exists in the database and models have `createdBy()` BelongsTo relationships, but the FK can never be mass-assigned. This breaks audit trail tracking.

---

## PRE-READ (Mandatory)

Read ALL 26 model files in `{MODULE_PATH}/app/Models/` to identify which ones are missing `created_by`:
1. Check each model's `$fillable` array
2. The gap analysis says only `LearningOutcomes` has it — verify the other 25

---

## STEPS

1. List all .php files in `{MODULE_PATH}/app/Models/`
2. For each model, check if `created_by` is in the `$fillable` array
3. Add `'created_by'` to `$fillable` in every model where it's missing
4. Do NOT add it if the model doesn't have the column (check relationships or migration if unsure)

---

## ACCEPTANCE CRITERIA

- All 26 HPC models have `created_by` in `$fillable`
- No duplicate entries in any `$fillable` array
- Setting `created_by` via mass assignment works: `Model::create(['created_by' => auth()->id(), ...])`

---

## DO NOT

- Do NOT modify `$casts`, `$guarded`, or relationships
- Do NOT add other missing columns — only `created_by`
- Do NOT modify controller code

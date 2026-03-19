# PROMPT: Annotate 25 Dormant Phantom Models as Phase-2 — SmartTimetable DDL Gap Fix
**Task ID:** P1_08
**Issue IDs:** Phantom model documentation
**Priority:** P1-High
**Estimated Effort:** 30 minutes
**Prerequisites:** All P0 tasks completed

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai_tarun
MODULE_PATH    = {LARAVEL_REPO}/Modules/SmartTimetable
DDL_FILE       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/0-DDL_Masters/tenant_db_v2.sql
BRANCH         = Brijesh_SmartTimetable
```

---

## CONTEXT

25 models in the SmartTimetable module reference tables that do not exist in any migration or DDL. These are NOT referenced by any active controller or service — they are Phase-2 placeholders created ahead of time. Without annotation, a developer may accidentally use them in a controller or service, leading to "Base table or view not found" runtime crashes.

Each model needs a `@phase2` docblock annotation to clearly communicate its status and prevent accidental use.

---

## PRE-READ (Mandatory)

Read all 25 model files listed below in `{MODULE_PATH}/app/Models/`:

1. `ApprovalWorkflow.php`
2. `ApprovalRequest.php`
3. `ApprovalLevel.php`
4. `ApprovalDecision.php`
5. `ApprovalNotification.php`
6. `MlModel.php`
7. `TrainingData.php`
8. `FeatureImportance.php`
9. `PredictionLog.php`
10. `OptimizationRun.php`
11. `OptimizationIteration.php`
12. `OptimizationMove.php`
13. `WhatIfScenario.php`
14. `VersionComparison.php`
15. `VersionComparisonDetail.php`
16. `ConstraintGroup.php`
17. `ConstraintGroupMember.php`
18. `ConstraintTemplate.php`
19. `EscalationRule.php`
20. `EscalationLog.php`
21. `RevalidationSchedule.php`
22. `RevalidationTrigger.php`
23. `PatternResult.php`
24. `ClassSubgroupMember.php`
25. `ClassModeRule.php`

---

## STEPS

1. For each of the 25 model files listed above, add a `@phase2` docblock immediately before the class declaration. The docblock format:
   ```php
   /**
    * @phase2 Phase-2 Model — No migration or DDL table exists yet.
    * DO NOT use in controllers or services until migration is created.
    * Table: {table_name_from_$table_property}
    */
   ```
2. If the model already has an existing class-level docblock, merge the `@phase2` annotation into the existing docblock rather than adding a duplicate
3. Do NOT modify any other part of the model — leave `$table`, `$fillable`, relationships, etc. untouched
4. Run `php -l` on each modified file to confirm no syntax errors
5. Verify the count: exactly 25 files should have the `@phase2` annotation after this task

---

## ACCEPTANCE CRITERIA

- All 25 models listed above have a `@phase2` docblock annotation
- Each annotation includes the table name from the model's `$table` property
- No functional code changes — annotation only
- `php -l` passes on all 25 modified files
- No other models (active, working models) have been modified

---

## DO NOT

- Do NOT delete any of the 25 models
- Do NOT create migrations for these models — they are Phase-2 placeholders
- Do NOT modify `$table`, `$fillable`, `$casts`, or any relationships
- Do NOT add `@phase2` to any models that have working migrations (active models)
- Do NOT modify any controller, service, or route file

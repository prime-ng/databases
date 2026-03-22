# Phantom Models — Verified (37 Confirmed)

**Tarun's claim:** 37 models reference tables that don't exist anywhere
**Verification:** CONFIRMED — all 37 are true phantoms (no DDL, no migration)

---

## Assessment

Tarun's analysis of phantom models is **accurate**. These 37 models reference `$table` names that:
1. Do NOT appear in `tenant_db_v2.sql` (DDL)
2. Do NOT have any migration file to create them
3. Will throw `Base table or view not found: 1146` if any code path touches them

---

## Critical Question: Are Any Phantom Models Actually Called?

During our P01-P21 code review (same day), we found these phantom models ARE referenced in active code:

| Phantom Model | Referenced By | Impact |
|---|---|---|
| `AnalyticsDailySnapshot` | `AnalyticsService` (P14) | **CRASH** — analytics snapshot feature broken |
| `SubstitutionPattern` | `SubstitutionService` (P16) | **CRASH** — pattern learning broken |
| `SubstitutionRecommendation` | `SubstitutionService` (P16) | **CRASH** — recommendation system broken |
| `RoomUtilization` | `AnalyticsService` (P14) | **CRASH** — room utilization report broken |
| `ConflictResolutionSession` | `RefinementService` (P15) | **CRASH** — conflict resolution broken |
| `ConflictResolutionOption` | `RefinementService` (P15) | **CRASH** — resolution options broken |
| `ImpactAnalysisSession` | `RefinementService` (P15) | **CRASH** — impact analysis broken |
| `ImpactAnalysisDetail` | `RefinementService` (P15) | **CRASH** — impact details broken |
| `BatchOperation` | `RefinementService` (P15) | **CRASH** — batch swap broken |
| `BatchOperationItem` | `RefinementService` (P15) | **CRASH** — batch items broken |
| `ConstraintTargetType` | `ConstraintController` | **CRASH** — constraint management tab |
| `GenerationQueue` | `GenerateTimetableJob` (P17) | **CRASH** — async generation broken |

**12 of 37 phantom models are actively referenced in recently-written code (P14-P17).** These will crash immediately when the features are used.

---

## Root Cause

Tarun's P14-P21 implementation created services and controllers that reference models for tables that were **never migrated**. The models existed before P14 (they were created as Phase-2 placeholders), and the new services imported them assuming the tables existed.

This is NOT a "Tarun's local DB out of sync" issue — it's a genuine code-vs-database gap where services reference non-existent tables.

---

## Truly Dormant Phantoms (25 models — Safe to Ignore)

These are not referenced in any controller, service, or route. They are Phase-2 placeholders:

| Category | Models | Count |
|---|---|---|
| Approval Workflow | ApprovalWorkflow, ApprovalRequest, ApprovalLevel, ApprovalDecision, ApprovalNotification | 5 |
| ML/AI | MlModel, TrainingData, FeatureImportance, PredictionLog | 4 |
| Optimization | OptimizationRun, OptimizationIteration, OptimizationMove, WhatIfScenario | 4 |
| Version Comparison | VersionComparison, VersionComparisonDetail | 2 |
| Constraint Extras | ConstraintGroup, ConstraintGroupMember, ConstraintTemplate | 3 |
| Escalation | EscalationRule, EscalationLog | 2 |
| Revalidation | RevalidationSchedule, RevalidationTrigger | 2 |
| Misc | PatternResult, ClassSubgroupMember, ClassModeRule | 3 |

---

## Recommendation

### Immediate (blocks all new features)
Create migrations for the 12 phantom tables that are actively referenced:
- `tt_analytics_daily_snapshots`
- `tt_substitution_patterns`
- `tt_substitution_recommendations`
- `tt_room_utilizations`
- `tt_conflict_resolution_sessions`
- `tt_conflict_resolution_options`
- `tt_impact_analysis_sessions`
- `tt_impact_analysis_details`
- `tt_batch_operations`
- `tt_batch_operation_items`
- `tt_constraint_target_types`
- `tt_generation_queues`

### Later
Add `@phase2` annotation to the 25 dormant phantom models.

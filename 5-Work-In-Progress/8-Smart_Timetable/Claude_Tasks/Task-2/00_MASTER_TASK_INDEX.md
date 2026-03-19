# SmartTimetable DDL Gap Fix — Task Index

**Generated:** 2026-03-17
**Source:** Gap Analysis at `5-Work-In-Progress/8-Smart_Timetable/1-Timetable_Gap_Analysis/`
**Total Tasks:** 17 (5 P0 + 3 P1 + 5 P2 + 4 P3)
**Total Estimated Effort:** ~10-13 hours
**Assigned To:** Tarun (code tasks P0-P1), Brijesh (DDL tasks P2-P3)

## Execution Order

> **RULE:** Complete ALL P0 tasks before starting ANY P1 task.
> Complete ALL P1 tasks before starting ANY P2 task.
> Complete ALL P2 tasks before starting ANY P3 task.
> Within a priority level, tasks can be done in any order unless prerequisites say otherwise.

## Task Index

| # | File | Issue ID(s) | Priority | Est. | Owner | Prerequisites | Status |
|---|------|------------|----------|------|-------|---------------|--------|
| 01 | P0_01_BUG-DDL-001_Fix_ClassWorkingDay_Table.md | BUG-DDL-001 | P0 | 5m | Tarun | None | ⬜ |
| 02 | P0_02_BUG-DDL-002_Fix_TeacherAvailabilityLog_Table.md | BUG-DDL-002 | P0 | 5m | Tarun | None | ⬜ |
| 03 | P0_03_BUG-DDL-003_Fix_TimetableCell_ScopeForClass.md | BUG-DDL-003 | P0 | 10m | Tarun | None | ⬜ |
| 04 | P0_04_BUG-DDL-005_Create_10_DDL_Migrations.md | BUG-DDL-005 | P0 | 2h | Tarun | None | ⬜ |
| 05 | P0_05_BUG-DDL-004_Create_12_Phantom_Migrations.md | BUG-DDL-004 | P0 | 2-3h | Tarun | P0_04 | ⬜ |
| 06 | P1_06_BUG-DDL-006_Fix_Constraint_Model_Fillable.md | BUG-DDL-006 | P1 | 30m | Tarun | All P0 | ⬜ |
| 07 | P1_07_BUG-DDL-007_Clean_Dead_Alias_Columns.md | BUG-DDL-007 | P1 | 15m | Tarun | All P0 | ⬜ |
| 08 | P1_08_Annotate_25_Dormant_Phantom_Models.md | Phantom docs | P1 | 30m | Tarun | All P0 | ⬜ |
| 09 | P2_09_DDL_Update_Table_Names_Plural.md | DDL name drift | P2 | 1-2h | Brijesh | All P1 | ⬜ |
| 10 | P2_10_DDL_Update_Constraint_Columns.md | DDL column drift | P2 | 1h | Brijesh | P2_09 | ⬜ |
| 11 | P2_11_DDL_Add_Missing_Columns.md | DDL incomplete | P2 | 1h | Brijesh | P2_09 | ⬜ |
| 12 | P2_12_DDL_Add_PostDDL_Tables.md | DDL missing tables | P2 | 30m | Brijesh | P2_09 | ⬜ |
| 13 | P2_13_DDL_Add_Phantom_Table_Definitions.md | DDL phantom defs | P2 | 1h | Brijesh | P0_05, P2_09 | ⬜ |
| 14 | P3_14_Fix_TeacherAvailablity_Typo.md | Class name typo | P3 | 30m | Tarun | All P2 | ⬜ |
| 15 | P3_15_Clean_Duplicate_Constraint_Columns.md | Tech debt | P3 | 30m | Tarun | All P2 | ⬜ |
| 16 | P3_16_Mark_Legacy_Tables_Deprecated.md | Legacy cleanup | P3 | 15m | Tarun | All P2 | ⬜ |
| 17 | P3_17_DDL_Add_Standard_Columns.md | DDL conventions | P3 | 2h | Brijesh | All P2 | ⬜ |

## Sprint Plan

| Sprint | Tasks | Duration | Focus |
|--------|-------|----------|-------|
| Sprint 1 | #01-#08 | 1 day | P0 crash fixes + P1 silent bugs (Tarun) |
| Sprint 2 | #09-#13 | 1-2 days | P2 DDL reconciliation (Brijesh) |
| Sprint 3 | #14-#17 | 0.5 day | P3 cleanup & backlog (Split) |

## Dependency Graph

```
P0_01 (ClassWorkingDay) ──┐
P0_02 (AvailabilityLog) ──┤
P0_03 (ScopeForClass)   ──┼──► P1_06 (Fillable cleanup) ──► P2_09 (DDL names)
P0_04 (10 DDL migrations)─┤                                  P2_10 (DDL columns)
P0_05 (12 phantom migr.) ─┘──► P1_07 (Dead aliases)     ──► P2_11 (DDL add cols)
                               P1_08 (Annotate phantoms) ──► P2_12 (DDL add tables)
                                                              P2_13 (DDL phantoms)
                                                              ──► P3_14-17 (Cleanup)
```

## Impact Summary

| When All Done | Effect |
|---------------|--------|
| After P0 | Analytics, Refinement, Substitution, API features stop crashing |
| After P1 | No silent data loss, phantom models documented |
| After P2 | DDL is accurate schema reference matching running code |
| After P3 | Clean codebase, no legacy confusion, full conventions |

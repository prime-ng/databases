# HPC Module — Task Prompt Index
**Generated:** 2026-03-17
**Source:** HPC_Gap_Analysis_Complete.md (2026-03-16)
**Total Tasks:** 37 (8 P0 + 11 P1 + 7 P2 + 11 P3)
**Total Estimated Effort:** ~13 developer-weeks

## Execution Order

> **RULE:** Complete ALL P0 tasks before starting ANY P1 task.
> Complete ALL P1 tasks before starting ANY P2 task.
> Complete ALL P2 tasks before starting ANY P3 task.
> Within a priority level, tasks can be done in any order unless prerequisites say otherwise.
> Get conformation frorm me everytime before starting next tasks.
> After completing each task, edit this file and mark the completed task status ✅ in this master index

## Task Index

| # | File | Issue ID(s) | Priority | Est. | Prerequisites | Status |
|---|------|------------|----------|------|---------------|--------|
| 01 | P0_01_SEC-HPC-001_Auth_HpcController.md | SEC-HPC-001 | P0 | 2h | None | ✅ |
| 02 | P0_02_SEC-HPC-002_Fix_FormRequest_Authorize.md | SEC-HPC-002 | P0 | 1h | None | ✅ |
| 03 | P0_03_BUG-HPC-001_Missing_Imports_TenantPHP.md | BUG-HPC-001 | P0 | 15m | None | ✅ |
| 04 | P0_04_BUG-HPC-003_Garbled_Permission_String.md | BUG-HPC-003 | P0 | 5m | None | ✅ |
| 05 | P0_05_SEC-HPC-003_EnsureTenantHasModule.md | SEC-HPC-003 | P0 | 30m | None | ✅ |
| 06 | P0_06_BUG-HPC-009_Trash_Route_Shadowing.md | BUG-HPC-009 | P0 | 30m | None | ✅ |
| 07 | P0_07_BUG-HPC-004_CrossLayer_AcademicSession.md | BUG-HPC-004 | P0 | 1h | None | ✅ |
| 08 | P0_08_FormStore_MassAssignment_Fix.md | SEC-HPC-001 (partial) | P0 | 1h | None | ✅ |
| 09 | P1_09_SEC-HPC-004_Remove_Module_Routes_Bypass.md | SEC-HPC-004 | P1 | 30m | P0 complete | ✅ |
| 10 | P1_10_BUG-HPC-005_Dead_Routes.md | BUG-HPC-005 | P1 | 15m | P0_03 | ✅ |
| 11 | P1_11_BUG-HPC-006_Case_Sensitivity_Linux.md | BUG-HPC-006 | P1 | 30m | None | ✅ |
| 12 | P1_12_BUG-HPC-007_Wrong_Student_Import.md | BUG-HPC-007 | P1 | 10m | None | ✅ |
| 13 | P1_13_BUG-HPC-008_Orphan_Import.md | BUG-HPC-008 | P1 | 5m | None | ✅ |
| 14 | P1_14_BUG-HPC-011_Created_By_Fillable.md | BUG-HPC-011 | P1 | 1h | None | ✅ |
| 15 | P1_15_BUG-HPC-012_CrossLayer_Dropdown.md | BUG-HPC-012 | P1 | 30m | None | ✅ |
| 16 | P1_16_BUG-HPC-013_ZIP_Cleanup.md | BUG-HPC-013 | P1 | 5m | None | ✅ |
| 17 | P1_17_PERF-HPC-002_Shared_Index_Query.md | PERF-HPC-002 | P1 | 2h | None | ✅ |
| 18 | P1_18_Permission_Typo_TopicEquivalency.md | BUG-HPC-015 | P1 | 10m | None | ✅ |
| 19 | P1_19_Missing_15_Migrations.md | Schema gap | P1 | 4h | None | ✅ |
| 20 | P2_20_GAP4_Role_Based_Section_Locking.md | GAP-4 | P2 | 3d | All P0+P1 | ✅ |
| 21 | P2_21_GAP5_Approval_Workflow.md | GAP-5 | P2 | 3d | All P0+P1 | ✅ |
| 22 | P2_22_GAP7_Eval_To_Report_AutoFeed.md | GAP-7 | P2 | 2d | All P0+P1 | ✅ |
| 23 | P2_23_GAP8_Attendance_Data_Complete.md | GAP-8 | P2 | 2d | All P0+P1 | ✅ |
| 24 | P2_24_PERF-HPC-001_Batch_PDF_Generation.md | PERF-HPC-001 | P2 | 1d | All P0+P1 | ✅ |
| 25 | P2_25_God_Controller_Refactor.md | Refactor | P2 | 3d | All P0+P1 | ✅ |
| 26 | P2_26_Job_Refactor_BuildPdf_To_Service.md | Refactor | P2 | 1d | P2_25 | ✅ |
| 27 | P3_27_GAP1_Student_Self_Service_Portal.md | GAP-1 | P3 | 5d | All P2 | ✅ |
| 28 | P3_28_GAP2_Parent_Data_Collection.md | GAP-2 | P3 | 4d | All P2 | ✅ |
| 29 | P3_29_GAP3_Peer_Assessment_Workflow.md | GAP-3 | P3 | 4d | All P2 | ✅ |
| 30 | P3_30_GAP6_LMS_Exam_AutoFeed.md | GAP-6 | P3 | 3d | All P2 | ✅ |
| 31 | P3_31_SC07_Attendance_Manager_Screen.md | SC-07 | P3 | 2d | P2_23 | ✅ |
| 32 | P3_32_SC09_Activity_Assessment_Screen.md | SC-09 | P3 | 3d | P3_27 | ✅ |
| 33 | P3_33_SC14_Student_Goals_Aspirations.md | SC-14 | P3 | 2d | P3_27 | ✅ |
| 34 | P3_34_SC15-17_Parent_Portal_Screens.md | SC-15, SC-16, SC-17 | P3 | 5d | P3_28 | ✅ |
| 35 | P3_35_SC20_Credit_Calculator.md | SC-20 | P3 | 3d | All P2 | ✅ |
| 36 | P3_36_Test_Suite_Basic_Coverage.md | Tests | P3 | 5d | All P2 | ✅ |
| 37 | P3_37_Cosmetic_Fixes_BUG010_BUG014.md | BUG-HPC-010, BUG-HPC-014 | P3 | 1d | All P2 | ✅ |



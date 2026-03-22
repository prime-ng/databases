Now let me read the constraint architecture and list files for completeness.

⏺ Read 2 files (ctrl+o to expand)

⏺ Folder is empty and ready. Let me create the master task list and all prompt files. I'll work in parallel batches.

  Batch 1: Master task list + first 4 prompt files

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/00_Master_TaskList.md)
  ⎿  Wrote 279 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/00_Master_TaskList.md
      1 # SmartTimetable — Master Task List (Skill-Categorized)
      2
      3 **Generated:** 2026-03-15
      4 **Source:** `2026Mar14_DevelopmentPlan_v2.md` + `2026Mar14_GapAnalysis_Updated_v2.md`
      5 **Module Completion:** ~60% → target 95%+
      6 **Total Effort:** ~69 working days across 19 phases
      7 **Total Prompt Files:** 21 (P01–P21)
      8
      9 ---
     … +269 lines (ctrl+o to expand)

     ⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P01_BugFixes.md)
  ⎿  Wrote 174 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P01_BugFixes.md
       1 # P01 — Critical Bug Fixes
       2
       3 **Phase:** 1 | **Priority:** P0 | **Effort:** 0.5 day
       4 **Skill:** Backend | **Model:** Sonnet
       5 **Branch:** Tarun_SmartTimetable
       6 **Dependencies:** None — DO THIS FIRST
       7
       8 ---
       9
      10 ## Pre-Requisites
     … +164 lines (ctrl+o to expand)

     ⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P02_Security_Middleware.md)
  ⎿  Wrote 120 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P02_Security_Middleware.md
       1 # P02 — Security: Middleware & Truncate Protection
       2
       3 **Phase:** 2 (Tasks 2.1–2.2) | **Priority:** P0 | **Effort:** 0.75 day
       4 **Skill:** Backend | **Model:** Sonnet
       5 **Branch:** Tarun_SmartTimetable
       6 **Dependencies:** None (can run parallel with P01)
       7
       8 ---
       9
      10 ## Pre-Requisites
     … +110 lines (ctrl+o to expand)

     ⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P03_Security_MainController.md)
  ⎿  Wrote 89 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P03_Security_MainController.md
       1 # P03 — Security: Auth on SmartTimetableController
       2
       3 **Phase:** 2 (Task 2.3) | **Priority:** P0 | **Effort:** 0.5 day (2 hrs)
       4 **Skill:** Backend | **Model:** Sonnet
       5 **Branch:** Tarun_SmartTimetable
       6 **Dependencies:** None (can run parallel with P01, P02)
       7
       8 ---
       9
      10 ## Pre-Requisites
     … +79 lines (ctrl+o to expand)

     ⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P04_Security_Controllers.md)
  ⎿  Wrote 242 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P04_Security_Controllers.md
       1 # P04 — Security: Auth on Remaining Controllers + Policy + Seeder
       2
       3 **Phase:** 2 (Tasks 2.4–2.7) | **Priority:** P0 | **Effort:** 1.5 days
       4 **Skill:** Backend + Schema | **Model:** Sonnet
       5 **Branch:** Tarun_SmartTimetable
       6 **Dependencies:** P03 should be done first (pattern established)
       7
       8 ---
       9
      10 ## Pre-Requisites
     … +232 lines (ctrl+o to expand)

     Batch 2: P05–P08

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P05_ActivityConstraints.md)
  ⎿  Wrote 243 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P05_ActivityConstraints.md
      1 # P05 — Activity Constr
        aint Integration
      2
      3 **Phase:** 3 | **Priori
        ty:** P1 | **Effort:** 
        2 days
      4 **Skill:** Backend | **
        Model:** Sonnet
      5 **Branch:** Tarun_Smart
        Timetable
      6 **Dependencies:** P01 (
        Phase 1 bug fixes must
        be done first)
      7 **Reference:** `2026Mar
        10_Step2_ActivityConstr
        aints_SubTasks.md`
      8
      9 ---
     … +233 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P06_Performance.md)
  ⎿  Wrote 239 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P06_Performance.md
       1 # P06 — Performance Optimization
       2
       3 **Phase:** 4 | **Priority:** P1 | **Effort:** 2 days
       4 **Skill:** Backend | **Model:** Sonnet
       5 **Branch:** Tarun_SmartTimetable
       6 **Dependencies:** None (can run in parallel with P05)
       7
       8 ---
       9
      10 ## Pre-Requisites
     … +229 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P07_RoomAllocation.md)
  ⎿  Wrote 286 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P07_RoomAllocation.md
      1 # P07 — Room Allocation
      2
      3 **Phase:** 5 | **Priority:** P1 | **Effort:** 3 days
      4 **Skill:** Backend + Frontend | **Model:** Sonnet
      5 **Branch:** Tarun_SmartTimetable
      6 **Dependencies:** P01 (bug fixes)
      7 **Reference:** `2026Mar10_ActivityConstraints_Integration_Plan.md` Section 6
      8
      9 ---
     … +276 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P08_StubsViewsCleanup.md)
  ⎿  Wrote 284 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P08_StubsViewsCleanup.md
       1 # P08 — Stub Controllers, Missing Views & Dead Code Cleanup
       2
       3 **Phase:** 6 | **Priority:** P1 | **Effort:** 2 days
       4 **Skill:** Backend + Frontend + Cleanup | **Model:** Sonnet
       5 **Branch:** Tarun_SmartTimetable
       6 **Dependencies:** P04 (Phase 2 security must be done — auth is added first, then stubs implemen
         ted)
       7
       8 ---
       9
      10 ## Pre-Requisites
     … +274 lines (ctrl+o to expand)

⏺ Batch 3: P09–P13 (Constraint System)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P09_ConstraintArchitecture.md)
  ⎿  Wrote 465 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P09_ConstraintArchitecture.md
      1 # P09 — Constraint Architecture Foundation
      2
      3 **Phase:** 11 | **Priority:** P1 | **Effort:** 3 days
      4 **Skill:** Backend | **Model:** Opus (complex architecture)
      5 **Branch:** Tarun_SmartTimetable
      6 **Dependencies:** P05 (Phase 3 activity constraints)
      7 **Reference:** `2026Mar10_ConstraintArchitecture_Analysis.md` §3
      8
      9 ---
     … +455 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P10_TeacherConstraints.md)
  ⎿  Wrote 280 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P10_TeacherConstraints.md
      1 # P10 — Teacher Constraints (Category B)
      2
      3 **Phase:** 12 | **Priority:** P1 | **Effort:** 5 days
      4 **Skill:** Backend + Schema | **Model:** Sonnet
      5 **Branch:** Tarun_SmartTimetable
      6 **Dependencies:** P09 (Phase 11 — Constraint Architecture must be done)
      7 **Reference:** `2026Mar10_ConstraintList_and_Categories.md` Category B
      8
      9 ---
     … +270 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P11_ClassConstraints.md)
  ⎿  Wrote 92 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P11_ClassConstraints.md
      1 # P11 — Class/Student Constraints (Category C)
      2
      3 **Phase:** 13 | **Priority:** P1 | **Effort:** 4 days
      4 **Skill:** Backend + Schema | **Model:** Sonnet
      5 **Branch:** Tarun_SmartTimetable
      6 **Dependencies:** P09 (Phase 11 — Constraint Architecture)
      7 **Reference:** `2026Mar10_ConstraintList_and_Categories.md` Category C
      8
      9 ---
     … +82 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P12_InterActivity_Part1.md)
  ⎿  Wrote 241 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P12_InterActivity_Part1.md
       1 # P12 — Inter-Activity Constraints Part 1 (H1-H7, H20-H22)
       2
       3 **Phase:** 15 (Tasks 15.1–15.5) | **Priority:** P1 | **Effort:** 5 days
       4 **Skill:** Backend | **Model:** Opus (complex solver changes)
       5 **Branch:** Tarun_SmartTimetable
       6 **Dependencies:** P09 (Phase 11 — Constraint Architecture)
       7 **Reference:** `2026Mar10_ConstraintList_and_Categories.md` Category H
       8 **WARNING:** These require solver-level changes in FETSolver, similar to how Parallel Periods (
         H8) was implemented
       9
      10 ---
     … +231 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P13_InterActivity_Part2.md)
  ⎿  Wrote 123 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P13_InterActivity_Part2.md
       1 # P13 — Inter-Activity Constraints Part 2 (H9-H19)
       2
       3 **Phase:** 15 (Tasks 15.6–15.8) | **Priority:** P1 | **Effort:** 3 days
       4 **Skill:** Backend | **Model:** Sonnet
       5 **Branch:** Tarun_SmartTimetable
       6 **Dependencies:** P12 (Phase 15 Part 1 — group infrastructure)
       7
       8 ---
       9
      10 ## Pre-Requisites
     … +113 lines (ctrl+o to expand)

⏺ Batch 4: P14–P17 (Feature Additions)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P14_Analytics.md)
  ⎿  Wrote 209 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P14_Analytics.md
       1 # P14 — Post-Generation Analytics
       2
       3 **Phase:** 7 | **Priority:** P2 | **Effort:** 5 days
       4 **Skill:** Backend + Frontend | **Model:** Sonnet
       5 **Branch:** Tarun_SmartTimetable
       6 **Dependencies:** P07 (Phase 5 — Room Allocation)
       7
       8 ---
       9
      10 ## Pre-Requisites
     … +199 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P15_Refinement.md)
  ⎿  Wrote 72 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P15_Refinement.md
      1 # P15 — Manual Refinement (Swap/Move/Lock)
      2
      3 **Phase:** 8 | **Priority:** P2 | **Effort:** 4 days
      4 **Skill:** Backend + Frontend | **Model:** Sonnet
      5 **Branch:** Tarun_SmartTimetable
      6 **Dependencies:** P07 (Phase 5 — Room Allocation)
      7 **Reference:** `2026Mar10_GapAnalysis_and_CompletionPlan.md` GAP-5
      8
      9 ---
     … +62 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P16_Substitution.md)
  ⎿  Wrote 85 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P16_Substitution.md
      1 # P16 — Substitution Management
      2
      3 **Phase:** 9 | **Priority:** P2 | **Effort:** 5 days
      4 **Skill:** Backend + Frontend | **Model:** Sonnet
      5 **Branch:** Tarun_SmartTimetable
      6 **Dependencies:** P07 (Phase 5 — Room Allocation)
      7 **Reference:** `2026Mar10_GapAnalysis_and_CompletionPlan.md` GAP-6
      8
      9 ---
     … +75 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P17_API_Async.md)
  ⎿  Wrote 78 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P17_API_Async.md
       1 # P17 — API & Async Generation
       2
       3 **Phase:** 10 | **Priority:** P2 | **Effort:** 3 days
       4 **Skill:** Backend + Frontend | **Model:** Sonnet
       5 **Branch:** Tarun_SmartTimetable
       6 **Dependencies:** P07 (Phase 5 — Room Allocation)
       7
       8 ---
       9
      10 ## Pre-Requisites
     … +68 lines (ctrl+o to expand)

⏺ Batch 5: P18–P21 (Remaining prompts)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P18_RoomConstraints.md)
  ⎿  Wrote 85 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P18_RoomConstraints.md
      1 # P18 — Room & Space Constraints (Category E)
      2
      3 **Phase:** 14 | **Priority:** P2 | **Effort:** 5 days
      4 **Skill:** Backend | **Model:** Sonnet
      5 **Branch:** Tarun_SmartTimetable
      6 **Dependencies:** P07 (Phase 5 — Room Allocation) + P09 (Phase 11 — Constraint Architecture)
      7 **Reference:** `2026Mar10_ConstraintList_and_Categories.md` Category E
      8
      9 ---
     … +75 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P19_GlobalPolicy_DBClasses.md)
  ⎿  Wrote 153 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P19_GlobalPolicy_DBClasses.md
      1 # P19 — Global Policy (Cat G) + DB Constraint PHP Classes (Cat F)
      2
      3 **Phase:** 16 + 17 | **Priority:** P2 | **Effort:** 6 days
      4 **Skill:** Backend | **Model:** Sonnet
      5 **Branch:** Tarun_SmartTimetable
      6 **Dependencies:** P09 (Phase 11 — Constraint Architecture)
      7 **Reference:** `2026Mar10_ConstraintList_and_Categories.md` Categories G and F
      8
      9 ---
     … +143 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P20_Testing.md)
  ⎿  Wrote 219 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P20_Testing.md
       1 # P20 — Testing (Pest 4.x)
       2
       3 **Phase:** 18 | **Priority:** P3 | **Effort:** 5 days
       4 **Skill:** Testing | **Model:** Sonnet
       5 **Branch:** Tarun_SmartTimetable
       6 **Dependencies:** P10–P13, P19 (constraint phases should be done first)
       7
       8 ---
       9
      10 ## Pre-Requisites
     … +209 lines (ctrl+o to expand)

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P21_CodeQuality.md)
  ⎿  Wrote 167 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/P21_CodeQuality.md
       1 # P21 — Code Quality & Cleanup
       2
       3 **Phase:** 19 | **Priority:** P3 | **Effort:** 3 days
       4 **Skill:** Cleanup + Schema + Backend | **Model:** Sonnet
       5 **Branch:** Tarun_SmartTimetable
       6 **Dependencies:** P08 (Phase 6 — stubs/views done first)
       7
       8 ---
       9
      10 ## Pre-Requisites
     … +157 lines (ctrl+o to expand)

⏺ Now let me verify all files are created correctly.

⏺ Read 1 file (ctrl+o to expand)

⏺ All 22 files created successfully. Here's the summary:

  Created: 22 files in Claude_Prompt/

  ┌────────────────────────────────┬────────────────────┬──────────────────────────────┬──────────┬────────┐
  │              File              │       Phase        │            Skill             │  Effort  │ Model  │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ 00_Master_TaskList.md          │ —                  │ Overview                     │ —        │ —      │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P01_BugFixes.md                │ 1                  │ Backend                      │ 0.5 day  │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P02_Security_Middleware.md     │ 2 (2.1-2.2)        │ Backend                      │ 0.75 day │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P03_Security_MainController.md │ 2 (2.3)            │ Backend                      │ 0.5 day  │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P04_Security_Controllers.md    │ 2 (2.4-2.7)        │ Backend + Schema             │ 1.5 days │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P05_ActivityConstraints.md     │ 3                  │ Backend                      │ 2 days   │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P06_Performance.md             │ 4                  │ Backend                      │ 2 days   │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P07_RoomAllocation.md          │ 5                  │ Backend + Frontend           │ 3 days   │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P08_StubsViewsCleanup.md       │ 6                  │ Backend + Frontend + Cleanup │ 2 days   │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P09_ConstraintArchitecture.md  │ 11                 │ Backend                      │ 3 days   │ Opus   │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P10_TeacherConstraints.md      │ 12                 │ Backend + Schema             │ 5 days   │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P11_ClassConstraints.md        │ 13                 │ Backend + Schema             │ 4 days   │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P12_InterActivity_Part1.md     │ 15 (H1-H7, H20-22) │ Backend                      │ 5 days   │ Opus   │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P13_InterActivity_Part2.md     │ 15 (H9-H19)        │ Backend                      │ 3 days   │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P14_Analytics.md               │ 7                  │ Backend + Frontend           │ 5 days   │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P15_Refinement.md              │ 8                  │ Backend + Frontend           │ 4 days   │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P16_Substitution.md            │ 9                  │ Backend + Frontend           │ 5 days   │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P17_API_Async.md               │ 10                 │ Backend + Frontend           │ 3 days   │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P18_RoomConstraints.md         │ 14                 │ Backend                      │ 5 days   │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P19_GlobalPolicy_DBClasses.md  │ 16+17              │ Backend                      │ 6 days   │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P20_Testing.md                 │ 18                 │ Testing                      │ 5 days   │ Sonnet │
  ├────────────────────────────────┼────────────────────┼──────────────────────────────┼──────────┼────────┤
  │ P21_CodeQuality.md             │ 19                 │ Cleanup + Schema             │ 3 days   │ Sonnet │
  └────────────────────────────────┴────────────────────┴──────────────────────────────┴──────────┴────────┘

  Each prompt file includes:
  - Pre-requisites (files to read)
  - Step-by-step tasks with exact file paths and code patterns
  - Post-execution checklist (lint, test, AI Brain updates)
  - Dependency chain so you know execution order

  Execution: copy-paste any prompt file directly into Claude Code to execute that phase.

✻ Cogitated for 15m 17s


# Prompts Detail to Generate Files
==================================

`1-Conditions_need_to_implement.md` :  Mannually created by me

------------------------------------------------------------------------------------------------------

`Algo_implement_plan.md`  : This is implementation plan provided by Claude
### Prompt
At the ned of (Algo_internal_detail) & (Activity_Prioritization_Discrepancies_TEMPLATE), Claude ask me whether I wanted an Implementation Plan for all Discrepancies and I said Yes create one. No Particuler Prompt for that.

------------------------------------------------------------------------------------------------------

`Prioritization_Enhancement_v1.md` & `Activity_Prioritization_Discrepancies_TEMPLATE.md`
### Prompt
Now when I have understood the Algorithm in detail what all Parameters it is using to priorities the Activities. I found many discripencies :
- Few Parameter which are being used to priorties Teacher (which activity we should place Teacher on first), actually should not be used for prioritising placement.
- Few Parameter has ben given higher weightage, however those are less important when we calculate prioritisation
- etc.

Now I want to know what is the best way to communicate all those discripencies, so that you can provide me a refined enhancement plan? Should I write all those discripencies in a saperarate .md file if yes then what should be format of that document(.md file)? Write the Template in folder "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/Algo_Refinement"

------------------------------------------------------------------------------------------------------

`Algo_parameter_detail.md`
### Prompt
I want to refine the Algorithm especially the sequence of the parameter being used to priorities the allocation. Few quesries are below which will help me to understand the current parameter sqence being used in algo, which will ultimatly help me to refine the Algo. Answer the below queries and also provide any additional information which can help me to understand the internal machanism of the algorithm :
- What all Parameters are there which can be used to prioritise the placement of a teacher+Period to a Activity (Class+section+Subject+Study_Format)?
- What all Parameters are there which can be used to prioritise the placement of the Room to a Activity (Class+section+Subject+Study_Format)?
- What should be the Formula to calculate all the parameter which will be used to Prioritise Placements? If any will be provided by School (End User) then mark it as "User provided"
- What should be the Priority Sequence of all those Parameters to get perfect Placement of Teacher+Period & Rooms? Save the output into a file "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/Algo_Refinement/Algo_parameter_detail.md"

------------------------------------------------------------------------------------------------------

`Algo_internal_detail.md`
### Prompt
I have few Queries related to the SmartTimetable Module :
  - What all Algorithm are being used in the SmartTimetable Module to Generate Timetable?
  - What is the Sequence of those Algorithms?
  - Provide Complete detail of those Algorithms, what parameter are being used in those algorithm and how it is deciding what action should be take next in process of Algo?
  - Does output of one Algorithm is being provided to the next Algorithm as input, if yes then provide detail?

  I want you to provide complete Algorithm detail in generic language. I have ben a developer 10 years back but now I am not very handon with coding on PHP. So keep the language of explaination accordingly, so that I can understand it easily. Save the output into file "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/Algo_Refinement/Algo_internal_detail.md"

------------------------------------------------------------------------------------------------------

`Algo_deep_dive.md`
### Prompt
Yes, Create another deepDiving doc as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/Algo_Refinement/Algo_deep_dive.md" where you should walk me through one by one all the algorithms in more depth — e.g., the backtracking + cache interaction, or how LPT and alternative-teacher retry actually interact?

### Final Summary
Saved to 1-DDL_Tenant_Modules/tt_SmartTimetable/Algo_Refinement/Algo_deep_dive.md.

What's deeper here vs. Algo_internal_detail.md

The plain-language doc told you what each algorithm does. This one shows you exactly how decisions are made, how state evolves, and where the interactions between algorithms produce non-obvious behavior.

Each section has the same 7-part structure:
  1. Decision in one sentence
  2. State at entry
  3. Exact rule (formula/pseudocode, no hand-waving)
  4. Worked example with state evolution
  5. Edge cases & boundaries
  6. Interactions with other algorithms 
  7. Where the bugs lurk

Two extra-deep sections (the ones you specifically asked about)

§10 — LPT + Alternative-Teacher Retry — walks through the three layers of teacher state (LPT charge, in-memory teacherOccupied, DB tt_teacher_workload) and exposes five non-obvious behaviors of the alternative-teacher retry:
  - (a) charge[] is not updated when retry reassigns a card → LPT's "balanced" view becomes stale.
  - (b) Eligible-teacher list is not re-sorted by least-loaded.
  - (c) Retry is per-card — splits an activity across multiple teachers.
  - (d) Retry doesn't honor is_preferred_teacher flags.
  - (e) Phase 1 doesn't try alternatives at all — meaning a card that could place cleanly with a different teacher is instead force-placed.

  Includes a full LPT trace (3 activities, 2 teachers, charge counters evolving step by step) and a Phase-2 retry trace showing how a Maths activity ends up split T1/T2.

  §12 — Phase 1 Backtracking + Constraint Cache — explains the cache key shape {type}-{classKey}-{dayId}-{startIndex}-{cardId}, walks two backtracking traces (one with no backtrack, one with cache pollution after undo), explains why the cache must be cleared coarsely on every backtrack, and where a smarter dependency-tracking cache could live.

  Other deeply-treated sections

  - §11 Difficulty Ordering — full numeric breakdown of three example cards with weights, plus the pathological "scarcity-blind" case that motivates your discrepancy doc.
  - §13 Slot Scoring — full formula with two complete trace calculations on the same card at different slots.
  - §17 Phase 3b Force-Place Bucketing — first-match-wins gotcha (a placement that's both D_CAPACITY and C_REAL_TEACHER gets only the first label).
  - §18 Room Allocation — score-then-walk dual-pass, why rooms aren't in the search space.
  - §20 Cross-Cutting Interactions — five "easy-to-miss" interaction issues across the whole pipeline.

  How to use this with the discrepancy template
 
  When you fill Activity_Prioritization_Discrepancies_TEMPLATE.md, you can now cite this doc by section in the "Evidence" column — e.g., "see §11.5 pathological case" or "see §10.5 alternative-teacher behaviors."
  That gives me a tight evidence chain when I do the architecture-review pass on your discrepancies.
 
  Want me to walk through any specific section live, or move on to drafting starter discrepancy rows based on what we've documented here? 

recap: We're refining SmartTimetable's activity-prioritization algorithm; you have a discrepancy template, plain-language algo doc, and deep-dive doc ready in Algo_Refinement/. Next action: fill the discrepancy template with your flagged parameter issues so I can do the architecture review.

------------------------------------------------------------------------------------------------------

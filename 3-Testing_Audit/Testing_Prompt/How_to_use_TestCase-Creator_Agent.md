# How to use TestCase Creator Agent
===================================

How to invoke

No slash command for custom agents — you name it in natural language: "Use the testcase-creator agent to …" (or @testcase-creator in FleetView). It reads four params from your words: module (required), feature, mode (feature/module/report), execute (true/false). All output lands under 3-Testing_Audit/TestCases/[Module]/[Feature]/.

Commands by capability

1 · One feature (full 8 artifacts)

▎ Use the testcase-creator agent — module=Accounting, feature=TaxRate — generate the complete suite.

2 · Whole module (discovers all features, generates each)

▎ Use testcase-creator — mode=module, module=HrStaff.

3 · Feature inventory only (scope first, no generation)

▎ Use testcase-creator to list the Feature Inventory for Billing — don't generate yet.

4 · Generate + run tests

▎ Use testcase-creator — module=HrStaff, feature=Holiday, execute=true — run V1 then V2 and attach the proof.

5 · Single artifact only

▎ Use testcase-creator to regenerate only the V2 test for HrStaff/LeaveType and refresh its Gap Analysis + Validation Report.

6 · Add enhanced dimensions

▎ Use testcase-creator to add the Tenancy (TC-T) and Security (TC-S) packs to Accounting/TaxRate.

7 · Fidelity dry run + diff

▎ Use testcase-creator to dry-run regenerate HrStaff/PayGrade into a scratch folder and diff vs committed. Don't execute.

8 · Update after code change

▎ Accounting/TaxRate's controller changed — use testcase-creator to re-read source and update the suite.

9 · Validate / lint only

▎ Use testcase-creator to run the Validation Report checklist and php -l on HrStaff/LeaveType.

10 · Roll-up reports (mode=report)

▎ Use testcase-creator — mode=report, module=HrStaff — build the Coverage Dashboard / RTM / Defect Register / Program Summary.

11 · Phased batch

▎ Use testcase-creator to generate Phase-1 modules (Accounting, Billing, Payment, StudentFee) one feature at a time; pause for review after the first feature of each.

Quick reference

┌─────────────────────┬─────────────────────────────────────────────────────┐
│        Task         │                      One-liner                      │
├─────────────────────┼─────────────────────────────────────────────────────┤
│ One feature         │ testcase-creator: module=X, feature=Y               │
├─────────────────────┼─────────────────────────────────────────────────────┤
│ Whole module        │ testcase-creator: mode=module, module=X             │
├─────────────────────┼─────────────────────────────────────────────────────┤
│ Inventory only      │ testcase-creator: inventory for X, don't generate   │
├─────────────────────┼─────────────────────────────────────────────────────┤
│ Generate + run      │ testcase-creator: module=X, feature=Y, execute=true │
├─────────────────────┼─────────────────────────────────────────────────────┤
│ Single artifact     │ testcase-creator: regenerate only <file> for X/Y    │
├─────────────────────┼─────────────────────────────────────────────────────┤
│ Add TC-T/TC-S       │ testcase-creator: add tenancy/security packs to X/Y │
├─────────────────────┼─────────────────────────────────────────────────────┤
│ Dry run + diff      │ testcase-creator: dry-run X/Y to scratch, diff      │
├─────────────────────┼─────────────────────────────────────────────────────┤
│ Update after change │ testcase-creator: re-read source & update X/Y       │
├─────────────────────┼─────────────────────────────────────────────────────┤
│ Validate only       │ testcase-creator: run Validation + php -l on X/Y    │
├─────────────────────┼─────────────────────────────────────────────────────┤
│ Roll-up             │ testcase-creator: mode=report, module=X             │
└─────────────────────┴─────────────────────────────────────────────────────┘

Tip: for whole-module or phase jobs, ask it to confirm the Feature Inventory before generating so you approve scope first — and it runs in the background, notifying you on completion.

Saved to Testing-Plan/04_Agent_Usage_Commands.md. Here's the cookbook.

---


Which Mode of TestCase Creator Agent will cover every report it is capable to generate of? What exact command i should use for that?

Good question — but I shouldn't guess at the modes. The agent's modes and report types are defined in its role prompt (the single source of truth), not in the loader I edited. Let me read that.

  Read 1 file

I read the agent's role prompt (its single source of truth). Here's the precise answer.

Which mode → report mode

Only report mode emits reports. feature and module mode generate the 8-artifact test suites; report mode is the only one that produces the roll-up reports. It's capable of exactly four reports (from §"REPORT MODE"):

┌───────────────────────────────────────┬────────────────────────────┬─────────────────────────────────┐
│                Report                 │           Scope            │              File               │
├───────────────────────────────────────┼────────────────────────────┼─────────────────────────────────┤
│ Coverage Dashboard                    │ per-module                 │ _{Module}_Coverage_Dashboard.md │
├───────────────────────────────────────┼────────────────────────────┼─────────────────────────────────┤
│ RTM (Requirement Traceability Matrix) │ per-module                 │ _{Module}_RTM.md                │
├───────────────────────────────────────┼────────────────────────────┼─────────────────────────────────┤
│ Defect Register                       │ program-wide (all modules) │ _Program_Defect_Register.md     │
├───────────────────────────────────────┼────────────────────────────┼─────────────────────────────────┤
│ Test Summary                          │ program-wide (all modules) │ _Program_Test_Summary.md        │
└───────────────────────────────────────┴────────────────────────────┴─────────────────────────────────┘

Important caveat: report mode consumes existing artifacts — it rolls up from test suites already generated by feature/module mode. It does not create test cases. So a module must already have its 8-artifact sets on disk before its reports mean anything.

Exact command

There's no slash command — you invoke the subagent by instruction, the same way you did for the Billing run. Because two of the four reports are per-module and two are program-wide, "every report" isn't a single scope. Two forms:

Per-module reports (Coverage Dashboard + RTM for one module):
Use the testcase-creator agent — mode=report, module=Billing

Program-wide reports (Defect Register + Test Summary across all modules that have artifacts):
Use the testcase-creator agent — mode=report, scope=program
(scope=program isn't a formal input param in the prompt — it's phrased as an instruction; the program roll-ups land in TestCases/_Program/.)

To truly get all four in one go, tell it both:
Use the testcase-creator agent — mode=report, module=Billing, and also produce the program-level roll-ups (Defect Register + Test Summary) across all modules with existing artifacts

Note on your Billing run

You already have 2 of the 4 for Billing — module mode auto-generated Billing_Coverage_Dashboard.md and Billing_RTM.md (step 5 of module mode optionally triggers report mode). The two program-level reports (_Program_Defect_Register.md, _Program_Test_Summary.md) were not produced, since they span all modules, not just Billing.

Want me to run report mode now to generate the two missing program-level reports?


--------------------------------------------------------------------------------------------
To truly get all four in one go, tell it both:

Use the testcase-creator agent — mode=report, module=Billing, and also produce the program-level roll-ups (Defect Register + Test Summary) across all modules with existing artifacts

Use the testcase-creator agent — mode=report, module=MarksheetGeneration, and also produce the program-level roll-ups (Defect Register + Test Summary) across the module with existing artifacts
--------------------------------------------------------------------------------------------

Use the testcase-creator agent — mode=module, module=BehaviouralAssessment. Generate the complete artifact set for every feature, then run report mode to produce the module roll-ups.
Write everything into the existing TestCases/BehaviouralAssessment/ folder (reuse it — don't create a dated copy). Use the Feature Inventory already in that folder as the work-list; skip 00-Module-Overview (not a feature). For each of the 24 features generate the 8 artifacts under BehaviouralAssessment/{Feature}/, then generate the module-level BehaviouralAssessment_Coverage_Dashboard.md and BehaviouralAssessment_RTM.md at the module-folder root. Detect the test style from the module's real source, obey 05_ constraints, and map the audit's BUG-BA-###/SEC-BA-### items as proving tests. Confirm the plan, then generate parents/masters → transactional → reports last, and pause after the first feature (RatingScale) for my review before continuing.

--------------------------------------------------------------------------

Use the testcase-creator agent — mode=module, module=BehaviouralAssessment. Generate the complete artifact set for every feature, then run report mode to produce the module roll-ups.
Write everything into the existing TestCases/BehaviouralAssessment/ folder (reuse it — don't create a dated copy). Use the Feature Inventory already in that folder as the work-list; skip 00-Module-Overview (not a feature). For each of the 24 features generate the 8 artifacts under BehaviouralAssessment/{Feature}/, then generate the module-level BehaviouralAssessment_Coverage_Dashboard.md and BehaviouralAssessment_RTM.md at the module-folder root. Detect the test style from the module's real source, obey 05_ constraints, and map the audit's BUG-BA-###/SEC-BA-### items as proving tests. Confirm the plan, then generate parents/masters → transactional → reports last, and pause after the first feature (RatingScale) for my review before continuing.

---

I have asked you to Generate the complete artifact set for every feature for "BehaviouralAssessment" but somehow the process breaked in between. Re-run the the process for "BehaviouralAssessment" by executing "Use the testcase-creator agent — mode=module, module=Billing". Generate the complete artifact set for every feature, then run report mode to produce the module roll-ups.


Write everything into the existing "old_db/3-Testing_Audit/TestCases/BehaviouralAssessment/" folder (reuse it — don't create a dated copy). Use the Feature Inventory already in that folder as the work-list; skip 00-Module-Overview (not a feature), also checkd already created files whether they are created completly are partially, If find anything in-complete then cmplete it first. 
For each of the 24 features generate the 8 artifacts under BehaviouralAssessment/{Feature}/, then generate the module-level BehaviouralAssessment_Coverage_Dashboard.md and BehaviouralAssessment_RTM.md at the module-folder root. Detect the test style from the module's real source, obey 05_ constraints, and map the audit's BUG-BA-###/SEC-BA-### items as proving tests. Confirm the plan, then generate parents/masters → transactional → reports last, and pause after the first feature (RatingScale) for my review before continuing.

---
## Prompt:
Read "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/Testing_Prompt/1-TestCase_Agent_using_Prompt.md" and let me know what it wil produce as output. Also let me know whether it is the right way to use to create TestCases files for a Module?

## Responce:








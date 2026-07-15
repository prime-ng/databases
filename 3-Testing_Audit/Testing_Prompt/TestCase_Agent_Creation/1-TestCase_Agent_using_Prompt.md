# Prompt for Generating Test Cases for a Particuler Module (All Artifacts)
==========================================================================

MODULE_NAME  = FrontOffice
Use the testcase-creator agent — mode=module, module={MODULE_NAME}. Generate the complete artifact set for every feature, then run report mode to produce the module roll-ups.


MODULE_NAME = FrontOffice
MODULE_REQUIREMENT = "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/2-Module_Requirement_V1"/{MODULE_NAME}_*

Use the testcase-creator agent — mode=module, module={MODULE_NAME}.

Run end-to-end in ONE go, no pausing:
1. Build the module Fact Pack once (Step 0.5), then generate the complete 5-artifact set for EVERY screen in {MODULE_REQUIREMENT} (all 16 features), back-to-back.
2. Do NOT pause to confirm the Feature Inventory — print it, then proceed straight through all features.
3. Then run report mode to produce the module roll-ups (Coverage Dashboard, RTM, Defect Register, Program Summary).

Keep 00_/03_/05_ byte-stable during the batch (cache warmth). Obey the 05_ Rule Card;
one comprehensive .php per screen; php -l clean; 5 artifacts per feature (combined TcList, GapAnalysis, .php, Validation Report, one run-*.php).


---
BehaviouralAssessment
Billing
MarksheetGeneration
GlobalMaster
Prime
StudentProfile


SystemConfig

---

Maintenance

Notification
ParentPortal
Payment

Ptm
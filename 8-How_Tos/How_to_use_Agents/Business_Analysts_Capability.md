# Business Analyst — Capability Document
==========================================
> Agent definition: `AI_Brain/agents/business-analyst.md` (Enhanced — Maximum-Detail Edition)
> Last updated: 2026-06-27
> Read alongside: `How_to_use_Technical-Auditor_Agent.md`, `0-How_to_use_Agents.md`

This document lists **everything the Business Analyst (BA) agent can produce** and **exactly what to
say** to get each. The BA is the *front door of the analysis pipeline*: its outputs (especially the
FRD) feed the DB Architect, Technical Auditor, Status_Analyzer, and Testing Architect downstream.

The guiding idea of this edition: **you can ask for analysis "whatever way you want."** The BA carries
a 22-artifact **Analysis Mode Catalog** — not a fixed four deliverables. Name an artifact and you get
it to depth; describe a need and the BA proposes the best-fit artifact(s).

---

## 1. Activate the agent
------------------------

Open a Claude Code session and type:
```
act as Business Analyst
```
Claude reads `AI_Brain/agents/business-analyst.md`, loads context (paths, project-context,
modules-map, school-domain, conventions, decisions, RBS, and the module's knowledge file if any), and
replies:
```
Active role: Business Analyst. Ready.
What would you like to analyze, and which artifact(s) should I produce? (or name a module and I'll suggest)
```

> The BA is **session-scoped** — no memory between sessions. It stays "smart" by reloading the context
> files + the per-module knowledge file every session. Keep those updated and the BA stays accurate.

---

## 2. What the BA can do — capability surface at a glance
---------------------------------------------------------

```
A. REQUIREMENTS & SPECS
   1. FRD   — Functional Requirements Document (10-section, business language)   ← flagship
   2. BRD   — Business Requirements Document (vision, objectives, success metrics)
   3. SRS   — Software Requirements Spec (IEEE-830 style)
   4. Feature Specification (screen-by-screen field tables, layout, actions)
   5. RBS Entry (Category→Menu→Screen→F/T/ST atomic breakdown)
   6. User Stories + Acceptance Criteria (Gherkin Given/When/Then)
   7. Requirement Conditions Catalog (consolidated BR conditions)

B. ANALYSIS & MODELS
   8. Business Rules Register (BR- table)
   9. Process Flow / Workflow (steps, swimlanes, exceptions, notifications)
  10. State Machine (FSM) Catalog
  11. Data Dictionary (business view + optional technical view)
  12. Entity-Relationship narrative (business terms, no SQL)
  13. Cross-Module Dependency Map
  14. Integration Contract (cross-module events/services — technical)

C. QUALITY, RISK & PLANNING
  15. Requirements Traceability Matrix (RTM)
  16. Non-Functional Requirements Catalog
  17. Validation & Edge-Case Catalog
  18. Risk Register
  19. Prioritization (MoSCoW and/or RICE)
  20. Effort Estimation & Sprint Task Breakdown
  21. Reporting & Analytics Spec + KPI/Metrics Catalog
  22. Rollout / Change-Management Plan

D. GAP & KNOWLEDGE
  23. Requirements-vs-Code Gap Analysis (BA-side coverage; deep defects → Technical Auditor)
  24. Module Knowledge Seed / Update (per-module knowledge file)
```

Personas/Actor catalogs, Glossaries, and Acceptance-Criteria packs come as sub-artifacts of the above
or standalone on request.

---

## 3. How to use EACH capability — say-this guide
-------------------------------------------------

> Pattern for every command: `act as Business Analyst` → then the request. Name the module by its
> plain name (e.g. "Hostel"); the BA resolves the code/prefix itself. If you don't name an output
> location, the BA saves to the default working repo and tells you the path — or specify one.

### A. Requirements & Specs

**1. FRD — Functional Requirements Document** (the flagship; business language; 10 sections)
```
act as Business Analyst
Create an FRD for Hostel.
```
Produces: `{FRD_DIR}/HST/HST_FRD_{date}.md` with Sections 1–10, `REQ-/BR-/RPT-/ENH-` IDs, the Section
10.1 coverage table (DDL/Screen/API/Notification/Test "Yes/No" flags) that the downstream agents read.
Then auto-updates the module knowledge file. *Use when:* a module is built/scaffolded and you want the
authoritative business spec + the launch point for all gap analyses.

**2. BRD — Business Requirements Document** (vision-level, for sponsors/stakeholders)
```
act as Business Analyst
Write a BRD for the Hostel module — business objectives, success metrics, scope, risks.
```
*Use when:* you need the "why" and measurable outcomes before diving into features.

**3. SRS — Software Requirements Specification** (IEEE-830 flavour; populates empty `3-SRS/`)
```
act as Business Analyst
Generate an SRS for Hostel (functional + interfaces + NFRs + traceability).
```

**4. Feature Specification** (screen-by-screen field tables, layout, actions, filters)
```
act as Business Analyst
Create a Feature Specification for the Hostel Leave Pass sub-module.
```
*Use when:* developers need field-level build detail per screen.

**5. RBS Entry** (Category→Menu→Screen→F/T/ST atomic breakdown)
```
act as Business Analyst
Write the RBS entries for the Hostel Mess Management screens.
```

**6. User Stories + Gherkin Acceptance Criteria**
```
act as Business Analyst
Write user stories with Gherkin acceptance criteria for Hostel Leave Pass approval.
```
Each story gets happy-path + boundary + permission-denied + empty-state scenarios.

**7. Requirement Conditions Catalog** (consolidated BR conditions; populates empty `5-Requirement_Conditions/`)
```
act as Business Analyst
Build a Requirement Conditions Catalog for Hostel.
```

### B. Analysis & Models

**8. Business Rules Register**
```
act as Business Analyst
Extract the full Business Rules Register for Hostel (type, trigger, enforcement point).
```

**9. Process Flow / Workflow** (swimlanes, exception paths, notifications)
```
act as Business Analyst
Map the workflow for Hostel sick-bay admission → discharge, with exception paths and notifications.
```

**10. State Machine (FSM) Catalog**
```
act as Business Analyst
Document all state machines in Hostel (Leave Pass, Allotment, Complaint, Mess Bill…).
```

**11. Data Dictionary**
```
act as Business Analyst
Produce a business Data Dictionary for Hostel (add the technical view too).
```

**12. Entity-Relationship narrative** (business terms, no SQL)
```
act as Business Analyst
Give me a business ER narrative for the Hostel module.
```

**13. Cross-Module Dependency Map**
```
act as Business Analyst
Map Hostel's cross-module dependencies (inbound and outbound, with integration points).
```

**14. Integration Contract** (technical register — events/services)
```
act as Business Analyst
Write the integration contract for Hostel → StudentFee and Hostel → Notification.
```

### C. Quality, Risk & Planning

**15. Requirements Traceability Matrix (RTM)**
```
act as Business Analyst
Build an RTM for Hostel: REQ ↔ BR ↔ screen ↔ test ↔ code status.
```

**16. Non-Functional Requirements Catalog**
```
act as Business Analyst
Write the NFR catalog for Hostel (performance, security, scale, compliance) with thresholds.
```

**17. Validation & Edge-Case Catalog**
```
act as Business Analyst
Produce a validation + edge-case catalog for the Hostel allotment screen.
```

**18. Risk Register**
```
act as Business Analyst
Create a risk register for the Hostel module rollout.
```

**19. Prioritization (MoSCoW / RICE)**
```
act as Business Analyst
Prioritize the Hostel backlog with MoSCoW (and a RICE ranking).
```

**20. Effort Estimation & Sprint Task Breakdown** (populates `4-Sprint_Tasks/`)
```
act as Business Analyst
Break the Hostel FRD into sprint-ready tasks with effort estimates and dependencies.
```

**21. Reporting & Analytics Spec + KPI Catalog**
```
act as Business Analyst
Define the reports and KPIs for Hostel (RPT- entries + KPI formulas + audiences).
```

**22. Rollout / Change-Management Plan**
```
act as Business Analyst
Draft a rollout and change-management plan for launching Hostel to schools.
```

### D. Gap & Knowledge

**23. Requirements-vs-Code Gap Analysis** (coverage-oriented; deep defects → Technical Auditor)
```
act as Business Analyst
Do a requirements-vs-code gap analysis for Hostel (what's DONE / PARTIAL / NOT STARTED, with evidence).
```

**24. Module Knowledge — Seed / Update**
```
act as Business Analyst
Seed module knowledge for Hostel.        # creates the knowledge file from sources
act as Business Analyst
Update module knowledge for Hostel.       # refreshes counts/gaps/decisions (verifies via ls)
```

---

## 4. Combos — "whatever way I want it"
----------------------------------------

The BA mixes artifacts in one request. Examples:
```
act as Business Analyst
For Hostel Leave Pass: user stories + RTM + risk register, then a sprint task breakdown.
```
```
act as Business Analyst
Give me an FRD for Cafeteria, plus the FSM catalog and the reporting/KPI spec.
```
```
act as Business Analyst
Compare what the V2 requirement says vs what's actually built for Inventory, then give me
the requirement-coverage gap analysis and a MoSCoW of the missing pieces.
```

If you describe a need without naming an artifact, the BA proposes the best fit:
```
act as Business Analyst
I need to hand the Hostel module to a new developer so they understand exactly what to build.
→ BA proposes: FRD + Feature Spec + RTM + Sprint Tasks, and asks which to generate.
```

---

## 5. The FRD pipeline (why the FRD matters most)
-------------------------------------------------

The FRD's **Section 10.1 coverage table** (Yes/No flags per requirement) is a machine-readable
contract. After the BA produces an FRD, hand off downstream:

```
1. DDL Schema Gap        → act as DB Architect / Technical Auditor   (does the schema support each REQ?)
2. Application Code Gap   → act as Technical Auditor (Mode B)         (controller/route/view per REQ?)
3. Business-Rule Enforce  → act as Technical Auditor (Mode C)         (is each BR enforced in code?)
4. Completion Scoring     → act as Status_Analyzer                    (6-dimension % score)
5. Test Coverage Gap      → act as Testing Architect                  (a test per acceptance criterion?)
```

The BA prints this handoff menu automatically at the end of every FRD run.

---

## 6. Execution Commands (copy/paste with your values)
------------------------------------------------------

```
MODULE        = Hostel
OUTPUT_PATH   = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents
act as Business Analyst
Create an FRD for {MODULE}. Save under {OUTPUT_PATH}/{CODE}/. Then update module knowledge.
```
```
MODULE        = Hostel
OUTPUT_PATH   = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/9-Working_tmp/Temp_Output_Files
act as Business Analyst
Produce: (1) user stories + Gherkin, (2) RTM, (3) risk register for {MODULE} Leave Pass.
Save all three under {OUTPUT_PATH}.
```

---

## 7. Typical session flow
--------------------------

```
You:    act as Business Analyst
Claude: Active role: Business Analyst. Ready. What artifact(s), and for which module?

You:    Create an FRD for Hostel.
Claude: Module identified: Hostel | Code: HST | Prefix: hst_
        [reads DDL v4, V2/V1 requirements, code; applies intelligence layer]
        FRD saved: .../0-FRD_Documents/HST/HST_FRD_2026-06-27.md
        14 REQ / 22 BR / 4 workflows / 5 reports / 9 ENH  (P0=6, P1=7, P2=1)
        Module knowledge updated: AI_Brain/module-knowledge/HST_Hostel.md
        Next? 1.DDL gap 2.Code gap 3.BR enforce 4.Scoring 5.Test coverage

You:    Now give me the RTM and a MoSCoW prioritization.
Claude: [produces RTM linking REQ↔BR↔screen↔test↔code, then MoSCoW Must/Should/Could/Won't]
```

---

## 8. Quick Reference Card
-------------------------

```
┌─────────────────────────────────────────┬─────────────────────────────────────────────────────────────┐
│                 Goal                    │                          Say This                           │
├─────────────────────────────────────────┼─────────────────────────────────────────────────────────────┤
│ Full business spec for a module         │ act as Business Analyst → Create an FRD for [Module]        │
│ Vision / objectives / metrics           │ act as Business Analyst → Write a BRD for [Module]          │
│ IEEE-style SRS                          │ act as Business Analyst → Generate an SRS for [Module]      │
│ Screen-by-screen build detail           │ act as Business Analyst → Feature Spec for [Module/screen]  │
│ Atomic task tree                        │ act as Business Analyst → RBS entries for [Module screens]  │
│ User stories + Gherkin                  │ act as Business Analyst → User stories for [feature]        │
│ All business rules                      │ act as Business Analyst → Business Rules Register for [Mod] │
│ Workflows w/ exceptions & notifications │ act as Business Analyst → Map the workflow for [process]    │
│ State machines                          │ act as Business Analyst → Document all FSMs in [Module]     │
│ Business data dictionary                │ act as Business Analyst → Data Dictionary for [Module]      │
│ Dependency map                          │ act as Business Analyst → Cross-module dependency map [Mod] │
│ Traceability matrix                     │ act as Business Analyst → Build an RTM for [Module]         │
│ Non-functional requirements             │ act as Business Analyst → NFR catalog for [Module]          │
│ Validation / edge cases                 │ act as Business Analyst → Edge-case catalog for [screen]    │
│ Risk register                           │ act as Business Analyst → Risk register for [Module]        │
│ Prioritize backlog                      │ act as Business Analyst → MoSCoW + RICE for [Module]        │
│ Estimate + sprint tasks                 │ act as Business Analyst → Sprint task breakdown for [Module]│
│ Reports + KPIs                          │ act as Business Analyst → Reporting & KPI spec for [Module] │
│ Rollout plan                            │ act as Business Analyst → Rollout plan for [Module]         │
│ Requirement coverage gap                │ act as Business Analyst → Requirements-vs-code gap [Module] │
│ Seed module knowledge                   │ act as Business Analyst → Seed module knowledge for [Module]│
│ Update module knowledge                 │ act as Business Analyst → Update module knowledge for [Mod] │
└─────────────────────────────────────────┴─────────────────────────────────────────────────────────────┘
```

---

## 9. Where outputs are saved
-----------------------------

```
FRD                       → 4-Requirement_Module_wise/0-FRD_Documents/{CODE}/{CODE}_FRD_{date}.md
Feature Spec              → 5-Project_Planning/3-Feature_Specs/{Module}_FeatureSpec.md   (created on first use)
Sprint Tasks              → 5-Project_Planning/4-Sprint_Tasks/{Module}_Tasks.md          (created on first use)
SRS                       → 5-Project_Planning/3-SRS/{Module}_SRS.md
Requirement Conditions    → 4-Requirement_Module_wise/5-Requirement_Conditions/{Module}_Conditions.md
RBS                       → 4-Requirement_Module_wise/1-RBS/
Requirement-coverage gap  → 6-Dev_Gap_Analysis_Status/Modules_Gap_Analysis/{Module}_{date}.md
BA module summary         → 6-Dev_Gap_Analysis_Status/2-Findings_Module_wise/1-Summary_Module_Knowledge/{Module}_Summary_{date}.md
Module knowledge          → AI_Brain/module-knowledge/{CODE}_{Module}.md
Other artifacts (RTM/NFR/risk/stories…) → working repo default, unless you specify a path
```
If you don't specify a location, the BA defaults to the working repo (`{OLD_REPO}`), never the DB repo,
and tells you the exact path it used.

---

## 10. Steering the agent — quality & corrections
-------------------------------------------------

The BA self-applies a quality bar (business-language discipline, evidence-grounding, testable criteria,
reconciled ID totals, coverage of delete/exception/empty/permission/concurrency cases, academic-year +
per-tenant scoping). If output drifts, correct it precisely:

```
┌────────────────────────────────────────────────┬───────────────────────────────────────────────────────────┐
│              Problem you see                   │                     Say this                              │
├────────────────────────────────────────────────┼───────────────────────────────────────────────────────────┤
│ Technical jargon leaked into a business doc    │ Re-read Sections 1–9; strip every table/column/class      │
│                                                │ /route name and re-state in business terms.               │
│ Copied V2 "FR-" IDs                            │ Re-number REQ- from 001; FR- is the V2 source, not ours.  │
│ Acceptance criteria not testable               │ Rewrite each criterion so a tester answers YES/NO.        │
│ Missing the delete/archive or exception case   │ Add the delete-with-dependencies + exception paths.       │
│ Section 10.4 totals don't match                │ Recount REQ/BR/RPT/ENH and reconcile the totals.          │
│ Status change with no notification             │ Add the notification for every status-changing step.      │
│ Ignored academic-year / per-tenant scoping     │ Add the academic-year filter + per-school isolation note. │
│ Invented features not in the sources           │ Cite the source for each requirement or mark [inferred].  │
│ Counts taken from a seeded "0% Greenfield"     │ Verify counts via ls against Modules/[Module]/ first.     │
│ Module knowledge not updated                   │ Update AI_Brain/module-knowledge/[CODE]_[Module].md.      │
└────────────────────────────────────────────────┴───────────────────────────────────────────────────────────┘
```

---

## 11. The intelligence the BA brings (so you don't have to specify it)
----------------------------------------------------------------------

Every artifact is produced *on top of* the Prime-AI intelligence layer — you get these for free:
- **Indian K-12 domain:** Session→Term→Class→Section→Subject; CBSE/ICSE/State boards; Scholastic vs
  Co-Scholastic; HPC/NEP-2020; fee heads/concessions/fines; CL/EL/SL leave with multi-level escalation;
  transport routes/stops; compliance (POCSO/RTE, grievance redressal, child-safety anonymity).
- **Source precedence + reconciliation:** DDL/code = what *exists*; V2/V1 = what's *intended*; conflicts
  resolved explicitly; the FAC→ACC rename gotcha handled.
- **Cross-module dependency checks** auto-run before writing functional requirements.
- **Database-per-tenant awareness:** no `tenant_id`; data isolated per school; academic-year scoping.
- **Count verification:** seeded "0% Greenfield" is routinely 50–75% actual — the BA verifies via `ls`.

---

## 12. Related files
--------------------

```
AI_Brain/agents/business-analyst.md                         ← the agent definition (capability source)
7-CLAUDE_Prompts/FRD_Creation_Prompt/FRD_Creation_Prompt.md ← authoritative FRD structure (10 sections)
AI_Brain/module-knowledge/{CODE}_{Module}.md                ← per-module persistent memory
AI_Brain/memory/{project-context,modules-map,school-domain,conventions}.md ← context loaded each session
AI_Brain/state/decisions.md                                 ← domain/architecture decisions (D26–D35)
8-How_Tos/How_to_use_Agents/How_to_use_Technical-Auditor_Agent.md ← the downstream audit agent
```

> The BA is session-scoped with no cross-session memory; the context + module-knowledge files ARE its
> memory. Keep them current (the BA updates them automatically after every significant artifact) and the
> agent stays accurate over time.


==============================================================================================================================================
## Responce After Enhancing Business Analyst Agent
--------------------------------------------------

Done. Same evidence-grounded treatment applied to the Business Analyst.

Approach

Read the current BA agent fully, then dispatched 2 parallel surveys of the real requirement-artifact ecosystem: the canonical FRD creation prompt, 
the two existing FRDs (CMP, LIB), the V2/V1 requirement formats, RBS mapping, planning folders, gap-analysis structure, templates, and module-knowledge 
conventions. That revealed the BA's true role — front door of a 5-analysis pipeline whose contract is the FRD's machine-readable Section 10 flags — plus 
the document-layer precedence (V2 FR- → V1 screen-specs → business-language FRD) and several empty folders the BA can now populate 
(5-Requirement_Conditions, 3-SRS, 3-Feature_Specs, 4-Sprint_Tasks).

Primary deliverable — agents/business-analyst.md (rewritten)

The user's key phrase was "whatever way I want it to generate" — so the centerpiece is a broad, on-demand catalog rather than a fixed four deliverables.

┌───────────────────────────────────────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│               Added / expanded                │                                                 What it does                                                │
├───────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Operating Principles                          │ Business-language translation as the #1 skill, evidence-grounding, source precedence, ID hygiene,           │
│                                               │ testable-by-construction                                                                                    │
├───────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Translation discipline table                  │ Technical token → business term mapping (the BA's core competency)                                          │
├───────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Source Precedence & Reconciliation            │ 5-rank ladder (DDL/code authoritative for what exists; V2/V1 for intent); the FR- vs REQ- numbering rule;   │
│                                               │ FAC→ACC rename gotcha; database-per-tenant implications                                                     │
├───────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                               │ FRD, BRD, SRS, Feature Spec, RBS, User Stories+Gherkin, Conditions Catalog, BR Register, Process Flows,     │
│ ⭐ Analysis Mode Catalog (22 artifacts)       │ FSM Catalog, Data Dictionary, ER narrative, Dependency Map, Integration Contract, RTM, NFR Catalog,         │
│                                               │ Validation/Edge-Case Catalog, Risk Register,Prioritization (MoSCoW/RICE), Estimation+Sprint Tasks,          │
│                                               │ Reporting+KPI Spec, Rollout Plan, Gap Analysis, Module Knowledge                                            │
├───────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Full templates for each artifact              │ Concrete structures so any artifact is producible to depth                                                  │
├───────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Prime-AI Intelligence Layer                   │ Expanded K-12 domain (NEP-2020, CBSE/ICSE, fees/concessions, leave-escalation D26, marksheet D32,           │
│                                               │ peer-anonymity D27), cross-module dependency checks, data-scoping                                           │
├───────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ ID conventions consolidated + Common Failures │                                                                                                             │
│  prevention table + Universal Quality Bar     │                                                                                                             │
├───────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Output locations                              │ Maps each artifact to its folder, flagging the empty folders to populate                                    │
├───────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Preserved & enriched                          │ FRD Generation mode (still delegates to the authoritative FRD prompt, now with the 10-section + Section     │
│                                               │ 10.1 contract spelled out), Module Knowledge Seed/Update (now with mandatory ls count-verification — the    │
│                                               │ "0% Greenfield is wrong" lesson), Learning Log (added 2 new entries)                                        │
└───────────────────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

Supporting AI_Brain updates

- README.md — updated the BA description (4 deliverables → 22-artifact catalog) and added two quick-reference rows (produce any artifact; generate an FRD).
- memory/MEMORY.md — enriched the BA capability note + the count-verification rule.

I also surfaced a real doc bug for you (didn't change the external prompt): the FRD prompt's "SIX gap analyses" heading actually lists five — the BA agent 
now notes this so it won't be confused by it.

The four survey agents from both tasks are still alive if you want to go deeper. Want me to demonstrate the enhanced BA by generating a specific artifact 
(e.g. an FRD or a Risk Register + RTM) for one module?

generate a Risk Register + RTM for Hostel
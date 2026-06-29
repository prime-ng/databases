# How to Use Claude Agents
==========================

## Direct Command (Can be used without providing file path, already configured in CLUADE.MD)
--------------------------------------------------------------------------------------------
seed module knowledge for {MODULE} 
update module knowledge for {MODULE}

`/agent business-analyst` → "Complete analysis of Hostel"
`use pa-business-analyst` → "produce FRD for Inventory, Cafeteria, Hostel, Library modules"
`/agent technical-auditor` → "Complete audit of Transport"
`use pa-technical-auditor` → "Complete Audit Inventory, FrontOffice, Cafeteria, Hostel, Library"



Admission
BehaviouralAssessment
Billing
CommonChat
Certificate
HPC

Transport


┌────────────────────────────────────────────────────┬───────────────────────────────────────────────────────────────────────────────────────┐
│               Command                              │                        When to Use                                                    │
├────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────┤
│ save context                                       │ Read and execute `7-CLAUDE_Prompts/0-Important_Prompts/Save_Context.md`               │
├────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────┤
│ seed module knowledge for {MODULE}                 │ Before starting work — builds baseline from existing docs                             │
├────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────┤
│ update module knowledge for {MODULE}               │ It Will update `AI_Brain/module-knowledge/{MODULE_CODE}_{MODULE_NAME}.md`             │
└────────────────────────────────────────────────────┴───────────────────────────────────────────────────────────────────────────────────────┘


Your new workflow for every module:
1. Start work → BA agent auto-reads LIB_Library.md (or whichever module) before starting
2. Finish work → say "update module knowledge for Library" → agent appends learnings
3. Over time, each module file becomes a rich knowledge base specific to that module



## Agent (How to use Agents & what all tasks those Agents are train to perform for)
-----------------------------------------------------------------------------------

┌────────────────────────────────────────┬───────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Command to Activate Agent             │                        When to Use                                                                │
├────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────┤
│ act as Business Analyst                │                                                                                                   │
├────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────┤
│ act as Technical Auditor               │                                                                                                   │
├────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────┤
│ update module knowledge for {MODULE}   │                                                                                                   │
└────────────────────────────────────────┴───────────────────────────────────────────────────────────────────────────────────────────────────┘

## Agent to Create FRD Document
-------------------------------

### Step-1
----------

1. act as Business Analyst to load the agent
2. Say "create an FRD for Library" — it now knows the full process natively
3. After each run, execute anyone of below (Use 1st one if you are creating Module Knowledge first time, else use 2nd one)
    - seed module knowledge for {MODULE} 
    - update module knowledge for {MODULE}


### Step-2
----------

### Updated "7-CLAUDE_Prompts/FRD_Creation_Prompt/FRD_Creation_Prompt.md" & "Busyness Analyst", hence :
Now you can just say: 
"act as Business Analyst" and then 
"create an FRD for Transport" 

— and it will auto-resolve to TPT / tpt_ without any prompting.

FRD is ready for gap analysis. What would you like to do next?

### Step-3
----------

1. DDL Gap Analysis      → act as DB Architect
2. Code Gap Analysis     → act as Technical Auditor
3. Completion Scoring    → act as Status Analyzer
4. Test Coverage Gap     → act as Testing Architect

## Agent (Technical Auditor)
----------------------------

Just say:

"act as Technical Auditor"  Then

"audit the [Module Name] module"

It Will Ask :
  (1) Standard technical audit    — 5-layer scan (schema, code, security, perf, deploy)
                                    NOTE: A full Mode A was already run 2026-06-23.
                                    Only run this if significant code changes since then.

  (2) FRD-driven gap analysis     — NEW: compare all 14 REQ- entries from CMP_FRD_v1.md
                                    vs DDL + code + notifications + tests.
                                    Recommended — FRD was just created, this hasn't been run.

  (3) Business rule enforcement   — NEW: verify all 24 BR- entries from CMP_FRD_v1.md
                                    are enforced in FormRequests / Controllers / Policies.
                                    Recommended — FRD is new, no prior BR audit exists.

  (4) Combined                    — Run modes 2 + 3 (FRD gap + BR enforcement)
                                    Produces the most comprehensive output.

  (5) Specific layer only         — specify: DDL / Code / Security / Performance / Deployment

  ----------------------------------------------------------------------------------------------------------

`/agent business-analyst` → "FRD for the Complaint module."


Next? (post-FRD handoffs)

1. DDL Schema Gap Analysis → /agent db-architect — compare Section 10.1 vs Complaint_DDL_v2.sql
2. Application Code Gap → /agent technical-auditor (Mode B, FRD-driven)
3. Business-Rule Enforcement → /agent technical-auditor (Mode C) — re-run against the refined BRs
4. Completion Scoring (6-dim) → /agent status-analyzer
5. Test Coverage Gap → /agent testing-architect


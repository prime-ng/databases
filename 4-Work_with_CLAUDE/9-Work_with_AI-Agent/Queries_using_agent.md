# Queries on how to use Agent
=============================

## Which Role or Agent I should select to execute "5-Work-In-Progress/22-Inventory/1-Claude_Prompt/INV_2step_Prompt1.md"? and What command I should use to switch to that Role or Agent?

Read 1 file (ctrl+o to expand)

⏺ This prompt has 3 phases that map to different agents:

┌─────────┬──────────────────────────────────────────────────┬──────────────────┐                                               
│  Phase  │                   Deliverable                    │    Best Agent    │
├─────────┼──────────────────────────────────────────────────┼──────────────────┤                                                                                                     
│ Phase 1 │ INV_FeatureSpec.md — Feature Specification + RBS │ Business Analyst │
├─────────┼──────────────────────────────────────────────────┼──────────────────┤                                                                                                     
│ Phase 2 │ INV_DDL_v1.sql + Migrations + Seeders            │ DB Architect     │
├─────────┼──────────────────────────────────────────────────┼──────────────────┤                                                                                                     
│ Phase 3 │ INV_Dev_Plan.md — Sprint-ready Dev Plan          │ Business Analyst │
└─────────┴──────────────────────────────────────────────────┴──────────────────┘                                                                                                     

Since all 3 phases run in a single conversation with review checkpoints, the cleanest option is to use Business Analyst as the primary agent (it owns Phases 1 & 3) and read DB Architect for Phase 2.

---
How to invoke — start your conversation with this command:

Read AI_Brain/agents/business-analyst.md and act as Business Analyst for this session.
Also read AI_Brain/agents/db-architect.md — you will apply it during Phase 2.

Then read the following prompt and wait for me to say "Start Phase 1":
[paste INV_2step_Prompt1.md contents here]

---
Alternatively, since you just created the Enterprise Architect agent which covers the full lifecycle (Feature Spec + Schema Design + Dev Roadmap), you can use that instead:

Read AI_Brain/agents/enterprise-architect.md and act as Enterprise Architect.
Also read AI_Brain/agents/db-architect.md for the schema phase.

Then read the following prompt and wait for me to say "Start Phase 1":
[paste INV_2step_Prompt1.md contents here]

---
As a subagent (if delegating from Claude Code's Agent tool):
subagent_type: "enterprise-architect"

My recommendation: use Enterprise Architect + DB Architect combo — EA handles the feature spec and dev plan, DB Architect ensures DDL quality in Phase 2.

-----------------------------------------------------------

Is it neccesory to provide Agent file path every time. Can't I say only (act as Enterprise Architect)? And Ai_Brain should underdtand what I want. If not then give me some easy way to switch to a particuler Agent? 
Searched for 1 pattern, read 2 files (ctrl+o to expand)

⏺ No, you shouldn't have to. The fix involves two things: a /agent skill for explicit switching, and a CLAUDE.md so natural phrases like "act as Enterprise Architect" work automatically.

⏺ Write(claude-config/skills/agent/SKILL.md)
  ⎿  Wrote 39 lines to claude-config/skills/agent/SKILL.md
      1 ---                                                                                                                                                                                                                 
      2 name: agent                                                                                                                                                                                                         
      3 description: Switch Claude's active role to a named AI_Brain agent                                                                                                                                                  
      4 user_invocable: true                                                                                                                                                                                                
      5 ---                                                 
      6                                                                                                                                                                                                                     
      7 # /agent — Switch Active Role                       
      8
      9 Switch to a named agent from `AI_Brain/agents/`.
     … +29 lines (ctrl+o to expand)

⏺ Now create a CLAUDE.md at the repo root so natural phrases work automatically:
                                                                                                                                  
⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/CLAUDE.md)
  ⎿  Wrote 38 lines to ../CLAUDE.md                                                                                                                                                                                         
       1 # Prime-AI Databases Repo — Claude Instructions
       2                                                                                                                                                                                                                    
       3 ## Agent Switching                                 
       4                                                                                                                                                                                                                    
       5 All agent role guides live in `AI_Brain/agents/`.  
       6                                                                                                                                                                                                                    
       7 **When the user says any of the following, read the corresponding file and adopt that role:**
       8
       9 | User Says | Read File |
      10 |-----------|-----------|
     … +28 lines (ctrl+o to expand)

⏺ Now update the reference doc and deploy:            
                                                                                                                                  
⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/4-Work_with_CLAUDE/9-Work_with_AI-Agent/1-Ai-Agent_Use_Command.md)
  ⎿  Wrote 74 lines to ../4-Work_with_CLAUDE/9-Work_with_AI-Agent/1-Ai-Agent_Use_Command.md                                                                                                                                 
       1 # AI Agent — How to Switch Roles              
       2                                                                                                                                                                                                                    
       3 ## Method 1: Natural Language (Easiest)            
       4                                                                                                                                                                                                                    
       5 Just say it — CLAUDE.md maps the phrase to the agent file automatically.
       6                                                                                                                                                                                                                    
       7 ```                                                
       8 act as Enterprise Architect
       9 act as Business Analyst
      10 act as DB Architect
     … +64 lines (ctrl+o to expand)

⏺ Bash(bash claude-config/setup.sh 2>&1 | tail -15)    
  ⎿  ==========================================                                                                                   
       Deployment Complete!
     ==========================================                                                                                                                                                                             
     … +10 lines (ctrl+o to expand)                                                                                               
                                                                                                                                                                                                                            
  Read 1 file (ctrl+o to expand)                                                                                                                                                                                            
                                                                                                                                  
⏺ Done. You now have 3 ways to switch agents — no file paths needed:                                                                                                                                                        
                                                                                                                                                                                                                            
  ---                                                                                                                             
  Method 1 — Natural language (just say it):                                                                                                                                                                                
  act as Enterprise Architect                                                                                                                                                                                               
  act as Business Analyst    
  act as DB Architect                                                                                                                                                                                                       
  CLAUDE.md handles the lookup automatically.               

  ---                                                                                                                                                                                                                       
  Method 2 — Slash command:
  /agent enterprise-architect                                                                                                                                                                                               
  /agent business-analyst                                   
  /agent db-architect
  Run /agent alone to list all available agents.

  ---
  For the Inventory prompt specifically:
  act as Enterprise Architect and DB Architect. Start Phase 1.                                                                                                                                                              
   
  ---                                                                                                                                                                                                                       
  Files created/updated:                                    
  - CLAUDE.md — auto-loaded, maps "act as X" to the right agent file                                                                                                                                                        
  - AI_Brain/claude-config/skills/agent/SKILL.md — /agent slash command (now deployed)
  - 4-Work_with_CLAUDE/9-Work_with_AI-Agent/1-Ai-Agent_Use_Command.md — reference doc

 -----------------------------------------------------------------------------------------------------------
 ## Is it possible that 1 Agent will consume more tokan then other Agent?
                                                                                                                                                                                                                            
⏺ Yes, significantly. Here's why: 
  What drives token consumption per agent

  1. Agent file size (loaded upfront)   
  ┌──────────────────────┬────────────┬─────────────────┐
  │        Agent         │ File Size  │ Tokens (approx) │
  ├──────────────────────┼────────────┼─────────────────┤                              
  │ Enterprise Architect │ ~450 lines │ ~3,500          │
  ├──────────────────────┼────────────┼─────────────────┤
  │ Business Analyst     │ ~200 lines │ ~1,800          │
  ├──────────────────────┼────────────┼─────────────────┤
  │ DB Architect         │ ~110 lines │ ~900            │
  ├──────────────────────┼────────────┼─────────────────┤                              
  │ Debugger             │ ~50 lines  │ ~400            │
  ├──────────────────────┼────────────┼─────────────────┤                              
  │ Test Agent           │ ~50 lines  │ ~400            │
  └──────────────────────┴────────────┴─────────────────┘

  2. Prerequisites each agent reads before starting
  This is the bigger cost — some agents read many files:

  ┌──────────────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────┬────────────────┐                              
  │        Agent         │                                         Files Read on Start                                         │  Extra Tokens  │
  ├──────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────┼────────────────┤
  │ Enterprise Architect │ 7 files (architecture, tenancy-map, modules-map, decisions, progress, project-context, conventions) │ ~8,000–12,000  │
  ├──────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────┼────────────────┤
  │ Business Analyst     │ 6 files (same set + RBS)                                                                            │ ~7,000–10,000  │
  ├──────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────┼────────────────┤                              
  │ DB Architect         │ DDL files (tenant_db_v2.sql = 10,000+ lines)                                                        │ ~25,000–40,000 │
  ├──────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────┼────────────────┤                              
  │ Debugger             │ Only reads relevant files on demand                                                                 │ ~500–2,000     │
  ├──────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────┼────────────────┤                              
  │ Test Agent           │ Only reads specific test files                                                                      │ ~500–2,000     │
  └──────────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────┴────────────────┘

  3. Output verbosity                    

  Business Analyst and Enterprise Architect produce long structured outputs (RBS entries, feature specs, ADRs). Debugger produces short findings.
  
  ---
  Practical impact

  Most expensive: DB Architect (reads full DDL) + Enterprise Architect + Business Analyst
  Cheapest: Debugger, Test Agent, API Builder

  For multi-phase prompts like the Inventory lifecycle:
  - Phase 1 (BA) + Phase 2 (DB Architect reading full DDL) + Phase 3 — a single conversation can easily consume 50,000–80,000 tokens

  ---
  How to reduce consumption                

  1. Don't load prerequisites you don't need — e.g., if you already know the schema, tell the agent: "Skip reading the DDL, I'll provide the relevant tables directly"
  2. Use subagents (/agent in a fresh subprocess) — each gets an isolated context, protecting your main conversation window
  3. Start fresh per phase — instead of one long conversation, run Phase 1, review, start new session for Phase 2 

  For the Inventory prompt specifically:
  act as Enterprise Architect and DB Architect. Start Phase 1.

---

 Whatis the command to know which Agent is active right now?                                                                                                                                                               

⏺ There's no dedicated "check active agent" command. Agent roles are conversation-context state — they get set when you say act as {Agent Name} or run /agent {name}, and they reset after /clear.

  Current state: No agent active (fresh context after /clear).

  To activate or switch an agent:
  - Say act as Enterprise Architect (or any agent from the CLAUDE.md table)
  - Or run /agent enterprise-architect

  The agent confirms with: Active role: {Agent Name}. Ready.

❯ Tell me the difference bewtween 2 scenario, 1-If I will load any Agent and run a prompt, 2-I will not load any Agent and a prompt. My Prompt is having 2 Secsion one is to create DDl file for a New Module and Another   
is to create Feature Specification document. What will be fiffrence in output Quality and Tokan Consumption?                                                                                                                

⏺ Great question. Here's a clear breakdown:

  ---
  Scenario Comparison

  Token Consumption

  ┌───────────────────┬────────────────┬───────────────────────────────────────────┐
  │                   │    No Agent    │                With Agent                 │
  ├───────────────────┼────────────────┼───────────────────────────────────────────┤
  │ Agent file load   │ 0 tokens       │ +500–1500 tokens (reading agent .md file) │
  ├───────────────────┼────────────────┼───────────────────────────────────────────┤
  │ Prompt processing │ Same           │ Same                                      │
  ├───────────────────┼────────────────┼───────────────────────────────────────────┤
  │ Output tokens     │ Similar volume │ Similar volume                            │
  ├───────────────────┼────────────────┼───────────────────────────────────────────┤
  │ Net difference    │ Lower          │ ~1–3% higher                              │
  └───────────────────┴────────────────┴───────────────────────────────────────────┘

  Verdict: Agent costs slightly more upfront (file read), but negligible difference overall.

  ---
  Output Quality

  ┌──────────────┬─────────────────────────────────────────────────────────────────────────────────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │     Task     │                                    No Agent                                     │                                            With Agent (right role)                                             │
  ├──────────────┼─────────────────────────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DDL File     │ Generic SQL, may miss prefix conventions, tenant_db rules, soft-delete patterns │ Follows exact tt_, std_, etc. prefixes; knows tenant_db isolation; auto-adds is_active, deleted_at, audit cols │
  ├──────────────┼─────────────────────────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Feature Spec │ Good structure but generic                                                      │ Uses your existing doc format, references cross-module dependencies, Indian school context baked in            │
  └──────────────┴─────────────────────────────────────────────────────────────────────────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  ---
  Practical Recommendation for Your 2-Section Prompt

  Your prompt spans two roles — that's the real problem:

  - DDL → needs DB Architect
  - Feature Spec → needs Business Analyst or Enterprise Architect

  Best approach:
  act as DB Architect       → run DDL section
  act as Business Analyst   → run Feature Spec section

  Running both under one agent means one section gets full role-aware quality, the other gets partial. Running with no agent means both sections get generic output — functional, but missing your project's specific
  patterns and conventions.

  Bottom line: For this repo, agent loading pays off for DDL especially — the prefix conventions and multi-tenant rules alone justify the small token overhead.

❯ I have few Queries -                                                                                                                                                                                                      
- Why DB Architect Agent need to read '0-DDL_Masters/tenant_db_v2.sql' every time?                                                                                                                                          
- if the purpose of reading '0-DDL_Masters/tenant_db_v2.sql' is only to understand the Template Schema then can it read "0-DDL_Masters/prime_db_v2.sql" instead of '0-DDL_Masters/tenant_db_v2.sql'?                        
- Prime Schema file "0-DDL_Masters/prime_db_v2.sql" is having less then 1000 lines whereas '0-DDL_Masters/tenant_db_v2.sql' is having more then 10000 lines.                                                                
- If it's possible and the result will be same then How can I Configure the AI_Brain in such way that Agent will read only Prime Db and not Tenant DB?                                                                      
                                                                                                                                                                                                                            
⏺ Good optimization thinking. Let me first check the DB Architect agent file to give accurate answers.                                                                                                                      
                                                                                                                                                                                                                          
Read 1 file (ctrl+o to expand)

⏺ Now I have the full picture. Here are direct answers:

---
  Q1: Why does DB Architect read tenant_db_v2.sql every time?

  The agent file says "Check existing schema" (line 10-14). The intent is to avoid conflicts with existing tables. But here's the key insight:

  The agent file already contains ALL template patterns it needs (lines 54-107):
  - Required columns template                   
  - Naming rules                             
  - Index rules                            
  - Data types 
  - Soft delete pattern

So reading tenant_db_v2.sql for template purposes is redundant — the template is already embedded in the agent file itself.

---
Q2 & Q3: Can prime_db_v2.sql replace tenant_db_v2.sql?

No — wrong substitute. prime_db has billing/tenant-management tables. 99% of new modules go into tenant_db. Using prime_db as a template reference would be misleading.

But more importantly — neither file needs to be read for template purposes.

---                                                                                                                                                                                 
Q4: How to Configure AI_Brain               

The fix is simple — change when the SQL file is read from "always" to "only when needed":
                        
Token Savings Summary
```
┌────────────────────────┬─────────────────────────────────────────────┬─────────────────────────────────────┐
│        Scenario        │                   Before                    │                After                │
├────────────────────────┼─────────────────────────────────────────────┼─────────────────────────────────────┤                                      
│ New module DDL         │ Reads full tenant_db_v2.sql (~10,297 lines) │ Reads nothing extra                 │
├────────────────────────┼─────────────────────────────────────────────┼─────────────────────────────────────┤
│ Extend existing module │ Reads full file                             │ Grep for prefix only (~20-50 lines) │
├────────────────────────┼─────────────────────────────────────────────┼─────────────────────────────────────┤                                      
│ Cross-module FK        │ Reads full file                             │ Read 1 table definition             │
└────────────────────────┴─────────────────────────────────────────────┴─────────────────────────────────────┘
```
  Estimated savings per new module prompt: ~8,000–10,000 tokens — significant.                                                                                                                                              
                                                                                                                                                                                                                          
  The pattern conventions are already in the agent file. The SQL files only need to be consulted for collision checking, not template reference.    
  
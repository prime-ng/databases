# Important Inforation

## How to Recreate Or Full Scan Memory update of AI Brain
=========================================================

Good question. The AI Brain needs a full codebase audit now. Here's the prompt to give me — split into two phases for best  
  results:                                                                                                                  
                                                                                                                              
  ---                                                                                                                         
  Phase 1 — Codebase Structure Audit (run first)                                                                              
                                                                                                                              
  I need you to audit the entire codebase and update the AI Brain with accurate                                               
  information about all merged modules.                                                                                       

  **AI Brain location:** `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/`
  **Code location:** `/Users/bkwork/Herd/prime_ai_tarun/`

  Read these AI Brain files first to understand current state:
  - `AI_Brain/memory/modules-map.md`
  - `AI_Brain/state/progress.md`

  Then scan the codebase:
  1. List all directories in `Modules/` — these are the modules
  2. For each module, count:
     - Models: `Modules/{Name}/app/Models/*.php`
     - Controllers: `Modules/{Name}/app/Http/Controllers/*.php`
     - Services: `Modules/{Name}/app/Services/**/*.php`
     - Routes: lines in `Modules/{Name}/routes/`
     - Migrations (tenant): `database/migrations/tenant/` files containing the module's table prefix
  3. Read each module's `module.json` for enabled/disabled status

  Then update:
  - `AI_Brain/memory/modules-map.md` — accurate model/controller/service counts per module
  - `AI_Brain/state/progress.md` — accurate completion % based on what's actually in the code

  Do NOT guess completion % — base it only on what routes, models, and controllers actually exist.

  ---
  Phase 2 — Deep Module Audit (run after Phase 1)

  Now do a deep audit of each tenant module for known issues, bugs, and gaps.

  For each module in `Modules/`:
  1. Read the module's route file — identify any routes pointing to non-existent
     controller methods (missing implementations)
  2. Read each controller — identify any method that returns a stub/TODO/empty response
  3. Check for SEC issues: missing auth middleware, missing policy checks
  4. Check for N+1 queries: eager loading missing in index methods
  5. Check for missing validation: store/update methods without Form Requests

  Record findings in:
  - `AI_Brain/lessons/known-issues.md` — new bugs/gaps discovered per module
  - `AI_Brain/state/progress.md` — adjust completion % if gaps found

  Focus on modules marked 80–95% complete — these are most likely to have hidden gaps.

  ---
  Tips for running these

  - Run Phase 1 first, let it finish completely before Phase 2
  - Phase 1 takes ~5–10 min (reading ~29 modules)
  - Phase 2 is heavy — if context fills up, run it one module at a time: Audit only the StudentFee module for Phase 2
  - Use /compact between phases to free context
  - After both phases, run Update your Brain to save a session summary

  ---
  The most critical file to get right is AI_Brain/memory/modules-map.md — that's what I reference at the start of every
  session to know what's in each module.





### Question : Which Model and with what effort type I should use for AI Brain update?
--------------------------------------------------------------------------------------

┌─────────────────────────────────────────┬─────────┬────────┬──────────────────────────────────────────────────────────────┐    
│                  Phase                  │  Model  │ Effort │                            Reason                            │    
├─────────────────────────────────────────┼─────────┼────────┼──────────────────────────────────────────────────────────────┤    
│ Phase 1 (structure scan — count files,  │ Sonnet  │ High   │ Mechanical task — reading files and counting. Your current   │    
│ read module.json)                       │ 4.6     │        │ setting is perfect.                                          │    
├─────────────────────────────────────────┼─────────┼────────┼──────────────────────────────────────────────────────────────┤    
│ Phase 2 (deep audit — spot bugs, judge  │ Opus    │ High   │ Requires real judgment: recognizing missing auth checks,     │    
│ completion %, read controllers)         │ 4.6     │        │ N+1s, stub methods. Opus is significantly better at this.    │
└─────────────────────────────────────────┴─────────┴────────┴──────────────────────────────────────────────────────────────┘    

  Switch before Phase 2 with:
  /model opus

  Why high effort for both: The AI Brain update will be referenced in every future session. Getting it right once saves hours of
  corrections later — worth the extra compute.

  Cost note: Phase 2 with Opus on 29 modules will use significant tokens. If cost is a concern, run Phase 2 module-by-module on
  only the 80–95% complete modules (StudentFee, LmsExam, LmsQuiz, LmsHomework, LmsQuests, Hpc, Recommendation) — these are the ones
   most likely to have hidden gaps worth documenting.
   
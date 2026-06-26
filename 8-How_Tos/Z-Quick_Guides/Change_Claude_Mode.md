

  What's Available

  ┌───────────────────────┬────────────────────────────────┬──────────────────────────────────────────────────────────────────────────────────┐
  │         Type          │            Location            │                                    How to Use                                    │
  ├───────────────────────┼────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────┤
  │ Agents (7)            │ AI_Brain/agents/               │ Role-specific instructions for different task types                              │
  ├───────────────────────┼────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────┤
  │ Rules (6)             │ AI_Brain/rules/                │ Mandatory guidelines per area                                                    │
  ├───────────────────────┼────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────┤
  │ Templates (15)        │ AI_Brain/templates/            │ Boilerplate for creating new code                                                │
  ├───────────────────────┼────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────┤
  │ Skills (5)            │ AI_Brain/claude-config/skills/ │ /slash commands: /test, /review, /schema, /lint, /module-status                  │
  ├───────────────────────┼────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────┤
  │ Path-scoped Rules (6) │ AI_Brain/claude-config/rules/  │ Auto-load when touching specific module files (hpc.md, smart-timetable.md, etc.) │
  └───────────────────────┴────────────────────────────────┴──────────────────────────────────────────────────────────────────────────────────┘

  Agents (closest to "modes")

  ┌────────────────────┬──────────────────────────────┬──────────────────────────────────┐
  │       Agent        │             File             │           When to Use            │
  ├────────────────────┼──────────────────────────────┼──────────────────────────────────┤
  │ Developer          │ agents/developer.md          │ General Laravel + modular dev    │
  ├────────────────────┼──────────────────────────────┼──────────────────────────────────┤
  │ DB Architect       │ agents/db-architect.md       │ Database design, migrations      │
  ├────────────────────┼──────────────────────────────┼──────────────────────────────────┤
  │ Module Agent       │ agents/module-agent.md       │ Creating new modules             │
  ├────────────────────┼──────────────────────────────┼──────────────────────────────────┤
  │ Tenancy Agent      │ agents/tenancy-agent.md      │ Multi-tenancy work               │
  ├────────────────────┼──────────────────────────────┼──────────────────────────────────┤
  │ API Builder        │ agents/api-builder.md        │ REST API endpoints               │
  ├────────────────────┼──────────────────────────────┼──────────────────────────────────┤
  │ Debugger           │ agents/debugger.md           │ Debugging issues                 │
  ├────────────────────┼──────────────────────────────┼──────────────────────────────────┤
  │ School Agent       │ agents/school-agent.md       │ School domain business rules     │
  ├────────────────────┼──────────────────────────────┼──────────────────────────────────┤
  │ Test Agent         │ agents/test-agent.md         │ Writing Pest tests               │
  ├────────────────────┼──────────────────────────────┼──────────────────────────────────┤
  │ Business Analyst   │ agents/business-analyst.md   │ RBS, gap analysis, feature specs │
  ├────────────────────┼──────────────────────────────┼──────────────────────────────────┤
  │ Frontend Developer │ agents/frontend-developer.md │ Blade views, Alpine.js           │
  ├────────────────────┼──────────────────────────────┼──────────────────────────────────┤
  │ Backend Developer  │ agents/backend-developer.md  │ Backend logic                    │
  ├────────────────────┼──────────────────────────────┼──────────────────────────────────┤
  │ DevOps Deployer    │ agents/devops-deployer.md    │ Deployment                       │
  └────────────────────┴──────────────────────────────┴──────────────────────────────────┘

  If you want a formal "mode" system (e.g., type /mode architect and Claude switches behavior), that would be a custom Skill — I can create that for you.

  What command I should pass to use these Modes?                                                                                                                                                                        

⏺ These aren't modes you activate with a command — they're reference files Claude reads when needed. Here's how each works:

  Agents

  You don't need to pass any command. Just describe what you want and I'll use the appropriate agent knowledge. But if you want to be explicit:

  ▎ "Read AI_Brain/agents/db-architect.md and follow those instructions to design the schema for X module"

  Skills (actual commands)

  These are the only ones with /commands:

  ┌────────────────┬────────────────────────────────────────────────┐
  │    Command     │                  What it does                  │
  ├────────────────┼────────────────────────────────────────────────┤
  │ /test          │ Run Pest tests                                 │
  ├────────────────┼────────────────────────────────────────────────┤
  │ /review        │ Code review for security, tenancy, performance │
  ├────────────────┼────────────────────────────────────────────────┤
  │ /schema        │ Generate or validate database schema           │
  ├────────────────┼────────────────────────────────────────────────┤
  │ /lint          │ PHP syntax check and code style                │
  ├────────────────┼────────────────────────────────────────────────┤
  │ /module-status │ Show status report for a module                │
  └────────────────┴────────────────────────────────────────────────┘

  Rules

  These auto-load — no command needed. When you touch a file matching the glob pattern (e.g., Modules/Hpc/**), the hpc.md rule loads automatically.

  ---
  Want a formal mode system?

  I can create a /mode skill where you type:

  /mode architect     → loads DB architect agent
  /mode debug         → loads debugger agent
  /mode test          → loads test agent
  /mode analyst       → loads business analyst agent

  That would give you a single command to switch behavior. Want me to create it?

❯ Switch to Frontend developer     
# 01 — Current State Analysis of `.ai/` Brain

## What Exists Today

```
.ai/
├── README.md                          # Entry point — navigation guide
├── agents/          (8 files)         # Role-specific AI instructions
│   ├── api-builder.md                 #   REST API endpoint builder
│   ├── db-architect.md                #   Database design specialist
│   ├── debugger.md                    #   Debugging specialist
│   ├── developer.md                   #   General feature developer
│   ├── module-agent.md                #   Module creation specialist
│   ├── school-agent.md                #   School domain expert
│   ├── tenancy-agent.md               #   Multi-tenancy specialist
│   └── test-agent.md                  #   Pest 4.x testing specialist
│
├── rules/           (6 files)         # Mandatory coding rules
│   ├── code-style.md                  #   PSR-12 naming & formatting
│   ├── laravel-rules.md               #   Framework conventions
│   ├── module-rules.md                #   Module development rules
│   ├── school-rules.md                #   School domain business rules
│   ├── security-rules.md              #   Security & input validation
│   └── tenancy-rules.md               #   Tenancy isolation (CRITICAL)
│
├── templates/       (16 files)        # Boilerplate code
│   ├── api-response.md                #   JSON response format
│   ├── controller.md                  #   Central controller
│   ├── event-listener.md              #   Event/Listener pair
│   ├── form-request.md                #   Validation (Store/Update)
│   ├── model.md                       #   Eloquent model (tenant+central)
│   ├── module-controller.md           #   Module controller (web+API)
│   ├── module-service.md              #   Service class with CRUD
│   ├── module-structure.md            #   New module scaffold
│   ├── policy.md                      #   Authorization policy
│   ├── repository.md                  #   Repository pattern
│   ├── service.md                     #   Central service
│   ├── system-migration.md            #   Central DB migration
│   ├── tenant-migration.md            #   Tenant DB migration
│   ├── test-feature-central.md        #   Central feature test
│   ├── test-feature-tenant.md         #   Tenant feature test
│   └── test-unit.md                   #   Unit test
│
├── memory/          (12 files)        # Stable project knowledge
│   ├── MEMORY.md                      #   Index of all memory files
│   ├── architecture.md                #   System architecture & request flow
│   ├── conventions.md                 #   Naming & coding patterns
│   ├── db-schema.md                   #   Canonical DB schema reference
│   ├── decisions.md                   #   Architectural decision log
│   ├── known-bugs-and-roadmap.md      #   8 bugs, 12 security issues
│   ├── modules-map.md                 #   All 29 modules inventory
│   ├── progress.md                    #   Module completion tracker
│   ├── project-context.md             #   Full project overview
│   ├── school-domain.md               #   School entity relationships
│   ├── tenancy-map.md                 #   Multi-tenancy architecture
│   └── testing-strategy.md            #   Pest 4.x testing approach
│
├── lessons/         (1 file)          # Hard-won knowledge
│   └── known-issues.md                #   Known bugs & gotchas
│
├── state/           (2 files)         # Current project state
│   ├── decisions.md                   #   Architectural decisions (D1-D17)
│   └── progress.md                    #   Work progress tracker
│
└── tasks/           (3 directories)   # Task tracking
    ├── active/                        #   Currently in-progress
    ├── backlog/                       #   Planned but not started
    └── completed/                     #   Done tasks
```

---

## What's Universal vs Module-Specific

### Fully Universal (Works for ALL 29 modules)
| File | Why It's Universal |
|------|-------------------|
| `rules/tenancy-rules.md` | Every query/route/migration follows tenancy rules |
| `rules/module-rules.md` | Every module follows the same structure |
| `rules/code-style.md` | PSR-12 applies everywhere |
| `rules/security-rules.md` | Every form/API/upload |
| `rules/laravel-rules.md` | Framework conventions |
| `templates/*` | All 16 templates work for any module |
| `memory/project-context.md` | Project overview |
| `memory/tenancy-map.md` | Tenancy architecture |
| `memory/conventions.md` | Naming patterns |
| `memory/modules-map.md` | Module inventory |
| `memory/architecture.md` | System architecture |
| `agents/developer.md` | General dev checklist |
| `agents/module-agent.md` | Module creation |
| `agents/tenancy-agent.md` | Tenancy specialist |
| `agents/test-agent.md` | Testing patterns |

### Partially Universal (Domain-specific but not module-specific)
| File | Scope |
|------|-------|
| `rules/school-rules.md` | Any module dealing with school entities |
| `agents/school-agent.md` | School domain workflows |
| `agents/db-architect.md` | Any database work |
| `agents/api-builder.md` | Any API work |
| `agents/debugger.md` | Any debugging work |
| `memory/school-domain.md` | School entity relationships |

### Currently Module-Biased (Recent SmartTimetable Focus)
| File | What's SmartTimetable-specific |
|------|-------------------------------|
| `state/decisions.md` | D11, D14, D16, D17 are SmartTimetable-specific |
| `state/progress.md` | "Recently Completed" section is all SmartTimetable |
| `memory/decisions.md` | Same as state/decisions.md |
| `memory/known-bugs-and-roadmap.md` | Universal but could grow per-module |

---

## The Gap — What's Missing

1. **No per-module memory** — When working on HPC, Claude loads SmartTimetable context too
2. **No module-detection** — Claude doesn't know which module you're focused on
3. **No work-type awareness** — Same instructions whether you're testing, designing DB, or coding
4. **No `.claude/rules/` path-scoping** — Claude Code's native feature for auto-loading rules per file path is unused
5. **No custom skills** — No reusable `/slash-commands` for common workflows
6. **No hooks** — No auto-formatting, no safety guards, no notifications
7. **No subagents** — No specialized workers for testing, code review, etc.

The next document (`02_Module_Aware_AI_Agent.md`) provides the complete plan to fix all of these.

# 12 — Implementation Checklist

> Step-by-step checklist to set up the complete module-aware AI agent system.
> Estimated total time: ~2-3 hours (or ask Claude to generate most of it).

---

## Phase 1: Path-Scoped Rules (30 min)

### Priority 1 — Active Development Modules

- [ ] Create `.claude/rules/` directory
  ```bash
  mkdir -p /Users/bkwork/Herd/laravel/.claude/rules
  ```

- [ ] Create `smart-timetable.md` — SmartTimetable rules
  ```yaml
  globs: ["Modules/SmartTimetable/**", "database/migrations/tenant/*timetable*"]
  ```
  Content: FET solver, constraints, tt_* prefix, D11/D14/D16/D17

- [ ] Create `hpc.md` — HPC rules
  ```yaml
  globs: ["Modules/Hpc/**", "database/migrations/tenant/*hpc*"]
  ```
  Content: DomPDF patterns, merged templates, hpc_* prefix, D13

- [ ] Create `student-profile.md` — StudentProfile rules
  ```yaml
  globs: ["Modules/StudentProfile/**"]
  ```
  Content: Profile tabs, medical incidents, std_* prefix

- [ ] Create `testing.md` — Testing rules
  ```yaml
  globs: ["tests/**", "phpunit.xml"]
  ```
  Content: Pest 4.x patterns, test types, run commands

- [ ] Create `migrations.md` — Migration rules
  ```yaml
  globs: ["database/migrations/**"]
  ```
  Content: Tenant vs central, additive only rule, naming conventions

### Priority 2 — Frequently Touched Modules

- [ ] Create `school-setup.md` — SchoolSetup rules
- [ ] Create `student-fee.md` — StudentFee rules
- [ ] Create `transport.md` — Transport rules
- [ ] Create `lms-exam.md` — LmsExam rules
- [ ] Create `notification.md` — Notification rules

### Priority 3 — Remaining Modules (create as needed)

- [ ] `syllabus.md`, `question-bank.md`, `lms-quiz.md`, `lms-homework.md`
- [ ] `complaint.md`, `vendor.md`, `recommendation.md`
- [ ] `prime.md`, `global-master.md`
- [ ] `blade-views.md`, `api-routes.md`, `policies.md`

---

## Phase 2: Per-Module Memory (30 min)

- [ ] Create `.ai/memory/modules/` directory
  ```bash
  mkdir -p /Users/bkwork/Herd/laravel/.ai/memory/modules
  ```

- [ ] Create module memory files (move relevant D## decisions from state/decisions.md):
  - [ ] `smart-timetable.md` — D11, D14, D16, D17, solver patterns
  - [ ] `hpc.md` — D13, DomPDF patterns, template structure
  - [ ] `student-profile.md` — Dusk tests, profile tabs
  - [ ] (Add others as you work on them)

- [ ] Update `.ai/memory/MEMORY.md` to index the new module files

---

## Phase 3: CLAUDE.md Optimization (15 min)

- [ ] Backup current CLAUDE.md
  ```bash
  cp CLAUDE.md CLAUDE.md.backup
  ```

- [ ] Trim CLAUDE.md to ~50 lines:
  - Keep: Tech stack, critical rules, key paths, brain pointer
  - Move to `.claude/rules/`: Module-specific content
  - Add: `@.ai/rules/tenancy-rules.md` and `@.ai/rules/module-rules.md` imports

---

## Phase 4: Custom Skills (30 min)

- [ ] Create `.claude/skills/` directory
  ```bash
  mkdir -p /Users/bkwork/Herd/laravel/.claude/skills
  ```

- [ ] Create essential skills:
  - [ ] `/test` — Run Pest tests (`skills/test/SKILL.md`)
  - [ ] `/review` — Code review (`skills/review/SKILL.md`)
  - [ ] `/schema` — DB schema work (`skills/schema/SKILL.md`)
  - [ ] `/lint` — PHP syntax check (`skills/lint/SKILL.md`)
  - [ ] `/module-status` — Module status report (`skills/module-status/SKILL.md`)

---

## Phase 5: Subagents (20 min)

- [ ] Create `.claude/agents/` directory
  ```bash
  mkdir -p /Users/bkwork/Herd/laravel/.claude/agents
  ```

- [ ] Create essential agents:
  - [ ] `test-runner/AGENT.md` — Run tests, report failures
  - [ ] `code-reviewer/AGENT.md` — Security, tenancy, performance review
  - [ ] `performance-auditor/AGENT.md` — N+1 queries, missing indexes
  - [ ] `db-analyzer/AGENT.md` — Schema-model alignment check

---

## Phase 6: Hooks (15 min)

- [ ] Create `.claude/hooks/` directory
  ```bash
  mkdir -p /Users/bkwork/Herd/laravel/.claude/hooks
  ```

- [ ] Create hooks:
  - [ ] `validate-bash.sh` — Block dangerous DB operations
  - [ ] Add desktop notification hook to `~/.claude/settings.json`

- [ ] Add hook config to `.claude/settings.json`

---

## Phase 7: Git Worktrees (15 min)

- [ ] Create permanent worktrees for your 3 branches:
  ```bash
  cd /Users/bkwork/Herd/laravel
  git worktree add ../laravel-smarttimetable Brijesh_SmartTimetable_2026Mar10
  git worktree add ../laravel-hpc <HPC_BRANCH_NAME>
  git worktree add ../laravel-tests <TESTS_BRANCH_NAME>
  ```

- [ ] Set up each worktree:
  ```bash
  for dir in laravel-smarttimetable laravel-hpc laravel-tests; do
    cd /Users/bkwork/Herd/$dir
    cp ../.env .env 2>/dev/null
    composer install
    npm install
  done
  ```

- [ ] Configure Herd (if needed) to serve each worktree

---

## Phase 8: Settings & Permissions (10 min)

- [ ] Create/update `.claude/settings.json`:
  ```json
  {
    "permissions": {
      "allow": [
        "Bash(php artisan *)",
        "Bash(./vendor/bin/pest *)",
        "Bash(git *)",
        "Bash(npm run *)",
        "Bash(composer *)"
      ],
      "deny": [
        "Bash(DROP DATABASE)",
        "Bash(DELETE FROM)",
        "Bash(migrate:fresh)",
        "Bash(migrate:reset)"
      ]
    }
  }
  ```

- [ ] Merge hooks config into the same settings file

---

## Phase 9: Verification (15 min)

- [ ] Start a new Claude session in SmartTimetable worktree
  ```bash
  cd /Users/bkwork/Herd/laravel-smarttimetable
  claude
  ```

- [ ] Verify:
  - [ ] CLAUDE.md loads (short version)
  - [ ] Touch a SmartTimetable file → smart-timetable rules auto-load
  - [ ] `/test` skill works
  - [ ] Desktop notification fires
  - [ ] Dangerous command is blocked

- [ ] Test module switching:
  - [ ] In the same session, touch an HPC file → HPC rules auto-load
  - [ ] SmartTimetable rules should NOT load if only touching HPC files

---

## Phase 10: Documentation (10 min)

- [ ] Update `.ai/README.md` to mention the new `.claude/` structure
- [ ] Add `.claude/settings.local.json` to `.gitignore`
- [ ] Commit `.claude/rules/`, `.claude/skills/`, `.claude/agents/`, `.claude/hooks/`
- [ ] Update `.ai/state/progress.md`

---

## Shortcut: Ask Claude to Generate Everything

Instead of manually creating all these files, you can ask Claude:

```
"Based on the guide in databases/Z_Work-In-Progress/Z_How_Tos/How_to_use_claude/,
create all the .claude/rules/ files for my top 6 modules:
SmartTimetable, Hpc, StudentProfile, SchoolSetup, StudentFee, and Testing.
Also create the 4 custom skills and 4 subagent files."
```

Claude will generate all files using its knowledge of your project from `.ai/memory/modules-map.md`.

---

## Final Directory Structure After Implementation

```
/Users/bkwork/Herd/laravel/
├── CLAUDE.md                              # Trimmed to ~50 lines
├── .ai/                                   # The Brain (existing, enhanced)
│   ├── memory/
│   │   ├── modules/                       # NEW: Per-module memory
│   │   │   ├── smart-timetable.md
│   │   │   ├── hpc.md
│   │   │   └── ...
│   │   └── (existing files)
│   └── (existing structure)
├── .claude/                               # Claude Config (new)
│   ├── settings.json                      # Permissions + hooks
│   ├── settings.local.json                # Personal (gitignored)
│   ├── rules/                             # Path-scoped auto-load
│   │   ├── smart-timetable.md
│   │   ├── hpc.md
│   │   ├── student-profile.md
│   │   ├── testing.md
│   │   ├── migrations.md
│   │   └── ...
│   ├── skills/                            # /slash commands
│   │   ├── test/SKILL.md
│   │   ├── review/SKILL.md
│   │   ├── schema/SKILL.md
│   │   ├── lint/SKILL.md
│   │   └── module-status/SKILL.md
│   ├── agents/                            # Subagents
│   │   ├── test-runner/AGENT.md
│   │   ├── code-reviewer/AGENT.md
│   │   ├── performance-auditor/AGENT.md
│   │   └── db-analyzer/AGENT.md
│   └── hooks/                             # Automation scripts
│       └── validate-bash.sh
└── .gitignore                             # Add: .claude/settings.local.json
```

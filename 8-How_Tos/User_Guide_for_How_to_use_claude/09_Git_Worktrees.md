# 09 — Git Worktrees for Parallel Branch Work

---

## Your Specific Situation

You work on 3 types of work simultaneously, each on a different branch:

| Branch | Work Type | Current Branch Name |
|--------|-----------|-------------------|
| Branch 1 | SmartTimetable Development | `Brijesh_SmartTimetable_2026Mar10` |
| Branch 2 | HPC Reportcard Development | (HPC branch) |
| Branch 3 | Test Case Scripts | (Test branch) |
| Main | Integration | `multi-tenancy-2` |

**Problem:** All 3 branches are in the same repo. Switching branches with `git checkout` is disruptive — unstashed changes, wrong files open, mixed context.

**Solution:** Git worktrees — each branch gets its own directory, all sharing the same git history.

---

## What Are Git Worktrees?

A worktree is a separate checkout of the same repository. You can have multiple branches checked out simultaneously in different directories:

```
/Users/bkwork/Herd/laravel/                          <-- Main worktree (multi-tenancy-2)
/Users/bkwork/Herd/laravel-smarttimetable/           <-- Worktree 1 (SmartTimetable branch)
/Users/bkwork/Herd/laravel-hpc/                      <-- Worktree 2 (HPC branch)
/Users/bkwork/Herd/laravel-tests/                    <-- Worktree 3 (Tests branch)
```

All 4 directories share the **same `.git` history**. Commits made in any worktree are visible in all others.

---

## Setup — Manual Git Worktrees (Recommended)

### Step 1: Create Worktrees

```bash
cd /Users/bkwork/Herd/laravel

# Create SmartTimetable worktree
git worktree add ../laravel-smarttimetable Brijesh_SmartTimetable_2026Mar10

# Create HPC worktree (replace with your actual HPC branch name)
git worktree add ../laravel-hpc Brijesh_HPC_branch

# Create Tests worktree (replace with your actual test branch name)
git worktree add ../laravel-tests Brijesh_Tests_branch
```

### Step 2: Each Worktree Gets Its Own Claude Session

```bash
# Terminal 1 — SmartTimetable work
cd /Users/bkwork/Herd/laravel-smarttimetable
claude

# Terminal 2 — HPC work
cd /Users/bkwork/Herd/laravel-hpc
claude

# Terminal 3 — Test work
cd /Users/bkwork/Herd/laravel-tests
claude
```

### Step 3: Verify Setup

```bash
# List all worktrees
git worktree list

# Output:
# /Users/bkwork/Herd/laravel                    abc1234 [multi-tenancy-2]
# /Users/bkwork/Herd/laravel-smarttimetable      def5678 [Brijesh_SmartTimetable_2026Mar10]
# /Users/bkwork/Herd/laravel-hpc                 ghi9012 [Brijesh_HPC_branch]
# /Users/bkwork/Herd/laravel-tests               jkl3456 [Brijesh_Tests_branch]
```

---

## Claude Code's Built-in Worktree Support

Claude Code also has built-in worktree support via `claude --worktree`:

```bash
# Auto-creates a worktree in .claude/worktrees/
claude --worktree smarttimetable-feature

# Claude works in isolated directory
# On exit: auto-deleted if no changes, prompt to keep if changes made
```

**Difference:**
- `claude --worktree` = temporary, managed by Claude, auto-cleaned
- `git worktree add` = permanent, you manage, persists across sessions

**For your 3-branch setup, use `git worktree add`** (permanent) — you want these to persist.

---

## How Memory Works Across Worktrees

All worktrees in the same git repo **share Claude's auto-memory**:

```
~/.claude/projects/-Users-bkwork-Herd-laravel/memory/
  └── Shared by ALL worktrees (main, smarttimetable, hpc, tests)
```

This means:
- Learnings from SmartTimetable work are available in HPC sessions
- Module-specific rules need `.claude/rules/` path-scoping to avoid cross-loading

**This is why `.claude/rules/` is so important** — without path-scoped rules, Claude would load SmartTimetable context even in the HPC worktree.

---

## Worktree-Specific Considerations

### `.env` Files
Each worktree needs its own `.env`:
```bash
cp /Users/bkwork/Herd/laravel/.env /Users/bkwork/Herd/laravel-smarttimetable/.env
cp /Users/bkwork/Herd/laravel/.env /Users/bkwork/Herd/laravel-hpc/.env
cp /Users/bkwork/Herd/laravel/.env /Users/bkwork/Herd/laravel-tests/.env
```

### `vendor/` and `node_modules/`
Each worktree needs its own dependencies:
```bash
cd /Users/bkwork/Herd/laravel-smarttimetable && composer install && npm install
cd /Users/bkwork/Herd/laravel-hpc && composer install && npm install
cd /Users/bkwork/Herd/laravel-tests && composer install && npm install
```

### Laravel Herd
If using Herd, you may need to add each worktree as a separate site:
- `laravel-smarttimetable.test`
- `laravel-hpc.test`
- `laravel-tests.test`

---

## Managing Worktrees

```bash
# List all worktrees
git worktree list

# Remove a worktree (after merging branch)
git worktree remove ../laravel-smarttimetable

# Prune stale worktree references
git worktree prune

# Move a worktree
git worktree move ../laravel-smarttimetable ../new-location
```

---

## Workflow: Day-to-Day with 3 Worktrees

```
Morning:
  Terminal 1: cd ~/Herd/laravel-smarttimetable && claude --continue
  Terminal 2: cd ~/Herd/laravel-hpc && claude --continue
  Terminal 3: cd ~/Herd/laravel-tests && claude --continue

During the day:
  Switch between terminals as needed
  Each terminal has its own Claude session with module-specific context
  Changes are isolated — no branch switching needed

End of day:
  Each worktree: git add, git commit, git push
  Changes are independent — no merge conflicts until integration

Integration:
  cd ~/Herd/laravel (main worktree, multi-tenancy-2 branch)
  git merge Brijesh_SmartTimetable_2026Mar10
  git merge Brijesh_HPC_branch
  Resolve conflicts if any
  git push
```

---

## Subagent Worktrees (Advanced)

Claude can also spawn subagents in isolated worktrees:

```yaml
# In AGENT.md frontmatter:
---
name: risky-refactor
isolation: worktree
---
```

The subagent gets its own copy of the repo. If it makes changes:
- Returns the worktree path and branch name
- You can review and merge, or discard

This is useful for risky operations (refactoring, schema changes) that you want to preview before applying.

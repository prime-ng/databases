# How to Switch Claude from one Account to Another without loosing anything
===========================================================================

 Now I want to use my another Claude account. What all steps I need to take to move from this account to another account, so I will not loose any of my work context, knowledge etc. and I will get same smooth transition experience. I have already saved context into a file "old_db/.ai-contexts/2026-06-27_14-00_module-knowledge-update-summary-8-modules-ba-agent.md". provide me step by step process to logout from this account and login on another account.

Let me check what's currently modified and what needs to be preserved before you switch accounts.

  Ran 1 shell command

Good. Here's the full picture and what you need to do:

---
What Is Account-Specific vs. Local

Good news: Almost everything is LOCAL on your Mac, not tied to your account:
- The entire git repo (old_db/) — local
- AI_Brain/ module knowledge, agents, memory — local
- CLAUDE.md project instructions — local
- Claude Code project memory (~/.claude/projects/.../memory/) — local
- Claude Code settings (~/.claude/settings.json) — local

Account-specific (will change): Only the authentication token and any billing/subscription.

---
Step-by-Step Transition

Step 1 — Commit all modified files (CRITICAL — do this first)

You have 24 modified/untracked files. They are only on your local disk right now.

git add -A
git commit -m "Save session state before account switch"
git push origin Brijesh

▎ Push to remote so work is backed up even if anything local changes.

Step 2 — Verify your context file is saved

You already saved: .ai-contexts/2026-06-27_14-00_module-knowledge-update-summary-8-modules-ba-agent.md
That file is untracked — make sure it's included in the commit above (the git add -A covers it).

Step 3 — Note your memory files (no action needed)

Your 3 memory files at ~/.claude/projects/.../memory/ are local — they will survive the account switch. You don't need to copy them anywhere.

Step 4 — Log out of current account

claude logout

Or from Claude Code desktop/IDE: Settings → Account → Sign Out

Step 5 — Log in with new account

claude login

Follow the browser OAuth flow for your new account.

Step 6 — Reopen the project

Navigate back to the old_db/ directory. Claude Code will:
- Reload CLAUDE.md automatically
- Find the local memory files (same machine path)
- See the full git history

Step 7 — Resume work

Start a new session and run:
save context
Or just mention the context file to re-orient:

▎ "Read .ai-contexts/2026-06-27_14-00_module-knowledge-update-summary-8-modules-ba-agent.md and resume as Business Analyst"

---
Summary

The only real risk is uncommitted local changes — that's what Step 1 prevents. Everything else (memory, CLAUDE.md, AI_Brain, module knowledge) is local and survives the account switch untouched.
# Context Save & Recall System for Claude Agent in VS Code

---

## 📋 CONFIGURATION (Edit once, used by both prompts)

```yaml
CONTEXT_STORAGE_DIR: ".ai-contexts"    # Folder where context files are saved (relative to project root)
PROJECT_NAME: "PrimeAI"                # Your project name (used in filenames)
MAX_CONTEXT_FILES: 200                  # Optional: max files to keep (oldest auto-flagged)
```

---
---

## PROMPT 1: SAVE CONTEXT

### Usage: Say "Save context" or "Save this context" at any point in your conversation

---

```
### INSTRUCTION: CONTEXT SAVE SYSTEM

You have a standing instruction that applies throughout this entire session:

**Whenever I say "save context", "save this context", "save session", or "checkpoint" — you must immediately execute the following procedure:**

#### STEP 1 — Analyze the Conversation

Review our ENTIRE conversation from the very first message to this point. Identify:
- What was the primary task/goal of this session?
- What specific files were created, modified, or discussed?
- What key decisions were made and WHY?
- What problems were encountered and how were they solved?
- What is the current state of work (what's done, what's in progress, what's pending)?
- Any important technical details, patterns, or approaches established
- Any instructions or preferences I stated that should carry forward
- Any TODO items, open questions, or unresolved issues

#### STEP 2 — Generate a Descriptive Filename

Create a filename that clearly describes the work done. Follow this format:

`YYYY-MM-DD_HH-MM_<short-descriptive-slug>.md`

Rules for the slug:
- Use 3-6 words separated by hyphens
- Be specific, not generic (NOT "coding-session" — YES "timetable-constraint-engine-refactor")
- Include the module or feature name
- Include the primary action (setup, refactor, debug, design, implement, fix, migrate, etc.)
- Examples:
  - `2025-06-15_14-30_smart-timetable-generation-algorithm-debug.md`
  - `2025-06-15_16-45_student-model-relationships-and-migration.md`
  - `2025-06-15_19-00_rbac-permission-seeder-implementation.md`
  - `2025-06-15_21-15_transport-route-optimization-api-design.md`

#### STEP 3 — Create the Context File

Save to: `{{CONTEXT_STORAGE_DIR}}/<generated-filename>`

The file MUST follow this exact structure:

```markdown
# Context: [One-line title describing the session work]
# Saved: [Date and Time]
# Session Duration: [Approximate — from first message topic to now]
# Project: {{PROJECT_NAME}}

---

## 1. SESSION OBJECTIVE
[What was the primary goal? What did I ask to accomplish?]

## 2. SUMMARY OF WORK DONE
[Concise but complete summary — 5-15 bullet points covering everything accomplished]

## 3. FILES TOUCHED
### Created:
- `path/to/file.php` — [Purpose: what this file does]
### Modified:
- `path/to/file.php` — [What was changed and why]
### Discussed/Reviewed (not modified):
- `path/to/file.php` — [Why it was discussed]

## 4. KEY DECISIONS & RATIONALE
[Every important decision made during the session, with the reasoning behind it]
- **Decision:** [What was decided]
  **Why:** [The reasoning]
  **Alternatives Considered:** [If any were discussed]

## 5. TECHNICAL DETAILS & PATTERNS
[Any architectural patterns, coding conventions, data structures, algorithms, or technical approaches established or used]
- [Detail 1]
- [Detail 2]

## 6. DATABASE CHANGES
[Any tables created, columns added, relationships changed, migrations written]
- Table: `table_name` — [What was done]
- Migration: `migration_file.php` — [What it does]
(Write "None" if no DB changes)

## 7. PROBLEMS ENCOUNTERED & SOLUTIONS
[Every error, bug, or challenge faced and how it was resolved]
- **Problem:** [Description]
  **Cause:** [Root cause]
  **Solution:** [How it was fixed]
(Write "None" if no problems)

## 8. CURRENT STATE OF WORK
### Completed:
- [What is fully done and working]
### In Progress:
- [What was started but not finished — include exact stopping point]
### Not Yet Started:
- [What was planned but we didn't get to]

## 9. OPEN QUESTIONS & TODOS
[Anything unresolved that needs future attention]
- [ ] [TODO item 1]
- [ ] [TODO item 2]
- [?] [Open question needing decision]

## 10. IMPORTANT CONTEXT FOR FUTURE SESSIONS
[Anything a future Claude instance MUST know to continue this work effectively]
[Include: variable names, function signatures, specific logic rules, constraints, edge cases discussed, user preferences stated]

## 11. DEPENDENCIES & CROSS-MODULE REFERENCES
[Other modules, packages, services, or external systems this work connects to]
- [Dependency 1 and how it relates]

## 12. CONVERSATION HIGHLIGHTS — RAW NOTES
[Key excerpts, commands, code snippets, or exact phrases from the conversation that would be critical for recall. This is the "raw memory" section — include anything that doesn't fit above but might be important.]

---
*End of Context Save*
```

#### STEP 4 — Confirm to User

After saving, display:
1. The full filepath where the context was saved
2. A 3-line summary of what was captured
3. The message: "Context saved. You can safely clear this conversation. To recall later, use the recall prompt with this filename."

#### IMPORTANT RULES:
- NEVER skip sections. If a section has nothing, write "None" or "N/A" — don't omit it.
- NEVER be vague. Use specific file paths, method names, table names, column names.
- NEVER summarize away details. When in doubt, include MORE detail, not less.
- Capture MY preferences and instructions (e.g., "user prefers X approach", "user said always do Y").
- If we discussed multiple topics, document ALL of them — not just the last one.
- The context file should be SELF-SUFFICIENT — a future Claude instance should be able to read ONLY this file and fully understand what happened and what to do next.

**Acknowledge this instruction now with: "Context save system active. Say 'save context' at any time."**
```

---
---

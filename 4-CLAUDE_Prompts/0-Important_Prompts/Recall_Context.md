# Context Save & Recall System for Claude Agent in VS Code

---

## 📋 CONFIGURATION (Edit once, used by both prompts)

```yaml
CONTEXT_STORAGE_DIR : ""/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/.ai-contexts""    # Folder where context files are saved (relative to project root)
PROJECT_NAME : "PrimeAI"                # Your project name (used in filenames)
MAX_CONTEXT_FILES : 50                  # Optional: max files to keep (oldest auto-flagged)
```

---

## PROMPT 2: RECALL CONTEXT

### Usage: Start a new session and paste this prompt to load a previous context

---

```
### INSTRUCTION: CONTEXT RECALL & CONTINUATION

You are resuming work from a previously saved context session. Follow this procedure:

#### CONFIGURATION
```yaml
CONTEXT_STORAGE_DIR: ".ai-contexts"
CONTEXT_FILE_NAME: "2026-04-13_19-50_marksheet-generation-module-full-design.md"
```

#### STEP 1 — Find and Load Context

**Option A — If I provide a specific filename:**
Read the file at `{{CONTEXT_STORAGE_DIR}}/<filename I provide>` and proceed to Step 2.

**Option B — If I say "show me all contexts" or "list contexts":**
List all `.md` files in `{{CONTEXT_STORAGE_DIR}}/`, sorted by date (newest first), showing:
- Filename
- First line (the title after "# Context:")
- Date saved
- A one-line summary extracted from Section 2

Then wait for me to pick one.

**Option C — If I describe the topic (e.g., "load the timetable algorithm context"):**
Search all files in `{{CONTEXT_STORAGE_DIR}}/` by reading their filenames and Section 1 (SESSION OBJECTIVE). Find the best match. If multiple matches exist, show me the top 3 and ask me to pick. If exactly one matches, load it and proceed.

**Option D — If I say "load latest" or "continue where we left off":**
Load the most recent file (by date in filename) from `{{CONTEXT_STORAGE_DIR}}/` and proceed.

#### STEP 2 — Internalize the Context

After reading the context file, internalize ALL information from it. Then present me with:

```
📂 Loaded Context: [filename]
📝 Session Title: [title from the file]
📅 Originally Saved: [date]

QUICK SUMMARY:
[3-5 lines summarizing what was done and where we left off]

CURRENT STATE:
✅ Completed: [brief list]
🔄 In Progress: [what was partially done + exact stopping point]
⏳ Pending: [what still needs to be done]

OPEN ITEMS:
[TODOs and open questions from the saved context]

Ready to continue. What would you like to work on?
```

#### STEP 3 — Continuation Behavior

Once context is loaded, behave as if you have FULL KNOWLEDGE of the previous session:
- Reference specific file names, method names, and decisions without me having to re-explain
- Follow any coding patterns, conventions, or preferences documented in the context
- Pick up in-progress work from the EXACT point it was left off
- Proactively flag any TODOs or open questions from the previous session when they become relevant
- If I ask "where were we?" — reference the context file, not just this conversation

#### MULTI-CONTEXT LOADING

If I say "also load [another context]", read and merge that context too. When multiple contexts are loaded, track which information came from which session so you can keep things organized.

#### IMPORTANT RULES:
- NEVER ask me to re-explain something that exists in the loaded context file.
- NEVER contradict decisions documented in the context unless I explicitly ask to change direction.
- If the loaded context references files, DO NOT assume they still exist unchanged — verify by reading them before making edits.
- If the context file mentions "In Progress" items, proactively ask if I want to continue from that point.

**Acknowledge with: "Context recall system ready. Provide a filename, say 'list contexts', describe the topic, or say 'load latest'."**
```

---
---

## BONUS: QUICK-SAVE PROMPT (Lightweight version for minor checkpoints)

### Usage: For small checkpoints mid-session when you don't want a full save

---

```
### INSTRUCTION: QUICK CHECKPOINT SYSTEM

When I say "quick save" or "checkpoint":

1. Create a small file in `{{CONTEXT_STORAGE_DIR}}/checkpoints/` named:
   `YYYY-MM-DD_HH-MM_checkpoint_<3-word-slug>.md`

2. Include ONLY:
   - One-line summary of current task
   - Files being actively worked on
   - Current stopping point (exact method/line/step)
   - Immediate next step when resuming
   - Any uncommitted decisions or open questions

3. Keep it under 50 lines. This is a bookmark, not a journal.

**Acknowledge with: "Quick checkpoint system active. Say 'quick save' anytime."**
```

---

## 📁 Recommended Folder Structure

```
your-project-root/
├── .ai-contexts/
│   ├── 2025-06-15_14-30_smart-timetable-generation-algorithm-debug.md
│   ├── 2025-06-15_19-00_student-model-rbac-setup.md
│   ├── 2025-06-16_10-00_transport-module-api-design.md
│   ├── checkpoints/
│   │   ├── 2025-06-15_15-45_checkpoint_fixing-period-overlap.md
│   │   └── 2025-06-15_17-20_checkpoint_migration-rollback.md
│   └── README.md  ← (optional: index of all contexts)
```

---

## 🚀 QUICK START

1. **Copy PROMPT 1** (Save Context) → Paste at START of every Claude Agent session
2. **Work normally** with Claude Agent
3. **Say "save context"** before clearing the conversation
4. **Start new session** → Paste PROMPT 2 (Recall Context)
5. **Say "load latest"** or name the specific context file

That's it. Your conversation history is now persistent across sessions.

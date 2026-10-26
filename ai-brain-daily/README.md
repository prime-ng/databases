# AI Brain — Daily Work Memory

**Location:** `/home/shailesh/shailesh/ai-brain-daily/` — outside the `prime_ai` project, shared by every AI model working on it (Claude, Gemini, opencode, Cursor, Codex, Antigravity, etc.).

The enforceable rule lives in the project at
[`../prime_ai/GEMINI.md`](../prime_ai/GEMINI.md) under
**"Strict Mandatory Daily Work Ledger & Evening Closeout Rule"**. This README is the quick guide.

## Load the Brain (Every Session)

In chat, just say **`Load the AI Brain`** (or `load brain`). The agent must run the load steps immediately.

Or run this once before starting work:

```bash
/home/shailesh/shailesh/ai-brain-daily/load.sh
```

It prints the index, the latest 3 daily reports, today's live journals from every AI model,
and the module index. The agent must then reply:

```text
AI Brain loaded: <date>, <n> live entries, last report <date>.
```

If the model does not read project rules automatically, paste the ready-made prompt from
[`LOAD-PROMPT.md`](LOAD-PROMPT.md).

## Folder Map

```text
ai-brain-daily/
├── README.md                  # this file
├── LOAD-PROMPT.md             # copy-paste prompt for any AI model
├── load.sh                    # prints the current brain snapshot
├── 00-INDEX.md                # one row per closed day
├── _templates/
│   ├── live-entry.md          # copy this into live/ for a new agent/day
│   └── evening-summary.md     # structure of the evening report
├── live/
│   └── YYYY-MM-DD/
│       └── <agent>.md         # append-only, written during the day
├── daily/
│   └── YYYY-MM-DD.md          # git-verified evening summary
└── modules/
    ├── 00-INDEX.md            # module rollup index
    └── <Module>.md            # cumulative module history
```

## During the Day

After **every** task or commit, the agent appends one entry to:

```text
ai-brain-daily/live/YYYY-MM-DD/<agent>.md
```

- Use the Asia/Kolkata date.
- One file per AI model, so parallel models never overwrite each other.
- Re-read the tail before appending.
- Never rewrite earlier entries.
- Never write secrets (`.env` values, API keys, passwords, tokens).

Each entry answers the four required questions:

1. **Which file changed?** exact repo-relative path.
2. **What changed?** specific change.
3. **Why?** the reason/request.
4. **Proof?** command output, test result, or commit hash.

## Evening Closeout

Triggers: `evening summary`, `day summary`, `close the day`, `today log`,
`what changed today`, `full day report`.

The agent must then:

1. Read every file in `live/YYYY-MM-DD/`.
2. Run real Git commands (`status`, `log`, `diff`, `diff --cached`, `show --stat`).
3. Reconcile every Git-reported file against the live entries.
4. Write `daily/YYYY-MM-DD.md` using `_templates/evening-summary.md`.
5. Update `modules/<Module>.md` rollups.
6. Add the day to `00-INDEX.md`.

The summary is invalid if it omits even one file Git reports as changed today.

## Result Codes

| Code | Meaning |
|---|---|
| `PASS` | Every Git change matched to a documented reason. |
| `PARTIAL` | Some files or commits are unverified/undocumented. |
| `FAIL` | Missing log, missing Git evidence, or fabricated data. |

## Notes

- The brain lives **outside** the `prime_ai` Git repository, so it is not versioned with the project.
  Optionally run `git init` inside this folder to version it separately.
- File paths inside entries must stay **project-relative** (e.g. `Modules/Fee/Http/Controllers/X.php`).
- `GEMINI.md` and `AGENTS.md` are gitignored in the project; both are local working-copy instructions.
- Live journals are evidence and must never be deleted.
- Backfilled days must be marked `backfilled`.
- Reference central AI Brain: `/home/shailesh/shailesh/ai-brain-daily/`.

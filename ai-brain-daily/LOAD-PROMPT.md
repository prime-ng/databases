# Copy-Paste Prompt — Load the AI Brain in Any Model

Paste this as the **first message** of a new chat in Claude, Gemini, opencode, Cursor, Codex,
Antigravity, or any other AI tool:

---

Before doing anything, load the shared AI Brain at
`/home/shailesh/shailesh/ai-brain-daily/`.

Read, in this order:

1. `README.md`
2. `00-INDEX.md`
3. The latest 3 files in `daily/`
4. Every file in `live/<today's Asia/Kolkata date>/`
5. `modules/00-INDEX.md` and the rollup for the module I am about to mention

Then reply only with:
`AI Brain loaded: <date>, <n> live entries, last report <date>.`

After loading, follow the **"Strict Mandatory Daily Work Ledger & Evening Closeout Rule"**
in `/home/shailesh/shailesh/prime_ai/GEMINI.md`:

- After every task, append your entry to `live/<date>/<agent>.md` (which file, what changed, why, proof).
- Never rewrite earlier entries.
- On "evening summary", "day summary", or "close the day", generate `daily/<date>.md`
  from real Git output and reconcile every changed file.

---

## Faster Option (Terminal)

Print the current brain snapshot before starting:

```bash
/home/shailesh/shailesh/ai-brain-daily/load.sh
```

## Fully Automatic Option

The project rule files already instruct agents to load the brain at session start:

- `/home/shailesh/shailesh/prime_ai/AGENTS.md` (opencode, Cursor, Codex, generic)
- `/home/shailesh/shailesh/prime_ai/GEMINI.md` (Gemini / Antigravity)

If a model does not read those files automatically, paste the prompt above.

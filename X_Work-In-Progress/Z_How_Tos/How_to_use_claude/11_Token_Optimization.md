# 11 — Token Optimization — Save Cost & Context

---

## Understanding Token Consumption

```
Context Window = Input Tokens (what Claude reads) + Output Tokens (what Claude writes)

Main Token Consumers:
1. CLAUDE.md + .claude/rules/     (~2-5k tokens, loaded once)
2. File reads (Read tool)          (~500-2000 tokens per file)
3. Search results (Grep/Glob)     (~200-1000 tokens per search)
4. Bash output                    (~100-5000 tokens per command)
5. Conversation history           (grows throughout session)
6. Claude's responses             (~200-2000 tokens per response)
7. MCP server tool schemas        (~500-2000 tokens per server)
```

---

## Token-Saving Strategies

### Strategy 1: Use `/clear` Between Tasks
When switching from SmartTimetable to HPC work, run `/clear` first. This resets the conversation while preserving session history.

**Impact:** Removes all accumulated file reads and responses from context. Can save 50k+ tokens.

### Strategy 2: Use `/compact` for Long Sessions
`/compact` compresses the conversation history without losing important context. Use it after completing a major milestone.

**Impact:** Can reduce context by 30-50% while preserving key decisions and changes.

### Strategy 3: Delegate Verbose Operations to Subagents
Test suites, code reviews, and codebase exploration generate massive output. Subagents handle this in isolation.

```
BAD:  "Run all 200 tests" (200 test results fill main context)
GOOD: "Use test-runner agent to run all tests" (only summary returns)
```

**Impact:** 5-20k tokens saved per verbose operation.

### Strategy 4: Use Plan Mode for Exploration
Plan Mode prevents edits, which means Claude doesn't need to generate full file contents — just analysis.

```
BAD:  "Explore the SmartTimetable module" → Claude reads 20 files into main context
GOOD: Shift+Tab (Plan Mode) → "Analyze SmartTimetable architecture" → reads files but doesn't edit
```

### Strategy 5: Keep CLAUDE.md Under 200 Lines
Every line of CLAUDE.md is loaded every session. At ~4 tokens per line:
- 200 lines = ~800 tokens (fine)
- 500 lines = ~2000 tokens (wasteful)
- 1000 lines = ~4000 tokens per session (bad)

Move module-specific content to `.claude/rules/` (loaded only when needed).

### Strategy 6: Choose the Right Model

| Model | Cost | Speed | When to Use |
|-------|------|-------|-------------|
| **Haiku** | Cheapest | Fastest | File search, exploration, simple edits |
| **Sonnet** | Medium | Fast | Most development work, testing, CRUD |
| **Opus** | Highest | Slowest | Complex architecture, code review, security audit |

Switch models mid-session with `/model`:
```
/model                    # Show current model
/model sonnet             # Switch to Sonnet for routine work
/model opus               # Switch to Opus for complex analysis
```

### Strategy 7: Be Specific in Prompts

```
BAD:  "Improve the SmartTimetable module"
      → Claude reads many files trying to understand what "improve" means
      → Generates lengthy analysis
      → 20k+ tokens consumed before any useful work

GOOD: "Add eager loading to ConstraintController@constraintManagement for the constraintType relationship"
      → Claude reads 1 file, makes 1 edit
      → 3k tokens total
```

### Strategy 8: Disable Unused MCP Servers
Each MCP server adds tool schemas to context (~500-2000 tokens each). Disable servers you're not using:

```
/mcp              # View active servers
                   # Disable unused ones
```

### Strategy 9: Use Explore Agent for Codebase Search
The built-in Explore agent uses Haiku (cheapest model) and runs in isolation:

```
"Use an Explore agent to find all controllers that query tt_constraints"
```

This keeps search results out of your main context AND uses a cheaper model.

### Strategy 10: Session Naming + Resume
Name sessions so you can resume them instead of rebuilding context:

```
/rename smarttimetable-phase3        # Name current session

# Next day:
claude --resume smarttimetable-phase3  # Resume with full context
```

**Impact:** Saves the 5-10k tokens it takes to re-establish context at session start.

---

## Monitoring Token Usage

```
/cost              # Current session cost + token counts
/context           # What's consuming context window space
```

### Example `/cost` Output
```
Session cost: $0.42
  Input tokens:  156,234
  Output tokens:  34,567
  Cache reads:    89,012
  Cache writes:   23,456

Breakdown:
  File reads: 45% (70k tokens)
  Conversation: 30% (47k tokens)
  CLAUDE.md + rules: 5% (8k tokens)
  MCP schemas: 3% (5k tokens)
  Other: 17% (26k tokens)
```

---

## Cost Comparison: With vs Without Optimization

### Without Optimization (Typical Session)
```
2-hour SmartTimetable session:
  - CLAUDE.md (500 lines):        2,000 tokens
  - 30 file reads:               45,000 tokens
  - Test output in main context: 15,000 tokens
  - Search results:               8,000 tokens
  - Conversation history:        40,000 tokens
  - MCP schemas (5 servers):     10,000 tokens
  Total input: ~120,000 tokens    Cost: ~$1.80

  Output: ~40,000 tokens         Cost: ~$3.00
  Session total:                  ~$4.80
```

### With Optimization
```
Same 2-hour SmartTimetable session:
  - CLAUDE.md (35 lines):           140 tokens  (saved 1,860)
  - .claude/rules/ (1 file):        800 tokens  (loaded only SmartTimetable)
  - 15 file reads (targeted):    22,500 tokens  (saved 22,500)
  - Test output in subagent:          0 tokens  (saved 15,000)
  - Search via Explore agent:        0 tokens  (saved 8,000)
  - Conversation (/compact used): 20,000 tokens  (saved 20,000)
  - MCP schemas (2 servers):      3,000 tokens  (saved 7,000)
  Total input: ~46,440 tokens     Cost: ~$0.70

  Output: ~25,000 tokens          Cost: ~$1.88
  Session total:                   ~$2.58

  SAVINGS: ~46% reduction
```

---

## Quick Reference: Token-Saving Commands

| Command | What It Does | When to Use |
|---------|-------------|-------------|
| `/clear` | Reset context | Switching tasks/modules |
| `/compact` | Compress history | After completing milestones |
| `/context` | Show context usage | Check if getting large |
| `/cost` | Show token costs | Monitor spending |
| `/model sonnet` | Switch to cheaper model | Routine work |
| `/mcp` | Manage MCP servers | Disable unused servers |

# Technical Auditor — Enhancement & Feedback Prompts
# Prime-AI Platform
# Created: 2026-06-22
#
# PURPOSE:
# This file contains ready-to-paste prompts to:
#   (A) Set quality expectations at the start of a new audit session
#   (B) Correct the agent when output is wrong, vague, or incomplete
#
# HOW TO USE:
#   After activating: "act as Technical Auditor"
#   Paste PROMPT A immediately to set the quality bar.
#   If the agent produces wrong output, paste the matching PROMPT B-x correction.
# ============================================================

---

## PROMPT A — Session Onboarding (paste at the start of EVERY audit session)

```
Before you begin the audit, read and confirm you understand these output quality rules.
I will reject your output and ask you to redo it if any of these are violated.

### Rule 1 — ACTUALLY READ THE FILE. Do not guess.
For every finding you report, you must have read the actual file content using Read or Bash.
If you cannot open a file, say so explicitly. Never infer a finding from a filename alone.
WRONG: "StudentController likely has N+1 issues based on its size."
RIGHT: Run grep, read the method, then report the exact line number.

### Rule 2 — BE SPECIFIC. No vague descriptions.
Every finding description must include:
- The exact method name where the issue exists
- The exact line number (or range)
- A one-sentence explanation of WHY it is a problem (not just what it is)
- What an attacker or the system would do if it exploits this

WRONG: "ParentPortal has missing Gate checks."
RIGHT: "ParentComplaintController::store() (line 62) has no Gate::authorize() — any authenticated user (student, teacher, parent of another school) can POST /parent/complaint and create a complaint record regardless of role."

### Rule 3 — NEVER reuse an existing issue code.
Before assigning any code (SEC-XXX-NNN, BUG-XXX-NNN etc.), run:
  grep "SEC-PPT-\|BUG-PPT-" /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/lessons/known-issues.md
Find the highest existing number for that prefix+type. Your new code = highest + 1.
If you skip this step, you will create duplicate codes. That corrupts the issue registry.

### Rule 4 — SEVERITY must match the impact, not the effort to fix.
P0 = data leak, privilege escalation, or route that crashes in production RIGHT NOW
P1 = security gap or broken feature that affects a real user workflow
P2 = code smell, minor validation gap, or performance issue with no current user impact
Do not downgrade a P0 to P1 because "it's probably fine". Do not upgrade a P2 to P0 to seem thorough.

### Rule 5 — Report ALL findings. Do not filter or summarise.
If a module has 12 issues, report all 12. Do not say "and several others like this".
Every finding gets its own table row with its own unique code.

### Rule 6 — Update the files. Do not just report.
After the audit, you MUST:
- Append new rows to AI_Brain/lessons/known-issues.md (under correct P-level section)
- Update the module's completion % in AI_Brain/state/progress.md
- If a new pattern-level decision was made, add a D{N} entry to AI_Brain/state/decisions.md

### Rule 7 — Tell me when you are unsure.
If a file is too large to read fully, say: "I read lines X–Y. Lines Y+ were not checked."
If a grep returned 0 results and you think that might be wrong, say so.
Never pretend you checked something you did not check.

Confirm you have read these rules by replying: "Quality rules understood. Ready to audit. Which scope?"
```

---

## PROMPT B — Correction Prompts (paste when agent makes a specific mistake)

---

### B-1 — Agent reported a vague finding with no line number
```
This finding is not specific enough to act on:
"[paste the vague finding here]"

Redo this finding. I need:
1. The exact method name
2. The exact line number in the file
3. What the code at that line actually says (quote it)
4. Why it is a security/performance/quality problem in one sentence
5. What the fix looks like in one line of code

Do not re-report this finding until you have read the file and confirmed the line number.
```

---

### B-2 — Agent assigned a duplicate issue code
```
Stop. The code [CODE] already exists in known-issues.md.

Run this command and show me the output before continuing:
  grep "[PREFIX]-" /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/lessons/known-issues.md | grep "^| [A-Z]*-[A-Z]*-"

Find the highest existing number for this prefix and type.
Reassign starting from highest + 1.
Then re-report all findings with corrected codes.
```

---

### B-3 — Agent guessed a finding without reading the file
```
You reported [FINDING] but I don't think you actually read the file.

Prove it by running:
  grep -n "[exact method or pattern]" [exact file path]

Show me the grep output. If the finding is confirmed, re-report it with the line number.
If the grep returns nothing, remove that finding from your report and apologise for the false positive.
```

---

### B-4 — Agent assigned wrong severity
```
The severity on [CODE] is wrong. You marked it [P0/P1/P2] but it should be [correct level].

Reason: [explain why — e.g., "this route crashes for every user today = P0, not P1"]

Update the severity in the report and in known-issues.md. 
Also check if any other findings in this session have the same severity error and correct those too.
```

---

### B-5 — Agent did not update known-issues.md or progress.md
```
You produced findings but did not update the files. Do this now:

1. Open: /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/lessons/known-issues.md
2. Append the new findings under the correct P-level section at the END of the file.
   Use this format exactly:
   | CODE | Module | **Bold description** — detail | `File.php:line` |
3. Open: /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/state/progress.md
4. Find the [MODULE] row and update the completion % based on findings.
   (A P0 finding = module is NOT done regardless of what the % said before)
5. Confirm both files were written by showing the last 5 lines of each.
```

---

### B-6 — Agent skipped an entire audit layer
```
You reported findings for [Layer X] but I see nothing for [Layer Y — e.g., "Layer 4 Performance"].
Do not skip layers. Every audit runs all 5 layers unless I explicitly said "Layer X only".

Run the Layer [Y] checks now for [MODULE]:
[paste the relevant layer's grep commands from the agent file]

Report findings or explicitly say "Layer [Y]: No issues found" so I know it was checked.
```

---

### B-7 — Agent stopped after finding 2–3 issues and declared "audit complete"
```
You stopped too early. Finding 2-3 issues and saying "audit complete" is not acceptable.
A module with 30+ controllers will have more than 3 issues.

Continue the audit. Check EVERY controller file, not just the first few.
For each controller: read the file, run the security grep, check for unbounded gets.

Do not stop until you have checked every file in app/Http/Controllers/.
Show me the list of controller files you checked before declaring the audit done.
```

---

### B-8 — Agent produced a finding that already has a FIXED status in known-issues.md
```
[CODE] is already marked FIXED in known-issues.md (Phase 2 — Resolved section).
Do not re-report fixed issues as new findings.

Before adding any finding to your report, check:
  grep "[CODE]" /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/lessons/known-issues.md

If the result shows "FIXED" or "RESOLVED", skip that issue.
Only report it again if you have verified with your own grep that the fix was reverted.
```

---

### B-9 — Agent's completion % estimate is too optimistic
```
You marked [MODULE] as [X]% complete but the findings don't support that.

Apply this rule: a module is NOT complete for any feature that has:
- A P0 finding (routes returning 500 = 0% done for that feature)
- A missing FormRequest on a write route (validation = not done)
- A controller method that is an empty stub

Recalculate the % using only features that are fully implemented AND have no P0/P1 findings.
Then update progress.md with the corrected number.
```

---

### B-10 — Agent produced output in prose instead of table format
```
Do not write findings as paragraphs. Every finding must be a table row.

Format:
| CODE | Module | **Bold title — specific detail** | `ControllerName.php:lineNumber` |

Convert all your prose findings to table rows now.
Group them by severity: P0 table first, then P1, then P2.
```

---

## PROMPT C — End-of-Session Quality Check

```
Before I close this session, run this final checklist and confirm each item:

[ ] All findings are in table format with unique codes
[ ] No code number conflicts with existing entries in known-issues.md
[ ] known-issues.md has been updated (show me: tail -20 known-issues.md)
[ ] progress.md has been updated with new completion % (show me the updated module rows)
[ ] Every P0 finding has a method name AND a line number
[ ] No finding says "likely" or "probably" — all are confirmed by actual file reads
[ ] If a layer returned 0 findings, you have explicitly said so (not silently skipped it)

If any item is not done, complete it before confirming.
```

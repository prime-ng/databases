I want to create Agents & other AI related inforamation for OpenCode as I have created previously for Claude in Folder "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain". Create Structure for that in the folder "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/OpenCode_Brain". This will work as a foundational information for Opencode. Read all the files from Claude AI_Brain (/old_db/AI_Brain) and generate appropritly usefull files for Opencode in Folder (old_db/OpenCode_Brain)

----------------------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
Priviously with Claude, I have created a system which automatically capture the detail of all my prompt and their reponce while working with claude and create a detail for every prompt into folder "/local_workspace/9-Prompt_Register/Prompts". The detail it capture was include What Prompt I have used, When I Used that (Date & Time), What all actions claude has performed and what was the output of that Prompt and where it saved. It also create a Prompt_Register as Summary for easy search. You can read all the files from the folder "/WorkFolder/3-Local_Workspace/9-Prompt_Register" to understand the complete detail of it. Now I want you to create a similer machanizm for opencode into the folder "/WorkFolder/3-Local_Workspace/9-OpenCode_Prompt_Register". The system should not required any action from myside but it should always capture the detail for every prompt I use with Opnecode. You can read but DO NOT Modify, Delet or Add anything in folder "/WorkFolder/3-Local_Workspace/9-Prompt_Register". Once you are done with creating such system, do let me know.
## Responce :
Done. The OpenCode Prompt Register is live at:
/Users/bkwork/WorkFolder/3-Local_Workspace/9-OpenCode_Prompt_Register
What was created
Path	Purpose
PROMPT_INDEX.md	Searchable summary — one row per prompt with ID, time, project, prompt, output, result
Prompts/P-YYYYMMDD-NN.md	Full detail for each prompt
build_register.py	Reads OpenCode's session database (read-only) and regenerates the register
.id_map.json	Keeps prompt IDs stable across rebuilds
README.md	Usage, limitations, and how the automation works
logs/plugin.log	Automatic-refresh audit log
Z-OpenCode_Prompt_Register_Creation_Prompt&Response.md	Record of this build
Automatic capture — no action from you
A global plugin is installed at:
~/.config/opencode/plugins/prompt-register.ts
It:
- imports all existing history when OpenCode starts,
- refreshes after every turn (session.idle / session.execution.*),
- runs a 10-minute safety refresh as a fallback,
- spawns the builder in the background with a file lock, and
- never modifies the prompt, model, or tools.
Because the source of truth is OpenCode's own database, even a missed refresh is recovered on the next run — nothing is lost.
What each prompt file records
- Prompt text verbatim
- Date & time in IST
- Project, directory, session, agent, model
- Files created, edited, read
- Shell commands run (multi-line scripts preserved)
- Files written by shell redirection/tee
- Web fetches/searches, skills, sub-agents, questions, todos
- Final reply reported back
- Cost, tokens, and turn outcome
Verified
- Imported 14 prompts · 6 sessions · 3 active days (including this prompt).
- End-to-end test: a separate session triggered session.execution.succeeded, the plugin refreshed automatically, and the register updated.
- IDs remain stable across rebuilds.
- The Claude folder 9-Prompt_Register was only read — not modified, deleted, or added to.
This very prompt is already captured as P-20261027-01; its final response will be filled in when this turn ends.
To cite an old prompt, just say e.g. “see P-20261016-09”. To resume the actual conversation instead, use opencode --session <session-id> — the ID is printed in every prompt file.
Manual refresh, if ever needed:
python3 /Users/bkwork/WorkFolder/3-Local_Workspace/9-OpenCode_Prompt_Register/build_register.py
Build · DeepSeek V4.1 Flash · 8m 30s · 95.8 tok/s

----------------------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
One of my Team Member has created an Agent to generate "Detailed Code Audit". Raed To understand what he has created, you need to read al the files from below folders :
- /prime_testing/final-audit-reports/_Info
- /prime_testing/final-audit-reports/_templates
- /prime_testing/final-audit-reports/_tools

You Goals :
- First update all the path written in all the files in the older "/prime_testing/final-audit-reports", which should point to the folders in my system.
- To understand the expected output, you can read files from any module folder under folder "/prime_testing/final-audit-reports/tarun" e.g. "final-audit-reports/tarun/BehaviouralAssessment-done"
- After having complete understanding, create an Agent "Code Auditor" into folder "/old_db/OpenCode_Brain/agents"
- Create an Agent which expect 2 Parameter from me 1-Module_Name (Which Module I want it to create Report for) 2-Developer_Name (This will decide where output files will go, I have folders with the name of all Developers e.g "/prime_testing/final-audit-reports/gaurav", "final-audit-reports/shailesh", "final-audit-reports/tarun")
- Agent will also be capable of creating Status Report for all the Controllers for a Module. So that Developer can check / Re-Check the current status of all the code fixing suggest by you in the file "02-fix-plan.md" for all the controllars.
All the Path related information for my system has already collected by you in the file "/old_db/OpenCode_Brain/config/paths.md"

Do NOT Assume anything, ask questions, if you need any information.

## Responce :
Completed. Here is what changed.
1. Path repair — final-audit-reports
- Corrected the application root from the empty /Users/bkwork/Herd/prime_ai to /Users/bkwork/Herd/prime_ai_dev everywhere.
- Mapped teammate machine paths (/home/tarun-chauhan/..., C:\laragon\..., C:\Users\GAURAV~1\...) to your local folders.
- Handled the _Info/ move: all 1,055 owner links in 00-CLASS-OWNERS.md now resolve relative to _Info/.
- Repaired local Markdown links mechanically, including -done folder renames and cross-developer links.
- Updated the protocol, both existing Final Audit agent twins, selfcheck.py, scan.php and scanfilter.py to the new location model: reports in prime_testing/, application in ../prime_ai_dev/.
- Updated OpenCode_Brain/config/paths.md with the correct LARAVEL_REPO and new AUDIT_* variables.
Verification: 2,923 of 3,044 local links resolve. The remaining 121 are not path typos: 54 gaurav/Accounting controller reports have never been written, plus 2 intentional template placeholders. I did not invent those missing reports.
Backup created at:
/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/9-Working_tmp/Temp_Output_Files/final-audit-reports-backup-20261027-104844.tar.gz
2. Code Auditor agent
Created the full guide in the folder you named:
OpenCode_Brain/agents/code-auditor.md
And OpenCode drivers in:
- OpenCode_Brain/.opencode/agents/code-auditor.md
- prime_testing/.opencode/agents/code-auditor.md — so it can also run from the audit workspace
It accepts exactly two parameters plus an optional mode keyword:
Code Auditor, Audit,  BehaviouralAssessment, tarun
Code Auditor, Status, BehaviouralAssessment, tarun
- Audit — audits every controller in the module, writes 01-report.md + 02-fix-plan.md per controller, plus 00-INDEX.md and 00-SUMMARY.md.
- Status — read-only re-check of every item in every 02-fix-plan.md; writes a module-wide 00-STATUS.md (dated copy if one already exists). It never edits the app, plans, 03-status.md or the index.
- No keyword — asks whether to Audit or check Status.
Added _templates/04-module-status.md for the module-wide status shape.
3. Validation
- Agent loads and responds correctly from both OpenCode_Brain and prime_testing.
- Verified it can read from prime_ai_dev and write inside final-audit-reports (test file removed afterwards).
- selfcheck.py on an audited controller: SELF-CHECK PASS.
- Scanner runs: 4,516 files / 32,585 findings.
- route:list: 8,124 routes.
- No application code was changed.
All test sessions were removed from OpenCode and the Prompt Register.
Build · DeepSeek V4.1 Flash · 29m 57s · 90.4 tok/s

----------------------------------------------------------------------------------------------------------------------------------------------------
## Prompt: Provide me the Coammnd I need to use to Run the "Code Auditor" Agent to create report & fix_plan files for a particuler Module?

## Responce :
$ ls /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/OpenCode_Brain/.opencode/commands; 
echo "=== agent command ==="; cat /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/OpenCode_Brain/.opencode/commands/agent.md 2>/dev/null | head -60
agent.md
frontend.md
lint.md
module-status.md
review.md
schema.md
test.md

=== agent command ===
---
description: Switch the session's active role to a named OpenCode_Brain agent
---

# /agent — Switch Active Role

Switch to a named role from `OpenCode_Brain/agents/`.

## Usage

- `/agent technical-auditor` — Switch to Technical Auditor
- `/agent business-analyst` — Switch to Business Analyst
- `/agent testing-architect` — Switch to Testing Architect
- `/agent status-analyzer` — Switch to Status_Analyzer
- `/agent db-architect` — Switch to Database Architect
- `/agent enterprise-architect` — Switch to Enterprise Architect
- `/agent backend-developer` — Switch to Backend Developer
- `/agent frontend-developer` — Switch to Frontend Developer
- `/agent api-builder` — Switch to API Builder
- `/agent developer` — Switch to General Developer
- `/agent debugger` — Switch to Debugger
- `/agent tenancy-agent` — Switch to Tenancy Agent
- `/agent module-agent` — Switch to Module Agent
- `/agent school-agent` — Switch to School Domain Agent
- `/agent test-agent` — Switch to Test Agent
- `/agent devops-deployer` — Switch to DevOps Deployer
- `/agent` — List all available agents

## Steps

1. If no argument (`$ARGUMENTS` empty), list every `.md` in `OpenCode_Brain/agents/` with a one-line description.
2. Otherwise read `OpenCode_Brain/agents/$ARGUMENTS.md`.
3. Adopt the role described in that file — follow its prerequisites/reading order first, and resolve paths via `OpenCode_Brain/config/paths.md`.
4. Confirm with: `Active role: {Agent Name}. Ready. What would you like me to do?`

## Notes

- Agent names are lowercase with hyphens matching the filename (e.g. `enterprise-architect` → `agents/enterprise-architect.md`).
- You can switch roles mid-session by running `/agent` again.
- If the file doesn't exist, list available agents and ask the user to pick one.
- For an **isolated parallel run** instead of an in-session role switch, ask the primary agent to
  launch the `<name>` **subagent** (e.g. "use the technical-auditor subagent on X and Y in parallel").
  cd /Users/bkwork/Herd/prime_testing && timeout 10 opencode api get /api/agent 2>/dev/null | python3 -c "…
err Expecting value: line 1 column 1 (char 0)

Use this command from the audit workspace:
```
cd /Users/bkwork/Herd/prime_testing && opencode run --standalone \
  --agent code-auditor \
  --model opencode-go/deepseek-v4.1-flash \
  "Code Auditor, Audit, <Module_Name>, <Developer_Name>"
Example — audit the BehaviouralAssessment module for Tarun

opencode run --standalone \
  --agent code-auditor \
  --model opencode-go/deepseek-v4.1-flash \
  "Code Auditor, Audit, <Module_Name>, <Developer_Name>"
```

----------------------------------------------------------------------------------------------------------------------------------------------------
## Prompt:

audit the SyllabusBooks module for gaurav. Do not assume anything, ask questions if you need any info.



----------------------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
My Team Members have creating similer Audit Report which I have created using code_auditor Agent in folder (final-audit-reports/gaurav, final-audit-reports/shailesh & final-audit-reports/tarun). I noticed 1 issue in all the reports created in these folders. These reports are having some reference path hard coded into the files. Now the problem is, if file is created by one person and solution implementation (code fixing) is being done by someone else then AI is getting different path (As everyone has different folder structure in their system) and need to correct it. Now again that code is getting upload on Git, which will be downloaded by someone else and same problem will be faced by other team members. So ultimatly all the team members are wasting their AI tokans to correcting path everytime they are taking pull from Git.

To Solve this issue permanently I want to create a new folder "_config" in the folder "prime_testing/final-audit-reports/" and create a file "audit_path.md", which will posses all the path being used in all the files stored into these 3 folders (final-audit-reports/gaurav, final-audit-reports/shailesh & final-audit-reports/tarun). We will add "_config" into .gitignore, so that it will not upload/download on git and every team member need to update their own path in "audit_path.md" only once and after that there will not be any need of any additional path update even after download from git.

I want you to perform below action to achive this:
1. Move all 4 Files (00-CLASS-OWNERS.md, FINAL-AUDIT-PROTOCOL.md, PATH-REPAIR-2026-10-27.md & README.md) into folder "prime_testing/final-audit-reports/_Info/"
2. Create a folder "_config" in the folder "prime_testing/final-audit-reports/"
3. Create a file "audit_path.md" into folder "prime_testing/final-audit-reports/_config/"
4. Create Variable for all 4 files mentioned in the Task - 1 and replace all the hard-coded reference for these 4 files with newly created variables.
5. Find all the hard coded path in all the files under folders (final-audit-reports/gaurav, final-audit-reports/shailesh & final-audit-reports/tarun)
6. Create required variables for those path into file "audit_path.md"
7. update all the files in folders (/gaurav, /shailesh & /tarun) with newly created variables in file "audit_path.md"

**DO NOT CHANGE** anything other hard coded paths in files under folders (final-audit-reports/gaurav, final-audit-reports/shailesh & final-audit-reports/tarun)
Create a Summary of all the changes you have made during this process and saved it as "prime_testing/final-audit-reports/_Info/Variables_update_log.md"


----------------------------------------------------------------------------------------------------------------------------------------------------
## Prompt:

## Importtant Queries in Transport Modulle :
1. When performing Invoicing for Student
   - If System find more then 2 Price for a single Month for a Student then how it will decide which one needs to be used for Invoicing?
2. Invoicing for other Transport facilities (e.g. Transport for Sports Academy, Transport for Extra Class etc.)
   - Student needs to be registered for those Activities
   - Provision for Rate Master for that Activity on distance basis
   - Saperate Billing for the Spacial Transport Facility
3. In 01-Consolidated_Requirement_Document.md, Section - #### FND-027 — Billing run and invoice :
   - In Acceptance : 3. Mid-month plan change with daily prorata; invoice reflects days.
		It should be configurable, School can choose to charge same old Price for change month and New Charges will be applicable from Next Month onward. To capture this Info we can add a field `new_fare_effective_from` into table `tpt_student_stop_change_request`.
4. In Accounting There should be a Screen where Accountant can see all the due on a Student :
   - When Accountant will enter Today's Date to pay the charges, system will fetch all the due on the student and also calculate late charges (if applicable) and will provide final amount to be paid.
	- System will also show the detail of other child of same Parent (if any) will all due + Charges.
	
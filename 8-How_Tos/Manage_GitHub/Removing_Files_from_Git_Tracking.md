# How to Remove Files / Folders to be tracked by Git
====================================================


## Removing a Folder from Git Tracking
--------------------------------------

### Remove a file (.claude & .opencode) from Git Cach:
git rm -r --cached -f -- .claude .opencode

### To Check the status in gitignore:
git ls-files .claude .opencode
Expected result: no output.

### Now confirm the local files still exist:
ls -la .claude
ls -la .opencode

### Verify the ignore rules in .gitignore:
/.claude/
/.opencode/

### Then run (Optional):
git check-ignore -v --no-index .claude/agents/final-audit-auditor.md
git check-ignore -v --no-index .opencode/agents/final-audit-fixer.md

(Above Both commands should show the matching ignore rules.)

### Commit the changes:
git status
git add .gitignore
git diff --cached --stat
(Review the staged changes. If they contain only the intended removal of these AI folders from Git tracking and your .gitignore update)

### Final commit:
git commit -m "Stop tracking local AI configuration folders (claude & Opencode)"

Then refresh GitHub Desktop.



## Removing a File from Git Tracking
------------------------------------

### Remove a file (.gitignore) from Git Cach:
git rm -r --cached -f -- .gitignore

### To Check the status in gitignore:
git ls-files .gitignore
Expected result: no output.

### Commit the changes:
git status
git add .gitignore
git diff --cached --stat
git commit -m "Stop tracking .gitignore file"

Then refresh GitHub Desktop.
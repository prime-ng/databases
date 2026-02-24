# Branch Governance Policy
--------------------------

## 1. Branch Structure (Simple & Safe)
```code
main        → Production only
develop     → Stable integration branch
feature/*   → Developer feature branches
hotfix/*    → Urgent production fixes
```

Rules:
  ❌ No direct commits to main
  ❌ No direct commits to develop
  ✅ Only Pull Requests allowed
  ✅ Minimum 1 reviewer mandatory
  ✅ CI must pass before merge

## 2. Strict Pull Request Rules

Every PR must:
  - Mention JIRA / task ID
  - Clearly describe DB changes
  - Mention if migration is added/modified
  - Include rollback strategy
  - Pass CI checks

## 3. Force Push Policy

🚨 This is critical.
	❌ No force push on shared branches
	❌ No rebase on develop
	❌ No history rewrite after merge
	✅ Force push allowed only on personal feature branches

You can enforce this in GitHub branch protection settings.








## 4. Branch Protection Rules

main:
	- No direct commits
	- PR required
	- 2 approvals minimum
	- CI must pass
	- No force push

Develop:
	- PR required
	- 1 approval minimum
	- CI must pass
	- No force push

Feature Branches:
	- No protection (developer autonomy)
	- Must merge to develop via PR
# Laravel Migration Safety Protocol
-----------------------------------

🔴 RULE 1 — Migration Files Are Immutable
Once committed:
	❌ Never rename
	❌ Never modify
	❌ Never delete
	❌ Never convert to .bk
	❌ Never move to backup folder

If change required:


## 1. Migration Immutability Rule

Once a migration file is merged into develop:

❌ It must never be modified
❌ It must never be renamed
❌ It must never be deleted
❌ It must never be moved
❌ It must never be converted to .bk

If schema change is required:
```bash
php artisan make:migration alter_<table>_<change_description>
```
Always create a new migration.

## 2. Revert & Reset Safety Rule

Before running:
```Bash
git revert <commit>
```

Developer must:
	- Inspect impacted files:
			```Bash
			git show <commit>
			```
	- Confirm no migration file will be removed.
	- Mention DB impact in PR.

## 3. Backup Prohibition Rule

Restoring files from:
	- Local backup
	- Personal folder
	- Zip archive
	- External storage

❌ STRICTLY PROHIBITED

If a file is missing:

	```Bash
	git log --all --follow -- <file>
	git checkout <commit_hash> -- <file>
	```

## 4. Branch Discipline

Protected branches:
	- main
	- develop

Rules:
	- PR required
	- 1 approval minimum
	- CI must pass
	- No force push
	- No direct commits

## 5. Migration Review Checklist (Mandatory in PR)

If PR includes migration:

	✔ Purpose of schema change documented
	✔ Rollback tested
	✔ Production impact analyzed
	✔ Multi-tenant impact reviewed
	✔ No modification of old migration

## 6. Violation Consequences

First violation → warning
Second → merge restriction
Third → code access review
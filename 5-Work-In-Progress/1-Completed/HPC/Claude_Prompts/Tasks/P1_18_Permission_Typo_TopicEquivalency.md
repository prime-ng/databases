# PROMPT: Fix Permission Typo in TopicEquivalency — HPC Module
**Task ID:** P1_18
**Issue IDs:** BUG-HPC-015
**Priority:** P1-High
**Estimated Effort:** 10 minutes
**Prerequisites:** None

---

## CONFIGURATION
```
MODULE_PATH    = /Users/bkwork/Herd/prime_ai/Modules/Hpc
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
```

---

## CONTEXT

A permission string `tenant.topic-equivalency-snapsho.viewAny` is truncated — missing the final "t" in "snapshot". This causes Gate to always deny access. The correct string should be `tenant.topic-equivalency-snapshot.viewAny`.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Http/Controllers/TopicEquivalencyController.php`
2. `{MODULE_PATH}/app/Http/Controllers/SyllabusCoverageSnapshotController.php`
3. Search all HPC files for `snapsho` to find all occurrences: `grep -r "snapsho[^t]" {MODULE_PATH}/`
4. Also check `{LARAVEL_REPO}/app/Providers/AppServiceProvider.php` for the permission registration

---

## STEPS

1. Search for `snapsho` (without trailing `t`) across the entire HPC module and AppServiceProvider
2. Replace all instances of `topic-equivalency-snapsho.` with `topic-equivalency-snapshot.`
3. Verify the permission is also correctly registered in AppServiceProvider's policy mapping

---

## ACCEPTANCE CRITERIA

- No truncated `snapsho` permission strings remain
- All TopicEquivalency Gate checks use correct `snapshot` spelling
- Permission checks pass for authorized users

---

## DO NOT

- Do NOT rename routes or controllers
- Do NOT change other permission strings

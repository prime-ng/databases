---
name: lint
description: Quick PHP syntax check and code style validation
user_invocable: true
---

# /lint — PHP Syntax & Style Check

Quick syntax check and PSR-12 validation.

## Usage
- `/lint` — Check all changed files (git diff)
- `/lint path/to/file.php` — Check specific file
- `/lint Modules/ModuleName/` — Check all files in a module

## Steps

1. Determine files to check:
   - No argument: get changed files from `git diff --name-only --diff-filter=ACMR HEAD`
   - Specific path: check that file/directory

2. Run PHP syntax check:
   ```bash
   php -l {file}
   ```

3. Run Laravel Pint (if available):
   ```bash
   ./vendor/bin/pint --test {file}
   ```

4. Report:
   - Syntax errors (fatal — must fix)
   - Style violations (should fix)
   - Clean files (no issues)

5. Offer to auto-fix style issues with `./vendor/bin/pint {file}`

# Module: Prime Testing (prime_testing harness)

Append-only rollup. Newest entries at the bottom.
Repository: `/home/shailesh/shailesh/prime_testing` (branch `testing_v3`).

## 2026-10-20 — Dusk harness startup + machine identity hardening

- **Commits:** `49cb28d9`, `b632cfc8`, `d827ac7b`, `9ee6291d`, `9dd3d007`, `eb12c951`, `f7e8dd6f`, `6d45c496` (8, all by Shailesh, message `fix issue`)
- **Files (14, +496/-157):** `app/Services/MachineInfoService.php`, `database/seeders/TstPlatformIdentitySeeder.php`, `Modules/PlatformConfig/app/Services/MaintenanceService.php`, `bootstrap/app.php`, `tests/Browser/Modules/preload.php`, `tests/DuskTestCase.php`, `config/view.php`, 5 `Modules/*/app/Providers/*ServiceProvider.php`, `resources/views/backend/layouts/master.blade.php`, `resources/views/components/backend/layouts/app.blade.php`
- **What:**
  - Resolve the `prime_ai` project path per machine (env → settings table → machine row → `.env` array-backed → sibling `prime_ai`), validating that `artisan` + `Modules` exist; fail loudly instead of silently falling back.
  - Launch the Dusk dev server via PHP's built-in server with opcache off and 1 worker; add ready-wait, exit-code/signal/output diagnostics, and a screenshot-dir fallback.
  - Detect this PC's workstation user before truncating `tst_machines` (built-in MAC/hostname/OS user/git user+email); refuse the D03 fallback and refuse a cross-PC MAC overwrite.
  - Add real machine model/serial/OS info; scope `bootMachineCheck` to rows matching this hostname or MAC; gate main-project view paths behind `usesMainProject` so local `view:cache` works.
  - Register the `bugtracking` view alias; remove duplicated scroll-to-top markup from two backend layouts.
- **Verification:** `git log --since/--until 2026-10-20` → 8 commits; `git show --numstat` → 14 unique files +496/-157; `git status --short` clean. No Dusk run output recorded.
- **Open:** run the Dusk suite end-to-end and record results; verify `TEST_RUNNER_CURRENT_USER` / `MAIN_PROJECT_PATH` in `prime_testing/.env` on every PC.
- **Status:** Done (unverified by test run)
- **Report:** `ai-brain-daily/daily/2026-10-20.md` (section 3.5)

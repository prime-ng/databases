# Section Dusk Pass/Fail Report

## Execution Target
- Command: `php artisan dusk --filter=SectionCrudTest --stop-on-failure`
- Suite file: `tests/Browser/Modules/Class&Subject Mgmt/Sections/SectionCrudTest.php`
- Proof log: `tests/Browser/Modules/Class&Subject Mgmt/Sections/proof/dusk_run_latest.txt`
- Run date: 2026-03-07

## Summary
- Status: Failed (environment/database connectivity)
- Total cases: 9
- Passed: 0
- Failed: 9
- Skipped: 0

## Failure Root Cause
- All tests failed in `setUp()` before browser actions.
- Error: `SQLSTATE[HY000] [2002] Unknown error while connecting`
- Connection attempted: `mysql://127.0.0.1:3306/prime_db`
- Failing query: `select * from prm_tenant_domains where domain = test.localhost limit 1`

## Case-wise Status
- SEC-001: Fail (DB connection unavailable)
- SEC-002: Fail (DB connection unavailable)
- SEC-003: Fail (DB connection unavailable)
- SEC-004: Fail (DB connection unavailable)
- SEC-005: Fail (DB connection unavailable)
- SEC-006: Fail (DB connection unavailable)
- SEC-007: Fail (DB connection unavailable)
- SEC-008: Fail (DB connection unavailable)
- SEC-009: Fail (DB connection unavailable)

## Failure Evidence
- Proof output: `tests/Browser/Modules/Class&Subject Mgmt/Sections/proof/dusk_run_latest.txt`
- Screenshot output expected path: `tests/Browser/console/screenshots/`
- Screenshot note: No browser failure screenshots were generated because failures happened before browser flow started.

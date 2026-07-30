# Menu Synchronisation — Test Case List

**Feature:** Menu Synchronisation | **REQ-ID:** REQ-SYS-007 | **Controller:** `MenuSyncController`

---

## 1. Test Case Summary

| Total TC | Pass | Fail | Blocked | Not Run | Coverage |
|:--------:|:----:|:----:|:-------:|:-------:|:--------:|
| 18 | — | — | — | 18 | 0% |

---

## 2. Sync Tenant Menus (`GET /system-config/sync-menus`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-SYN-001 | Verify tenant menu sync succeeds as Super Admin | Authenticated as Super Admin with `system-config.menu.sync` permission | — | Menus truncated and re-created; JSON response with `success=true`, `created` count > 0, `menu_module_links` count > 0; 200 OK | — | — | ⬜ |
| TC-SYS-SYN-002 | Verify all tenant menus from definition exist in DB after sync | Definitions contain 18 top-level categories | — | 18 top-level categories exist in `glb_menus` with `menu_for='tenant'`; all children present | — | — | ⬜ |
| TC-SYS-SYN-003 | Verify `glb_menu_module_jnt` pivot table populated after sync | — | — | Pivot has entries mapping menu IDs to module IDs for all tenant menus | — | — | ⬜ |
| TC-SYS-SYN-004 | Verify previous tenant menus are removed after sync | Existing tenant menus before sync | — | Old menus gone; only newly synced menus present | — | — | ⬜ |
| TC-SYS-SYN-005 | Verify non-Super-Admin receives 403 | Authenticated as Platform Manager (without `system-config.menu.sync`) | — | 403 Forbidden; no menus truncated | — | — | ⬜ |
| TC-SYS-SYN-006 | Verify unauthenticated request is rejected | No active session | — | Redirected to login (401) | — | — | ⬜ |
| TC-SYS-SYN-007 | Verify `set_time_limit(300)` is set | — | — | Execution time limit of 300 seconds set (test via runtime inspection) | — | — | ⬜ |
| TC-SYS-SYN-008 | Verify `FOREIGN_KEY_CHECKS` restored to 1 after sync | Sync completes | — | `FOREIGN_KEY_CHECKS=1` after sync | — | — | ⬜ |

---

## 3. Sync Prime Menus (`GET /system-config/sync-prime-menus`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-SYN-009 | Verify prime menu sync succeeds as Super Admin | Authenticated as Super Admin | — | Prime menus truncated and re-created; JSON response with `success=true`; 200 OK | — | — | ⬜ |
| TC-SYS-SYN-010 | Verify all 5 prime categories created | Definitions contain 5 categories | — | 5 categories with `menu_for='prime'` exist in `glb_menus` | — | — | ⬜ |
| TC-SYS-SYN-011 | Verify prime menus do NOT affect tenant menus | Prime sync performed | — | Tenant menus (`menu_for='tenant'`) remain unchanged | — | — | ⬜ |
| TC-SYS-SYN-012 | Verify non-Super-Admin receives 403 on prime sync | Authenticated as Platform Manager | — | 403 Forbidden | — | — | ⬜ |

---

## 4. Refresh Menu Cache (`GET /system-config/refresh-menu-cache`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-SYN-013 | Verify cache refresh clears application cache | — | — | `cache:clear` and `view:clear` Artisan commands executed | — | — | ⬜ |
| TC-SYS-SYN-014 | Verify tenant menu caches cleared after refresh | At least 1 active tenant | — | Each tenant's `allowed_modules` cache and `tenant_main_menus_tree_{id}` cleared | — | — | ⬜ |
| TC-SYS-SYN-015 | Verify global menu cache keys cleared | — | — | `tenant_main_menus_tree` and `prime_main_menus_tree` cache keys absent | — | — | ⬜ |
| TC-SYS-SYN-016 | Verify cache refresh returns success JSON | — | — | JSON with `success=true` and descriptive message | — | — | ⬜ |

---

## 5. Tenant Menu Cache Refresh (`GET /system-config/refresh-menu-cache` — tenant domain)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-SYN-017 | Verify tenant-specific cache cleared from tenant domain | Access from tenant subdomain | — | Current tenant's `allowed_modules`, `menu_cache`, and `tenant_main_menus_tree_{id}` cleared | — | — | ⬜ |
| TC-SYS-SYN-018 | Verify 400 returned when not on tenant domain | Access from central domain | — | 400 Bad Request: "Not a tenant request." | — | — | ⬜ |

---

## 6. Edge Cases

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-SYN-019 | Verify sync with zero existing menus (first-time setup) | Empty `glb_menus` | — | Sync creates all menus from definition successfully | — | — | ⬜ |
| TC-SYS-SYN-020 | Verify sync response includes created count matching menu definitions | Definitions count = X | — | `data.created` = X | — | — | ⬜ |
| TC-SYS-SYN-021 | Verify concurrent sync calls are handled | Two simultaneous sync requests | — | ⚠️ No locking — second call may truncate mid-first-sync; potential race condition | — | — | ⬜ |

---

## 7. Permissions Matrix

| Role | Sync Tenant Menus | Sync Prime Menus | Refresh Cache | Tenant Cache Refresh |
|------|:-----------------:|:----------------:|:-------------:|:--------------------:|
| Super Admin | ✅ | ✅ | ✅ | ✅ |
| Platform Manager | ❌ | ❌ | ✅ | ✅ |
| Platform Support | ❌ | ❌ | ✅ | ✅ |
| School Admin | ❌ | ❌ | ❌ | ❌ (not on central) |
| Any authenticated user | ❌ | ❌ | ⚠️ (no gate check) | ✅ (tenant domain) |

---

## 8. Data Table

| TC-ID | REQ-ID | BR-ID | Type | Priority | Test Level | Automated |
|-------|:------:|:-----:|:----:|:--------:|:----------:|:---------:|
| TC-SYS-SYN-001 | REQ-SYS-007 | BR-SYS-011 | Positive | P0 | Functional | ⬜ |
| TC-SYS-SYN-002 | REQ-SYS-007 | — | Positive/Verification | P1 | Functional | ⬜ |
| TC-SYS-SYN-003 | REQ-SYS-007 | — | Positive/Integration | P1 | Integration | ⬜ |
| TC-SYS-SYN-004 | REQ-SYS-007 | — | Positive/Destructive | P1 | Functional | ⬜ |
| TC-SYS-SYN-005 | REQ-SYS-007 | BR-SYS-011 | Security/Auth | P0 | Security | ⬜ |
| TC-SYS-SYN-006 | REQ-SYS-007 | BR-SYS-018 | Security/Auth | P0 | Security | ⬜ |
| TC-SYS-SYN-007 | REQ-SYS-007 | — | Non-functional | P2 | Performance | ⬜ |
| TC-SYS-SYN-008 | REQ-SYS-007 | — | Data Integrity | P1 | Functional | ⬜ |
| TC-SYS-SYN-009 | REQ-SYS-007 | — | Positive | P0 | Functional | ⬜ |
| TC-SYS-SYN-010 | REQ-SYS-007 | — | Positive/Verification | P1 | Functional | ⬜ |
| TC-SYS-SYN-011 | REQ-SYS-007 | — | Isolation | P1 | Integration | ⬜ |
| TC-SYS-SYN-012 | REQ-SYS-007 | BR-SYS-011 | Security/Auth | P0 | Security | ⬜ |
| TC-SYS-SYN-013 | REQ-SYS-007 | — | Positive | P1 | Functional | ⬜ |
| TC-SYS-SYN-014 | REQ-SYS-007 | — | Positive/Integration | P1 | Integration | ⬜ |
| TC-SYS-SYN-015 | REQ-SYS-007 | — | Positive | P1 | Functional | ⬜ |
| TC-SYS-SYN-016 | REQ-SYS-007 | — | Positive | P1 | Functional | ⬜ |
| TC-SYS-SYN-017 | REQ-SYS-007 | — | Positive/Tenant | P1 | Functional | ⬜ |
| TC-SYS-SYN-018 | REQ-SYS-007 | — | Negative | P2 | Functional | ⬜ |
| TC-SYS-SYN-019 | REQ-SYS-007 | — | Edge/First-run | P2 | Functional | ⬜ |
| TC-SYS-SYN-020 | REQ-SYS-007 | — | Positive/Verification | P1 | Functional | ⬜ |
| TC-SYS-SYN-021 | REQ-SYS-007 | — | Concurrency | P2 | Integration | ⬜ |

---

## 9. Known Issues

| # | Issue | Linked TC | Severity | Status |
|---|-------|:---------:|:--------:|:------:|
| 1 | Controller is 2,760 lines — SRP violation | All TCs | High | ⬜ |
| 2 | No transaction wrapping — partial truncation on failure | TC-SYS-SYN-004 | Critical | ⬜ |
| 3 | `refreshCache()` has no permission check | TC-SYS-SYN-013 through TC-SYS-SYN-016 | Medium | ⬜ |
| 4 | No audit log call in sync methods — violates BR-SYS-012 | TC-SYS-SYN-001, TC-SYS-SYN-009 | Medium | ⬜ |
| 5 | No confirmation prompt before destructive truncate | TC-SYS-SYN-001 | Medium | ⬜ |
| 6 | `$legacyCodesToDelete` array is dead code (60 entries) | — | Low | ⬜ |
| 7 | No concurrency locking — dual sync requests race condition | TC-SYS-SYN-021 | Medium | ⬜ |

---

## 10. Route Reference

| Method | URI | Name | Middleware | Scope |
|--------|-----|------|-----------|-------|
| GET | `/system-config/sync-menus` | `system-config.sync-menus` | `web`, `auth`, `verified` | Central |
| GET | `/system-config/sync-prime-menus` | `system-config.sync-prime-menus` | Same | Central |
| GET | `/system-config/refresh-menu-cache` | `system-config.refresh-menu-cache` | Same | Central |
| GET | `/system-config/refresh-menu-cache` | `system-config.refresh-tenant-menu-cache` | `web`, `auth`, `verified`, tenancy | Tenant |

---

## 11. Execution Status

| TC-ID | Status | Executed By | Execution Date | Build | Comments |
|-------|:-----:|:-----------:|:--------------:|:-----:|----------|
| TC-SYS-SYN-001 | ⬜ | — | — | — | — |
| TC-SYS-SYN-002 | ⬜ | — | — | — | — |
| TC-SYS-SYN-003 | ⬜ | — | — | — | — |
| TC-SYS-SYN-004 | ⬜ | — | — | — | — |
| TC-SYS-SYN-005 | ⬜ | — | — | — | — |
| TC-SYS-SYN-006 | ⬜ | — | — | — | — |
| TC-SYS-SYN-007 | ⬜ | — | — | — | — |
| TC-SYS-SYN-008 | ⬜ | — | — | — | — |
| TC-SYS-SYN-009 | ⬜ | — | — | — | — |
| TC-SYS-SYN-010 | ⬜ | — | — | — | — |
| TC-SYS-SYN-011 | ⬜ | — | — | — | — |
| TC-SYS-SYN-012 | ⬜ | — | — | — | — |
| TC-SYS-SYN-013 | ⬜ | — | — | — | — |
| TC-SYS-SYN-014 | ⬜ | — | — | — | — |
| TC-SYS-SYN-015 | ⬜ | — | — | — | — |
| TC-SYS-SYN-016 | ⬜ | — | — | — | — |
| TC-SYS-SYN-017 | ⬜ | — | — | — | — |
| TC-SYS-SYN-018 | ⬜ | — | — | — | — |
| TC-SYS-SYN-019 | ⬜ | — | — | — | — |
| TC-SYS-SYN-020 | ⬜ | — | — | — | — |
| TC-SYS-SYN-021 | ⬜ | — | — | — | — |

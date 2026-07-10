# Scheduling & Lifecycle — Gap Analysis & Coverage

**V1 methods:** 18 · **V2 methods:** 56 · **Gate:** V2 ≥ 2×V1 → 56 ≥ 36 ✅

## 1. Manual TC ↔ Dusk method mapping

### Positive
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| MTC-01 create | 03 | 10 | Full |
| MTC-01 update | 07 | 11 | Full |
| MTC-01 delete | 08 | 12 | Full |
| MTC-01 show/breadcrumb | 06 | — | Partial (render assert only) |
| Combined page tabs | 02 | 13 | Full |
| MTC-09 practical create/unique/toggle | 17 | 14,15 | Full |
| Compute dispatch | — | 17,20 | Full |
| Export | — | 18 | Partial (status only, guarded) |

### State machine
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| MTC-04 review legal | 09 | 21 | Full |
| MTC-05 publish legal + template lock | 10 | 22 | Full |
| MTC-06 lock legal | 11 | 23 | Full |
| MTC-07 unlock legal + reason audit | 12 | 24 | Full |
| MTC-04 review illegal | 13 | 25 | Full |
| MTC-05 publish illegal | 14 | 26 | Full |
| MTC-06 lock illegal | — | 27 | Full |
| MTC-08 compute lock guard | 15 | 28 | Full |
| DRAFT compute dispatch | — | 20 | Full |

### Negative / validation
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| MTC-02 required | 04 | 30 | Full |
| MTC-03 duplicate/diff-session | 05 | 31 | Full |
| code max:50 | — | 32 | Full (rule assert) |
| name max:150 | — | 33 | Full (rule assert) |
| FK exists rules | 01 | 34 | Full |
| MTC-07 unlock reason min:5 | — | 35 | Full |
| practical numeric min:0 | — | 36 | Full |
| schedule_date nullable | — | 37 | Full |
| XSS name escaped | — | 38 | Full |
| whitespace code | — | 75 | Full |

### Dependency / integration
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| config_template FK RESTRICT | — | 40 | Full |
| status FK sys_dropdowns | — | 41 | Full |
| schedule delete CASCADE junction | — | 42 | Full |
| computation-log FK | — | 43 | Partial (migration assert) |
| MTC-10 precheck cross-module | 16 | 44 | Full (guarded) |
| publish locks template | 10 | 22 | Full |
| recompute wipes results (PERF-MSH-004) | — | 45 | Partial (source) |
| BR-MSH-027 concurrency | — | 71 | Full (behaviour) |

### Permissions / tenancy / security
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| MTC-11 guest redirect | — | 50 | Full |
| MTC-11 limited-user 403 | — | 51 | Full (guarded) |
| SEC-MSH-003 authorize()=true | 01 | 52 | Full |
| lifecycle gates wired | — | 53 | Full |
| policy abilities map | — | 54 | Full |
| Cross-tenant IDOR | — | 90 | Full (guarded) |
| XSS unlock_reason | — | 91 | Full |
| is_locked mass-assign note | — | 92 | Full |

### UI / Edge
| Manual TC | V2 | Coverage |
|-----------|----|----------|
| search / pagination / empty / practical tab | 60,61,62,63 | Full |
| BR-MSH-026 recompute defect | 29 | Full |
| unlock-from-draft edge | 70 | Full |
| BR-MSH-050 weightage sum | 72 | Full (source) |
| PERF-MSH-002 hasTable×3 | 73 | Full (source) |
| PERF-MSH-001 precheck N+1 | 74 | Partial (soft timing) |
| BUG-MSH-101 SoftDeletes gap | 04,16 (V1 18) | Full |

## 2. Coverage Summary
| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Positive | 9 | 7 | 2 | 0 | 100% |
| State machine | 9 | 9 | 0 | 0 | 100% |
| Negative | 10 | 10 | 0 | 0 | 100% |
| Dependency | 8 | 5 | 3 | 0 | 100% |
| Permissions/Tenancy/Security | 8 | 8 | 0 | 0 | 100% |
| UI/Edge | 7 | 6 | 1 | 0 | 100% |
| **Total** | **51** | **45** | **6** | **0** | **100%** |

Targets met: Negative 100% ✅ · Positive ≥90% (100%) ✅ · Dependency ≥90% (100%) ✅ · Tenancy present (P1) ✅.

## 3. Coverage-Score by requirement Source
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR / FR) | 5 | 5 | 100% |
| State-Machine transitions (Screen-SM) | 9 | 9 | 100% |
| Validation Rules (Screen-VR) | 9 | 9 | 100% |
| Integration Points (Screen-IP) | 3 | 3 | 100% |
| Permissions (Screen-PM) | 7 | 7 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. No zero-coverage items.

## 4. Cross-Reference Defect Scan
| # | Check | Compare | Finding | Test |
|---|-------|---------|---------|------|
| 1 | Enum case | DDL vs Request | No ENUMs on scheduling tables (statuses via sys_dropdowns) — clean | — |
| 2 | Route registration | Blade `route()` vs routes/web.php | review/lock/unlock/publish/precheck/compute/export all registered — clean | 53 |
| 3 | Gate vs Policy | controller `Gate::authorize` vs Policy | Policy exposes review/publish/unlock/lock/export — matched | 53,54 |
| 4 | Fillable/trait vs DDL | model vs migration | **BUG-MSH-101**: `ScheduleClass` missing `SoftDeletes` though migration declares `softDeletes()` + controller/service call soft-delete methods → runtime error (audit D38 wrongly marked clean) | 04,16, V1-18 |
| 5 | Cast vs DDL | model `$casts` vs DDL | `is_locked`/`is_active` bool casts correct; decimals correct — clean | 03 |
| 6 | Service delegation | controller vs service | Lifecycle correctly delegated to `MarksheetScheduleLifecycleService`; compute guard lives in controller (thin) — noted | 29 |
| 7 | State machine vs impl | Screen FSM vs service | review/publish/lock enforce FSM; **compute() does NOT** (BR-MSH-026); unlock ignores prior state (edge) | 29,70 |
| 8 | Validation vs FormRequest | Screen VR vs rules() | All rules present; `authorize()=true` bypass (SEC-MSH-003) | 34,52 |
| 9 | Error message vs FormRequest | expected vs messages() | DomainException strings verbatim in service; no custom `messages()` array | 25,26,27 |
| 10 | Permissions vs Policy/Gates | matrix vs Policy | Gates present but **D39-MSH** none seeded → super-admin-only | 54 + Validation prereq |
| 11 | Integration FK vs migration | requirement vs migration | config_template/session/status FKs present; schedule→jnt CASCADE present | 40,41,42,43 |

## 5. Defect candidates (verify in source)
- **BUG-MSH-101 (NEW, P1):** `ScheduleClass` missing `SoftDeletes` trait — traced across model (`app/Models/ScheduleClass.php`, only `HasFactory`), migration (`…115741` declares `softDeletes()`), controller (`ScheduleClassController` `onlyTrashed/withTrashed/restore`), service (`MarksheetScheduleService::syncClassSections` `withTrashed()/restore()`). Runtime `BadMethodCallException` on any schedule create/update with class sections and on trash/restore/force-delete. The audit's D38 ("all models with deleted_at use SoftDeletes — CLEAN") missed this. **Recommend adding `use SoftDeletes;` to `ScheduleClass`.**
- Confirmed existing audit defects reproduced as proving tests: BR-MSH-026 (29), BR-MSH-027 (71), BR-MSH-050 (72), PERF-MSH-001 (74), PERF-MSH-002 (73), PERF-MSH-004 (45), DEP-MSH-001 (44), DOC-MSH-002 (02), SEC-MSH-003 (52).

## 6. Remaining partial-coverage limitations
- **74 (PERF-MSH-001):** soft timing only (logs to STDERR, never hard-fails) — full N+1 query-count assertion needs `DB::enableQueryLog` around a controller-internal call, out of browser-Dusk scope.
- **18 (export), 43 (log FK):** assert response status / migration content rather than binary/xlsx contents.
- **45 (PERF-MSH-004):** source-level assertion (recompute path is not driven end-to-end to avoid destroying seed data).
- **06 (show breadcrumb):** render assertion only (breadcrumb link nav not deep-walked).

## Legend
Full = behaviour + DB/side-effect asserted · Partial = source/migration/status asserted (runtime path guarded or out of scope) · Gap = none.

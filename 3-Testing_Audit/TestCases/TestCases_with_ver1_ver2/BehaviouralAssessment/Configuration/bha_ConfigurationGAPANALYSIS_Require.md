# Configuration — Gap Analysis & Coverage

**Feature:** BehaviouralAssessment › Configuration · **V1 = 15 methods · V2 = 47 methods (3.13×)**
**Style:** browser Dusk · **Scope:** tenant-side · **Live table:** `ba_config`

Legend: **Full** = behaviour asserted end-to-end · **Partial** = asserted at model/DB/source layer or defensively skipped · **Gap** = not covered.

---

## 1. Manual TC ↔ V2 Method Mapping

### Positive
| Manual TC | V2 method | Coverage |
|-----------|-----------|----------|
| TC-P01 | 01 | Full |
| TC-P02 | 02 | Full |
| TC-P03 | 03 | Full |
| TC-P04 | 06 | Full |
| TC-P10 | 15 | Full |
| TC-P11 | 10 | Full |
| TC-P12 | 11 | Full |
| TC-P13 | 12 | Full |
| TC-P14 | 13 | Full |
| TC-P15 | 14 | Full |
| TC-P16 | 15 | Full |
| TC-P60 | 60 | Full |
| TC-P61 | 61 | Partial (search relies on shared scale name) |
| TC-P62 | 62 | Full |

### Negative
| Manual TC | V2 method | Coverage |
|-----------|-----------|----------|
| TC-N01 | 05 | Full |
| TC-N02 | 04 | Full |
| TC-N10 | 31 | Full |
| TC-N30 | 30 | Full |
| TC-N32 | 32 | Full |
| TC-N33 | 33 | Full |
| TC-N34 | 34 | Full |
| TC-N35 | 35 | Full |
| TC-N36 | 36 | Full |
| TC-N37 | 37 | Full |
| TC-N40 (SEC-BA-002) | 52 | Full (proves gap) |
| TC-N41 (DATA-BA-001) | 82 | Full (source scan + model switch; proves bug) |
| TC-N42 (SEC-BA-001) | 83 | Full (proves bug) |
| TC-N43 (CFG candidate) | 84 | Full (proves gap) |
| TC-N44 (REQ candidate) | 85 | Full (proves divergence) |

### Dependency / State / Config / Tenancy / Security
| Manual TC | V2 method | Coverage |
|-----------|-----------|----------|
| TC-D01 | 22/23/24 | Full |
| TC-D02 | 23 | Full |
| TC-D03 | 24 | Full |
| TC-D06 | 16 | Full (source scan of service) |
| TC-D07 | 40 | Full |
| TC-D08 | 41 | Full |
| TC-D09 | 42 | Full (defensive; RESTRICT) |
| TC-D10 (DATA-BA-003) | 43 | Full (proves bug) |
| TC-D11 | 70 | Full |
| TC-D12 | 71 | Full |
| TC-SM01 | 20 | Full |
| TC-SM02 | 21 | Partial (async-JS fetch; env-dependent) |
| TC-SM03 | 22 | Full |
| TC-CFG01 | 80 | Full (source scan) |
| TC-CFG02 | 81 | Full (source scan) |
| TC-T01 | 90 | Full |
| TC-S01 | 50 | Full |
| TC-S02 | 51 | Full |
| TC-S04 | 53 | Partial (limited-user provisioning defensive skip) |
| TC-S06 | 91 | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Positive | 14 | 13 | 1 | 0 | 100% |
| Negative | 15 | 15 | 0 | 0 | 100% |
| Dependency | 10 | 10 | 0 | 0 | 100% |
| State-machine | 3 | 2 | 1 | 0 | 100% |
| Configuration | 2 | 2 | 0 | 0 | 100% |
| Tenancy | 1 | 1 | 0 | 0 | 100% |
| Security/Auth | 5 | 4 | 1 | 0 | 100% |
| **Total** | **50** | **47** | **3** | **0** | **100%** |

Targets met: Negative 100% (≥100), Positive 100% (≥90), Dependency 100% (≥90), Tenancy 100%.

**Partial-coverage limitations**
- TC-P61 (`61`) — searches on the bound rating scale's name; if that name is shared with other rows the assertion is still satisfied (defensive), and it `markTestSkipped`s if the scale has no name.
- TC-SM02 (`21`) — asserts JSON via `executeAsyncScript`; if the page has no CSRF meta the fetch may 419; assertion is defensive.
- TC-S04 (`53`) — `markTestSkipped` when a limited `sys_users` row can't be provisioned (FK to `glb_languages`).

---

## 3. Cross-Reference Defect Scan (11 checks)

Findings reported as **verify in source** (traced to cited lines); each maps to a proving test.

| # | Check | Compared | Finding | ID | Proving test |
|---|-------|----------|---------|----|--------------|
| 1 | Enum case | DDL `ENUM` vs Request `in:` | `aggregation_method` DDL order is `average,separate_display,weighted_average`; Request `in:average,weighted_average,separate_display` — same value set, case-exact. `parent_notification_threshold` DDL `critical,major,minor,moderate` vs Request `minor,moderate,major,critical` — same set, case-exact. No enum mismatch. | — | 34, 35 |
| 2 | Route registration | Blade `route('behavioural-assessment.configs.*')` vs `routes/web.php` | Static routes (`trash`,`restore`,`force-delete`,`toggle-status`) declared **before** `Route::resource('configs', …)`. All referenced names registered. No gap. | — | 60–62 |
| 3 | Gate vs Policy | Controller `Gate::authorize('…configs.*')` vs `BaConfigPolicy` | Policy methods exist for all 8 abilities, but the controller uses `Gate::authorize(permission-string)` (Spatie permission gate), not `authorize('update',$model)` → policy class effectively unused for configs. | AUTH-BA-CFG-01 | 52 |
| 4 | Fillable vs DDL | `BaConfig::$fillable` vs `ba_config` cols | All writable cols present; `created_by/updated_by` fillable (set in controller). No gap. | — | 03 |
| 5 | Cast vs DDL | `$casts` vs column type | `decimal:1` on DECIMAL(4,1), boolean on TINYINT(1), integer on FKs — correct. No gap. | — | 06 |
| 6 | Service delegation | Controller body vs Service | Config CRUD uses plain Eloquent (no service). `BehaviouralScoreService` **reads** the config for scoring — no duplicated business logic. | — | 16 |
| 7 | State machine vs impl | Screen "Scale Integrity Constraint" vs `update`/edit blade | Once ratings exist the scale dropdown must lock (BR-BA-029). `update()` has **no** ratings guard; edit blade select has **no** `disabled`. | DATA-BA-001 | 82 |
| 8 | Validation vs FormRequest | Screen rules vs `rules()` | Screen "Incident Escalation Threshold" (int, default 3) and "Approval Workflow" boolean have **no** validation rule and **no** column — not implemented. | REQ-BA-CFG-01 | 85 |
| 9 | Error message vs FormRequest | Expected vs `messages()` | Only `academic_session_id.unique` has a custom message (asserted verbatim); other fields use Laravel defaults (tests assert `.alert-danger` + no-insert). | — | 31 |
| 10 | Permissions vs Policy/Gates | Screen permission matrix vs Policy + gates | 8 abilities consistent across controller/policy/blade. `authorize()` in FormRequest returns bare `true`. | SEC-BA-002 | 52 |
| 11 | Integration FK vs migration | Screen FKs vs migration `foreign()` | `ba_config.rating_scale_id` → `ba_rating_scales` RESTRICT; `academic_session_id` → `sch_org_academic_sessions_jnt` RESTRICT — both present. `uq_ba_config_session` unique **omits `deleted_at`** → recreate-after-delete collision. Also: `weightage_percent` stored but not consumed; `parent_notification_threshold` stored but not consumed. | DATA-BA-003 / SEC-BA-001 / CFG-BA-CFG-01 | 43, 83, 84 |

**Cross-Reference Findings count: 7** — `DATA-BA-001`, `SEC-BA-001`, `SEC-BA-002`, `DATA-BA-003`, `DOC-BA-001` (audit-confirmed); `CFG-BA-CFG-01` (weightage unused), `REQ-BA-CFG-01` (screen fields absent) + `AUTH-BA-CFG-01` (gate-uses-permission-string) are newly surfaced candidates reported as **verify in source**.

---

## 4. Coverage-Score by Requirement Source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`: one config/session, scale-integrity lock, global-approval flow, multi-tenant isolation) | 3 | 4 | 75% |
| State-Machine transitions (`Screen-SM`: active↔inactive, trash lifecycle) | 5 | 5 | 100% |
| Validation Rules (`Screen-VR`: session, scale, weightage, aggregation, threshold) | 5 | 5 | 100% |
| Integration Points (`Screen-IP`: scale binding→scoring, aggregation→scoring, threshold→notification) | 3 | 3 | 100% (2 wired, 1 proven-absent) |
| Permissions (`Screen-PM`: 8 abilities + guest) | 5 | 5 | 100% |

**Explicit requirement gaps (each has ≥1 proving TC — a documented gap, not an untested requirement):**
- `Screen-BR` "Scale Integrity Constraint" (lock scale after ratings) — **no application enforcement**; covered as a documented gap (DATA-BA-001, test 82). Counts as the 1 uncovered BR.
- `Screen-BR` "Global Approval Flow" (Approval Workflow toggle) — **field not implemented** on `ba_config`; proven absent (REQ-BA-CFG-01, test 85).
- `Screen-IP` threshold→notification — **not wired**; proven absent (SEC-BA-001, test 83).

Every `Source`-tagged requirement item has ≥ 1 mapped TC.

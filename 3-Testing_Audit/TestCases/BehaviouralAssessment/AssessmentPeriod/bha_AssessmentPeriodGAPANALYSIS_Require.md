# AssessmentPeriod — Gap Analysis & Coverage

**Feature:** BehaviouralAssessment › AssessmentPeriod · **V1 = 16 methods · V2 = 44 methods (2.75×)**
**Style:** browser Dusk · **Scope:** tenant-side · **Live table:** `ba_assessment_periods`
**Focus:** WORKFLOW/FSM feature — the `BC-SM` band (20–29) is the centre of gravity.

Legend: **Full** = behaviour asserted end-to-end · **Partial** = asserted at model/DB/source layer or defensively skipped · **Gap** = not covered.

---

## 1. Manual TC ↔ V2 Method Mapping

### Positive
| Manual TC | V2 method | Coverage |
|-----------|-----------|----------|
| TC-P01 | 01 / 02 | Full |
| TC-P02 / P04 | 06 | Full |
| TC-P03 | 03 | Full |
| TC-P10 | 10 / 11 | Full |
| TC-P11 | 12 | Full |
| TC-P12 | 13 | Full |
| TC-P13 | 14 | Full |
| TC-P15 | 15 | Full |
| TC-P20 | 60 | Full |
| TC-P21 | 61 | Full |
| TC-P22 | 62 | Full |
| TC-P23 | 63 | Full |

### State-machine (BC-SM) — the FSM band
| Manual TC | Transition | V2 method | Coverage |
|-----------|-----------|-----------|----------|
| TC-SM-tog | is_active flip (JSON) | 20 | Full |
| TC-SM-01 | open → locked (legal) | 21 | Full |
| TC-SM-02 | locked → closed (unlock) | 22 | Full |
| TC-SM-04 | lock already-locked (guard) | 23 | Full |
| TC-SM-05 | unlock non-locked (guard) | 24 | Full |
| TC-SM-03 (BUG-BA-002) | closed → locked (illegal re-lock) | 25 | Full (proves bug) |
| TC-SM-08 (BUG-BA-002) | open → closed unreachable | 26 | Full (proves bug) |
| TC-SM-06a (BUG-BA-002) | edit back-door closed → open | 27 | Full (proves bug) |
| TC-SM-06b (BUG-BA-002) | edit back-door open → closed | 28 | Full (proves bug) |
| TC-SM-10 (BUG-BA-001) | lock() no cascade (source) | 29 | Full (proves bug) |
| TC-N25 (BUG-BA-001) | assessment writable under lock (data) | 41 | Partial (cross-module defensive skip) |

### Negative
| Manual TC | V2 method | Coverage |
|-----------|-----------|----------|
| TC-N01 | 05 | Full |
| TC-N02 | 04 | Full |
| TC-N30 | 30 | Full |
| TC-N10 | 31 | Full |
| TC-N32 | 32 | Full |
| TC-N33 | 33 | Full |
| TC-N34 | 34 | Full |
| TC-N26 (VAL-BA-AP-01) | 71 | Full (proves gap) |
| TC-S03 (SEC-BA-002) | 52 | Full (proves gap) |

### Dependency / Tenancy / Security
| Manual TC | V2 method | Coverage |
|-----------|-----------|----------|
| TC-D01 | 43 | Full |
| TC-D02 | 40 | Partial (cross-module assessment defensive skip) |
| TC-D03 | 42 | Full |
| TC-D04 | 43 | Full |
| TC-D08 | 70 | Full |
| TC-T01 | 90 | Full |
| TC-S01 | 50 | Full |
| TC-S02 | 51 | Full |
| TC-S04 | 53 | Partial (limited-user provisioning defensive skip) |
| TC-S05 | 91 | Full |
| TC-S06 | 92 | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Positive | 12 | 12 | 0 | 0 | 100% |
| Negative | 9 | 9 | 0 | 0 | 100% |
| State-machine | 11 | 10 | 1 | 0 | 100% |
| Dependency | 5 | 4 | 1 | 0 | 100% |
| Tenancy | 1 | 1 | 0 | 0 | 100% |
| Security/Auth | 5 | 4 | 1 | 0 | 100% |
| **Total** | **43** | **40** | **3** | **0** | **100%** |

Targets met: Negative 100% (≥100), Positive 100% (≥90), Dependency 100% (≥90), **State-machine 100%** (every legal + key illegal transition covered), Tenancy 100%.

**Partial-coverage limitations**
- TC-N25 / BUG-BA-001 data proof (`41`) & TC-D02 (`40`) — need cross-module `sch_employees` + `sch_class_section_jnt` rows to create a real `ba_assessment`; `markTestSkipped` when absent. The **source-scan** proof of BUG-BA-001 (`29`) always runs and is Full.
- TC-S04 (`53`) — `markTestSkipped` when a limited `sys_users` row can't be provisioned (FK to `glb_languages`).

---

## 3. Cross-Reference Defect Scan (11 checks)

Findings reported as **verify in source** (traced to cited lines); each maps to a proving test.

| # | Check | Compared | Finding | ID | Proving test |
|---|-------|----------|---------|----|--------------|
| 1 | Enum case | DDL `ENUM('open','closed','locked')` vs Request `in:open,closed,locked` vs migration `['closed','locked','open']` | Values match case-exact; migration lists them in a different **order** (harmless) but the live column type is identical. No enum-case bug. | — | 01, 02 |
| 2 | Route registration | Blade `route('…assessment-periods.lock/unlock/toggleStatus')` vs `routes/web.php` | All referenced names registered; static routes (`/trash`,`/restore`,`/force-delete`,`/lock`,`/unlock`,`/toggle-status`) declared **before** `Route::resource`. **No `…/close` route** → confirms BUG-BA-002. | BUG-BA-002 | 26 |
| 3 | Gate vs Policy | Controller `Gate::authorize('…assessment-periods.*')` vs Policy | Gates use direct permission strings (Spatie), incl. `lock`/`unlock` abilities not in the standard CRUD set. Consistent. | — | 52 |
| 4 | Fillable vs DDL | `BaAssessmentPeriod::$fillable` vs columns | All writable cols present (incl. `status`). `status` being fillable + editable on the edit form is the FSM back-door. | BUG-BA-002 | 03, 27 |
| 5 | Cast vs DDL | `$casts` vs column type | `date` on DATE cols, `boolean` on TINYINT(1) — correct. No `status` cast (plain string enum). | — | 01 |
| 6 | Service delegation | Controller body vs `BehaviouralScoreService` | Period CRUD/FSM does **not** use a service (plain Eloquent). Score service only reads periods. No duplication. | — | — |
| 7 | State machine vs impl | FRD FSM-2 (`open→closed→locked`, locked terminal) vs `lock()`/`unlock()`/`update()` | `lock()` allows `open→locked` (skips closed) **and** `closed→locked` (re-lock terminal); `unlock()` maps `locked→closed` (mislabeled); **no `close()`**; `update()` writes `status` unchecked (back-door). `open→closed` unreachable via actions. | **BUG-BA-002** | 25, 26, 27, 28 |
| 8 | Validation vs FormRequest | Screen rules vs `rules()` | `after_or_equal`/`gte`/`exists` present. **"Chronological Non-Overlapping Rule" has NO rule/check** anywhere. | **VAL-BA-AP-01** | 71 |
| 9 | Error message vs FormRequest | Expected vs `messages()` | Request defines **no** custom `messages()` → Laravel defaults. Tests assert `.alert-danger` + no-insert (message text not asserted, by design). | — | 30–34 |
| 10 | Permissions vs Policy/Gates | Screen matrix vs gates | 10 abilities consistent across controller/blade. `authorize()` in FormRequest returns bare `true`. | SEC-BA-002 | 52 |
| 11 | Integration FK vs migration | Screen FKs vs migration `foreign()` | `academic_session_id` → `sch_org_academic_sessions_jnt` RESTRICT (`fk_ba_period_session_id`); `academic_term_id` → `sch_academic_term` SET NULL (`fk_ba_period_term_id`); `ba_assessments.period_id` → periods RESTRICT (destroy() guard). All present. | — | 02, 40 |

**Cross-Reference Findings count: 4** (BUG-BA-002, BUG-BA-001, SEC-BA-002, VAL-BA-AP-01). Of these, 3 are audit-confirmed (`BUG-BA-002`, `BUG-BA-001`, `SEC-BA-002` + doc `DOC-BA-001`); 1 is a newly surfaced candidate (`VAL-BA-AP-01`, non-overlap rule) reported as **verify in source**.

**Additional artifact note (not a source defect):** the committed sibling `AssessmentPeriodCrudTest.php` is **stale** — wrong migration path (`2026_04_11_000007…` vs live `2026_06_16_130612…`), page texts that do not exist (`Create/Edit Assessment Period`, `Assessment Period Details`), capitalised flash (`Assessment Period updated…` vs real `Assessment period updated…`), and selectors that do not exist (`.lock-btn`/`.unlock-btn`/`.status-switch`). This suite uses the real strings and drives lock/unlock/toggle via the real endpoints.

---

## 4. Coverage-Score by Requirement Source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`: absolute-lock, delete-restriction, non-overlap, manual-lock) | 3 | 4 | 75% |
| State-Machine transitions (`Screen-SM`: store→open, open→locked, locked→closed, guards, illegal re-lock, unreachable close, back-door) | 10 | 10 | 100% |
| Validation Rules (`Screen-VR`: session, name, start, end≥start, deadline≥end, term) | 6 | 6 | 100% |
| Integration Points (`Screen-IP`: session FK, term FK, assessments RESTRICT) | 3 | 3 | 100% |
| Permissions (`Screen-PM`: 10 abilities + guest) | 6 | 6 | 100% |

**Explicit requirement gap (0 TC would be a fail — all have ≥1):**
- `Screen-BR` "Absolute Lock Rule" (freeze ratings/remarks/review when locked) — **not implemented in source** (BUG-BA-001); covered only as a documented gap proof (`29`/`41`), counted as the 1 uncovered BR since the intended *freeze* behaviour cannot be asserted Full. Recommend a real freeze test once BUG-BA-001 is fixed.

Every other `Source`-tagged item has ≥ 1 mapped TC.

# FrontOffice :: NoticesEvents — Gap Analysis & Coverage

Maps every TC (from `fof_NoticesEventsTcList_Require.md`) to the method(s) in
`fof_NoticesEvents_TestCas.php`. Compound feature → both `fof_notices` and
`fof_school_events` are covered.

Legend: **Full** = behaviour fully asserted · **Partial** = asserted but env/tolerance-limited · **Gap** = not covered.

---

## 1. Coverage by category

### Schema / Configuration (G46)
| TC | Method(s) | Coverage |
|----|-----------|----------|
| TC-P01 Notice alignment | `_01` | Full |
| TC-P02 Event alignment | `_02` | Full |
| TC-P03/N01 Notice nullable/required | `_05`,`_03` | Full |
| TC-P04/N02 Event nullable/required | `_06`,`_04` | Full |
| TC-P05 defaults | `_07` | Full |
| TC-P06 casts | `_08` | Full |
| TC-P07 no-unique duplicates | `_09` | Full |

### Negative matrix (target 100%)
| TC | Method(s) | Coverage |
|----|-----------|----------|
| TC-N01 notice required missing | `_03` | Full |
| TC-N02 event required missing | `_04` | Full |
| TC-N03 over-length title/name/venue (G45) | `_30`,`_31`,`_32` | Full |
| TC-N04 category app-only values (DEV-001) | `_33` | Full |
| TC-N05 audience Management (DEV-002) | `_35` | Full |
| TC-N06 event_type Function (DEV-003) | `_36` | Full |
| TC-N07 end_date NOT NULL (DEV-004) | `_38` | Full |
| TC-N08 store missing required (browser) | `_39` | Partial (needs module enabled; tolerant status set) |
| TC-N09 attachment FK | `_40` | Partial (skips if sys_media absent) |
| TC-N10 show 404 | `_72`,`_73` | Partial (needs module enabled) |
| TC-N11 guest redirect | `_50`,`_51` | Full |
| TC-N12 limited-user 403 | `_52`–`_55` | Full (real 403 + `forgetCachedPermissions`, non-super-admin) |
| TC-N13 stored XSS | `_90`,`_91` | Partial (needs module enabled to render show) |

**Negative coverage: 13/13 categories = 100%.**

### Positive matrix (target ≥ 90%)
| TC | Method(s) | Coverage |
|----|-----------|----------|
| TC-P08 active scopes | `_10`,`_12` | Full |
| TC-P09 emergency visible (BR-FOF-014) | `_11` | Full |
| TC-P10 upcoming scope | `_13` | Full |
| TC-P11 status default | `_14` | Full |
| TC-P12 category db-valid | `_34` | Full |
| TC-P13 event_type db-valid | `_37` | Full |
| TC-P14 created_by auto | `_42`,`_43` | Partial (needs module enabled) |
| TC-P15 toggle-status | `_20`,`_21` | Partial (needs module enabled) |
| TC-P16 lifecycle | `_22`–`_27` | Partial (needs module enabled) |
| TC-P17 max-length accept | `_30`,`_31` | Full |
| TC-P18 UI list/search/filter/show/edit | `_60`–`_67` | Partial (needs module enabled) |
| TC-P19 pinned ordering | `_68` | Full (model-level) |
| TC-P20 long text | `_74`,`_75` | Full |
| TC-P21 trash listings | `_70`,`_71` | Partial (needs module enabled) |

**Positive coverage: 21/21 categories ≥ 90% (all have ≥1 asserting method).**

### Dependency (target ≥ 90%)
| TC | Method(s) | Coverage |
|----|-----------|----------|
| TC-D01 FK SET NULL declared | `_41` | Full (schema inspection, skip if DDL lags) |
| TC-D02 invalid FK rejected | `_40` | Partial (skip if sys_media absent) |

**Dependency coverage: 2/2 = 100% (env-guarded).**

### State-machine (BC-SM)
| Transition | Method | Coverage |
|-----------|--------|----------|
| active→toggle→inactive | `_20`,`_21` | Partial |
| active→destroy→trashed (+event log) | `_22`,`_23` | Partial |
| trashed→restore→active (+log) | `_24`,`_25` | Partial |
| trashed→forceDelete→gone | `_26`,`_27` | Partial |

**All 4 legal transitions × 2 entities have a TC.**

### Security (TC-S)
| TC | Method | Coverage |
|----|--------|----------|
| Stored XSS title/event_name | `_90`,`_91` | Partial |

---

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % (≥Partial) |
|----------|-------|------|---------|-----|--------------|
| Schema/Config | 7 | 7 | 0 | 0 | 100% |
| Negative | 13 | 8 | 5 | 0 | 100% |
| Positive | 21 | 12 | 9 | 0 | 100% |
| Dependency | 2 | 1 | 1 | 0 | 100% |
| State-machine | 8 | 0 | 8 | 0 | 100% |
| Security | 2 | 0 | 2 | 0 | 100% |
| DEV proving | 6 | 6 | 0 | 0 | 100% |

**"Partial" = the assertion is real and correct but requires FrontOffice ENABLED in `modules_statuses.json` and/or a live tenant URL to exercise the HTTP path; model-layer assertions run unconditionally. No true Gaps.**

---

## 3. Coverage-Score by requirement Source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 4 | 4 | 100% |
| State-Machine (BC-SM) | 4 | 4 | 100% |
| Validation Rules (BC-VAL) | 8 | 8 | 100% |
| Integration Points (BC-REF/INT) | 1 | 1 | 100% |
| Permissions (BC-AUTH) | 3 | 3 | 100% |
| DDL constraints (BC-DB N01–N13, E01–E12) | 25 | 25 | 100% |

Every `Source`-tagged item has ≥ 1 TC. No zero-coverage items.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compare | Finding | DEV |
|---|-------|---------|---------|-----|
| 1 | Enum case/domain | DDL `ENUM` vs controller `in:` | notice.category, both.audience, event.event_type all diverge | **DEV-FOF-NE-001/002/003** |
| 2 | Route registration | Blade `route()` vs `routes/web.php` | all `fof.notices.*`/`fof.school-events.*` registered; store/update redirect to `fof.menu.communication` (exists) | OK |
| 3 | Gate vs Policy | `Gate::authorize('frontoffice.notice.*')` string gate vs `NoticePolicy`/`SchoolEventPolicy` | string gates NOT model-bound to the policies (module-wide SEC-FOF-001 pattern) | Note (SEC-FOF-001) |
| 4 | Fillable vs DDL | model `$fillable` vs DDL cols | aligned (both) | OK |
| 5 | Cast vs DDL | `$casts` vs DDL types | aligned (bool/date) | OK |
| 6 | Service delegation | controller vs Service | no service layer; logic inline | OK |
| 7 | State machine vs impl | lifecycle vs controller | toggle/destroy/restore/forceDelete present | OK |
| 8 | Validation vs rules | requirement vs `validate()` | inline rules present | OK |
| 9 | Error message vs rules | expected vs messages | default Laravel messages (no custom `messages()`) | Note |
| 10 | Permissions vs gates | matrix vs `Gate::authorize` | `notice`/`school-event` slugs (singular, hyphen) confirmed | OK |
| 11 | Integration FK vs migration | requirement FK vs schema | attachment→sys_media SET NULL | OK |
| 12 | UNIQUE enforcement | DDL UNIQUE vs `unique:` | neither table has UNIQUE; no `unique:` rule | OK (G43 absence) |
| 13 | Required enforcement | DDL NOT NULL vs `required` | **event.end_date NOT NULL but `nullable`** | **DEV-FOF-NE-004** |
| 14 | Length enforcement | DDL `VARCHAR(n)` vs `max:` | notice.title max:200=col; **event.venue max:150 < col 200** | **DEV-FOF-NE-006** |
| 15 | Soft-delete col vs trait | DDL `deleted_at` vs `SoftDeletes` | both present & agree (asserted independently `_01`/`_02`) | OK |
| — | Activity-log completeness | module convention vs controllers | store/update (+notice destroy/toggle) call no `activityLog()` | **DEV-FOF-NE-005** |

---

## 5. DEV register (this feature)

| ID | Sev | Summary | Proving test | Status |
|----|-----|---------|--------------|--------|
| DEV-FOF-NE-001 | P2 | notice.category ENUM app↔DB mismatch | `_33`,`_34` | Documented, proven |
| DEV-FOF-NE-002 | P2 | audience 'Management' not in DB ENUM (both) | `_35` | Documented, proven |
| DEV-FOF-NE-003 | P2 | event.event_type app allows 'Function', rejects Exam/Admission | `_36`,`_37` | Documented, proven |
| DEV-FOF-NE-004 | P1 | event.end_date NOT NULL vs FormRequest nullable | `_38` | Documented, proven |
| DEV-FOF-NE-005 | P2 | partial activity logging | `_92`,`_93` | Documented, proven (reflection) |
| DEV-FOF-NE-006 | P3 | venue max:150 < column 200 | `_32` | Documented |
| SEC-FOF-001 | P1 | string gates not bound to Notice/SchoolEvent policies (module-wide) | — | Carried from FactPack |
| SEC-FOF-003 | P1 | no FormRequest → no `authorize()` defense-in-depth | — | Carried from FactPack |

---

## 6. Coverage targets — verdict

| Target | Required | Achieved |
|--------|----------|----------|
| Negative | 100% | 100% |
| Positive | ≥ 90% | 100% |
| Dependency | ≥ 90% | 100% |
| Tenancy/Security (P1) | present | XSS + guest + 403 present |

All targets met (subject to the ENV prerequisite that FrontOffice is enabled for the HTTP-path methods).

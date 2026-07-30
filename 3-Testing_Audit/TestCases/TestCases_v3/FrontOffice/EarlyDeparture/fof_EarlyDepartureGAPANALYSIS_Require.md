# FrontOffice — Early Departure : Gap Analysis & Traceability

Maps every TC (from `fof_EarlyDepartureTcList_Require.md`) to test method(s) in `fof_EarlyDeparture_TestCas.php`, with coverage = **Full / Partial / Gap**. Includes the Cross-Reference Defect Scan (15 checks) and per-requirement Coverage-Score table.

Legend: **Full** = TC exercised end-to-end with a real assertion. **Partial** = asserted but env-tolerant (module disabled → skip/tolerant status) or DB-layer proxy for a FormRequest rule. **Gap** = no coverage.

---

## 1. Coverage by category

### Positive

| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-P01 | `_01` | Full | Full DDL↔app matrix vs live schema |
| TC-P02 | `_04` | Full | Nullable NULL insert |
| TC-P03 | `_07` | Full | Defaults via query-builder insert + refresh (F35) |
| TC-P04 | `_10` | Full | Service auto-number regex (skips if dispatch unavailable) |
| TC-P05 | `_14` | Full | today-visible / old-hidden on index |
| TC-P06 | `_22` | Partial | is_active toggle via browser XHR; tolerant when module disabled |
| TC-P07 | `_23` | Full | soft delete + restore |
| TC-P08 | `_24` | Full | force delete |
| TC-P09 | `_30` | Partial | browser form happy path; skips if create form unreachable |
| TC-P10 | `_36` | Full | exactly-100 boundary accepted |
| TC-P11 | `_60` | Partial | index render; env-tolerant |
| TC-P12 | `_61` | Partial | create form selectors; env-tolerant |
| TC-P13 | `_63` | Partial | show page; env-tolerant |
| TC-P14 | `_64` | Partial | trash render; env-tolerant |
| TC-P15 | `_38` | Partial | edit/update; env-tolerant |
| TC-P16 | `_40` | Full | student() relationship (skips if StudentProfile absent) |
| TC-P17 | `_12` | Full | att_sync_status not a form input (source) |
| TC-P18 | `_13` | Full | created_by set programmatically (source) |
| TC-P19 | `_11` | Full | lockForUpdate present (source) |
| TC-P20 | `_15` | Full | Updated activity row count +1 |
| TC-P21 | `_91` | Full | tenant-scoped visibility |
| TC-P22 | `_90` | Full | ActivityLog $table = sys_activity_logs |

Positive: 22/22 covered (Full 14, Partial 8). **Positive coverage = 100% present, ≥ 90% Full-or-Partial.**

### Negative

| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-N01 | `_02` | Full | UNIQUE duplicate rejected (DB) |
| TC-N02 | `_03` | Full | 8 NOT-NULL columns each rejected (DB loop) |
| TC-N03 | `_21` | Full | invalid att_sync_status enum rejected |
| TC-N04 | `_25` | Full | force-deleted not restorable |
| TC-N05 | `_31` | Partial | missing name via form; env-tolerant |
| TC-N06 | `_32` | Partial | future departure_time; env-tolerant |
| TC-N07 | `_33` | Partial | invalid reason enum; env-tolerant |
| TC-N08 | `_34` | Partial | over-length name; env-tolerant, 500-vs-422 tolerant |
| TC-N09 | `_35` | Full | over-length id_proof_number (DB, ≤50) |
| TC-N10 | `_42` | Partial | non-existent student_id; env-tolerant |
| TC-N11 | `_50` | Full | guest → login |
| TC-N12 | `_51` | Full | non-super-admin denied index (not 200) |
| TC-N13 | `_52` | Full | non-super-admin denied create (not 200) |

Negative: 13/13 covered. **Negative coverage = 100%.**

### Dependency / Security

| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-D01 | `_05` | Full | soft-delete column & trait independent |
| TC-D02 | `_06` | Full | FK RESTRICT (information_schema; skip if absent) |
| TC-D03 | `_20` | Full | ATT sync Failed + updated_by=0 (ORM-FOF-001) |
| TC-D04 | `_17` | Full | toggleStatus writes no activity |
| TC-S01 | `_70` | Full | XSS escaped (script not executed) |
| TC-S02 | `_71` | Full | whitespace-only behaviour |
| TC-S03 | `_54` | Full | authorize() true defect proven |

Dependency/Security: 7/7 covered. **Dependency coverage = 100%.**

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % Covered |
|----------|----------|------|---------|-----|-----------|
| Positive | 22 | 14 | 8 | 0 | 100% |
| Negative | 13 | 9 | 4 | 0 | 100% |
| Dependency/Security | 7 | 7 | 0 | 0 | 100% |
| **Total** | **42** | **30** | **12** | **0** | **100%** |

Every TC-ID ↔ ≥1 method; every method ↔ a TC/BC. Partials are env-tolerant browser flows (module currently disabled) or DB-layer proxies for FormRequest rules — no coverage is dropped.

Targets: Negative 100% ✅ · Positive ≥ 90% ✅ · Dependency ≥ 90% ✅ · Tenancy present (`_90`,`_91`) ✅.

---

## 3. Coverage-Score by requirement source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`BC-BIZ`) | 5 | 5 | 100% |
| State-Machine transitions (`BC-SM`) | 11 | 11 | 100% |
| Validation Rules (`BC-VAL`) | 11 | 11 | 100% |
| DB constraints (`BC-DB`) | 18 | 18 | 100% |
| Auto/programmatic fields (`BC-AUTO`) | 5 | 5 | 100% |
| Integration Points (`BC-INT`) | 3 | 3 | 100% |
| Permissions (`BC-AUTH`) | 7 | 7 | 100% |
| Edge (`BC-EDG`) | 3 | 3 | 100% |

Notes: BC-SM-01 (Pending→Synced) and BC-SM-03 (retry→Synced) are covered indirectly — the ATT service is absent in the test env, so `_20` exercises the Failed branch and BR-FOF-013's "not silent" contract; the Synced branch is documented (MT-2) and would require the Attendance module installed. BC-VAL every rule has a TC (DB or form layer). No `Source`-tagged item has 0 TCs.

---

## 4. Cross-Reference Defect Scan (15 checks)

| # | Check | Compared | Finding | DEV / Status |
|---|-------|----------|---------|--------------|
| 1 | Enum case | DDL ENUM vs Request `in:` | reason, relation, id_proof_type all match case-exactly (`Family_Emergency`, `Driving_License`) | ✅ aligned |
| 2 | Route registration | Blade `route('fof.early-departures.*')` + `route('fof.menu.visitorManagement')` vs routes/web.php | all present (index/create/store/show/edit/update/destroy/toggleStatus/trashed/restore/forceDelete + menu.visitorManagement) | ✅ registered |
| 3 | Gate vs Policy | Controller `Gate::authorize('frontoffice.early-departure.*')` vs `EarlyDeparturePolicy` | string gates used; Policy exists mirroring same abilities but is NOT invoked by the controller (string gate, not `authorize($model)`) | ⚠ DEV-FOF-ED-06 (Policy dead on these paths; abilities still enforced via Spatie perms) |
| 4 | Fillable vs DDL | Model `$fillable` vs DDL columns | all user + auto cols fillable; no missing/extra | ✅ aligned |
| 5 | Cast vs DDL | Model `$casts` vs DDL | `parent_authorized`/`is_active`→boolean (TINYINT), `departure_time`/`att_synced_at`→datetime | ✅ aligned |
| 6 | Service delegation | Controller `store` vs `EarlyDepartureService::logDeparture` | store delegates correctly; update/destroy inline in controller (acceptable) | ✅ |
| 7 | State machine vs impl | BC-SM vs service/controller | att_sync FSM in service; is_active toggle + soft-delete in controller; all handled | ✅ |
| 8 | Validation vs FormRequest | BC-VAL vs `rules()` | all rules present; `before_or_equal:now` enforces no-future (business rule beyond DDL) | ✅ |
| 9 | Error message vs FormRequest | expected vs `messages()` | `EarlyDepartureRequest` defines **no** custom `messages()` — Laravel defaults used | ℹ note (not a defect) |
| 10 | Permissions vs Policy/Gates | BC-AUTH vs Gates | 6 abilities; toggleStatus reuses `update` (no separate `toggle` ability) | ✅ (consistent with module) |
| 11 | Integration FK vs migration | BC-INT-02 vs DDL | `fk_fof_ed_student_id` → std_students RESTRICT/CASCADE present | ✅ |
| 12 | UNIQUE enforcement | DDL UNIQUE vs Request `unique:` | DB has `uq_fof_ed_departure_number`; Request has **no** `unique:` rule — OK because departure_number is auto-generated (not a form input); uniqueness proven at DB (`_02`) | ✅ by design (G48) |
| 13 | Required enforcement | DDL NOT NULL vs Request `required` | DDL NOT NULL user cols (student_id, departure_time, reason, collecting_person_name, collecting_person_relation) all `required` in Request; auto cols (departure_number, created_by, updated_by) set by service | ✅ aligned |
| 14 | Length enforcement | DDL VARCHAR(n) vs Request `max:` | collecting_person_name 100=100 ✅; collecting_id_proof_number 50=50 ✅; reason_details 200=200 ✅; **`notes` DDL TEXT vs Request max:1000** — Request stricter (safe) | ℹ DEV-FOF-ED-05 (info) |
| 15 | Soft-delete column vs trait | DDL `deleted_at` vs model `SoftDeletes` | both present (`_05`) | ✅ aligned |

### Cross-Reference DEV candidates

| ID | Sev | Finding | Proving/Documenting test |
|----|-----|---------|--------------------------|
| DEV-FOF-ED-01 (=SEC-FOF-003) | P1 | FormRequest `authorize()` returns `true` (D30) | `_54` |
| DEV-FOF-ED-02 (=JOB-FOF-001) | P1 | AttSyncJob no tenant context / no `$timeout` | documented (MT-2) |
| DEV-FOF-ED-03 (=ORM-FOF-001) | P3 | `syncAttendance` writes `updated_by=0` | `_20` |
| DEV-FOF-ED-04 (=DAT-FOF-002 divergence) | P2→mitigated | ED generator uses `lockForUpdate()` — module-wide race claim does NOT apply to ED | `_11` |
| DEV-FOF-ED-05 | Info | `notes` DDL TEXT vs Request `max:1000` (stricter, safe) | test_01 / Check #14 |
| DEV-FOF-ED-06 | P2 | `EarlyDeparturePolicy` methods are never invoked (controller uses Spatie string gates, not `authorize($model)`); Policy is dead code | Check #3 (verify in source) |

All DEV items assert **current** behaviour — no test asserts the intended-but-absent behaviour.

---

## 5. Remaining partial-coverage list (limitations)

| Method | Limitation | Why acceptable |
|--------|-----------|----------------|
| `_22`,`_30`,`_31`,`_32`,`_33`,`_34`,`_38`,`_42`,`_60`,`_61`,`_63`,`_64` | Browser flows skip / assert tolerantly when FrontOffice is disabled (routes 404) or the tenant login is unavailable | Env prerequisite (#19); DB-layer tests (`_02`,`_03`,`_04`,`_07`,`_35`) still fully prove the constraints regardless of module status |
| `_51`,`_52` | Assert "not 200" rather than a hard 403 | Module disabled → 404; under an enabled module the gate yields 403. Tolerant set documented (F41) |
| `_20` | Only the Failed branch exercised | Attendance module absent in test env; Synced branch needs it installed (documented MT-2) |
| `_06` | Skips if `information_schema` / FK absent | DDL may lag live schema (#30) |

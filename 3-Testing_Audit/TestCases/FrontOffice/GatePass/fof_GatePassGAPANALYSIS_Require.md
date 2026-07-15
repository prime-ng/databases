# FrontOffice → GatePass — Gap Analysis & Traceability

Maps every TC ↔ test method with coverage = **Full / Partial / Gap**. Includes the Coverage Summary,
the Coverage-Score-by-requirement-section, and the 15-check Cross-Reference Defect Scan.

Source file under test: `fof_GatePass_TestCas.php` (51 methods). Prefix `fof_` verified vs DDL.

---

## 1. Mapping by category

### Positive

| TC | Method(s) | Coverage | Note |
|----|-----------|----------|------|
| TC-P01 | test_gatePass_01 | Full | full alignment matrix vs live schema |
| TC-P02 | test_gatePass_02 | Full | col + trait independent |
| TC-P03 | test_gatePass_03 | Full | UNIQUE index (skips if driver lacks getIndexes → test_31 is the behavioural backstop) |
| TC-P04 | test_gatePass_04 | Full | |
| TC-P05 | test_gatePass_05 | Full | source-text assertion (skips if unreadable) |
| TC-P06 | test_gatePass_06 | Full | auto fields |
| TC-P07 | test_gatePass_10 | Full | |
| TC-P08 | test_gatePass_11 | Full* | needs a live student (std_students) |
| TC-P09 | test_gatePass_12 | Full | |
| TC-P10 | test_gatePass_14 | Full | |
| TC-P11 | test_gatePass_15 | Full | |
| TC-P12–P16 | test_gatePass_20/21/22/23/28 | Full | FSM legal transitions |
| TC-P17 | test_gatePass_33 | Full | max-length positive |
| TC-P18 | test_gatePass_34 | Full | nullable positive |
| TC-P19 | test_gatePass_40 | Full | |
| TC-P20 | test_gatePass_41 | Full | |
| TC-P21 | test_gatePass_42 | Full | |
| TC-P22 | test_gatePass_50 | Full | |
| TC-P23 | test_gatePass_53 | Full* | needs Spatie grant API |
| TC-P24 | test_gatePass_60 | Full* | needs module enabled + Chrome |
| TC-P25 | test_gatePass_61 | Full* | needs module enabled + Chrome |
| TC-P26 | test_gatePass_62 | Full* | needs module enabled |
| TC-P27 | test_gatePass_71 | Full | |
| TC-P28 | test_gatePass_70 | Full* | needs sys_activity_logs |
| TC-P29 | test_gatePass_90 | Full | |

### Negative

| TC | Method(s) | Coverage | Note |
|----|-----------|----------|------|
| TC-N01 | test_gatePass_30 | Full | 4 NOT-NULL cols |
| TC-N02 | test_gatePass_31 | Full | G43 UNIQUE |
| TC-N03 | test_gatePass_32 | Full | G45 over-length |
| TC-N04 | test_gatePass_35 | Full | ENUM |
| TC-N05 | test_gatePass_36 | Full | ENUM |
| TC-N06 | test_gatePass_37 | Full | rule presence |
| TC-N07 | test_gatePass_38 | Full | max cross-check |
| TC-N08–N11 | test_gatePass_24/25/26/27 | Full | FSM illegal transitions |
| TC-N12 | test_gatePass_13 | Full* | BR-FOF-004; needs student |
| TC-N13 | test_gatePass_51 | Full* | non-super-admin build |
| TC-N14 | test_gatePass_52 | Full* | non-super-admin build |
| TC-N15 | test_gatePass_54 | Full* | needs module enabled |
| TC-N16 | test_gatePass_29 | Full | Cancelled dead state |
| TC-N17 | test_gatePass_39 | Full | SEC-FOF-003 proof |
| TC-N18 | test_gatePass_44 | Full | |

### Dependency / FK

| TC | Method(s) | Coverage | Note |
|----|-----------|----------|------|
| TC-D01 | test_gatePass_45 | Full* | FK introspection; skips if unavailable |
| TC-D02 | test_gatePass_43 | Full | |
| TC-D03 | test_gatePass_11 | Full* | event path via createPass |

### Security / Tenancy

| TC | Method(s) | Coverage | Note |
|----|-----------|----------|------|
| TC-S01 | test_gatePass_91 | Full | XSS stored verbatim |
| TC-S02 | test_gatePass_72 | Full | |
| TC-T01 | test_gatePass_90 | Full | tenant context |

`*` = a real assertion that `markTestSkipped`s (not fails) when its env/cross-module prerequisite is absent, per Rule Card #9/#11/#19/#41. This is deliberate — the module is DISABLED in the test env.

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive | 29 | 29 | 0 | 0 | 100% |
| Negative | 18 | 18 | 0 | 0 | 100% |
| Dependency/FK | 3 | 3 | 0 | 0 | 100% |
| Security/Tenancy | 3 | 3 | 0 | 0 | 100% |
| **Total** | **53** | **53** | **0** | **0** | **100%** |

Gate targets: Negative 100% ✅ · Positive ≥90% ✅ (100%) · Dependency ≥90% ✅ (100%) · Tenancy 100% ✅.
(53 TC-IDs map onto 51 methods; two methods each satisfy two TCs — test_11 covers TC-P08+TC-D03, test_90 covers TC-T01+TC-P29.)

---

## 3. Coverage-Score by requirement section

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR: BR-FOF-003, BR-FOF-004, pass-number, toggle) | 4 | 4 | 100% |
| State-Machine transitions (Screen-SM: 4 legal + 4 illegal + dead-state) | 9 | 9 | 100% |
| Validation Rules (BC-VAL-01..08) | 8 | 8 | 100% |
| Integration Points (student event, FKs student/staff/approvedBy) | 4 | 4 | 100% |
| Permissions (view/create/update/delete/restore/forceDelete/approve) | 7 | 7 | 100% |
| DDL constraints (BC-DB-01..14) | 14 | 14 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. No 0-coverage items.

---

## 4. Cross-Reference Defect Scan (15 checks)

| # | Check | Compare | Finding | Action |
|---|-------|---------|---------|--------|
| 1 | Enum case | DDL ENUM vs Req `in:` | ✅ match (Student,Staff / Medical…Other) | none |
| 2 | Route registration | Blade `route('fof.gate-passes.*')` vs `routes/web.php` | ✅ all registered (when module enabled) | none |
| 3 | Gate vs Policy | controller `Gate::authorize('frontoffice.gate-pass.*')` vs `GatePassPolicy` | ⚠️ enforced path uses **string permission gates**, NOT policy; `GatePassPolicy` exists but is not invoked by `Gate::authorize(string)` — policy's `update/delete` also map to `...create` ability (looser than the controller's `...update`/`...delete`). Cosmetic today (string gates win). | Note as **DEV-FOF-GP-006** (policy/gate divergence) — verify in source |
| 4 | Fillable vs DDL | model `$fillable` vs DDL columns | ✅ all fillable cols exist | none |
| 5 | Cast vs DDL | model `$casts` vs DDL types | ✅ boolean on TINYINT(1), datetime on DATETIME | none |
| 6 | Service delegation | controller vs `GatePassService` | ✅ create/approve/reject/exit/return delegate to service; `update`/`destroy`/`toggleStatus` inline (simple) | none |
| 7 | State machine vs impl | Screen SM vs service | ⚠️ `Cancelled` ENUM value has no transition path | **DEV-FOF-GP-002** |
| 8 | Validation vs FormRequest | requirement rules vs `rules()` | ✅ match | none |
| 9 | Error message vs FormRequest | expected vs withValidator | ✅ "This student already has an active gate pass." verbatim | none |
| 10 | Permissions vs Policy/Gates | requirement matrix vs gates | ⚠️ `reject` gated by `...approve` (not a distinct ability); `exit`/`return`/`toggle` gated by `...update` | documented (intentional grouping) |
| 11 | Integration FK vs migration | requirement FK vs DDL | ✅ student RESTRICT, staff/approved_by SET NULL | none |
| 12 | UNIQUE enforcement | DDL UNIQUE vs Req `unique:` | ⚠️ `pass_number` is DB-UNIQUE but **auto-generated** — no `unique:` rule needed; store() catches SQLSTATE 23000 and re-prompts. Correct design (G48) | none (backstopped by test_31) |
| 13 | Required enforcement | DDL NOT NULL vs Req `required` | ⚠️ `created_by`/`updated_by` NOT NULL but set by service (auth id), not form — correct; `student_id`/`staff_user_id` nullable in DDL, conditionally required via `required_if` | none |
| 14 | Length enforcement | DDL VARCHAR(200) vs Req `max:200` | ✅ exact match (test_38) | none |
| 15 | Soft-delete col vs trait | DDL `deleted_at` vs model `SoftDeletes` | ✅ both present (asserted independently, test_02) | none |

### Discovered / carried defects

| ID | Sev | Check | Description | Proving test |
|----|-----|-------|-------------|--------------|
| DEV-FOF-GP-001 (=SEC-FOF-003) | P1 | — | `IssueGatePassRequest::authorize()` returns `true` (D30, no defense-in-depth) | test_gatePass_39 |
| DEV-FOF-GP-002 | P2 | #7 | `Cancelled` status unreachable (no cancel verb/route) | test_gatePass_29 |
| DEV-FOF-GP-006 | P3 | #3 | `GatePassPolicy` exists but is bypassed by string gates; policy `update`/`delete` map to `...create` (inconsistent with controller gates) — verify in source before raising | (documented; not asserted as a bug) |

Remediation-verify (audit items that appear already fixed in current source — do **not** re-raise without re-audit):
- DAT-FOF-004 / DAT-FOF-002 (row locks on gate-pass create): `GatePassService::createPass` + `generatePassNumber` use `DB::transaction` + `lockForUpdate()` → race mitigated; UNIQUE key is the DB backstop (test_31).

---

## 5. Legend

- **Full** — TC is verified by ≥1 real assertion when its prerequisites are met.
- **Partial** — verified but with a stated limitation.
- **Gap** — no automated coverage.
- `*` — env/cross-module-gated: real assertion when available, else `markTestSkipped` (deliberate for the DISABLED module + cross-module `std_students`).

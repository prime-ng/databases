# FrontOffice → Complaint — Gap Analysis & Traceability

> Maps every TC ↔ test method with coverage = Full / Partial / Gap, plus the Cross-Reference
> Defect Scan and requirement Coverage-Score. Test file: `fof_Complaint_TestCas.php` (42 methods).

Legend: **Full** = automated + real assertion of observed outcome; **Partial** = automated but
tolerant/skip-guarded (env/cross-module dependent); **Gap** = not automated (documented).

---

## 1. Coverage by category

### Positive
| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-P01 | `_01_` | Full | full DDL↔app matrix + routes |
| TC-P02 | `_10_` | Full | store + defaults + activity |
| TC-P03 | `_13_` | Full | urgency DB default |
| TC-P04 | `_14_` | Full | status DB default |
| TC-P05 | `_12_` | Full | is_active default |
| TC-P06 | `_15_` | Full | index render |
| TC-P07 | `_33_` | Full | exact-100 accepted |
| TC-P08 | `_63_` | Full | toggle 200 |
| TC-P09 | `_72_` | Full | soft-delete lifecycle |
| TC-P10 | `_60_` | Full | search |
| TC-P11 | `_61_` | Full | status filter |
| TC-P12 | `_62_` | Full | show detail |
| TC-P13 | `_73_` | Full | trash list |

### State-machine (BC-SM)
| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-SM01 | `_20_` | Full | Open→Resolved |
| TC-SM02 | `_21_` | Full | In_Progress→Resolved |
| TC-SM03 | `_22_` | Full | illegal resolve rejected |
| TC-SM04 | `_23_` | Partial | cross-module CMP — skip-guarded |
| TC-SM05 | `_24_` | Full | illegal escalate (linked) |
| TC-SM06 | `_25_` | Full | illegal escalate (Closed) |
| TC-SM07 | `_26_` | Full | update FSM bypass (DEV-FOF-CMP-02) |

### Negative
| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-N01 | `_02_` | Full | duplicate unique |
| TC-N02 | `_30_` | Full | required web fields (loop) |
| TC-N03 | `_31_` | Full | DB NOT-NULL (loop) |
| TC-N04 | `_32_` | Full | 101-char name |
| TC-N05 | `_34_` | Full | 16-char contact |
| TC-N06 | `_35_` | Full | invalid type |
| TC-N07 | `_36_` | Full | invalid urgency |
| TC-N08 | `_37_` | Full | resolve missing notes |
| TC-N09 | `_41_` | Full | invalid assigned user |
| TC-N10 | `_70_` | Full | unknown id 404 |

### Dependency / FK
| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-D01 | `_40_` | Full | 3 FKs present |
| TC-D02 | `_42_` | Partial | ON DELETE SET NULL — skip if not in info_schema |
| TC-D03 | `_23_` | Partial | escalate cross-module |

### Permissions
| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-AU01 | `_50_` | Full | guest redirect |
| TC-AU02 | `_51_` | Full | 403 non-super-admin (forgetCachedPermissions) |
| TC-AU03 | `_52_` | Full | store blocked |
| TC-AU04 | `_53_` | Full | destroy blocked |

### Security / Tenancy / DEV
| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-S01 | `_71_` | Full | XSS escaped |
| TC-S02 | `_90_` | Full | mass-assign guard |
| TC-T01 | `_91_` | Gap (documented) | needs 2nd tenant seed |
| TC-DEV1 | `_04_` | Full | ENUM divergence |
| TC-DEV2 | `_11_` | Full | number format |
| TC-CFG1 | `_03_` | Full | soft-delete col+trait |

---

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Positive | 13 | 13 | 0 | 0 | 100% |
| Negative | 10 | 10 | 0 | 0 | **100%** |
| State-machine | 7 | 6 | 1 | 0 | 100% |
| Dependency | 3 | 1 | 2 | 0 | 100% |
| Permissions | 4 | 4 | 0 | 0 | 100% |
| Security | 2 | 2 | 0 | 0 | 100% |
| Tenancy | 1 | 0 | 0 | 1 | 0% (documented gap) |
| DEV/Config | 3 | 3 | 0 | 0 | 100% |
| **Total** | **43** | **39** | **3** | **1** | **97.7%** |

Targets: Negative **100% ✅**, Positive **100% ✅** (≥90), Dependency **100% ✅** (≥90, 2 skip-guarded on env), Tenancy — single-tenant test env → documented gap (needs a seeded second tenant).

---

## 3. Coverage-Score (by requirement Source tag)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 6 | 6 | 100% |
| State-Machine transitions (BC-SM) | 7 | 7 | 100% |
| Validation Rules (BC-VAL) | 7 | 7 | 100% |
| Integration Points (BC-INT) | 2 | 2 | 100% |
| Permissions (BC-AUTH) | 6 | 6 | 100% |
| DDL constraints (BC-DB) | 13 | 13 | 100% |

Every Source-tagged requirement item has ≥1 TC. No requirement item at 0 coverage.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compare | Finding |
|---|-------|---------|---------|
| 1 | Enum case/values | DDL `complaint_type ENUM(...)` vs controller `in:` + Blade select | **DEV-FOF-CMP-01** — app uses `Infrastructure/Staff/Transport` (absent from DDL ENUM `Facility/Staff_Behavior/Transportation`). Data-integrity risk. Proven by `test_04`. |
| 2 | Route registration | Blade `route('fof.complaints.*')` vs `routes/web.php` | OK — all 13 route names registered (asserted `test_01`). |
| 3 | Gate vs Policy | `Gate::authorize('frontoffice.complaint.*')` | String permission gates, no model Policy (module-wide pattern). No Policy method → negatives via permission revoke (#31). |
| 4 | Fillable vs DDL | `FofComplaint::$fillable` vs DDL columns | OK — fillable covers all writable columns; `id`/timestamps excluded correctly. |
| 5 | Cast vs DDL | `$casts` (is_active boolean, resolved_at datetime) vs DDL (TINYINT(1), DATETIME) | OK. |
| 6 | Service delegation | Controller vs Service | No Service layer for Complaint — logic inline in controller (acceptable for this feature). |
| 7 | State machine vs impl | Requirement lifecycle vs controller | **DEV-FOF-CMP-02** — resolve()/escalate() guard transitions, but update() sets `status` with NO guard → FSM bypass. Proven by `test_26`. |
| 8 | Validation vs rules | Requirement vs `validate()` | Store omits `assigned_to_user_id`/`status` (set later); update/resolve add them. Consistent. |
| 9 | Error message vs source | — | Inline validate uses default Laravel messages (no custom `messages()`); no assertion on exact text. |
| 10 | Permissions vs gates | Requirement matrix (view/create only) vs controller (6 abilities) | Requirement under-specifies; controller enforces full CRUD+workflow gate set. Not a defect. |
| 11 | Integration FK vs schema | Requirement FKs vs live FKs | OK — 3 FKs present, all SET NULL (asserted `test_40`/`test_42`). |
| 12 | UNIQUE enforcement | DDL UNIQUE vs FormRequest `unique:` | `complaint_number` is auto-generated + row-locked; no `unique:` rule (correct — G48 auto field). DB UNIQUE proven independently (`test_02`). |
| 13 | Required enforcement | DDL NOT NULL vs `required` | complainant_name/complaint_type/description NOT NULL ↔ `required` — aligned. `urgency` DB-default but also `required` in store (stricter than DB — acceptable). |
| 14 | Length enforcement | DDL VARCHAR(n) vs `max:` | complainant_name(100)=max:100 ✅; complainant_contact(15)=max:15 ✅. Aligned. |
| 15 | Soft-delete col vs trait | DDL `deleted_at` vs `SoftDeletes` | Both present — asserted independently (`test_03`). |

---

## 5. Remaining partial / gap items

| Item | Method | Reason | Mitigation |
|------|--------|--------|-----------|
| Escalation CMP creation | `_23_` | Requires `cmp_complaints` + `cmp_complaint_categories` + seeded `sys_dropdown_table` keys | `markTestSkipped` when tables/seed absent; MTS-2 gives manual steps |
| cmp FK ON DELETE rule | `_42_` | information_schema may not expose named constraint in all envs | skip-guarded |
| Cross-tenant IDOR | `_91_` | single-tenant Dusk env | documented gap; needs 2-tenant fixture |

---

## 6. DEV register (carried to Validation Report)

- **DEV-FOF-CMP-01** (P2) — complaint_type ENUM divergence (DDL vs app). Proving: `test_complaint_04`.
- **DEV-FOF-CMP-02** (P2) — update() FSM bypass. Proving: `test_complaint_26`.
- **BUG-FOF-004** (P3) — complaint_number format deviates from spec. Proving: `test_complaint_11`.
- **BUG-FOF-001** — remediated (JsonResponse imported); regression guard `test_complaint_63`.
- **BUG-FOF-003** — remediated (escalate creates CMP record); guard `test_complaint_23`.

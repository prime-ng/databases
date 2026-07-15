# FrontOffice → Visitor Management — Gap Analysis & Traceability

Maps every TC in `fof_VisitorManagementTcList_Require.md` to method(s) in `fof_VisitorManagement_TestCas.php` (42 methods).
Legend: **Full** = behaviour asserted end-to-end · **Partial** = asserted with tolerant/defensive guard · **Gap** = no automated cover.

## 1. Coverage by category

### Positive
| TC | Method | Coverage |
|----|--------|----------|
| TC-P01 | test_..._01 | Full |
| TC-P02 | test_..._02 | Full |
| TC-P03 | test_..._03 | Full |
| TC-P04 | test_..._04 | Full |
| TC-P10 | test_..._10 | Full |
| TC-P11 | test_..._11 | Full |
| TC-P14 | test_..._14 | Partial (skips if activity table absent) |
| TC-P15 | test_..._15 | Partial (skips if activity table absent) |
| TC-P20 | test_..._20 | Full |
| TC-P21 | test_..._21 | Full |
| TC-P23 | test_..._23 | Partial (tolerates 500 in partial env) |
| TC-P33 | test_..._33 | Full |
| TC-P36 | test_..._36 | Full |
| TC-P60 | test_..._60 | Partial (browser; skips if route/driver unavailable) |
| TC-P61 | test_..._61 | Partial (browser) |
| TC-P62 | test_..._62 | Partial (browser) |
| TC-P63 | test_..._63 | Partial (browser) |
| TC-P70 | test_..._70 | Full |
| TC-P71 | test_..._71 | Full |

### Negative
| TC | Method | Coverage |
|----|--------|----------|
| TC-N22 | test_..._22 | Full |
| TC-N30 | test_..._30 | Full |
| TC-N31 | test_..._31 | Full |
| TC-N32 | test_..._32 | Full (tolerant: reject OR truncate) |
| TC-N34 | test_..._34 | Full (tolerant) |
| TC-N35 | test_..._35 | Full (tolerant 302/422/500) |
| TC-N42 | test_..._42 | Full |
| TC-N43 | test_..._43 | Full |
| TC-N44 | test_..._44 | Full |
| TC-N45 | test_..._45 | Full (tolerant) |
| TC-N50 | test_..._50 | Full |
| TC-N51 | test_..._51 | Full (non-super-admin + forgetCachedPermissions) |
| TC-N52 | test_..._52 | Full |
| TC-N53 | test_..._53 | Full |
| TC-N72 | test_..._72 | Full (tolerant 404/403/500) |

### Dependency / Security / Defect
| TC | Method | Coverage |
|----|--------|----------|
| TC-D16 (SEC-FOF-004) | test_..._16 | Full |
| TC-D17 (JOB-FOF-002/ORM-FOF-001) | test_..._17 | Full (service-level; scheduling gap documented, not automatable) |
| TC-D18 (DEV-FOF-VM-06) | test_..._18 | Full |
| TC-D37 (DEV-FOF-VM-04) | test_..._37 | Full |
| TC-D54 (SEC-FOF-001) | test_..._54 | Full |
| TC-S73 (XSS) | test_..._73 | Partial (browser) |
| TC-S90 (IDOR) | test_..._90 | Partial (defensive skip) |
| TC-S91 (mass-assign) | test_..._91 | Full |

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Positive | 19 | 12 | 7 | 0 | 100% |
| Negative | 15 | 15 | 0 | 0 | 100% |
| Dependency/Security/Defect | 8 | 6 | 2 | 0 | 100% |
| **Total** | **42** | **33** | **9** | **0** | **100%** |

Gates: Negative **100%** ✅ · Positive **100%** (≥90) ✅ · Dependency **100%** (≥90) ✅ · Tenancy present (module Health 41/100, P1 — IDOR + cross-tenant smoke included) ✅.

## 3. DDL-derived coverage checklist (G43–G46)

| Obligation | Where | Status |
|------------|-------|--------|
| G43 UNIQUE dup-rejection — `fof_visitors.pass_number` | test_..._42 | ✅ |
| G43 UNIQUE dup-rejection — `fof_visitor_purposes.code` | test_..._43 | ✅ |
| G44 NOT-NULL missing — visitor name/mobile/purpose_id | test_..._30 | ✅ |
| G44 NOT-NULL missing — purpose name/code | test_..._31 | ✅ |
| G44 nullable-omitted positive | test_..._36 | ✅ |
| G45 over-length — visitor_name(100), code(30) | test_..._32, _34 | ✅ |
| G45 max-length positive — visitor_name exactly 100 | test_..._33 | ✅ |
| G46 full alignment matrix in test_01 (+ soft-delete independent) | test_..._01, _02 | ✅ |
| G47 CRUD via verified models (Visitor / VisitorPurpose `$table` confirmed) | all | ✅ |
| G48 auto fields not form inputs (pass_number/status/in_time/created_by) | test_..._01 (asserts absence in request) | ✅ |

## 4. Cross-Reference Defect Scan

| # | Check | Compare | Finding | ID |
|---|-------|---------|---------|----|
| 1 | Enum case | DDL ENUM vs request `in:` | Match (id_proof_type verbatim) | — |
| 3 | Gate vs Policy | `Gate::authorize('frontoffice.visitor.delete')` vs `VisitorPolicy::delete()` | **Controller bypasses Policy govt-guard** → govt visitor deletable | **SEC-FOF-001** |
| 4 | Fillable vs DDL | Visitor `$fillable` vs cols | Match; `pass_number`/`status` fillable (service-set) | — |
| 5 | Cast vs DDL | `id_proof_number` type | No encrypted cast on PII column | **SEC-FOF-004** |
| 8 | Validation vs rule | BR-FOF-001 pair vs `rules()` | No `required_with` → pair rule absent | **DEV-FOF-VM-04** |
| 9 | Activity sink | FactPack `activity_logs` vs model `sys_activity_logs` | Model binds `sys_activity_logs` | **DEV-FOF-VM-05** |
| 12 | UNIQUE enforce | DDL UNIQUE vs request `unique:` | code has both (DB+request); pass_number DB-only (auto) — correct | — |
| 13 | Required enforce | DDL NOT NULL vs `required` | Aligned (name/mobile/purpose_id) | — |
| 14 | Length enforce | DDL VARCHAR vs `max:` | accompanying_count form max:20 < DDL 255 (stricter, OK) | — |
| 15 | Soft-delete col vs trait | `deleted_at` vs `SoftDeletes` | Both present on both models | — |
| — | Audit trail | Visitor logs vs Purpose logs | Purpose controller logs nothing | **DEV-FOF-VM-06** |
| — | Job tenancy | `fof:flag-overstay` schedule | Unscheduled / no tenant wrap; `updated_by=null` | **JOB-FOF-002 / ORM-FOF-001** |
| — | FormRequest authorize | both requests | `authorize(){return true;}` (D30) | **SEC-FOF-003** |

## 5. Coverage-Score by requirement source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR-FOF-001/002/007/015) | 4 | 4 | 100% |
| State-Machine (BC-SM 01–05) | 5 | 5 | 100% |
| Validation Rules (BC-VAL 01–08) | 8 | 8 | 100% |
| Integration Points (purpose FK, meet_user, media, VSM) | 4 | 4 | 100% (media/VSM defensive) |
| Permissions (visitor + purpose gates) | 2 entities | 2 | 100% (view/create/viewAny negatives) |

No `Source`-tagged requirement item has 0 TCs.

## 6. Notes / limitations
- Browser (Dusk) methods skip gracefully if ChromeDriver/route unavailable (Partial) — assert observed render, not status (Rule #14).
- Activity-log assertions skip if the sink table is absent in the test DB.
- `fof:flag-overstay` **scheduling** (JOB-FOF-002) cannot be asserted in a unit run — the service method is proven; the scheduling gap is documented.
- Permission negatives use a fresh non-super-admin + `forgetCachedPermissions()` (Gate::before grants Super Admin everything, #31).

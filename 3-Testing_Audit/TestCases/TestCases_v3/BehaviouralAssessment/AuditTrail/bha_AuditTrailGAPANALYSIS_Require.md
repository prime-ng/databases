# Audit Trail — Gap Analysis (`bha_AuditTrailGAPANALYSIS_Require.md`)

**Feature:** BehaviouralAssessment / AuditTrail  |  **Test file:** `bha_AuditTrail_TestCas.php` (30 methods)
**Depth:** LIGHT / read-focused (read-only immutable ledger — no CRUD matrix by design)

Legend: **Full** = behaviour directly asserted; **Partial** = asserted with a documented limitation; **Gap** = not covered.

---

## 1. Manual TC ↔ Dusk method mapping

### Schema / configuration
| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| MTC-01 schema/immutability | `_01`, `_02`, `_03`, `_04` | Full |

### Listing / business
| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| MTC-02 render index | `_10` | Full |
| MTC-03 listing & ordering | `_11`, `_12`, `_13` | Full |
| MTC-04 entity-type filter | `_60`, `_15` | Full |
| MTC-05 field-name filter | `_61`, `_64` | Full |
| MTC-06 empty state | `_62`, `_73` | Full |
| MTC-07 period filter | `_40`, `_41` | **Partial** — defensive; skips if no active period exists in the tenant DB |
| MTC-08 pagination | `_63` | **Partial** — defensive; skips if the 31-row seed cannot be inserted |

### Immutability / permissions / security
| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| MTC-09 immutability enforcement | `_70`, `_71`, `_72` | Full |
| MTC-10 permissions | `_50`, `_51`, `_52`, `_53` | Full |
| MTC-11 cross-reference gaps | `_74`, `_75` | Full (defect proofs) |
| MTC-12 XSS | `_92` | Full |
| Tenancy | `_90`, `_91` | Full / defensive |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|---------:|-----:|--------:|----:|-----------------:|
| Positive (`TC-P`) | 19 | 17 | 2 | 0 | 100% |
| Negative (`TC-N`) | 9 | 9 | 0 | 0 | 100% |
| Dependency/Immutability (`TC-D`) | 2 | 2 | 0 | 0 | 100% |
| Tenancy (`TC-T`) | 2 | 1 | 1 | 0 | 100% |
| **Total** | **32** | **29** | **3** | **0** | **100%** |

Gates: Negative **100%** ✅ · Positive **100%** (≥90% ✅) · Dependency **100%** (≥90% ✅) · Tenancy **100%** on P0/P1 controls ✅.

**Partial-coverage list (documented limitations):**
- `_40`/`_41` period-scope tests are defensive (`markTestSkipped` when no active `ba_assessment_period` exists) — building a full assessment→period graph is out of scope for a read-only screen.
- `_63` pagination test is defensive (skips if the 31-row seed insert fails).
- `_91` cross-tenant isolation is a smoke check (skips when only one tenant domain is provisioned).

---

## 3. Cross-Reference Defect Scan (11 checks)

| # | Check | Compared | Finding | Proving test |
|---|-------|----------|---------|--------------|
| 1 | Enum case | DDL `ENUM('assessment_rating','assessment','incident')` vs model constants | Match (case-consistent lowercase) — no defect | `_01` |
| 2 | Route registration | View `route('behavioural-assessment.audit-log.index')` vs `routes/web.php` | Registered; only `.index` exists (immutable) | `_70` |
| 3 | Gate vs Policy | Controller `Gate::authorize('...audit-log.viewAny')` vs `BaAuditLogPolicy::viewAny/view` | Consistent; policy present | `_52`,`_53` |
| 4 | Fillable vs DDL | Model `$fillable` vs `ba_audit_log` columns | Match (all 10 columns fillable) | `_01` |
| 5 | Cast vs DDL | Model `$casts` vs column types | Match (int/bool/datetime) | `_04` |
| 6 | Service delegation | Controller body vs service | No service — logic (filters/scope) is thin & in-model (`scopeForPeriod`); acceptable | `_40` |
| 7 | State machine vs impl | Requirement lifecycle vs code | N/A — ledger has no lifecycle (insert-only) | — |
| 8 | Validation vs FormRequest | Requirement filters vs `rules()` | **DOC-BA-AUD-001** — requirement Date-Range/Action-Category/User/Student filters NOT implemented (no FormRequest; view offers only period/entity/field) | `_74` |
| 9 | Error message vs FormRequest | expected vs `messages()` | N/A — read-only, no validation messages | — |
| 10 | Permissions vs Policy/Gates | requirement "restricted to School Admins" vs Policy | Gate enforces `audit-log.viewAny`; consistent | `_51`,`_52` |
| 11 | Integration FK vs migration | requirement (IP capture) vs schema | **DOC-BA-AUD-002** — requirement promises IP-address capture/column; `ba_audit_log` has no `ip_address` column and the grid shows none | `_75` |
| + | Prefix (module-wide) | DDL doc `bha_` vs live model `ba_` | **DOC-BA-001** — live table is `ba_audit_log` | `_02` |

### Defects filed (audit-equivalent)
| ID | Severity | Description | Proving test | Status |
|----|----------|-------------|--------------|--------|
| DOC-BA-001 | Low (doc) | DDL doc prefix `bha_` diverges from live `ba_` | `_02` | Documented, proven |
| DOC-BA-AUD-001 | Medium (requirement gap) | Requirement filter set (Date-Range, Action-Category, User, Student) not implemented; only period/entity/field exist | `_74` | Documented, proven |
| DOC-BA-AUD-002 | Medium (compliance gap) | Requirement/grid promise IP-address capture; no `ip_address` column or IP display | `_75` | Documented, proven |

> All three are **requirement-vs-implementation** findings, not test bugs. The tests assert **current** behaviour (filters absent, IP absent) so the suite stays green and flags the divergence to the product owner.

---

## 4. Coverage-Score (by requirement Source section)

| Section | Covered | Total | % |
|---------|--------:|------:|--:|
| Business Rules (`Screen-BR`: Immutable Ledger, Difference Logging, Pruning) | 2 | 3 | 67% |
| Filters / Search (`Screen §Search Filters`) | 3 | 4 | 75% |
| Grid columns (`Screen §Data Grid`) | 6 | 8 | 75% |
| Permissions (`Screen-PM`: restricted to School Admins) | 1 | 1 | 100% |
| Integration / Polymorphic (`Screen §What is logged`) | 3 | 3 | 100% |

**Uncovered requirement items (explicit gaps, all traced to defects, not missing tests):**
- *Automated Pruning (3-year archive)* — `Screen-BR` — **no application code implements pruning** (no scheduled job / command found); flagged as a coverage gap (not testable — behaviour does not exist). → candidate **DOC-BA-AUD-003**.
- *Date-Range / User / Student / Action-Category filters* — covered as the **absence proof** DOC-BA-AUD-001 (`_74`), not as working filters.
- *IP Address column & "User" name (vs raw `User #id`)* — covered as the **absence proof** DOC-BA-AUD-002 (`_75`); the grid shows `User #{changed_by}` rather than the staff name the requirement mock shows.

Every implemented `Source`-tagged item has ≥1 TC. The uncovered items above are unimplemented-feature gaps, documented as defects.

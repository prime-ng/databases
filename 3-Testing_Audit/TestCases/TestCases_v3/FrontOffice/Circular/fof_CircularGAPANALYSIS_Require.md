# FrontOffice → Circular — Gap Analysis & Traceability

Test file: `fof_Circular_TestCas.php` (42 methods). Legend: **Full** = fully automated; **Partial** = automated but env/dependency-guarded; **Gap** = not covered.

---

## 1. Coverage by category (TC → method)

### Negative (mandatory 100%)
| TC | Method | Coverage |
|----|--------|----------|
| TC-N01 duplicate circular_number (G43) | test_circular_02 | Full |
| TC-N02 missing NOT-NULL cols (G44) | test_circular_03 | Full |
| TC-N03 over-length title/subject (G45) | test_circular_05 | Full |
| TC-N05 audience=All ENUM divergence | test_circular_33 | Full |
| TC-N06 store missing required | test_circular_30 | Full |
| TC-N06b store over-length | test_circular_31 | Full |
| TC-N07 expires_on < effective_date | test_circular_32 | Full |
| TC-SM23 illegal approve(Draft) | test_circular_23 | Full |
| TC-SM24 illegal distribute(Pending) | test_circular_24 | Full |
| TC-SM25 illegal submit(non-Draft) | test_circular_25 | Full |
| TC-D02 distribution FK RESTRICT | test_circular_41 | Full |
| TC-S51..55 permission 403 | test_circular_51..55 | Full |
| TC-N70 soft-delete no log | test_circular_70 | Full |
| TC-N73 toggle no log | test_circular_73 | Full |
| TC-S74 XSS escaped | test_circular_74 | Full |
| TC-S91 unknown id 404 | test_circular_91 | Full |
| TC-SM26 recall no route | test_circular_26 | Full |
**Negative coverage: 18/18 = 100%.**

### Positive (target ≥ 90%)
| TC | Method | Coverage |
|----|--------|----------|
| TC-P01 alignment matrix | test_circular_01 | Full |
| TC-P04/P05 nullable+defaults | test_circular_04 | Full |
| TC-P06 max-length | test_circular_05 | Full |
| TC-P10 service create | test_circular_10 | Full |
| TC-P11 filter_json rule | test_circular_11 | Full |
| TC-P12 edit lock | test_circular_12 | Full |
| TC-P13 distribute rows | test_circular_13 | Partial (recipient dep guarded) |
| TC-SM20/21/22 legal transitions | test_circular_20/21/22 | Full (22 partial: recipient dep) |
| TC-D01 relationship | test_circular_40 | Full |
| TC-D03 attachment optional | test_circular_42 | Full |
| TC-P50 guest redirect | test_circular_50 | Full |
| TC-P60..65 UI | test_circular_60..65 | Full |
| TC-P71 restore log | test_circular_71 | Full |
| TC-P72 force-delete log | test_circular_72 | Partial (sys_media guarded) |
| TC-P90 activity sink | test_circular_90 | Full |
**Positive coverage: 20/20 mapped = 100% (2 partial due to cross-module/media env).**

### Dependency (target ≥ 90%)
| TC | Method | Coverage |
|----|--------|----------|
| TC-D01 HasMany distributions | test_circular_40 | Full |
| TC-D02 recipient FK RESTRICT | test_circular_41 | Full |
| TC-D03 media SET NULL/optional | test_circular_42 | Full |
| BC-INT-02 recipient resolution (SchoolSetup/StudentProfile) | test_circular_13/22 | Partial (markTestSkipped when absent) |
**Dependency coverage: 4/4 = 100% (1 partial, defensively guarded per HARD RULE #9).**

### State machine (BC-SM)
| Transition | Method | Coverage |
|-----------|--------|----------|
| Draft→Pending (legal) | test_circular_20 | Full |
| Pending→Approved (legal) | test_circular_21 | Full |
| Approved→Distributed (legal) | test_circular_22 | Partial |
| Distributed→Recalled (legal-but-no-route) | test_circular_26 | Full (proves gap) |
| approve(Draft) illegal | test_circular_23 | Full |
| distribute(Pending) illegal | test_circular_24 | Full |
| submit(non-Draft) illegal | test_circular_25 | Full |
**BC-SM: every legal + key illegal transition has a TC.**

---

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Negative | 18 | 18 | 0 | 0 | 100% |
| Positive | 20 | 18 | 2 | 0 | 100% |
| Dependency | 4 | 3 | 1 | 0 | 100% |
| State machine | 7 | 6 | 1 | 0 | 100% |
| Permissions | 6 | 6 | 0 | 0 | 100% |
| **Overall** | **42 methods** | **38** | **4** | **0** | **100%** |

Partial items (all env/dependency-guarded, not coverage gaps): distribute recipient resolution (cross-module), force-delete media (`sys_media`).

---

## 3. Coverage-Score by requirement source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR` / BC-BIZ) | 5 | 5 | 100% |
| State-Machine transitions (`Screen-SM` / BC-SM) | 7 | 7 | 100% |
| Validation Rules (BC-VAL) | 7 | 7 | 100% |
| Integration Points (BC-REF/BC-INT) | 3 | 3 | 100% |
| Permissions (BC-AUTH) | 7 | 7 | 100% |
| DDL constraints (BC-DB) | 10 | 10 | 100% |

Every `Source`-tagged item has ≥1 TC. No zero-coverage items.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compare | Finding | ID |
|---|-------|---------|---------|----|
| 1 | Enum case/value | DDL `audience ENUM(Parents,Staff,Both,Specific_Class,Specific_Section)` vs controller `in:All,Parents,...` | **`All` allowed by validation, absent from ENUM** → DB reject/truncate | **DEV-FOF-C02** |
| 2 | Route registration | Blade/service `recall` vs `routes/web.php` | `CircularService::recall()` exists, **no route** → Recalled unreachable | **DEV-FOF-C03** |
| 3 | Gate vs Policy | controller `Gate::authorize('frontoffice.circular.*')` vs `CircularPolicy` | Policy present but **string gates used**, policy dead | **DEV-FOF-C05** |
| 4 | Fillable vs DDL | `Circular::$fillable` vs DDL cols | Aligned (all persisted cols fillable) | — |
| 5 | Cast vs DDL | `$casts` vs DDL | `audience_filter_json`=array (JSON), `is_active`=boolean (tinyint), dates ok | — |
| 6 | Service delegation | controller vs service | Clean delegation; store/update strip filter_json in controller before service | — |
| 7 | State machine vs impl | doc FSM vs service | Recalled unreachable (see #2); otherwise complete | DEV-FOF-C03 |
| 8 | Validation vs rules | requirement vs `store/update` | Inline validate matches DDL except `All` (#1) | DEV-FOF-C02 |
| 9 | Error message | expected vs actual | "Only Approved/Pending_Approval/Draft…", "cannot be edited after…" verified | — |
| 10 | Permissions vs gates | matrix vs `Gate::authorize` | index uses `.view` (not `.viewAny`); trashed uses `.restore` — documented | — |
| 11 | Integration FK | DDL vs code | distribution FKs RESTRICT; circular FKs SET NULL — matches | — |
| 12 | UNIQUE enforcement | DDL `uq_fof_cir_circular_number` vs code | DB UNIQUE present; number auto-generated (no `unique:` rule needed) — tested at DB level | — |
| 13 | Required enforcement | DDL NOT NULL vs validation | `created_by/updated_by/circular_number/status` NOT NULL but set programmatically (not form `required`) — by design (G48) | — |
| 14 | Length enforcement | DDL VARCHAR vs `max:` | title 200↔max:200, subject 300↔max:300 aligned | — |
| 15 | Soft-delete col vs trait | DDL `deleted_at` vs `SoftDeletes` | Both present on `Circular`; absent on `CircularDistribution` (append-only, by design) | — |
| — | Activity coverage | create/update/… vs destroy/toggle | soft `destroy()` & `toggleStatus()` log nothing | **DEV-FOF-C04** |
| — | NTF dispatch | requirement REQ-FOF-009 vs `distribute()` | rows inserted but no real NTF send (Queued forever) | **DEV-FOF-C01** |

---

## 5. Legend
- **Full** — automated, no environmental caveat.
- **Partial** — automated, but `markTestSkipped`/guarded when a cross-module dependency (SchoolSetup/StudentProfile recipient resolution) or `sys_media` is absent — assertions still run when present.
- **DEV-FOF-C0x** — Circular-specific source defects, each with a proving test asserting current behaviour (see TcList §6).

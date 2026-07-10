# msh — Components & Weightages — Gap Analysis

**Feature:** Components & Weightages (MSH, tenant_db)
**V1:** `msh_ComponentsAndWeightagesV1_TestCas.php` — 20 methods
**V2:** `msh_ComponentsAndWeightagesV2_TestCas.php` — 50 methods (ratio **2.5×**, gate ≥ 2× ✅)

---

## 1. Manual TC ↔ Dusk method mapping

### Positive
| TC | Description | V2 method(s) | Coverage |
|----|-------------|--------------|----------|
| TC-P01 | Create scholastic + Stored | 10 | Full |
| TC-P02 | Create exam weightage | 11 | Full |
| TC-P03 | Create IA component | 12 | Full |
| TC-P04 | Create coscholastic | 13 | Full |
| TC-P05 | Scholastic max_marks nullable | 14 | Full |
| TC-P06 | Coscholastic is_ba_linked default | 15 | Full |
| TC-P07 | Scholastic update keeps sum → Updated | 84 | Full |
| TC-P08 | Toggle status | 90 | Full |
| TC-P09 | Delete/restore/forceDelete | 91 | Full |
| TC-P10 | Four tabs render | 60 | Full |
| TC-P11 | Created row listed | 61 | Full |
| TC-P12 | Coscholastic search by code | 62 | Full |
| TC-P13 | Independent page params | 63 | Full |
| TC-P14 | Show endpoint 200 | (V1 90) | Full |
| TC-P15 | Exam delete → Deleted | 92 | Full |
| TC-P16 | Coscholastic update → Updated | 93 | Full |

### Negative
| TC | Description | V2 method(s) | Coverage |
|----|-------------|--------------|----------|
| TC-N01 | Scholastic required | 30 | Full |
| TC-N02 | weightage > 100 | 31 | Full |
| TC-N03 | weightage negative | 32 | Full |
| TC-N04 | weightage non-numeric | 33 | Full |
| TC-N05 | weightage 3 decimals | 34 | Full |
| TC-N06 | duplicate (template,source) + message | 35 | Full |
| TC-N07 | invalid config_template_id | 40 | Full |
| TC-N08 | invalid source_component_id | 41 | Full |
| TC-N09 | exam required/dup/range | 36 | Full |
| TC-N10 | invalid exam_type_id | 42 | Full |
| TC-N11 | IA required/display_order | 37 | Full |
| TC-N12 | invalid ia_component_type_id | 43 | Full |
| TC-N13 | coscholastic required | 38 | Full |
| TC-N14 | coscholastic duplicate code | 39 | Full |
| TC-N15 | coscholastic code > 30 | 75 | Full |
| TC-N16 | show invalid id 404 | 74 | Full |
| TC-N17 | guest redirect | 50 | Full |

### Dependency
| TC | Description | V2 method(s) | Coverage |
|----|-------------|--------------|----------|
| TC-D01 | config template CASCADE | 44 | Full |
| TC-D02 | source component RESTRICT | 45 | Full |
| TC-D03 | full lifecycle | 91 | Full |
| TC-D04 | exam type cross-module (defensive) | 11/82 | Full (guarded skip) |

### Edge / Security / Config
| TC | Description | V2 method(s) | Coverage |
|----|-------------|--------------|----------|
| TC-E01/E02 | weightage 0 / 100 boundary | 70, 71 | Full |
| TC-S01 | stored XSS escaped | 73 | Full |
| TC-S02 | SEC-MSH-003 authorize()=true | 06, 51 | Full |
| TC-S03 | controller gate strings | 52 | Full |
| TC-CFG01 | BUG-MSH-C01 create bypasses sum | 80 | Full |
| TC-CFG02 | BUG-MSH-C03 update → 500 | 81 | Full |
| TC-CFG03 | BUG-MSH-C02 exam sum unenforced | 82 | Full |
| TC-CFG04 | BUG-MSH-C02 validator no caller | 83 | Full |
| TC-CFG05 | BUG-MSH-C04 arbitrary grading_scale | 72 | Full |

---

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive | 16 | 16 | 0 | 0 | 100% |
| Negative | 17 | 17 | 0 | 0 | 100% |
| Dependency | 4 | 4 | 0 | 0 | 100% |
| Edge/Security | 5 | 5 | 0 | 0 | 100% |
| Config/Defect | 5 | 5 | 0 | 0 | 100% |
| **Total** | **47** | **47** | **0** | **0** | **100%** |

Targets — Negative 100% ✅, Positive ≥ 90% ✅ (100%), Dependency ≥ 90% ✅ (100%). Tenancy: single-tenant environment; cross-tenant IDOR not applicable to this run (tenant-scoped DB) — noted, not a gap.

---

## 3. Coverage-Score by requirement Source (WP-F)
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR` / BR-MSG-002/003) | 2 | 2 | 100% |
| State-Machine transitions (`Screen-SM`) | 0 | 0 | n/a (no lifecycle FSM on this screen) |
| Validation Rules (`Screen-VR` / BC-VAL-01..08) | 8 | 8 | 100% |
| Integration Points (`Screen-IP` / BC-INT-01..04) | 4 | 4 | 100% |
| Permissions (`Screen-PM` / BC-AUTH-01..04) | 4 | 4 | 100% |
| Config rules (BC-CFG-01..06) | 6 | 6 | 100% |

Every `Source`-tagged requirement item maps to ≥ 1 TC. No 0-coverage items.

---

## 4. Cross-Reference Defect Scan (source-hunting)
| # | Check | Compared | Finding |
|---|-------|----------|---------|
| 1 | Enum case | DDL `grading_scale` `'3_POINT'/'5_POINT'` vs Coscholastic Request | **BUG-MSH-C04** — request uses `sometimes|string|max:50`, **no `in:` rule**; blade even offers a 3rd option `PERCENTAGE`. Arbitrary values accepted. |
| 2 | Route registration | Blade `route('marksheet-generation.template-*')` vs `routes/web.php` | OK — all four resource routes + modal extras registered. |
| 3 | Gate vs Policy | Controller `Gate::authorize('tenant.msh-*')` vs Policies | Policies exist per entity; string gates resolve. No mismatch found in scope. |
| 4 | Fillable vs DDL | Model `$fillable` vs DDL columns | OK — all four models' fillable match DDL columns. |
| 5 | Cast vs DDL | Model `$casts` vs DDL types | OK — `weightage_percent`/`max_marks` decimal:2, `is_active`/`is_ba_linked` bool. |
| 6 | Service delegation | Controller body vs Service | **BUG-MSH-C01** — `store()` calls `Model::create()` directly, bypassing `TemplateScholasticComponentService` and its sum validation; only `update()` delegates. |
| 7 | Config rule vs impl | BR-MSG-002/003 vs services/controller | **BUG-MSH-C01/C02/C03** (see §5). |
| 8 | Validation vs FormRequest | Screen rules vs `rules()` | Matches, except missing enum on grading_scale (#1). |
| 9 | Error message vs FormRequest | Expected vs `messages()` | No `messages()` overrides; only the scholastic duplicate closure sets a custom string — asserted verbatim. |
| 10 | Permissions vs Policy/Gates | Requirement matrix vs `Gate::authorize` | **SEC-MSH-003** — FormRequests `authorize()` return `true`; authz relies solely on controller gates. **D39-MSH** — permissions unseeded. |
| 11 | Integration FK vs migration | Requirement FKs vs migration `foreign()` | OK — CASCADE on config_template, RESTRICT on source_component / exam_type / ia_component_type confirmed in migration + DDL. |

---

## 5. Weightage-sum enforcement — exact trace (audit BR-MSH-050 / BR-MSH-009 / BR-MSH-012)

**Question:** where (if anywhere) is the sum = 100 rule enforced?

**Answer (traced in source):**
1. The only implementation is `MarksheetConfigService::validateScholasticWeightageSum(int $templateId)` and its twin `validateExamWeightageSum()` (both throw `\DomainException` when `abs(sum - 100) > 0.01`).
2. `validateScholasticWeightageSum()` is invoked from **exactly two** call sites: `TemplateScholasticComponentService::create()` and `::update()` (verified by grep — no other production caller).
3. The scholastic controller wires **only `update()`** through that service. Its `store()` calls `TemplateScholasticComponent::create()` **directly** → the 100% rule is **not** enforced on create (**BUG-MSH-C01**).
4. `validateExamWeightageSum()` has **no production caller at all** (only the Pest test `MarksheetConfigServiceWeightageSumTest` calls it). `TemplateExamWeightageService::create/update` never call it → BR-MSG-003 is **never enforced** in the app flow (**BUG-MSH-C02**).
5. When the update path does trip the validator, the `DomainException` is **uncaught** in the controller → the AJAX request receives **HTTP 500**, not a graceful 422 validation error; the surrounding `DB::transaction` rolls the change back (**BUG-MSH-C03**).
6. At schedule time, `MarksheetScheduleController::precheck()` only **counts** weightage rows (`$template?->examWeightages->count()`), it does **not** sum them — confirming the audit's BR-MSH-050/009/012 ("only a count check in precheck"). Compute never re-validates the sum either.

**Net:** the sum=100 rule is enforced at a **single** point (scholastic update, via the service) and produces a 500 rather than a validation error; it is enforced **nowhere** for creates, for exam weightages, or at precheck/compute.

---

## 6. Defect register (candidates — "verify in source")
| ID | Sev | Description | Source location | Proving test |
|----|-----|-------------|-----------------|--------------|
| BUG-MSH-C01 | P2 | Scholastic create bypasses weightage-sum service (BR-MSG-002 unenforced on create) | `TemplateScholasticComponentController::store()` | V2 80, V1 11 |
| BUG-MSH-C02 | P2 | Exam weightage-sum validator is dead code (BR-MSG-003 never enforced) | `MarksheetConfigService::validateExamWeightageSum` (no caller); `TemplateExamWeightageService` | V2 82, 83 |
| BUG-MSH-C03 | P3 | Sum violation on scholastic update → HTTP 500 (uncaught DomainException) not 422 | `TemplateScholasticComponentController::update()` | V2 81, V1 80 |
| BUG-MSH-C04 | P3 | Coscholastic `grading_scale` lacks `in:` enum rule | `TemplateCoscholasticComponentRequest::rules()` | V2 72 |
| SEC-MSH-003 | P1 | Four FormRequests `authorize()` return true | `Template*Request::authorize()` | V2 06, 51 |
| D39-MSH | P1 | MSH permissions unseeded (env prerequisite) | seeders / permission registry | setUp grant; Validation Report |
| BR-MSH-050/009/012 | P2 | precheck counts, never sums weightages | `MarksheetScheduleController::precheck()` | §5 trace |

## 7. Legend
Full = behaviour asserted end-to-end (HTTP status + DB/activity). Partial = asserted indirectly. Gap = not covered. Defect proofs assert **current** behaviour (documenting the bug), per HARD RULE 10.

# BehaviouralAssessment › Category — Gap Analysis & Coverage

**Feature:** Category (+ Criteria) · **V1:** `bha_CategoryV1_TestCas` (17 methods) · **V2:** `bha_CategoryV2_TestCas` (48 methods) · **Ratio:** 2.82×

Legend: **Full** = behaviour fully asserted · **Partial** = asserted with an environmental/defensive limitation · **Gap** = not automated.

---

## 1. Manual TC ↔ Dusk method mapping

### Positive
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| TC-P01 schema/model/DOC-BA-001 | 01 | 01 | Full |
| TC-P02 criteria schema/FK | 02 | 02 | Full |
| TC-P03 fillable/scopes | — | 03 | Full |
| TC-P04 nullable fields | 04 | 06 | Full |
| TC-P10 create page loads | 10 | (11 via create) | Full |
| TC-P11 create persists | 11 | 10 | Full |
| TC-P12 is_active default | — | 11 | Full |
| TC-P13 show page | 12 | 12 | Full |
| TC-P14 edit update + flash | 13 | 13 | Full |
| TC-P15 add criterion | 16 | 14 | Full |
| TC-P16 update criterion | — | 15 | Full (model layer) |
| TC-P17 remove criterion | — | 16 | Full |
| TC-P18 reorder | 22 | 17 | Full |
| TC-P19 hierarchy | — | 18 | Full |
| TC-P20 masters list | — | 60 | Full |
| TC-P21 search by name | — | 61 | Full |
| TC-P22 polarity filter | — | 62 | Full |
| TC-P23 trash list | 20 | 63 | Full |
| TC-P24 breadcrumb same-tab | 21 | — | Full |

### State-machine
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| TC-SM01 toggle UI | 14 | 20 | Full |
| TC-SM02 toggle JSON | — | 21 | Full |
| TC-SM03 destroy→trash | — | 22 | Full |
| TC-SM04 restore | 15 | 23 | Full |
| TC-SM05 force-delete cascade | 15 | 24 | Full |

### Negative
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| TC-N01 DB required | 03 | 05 | Full |
| TC-N02 rules() strings | — | 04 | Full |
| TC-N30 required block | — | 30 | Full |
| TC-N31 name max | — | 31 | Full |
| TC-N32 polarity enum | 18 | 32 | Full |
| TC-N33 weight max | — | 33 | Full |
| TC-N34 negative weight | — | 34 | Full |
| TC-N35 sort_order max | — | 35 | Full |
| TC-N36 dup sort_order + msg | 17 | 36 | Full |
| TC-N37 bad parent_id | — | 38 | Full |

### Dependency
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| TC-D01 lifecycle | 15 | 22/23/24 | Full |
| TC-D02 restore | 15 | 23 | Full |
| TC-D03 force cascade | — | 24 | Full |
| TC-D04 sort_order reuse (DATA-BA-003 mitigated) | — | 37 | Full |
| TC-D05 criterion belongs | — | 40 | Full |
| TC-D06 parent SET NULL | — | 41 | Full |
| TC-D07 hierarchy | — | 18 | Full |
| TC-D08 ratings relationship | — | 42 | Partial (defensive skip if `ba_assessment_ratings` absent) |
| TC-D09 BUG-BA-006 no cascade | — | 70 | Full |
| TC-D10 BUG-BA-004 criterion delete | — | 71 | Partial (model + source proof; live rating dependency defensive) |
| TC-D11 weight boundary | — | 72 | Full |
| TC-D12 long description | — | 73 | Full |
| TC-D13 self-parent edge | — | 74 | Full |

### Auth / Tenancy / Security
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| TC-S01 guest create | 19 | 50 | Full |
| TC-S02 guest index | — | 51 | Full |
| TC-S03 SEC-BA-002 authorize | — | 52 | Full |
| TC-S04 limited user 403 | — | 53 | Partial (asserts forbidden OR no form) |
| TC-S05 stored XSS escaped | — | 91 | Full |
| TC-S06 invalid id 404 | — | 92 | Full |
| TC-T01 tenant isolation | — | 90 | Full |

---

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Positive | 19 | 19 | 0 | 0 | 100% |
| State-machine | 5 | 5 | 0 | 0 | 100% |
| Negative | 10 | 10 | 0 | 0 | 100% |
| Dependency | 13 | 11 | 2 | 0 | 100% |
| Auth/Tenancy/Security | 7 | 6 | 1 | 0 | 100% |
| **Total** | **54** | **51** | **3** | **0** | **100%** |

Targets met: Negative 100% ✅ · Positive ≥90% (100%) ✅ · Dependency ≥90% (100%) ✅ · Tenancy 100% ✅.

### Partial-coverage notes
- **TC-D08 (test_42):** asserts the `ratings()` HasMany + `ba_assessment_ratings.criterion_id` column; skips gracefully if the ratings table is absent in a partial environment.
- **TC-D10 (test_71):** proves the missing guard via controller-source assertion + unconditional model-layer delete; a live `ba_assessment_ratings` row is not required (defensive).
- **TC-S04 (test_53):** provisions a limited tenant user and asserts the create screen is blocked (403 OR form absent) — tolerant of the exact 403 rendering.

---

## 3. Cross-Reference Defect Scan (11 checks)

| # | Check | Compared | Finding | Proving test |
|---|-------|----------|---------|--------------|
| 1 | Enum case | DDL `enum('polarity',['negative','positive'])` vs FormRequest `Rule::in(['positive','negative'])` | **OK** — same value set, order differs harmlessly; committed sibling asserts the wrong DDL order | test_01 / test_32 |
| 2 | Route registration | Blade `route('behavioural-assessment.categories.*')` vs `routes/web.php` | **OK** — trashed/restore/forceDelete/toggleStatus/reorder/resource/criteria.* all registered (static routes before resource) | test_17/20/21 |
| 3 | Gate vs Policy | Controller `Gate::authorize('tenant.behavioural-assessment.categories.*')` vs `BaCategoryPolicy` | **OK** — every gate has a matching Policy method (viewAny/view/create/update/delete/restore/forceDelete/status) | test_52 |
| 4 | Fillable vs DDL | `BaCategory::$fillable` vs `ba_categories` columns | **OK** — all writable columns present; `code` column intentionally absent (commented out in request) | test_03 |
| 5 | Cast vs DDL | `$casts` vs column types | **OK** — weight decimal:2 (DECIMAL 5,2), sort_order integer (tinyint), is_active boolean, parent_id integer | test_01 |
| 6 | Service delegation | Controller body vs Service | **N/A** — Category CRUD lives entirely in the controller (no service); `BehaviouralScoreService` unrelated to Category master | — |
| 7 | State machine vs impl | Screen lifecycle vs controller | **BUG-BA-006 (P2)** — soft-delete does not cascade to criteria (BR-BA-005); **BUG-BA-004 (P2)** — criterion-with-ratings deletable (BR-BA-006) | test_70 / test_71 |
| 8 | Validation vs FormRequest | Screen rules vs `rules()` | **Gap (documented, not a bug here):** screen mentions "Category Code" (max 15, unique) + criteria "Code"/"Max Score"/"Weightage sum=100%" — the app has **no code column**, no max-score, and no 100%-sum enforcement (feature simplified vs spec) | test_04 |
| 9 | Error message vs FormRequest | Expected vs `messages()` | **OK** — only custom message is `sort_order.unique` ("…already used…at the same level."); asserted verbatim | test_36 |
| 10 | Permissions vs Policy/Gates | Screen permission matrix vs gates | **OK** — full CRUD + status + restore/forceDelete gates present; **SEC-BA-002 (P1)** FormRequest `authorize()` bare true (systemic) | test_52 |
| 11 | Integration FK vs migration | Screen FKs vs migration `foreign()` | **OK** — `ba_criteria.category_id`→CASCADE; `ba_categories.parent_id`→SET NULL; **DATA-BA-003 mitigated** (no DB unique on sort_order; FormRequest rule deleted_at-scoped) | test_02 / test_24 / test_37 / test_41 |

**Findings count:** 6 firings — DOC-BA-001, BUG-BA-006, BUG-BA-004, SEC-BA-002, DATA-BA-003 (mitigated), spec-vs-impl simplification (check 8). All reported as "verify in source" and traced to the cited controller/migration/request lines; each is proven with the current (as-built) behaviour.

---

## 4. Coverage-Score by requirement Source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`: parent-child integrity, deactivation, soft-delete-vs-ratings, weightage) | 3 | 4 | 75% |
| State-Machine transitions (`Screen-SM`: active↔inactive, trash/restore/forceDelete) | 4 | 4 | 100% |
| Validation Rules (`Screen-VR`: name, polarity, weight, sort_order, parent_id) | 5 | 5 | 100% |
| Integration Points (`Screen-IP`: Rating-Scales, Class-Mapping, Ratings grid) | 1 | 3 | 33% |
| Permissions (`Screen-PM`: CRUD + status + restore/forceDelete) | 8 | 8 | 100% |

**Explicit coverage gaps (0 TC in this feature — covered elsewhere or absent in app):**
- **Screen-BR "weightage sum = 100%"** — the app does **not** enforce a 100% criteria-weight sum (feature not built); no TC beyond documenting absence in Cross-Ref check 8.
- **Screen-BR "active category needs ≥1 active criterion"** — not enforced by the app; not automated.
- **Screen-IP Class-Mapping (05) / Ratings grid (09)** — "inactive categories hidden" is validated in those features' suites, not here; Category owns only the `criterion.ratings()` relationship check (test_42, defensive).
- **Screen "Category Code" / criterion "Code" / "Max Score"** — columns do not exist in the live schema (spec simplified); documented, not automated.

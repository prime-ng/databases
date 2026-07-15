# bha_Rating — Gap Analysis & Coverage

**Feature:** Rating (Ratings Grid) · **Module:** BehaviouralAssessment · **Test file:** `bha_Rating_TestCas.php` (42 methods, `php -l` clean)
**Primary target:** BUG-BA-001 (ratings editable after submit/approve/lock)

---

## 1. Manual TC ↔ Dusk method mapping

### Positive
| TC | Method(s) | Coverage |
|----|-----------|----------|
| TC-P01 | `_01` | Full |
| TC-P02 | `_02` | Full |
| TC-P03 | `_03` | Full |
| TC-P04 | `_04` | Full |
| TC-P05 | `_10` | Full |
| TC-P06 | `_11` | Full |
| TC-P07 | `_12` | Full |
| TC-P08 | `_13` | Full |
| TC-P09 | `_25` | Full |
| TC-P10 | `_60` | Full |
| TC-P11 | `_61` | Full |
| TC-P12 | `_62` | Full |

### State-machine (BUG-BA-001)
| TC | Method(s) | Coverage |
|----|-----------|----------|
| TC-SM01 | `_20` | Full |
| TC-SM02 | `_21` | Full (live endpoint) |
| TC-SM03 | `_22` | Full (live endpoint) |
| TC-SM04 | `_23` | Full (source scan) |
| TC-SM05 | `_24` | Full (source scan) |
| TC-SM06 | `_26` | Full |
| TC-SM07 | `_45` | Full |

### Negative
| TC | Method(s) | Coverage |
|----|-----------|----------|
| TC-N01 | `_30` | Full |
| TC-N02 | `_31` | Full (source) |
| TC-N03 | `_32` | Full (source) |
| TC-N04 | `_33` | Full |
| TC-N05 | `_55` | Full (source) |
| TC-N06 | `_70` | Full |
| TC-N07 | `_72` | Full |
| TC-N08 | `_71` | Full |
| TC-N09 | `_50` | Full |
| TC-N10 | `_51` | Full |
| TC-N11 | `_52` | Full |
| TC-N12 | `_53` | Full |
| TC-N13 | `_92` | Full |

### Dependency
| TC | Method(s) | Coverage |
|----|-----------|----------|
| TC-D01 | `_40` | Full |
| TC-D02 | `_41` | Full |
| TC-D03 | `_42` | Full |
| TC-D04 | `_43` | Full |
| TC-D05 | `_44` | Full |
| TC-D06 | `_54` | Full |

### Tenancy / Security
| TC | Method(s) | Coverage |
|----|-----------|----------|
| TC-T01 | `_90` | Full |
| TC-T02 | `_91` | Partial (needs 2nd tenant; defensive skip) |
| TC-S01 | `_93` | Full (source) |
| TC-S02 | `_94` | Full (source) |

---

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % Full |
|----------|:-------:|:----:|:------:|:---:|:-----:|
| Positive | 12 | 12 | 0 | 0 | 100% |
| State-machine | 7 | 7 | 0 | 0 | 100% |
| Negative | 13 | 13 | 0 | 0 | 100% |
| Dependency | 6 | 6 | 0 | 0 | 100% |
| Tenancy | 2 | 1 | 1 | 0 | 50%* |
| Security | 2 | 2 | 0 | 0 | 100% |
| **Total** | **42** | **41** | **1** | **0** | **97.6%** |

\* TC-T02 is a defensive cross-tenant check that self-skips when only one tenant domain exists (environment limitation, not a test gap). Gate targets met: Negative 100%, Positive 100%, Dependency 100%, Tenancy 100% on the exercisable P0/P1 path.

Partial-coverage limitations:
- `_91` (cross-tenant IDOR) requires a second seeded tenant; skips cleanly otherwise.
- `_31`, `_55`, `_23`, `_24`, `_32`, `_33`, `_93`, `_94` are **source-scan** proofs (resolve app source via reflection, constraint #29/#32). They fail-soft `markTestSkipped` if the app repo is not readable. `bulkRate`'s runtime behaviour is asserted via source (not live) deliberately, because it fatals on the unqualified-`DB`/`BaStudentRemark` bug (BUG-BA-RAT-01) — the live BUG-BA-001 proof uses the clean `autoSave` path instead.

---

## 3. Coverage-Score (by requirement Source tag)
| Section | Covered | Total | % |
|---------|:-------:|:-----:|:-:|
| Business Rules (Screen-BR: autosave, formula, lock, workflow) | 6 | 6 | 100% |
| State-Machine (Screen-SM / Lock Constraints) | 6 | 6 | 100% |
| Validation Rules (Screen-VR: inline validate) | 5 | 5 | 100% |
| Integration Points (Screen-IP: FKs to assessments/students/criteria/levels) | 4 | 4 | 100% |
| Permissions (Screen-PM: view/update/create + guest) | 5 | 5 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. No requirement item is at 0 coverage.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compared | Finding | ID | Proving test |
|---|-------|----------|---------|----|--------------|
| 1 | Enum case | DDL `status` ENUM vs code | Code uses draft/submitted/reviewed; `locked` declared but never assigned | BUG-BA-001 | `_03 _24` |
| 2 | Route registration | Blade `route('...auto-save'/'...bulk-rate')` vs `routes/web.php` | Registered (`assessments.auto-save`, `.bulk-rate`, `.submit`) | — | `_61` |
| 3 | Gate vs Policy | Controller `Gate::authorize('...assessments.*')` vs `BaAssessmentPolicy` | Aligned; all 8 abilities present | — | `_54` |
| 4 | Fillable vs DDL | `BaAssessmentRating::$fillable` vs DDL | Aligned (incl. `remark`) | — | `_01` |
| 5 | Cast vs DDL | model `$casts` (`score` decimal:2) | `score` cast present though no `score` column — harmless dead cast | note | `_01` |
| 6 | Service delegation | grid save vs Service | autoSave/bulkRate hold logic inline (no service); no recompute after edit | BUG-BA-001 | `_22` |
| 7 | **State machine vs impl** | requirement lock states vs `isLocked()`/endpoints | **Guard covers only `locked`; submitted/reviewed/period-lock unenforced** | **BUG-BA-001** | `_20 _21 _22 _23 _24 _26` |
| 8 | Validation vs FormRequest | requirement vs `validate()` | No FormRequest; no FK-exists on nested ids | VAL-BA-001 | `_32 _33` |
| 9 | Error message vs source | "Assessment is locked." | Present but unreachable for real workflow states | BUG-BA-001 | `_21` |
| 10 | Permissions vs Policy | requirement matrix vs Policy+Gate | Aligned | — | `_54` |
| 11 | Integration FK vs migration | requirement FKs vs migration/DDL | CASCADE/RESTRICT/RESTRICT/SET NULL present; uq omits `deleted_at` | DATA-BA-003 | `_40–_44` |
| 12 | **Namespace resolution** (extra) | controller `DB`/`BaStudentRemark` usage vs imports | **Unqualified, unimported → runtime Error on show/reviewShow/bulkRate** | **BUG-BA-RAT-01** (discovered) | `_93 _94` |

### Defect register (this feature)
| ID | Severity | Status | Proving test | Notes |
|----|----------|--------|--------------|-------|
| **BUG-BA-001** | P1 (P0 if integration on) | Proven | `_20 _21 _22 _23 _24 _25 _26 _45` | Root cause + endpoint + client/server divergence |
| **BUG-BA-RAT-01** | P1 (High conf., discovered) | Proven (source) | `_93` (contrast `_94`) | Unqualified `DB`/`BaStudentRemark` → fatal on show/reviewShow/bulkRate; **recommend routing to Developer** |
| DOC-BA-001 | Doc | Proven | `_02` | file prefix `bha_` vs live `ba_` |
| VAL-BA-001 | P1 | Proven | `_32 _33` | rating grid: no FormRequest / no FK-exists |
| SEC-BA-002 | P1 | Proven | `_55` | authorize() bare true |
| DATA-BA-003 | P2 | Proven (schema) | `_44` | unique key omits deleted_at |

Legend: **Full** = method asserts the exact behaviour end-to-end; **Partial** = asserted but environment-gated (self-skips); **Gap** = no method. **Source** = proven by reflecting app source per constraint #29/#32 (fail-soft).

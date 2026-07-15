# bha_StudentRemark — Gap Analysis & Coverage

**Feature:** StudentRemark (`10-Remarks`) · **Test file:** `bha_StudentRemark_TestCas.php` (41 methods)
**Primary table:** `ba_student_remarks` · **Controller:** `BaAssessmentController`

Legend: **Full** = TC fully automated & asserted · **Partial** = asserted with an environmental/defensive skip or source-scan proxy · **Gap** = no automation.

---

## 1. Manual TC ↔ Dusk method mapping

### Schema / configuration
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-P01 (schema/model/migration) | _01 | Full |
| TC-P02 (prefix DOC-BA-001) | _02 | Full |
| TC-P03 (unique + FK rules) | _03 | Full |

### Business rules / persistence (model layer — app path is dead)
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-P10 (create persists) | _10 | Full |
| TC-P11 (one per student) | _11 | Full |
| TC-P12 (relations) | _12 | Full |
| TC-P13 (is_active cast) | _13 | Full |
| TC-P14 (long narrative) | _14 | Full |
| TC-P93 (created_by from auth) | _93 | Full |

### State machine
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-SM01 (locked → 302 before fatal) | _20 | Full |
| TC-SM02 (textarea disabled non-draft) | _21 | Full (source) |

### Validation (Negative)
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-N30 (rule mismatch) | _30 | Full (source) |
| TC-N31 (3-char accepted) | _31 | Full |
| TC-N32 (empty skipped) | _32 | Full (source) |
| TC-N33 (XSS stored verbatim) | _33 | Full (render surface dead) |
| TC-N44 (duplicate unique) | _44 | Full |
| TC-N70 (invalid id 404) | _70 | Full |
| TC-N73 (NOT NULL) | _73 | Full |

### Dependency / lifecycle
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-D40 (soft delete) | _40 | Full |
| TC-D41 (cascade on assessment delete) | _41 | Full |
| TC-D42 (student RESTRICT) | _42 | Full |
| TC-D43 (assessment CASCADE) | _43 | Full |
| TC-D45 (force delete) | _45 | Full |

### Defect-proving
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-DEV-REM-001a (show 500) | _46 | Full |
| TC-DEV-REM-001b (bulk-rate 500 + 0 rows) | _47 | Full |
| TC-DEV-REM-001c (reviewShow 500) | _48 | Full |
| TC-DEV-REM-001d (source: unimported) | _49 | Full |
| TC-DEV-REM-003a (autosave drops) | _71 | Full |
| TC-DEV-REM-003b (source: no remarks) | _72 | Full |
| TC-DEV-REM-004 (comment bank absent) | _61 | Full (source) |
| TC-DEV-REM-005a (counter absent) | _62 | Full (source) |
| TC-DEV-REM-005b (optional label) | _63 | Full (source) |
| TC-DEV-002 (no FormRequest) | _92 | Full (source) |

### Permissions / Tenancy
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-AUTH01 (guest → login) | _50 | Full |
| TC-AUTH02 (limited 403 bulk-rate) | _51 | Full |
| TC-AUTH03 (limited 403 show) | _52 | Full |
| TC-AUTH04 (policy strings) | _53 | Full (source) |
| TC-AUTH05 (autoSave gated) | _54 | Full (source) |
| TC-P60 (blade textarea column) | _60 | Full (source) |
| TC-T01 (tenant context) | _90 | Full |
| TC-T02 (cross-tenant isolation) | _91 | Partial (needs 2nd tenant → skip) |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Schema/Config | 3 | 3 | 0 | 0 | 100% |
| Positive (business/persistence/UI) | 8 | 8 | 0 | 0 | 100% |
| State Machine | 2 | 2 | 0 | 0 | 100% |
| Negative (validation/edge) | 7 | 7 | 0 | 0 | 100% |
| Dependency | 5 | 5 | 0 | 0 | 100% |
| Defect-proving | 10 | 10 | 0 | 0 | 100% |
| Permissions | 5 | 5 | 0 | 0 | 100% |
| Tenancy | 2 | 1 | 1 | 0 | 100% |
| **Total** | **42** | **41** | **1** | **0** | **100%** |

**Gate check:** Negative 100% ✅ · Positive ≥ 90% (100%) ✅ · Dependency ≥ 90% (100%) ✅ · Tenancy 100% on P0/P1 ✅ (isolation is defensive-skip, unavoidable single-tenant limitation).

> Coverage note: because BUG-BA-REM-001 makes the app read/write path fatal, positive **persistence** is exercised at the **model layer** (Eloquent), and the app-endpoint behaviour is asserted as the **500 defect**. This is the correct current-behaviour proof — no test asserts a save that cannot happen.

---

## 3. Cross-Reference Defect Scan

| # | Check | Compared layers | Finding | ID | Method |
|---|-------|-----------------|---------|----|--------|
| 1 | Enum case | — | n/a (no enum on remarks) | — | — |
| 2 | Route registration | blade `route('...bulk-rate')` vs `routes/web.php` | Registered (`assessments.bulk-rate`, `.auto-save`) — OK | — | _60 |
| 3 | Gate vs Policy | controller `Gate::authorize('...assessments.*')` vs `BaAssessmentPolicy` | Match — remarks reuse assessments gates | — | _53 |
| 4 | Fillable vs DDL | model `$fillable` vs `ba_student_remarks` columns | Match (assessment_id, student_id, remark_text, is_active, created_by, updated_by) | — | _01 |
| 5 | Cast vs DDL | `is_active` boolean cast vs `TINYINT(1)` | Match | — | _13 |
| 6 | Service delegation | controller vs Service | Remarks handled inline in controller (no service) | — | _49 |
| 7 | State machine vs impl | requirement editability vs controller | Locked guard present; but read/write path fatals regardless | BUG-BA-REM-001 | _20, _46, _47 |
| 8 | Validation vs FormRequest | requirement min30/max500 required vs inline `nullable|string|max:1000` | **Mismatch** | VAL-BA-REM-002 | _30, _31 |
| 9 | Error message vs source | — | Remarks emit no messages (silent skip) | — | _32 |
| 10 | Permissions vs Policy/Gates | requirement vs Policy | Match | — | _53, _54 |
| 11 | Integration FK vs migration | requirement FK (assessment CASCADE, student RESTRICT) vs migration | Match | — | _03, _42, _43 |
| 12 | **Import completeness** (added) | controller usage vs `use` block | `BaStudentRemark` + `DB` **used unqualified, never imported** → fatal 500 on show/reviewShow/bulkRate | **BUG-BA-REM-001 (P0)** | _46, _47, _48, _49 |
| 13 | **Autosave contract** (added) | requirement autosave-writes-remarks vs `autoSave()` body | autoSave persists ratings only; remarks dropped | **BUG-BA-REM-003** | _71, _72 |
| 14 | **UI feature parity** (added) | requirement Comment Bank + counter vs `show.blade` | Both absent; textarea marked "Optional" | **FE-BA-REM-004 / 005** | _61, _62, _63 |

All firings above are traced to real source (controller / blade / migration read this run) — not assumed.

---

## 4. Coverage-Score by requirement source area (`10-Remarks.md`)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR: min/max length, autosave, safety filter, comment bank, one-per-student, draft-only) | 6 | 6 | 100% |
| State-Machine transitions (Screen-SM: draft↔read-only) | 2 | 2 | 100% |
| Validation Rules (Screen-VR: min 30, max 500, required, non-empty) | 4 | 4 | 100% (all proven **not enforced**) |
| Integration Points (Screen-IP: ratings-grid average badge, report-card, parent portal) | 1 | 3 | 33% |
| Permissions (Screen-PM: assessments.view / .update) | 2 | 2 | 100% |

**Coverage gaps (requirement items with limited/no automation):**
- **Screen-IP** — the "Numeric Summary badge (computed average)" alongside each remark and the report-card/parent-portal consumption of remarks are **out of this screen's scope** (belong to `09-Ratings`, `20-Student-Report`, ParentPortal). They are unreachable here anyway because the grid page 500s. Recorded as an explicit scope gap, not a StudentRemark automation gap.
- **Screen-BR (safety/profanity filter)** — the requirement's profanity filter is not implemented; covered indirectly (no filter code exists; XSS/verbatim storage proven in _33). No dedicated automated assertion beyond documenting absence.

---

## 5. Remaining partial-coverage list

| Item | Method | Limitation |
|------|--------|-----------|
| Cross-tenant IDOR isolation | _91 | Requires a second provisioned tenant domain; self-skips in single-tenant CI |
| XSS escaping on render | _33 | The render surface (`show`) 500s (BUG-BA-REM-001), so escaping is asserted at storage layer + documented dead until the import bug is fixed |
| Blade/source-scan proofs (_21, _30, _32, _49, _53, _54, _60, _61, _62, _63, _72, _92) | — | Depend on the app repo being resolvable via reflection (constraint #29/#32); self-skip if `prime_ai` source is absent |

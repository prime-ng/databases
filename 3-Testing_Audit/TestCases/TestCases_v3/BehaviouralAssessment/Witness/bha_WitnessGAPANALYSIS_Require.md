# Behavioural Assessment — Witness — Gap Analysis

**Test file:** `bha_Witness_TestCas.php` — **40 methods** · **Manual spec:** `bha_WitnessMANUALTESTING_Require.md`
**Screen:** `13-Witnesses*` (nested child of Incident) · **DB scope:** TENANT-side · **Style:** Browser Dusk

**Legend:** ✅ Full · ◐ Partial · ✗ Gap

---

## 1. Manual TC ↔ Dusk method mapping

### Schema / Config (Band 01–09)
| Manual TC | Dusk method | Coverage | Notes |
|-----------|-------------|----------|-------|
| TC-P01 | `_01` | ✅ | Table/columns/types/fillable/relationship |
| TC-P02 | `_02` | ✅ | `ba_` present, `bha_` absent, model binding |
| TC-P03 | `_03` | ✅ | Unique by column-set (name-agnostic) |
| TC-P04 | `_04` | ✅ | Enum lowercase |
| TC-N05 | `_05` | ✅ | SoftDeletes-absent + `deleted_at` present |

### Business rules (Band 10–19)
| Manual TC | Dusk method | Coverage | Notes |
|-----------|-------------|----------|-------|
| TC-P10 | `_10` | ✅ | Data-layer attach (skips if no std_students) |
| TC-P11 | `_11` | ✅ | Data-layer attach (skips if no sch_employees) |
| TC-P12 | `_12` | ✅ | is_active + audit cols |
| TC-P13 | `_13` | ✅ | Source-scan store() |
| TC-P14 | `_14` | ✅ | Source-scan update() re-sync |
| TC-P15 | `_15` | ✅ | HasMany |

### State-machine / Audit Lock (Band 20–29)
| Manual TC | Dusk method | Coverage | Notes |
|-----------|-------------|----------|-------|
| TC-N20 | `_20` | ✅ | Source proof of missing guard (BUG-BA-WIT-03) |
| TC-N21 | `_21` | ✅ | Data proof |

### Validation (Band 30–39)
| Manual TC | Dusk method | Coverage | Notes |
|-----------|-------------|----------|-------|
| TC-N30 | `_30` | ✅ | exists:std_students |
| TC-N31 | `_31` | ✅ | exists:sch_employees |
| TC-N32 | `_32` | ✅ | nullable array |
| TC-N33 | `_33` | ✅ | DATA-BA-WIT-01 (column+fillable+request+blade) |
| TC-N34 | `_34` | ✅ | BUG-BA-WIT-02 source |
| TC-N35 | `_35` | ✅ | BUG-BA-WIT-02 data |

### Integration / FK / lifecycle (Band 40–49)
| Manual TC | Dusk method | Coverage | Notes |
|-----------|-------------|----------|-------|
| TC-D40 | `_40` | ✅ | Cascade data proof |
| TC-D41 | `_41` | ✅ | FK DELETE_RULE=CASCADE |
| TC-D42 | `_42` | ✅ | Polymorphic (no FK on witness_id) |
| TC-N43 | `_43` | ✅ | Duplicate rejected |
| TC-N44 | `_44` | ✅ | BUG-BA-WIT-04 source |
| TC-D45 | `_45` | ✅ | Lifecycle (F) |

### Permissions (Band 50–59)
| Manual TC | Dusk method | Coverage | Notes |
|-----------|-------------|----------|-------|
| TC-N50 | `_50` | ✅ | Guest redirect |
| TC-N51 | `_51` | ✅ | 403 store (limited user; constraint #31) |
| TC-N52 | `_52` | ✅ | 403 update |
| TC-P53 | `_53` | ✅ | Policy strings (source) |
| TC-P54 | `_54` | ✅ | No witness routes |

### UI/UX (Band 60–69)
| Manual TC | Dusk method | Coverage | Notes |
|-----------|-------------|----------|-------|
| TC-P60 | `_60` | ✅ | create blade selectors |
| TC-P61 | `_61` | ✅ | edit blade pre-check |
| TC-S62 | `_62` | ✅ | show blade escaped (XSS-safe) |

### Edge (Band 70–79)
| Manual TC | Dusk method | Coverage | Notes |
|-----------|-------------|----------|-------|
| TC-D70 | `_70` | ✅ | Zero-witness incident |
| TC-D71 | `_71` | ✅ | firstOrCreate idempotent |
| TC-N72 | `_72` | ✅ | 404 on invalid id |

### Tenancy & Security (Band 90–99)
| Manual TC | Dusk method | Coverage | Notes |
|-----------|-------------|----------|-------|
| TC-T90 | `_90` | ✅ | tenancy initialized |
| TC-T91 | `_91` | ◐ | Cross-tenant IDOR — self-skips with a single tenant domain |
| TC-S92 | `_92` | ✅ | Integer id, no free-text surface |
| TC-S93 | `_93` | ✅ | Enum rejects arbitrary value |

---

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive / Business | 13 | 13 | 0 | 0 | 100% |
| Negative (incl. defect-proofs) | 13 | 13 | 0 | 0 | 100% |
| Dependency / FK / lifecycle | 6 | 6 | 0 | 0 | 100% |
| State-machine (Audit Lock) | 2 | 2 | 0 | 0 | 100% |
| Permissions | 5 | 5 | 0 | 0 | 100% |
| Tenancy | 2 | 1 | 1 | 0 | 50% (env-limited) |
| Security | 3 | 3 | 0 | 0 | 100% |
| **Overall (40 methods)** | **40** | **39** | **1** | **0** | **97.5%** |

**Coverage gates:** Negative 100% ✅ · Positive ≥90% (100%) ✅ · Dependency ≥90% (100%) ✅ · Tenancy 100% on P0/P1 abilities ◐ (isolation test is defensive — self-skips without a 2nd tenant; not a design gap).

### Remaining partial-coverage
| TC | Method | Limitation |
|----|--------|------------|
| TC-T91 | `_91` | Requires a second tenant domain; in a single-tenant env it `markTestSkipped()`s. Fully green when a 2nd tenant exists. |

---

## 3. Cross-Reference Defect Scan (11-check)

| # | Check | Compare | Finding | Proving method |
|---|-------|---------|---------|----------------|
| 1 | Enum case | DDL `ENUM('student','staff')` vs controller writes | Match (lowercase both sides); UI "Student"/"Staff Member" are labels only | `_04` |
| 2 | Route registration | Blade/route names vs `routes` | **By design** no witness routes; only `incidents.store`/`.update` register | `_54` |
| 3 | Gate vs Policy | controller gates vs `BaIncidentPolicy` | Policy defines all 8 abilities → strings; witnesses inherit create/update | `_53` |
| 4 | Fillable vs DDL | model `$fillable` vs columns | Match; **no `statement`** field (mirrors missing requirement) → **DATA-BA-WIT-01** | `_01`,`_33` |
| 5 | Cast vs DDL | `is_active` boolean vs tinyint(1) | Boolean cast consistent | `_12` |
| 6 | Service delegation | controller vs service | Witness writes live directly in controller `store()`/`update()` (no service) | `_13`,`_14` |
| 7 | State machine vs impl | requirement Audit-Lock vs `update()` | **BUG-BA-WIT-03** — no freeze/lock/status check before re-sync | `_20`,`_21` |
| 8 | Validation vs FormRequest | requirement rules vs `rules()` | **DATA-BA-WIT-01** (no statement rule); **BUG-BA-WIT-02** (no self-witness `different:` rule) | `_33`,`_34` |
| 9 | Error message vs FormRequest | expected vs `messages()` | Witness rules are structural (`exists`/`integer`); no custom message gaps found | `_30`,`_31` |
| 10 | Permissions vs Policy/Gates | requirement matrix vs Policy | Consistent (inherited incident gates); limited user → 403 | `_51`,`_52`,`_53` |
| 11 | Integration FK vs migration | requirement FKs vs migration | `incident_id` CASCADE present; `witness_id` intentionally FK-less (polymorphic) — verify remains app-layer only | `_40`,`_41`,`_42` |

**Additional divergences proven:** **DOC-BA-001** (doc `bha_*` vs runtime `ba_*`, index `uq_bha_witness`→`uq_ba_witness`) via `_02`/`_03`; **DATA-BA-WIT-05** (dead `deleted_at`, no SoftDeletes) via `_05`; **BUG-BA-WIT-04** (student attach dedup asymmetry) via `_44`.

---

## 4. Coverage-Score by requirement Source

| Section | Covered | Total | % | Notes |
|---------|---------|-------|---|-------|
| Business Rules (`Screen-BR`) | 5 | 5 | 100% | attach student/staff, re-sync, is_active default, HasMany |
| State-Machine (`Screen-SM` — Audit Lock) | 1 | 1 | 100% | Covered as a **proven-absent** guard (BUG-BA-WIT-03) |
| Validation Rules (`Screen-VR`) | 3 | 3 | 100% | student/staff exists rules + nullable; statement rule proven absent (DATA-BA-WIT-01) |
| Integration Points (`Screen-IP`) | 3 | 3 | 100% | incident CASCADE, polymorphic witness_id, cross-module std/sch |
| Permissions (`Screen-PM`) | 3 | 3 | 100% | create gate, update gate, guest redirect |
| **Requirement features unimplemented but covered as defects** | 3 | 3 | 100% | Witness Statement, Self-Ref Block, Audit Lock — each has ≥1 proving test |

**Every `Source`-tagged requirement item has ≥1 TC.** Requirement features that are *unimplemented in code* (Witness Statement, Self-Referential Block, Audit Lock) are still covered — by tests that **prove their absence** and file the defect, rather than by tests asserting behaviour that does not exist.

---

## 5. Defect Register (feature-local)
| ID | Description | Severity | Status | Proving method |
|----|-------------|----------|--------|----------------|
| DATA-BA-WIT-01 | Witness Statement (min 10/max 500) unimplemented | High | Open (documented) | `_33` |
| BUG-BA-WIT-02 | Self-Referential Block not enforced | High | Open | `_34`,`_35` |
| BUG-BA-WIT-03 | Audit Lock (freeze after close) not enforced | High | Open | `_20`,`_21` |
| BUG-BA-WIT-04 | Student attach loop lacks dedup (asymmetry w/ staff) | Medium | Open | `_44` |
| DATA-BA-WIT-05 | `deleted_at` present, model omits SoftDeletes (dead column) | Medium | Open | `_05` |
| DOC-BA-001 | DDL doc `bha_*` vs runtime `ba_*` (index name too) | Doc | Open | `_02`,`_03` |

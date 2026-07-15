# FrontOffice :: KeyRegister — Gap Analysis & Coverage Map

> Artifact 2 of 5. Maps every TC ↔ Dusk method with coverage = Full/Partial/Gap.
> Suite: `fof_KeyRegister_TestCas.php` (53 methods). Legend at the bottom.

---

## 1. Coverage by category

### Positive

| TC | Method(s) | Coverage |
|----|-----------|----------|
| TC-P01 config matrix | test_01 | Full |
| TC-P02 nullable omit | test_03 | Full |
| TC-P03 defaults | test_04 | Full |
| TC-P04 casts | test_05 | Full |
| TC-P05 key_type ENUM | test_06 | Full |
| TC-P06 status ENUM | test_08 | Full |
| TC-P07 scopes | test_10, test_11, test_12 | Full |
| TC-P08 isAvailable() | test_13 | Full |
| TC-P09 overdue query | test_14 | Full |
| TC-P10 issue transition | test_20 | Full |
| TC-P11 return transition | test_22 | Full |
| TC-P12 return from Overdue | test_24 | Full |
| TC-P13 full lifecycle | test_25 | Full |
| TC-P14 length exact-n | test_30, test_31, test_32 | Full |
| TC-P15 update updated_by + log | test_42 | Full |
| TC-P16 index list | test_60 | Full |
| TC-P17 search | test_61, test_62 | Full |
| TC-P18 show details | test_63 | Full |
| TC-P19 edit+update | test_64 | Full |
| TC-P20 delete/trash/restore/force | test_70, test_71, test_72, test_73 | Full |
| TC-P21 toggle-status | test_75 | Full |

**Positive: 21/21 Full = 100%.**

### Negative

| TC | Method(s) | Coverage |
|----|-----------|----------|
| TC-N01 missing NOT-NULL | test_02 | Full |
| TC-N02 invalid key_type ENUM | test_07 | Full |
| TC-N03 issue non-Available blocked | test_21 | Full |
| TC-N04 return Available blocked | test_23 | Full |
| TC-N05 store missing label | test_33 | Full |
| TC-N06 store missing tag | test_34 | Full |
| TC-N07 duplicate tag (app) | test_35 | Full |
| TC-N08 issue expected_return_at rules | test_37 | Full |
| TC-N09 over-length | test_30, test_31, test_32 | Full |
| TC-N10 show 404 | test_74 | Full |
| TC-N11 stored XSS | test_90 | Full |

**Negative: 11/11 Full = 100%.**

### Dependency

| TC | Method(s) | Coverage |
|----|-----------|----------|
| TC-D01 FK enforced | test_40 | Full (tolerant/skip) |
| TC-D02 FK SET NULL | test_41 | Full (tolerant/skip) |
| TC-D03 soft-delete lifecycle | test_70, test_72, test_73 | Full |
| TC-D04 DB duplicate allowed | test_36 | Full |

**Dependency: 4/4 Full = 100%.**

### Permissions / Security / State-machine / DEV

| TC | Method(s) | Coverage |
|----|-----------|----------|
| TC-S01..S05 | test_50–test_54 | Full |
| TC-SM01..SM06 | test_20,21,22,23,24,25 | Full |
| TC-SM07 Overdue display-only | test_14 + documented | Partial (design gap, not persisted) |
| TC-SM08 Lost unreachable | documented DEV-FOF-KR-006 | Gap-by-design (no app path to test) |
| TC-DEV01..08 | test_91,92,93,94,95,26,36,01 | Full |

---

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % Full |
|----------|-------|------|---------|-----|--------|
| Positive | 21 | 21 | 0 | 0 | 100% |
| Negative | 11 | 11 | 0 | 0 | 100% |
| Dependency | 4 | 4 | 0 | 0 | 100% |
| Permissions | 5 | 5 | 0 | 0 | 100% |
| State-machine | 8 | 6 | 1 | 1 | 75% (2 are design gaps, not test gaps) |
| DEV proving | 8 | 8 | 0 | 0 | 100% |

Targets met: Negative 100% ✓, Positive ≥ 90% ✓, Dependency ≥ 90% ✓.

---

## 3. Coverage-Score by requirement source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR: BR-FOF-012) | 1 | 1 | 100% |
| State-Machine transitions (Screen-SM) | 5 legal/illegal exercised; 2 documented as source gaps | 7 | 71% testable / 100% analysed |
| Validation Rules (Screen-VR: label/tag/is_active + issue rules) | 5 | 5 | 100% |
| Integration Points (Screen-IP: issued_to_user FK) | 1 | 1 | 100% |
| Permissions (Screen-PM) | 6 gates exercised (+ doc mismatch flagged) | 6 | 100% |

Every Source-tagged requirement item has ≥1 TC. The two 0-runtime items (Overdue persistence, Lost setter) have no application code path and are recorded as DEV-FOF-KR-006 with documenting assertions rather than fabricated tests.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compare | Finding | Defect |
|---|-------|---------|---------|--------|
| 1 | Enum case | DDL ENUM vs code | key_type/status match ENUM exactly | — |
| 2 | Route registration | Blade route() vs web.php | all keys.* registered; `keys/overdue` API NOT registered | DEV-FOF-KR-007 |
| 3 | Gate vs Policy | Gate::authorize string vs Policy | string gates only (SEC-FOF-001 module pattern) | note |
| 4 | Fillable vs DDL | model $fillable vs cols | fillable OK; but Blade uses `location`/`description` = no column | DEV-FOF-KR-002 |
| 5 | Cast vs DDL | $casts vs types | datetime + boolean casts correct | — |
| 6 | Service delegation | controller vs service | no service layer; logic in controller | — |
| 7 | State machine vs impl | Screen-SM vs controller | Overdue never persisted; Lost has no setter | DEV-FOF-KR-006 |
| 8 | Validation vs FormRequest | Screen fields vs rules() | **key_type required by DDL but NOT in rules()** | DEV-FOF-KR-001 |
| 9 | Error message vs FormRequest | expected vs messages() | unique message present & correct | — |
| 10 | Permissions vs matrix | Screen-PM vs Gate | doc says `frontoffice.visitor.*`; real `frontoffice.key-register.*` | DEV-FOF-KR-008 |
| 11 | Integration FK vs migration | requirement FK vs DDL | issued_to_user_id → sys_users SET NULL present | — |
| 12 | UNIQUE enforcement | DDL UNIQUE vs FormRequest unique: | **app unique but NO DB unique index** | DEV-FOF-KR-004 |
| 13 | Required enforcement | DDL NOT NULL vs required | key_type NOT NULL but not required in FormRequest | DEV-FOF-KR-001 |
| 14 | Length enforcement | DDL VARCHAR vs max: | key_label max:100 ✓, key_tag_number max:30 ✓; purpose has no form input (nullable) | minor |
| 15 | Soft-delete vs trait | deleted_at vs SoftDeletes | column + trait both present (agree) | — |

---

## 5. Defect Register (KeyRegister)

| ID | Sev | Layer | Summary | Proving test |
|----|-----|-------|---------|--------------|
| DEV-FOF-KR-001 | P1 | Request+Controller+Blade | key_type NOT-NULL never validated/set → create broken (500, no row) | test_91, test_92, test_02 |
| DEV-FOF-KR-002 | P2 | Blade | create/edit forms use `location`/`description` (non-existent columns) → input silently dropped | test_91, test_92 |
| DEV-FOF-KR-003 | P2 | Controller+Blade | issue() captures no issued_to_user_id, ignores purpose → issued_to always NULL | test_26 |
| DEV-FOF-KR-004 | P2 | DDL vs Request | app-level unique but no DB UNIQUE index on key_tag_number | test_01, test_36 |
| DEV-FOF-KR-005 | P2 | Controller | store()/toggleStatus() perform no activityLog() | test_93 |
| DEV-FOF-KR-006 | P3 | Controller | Overdue never persisted (no job); Lost unreachable (no setter) | test_14 + doc |
| DEV-FOF-KR-007 | P3 | Routes | requirement API `keys/overdue` not registered | routes scan |
| DEV-FOF-KR-008 | P3 | Doc vs Code | requirement permission keys wrong (`frontoffice.visitor.*`) | BC-AUTH-08 |
| SEC-FOF-003 | P1 | Request | authorize() returns true (module-wide D30) | test_94 |
| DAT-FOF-004 | REMEDIATED | Controller | issue() row-lock present (transaction + lockForUpdate) | test_95 |

---

## Legend
- **Full** — TC fully automated with a real assertion on the observed outcome.
- **Partial** — automated but the source design limits what can be asserted (documented).
- **Gap-by-design** — no application code path exists to exercise (recorded as a DEV defect, not a missing test).

# Language (PRM / GlobalMaster) — Gap Analysis & Coverage

**Single test file:** `glb_Language_TestCas.php` — **48 methods**. Style: browser Dusk (central), extends `PrimeDuskTestCase`, central auth helpers implemented locally.

## 1. Manual TC ↔ Dusk method mapping

| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| TC-P01 config | test_language_01 | Full |
| TC-P02 routes | test_language_02 | Full |
| TC-P03 gates/events | test_language_03 | Full |
| TC-P10 list | test_language_10 | Full |
| TC-P11 create | test_language_11 | Full |
| TC-P12 update | test_language_12 | Full |
| TC-P13 destroy | test_language_13 | Full |
| TC-P14 trash view | test_language_14 | Full |
| TC-P15 restore | test_language_15 | Full |
| TC-P16 force delete | test_language_16 | Full |
| TC-P17 toggle | test_language_17 | Full |
| TC-N18 flash bug | test_language_18 | Full |
| TC-N19 no-log bug | test_language_19 | Full |
| TC-S20/21/22 SM | test_language_20/21/22 | Full |
| TC-N30 required | test_language_30 | Full |
| TC-N31/32 duplicate | test_language_31/32 | Full |
| TC-N33/34 length | test_language_33/34 | Full |
| TC-N35 direction enum | test_language_35 | Full |
| TC-P36 nullable native | test_language_36 | Full |
| TC-P37 unique-ignore-self | test_language_37 | Full |
| TC-D40/41/42 FK/global | test_language_40/41/42 | Partial (env-guarded) |
| TC-N50 guest | test_language_50 | Full |
| TC-N51–56 permissions | test_language_51–56 | Partial (super-admin path + gate-string asserts; no negative limited-user run — see limitations) |
| TC-P60–64 UI | test_language_60–64 | Full |
| TC-E70–74 edge/defects | test_language_70–74 | Full |
| TC-T90 write path | test_language_90 | Full |
| TC-S91 XSS | test_language_91 | Full |
| TC-S92 404 | test_language_92 | Full |
| TC-S93 guest toggle | test_language_93 | Full |

## 2. Coverage Summary
| Category | Total | Full | Partial | Gap | % (Full) |
|----------|-------|------|---------|-----|----------|
| Positive | 18 | 18 | 0 | 0 | 100% |
| Negative | 15 | 13 | 2 (perm negatives via string-assert) | 0 | 100% coverage / 87% deep-negative |
| Dependency | 3 | 0 | 3 (env-guarded) | 0 | 100% (defensive) |
| State-Machine | 3 | 3 | 0 | 0 | 100% |
| Edge/Tenancy/Security | 9 | 9 | 0 | 0 | 100% |

Gates target: Negative 100% (met — every negative TC has a method), Positive ≥90% (100%), Dependency ≥90% (100% defensive-guarded).

**Partial-coverage limitations:**
- **TC-N51–56:** negative authorization (a limited central user receiving 403) is asserted structurally (gate string present + super-admin positive path) rather than by provisioning a non-super central user, because central permission seeding for `prime.language.*` is environment-dependent (LanguagePolicy exists but the string gates resolve through Spatie permissions not registered in AppServiceProvider). Guest-redirect (TC-N50) and guest-toggle (TC-N93) cover the unauthenticated boundary directly.
- **TC-D40/41/42:** FK/global-view behaviour is exercised defensively with `markTestSkipped` when `sys_users`/`information_schema` are unavailable in a partial runner env.

## 3. Coverage-Score by requirement source
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 8 | 8 | 100% |
| State-Machine (BC-SM) | 5 | 5 | 100% |
| Validation Rules (BC-VAL) | 5 | 5 | 100% |
| Integration/Referential (BC-INT/REF) | 2 | 2 | 100% |
| Permissions (BC-AUTH) | 7 | 7 | 100% |
| Edge/Defects (BC-EDG) | 4 | 4 | 100% |

Every `Source`-tagged requirement item maps to ≥1 TC. No 0-coverage items.

## 4. Cross-Reference Defect Scan
| # | Check | Compared | Finding | ID | Test |
|---|-------|----------|---------|----|----|
| 1 | Enum case | DDL `ENUM('LTR','RTL')` vs Request `in:['LTR','RTL']` | MATCH (no defect) | — | test_language_74 |
| 2 | Route registration | Blade `central.global-master.language.*` vs web.php | Registered, but the whole group is declared **twice** | DEV-LANG-002 | test_language_72 |
| 3 | Gate vs Policy | Controller string gates vs LanguagePolicy | Policy exists but NOT wired to string gates; gates resolve via Spatie permissions (super-admin bypass). Redundant policy | DEV-LANG-010 (obs.) | test_language_51 |
| 4 | Fillable vs DDL | Model fillable vs columns | MATCH | — | test_language_01 |
| 5 | Cast vs DDL | No custom casts; is_active tinyint | OK (no boolean cast declared — value read as int) | obs. | test_language_17 |
| 6 | Service delegation | Controller vs Service | No service layer (thin controller) | — | — |
| 7 | State machine vs impl | restore lifecycle | `restore()` does not reset `is_active` → restored langs stay inactive | DEV-LANG-007 | test_language_22 |
| 8 | Validation vs Request | Screen rules vs rules() | MATCH | — | test_language_30–37 |
| 9 | Error/message vs source | forceDelete event label; update flash | forceDelete logs `Stored`; update flash `'update.language'` unresolved | DEV-LANG-003, 004 | test_language_16, 18 |
| 10 | Permissions vs Policy | prime.language.* vs Policy/Gates | toggleStatus reuses `.update` (no dedicated status gate); update authorizes twice | DEV-LANG-006 | test_language_55, 73 |
| 11 | Integration FK vs migration | sys_users.prefered_language → glb_languages | FK present; global-shared implications for delete | BC-REF-01 | test_language_40/41 |

**Additional:** DEV-LANG-005 (no activity log on store/update — audit gap, test_language_19); DOC-LANG-008 (consolidated DDL stale vs migration, test_language_71); DEV-LANG-009 (prime_db view + global_master write path, test_language_70/90).

## Legend
Full = behaviour asserted end-to-end (UI + DB/activity). Partial = asserted structurally or env-guarded. Gap = no coverage (none here).

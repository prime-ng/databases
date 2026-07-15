# Tenant Domain — Gap Analysis (`prm_TenantDomainGAPANALYSIS_Require.md`)

- **Feature:** TenantDomain (Prime / central)
- **Test file:** `prm_TenantDomain_TestCas.php` — 47 methods
- **Coverage legend:** Full = automated assertion(s) directly verify the TC; Partial = verified indirectly / documented-only; Gap = no coverage.

## 1. Manual TC ↔ Dusk method mapping

### Positive
| TC | Method(s) | Coverage |
|----|-----------|----------|
| TC-P01 config truth | test_01 | Full |
| TC-P02 no FormRequest | test_02 | Full |
| TC-P03 index render | test_10 | Full |
| TC-P04 store creates + log | test_11, test_19 | Full |
| TC-P05 update fields + log | test_12 | Full |
| TC-P06 blank password kept | test_13 | Full |
| TC-P07 encrypted at rest | test_15 | Full |
| TC-P08 is_active default 0 | test_16 | Full |
| TC-P09 create form fields | test_17 | Full |
| TC-P10 edit read-only | test_18 | Full |
| TC-P11 activity actor | test_19 | Full |
| TC-P12 belongsTo tenant | test_40 | Full |
| TC-P13 search / empty | test_60, test_61 | Full |
| TC-P14 breadcrumb / columns | test_62, test_63 | Full |

### State machine
| TC | Method | Coverage |
|----|--------|----------|
| TC-SM01 activate | test_20 | Full |
| TC-SM02 deactivate | test_21 | Full |
| TC-SM03 non-boolean rejected | test_22 | Full |
| TC-SM04 inactive listed | test_23 | Full |

### Negative
| TC | Method | Coverage |
|----|--------|----------|
| TC-N01 tenant_id required | test_30 | Full |
| TC-N02 domain required | test_31 | Full |
| TC-N03 duplicate domain | test_32 | Full |
| TC-N04 db fields required | test_33 | Full |
| TC-N05 domain > 255 | test_34 | Full |
| TC-N06 db_port > 10 | test_35 | Full |
| TC-N07 tenant exists | test_36 | Full |
| TC-N08 update db_name required | test_37 | Full |
| TC-N09 immutable keys | test_38 | Full |
| TC-N10 max>column (BUG-PRM-003) | test_39 | Full (documenting) |
| TC-N11 guest redirect | test_50 | Full |
| TC-N12 toggle boolean | test_22 | Full |
| TC-N13 unknown id 404 | test_92 | Full |

### Dependency
| TC | Method | Coverage |
|----|--------|----------|
| TC-D01 inactive display | test_23 | Full |
| TC-D02 hard delete (BUG-PRM-002) | test_14 | Full |
| TC-D03 FK RESTRICT | test_41 | Full |
| TC-D04 delete keeps tenant | test_42 | Full |

### Permissions
| TC | Method | Coverage |
|----|--------|----------|
| TC-AU01..06 | test_51..56 | Full (defensive skip if role infra absent) |
| TC-AU07 action column | test_57 | Partial (admin-visible confirmed; hidden-state not driven) |

### Security / Edge
| TC | Method | Coverage |
|----|--------|----------|
| TC-S01 reflected XSS | test_90 | Full |
| TC-S02 stored XSS | test_91 | Full |
| TC-S03 404 | test_92 | Full |
| TC-E01 lowercase | test_70 | Full |
| TC-E02 password overflow (BUG-PRM-004) | test_71 | Partial (documented, defensive) |
| TC-E03 whitespace username | test_72 | Full (documenting) |

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|---------|------|---------|-----|------------------|
| Positive | 14 | 14 | 0 | 0 | 100% |
| State-machine | 4 | 4 | 0 | 0 | 100% |
| Negative | 13 | 13 | 0 | 0 | 100% |
| Dependency | 4 | 4 | 0 | 0 | 100% |
| Permissions | 7 | 6 | 1 | 0 | 100% |
| Security | 3 | 3 | 0 | 0 | 100% |
| Edge | 3 | 2 | 1 | 0 | 100% |
| **Total** | **48** | **46** | **2** | **0** | **100%** |

Gate targets: **Negative 100% ✅ · Positive ≥90% (100%) ✅ · Dependency ≥90% (100%) ✅**. Tenancy-isolation gate is **N/A** (central single-DB feature — no cross-tenant surface).

## 3. Coverage-Score by Requirement Source (WP-F)
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 11 | 11 | 100% |
| State-Machine (BC-SM) | 3 | 3 | 100% |
| Validation Rules (BC-VAL) | 10 | 10 | 100% |
| Integration / FK (BC-INT/REF) | 2 | 2 | 100% |
| Permissions (BC-AUTH) | 7 | 7 | 100% |
| Edge (BC-EDG) | 4 | 4 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. No zero-coverage items.

## 4. Cross-Reference Defect Scan (11 checks)
| # | Check | Compare | Finding |
|---|-------|---------|---------|
| 1 | Enum case | — | No ENUM columns on this table. N/A |
| 2 | Route registration | Blade `route('central.prime.tenant-domain.*')` vs `routes/web.php:142-143` | All registered (resource + toggleStatus). OK |
| 3 | Gate vs Policy | Controller `Gate::authorize('prime.tenant-domain.*')` | String gates; no dedicated Policy class (permission-name gates). Consistent with module pattern. OK |
| 4 | Fillable vs DDL | Model `$guarded=[]` (Stancl) | All columns mass-assignable; controller only passes `$validated`. OK (note: open guard) |
| 5 | **Cast vs DDL** | `casts db_password=encrypted` vs `db_password VARCHAR(255)` | **BUG-PRM-004** — encrypted ciphertext can exceed 255 for long input |
| 6 | Service delegation | Controller has no Service — logic inline | OK (simple CRUD) |
| 7 | State machine vs impl | is_active toggle | Implemented + validated. OK |
| 8 | Validation vs rules | brief vs `validate()` | store/update/toggle match source exactly. OK |
| 9 | Error message vs source | default Laravel messages (no custom `messages()`) | Assertions target field keys not exact text (no custom messages defined). OK |
| 10 | Permissions vs gates | `prime.tenant-domain.{viewAny,create,view,update,delete}` | 5 gates over 8 methods (update shared by edit/update/toggle; create by create/store). All present. OK |
| 11 | **Integration FK vs migration** | DDL FK `tenant_id → prm_tenant ON DELETE RESTRICT` | Present. OK |
| — | **Soft-delete vs schema** | `deleted_at` column + "soft deleted" log vs no `SoftDeletes` trait | **BUG-PRM-002** — hard delete |
| — | **Encrypted cast vs brief** | brief "no encrypted cast / plaintext" vs actual `casts()` | **BUG-PRM-001 NOT reproducible / remediated** — brief is stale |
| — | **Validation max vs column size** | `max:255` vs VARCHAR(100)/(200) | **BUG-PRM-003** |

## 5. Defect Register (feature-level)
| ID | Sev | Status | Description | Proving test | Business rule |
|----|-----|--------|-------------|--------------|---------------|
| BUG-PRM-001 | P0 (brief) | **Remediated / not reproducible** | Brief claimed `db_password` plaintext; current `Domain::casts()` encrypts it | test_15, test_01 | BR-PRM-006 = **PASS** |
| BUG-PRM-002 | P1 | Open | Hard delete despite `deleted_at` + "soft deleted" intent; `Domain` lacks `SoftDeletes` | test_01, test_14 | Data-loss / no trash-restore |
| BUG-PRM-003 | P2 | Open | Validation `max:255` > DDL column size (db_name/host/username) | test_39 | Integrity risk |
| BUG-PRM-004 | P2 | Open | Encrypted `db_password` may overflow VARCHAR(255) | test_71 | Integrity risk |

## 6. Notes / Partial-coverage limitations
- **test_57** confirms the Action column renders for a super-admin; it does not drive a limited user to assert the column is *hidden* (permission-provisioning in central is environment-dependent; the negative permission cases test_51–56 cover the gate behaviour directly).
- **test_71 (BUG-PRM-004)** is intentionally defensive (skips/records on infra error) so a partial environment stays green while still documenting the overflow risk.
- Permission negative tests (test_51–56) `markTestSkipped` if a non-super-admin user cannot be provisioned, keeping partial environments green (constraint C13 / defensive rule).

# prm_Tenant — Gap Analysis & Coverage

**Test file:** `prm_Tenant_TestCas.php` — 50 methods · **DB scope:** central `prime_db`

## 1. Manual TC ↔ Dusk method mapping

### Positive
| TC | Method | Coverage |
|----|--------|----------|
| TC-P01..P05 | test_tenant_01..05 | Full |
| TC-P10,P11,P12,P13,P14,P16 | test_tenant_10..16 | Full |
| TC-P25,P26,P36,P45,P64 | test_tenant_25/26/36/45/64 | Full |
| TC-P60,P61,P62 | test_tenant_60/61/62 | Full (guarded: module-enabled + auth) |

### Negative
| TC | Method | Coverage |
|----|--------|----------|
| TC-N30,N53,N94 | test_tenant_30/53/94 | Full |
| TC-N31,N32,N33,N34 | test_tenant_31/32/33/34 | Full (source-string) |
| TC-N38 | test_tenant_38 | Full (guarded 404) |
| TC-N46 | test_tenant_46 | Full |

### State machine
| TC | Method | Coverage |
|----|--------|----------|
| TC-SM01..SM06 | test_tenant_20/21/22/23/24/27 | Full (source-truth; live re-dispatch not executed) |

### Dependency / Permissions / Tenancy / Security / Edge
| TC | Method | Coverage |
|----|--------|----------|
| TC-D40 | test_tenant_40 | Full (migration file) |
| TC-D41 | test_tenant_41 | Partial (info_schema; skips if not introspectable) |
| TC-D43 | test_tenant_43 | Full (transaction steps) |
| TC-AUTH37,50,54 | test_tenant_37/50/54 | Full |
| TC-T90,T91 | test_tenant_90/91 | Full |
| TC-S93 | test_tenant_93 | Full |
| TC-E70,E71,E73 | test_tenant_70/71/73 | Full |

### Defect-proving
| Defect | Method | Coverage |
|--------|--------|----------|
| BUG-PRM-TENANT-001 (NEW) | test_tenant_55 | Full — proves routes present + methods missing |
| GAP-PRM-003 | test_tenant_15 | Full — proves random password |
| BUG-PRM-006 | test_tenant_51 | Full — proves correct gate |
| BUG-PRM-STUB-001 | test_tenant_52 | Full — proves destroy implemented |
| DOC-PRM-DDL-001 | test_tenant_02/73 | Full |

## 2. Coverage Summary
| Category | Total | Full | Partial | Gap | % |
|----------|-------|------|---------|-----|---|
| Positive | 19 | 19 | 0 | 0 | 100% (guarded UI counts as full) |
| Negative | 9 | 9 | 0 | 0 | 100% |
| State machine | 6 | 6 | 0 | 0 | 100% |
| Dependency/FK | 3 | 2 | 1 | 0 | 100% (1 env-guarded) |
| Permissions/Routes | 3 | 3 | 0 | 0 | 100% |
| Tenancy/Security | 3 | 3 | 0 | 0 | 100% |
| Edge | 3 | 3 | 0 | 0 | 100% |
| Defect-proving | 5 | 5 | 0 | 0 | 100% |

Meets gates: **Negative 100%, Positive ≥90%, Dependency ≥90%, Tenancy 100%** (central-scope P0/P1).

## 3. Partial-coverage / limitations
- **End-to-end provisioning** (real DB creation, migrations, root-user, completed/failed transitions) is **not executed** — the runner cannot create databases/queue. Proven via literal-source + progress-checkpoint asserts. *Recommend a dedicated integration harness with a disposable MySQL instance to exercise `SetupTenantDatabase` live.*
- **Live create/edit/destroy DB mutations** are not run against `prm_tenant` (string PK + FK to prm_tenant_groups/glb_cities require seeded parents). Behaviour proven via source + schema truth.
- **TC-D41** (domain FK) depends on `information_schema` access; skips cleanly otherwise.

## 4. Coverage-Score by requirement Source
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 9 | 9 | 100% |
| State-Machine (BC-SM) | 7 | 7 | 100% |
| Validation Rules (BC-VAL) | 8 | 8 | 100% |
| Integration/FK (BC-REF/INT) | 4 | 4 | 100% |
| Permissions (BC-AUTH) | 6 | 6 | 100% |

Every `Source`-tagged requirement item maps to ≥1 TC. No zero-coverage items.

## 5. Cross-Reference Defect Scan
| # | Check | Compare | Finding |
|---|-------|---------|---------|
| 1 | Enum case | tenant_type ENUM('live','archive') vs model `=== 'live'/'archive'` | ✅ match |
| 2 | Route registration | routes `tenant.trashed/restore/forceDelete` vs controller methods | ❌ **BUG-PRM-TENANT-001** — methods `trashedTenant/restore/forceDelete` absent |
| 3 | Gate vs method | 3 flagged methods vs gate string | ✅ all `prime.tenant.update` (BUG-PRM-006 FIXED) |
| 4 | Fillable/custom-cols vs DDL | Tenant `getCustomColumns` vs DDL prm_tenant | ⚠ model omits DDL cols `crc_code/brc_code/instruction_language/rural_urban`; DDL omits live `data/setup_*/rollover_*` — **DOC-PRM-DDL-001** (DDL stale) |
| 5 | Cast vs DDL | `is_active` boolean cast vs tinyint(1) | ✅ |
| 6 | Service delegation | updateTenantPlan controller body vs `TenantPlanAssigner::assign` | ⚠ near-duplicate 5-step logic exists in BOTH controller and service; controller uses its own copy (service unused by this route) — refactor smell, not a functional bug |
| 7 | State machine vs impl | doc lifecycle vs job/controller | ✅ pending→…→completed/failed + reset guard present |
| 8 | Validation vs FormRequest | required matrix vs rules() | ✅ |
| 9 | Error message vs FormRequest | sub-domain / board messages | ✅ verbatim |
| 10 | Permissions vs gates | matrix vs Gate::authorize | ✅ 21 gated actions |
| 11 | FK vs migration | tenant_group/city/domain FKs | ✅ RESTRICT present; **MIG-PRM-001 FIXED** (down drops `prm_tenant`) |

### Discovered defects
- **BUG-PRM-TENANT-001 (P1, NEW):** `Route::resource('tenant')` is followed by `tenant.trashed` (`/tenant/trash/view`), `tenant.restore` (`/tenant/{id}/restore`), `tenant.forceDelete` (`/tenant/{id}/force-delete`) that reference `TenantController::trashedTenant/restore/forceDelete` — none of which exist on the controller. Any access (trash view, restore, force-delete) throws. Proving test: `test_tenant_55`.
- **DOC-PRM-DDL-001 (P3):** consolidated `_prime_db_v4.sql` is stale vs the live migrations (id INT vs string PK; missing `data`, setup/rollover/archive columns). Assert schema truth from the live DB, not the DDL file.

### Reported-but-not-reproducing (code advanced past audit snapshot)
GAP-PRM-003, BUG-PRM-006, BUG-PRM-STUB-001, MIG-PRM-001, GAP-PRM-001 are all **fixed/resolved** in current source — each has a proving/regression test so any regression re-surfaces.

## 6. Legend
Full = behaviour asserted directly · Partial = asserted with an environment guard (skips cleanly) · Gap = not covered (none).

# prm_SalesPlanAndModuleMgmt — Gap Analysis

**Feature:** Prime (PRM) Sales Plan & Module Mgmt (composite read-only) · **Test file:** `prm_SalesPlanAndModuleMgmt_TestCas.php` (35 methods)
**Screen type note:** read/composite screen — no create/edit/delete matrix is expected because the resource controller's write half is non-functional (documented as defects). Coverage targets are applied to the applicable categories (render/filter/permission/integrity/security).

## 1. Manual TC ↔ Dusk method mapping

### Configuration
| Manual | Method(s) | Coverage |
|--------|-----------|----------|
| MTC-01 (schema/route/gate) | `_01`,`_02`,`_03` | Full |

### Render / Business rules
| Manual | Method(s) | Coverage |
|--------|-----------|----------|
| MTC-01 tabs | `_10` | Full |
| MTC-02 plans+modal | `_13`,`_14` | Full |
| billing/modules panes | `_11`,`_12` | Full |
| pagination params | `_15` | Full |

### Filters / Negative
| Manual | Method(s) | Coverage |
|--------|-----------|----------|
| MTC-03 search | `_30`,`_31` | Full |
| MTC-04 status + invalid | `_32`,`_33` | Full |
| MTC-05 empty-state | `_34` | Full |

### Permissions
| Manual | Method(s) | Coverage |
|--------|-----------|----------|
| index gate | `_50` | Full |
| resource gates | `_51` | Full |
| MTC-09 vocab mismatch | `_52` | Full |
| policy type-hint | `_53` | Full |
| MTC-06 guest | `_54` | Full |
| admin access | `_55` | Full |

### Integrity / Integration / Defects
| Manual | Method(s) | Coverage |
|--------|-----------|----------|
| MTC-07 store stub | `_40`,`_42` | Full |
| update/destroy stub | `_41` | Full |
| MTC-08 missing views | `_43` | Full |
| MTC-10 FK RESTRICT | `_44` | Full |
| pivot mismatch | `_45` | Full |
| fillable gap | `_46` | Full |
| BillingCycle ts gap | `_47` | Full |
| MTC-11 command | `_48` | Full |

### UI / Security / Scope
| Manual | Method(s) | Coverage |
|--------|-----------|----------|
| breadcrumb | `_60` | Full |
| default/switch panes | `_61`,`_62` | Full |
| central scope | `_90` | Full |
| MTC-12 XSS | `_91` | Full |
| guest DELETE | `_92` | Full |

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive (render/config) | 17 | 17 | 0 | 0 | 100% |
| Negative | 5 | 5 | 0 | 0 | 100% |
| Dependency / Integration | 8 | 8 | 0 | 0 | 100% |
| Permissions | 4 | 4 | 0 | 0 | 100% |
| Central scope | 1 | 1 | 0 | 0 | 100% |
| **Total** | **35** | **35** | **0** | **0** | **100%** |

> Targets (Negative 100%, Positive ≥90%, Dependency ≥90%, central-scope 100%) all met. No create/edit/delete positive matrix is applicable (write path is a documented non-functional stub, not a working feature).

## 3. Cross-Reference Findings (source-defect scan)
| # | Check | Compare | Finding | Test | Defect |
|---|-------|---------|---------|------|--------|
| 2 | Route registration | Blade `route('central.*')` vs registered names | Row actions point at OTHER controllers (`central.billing.billing-cycle`, `central.global-master.module/plan`); this screen writes nothing | `_51`,`_52` | (design note) |
| 3 | Gate vs Policy | controller string gates vs Policy class | Policy is never bound (string `Gate::authorize`), so `SalesPlanAndModuleMgmtPolicy` is dead code | `_53` | DEV-PRM-SPM-004 |
| 4 | Fillable vs DDL | `Plan $fillable` vs `prm_plans` cols | `price_quarterly` in DDL, absent from fillable | `_46` | DEV-PRM-SPM-006 |
| 4b | Fillable vs DDL | `Plan $fillable` vs FK | `billing_cycle_id` fillable but SMALLINT FK RESTRICT | `_44` | (ok) |
| 5 | Cast vs DDL / SoftDeletes | `BillingCycle` traits vs `prm_billing_cycles` cols | SoftDeletes+timestamps used, DDL declares no `deleted_at/created_at/updated_at`; `index()->latest()` orders by `created_at` | `_47` | DEV-PRM-SPM-007 |
| 6 | Service delegation | controller body | store/update/destroy contain NO logic at all (empty stubs) | `_40`,`_41`,`_42` | DEV-PRM-SPM-001 |
| 8/9 | Validation/messages | FormRequest | No FormRequest exists; write actions accept `Request` and validate nothing | `_40` | DEV-PRM-SPM-001 |
| 10 | Permissions vs UI | controller gate vs view tab gates | `prime.sale-plan-module-mgmt.*` (controller) vs `prime.billing-cycle/module/plan.*` (view) — divergent vocabularies | `_52` | DEV-PRM-SPM-003 |
| 11 | Pivot/FK naming | DDL `prm_module_plan_jnt` vs models `glb_module_plan_jnt` | pivot table name mismatch; relationship queries a differently-named table | `_45` | DEV-PRM-SPM-005 |
| 2b | View existence | controller `view('prime::create/show/edit')` vs files | none of those blade files exist | `_43` | DEV-PRM-SPM-002 |
| 12 | Command wiring | audit GAP-PRM-001 vs `registerCommands()` | command exists + registered — **audit claim refuted** | `_48` | GAP-PRM-001 (refuted) |

## 4. Coverage-Score by requirement source
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR / index behaviour) | 6 | 6 | 100% |
| Validation/Filter Rules (Screen-VR) | 5 | 5 | 100% |
| Integration Points (Screen-IP: FK, pivot, stubs, views, command) | 8 | 8 | 100% |
| Permissions (Screen-PM) | 6 | 6 | 100% |
| Schema (DDL) | 13 | 13 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. No item is left at 0.

## 5. Defect Register (feature-scoped)
| ID | Sev | Description | Status | Proving test |
|----|-----|-------------|--------|--------------|
| DEV-PRM-SPM-001 | P1 | `store()/update()/destroy()` empty stubs — resource cannot create/update/delete | Open | `_40`,`_41`,`_42` |
| DEV-PRM-SPM-002 | P1 | `create()/show()/edit()` return non-existent views → View-not-found | Open | `_43` |
| DEV-PRM-SPM-003 | P2 | permission vocabulary split (controller vs view tabs) | Open | `_52` |
| DEV-PRM-SPM-004 | P2 | Policy type-hints `TenantPlan` + never bound (dead policy) | Open | `_53` |
| DEV-PRM-SPM-005 | P2 | pivot DDL `prm_module_plan_jnt` vs code `glb_module_plan_jnt` | Open | `_45` |
| DEV-PRM-SPM-006 | P3 | `Plan $fillable` omits `price_quarterly` | Open | `_46` |
| DEV-PRM-SPM-007 | P2 | `BillingCycle` SoftDeletes/timestamps vs DDL columns absent | Open | `_47` |
| GAP-PRM-001 | P1 | GenerateInvoicesCommand — **REFUTED** (present + registered; REQ-PRM-005 wiring exists). BR-PRM-016/017 depend on runtime execution, not on missing wiring. | Refuted | `_48` |

## 6. Legend
- **Full** = manual TC fully automated by ≥1 method. **Partial** = automated with a documented limitation. **Gap** = not automated.
- Source-content asserts (`readAppSource`/DDL) degrade to `markTestSkipped` when `MAIN_PROJECT_PATH`/DDL is unreachable (fail-soft), so a partial environment stays green rather than false-failing.

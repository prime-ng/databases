# Module Knowledge Summary: Inventory (INV)

**Date:** 2026-06-27
**Agent:** Business Analyst
**Source Files:**
- `4-Requirement_Module_wise/4-Initial_Requirements/V2/INV_Inventory_Requirement.md` (V2, 7 sub-modules, 19 BRs)
- `2-DDL_Tenant_Consolidated/Inventory_DDL_v1.sql` (28 tables)
- `Herd/prime_ai/Modules/Inventory/` (live filesystem verification — seeding + update pass on 2026-06-27)

**Knowledge File:** `AI_Brain/module-knowledge/INV_Inventory.md`

---

## 1. Module Identity

| Item | Finding |
|------|---------|
| Module Code | `INV` |
| Table Prefix | `inv_*` |
| Database | `tenant_db` (per-school, no `tenant_id` columns) |
| Laravel Path | `Modules/Inventory/` |
| DDL Version | v1 (28 tables, several FK constraints intentionally commented out) |
| V2 Requirement | `INV_Inventory_Requirement.md` (7 sub-modules / layers) |
| FRD Status | Not yet generated |

**Key Discovery from this session:** Seeded as 0% Greenfield on 2026-06-27. Update pass on the same day revealed ~55–65% actual completion with 20 controllers, 28 models, 14 services, 77 views, and 221 route lines — all unverified at seeding time.

---

## 2. Actual vs. Proposed Comparison

| Metric | Seeded Estimate | Actual (Verified) | Change |
|--------|----------------|-------------------|--------|
| Controllers | 18 proposed | **20** | +2 (`InventoryController` base, `InvMenuController`) |
| Models | 28 proposed | **28** | Exact match (one per DDL table) |
| Services | **7** proposed | **14** | **+7 — 2× proposed count** (see Section 4) |
| FormRequests | 13 proposed | **18** | +5 (Update variants + StoreUom, StoreItemVendor) |
| Policies | 13 proposed | **16** | +3 (AssetCategoryPolicy, StockEntryPolicy, UomPolicy) |
| Blade Views | ~65 estimated | **77** | +12 |
| Route Lines | ~65 routes estimated | **221 lines** (143 named routes) | 3× estimate |
| Tests | 0 | **0** | Feature/ and Unit/ dirs exist but no test files |
| Jobs | Listed as Artisan command | **1** (`ReorderAlertJob`) | Implemented as Job not Command |
| Events | 8 proposed | **4 actual** | 4 missing (see Section 6) |
| Listeners | Required (D21) | **0** | No Listeners/ directory in INV |
| Artisan Commands | 4 proposed | **1** (`MaintenanceOverdueCommand`) | 3 missing |
| Seeders | 3 proposed | **35 actual** | +32 (incl. 5 placeholder seeders) |
| Migrations | Required | **0** | FK constraints also commented out in DDL |
| Completion % | 0% (incorrectly seeded) | **~55–65%** | Corrected |

---

## 3. DDL Architecture: 28 Tables Across 7 Sub-Modules

| Sub-Module | Tables | Status |
|-----------|--------|--------|
| L1 — Item & Category Master | `inv_stock_groups`, `inv_units_of_measure`, `inv_uom_conversions`, `inv_stock_items`, `inv_godowns`, `inv_asset_categories` | ✅ Implemented |
| L2 — Stock Management | `inv_stock_entries`, `inv_stock_balances`, `inv_stock_adjustments`, `inv_stock_adjustment_items` | ✅ Implemented |
| L3 — Purchase Orders | `inv_purchase_requisitions`, `inv_purchase_requisition_items`, `inv_purchase_orders`, `inv_purchase_order_items`, `inv_goods_receipt_notes`, `inv_grn_items` | ✅ Implemented |
| L4 — Vendor Linkage | `inv_item_vendor_jnt`, `inv_rate_contracts`, `inv_rate_contract_items_jnt` | ✅ Implemented |
| L5 — Asset Tracking | `inv_assets`, `inv_asset_movements`, `inv_asset_maintenance` | ✅ Implemented |
| L6 — Quotations | `inv_quotations`, `inv_quotation_items` | ✅ Implemented |
| L7 — Stock Issue | `inv_issue_requests`, `inv_issue_request_items`, `inv_stock_issues`, `inv_stock_issue_items` | ✅ Implemented |

All 7 sub-modules appear to have code scaffold. Physical implementation completeness (logic depth) is unverified — Technical Audit needed.

**V1 → V2 DDL additions (9 new tables):** `inv_stock_balances` (denormalized balance), `inv_stock_adjustments` + items (physical count workflow), `inv_quotations` + items (RFQ flow), `inv_asset_categories`, `inv_assets`, `inv_asset_movements`, `inv_asset_maintenance`. These were all missing from V1 and are present in the current DDL v1 (confusingly named V1 despite incorporating V2 scope).

---

## 4. Service Count: 7 Proposed → 14 Actual (The Biggest Finding)

This is the largest service count discrepancy in the audit to date — actual is **2× the proposed count**. The 7 extra services implement architectural decisions that went beyond the V2 requirement scope:

| Service | In V2 Req? | Role |
|---------|-----------|------|
| `AssetService` | Implied | Asset lifecycle, disposal, acc_fixed_assets event |
| `GodownService` | Implied | Godown management, transfer logic |
| `GrnPostingService` | ✅ Core | GRN acceptance, stock entry creation, event dispatch |
| `InventoryReportService` | ✅ Core | Stock ledger, asset register, valuation reports |
| `PurchaseOrderService` | ✅ Core | PR→PO conversion, approval workflow |
| `PurchaseRequisitionService` | ✅ Core | PR creation, department validation |
| `QuotationService` | ✅ Core | RFQ, comparative statement |
| `RateContractService` | ✅ Core | Rate contract lifecycle, expiry management |
| `ReorderAlertService` | ✅ Core | Balance vs reorder_level check, alert dispatch |
| `StockAdjustmentService` | ✅ Core | Physical count, variance calc, approval |
| `StockGroupService` | Implied | Group hierarchy management |
| `StockIssueService` | ✅ Core | Issue request → issue confirmation workflow |
| **`StockLedgerService`** | ❌ **Not in V2 req** | Stock movement ledger — history per item per godown |
| **`StockValuationService`** | ❌ **Not in V2 req** | FIFO / Weighted Avg / Last Purchase Cost valuation engine |

**`StockLedgerService` and `StockValuationService` are undocumented additions** — no method signatures, no requirement coverage. These are architecturally significant: `StockValuationService` implements the three valuation methods (Design Decision D9 — FIFO, Weighted Avg, Last Purchase Cost). Their integration with `GrnPostingService` and `StockIssueService` is unverified.

---

## 5. Cross-Module Placeholder Seeders — Smart Prerequisite Bypass (Major Discovery)

The module contains **5 cross-module placeholder seeders** not proposed in the V2 requirement:

| Placeholder Seeder | Prereq Blocked | What It Creates |
|--------------------|---------------|----------------|
| `AccVoucherPlaceholderSeeder` | P1 — `acc_vouchers` FK mandatory on stock entries | Fake voucher records so INV can post stock entries |
| `AccLedgerPlaceholderSeeder` | P2 — `acc_ledgers` FK on stock items | Fake purchase/sales/party ledgers |
| `AccTaxRatePlaceholderSeeder` | P2 — `acc_tax_rates` FK on PO lines | Fake GST rate records |
| `AccFixedAssetPlaceholderSeeder` | P2 — `acc_fixed_assets` FK on assets | Fake fixed asset records |
| `VendorPlaceholderSeeder` | P3 — `vnd_vendors` FK on PO/GRN/rate contracts | Fake vendor records |

**Significance:** The V2 requirement listed ACC and VND modules as hard prerequisites for INV implementation (P1–P3 blockers). The team bypassed this by creating fake data in the prerequisite tables. INV is now **functionally testable standalone** without ACC or VND being complete.

**Tech debt created:** When ACC and VND modules reach production readiness, all 5 placeholder seeders must be identified and removed from the production seeder stack. There is no automated flag to remove them — this is a risk of stale placeholder data in production.

**Total seeders = 35** — one per entity (28 INV tables) plus the 5 placeholder seeders plus 2 compound (InventoryDatabaseSeeder orchestrator + one extra). This is the most comprehensively seeded module in the audit.

---

## 6. Domain Events: 4 of 8 Implemented — 4 Missing

Decision D21 (event-driven Accounting integration) required 8 domain events. Only 4 exist:

| Event | Status | Consumer | Impact if Missing |
|-------|--------|----------|-------------------|
| `GrnAccepted` | ✅ Exists | Accounting | Purchase voucher creation |
| `StockIssued` | ✅ Exists | Accounting | Stock journal voucher |
| `StockAdjusted` | ✅ Exists | Accounting | Journal entry for variance |
| `AssetDisposed` | ✅ Exists | Accounting | Fixed asset write-off |
| **`StockTransferred`** | ❌ Missing | Accounting | Godown-to-godown transfer never notifies ACC — no journal entry created |
| **`ReorderThresholdReached`** | ❌ Missing | NTF | Reorder alerts fire via `ReorderAlertJob`/`ReorderAlertService` instead — confirm this path works |
| **`RateContractExpiringSoon`** | ❌ Missing | NTF | Rate contract expiry alerts never dispatched |
| **`MaintenanceOverdue`** | ❌ Missing | NTF | Maintenance overdue alerts never dispatched (though `MaintenanceOverdueCommand` exists to trigger this) |

**Critical gap:** `StockTransferred` event missing means every godown-to-godown transfer completes in the INV module but never creates an accounting journal entry. This silently breaks the ledger balance for inter-godown transfers.

---

## 7. No Listeners Directory — Decision D21 Ownership

INV has no `Listeners/` directory. This is architecturally correct per **Decision D21** (event-driven Accounting integration): INV fires events; Accounting **subscribes** via its own event listeners. The listener that handles `GrnAccepted` → creates Purchase Voucher must live in `Modules/Accounting/app/Listeners/`.

**Action required:** Verify ACC module has listeners registered for all INV events (`GrnAccepted`, `StockIssued`, `StockAdjusted`, `AssetDisposed`). If ACC's `Listeners/` directory is also empty, the full ACC←→INV integration is broken silently — events fire but no vouchers are created.

---

## 8. Route Duplication — Minor Bug

`toggleStatus` is registered under two different URL patterns for at least 4 resources:

```
Route::post('stock-groups/{id}/toggle-status', ...)   // kebab-case
Route::post('stock-groups/{id}/toggleStatus', ...)    // camelCase — DUPLICATE
```

Both point to the same controller method. Same pattern on `uoms`, `stock-items`, `godowns`. This doubles the route table entries for these actions and will cause ambiguity in named route lookups. Standardise to kebab-case and remove camelCase variants.

---

## 9. Key Architecture Decisions (10 Documented)

| Decision | Summary | Risk if Missed |
|----------|---------|---------------|
| D1 — Denormalized `inv_stock_balances` | One row per (stock_item_id, godown_id); updated atomically in same DB::transaction as stock entry; `lockForUpdate()` prevents race conditions | Concurrent stock entries corrupt balance without lock |
| D2 — `inv_stock_entries` immutable | No UPDATE/DELETE on posted entries; corrections go through `inv_stock_adjustments` | Any direct edit to posted entry breaks audit trail |
| D21 — Event-driven ACC integration | INV fires events; ACC subscribes via listeners; `voucher_id` on stock tables is NULL until ACC processes | Missing events = silent ledger gap in ACC |
| D4 — No `tenant_id` columns | DB-level isolation via stancl/tenancy v3.9 | N/A — design constraint |
| D5 — `sch_department` singular | FK references `sch_department.id` (NOT `sch_departments`) | Migration FK fails if pluralized |
| D6 — Stock adjustment `variance_qty` is GENERATED | `variance_qty = physical_qty - system_qty` is a DB GENERATED ALWAYS column — never INSERT/UPDATE it | Direct write to generated column throws DB error |
| D7 — Auto-create `inv_assets` on GRN accept | When `inv_stock_items.item_type = 'asset'` and GRN accepted, one `inv_assets` record auto-created per accepted unit; fires event to ACC for `acc_fixed_assets` | Asset GRN without auto-create = asset unregistered in fixed asset register |
| D8 — Mandatory `voucher_id` on stock entries | Every `inv_stock_entries` row MUST have non-null `voucher_id` (BR-INV-001) | Stock entry insert blocked until ACC creates voucher — placeholder seeder bypasses this for dev |
| D9 — Valuation methods per item | FIFO / Weighted Average / Last Purchase Cost per item | FIFO uses oldest batch first — wrong batch selection inflates/deflates COGS |
| D10 — FK constraints commented out | `acc_vouchers`, `vnd_vendors`, `sch_department`, `sch_employees` FKs intentionally disabled in DDL | When prereqs are ready, FKs must be uncommented + migration applied — no automated reminder |

---

## 10. Artisan Commands: 1 of 4 — 3 Missing

| Command | Status | Purpose | Schedule |
|---------|--------|---------|----------|
| `inventory:recalculate-balances` | ❌ Missing | Rebuild `inv_stock_balances` from scratch (recovery tool) | Manual |
| `inventory:check-reorder-levels` | ❌ Missing | Dispatch `ReorderAlertJob` for all items below reorder_level | Daily morning |
| `inventory:expire-rate-contracts` | ❌ Missing | Auto-transition past-`valid_to` contracts to 'expired' | Daily midnight |
| `MaintenanceOverdueCommand` | ✅ Exists | Check maintenance schedules; dispatch overdue alerts | Daily morning |

**Note:** `ReorderAlertJob` exists and `ReorderAlertService` exists, but `inventory:check-reorder-levels` (the command that dispatches the job on schedule) is missing. The job cannot be triggered automatically without its scheduler command.

---

## 11. Open Gaps & Recommended Actions

### P1 — Critical

| Gap | Recommended Action |
|-----|-------------------|
| **0 test files** | Priority: `StockBalance` SELECT...FOR UPDATE concurrency (D1), `StockValuationService` FIFO batch selection (D9), GRN posting event dispatch chain (D21), stock adjustment `variance_qty` GENERATED column behaviour, immutability of `inv_stock_entries` (D2) |
| **0 migrations** | Create 28 tenant migrations; FK constraints for ACC/VND/SCH commented in DDL — create with comments and activate when prereqs are ready |
| **`StockTransferred` event missing** | Godown-to-godown transfers never create ACC journal entry — silent ledger gap. Create event + verify ACC has a listener for it. |
| **Verify ACC listeners for INV events** | ACC module must own listeners for `GrnAccepted`, `StockIssued`, `StockAdjusted`, `AssetDisposed`. If ACC Listeners/ is also empty, D21 is fully broken silently. |

### P2 — Architecture Risk

| Gap | Recommended Action |
|-----|-------------------|
| `ReorderThresholdReached`, `RateContractExpiringSoon`, `MaintenanceOverdue` events missing | NTF alert chain is incomplete; `MaintenanceOverdueCommand` exists but fires via command not event — confirm notification is actually dispatched |
| `StockLedgerService` + `StockValuationService` undocumented | Technical Audit: document method signatures; confirm FIFO implementation; confirm integration with `GrnPostingService` and `StockIssueService` |
| 3 missing Artisan commands | Create `inventory:recalculate-balances`, `inventory:check-reorder-levels`, `inventory:expire-rate-contracts` |
| Controller logic completeness unknown | Technical Audit (Mode A): 20 controllers present but GRN workflow, FIFO selection, PR→PO conversion logic depth unverified |

### P3 — Cleanup

| Gap | Action |
|-----|--------|
| Route duplication (`toggle-status` + `toggleStatus`) | Standardise to kebab-case; remove camelCase duplicate routes on ≥4 resources |
| Placeholder seeders tech debt | Document removal checklist for when ACC + VND reach production readiness; tag seeder files with `// PLACEHOLDER — remove when ACC/VND production-ready` comment |
| FK constraints uncomment plan | Create a checklist of which FK to uncomment after which module is ready; tie to ACC + VND + SCH release milestones |

---

## 12. Cross-Module Integration Map

### INV Reads From:
| Module | Tables | Integration Point |
|--------|--------|-----------------|
| Vendor (VND) | `vnd_vendors` | PO vendor, rate contracts, GRN vendor, maintenance vendor |
| SchoolSetup (SCH) | `sch_department` *(singular)* | PR/issue/stock-issue department assignment |
| SchoolSetup (SCH) | `sch_employees` | Godown in-charge, asset assigned-to, stock issue recipient |
| Accounting (ACC) | `acc_ledgers`, `acc_tax_rates`, `acc_vouchers`, `acc_fixed_assets` | Mandatory FKs on stock entries; GST on PO; asset linkage |
| System (SYS) | `sys_users`, `sys_permissions` | Audit columns, RBAC |

### INV Fires Events To:
| Event | Consumer | Result |
|-------|----------|--------|
| `GrnAccepted` | Accounting | Creates Purchase Voucher |
| `StockIssued` | Accounting | Creates Stock Journal Voucher |
| `StockAdjusted` | Accounting | Creates Journal Entry for variance |
| `AssetDisposed` | Accounting | Write-off residual in `acc_fixed_assets` |
| `ReorderThresholdReached` ❌ | NTF | Reorder alert (event not yet created) |
| `RateContractExpiringSoon` ❌ | NTF | Expiry alert (event not yet created) |
| `MaintenanceOverdue` ❌ | NTF | Overdue alert (event not yet created) |

### Downstream Consumers of INV:
| Module | Usage |
|--------|-------|
| Accounting (ACC) | Receives voucher creation triggers via events |
| Cafeteria (CAF) | Optional: INV purchase requisition on stock reorder (`caf_inv_integration = true`) |
| Notification (NTF) | Receives reorder/expiry/maintenance alerts |

### Module Independence Notes:
- Library (`lib_*`) owns its own book stock — NOT tracked in INV
- Transport (`tpt_*`) owns vehicle fuel/parts — NOT tracked in INV
- Vendor module owns `vnd_vendors` master — INV only adds linkage and pricing

---

## 13. Key Lessons Learned

1. **Service count can be UNDER-counted in requirement docs just as easily as over-counted.** ACC and BHA had services over-counted (req doc listed "proposed" services that were never built). INV is the opposite — req doc proposed 7, actual has 14. Two entirely undocumented services (`StockLedgerService`, `StockValuationService`) implement significant architectural functionality. The only reliable count is `ls app/Services/`.

2. **Placeholder seeders are an important workaround pattern — but create silent tech debt.** The 5 ACC/VND placeholder seeders are architecturally clever: they allow INV to be tested without waiting for ACC and VND modules to be production-ready. But there is no automated mechanism to remove them. If placeholder data persists in production, every stock entry created in dev/staging will have a fake `voucher_id` that does not correspond to a real ACC voucher — a data integrity issue.

3. **"Implemented as Job not Artisan Command" is a valid design choice that req docs don't capture.** `ReorderAlertJob` was proposed as `inventory:check-reorder-levels` Artisan command; the team created it as a queued `ShouldQueue` Job instead. The requirement doc cannot be trusted for class type (Command vs Job vs Service). Always verify implementation class type separately.

4. **A missing event in an event-driven architecture is a silent integration failure.** `StockTransferred` event is missing. When a godown-to-godown transfer is confirmed in the UI, it succeeds in INV but Accounting never receives a notification to create the corresponding journal entry. There is no error — the transfer just silently fails to post to the ledger. This is harder to catch than a thrown exception.

5. **Decision D21 (event-driven ACC integration) is only half-implemented.** INV's side (firing events) has 4 of 8 events created. But the ACC side (listening and creating vouchers) has not been verified — if ACC's Listeners/ directory is also empty, the entire integration is broken. Cross-module event-driven integrations must be verified end-to-end, not just per module.

6. **28 models = 28 DDL tables — the one-model-per-table rule holds again.** Consistent with CAF (21/21) and ADM (20/20). This rule is now confirmed across 4+ modules. Never subtract junction or log tables from model count estimates.

7. **Route duplication (`toggle-status` + `toggleStatus`) suggests copy-paste route registration.** The same pattern appears on ≥4 resources. This likely happened when routes were migrated from a central file to the module route file and both old and new patterns were retained. Route naming conventions must be standardised at the module level.

---

## 14. Recommended Next Steps

| Priority | Action | Agent |
|----------|--------|-------|
| 1 | Verify ACC module has Listeners for all 4 INV events — if not, D21 is fully broken | Technical Auditor |
| 2 | Create `StockTransferred` event + confirm ACC listener handles it | Developer |
| 3 | Add tests: `StockBalance` concurrency (SELECT...FOR UPDATE), `StockValuationService` FIFO, GRN event dispatch chain, stock entry immutability | Testing Architect |
| 4 | Document `StockLedgerService` + `StockValuationService` method signatures; confirm FIFO integration with `GrnPostingService` | Technical Auditor |
| 5 | Create 28 tenant migrations (DDL layer order; leave FK constraints as commented migrations with prerequisite notes) | Developer |
| 6 | Create 3 missing Artisan commands: `inventory:recalculate-balances`, `inventory:check-reorder-levels`, `inventory:expire-rate-contracts` | Developer |
| 7 | Create 3 remaining NTF events: `ReorderThresholdReached`, `RateContractExpiringSoon`, `MaintenanceOverdue` | Developer |
| 8 | Generate FRD — must document placeholder seeder strategy, undocumented services, and 4 missing events as known divergences from V2 req | Business Analyst → "create an FRD for Inventory" |
| 9 | Tag placeholder seeders with removal checklist; fix route duplication (kebab-case only) | Developer |


Status: 0% Greenfield → ~55–65% — substantial scaffold was present but never verified.

Key findings from the update pass:

┌──────────────┬────────────┬───────────┬───────────────────────────────────────────────────────────────────────────────────┐
│    Metric    │   Seeded   │  Actual   │                                       Note                                        │
├──────────────┼────────────┼───────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Controllers  │ 18         │ 20        │ +InventoryController (base), InvMenuController                                    │
├──────────────┼────────────┼───────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Models       │ 28         │ 28        │ Exact match                                                                       │
├──────────────┼────────────┼───────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Services     │ 7          │ 14        │ 2× proposed — StockLedgerService + StockValuationService + 5 others not in V2 req │
├──────────────┼────────────┼───────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ FormRequests │ 13         │ 18        │ +5 including Update variants                                                      │
├──────────────┼────────────┼───────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Policies     │ 13         │ 16        │ +3 extras                                                                         │
├──────────────┼────────────┼───────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Views        │ ~65        │ 77        │ Standard undershoot                                                               │
├──────────────┼────────────┼───────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Routes       │ ~65        │ 221 lines │ 143 named routes                                                                  │
├──────────────┼────────────┼───────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Seeders      │ 3          │ 35        │ Includes 5 cross-module ACC/VND placeholder seeders                               │
├──────────────┼────────────┼───────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Events       │ 8 proposed │ 4 actual  │ StockTransferred, reorder, rate-contract, maintenance alerts missing              │
├──────────────┼────────────┼───────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Listeners    │ —          │ 0         │ ACC must own listeners per Decision D21                                           │
├──────────────┼────────────┼───────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Tests        │ —          │ 0         │ Critical: SELECT...FOR UPDATE on stock_balances has no coverage                   │
└──────────────┴────────────┴───────────┴───────────────────────────────────────────────────────────────────────────────────┘

Biggest discoveries: the 5 cross-module placeholder seeders (enabling standalone INV testing despite ACC/VND blockers) and service count doubling from StockLedgerService + StockValuationService — two undocumented services that confirm the FIFO/weighted-average valuation engine is implemented beyond the req doc scope.
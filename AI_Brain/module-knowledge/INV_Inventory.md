# Module Knowledge: Inventory (INV)
# Last Updated: 2026-06-27 (update pass — file counts verified against Herd/prime_ai)
# Completion Status: ~55–65% (all controllers/models/services/policies present; 77 views; 0 tests critical; 4 of 8 events; 0 migrations)

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix | `inv_*` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/Inventory_DDL_v1.sql` — 28 tables |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/INV_Inventory_Requirement.md` |
| Routes | **221 lines** in `Modules/Inventory/routes/web.php` (143 named route entries; re-verified 2026-06-27) |
| Controllers | **20** actual (**corrected from 18 proposed**; extras: `InventoryController` base, `InvMenuController`) |
| Models | **28** actual (matches DDL table count exactly — re-verified) |
| Services | **14** actual (**corrected from 7 proposed** — 2× proposed count): AssetService, GodownService, GrnPostingService, InventoryReportService, PurchaseOrderService, PurchaseRequisitionService, QuotationService, RateContractService, ReorderAlertService, StockAdjustmentService, StockGroupService, StockIssueService, **StockLedgerService**, **StockValuationService** |
| FormRequests | **18** actual (corrected from 13 proposed; extras: StoreUomRequest, StoreUomConversionRequest, StoreItemVendorRequest, UpdateAssetRequest, UpdateItemVendorRequest) |
| Policies | **16** actual (corrected from 13 proposed; extras: AssetCategoryPolicy, StockEntryPolicy, UomPolicy) |
| Blade Views | **77** actual (corrected from ~65 proposed) |
| Tests | **0** — Feature/ and Unit/ directories exist but contain no test files (critical gap) |
| Jobs | **1** actual: `ReorderAlertJob` (proposed as Artisan command — implemented as queued job instead) |
| Events | **4** of 8 proposed: `AssetDisposed`, `GrnAccepted`, `StockAdjusted`, `StockIssued` — **missing 4**: `StockTransferred`, `ReorderThresholdReached`, `RateContractExpiringSoon`, `MaintenanceOverdue` |
| Listeners | **0** — no `Listeners/` directory in INV module |
| Artisan Commands | **1** actual: `MaintenanceOverdueCommand` (3 of 4 proposed commands missing) |
| Seeders | **35** actual (3 proposed) — includes **5 cross-module placeholder seeders** for ACC + VND prerequisite bypass |
| Migrations | **0** — module uses DDL directly |
| FRD | **Generated 2026-06-29** → `4-Requirement_Module_wise/0-FRD_Documents/INV_FRD_2026-06-29.md` |

---

## FRD Summary

| Item | Value |
|------|-------|
| FRD File | `4-Requirement_Module_wise/0-FRD_Documents/INV_FRD_2026-06-29.md` |
| Date | 2026-06-29 |
| Functional Requirements (REQ-INV) | **22** (re-derived from V2's 15 `FR-INV`; separated masters, valuation, transfer, asset register vs maintenance, reporting into distinct testable units) |
| Business Rules (BR-INV) | **58** (re-numbered + expanded from V2's 18; added delete/archive, opening-balance lock, concurrency, data-isolation, audit, negative-stock and partial-flow coverage) |
| Workflows | **6** (Procure-to-Stock, Stock Issue, Physical Count & Adjustment, Asset Lifecycle, Reorder Automation, Rate Contract Lifecycle) |
| Reports (RPT-INV) | **12** (balance, valuation, ledger, consumption, purchase register, pending PO, GRN register, reorder, fast/slow movers, expiry, storeroom-wise, asset register) |
| Enhancements (ENH-INV) | **7** (mobile count app, multi-level approval, predictive reorder, supplier scorecard, GeM integration, regional language, asset self-service QR) |
| Priority split | P0 = 11 · P1 = 8 · P2 = 3 |
| Status | Draft (superseded none — first FRD for this module) |

---

## Sub-Modules

| Code | Name | Tables | Status |
|------|------|--------|--------|
| L1 | Item & Category Master | `inv_stock_groups`, `inv_units_of_measure`, `inv_uom_conversions`, `inv_stock_items`, `inv_godowns`, `inv_asset_categories` | Not Started |
| L2 | Stock Management | `inv_stock_entries`, `inv_stock_balances`, `inv_stock_adjustments`, `inv_stock_adjustment_items` | Not Started |
| L3 | Purchase Orders | `inv_purchase_requisitions`, `inv_purchase_requisition_items`, `inv_purchase_orders`, `inv_purchase_order_items`, `inv_goods_receipt_notes`, `inv_grn_items` | Not Started |
| L4 | Vendor Linkage | `inv_item_vendor_jnt`, `inv_rate_contracts`, `inv_rate_contract_items_jnt` | Not Started |
| L5 | Asset Tracking | `inv_assets`, `inv_asset_movements`, `inv_asset_maintenance` | Not Started |
| L6 | Procurement Workflow / Quotations | `inv_quotations`, `inv_quotation_items` | Not Started |
| — | Stock Issue | `inv_issue_requests`, `inv_issue_request_items`, `inv_stock_issues`, `inv_stock_issue_items` | Not Started |

---

## Known Gaps & Open Issues

### Implementation Blockers (Prerequisites)

| # | Blocker | Owner Module | Blocks |
|---|---------|-------------|--------|
| P1 | `VoucherServiceInterface` must be implemented | Accounting (ACC) | GRN acceptance, Stock Issue posting |
| P2 | `acc_vouchers`, `acc_ledgers`, `acc_tax_rates` tables must exist in DDL | Accounting (ACC) | `inv_*` FK migrations (currently commented out) |
| P3 | `vnd_vendors` table must exist and be populated | Vendor (VND) | PO creation, Rate Contracts, GRN |
| P4 | `sch_department` (singular table name) must exist | SchoolSetup (SCH) | PR creation, Issue Requests |
| P5 | `sch_employees` table must exist | SchoolSetup (SCH) | Godown in-charge assignment, Asset employee assignment |
| P6 | Notification module event bus active | Notification (NTF) | Reorder alert, Rate contract expiry, Maintenance overdue alerts |

### FK Constraints Commented Out in DDL

Several FK constraints are intentionally commented out in `Inventory_DDL_v1.sql` pending other modules:
- `acc_vouchers` FK on `inv_stock_entries`, `inv_stock_issues`, `inv_goods_receipt_notes` (D21 dependency)
- `vnd_vendors` FK on all vendor-linked tables
- `sch_department` FK on `inv_purchase_requisitions`, `inv_issue_requests`, `inv_stock_issues`
- `sch_employees` FK on `inv_godowns`, `inv_stock_issues`, `inv_assets`, `inv_asset_movements`
- `acc_fixed_assets` FK on `inv_assets`

These must be uncommented and applied **after** the respective module DDLs are in place.

### V1 → V2 Additions (9 new tables)

The DDL is V1 but the requirement doc is V2. The V1→V2 delta added:
- `inv_stock_balances` — denormalized running balance (was SUM query in V1; performance critical)
- `inv_stock_adjustments` + `inv_stock_adjustment_items` — physical audit workflow (compliance gap in V1)
- `inv_quotations` + `inv_quotation_items` — RFQ/quotation comparison workflow (V1 went PR → PO directly)
- `inv_asset_categories` — asset depreciation classification
- `inv_assets` — full fixed asset register (V1 only mentioned this briefly)
- `inv_asset_movements` — asset transfer history
- `inv_asset_maintenance` — maintenance scheduling and AMC tracking

---

## Design Decisions Made

1. **Denormalized `inv_stock_balances`**: Replaces expensive `SUM(quantity)` across `inv_stock_entries` at scale. One row per `(stock_item_id, godown_id)`. Updated atomically within the same DB transaction as each stock entry. Uses `lockForUpdate()` to prevent race conditions on concurrent writes. Artisan command `inventory:recalculate-balances` can rebuild from scratch.

2. **`inv_stock_entries` is immutable (append-only)**: No UPDATE/DELETE on posted entries. Corrections go through `inv_stock_adjustments` workflow. Protected at both application and service layer.

3. **Event-driven Accounting integration (Decision D21)**: Inventory does NOT call Accounting service methods directly. It fires events (`GrnAccepted`, `StockIssued`, `StockTransferred`, `StockAdjusted`, `AssetDisposed`); Accounting subscribes via event listeners. `voucher_id` on stock tables is NULL until Accounting processes the event and creates the voucher.

4. **No `tenant_id` columns**: DB-level tenant isolation via `stancl/tenancy v3.9`. One database per tenant. No tenant scoping needed on queries.

5. **`sch_department` is SINGULAR** (not `sch_departments`): FK columns in `inv_purchase_requisitions.department_id`, `inv_issue_requests.department_id`, `inv_stock_issues.department_id` reference `sch_department.id` (singular). This is a confirmed DDL naming quirk — do not pluralize.

6. **Separate stock adjustment workflow**: Physical count creates `inv_stock_adjustments` → items with system vs physical qty → `variance_qty` is a GENERATED ALWAYS column (`physical_qty - system_qty`) — never INSERT/UPDATE it directly. Approval required above configurable value threshold (BR-INV-017).

7. **Asset item type auto-creates `inv_assets`**: When `inv_stock_items.item_type = 'asset'` and GRN is accepted, one `inv_assets` record is auto-created per accepted unit (integer quantity assumed). Fires event to Accounting to create `acc_fixed_assets` record.

8. **Mandatory voucher on stock entries**: Every `inv_stock_entries` record MUST have a non-null `voucher_id` (BR-INV-001). No orphan stock movements are permitted.

9. **Valuation methods per item**: FIFO, Weighted Average, or Last Purchase Cost — configurable per item. FIFO uses FIFO batch selection (oldest batch first) for outward entries.

10. **Recommended implementation sequence** (from V2 Section 14.6):
    - Phase 1: Masters (UOM, Stock Groups, Items, Godowns, Asset Categories)
    - Phase 2: Vendor Linkage (requires VND)
    - Phase 3: Procurement (requires SCH)
    - Phase 4: GRN + Stock Entry (requires ACC VoucherServiceInterface)
    - Phase 5: Issue Workflow
    - Phase 6: Assets
    - Phase 7: Adjustments + Reports

---

## Cross-Module Dependencies

### Inbound (Inventory reads from)

| Dependency | Table(s) | Integration Point |
|------------|----------|------------------|
| Vendor (VND) | `vnd_vendors` | PO vendor, Rate contracts, GRN vendor, Maintenance vendor |
| SchoolSetup (SCH) | `sch_department` (singular) | PR department, Issue request department, Stock issue department |
| SchoolSetup (SCH) | `sch_employees` | Godown in-charge, Asset assigned employee, Stock issue recipient |
| Accounting (ACC) | `acc_ledgers` | Purchase/sales/party ledgers on items and stock entries |
| Accounting (ACC) | `acc_tax_rates` | GST rates on items and PO lines |
| Accounting (ACC) | `acc_vouchers` | Mandatory FK on every `inv_stock_entries` row |
| Accounting (ACC) | `acc_fixed_assets` | Asset linkage via `inv_assets.acc_fixed_asset_id` |
| System (SYS) | `sys_users`, `sys_permissions` | User refs on all audit columns, RBAC permissions |

### Outbound Events (Inventory fires)

| Event | Fired When | Consumer | Action |
|-------|-----------|----------|--------|
| `GrnAccepted` | GRN status → 'accepted' | Accounting | Creates Purchase Voucher |
| `StockIssued` | Stock issue confirmed | Accounting | Creates Stock Journal Voucher |
| `StockTransferred` | Godown-to-godown transfer | Accounting | Creates Stock Journal |
| `StockAdjusted` | Adjustment approved + posted | Accounting | Creates Journal Entry |
| `AssetDisposed` | Asset marked 'disposed' | Accounting | Write-off residual in acc_fixed_assets |
| `ReorderThresholdReached` | Balance <= reorder_level | Notification (NTF) | Alert to store manager |
| `RateContractExpiringSoon` | 30 days before valid_to | Notification (NTF) | Alert to store manager |
| `MaintenanceOverdue` | next_due_date passed | Notification (NTF) | Alert to store manager |

### Module Independence Notes

- Library (`lib_*`) owns its own book stock — NOT tracked in Inventory
- Transport (`tpt_*`) owns vehicle fuel/parts — NOT tracked in Inventory
- Vendor module owns `vnd_vendors` master — Inventory only adds linkage and pricing

---

## Artisan Commands to Build

| Command | Purpose | Schedule |
|---------|---------|----------|
| `inventory:recalculate-balances` | Rebuild `inv_stock_balances` from `inv_stock_entries` | Manual |
| `inventory:check-reorder-levels` | Run reorder check on all items | Daily morning |
| `inventory:expire-rate-contracts` | Auto-transition past-`valid_to` contracts to 'expired' | Daily midnight |
| `inventory:maintenance-overdue` | Check schedules and dispatch overdue notifications | Daily morning |

---

## Cross-Module Placeholder Seeders (Key Discovery)

The module contains **5 cross-module placeholder seeders** — a workaround for implementation blockers listed in the Knowledge file. These create fake records in ACC and VND tables so INV can be tested standalone:

| Placeholder Seeder | Bypasses Blocker |
|--------------------|-----------------|
| `AccVoucherPlaceholderSeeder` | P1 — `VoucherServiceInterface` / `acc_vouchers` FK |
| `AccLedgerPlaceholderSeeder` | P2 — `acc_ledgers` FK on stock items |
| `AccTaxRatePlaceholderSeeder` | P2 — `acc_tax_rates` FK on PO lines |
| `AccFixedAssetPlaceholderSeeder` | P2 — `acc_fixed_assets` FK on assets |
| `VendorPlaceholderSeeder` | P3 — `vnd_vendors` FK on PO/GRN/rate contracts |

**Implication:** INV module is functionally testable standalone despite the prerequisite blockers. When ACC and VND modules are fully implemented, placeholder seeders must be removed and replaced with real cross-module data.

---

## Route Duplication Issue

`toggleStatus` is registered under **two different URL patterns** for at least 4 resources (stock-groups, uoms, stock-items, godowns):

```
Route::post('stock-groups/{id}/toggle-status', ...)   // kebab-case URL
Route::post('stock-groups/{id}/toggleStatus', ...)    // camelCase URL — DUPLICATE
```

Both point to the same controller method. This is a DRY violation and wastes route table entries. Should be standardised to one pattern (kebab-case preferred) and the other removed.

---

## Known Gaps & Open Issues (as of 2026-06-27)

| Priority | Gap | Detail |
|----------|-----|--------|
| P1 | **0 test files** | Feature/ and Unit/ directories exist but contain no test files. `SELECT...FOR UPDATE` on `inv_stock_balances`, FIFO batch selection in `StockValuationService`, GRN acceptance event dispatch, and stock adjustment approval flow are all high-risk without tests. |
| P1 | **0 migrations** | Cannot bootstrap a fresh tenant via `artisan migrate`. All 28 tables exist only in DDL. |
| P1 | **4 of 8 domain events missing** | `StockTransferred`, `ReorderThresholdReached`, `RateContractExpiringSoon`, `MaintenanceOverdue` not created. Without these: godown-to-godown transfers don't notify Accounting; reorder alerts don't fire; rate contract expiry goes undetected. |
| P1 | **0 Listeners directory** | Decision D21 (event-driven Accounting integration) requires ACC to subscribe to INV events. No `Listeners/` in INV — ACC module must own those listeners. Verify ACC has them before assuming D21 is implemented. |
| P2 | **3 of 4 Artisan commands missing** | `inventory:recalculate-balances`, `inventory:check-reorder-levels`, `inventory:expire-rate-contracts` not created. Only `MaintenanceOverdueCommand` exists. `ReorderAlertJob` exists but the scheduled command that dispatches it is missing. |
| P2 | **Route duplication** | `toggle-status` and `toggleStatus` both registered for same method on ≥4 resources. Standardise to kebab-case. |
| P2 | **Controller logic completeness unknown** | 20 controllers present but internal logic (FIFO valuation, PR→PO→GRN workflow, concurrency on stock_balances) unverified. Technical Audit needed. |
| P2 | **FK constraints commented out in DDL** | `acc_vouchers`, `vnd_vendors`, `sch_department`, `sch_employees`, `acc_fixed_assets` FKs intentionally commented out. Must be uncommented once prerequisite modules are complete — no automated reminder exists. |
| P3 | **`StockValuationService` and `StockLedgerService` undocumented** | Both services are not in V2 requirement doc. Method signatures and integration with `GrnPostingService` unknown. Technical Audit needed. |

---

## Known Gaps & Open Issues (Technical Audit 2026-06-29 — Mode A, verified against LIVE code)

> Full report: `3-Audit_Reports/V1_Jun-2026/Inventory_Technical_Audit_2026-06-29.md`. Health **38/100 (P0 cap ≤40 applies)**. New codes: P0=1, P1=5, P2=3, P3=1.

| Code | Sev | Issue | File:Line |
|------|-----|-------|-----------|
| DAT-INV-001 | P0 | `StockAdjustmentService::approve()` posting loop commented out (FIXME) — approved physical-count variances flip status to `approved` + fire `StockAdjusted` but NEVER post to ledger/balances → balances silently corrupt. | `app/Services/StockAdjustmentService.php:138-163` |
| DAT-INV-002 | P1 | `entry_type='adjustment'` sign contradiction: `postEntry()` treats it OUTWARD(−) but `recalculateBalances()` treats it INWARD(+); transfers create only a `transfer_out` row (destination credited via direct write) so `inventory:recalculate-balances` cannot rebuild destination stock → rebuild corrupts balances. | `app/Services/StockLedgerService.php:59 vs 92-102,154-161` |
| DAT-INV-003 | P1 | Negative-stock guard runs OUTSIDE the lock/transaction → TOCTOU oversell race; `max(0,…)` then silently clamps the loss. BR-INV-003 defeated under concurrency. | `app/Services/StockLedgerService.php:63-65 vs 116-123` |
| BUG-INV-001 | P1 | `Events/MaintenanceOverdue.php`, `Events/AssetDisposed.php`(dup), `Listeners/*` live at module ROOT (PSR-4 root is `app/` only) → NOT autoloadable. Firing `AssetDisposed` (live `assets.dispose`) 500s + rolls back; scheduled `inventory:maintenance-overdue` fatals nightly. | root `Events/`,`Listeners/`; `app/Providers/EventServiceProvider.php:14-21` |
| JOB-INV-001 | P1 | `ReorderAlertJob` queries/writes tenant tables with no tenancy re-init (constructor carries no tenant id, `handle()` no `initialize()`/`$tenant->run()`). | `app/Jobs/ReorderAlertJob.php:25-67` |
| DEPLOY-INV-01 | P1 | Closure route `Route::get('/', fn () => view(...))` breaks `php artisan route:cache` for the whole app. | `routes/web.php:216` |
| MIG-INV-001 | P2 | `entry_type` hard ENUM (D29; root cause of DAT-INV-001) + `variance_qty` is a plain writable column though DDL intended GENERATED ALWAYS and its own comment says "DO NOT INSERT/UPDATE". | `database/migrations/tenant/...create_inv_stock_entries_table.php:17`; `...stock_adjustment_items...` |
| PERF-INV-003 | P2 | ~10 unbounded `->get()` over growing ledger tables in report builders (stock-ledger/consumption/valuation). | `app/Services/InventoryReportService.php` (36,60,82,…) |
| DAT-INV-004 | P2 | GRN/ADJ/SI/IR numbers + asset tags minted via `COUNT(*)+1` with no lock/unique → duplicates under concurrency. | `GrnPostingService.php:26-32,223-233`; `StockAdjustmentService.php:232-238`; `StockIssueService.php:25-42` |
| DEAD-INV-003 | P3 | `prs.import` route wired to a "coming soon" stub; orphan duplicate `Events/AssetDisposed.php`. | `routes/web.php:113`; `PurchaseRequisitionController.php:158` |

**Snapshot corrections (do not trust the 2026-06-27 facts block blindly):**
- ❌ "0 migrations" is FALSE — all **28 `inv_*` tenant migrations exist** at `database/migrations/tenant/2026_06_15_*`. The module's own `database/migrations/` is empty (expected — migrations are centralized).
- ❌ "`MaintenanceOverdue` missing / 0 Listeners" — they EXIST but are mis-located outside `app/` (BUG-INV-001): present-but-unwired, not missing.
- FormRequests are **19** (not 18) — `BulkTransferRequest` included; all 19 still `authorize(){return true}` (SEC-INV-001 / D30).

## Lessons Learned

- [2026-06-29 | Technical Auditor] **The core stock-integrity engine is broken at the worst layer.** `StockAdjustmentService::approve()` ships with its ledger-posting loop commented out (FIXME blaming the `entry_type` ENUM) → approved adjustments never reconcile balances. Always read the *body* of an approve/post method, not just its existence — the method exists, is routed, fires its event, and looks complete, but does nothing to the ledger. The cited ENUM excuse is half-false: a generic `'adjustment'` value already exists in the enum.
- [2026-06-29 | Technical Auditor] **PSR-4 trap:** nwidart modules map `Modules\Inventory\` → `app/` ONLY. Files at the module root (`Events/`, `Listeners/`) carrying an `app`-namespace are NOT autoloadable — they silently break event wiring and any code that references them. Grep the autoload map in `composer.json` before trusting a class's location.
- [2026-06-29 | Technical Auditor] **"0 migrations" snapshot error:** migrations are centralized under `database/migrations/tenant/`, never inside `Modules/<X>/database/migrations/`. A per-module-dir check will always report 0 — verify against the tenant migration set.
- [2026-06-29 | Technical Auditor] **Locking is half-done:** the balance WRITE uses `lockForUpdate()` (good) but the negative-stock CHECK and all `COUNT(*)+1` document-number generators are unlocked → oversell + duplicate numbers. A locked write does not make a read-modify-write safe.
- [2026-06-27 | Update] Module was seeded as "0% Greenfield" without filesystem check. Actual state: 20 controllers, 28 models, 14 services, 16 policies, 18 FormRequests, 77 views, 221 route lines — ~55–65% complete. Standard update pass pattern applied.
- [2026-06-27 | Update] Services count UNDER-counted in req doc (7 proposed vs 14 actual) — reverse of ACC/BHA pattern. The extra 7 services (`StockLedgerService`, `StockValuationService`, `ReorderAlertService`, etc.) implement architectural decisions beyond what the req doc proposed. Verify actual `app/Services/` always.
- [2026-06-27 | Update] **5 cross-module placeholder seeders** enable standalone INV testing despite ACC/VND blockers. When ACC/VND modules are production-ready, placeholder seeders must be removed. Document this as a tech debt item.
- [2026-06-27 | Update] `ReorderAlertJob` was proposed as an Artisan command in the req doc; implemented as a queued Job instead. Req doc is not a reliable guide for implementation class type (Command vs Job vs Service).

---

## Pending Next Steps

- [x] Generate FRD → DONE 2026-06-29 → `INV_FRD_2026-06-29.md` (22 REQ / 58 BR / 6 workflows / 12 reports / 7 ENH)
- [ ] Create 4 missing domain events: `StockTransferred`, `ReorderThresholdReached`, `RateContractExpiringSoon`, `MaintenanceOverdue`
- [ ] Create 3 missing Artisan commands: `inventory:recalculate-balances`, `inventory:check-reorder-levels`, `inventory:expire-rate-contracts`
- [ ] Verify ACC module has Listeners for INV events (`GrnAccepted`, `StockIssued`, etc.) as per Decision D21
- [ ] Create 28 tenant migrations (DDL layer order)
- [ ] Uncomment FK constraints in DDL after ACC + VND + SCH modules are production-ready
- [ ] Add tests: `StockValuationService` (FIFO), `StockBalance` (SELECT...FOR UPDATE concurrency), GRN posting event dispatch
- [ ] Fix route duplication: standardise `toggle-status` vs `toggleStatus` to one pattern
- [ ] Code Gap Analysis → `act as Technical Auditor` — Mode B (FRD-driven) after FRD is generated
- [ ] Remove placeholder seeders when ACC/VND modules are production-ready

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-29 | Technical Auditor | Mode A 12-layer deep audit (live-verified). Health 38/100 (P0 cap). 10 new issues: DAT-INV-001 (P0 posting disabled), DAT-INV-002/003 (P1 sign/transfer + oversell race), BUG-INV-001 (P1 mis-located Events/Listeners), JOB-INV-001 (P1 job tenancy), DEPLOY-INV-01 (P1 closure route), MIG-INV-001 + PERF-INV-003 + DAT-INV-004 (P2), DEAD-INV-003 (P3). Corrected snapshot: 28 migrations DO exist, MaintenanceOverdue/Listeners present-but-unwired, 19 FormRequests. Report → `3-Audit_Reports/V1_Jun-2026/Inventory_Technical_Audit_2026-06-29.md`. |
| 2026-06-27 | Business Analyst | Knowledge file seeded from V2 requirement doc (INV_Inventory_Requirement.md v2) + DDL (Inventory_DDL_v1.sql). Status incorrectly recorded as 0% Greenfield — actual code not checked at seeding. |
| 2026-06-29 | Business Analyst | FRD generated fresh (no prior FRD) → `INV_FRD_2026-06-29.md`. Synthesized from V2 requirement (15 FR/18 BR), V1 19 screen-specs, DDL (28 tables) and the 20-controller Laravel module. Produced 22 REQ-INV, 58 BR-INV, 6 workflows, 12 RPT-INV reports, 7 ENH-INV. Section 10.4 totals reconciled (P0=11/P1=8/P2=3). FRD Summary block added to knowledge file. |
| 2026-06-27 | Business Analyst | Update pass: verified all file counts against prime_ai/Modules/Inventory/. Status corrected to ~55–65%. Controllers 18→20, models 28→28 (confirmed), services 7→14 (2× proposed), FormRequests 13→18, policies 13→16, views 65→77, routes 221 lines. Discovered: 5 cross-module placeholder seeders (ACC+VND bypass), 35 total seeders, 4 of 8 domain events implemented, 1 Artisan command, 1 queued Job, 0 Listeners, 0 tests, 0 migrations. Route duplication noted. StockLedgerService + StockValuationService found (not in V2 req). |

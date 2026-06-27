# Module Knowledge: Inventory (INV)
# Last Updated: 2026-06-27
# Completion Status: 0% — Greenfield (no implementation started)

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix | `inv_*` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/Inventory_DDL_v1.sql` — 28 tables |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/INV_Inventory_Requirement.md` |
| Routes | `routes/tenant.php` under `inventory/` prefix (~65 routes) |
| Controllers | 18 proposed |
| Models | 28 proposed (one per table) |
| Services | 7 proposed |
| FormRequests | 13 proposed |
| Policies | 13 proposed |
| Blade Views | ~65 proposed |
| Seeders | 3 (StockGroups×10, UOM×10, Godowns×5) |
| Events | 8 domain events |
| Artisan Commands | 4 proposed |
| FRD | Not yet generated |

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

## Lessons Learned

(empty until session work populates this)

---

## Pending Next Steps

- [ ] Generate FRD → `act as Business Analyst` → "create an FRD for Inventory"
- [ ] DDL Gap Analysis → `act as DB Architect` — verify 28 DDL tables vs requirement data model
- [ ] Ensure prerequisite modules (Vendor, SchoolSetup, Accounting) DDLs are in place before implementing FK constraints
- [ ] Code Gap Analysis → `act as Technical Auditor` — Mode B (FRD-driven) after FRD is generated

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | Knowledge file seeded from V2 requirement doc (INV_Inventory_Requirement.md v2) + DDL (Inventory_DDL_v1.sql). No session work yet. |

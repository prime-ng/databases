# Inventory Module — Requirements Overview

**Module:** Inventory Management | **Laravel Module:** `Modules/Inventory/` | **Prefix:** `inv_`
**Database:** tenant_db (dedicated per tenant) | **Route:** `/inventory/*`
**DDL:** `DDL/INV_DDL_v1.sql` (28 tables) | **Migration:** `2026_03_27_100000_create_inv_tables.php`

## Module Overview

The Inventory module provides complete stock and procurement management for Indian K-12 schools. It covers the full lifecycle from item master setup through procurement workflow (PR → Quotation → PO → GRN → Stock Entry), departmental stock issue and consumption tracking, asset tracking, and automated reorder alerts — all integrated with the Accounting module via event-driven voucher posting.

**Core Principle:** Stock valuation follows per-item method (FIFO/Weighted Average/Last Purchase). Stock entries are immutable once posted. Negative stock is never permitted. Asset-type items auto-create fixed asset records on GRN acceptance.

## Requirements by Tab/Table

| # | File | Table(s) | Parent Tab |
|---|------|----------|------------|
| 1 | `Requirements/dashboard.md` | — | Dashboard |
| 2 | `Requirements/stock-groups.md` | `inv_stock_groups` | Masters |
| 3 | `Requirements/uoms.md` | `inv_units_of_measure`, `inv_uom_conversions` | Masters |
| 4 | `Requirements/godowns.md` | `inv_godowns` | Masters |
| 5 | `Requirements/asset-categories.md` | `inv_asset_categories` | Masters |
| 6 | `Requirements/stock-items.md` | `inv_stock_items` | Standalone |
| 7 | `Requirements/item-vendor-links.md` | `inv_item_vendor_jnt` | Vendor & Contracts |
| 8 | `Requirements/rate-contracts.md` | `inv_rate_contracts`, `inv_rate_contract_items_jnt` | Vendor & Contracts |
| 9 | `Requirements/purchase-requisitions.md` | `inv_purchase_requisitions`, `inv_purchase_requisition_items` | Procurement |
| 10 | `Requirements/quotations.md` | `inv_quotations`, `inv_quotation_items` | Procurement |
| 11 | `Requirements/purchase-orders.md` | `inv_purchase_orders`, `inv_purchase_order_items` | Procurement |
| 12 | `Requirements/grns.md` | `inv_goods_receipt_notes`, `inv_grn_items` | Procurement |
| 13 | `Requirements/issue-requests.md` | `inv_issue_requests`, `inv_issue_request_items` | Stock Movement |
| 14 | `Requirements/stock-issues.md` | `inv_stock_issues`, `inv_stock_issue_items` | Stock Movement |
| 15 | `Requirements/stock-adjustments.md` | `inv_stock_adjustments`, `inv_stock_adjustment_items` | Stock Movement |
| 16 | `Requirements/stock-ledger.md` | `inv_stock_entries`, `inv_stock_balances` | Stock Movement |
| 17 | `Requirements/asset-register.md` | `inv_assets`, `inv_asset_movements` | Assets |
| 18 | `Requirements/asset-maintenance.md` | `inv_asset_maintenance` | Assets |
| 19 | `Requirements/reports.md` | — (aggregate views) | Reports |

## Key Integrations

| Module | Integration |
|---|---|
| Accounting (ACC) | Voucher posting on GRN acceptance (`GrnAccepted`), Stock Issue (`StockIssued`), Stock Adjustment (`StockAdjusted`). Fixed asset sync (`acc_fixed_assets`). Tax rate and ledger references. |
| Vendor (VND) | Vendor master data for POs, quotations, rate contracts, item-vendor links |
| SchoolSetup (SCH) | Department reference, employee assignments for godown in-charge |
| Notification (NTF) | Reorder alert dispatch, contract expiry alerts, maintenance overdue alerts |
| StudentFee | Asset depreciation feed |
| Payment | Procurement-related payment linkage |

## Stakeholders

| Role | Primary Actions |
|---|---|
| Store Keeper / Inventory Manager | Full inventory operations: item master, stock receipt, issue, adjustments, godown management |
| Purchase Officer | Procurement workflow: PR creation, quotation collection, PO issuance, GRN processing |
| School Admin / Principal | Approval of POs above threshold, stock adjustments above threshold, asset disposal |
| Department Head / HOD | PR creation, issue request approval within department |
| Accountant | Stock valuation review, voucher posting audit, asset register |
| Lab / Department Staff | Create issue requests, view stock availability |
| Asset Manager | Asset register management, maintenance scheduling, transfers |

## Role Permissions

| Operation | Permission Key |
|---|---|
| View any | `tenant.inventory.viewAny` |
| View details | `tenant.inventory.view` |
| Create/Store | `tenant.inventory.create` |
| Update | `tenant.inventory.update` |
| Delete | `tenant.inventory.delete` |
| Approve PR/PO/IR | `tenant.inventory.approve` |
| Direct stock issue | `inventory.stock-issue.direct` |
| View reports | `tenant.inventory.reports` |

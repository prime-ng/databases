# INV — Inventory Module Table Summary
**Module:** Inventory (`Modules\Inventory`) | **Prefix:** `inv_` | **Total:** 28 tables | **Database:** `tenant_db`

| # | Table | Layer | Description |
|---|-------|-------|-------------|
| 1 | `inv_units_of_measure` | L1 | Unit of Measure master (Pcs, Kg, L, Box, etc.); seeded with 10 system UOMs |
| 2 | `inv_asset_categories` | L1 | Asset category master with Income Tax Act WDV depreciation rates and useful life |
| 3 | `inv_stock_groups` | L2 | Hierarchical stock category tree (self-referencing); seeded with 10 system groups |
| 4 | `inv_uom_conversions` | L2 | Bidirectional UOM conversion rules (e.g. 1 Box = 10 Pcs); unique per from/to pair |
| 5 | `inv_stock_items` | L3 | Item catalog with valuation method (FIFO/WAC/LPC), reorder levels, and accounting ledger linkage |
| 6 | `inv_godowns` | L3 | Storage locations; self-referencing hierarchy; seeded with 5 system godowns |
| 7 | `inv_stock_balances` | L4 | Denormalized running stock balance per item per godown; updated atomically with `lockForUpdate()` |
| 8 | `inv_item_vendor_jnt` | L4 | Item-to-vendor mapping with preferred vendor flag, last purchase rate, and lead time |
| 9 | `inv_rate_contracts` | L4 | Vendor rate contracts with validity period; expiry alert 30 days before `valid_to` |
| 10 | `inv_purchase_requisitions` | L4 | Purchase Requisition header; Draft → Submitted → Approved → Converted/Cancelled lifecycle |
| 11 | `inv_stock_adjustments` | L4 | Physical stock audit header; approval required above configurable value threshold (BR-INV-017) |
| 12 | `inv_rate_contract_items_jnt` | L5 | Per-item agreed rates within a vendor rate contract |
| 13 | `inv_purchase_requisition_items` | L5 | PR line items; cascade-deleted with parent PR |
| 14 | `inv_quotations` | L5 | RFQ/Quotation header (one per vendor per PR); supports side-by-side comparison |
| 15 | `inv_issue_requests` | L5 | Stock issue request header; Submitted → Approved → Issued/Partial lifecycle |
| 16 | `inv_quotation_items` | L6 | Quotation line items with quoted rate and lead time; cascade-deleted with parent quotation |
| 17 | `inv_purchase_orders` | L6 | PO header with GST totals, net amount, and approval threshold enforcement (BR-INV-016) |
| 18 | `inv_issue_request_items` | L6 | Issue request line items; `issued_qty` auto-updated on partial/full execution |
| 19 | `inv_stock_adjustment_items` | L6 | Audit line items; `variance_qty` is GENERATED ALWAYS AS (`physical_qty - system_qty`) |
| 20 | `inv_purchase_order_items` | L7 | PO line items; `received_qty` auto-updated by GrnPostingService; triggers PO status transition |
| 21 | `inv_goods_receipt_notes` | L7 | GRN header with QC status; `voucher_id` set on acceptance via GrnAccepted event (D21) |
| 22 | `inv_grn_items` | L8 | GRN line items; `accepted_qty + rejected_qty = received_qty` enforced per BR-INV-006 |
| 23 | `inv_stock_issues` | L8 | Stock issue execution; `voucher_id` linked after Accounting creates Stock Journal (D21) |
| 24 | `inv_stock_entries` | L8 | Immutable stock movement journal; append-only; `voucher_id` mandatory (BR-INV-001, BR-INV-014) |
| 25 | `inv_stock_issue_items` | L9 | Issue execution line items; `unit_cost` from StockValuationService per item valuation method |
| 26 | `inv_assets` | L9 | Fixed asset register; one record per physical unit; auto-created on GRN acceptance for `item_type=asset` |
| 27 | `inv_asset_movements` | L10 | Asset transfer history; records every change of location or assigned employee |
| 28 | `inv_asset_maintenance` | L10 | Asset maintenance log; overdue alert via Artisan command when `next_due_date` passes |

## Cross-Module FK Dependencies (Commented Out — Enable After Module DDL Applied)

| Column | References | Condition |
|--------|-----------|-----------|
| `inv_stock_items.tax_rate_id` | `acc_tax_rates.id` (BIGINT) | After Accounting DDL |
| `inv_stock_items.purchase_ledger_id` | `acc_ledgers.id` (BIGINT) | After Accounting DDL |
| `inv_stock_items.sales_ledger_id` | `acc_ledgers.id` (BIGINT) | After Accounting DDL |
| `inv_godowns.in_charge_employee_id` | `sch_employees.id` (INT) | After SchoolSetup module |
| `inv_item_vendor_jnt.vendor_id` | `vnd_vendors.id` (INT) | After Vendor module |
| `inv_rate_contracts.vendor_id` | `vnd_vendors.id` (INT) | After Vendor module |
| `inv_purchase_requisitions.department_id` | `sch_department.id` (INT) | After SchoolSetup module |
| `inv_quotations.vendor_id` | `vnd_vendors.id` (INT) | After Vendor module |
| `inv_purchase_orders.vendor_id` | `vnd_vendors.id` (INT) | After Vendor module |
| `inv_purchase_order_items.tax_rate_id` | `acc_tax_rates.id` (BIGINT) | After Accounting DDL |
| `inv_goods_receipt_notes.vendor_id` | `vnd_vendors.id` (INT) | After Vendor module |
| `inv_goods_receipt_notes.voucher_id` | `acc_vouchers.id` (BIGINT) | After Accounting DDL (D21) |
| `inv_stock_issues.issued_to_employee_id` | `sch_employees.id` (INT) | After SchoolSetup module |
| `inv_stock_issues.department_id` | `sch_department.id` (INT) | After SchoolSetup module |
| `inv_stock_issues.voucher_id` | `acc_vouchers.id` (BIGINT) | After Accounting DDL (D21) |
| `inv_stock_entries.voucher_id` | `acc_vouchers.id` (BIGINT) | After Accounting DDL (D21) — **NOT NULL** |
| `inv_stock_entries.party_ledger_id` | `acc_ledgers.id` (BIGINT) | After Accounting DDL |
| `inv_assets.acc_fixed_asset_id` | `acc_fixed_assets.id` (BIGINT) | After Accounting DDL |
| `inv_assets.assigned_employee_id` | `sch_employees.id` (INT) | After SchoolSetup module |
| `inv_asset_movements.from_employee_id` | `sch_employees.id` (INT) | After SchoolSetup module |
| `inv_asset_movements.to_employee_id` | `sch_employees.id` (INT) | After SchoolSetup module |
| `inv_asset_maintenance.vendor_id` | `vnd_vendors.id` (INT) | After Vendor module |

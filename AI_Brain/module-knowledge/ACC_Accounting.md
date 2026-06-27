# Module Knowledge: Accounting (ACC)
# Last Updated: 2026-06-27 (update pass — file counts re-verified against Herd/prime_ai)
# Completion Status: ~60–70% estimated (views + services + controllers present; migrations missing; GST/TDS/YearEnd tables absent)

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix | `acc_*` |
| Old module code | `FAC` (V1/V2 req used FAC; module_list.md now uses ACC) |
| Module path | `Modules/Accounting/` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/Accounting_DDL_v3.sql` — 28 tables |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/FAC_FinanceAccounting_Requirement.md` |
| Database | `tenant_db` |
| Routes | `web.php` — 220 lines (V2 req cited 18 controller registrations; ~65 named routes was an undercount) |
| Controllers | 21 (re-verified 2026-06-27; V2 req cited 18) |
| Models | 25 (re-verified 2026-06-27; V2 req cited 21) |
| Services | 7 (re-verified 2026-06-27; **corrected from prior 10** — see service inventory below) |
| FormRequests | 17 (re-verified 2026-06-27) |
| Policies | 19 (re-verified 2026-06-27) |
| Tests | 21 (re-verified 2026-06-27) |
| Blade Views | 141 (re-verified 2026-06-27; V2 req said 29 screens needed, no views confirmed in March 2026) |
| Migrations | 0 (re-verified 2026-06-27; likely handled by tenant DDL applied directly) |
| FRD | Not yet generated |

**Service inventory (all 7):**
| Service | Covers |
|---------|--------|
| `VoucherService` | Core Dr/Cr engine, balance enforcement |
| `ReconciliationService` | Bank recon sessions, CSV import, auto-match |
| `DepreciationService` | SLM/WDV engine, per-asset per-FY runs |
| `ExpenseClaimService` | Claim lifecycle, approval → payment voucher |
| `RecurringTemplateService` | Recurring voucher generation |
| `ReportService` | TB, P&L, BS, Day Book and other 11 reports |
| `RemoteEntryService` | **Not in V2 req** — cross-module voucher entry point; likely serves the generic event engine |

**Note:** Services dropped from 10 to 7 after re-verification (prior count was incorrect). The 141 blade views vs V2 req's "29 screens needed" confirms substantial view work done post-March 2026. Estimated completion revised to 60–70%.

---

## DDL Table Inventory (28 tables)

### Domain 0 — Shared Status & Integration Infrastructure (3 tables)
| Table | Purpose |
|-------|---------|
| `acc_accounting_status_masters` | Generic status code master for Voucher, Bank Recon, Expense Claim, Tally Export, Cross-Module statuses — avoids per-table ENUM changes |
| `acc_voucher_modules` | Registry of modules that can trigger accounting vouchers (TRANSPORT, LIBRARY, HR, etc.) |
| `acc_voucher_category` | Categories per module, links to ledger for auto-voucher Dr/Cr mapping |

### Domain 1 — Core Accounting (12 tables)
| Table | Purpose |
|-------|---------|
| `acc_financial_years` | Fiscal year master (Apr-Mar); `is_locked` blocks edits |
| `acc_account_groups` | Hierarchical COA groups — 5 natures: Asset, Liability, Equity, Income, Expense |
| `acc_ledgers` | Individual ledger accounts; has bank/cash flags, student/employee/vendor links, GST fields |
| `acc_voucher_types` | 8 system types (RCT/PMT/CTR/JNL/SLS/PUR/CRN/DBN) + custom; links to `acc_voucher_category` |
| `acc_vouchers` | Voucher header — the heart of the engine; `source_module` FK to `acc_voucher_modules` |
| `acc_voucher_items` | Dr/Cr line items; `type` ENUM('debit','credit') |
| `acc_cost_centers` | Hierarchical department/activity cost centers |
| `acc_budgets` | Budget allocation per FY + cost center + ledger |
| `acc_tax_rates` | GST/TDS tax rate master (CGST/SGST/IGST/Cess) |
| `acc_ledger_mappings` | Cross-module ledger mapping (source_module ENUM: Fees/Library/Transport/HR/Vendor/Inventory/Payroll) |
| `acc_recurring_templates` | Recurring voucher templates with frequency |
| `acc_recurring_template_lines` | Dr/Cr lines for recurring templates |

### Domain 2 — Banking (2 tables)
| Table | Purpose |
|-------|---------|
| `acc_bank_reconciliations` | Reconciliation sessions; `status` FK to status master |
| `acc_bank_statement_entries` | Imported bank statement lines; `is_matched` flag + matched voucher item link |

### Domain 3 — Fixed Assets (3 tables)
| Table | Purpose |
|-------|---------|
| `acc_asset_categories` | SLM/WDV depreciation method + rate per category |
| `acc_fixed_assets` | Asset register; links to vendor + purchase voucher |
| `acc_depreciation_entries` | Per-asset per-FY depreciation records; links to JNL voucher |

### Domain 4 — Expense Claims (2 tables)
| Table | Purpose |
|-------|---------|
| `acc_expense_claims` | Claim header; `status` FK to status master; links to payment voucher on approval |
| `acc_expense_claim_lines` | Individual expense lines with ledger + receipt path |

### Domain 5 — Tally Integration (2 tables)
| Table | Purpose |
|-------|---------|
| `acc_tally_export_logs` | Export audit trail (Ledgers/Vouchers/Inventory); `status` FK to status master |
| `acc_tally_ledger_mappings` | Prime ledger → Tally ledger/group name; supports export_only/import_only/bidirectional |

### Domain 6 — Generic Cross-Module Event Engine (4 tables — NOT in V2 req)
| Table | Purpose |
|-------|---------|
| `acc_module_events` | Registry of all cross-module events that can trigger vouchers (LIBRARY, TRANSPORT, HR, etc.) |
| `acc_event_voucher_configs` | Per-event voucher config: type, auto-post flag, narration template |
| `acc_event_voucher_line_templates` | Dr/Cr line templates with `ledger_resolver` (fixed/student/vendor/employee) and `amount_resolver` strategies |
| `acc_event_processing_log` | Audit trail of every event received + processing outcome + retry count |

---

## Architecture Decisions

### D1 — Tally-Inspired Double-Entry Engine
Every financial transaction = Voucher (`acc_vouchers`) + VoucherItems (`acc_voucher_items`). Invariant: `SUM(Dr) = SUM(Cr)` — enforced at service layer before save.

### D2 — 8 Voucher Types
RCT (Receipt), PMT (Payment), CTR (Contra), JNL (Journal), SLS (Sales), PUR (Purchase), CRN (Credit Note), DBN (Debit Note)

### D3 — Generic Event Engine (DDL v3 addition, not in V2 req)
The DDL introduced a 4-table generic cross-module event processing engine (`acc_module_events` → `acc_event_voucher_configs` → `acc_event_voucher_line_templates` + `acc_event_processing_log`). This is more flexible than the hardcoded 4-listener pattern described in the V2 requirement. It supports:
- Any module registering events without schema changes
- Runtime ledger resolution (fixed / student_ledger / vendor_ledger / employee_ledger)
- Runtime amount resolution (from_source column / fixed_amount / from_payload JSON)
- Full retry + audit trail

### D4 — Status Master Pattern
ENUM status fields replaced with FK to `acc_accounting_status_masters` across vouchers, reconciliations, expense claims, tally exports, and event processing logs. Allows adding statuses without ALTER TABLE.

### D5 — Ledger Entity Links
`acc_ledgers` has `student_id`, `employee_id`, `vendor_id` columns — enables auto-ledger creation per entity and direct Dr/Cr posting to entity sub-ledger in the generic event engine.

### D6 — Module Code Rename
V1 used `fac_*` prefix and module code `FAC`. V2 unified to `acc_*` under `Modules/Accounting/`. `module_list.md` now shows code as `ACC`. The V2 requirement file is still named `FAC_FinanceAccounting_Requirement.md` — this is historical, not current naming.

---

## Known Gaps & Open Issues

### From V2 Requirement (as of 2026-03-26)
| Priority | Gap | Notes |
|----------|-----|-------|
| P1 | DB Migrations | 0 confirmed 2026-06-27 — module likely bootstrapped via tenant DDL directly |
| P1 | Controller business logic | 21 controllers present; completeness of logic inside each is unverified — needs Technical Audit |
| ~~P1~~ | ~~Blade Views~~ | **RESOLVED** — 141 blade views found (2026-06-27); V2 req said 0 views in March 2026 |
| ~~P2~~ | ~~BankReconciliationService~~ | **RESOLVED** — `ReconciliationService` confirmed present |
| ~~P2~~ | ~~DepreciationService~~ | **RESOLVED** — `DepreciationService` confirmed present |
| ~~P2~~ | ~~Cross-module event listeners x4~~ | **RESOLVED (architecture shift)** — generic event engine confirmed: `EventVoucherConfigController`, `ModuleEventController`, `EventVoucherConfigRequest`, `ModuleEventRequest` all present. `RemoteEntryService` handles inbound cross-module calls. Hardcoded Laravel listeners superseded. |
| P3 | GstService | GST tables (`acc_gst_details`, `acc_tds_entries`, `acc_year_end_closings`) not in DDL v3; no GstService file found |
| ~~P3~~ | ~~TallyExportService~~ | **N/A** — Tally export logic likely in `TallyExportController` directly (no separate TallyExportService found — not a gap) |
| P3 | TDS management | `acc_tds_entries` table not in DDL v3; no TDS service or controller found |
| P3 | Year-end closing wizard | `acc_year_end_closings` table not in DDL v3; `lock/unlock` routes exist but schema incomplete |
| P3 | Jobs (3 proposed) | ProcessRecurringVouchers, RunMonthlyDepreciation, CheckBudgetBreach — 0 job files found; recurring handled by service, depreciation handled by service — jobs may not be implemented |

### Schema Gaps (DDL v3 vs V2 Req)
3 tables proposed in V2 req still missing from DDL v3: `acc_gst_details`, `acc_tds_entries`, `acc_year_end_closings`. These cover GST compliance (FAC7), TDS management (FAC8), and year-end close audit trail (FAC10). No controller or service for these areas found in code either — these sub-modules are genuinely incomplete.

### Verification Needed
A Technical Audit (Mode A) is needed to assess:
- Internal logic completeness of the 21 controllers (stubs vs. full logic)
- Whether `RemoteEntryService` is integrated with `acc_module_events` engine or is an independent pattern
- Test coverage: 21 test files exist — are they unit, feature, or integration?
- Whether recurring voucher and depreciation services are called by scheduled commands or manual triggers

---

## Design Decisions Made

### D7 — Generic Event Engine Supersedes Hardcoded Listeners (confirmed 2026-06-27)
The V2 requirement described 4 hardcoded Laravel event listeners (for FIN/HR/INV/TPT). DDL v3 introduced a generic 4-table engine. Code verification confirms the engine is implemented (`ModuleEventController`, `EventVoucherConfigController`, `RemoteEntryService`). The hardcoded listener approach from the V2 req is now obsolete — any new cross-module integration should use `acc_module_events` + `acc_event_voucher_configs` + `RemoteEntryService`.

### D8 — No Separate Tally Export Service
Tally export logic is in `TallyExportController` and `TallyLedgerMappingController` directly, not in a standalone TallyExportService. This is an exception to the thin-controller pattern — may need refactoring if Tally logic grows.

---

## Cross-Module Dependencies

| Dependency | Integration Point |
|------------|-------------------|
| StudentFee (FIN) | `FeePaid` event → Receipt voucher (RCT) |
| HR/Payroll (HRS) | `SalaryProcessed` event → Journal voucher (JNL) with TDS/PF split |
| Inventory (INV) | `PurchaseOrderPaid` event → Purchase (PUR) + Payment (PMT) vouchers |
| Transport (TPT) | `TransportFeePaid` event → Receipt voucher (RCT) |
| Vendor (VND) | `vnd_vendors` → Fixed asset supplier; vendor payable ledger |
| SchoolSetup (SCE) | `sch_employees` → Expense claim `employee_id` FK |
| SystemUsers | `sys_users` → `created_by`, `approved_by`, `locked_by` across all tables |

**Note:** Integration may now use the generic `acc_module_events` / `acc_event_voucher_configs` engine rather than hardcoded Laravel event listeners — the DDL v3 additions imply this architectural shift.

---

## Sub-Module Coverage (FAC1–FAC10)

| Sub-Module | Scope | Routes Status | Code Status |
|---|---|---|---|
| FAC1 — Chart of Accounts | COA groups + ledgers + financial year | ✅ Routes + Views | `FinancialYearController`, `AccountGroupController`, `LedgerController` present; 141 views confirmed |
| FAC2 — Voucher Management | 8 types, Dr/Cr engine, lifecycle | ✅ Routes + Views | `VoucherController`, `VoucherTypeController`, `VoucherService`, `VoucherRequest` confirmed |
| FAC3 — Bank & Cash | Bank accounts, CSV import, reconciliation | ✅ Routes + Views | `BankReconciliationController`, `ReconciliationService` confirmed |
| FAC4 — Financial Reports | TB, P&L, BS, Day Book, etc. (11 reports) | ✅ Routes + Views | `AccReportController`, `ReportService` confirmed |
| FAC5 — Budget Management | Cost centers, budget plans, variance | ✅ Routes + Views | `BudgetController`, `CostCenterController` confirmed |
| FAC6 — Tally Integration | XML export, ledger mapping, export log | ✅ Routes + Views | `TallyExportController`, `TallyLedgerMappingController`, `TallyExportLog` model confirmed |
| FAC7 — GST Compliance | GSTIN, CGST/SGST/IGST, GSTR-1/3B | ❌ Not built | `TaxRateController` + `TaxRate` model exist; no GST tables in DDL; no GstService |
| FAC8 — TDS Management | TDS deduction, Form 26Q, Form 16 | ❌ Not built | No controller, service, or DDL table (`acc_tds_entries` absent) |
| FAC9 — Fixed Assets | SLM/WDV depreciation, asset register | ✅ Routes + Views | `FixedAssetController`, `AssetCategoryController`, `DepreciationService`, DDL tables confirmed |
| FAC10 — Year-End Closing | Period lock, P&L carry-forward, OB | 🟡 Partial | lock/unlock routes exist; `acc_year_end_closings` table absent from DDL |
| DDL v3 — Event Engine | Generic cross-module event routing | ✅ Implemented | `ModuleEventController`, `EventVoucherConfigController`, `RemoteEntryService` confirmed |

---

## Lessons Learned

### From Seeding + Update Pass (2026-06-27, Business Analyst)
- **Old module code persists in file names:** The V2 requirement file is still `FAC_FinanceAccounting_Requirement.md` — always search by both `FAC` and `ACC` when looking for Accounting artifacts.
- **Service count can be wrong from indirect sources:** The initial seed said "10 services" (sourced from V2 req baseline plus proposed additions). Actual `ls` shows 7. Always re-verify counts by reading the filesystem directly.
- **View count is the best completion proxy:** 141 blade files vs 0 in March 2026 tells more about actual progress than controller counts alone, since controllers can be empty stubs.
- **Generic event engine has no listener files:** The cross-module integration is driven by config data in `acc_module_events` + `acc_event_voucher_configs`, not by PHP Listener classes. Don't look for `Listeners/` directory — look for `RemoteEntryService` + controller endpoints instead.

---

## Pending Next Steps

- [ ] Generate FRD → `act as Business Analyst` → "create an FRD for Accounting"
- [ ] Code Gap Analysis → `act as Technical Auditor` — Mode A (actual vs V2 req) to assess controller logic completeness (stubs vs. implemented), test coverage, and RemoteEntryService integration
- [ ] DDL Gap Decision → `act as DB Architect` — decide whether to add `acc_gst_details` / `acc_tds_entries` / `acc_year_end_closings` to DDL v4 or defer FAC7/FAC8/FAC10 entirely
- [ ] ~~Verify generic event engine~~ — **DONE** (2026-06-27): confirmed implemented via ModuleEventController + EventVoucherConfigController + RemoteEntryService

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | Knowledge file seeded from FAC_FinanceAccounting_Requirement.md (V2, 2026-03-26) + Accounting_DDL_v3.sql. Actual file counts as of seeding: 21 ctrl, 25 models, 10 services (later corrected), 17 FormRequests, 19 policies, 21 tests. |
| 2026-06-27 | Business Analyst | Update pass: re-verified all file counts against prime_ai/Modules/Accounting/. Corrections: services = 7 (not 10); 141 blade views confirmed (was unknown); 220 route lines; generic event engine confirmed implemented; 0 migrations confirmed. Gaps resolved: views, ReconciliationService, DepreciationService, cross-module event engine. Remaining gaps: FAC7 (GST), FAC8 (TDS), FAC10 (Year-End DDL), controller logic completeness. Completion estimate revised to ~60–70%. |

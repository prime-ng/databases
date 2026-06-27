# Module Knowledge Summary: Accounting (ACC)

**Date:** 2026-06-27
**Agent:** Business Analyst
**Source Files:**
- `4-Requirement_Module_wise/4-Initial_Requirements/V2/FAC_FinanceAccounting_Requirement.md` (V2, dated 2026-03-26)
- `2-DDL_Tenant_Consolidated/Accounting_DDL_v3.sql`
- `Herd/prime_ai/Modules/Accounting/` (live filesystem verification)

**Knowledge File:** `AI_Brain/module-knowledge/ACC_Accounting.md`

---

## 1. Module Identity

| Item | Finding |
|------|---------|
| Module Code | `ACC` (current) |
| Old Module Code | `FAC` — all V1/V2 requirement docs and the current V2 requirement file (`FAC_FinanceAccounting_Requirement.md`) still use the old code. The codebase uses `ACC` and `acc_*` prefix. |
| Table Prefix | `acc_*` |
| Database | `tenant_db` (per-school, no `tenant_id` columns) |
| Laravel Path | `Modules/Accounting/` |
| DDL Version | v3 (April 2026) — significant additions over V2 req baseline |

**Key Risk:** The module code rename from `FAC` → `ACC` is not reflected in the requirement filename. Any agent searching for `ACC_*` in `4-Initial_Requirements/V2/` will find nothing. Always search by both `FAC` and `ACC`.

---

## 2. Actual vs. Baseline Comparison

The V2 requirement was written in March 2026. The update pass compared actuals from June 2026.

| Metric | V2 Req Baseline (Mar 2026) | Actual (Jun 2026) | Change |
|--------|---------------------------|-------------------|--------|
| Controllers | 18 proposed | **21** | +3 |
| Models | 21 proposed | **25** | +4 |
| Services | 6 proposed | **7** actual | +1 |
| FormRequests | 0 confirmed | **17** | New |
| Policies | Not mentioned | **19** | New |
| Tests | 0 confirmed | **21** | New |
| Blade Views | 29 screens needed, 0 confirmed | **141** | Major growth |
| Route Lines | ~65 named routes (estimate) | **220** | 3× estimate |
| Migrations | 0 | **0** | No change |
| Completion % | ~30% | **~60–70%** | Doubled |

**Learning:** A V2 requirement written in March 2026 significantly under-represents the actual state by June 2026. Seeding from a requirement doc without verifying the filesystem gives an accuracy floor of ~30%; actual state can be 2× higher.

---

## 3. DDL Architecture: What Was Designed vs. What the Requirement Said

### 3.1 V2 Requirement → DDL v3 Evolution

The V2 requirement described a Tally-inspired double-entry engine with 4 hardcoded Laravel event listeners for cross-module integration. DDL v3 (April 2026) introduced a fundamentally different, more flexible architecture.

### 3.2 The Generic Cross-Module Event Engine (DDL v3 Addition — Not in V2 Req)

**Finding:** DDL v3 added 4 tables that do not appear anywhere in the V2 requirement document:

| Table | Role |
|-------|------|
| `acc_module_events` | Registry of all cross-module events (LIBRARY, TRANSPORT, HR, etc.) |
| `acc_event_voucher_configs` | Per-event voucher configuration: type, auto-post flag, narration template |
| `acc_event_voucher_line_templates` | Dr/Cr line templates with runtime ledger + amount resolution strategies |
| `acc_event_processing_log` | Full audit trail — every event received, outcome, retry count |

**Significance:** This engine replaces the V2 requirement's proposed 4 hardcoded listeners (`FIN/HR/INV/TPT`). Any new module integration should use `acc_module_events` + `acc_event_voucher_configs` + `RemoteEntryService` — **not** create new Laravel Listener classes.

**Confirmed implemented in code:** `ModuleEventController`, `EventVoucherConfigController`, `EventVoucherConfigRequest`, `ModuleEventRequest` all present. `RemoteEntryService` serves as the inbound cross-module entry point.

### 3.3 DDL Table Inventory (28 tables, 6 domains)

| Domain | Tables | Count |
|--------|--------|-------|
| D0 — Infrastructure | `acc_accounting_status_masters`, `acc_voucher_modules`, `acc_voucher_category` | 3 |
| D1 — Core Accounting | `acc_financial_years`, `acc_account_groups`, `acc_ledgers`, `acc_voucher_types`, `acc_vouchers`, `acc_voucher_items`, `acc_cost_centers`, `acc_budgets`, `acc_tax_rates`, `acc_ledger_mappings`, `acc_recurring_templates`, `acc_recurring_template_lines` | 12 |
| D2 — Banking | `acc_bank_reconciliations`, `acc_bank_statement_entries` | 2 |
| D3 — Fixed Assets | `acc_asset_categories`, `acc_fixed_assets`, `acc_depreciation_entries` | 3 |
| D4 — Expense Claims | `acc_expense_claims`, `acc_expense_claim_lines` | 2 |
| D5 — Tally Integration | `acc_tally_export_logs`, `acc_tally_ledger_mappings` | 2 |
| D6 — Event Engine | `acc_module_events`, `acc_event_voucher_configs`, `acc_event_voucher_line_templates`, `acc_event_processing_log` | 4 |

### 3.4 Schema Gaps (V2 Req Tables Not in DDL v3)

| Missing Table | Sub-Module | Impact |
|---------------|-----------|--------|
| `acc_gst_details` | FAC7 — GST Compliance | GSTR-1/3B reporting impossible |
| `acc_tds_entries` | FAC8 — TDS Management | Form 26Q/Form 16 impossible |
| `acc_year_end_closings` | FAC10 — Year-End Close | Year-end close audit trail missing |

**Verdict:** FAC7, FAC8, and FAC10 are not only unimplemented in code — they are also unimplemented in the DDL. These three sub-modules are genuinely deferred, not just pending code work.

---

## 4. Service Inventory & Composition

**Corrected count: 7 services** (the V2 req proposed 6; an earlier seeding record showed 10 — both wrong).

| Service | Sub-Module Coverage |
|---------|-------------------|
| `VoucherService` | Core Dr/Cr engine, balance enforcement (FAC2) |
| `ReconciliationService` | Bank recon sessions, CSV import, auto-match (FAC3) |
| `DepreciationService` | SLM/WDV engine, per-asset per-FY runs (FAC9) |
| `ExpenseClaimService` | Claim lifecycle, approval → payment voucher |
| `RecurringTemplateService` | Recurring voucher generation |
| `ReportService` | Trial Balance, P&L, BS, Day Book and 7 other reports (FAC4) |
| `RemoteEntryService` | **Not in V2 req** — cross-module voucher entry point for the generic event engine |

**Learning:** `RemoteEntryService` is an architectural innovation introduced after the V2 requirement was written. It is the inbound API for the generic event engine. Its presence confirms the shift from hardcoded listeners to the config-driven `acc_module_events` pattern.

---

## 5. Sub-Module Completion Assessment

| Sub-Module | Status | Evidence |
|-----------|--------|---------|
| FAC1 — Chart of Accounts | ✅ Implemented | FinancialYearController, AccountGroupController, LedgerController, 141 views |
| FAC2 — Voucher Management | ✅ Implemented | VoucherController, VoucherTypeController, VoucherService |
| FAC3 — Bank & Cash | ✅ Implemented | BankReconciliationController, ReconciliationService |
| FAC4 — Financial Reports | ✅ Implemented | AccReportController, ReportService |
| FAC5 — Budget Management | ✅ Implemented | BudgetController, CostCenterController |
| FAC6 — Tally Integration | ✅ Implemented | TallyExportController, TallyLedgerMappingController |
| FAC7 — GST Compliance | ❌ Not built | No DDL tables, no service, TaxRateController exists but covers only tax rate master |
| FAC8 — TDS Management | ❌ Not built | No DDL tables, no controller, no service |
| FAC9 — Fixed Assets | ✅ Implemented | FixedAssetController, AssetCategoryController, DepreciationService |
| FAC10 — Year-End Closing | 🟡 Partial | lock/unlock routes exist; `acc_year_end_closings` table missing from DDL |
| DDL v3 Event Engine | ✅ Implemented | ModuleEventController, EventVoucherConfigController, RemoteEntryService |

**Overall: 8 of 11 sub-modules implemented → ~60–70% completion**

---

## 6. Open Gaps & Recommended Actions

### 6.1 Immediate (P1)

| Gap | Recommended Action |
|-----|-------------------|
| 0 migrations | Create tenant migration files for all 28 `acc_*` tables |
| Controller logic completeness unknown | Technical Audit (Mode A) — are controllers stubs or fully implemented? |
| `RemoteEntryService` integration | Verify it is wired into `acc_module_events` / `acc_event_voucher_configs` engine (or is it a standalone pattern?) |

### 6.2 Architectural Decision Needed (P2)

| Decision | Context |
|----------|---------|
| Tally export service vs. controller | Tally export logic sits in `TallyExportController` + `TallyLedgerMappingController` directly — no `TallyExportService` found. As Tally logic grows, this becomes a fat controller. Decide: extract service or leave in controller. |
| FAC10 Year-End Close | `acc_year_end_closings` table is absent from DDL v3. Lock/unlock routes exist. Decide: add the table to DDL v4, or document that year-end close is admin-managed via period lock flag only (simpler). |

### 6.3 Deferred Sub-Modules (P3)

| Sub-Module | Decision |
|-----------|---------|
| FAC7 — GST Compliance | Requires `acc_gst_details` DDL table + GstService. Significant scope. Recommend scoping separately as GST sprint before assessment period. |
| FAC8 — TDS Management | Requires `acc_tds_entries` DDL table + TdsService + Form 26Q/16 generation. Significant scope. Recommend deferring to FY end sprint. |

---

## 7. Architecture Decisions Confirmed

| Decision | Summary |
|----------|---------|
| D1 — Double-Entry Engine | Every transaction = Voucher header + VoucherItems. `SUM(Dr) = SUM(Cr)` enforced at service layer before save. |
| D2 — 8 Voucher Types | RCT, PMT, CTR, JNL, SLS, PUR, CRN, DBN — 8 system types + custom. |
| D3 — Generic Event Engine | Config-driven, not listener-driven. `acc_module_events` → `acc_event_voucher_configs` → `acc_event_voucher_line_templates`. `RemoteEntryService` is the inbound bridge. |
| D4 — Status Master Pattern | Status ENUMs replaced with FK to `acc_accounting_status_masters` across all major tables — avoids ALTER TABLE for new statuses. |
| D5 — Ledger Entity Links | `acc_ledgers` has `student_id`, `employee_id`, `vendor_id` — enables auto-ledger creation per entity and direct Dr/Cr posting. |
| D6 — No Separate Tally Service | Tally logic in controllers directly. Exception to thin-controller pattern — monitor for fat controller risk. |

---

## 8. Cross-Module Integration Map

| Downstream Module | Integration Point | Status |
|-------------------|------------------|--------|
| StudentFee (FIN) | `FeePaid` event → RCT voucher via event engine | Engine ready; integration config TBD |
| HR/Payroll (HRS) | `SalaryProcessed` → JNL voucher with TDS/PF split | Engine ready; FAC8 (TDS) not built |
| Inventory (INV) | `PurchaseOrderPaid` → PUR + PMT vouchers | Engine ready; integration config TBD |
| Transport (TPT) | `TransportFeePaid` → RCT voucher | Engine ready; integration config TBD |
| Vendor (VND) | `vnd_vendors` → fixed asset supplier + vendor payable ledger | Via `acc_ledgers.vendor_id` |
| SchoolSetup (SCE) | `sch_employees` → expense claim employee FK | Direct FK in `acc_expense_claims` |

---

## 9. Key Lessons Learned

1. **Requirement file naming is frozen at V1 code:** `FAC_FinanceAccounting_Requirement.md` retains the old module code. Search using both `FAC` and `ACC` when looking for Accounting artifacts.

2. **V2 requirement (March 2026) understated actual progress by ~30%:** 141 views, 21 tests, 17 FormRequests, and 19 policies all existed by June 2026 but were "0 confirmed" in the V2 req. The gap between req doc baseline and actual state can be large for actively developed modules.

3. **DDL v3 introduced an architectural shift not in any requirement document:** The generic event engine (D6 tables) is the most significant design decision in this module and it exists only in the DDL — not in the V2 requirement, not in any FRD. Future FRD generation must read DDL v3 alongside the requirement doc, or it will miss this entirely.

4. **`RemoteEntryService` is undocumented:** No requirement doc, no FRD, no knowledge entry existed for this service before this session. It was discovered only by reading the actual `app/Services/` directory. It is architecturally significant — any cross-module integration with Accounting flows through it.

5. **Service counts from requirement docs are unreliable:** The V2 req proposed 6 services; an earlier pass counted 10; actual is 7. The only reliable count is `ls app/Services/`.

---

## 10. Recommended Next Steps

| Priority | Action | Agent |
|----------|--------|-------|
| 1 | Generate FRD — must read DDL v3 alongside V2 req to capture event engine | Business Analyst → "create an FRD for Accounting" |
| 2 | Technical Audit (Mode A) — assess controller logic completeness, test coverage (21 tests: unit vs. feature?), RemoteEntryService integration | Technical Auditor |
| 3 | DDL decision on FAC10 — add `acc_year_end_closings` or document lock-only approach | DB Architect |
| 4 | Create tenant migrations for all 28 acc_* tables | Developer |
| 5 | Scope FAC7 (GST) and FAC8 (TDS) as separate sprints — significant scope requiring new DDL tables | Business Analyst + DB Architect |

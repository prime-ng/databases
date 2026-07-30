# Tally Export — Business Requirements

## What This Screen Does

The Tally Export screen generates TALLYXML files for export to Tally ERP. It supports three export types: vouchers, ledgers, and stock items. Each export is logged with status tracking (pending → processing → completed/failed), and the generated XML can be viewed and downloaded.

## When This Screen Is Used

- **When migrating accounting data** from this system to Tally ERP.
- **For periodic data sync** with Tally (daily/weekly voucher exports).
- **When exporting master data** (ledgers, stock items) for Tally setup.

## Key Fields

**Export Configuration:**
- **Export Type** (enum: vouchers/ledgers/stock) — What to export
- **From Date** (date) — Start of date range
- **To Date** (date) — End of date range
- **Voucher Type IDs** (array, nullable) — Filter by voucher types (for vouchers export)
- **Ledger IDs** (array, nullable) — Filter by ledgers (for ledgers export)

**Export Log:**
- **Status** (enum: pending/processing/completed/failed)
- **Total Vouchers** (integer)
- **Successful Vouchers** (integer)
- **Failed Vouchers** (integer)
- **XML Content** (longtext) — Generated TALLYXML
- **Error Message** (text, nullable)
- **Exported By** (FK → sys_users)
- **Exported At** (timestamp)

## Business Rules

**TALLYXML Generation:**
The export service generates XML conforming to Tally's import format. Each export type produces the appropriate XML structure (VOUCHER, LEDGER, or STOCK entries).

**Date Range Filtering:**
Exports are filtered by from_date and to_date. All three export types support date filtering.

**Type-Specific Filters:**
- Vouchers export: optional voucher_type_ids filter
- Ledgers export: optional ledger_ids filter
- Stock export: no additional filters

**Logging:**
Every export creates a log entry. The log tracks status through each phase. On failure, the error message is recorded. The generated XML is stored in the log for later viewing/download.

**Large Dataset Risk:**
There is no pagination/chunking in the XML generation. Large datasets may cause timeout or memory issues.

## Workflow

1. User navigates to Accounting → Assets & Integration → Tally Export.
2. User selects export type, date range, optional filters.
3. System generates XML and creates a log entry.
4. User can view the XML content or download it.
5. Export history is available showing past exports, status, and results.

## Requirements

- MUST display at `/accounting/tally-export?tab=tally-export` as paginated table (logs)
- MUST authorize via `tenant.accounting.tally-export.*` policy gates
- MUST support 3 export types: vouchers, ledgers, stock
- MUST generate valid TALLYXML format for each type
- MUST support date range filtering
- MUST support voucher_type_ids filter for vouchers export
- MUST support ledger_ids filter for ledgers export
- MUST log every export with status tracking
- MUST store generated XML in the log for viewing/download
- MUST support soft delete with trash view, restore, forceDelete
- **SHOULD** implement chunking/pagination for large datasets

# Tally Integration — Business Requirements

## Business Need
Most Indian schools maintain parallel books in Tally Prime for CA filing and statutory compliance. Manually re-entering all transactions from our system into Tally is time-consuming and error-prone. The Tally Integration module enables schools to export ledgers and vouchers in Tally-compatible XML format, with a mapping layer that links our accounts to their Tally equivalents.

## Business Objectives
- Export ledgers and vouchers in Tally-compatible XML format
- Maintain a mapping between our ledgers and their Tally ledger names
- Track export history for audit purposes
- Support bidirectional sync directions (export only / import / bidirectional)
- Provide ready-made mappings for all seeded accounts (28 Tally groups + 11 default ledgers)

## User Stories

**As School Accountant,** I want to:
- Map each of our ledgers to the correct Tally ledger name
- View all Tally mappings in one place — see which ledgers are mapped and which are not
- Export all ledgers to Tally-compatible XML
- Export vouchers for a specific date range to Tally XML
- Download the generated XML file for import into Tally
- Review the export log to see what was exported, when, and by whom
- Know if an export failed and see the error details

**As CA / Tax Consultant,** I want to:
- Receive a Tally-compatible XML file that I can directly import into Tally Prime
- Verify that ledgers are mapped correctly before import
- Have export logs for audit trail

## Key Business Rules

**Mapping Rules**
- Each ledger can have exactly one Tally mapping (one-to-one)
- Mapping is optional — unmapped ledgers are excluded from exports
- Auto-mapped records are seeded for 28 Tally groups + 11 default ledgers
- Manual mappings allow schools to configure custom ledger-to-Tally links

**Export Types**
- **Ledgers:** Export all active ledgers with their groups
- **Vouchers:** Export posted vouchers in a date range with Dr/Cr entries
- **Inventory:** Export stock items (if applicable)

**Sync Directions**
- **Export Only (default):** Our system → Tally (one-way push)
- **Import Only:** Tally → Our system (one-way pull)
- **Bidirectional:** Both directions supported

**Export Process**
1. User selects export type and date range
2. System queries active ledgers/vouchers with their Tally mappings
3. Generates Tally-compatible XML following Tally's schema
4. File is saved, download link provided, export is logged

## Seeded Data
~40 auto-mapped entries:
- 28 Tally standard groups mapped to corresponding account groups
- 11 default ledgers mapped to their Tally names (Cash A/c, Bank A/c, etc.)
- All seeded as "auto" mapping type

## Stakeholders

| Stakeholder | Interest |
|---|---|
| School Accountant | Maps ledgers, runs exports |
| CA / Tax Consultant | Imports XML into Tally for filing |
| School Admin / Bursar | Ensures books are in sync with Tally |

## Permissions

| Role | Access |
|---|---|
| School Admin | Full access to Tally mappings and exports |
| Accountant | Configure mappings, run exports |
| Auditor | View mapping and export logs |

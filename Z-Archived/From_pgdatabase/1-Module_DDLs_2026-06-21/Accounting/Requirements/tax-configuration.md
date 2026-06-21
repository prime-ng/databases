# Tax Configuration — Business Requirements

## Business Need
Indian schools must comply with GST regulations for taxable services (transport, canteen, certain supplies) while tuition fees are GST-exempt. The system must support CGST, SGST, IGST, and Cess with proper HSN/SAC codes, and generate data for GSTR-1 and GSTR-3B compliance filings.

## Business Objectives
- Configure GST tax rates for applicable school services
- Support CGST + SGST (intra-state) and IGST (inter-state) tax models
- Auto-compute tax on voucher transactions based on ledger configuration
- Generate GSTR-1 (outward supply) and GSTR-3B (summary) data for CA filing
- Track HSN/SAC codes per tax rate for compliance

## User Stories

**As School Accountant,** I want to:
- View all configured tax rates (CGST, SGST, IGST, Cess) with their percentages
- Create new tax rates as needed (e.g., "CGST 9%", "SGST 9%")
- Assign HSN/SAC codes to each tax rate for GST compliance
- Configure whether a ledger is GST-registered or not
- Mark whether a transaction is intra-state (CGST+SGST) or inter-state (IGST)
- Generate GSTR-1 data for a given tax period (month/quarter)
- Generate GSTR-3B summary for monthly filing

**As CA / Tax Consultant,** I want to:
- Review GST data before filing
- Export GSTR-1 and GSTR-3B summaries
- Verify HSN/SAC codes are correctly assigned

## Key Business Rules

**Tax Application**
- For intra-state transactions: CGST + SGST applied (split equally)
- For inter-state transactions: IGST applied (full rate)
- HSN/SAC codes are required for GST compliance — validated at voucher level
- Tax rates are seeded with standard GST slabs but editable per school

**GST Compliance**
- **GSTR-1 (Outward Supplies):** Compiled from Sales/Receipt vouchers — invoice-wise GSTIN, HSN/SAC, taxable value, tax amount. Filters to GST-registered ledgers only.
- **GSTR-3B (Summary):** Monthly summary of total outward and inward taxable values. Net tax payable = Output tax − Input tax credit.

## Seeded Tax Rates

| Name | Type | Rate |
|---|---|---|
| CGST 9% | CGST | 9% |
| SGST 9% | SGST | 9% |
| IGST 18% | IGST | 18% |
| CGST 2.5% | CGST | 2.5% |
| SGST 2.5% | SGST | 2.5% |
| IGST 5% | IGST | 5% |

## Stakeholders

| Stakeholder | Interest |
|---|---|
| School Accountant | Configures tax rates, assigns to ledgers, generates GST data |
| CA / Tax Consultant | Uses exported GST data for monthly/quarterly filings |
| Auditor | Verifies GST compliance |

## Permissions

| Role | Access |
|---|---|
| School Admin | Full access to tax configuration |
| Accountant | Create/edit tax rates |
| Auditor | View-only access |

# Expense Claims — Business Requirements

## Business Need
Staff members incur out-of-pocket expenses for school purposes — travel for school business, classroom supplies, refreshments for events, etc. These need to be reimbursed through a proper workflow: the employee submits a claim with receipts, the approver reviews and approves, and the accountant processes payment. The system should auto-create the payment voucher on approval.

## Business Objectives
- Allow staff to submit expense claims with line items and receipts
- Provide an approval workflow: Draft → Submitted → Approved/Rejected → Paid
- Auto-create a Payment Voucher when a claim is approved
- Track each claim against the employee profile (sch_employees)
- Maintain receipt attachments for audit compliance

## User Stories

**As Staff Member (Employee),** I want to:
- Submit an expense claim with multiple line items (date, description, amount, category)
- Attach receipt images/photos for each expense line
- Save a claim as draft and submit it later
- View the status of my submitted claims (Pending/Approved/Rejected/Paid)
- Know why my claim was rejected

**As Approver (HOD/Admin),** I want to:
- Review submitted claims with attached receipts
- See the total claim amount and per-line breakdown
- Approve or reject a claim with comments
- Know that approved claims will auto-generate a payment voucher

**As Accountant,** I want to:
- See approved claims ready for payment
- Post the auto-created payment voucher to complete the transaction
- Ensure the correct expense ledgers are debited and the bank/cash ledger is credited

## Key Business Rules

**Workflow**
```
Draft → Submitted → Approved → Paid
                  → Rejected
```

**Validation Rules**
- Total claim amount must equal the sum of individual line amounts
- An employee can have multiple claims in various statuses simultaneously
- Receipt upload is optional but recommended for audit compliance

**Approval → Payment Voucher**
- When approved, the system automatically creates a Payment Voucher
- Dr: Expense Ledger (per claim line category)
- Cr: Bank/Cash Ledger (configurable payment account)
- The voucher is linked to the claim for audit trail
- The claim moves to "Paid" when the voucher is posted

**Claim Numbering**
- Auto-generated sequential numbers per financial year
- Format: `CLM-YYYY-NNNNNN`

## Business Workflow

1. **Submit:** Employee fills expense claim form with line items, attaches receipts, submits
2. **Review:** Approver reviews the claim, checks receipts, approves or rejects
3. **Auto-Voucher:** On approval, system creates a Payment Voucher in draft status
4. **Payment:** Accountant posts the voucher, claim status moves to "Paid"
5. **Audit:** Complete trail — claim → approval → voucher → payment

## Stakeholders

| Stakeholder | Interest |
|---|---|
| Staff / Employee | Submits claims, expects timely reimbursement |
| HOD / Approver | Reviews and approves claims for their team |
| School Accountant | Processes payment, ensures correct ledger posting |
| School Admin / Bursar | Oversees expense control, approves large claims |

## Permissions

| Role | Access |
|---|---|
| School Admin | Full access — approve, reject, process payment |
| Accountant | View, process payment vouchers |
| HOD/Approver | Approve or reject claims for their department |
| Employee | Create and view own claims |

# Recurring Templates — Business Requirements

## Business Need
Many transactions repeat on a regular schedule — monthly rent, quarterly tax provisions, annual insurance premiums, monthly depreciation. Rather than creating these manually each time, accountants need a template system that auto-creates vouchers on a defined schedule, saving time and preventing missed entries.

## Business Objectives
- Define journal voucher templates that repeat on a schedule (daily/weekly/monthly/quarterly/yearly)
- Auto-create vouchers on the scheduled dates without manual intervention
- Prevent duplicate vouchers for the same period
- Back-fill missed entries if the system was down
- Track the last posted date for each template

## User Stories

**As School Accountant,** I want to:
- Create a recurring journal template (e.g., monthly rent: Dr Rent Expense, Cr Bank)
- Set the frequency (Monthly), start date, and optional end date
- Configure the day of month for posting (e.g., 1st of every month)
- Define the Dr/Cr line items with amounts that balance
- View when the template was last posted and when the next posting is due
- Manually trigger an immediate posting if needed
- Deactivate a template when no longer needed (e.g., lease ended)

## Key Business Rules

**Template Validation**
- Line items must balance: Total Debits = Total Credits
- Total amount must match the sum of line items
- For monthly frequency, a day of month (1-28) is required
- For quarterly: posts on first day of the quarter
- For yearly: posts on start date each year

**Auto-Posting Logic**
- A daily scheduled job checks all active templates
- If current date >= next due date AND within the template's date range, it creates the voucher
- Vouchers are created in "Draft" status by default
- The template's `last_posted_date` is updated after successful creation
- Duplicate prevention: checks if a voucher already exists for the period

**Missed Post Handling**
- If the system missed a cycle (e.g., server downtime), it catches up in sequence
- Each missed entry is created with its original scheduled date
- Back-fill is limited to 3 missed cycles to prevent overwhelming the system

## Business Workflow

1. **Setup:** Accountant creates a template (e.g., "Monthly Rent — April 2026 to March 2027")
2. **Scheduled Run:** Daily cron job checks all active templates
3. **Voucher Creation:** When due, system creates a Journal Voucher with the template's Dr/Cr lines
4. **Review:** Accountant reviews and posts the auto-created vouchers
5. **Completion:** Template continues until end date or deactivation

## Common Use Cases

| Template | Frequency | Dr | Cr |
|---|---|---|---|
| Monthly Rent | Monthly, 1st | Rent Expense | Bank A/c |
| Quarterly GST Payment | Quarterly | GST Payable | Bank A/c |
| Annual Insurance Premium | Yearly | Insurance Expense | Bank A/c |
| Monthly Depreciation | Monthly | Depreciation Expense | Accumulated Depreciation |
| Monthly Salary Accrual | Monthly | Salary Expense | Salary Payable |

## Stakeholders

| Stakeholder | Interest |
|---|---|
| School Accountant | Creates templates, reviews auto-generated vouchers |
| School Admin / Bursar | Oversees recurring commitments |

## Permissions

| Role | Access |
|---|---|
| School Admin | Full access to recurring templates |
| Accountant | Create/edit templates, trigger manual posting |

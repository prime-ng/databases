# Business Conditions
=====================

## In Table `acc_account_groups`, what is the use of `is_subledger`?

is_subledger marks an Account Group as a sub-ledger group — meaning ledgers under it track balances per individual entity (student, vendor, staff) rather than as one consolidated account.

In plain accounting terms
A normal group like "Direct Expenses" holds ledgers where you just post journal entries and see a total balance.

A sub-ledger group like "Sundry Debtors" or "Student Fee Receivable" holds ledgers where each ledger represents one party (one student, one vendor), and you need a running balance per party — the main ledger is just the control/summary account.

Practical example in PrimeDB context
Group	is_subledger	What it means
Direct Expenses	0	Just a group — post entries, see totals
Student Fee Receivable	1	Each student has their own sub-ledger; the group total = sum of all student balances
Vendor Payables	1	Each vendor has their own sub-ledger
How the app should use this flag
When is_subledger = 1 on a group:

Ledgers under it should be auto-created per entity (e.g., one ledger per student on admission)
Reports should be able to drill down from group → individual ledger balances
The group acts as the control account in the Trial Balance; sub-ledger detail is shown separately in the Debtor/Creditor register

Exampal :
Here's a walk-through with sample data across the three levels.

Level 1 — acc_account_groups
id	name	code	nature	is_subledger	parent_id
1	Current Assets	A01	asset	0	NULL
2	Student Fee Receivable	A02	asset	1	1
3	Vendor Payables	L01	liability	1	NULL
4	Direct Expenses	E01	expense	0	NULL
5	Salary Expenses	E02	expense	0	NULL
Groups 2 and 3 have is_subledger = 1 → each ledger under them represents one entity
Groups 1, 4, 5 have is_subledger = 0 → ledgers under them are just named accounts, no per-party tracking
Level 2 — acc_ledgers (one row per student / vendor)
id	name	account_group_id	opening_balance	opening_balance_type
101	Rahul Sharma (STU-2025-001)	2	12000.00	Dr
102	Priya Mehta (STU-2025-002)	2	8500.00	Dr
103	Ankit Verma (STU-2025-003)	2	0.00	Dr
201	ABC Bus Suppliers	3	25000.00	Cr
202	XYZ Stationery Co.	3	11000.00	Cr
301	Electricity Expense	4	0.00	Dr
302	Teacher Salary	5	0.00	Dr
Notice:

Group 2 (sub-ledger) → one ledger per student
Group 4 (normal) → one ledger for the whole expense category — no per-party split
Level 3 — Journal entries posted against ledgers
Example A — Fee collected from Rahul (ledger 101)
Entry	Ledger	Dr	Cr
Fee Receipt	Cash/Bank	5,000	—
Fee Receipt	Rahul Sharma (101)	—	5,000
Rahul's ledger balance moves: 12,000 Dr → 7,000 Dr (still owes ₹7,000)

Example B — Fee collected from Priya (ledger 102)
Entry	Ledger	Dr	Cr
Fee Receipt	Cash/Bank	8,500	—
Fee Receipt	Priya Mehta (102)	—	8,500
Priya's ledger balance: 8,500 Dr → 0 (fully cleared)

Example C — Electricity bill paid (ledger 301, normal group)
Entry	Ledger	Dr	Cr
Expense	Electricity Expense (301)	3,200	—
Expense	Cash/Bank	—	3,200
No per-party tracking here — it's just one expense bucket.

How reports use is_subledger
Trial Balance (control account view — is_subledger = 1 groups show as one line)
Account	Dr	Cr
Student Fee Receivable (Group A02)	20,500	—
Vendor Payables (Group L01)	—	36,000
Electricity Expense	3,200	—
Debtors Register (drill-down into sub-ledger group A02)
Student	Ledger ID	Balance
Rahul Sharma	101	7,000 Dr
Priya Mehta	102	0
Ankit Verma	103	0
Group Total		7,000 Dr
The key rule
When is_subledger = 0 → the group's ledgers are buckets for transaction types
When is_subledger = 1 → the group's ledgers are buckets per person/entity, and the group total acts as the control account that must always equal the sum of all individual ledger balances

This is the classic Control Account ↔ Sub-Ledger relationship used in double-entry accounting systems (same as how Tally's "Sundry Debtors" works).

## Table : `acc_ledgers` Field : `gst_registration_type`

gst_registration_type captures how the party linked to this ledger is registered under India's GST system. It only applies to ledgers that represent vendors, suppliers, or service providers — not students or employees.

Why it lives on a Ledger
In GST, how you calculate and claim Input Tax Credit (ITC) depends on the supplier's registration type. So when the school raises a purchase voucher against a vendor ledger, the system needs to know the vendor's GST type to:
- Apply the correct tax rate
- Decide if ITC can be claimed
- Generate the correct GST return entries (GSTR-2B reconciliation)

The valid GST Registration Types in India
|---------------------------|-------------------------------------------------------|-------------------------------------------|
| Type	                    | Who it applies to	                                    | ITC claimable by school?                  |
|---------------------------|-------------------------------------------------------|-------------------------------------------|
|Regular	                | Vendors with turnover > ₹40L, fully GST registered	| Yes — full ITC                            |
|Composition	            | Small vendors (turnover < ₹1.5Cr) who pay flat tax	| No — composition dealers can't pass ITC   |
|Unregistered	            | Vendor has no GST registration	                    | No — school may need to pay GST under RCM |
|Consumer	                | Individual, no GSTIN	                                | No                                        |
|SEZ	                    | Special Economic Zone supplier	                    | Yes — zero-rated                          |
|---------------------------|-------------------------------------------------------|-------------------------------------------|

RCM = Reverse Charge Mechanism — when a vendor is Unregistered, the school itself has to pay the GST to the government instead of the vendor.

### Practical example
| Vendor Ledger	         | gst_registration_type | gstin	            | Effect on voucher                       |
|------------------------|-----------------------|----------------------|-----------------------------------------|
| ABC Bus Suppliers	     | Regular	             | 27AABCU9603R1ZX	    | ITC claimable, normal GST entry         |
| Local Carpenter	     | Unregistered	         | NULL	                | RCM applies, school pays GST            |
| XYZ Stationery (small) | Composition	         | 27XXXXX1234R1ZX	    | No ITC, cost goes to expense directly   |
|------------------------|-----------------------|----------------------|-----------------------------------------|

Since the valid types are a known closed set (defined by GST law), VARCHAR(30) is loose. It would be safer as an ENUM:


`gst_registration_type` ENUM('Regular','Composition','Unregistered','SEZ','Consumer') NULL
This prevents data entry errors like 'regular' vs 'Regular' breaking ITC logic. Want me to update it?

# Prime-AI Accounting Module
## Business Requirements Document (BRD)

**Document Type:** Business Requirements Document  
**Application:** Prime-AI Main Application — Accounting Module  
**Perspective:** Business Analyst  
**Status:** Draft for Business Review  
**Reference Benchmark:** Tally.ERP 9 Help Documentation  
**Purpose:** Define business needs, accounting capabilities, business rules, controls, and operating conditions without prescribing technical implementation.

---

# 1. Document Purpose

This document defines the Business Requirements for the Accounting Module of the Prime-AI Main Application.

The purpose is to establish what the business expects the Accounting Module to accomplish, what accounting activities it must support, what controls and business rules it must follow, and what information the business must be able to obtain from it.

This is a Business Requirements Document and therefore intentionally avoids prescribing:

- Database tables
- Database keys
- Programming language
- Framework
- APIs
- Technical architecture
- Specific user-interface implementation
- Internal storage mechanisms
- Technical integration mechanisms

The Accounting Module should ultimately provide a complete business accounting environment capable of supporting day-to-day bookkeeping, receivables, payables, banking, taxation, financial reporting, budgeting, cost/profit analysis, auditability, and management analysis.

The requirements in this document are benchmarked primarily against the accounting-related capabilities documented by Tally.ERP 9. Tally.ERP 9 documentation describes accounting through masters, vouchers and reports, including groups, ledgers, voucher types, accounting vouchers, cost centres, currencies, credit limits, budgets, interest calculations, banking, statutory taxation, and financial/MIS reports.

The Tally reference is used as a functional benchmark, not as a requirement that Prime-AI must copy Tally's user interface or implementation.

---

# 2. Business Context

Accounting is a core business function of the Prime-AI application.

The Accounting Module is expected to maintain a reliable record of the financial activities of an organization and provide management with timely and meaningful financial information.

The module should support the complete accounting lifecycle:

**Business Transaction**

→

**Accounting Classification**

→

**Transaction Recording**

→

**Receivable / Payable Tracking**

→

**Bank / Cash Management**

→

**Tax and Statutory Treatment**

→

**Reconciliation**

→

**Period Closing**

→

**Financial Statements**

→

**Management Analysis**

→

**Audit / Review**

The business must be able to use the accounting information for operational decisions as well as formal financial reporting.

---

# 3. Business Problems to Be Solved

The Accounting Module should address business problems such as:

- Maintaining accurate books of accounts
- Recording financial transactions consistently
- Maintaining customer and supplier balances
- Tracking invoices and outstanding amounts
- Tracking receipts and payments against outstanding bills
- Managing cash and bank transactions
- Reconciling bank transactions
- Managing taxes and statutory liabilities
- Monitoring income and expenses
- Understanding profitability
- Monitoring cash flow
- Managing budgets
- Tracking financial performance by business area
- Maintaining an audit trail
- Preventing unauthorized or inappropriate accounting changes
- Identifying unusual or exceptional transactions
- Preserving historical accounting information
- Providing management reports
- Supporting year-end and period-end accounting
- Supporting multiple currencies where required
- Supporting multiple branches, business units, projects or cost centres where required
- Reducing duplicate data entry
- Reducing accounting errors through validation and controlled defaults

---

# 4. Business Objectives

## BR-OBJ-01 — Accurate Bookkeeping

The system must enable the organization to record financial transactions accurately and consistently.

## BR-OBJ-02 — Complete Financial Visibility

Management should be able to obtain a clear view of:

- Assets
- Liabilities
- Capital
- Income
- Expenses
- Receivables
- Payables
- Cash
- Bank balances
- Tax liabilities
- Profitability

## BR-OBJ-03 — Reliable Financial Statements

The Accounting Module should produce reliable financial statements from recorded transactions.

## BR-OBJ-04 — Receivable and Payable Control

The business should be able to monitor money due from customers and money payable to suppliers.

## BR-OBJ-05 — Banking Control

The business should be able to track bank transactions, cheques, deposits, payments, receipts and reconciliation status.

## BR-OBJ-06 — Tax Compliance Support

The module should support applicable tax accounting and provide information required for statutory compliance.

## BR-OBJ-07 — Management Accounting

The module should provide information for cost analysis, profitability analysis, budgeting, cash-flow planning and management decisions.

## BR-OBJ-08 — Auditability

Financial transactions and important changes must be traceable and reviewable.

## BR-OBJ-09 — Controlled Accounting

The application must provide appropriate controls over who can create, approve, modify, cancel, reverse or otherwise affect financial transactions.

## BR-OBJ-10 — Historical Integrity

Historical accounting information must remain trustworthy and must not be silently changed by subsequent master or configuration changes.

---

# 5. Reference Scope from Tally.ERP 9

The Tally.ERP 9 documentation identifies accounting capabilities including:

- Accounting features and company preferences
- Groups
- Ledgers
- Voucher types
- Voucher classes
- Accounting vouchers
- Contra
- Payment
- Receipt
- Purchase
- Sales
- Journal
- Debit Notes
- Credit Notes
- Post-dated transactions
- Optional and non-accounting vouchers
- Cost categories
- Cost centres
- Multi-currency
- Credit limits
- Budgets
- Interest calculations
- Banking
- Cheque management
- E-payments
- Bank reconciliation
- Receivables
- Payables
- Ageing
- Cash flow
- Fund flow
- Ratio analysis
- Cash-flow projection
- Exception reports
- Financial statements
- Registers and books
- Taxation and statutory accounting
- GST
- TDS
- TCS
- Other statutory/tax capabilities documented for the Tally.ERP 9 era
- Audit and verification capabilities

Tally also supports accounting-related integration with inventory, sales, purchase, order processing, job costing and payroll. The Prime-AI Accounting Module should therefore define clear business boundaries and integration expectations for these related areas.

---

# 6. Accounting Philosophy

The Accounting Module should follow fundamental accounting principles.

## BR-ACC-01 — Every Financial Transaction Must Be Accounted For

A transaction that affects the organization's financial position must ultimately be reflected in the appropriate books of account.

## BR-ACC-02 — Debit and Credit Integrity

Accounting transactions must maintain accounting balance.

## BR-ACC-03 — Transaction Classification

Transactions must be classified into appropriate accounts and accounting categories.

## BR-ACC-04 — Period Integrity

Transactions must belong to an appropriate accounting period.

## BR-ACC-05 — Historical Integrity

Past financial transactions must remain historically meaningful.

## BR-ACC-06 — Traceability

A reported financial balance must be traceable back to the underlying accounting transactions.

## BR-ACC-07 — Evidence

Important accounting transactions should be supported by appropriate business documents or references.

---

# 7. Organization / Company Accounting Context

The Accounting Module shall operate within an identifiable organization or company accounting context.

The business may have:

- One company
- Multiple companies
- Branches
- Divisions
- Business units
- Projects
- Cost centres
- Departments

The module should support the organizational structure required by the business.

### Business Rules

**BR-COMP-01:** Accounting transactions must belong to a clearly identified accounting organization.

**BR-COMP-02:** Accounting information belonging to one organization must not accidentally be mixed with another organization.

**BR-COMP-03:** Where multiple business units share accounting information, the business must be able to distinguish them where required.

**BR-COMP-04:** Historical transactions must retain the accounting context applicable when they were recorded.

---

# 8. Financial Year and Accounting Period

The Accounting Module shall support accounting by financial year and accounting period.

### Business Needs

The business should be able to:

- Define financial years
- Record transactions within a financial year
- View transactions for selected periods
- Compare periods
- Close periods
- Carry forward appropriate balances
- Review previous periods

### Business Rules

**BR-PERIOD-01:** Every accounting transaction must have an accounting date.

**BR-PERIOD-02:** The accounting date determines the accounting period in which the transaction is recognized, subject to applicable accounting rules.

**BR-PERIOD-03:** Closed periods must be protected from unauthorized modification.

**BR-PERIOD-04:** Reopening a closed period must require appropriate authorization.

**BR-PERIOD-05:** Year-end closing must preserve the financial history of the previous year.

---

# 9. Chart of Accounts

The application shall provide a structured Chart of Accounts.

The Chart of Accounts should organize accounts into meaningful groups and sub-groups.

Typical broad classifications include:

- Capital
- Liabilities
- Assets
- Income
- Expenses

The business may require additional sub-classifications.

### Business Rules

**BR-COA-01:** Every accounting ledger should belong to an appropriate accounting classification.

**BR-COA-02:** The Chart of Accounts should support hierarchical grouping.

**BR-COA-03:** Grouping should support financial reporting.

**BR-COA-04:** An account should not be classified in a way that produces misleading financial statements.

**BR-COA-05:** Changes to account classification must be controlled.

**BR-COA-06:** Historical reports should remain understandable if an account's current classification changes.

---

# 10. Accounting Groups

Accounting groups provide the business structure used to classify ledger accounts.

### Business Needs

Users should be able to:

- View account groups
- Create appropriate sub-groups
- Organize ledgers
- Review group balances
- Analyze income and expenses by group
- Analyze assets and liabilities by group

### Business Rules

**BR-GROUP-01:** A group must have a clear accounting purpose.

**BR-GROUP-02:** A ledger must be associated with an appropriate group.

**BR-GROUP-03:** Group changes must not unintentionally alter historical accounting meaning.

**BR-GROUP-04:** Standard or system-defined groups should be protected from inappropriate modification.

---

# 11. Ledger Accounts

The application shall support ledger accounts representing individual accounting heads.

Examples include:

- Cash
- Bank
- Customer
- Supplier
- Sales
- Purchases
- Rent
- Salary
- Electricity
- Tax
- Loan
- Capital
- Fixed assets
- Other income
- Other expenses

### Business Rules

**BR-LEDGER-01:** Each ledger must have a meaningful name.

**BR-LEDGER-02:** Each ledger must have an appropriate accounting classification.

**BR-LEDGER-03:** Party ledgers should support relevant customer/supplier information.

**BR-LEDGER-04:** Bank ledgers should support relevant banking information.

**BR-LEDGER-05:** Tax ledgers should support applicable tax information.

**BR-LEDGER-06:** Ledger balances must be derived from accounting transactions and applicable opening balances.

---

# 12. Ledger Master Information

Depending on the ledger type, the business may require:

- Name
- Address
- Contact information
- Tax identification information
- Payment terms
- Credit limit
- Bank information
- Currency
- Opening balance
- Cost-centre applicability
- Bill-wise applicability
- Tax classification
- Interest applicability
- Other relevant business attributes

### Business Rule

**BR-LEDGER-MASTER-01:** Required ledger information must be collected according to the purpose of the ledger.

---

# 13. Customer and Supplier Accounts

The Accounting Module shall support party accounts for:

- Customers
- Suppliers
- Vendors
- Service providers
- Other receivable parties
- Other payable parties

### Business Needs

The business must be able to determine:

- Amount due from each customer
- Amount payable to each supplier
- Invoice-wise outstanding
- Payment history
- Receipt history
- Credit exposure
- Age of outstanding balances

---

# 14. Bill-Wise Accounting

The application should support tracking outstanding transactions at the bill/document level.

### Business Need

The business should be able to know:

> Which invoice is outstanding?

> How much is outstanding against that invoice?

> When is it due?

> Which payment has been adjusted against it?

### Business Rules

**BR-BILL-01:** A bill/reference may be tracked independently within a party account.

**BR-BILL-02:** Receipts and payments may be allocated against relevant outstanding bills.

**BR-BILL-03:** Partial settlement must be supported where applicable.

**BR-BILL-04:** One payment may be allocated across multiple outstanding bills where appropriate.

**BR-BILL-05:** One bill may be settled through multiple payments.

**BR-BILL-06:** Outstanding reports must distinguish fully settled, partially settled and outstanding bills.

---

# 15. Credit Limits

The system should support credit-limit management for applicable customers or parties.

### Business Rules

**BR-CREDIT-01:** A credit limit may be defined for a party.

**BR-CREDIT-02:** The system should be able to determine current exposure against the permitted limit.

**BR-CREDIT-03:** Transactions that exceed an approved credit limit may require warning, approval or restriction according to business policy.

**BR-CREDIT-04:** Credit-limit overrides must be traceable.

---

# 16. Voucher / Transaction Concept

A voucher represents a business document or accounting event used to record a financial transaction.

Tally documentation describes vouchers as primary transaction documents and provides specialized voucher types for payments, receipts, purchases, sales, contra, journals, debit notes and credit notes.

Prime-AI should use the same business principle:

> A financial event should be recorded as a clearly identifiable accounting transaction supported by an appropriate business document or voucher type.

---

# 17. Voucher Types

The application shall support appropriate transaction types.

At minimum, the accounting business scope should consider:

- Receipt
- Payment
- Contra
- Journal
- Sales
- Purchase
- Debit Note
- Credit Note

Additional voucher types may be introduced where business requirements justify them.

### Business Rules

**BR-VTYPE-01:** Each voucher type must have a clear business purpose.

**BR-VTYPE-02:** Users should not use an inappropriate voucher type merely to bypass accounting controls.

**BR-VTYPE-03:** Voucher numbering should follow defined business policy.

**BR-VTYPE-04:** Voucher numbering should support appropriate uniqueness and period controls.

**BR-VTYPE-05:** Changes to voucher-type configuration must be controlled.

---

# 18. Voucher Numbering

The application should support configurable voucher numbering policies.

Possible policies include:

- Automatic numbering
- Manual numbering
- Sequential numbering
- Prefix/suffix
- Financial-year-based numbering
- Branch-specific numbering
- Voucher-type-specific numbering

### Business Rules

**BR-VNO-01:** Voucher numbers must follow the organization's numbering policy.

**BR-VNO-02:** Duplicate voucher numbers should be prevented where uniqueness is required.

**BR-VNO-03:** Cancelled or unused numbers must be handled according to organizational policy.

**BR-VNO-04:** Historical voucher numbers must not be changed casually.

---

# 19. Receipt Transactions

The application shall support recording money received by the organization.

Examples:

- Customer payment
- Advance receipt
- Other income receipt
- Loan receipt
- Capital contribution
- Refund receipt

### Business Rules

**BR-RECEIPT-01:** Receipt transactions must identify the receiving account or mode.

**BR-RECEIPT-02:** Customer receipts should support bill-wise allocation where applicable.

**BR-RECEIPT-03:** Advance receipts must be distinguishable from settlement of existing invoices.

**BR-RECEIPT-04:** Bank/cash receipts should update the relevant financial balance.

---

# 20. Payment Transactions

The application shall support recording money paid by the organization.

Examples:

- Supplier payment
- Expense payment
- Employee-related payment
- Tax payment
- Loan repayment
- Advance payment
- Other business payment

### Business Rules

**BR-PAY-01:** Payment transactions must identify the paying account or mode.

**BR-PAY-02:** Supplier payments should support bill-wise allocation where applicable.

**BR-PAY-03:** Advance payments must be distinguishable from settlement of existing bills.

**BR-PAY-04:** The system may warn or restrict payments that create an unauthorized negative cash position.

---

# 21. Contra Transactions

The application shall support transfers between cash and bank accounts or between relevant internal accounts.

Examples:

- Cash deposited into bank
- Cash withdrawn from bank
- Transfer between bank accounts
- Internal transfer where appropriate

### Business Rules

**BR-CONTRA-01:** Contra transactions should represent internal movement rather than income or expense.

**BR-CONTRA-02:** Both sides of the transfer must be identifiable.

**BR-CONTRA-03:** Contra transactions must not incorrectly affect profit and loss.

---

# 22. Journal Transactions

The application shall support journal transactions for accounting adjustments and other transactions not better represented by specialized vouchers.

Examples:

- Accruals
- Depreciation
- Provisions
- Reclassifications
- Adjustments
- Corrections
- Accounting-period adjustments

### Business Rules

**BR-JV-01:** Journal entries must maintain accounting balance.

**BR-JV-02:** Users should provide meaningful narration or explanation for significant journal entries.

**BR-JV-03:** Journal entries requiring supporting documentation should reference that documentation.

**BR-JV-04:** Sensitive adjustment journals may require approval.

---

# 23. Sales Transactions

The Accounting Module should support sales accounting.

Sales may involve:

- Goods
- Services
- Taxable supplies
- Exempt supplies
- Zero-rated supplies
- Other business sales

Where inventory is maintained by another module, the Accounting Module should integrate with inventory information rather than duplicate business ownership of stock information.

### Business Rules

**BR-SALES-01:** Sales transactions must identify the customer or relevant party where required.

**BR-SALES-02:** Sales transactions must identify the appropriate income/revenue account.

**BR-SALES-03:** Applicable taxes must be recognized according to the transaction's tax treatment.

**BR-SALES-04:** Receivables should be updated for credit sales.

**BR-SALES-05:** Cash/bank balances should be updated for immediate settlements.

---

# 24. Purchase Transactions

The Accounting Module should support purchase accounting.

Purchases may involve:

- Goods
- Services
- Fixed assets
- Taxable purchases
- Exempt purchases
- Imports
- Other business purchases

### Business Rules

**BR-PUR-01:** Purchase transactions must identify the supplier or relevant party where required.

**BR-PUR-02:** Purchases must be classified appropriately.

**BR-PUR-03:** Applicable taxes must be recognized according to the transaction.

**BR-PUR-04:** Credit purchases must create or update payable balances.

**BR-PUR-05:** Immediate payments must update the appropriate cash/bank balance.

---

# 25. Debit Notes

The application should support debit notes for appropriate business situations.

Potential uses include:

- Purchase adjustments
- Supplier claims
- Purchase returns where appropriate
- Additional supplier charges
- Other accounting adjustments

### Business Rules

**BR-DN-01:** Debit notes must clearly identify the reason for the adjustment.

**BR-DN-02:** Where related to an original transaction, the relationship should be traceable.

**BR-DN-03:** Tax consequences must be handled according to the applicable transaction.

---

# 26. Credit Notes

The application should support credit notes for appropriate business situations.

Potential uses include:

- Sales returns
- Customer claims
- Discounts/adjustments
- Sales corrections
- Other customer adjustments

### Business Rules

**BR-CN-01:** Credit notes must clearly identify the reason for the adjustment.

**BR-CN-02:** Where related to an original transaction, the relationship should be traceable.

**BR-CN-03:** Tax consequences must be handled according to the applicable transaction.

---

# 27. Optional / Provisional Accounting

The application may support transactions that are recorded for planning, estimation or review but should not immediately affect finalized accounting results.

Examples include:

- Memorandum/provisional transactions
- Reversing entries
- Optional entries
- Scenario transactions

### Business Rules

**BR-OPT-01:** Provisional transactions must be clearly distinguishable from finalized accounting transactions.

**BR-OPT-02:** Provisional transactions must not be included in finalized financial statements unless explicitly recognized.

**BR-OPT-03:** Reversing transactions must have a defined reversal condition/date.

---

# 28. Post-Dated Transactions

The application should support post-dated accounting transactions where business policy permits.

### Business Rules

**BR-PD-01:** A post-dated transaction must be distinguishable from an immediately effective transaction.

**BR-PD-02:** The system should support reporting of post-dated transactions separately.

**BR-PD-03:** Recognition in financial statements must follow the organization's accounting policy.

---

# 29. Cost Centres

The Accounting Module shall support allocation of income and expenses to cost centres where required.

Examples:

- Department
- Branch
- Project
- Location
- Business unit
- Product line
- Employee-related cost centre
- Other management dimension

### Business Rules

**BR-CC-01:** A cost centre must represent a meaningful management-accounting dimension.

**BR-CC-02:** Applicable transactions should support allocation to one or more cost centres.

**BR-CC-03:** Cost-centre allocation should not change the underlying financial accounting classification.

**BR-CC-04:** Cost-centre reports should reconcile with the underlying accounting records.

---

# 30. Cost Categories

The application may support multiple independent cost dimensions where required.

For example, an organization may want to analyze the same expense by:

- Department
- Project
- Location

### Business Rules

**BR-CAT-01:** Cost categories must be clearly defined.

**BR-CAT-02:** The same financial transaction may be analyzed across multiple permitted dimensions.

**BR-CAT-03:** Cost-category analysis must remain consistent with the underlying accounting transaction.

---

# 31. Cost Centre Classes / Predefined Allocation

The application may support predefined allocation rules for recurring transactions.

Examples:

- Monthly rent allocation
- Common administrative expense allocation
- Shared service allocation
- Department-wise salary allocation

### Business Rules

**BR-ALLOC-01:** Predefined allocation must be configurable.

**BR-ALLOC-02:** Users must be able to review or override allocations where business policy permits.

**BR-ALLOC-03:** Overrides should be traceable.

---

# 32. Multi-Currency

The application should support transactions involving multiple currencies where required.

### Business Needs

The business should be able to:

- Maintain foreign-currency accounts
- Record foreign-currency transactions
- Apply appropriate exchange rates
- View transaction currency
- View accounting/base currency
- Recognize exchange differences where applicable

### Business Rules

**BR-FX-01:** The transaction currency must be identifiable.

**BR-FX-02:** The applicable exchange rate must be identifiable.

**BR-FX-03:** Foreign-currency balances must be distinguishable from base-currency values.

**BR-FX-04:** Exchange-rate differences must be handled according to the organization's accounting policy.

**BR-FX-05:** Historical transaction values must remain explainable even if exchange rates later change.

---

# 33. Interest Calculation

The application may support interest calculation for applicable accounts and transactions.

Potential use cases include:

- Customer overdue interest
- Supplier interest
- Loan interest
- Other contractual interest

### Business Rules

**BR-INT-01:** Interest rules must be configurable according to business agreements or policy.

**BR-INT-02:** Interest may depend on transaction date, due date, payment date or other defined dates.

**BR-INT-03:** The system should support applicable grace periods.

**BR-INT-04:** Calculated interest should be distinguishable from the original principal amount.

**BR-INT-05:** Interest calculations must be explainable.

---

# 34. Banking Management

The Accounting Module shall provide banking-related accounting capabilities.

Tally.ERP 9 includes bank ledgers, cheque management, payment advice, e-payments, post-dated cheques and bank reconciliation.

Prime-AI should support the relevant business capabilities required by the organization.

---

# 35. Bank Accounts

The application shall support multiple bank accounts.

Each bank account may have:

- Bank name
- Branch
- Account number
- Account type
- Relevant bank identifiers
- Currency
- Opening balance
- Cheque details
- Reconciliation settings

### Business Rules

**BR-BANK-01:** Each bank account must be clearly identifiable.

**BR-BANK-02:** Transactions must be attributable to the appropriate bank account.

**BR-BANK-03:** Bank balances should be reconcilable against bank statements.

---

# 36. Cheque Management

The application should support cheque-related business activities.

Examples:

- Cheques issued
- Cheques received
- Deposited cheques
- Cleared cheques
- Uncleared cheques
- Post-dated cheques
- Cancelled cheques
- Cheque printing where required

### Business Rules

**BR-CHEQUE-01:** Cheques must have an identifiable status.

**BR-CHEQUE-02:** Issued and received cheques must be distinguishable.

**BR-CHEQUE-03:** Cheque clearing status must be trackable.

**BR-CHEQUE-04:** Cancelled cheques must remain historically traceable where required.

**BR-CHEQUE-05:** Post-dated cheques must be distinguishable from immediately effective transactions.

---

# 37. Cash Management

The application shall support cash accounting.

### Business Needs

The business should be able to know:

- Opening cash
- Receipts
- Payments
- Transfers
- Closing cash
- Cash balance by period
- Unusual cash movements

### Business Rules

**BR-CASH-01:** Cash transactions must update the appropriate cash balance.

**BR-CASH-02:** The application should be able to warn about negative cash balances where configured.

**BR-CASH-03:** Cash balances should be traceable to the underlying transactions.

---

# 38. Bank Reconciliation

The application shall support bank reconciliation.

The business should be able to compare:

**Accounting Bank Book**

against

**Bank Statement**

and identify:

- Matched transactions
- Unmatched accounting transactions
- Unmatched bank transactions
- Timing differences
- Missing entries
- Duplicate entries
- Incorrect amounts
- Other discrepancies

### Business Rules

**BR-BRS-01:** Reconciliation status must be identifiable for relevant bank transactions.

**BR-BRS-02:** A reconciliation difference must not be silently treated as an accounting correction.

**BR-BRS-03:** Manual reconciliation actions should be traceable.

**BR-BRS-04:** Imported bank statements should be reviewable before affecting accounting records where applicable.

**BR-BRS-05:** Reconciliation should support re-review when an earlier match is found to be incorrect.

---

# 39. Electronic Payments

Where supported, the application may facilitate electronic payment processing.

### Business Needs

The system may support:

- Preparing payment instructions
- Validating bank details
- Identifying incomplete payment information
- Identifying mismatches
- Tracking payment instruction status
- Tracking successful/failed/rejected processing

### Business Rules

**BR-EPAY-01:** Payment instructions must not be sent without required information.

**BR-EPAY-02:** Bank-detail mismatches must be clearly identified.

**BR-EPAY-03:** Payment status must remain traceable.

**BR-EPAY-04:** Payment processing status must not automatically mean accounting settlement unless the business rules define it so.

---

# 40. Payment Advice

The application should support generation or recording of payment advice for relevant transactions.

The advice should communicate:

- Party
- Payment amount
- Payment date
- Invoice/bill references
- Payment mode
- Other relevant information

---

# 41. Receivables Management

The application shall provide a comprehensive receivables function.

The business should be able to see:

- Total receivables
- Customer-wise receivables
- Invoice-wise receivables
- Due dates
- Overdue amounts
- Ageing
- Collection history
- Credit exposure
- Advances
- Disputed amounts where applicable

---

# 42. Receivable Ageing

The system should provide ageing analysis.

Possible ageing buckets may include:

- Current
- 1–30 days
- 31–60 days
- 61–90 days
- 91–180 days
- More than 180 days

The exact ageing policy should be configurable.

### Business Rules

**BR-AGE-01:** Ageing should be based on defined business dates such as invoice date or due date according to policy.

**BR-AGE-02:** Ageing categories must be configurable.

**BR-AGE-03:** Outstanding balances must reconcile with party ledger balances.

---

# 43. Payables Management

The application shall provide comprehensive payables functionality.

The business should be able to see:

- Total payables
- Supplier-wise payables
- Bill-wise payables
- Due dates
- Overdue amounts
- Ageing
- Payment history
- Advances
- Disputed amounts where applicable

---

# 44. Payment Planning

The application may support payment planning based on:

- Due dates
- Supplier priority
- Available cash
- Payment terms
- Discounts
- Credit limits
- Tax liabilities
- Management priorities

The purpose is to help management decide which obligations require attention.

---

# 45. Reminder and Confirmation Management

The application should support customer/supplier communication related to accounting balances.

Examples:

- Payment reminders
- Outstanding statements
- Account confirmations
- Payment advice

### Business Rules

**BR-REM-01:** Reminders should be based on current outstanding information.

**BR-REM-02:** Historical communications should remain identifiable where required.

**BR-REM-03:** Confirmation information must not be treated as accounting settlement until the underlying transaction is recorded.

---

# 46. Sales and Purchase Returns

The Accounting Module should support financial accounting for returns.

### Business Rules

**BR-RETURN-01:** A return should be linked to the relevant original transaction where practical.

**BR-RETURN-02:** The accounting effect of the return must be clearly identifiable.

**BR-RETURN-03:** Tax consequences of returns must be handled appropriately.

---

# 47. Advances

The application shall distinguish advances from final settlement.

Examples:

- Customer advance
- Supplier advance
- Employee advance
- Tax advance
- Other business advance

### Business Rules

**BR-ADV-01:** An advance must remain identifiable until adjusted or settled.

**BR-ADV-02:** An advance should not automatically be treated as revenue or expense unless accounting policy requires it.

**BR-ADV-03:** Adjustment of an advance against a final transaction must be traceable.

---

# 48. Fixed Assets

The Accounting Module should support accounting for fixed assets.

Business capabilities may include:

- Asset acquisition
- Asset capitalization
- Asset disposal
- Asset transfer
- Depreciation
- Asset-related expenses
- Gain/loss on disposal

### Business Rules

**BR-FA-01:** Fixed assets must be distinguishable from normal operating expenses where required.

**BR-FA-02:** Asset acquisition should be traceable to the relevant transaction.

**BR-FA-03:** Depreciation must follow the organization's accounting policy.

**BR-FA-04:** Disposal must preserve the historical asset record.

---

# 49. Loans and Advances

The Accounting Module may support accounting for loans and advances.

Examples:

- Business loans
- Employee loans
- Loans received
- Loans given
- Principal repayment
- Interest
- Outstanding balance

### Business Rules

**BR-LOAN-01:** Principal and interest should be distinguishable where required.

**BR-LOAN-02:** Repayments must be traceable to the relevant loan.

**BR-LOAN-03:** Outstanding loan balances must be reportable.

---

# 50. Budgets

The application shall support budgeting.

Budgets may be defined for:

- Groups
- Ledgers
- Cost centres
- Departments
- Projects
- Other management dimensions

### Business Needs

Management should be able to compare:

**Budget**

against

**Actual**

and identify:

- Variance
- Over-budget activity
- Under-utilization
- Trends

### Business Rules

**BR-BUD-01:** Multiple budgets may exist where business planning requires them.

**BR-BUD-02:** Budget periods must be identifiable.

**BR-BUD-03:** Actual results must remain independent of budget values.

**BR-BUD-04:** Budget revisions should remain historically traceable where required.

---

# 51. Scenario Management

The application may support accounting scenarios for planning or forecasting.

Examples:

- Expected revenue
- Forecast expenses
- Planned investments
- Cash-flow scenarios

### Business Rules

**BR-SCEN-01:** Scenario information must be distinguishable from finalized accounting information.

**BR-SCEN-02:** Scenario values must not accidentally affect official financial statements.

---

# 52. Tax and Statutory Accounting

The Accounting Module shall support applicable taxation and statutory accounting requirements.

Because tax rules change over time and differ by jurisdiction, tax functionality must be designed as a configurable business capability rather than as permanent hard-coded assumptions.

Tally.ERP 9 documentation contains extensive India-specific GST, TDS, TCS and legacy VAT/service-tax/excise functionality.

Prime-AI should prioritize the tax regimes actually applicable to its target businesses and maintain historical applicability by period.

---

# 53. GST

Where applicable, the application shall support GST accounting.

Potential business areas include:

- GST registration details
- GST rates
- GST classifications
- GST ledgers
- Taxable sales
- Purchases
- Input tax credit
- Output tax
- Reverse charge
- Advances
- Sales returns
- Purchase returns
- Exempt supplies
- Nil-rated supplies
- Zero-rated supplies
- SEZ transactions
- Imports
- Exports
- Tax payments
- GST reconciliation
- GST return preparation
- GST reporting

Tally.ERP 9 documentation specifically covers GST setup, GST classifications, ledger and party GST details, taxable sales and purchases, reverse charge scenarios, returns such as GSTR-1/GSTR-3B, annual computation and other GST reports.

### Business Rules

**BR-GST-01:** GST treatment must be determined based on applicable transaction conditions.

**BR-GST-02:** GST information must be traceable to the underlying transaction.

**BR-GST-03:** Input tax credit and output tax must be distinguishable.

**BR-GST-04:** Tax adjustments and reversals must remain traceable.

**BR-GST-05:** GST reports must reconcile with the underlying accounting transactions.

**BR-GST-06:** Changes to GST configuration must not silently rewrite historical tax treatment.

---

# 54. Reverse Charge

Where applicable, the application shall support reverse-charge transactions.

### Business Rules

**BR-RCM-01:** Reverse-charge transactions must be identifiable.

**BR-RCM-02:** Applicable liability and input-credit treatment must be separately traceable.

**BR-RCM-03:** Reverse-charge payment and adjustment must remain linked to the relevant tax liability.

---

# 55. TDS

Where applicable, the application shall support Tax Deducted at Source accounting.

Potential business areas include:

- TDS applicability
- Nature of payment
- TDS rate
- TDS deduction
- Lower/zero rate scenarios
- TDS on advances
- TDS on expenses
- TDS on fixed assets
- TDS on transport
- TDS on interest
- TDS payment
- TDS reconciliation
- TDS returns

Tally.ERP 9 documentation includes TDS masters, expense/party/tax ledgers, several TDS transaction scenarios and reports such as Form 26Q, Form 27Q, outstanding reports and challan reconciliation.

### Business Rules

**BR-TDS-01:** TDS applicability must be determined according to the applicable rule and transaction.

**BR-TDS-02:** TDS deducted must remain traceable to the underlying transaction.

**BR-TDS-03:** TDS payable must be distinguishable from the expense or payable to the party.

**BR-TDS-04:** TDS payment and return information must reconcile with the underlying TDS records.

---

# 56. TCS

Where applicable, the application shall support Tax Collected at Source.

Potential capabilities include:

- TCS applicability
- Nature of goods/transaction
- Rate
- Collection
- Payment
- Interest
- Penalty
- Late fee
- Reconciliation
- TCS return information

### Business Rules

**BR-TCS-01:** TCS collection must be traceable to the underlying transaction.

**BR-TCS-02:** TCS liability and payment must be separately identifiable.

**BR-TCS-03:** TCS reporting must reconcile with the underlying records.

---

# 57. Legacy / Jurisdiction-Specific Tax Capabilities

The Tally.ERP 9 reference also contains historical/legacy functionality for regimes such as:

- VAT
- CST
- Service Tax
- Excise
- State-specific statutory forms

These capabilities should not automatically become mandatory Prime-AI requirements.

They should be treated as a reference for designing a flexible statutory-accounting framework and considered only when a target jurisdiction, business type or historical-data requirement requires them.

---

# 58. Tax Period and Compliance Calendar

The application should support tracking of statutory due dates and compliance activities.

Potential activities include:

- Return preparation
- Return review
- Payment
- Filing
- Reconciliation
- Correction/revision
- Supporting-document review

### Business Rules

**BR-TAXCAL-01:** Statutory deadlines should be configurable.

**BR-TAXCAL-02:** Completed compliance activities must remain historically traceable.

**BR-TAXCAL-03:** Overdue compliance activities should be identifiable.

---

# 59. Financial Statements

The Accounting Module shall provide financial statements.

At minimum:

- Balance Sheet
- Profit & Loss Account
- Trial Balance
- Receipts and Payments
- Cash Flow
- Fund Flow

Tally.ERP 9 documentation identifies Balance Sheet, Profit & Loss, Trial Balance, Receipts and Payments, Cash Flow and Fund Flow among its accounting reports.

---

# 60. Balance Sheet

The Balance Sheet shall provide a view of the organization's financial position.

It should present relevant:

- Assets
- Liabilities
- Capital/equity
- Other applicable classifications

### Business Rules

**BR-BS-01:** Balance Sheet values must derive from accounting records and applicable closing rules.

**BR-BS-02:** The report must support period/date selection.

**BR-BS-03:** Users should be able to drill down from summarized balances to underlying accounts and transactions.

---

# 61. Profit and Loss Account

The Profit & Loss Account shall provide a view of:

- Revenue
- Income
- Cost
- Expenses
- Profit
- Loss

### Business Rules

**BR-PL-01:** Income and expenses must be classified correctly for reporting.

**BR-PL-02:** The report should support period comparisons.

**BR-PL-03:** Users should be able to trace material values back to underlying transactions.

---

# 62. Trial Balance

The Trial Balance shall summarize ledger balances and support verification that accounting balances are consistent.

### Business Rules

**BR-TB-01:** Trial Balance should show account balances by appropriate grouping.

**BR-TB-02:** Debit and credit totals must reconcile.

**BR-TB-03:** Users should be able to drill down from a ledger balance to underlying transactions.

---

# 63. Cash Flow

The application should provide cash-flow analysis.

The business should be able to understand:

- Cash generated
- Cash consumed
- Operating cash movements
- Investing cash movements
- Financing cash movements
- Opening cash
- Closing cash

---

# 64. Fund Flow

Where required, the application should provide fund-flow analysis to help management understand movement in financial resources.

---

# 65. Ratio Analysis

The application should provide financial ratios where appropriate.

Potential ratios include:

- Current ratio
- Quick ratio
- Gross margin
- Net margin
- Return-related ratios
- Receivable turnover
- Payable turnover
- Other business-defined ratios

### Business Rules

**BR-RATIO-01:** Ratio definitions must be clearly documented.

**BR-RATIO-02:** Users should understand the period and values used in a ratio.

**BR-RATIO-03:** Ratio calculations must be traceable to underlying financial information.

---

# 66. Cash Flow Projection

The application may support future cash-flow projections using:

- Expected receipts
- Expected payments
- Outstanding receivables
- Outstanding payables
- Planned expenses
- Planned investments
- Other forecast information

Scenario values must remain distinguishable from actual accounting results.

---

# 67. Books and Registers

The application shall provide detailed accounting books and registers.

Potential reports include:

- Day Book
- Cash Book
- Bank Book
- Sales Register
- Purchase Register
- Receipt Register
- Payment Register
- Journal Register
- Debit Note Register
- Credit Note Register
- Ledger Vouchers
- Group Vouchers
- Account Statements

Tally.ERP 9 provides these categories of registers and statements and allows users to drill into accounting information.

---

# 68. Day Book

The Day Book should provide a chronological view of transactions for a selected date or period.

### Business Rules

**BR-DAY-01:** The Day Book should include relevant accounting transactions for the selected period.

**BR-DAY-02:** Users should be able to drill into individual transactions.

**BR-DAY-03:** Cancelled or provisional transactions should be distinguishable where applicable.

---

# 69. Ledger Statement

The application shall provide a detailed statement for a selected ledger.

It should show:

- Opening balance
- Transactions
- Debit
- Credit
- Running balance
- Closing balance
- Relevant references

---

# 70. Group Statement

The application should provide group-level financial summaries and drill-down capability.

The user should be able to move from:

**Group**

→

**Sub-group**

→

**Ledger**

→

**Transaction**

---

# 71. Outstanding Reports

The application shall provide receivable and payable outstanding reports.

The business should be able to filter by:

- Party
- Group
- Date
- Due date
- Ageing
- Amount
- Status
- Branch/business unit
- Other relevant business dimensions

---

# 72. Exception Reports

The application should identify unusual or potentially problematic accounting conditions.

Examples include:

- Negative cash
- Negative ledger balance where unexpected
- Overdue receivables
- Overdue payables
- Unreconciled bank transactions
- Unallocated advances
- Unadjusted bills
- Unusual journal entries
- Cancelled transactions
- Post-dated transactions
- Provisional transactions
- Missing tax information
- Incomplete party information
- Duplicate references
- Other business-defined exceptions

Tally.ERP 9 explicitly includes exception reporting for negative ledgers, overdue receivables/payables, memorandum, reversing, optional, cancelled and post-dated vouchers.

---

# 73. Audit Trail and Accounting Review

The Accounting Module shall support auditability.

The business should be able to determine:

- Who created a transaction
- Who modified it
- When it was modified
- What was changed
- Why it was changed where required
- Who approved it
- Whether it was cancelled
- Whether it was reversed
- Whether it was reconciled
- Whether it was included in a statutory process

### Business Rules

**BR-AUD-01:** Important accounting changes must be traceable.

**BR-AUD-02:** Financial records should not be silently overwritten.

**BR-AUD-03:** Cancellation and reversal must remain distinguishable from deletion.

**BR-AUD-04:** Audit history must have stronger protection than normal operational data.

---

# 74. Transaction Correction

The application shall support controlled correction of accounting mistakes.

Possible approaches include:

- Editing before finalization
- Reversal
- Adjustment entry
- Debit/credit note
- Corrective transaction

### Business Rules

**BR-CORR-01:** The correction method must be appropriate to the accounting situation.

**BR-CORR-02:** Historical evidence of the original transaction should remain available where required.

**BR-CORR-03:** Corrections must not conceal the existence of the original error where auditability requires its preservation.

---

# 75. Cancellation

The application should support transaction cancellation.

### Business Rules

**BR-CANCEL-01:** Cancellation must be controlled.

**BR-CANCEL-02:** A cancelled transaction must remain identifiable as cancelled where historical traceability is required.

**BR-CANCEL-03:** Cancellation must not be equivalent to silently deleting the transaction.

**BR-CANCEL-04:** The business should be able to report cancelled transactions.

---

# 76. Approval and Authorization

The application should support approval workflows for sensitive accounting activities.

Potential approval candidates include:

- High-value payments
- Journal adjustments
- Credit-limit overrides
- Discounts
- Manual tax overrides
- Period reopening
- Large write-offs
- Account changes
- Bank-detail changes
- Cancellation of finalized transactions

### Business Rules

**BR-APPROVE-01:** Approval requirements should be configurable by business policy.

**BR-APPROVE-02:** The person approving a transaction must be identifiable.

**BR-APPROVE-03:** Approval must not erase the identity of the person who created the transaction.

**BR-APPROVE-04:** A rejected transaction must remain traceable.

---

# 77. Maker-Checker Principle

Where required, the application should support separation between:

**Maker**

and

**Checker / Approver**

### Business Rules

**BR-MAKER-01:** A user should not approve their own transaction where segregation of duties requires independent approval.

**BR-MAKER-02:** Approval rights must depend on user responsibility and business policy.

**BR-MAKER-03:** Overrides must be auditable.

---

# 78. Accounting Controls

The application should provide controls to prevent common accounting mistakes.

Examples:

- Unbalanced transaction
- Invalid account
- Invalid date
- Closed-period entry
- Duplicate reference
- Missing party
- Missing tax information
- Invalid tax treatment
- Excessive credit
- Negative cash
- Invalid currency
- Missing required approval
- Incomplete bank information

---

# 79. Transaction Narration

Important transactions should support narration or explanation.

### Business Rules

**BR-NARR-01:** Significant adjustments should require meaningful narration.

**BR-NARR-02:** Narration should describe the business reason where necessary.

**BR-NARR-03:** Narration should remain historically associated with the transaction.

---

# 80. Supporting Documents and Evidence

Accounting transactions may require supporting documents such as:

- Invoice
- Receipt
- Purchase bill
- Contract
- Bank statement
- Tax document
- Approval document
- Credit/debit note
- Other supporting evidence

### Business Rules

**BR-DOC-01:** Important transactions should be able to reference supporting evidence.

**BR-DOC-02:** Evidence must remain associated with the relevant accounting activity.

**BR-DOC-03:** Evidence access should follow business permissions.

---

# 81. Period Closing

The application shall support period-end and year-end closing activities.

Potential activities include:

- Review outstanding balances
- Bank reconciliation
- Tax reconciliation
- Adjustment entries
- Depreciation
- Accruals
- Provisions
- Review of suspense accounts
- Review of unusual balances
- Finalization
- Closing period

### Business Rules

**BR-CLOSE-01:** Closing should occur only after appropriate review.

**BR-CLOSE-02:** Closed periods should be protected from unauthorized changes.

**BR-CLOSE-03:** Reopening should require authorization.

**BR-CLOSE-04:** Reopening and subsequent changes must be auditable.

---

# 82. Opening Balances

The application shall support opening balances.

Opening balances may include:

- Cash
- Bank
- Receivables
- Payables
- Assets
- Liabilities
- Capital
- Other applicable accounts

### Business Rules

**BR-OPEN-01:** Opening balances must be identifiable as opening values.

**BR-OPEN-02:** Opening balances should be reviewable and reconcilable.

**BR-OPEN-03:** Changes to finalized opening balances must be controlled.

---

# 83. Year-End Carry Forward

The application should support appropriate carry-forward of balances between financial years.

### Business Rules

**BR-CARRY-01:** Balance-sheet-related balances should carry forward according to accounting rules.

**BR-CARRY-02:** Revenue and expense accounts should be handled according to the organization's accounting process.

**BR-CARRY-03:** Carry-forward values must remain traceable to the previous period.

---

# 84. Inventory Integration

The Accounting Module should integrate with inventory when the Prime-AI application includes inventory management.

Accounting and inventory should have clear responsibilities.

Potential integrated activities include:

- Purchase of goods
- Sales of goods
- Stock valuation
- Cost of goods
- Purchase returns
- Sales returns
- Inventory adjustments
- Stock-related accounting

### Business Rules

**BR-INV-01:** Inventory information and accounting information must remain consistent.

**BR-INV-02:** A stock transaction that has financial impact must be reflected appropriately in accounting.

**BR-INV-03:** Inventory changes must not result in duplicate accounting entries.

**BR-INV-04:** The source of a financial amount should remain traceable.

---

# 85. Sales Module Integration

Where a separate Sales Module exists, sales transactions should flow into accounting appropriately.

The Accounting Module should receive or recognize:

- Customer
- Invoice
- Revenue
- Tax
- Discount
- Receivable
- Receipt/settlement information

### Business Rule

**BR-SALES-INT-01:** Financial information originating from Sales must not require unnecessary duplicate entry.

---

# 86. Purchase Module Integration

Where a separate Purchase Module exists, purchase information should flow into accounting appropriately.

Potential information includes:

- Supplier
- Purchase invoice
- Expense/stock value
- Tax
- Payable
- Payment information

---

# 87. Payroll Integration

Where a Payroll Module exists, payroll-related accounting should integrate with accounting.

Potential accounting effects include:

- Salary expense
- Employee payable
- Statutory deductions
- Employer contributions
- Salary payments
- Payroll-related liabilities

The payroll process should remain the responsibility of the Payroll Module while the Accounting Module records the financial impact.

---

# 88. Project / Job Costing

The Accounting Module should support financial analysis by project or job where required.

Potential information includes:

- Project income
- Project expenses
- Material costs
- Labour costs
- Other direct costs
- Allocated overheads
- Project profitability

### Business Rules

**BR-JOB-01:** Project costs must be traceable to the underlying accounting transactions.

**BR-JOB-02:** Project profitability should reconcile with accounting records.

**BR-JOB-03:** A project allocation should not duplicate the underlying expense.

---

# 89. Cost and Profitability Analysis

Management should be able to analyze:

- Revenue by business unit
- Expense by department
- Profit by project
- Profit by branch
- Cost by category
- Customer profitability
- Product/service profitability where relevant

---

# 90. Management Information System

The Accounting Module should provide management information beyond statutory statements.

Possible reports include:

- Receivable analysis
- Payable analysis
- Cost-centre analysis
- Cash-flow analysis
- Fund-flow analysis
- Budget variance
- Ratio analysis
- Exception reports
- Profitability analysis
- Expense trends
- Income trends

---

# 91. Drill-Down Principle

Financial reports should be explainable.

The business should be able to move from:

**Management Report**

→

**Financial Statement**

→

**Group**

→

**Ledger**

→

**Transaction**

→

**Supporting Evidence**

This should be a core business principle.

---

# 92. Comparative Reporting

The application should support comparison across:

- Current vs previous period
- Current year vs previous year
- Budget vs actual
- Branch vs branch
- Department vs department
- Project vs project
- Customer vs customer
- Supplier vs supplier

---

# 93. Financial Search and Filtering

Users should be able to search and filter accounting information by:

- Date
- Voucher type
- Voucher number
- Ledger
- Group
- Customer
- Supplier
- Amount
- Cost centre
- Project
- Tax
- Payment mode
- Bank
- Status
- User
- Approval status
- Reconciliation status

---

# 94. Business Data Integrity

The Accounting Module must protect financial data integrity.

### Business Rules

**BR-INTEGRITY-01:** A transaction must not be partially recorded.

**BR-INTEGRITY-02:** Financial postings must remain balanced.

**BR-INTEGRITY-03:** Related accounting information must remain consistent.

**BR-INTEGRITY-04:** Invalid transactions must be rejected or clearly identified.

**BR-INTEGRITY-05:** System-generated calculations must be explainable.

---

# 95. Duplicate Transaction Prevention

The application should help prevent duplicate accounting entries.

Potential duplicate indicators include:

- Same party
- Same document number
- Same document date
- Same amount
- Same transaction type
- Same reference

### Business Rules

**BR-DUP-01:** Duplicate detection should be based on appropriate business criteria.

**BR-DUP-02:** The system may warn about potential duplicates rather than automatically rejecting every similar transaction.

**BR-DUP-03:** A user override should be recorded where permitted.

---

# 96. Security and Access

Accounting information is sensitive.

The application shall support controlled access to:

- Masters
- Transactions
- Reports
- Tax information
- Bank information
- Approvals
- Period closing
- Audit information

### Business Rules

**BR-SEC-01:** Users should receive only the access appropriate to their responsibilities.

**BR-SEC-02:** Financial information must not be exposed to unauthorized users.

**BR-SEC-03:** Access to high-risk accounting activities should be restricted.

---

# 97. User Accountability

The business should always be able to identify the responsible user for important accounting actions.

Relevant activities include:

- Creation
- Modification
- Approval
- Cancellation
- Reversal
- Reconciliation
- Period closing
- Period reopening
- Tax filing preparation
- Configuration changes

---

# 98. Accounting Notifications

The application may notify responsible users about:

- Overdue receivables
- Overdue payables
- Failed bank reconciliation
- Unapproved transactions
- Tax deadlines
- Negative cash
- Credit-limit breaches
- High-value transactions
- Pending period closing
- Unusual accounting activity

Notifications should remain relevant and should not replace accounting controls.

---

# 99. Exception and Risk Monitoring

The application should identify accounting risks.

Examples:

- Large unusual transaction
- Repeated manual journal entries
- Frequent cancellations
- Frequent corrections
- Negative cash
- Long-overdue receivables
- Long-overdue payables
- Unreconciled bank balances
- Unusual tax values
- Excessive credit exposure
- Transactions outside normal business patterns

These may later become candidates for intelligent analysis.

---

# 100. AI-Assisted Accounting Analysis

The Accounting Module may use AI to assist with analysis.

Potential capabilities include:

- Duplicate transaction detection
- Unusual transaction detection
- Expense classification suggestions
- Ledger classification suggestions
- Tax treatment suggestions
- Reconciliation suggestions
- Outstanding collection prioritization
- Payment prioritization
- Cash-flow forecasting
- Budget variance explanation
- Financial trend explanation
- Potential error detection
- Suspicious journal identification

### Business Rules

**BR-AI-ACC-01:** AI recommendations must not silently change accounting records.

**BR-AI-ACC-02:** Important accounting decisions must remain subject to appropriate human review.

**BR-AI-ACC-03:** AI-generated classifications must be distinguishable from confirmed accounting classifications.

**BR-AI-ACC-04:** Important AI recommendations should provide supporting reasoning or evidence where practical.

---

# 101. Historical Accounting Integrity

Accounting information is long-term business evidence.

### Business Rules

**BR-HIST-ACC-01:** Historical transactions must not be silently rewritten.

**BR-HIST-ACC-02:** Changes to accounting masters must not unexpectedly change historical transaction meaning.

**BR-HIST-ACC-03:** Historical tax treatment must remain explainable.

**BR-HIST-ACC-04:** Historical reports must remain reproducible or explainable.

**BR-HIST-ACC-05:** Corrections must be traceable.

---

# 102. Accounting Master Changes

Changes to:

- Ledger classification
- Tax configuration
- Credit limits
- Payment terms
- Cost-centre configuration
- Bank details
- Currency
- Other accounting master information

may affect future transactions.

### Business Rules

**BR-MASTER-01:** Master changes should normally apply prospectively unless an authorized correction explicitly requires otherwise.

**BR-MASTER-02:** Historical transactions must retain appropriate historical context.

**BR-MASTER-03:** Important master changes must be auditable.

---

# 103. Reporting Accuracy

Reports are business outputs and must be trustworthy.

### Business Rules

**BR-REPORT-01:** Reports must use the same underlying accounting truth.

**BR-REPORT-02:** Different reports representing the same accounting concept should reconcile.

**BR-REPORT-03:** Report filters and periods must be clearly visible.

**BR-REPORT-04:** Report calculations must be explainable.

---

# 104. Accounting Reconciliation Principle

The application should support reconciliation between related accounting views.

Examples:

- Ledger vs Trial Balance
- Bank Book vs Bank Statement
- Receivables vs Customer Ledgers
- Payables vs Supplier Ledgers
- GST reports vs GST-related transactions
- TDS reports vs TDS transactions
- TCS reports vs TCS transactions
- Cost-centre reports vs accounting transactions

---

# 105. Multi-Branch / Multi-Unit Accounting

Where required, the application should support financial analysis across:

- Branches
- Locations
- Divisions
- Business units
- Legal entities

### Business Rules

**BR-BRANCH-01:** Transactions must be attributable to the appropriate business unit where required.

**BR-BRANCH-02:** Consolidated reporting should be possible.

**BR-BRANCH-03:** Unit-level reporting should remain possible.

**BR-BRANCH-04:** Inter-unit transactions must be distinguishable from external transactions.

---

# 106. Inter-Unit Transactions

Where multiple business units exist, the application should support internal transactions.

Examples:

- Inter-branch transfer
- Inter-company transaction
- Shared expense allocation
- Internal service charge

### Business Rules

**BR-INTER-01:** Internal transactions must be distinguishable from external transactions.

**BR-INTER-02:** Both sides of an internal transaction should remain traceable where applicable.

**BR-INTER-03:** Consolidated reporting must prevent inappropriate double counting.

---

# 107. Data Import

The Accounting Module may support importing accounting information from external sources.

Possible imports include:

- Opening balances
- Bank statements
- Customer/supplier masters
- Transactions
- Tax information
- Other accounting data

### Business Rules

**BR-IMPORT-01:** Imported information must be validated before becoming finalized accounting information where appropriate.

**BR-IMPORT-02:** Import source must remain identifiable.

**BR-IMPORT-03:** Duplicate import must not create unintended duplicate accounting transactions.

**BR-IMPORT-04:** Import errors must be identifiable and reviewable.

---

# 108. Data Export

The application should support export of accounting information for:

- Auditors
- Tax professionals
- Management
- External systems
- Backup/archival purposes
- Regulatory purposes

### Business Rules

**BR-EXPORT-01:** Exported data must represent the selected accounting information accurately.

**BR-EXPORT-02:** Export scope and period must be identifiable.

**BR-EXPORT-03:** Sensitive accounting data must be protected during export.

---

# 109. Audit / Accountant Access

The application should support controlled access for accountants, auditors or external reviewers where required.

Possible capabilities include:

- View financial statements
- View ledgers
- Review transactions
- Review audit trail
- Review exceptions
- Add review notes
- Identify transactions requiring clarification

Reviewer access should not automatically provide modification rights.

---

# 110. Accounting Notes and Review Comments

Authorized users should be able to add review comments to accounting records.

Examples:

- “Awaiting invoice copy”
- “Tax treatment under review”
- “Bank reconciliation pending”
- “Management approval required”
- “Possible duplicate”
- “Supporting document verified”

Review comments should not alter the accounting amount unless an authorized accounting transaction is subsequently recorded.

---

# 111. Periodic and Recurring Transactions

The application may support identification or preparation of recurring transactions.

Examples:

- Rent
- Insurance
- Subscription
- Loan installment
- Salary-related recurring entries
- Service contracts

### Business Rules

**BR-RECUR-01:** Recurring transaction definitions must be distinguishable from actual posted transactions.

**BR-RECUR-02:** Generated transactions must be reviewed where business policy requires.

**BR-RECUR-03:** Changes to recurring definitions should not alter already posted transactions.

---

# 112. Accounting Workflow States

A financial transaction may move through states such as:

**Draft**

→

**Submitted**

→

**Approved**

→

**Posted**

→

**Reconciled**

→

**Closed**

or, where applicable:

**Posted**

→

**Cancelled / Reversed / Corrected**

The exact workflow should depend on business policy.

### Business Rules

**BR-WF-01:** A transaction's current state must be clear.

**BR-WF-02:** Important state changes must be traceable.

**BR-WF-03:** Posted transactions should have stronger controls than drafts.

---

# 113. Financial Close Checklist

The application should support a period-close checklist.

Potential checklist items:

- Bank reconciliation completed
- Cash verified
- Receivables reviewed
- Payables reviewed
- Tax liabilities reviewed
- Tax returns reconciled
- Suspense accounts reviewed
- Advances reviewed
- Fixed assets reviewed
- Depreciation recorded
- Accruals recorded
- Provisions reviewed
- Unusual transactions reviewed
- Management review completed

---

# 114. Suspense and Temporary Accounts

The application should support temporary or suspense accounts where required.

### Business Rules

**BR-SUSP-01:** Suspense balances should be identifiable.

**BR-SUSP-02:** Suspense accounts should be reviewed periodically.

**BR-SUSP-03:** Long-standing suspense balances should be highlighted as exceptions.

---

# 115. Write-Offs and Adjustments

The application may support controlled write-offs.

Examples:

- Bad debt
- Small balance adjustment
- Rounding adjustment
- Other approved write-off

### Business Rules

**BR-WRITE-01:** Write-offs should require appropriate authorization.

**BR-WRITE-02:** The reason for the write-off should be recorded.

**BR-WRITE-03:** The original outstanding history should remain traceable.

---

# 116. Rounding and Minor Differences

The application should support controlled handling of legitimate rounding differences.

### Business Rules

**BR-ROUND-01:** Rounding rules should be clearly defined.

**BR-ROUND-02:** Rounding adjustments must be distinguishable from ordinary transactions.

---

# 117. Business Continuity and Recovery

Financial information is critical business data.

The application should support business processes for:

- Backup
- Recovery
- Data integrity verification
- Recovery from failed processing
- Historical preservation

Technical implementation is outside this BRD, but the business requirement is that accounting data must be recoverable without compromising financial integrity.

---

# 118. Accounting Data Retention

The application should retain accounting information according to:

- Legal requirements
- Tax requirements
- Audit requirements
- Organizational policy
- Business needs

Historical records should remain available for investigation and reporting for the required retention period.

---

# 119. Accounting Performance and Usability Expectations

The business expects the Accounting Module to support:

- Large transaction volumes
- Large Chart of Accounts
- Many customers and suppliers
- Many bank transactions
- Long accounting histories
- Multiple reporting dimensions

Users should be able to navigate from summaries to detailed transactions without unnecessary complexity.

---

# 120. Core Accounting Business Rules

The following rules are fundamental.

### Rule 1 — No Unbalanced Final Accounting

Finalized accounting transactions must maintain debit/credit integrity.

### Rule 2 — Every Transaction Must Have a Business Purpose

A financial transaction must represent a legitimate business event or accounting adjustment.

### Rule 3 — History Must Be Preserved

Historical financial information must not be silently rewritten.

### Rule 4 — Correction Must Be Traceable

Corrections must not hide the existence of the original accounting event where auditability requires preservation.

### Rule 5 — Cancellation Is Not Deletion

A cancelled transaction should remain historically identifiable.

### Rule 6 — Approval Is Not Creation

The person approving a transaction is not necessarily the person who created it.

### Rule 7 — Customer and Supplier Balances Must Reconcile

Party outstanding information must reconcile with the underlying ledger information.

### Rule 8 — Bank Balances Must Be Reconciliable

Accounting bank balances must be capable of reconciliation with external bank statements.

### Rule 9 — Tax Must Be Traceable

Tax amounts must be traceable to the transactions from which they arise.

### Rule 10 — Reports Must Be Explainable

A financial report value should be traceable to underlying accounting information.

### Rule 11 — Masters and History Are Different

Changing a current master must not silently rewrite historical accounting meaning.

### Rule 12 — AI Must Assist, Not Post Silently

AI may recommend accounting classifications or actions but must not silently alter finalized accounting.

---

# 121. Business Conditions

The Accounting Module shall operate under the following conditions:

## BC-ACC-01 — Multiple Users

Multiple authorized users may perform accounting activities.

## BC-ACC-02 — Different Responsibilities

Users may have different accounting responsibilities and access.

## BC-ACC-03 — Continuous Transactions

Transactions may be recorded throughout the accounting period.

## BC-ACC-04 — Multiple Transaction Types

The organization may use different voucher/document types.

## BC-ACC-05 — Multiple Parties

The organization may have many customers and suppliers.

## BC-ACC-06 — Multiple Bank Accounts

The organization may maintain multiple bank accounts.

## BC-ACC-07 — Multiple Currencies

Some organizations may operate in multiple currencies.

## BC-ACC-08 — Tax Changes

Tax rules and rates may change over time.

## BC-ACC-09 — Historical Data

Historical accounting data must remain available.

## BC-ACC-10 — Corrections

Accounting errors may require controlled corrections.

## BC-ACC-11 — Period Closure

Accounting periods may be closed and later reopened under authorization.

## BC-ACC-12 — External Reconciliation

Accounting information may need reconciliation with external sources.

## BC-ACC-13 — Audit

Accounting information may be reviewed by internal or external auditors.

## BC-ACC-14 — Management Reporting

Management may require information beyond statutory financial statements.

## BC-ACC-15 — Integration

Accounting may receive financial information from Sales, Purchase, Inventory, Payroll, Banking and other modules.

---

# 122. Accounting Success Criteria

The Accounting Module will be considered successful when the organization can reliably answer:

### Financial Position

- What do we own?
- What do we owe?
- What is our capital/equity position?
- What is our current financial position?

### Profitability

- How much revenue did we generate?
- What were our expenses?
- What is our profit/loss?
- Which business areas are profitable?

### Receivables

- Who owes us money?
- How much?
- Which invoices are overdue?
- How long have they been outstanding?

### Payables

- Whom do we owe?
- How much?
- Which bills are due?
- Which obligations are overdue?

### Banking

- What is our bank balance?
- Which transactions have cleared?
- What remains unreconciled?
- Which cheques are outstanding?

### Tax

- What tax do we owe?
- What tax credit is available?
- What has been paid?
- What remains to be filed or reconciled?

### Budget

- What was planned?
- What actually happened?
- Where are the variances?

### Audit

- Who created this transaction?
- Who changed it?
- Who approved it?
- Why was it changed?
- Was it cancelled or reversed?

### Management

- What is our cash position?
- What are the major risks?
- Where are costs increasing?
- Which customers are high-risk?
- Which suppliers require attention?
- What financial trends are emerging?

---

# 123. Additional Business Suggestions

The following capabilities are recommended to make the Prime-AI Accounting Module more robust.

## AS-ACC-01 — Accounting Health Dashboard

Provide a high-level accounting health view showing:

- Cash position
- Bank reconciliation status
- Receivables
- Payables
- Tax liabilities
- Overdue items
- Unapproved transactions
- Suspense balances
- Budget variances
- Unusual transactions

---

## AS-ACC-02 — Financial Close Dashboard

Provide a controlled view of the current period's closing readiness.

---

## AS-ACC-03 — Accounting Risk Score

Provide a business-level risk indicator based on:

- Unreconciled balances
- Overdue receivables
- Overdue payables
- Suspense balances
- Large adjustments
- Unusual transactions
- Tax discrepancies
- Repeated corrections

The score should remain explainable.

---

## AS-ACC-04 — Collection Prioritization

Use receivable history to recommend which customers should receive collection attention first.

---

## AS-ACC-05 — Payment Prioritization

Use payable due dates, cash availability and business priority to recommend payment priorities.

---

## AS-ACC-06 — Cash Forecasting

Combine:

- Current cash
- Expected collections
- Expected payments
- Recurring obligations
- Tax liabilities
- Planned expenditure

to provide cash-flow forecasts.

---

## AS-ACC-07 — Duplicate Detection

Identify potentially duplicated:

- Bills
- Invoices
- Payments
- Receipts
- Journal entries

before or after posting.

---

## AS-ACC-08 — Unusual Transaction Detection

Identify transactions that differ materially from normal historical patterns.

---

## AS-ACC-09 — Automated Reconciliation Suggestions

Where reliable evidence exists, suggest matches between:

- Bank statement and bank book
- Payment and invoice
- Receipt and invoice
- Tax records and accounting records

Users should retain control over final confirmation.

---

## AS-ACC-10 — Accounting Knowledge Base

Maintain explanations and historical relationships such as:

- Why a transaction was adjusted
- Why a tax treatment was selected
- Why a payment was delayed
- Why a reconciliation difference occurred
- Why a write-off was approved

---

## AS-ACC-11 — Explainable Financial Reports

Every major financial number should be drillable to its source.

---

## AS-ACC-12 — Accounting Anomaly Investigation

Allow users to investigate suspicious patterns rather than merely receiving an alert.

---

## AS-ACC-13 — Period Locking

Provide strong business controls around finalized periods.

---

## AS-ACC-14 — Segregation of Duties

Support separation of:

- Data entry
- Approval
- Payment authorization
- Reconciliation
- Period closing

where organizational policy requires it.

---

## AS-ACC-15 — Accounting Data Quality Score

Provide a data-quality view covering:

- Missing information
- Unreconciled transactions
- Duplicate candidates
- Incorrect classifications
- Outstanding exceptions
- Incomplete tax details

---

# 124. Tally Benchmark Coverage Matrix

The following summarizes the major Tally.ERP 9 accounting capabilities considered during preparation of this BRD and their corresponding Prime-AI business scope.

| Tally.ERP 9 Capability | Prime-AI Business Requirement |
|---|---|
| Groups | Chart of Accounts / Accounting Groups |
| Ledgers | Ledger Accounts |
| Bank Ledger | Bank Account Management |
| Party Ledger | Customer/Supplier Accounting |
| Purchase/Sales Ledger | Purchase/Sales Accounting |
| Voucher Types | Accounting Transaction Types |
| Voucher Classes | Controlled / Predefined Transaction Allocation |
| Contra | Internal Cash/Bank Transfers |
| Payment | Payment Transactions |
| Receipt | Receipt Transactions |
| Journal | Adjustment Accounting |
| Debit Note | Debit Note Management |
| Credit Note | Credit Note Management |
| Post-dated Vouchers | Post-dated Transactions |
| Optional Vouchers | Provisional / Scenario Accounting |
| Cost Categories | Multi-dimensional Cost Analysis |
| Cost Centres | Cost Centre Accounting |
| Multi-currency | Foreign Currency Accounting |
| Credit Limits | Customer Credit Management |
| Budgets | Budget vs Actual |
| Interest Calculations | Interest Management |
| Cheque Management | Cheque Lifecycle |
| E-Payments | Electronic Payment Processing |
| Bank Reconciliation | Bank Statement Reconciliation |
| Receivables | Customer Outstanding Management |
| Payables | Supplier Outstanding Management |
| Ageing | Receivable/Payable Ageing |
| Cash Flow | Cash Flow Reporting |
| Fund Flow | Fund Flow Reporting |
| Ratio Analysis | Financial Ratio Analysis |
| Cash Flow Projection | Cash Forecasting |
| Exception Reports | Accounting Risk/Exception Monitoring |
| GST | GST Accounting and Compliance |
| TDS | TDS Accounting and Compliance |
| TCS | TCS Accounting and Compliance |
| Financial Statements | Balance Sheet / P&L / Trial Balance |
| Day Book | Transaction Register |
| Ledger Statements | Account Statements |
| Audit / Verification | Auditability and Review |

---

# 125. Requirements Intentionally Not Prescribed by This BRD

The following decisions should be made after the business requirements are approved:

1. Exact database structure
2. Ledger table design
3. Voucher header/detail design
4. Accounting-entry representation
5. Tax data model
6. Cost-centre data model
7. Bank-reconciliation data model
8. Multi-currency calculation model
9. Approval workflow implementation
10. Technical audit architecture
11. API architecture
12. Import/export file formats
13. Integration architecture
14. Technical reporting architecture
15. Technical AI implementation

These belong to subsequent Functional Specification and Technical Design documents.

---

# 126. Key Business Principle

The central principle of the Prime-AI Accounting Module should be:

> **Every financial number shown to the business must be trustworthy, explainable, traceable, and consistent with the underlying accounting records.**

A user should be able to move from:

**Financial Decision**

→

**Financial Report**

→

**Account**

→

**Transaction**

→

**Business Document**

→

**Supporting Evidence**

and understand how the final number was produced.

---

# 127. Final Business Vision

The Prime-AI Accounting Module should not merely be a system for entering debit and credit transactions.

It should become the organization's:

**Financial Record**

+

**Financial Control System**

+

**Receivables and Payables Management System**

+

**Banking and Reconciliation System**

+

**Tax Accounting System**

+

**Management Accounting System**

+

**Financial Reporting System**

+

**Audit and Compliance Evidence System**

+

**Financial Intelligence Platform**

The desired evolution is:

**Record Transactions**

↓

**Maintain Accurate Books**

↓

**Track Receivables and Payables**

↓

**Manage Cash and Banking**

↓

**Reconcile Financial Information**

↓

**Manage Tax and Statutory Obligations**

↓

**Close Accounting Periods**

↓

**Produce Financial Statements**

↓

**Analyze Profitability and Cash Flow**

↓

**Monitor Risks and Exceptions**

↓

**Forecast Financial Position**

↓

**Use Historical Evidence and AI to Improve Financial Decisions**

---

# 128. BRD Review Questions

Before the Accounting Module moves to Functional Specification and Technical Design, the following business decisions should be confirmed:

1. Is the Accounting Module intended for a single organization or multiple organizations?
2. Is multi-company accounting required?
3. Is multi-branch accounting required?
4. Is consolidated accounting required?
5. What is the organization's financial year?
6. Can accounting periods be reopened?
7. Who can reopen a closed period?
8. Which accounting transactions require approval?
9. Which transactions require maker-checker separation?
10. What constitutes a finalized accounting transaction?
11. Which transactions can be cancelled?
12. Which transactions must be reversed rather than edited?
13. What is the required voucher numbering policy?
14. Is bill-wise accounting mandatory for customers and suppliers?
15. Are credit limits required?
16. Is multi-currency required?
17. Which currencies must be supported?
18. Is interest calculation required?
19. Which interest rules are required?
20. Are cost centres required?
21. Are multiple cost dimensions required?
22. Is project/job costing required?
23. Is inventory integration required?
24. Is Sales integration required?
25. Is Purchase integration required?
26. Is Payroll integration required?
27. Which banking facilities are required?
28. Is bank statement import required?
29. Is automatic reconciliation required?
30. Are electronic payments required?
31. Is cheque printing required?
32. Which statutory taxes must be supported?
33. Is GST mandatory?
34. Is TDS mandatory?
35. Is TCS mandatory?
36. Are historical VAT/Service Tax/Excise records required?
37. Which statutory returns must be supported?
38. How long must accounting history be retained?
39. What financial reports are mandatory?
40. Which management reports are required?
41. Which financial ratios are important?
42. What constitutes an accounting exception?
43. Which accounting activities should generate notifications?
44. What level of AI assistance is acceptable?
45. Which AI recommendations require human approval?
46. What financial information should senior management see?
47. What should the Accounting Health Dashboard contain?
48. What should be considered the organization's primary measure of accounting quality?
49. What level of audit history is legally or operationally required?
50. Which accounting processes must remain manual because of organizational policy?

---

# 129. Document Boundary

This BRD answers:

### “What does the business need from Accounting?”

and:

### “What business rules and conditions must Accounting follow?”

The next stages should define:

**Functional Requirements:**  
How users perform accounting activities.

**Detailed Business Rules:**  
Exact validations, approvals, calculations and exception conditions.

**Process Specifications:**  
Detailed accounting workflows.

**UX/UI Requirements:**  
How accounting activities are presented to users.

**Technical Design:**  
How the application implements these capabilities.

**Database Design:**  
How accounting information is represented and related.

---

# 130. Source and Benchmark Note

This BRD was prepared using the Tally.ERP 9 Help documentation as the primary external functional benchmark.

The Tally documentation describes accounting through masters, vouchers, banking, cost/profit centres, multi-currency, credit limits, budgets, interest calculations, financial reports, MIS reports and statutory/tax capabilities.

Relevant Tally.ERP 9 reference areas include:

- Accounting in Tally.ERP 9
- Accounting Features
- Groups
- Ledgers
- Voucher Types
- Voucher Classes
- Accounting Vouchers
- Banking
- Bank Reconciliation
- Receivables and Payables
- Financial Statements
- MIS Reports
- GST
- TDS
- TCS
- Audit and Verification

Primary reference:

Tally Solutions — Tally.ERP 9 Help Documentation  
https://help.tallysolutions.com/article/Tally.ERP9/

Accounting overview:
https://help.tallysolutions.com/article/Tally.ERP9/Creating_Masters/Accounts_Info/accounting_in_tally.htm/

Accounting Features:
https://help.tallysolutions.com/article/Tally.ERP9/Maintaining_Company_Data/Company_Info/F1_Accounting_Features.htm

Voucher Entry:
https://help.tallysolutions.com/article/Tally.ERP9/Voucher_Entry/Accounting_Vouchers/Voucher_Entry_in_Tally.htm

Reports:
https://help.tallysolutions.com/article/Tally.ERP9/Reports/Display_Reports.htm

GST:
https://help.tallysolutions.com/article/Tally.ERP9/Tax_India/gst/

Note: Tally.ERP 9 contains historical statutory functionality that may no longer be applicable to current transactions. Such functionality has been treated in this BRD as a benchmark/reference and not automatically as a mandatory Prime-AI requirement.

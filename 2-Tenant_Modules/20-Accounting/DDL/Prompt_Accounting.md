You are "Business Analyst GPT" - an Experienced Business Analyst specializing in SCHOOL ERP systems. You will Identify all the requirement needs to be incorporated in Student Fees Module.

1. High Level Detail of the Fuctionality, needs to be covered in the Module
   - Chart of Accounts
   - Journal Entry
   - Receipt
   - Payment
   - Sales Invoice
   - Purchase Invoice
   - Trail Balance
   - Ledger
   - Budgeting
   - GST & Tax Management
   - Opening Balance Entry
   - Approval Workflow
   - Recurring Entries
   - Automated Journal Entry Generation
   - Payment Gateway Integration
   - Expense Claim Management
   - Bank Reconciliation

2. Highlevel Requirement -

   - Define primary group (Assets/Liabilities/Income/Expense)
   - Assign accounting nature (Debit/Credit)
   - Create hierarchical sub-groups
   - Set posting permissions
   - Define ledger name & code
   - Assign parent account group
   - Link GST/TAX configuration
   - Enable reconciliation
   - Set allowed modules for ledger usage
   - Trial Balance
   - Profit & Loss
   - Balance Sheet
   - Revenue vs Expense analysis
   - Cashflow trend visualization
   - Export JE/Receipts in XML
   - Download Tally-compatible files
   - Synchronize ledgers
   - Sync transactions via API
   - Set overall institutional budget for the fiscal year
   - Allocate budgets to departments/cost centers (Academics, Sports, Admin)
   - Record commitments (POs) and actual expenditures against budget
   - Calculate available balance per cost center in real-time
   - Show budget vs. actual spend with variance percentages
   - Highlight departments exceeding budget thresholds
   - Define HSN/SAC codes for fee heads and services
   - Configure tax rates (CGST, SGST, IGST) based on location
   - Generate IRN (Invoice Reference Number) via government portal
   - Attach QR code to invoices for verification
   - Compile data for GSTR-1 (Outward supplies)
   - Compile data for GSTR-3B (Summary return)
   - Enter debit/credit opening balance
   - Validate fiscal year constraints
   - Upload outstanding fee CSV
   - Map vendor outstanding balances
   - Select debit/credit ledgers
   - Add narration & attachments
   - Submit JE for approval
   - Track approval history
   - Define recurrence cycle
   - Auto-post according to period
   - Generate fee JE automatically
   - Map fee heads to income ledgers
   - Accept multi-mode payments
   - Auto-send receipt to parent
   - Produce 30/60/90-day aging
   - Identify high-risk accounts
   - Send due reminders
   - Escalate chronic defaulters
   - Attach bill copy
   - Verify purchase order linkage
   - Select payment mode
   - Auto-generate payment voucher
   - Capture vendor GST/PAN
   - Store contract terms
   - Rate quality & delivery time
   - Update rating based on performance
   - Select vendor & items
   - Apply tax & discount rules
   - Upload claim receipts
   - Approve/Reject staff claims
   - Upload CSV/MT940
   - Auto-match transactions
   - Mark matched items
   - Identify mismatches
   - Record cash inflow/outflow
   - Track daily cash balance
   - Enter asset details
   - Assign asset category
   - Apply SLM/WDV methods
   - Generate depreciation JE

I want you to provide me a detailed requirement Document for **Accounting Module** to provide to AI for creating an deteailed DDL design and then further design documents.

### Your Mission:
I want you to generate a detailed Requirement Document by analyzing the Requirement I have provided above and searching for Accounting Module from other ERP Applications available online and then generate a detailed Requirement Document which should cover all required fuctionalties for **Accounting Module**.

The Final Document should be Grouped into Fuctionalities and should also cover Deatil of the Fuctionalities (like what is the use of that feature and how it will be used, who will perform that activity).


-------------------------------------------------------------------------------------------------------------------------------

You are "ERP Architect GPT" — an expert software architect, data modeler, API designer and UX/UI systemizer for school/education ERP systems. Your outputs must be precise, reproducible and developer-ready.

Technology Stack: PHP + Laravel + MySQL 8.x

Use Above Requirement Provided by You for Accounting Module and generate a detailed DDL schema and other design documents for the same.

You must remember below Important Points When creating DDL and other design document :
- We already have some related Modules like - Vendor Management, Student Fees Module, Transport Module, Library Module etc.
- We have to create a Export Functionality to Export accounting data which should be compaitible to be imported into Tally.

REQUIREMENT:
 - Parse the above Accounting Module Requirement provided above to Create DDL for the same.
 - Following are some key Accounting Functionalities that you need to consider while creating DDL for the Accounting Module:
   - Chart of Accounts
   - Journal Entry
   - Receipt
   - Payment
   - Sales Invoice
   - Purchase Invoice
   - Trail Balance
   - Ledger
   - Budgeting
   - GST & Tax Management
   - Opening Balance Entry
   - Approval Workflow
   - Recurring Entries
   - Automated Journal Entry Generation
   - Payment Gateway Integration
   - Expense Claim Management
   - Bank Reconciliation

Technology Stack
  - Backend: PHP 8.x + Laravel
  - Database: MySQL 8+
  - Architecture: Multi-tenant (Master DB + Tenant DB)
  - We are having separate Databases for every Tenant, so no requirement for org_id in every table.
  - Jobs: Laravel Queue / Scheduler
  - AI Layer: Rule-based analytics (PHP)

DELIVERABLES NEEDED:

DELIVERABLE-1 : Refactored Database DDL (MySQL 8 / Laravel-Friendly)
   Propose a **Refine, extended and industrialized Accounting Module architecture** including but not limited to:
    - Provide cleaned, refactored CREATE TABLE statements for **Accounting Module** tables with:
    - precise data types for MySQL 8.
    - primary keys, foreign keys, unique constraints, check constraints, indexes (including composite indexes), and nullable rules.
    - example seed rows for main lookup tables(sys_dropdown_table) (INSERT statements).
    - is active (`is_active`)
    - created_at, updated_at, deleted_at

OTHER DELIVERABLES :
   Deliverable 2 : Provide me the Complete Process Flow for "Student Fee Management Module".
   Deliverable 3 : Detailed Process Flow with the sequence how data will be captured.
   Deliverable 4 : Which detail will be fed by which process.
   Deliverable 5 : What all data will be fetched from existing database of other Modules.
   Deliverable 6 : What all data is required to be captured by manual data entry from user for "Student Fee Management Module".
   Deliverable 7 : What all Screen we need to develop to Capture or to showcase data to the user for "Student Fee Management Module".
   Deliverable 8 : Any other information which is useful for Developer for "Student Fee Management Module".
   Deliverable 9 : Provide me Screen Design in ascii format for all the screen suggested by you for "Student Fee Management Module".
   Deliverable 10 : Provide me the Complete API (ROUTES) Documentation for "Student Fee Management Module".
   Deliverable 11 : Provide me the Complete Data Dictionary for "Student Fee Management Module" including but limited to below detail -
                    - Purpose of all the tables,
                    - Use & Meaning of all the columns of every Table,
                    - Any other relevant information.
   Deliverable 12 : Provide me Dashboard Design in ascii format for "Student Fee Management Module".
   Deliverable 13 : Provide me All the Reports Design in ascii format for "Student Fee Management Module" with detail how to fetch data for those Reports.

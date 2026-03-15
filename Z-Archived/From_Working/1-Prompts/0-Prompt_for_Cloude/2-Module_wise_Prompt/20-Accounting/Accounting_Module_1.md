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

2. Highlevel RBS -

   - Define primary group (Assets/Liabilities/Income/Expense)
   - Assign accounting nature (Debit/Credit)
   - Create hierarchical sub-groups
   - Set posting permissions
   - Define ledger name & code
   - Assign parent account group
   - Link GST/TAX configuration
   - Enable reconciliation
   - Set allowed modules for ledger usage
   - Trial Balance & Profit & Loss
   - Revenue vs Expense analysis
   - Cashflow trend visualization
   - Download Tally-compatible files
   - Synchronize ledgers
   - Set overall institutional budget for the fiscal year
   - Allocate budgets to departments/cost centers (Academics, Sports, Admin)
   - Record commitments (POs) and actual expenditures against budget
   - Calculate available balance per cost center in real-time
   - Show budget vs. actual spend with variance percentages
   - Highlight departments exceeding budget thresholds
   - Provision for HSN/SAC codes for fee heads and services
   - Configure tax rates (CGST, SGST, IGST) based on location
   - Enter debit/credit opening balance
   - Validate fiscal year constraints
   - Export outstanding fee CSV/Excel file
   - Map vendor outstanding balances
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
   - Select vendor & items from Vendor Module (already Developed)
   - Upload claim receipts (Expense Reimbursement)
   - Approve/Reject staff claims (Expense Reimbursement)
   - Identify Transaction mismatches
   - Record cash inflow/outflow
   - Track daily cash balance

### Your Mission:
 - First I want you to understand above high level requirement of "Accounting Module" then search for Accounting Module developed by other ERP Applications available in Indian Market and find out additional required fuctionalities.
 - Create an Enhanced Requirement Document for "Accounting Module" and ,save it as "Account_Requirement.md" into "Working/0-Claude_workspace/Working/Accounting_Module". Provide me for Review.
 - After getting conformation from me on the Requirement, create a detailed plan for complete development lifeCycle of the "Accounting Module". Save it as "Plan_Account_Module.md" into "Working/0-Claude_workspace/Working/Accounting_Module". Show me the complete development for Review.
 - After getting conformation from me to Create DDL Schema of "Accounting Module" and  Save it as "Account_DDL.sql" into "Working/0-Claude_workspace/Working/Accounting_Module". Show me the complete development for Review.
 - Get Confirmation from me to work on further steps in Plan.



The Final Document should be Grouped into Fuctionalities and should also cover Deatil of the Fuctionalities (like what is the use of that feature and how it will be used, who will perform that activity).





Removed Items from REquirement :
   - Compile data for GSTR-1 (Outward supplies)
   - Compile data for GSTR-3B (Summary return)
   - Select debit/credit ledgers
   - Capture vendor GST/PAN
   - Store contract terms
   - Rate quality & delivery time
   - Update rating based on performance
   - Apply tax & discount rules
   - Upload CSV/MT940
   - Auto-match transactions
   - Mark matched items
   - Identify mismatches
   - Enter asset details
   - Assign asset category
   - Apply SLM/WDV methods
   - Generate depreciation JE


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

2. Highlevel RBS -

   - Define primary group (Assets/Liabilities/Income/Expense)
   - Assign accounting nature (Debit/Credit)
   - Create hierarchical sub-groups
   - Set posting permissions
   - Define ledger name & code
   - Assign parent account group
   - Link GST/TAX configuration
   - Enable reconciliation
   - Set allowed modules for ledger usage
   - Trial Balance & Profit & Loss
   - Revenue vs Expense analysis
   - Cashflow trend visualization
   - Download Tally-compatible files
   - Synchronize ledgers
   - Set overall institutional budget for the fiscal year
   - Allocate budgets to departments/cost centers (Academics, Sports, Admin)
   - Record commitments (POs) and actual expenditures against budget
   - Calculate available balance per cost center in real-time
   - Show budget vs. actual spend with variance percentages
   - Highlight departments exceeding budget thresholds
   - Provision for HSN/SAC codes for fee heads and services
   - Configure tax rates (CGST, SGST, IGST) based on location
   - Enter debit/credit opening balance
   - Validate fiscal year constraints
   - Export outstanding fee CSV/Excel file
   - Map vendor outstanding balances
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
   - Select vendor & items from Vendor Module (already Developed)
   - Upload claim receipts (Expense Reimbursement)
   - Approve/Reject staff claims (Expense Reimbursement)
   - Identify Transaction mismatches
   - Record cash inflow/outflow
   - Track daily cash balance

Technology Stack
  - Backend: PHP 8.x + Laravel
  - Database: MySQL 8+
  - Architecture: Multi-tenant (Master DB + Tenant DB)
  - We are having separate Databases for every Tenant, so no requirement for org_id in every table.
  - Jobs: Laravel Queue / Scheduler
  - AI Layer: Rule-based analytics (PHP)

DELIVERABLES NEEDED:

I want you to provide me a detailed requirement Document for **Accounting Module** to provide to AI for creating an deteailed DDL design and then further design documents.

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


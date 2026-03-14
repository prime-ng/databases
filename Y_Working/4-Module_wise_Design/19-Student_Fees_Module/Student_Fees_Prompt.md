# Prompt for Student Fees Module

You are "ERP Architect GPT" — an expert software architect, data modeler, API designer and UX/UI systemizer for school/education ERP systems. Your outputs must be precise, reproducible and developer-ready.

SYSTEM: You are a senior software architect and product designer for enterprise ERP systems. Produce clean, developer-ready design docs, DDLs, REST API contracts, screen mockups (ASCII), workflows, testing checklists and future-enhancement items.

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


You are "Business Analyst GPT" - an Experienced Business Analyst specializing in SCHOOL ERP systems. You will Identify all the requirement needs to be incorporated in LMS Module.

Your outputs must be precise, grouped in modules and Sub-Modules and formatted cleanly in Markdown with example and ready to provide to a AI to create an deteailed DDL design and then further design documents.

USER: I will provide:
  1) a short functional requirement summary (plain text), and
  2) an existing database DDL file (SQL) named "<filename>.sql".



-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

You are "Business Analyst GPT" - an Experienced Business Analyst specializing in SCHOOL ERP systems. You will Identify all the requirement needs to be incorporated in Student Fees Module.

## High Level Detail of the Fuctionality
   
### 1) Highlevel Requirement -
   - Define fee head name (Tuition, Transport, Hostel)
   - Provision for Tax Applicability
   - Create fee group (Academic, Transport)
   - Assign fee heads to group
   - Define class-wise fee amount
   - Map optional/mandatory heads
   - Define installment dates
   - Set fine rules
   - Define rules based on student attributes (Class, Category, Board)
   - Set conditional logic (e.g., sibling discount if 2+ students)
   - Preview fee breakdown before applying to batch
   - Auto-assign class-wise fees
   - Apply concession/scholarship
   - Validate student-class mapping
   - Select optional fee heads
   - Apply prorated amount
   - Select payment mode (Cash/UPI/Bank)
   - Enter amount & receipt details
   - Generate receipt number
   - Send SMS/email confirmation
   - Integrate with Razorpay/Paytm
   - Auto-reconcile online payments
   - Define concession type (Sibling, Merit)
   - Set percentage/amount
   - Send approval request
   - Record approval history
   - Fetch Transport Fees from Transport Module
   - Assign room type
   - Apply mess charges
   - Partial month calculation
   - Room change adjustment
   - Define late fee per day
   - Set grace period
   - Record waiver reason
   - Generate approval log
   - Compute fee pending per student
   - Identify overdue installments
   - Send due reminders
   - Escalate to admin after multiple misses
   - Fee collection summary
   - Outstanding report
   - Predict fee default risk
   - Identify patterns in late payments
   - Define fund name, sponsor, and total amount
   - Set eligibility criteria (Academic, Financial Need, Category)
   - Create online scholarship application form
   - Define review committee and approval stages
   - Approve applications and allocate amounts
   - Auto-apply scholarship to student fee account
   - Track renewal criteria (e.g., maintain certain grades)
   - Send renewal reminders and process continuations

### 2) Student Fee Management Module Fuctionalities
      
      - Fee Setup (Masters)
      - Fine Setup (Masters)
      - Student Fees Details
      - Student Fees Payment
      - Student Fees Receipt
      - Student Fine master and Detail on delay on Fees Payment
      - Fine May have multipal Categories like -
         - from 1 to 10th day - Fine is 10% or Rs.25/- per day
         - From 11th day to 30th day - Fine is 20% or Rs.50/- per day
         - From 31st day to 60th day - Fine is 30% or Rs.100/- per day
         - on 61st day Name will be removed from the class
         - After Name Removal he need to do Re-Admission Fomalities with Fine
         - After Re-Admission he need to pay the fine
         - Then only His Name will be Re-activated in the class
   - Fee Report
   - Fee Analytics
   - Fee Invoice

I want you to provide me a detailed requirement Document for **Student Fee Management** Module to provide to AI for creating an deteailed DDL design and then further design documents.

### Your Mission:
I want you to generate a detailed Requirement Document by searching the Requirement Detail of LMS Module from other LMS Applications and then generate a detailed Requirement Document which should cover all required fuctionalties for **Student Fee Management** Module.

The Final Document should be Grouped into Fuctionalities and should also cover Deatil of the Fuctionalities (like what is the use of that feature and how it will be used, who will perform that activity).

### DELIVERABLE:
The Requirement should meet below principles:
1) Requirement should be Grouped logically into Functionalities by thinking deeply on grouping the fuctionalities.
2) Requirement should be formatted cleanly in Markdown with examples and code blocks for SQL/JSON/cURL.
3) Requirement should be precise, technically correct, AI input ready, and formatted cleanly in Markdown with code blocks for SQL/JSON/cURL.
4) Provide detail what is the use of that feature and how it will be used, who will perform that activity.

------------------------------------------------------------------------------------------------------------------------------------------------------------------

You are "ERP Architect GPT" — an expert software architect, data modeler, API designer and UX/UI systemizer for school/education ERP systems. Your outputs must be precise, reproducible and developer-ready.

Use Above Requirement Provided by You for Student Fees Module and generate a detailed DDL schema and other design documents for the same.

Technology Stack
  - Backend: PHP 8.x + Laravel
  - Database: MySQL 8+
  - Architecture: Multi-tenant (Master DB + Tenant DB)
  - We are having separate Databases for every Tenant, so no requirement for org_id in every table.
  - Jobs: Laravel Queue / Scheduler
  - AI Layer: Rule-based analytics (PHP)

DELIVERABLES NEEDED:

DELIVERABLE-1 : Refactored Database DDL (MySQL 8 / Laravel-Friendly)
   Propose a **Refine, extended and industrialized Student Fee Management Module architecture** including but not limited to:
    - Provide cleaned, refactored CREATE TABLE statements for **Student Fee Management Modules** tables with:
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


Addional Requirement (Not Very Important)
   Deliverable A : Provide me the Complete ER Diagram for "Student Fee Management Module".
   Deliverable B : Provide me the Complete Sequence Diagram for "Student Fee Management Module".
   Deliverable C : Provide me the Complete State Diagram for "Student Fee Management Module".
   Deliverable D : Provide me the Complete Activity Diagram for "Student Fee Management Module".

   
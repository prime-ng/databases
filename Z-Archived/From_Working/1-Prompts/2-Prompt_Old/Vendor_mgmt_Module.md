Vendor Management Promt
-----------------------

I need you to act as a Principal Systems Architect to refine and expand my School ERP Vendor Management module. I am using PHP (Laravel) + MySQL. 

SYSTEM: You are "ERP Architect GPT" — an expert software architect, data modeler, API designer and UX/UI systemizer for school/education ERP systems. Your outputs must be precise, reproducible and developer-ready.

Existing Database Structure & key reusable components/tables:
  - sys_media_table ('sys_media' in 'database/master_dbs/tenant_db.sql'). This is used to store media files.
  - sys_dropdown_table ('sys_dropdown_table' in 'database/master_dbs/tenant_db.sql'). This is a common table to store dropdown values.
  - tenant database ('database/master_dbs/tenant_db.sql'). This is main tenant specific database.
  - global database ('database/master_dbs/global_db.sql'). This is a database to store global tables, which will be used by all tenants.
  - prime database ('database/master_dbs/prime_db.sql'). This is a service provide database, which will control all the services provided to tenants e.g. Billing, Subscription, etc.
  - Consolidated DDL file named "Modules_Design/Z_Templates/z_consolidated_ddl.sql", is only for reference. It is not the final database structure BUT A CONSOLIDATION OF ALL EXISTING DATABASES.
  - Multi Tenancy is being used in the system and will be handled by having separate database for each tenant. So no need to add tenant_id in the database.

INPUT FILES: 
  A) Consolidated database DDL file named "Modules_Design/Z_Templates/z_consolidated_ddl.sql".
  B) Initial version of database DDL for Vendor Management Module named "Modules_Design/Vendor_Mgmt/DDLs/vendor_mgmt_v1.0.sql".
  C) Sample Version of Screen Design files named "Modules_Design/Z_Templates/Z-Screen-Sample.md"

Your mission:
 - Parse all 3 files A–C.  
 - Understand the functional requirements, existing schema, existing schema, and the sample screen design style.  
 - Produce a **fully integrated, production-quality Vendor Management Module Design** that:
   - Fits into the existing ERP architecture  
   - Follows advanced logic  
   - Includes complete backend design, frontend design, UX flows, permissions, APIs, and DDL  
   - Uses EXACT SAME screen-design pattern as **Z-Screen-Sample.md**  
   - I have consolidated all the DDLs into Consolidated DDL file, so you need not to read Prime_db, Global_db & Tenant_db.

REQUIREMENT OF VENDOR MANAGEMENT MODULE:
  - School will take different type of Services from Vendor. below are some key services School will take from Vendor -
    - Buses on Leave for Transport
    - Taking Food from Vendor and Managing Canteen for School OR Giving Canteen contract to the Vendor
    - Security Personnel for School
    - Drivers for School on Contract
    - Stalls for Events
    - Doctor on Call
    - Car on Rent
    - etc.
  - School will pay for the services on monthly basis OR in some cases Uses basis (like Bus can be Billed per Km wise or Hybrid mode Like some charges are Fixed for the Bus and Additionally it will be charged Per km basis).
  - Doctor will be paid on per visit basis.
  - Car on Rent will be paid on per day basis OR 
  - School will also purchase different type of Products from Vendor e.g. For Student Dress, Stationery, Student Books Mainitenance Items, Sports Items etc.
  - Analytics Hook: Ensure we will have analytics hook for all the services and products.
  - Complaints also will be allign with Vendor.
  - This Module should be flexible enough to add any type of Service or Product.

  These are some key requirements but that's not all. You can add any other requirement which I may missed.

DELIVERABLES NEEDED:

DELIVERABLE A — Refactored Database DDL
  • Provide cleaned, refactored CREATE TABLE statements for Vendor Management module tables with:
      - precise data types for MySQL 8.
      - primary keys, foreign keys, unique constraints, check constraints, indexes (including composite indexes), and nullable rules.
      - example seed rows for main lookup tables(sys_dropdown_table) (INSERT statements).
      - Soft delete (`is_deleted`)
      - is active (`is_active`)
      - created_at, updated_at, deleted_at

DELIVERABLE B — Data Dictionary(vendor_mgmt_ddl_dictionary.md): 
  - A complete breakdown of every table and column purpose.
  - Each table must include an explanation block:
    - Purpose  
    - Key fields  
    - Relationship context  

DELIVERABLE C — Design Document (Full 10-Section Design Document):
  1. Overview — scope, responsibilities, owners, cross-module interactions.
  2. Data Context — entity list, cardinality matrix, sensitive fields (PII), retention rules.
  3. Screen Layouts — list of screens with purpose and priority (CRUD, list, detail, report).
  4. Data Models — ER diagram in ASCII + table-to-field mapping and rationales.
  5. User Workflows — step-by-step happy path + alternatives + error handling for each key workflow.
  6. Visual Design — component list (header, table, forms, filters) and spacing/layout guidelines; include accessibility notes.
  7. Accessibility — WCAG AA checklist items for each screen; keyboard flows and ARIA roles.
  8. Testing — unit, integration, E2E, contract tests, security tests; provide sample test-cases and test-data.
  9. Deployment/Runbook — configuration, environment variables, startup sequence, backup and restore steps.
 10. Future Enhancements — short actionable ideas, with complexity tags (low/med/high).

You MUST strictly learn and replicate the screen-design style found in the sample file **Z-Screen-Sample.md**
Your outputs must be precise, developer-ready, and formatted cleanly in Markdown.
Match:
- format (ASCII Screen Designs)
- structure
- sections
- diagrams
- naming conventions
- tone & explanation depth


DELIVERABLE D - Vendor Dashboard Design:
  - Vendor Mgmt Dashboard: An ASCII wireframe showing analytics of the Vendor.

DELIVERABLE E - Report Design: 
  Detail the logic for a 'Vendor Analysis & Reports' (identifying the analytical need of the vendor).
  For EACH report provide:
  - Report Name
  - Report Category
  - Primary Tables Used
  - Key Filters (date, route, vehicle, session, class, stop, etc.)
  - Output Columns
  - Frequency (Daily / Monthly / On-Demand)
  - Intended User Role (Transport Head, Driver, Helper, Admin, Accountant, Principal, Teacher, Student, Parents)
  - What all permissions those roles have from list of permissions (View, Add, Edit, Delete, Print, Export, Import)

DELIVERABLE F — Testing & QA
  • Provide a test-run checklist for developers for each screen
  • Provide a test-run checklist for QA for each screen
  • Provide minimum 5-10 representative test-cases (table-driven) with inputs and expected outputs, including edge cases.

Thinking Instructions:

Please output the schema first, followed by the UI designs and other deliverables.
First only provide the schema design. Once I will confirm the schema design that no enhancement is required then only proceed further fter getting confirmation from me.

Save all the files in the folder named "/Users/bkwork/Documents/0-Git_Work/prime-ai_db/databases/Modules_Design/Vendor_Mgmt/"


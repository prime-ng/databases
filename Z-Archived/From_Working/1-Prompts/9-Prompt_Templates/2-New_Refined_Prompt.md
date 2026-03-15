I need you to act as a Principal Systems Architect to refine and expand my School ERP **Complaint Management Module**. I am using PHP (Laravel) + MySQL. 

**SYSTEM**: You are "ERP Architect GPT" — an expert software architect, data modeler, API designer and UX/UI systemizer for school/education ERP systems. Your outputs must be precise, reproducible and developer-ready.

**EXISTING DATABASE STRUCTURE & KEY REUSABLE COMPONENTS/TABLES**:
  - Common System Media Table (**'sys_media' in 'database/master_dbs/tenant_db.sql'**). This is used to store media files.
  - Common System Dropdown Table (**'sys_dropdown_table' in 'database/master_dbs/tenant_db.sql'**). This is used to store dropdown values.
  - Tenant Database (**'database/master_dbs/tenant_db.sql'**). This is main tenant specific database.
  - Global Database (**'database/master_dbs/global_db.sql'**). This is a database to store global tables, which will be used by all tenants.
  - Prime Database (**'database/master_dbs/prime_db.sql'**) is a service provider database to control all the services provided to tenants e.g. Billing, Subscription, etc.
  - Consolidated DDL file named **"Modules_Design/Z_Templates/z_consolidated_ddl.sql"**, is only for reference. It is not the final database structure BUT A CONSOLIDATION OF ALL EXISTING DATABASES.
  - Multi Tenancy is being used in the system and will be handled by having separate database for each tenant. So no need to add tenant_id in the database.

**INPUT FILES**: 
  A) Consolidated database DDL file named - **"Modules_Design/Z_Templates/z_consolidated_ddl.sql"**.
  B) Initial version of DB Schema for **Complaint Management Module** named - **"Modules_Design/Complaint_Module/DDLs/complaint_mgmt_v1.0.sql"**.

**SAMPLE FILES**
  A) Sample Version For (DELIVERABLE B — Data Dictionary) files named **"Modules_Design/Z_Templates/Data_Dictionary_Sample.md"**
  B) Sample Version for (DELIVERABLE C - Design Document) files named **"Modules_Design/Z_Templates/Design_doc_Sample.md"** 
  C) Sample Version for (DELIVERABLE D - Screen Design) files named **"Modules_Design/Z_Templates/Screen-Sample.md"**
  D) Sample Version for (DELIVERABLE E - Dashboard) files named **"Modules_Design/Z_Templates/Dashboard_Sample.md"**
  E) Sample Version for (DELIVERABLE F - Testing & QA) files named **"Modules_Design/Z_Templates/Testing_QA_Sample.md"**
  F) Sample Version for (DELIVERABLE G - Report Design) files named **"Modules_Design/Z_Templates/Report_Sample.md"**


**YOUR MISSION**:
 - You need to create a **Complaint Management Module** for School ERP.
 - Parse **both** the files provided in INPUT Files for understanding the existing schema.  
 - Parse **all 6 files A–F** provided in SAMPLE for understanding expected output.  
 - Understand the functional requirements, existing schema, **initial version of schema** and the sample screen design style.  
 - Produce a **fully integrated, production-quality Complaint Management Module Design** that:
   - Fits into the existing ERP architecture  
   - Follows advanced logic  
   - Includes complete backend design, frontend design, UX flows, permissions, APIs, and DDL  
   - Uses EXACT SAME screen-design pattern as Provided in Section - **SAMPLE FILES**
   - I have consolidated all the DDLs into Consolidated DDL file, so you **need not to read Prime_db, Global_db & Tenant_db**.

**REQUIREMENT OF THE MODULE**:
  - This Module will capture all type of Complaints and Grievances related to all departments and entities.
    - Complaints related to Transport
    - Complaints related to Food
    - Complaints related to Security
    - Complaints related to Drivers
    - Complaints related to Stalls
    - Complaints related to Doctor
    - Complaints related to Car
    - Complaints related to Products
    - Complaints related to Services
    - Complaints related to Events
    - Complaints related to Infrastructure
    - Complaints related to Vendor
    - Complaints related to Student
    - Complaints related to Teacher
    - Complaints related to Staff
    - Complaints related to Drivers
    - Complaints related to Stalls
    - Complaints related to Doctor
    - Complaints related to Car
    - etc.
  
  - Students & Parents can raise Complaints on their own Portal.
  - Complaint Module will have 5 Level of Excalation Matrix.
  - Excalation Matrix will be as follows:
    - Level 1: Manager
    - Level 2: Department Head
    - Level 3: Excalation Manager
    - Level 4: Principal
    - Level 5: Management / Director
  - Complaints will be assigned to the appropriate level based on the severity of the complaint.
  - Complaints Module will have Complaint Categories & Sub-Categories.
  - Every Complaint category & Sub-category is having different Priority Level & Severity Level.
  - Every Complaint category & Sub-category will have Default & Department specific 'expected_resolution_hours'.
  - Priority Level & Severity Level Can be different for different Departments.
  - Number of Compaints / High Severity Complaints / Un-Resolved Complaints will impect the performance Matrix of the department.
  - Complaints will be assigned to the appropriate level based on the priority of the complaint.
  - Module will also capture Roles & User ID for Every Level of Excalation Matrix for Every Department.
  - Complaint Can be Assigned & Re-Assigned as many time as required.
  - Module will capture Log of complete life cycle of the complaint.
  - Any Serious which need any Medical Checkup or Inspection will be captured in the module.
  - Module will provide a detailed data Insights for Complaints.
  - System will identify if Student / Teacher Attrition is due to Complaints.
  - Complaint Status will be as follows:
    - Open
    - In Progress
    - Closed
    - Rejected
    - Reopened
    - Resolved
    - Cancelled

  These are some key requirements but that's not all. You can add any other requirement which I may missed.

**CURRENT STATUS:**
  - Currently this Module is in preliminary stage and it can be considered for Database Schema Refinement if Required.
  - So provide the Database Schema Refinement if Required.

**DELIVERABLES NEEDED**:

**DELIVERABLE A — Refactored Database DDL:**
  • Provide cleaned, refactored CREATE TABLE statements for **Complaint Management Module** tables with:
      - precise data types for MySQL 8.
      - primary keys, foreign keys, unique constraints, check constraints, indexes (including composite indexes), and nullable rules.
      - example seed rows for main lookup tables(sys_dropdown_table) (INSERT statements).
      - Soft delete (`is_deleted`)
      - is active (`is_active`)
      - created_at, updated_at, deleted_at

**DELIVERABLE B — Data Dictionary:** 
  - A complete breakdown of every table and column purpose.
  - Each table must include an explanation block:
    - Purpose  
    - Key fields  
    - Relationship context  

**DELIVERABLE C — Design Document (Full 10-Section Design Document):**
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

    You MUST strictly learn and replicate the design document style found in the sample file **Design_doc_Sample.md**.
    Your outputs must be precise, developer-ready, and formatted cleanly in Markdown.
    Match:
    - format (ASCII Screen Designs)
    - structure

**DELIVERABLE D - Screen Design**
  - Provide Separate Screen Design Files for each screen with All the sections provided in the sample file **Screen-Sample.md**.
  - Provide clean, developer-ready ASCII screen designs for all the screens required for the module.
  - Cover each and every Table provided in the DDL file.
  - **MUST MATCH** the screen-design style found in the sample file **Screen-Sample.md**.
  - Your outputs must be precise, developer-ready, and formatted cleanly in Markdown.
  - Match:
    - format (ASCII Screen Designs)
    - structure

**DELIVERABLE E - Dashboard**
  - Provide clean, developer-ready ASCII dashboard designs for all the dashboards required for the module.
  - Cover all possible Analytical charts for all critical parameters for the module.
  - Provide all Actionable items in the Dashboard , which can help to take quick action.
  - Provide all possible filters in the Dashboard , which can help to filter the data as per the requirement.
  - Provide all possible drilldowns in the Dashboard , which can help to drilldown the data as per the requirement.
  - Keep it Crisp and Clean.
  - Match the style of the dashboard found in the sample file **Dashboard_Sample.md**.
  - Your outputs must be precise, developer-ready, and formatted cleanly in Markdown.
  - Match:
    - format (ASCII Dashboard Designs)
    - structure

**DELIVERABLE F - Testing & QA**
  - Provide clean, developer-ready ASCII test-cases and test-data for all the screens required for the module.
  - Provide a test-run checklist for developers for each screen
  - Provide a test-run checklist for QA for each screen
  - Provide minimum 10-20 representative test-cases (table-driven) with inputs and expected outputs, including edge cases.  
  - Cover Maximum Test cases as much as you can for each screen.
  - Match the style of the test-cases found in the sample file **Test_Cases_Sample.md**.

**DELIVERABLE G - Report Design**
  - Provide clean, developer-ready ASCII report designs for all the reports required for the module.
  - Cover all possible Analytical charts for all critical parameters for the module.
  - Provide all Actionable items in the Report , which can help to take quick action.
  - Provide all possible filters in the Report , which can help to filter the data as per the requirement.
  - Provide all possible drilldowns in the Report , which can help to drilldown the data as per the requirement.
  - Keep it Crisp and Clean.
  - Match the style of the report found in the sample file **Report_Sample.md**.
  - Your outputs must be precise, developer-ready, and formatted cleanly in Markdown.
  - Match:
    - format (ASCII Report Designs)
    - structure

**DELIVERABLE H - Deployment & Runbook**
  - Provide clean, developer-ready ASCII deployment and runbook for all the screens required for the module.
  - Provide a deployment checklist for developers for each screen
  - Provide a deployment checklist for QA for each screen
  - Provide a deployment checklist for production for each screen
  - Provide a deployment checklist for rollback for each screen
  - Provide a deployment checklist for backup and restore for each screen
  - Provide a deployment checklist for disaster recovery for each screen
  - Provide a deployment checklist for monitoring for each screen
  - Provide a deployment checklist for alerting for each screen
  - Provide a deployment checklist for logging for each screen
  - Provide a deployment checklist for security for each screen
  - Provide a deployment checklist for performance for each screen
  - Provide a deployment checklist for scalability for each screen
  - Provide a deployment checklist for availability for each screen
  - Provide a deployment checklist for maintainability for each screen
  - Provide a deployment checklist for accessibility for each screen
  - Provide a deployment checklist for internationalization for each screen
  - Provide a deployment checklist for localization for each screen

**Thinking Instructions:**

  - Please output the schema first, followed by the UI designs and other deliverables.
  - First only provide the schema design. Once I will confirm the schema design that no enhancement is required then only proceed further fter getting confirmation from me.

Save all the files in the folder named **"Modules_Design/Complaint_Module/v2/"**
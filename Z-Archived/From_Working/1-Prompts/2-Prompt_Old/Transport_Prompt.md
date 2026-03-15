
I need you to act as a Principal Systems Architect to refine and expand my School ERP **Transport Module**. I am using PHP (Laravel) + MySQL. 

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
  B) Initial version of DB Schema for **Transport Module** named - **"Modules_Design/Transport_Module/DDLs/tpt_transport_v2.1.sql"**.

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


------------------------------
**YOUR MISSION**:
 - You need to create Reports for **Transport Module** for School ERP.
 - Parse **both** the files provided in INPUT Files for understanding the existing schema.  
 - Understand the functional requirements, existing schema of Transport Module. 
 - Produce a **fully integrated, production-quality Transport Module Reports Design** that:
   - Fits into the existing ERP architecture  
   - Follows advanced logic  


**DELIVERABLE E - Dashboard**
  - Provide clean, developer-ready ASCII dashboard designs for all the dashboards required for the module.
  - Cover all possible Analytical charts for all critical parameters for the module.
  - Provide all Actionable items in the Dashboard , which can help to take quick action.
  - Provide all possible filters in the Dashboard , which can help to filter the data as per the requirement.
  - Provide all possible drilldowns in the Dashboard , which can help to drilldown the data as per the requirement.
  - Keep it Crisp and Clean.
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

**DELIVERABLE G - Report Design**
  - Provide clean, developer-ready ASCII report designs for all the reports required for the module.
  - Cover all possible Analytical charts for all critical parameters for the module.
  - Provide all Actionable items in the Report , which can help to take quick action.
  - Provide all possible filters in the Report , which can help to filter the data as per the requirement.
  - Provide all possible drilldowns in the Report , which can help to drilldown the data as per the requirement.
  - Keep it Crisp and Clean.
  - Your outputs must be precise, developer-ready, and formatted cleanly in Markdown.
  - Match:
    - format (ASCII Report Designs)
    - structure

Create all the deliverables in .md format. 

===========================================================================================================================

I need you to act as a Principal Systems Architect to refine and expand my School ERP **Transport Module**. I am using PHP (Laravel) + MySQL. 

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
  B) Current version of DB Schema for **Transport Module** named - **"Modules_Design/Transport_Module/DDLs/tpt_transport_v2.1.sql"**.

**SAMPLE FILES**
  A) Sample Version For (DELIVERABLE B — Data Dictionary) files named **"Modules_Design/Z_Templates/Data_Dictionary_Sample.md"**
  B) Sample Version for (DELIVERABLE C - Design Document) files named **"Modules_Design/Z_Templates/Design_doc_Sample.md"** 
  C) Sample Version for (DELIVERABLE D - Screen Design) files named **"Modules_Design/Z_Templates/Screen-Sample.md"**
  D) Sample Version for (DELIVERABLE E - Dashboard) files named **"Modules_Design/Z_Templates/Dashboard_Sample.md"**
  E) Sample Version for (DELIVERABLE F - Testing & QA) files named **"Modules_Design/Z_Templates/Testing_QA_Sample.md"**
  F) Sample Version for (DELIVERABLE G - Report Design) files named **"Modules_Design/Z_Templates/Report_Sample.md"**



**YOUR MISSION**:
 - You need to add schema for Reports for **Transport Module** for School ERP.
 - Parse **both** the files provided in INPUT Files for understanding the existing schema.  
 - Understand the functional requirements, existing schema of Transport Module. 
 - Produce a **fully integrated, production-quality Transport Module Reports Design** that:
   - Fits into the existing ERP architecture  
   - Follows advanced logic  
   - Includes complete backend design, frontend design, UX flows, permissions, APIs, and DDL  
   - Uses EXACT SAME screen-design pattern as Provided in Section - **SAMPLE FILES**
   - I have consolidated all the DDLs into Consolidated DDL file, so you **need not to read Prime_db, Global_db & Tenant_db**.


===========================================================================================================================

I need you to act as a Principal Systems Architect to refine and expand my School ERP **Transport Module**. I am using PHP (Laravel) + MySQL. 

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
  B) Current version of DB Schema for **Transport Module** named - **"Modules_Design/Transport_Module/DDLs/tpt_transport_v2.2.sql"**.
  C) Current version of DB Schema for **Tenant Database** named - **"Modules_Design/Transport_Module/DDLs/tenant_db.sql"**.
  D) Current version of Report Design for **Transport Module** named - **"Modules_Design/Transport_Module/Report_Design/tpt_Reports_Design_v4.md"**.

I have made some updates in the Transport Module DDL "tpt_transport_v2.2.sql" and also made some changes in "tenant_db". Analyze all the attached DDL file deeply and update Reports Design.

**SAMPLE FILES**
  A) Sample Version For (DELIVERABLE B — Data Dictionary) files named **"Modules_Design/Z_Templates/Data_Dictionary_Sample.md"**
  B) Sample Version for (DELIVERABLE C - Design Document) files named **"Modules_Design/Z_Templates/Design_doc_Sample.md"** 
  C) Sample Version for (DELIVERABLE D - Screen Design) files named **"Modules_Design/Z_Templates/Screen-Sample.md"**
  D) Sample Version for (DELIVERABLE E - Dashboard) files named **"Modules_Design/Z_Templates/Dashboard_Sample.md"**
  E) Sample Version for (DELIVERABLE F - Testing & QA) files named **"Modules_Design/Z_Templates/Testing_QA_Sample.md"**
  F) Sample Version for (DELIVERABLE G - Report Design) files named **"Modules_Design/Z_Templates/Report_Sample.md"**

**YOUR MISSION**:
 - Parse **all** the files provided in INPUT Files for understanding the existing schema.  
 - Parse **all** the files provided in SAMPLE for understanding expected output.  
 - Understand the functional requirements, existing schema, **current version of schema** and the sample screen design style.  
 - Produce a **fully integrated, production-quality Transport Management Module Design** that:
   - Fits into the existing ERP architecture  
   - Follows advanced logic  
   - Includes complete backend design, frontend design, UX flows, permissions, APIs, and DDL  
   - Uses EXACT SAME screen-design pattern as Provided in Section - **SAMPLE FILES**

**DELIVERABLES**:
  A) Data Dictionary for Transport Module named - **"Modules_Design/Transport_Module/v2/Data_Dictionary.md"**.
  B) Design Document for Transport Module named - **"Modules_Design/Transport_Module/v2/Design_Document.md"**.
  C) Screen Design Only or New Tables for Transport Module named - **"Modules_Design/Transport_Module/v2/Screen_Design.md"**. Here are the Name of New/Enhanced tables -
     i. tpt_student_boarding_log (New)
     ii. tpt_notification_log (New)
     iii. tpt_attendance_device (Enhanced)
  D) UX Flows for Transport Module named - **"Modules_Design/Transport_Module/v2/UX_Flows.md"**.  
  E) Dashboard Design for Transport Module named - **"Modules_Design/Transport_Module/v2/Dashboard_Design.md"**.
  F) Testing & QA Design for Transport Module named - **"Modules_Design/Transport_Module/v2/Testing_QA_Design.md"**.
  G) Report Design for Transport Module named - **"Modules_Design/Transport_Module/v2/Report_Design.md"**.

  **NOTE**: 
  - In Existing Report Design, Few SQL Queries are not having correct table names. Though the table names are correct in the DDL file. Verify all the table names in the SQL queries and update them as per the DDL file.

Upload all the files in the Modules_Design/Transport_Module/v2 folder.

END OF DOCUMENT


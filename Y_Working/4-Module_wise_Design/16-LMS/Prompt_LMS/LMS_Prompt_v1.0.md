==============================================================================================================================
# Prompt - 1 Creating DDL for LMS Module (LMS_Quiz) Module
==============================================================================================================================

SYSTEM:
You are "ERP Architect GPT" — a senior software architect, data modeler, API designer, and UX/UI systemizer specializing in SCHOOL ERP systems. You will design a production-grade, fully detailed **LMS Online Exam Module** using the inputs I provide.

Your outputs must be precise, technically correct, developer-ready, and formatted cleanly in Markdown with code blocks for SQL/JSON/cURL.

### Product Vision
An AI-enabled, modular, multi-tenant School ERP + LMS + LXP platform designed for:
  - CBSE / ICSE / State Boards
  - Medium to large schools
  - Data-driven academic & administrative decision-making

### Technology Stack
  - Backend: PHP 8.x + Laravel
  - Database: MySQL 8+
  - Architecture: Multi-tenant (Master DB + Tenant DB)
  - We are having separate Databases for every Tenant, so no requirement for org_id in every table.
  - Jobs: Laravel Queue / Scheduler
  - AI Layer: Rule-based analytics (PHP)
    - ML-ready schemas
    - External AI APIs where needed

### Core Architectural Principles
  - Modular design (loosely coupled modules)
  - Centralized common services (Notifications, Files, AI Insights)
  - Role-based access (fine-grained permissions)
  - Audit-ready data model
  - Report-first & analytics-friendly schema

### Database Strategy
    - Naming conventions enforced
    - Master tables configurable by school
    - Historical tables (no hard deletes)
    - AI Insight tables separated from transactional tables

### REQUIREMENTS:
  - **1 - ONLINE EXAM**

  Online Exam Flow:
  - Here is the Proces Flow how Online Exam will proceed -
    - Teacher will Create Exam (with all the conditions) (e.g. 7th_Half_Yearly_Exam, 7th_Final_Exam)
    - Every Exam will have a fix Scope of the Syllabus (what All Lessons, Topics will be Assessed in that Exam)
    - Questions will be selected from Question Bank as per the Scope of the Syllabus to align with the Exam.
    - Exam can have MCQ & Descriptive Questions
    - Exam questions will be selected as per the Difficulty Level defined in the Exam.
    - Teacher will Assign Exam to Class/Section/Group/Individual Student
    - Student will Attempt Exam with Time Limit apply as per the configuration.
    - Teacher will Evaluate Descriptive Answers of Exam and provide Marks & Remarks
    - The Marks of Descriptive Question (Evaluated by Teacher) will be entered into system mannually.
    - The Marks of MCQ (Auto Evaluated) will be entered into system automatically by system.
    - The Marks of Descriptive Question (Evaluated by Teacher) + Marks of MCQ (Auto Evaluated) will be considered for the Final Result.
    - Teacher can Re-Assign Exam to a class/section/group/individual if required.
    - Teacher will Publish Result on a specified date.
    - Student will View Result on a specified date.
    - Student can raise Grievance against the Marks of Descriptive Question (Evaluated by Teacher) within a specified time period.
    - Teacher will Review the Grievance and provide Final Decision.
    - Student can View the Final Decision of the Grievance.
    - Result Card will be generated for each student using Pre-Defined Template configured by School.

  Online Exam Functionalities:
  - All Quiz & Quest conditions applicable with additional conditions
    - is_proctored
    - is_ai_proctored
    - fullscreen_required
    - browser_lock_required
    - Exam Specific Security
      - Anti-Cheating
      - AI Readiness
      - Rubric-based evaluation
      - Performance auto-rating
      - Timer enforced
    - Result card generation per student
    - Subject-wise exam blueprint
    - Exam analytics dashboard
    - Scheduled result publishing
    - Automatic grade & division calculation
    - Performance category calculation
    - Exam timer enforcement. One time is lapsed then exam will be submitted automatically and student cannot restart the exam.
    - Result card generation per student
    - Subject-wise exam blueprint
    - Exam analytics dashboard
    - Collect Data for AI Readiness Prediction
  - Fully online exam capability (NEP aligned)
  - Combination of:
    - MCQ
    - Descriptive
  - Teacher evaluates descriptive answers
  - Exam question pool restricted to exam-enabled questions
  - Each Student may have Unique Exam Paper (Configurable)
  - Exam can be conducted for:
    - Class
    - Section
    - Group of Student
    - Individual Student
  - Exam Scope can have Multipal Lesson Or Topic / Sub-Topic
  - Configurable Difficulty Level (Easy, Medium, Hard) as used in Quiz & Quest
  - Exam result can be scheduled for specific date
    - Teacher can schedule the Exam result to be published on a specified date
    - Teacher can schedule the Exam result to be published Manually to a class/section/group/individual student
  - Exam instructions support:
    - TEXT
    - HTML
    - MARKDOWN
    - LATEX
    - JSON
  - Capture behavioral parameters for Analytics as mentioned below :
    - Time per question
    - Review behavior
    - Answer changes
    - Attempt patterns
  - Exam can be Re-Assigned to a class/section/group/individual student mannually by Teacher
  - Performance of MCQ auto-rating using configuration
  - Exam difficulty balancing
  - Update table (qns_question_statistics) after each attempt e.g. difficulty_index, discrimination_index, guessing_factor, min_time_taken_seconds, max_time_taken_seconds, avg_time_taken_seconds, total_attempts
  - Teacher can:
    - View Attempted Exam
    - View Attempted Exam Result
    - Teacher evaluates descriptive answers
    - Add remarks
    - Re-assign Exam if unsatisfactory
    - See who all submitted OR Not submitted the Exam
    - Extend the date of Exam (Re-schedule the Exam)
    - Extend the Submission Time of Exam (If Required) for a partucler Student/Class/Section/Group
  - Student can: 
    - View Exam Description to understand the Exam and Instruction
    - Attempt the Exam
    - View all Exam Due on him
    - VIEW Attempted Exam Result

---
### 2 - OFFLINE EXAM

  **Offline Exam Flow**
  - Here is the Proces Flow how Offline Exam will proceed -
    - Teacher will Create Exam (with all the conditions) (e.g. 7th_Half_Yearly_Exam, 7th_Final_Exam)
    - Teacher will define the Scope of the Exam (what All Lessons, Topics will be Assessed in that Exam)
    - Teacher will define the Difficulty Level of the Exam (Easy, Medium, Hard)
    - Teacher will define the Time Limit & Instructions of the Exam
    - System will help Teacher to Create Question Paper as per the Scope of the Exam, Difficulty Level & Time Limit for every Class/Subjects.
    - Teacher will Review the Question Paper and can make necessary changes and download the Question Paper.
    - Teacher will Assign the Question Paper to Class/Section/Group/Individual Student.
    - Exam will be Conducted Offline by Teacher as per the School Rules.
    - Student will attempt the Exam Offline as per the School Rules.
    - Teacher will Evaluate all the Questions and provided Marks & Remarks.
    - Students wise Answer and Marks will be Entered into System OR it can be uploaded as a file into system
    - System will calculate Grade & Division as per the Configuration and use the data for Analysis.
    - Teacher will Publish Result on a specified date.
    - Student will View Result on a specified date.
    - Student can raise Grievance against the Marks of Descriptive Question (Evaluated by Teacher) within a specified time period.
    - Teacher will Review the Grievance and provide Final Decision.
    - Student can View the Final Decision of the Grievance.
    - Result Card will be generated for each student using Pre-Defined Template configured by School.

  **Offline Exam Functionalities**

    - All conditions of Online Exam will be applicable, the only difference is that Exam will be Conducted Offline by Teacher as per the School Rules and Markes will be Enterd / Uploaded Later.
    - Fully offline exam capability (NEP aligned)
    - Combination of:
      - MCQ
      - Descriptive
    - Teacher evaluates all answers
    - Exam data entry / Data upload into App
    - Exam question pool restricted to Exam Paper Creation
    - Scheduled result publishing
    - Automatic grade & division calculation
    - Performance category calculation
    - Exam timer enforcement will be managed by Teacher
    - Result card generation per student
    - Subject-wise exam blueprint
    - Exam analytics dashboard

---

### USER INPUT:
I am providing four input files:
A) Requirement has been provided in the above section (REQUIREMENT)
B) An existing consolidated database DDL for other modules: **0-master_dbs/tenant_db.sql**
C) An existing DDL for Question Module : **2-Tenant_Modules/10-Question_Bank/DDL/Question_Bank_ddl_v1.2.sql**
D) An existing DDL for LMS Homework Module : **2-Tenant_Modules/16-LMS/LMS_Homework/DDL/LMS_Homework_DDL.sql**
E) An existing DDL for LMS Quiz Module : **2-Tenant_Modules/16-LMS/LMS_Quiz/DDL/LMS_Quiz_DDL.sql**
F) An existing DDL for LMS Quest Module : **2-Tenant_Modules/16-LMS/LMS_Quest/DDL/LMS_Quest_ddl_v1.0.sql**
G) An existing DDL for Student Profile Module : **2-Tenant_Modules/13-StudentProfile/DDL/StudentProfile_ddl_v1.4.sql**


### Your Mission:
1) Read the REQUIREMENT from section (REQUIREMENT) to understand the functional requirements.
2) Parse All the DDL files provided in the section (USER INPUT) to understand the existing DDL.
3) Extract requirements, domain entities, constraints, relationships, and business rules from the parsed files.
4) Produce a **complete and production-ready LMS_Quiz, LMS Online Exam Module Architecture** that unifies:
   - my functional requirements
   - my existing ERP schema

### DELIVERABLE:
DELIVERABLE A — Refactored Database DDL (MySQL 8 / Laravel-Friendly)
   Propose a **Refine, extended and industrialized LMS_Quiz & LMS_Quest Module architecture** including but not limited to:
    - Provide cleaned, refactored CREATE TABLE statements for **LMS_Quiz & LMS_Quest Modules** tables with:
    - precise data types for MySQL 8.
    - primary keys, foreign keys, unique constraints, check constraints, indexes (including composite indexes), and nullable rules.
    - example seed rows for main lookup tables(sys_dropdown_table) (INSERT statements).
    - Soft delete (`is_deleted`)
    - is active (`is_active`)
    - created_at, updated_at, deleted_at
   Output as single file in the folder "2-Tenant_Modules/16-LMS/LMS_Online_Exam" with file name : **LMS_Exam_ddl_v1.0.sql**  
   
   Store output in **2-Tenant_Modules/16-LMS/LMS_Online_Exam** 

   The DDL must include:
   - `CREATE TABLE` IF NOT EXISTS statements with strict data types  
   - Primary/Foreign keys  
   - Unique/Check constraints  
   - Composite indexes  
   - `is_active`, `created_at`, `updated_at`, `deleted_at` (soft delete)  
   - Referential integrity  
   - Required lookup tables  
   - Example seed data (INSERT statements)
  - Your outputs must be precise, developer-ready, and formatted cleanly in Markdown.
  


**Thinking Instructions:**

Save all the files in the folder named "2-Tenant_Modules/16-LMS/LMS_Online_Exam"

  - Provide All the Deliverables one by one, start with Database DDL, then move to Data Dictionary and so on..
  - Please provide all the Deliverables in the same folder "2-Tenant_Modules/16-LMS/LMS_Online_Exam/".




==============================================================================================================================
# Prompt - 2 for getting Screen Design, Dashboard, Testing & QA, Report Design for STUDENT PROFILE Module
==============================================================================================================================

Now Provide remaining Deliverables one by one.

Use DDL File "2-Tenant_Modules/ 13-StudentProfile/DDL/StudentProfile_ddl_v1.3.sql" for producing below deliverables.


**DELIVERABLE B - Screen Design**
  - Provide Separate Screen Design Files with All the sections provided in the sample file **Screen-Sample.md** to cover each tables in the Module.
  - One Screen may cover more then one Table, so think deeply before designing screens.
  - One screen may have multiple Tabs, so think deeply before designing screens.
  - Provide clean, developer-ready ASCII screen designs for all the screens required for the module.
  - Cover each and every Table provided in the DDL file.
  - **MUST MATCH** the screen-design style found in the sample file **Screen-Sample.md**.
  - Your outputs must be precise, developer-ready, and formatted cleanly in Markdown.
  - Match:
    - format (ASCII Screen Designs)
    - structure

**DELIVERABLE C - Dashboard**
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

**DELIVERABLE D - Testing & QA**
  - Provide clean, developer-ready ASCII test-cases and test-data for all the screens required for the module.
  - Provide a test-run checklist for developers for each screen
  - Provide a test-run checklist for QA for each screen
  - Provide minimum 10-20 representative test-cases (table-driven) with inputs and expected outputs, including edge cases.  
  - Cover Maximum Test cases as much as you can for each screen.
  - Match the style of the test-cases found in the sample file **Test_Cases_Sample.md**.

**DELIVERABLE E - Report Design**
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


**Storing Instructions:**

  - Save all the files in the folder named "2-Tenant_Modules/13-StudentProfile/Design/"
  - Provide All the Deliverables one by one.



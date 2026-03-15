### REQUIREMENT

   Modules_Design/LMS_Module/DDLs/lms_ddl_v1.5.sql
   


==============================================================================================================================
# Prompt - 1 To Enhance My Requirement for LMS Module
==============================================================================================================================
SYSTEM:
You are "Business Analyst GPT" - an Experienced Business Analyst specializing in SCHOOL ERP systems. You will Identify all the requirement needs to be incorporated in LMS Module.

Your outputs must be precise, grouped in modules and Sub-Modules and formatted cleanly in Markdown with example and ready to provide to a AI to create an deteailed DDL design and then further design documents.

**High Level Detail of the Fuctionality**

   Modules I need to Cover are -
   1) Syllabus Management
      - Syllabus Setup
        - Subject Setup
        - Chapter Setup
        - Sub-Chapter Setup
        - Topic Setup
        - Sub-Topic Setup
      - Book/Publication Management
        - Book Setup
        - Publication Setup
        - Book Management
        - Publication Management
      - Questiona Creation & Management
        - Question Bank Setup
        - Question Bank Management
        - Questiona Creation
        - Questiona Management
   2) Exam Management
      - Exam Management (Online)
        - Exam Setup
        - Exam Management
      - Exam Management (Offline)
        - Exam Setup
        - Exam Management
        - Exam Paper Creation
   3) Quiz & Assessment Management
      - Quiz & Assessment Management
        - Quiz & Assessment Masters
        - Quiz & Assessment Creation
        - Assign Questions to Quiz & Assessment
        - Assign Quiz & Assessment to Students
        - Quiz & Assessment Results
        - Quiz & Assessment Reports
        - Quiz & Assessment Analytics
   4) Recommendations Module
      - Recommendations Setup
      - Recommendations Management
      - Content Management
      - Recommendations Analytics
   5) Behavior Management
      - Behavior Categories
      - Behavior Subcategories
      - Behavior Points
      - Behavior Points History
      - Behavior Points Summary
      - Behavior Points Report
   6) Class Performance Management
      - Class Performance Setup
      - Class Performance Management
      - Class Performance Analytics
   7) Student Performance Management
      - Student Performance Setup
      - Student Performance Management
      - Student Performance Analytics
   8) Student Progress Management
      - Student Progress Setup
      - Student Progress Management
      - Student Progress Analytics
   9) Student Attendance Management
      - Student Attendance Setup
      - Student Attendance Management
      - Student Attendance Analytics

A Pre-liminary Requirement Document for LMS Module is attached.

I want you to provide me a detailed requirement Document to provide to a AI to create an deteailed DDL design and then further design documents.
The Requirement should meet below principles:

1) Requirement should be Grouped logically into Modules, Sub-Modules, Functionalities by thinking deeply on grouping the fuctionalities.
2) Requirement should be formatted cleanly in Markdown with examples and code blocks for SQL/JSON/cURL.
3) Requirement should be precise, technically correct, AI input ready, and formatted cleanly in Markdown with code blocks for SQL/JSON/cURL.
4) Provide detail what is the use of that feature and how it will be used, who will perform that activity.

Save the output file into folder **"2-Tenant_Modules/Z_Work-In-Progress"** with the file name **"LMS_Requirement.md"**.

This is not what I need I want you to generate a detailed Requirement Document which should cover all required fuctionalties for LMS Module. You need to search the Requirement Detail of LMS Module from other LMS Applications and then generate a detailed Requirement Document which should cover all required fuctionalties for LMS Module.
The Final Document should be Grouped into Module, Sub-Module, Fuctionalities and should also cover Deatil of the Fuctionalities (like what is the use of that feature and how it will be used, who will perform that activity).
Save the output file into folder **"2-Tenant_Modules/Z_Work-In-Progress"** with the file name **"LMS_Requirement_v1.md"**.



==============================================================================================================================
# Prompt - 2 To Enhance My Requirement for LMS Module using Chat GPT
==============================================================================================================================


SYSTEM:
You are "Business Analyst GPT" - an Experienced Business Analyst specializing in SCHOOL ERP systems. You will Identify all the requirement needs to be incorporated in LMS Module.

Your outputs must be precise, grouped in modules and Sub-Modules and formatted cleanly in Markdown with example and ready to provide to a AI to create an deteailed DDL design and then further design documents.

High Level Detail of the Fuctionality

   Modules I need to Cover are -
   1) Syllabus Management
      - Syllabus Setup
        - Subject Setup
        - Chapter Setup
        - Sub-Chapter Setup
        - Topic Setup
        - Sub-Topic Setup
      - Book/Publication Management
        - Book Setup
        - Publication Setup
        - Book Management
        - Publication Management
      - Questiona Creation & Management
        - Question Bank Setup
        - Question Bank Management
        - Questiona Creation
        - Questiona Management
   2) Exam Management
      - Exam Management (Online)
        - Exam Setup
        - Exam Management
      - Exam Management (Offline)
        - Exam Setup
        - Exam Management
        - Exam Paper Creation
   3) Quiz & Assessment Management
      - Quiz & Assessment Management
        - Quiz & Assessment Masters
        - Quiz & Assessment Creation
        - Assign Questions to Quiz & Assessment
        - Assign Quiz & Assessment to Students
        - Quiz & Assessment Results
        - Quiz & Assessment Reports
        - Quiz & Assessment Analytics
   4) Recommendations Module
      - Recommendations Setup
      - Recommendations Management
      - Content Management
      - Recommendations Analytics
   5) Behavior Management
      - Behavior Categories
      - Behavior Subcategories
      - Behavior Points
      - Behavior Points History
      - Behavior Points Summary
      - Behavior Points Report
   6) Class Performance Management
      - Class Performance Setup
      - Class Performance Management
      - Class Performance Analytics
   7) Student Performance Management
      - Student Performance Setup
      - Student Performance Management
      - Student Performance Analytics
   8) Student Progress Management
      - Student Progress Setup
      - Student Progress Management
      - Student Progress Analytics
   9) Student Attendance Management
      - Student Attendance Setup
      - Student Attendance Management
      - Student Attendance Analytics


Student Mgmt.
  - Student Master Data Management	
    - Student Profile
      - Create Student Record
      - Edit Student Profile
      - Student Address & Family
      - Manage Address
      - Family Information
      - Student Academic Information	
      - Class & Section Allocation
      - Modify Class Allocation
      - Assign Subjects
    - Student Attendance Records	
      - Daily Attendance
      - Mark Attendance (Mannual)
      - Attendance Corrections
      - Attendance Reports
      - Generate Reports
    - Student Health & Medical Records	
      - Medical Profile
      - Record Health Details
      - Vaccination History
      - Medical Incidents
      - Record Incident
      - Follow-up Tracking
    - Parent & Guardian Portal Access	
      - Parent Accounts
      - Create Parent Login
      - Manage Parent Access
      - Parent Communication
      - Parent Notifications

Student Attendance
  - Student Daily Attendance
    - Mark Daily Attendance (QR Code)
    - Bulk Attendance Entry
    - Request Correction
    - Approve/Reject Correction
  - Student Period/Subject Attendance
    - Mark Period Attendance
    - Bulk Attendance Entry
    - Request Correction
    - Approve/Reject Correction
  - Student Attendance Analytics
    - Generate Attendance Reports
    - Absentee Patterns
    - Send Alerts

Staff Attendance
  - Staff Daily Attendance
    - Mark Daily Attendance (QR Code)
    - Bulk Attendance Entry
    - Request Correction
    - Approve/Reject Correction
  - Leave Management
    - Apply Leave
    - Approve/Reject Leave
    - Leave Balance
    - Leave History
  - Attendance Regularization
    - Request Regularization
    - Approve/Reject Regularization
    - Regularization History
  - Department-Level Stats
  - Late/Early Alerts
  - Staff Attendance Analytics
    - Generate Attendance Reports
    - Absentee Patterns
    - Send Alerts

Academics Mgmt.
  - Academic Structure & Curriculum
    - Create Academic Structure
    - Edit Academic Structure
    - Delete Academic Structure
    - View Academic Structure
  - Curriculum Management
    - Create Curriculum
    - Edit Curriculum
    - Delete Curriculum
    - View Curriculum
  - Class & Section Management
    - Create Class
    - Edit Class
    - Delete Class
    - View Class
  - Class & Section Allocation
    - Assign Class to Student
    - Edit Class Allocation
    - Delete Class Allocation
    - View Class Allocation
  - Class & Section Analytics
    - Generate Class Analytics
    - View Class Analytics
    - Delete Class Analytics
    - Edit Class Analytics

    - Academic Structure
    - Create Academic Structure
    - Edit Academic Structure
    - Delete Academic Structure
    - View Academic Structure
  - Curriculum Management
    - Create Curriculum
    - Edit Curriculum
    - Delete Curriculum
    - View Curriculum
  - Class & Section Management
    - Create Class
    - Edit Class
    - Delete Class
    - View Class
  - Class & Section Allocation
    - Assign Class to Student
    - Edit Class Allocation
    - Delete Class Allocation
    - View Class Allocation
  - Class & Section Analytics
    - Generate Class Analytics
    - View Class Analytics
    - Delete Class Analytics
    - Edit Class Analytics

Lesson Planning & Delivery
  - Lesson Plan Setup
    - Create Lesson Plan
    - Edit Lesson Plan
    - Delete Lesson Plan
    - View Lesson Plan
  - Lesson Plan Allocation
    - Assign Lesson Plan to Student
    - Edit Lesson Plan Allocation
    - Delete Lesson Plan Allocation
    - View Lesson Plan Allocation
  - Lesson Plan Analytics
    - Generate Lesson Plan Analytics
    - View Lesson Plan Analytics
    - Delete Lesson Plan Analytics
    - Edit Lesson Plan Analytics

Homework & Assignments
  - Homework Setup
    - Create/Edit/Delete/View Homework
  - Homework Allocation
    - Assign Homework to Student
    - Edit/Delete/View Homework Allocation
  - Homework Analytics
    - Generate Homework Analytics
    - View/Edit/Delete Homework Analytics

Academic Calendar & Events
  - Academic Calendar Setup
    - Create/Edit/Delete/View Academic Calendar
  - Academic Calendar Allocation
    - Assign Academic Calendar to Student
    - Edit/Delete/View Academic Calendar Allocation
  - Academic Calendar Analytics
    - Generate Academic Calendar Analytics
    - View/Edit/Delete Academic Calendar Analytics

Teacher Workload & Distribution
  - Teacher Workload Setup
    - Create/Edit/Delete/View Teacher Workload
  - Teacher Workload Allocation
    - Assign Teacher Workload to Student
    - Edit/Delete/View Teacher Workload Allocation
  - Teacher Workload Analytics
    - Generate Teacher Workload Analytics
    - View/Edit/Delete Teacher Workload Analytics

Skill & Competency Tracking
  - Skill & Competency Setup
    - Create/Edit/Delete/View Skill & Competency
  - Skill & Competency Allocation
    - Assign Skill & Competency to Student
    - Edit/Delete/View Skill & Competency Allocation
  - Skill & Competency Analytics
    - Generate Skill & Competency Analytics
    - View/Edit/Delete Skill & Competency Analytics






A Pre-liminary Requirement Document for LMS Module is attached.

I want you to provide me a detailed requirement Document for providing to AI to create an deteailed DDL design and then further design documents.
The Requirement should meet below principles:

1) Requirement should be Grouped logically into Modules, Sub-Modules, Functionalities by thinking deeply on grouping the fuctionalities.
2) Requirement should be formatted cleanly in Markdown with examples and code blocks for SQL/JSON/cURL.
3) Requirement should be precise, technically correct, AI input ready, and formatted cleanly in Markdown with code blocks for SQL/JSON/cURL.
4) Provide detail what is the use of that feature and how it will be used, who will perform that activity.

Your Mission:
I want you to generate a detailed Requirement Document by searching the Requirement Detail of LMS Module from other LMS Applications and then generate a detailed Requirement Document which should cover all required fuctionalties for LMS Module.
The Final Document should be Grouped into Module, Sub-Module, Fuctionalities and should also cover Deatil of the Fuctionalities (like what is the use of that feature and how it will be used, who will perform that activity).

Save the output file as a new excel file. Output Format should be exactly same as the attached excel file.

==============================================================================================================================
# Prompt - 2 only for Enhancing Existing DDL for LMS Module
==============================================================================================================================

SYSTEM:
You are "ERP Architect GPT" — a senior software architect, data modeler, API designer, and UX/UI systemizer specializing in SCHOOL ERP systems. You will design a production-grade, fully detailed **LMS Module** using the inputs I provide.

Your outputs must be precise, technically correct, developer-ready, and formatted cleanly in Markdown with code blocks for SQL/JSON/cURL.

### Product Vision
An AI-enabled, modular, multi-tenant School ERP + LMS + LXP platform designed for:
  - CBSE / ICSE / State Boards
  - Medium to large schools
  - Data-driven academic & administrative decision-making

### Technology Stack
  - Backend: PHP 8.x + Laravel
  - Database: MySQL 8+
  - Architecture: Multi-tenant (Master DB + Tenant DB). Every Tenant will have separate DB.
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

### REQUIREMENT:
  - This Module will capture the performance based recommendations for students.
  - This will capture different type of Media for recommendations e.g. Text, Video, PDF, Audio, Quiz, Assignment, Link etc.
  - This will capture different type of recommendations for different purpose e.g. Revision, Practice, Remedial, Advanced, Enrichment etc.
  - It will provide different type of recommendations for different subjects, classes, topics etc.
  - It will provide different type of recommendations for different performance categories e.g. Quiz, Weekly/Monthly/Yearly Tests, Exam Prep, Revision, Practice, Remedial, Advanced, Enrichment etc.
  - Recommendation engine will provide different type of recommendations for different level of performance e.g. Excelent, Good, Average, Poor etc.


### USER INPUT:
I am providing four input files:
A) An existing tenant_db database DDL: **master_dbs/tenant_db.sql**
B) A preliminary version of the Recommendation module schema: **2-Tenant_Modules/11-Recommendation/DDL/Recommendation_ddl_v1.1.sql**
C) A existing syllabus module database DDL: **Modules_Design/Syllabus_Module/DDLs/syllabus_ddl_v1.5.sql**
D) An existing consolidated database DDL for other modules: **Modules_Design/Z_Templates/z_consolidated_ddl.sql**

### Your Mission:
1) Parse the Recommendation_Requirement.md file first with REQUIREMET Section to understand the functional requirements.
2) Parse remaining 4 files to understand the existing database schema if required.
3) Extract requirements, domain entities, constraints, relationships, and business rules from the parsed files.
4) Produce a **complete and production-ready Recommendation Module Architecture** that unifies:
   - my functional requirements
   - my existing ERP schema
   - Refine, extend and industrialize my existing DDL design of Recommendation Module.

### DELIVERABLE:
DELIVERABLE A — Refactored Database DDL (MySQL 8 / Laravel-Friendly)
   Propose a **Refine, extended and industrialized Recommendation Module architecture** including butnot limited to:
   - Core entities (Day, Period, Session, Slot, Teacher, Subject, Room, Constraint)
   - Advanced scheduling entities (Auto-scheduler rules, Constraints, Weightage, Timer rules)
   - Manual vs automatic timetable generation models
   - Substitution workflow entities
   - Academic year & class-section linkage
   - Create DDL in 2 Sections Proposed new tables & Enhancement in Existing Tables.
   
   Output as single file (in same folder) with file name : **recommendation_ddl_v1.2.sql**  
   
   Store output in **2-Tenant_Modules/11-Recommendation/DDL/** 

   The DDL must include:
   - `CREATE TABLE` IF NOT EXISTS statements with strict data types  
   - Primary/Foreign keys  
   - Unique/Check constraints  
   - Composite indexes  
   - `is_active`, `created_at`, `updated_at`, `deleted_at` (soft delete)  
   - Referential integrity  
   - Required lookup tables  
   - Example seed data (INSERT statements)



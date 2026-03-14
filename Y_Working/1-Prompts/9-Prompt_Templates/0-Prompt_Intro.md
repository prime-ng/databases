# Conversation Starter Template (Provided by ChatGPT)

PROJECT CONTEXT
---------------
I am building a School ERP + LMS + LXP system.
Tech Stack: PHP (Laravel) + MySQL
Architecture: Multi-tenant, modular, AI-enabled
Role: I want you to act as a Principal Systems Architect.

EXISTING CONTEXT (Already Designed Earlier)
-------------------------------------------
Modules already discussed/designed earlier include (not limited to):
- Core School ERP Modules
- Transport Management (Standard + Advanced)
- Complaint Management with AI Insights
- Notification Module (Common, Cross-Module)
- LMS / LXP
- Timetable Module (FET-level complexity)
- Recommendation Engine
- Analytics, Reports, Dashboards
- Background Jobs / Nightly Batches

CURRENT OBJECTIVE
-----------------
Now I want to work on:
👉 [MENTION MODULE / SUB-MODULE NAME]

WHAT I EXPECT IN OUTPUT
-----------------------
Please provide:
- Architecture / Process Flow
- Database Design (DDL / ERD if required)
- API Design (Request/Response)
- Jobs / Batches / Events if applicable
- Reports & Dashboards if relevant
- Assumptions + Extensibility Notes

CONSTRAINTS
-----------
- Do NOT redesign unrelated modules
- Maintain consistency with existing ERP philosophy
- Assume production-grade, scalable design

START FROM:
-----------
[Example: “Extend existing design”, “Design from scratch”, “Modify existing DDL”]


---------------------------------------------------------------------------------------------------------------------


## MASTER ERP REFERENCE — PRIME SCHOOL ERP

### Product Vision
An AI-enabled, modular, multi-tenant School ERP + LMS + LXP platform designed for:
  - CBSE / ICSE / State Boards
  - Medium to large schools
  - Data-driven academic & administrative decision-making

### Technology Stack
  - Backend: PHP 8.x + Laravel
  - Database: MySQL 8+
  - Architecture: Multi-tenant (Master DB + Tenant DB)
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

### Key Modules (High Level)
**Academic**
    - Class, Section, Subject
    - Syllabus → Lessons → Topics → Sub-Topics
    - Question Bank (NEP 2020 aligned)
    - Exams, Assessments, Quizzes
    - Timetable (Auto + Manual)

**Administrative**
    - Student, Teacher, Parent
    - HR & Staff Management
    - Attendance (Manual, QR, Device-based)
    - Certificates & Documents

**Transport**
    - Routes, Stops, Vehicles
    - Driver & Helper
    - Student Boarding / Unboarding
    - GPS / Safety / Attendance
    - Advanced Analytics & Prediction

**Communication**
    - Notification Module (Common)
    - SMS / Email / App Push
    - Alerts, Reminders, Escalations

**Complaints & Feedback**
    - Complaint Lifecycle
    - SLA & Escalation
    - AI Insights:
      - Sentiment
      - Risk Scores
      - Category Prediction
      - Safety Index

**LMS / LXP**
    - Content (Video, PDF, Text)
    - Learning Paths
    - Personalized Recommendations
    - Performance-based suggestions

### AI & Analytics Philosophy
    - AI is assistive, not opaque
    - Prefer explainable scores
    - Store raw signals + derived metrics
    - Nightly batch jobs for heavy computation
    - Real-time insights only where required

### Reporting & Dashboard Strategy
    - Role-based dashboards:
        - Management
        - Principal
        - Teacher
        - Transport Head
        - Parents
    - KPI-driven charts
    - Materialized Views for heavy reports
    - Audit-friendly data lineage

### Database Strategy
    - Naming conventions enforced
    - Master tables configurable by school
    - Historical tables (no hard deletes)
    - AI Insight tables separated from transactional tables

### Design Expectations from AI
    - When designing any module:
        - Start with process flow
        - Then DDL
        - Then APIs
    - Then Jobs / Reports
    - Always mention:
        - What problem it solves
        - Who uses it
    - How it scales
    - How it integrates

### Non-Goals
    - No over-engineering
    - No unnecessary microservices
    - No black-box ML without explainability

### Working Mode
    - You are expected to behave as:
        - Principal Architect + Data Modeler + ERP Domain Expert

For 90% of chats, you will be provided with the following information:
    - Just use:
        - “Continuing my School ERP project. Now I want to work on …”


================================================================================================================
Previously I have designed a Question Bank Module for my School ERP project with your help (Chat - "Question Bank Module") and I also provided you the DDL of all the Modules we have developed so far in the Chat - "Working with ChatGPT". Now I am working on "Question Bank Module"and wanted you to refine, extend and industrialize my existing design. Below is my existing design of Question Bank Module:




Now I wanted you to refine, extend and industrialize my existing design.




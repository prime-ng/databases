Architecture Highlights
1. Unified Student Core
std_students: Stores immutable/core identity data (Admission No, Joining Date, DOB, Gender).
std_student_profiles: Stores extended personal details (Religion, Bank Info, Physical Stats) to keep the core table lightweight.
2. Normalized Family & Address
std_guardians: Independent table for parents/guardians, linked to std_students via std_student_guardian_jnt. This allows:
Multiple siblings sharing the same parent record.
Multiple guardians (Father, Mother, Local Guardian) per student.
Integration with sys_users for Parent Portal access.
std_student_addresses: One-to-Many relationship allows separate Permanent, Correspondence, and Local Guardian addresses.
3. Academic & Attendance
std_student_academic_sessions: Tracks the student's journey across sessions (Class 1 -> Class 2 -> Class 3), retaining history of Class/Section allocations.
std_student_attendance: Optimized daily attendance log with status enum (Present, Absent, Late, etc.).
std_attendance_corrections: Built-in workflow for parents to request attendance corrections.
4. Health Module
std_health_profiles: Longitudinal health record foundation.
std_medical_incidents: Logs school clinic visits/injuries.
std_vaccination_records: Digital vaccination card.
Next Steps
Execute the SQL script in your development tenant_db to create the tables.
Run php artisan migrate or equivalent if mapping to Laravel models.
Seed the sys_dropdown_needs and sys_dropdown_table with the required lookups (Student Status, Attendance Status, etc.).


Student Profile Module Implementation Plan
Goal Description
Design a production-grade Student Profile Module for the School ERP. This module unifies Student Master Data, Family/Address info, Academic allocations, Attendance, and Health records into a normalized, efficiently indexed schema.

User Review Required
IMPORTANT

Normalization Strategy: I am normalizing "Family/Guardian" details into a separate std_guardians table (linked via M:N or 1:N) rather than flat columns in student_details. This supports siblings and cleaner parent portal access.
Address Strategy: Moving addresses to std_student_addresses to better handle multiple address types (Permanent, Correspondence).
Attendance: New tables std_student_attendance and std_attendance_corrections added.
Health: New tables for std_health_profiles, std_vaccinations, std_medical_incidents.
Proposed Changes
Student Profile Module (2-Tenant_Modules/13-StudentProfile/DDL/)
[NEW] 
StudentProfile_ddl_v1.2.sql
Student Core
std_students: Main entity. Links to sys_users.
std_student_profiles: Extended personal details (DOB, Religion, Category).
Contact & Family
std_student_addresses: One-to-Many (Permanent, Current).
std_guardians: Database of parents/guardians. Links to sys_users for Parent Portal.
std_student_guardian_jnt: Junction table (Father, Mother, Guardian relationships).
Academic
std_student_academic_sessions: (Refined std_student_sessions_jnt). Tracks Class, Section, Roll No, Subject Group per session.
Attendance
std_student_attendance: Daily attendance log.
std_attendance_corrections: Workflow for attendance fixes.
Health
std_health_profiles: Blood group, allergies, chronic conditions.
std_vaccination_records: Vaccine taken, date.
std_medical_incidents: Injury/Sickness logs at school.
Verification Plan
Manual Verification
Review the generated SQL for syntax errors.
Verify Foreign Key relationships match tenant_db.sql master tables (sys_users, glb_cities, sch_classes).
Check data types compatibility (MySQL 8.x).
Validate that all requirements (Attendance, Health, Parent Portal links) are covered by table structures.

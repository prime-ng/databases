LMS Exam Module v2 Implementation Plan
Goal
Create a robust, flexible DDL (LMS_Exam_ddl_v2.sql) that supports complex exam scenarios including Mixed Modes (Online/Offline), Multi-Set Papers, and Student Grouping strategies.

User Review Required
IMPORTANT

Offline Exam Data Entry: The design supports both "Bulk Total Marks" entry and "Granular Question-wise" entry for offline exams. Granular entry is required if AI evaluation is desired.

WARNING

Complexity: The hierarchy Exams -> Papers -> Sets -> Questions adds complexity compared to a simple Exam -> Questions model. This is necessary to support different questions for different students within the same "Exam".

Proposed Schema Structure
1. Masters & Configuration
lms_exam_types: (Already defined) UT-1, Annual, etc.
lms_grading_schemas: Rules for converting marks to Grades (A, B, C).
2. Exam Definition Hierarchy
lms_exams [Level 1]: The umbrella event (e.g., "Half Yearly Exam 2025").
Properties: Session, Board, Exam Type.
lms_exam_papers [Level 2]: Specific subject paper for a cohort (e.g., "Class 9 - Science - Offline").
Properties: Subject, Mode (Online/Offline), Date, Duration, Total Marks.
lms_exam_paper_sets [Level 3]: Variants of the paper (e.g., "Set A", "Set B").
Properties: Name, Code.
lms_paper_set_questions [Level 4]: Questions linked to a Set.
Properties: Question ID (from Bank), Order, Marks (Override).
3. Allocation & Grouping
lms_exam_student_groups: Ad-hoc groups of students for exam distribution (e.g., "Class 9 - Advanced Math Group").
lms_exam_allocations: Mapping of lms_exam_paper_sets to lms_exam_student_groups or individual students.
4. Execution (Online & Offline)
lms_student_attempts:
Online: Session tracking (Start/End time, IP).
Offline: Metadata for the attempt (Answer Sheet Reference, Presence status).
lms_student_answers:
Online: Student selected options or typed text.
Offline: Digitized marks per question (optional) or OCR text.
5. Results & Grading
lms_exam_marks_entry: For offline exams where only total marks are entered (bypassing granular answers).
lms_exam_results: Consolidated Final Result (Marks + Grade).
Verification Plan
Automated Verification
We will parse the generated SQL using a syntax checker (if available) or review the SQL structure.
We will simulate the "Create Exam" flow mentally to ensure all foreign keys and dependencies exist.
Manual Verification
Check Foreign Keys: Ensure all references to academic_session, subjects, classes point to valid master tables in tenant_db.
Check Constraints: Verify UNIQUE constraints on Codes and UUIDs.
Check Data Types: Ensure DECIMAL is used for marks and DATETIME for schedules.
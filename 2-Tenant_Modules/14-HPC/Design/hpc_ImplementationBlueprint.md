# Holistic Progress Card (HPC) - Complete Implementation Blueprint

## Executive Summary
This document provides a comprehensive process flow for capturing student data and generating HPC report cards across four stages (Foundation, Preparatory, Middle, Secondary). The implementation leverages your existing schema while introducing new workflows, screens, and automation rules.

### 1. HIGH-LEVEL PROCESS FLOW
   View - (2-Tenant_Modules/14-HPC/SVGs/1-HighLevelProcessFlow.svg)

### 2. DETAILED PROCESS SEQUENCE

#### Phase 1: Academic Year Setup (Before Session Starts)
|Step|Process                       |Data Source          |Target Tables                                                                  |Responsibility    |
|----|------------------------------|---------------------|-------------------------------------------------------------------------------|------------------|
|1.1 |Create HPC Templates          |Form PDFs            | hpc_templates, hpc_template_parts, hpc_template_sections, hpc_template_rubrics|Admin/Super Admin |
|1.2 |Map Templates to Classes      |Class-Session mapping|Application layer mapping                                                      |Admin             |
|1.3 |Configure Circular Goals      |NCF 2023 documents   |hpc_circular_goals                                                             |Curriculum Head   |
|1.4 |Map Competencies to Goals     |Existing competencies|hpc_circular_goal_competency_jnt                                               |Curriculum Head   |
|1.5 |Define Learning Outcomes      |Syllabus + NCF       |hpc_learning_outcomes                                                          |Subject Teachers  |
|1.6 |Map Outcomes to Topics        |Lesson plans         |hpc_outcome_entity_jnt                                                         |Subject Teachers  |
|1.7 |Setup Ability Parameters      |System defaults      |hpc_ability_parameters                                                         |System (One-time) |
|1.8 |Setup Performance Descriptors |System defaults      |hpc_performance_descriptors                                                    |System (One-time) |

#### Phase 2: Student Onboarding & Initial Data (First Month)
|Step|Process	                    |Data Source	     |Target Tables	              |Responsibility         |
|----|------------------------------|--------------------|----------------------------|-----------------------|
|2.1 |Create Student Records        |Admission module    |slb_students                |Admission Office       |
|2.2 |Assign APAAR IDs              |External API/Manual |slb_students.apaar_id       |Admin                  |
|2.3 |Initialize HPC Reports        |System automation   |hpc_reports (draft status)  |System (Cron)          |
|2.4 |Capture Part-A (1) Data       |Parent interaction  |hpc_report_items via screens|Class Teacher          |
|2.5 |Parent Questionnaire          |Parent portal       |hpc_report_items            |Parents                |
|2.6 |Student Self-Introduction     |Classroom activity  |hpc_report_items            |Students (with teacher)|


### Phase 3: Continuous Data Capture (Throughout Year)
   View - (2-Tenant_Modules/14-HPC/SVGs/3-ContinousDataCapture.svg)

#### 3. DATA CAPTURE MATRIX
#### 3.1 Data from Existing ERP Modules (Auto-fetched)
|Module	                |Data Elements	                            |Source Table	                    |Target HPC Section
|-----------------------|-------------------------------------------|-----------------------------------|------------------
|Student Information	|Name, Roll No., DOB, Age, Address, Phone	|slb_students	                    |Part-A (1)
|Parent Information	    |Mother/Father Name, Education, Occupation	|slb_parents	                    |Part-A (1)
|Academic Structure	    |Section, Class, Registration No.	        |class_sections, slb_enrollments	|Part-A (1)
|School Information	    |School Name, Address, UDISE Code, BRC, CRC	|sch_organizations	                |Part-A (1)
|Attendance	            |Monthly attendance data	                |attendance_students                |Attendance Table
|Assessment Scores	    |Subject-wise marks/grades	                |exam_results	                    |Domain assessments
|Co-scholastic Areas	|Physical/Health records	                |co_scholastic_records	            |Physical Development
|Previous HPC Data	    |Historical performance	                    |hpc_reports	                    |Progress tracking

#### 3.2 Manual Data Entry Requirements
|Data Element	            |Input Screen                |Frequency           |Responsible Person
|---------------------------|----------------------------|--------------------|----------------------
|Mother Tongue	            |Part-A Data Entry	         |Once	              |Class Teacher
|Rural/Urban	            |Part-A Data Entry	         |Once	              |Class Teacher
|Illness History	        |Health Record Screen	     |Monthly	          |Class Teacher/Parent
|Siblings Details	        |Family Information Screen	 |Once                |Class Teacher
|Student Interests	        |Interests Screen	         |Termly              |Student + Teacher
|Domain-wise Observations	|Domain Assessment Screen	 |Ongoing             |Subject Teachers
|Activity-specific Rubrics	|Activity Assessment Screen	 |Per activity        |Subject Teachers
|Teacher's Feedback Notes	|Feedback Screen	         |Termly              |Class Teacher
|Parent Observations	    |Parent Portal	             |Termly              |Parents
|Self-Assessment Emojis	    |Student Dashboard	         |Per activity        |Students
|Peer Assessment	        |Peer Review Screen	         |Per group activity  |Students

#### 3.3 Generated/Calculated Data
|Data Element	                |Calculation Logic	                    |Frequency
|-------------------------------|---------------------------------------|-------------
|Attendance Percentage	        |Days Present ÷ Working Days) × 100	    |Monthly
|Age	                        |Current Date - DOB	                    |Once
|Credit Points	                |Credits × NCrF Level                   |Year-end
|Performance Level (Awareness)	|Aggregation of related rubric scores	|Per domain
|Performance Level (Creativity)	|Aggregation of related rubric scores	|Per domain
|Summary Descriptors	        |Algorithm combining multiple inputs    |Year-end


### 4. SCREEN REQUIREMENTs
   View - (2-Tenant_Modules/14-HPC/Design/hpc_screen_requirement.md)

### 5. COMPLETE DATA FLOW DIAGRAM
   View - (2-Tenant_Modules/14-HPC/SVGs/5-CompleteDataFlowDiagram.svg)

### 6. KEY IMPLEMENTATION CONSIDERATIONS
#### 6.1 Age-Specific Workflows
|Stage	     |Grades	 |Key Features					                     |Assessment Approach
|------------|-----------|---------------------------------------------------|---------------------------------------
|Foundation	 |BV1-3, 1-2 |Emoji-based, Picture selection, Simple statements	 |Teacher + Parent input primarily
|Preparatory |3-5		 |Statement-based, Self + Peer assessment			 |Balanced teacher-student input
|Middle	     |6-8		 |Detailed rubrics, Project work, Skill tracking	 |Multi-source assessment
|Secondary   |9-12		 |Career planning, Credit accumulation, MOOCs		 |Comprehensive + External certifications

#### 6.2 Automation Rules
```sql
-- Rule 1: Auto-create hpc_reports at session start
CREATE EVENT auto_create_hpc_reports
ON SCHEDULE EVERY 1 YEAR
STARTS '2025-04-01 00:00:00'
DO
  INSERT INTO hpc_reports (student_id, template_id, session_id, term_id, report_date, status)
  SELECT s.id, t.id, ss.id, t.id, CURDATE(), 'draft'
  FROM slb_students s
  JOIN sch_sessions ss ON ss.is_current = 1
  JOIN hpc_templates t ON t.grade_from <= s.current_grade AND t.grade_to >= s.current_grade
  WHERE s.is_active = 1;

-- Rule 2: Calculate attendance percentages monthly
CREATE EVENT calculate_monthly_attendance
ON SCHEDULE EVERY 1 MONTH
DO
  UPDATE hpc_report_items ri
  JOIN hpc_reports r ON r.id = ri.report_id
  JOIN attendance_students a ON a.student_id = r.student_id AND MONTH(a.date) = MONTH(CURDATE())
  SET ri.out_numeric_value = (COUNT(a.present) / COUNT(a.date)) * 100
  WHERE ri.rubric_id = (SELECT id FROM hpc_template_rubrics WHERE code = 'ATTENDANCE_PCT');
```

#### 6.3 Validation Rules

|Rule                |Description                                              |Enforcement Point
|--------------------|---------------------------------------------------------|--------------------
|Mandatory Fields    |Part-A fields must be filled before report finalization  |Report generation
|Rubric Completeness |All rubrics must have values before final                |Report generation
|Parent Signature    |Digital acknowledgment required for Secondary            |Parent portal
|Credit Calculation  |Total credits must match NCrF requirements               |Year-end processing
|Data Consistency    |Student details match across modules                     |Real-time on save

#### 6.4 API Endpoints Required

```yaml
/api/hpc/templates:
  GET: List all templates
  POST: Create new template
  PUT: Update template
  DELETE: Archive template

/api/hpc/reports:
  GET: List reports (filter by student/class/term)
  POST: Generate new report
  PUT: Update report status

/api/hpc/assessments:
  GET: Get assessments for student/activity
  POST: Submit assessment
  PUT: Update assessment

/api/hpc/activities:
  GET: List learning activities
  POST: Create activity record
  PUT: Update activity

/api/hpc/credits:
  GET: Calculate credit points for student
  POST: Validate credit accumulation

/api/hpc/export:
  POST: Generate PDF report
  GET: Download generated report
  POST: Bulk export class reports
  ```


### 7. IMPLEMENTATION PHASING

#### Phase 1: Foundation (Months 1-3)

✅ SC-01, SC-02: Template Builder & Goals Manager
✅ SC-05, SC-06: Teacher Dashboard & Part-A Entry
✅ SC-11, SC-12: Student Dashboard & Simple Self-Assessment
✅ Basic report generation (PDF)

#### Phase 2: Core Assessment (Months 4-6)
✅ SC-08, SC-09: Domain & Activity Assessment
✅ SC-10: Teacher Feedback
✅ SC-15, SC-16: Parent Portal & Input
✅ SC-18: Report Preview

#### Phase 3: Advanced Features (Months 7-9)
✅ SC-13, SC-14: Peer Assessment & Goal Setting
✅ SC-19: Bulk Report Generator
✅ SC-20: Credit Calculator
✅ Integration with existing exam module

#### Phase 4: Optimization (Months 10-12)
✅ Performance tuning
✅ Advanced analytics
✅ Mobile app integration
✅ External API connections (APAAR, UDISE+)


### 8. SAMPLE SQL FOR REPORT GENERATION

```sql
-- Stored Procedure to Generate Complete HPC Report
DELIMITER $$

CREATE PROCEDURE generate_hpc_report(
    IN p_student_id INT UNSIGNED,
    IN p_session_id INT UNSIGNED,
    IN p_term_id INT UNSIGNED
)
BEGIN
    DECLARE v_report_id INT UNSIGNED;
    
    -- Get or create report record
    INSERT INTO hpc_reports (student_id, template_id, session_id, term_id, report_date, status)
    SELECT 
        p_student_id,
        t.id,
        p_session_id,
        p_term_id,
        CURDATE(),
        'draft'
    FROM hpc_templates t
    WHERE t.grade_from <= (SELECT current_grade FROM slb_students WHERE id = p_student_id)
      AND t.grade_to >= (SELECT current_grade FROM slb_students WHERE id = p_student_id)
    ON DUPLICATE KEY UPDATE
        report_date = CURDATE(),
        updated_at = NOW();
    
    -- Get report ID
    SELECT id INTO v_report_id
    FROM hpc_reports
    WHERE student_id = p_student_id
      AND session_id = p_session_id
      AND term_id = p_term_id;
    
    -- Aggregate assessment data into report items
    INSERT INTO hpc_report_items (
        report_id, rubric_id, out_label, out_numeric_value, out_text_value
    )
    SELECT 
        v_report_id,
        tr.id,
        hpd.code,
        AVG(hpd.ordinal),
        GROUP_CONCAT(DISTINCT hpd.description)
    FROM hpc_student_evaluation hse
    JOIN hpc_ability_parameters hap ON hap.id = hse.hpc_ability_parameter_id
    JOIN hpc_performance_descriptors hpd ON hpd.id = hse.hpc_performance_descriptor_id
    JOIN hpc_template_rubrics tr ON tr.ability_parameter_id = hap.id
    WHERE hse.student_id = p_student_id
      AND hse.academic_session_id = p_session_id
    GROUP BY tr.id, hap.code;
    
    -- Return success
    SELECT v_report_id AS report_id, 'Report generated successfully' AS message;
END$$

DELIMITER ;
```

### 9. SUMMARY: WHAT DEVELOPERS NEED TO BUILD

#### Backend Services (9)
  1. Template Management Service
  2. Assessment Service
  3. Report Generation Service
  4. Credit Calculation Service
  5. Data Aggregation Service
  6. Import/Export Service
  7. Notification Service
  8. Validation Service
  9. Analytics Service

#### Database Tables (19 new + existing)
  1. Schema-1: 7 tables (already designed)
  2. Schema-2: 12 tables (with fixes)
  3. Bridge tables: 2-3 additional

#### Frontend Screens (20 total)
  1. Admin: 4 screens
  2. Teacher: 6 screens
  3. Student: 4 screens
  4. Parent: 3 screens
  5. Reports: 3 screens

#### Integration Points (8)
  1. Student Information System
  2. Attendance Module
  3. Examination Module
  4. Parent Portal
  5. UDISE+ API
  6. APAAR ID System
  7. Learning Management System (LXP)
  8. Analytics Dashboard

#### Deliverables Timeline
  - Month 1-2: Database setup + Admin screens
  - Month 3-4: Teacher interface + Basic assessment
  - Month 5-6: Student/Parent portals + Simple reports
  - Month 7-8: Full assessment cycle + Advanced reports
  - Month 9-10: Credit framework + External integrations
  - Month 11-12: Testing, optimization, deployment


This blueprint provides a complete, developer-ready implementation plan for the HPC module. Each section contains precise specifications that can be directly translated into code by your development team.



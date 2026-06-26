# Behavioural Assessment Module — Business Requirements Overview

## Module Purpose

The Behavioural Assessment Module enables the school to systematically track, evaluate, and report student conduct, personality traits, and behavioural development. It transitions the school from subjective, unstructured feedback to a standardized, criteria-based evaluation framework. 

This module supports configuring custom rating scales, setting up specific behavioural criteria (e.g., leadership, teamwork, discipline), logging real-time behavioural incidents (both positive achievements and disciplinary infractions), tracking witnesses/interventions, and generating rich standalone progress reports for parent-teacher meetings and report cards.

---

## Who Uses This Module

| Role | Primary Activities |
|------|-------------------|
| **Admin / Principal** | Configures global rating scales, category templates, academic periods, and custom interventions. Reviews logs and system audits. |
| **Class Teacher** | Conducts periodic assessments, inputs qualitative remarks, manages class-level mappings, and generates student report cards. |
| **Subject Teacher** | Grades students on specific criteria, files incident logs (disciplinary or achievements), and adds descriptive remarks. |
| **Behavioural Counsellor / HOD** | Reviews assessment queues, tracks escalated behavioral incidents, coordinates and applies specific corrective interventions. |

---

## Module Screens (Tab-wise Structure)

The module is organized under five primary menus, each containing multiple tabs, along with standalone reporting pages.

### 1. Dashboard
- **Dashboard**: High-level financial and behavioural analytics, incident frequency charts, and pending evaluation tracking.

### 2. Masters
- **Rating Scales**: Configure the scoring frameworks (e.g., 1-5 scales, A-E grades) and descriptions.
- **Categories**: Classify behavioural criteria into domains (e.g., Social Skills, Personal Hygiene).
- **Interventions**: Maintain a repository of standardized supportive or disciplinary actions.

### 3. Setup
- **Class Mapping**: Map behavioural categories to specific classes/grades to tailor evaluation.
- **Periods**: Define evaluation terms or monthly cycles within an academic session.
- **Configuration**: Set global defaults, active scales, grade thresholds, and automated rules.

### 4. Assessments
- **My Assessments**: A teacher-focused hub showing assignments, status, and search filters.
- **Ratings**: Grid interface to score students on criteria within a selected class/section and period.
- **Remarks**: Text area to capture qualitative descriptions and recommendations per student.
- **Review Queue**: An approval workflow for supervisors/HODs to review and lock submitted grades.

### 5. Incidents
- **Incident Log**: Register disciplinary issues, student conflicts, or positive achievements.
- **Witnesses**: Link other students or staff who witnessed the logged incident.
- **Interventions Applied**: Log and track restorative actions, counseling sessions, or warnings.

### 6. Reports Hub
- **Reports Hub**: central directory to configure and download CSV/Excel reports.
- **Student Scores**: Export student-wise composite and average scores.
- **Category Summary**: Detailed breakdown of category performance class-wise.
- **Period Report**: Comparison of scores across different terms or months.
- **Audit Trail**: Tracking who modified assessment scores or configurations.

### 7. Standalone Reports (Detailed Views)
- **Student Report**: Holistic report card containing criteria scores, remarks, and incidents.
- **Class Analysis**: Comparative analysis of all students in a section to identify outliers.
- **Period Progress**: Trend charts showing score improvements or declines over time.
- **Category Performance**: Statistical standard deviation and average analysis per category.
- **Incident Report**: Comprehensive summary of all recorded incidents and corrective outcomes.

---

## Core Business Flow

```
1. Master Configuration
   ├── Define Rating Scales & Levels (e.g., A to E)
   ├── Establish Categories & Criteria (e.g., Cooperation)
   └── Register Interventions (e.g., Parent Counseling)
           ↓
2. Class & Period Setup
   ├── Map Categories to Grade Levels (e.g., Primary vs. High School)
   └── Define Assessment Periods & Locking Deadlines
           ↓
3. Continuous Assessment
   ├── Teachers score students via Ratings Grid
   ├── Add qualitative comments via Remarks Tab
   └── Log real-time Incidents, Witnesses, & Interventions
           ↓
4. Quality & Review
   └── Submit assessments to Review Queue for Approval & Locking
           ↓
5. Analytics & Reporting
   ├── View real-time trend charts in the Dashboard
   └── Generate Student Report Cards and comparative Class Analysis
```

---

## Document Index

| File | Section | Screen / Tab | Description |
|------|---------|--------------|-------------|
| [01-Dashboard.md](./01-Dashboard.md) | Dashboard | Dashboard | High-level analytics and summary charts |
| [02-Rating-Scales.md](./02-Rating-Scales.md) | Masters | Rating Scales | Configuration of scales and levels |
| [03-Categories.md](./03-Categories.md) | Masters | Categories | Categories and criteria master records |
| [04-Interventions.md](./04-Interventions.md) | Masters | Interventions | Core list of supportive/corrective actions |
| [05-Class-Mapping.md](./05-Class-Mapping.md) | Setup | Class Mapping | Mapping categories to class levels |
| [06-Periods.md](./06-Periods.md) | Setup | Periods | Definition of evaluation periods |
| [07-Configuration.md](./07-Configuration.md) | Setup | Configuration | Setting active rating scales and thresholds |
| [08-My-Assessments.md](./08-My-Assessments.md) | Assessments | My Assessments | Teacher assessment tracking and search |
| [09-Ratings.md](./09-Ratings.md) | Assessments | Ratings | Numerical & level scoring per student-criteria |
| [10-Remarks.md](./10-Remarks.md) | Assessments | Remarks | Capturing student qualitative comments |
| [11-Review-Queue.md](./11-Review-Queue.md) | Assessments | Review Queue | Reviewing and approving assessment submissions |
| [12-Incident-Log.md](./12-Incident-Log.md) | Incidents | Incident Log | Registering and logging student behavior incidents |
| [13-Witnesses.md](./13-Witnesses.md) | Incidents | Witnesses | Associating witnesses to incidents |
| [14-Interventions-Applied.md](./14-Interventions-Applied.md) | Incidents | Interventions Applied | Associating interventions with incidents |
| [15-Reports-Hub.md](./15-Reports-Hub.md) | Reports | Reports Hub | central directory for reports |
| [16-Student-Scores-Report.md](./16-Student-Scores-Report.md) | Reports | Student Scores | Composite and average student scores report |
| [17-Category-Summary.md](./17-Category-Summary.md) | Reports | Category Summary | Aggregated score statistics by category |
| [18-Period-Report.md](./18-Period-Report.md) | Reports | Period Report | Progression of scores across multiple periods |
| [19-Audit-Trail.md](./19-Audit-Trail.md) | Reports | Audit Trail | Log of all modifications to scores & configs |
| [20-Student-Report.md](./20-Student-Report.md) | Standalone | Student Report | Comprehensive individual report card |
| [21-Class-Analysis.md](./21-Class-Analysis.md) | Standalone | Class Analysis | Multi-student comparative dashboard |
| [22-Period-Progress.md](./22-Period-Progress.md) | Standalone | Period Progress | Longitudinal progress tracking |
| [23-Category-Performance.md](./23-Category-Performance.md) | Standalone | Category Performance | Statistical analyses and variance in categories |
| [24-Incident-Report.md](./24-Incident-Report.md) | Standalone | Incident Report | Incident logs, frequencies, and outcomes |

---

## Schema & Data Tables Reference

### Internal Behavioural Assessment Tables

| Table | Description | Primary Key / Key Columns |
|-------|-------------|----------------------------|
| `ba_rating_scales` | Master scales for scoring. | `id`, `name`, `code`, `status` |
| `ba_rating_levels` | Individual grade steps within a scale. | `id`, `ba_rating_scale_id`, `name`, `numeric_score` |
| `ba_categories` | Groups of behavioural qualities. | `id`, `name`, `code`, `status` |
| `ba_criteria` | Specific measurable criteria. | `id`, `ba_category_id`, `name`, `max_score`, `status` |
| `ba_interventions` | Corrective actions list. | `id`, `name`, `type`, `description`, `status` |
| `ba_class_category_jnt` | Maps categories to school classes. | `ba_category_id`, `sch_class_id` |
| `ba_assessment_periods` | Date-bound grading terms. | `id`, `name`, `start_date`, `end_date`, `is_locked` |
| `ba_config` | Module configuration settings. | `id`, `ba_rating_scale_id`, `org_academic_session_id` |
| `ba_assessments` | Assessment status records per teacher/period. | `id`, `ba_assessment_period_id`, `sch_employee_id`, `status` |
| `ba_assessment_ratings` | Student scores for each criterion. | `id`, `ba_assessment_id`, `std_student_id`, `ba_criterion_id`, `score` |
| `ba_computed_scores` | Processed averages and summaries. | `id`, `std_student_id`, `ba_category_id`, `computed_avg` |
| `ba_student_remarks` | Qualitative comment records. | `id`, `ba_assessment_id`, `std_student_id`, `remarks` |
| `ba_incidents` | logged behavioral incidents. | `id`, `std_student_id`, `logged_by_employee_id`, `severity` |
| `ba_incident_witnesses_jnt` | Links witnesses to incidents. | `ba_incident_id`, `std_student_id` |
| `ba_incident_intervention_jnt` | Applied corrective actions to incidents. | `ba_incident_id`, `ba_intervention_id` |
| `ba_audit_log` | Tracking modifications to scores. | `id`, `action_taken`, `performed_by_user_id` |

### External Tables Used

- `std_students`: Student profile records.
- `std_student_academic_sessions`: Student enrollment details.
- `sch_employees`: Teacher and admin profiles.
- `sch_classes`: Class master list.
- `sch_sections`: Section master list.
- `org_academic_sessions`: Active school session calendar.
- `academic_terms`: Academic terms database.

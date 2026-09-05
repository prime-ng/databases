# Behavioural Assessment Module — Business Requirements Overview
================================================================

## Section-1 : Module Overview
==============================

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


## Section-2 : Dashboard
========================

## What This Screen Does

The Behavioural Assessment Dashboard provides a centralized, real-time analytics hub for school leaders, counsellors, and teachers. It consolidates qualitative scores, pending evaluation tasks, and logged incidents into visual summaries, helping staff monitor student development and address disciplinary or behavioral anomalies immediately.

The dashboard displays high-level metrics, such as total incidents logged this week, pending teacher assessments, top-performing student cohorts, and key warning signals (e.g., spike in severe behavioral infractions).

---

## When This Screen Is Used

- **Admin/Principal** opens the dashboard daily to monitor the overall behavioral climate of the school and track the progress of ongoing assessment periods.
- **School Counsellors** review the dashboard to identify students with a high frequency of negative incidents or severe infractions requiring therapeutic interventions.
- **Teachers** use the dashboard to check if they have pending behavioral grading tasks that need completion before the lock deadline.
- **HODs / Coordinators** check the dashboard to see the count of submitted assessments in their review queue.

---

## Key Widgets & Components

### 1. Key Performance Indicator (KPI) Cards
- **Active Assessment Period**: Name and remaining days of the current grading cycle.
- **Assessments Completed**: Percentage of sections whose assessments are locked.
- **Incidents Logged (This Week)**: Total incident count with an up/down arrow comparison against the previous week.
- **Active Interventions**: Number of students currently undergoing behavioral plans.

### 2. Analytical Charts
- **Incident Severity Distribution**: A donut chart showing the split of incidents by severity levels (Info, Low, Medium, High).
- **Incident Trend (Monthly)**: A line chart plotting Positive vs. Disciplinary incidents recorded week-by-week.
- **Category-wise Averages**: A bar chart displaying school-wide average scores across core behavioural categories (e.g., Collaboration, Cleanliness).

### 3. Actionable Lists & Alerts
- **Recent Severe Incidents**: A grid showing the latest incidents marked with 'High' severity, including student name, class, date, and description.
- **Pending Approvals Alert**: Direct link and count of submissions in the review queue.
- **Counsellor Alert List**: Automatically surfaces students who have accumulated more than three disciplinary infractions in the last 30 days.

---

## Business Rules and Conditions

**Role-Based Data Visibility**
- **Admins & Counsellors** see school-wide data.
- **Class Teachers** see aggregated metrics for their class/section only.
- **Subject Teachers** only see metrics corresponding to sections they teach.

**Interactive Drilldowns**
- Clicking on the "Pending Approvals" card redirects HODs directly to the [Review Queue](./11-Review-Queue.md).
- Clicking on a student’s name in any dashboard widget redirects to their individual [Student Report](./20-Student-Report.md).

**Dynamic Data Fetching**
- Dashboard metrics do not run heavy real-time queries across transactional grading tables on page load. Instead, it aggregates from `ba_computed_scores` and pre-summarized tables to guarantee page load speeds under 2 seconds.

---

## Workflow Steps

**Viewing Dashboard Metrics**
1. User logs in and navigates to the Behavioural Assessment module.
2. The system checks the user's role to determine scope (school-wide or section-level).
3. The dashboard renders widgets, loading charts asynchronously using cached aggregate scores.
4. If there is an active assessment period near its deadline, a red notification banner appears at the top.

**Drilling Down on Alerts**
1. HOD clicks on the "Pending Approvals" card showing `12 Sections Submitted`.
2. HOD is redirected to the [Review Queue](./11-Review-Queue.md) pre-filtered for those 12 sections.

---

## Example Scenario

At the start of November, the School Principal logs into the portal. The Behavioural Assessment Dashboard highlights:
- A red warning banner: `"Term 1 Assessment Period closes in 3 days. 8 sections still pending."`
- The KPI card shows: `Assessments Completed: 78%`
- The Incident Donut chart indicates a 15% increase in "High Severity" disputes.
- The Principal clicks on the `High Severity` slice, which filters the list of severe incidents below. They see two fights logged by different teachers. 
- The Principal clicks on the counsellor alert list to confirm if a counsellor intervention has been assigned to those students.

---

## Related Screens

- [00-Module-Overview.md](./00-Module-Overview.md) — Module purpose and complete schema.
- [06-Periods.md](./06-Periods.md) — Setting active periods and lock dates.
- [11-Review-Queue.md](./11-Review-Queue.md) — Viewing/approving pending entries.
- [12-Incident-Log.md](./12-Incident-Log.md) — Logging new behavioral incidents.

## Section-3 : Rating Scales — Business Requirements
====================================================

## What This Screen Does

The Rating Scales screen is the foundation for all behavioral grading in the module. It allows school administrators to configure the grading frameworks used to assess student behavior. Rather than teachers typing random grades, the system enforces selecting levels defined inside an active Rating Scale.

For example, a school might use an academic-grade style scale (A, B, C, D, E) or a descriptive-level style scale (Outstanding, Proficient, Developing, Emerging). Each level within a scale is linked to a numeric score value (e.g., A = 5, E = 1) to enable the system to calculate averages and aggregates behind the scenes.

---

## When This Screen Is Used

- **Academic Year Commencement**: Admin configures the master behavioral rating scale to be used across all classes for the new session.
- **Modifying Grading Rubrics**: Admin wants to adjust the wordings of levels (e.g., renaming "Unsatisfactory" to "Needs Support" to sound more encouraging).
- **Adding Custom Scales**: The school decides to apply a simpler 3-point scale for nursery/kindergarten students and a more detailed 5-point scale for high schoolers.
- **Deactivating a Scale**: A retired grading scale is turned off so teachers can no longer select it for new setups.

---

## Key Fields at a Glance

### Rating Scale (Header)
| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Scale Name** | String | Text Input | Yes | Must be unique. Max 100 characters. e.g., "5-Point Descriptive Scale" |
| **Scale Code** | Alphanumeric | Text Input | Yes | Unique, capitalized, short code. Max 10 chars. e.g., "STD_5_PT" |
| **Status** | Boolean | Toggle / Switch | Yes | Defaults to Active. |

### Rating Levels (Details / Grid Rows)
Multiple levels can be added under a single header.
| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Level Name** | String | Text Input | Yes | e.g., "Always", "Consistently", "Frequently", "Seldom", "Never" |
| **Numeric Score** | Integer / Float | Number Input | Yes | Unique within the scale. Used for computing averages. e.g., 5.0, 4.0, 3.0 |
| **Description** | String | Text Area | No | Tooltip context for teachers during grading. Max 250 chars. |

---

## Business Rules and Conditions

**Unique Numeric Scores & Names**
- No two levels inside the same Rating Scale can have the exact same level name or numeric score.

**Minimum & Maximum Levels**
- A Rating Scale must contain at least two levels (e.g., Yes/No) and can support a maximum of ten levels.

**Active Status Constraints**
- A Rating Scale can be deactivated only if it is NOT currently linked in the global [Configuration](./07-Configuration.md) or utilized in active [Assessment Periods](./06-Periods.md).
- Deactivating a scale does not delete historical records. Inactive scales are retained in database queries for past academic terms.

**Soft Delete Protection**
- Deleting a scale is blocked if any `ba_assessment_ratings` reference it. Admin can only toggle the status to Inactive.

---

## Workflow Steps

**Creating a New Rating Scale**
1. Admin navigates to **Masters -> Rating Scales** and clicks **Create New**.
2. Fills in the Scale Name and Scale Code.
3. Clicks **Add Row** under the Levels grid to define the levels.
4. Input details: Level Name: `Exemplary`, Numeric Score: `5`, Description: `Exceeds expectations in behaviour`.
5. Clicks **Add Row** again to add more levels.
6. The system verifies that numeric scores are in descending or ascending sequence (best practice) and that all required fields are filled.
7. Admin clicks **Save**. The records are successfully inserted into `ba_rating_scales` and `ba_rating_levels`.

**Deactivating a Scale**
1. Admin views the list of scales on the Rating Scales index.
2. Toggles the active status switch of an unused scale to "Inactive".
3. System checks for current usage. Since no active terms are linked, the state updates in the DB, and a success toast appears.

---

## Example Scenario

The primary school coordinator wants to establish a simple 3-point behavior scale. The admin creates the scale:
- **Scale Name**: Primary Behaviour Scale
- **Scale Code**: PRI_BEH_3
- **Levels**:
  1. *Consistently* (Numeric Score: 3, Description: "Shows the behavior at almost all times")
  2. *Sometimes* (Numeric Score: 2, Description: "Shows the behavior occasionally")
  3. *Rarely* (Numeric Score: 1, Description: "Struggles to show the behavior")

This scale is then selected in global [Configuration](./07-Configuration.md) for Class 1 to Class 5.

---

## Related Screens

- [03-Categories.md](./03-Categories.md) — Scoring categories that criteria will be evaluated against.
- [07-Configuration.md](./07-Configuration.md) — Linking classes/years to specific rating scales.
- [09-Ratings.md](./09-Ratings.md) — Core grid where teachers select these level options.

## Section-4 : # Categories and Criteria — Business Requirements
================================================================

## What This Screen Does

The Categories and Criteria screen allows school administrators to build the behavioral curriculum. Behaviour is evaluated based on concrete, structured criteria rather than abstract judgment. 

A **Category** represents a broad domain of personal development or conduct (e.g., "Social Skills," "Responsibility," "Health & Hygiene"). 

Under each Category, the school defines specific, measurable **Criteria** (e.g., under "Social Skills", the criteria might be "Collaborates effectively in groups" and "Respects diverse opinions"). During the assessment phase, teachers assign grades directly against these criteria.

---

## When This Screen Is Used

- **Configuring Assessment Framework**: Admin wants to define new areas of behavior to be assessed for students.
- **Adding Criteria**: A teacher requests an additional criterion under the "Ethics" category to track "Demonstrates honesty in academic tasks."
- **Deactivating Criteria**: The school decides to stop grading a specific criterion and flags it as Inactive.
- **Setting up Grade Weightages**: Customizing how criteria contribute to the overall category score.

---

## Key Fields at a Glance

### Behavioural Category (Header)
| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Category Name** | String | Text Input | Yes | Must be unique. Max 100 characters. e.g., "Personal Integrity" |
| **Category Code** | Alphanumeric | Text Input | Yes | Capitalized, unique code. Max 15 chars. e.g., "PERS_INTEG" |
| **Description** | String | Text Area | No | Explain what this behavioral category covers. |
| **Status** | Boolean | Toggle | Yes | Defaults to Active. |

### Behavioral Criteria (Details / Sub-Grid)
Each Category contains a nested grid to add one or more child criteria.
| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Criteria Name** | String | Text Input | Yes | Unique within the category. Max 150 chars. e.g., "Completes assignments on time" |
| **Criteria Code** | Alphanumeric | Text Input | Yes | Unique code. e.g., "HW_PUNCT" |
| **Max Score** | Decimal | Number Input | Yes | Defaults to 5.0. Configures the maximum numeric rating point. |
| **Weightage (%)** | Integer | Number Input | Yes | Sum of all active criteria weightages under one category must equal 100%. |
| **Status** | Boolean | Toggle | Yes | Active/Inactive. |

---

## Business Rules and Conditions

**Parent-Child Integrity**
- An active Category must have at least one active Criterion linked to it.
- If a Category is deactivated, all of its nested Criteria are automatically marked Inactive in grading screens, though their individual statuses in this master grid remain unchanged.

**Weightage Validation**
- If the school configures weighted grading, the system will enforce that the sum of the `Weightage (%)` of all active Criteria under a single Category is exactly `100` before allowing the record to save.

**Category Deactivation & Soft Deletes**
- A Category or Criterion cannot be deleted if there are any recorded marks in `ba_assessment_ratings` linked to them. Instead, the admin must switch the Status toggle to Inactive.
- Inactive Categories/Criteria are hidden from the [Class Mapping](./05-Class-Mapping.md) form and the [Ratings Grid](./09-Ratings.md).

---

## Workflow Steps

**Adding a Category and Criteria**
1. Admin navigates to **Masters -> Categories** and clicks **Add Category**.
2. Fills in the Category Name (e.g., "Digital Citizenship") and Category Code (e.g., "DIG_CIT").
3. In the nested table, clicks **Add Criterion**.
4. Enters Criteria Name: `Uses technology responsibly`, Code: `TECH_RESP`, Max Score: `5`, and Weightage: `50`.
5. Clicks **Add Criterion** again, enters Criteria Name: `Respects digital privacy`, Code: `TECH_PRIV`, Max Score: `5`, and Weightage: `50`.
6. Admin clicks **Save**. The system validates the 100% total weightage and writes the records to `ba_categories` and `ba_criteria`.

**Modifying Weightage**
1. Admin clicks on an existing category (e.g., "Social Skills").
2. Modifies the weightages of the 4 active criteria from `25% each` to `30%, 30%, 20%, 20%`.
3. System verifies the sum is 100% and updates the records.

---

## Example Scenario

An elite secondary school wants to assess "Emotional Intelligence." The admin adds a new Category:
- **Category Name**: Emotional Quotient
- **Category Code**: EQ_MASTER
- **Criteria Grid**:
  1. *Self-Regulation* (Code: EQ_SELF, Weight: 40%, Max Score: 5)
  2. *Empathy & Peer Support* (Code: EQ_EMP, Weight: 60%, Max Score: 5)

This structure is instantly available for teacher evaluations once class mappings are set.

---

## Related Screens

- [02-Rating-Scales.md](./02-Rating-Scales.md) — Scoring scales used to grade these criteria.
- [05-Class-Mapping.md](./05-Class-Mapping.md) — Linking these categories to specific grades.
- [09-Ratings.md](./09-Ratings.md) — Scoring interface showing active criteria.

## Section-5 : # Interventions — Business Requirements
======================================================

## What This Screen Does

The Interventions screen acts as a central repository for the school's standardized corrective, supportive, or restorative actions. When a student behaves exceptionally (either positively or negatively), the school does not just log the incident; they assign an **Intervention** to help guide or acknowledge the student.

Examples of negative interventions include "Principal Warning," "Parent-Teacher Counseling," "Restorative Service," or "Reflection Essay Assignment." Examples of positive interventions (reinforcements) include "Leadership Certificate Nomination," "Appreciation Badge," or "Roll of Honour recommendation."

Defining these interventions globally ensures that teachers and counselors use standardized administrative measures rather than defining ad-hoc actions.

---

## When This Screen Is Used

- **Policy Setup**: Admin configures the standard list of interventions approved by the school board.
- **Introducing Restorative Practices**: The school adds a new intervention type such as "Peer Mediation Sessions" to resolve student conflicts.
- **Updating Intervention Descriptions**: Updating standard procedures (e.g., specifying that a "Suspension Notice" must be signed by both HOD and Principal).
- **Retiring an Intervention**: An outdated disciplinary measure is deactivated.

---

## Key Fields at a Glance

| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Intervention Name** | String | Text Input | Yes | Must be unique. Max 100 characters. e.g., "Parent Counseling Session" |
| **Intervention Code**| Alphanumeric | Text Input | Yes | Unique capitalized code. e.g., "DISC_PARENT_COUNSEL" |
| **Intervention Type**| Dropdown | Select | Yes | Options: `Supportive` (Counselling, coaching), `Corrective` (Warning, suspension), `Reinforcement` (Award, recommendation) |
| **Description** | String | Text Area | Yes | Explains the protocol and expectations. Max 500 characters. |
| **Escalation Level** | Dropdown | Select | Yes | Options: `Level 1` (Teacher handled), `Level 2` (Counsellor/HOD), `Level 3` (Principal/Board) |
| **Status** | Boolean | Toggle | Yes | Active/Inactive. Defaults to Active. |

---

## Business Rules and Conditions

**Standardization Enforcement**
- Subject teachers can only view and select interventions during incident logging that match the incident's severity (e.g., a teacher cannot assign a Level 3 "Suspension" intervention directly; they can only suggest it or assign Level 1 interventions).

**Deactivation Protections**
- An intervention cannot be deactivated if it is linked to an open/active incident in `ba_incident_intervention_jnt`.
- Inactive interventions remain linked to historical incidents for record-keeping but are hidden from the dropdown menu on the [Interventions Applied](./14-Interventions-Applied.md) tab.

**Unique Code & Name**
- The system enforces unique combinations of Intervention Codes and Names to prevent administrative duplicate definitions.

---

## Workflow Steps

**Adding a New Intervention**
1. Admin navigates to **Masters -> Interventions** and clicks **Add Intervention**.
2. Fills in the Intervention Name (e.g., "Disciplinary Reflection Assignment") and Intervention Code (e.g., "DISC_REFLECT").
3. Selects Intervention Type as `Corrective`.
4. Selects Escalation Level as `Level 1`.
5. Enters Description: `"Student completes a structured worksheet reflecting on their behaviour, actions, and impact on peers. Checked by the homeroom teacher."`
6. Admin clicks **Save**. The record is successfully written to `ba_interventions`.

**Editing an Intervention**
1. Admin clicks **Edit** on "Suspension Notice".
2. Modifies the description to include: `"Requires a formal parent signature before the student is allowed back in class."`
3. Clicks **Save**. The description updates immediately across all active instances.

---

## Example Scenario

The school counsellor wants to standardize positive reinforcements. The admin registers a new intervention:
- **Intervention Name**: Star Student Badge
- **Intervention Code**: POS_STAR_BADGE
- **Intervention Type**: Reinforcement
- **Escalation Level**: Level 2 (Counsellor/HOD approved)
- **Description**: "Awarded to students exhibiting outstanding empathy and helping behavior. Highlighted during the weekly assembly."

This positive intervention is now ready to be selected in the [Interventions Applied](./14-Interventions-Applied.md) screen.

---

## Related Screens

- [12-Incident-Log.md](./12-Incident-Log.md) — Incidents where these interventions are mapped.
- [14-Interventions-Applied.md](./14-Interventions-Applied.md) — Screen where staff log and update the progress of assigned interventions.
- [24-Incident-Report.md](./24-Incident-Report.md) — Analytics summarizing intervention success rates.


## Section-6 : # Class Mapping — Business Requirements
======================================================

## What This Screen Does

The Class Mapping screen bridges the behavioral curriculum to specific grade levels. Not all student age groups should be evaluated on the same behavioral expectations. For instance, kindergarteners should be assessed on fundamental physical habits (e.g., "Maintains cleanliness," "Shares toys"), whereas senior high schoolers should be evaluated on mature cognitive and social standards (e.g., "Leadership initiative," "Digital Citizenship," "Critical Thinking").

Class Mapping allows administrators to select a Class (e.g., "Grade 1") and map specific **Behavioural Categories** to it. This dynamic link ensures that teachers grading a specific section only see the categories and criteria appropriate for that student age group.

---

## When This Screen Is Used

- **Academic Session Setup**: Admin links the behavioral categories to each class level at the beginning of the year.
- **Introducing a New Subject Area**: The school adds a "Community Service" category and maps it only to Grade 9 through Grade 12.
- **Excluding Non-Applicable Categories**: Admin removes the "Fine Motor Skills" behavioral category from Middle School classes as they transition to higher grades.

---

## Key Fields at a Glance

| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **School Class** | Integer (ID) | Dropdown / Select | Yes | References `sch_classes`. e.g., "Grade 6". |
| **Academic Session**| Integer (ID)| Dropdown / Read-only | Yes | References `org_academic_sessions`. Set to the active session. |
| **Select Categories**| Array (IDs) | Checkbox Grid / Multi-Select | Yes | Lists active categories from `ba_categories`. At least 1 must be selected. |

---

## Business Rules and Conditions

**No Blank Evaluations**
- Every class active in the current academic session must have at least one mapped category. The system will throw an validation error if an admin tries to save a class mapping with zero checked categories.

**Preservation of Existing Grades**
- If an admin unmaps a category from a class midway through an academic session, the system will perform an integrity check on `ba_assessment_ratings` for that class.
- If grades have already been entered for the category being unmapped, the action is **blocked**, and the admin is prompted: `"Cannot remove Category 'Social Skills' because teachers have already recorded ratings for this class."`

**Dynamic Form Rendering**
- The [Ratings Grid](./09-Ratings.md) automatically queries `ba_class_category_jnt` based on the selected student's class to determine which criteria to render. If no mapping is found, the grading form is disabled.

---

## Workflow Steps

**Mapping Categories to a Class**
1. Admin navigates to **Setup -> Class Mapping**.
2. Selects School Class: `Grade 9` from the dropdown list.
3. The checkbox grid shows all active behavioral categories.
4. Admin checks the boxes for:
   - `Emotional Intelligence`
   - `Personal Hygiene`
   - `Digital Citizenship`
   - `Leadership Skills`
5. Leaves `Motor Skills` unchecked.
6. Admin clicks **Save**. The system inserts the mappings into the joint table `ba_class_category_jnt`.

**Overriding Mappings**
1. Admin opens `Grade 9` mapping.
2. Unchecks `Personal Hygiene` (determining that high schoolers no longer need this tracked).
3. The system checks `ba_assessment_ratings`. Since it is a new academic year and no grades have been inputted, the system permits the update.
4. Clicks **Save**. The obsolete joint rows are deleted, and new mappings persist.

---

## Example Scenario

A school has a separate Preschool wing and High School wing. The admin configures Class Mappings:
- **Class**: `LKG (Lower Kindergarten)`
  - *Mapped Categories*: Basic Hygiene, Motor Skills, Sharing & Cooperation.
- **Class**: `Grade 10`
  - *Mapped Categories*: Leadership & Initiative, Analytical Mindset, digital Ethics, Peer Collaboration.

When the Grade 10 homeroom teacher opens the grading portal, they are only presented with advanced rubrics, while the kindergarten teacher receives developmental rubrics.

---

## Related Screens

- [03-Categories.md](./03-Categories.md) — Master categories that are selected in this mapping form.
- [07-Configuration.md](./07-Configuration.md) — Setting up global modules parameters.
- [09-Ratings.md](./09-Ratings.md) — Grade grid that dynamically adjusts based on these mappings.


## Section-7 : # Assessment Periods — Business Requirements
===========================================================

## What This Screen Does

The Assessment Periods screen allows schools to define the calendar schedule for behavioral evaluations. Similar to academic exams, behavioral assessments are conducted in structured cycles—either Monthly (e.g., "September 2026 Evaluation"), Term-wise (e.g., "Term 1 Behavioral Review"), or Annual.

This screen defines the start and end dates for each period, and more importantly, establishes a **Lock Date / Submission Deadline**. Once the lock date passes, the system automatically locks the evaluation data, blocking teachers from making further changes to protect grade integrity before reports are generated.

---

## When This Screen Is Used

- **Academic Calendar Planning**: Admin registers all behavioral assessment periods for the entire academic year.
- **Extending Grading Deadlines**: Teachers request more time, and the admin edits the Lock Date for the current period to grant a 2-day extension.
- **Locking a Period Manually**: A period has finished, HODs have approved all scores, and the admin manually flags the period as Locked to freeze the database.
- **Reviewing Historic Periods**: Checking start/end dates of previous terms for audit purposes.

---

## Key Fields at a Glance

| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Period Name** | String | Text Input | Yes | Unique name. Max 100 characters. e.g., "Term 1 Behavioral Review" |
| **Academic Session**| Integer (ID) | Dropdown | Yes | References `org_academic_sessions`. |
| **Start Date** | Date | Date Picker | Yes | Must be within the academic session calendar. |
| **End Date** | Date | Date Picker | Yes | Must be after or equal to the Start Date. |
| **Lock Date** | Date | Date Picker | Yes | Deadline for grading. Must be equal to or after the End Date. |
| **Is Locked** | Boolean | Toggle | Yes | Defaults to False (Open). If True, all database inserts and edits to ratings for this period are blocked. |

---

## Business Rules and Conditions

**Chronological Non-Overlapping Rule**
- No two active assessment periods under the same academic session can have overlapping date ranges. The system will throw an error if a newly proposed period starts before the previous one ends.

**The Absolute Lock Rule**
- Once a period is flagged as **Locked** (`is_locked = true`):
  - Teachers cannot enter or edit grades in [Ratings](./09-Ratings.md) or [Remarks](./10-Remarks.md).
  - Coordinators/HODs cannot modify entries in the [Review Queue](./11-Review-Queue.md).
  - All API endpoints for saving marks verify `is_locked` and reject requests with a `403 Forbidden` response.
- Only the Admin can toggle `Is Locked` back to False to temporary open the period for emergency corrections.

**Delete Restrictions**
- An assessment period cannot be deleted if there are any records in `ba_assessments` or `ba_computed_scores` pointing to its ID. It can only be locked/deactivated.

---

## Workflow Steps

**Creating a New Assessment Period**
1. Admin navigates to **Setup -> Periods** and clicks **Add Period**.
2. Fills in the Period Name: `"Term 2 Assessment"`.
3. Selects Academic Session: `"2026-2027 Academic Session"`.
4. Sets Start Date: `2026-11-01` and End Date: `2027-01-31`.
5. Sets Lock Date: `2027-02-05` (giving teachers 5 days after the term ends to finish grading).
6. Admin clicks **Save**. The system validates no date conflicts and writes the record to `ba_assessment_periods`.

**Extending a Deadline**
1. Admin opens the edit screen for `"Term 2 Assessment"`.
2. Changes the Lock Date from `2027-02-05` to `2027-02-08`.
3. Clicks **Save**. Teachers immediately gain access to input scores for an extra three days.

**Manual Locking**
1. Admin views the periods list.
2. Toggles the `Is Locked` switch for `"Term 2 Assessment"` to True.
3. System prompts: `"Are you sure you want to lock this period? This will freeze all evaluations."`
4. Admin confirms. The database state updates, preventing any future edits.

---

## Example Scenario

The school operates on a quarterly assessment cycle. The admin registers:
- **Period**: Q1 Behavioural Assessment (Start: June 1, End: Aug 31, Lock Date: Sept 5)
- **Period**: Q2 Behavioural Assessment (Start: Sept 1, End: Nov 30, Lock Date: Dec 5)

On September 6th, a teacher attempts to edit a student's Q1 score. The page loads in read-only mode, displaying a banner: `"This assessment period was locked on Sept 5, 2026."`

---

## Related Screens

- [07-Configuration.md](./07-Configuration.md) — Linking classes to default configurations.
- [09-Ratings.md](./09-Ratings.md) — Core grid where teachers score within active periods.
- [11-Review-Queue.md](./11-Review-Queue.md) — Queue where submitted scores are locked at the deadline.


## Section-8 : # Configuration — Business Requirements
======================================================

## What This Screen Does

The Configuration screen allows administrators to manage global parameters and system rules for the entire Behavioural Assessment module. This panel controls the core logical behavior of the module, ensuring that the system enforces school-wide grading policies automatically.

This screen is where the admin binds a specific [Rating Scale](./02-Rating-Scales.md) as the default for the active Academic Session, determines whether teacher-submitted scores require an approval workflow, and establishes automated thresholds for behavioral alerts.

---

## When This Screen Is Used

- **Academic Session Initialization**: The admin selects the active school session and links the behavioral rules to it.
- **Switching Grading Models**: The school board decides that teachers no longer need HOD approval for minor behavioral marks, and the admin toggles off the "Approval Workflow Required" setting.
- **Configuring Automated Disciplinary Triggers**: The admin updates the system rules so that any student reaching 3 high-severity incidents automatically triggers a counsellor alert email.

---

## Key Fields at a Glance

| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Academic Session** | Integer (ID) | Read-only / Dropdown | Yes | References `org_academic_sessions`. |
| **Active Rating Scale** | Integer (ID) | Dropdown / Select | Yes | References `ba_rating_scales`. Sets the scoring standard school-wide. |
| **Approval Workflow** | Boolean | Toggle / Switch | Yes | If True, teacher grades must be reviewed in the [Review Queue](./11-Review-Queue.md) before publishing. |
| **Incident Escalation Threshold** | Integer | Number Input | Yes | Count of negative incidents that automatically flags a student for counsellor attention. Default is `3`. |
| **Notification Settings** | Checkbox Group | Multi-select checkbox | No | Options: `Email HOD on Submission`, `Email Parents on Severe Incident`, `Daily Digest to Principal`. |

---

## Business Rules and Conditions

**Scale Integrity Constraint**
- Once a Rating Scale is active and teachers have entered *even a single rating* in `ba_assessment_ratings` for the current academic session, the **Active Rating Scale** dropdown is locked and cannot be changed. This prevents catastrophic database corruption where scores mapped to 5-point scales are suddenly evaluated under a 3-point scale.

**Global Approval Flow**
- If **Approval Workflow** is enabled:
  - Teacher submissions go to the `PENDING` status.
  - Grades are not visible in [Student Reports](./20-Student-Report.md) or final analytics until the HOD locks and changes the status to `APPROVED`.
- If disabled:
  - Teacher submission directly saves as `APPROVED` and publishes immediately.

**Multi-Tenant Validation**
- All configuration settings are securely restricted to the current school (tenant) inside `ba_config` and cannot affect other schools on the same server database.

---

## Workflow Steps

**Configuring Global Parameters**
1. Admin navigates to **Setup -> Configuration**.
2. The active academic session is pre-filled: `2026-2027 Academic Session`.
3. Selects **Active Rating Scale**: `Standard 5-Point Scale`.
4. Enables the **Approval Workflow** toggle.
5. Sets **Incident Escalation Threshold** to `3`.
6. Checks **Email Parents on Severe Incident** in Notification Settings.
7. Admin clicks **Save**. The system inserts or updates the record in `ba_config` and logs the action in the audit trail.

**Mid-Session Modification (Protected)**
1. Admin attempts to change **Active Rating Scale** from `Standard 5-Point Scale` to `Primary Behaviour Scale`.
2. System queries `ba_assessment_ratings`.
3. The query returns 150 student ratings already submitted.
4. The system disables the dropdown and renders a warning message: `"Active Rating Scale cannot be modified because behavioral grades have already been recorded. Create a new academic session mapping instead."`

---

## Example Scenario

At the start of the year, the admin configures:
- **Rating Scale**: Standard A-E Scale
- **Approval Workflow**: Enabled
- **Incident Escalation Threshold**: 3 Incidents

In October, Student Ajay gets logged for 3 separate minor class disruptions. On the third incident log entry, the system checks `ba_config`, matches the threshold of 3, and automatically triggers an email notification to the High School Counsellor for immediate guidance mapping.

---

## Related Screens

- [02-Rating-Scales.md](./02-Rating-Scales.md) — The grading scales linked in this configuration panel.
- [11-Review-Queue.md](./11-Review-Queue.md) — Screen that executes the HOD approval workflow if toggled on here.
- [12-Incident-Log.md](./12-Incident-Log.md) — Screen that tracks infractions against the escalation thresholds.


## Section-9 : # My Assessments — Business Requirements
=======================================================

## What This Screen Does

The My Assessments screen serves as the primary workspace and dashboard for teachers. This portal aggregates all classes, sections, and behavioral evaluation periods assigned to the logged-in teacher for the active academic session.

Instead of navigating complex menus, a teacher can open this screen to instantly see a list of their assigned cohorts, the progress of their assessments (e.g., `"Not Started,"` `"Draft (12/25 Graded),"` `"Submitted,"` or `"Approved"`), the remaining days before the submission deadline, and quick links to open the grading sheets.

---

## When This Screen Is Used

- **Daily Grading**: A teacher opens this screen to resume scoring their class.
- **Checking Deadlines**: Teachers use this list to see which assessment terms are closing soon.
- **Submitting Scores**: Once all student marks and qualitative remarks are entered, the teacher triggers the submission approval workflow from this screen.
- **Viewing Approved Scores**: Reviewing historical grades that have already been finalized and locked by HODs.

---

## Key Columns & Fields

The core of this screen is a search filter bar followed by a detailed data grid of assigned classes.

### Filter Options
- **Assessment Period**: Dropdown filter to switch between terms (defaults to current active period).
- **Class / Grade**: Filter to narrow down search to specific classes.

### Assigned Classes Data Grid
For each assigned class-section, the grid displays:
| Field Name | Source Table | Description |
|------------|--------------|-------------|
| **Class & Section** | `sch_classes`, `sch_sections` | The class and section assigned to the teacher (e.g., "Class 8-A"). |
| **Assessment Period**| `ba_assessment_periods` | The current evaluation period (e.g., "Term 1"). |
| **Progress Status** | `ba_assessments` | Status of grading: `Not Started` (No scores saved), `Draft` (Some scores saved), `Submitted` (Pending HOD review), or `Approved` (Locked & Published). |
| **Completion Rate** | Calculated | Displays progress visually (e.g., a progress bar showing "15 / 30 Students Evaluated"). |
| **Lock Date** | `ba_assessment_periods` | The deadline for submission. Displays warning icons if under 48 hours remaining. |
| **Action** | Action Trigger | Dynamic button based on status: **"Start Grading"** (if Not Started), **"Edit Ratings"** (if Draft), or **"View Summary"** (if Submitted or Approved). |

---

## Business Rules and Conditions

**Strict Teacher Partitioning**
- Teachers can *only* see class-sections where they are officially registered as the Class Teacher or Subject Teacher in the school's central employee mapping (`sch_employees` & `sch_class_section_jnt`). They cannot see or edit assessments for other sections.

**Dynamic Status Transitions**
- **Draft** status triggers automatically as soon as a teacher saves the first numeric score in `ba_assessment_ratings`.
- **Submit Button Activation**: The "Submit to HOD" action button becomes clickable *only* when the Completion Rate is exactly 100% (i.e. every active student in the section has received a score for every mapped criterion and a qualitative remark).
- **Post-Submission Freeze**: As soon as the teacher clicks "Submit to HOD," the progress status changes to `Submitted`, the edit option is disabled, and the grid becomes read-only.

---

## Workflow Steps

**Resuming a Draft Grading Sheet**
1. Teacher logs in and opens **Assessments -> My Assessments**.
2. The screen automatically filters for the current active period (`Term 1`) and the teacher's assigned section (`Class 8-A`).
3. The progress status shows `Draft (18/30 Graded)`.
4. Teacher clicks **Edit Ratings**.
5. The system redirects them to the [Ratings Grid](./09-Ratings.md) with active student lists.

**Submitting a Completed Section**
1. Teacher completes grading all 30 students. The progress bar displays `30 / 30 Completed (100%)`.
2. The status is still `Draft`. A green **Submit to Coordinator** button appears in the action column.
3. Teacher clicks the button.
4. The system updates `status` in `ba_assessments` to `Submitted` and logs the submission time.
5. The action column changes to **"View Summary"** (read-only mode), and a notification is sent to the section coordinator's queue.

---

## Example Scenario

Mrs. Priya teaches Science to Grade 7-B and 7-C. At the end of September, she opens **My Assessments**:
- Row 1: `Grade 7-B — Sept Evaluation` — Status: `Submitted` (Locked, Mrs. Priya is waiting for HOD approval).
- Row 2: `Grade 7-C — Sept Evaluation` — Status: `Draft (20/28 Graded)` — MRS. Priya clicks `Edit Ratings` to input scores for the remaining 8 students.

---

## Related Screens

- [06-Periods.md](./06-Periods.md) — The assessment calendars showing deadlines.
- [09-Ratings.md](./09-Ratings.md) — The grading grid opened by clicking "Edit Ratings".
- [10-Remarks.md](./10-Remarks.md) — Screen where teachers write student narratives before submitting.
- [11-Review-Queue.md](./11-Review-Queue.md) — The supervisor screen where Mrs. Priya’s submissions are reviewed.


## Section-10 : # Ratings Grid — Business Requirements
======================================================

## What This Screen Does

The Ratings Grid is the core data-entry screen where teachers score student behavior. It presents a spreadsheet-like matrix layout. The rows list all active students within the selected class and section, while the columns display the specific behavioral criteria mapped to that class level.

In each intersection cell, the teacher selects a grade level (e.g., A, B, C, D, E) or a numeric point from a dropdown or button group. The UI is designed for rapid entry, featuring complete keyboard navigation, status markers, and an automated background autosave system to guarantee no data loss.

---

## When This Screen Is Used

- **End-of-Term Evaluations**: Homeroom teachers open the grid to fill out ratings for all 30+ students across various behavioral criteria.
- **Continuous Grading**: Subject teachers update ratings for students over the course of a week as they observe class interactions.
- **Data Editing**: Modifying draft ratings based on updated observations before final submission.

---

## Key Fields & Grid Layout

### Header Filters (Locked when opened from "My Assessments")
- **Class & Section**: Read-only labels or selects.
- **Assessment Period**: The term active for grading.
- **Rating Scale Reference**: Information banner showing which grading scale is currently being enforced (e.g., `"Rating Scale: 5-Point Descriptive Scale"`).

### Dynamic Ratings Matrix
- **Row Header**: Student list showing Student Photo, Roll Number, and Name.
- **Columns**: Dynamic criteria headers (e.g., "Respects Peers," "Punctuality," "Organization"). Hovering over a header displays the criterion's full description.
- **Intersection Cells**: Selection dropdowns. The options listed are the `Level Names` from `ba_rating_levels` (e.g., *Always*, *Sometimes*, *Never*).
- **Row Summary Column**: **"Computed Average"** — A calculated cell showing the student's rolling average score in real-time as cells are populated.

---

## Business Rules and Conditions

**Dynamic Column Generation**
- The system queries `ba_class_category_jnt` for the class ID to fetch all mapped categories. It then queries `ba_criteria` to extract all active criteria. These criteria represent the columns of the grid. 

**Autosave Mechanics**
- To prevent loss of data from session timeouts or network drops, changing a dropdown cell value immediately triggers an asynchronous AJAX `POST` request to `save-rating`.
- A small green indicator at the top right flips from `"Saving..."` to `"All Changes Saved in Cloud"` to assure the teacher.

**Formula Calculations**
- When a level is selected, the system retrieves its `numeric_score` from `ba_rating_levels`.
- **Computed Average Formula**: Sum of (Criterion Numeric Score × Criterion Weightage) divided by 100.
- The average recalculates instantly on the client side using JavaScript, then persists to `ba_computed_scores` upon background save.

**Lock Constraints**
- If the corresponding `ba_assessments` record is in `Submitted` or `Approved` status, or the `ba_assessment_periods` lock date has passed, the entire grid disables. All dropdowns turn read-only, and the save endpoints reject requests.

---

## Workflow Steps

**Grading a Cohort**
1. Teacher clicks **Edit Ratings** on Mrs. Priya’s [My Assessments](./08-My-Assessments.md) dashboard.
2. The Ratings Grid loads. The columns render: `Respects Peers`, `Academic Honesty`, and `Punctuality`.
3. Teacher uses keyboard Arrow keys to navigate down to Roll Number 1: **Amit Sharma**.
4. In `Respects Peers`, Mrs. Priya hits `Enter`, selects **Consistently** (Value: 4.0), and hits `Tab`.
5. The cell background highlights in light green, the `"Saving..."` message flashes, and Amit’s rolling average updates to `4.0`.
6. Mrs. Priya tabs to `Academic Honesty`, selects **Exemplary** (Value: 5.0). Average instantly updates to `4.5`.
7. Mrs. Priya completes all rows. Once done, she clicks **Proceed to Remarks** to write narratives.

---

## Example Scenario

Teacher Mr. Khan is grading Class 10-A on "Team Collaboration" (Weight 50%) and "Conflict Resolution" (Weight 50%) under a standard 5-point scale:
- Student John receives **Exemplary** (5 points) in Collaboration and **Satisfactory** (3 points) in Conflict Resolution.
- John's computed average cell instantly displays: `(5 × 0.5) + (3 × 0.5) = 4.00`.
- The database writes John's individual scores to `ba_assessment_ratings` and his average `4.0` to `ba_computed_scores`.

---

## Related Screens

- [02-Rating-Scales.md](./02-Rating-Scales.md) — The scoring standards that fill the cells.
- [08-My-Assessments.md](./08-My-Assessments.md) — The launchpad dashboard.
- [10-Remarks.md](./10-Remarks.md) — Writing corresponding student narratives.
- [20-Student-Report.md](./20-Student-Report.md) — The final report card where these ratings display.


## Section-11 : # Student Remarks — Business Requirements
=========================================================

## What This Screen Does

The Student Remarks screen allows teachers to enter qualitative narratives to accompany numerical scores. While numbers and averages show general performance trends, qualitative statements offer essential nuance, giving parents specific context on their child's classroom conduct, emotional growth, and areas requiring corrective guidance.

The screen provides a list of all students in the cohort, with a large, descriptive text box next to each name. To assist teachers in writing professional and constructive comments quickly, the UI includes a **Comment Bank / Predefined Templates** panel that allows them to insert standard phrases with a single click.

---

## When This Screen Is Used

- **Finalizing Assessment Cycles**: After completing the [Ratings Grid](./09-Ratings.md), teachers write behavioral summaries for each student before submitting the term data.
- **Mid-term Progress Notes**: Class teachers input developmental recommendations for students struggling with behavior.
- **Reporting Updates**: Modifying and correcting written remarks based on coordinator feedback.

---

## Key Fields & UI Layout

### Header Information
- Displays Class, Section, and active Assessment Period.

### Remarks Entry Table
- **Student Profile**: Student Photo, Roll Number, and Name.
- **Numeric Summary**: A read-only badge showing the student's computed average score from the [Ratings Grid](./09-Ratings.md) (e.g., `4.5 / 5.0`). This helps the teacher write remarks that match the numerical scoring.
- **Remarks Text Area**: Standard text entry field.
  - *Character Counter*: Visual indicator showing current count (e.g., `120 / 500 characters`). Enforces a minimum of 30 characters.
- **Comment Bank Helper Button**: A wizard button next to each text area that pops open a side panel containing standardized, categorised comments (e.g., Categories: *Collaboration Positive*, *Discipline Corrective*, *Leadership Praise*).

---

## Business Rules and Conditions

**Minimum Word Count & Validation**
- To prevent teachers from writing generic or single-word comments (e.g., "Good," "Nice"), the system enforces a **minimum length of 30 characters** and a **maximum of 500 characters**.
- The "Submit" button on [My Assessments](./08-My-Assessments.md) remains locked until every student has an approved, non-empty remark that passes the validation threshold.

**Autosave Mechanics**
- Similar to ratings, the text boxes feature a debounced autosave. When the teacher stops typing for more than `1.5 seconds`, or shifts focus away from the text area (`blur` event), the remarks are written to `ba_student_remarks` in the background.

**Safety Filters**
- The system includes a basic profanity/inappropriate language filter. If a teacher enters restricted terms, the input outlines in red, and the system prompts them to rephrase before saving.

---

## Workflow Steps

**Writing a Narrative Comment**
1. Teacher clicks **Proceed to Remarks** after completing the [Ratings Grid](./09-Ratings.md).
2. The list of students loads. MRS. Priya starts with student **John Doe** (rolling average is `2.3` - representing some behavior struggles).
3. Mrs. Priya clicks the **Comment Bank** helper icon.
4. Selects category: `Needs Support -> Focus & Distraction`.
5. Selects template: `"{Student} frequently struggles to maintain focus during independent tasks but responds well to quiet redirections."`
6. The system inserts the template, replacing `{Student}` with `John`.
7. Mrs. Priya appends custom details: `"He showed slight improvement in the final week of November."`
8. The character counter reads `135 / 500`. 
9. She clicks `Tab` to go to the next row. The system autosaves John's narrative.

---

## Example Scenario

Mrs. Priya is writing a remark for Amit Sharma (Average `4.9`):
- Entered text: `"Amit is a natural leader who constantly helps his peers during lab activities. His positive attitude is an asset to Class 8-A."`
- Character count: 125 characters. Validation: Passed.
- Database records the text under `remarks` in the `ba_student_remarks` table.

---

## Related Screens

- [08-My-Assessments.md](./08-My-Assessments.md) — The parent submission dashboard.
- [09-Ratings.md](./09-Ratings.md) — Grid displaying the numeric scores Mrs. Priya references.
- [20-Student-Report.md](./20-Student-Report.md) — The standalone report card where these paragraphs are printed.


## Section-12 : # Review Queue — Business Requirements
======================================================

## What This Screen Does

The Review Queue is the primary workspace for academic coordinators, section heads, and HODs. When teachers submit behavioral evaluations from their [My Assessments](./08-My-Assessments.md) dashboard, the records enter the Review Queue rather than publishing immediately. 

This portal acts as a quality control gateway. Supervisors review teachers' grades and qualitative remarks to verify consistency, professional language, and objective grading standards. From this screen, coordinators can either **Approve & Lock** a section's grades or **Send Back with Feedback** to a teacher for corrections.

---

## When This Screen Is Used

- **End of Term Audits**: After teachers complete their grades, the coordinator opens the queue to inspect and sign off on submissions.
- **Validating Remarks**: A coordinator scans student narratives to ensure no emotional or inappropriate language was recorded.
- **Handling Grade Corrections**: Returning a grading sheet to a teacher who accidentally gave a student incorrect marks.

---

## Key Fields & Screen Layout

### Pending Submissions Queue (Index Grid)
The main screen lists all sections awaiting approval:
| Field Name | Source Table | Description |
|------------|--------------|-------------|
| **Class & Section** | `sch_classes`, `sch_sections` | The student cohort (e.g., "Class 10-B"). |
| **Teacher Name** | `sch_employees` | The name of the teacher who submitted the grades. |
| **Period** | `ba_assessment_periods` | The grading period (e.g., "Term 1"). |
| **Submitted Date** | `ba_assessments` | The timestamp when the teacher clicked submit. |
| **Status Badge** | `ba_assessments` | Visual indicator: `Pending Review` (Yellow). |
| **Actions** | Interactive Buttons | **"Review Sheet"** opens the modal; **"Quick Approve"** signs off without detailing. |

### Detailed Review Modal / View Sheet Panel
Clicking "Review Sheet" opens a side-drawer or full-screen view of the teacher's grading matrix:
- Displays a read-only list of all students with their numeric criteria grades and written remarks.
- **HOD Feedback Box**: A text field to record internal feedback if returning the sheet.
- **Action Footer**:
  - **"Approve & Lock"** (Green Button)
  - **"Send Back for Correction"** (Red Button)

---

## Business Rules and Conditions

**Approval Workflow Constraint**
- The HOD approval logic is globally controlled via the [Configuration](./07-Configuration.md) panel. If approval is disabled, this queue is hidden, and teacher submissions bypass this screen.

**Approved State Freeze**
- Clicking **Approve & Lock**:
  - Transitions `status` in `ba_assessments` to `Approved`.
  - Disables the "Send Back" option permanently.
  - Automatically pushes finalized averages to the student academic records, making them visible on the parent portal and in [Student Reports](./20-Student-Report.md).

**Send Back Loop**
- Clicking **Send Back for Correction**:
  - Transitions `status` back to `Draft`.
  - Copies the HOD’s feedback message into a notification table.
  - Automatically unlocks the grading grid on the teacher's [My Assessments](./08-My-Assessments.md) dashboard, flagging it with a red `"Correction Required"` alert.

---

## Workflow Steps

**Approving a Submission**
1. Coordinator logs in and navigates to **Assessments -> Review Queue**.
2. Sees 3 sections pending. Clicks **Review Sheet** next to `"Grade 8-A — Mrs. Priya"`.
3. Modal displays. The coordinator reviews rolls 1 to 30. All criteria ratings are balanced and Amit’s remarks are professional.
4. Coordinator clicks **Approve & Lock**.
5. System displays a confirmation: `"Approved scores will be instantly visible to parents and locked. Proceed?"`
6. Coordinator clicks **Confirm**. The status updates to `Approved`, the row disappears from the queue, and the database freezes.

**Returning a Submission**
1. Coordinator opens `"Grade 8-B — Mr. Roy"`.
2. Scans remarks. Sees roll 12 has a generic remark: `"Good student"`. This violates the 30-character rule.
3. In the Feedback Box, the coordinator writes: `"Please expand on the remarks for Amit (Roll 12) to describe his interpersonal skills in class."`
4. Clicks **Send Back for Correction**.
5. System resets `ba_assessments.status` to `Draft` and logs the feedback.
6. The class unlocks for Mr. Roy to edit.

---

## Example Scenario

High School Coordinator Mr. Jacob opens the queue. Mrs. Priya's submission for 8-A has been sitting in `Pending` since yesterday. Mr. Jacob reviews the sheet. He finds a student rated 1.0 (Low) in Collaboration, but the remark says `"Excellent student."` This is a contradiction. Jacob writes: `"The remark contradicts the low collaboration rating. Please review."` and clicks `Send Back`. Mrs. Priya receives an automated alert and fixes it.

---

## Related Screens

- [07-Configuration.md](./07-Configuration.md) — Controls whether this queue is active.
- [08-My-Assessments.md](./08-My-Assessments.md) — The teacher portal affected by HOD approvals/returns.
- [09-Ratings.md](./09-Ratings.md) / [10-Remarks.md](./10-Remarks.md) — The sheets audited inside this queue.


## Section-13 : # Incident Log — Business Requirements
======================================================

## What This Screen Does

The Incident Log screen enables real-time tracking of behavioral events. While periodic term assessments reflect overall development, the Incident Log captures specific, concrete actions—both exceptional positive accomplishments (e.g., "Assisted a classmate during a medical emergency," "Won national debate championship") and critical disciplinary infractions (e.g., "Cheated during a math exam," "Aggressive conflict during recess").

By logging these events immediately, the school maintains an objective, verifiable log of critical events that directly influence parental discussions, counsellor meetings, and student report card comments.

---

## When This Screen Is Used

- **Immediate Infractions**: A teacher catches a student copying answers during an exam and registers the event.
- **Positive Milestones**: A teacher logs a student’s exemplary leadership during a school festival.
- **Consulting Records**: A counsellor reviews a student's history of incidents before a scheduled meeting.
- **Parent Meetings**: Class teachers open the incident history list to show parents evidence of repeated classroom disruption.

---

## Key Fields & Log Form

The main page contains an **"Add Incident"** form button and a list of previously recorded incidents with advanced search and filters.

### Log New Incident Form
| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Student** | Integer (ID) | Autocomplete Search | Yes | Search by Name/Admission Number. Ref: `std_students`. |
| **Incident Type** | String | Radio Group | Yes | Options: `Positive (Achievement)` or `Negative (Infraction)`. |
| **Category** | Integer (ID) | Dropdown | Yes | Filters active categories from `ba_categories`. |
| **Severity** | String | Dropdown / Select | Yes | Options: `Info` (Minor), `Low` (Warning), `Medium` (Escalate), `High` (Critical). |
| **Incident Date** | Date / Time | Date-Time Picker | Yes | Defaults to current date-time. Cannot be a future date. |
| **Description** | String | Text Area | Yes | Plain description of the event. Min 20, Max 1000 characters. |
| **Logged By** | Integer (ID) | Read-only Text | Yes | Defaults to current user ID from `sch_employees`. |

---

## Business Rules and Conditions

**Real-Time Logging Rule**
- Incidents can only be logged within a **maximum of 7 days** from the event occurrence date. The system prevents choosing dates older than 7 days to maintain reporting accuracy and avoid delayed disciplinary processing.

**Automated Email Warnings (High Severity)**
- When an incident is saved with `Severity = 'High'`:
  - An email alert is instantly dispatched to the student's Homeroom Teacher, Section HOD, and the School Principal.
  - If parent email notification is checked in [Configuration](./07-Configuration.md), the system auto-generates a standardized email detailing the event.

**Incident Type Visual Formatting**
- In lists and timelines, Positive incidents are highlighted in light emerald green with a star icon. Disciplinary incidents are highlighted in light rose/amber with an exclamation triangle icon.

---

## Workflow Steps

**Logging a Disciplinary Incident**
1. Teacher clicks **Log Incident** on the Incident Log tab.
2. Type student's name: `Amit Sharma`. Autocomplete lists matching records; MRS. Priya selects Amit (Class 8-A, Admission #12345).
3. Selects Incident Type: `Negative (Infraction)`.
4. Selects Category: `Peer Relations`.
5. Selects Severity: `Medium`.
6. Enters Description: `"Amit was repeatedly shouting and disrupting other students during group project work. He refused to quiet down when asked multiple times."`
7. Teacher clicks **Submit**. 
8. The system creates the incident record in `ba_incidents`, logs the author, and displays a success toast.
9. Mrs. Priya is prompted: `"Do you want to add witnesses to this incident?"` Clicking Yes opens the [Witnesses](./13-Witnesses.md) sub-tab.

---

## Example Scenario

During Chemistry lab, John is caught playing on his mobile phone and breaking a beaker. Teacher Mr. Roy logs:
- **Student**: John Doe (Grade 10)
- **Incident Type**: Negative
- **Category**: Responsibility & Care of Equipment
- **Severity**: Low (Requires Warning)
- **Description**: "John was using his personal mobile phone during experiments and accidentally knocked over a beaker, shattering it."
- **Logged By**: Mr. Roy

The record immediately updates John's student timeline and is flagged on the [Dashboard](./01-Dashboard.md).

---

## Related Screens

- [03-Categories.md](./03-Categories.md) — Category classifications.
- [13-Witnesses.md](./13-Witnesses.md) — Linking student/staff witnesses.
- [14-Interventions-Applied.md](./14-Interventions-Applied.md) — Attaching corrective actions to resolve this logged incident.
- [24-Incident-Report.md](./24-Incident-Report.md) — The standalone report card summarizing logged infractions.


## Section-14 : # Witnesses — Business Requirements
===================================================

## What This Screen Does

The Witnesses screen allows school administrators, HODs, and counsellors to record the testimony and statements of individuals who observed a logged behavioral incident. When serious incidents occur (e.g., student bullying, property damage, academic dishonesty), having a formal method to document multiple witness statements ensures administrative objectivity and accuracy.

Witnesses can be either other **Students** or **Staff Members** (teachers, security guards, administrators). Each witness is linked to a specific parent incident, and their statements are stored securely to build a complete case record.

---

## When This Screen Is Used

- **Investigating Serious Infractions**: A coordinator is resolving a physical dispute between two students and records testimonies from three classmates who saw the event.
- **Validating Claims**: A student claims they were unfairly accused of cheating; the HOD reviews the statements of proctoring teachers logged on this screen.
- **Formal Record Keeping**: Attaching staff testimonies before sending a formal behavior report or disciplinary action to parents.

---

## Key Fields & Add Witness Form

This screen is typically accessed as a nested panel or a sub-tab when viewing the details of a specific parent incident from the [Incident Log](./12-Incident-Log.md).

### Active Incident Context (Header)
- Displays Parent Incident ID, Student Name, Date, Severity, and the primary Description of the event in a read-only container.

### Add Witness Row / Form
| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Witness Type** | String | Dropdown / Select | Yes | Options: `Student` or `Staff Member`. |
| **Witness Name** | Integer (ID) | Autocomplete Search | Yes | If Student: searches `std_students`. If Staff: searches `sch_employees`. |
| **Witness Statement** | String | Text Area | Yes | Explains exactly what they observed. Min 10, Max 500 characters. |

### Witnesses Linked Grid
A table displaying already recorded witnesses for this incident:
- Name and Role (e.g., "Amit Sharma - Student" or "Mr. Khan - Staff").
- Witness Statement text.
- Date Added.
- **Action**: **"Remove"** (Trash icon) to delete the link.

---

## Business Rules and Conditions

**Self-Referential Block**
- A student who is the **primary subject** of the logged incident cannot be added as a witness to their own incident. The autocomplete dropdown automatically excludes the subject student's ID from searches.

**Audit Lock**
- Once the parent incident has been closed or resolved with an associated [Intervention](./14-Interventions-Applied.md) that is marked "Completed," the witness list freezes. No new witnesses can be added, and existing statements cannot be edited or deleted.

**Role-Based Security**
- Witness statements are highly sensitive. While regular subject teachers can see that witnesses exist for an incident, the actual *statement text* can only be viewed by users with HOD, Counsellor, or Principal credentials.

---

## Workflow Steps

**Adding a Witness to an Incident**
1. HOD navigates to **Incidents -> Incident Log** and clicks **View Details** on a High-Severity conflict incident.
2. Clicks on the **Witnesses** tab.
3. Clicks **Add Witness**.
4. Selects Witness Type: `Student`.
5. Searches for: `Rohan Verma` (Admission #1452). Autocomplete matches and populates.
6. Enters Witness Statement: `"Rohan stated that he was sitting two desks away and saw the argument start over a misplaced notebook. He confirms that John pushed Ajay first."`
7. HOD clicks **Save Witness**.
8. The system inserts a record into the joint table `ba_incident_witnesses_jnt` and refreshes the grid.

---

## Example Scenario

During recess, a playground window is broken. A security guard and a student witness the event. The admin logs:
- **Parent Incident**: Window Broken (Subject: John Doe)
- **Witness 1**: Mr. Samuel (Staff / Security Guard) — Statement: `"I was patrolling the west corridor and heard the glass shatter. I saw John running away with a bat."`
- **Witness 2**: Ajay Kumar (Student) — Statement: `"John and I were playing cricket. John hit a ball that went straight into the window."`

These records provide the necessary evidence for the HOD to assign an intervention.

---

## Related Screens

- [12-Incident-Log.md](./12-Incident-Log.md) — The parent incident screen.
- [14-Interventions-Applied.md](./14-Interventions-Applied.md) — The resolution screen linked to this investigation.
- [24-Incident-Report.md](./24-Incident-Report.md) — Prints witness summaries when exporting serious cases.


## Section-15 : # Interventions Applied — Business Requirements
===============================================================

## What This Screen Does

The Interventions Applied screen is where the school logs and manages the active resolution of behavioral issues. Logging an incident only records what went wrong; the **Interventions Applied** tab documents how the school is actively working to resolve it and support the student.

This portal allows counsellors, HODs, and teachers to assign standardized corrective or supportive programs (defined in the [Interventions Master](./04-Interventions.md)) to specific [Incidents](./12-Incident-Log.md). Staff use this screen to track the execution status (e.g., `Assigned`, `In Progress`, `Completed`), assign staff members to lead the intervention, and record developmental progress notes.

---

## When This Screen Is Used

- **Post-Incident Action**: After a severe disciplinary infraction is logged, a counsellor opens this screen to assign "Parent Counseling" to the student.
- **Monitoring Progress**: A counsellor updates progress notes weekly for a student undergoing "Weekly Mentor Meetings."
- **Closing a Case**: Mark an intervention as Completed once the student completes their reflection assignment or restorative service.
- **Reporting Outcomes**: Reviewing the success rates of various interventions during school safety audits.

---

## Key Fields & Assignment Form

This screen is accessible both as a sub-tab within an Incident’s detail card and as a standalone listing of all active behavioral interventions in the school.

### Assign New Intervention Form
| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Parent Incident** | Integer (ID) | Read-only Context | Yes | The incident being resolved. Ref: `ba_incidents`. |
| **Select Intervention**| Integer (ID)| Dropdown / Select | Yes | References active interventions in `ba_interventions`. |
| **Assigned To Staff** | Integer (ID) | Autocomplete Search | Yes | The staff leading the intervention. Ref: `sch_employees`. |
| **Scheduled Date** | Date | Date Picker | Yes | When the intervention should commence. |
| **Status** | String | Dropdown / Select | Yes | Options: `Assigned` (Not started), `In Progress`, `Completed`, `Cancelled`. |
| **Progress Notes** | String | Text Area | No | Rolling log of sessions and student responses. Max 1000 chars. |

---

## Business Rules and Conditions

**Case Resolution Flow**
- A high-severity disciplinary incident *cannot* be marked as resolved or archived until the associated **Intervention Applied** record is updated to `Completed` or `Cancelled` (with a cancellation justification).

**Automated Closure Checklist**
- When the status is flipped to `Completed`, the system enforces filling in the **Completion Date** and adding a closing summary note of at least 50 characters in the **Progress Notes** field.

**Continuous Log Auditing**
- All modifications to the intervention status and notes are written to the [Audit Trail](./19-Audit-Trail.md) along with the staff author’s ID to maintain a secure behavioral record.

---

## Workflow Steps

**Assigning an Intervention**
1. Counsellor opens the active incident list and clicks **Assign Action** on John Doe’s high-severity academic cheating incident.
2. In the assignment form, select Intervention: `Disciplinary Reflection Assignment`.
3. Select Assigned Staff: `Mr. Roy` (Science Teacher).
4. Set Scheduled Date: `2026-12-01`. Set Status: `Assigned`.
5. Counsellor clicks **Save**. The row inserts into the joint table `ba_incident_intervention_jnt`.

**Updating and Completing an Intervention**
1. On December 3rd, Mr. Roy logs in, opens the **Interventions Applied** tab, and searches for John Doe.
2. Clicks **Update Progress**.
3. Changes Status to `Completed`.
4. Enters Progress Notes: `"John successfully completed his 3-page reflection worksheet, discussing the impact of cheating on his learning and character. He apologized to the class."`
5. Enters Completion Date: `2026-12-03`.
6. Clicks **Save**. The parent incident status automatically transitions to `Resolved`. John’s parent receives an automated confirmation email.

---

## Example Scenario

A student is caught using abusive language. The HOD logs the infraction. The counsellor assigns:
- **Intervention**: Anger Management Counselling (Type: Supportive)
- **Assigned Staff**: Dr. Sen (School Psychologist)
- **Scheduled Date**: December 5th
- **Status**: In Progress

Dr. Sen records weekly notes under `Progress Notes` detailing John's attendance and responsiveness. Once the 4-week program is done, Dr. Sen marks it `Completed`, archiving the file.

---

## Related Screens

- [04-Interventions.md](./04-Interventions.md) — The core interventions master.
- [12-Incident-Log.md](./12-Incident-Log.md) — Screen where the parent incident is logged.
- [24-Incident-Report.md](./24-Incident-Report.md) — The standalone report card detailing incident-intervention lifecycles.


## Section-16 : # Reports Hub — Business Requirements
=====================================================

## What This Screen Does

The Reports Hub is the central control station for generating and exporting behavioral data. Rather than scattering download links across various grading and setup pages, this dashboard aggregates all analytical and compliance reports into a single, structured interface.

From the Reports Hub, administrators, coordinators, and teachers can filter broad behavioral metrics, select target cohorts (by Class, Section, or Period), and export structured reports. The hub supports downloading data in standard formats like **CSV** and **Excel** for deep statistical analysis or print integration.

---

## When This Screen Is Used

- **Parent-Teacher Meeting Preparation**: Teachers generate bulk reports summarizing class averages and comments to prepare for conferences.
- **Academic Term Audits**: Admin exports the school-wide behavioral averages to compare against academic performance.
- **Disciplinary Reviews**: The Principal pulls historical incident logs to evaluate school climate and intervention effectiveness.
- **Compliance Reporting**: Generating audit logs for external board reviews to confirm consistent grading practices.

---

## Key Fields & UI Layout

The screen features a split layout: a left-hand navigation menu listing available report categories and a right-hand dynamic configuration and filtering panel.

### Available Reports Menu
- **Student Scores**: Standard grid export of final averages per student.
- **Category Summary**: Performance averages grouped by main behavioral domains.
- **Period Report**: Comparison trends across distinct terms or monthly periods.
- **Audit Trail**: Tracking modification actions and timestamps.
- **Incident Summary**: Aggregating incident counts, witnesses, and resolutions.

### Report Filters Panel (Dynamic based on selected report)
| Filter Field | Data Type | UI Element | Mandatory | Description |
|--------------|-----------|------------|-----------|-------------|
| **Academic Session** | Integer (ID) | Dropdown | Yes | References `org_academic_sessions`. |
| **Assessment Period**| Integer (ID) | Dropdown | Yes | References `ba_assessment_periods`. |
| **Class** | Integer (ID) | Dropdown | No | Filter by Class Level (e.g., "Grade 10"). |
| **Section** | Integer (ID) | Dropdown | No | Filter by Section (e.g., "A"). Enabled only when Class is selected. |
| **Format** | String | Radio Group | Yes | Options: `Excel (.xlsx)` or `CSV (.csv)`. |

### Actions
- **"Generate Preview"**: Renders a read-only mock table of the first 10 rows on screen to verify filters before generating a large download.
- **"Export Report"**: Triggers the file download engine.

---

## Business Rules and Conditions

**Dynamic Row Limitation & Queueing**
- If the target export dataset exceeds **1,000 rows** (e.g., exporting school-wide scores for 1,500 students), the system bypasses direct synchronous downloading (which causes browser timeouts). Instead, it schedules an asynchronous background job and notifies the user via an in-app banner: `"Your report is generating in the background. You will receive a notification to download it shortly."`

**Role-Based Export Filters**
- Teachers are restricted to exporting details for sections they actively instruct or tutor. The Class and Section dropdowns automatically restrict selection to authorized cohorts.
- Administrators and Counsellors have unrestricted access to school-wide filters.

**Data Freshness**
- The export engine pulls from `ba_computed_scores` rather than recalculating individual raw ratings dynamically. A timestamp label at the bottom of the hub displays: `"Data last synced: Today at 2:00 PM."`

---

## Workflow Steps

**Exporting a Class Score Report**
1. User navigates to **Reports -> Reports Hub**.
2. Selects **Student Scores** from the left-hand menu.
3. In the filters panel, selects Academic Session: `2026-2027 Session`, Period: `Term 1`, Class: `Grade 8`, Section: `8-A`.
4. Selects Format: `Excel (.xlsx)`.
5. Clicks **Generate Preview**. The grid below renders John Doe, Amit Sharma, and roll numbers with their averages.
6. The user clicks **Export Report**.
7. The system queries the database, formats the excel spreadsheet using standard template grids, writes the file to disk, and triggers the browser download window. A success toast appears.

---

## Example Scenario

At the end of the first quarter, the High School Principal wants to download a summary of all recorded behavioral infractions to present to the school board. They open the Reports Hub, select **Incident Summary**, filter for High School classes, pick `Excel` format, and click `Export`. They receive a beautifully structured Excel sheet listing student names, infraction descriptions, witness counts, and final intervention outcomes.

---

## Related Screens

- [16-Student-Scores-Report.md](./16-Student-Scores-Report.md) — The student scores detail sheet.
- [17-Category-Summary.md](./17-Category-Summary.md) — The category summary report.
- [18-Period-Report.md](./18-Period-Report.md) — The periodic trend comparison.
- [19-Audit-Trail.md](./19-Audit-Trail.md) — The compliance and change logs.


## Section-17 : # Student Scores Report — Business Requirements
===============================================================

## What This Screen Does

The Student Scores Report is a tabular dashboard displaying final composite and category-level behavioral scores for every student in a selected cohort (Class and Section). Instead of looking at individual criteria, this report aggregates ratings to show broad student performance across core behavioral domains (e.g., Social Skills, Responsibility, Personal Hygiene) alongside their overall weighted average score.

This screen acts as the primary reference grid for teachers and HODs during report card preparation, allowing them to instantly identify students with exceptional behavioral ratings or those showing serious warning signs.

---

## When This Screen Is Used

- **End-of-Term Grading Review**: Teachers open the report to inspect final calculated scores before sending report cards to print.
- **Academic Performance Correlation**: The HOD compares this report with academic grade books to identify if behavioral patterns are affecting classroom learning.
- **Exporting Data**: Exporting structured tabular scores for third-party school information system (SIS) integrations.

---

## Key Columns & Fields

The screen consists of search parameters followed by a wide data table.

### Search and Filters
- **Academic Year**: Dropdown select.
- **Assessment Period**: Dropdown select.
- **Class & Section**: Dropdown selects.

### Scores Data Grid
For the selected section (e.g., Class 8-A), the grid displays:
| Column Header | Source Table | Description |
|---------------|--------------|-------------|
| **Roll No** | `std_students` | Student's school roll number. |
| **Admission No** | `std_students` | Unique school admission code. |
| **Student Name** | `std_students` | Student’s full name. Links to [Student Report](./20-Student-Report.md). |
| **Category Averages** | `ba_computed_scores` | Dynamic columns for each mapped category. Displays the student's calculated average score (e.g., "Collaboration: 4.5", "Hygiene: 3.2"). |
| **Overall Average** | `ba_computed_scores` | The final weighted average score across all categories (e.g., `4.12 / 5.00`). |
| **Grading Teacher** | `sch_employees` | The Class Teacher who completed the evaluation. |
| **Status** | `ba_assessments` | `Draft`, `Submitted`, or `Approved` (Locked). |

---

## Business Rules and Conditions

**Dynamic Category Columns**
- The table columns are generated dynamically on load by querying `ba_class_category_jnt` for the chosen class. If the class only has 3 mapped categories, the table renders exactly 3 category-average columns, ensuring the grid remains compact and readable.

**Score Highlighting (Color-Coded Badges)**
- To aid rapid scannability, cells are color-coded based on average score thresholds:
  - **4.5 to 5.0**: Bright Green (Exemplary)
  - **3.0 to 4.4**: Soft Green/Blue (Proficient)
  - **2.0 to 2.9**: Amber (Developing - Warning)
  - **1.0 to 1.9**: Red (Needs Intervention - Critical)

**Unfinished Grading Protection**
- If a section's progress status is still in `Draft` or `Submitted` (not yet locked by the HOD), a warning banner appears at the top: `"Alert: Grades for this section are not yet approved. Listed scores are drafts and subject to change."`

---

## Workflow Steps

**Reviewing and Filtering Scores**
1. User navigates to **Reports Hub** and selects **Student Scores Report**.
2. Selects Period: `Term 1`, Class: `Grade 8`, Section: `8-A`.
3. The system queries the joint and computed score tables, loads student profiles, and renders the grid.
4. The user notices that Amit Sharma has a red badge in `Responsibility (1.8 / 5.0)`.
5. The user clicks on Amit’s name.
6. The system triggers a redirection, opening Amit’s full [Student Report](./20-Student-Report.md) in a new browser tab to inspect individual criteria scores and written remarks.

---

## Example Scenario

Teacher Mrs. Priya reviews the scores report for Class 8-A:
- The columns display: `Roll No`, `Name`, `Social EQ`, `Self-Discipline`, `Overall Average`, `Status`.
- Student Amit Sharma shows: `Social EQ: 4.80`, `Self-Discipline: 4.60`, `Overall: 4.70` (Green Badge).
- Student Ajay Kumar shows: `Social EQ: 3.00`, `Self-Discipline: 2.10`, `Overall: 2.55` (Amber Badge).
- Mrs. Priya exports this table to CSV for reference in preparation for upcoming parent-teacher conferences.

---

## Related Screens

- [15-Reports-Hub.md](./15-Reports-Hub.md) — The parent reporting portal.
- [17-Category-Summary.md](./17-Category-Summary.md) — Showing category aggregates rather than student-wise listings.
- [20-Student-Report.md](./20-Student-Report.md) — The individual profile report opened by clicking a student's name.


## Section-18 : # Category Summary Report — Business Requirements
=================================================================

## What This Screen Does

The Category Summary Report provides HODs, Principals, and counsellors with high-level curriculum analytics. Rather than listing individual students, this report aggregates score statistics to summarize performance across broad behavioral categories (e.g., "Personal Integrity," "Digital Literacy," "Social Responsibility").

It highlights which behavioral categories are strengths for a particular class or grade level, and which domains represent widespread struggles (e.g., identifying that Class 8-A averages an excellent `4.6 / 5.0` in Peer Collaboration but averages a concerning `2.4 / 5.0` in Classroom Focus).

---

## When This Screen Is Used

- **Curriculum Planning Meetings**: The school leadership HOD reviews behavioral category averages to decide if the school needs to dedicate more focus to digital ethics or basic hygiene.
- **Section Comparative Analysis**: Comparing the performance of Section A vs. Section B to see if teaching styles or section distributions affect student behavioral scores.
- **School Quality Inspections**: Exporting aggregated category statistics for educational accreditation reviews.

---

## Key Fields & Report Layout

### Filters
- **Assessment Period**: Dropdown select.
- **Class**: Dropdown select (Optional. If empty, aggregates school-wide).
- **Section**: Dropdown select (Optional. Enabled only when Class is selected).

### Category Summary Grid
For the selected cohort, the report displays:
| Field Header | Description |
|--------------|-------------|
| **Category Name** | The behavioral category (e.g., "Collaboration"). |
| **Students Count** | Total number of students evaluated in this cohort. |
| **Category Average**| The average score of all students under this category (e.g., `3.82`). |
| **Top Criterion** | The specific criterion that received the highest class average (e.g., "Works well in teams" - Average `4.2`). |
| **Lowest Criterion**| The specific criterion that received the lowest class average (e.g., "Resolves conflicts" - Average `3.1`). |
| **Cohort Distribution** | A small inline bar chart showing the split of students in grading buckets (e.g., Exemplary: 40%, Proficient: 50%, Developing: 10%). |

---

## Business Rules and Conditions

**Anonymized Reporting**
- Unlike the [Student Scores Report](./16-Student-Scores-Report.md), the Category Summary Report is **fully anonymized**. It lists no individual student names or IDs, only counts and averages. This allows teachers to share these reports during general grade-level staff briefings without violating student privacy.

**Weighted Category Aggregations**
- Averages are calculated using the formula:
  - `Category Average = Sum of (Student Computed Category Average) / Total Students`.
  - Inactive criteria weights are excluded from calculations dynamically based on historical mapping entries in `ba_class_category_jnt`.

**Download Formats**
- Supports exports to **PDF** (which embeds a professional distribution chart) and **CSV** for spreadsheet compilation.

---

## Workflow Steps

**Reviewing Category Averages**
1. HOD navigates to **Reports Hub** and clicks **Category Summary**.
2. Selects Period: `Term 1`, Class: `Grade 8`, Section: `All Sections`.
3. Clicks **Generate Report**.
4. The screen loads three rows: `Social Quotient`, `Self-Discipline`, and `Responsibility`.
5. Under `Self-Discipline`, Mr. Jacob notices the Class Average is `2.9` (Amber warning badge).
6. Under the "Lowest Criterion" column, the cell reads: `"Punctual Submission of Assignments (Average: 2.1)"`.
7. This indicates that assignment submission, specifically, is pulling down the self-discipline averages across the grade level.
8. Mr. Jacob schedules a staff meeting to discuss homework policies and logs out.

---

## Example Scenario

The High School Principal pulls a school-wide Category Summary Report for the Mid-Term Period:
- **School-Wide Average**: `3.90 / 5.00`
- **Highest Performing Category**: `Collaboration & Sharing` (Average: `4.52`)
- **Lowest Performing Category**: `Digital Ethics` (Average: `2.10`)
- The Principal notices a school-wide drop in digital ethics and organizes a cyber-safety workshop for high school students in November.

---

## Related Screens

- [03-Categories.md](./03-Categories.md) — Master categories definitions.
- [15-Reports-Hub.md](./15-Reports-Hub.md) — The parent reporting portal.
- [16-Student-Scores-Report.md](./16-Student-Scores-Report.md) — Detailed student-wise scores.
- [23-Category-Performance.md](./23-Category-Performance.md) — Standalone analytical page showing category standard deviations.


## Section-19 : # Period Report — Business Requirements
=======================================================

## What This Screen Does

The Period Report is a comparative analytical dashboard designed to track longitudinal performance changes. Instead of showing scores for a single isolated term, this report compares student-wise or cohort-wide averages across multiple consecutive **Assessment Periods** (e.g., comparing "Term 1" vs. "Term 2", or plotting progress month-by-month).

It highlights developmental progression, showing which students are showing improvement in their behavioral averages, who has remained stable, and who is experiencing a sharp decline in conduct or self-discipline.

---

## When This Screen Is Used

- **Year-End Progress Reviews**: Teachers open the comparison grid to evaluate a student's year-long behavioral trajectory.
- **Intervention Audits**: Counsellors review this report to verify if a student’s scores improved after an [Intervention](./14-Interventions-Applied.md) was completed.
- **Parent meetings (Report Cards)**: Providing parents with a clear visual chart showing their child’s progress across distinct quarters.

---

## Key Fields & Grid Layout

### Filters
- **Academic Session**: Dropdown select.
- **Class & Section**: Dropdown select.
- **Compare Periods**: Multi-select dropdown (allows choosing two or more periods, e.g., "Term 1" and "Term 2").

### Period Comparison Data Table
For the selected cohort, the grid displays:
| Roll No | Student Name | Period 1 Average | Period 2 Average | Score Delta | Incidents (P1) | Incidents (P2) | Trend Indicator |
|---------|--------------|------------------|------------------|-------------|----------------|----------------|-----------------|
| 1 | Amit Sharma | `4.2` | `4.7` | `+0.5` | 0 | 0 | ↗️ Upward (Green) |
| 2 | John Doe | `3.1` | `2.5` | `-0.6` | 1 | 3 | ↘️ Downward (Red) |
| 3 | Ajay Kumar | `3.8` | `3.8` | `0.0` | 0 | 0 | ➡️ Stable (Blue) |

---

## Business Rules and Conditions

**The Delta (Score Change) Formula**
- `Score Delta = Period (N) Average - Period (N-1) Average`.
- If the delta is positive (e.g., `+0.30` or higher), the trend cell displays a green up-arrow.
- If the delta is negative (e.g., `-0.30` or lower), the trend cell displays a red down-arrow.
- A small change within `0.20` displays a blue horizontal flat arrow, representing stability.

**Dynamic Period Mapping**
- If categories or criteria mappings changed between Period 1 and Period 2 (which is discouraged but possible), the comparison engine calculates the delta *only* across categories that were active in **both** periods. This prevents skewed calculations from mismatched grading rubrics.

---

## Workflow Steps

**Reviewing Progress Trends**
1. Coordinator navigates to **Reports -> Period Report**.
2. Selects Class: `Grade 8`, Section: `8-A`.
3. In "Compare Periods", checks **Quarter 1** and **Quarter 2**.
4. Clicks **Generate Comparison**.
5. The comparison table renders roll numbers 1 to 30.
6. The coordinator filters the table by the "Score Delta" column in ascending order to instantly push students with declining scores to the top.
7. Sees John Doe has a delta of `-0.60` and his incident count spiked from `1` to `3`.
8. Coordinator flags John’s profile for a counselor review.

---

## Example Scenario

The school counsellor wants to check if counselling helped John. They open the Period Report for Grade 10:
- Q1 (Before counselling): John Doe average was `2.1` with 4 incidents.
- Q2 (After counselling): John Doe average is `3.8` with 0 incidents.
- Delta: `+1.7` (Green Upward Trend).
- This confirms that the behavior support plan was highly successful.

---

## Related Screens

- [06-Periods.md](./06-Periods.md) — Master periods configuration.
- [15-Reports-Hub.md](./15-Reports-Hub.md) — Central reports dashboard.
- [20-Student-Report.md](./20-Student-Report.md) — The individual card printing these trend comparisons.
- [22-Period-Progress.md](./22-Period-Progress.md) — Standalone analytical page showing trend line charts.


## Section-20 : # Audit Trail — Business Requirements
=====================================================

## What This Screen Does

The Audit Trail log report is a secure, read-only system registry designed for security and administrative transparency. In school administration, grades and behavioral remarks are sensitive records. The Audit Trail automatically logs every creation, modification, or deletion of behavioral data, including score updates, remark edits, configuration overrides, and period locks.

This ledger ensures that any disputed grade change or configuration toggle can be traced back to the exact staff member, timestamp, IP address, and old vs. new values.

---

## When This Screen Is Used

- **Investigating Grade Discrepancies**: A parent complains that their child's rating was suddenly lowered; the HOD reviews the audit logs to check which teacher modified it and why.
- **Security Audits**: The IT Administrator checks the log to confirm if any unauthorized user attempted to override locked assessment periods.
- **Tracking System Changes**: Verifying when a global configuration (e.g., active rating scale) was modified and who performed the update.

---

## Key Columns & Filters

The Audit Trail is restricted to School Admins and is located under **Reports -> Audit Trail**.

### Search Filters
- **Date Range**: Start and End Date pickers (defaults to last 7 days).
- **Action Type**: Dropdown select (Options: `Grade Edit`, `Remark Edit`, `Config Change`, `Status Lock`, `Record Delete`).
- **User (Staff)**: Autocomplete search filter to look up actions performed by a specific employee.
- **Student**: Filter by a specific student profile.

### Audit Log Data Grid
| Timestamp | User | Action Category | Affected Student / Cohort | Description | Old Value | New Value | IP Address |
|-----------|------|-----------------|---------------------------|-------------|-----------|-----------|------------|
| 2026-11-28 14:05:12 | Mrs. Priya | `Grade Edit` | Amit Sharma (Class 8-A) | Modified Peer Collaboration rating. | `Satisfactory (3.0)` | `Exemplary (5.0)` | `192.168.1.45` |
| 2026-11-28 16:30:00 | Mr. Jacob | `Status Lock` | Grade 8-A (Term 1) | Approved and locked assessment period. | `Submitted` | `Approved` | `192.168.1.10` |

---

## Business Rules and Conditions

**The Immutable Ledger Rule**
- The `ba_audit_log` table is **strictly insert-only**.
- The system provides **no interface or API endpoint** to edit or delete rows in the audit trail. Even the Super Admin cannot modify these logs through the application UI to prevent tampering with historical school records.

**Detailed Difference Logging**
- Any change to student scores in `ba_assessment_ratings` must record:
  - The exact criterion affected.
  - The `old_value` (both Level Name and Numeric Score).
  - The `new_value` (both Level Name and Numeric Score).

**Automated Pruning**
- To prevent the database from growing excessively, audit logs older than **3 years** are automatically archived to cold storage and pruned from active transactional tables.

---

## Workflow Steps

**Investigating a Score Change**
1. Admin logs in and navigates to **Reports Hub -> Audit Trail**.
2. Applies filters: Student: `John Doe`, Action Type: `Grade Edit`.
3. Clicks **Search**.
4. The grid displays one row.
   - **Timestamp**: `2026-11-25 10:15:20`
   - **User**: `Mr. Roy`
   - **Description**: `"Modified 'Academic Honesty' rating for John Doe (10-A)."`
   - **Old Value**: `Exemplary (5.0)`
   - **New Value**: `Needs Improvement (1.0)`
5. This trace confirms that Mr. Roy lowered John's score on November 25th, providing the HOD with clear context for discussion.

---

## Example Scenario

A teacher disputes that she locked a section's grades by accident. The admin opens the Audit Trail, filters by Action Category: `Status Lock` and User: `Teacher Name`. The log reveals:
- **Timestamp**: `2026-11-26 15:45:10`
- **Action**: `"Teacher clicked 'Submit to Coordinator' for Class 7-C."`
- **IP Address**: `192.168.4.12` (Matching the teacher’s classroom computer).
This log confirms the lock action was initiated from the teacher's active workspace session.

---

## Related Screens

- [07-Configuration.md](./07-Configuration.md) — Tracks global settings changes recorded here.
- [09-Ratings.md](./09-Ratings.md) / [10-Remarks.md](./10-Remarks.md) — Audits score and text changes.
- [15-Reports-Hub.md](./15-Reports-Hub.md) — The parent reporting portal.


## Section-21 : # Student Report — Business Requirements
========================================================

## What This Screen Does

The Student Report is a standalone, highly formatted digital profile card. It serves as a student's holistic behavioral dossier. Instead of looking at raw spreadsheets, this dashboard consolidates a student's entire behavioral history for the active academic session into a single visually polished, print-ready document.

It aggregates the student's category-wise numeric averages, detailed criteria ratings, homeroom teacher remarks, real-time incident logs (both positive achievements and infractions), and the outcomes of any applied corrective interventions.

---

## When This Screen Is Used

- **Parent-Teacher Meetings**: Homeroom teachers print or display this sheet to guide conversations with parents.
- **Disciplinary Hearings**: The HOD and Principal review the student’s complete record before deciding on severe interventions.
- **Report Card Printing**: Bulk generating behavior sheets to attach to final academic progress cards.

---

## Key Widgets & Report Structure

The document layout is divided into four logical zones:

### 1. Student Identity Header
- Student Photo, Full Name, Admission Number, Class & Section, and Homeroom Teacher.
- **Download PDF** button in the top right corner.

### 2. High-Level KPI Summary (Metric Badges)
- **Overall Behavioral Average**: e.g., `4.22 / 5.00` (highlighted in color badge matching score tier).
- **Achievements Logged**: Count of positive behavioral logs.
- **Infractions Logged**: Count of negative behavioral logs.
- **Interventions Completed**: Active/Completed count.

### 3. Detailed Behavioral Rubrics Grid
Structured by Category and Criteria:
- **Category (Social EQ)**
  - *Respects Peers*: `Exemplary (5.0)` — "Always speaks politely and shares materials."
  - *Collaboration*: `Satisfactory (3.0)` — "Works well in teams but sometimes dominates."
- **Category (Self-Discipline)**
  - *Punctuality*: `Proficient (4.0)` — "Consistently arrives on time."
- **Narrative Section**: Displays the exact text from the [Student Remarks](./10-Remarks.md) table.

### 4. Incident Timeline & Interventions Resolved
A chronological feeds of events:
- **2026-11-20**: Negative Incident (Medium Severity) — "Class disruption."
  - *Intervention Applied*: Disciplinary Reflection Assignment (Status: Completed).
- **2026-11-12**: Positive Incident (Info) — "Assisted lab setup."

---

## Business Rules and Conditions

**The Grade Lockdown Rule**
- Draft or unapproved grades from `ba_assessments` are **strictly hidden** from the parent-facing digital Student Report. If a period is still in `Draft` or `Submitted` status, the Rubrics Grid shows: `"Grading for this period is in progress. Averages will be visible once finalized by HOD."`
- Staff users can toggle a `"Show Drafts"` checkbox in the top bar to inspect active scoring sheets.

**High-Quality PDF Generation**
- The "Download PDF" action utilizes an isolated CSS print stylesheet. Page-break margins are strictly defined so that student headers do not orphan at the bottom of pages, and charts render in clean high-contrast gray scale/color.

---

## Workflow Steps

**Reviewing and Printing a Report Card**
1. Teacher Mrs. Priya opens the **Reports Hub** and searches for student `Amit Sharma`.
2. Clicks **View Report**.
3. The Student Report dashboard loads. Mrs. Priya reviews the KPI summary (Overall score: `4.7` - Excellent), the rubrics grid, and the positive incident timeline showing 2 achievements.
4. Clicks **Download PDF**.
5. The system initiates an HTML-to-PDF compilation job on the server, formats the document using standard school logos and borders, and outputs a downloadable file `Amit_Sharma_Behavior_Report_Term_1.pdf`.
6. Mrs. Priya prints the file to present at the next day's parent conference.

---

## Example Scenario

During a parent conference, Ajay’s mother is concerned about his behavior. The teacher loads Ajay’s Student Report:
- It displays a low overall score: `2.4 / 5.0`.
- The rubrics grid shows a low rating `Needs Support (1.0)` in "Conflict Resolution."
- The timeline lists 2 negative incidents of physical disputes at recess, with an intervention "Anger Management Counseling" marked `In Progress`.
- This visual evidence helps the parent understand the school's concern and the restorative action plan in place.

---

## Related Screens

- [09-Ratings.md](./09-Ratings.md) / [10-Remarks.md](./10-Remarks.md) — Source databases for the rubrics and comments.
- [12-Incident-Log.md](./12-Incident-Log.md) / [14-Interventions-Applied.md](./14-Interventions-Applied.md) — Sources for the incident timelines.
- [15-Reports-Hub.md](./15-Reports-Hub.md) — The parent portal access.


## Section-22 : # Class Analysis — Business Requirements
========================================================

## What This Screen Does

The Class Analysis dashboard is a standalone analytical workspace designed for school leaders and HODs. While the [Student Scores Report](./16-Student-Scores-Report.md) displays a simple flat data grid, the Class Analysis screen uses advanced data visualization (heatmaps, cohort distribution charts, and outlier detectors) to provide a comprehensive behavioral diagnostic of an entire class section.

This dashboard helps coordinators identify macro trends across sections, compare section averages, and instantly isolate student outliers—both high-achievers who deserve recognition and at-risk students who need counselling before behavioral issues escalate.

---

## When This Screen Is Used

- **Inter-Section Audits**: The HOD compares Class 8-A vs. Class 8-B to see why one section has significantly lower discipline averages.
- **Isolating At-Risk Cohorts**: Quickly identifying the bottom 10% of students across a grade level to organize targeted group therapy.
- **Academic Counsel Preparation**: Reviewing macro-level class behavior to discuss in weekly teacher alignment meetings.

---

## Key Widgets & Visual Analytics

### 1. Cohort Score Distribution (Donut / Bar Chart)
- Displays the headcount and percentage of students falling into distinct behavioral brackets (e.g., Exemplary: `8 Students`, Proficient: `15 Students`, Developing: `5 Students`, Critical: `2 Students`).

### 2. Behavioral Heatmap Grid
A visual matrix grid:
- **Rows**: Students listed by name.
- **Columns**: Mapped behavioral categories (e.g., "Collaboration," "Ethics," "Focus").
- **Cells**: Instead of text numbers, cells are filled with shaded gradient colors based on scores (e.g., Deep Emerald Green for `5.0` fading down to Deep Rose Red for `1.0`).
- This layout allows a coordinator to scan 35 students in a split second and instantly spot red or amber blocks representing struggling students.

### 3. Outlier Lists (The Extremes Panel)
- **Top Performers (Positives)**: Lists the top 5 students in the class with the highest composite score averages and positive incident counts.
- **At-Risk Alert (Negatives)**: Automatically surfaces the bottom 5 students with the lowest composite score averages or highest negative incident frequencies.

---

## Business Rules and Conditions

**Strict Threshold Triggers**
- The **At-Risk Alert** list automatically flags any student whose composite rolling average falls below `2.5 / 5.0` OR who has accumulated `2 or more` negative incidents during the active term, regardless of their average score.

**Data Aggregation Speed**
- Heatmaps use heavy database matrix queries. To maintain page responsiveness, heatmap data is compiled asynchronously in the background using JavaScript and stored in a browser local storage cache. If no changes are detected in `ba_assessment_ratings`, the grid loads instantly from cache.

---

## Workflow Steps

**Investigating Class Outliers**
1. Coordinator navigates to **Standalone Reports -> Class Analysis**.
2. Selects Class: `Grade 8`, Section: `8-A`, Period: `Term 1`.
3. Clicks **Analyze Cohort**.
4. The dashboard renders. The distribution chart shows: `Exemplary: 30%, Proficient: 50%, Developing: 15%, Critical: 5%`.
5. Mr. Jacob scans the **Behavioral Heatmap**. He spots a dark red cell in the row for student **John Doe** under the "Focus" column.
6. Jacob hovers over the cell. A tooltip displays: `"John Doe - Focus Score: 1.50 / 5.00"`.
7. Jacob reviews the "At-Risk Alert" panel. John is listed at the top.
8. Jacob clicks John’s name, opening his [Student Report](./20-Student-Report.md) to inspect the specific teacher remarks.

---

## Example Scenario

During a grade level review, HOD Mr. Jacob opens the Class Analysis for Grade 8-A:
- **Section Average**: `3.80 / 5.00`
- **Heatmap Scan**: The column `Digital Citizenship` is almost entirely light green and yellow, averaging `2.8` class-wide, whereas `Collaboration` is deep emerald green (`4.5` class-wide).
- This alerts Jacob that the entire section is struggling with digital safety and phone protocols, indicating a need for a targeted class-wide intervention rather than individual disciplinary actions.

---

## Related Screens

- [16-Student-Scores-Report.md](./16-Student-Scores-Report.md) — The transactional scores list.
- [17-Category-Summary.md](./17-Category-Summary.md) — Category-level summaries.
- [20-Student-Report.md](./20-Student-Report.md) — Student detailed reports.
- [22-Period-Progress.md](./22-Period-Progress.md) — Longitudinal trend tracking.


## Section-23 : # Period Progress — Business Requirements
=========================================================

## What This Screen Does

The Period Progress dashboard is a standalone data visualization screen designed to illustrate change over time. While the [Period Report](./18-Period-Report.md) displays comparative scores in a flat tabular format, this screen renders **longitudinal trend line charts** and area graphs, plotting a student's or section's behavioral performance over consecutive terms or months.

This visual representation makes it extremely easy to spot behavior cycles (e.g., scores dipping in winter terms, or showing a massive upward trajectory after a counselor-led intervention plan starts).

---

## When This Screen Is Used

- **Counseling Intake Meetings**: School psychologists open this trend dashboard to review a student's historical behavioral graph before beginning therapy.
- **Academic Board Reviews**: Presenting year-over-year behavioral progress metrics to the school's board of directors.
- **Individual Student Counseling**: Showing students their own progress graph visually as a positive motivational tool.

---

## Key Widgets & Visual Elements

### 1. Trend Line Chart (Main Widget)
- **X-Axis**: Lists the consecutive assessment periods in chronological order (e.g., Month-1, Month-2, Month-3 or Q1, Q2, Q3, Q4).
- **Y-Axis**: The scoring range (e.g., `1.0` to `5.0`).
- **Plot Lines**:
  - *Composite Score Trend Line*: A bold blue line showing the student's overall weighted average.
  - *Category Trend Lines*: Optional thinner dotted lines plotted in different colors (e.g., Green for "Social EQ", Purple for "Self-Discipline") that can be toggled on/off using chart legends.

### 2. Milestone Event Markers (Chronological Overlay)
- Interactive flags overlaid directly onto the line chart.
- A red flag marker displays on a specific date when a High Severity incident was logged.
- A green flag marker displays on the date when an [Intervention Applied](./14-Interventions-Applied.md) was completed.
- Hovering over a flag displays a tooltip summarizing the event (e.g., `"Dec 5: Completed Anger Management Plan"`). This shows the direct correlation between active interventions and score improvements.

### 3. Progress KPI Summary Cards
- **Starting Score**: The score in the earliest chosen period.
- **Ending Score**: The score in the latest period.
- **Total Progress Delta**: Score change percentage (e.g., `+18% Improvement` or `-5% Decline`).

---

## Business Rules and Conditions

**Continuous Data Interpolation**
- If a student was absent or had no grades recorded for a specific middle period (e.g., missed Q2 due to medical leave), the chart line interpolates across the missing period with a dashed line, preventing a broken or disjointed chart layout.

**Multi-Line Chart Limits**
- To prevent chart clutter, users can plot a maximum of **5 categories** simultaneously. Selecting more than 5 categories prompts an alert requesting the user to uncheck a category before plotting another.

---

## Workflow Steps

**Reviewing Student Trend Graphs**
1. User navigates to **Standalone Reports -> Period Progress**.
2. Selects Target Scope: `Student`.
3. Type student name: `John Doe` (Grade 10).
4. The system queries `ba_computed_scores` for John across all active terms in the current session.
5. The **Trend Line Chart** renders John’s behavioral performance.
6. The user notices John’s line starts low in Q1 (`2.1`), dips further in Q2 (`1.9`), but spikes dramatically in Q3 (`3.8`).
7. The user notices a green milestone flag on the line at the start of Q3.
8. Hovering over the green flag displays: `"Completed Mentor Coaching Intervention led by Mr. Roy on Oct 10"`.
9. The user exports this progress chart to PDF to attach to the final term progress folder.

---

## Example Scenario

At the end of the year, HOD Mr. Jacob wants to check the overall behavior progress of Class 8-A. He selects Scope: `Class Section`, Class: `Grade 8`, Section: `8-A`. The dashboard plots a single line representing the section's class average over 4 quarters. The line starts at `3.4`, remains stable at `3.5` and `3.5`, and climbs to `3.9` in Q4, representing a year-over-year improvement of `+14.7%` across the cohort.

---

## Related Screens

- [06-Periods.md](./06-Periods.md) — The date-bound evaluation terms.
- [14-Interventions-Applied.md](./14-Interventions-Applied.md) — Interventions that generate milestone flags.
- [18-Period-Report.md](./18-Period-Report.md) — The flat table comparison report.
- [20-Student-Report.md](./20-Student-Report.md) — Individual student dossiers.


## Section-24 : # Category Performance — Business Requirements
==============================================================

## What This Screen Does

The Category Performance dashboard is a standalone analytical interface designed for advanced behavioral analytics. While the [Category Summary Report](./17-Category-Summary.md) presents a simple flat table of class averages, the Category Performance screen provides deep statistical evaluations, such as **Standard Deviation / Score Spread curves (Bell Curves)**, **Gender-wise performance splits**, and **Academic Correlation Indexes**.

This page helps HODs and educational researchers evaluate if teacher grading is highly uniform (low standard deviation) or highly polarized (high standard deviation), and whether behavioral standards correlate directly with the school’s academic achievements.

---

## When This Screen Is Used

- **Academic Studies & Board Audits**: Presenting behavioral performance correlations during school board reviews.
- **Teacher Standardization Meetings**: HODs use this report to determine if teachers in Section A are grading significantly easier or harder than teachers in Section B (checking for grading bias).
- **Evaluating Demographics**: Reviewing if specific student demographics (e.g., gender, boarding vs. day scholar) show different behavioral patterns to direct school counseling initiatives.

---

## Key Widgets & Statistical Elements

### 1. Score Dispersion Curve (Standard Deviation Bell Curve)
- Illustrates how student scores are spread across the grading spectrum for the chosen category.
- **Low Standard Deviation Indicator**: A tall, narrow curve showing that teachers graded most students uniformly (e.g., almost everyone scored around 3.5).
- **High Standard Deviation Indicator**: A wide, flat curve showing polarized grading, where many students scored 5.0 and many scored 1.0, requiring HOD review for potential grading inconsistency.

### 2. Demographic Score Split (Bar Chart)
- **Gender-wise Comparison**: Bar chart comparing boys' average score vs. girls' average score in the category (e.g., Social EQ: Boys 3.6, Girls 4.1).
- **Enrolment Comparison**: Comparing boarding students vs. day scholars to check for different social development patterns.

### 3. Academic Correlation Matrix
- Plots a scatter diagram correlating a student's Behavioral Category average (X-Axis) against their Academic GPA (Y-Axis).
- Helps prove or disprove whether behavioral factors (e.g., Punctuality, Collaboration) directly influence a student's final academic exam scores.

---

## Business Rules and Conditions

**The Standardization Threshold**
- If the Standard Deviation for any category in a class exceeds **`1.20` on a 5-point scale**, the system highlights a warning icon next to the class name: `"High Grading Dispersal Detected. Review teacher grading patterns for consistency."`

**Anonymity Constraints**
- To maintain statistical objectivity and protect student privacy, this dashboard contains **no student-level identities**. It focuses entirely on cohort aggregates, statistical spreads, standard deviations, and correlation indexes.

---

## Workflow Steps

**Evaluating Grading Consistency**
1. HOD navigates to **Standalone Reports -> Category Performance**.
2. Selects Category: `Self-Discipline`, Period: `Term 1`, Class: `Grade 8`.
3. Clicks **Calculate Statistics**.
4. The dashboard renders:
   - **Class Average**: `3.22 / 5.00`
   - **Standard Deviation**: `1.45` (triggers a red warning banner: `"Polarized Grading Alert"`).
5. The HOD clicks the **Teacher Comparison** tab below.
6. The grid reveals that Mr. Roy graded 8-A with a standard deviation of `0.45` (very consistent), while Mr. Roy's co-teacher in 8-B graded with a standard deviation of `1.65` (highly inconsistent, with mostly 5s and 1s).
7. Mr. Jacob schedules a standardization alignment session for the Grade 8-B teacher.

---

## Example Scenario

The High School Principal wants to analyze the school's "Leadership & Initiative" category. They select the category and click analyze:
- **School-Wide average**: `3.60`
- **Gender Split**: Girls `3.92`, Boys `3.24` (revealing a significant development gap).
- **Academic Correlation**: `0.72` (a high positive correlation, proving that students with high leadership ratings are also scoring high academic grades).
- These insights are exported to PDF to include in the school's annual developmental journal.

---

## Related Screens

- [03-Categories.md](./03-Categories.md) — Master categories definitions.
- [15-Reports-Hub.md](./15-Reports-Hub.md) — The parent reporting portal.
- [17-Category-Summary.md](./17-Category-Summary.md) — The flat table summary report.
- [21-Class-Analysis.md](./21-Class-Analysis.md) — Comparative heatmaps.


## Section-25 : # Incident Report — Business Requirements

## What This Screen Does

The Incident Report dashboard is a standalone tracking and analytical panel focused entirely on real-time conduct tracking. While other reports summarize term grades, this report aggregates the daily logs recorded in the [Incident Log](./12-Incident-Log.md), detailing positive achievements, disciplinary infractions, [Witness testimonies](./13-Witnesses.md), and [Interventions Applied](./14-Interventions-Applied.md).

It compiles transactional logs into high-level analytical widgets (such as Weekly Incident Frequencies, Category Distributions, and Intervention Success Rates), helping the school administration identify repeating behavioral triggers and assess the effectiveness of disciplinary and supportive protocols.

---

## When This Screen Is Used

- **Monthly Administrative Audits**: The Principal reviews the frequency and categories of negative incidents to measure general school safety and order.
- **Parent Confrontation Meetings**: The counsellor opens the report pre-filtered for a specific student to present parent-ready printouts showing timelines of infractions and linked witness statements.
- **Intervention Efficacy Reviews**: Evaluating which restorative interventions show the highest success rates in preventing repeating offenses.

---

## Key Fields & Screen Layout

The dashboard features search parameters at the top, analytical metric widgets in the middle, and a detailed tabular log grid at the bottom.

### Search and Filters
- **Date Range**: Start and End Date pickers (defaults to active term).
- **Incident Type**: Dropdown (Options: `All`, `Positive (Achievements)`, `Negative (Infractions)`).
- **Severity**: Dropdown (Options: `All`, `Info`, `Low`, `Medium`, `High`).
- **Class & Section**: Filter logs by a specific cohort.
- **Student**: Filter by a specific student profile.

### Analytical Charts & Widgets
- **Weekly Frequency Curve**: A line chart plotting the count of incidents logged week-by-week to identify cycles of behavioral spikes (e.g., spikes before school exams or holidays).
- **Intervention Success Rate**: A donut chart showing the percentage of assigned interventions that reached `Completed` status vs. those marked `Cancelled` or `In Progress`.
- **Top 3 Infraction Triggers**: Horizontal bar chart highlighting the categories with the highest incident counts (e.g., "Late Attendance," "Littering").

### Incidents Grid Table
| Date | Student Name | Logged By Staff | Category & Severity | Description | Witness Count | Applied Intervention & Status |
|------|--------------|-----------------|---------------------|-------------|---------------|--------------------------------|
| 2026-11-20 | John Doe | Mr. Roy | Peer Relations (High) | Academic cheating dispute. | `2 Witnesses` | Parent Counseling (Completed) |
| 2026-11-18 | Amit Sharma | Mrs. Priya | Cooperation (Info) | Cleaned laboratory workspace. | `0 Witnesses` | Praise Badge (Completed) |

---

## Business Rules and Conditions

**The Escalation Link**
- The table must fetch links dynamically from:
  - `ba_incidents` (The core event).
  - `ba_incident_witnesses_jnt` (Count of witness records).
  - `ba_incident_intervention_jnt` joined with `ba_interventions` (The corrective actions and their current status).

**Export Compliance & Privacy**
- **CSV & Excel Exports**: When exported for administrative use, the file includes student roll numbers and names.
- **Public/Staff Digests**: When exported as an aggregate school safety digest, the system automatically replaces individual student names with anonymous hashes (e.g., `STUDENT-SHA-123`) to comply with pupil data privacy regulations.

---

## Workflow Steps

**Reviewing Disciplinary Trends**
1. Counsellor logs in and navigates to **Standalone Reports -> Incident Report**.
2. Selects Date Range: `Past 30 Days`, Incident Type: `Negative (Infractions)`, Severity: `High`.
3. Clicks **Generate Report**.
4. The line chart highlights a sudden spike in high-severity incidents during the second week of November.
5. In the grid below, the counsellor filters by "Category".
6. Sees 4 high-severity incidents under "Exam Honesty" matching the dates of mid-term examinations.
7. This trace confirms a correlation between exam stress and honor-code violations, prompting the counsellor to schedule stress-management and ethics assemblies before the next final examination period.

---

## Example Scenario

During a parent assembly, the coordinator wants to present a summary of positive conduct. They open the Incident Report, select Type: `Positive`, pick `PDF` format, and export it. The generated PDF showcases that students logged over 250 positive achievements (helpfulness, academic triumphs, cleanliness initiatives) this term, with a 98% intervention reinforcement completion rate.

---

## Related Screens

- [12-Incident-Log.md](./12-Incident-Log.md) — Source database for behavioral events.
- [13-Witnesses.md](./13-Witnesses.md) — Witness linkages.
- [14-Interventions-Applied.md](./14-Interventions-Applied.md) — Resolution timelines.
- [15-Reports-Hub.md](./15-Reports-Hub.md) — The parent reporting portal.
- [20-Student-Report.md](./20-Student-Report.md) — Individual student profiles.


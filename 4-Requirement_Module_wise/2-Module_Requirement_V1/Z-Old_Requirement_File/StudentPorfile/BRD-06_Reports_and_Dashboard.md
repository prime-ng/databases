# BRD-06: Reports & Dashboard

**Document Version:** 1.0
**Date:** 2026-05-21
**Author:** Business Analyst
**Status:** Draft**

---

## 1. Business Need

### 1.1 Problem Statement
School leadership (Principal, Admin, Academic Coordinator) needs real-time visibility into student demographics, enrollment trends, attendance patterns, and operational alerts to make informed decisions. Currently, this data is scattered across multiple registers, Excel sheets, and manual reports — making it time-consuming to get answers to basic questions like "How many students are in Class 10?", "What is today's attendance percentage?", or "Which students have pending document verification?". Schools also require specific reports for government submissions, audits, and internal analysis.

### 1.2 Business Objectives
- Provide a centralized dashboard with key performance indicators at a glance
- Enable instant access to student strength, attendance, and admission trends
- Generate government-required reports (caste category, RTE/EWS quota, admission register)
- Support daily operational reports (attendance summary, class-wise strength)
- Surface actionable alerts (unverified documents, low attendance, suspended students)
- Reduce manual report preparation time from hours to minutes

---

## 2. Scope

### 2.1 In Scope
- Dashboard with KPI cards (Total Students, New Admissions, Attrition, Today's Attendance)
- Dashboard charts (Student Distribution by Class, Gender Ratio, Admission Trend, Categories)
- Critical alerts panel (unverified documents, low attendance, suspended students)
- Quick action buttons (New Admission, Bulk Import, ID Card Print)
- Class-wise Student Strength Report with gender and category breakdown
- Admission Register Report for audit/government submission
- Student Medical Profile & Exceptions Report
- Caste Category Distribution Report
- Age-wise Student Report
- Suspended/Inactive Student Report
- RTE/EWS Quota Report
- Attendance Summary Report
- Student ID Card generation (batch/single)
- Missing Optional Subjects Report
- Student Login Credentials sending

### 2.2 Out of Scope
- Cross-module analytics (combining fee, exam, transport data — separate Analytics module)
- Custom report builder (ad-hoc field selection)
- Scheduled/delayed report generation (email-based report delivery)
- Multi-school comparison reports (for central/Super Admin use — separate reporting module)

---

## 3. Stakeholders

| Stakeholder | Interest |
|---|---|
| Principal | Needs holistic view of school demographics, enrollment trends, attendance |
| School Admin | Uses reports for daily operations, government submissions, audits |
| Academic Coordinator | Needs class-wise strength for resource planning |
| Class Teacher | Uses attendance reports for parent communication |
| School Nurse | Needs medical exception reports for health monitoring |
| Clerk | Prepares admission register and ID cards |
| Accountant | Uses caste/RTE reports for government compliance |

---

## 4. User Roles & Permissions

| Role | Dashboard | All Reports | Export Reports | ID Card Print |
|---|---|---|---|---|
| Super Admin | ✓ | ✓ | ✓ | ✓ |
| School Admin | ✓ | ✓ | ✓ | ✓ |
| Principal | ✓ | ✓ | ✓ | ✓ |
| Teacher | ✗ | Limited (own class) | ✗ | ✓ (own class) |
| Clerk | ✓ | ✓ | ✓ | ✓ |
| School Nurse | ✓ (medical alerts) | Medical reports | ✓ | ✗ |

---

## 5. Functional Requirements

### 5.1 Dashboard — KPI Cards
**As a** Principal / School Admin,
**I want** to see key metrics at the top of the dashboard
**So that** I can quickly assess the school's overall student status.

**Requirements:**
- FR-01: Dashboard shall display a Total Students count (currently active students)
- FR-02: Dashboard shall display New Admissions count for the current academic session
- FR-03: Dashboard shall display YTD Attrition count (students who left this session)
- FR-04: Dashboard shall display Today's Attendance percentage
- FR-05: Each KPI card shall be clickable to navigate to the detailed student list filtered by that metric
- FR-06: KPI cards shall show a trend indicator vs previous year (e.g., ▲ 5% vs last year)

### 5.2 Dashboard — Charts
**As a** Principal / School Admin,
**I want** to see visual representations of student data
**So that** I can identify trends and patterns quickly.

**Requirements:**
- FR-07: Dashboard shall show a bar chart of Student Distribution by Class
- FR-08: Dashboard shall show a donut chart of Gender Ratio (Boys vs Girls)
- FR-09: Dashboard shall show a line chart of Admission Trend over the last 5 years
- FR-10: Dashboard shall show a table of Student Categories (General, OBC, SC/ST, RTE/EWS with counts)

### 5.3 Dashboard — Critical Alerts
**As a** School Admin / Principal,
**I want** to see actionable alerts on the dashboard
**So that** I can address issues that need immediate attention.

**Requirements:**
- FR-11: Dashboard shall alert when there are unverified student documents
- FR-12: Dashboard shall alert when any class has attendance below 75% for 3+ consecutive days
- FR-13: Dashboard shall alert when there are suspended students requiring review
- FR-14: Each alert shall be clickable to navigate to the relevant management screen

### 5.4 Dashboard — Quick Actions
**As a** School Admin / Clerk,
**I want** quick access buttons on the dashboard
**So that** I can perform common tasks without navigating through menus.

**Requirements:**
- FR-15: Dashboard shall provide a [+ New Admission] button
- FR-16: Dashboard shall provide a [Bulk Import] button for mass student data import
- FR-17: Dashboard shall provide an [ID Card Print] button

### 5.5 Class-wise Student Strength Report
**As a** Principal / Academic Coordinator,
**I want** a report showing student count per class and section
**So that** I can plan teacher allocation, classroom capacity, and monitor gender balance.

**Requirements:**
- FR-18: Report shall show total students per class-section
- FR-19: Report shall break down by gender (boys/girls count per class)
- FR-20: Report shall break down by caste category (General, OBC, SC/ST)
- FR-21: Report shall show RTE/EWS count per class
- FR-22: Report shall display the Class Teacher's name
- FR-23: User shall filter by Academic Session and Class range
- FR-24: Report shall include a stacked bar chart showing gender split per class

### 5.6 Admission Register Report
**As a** Clerk / School Admin,
**I want** a register of all new admissions in a given date range
**So that** I can submit it for government audit or maintain an admission ledger.

**Requirements:**
- FR-25: Report shall list: Admission No, Admission Date, Student Name, DOB, Gender
- FR-26: Report shall include Father and Mother names
- FR-27: Report shall include the student's address
- FR-28: Report shall include previous school name and TC number
- FR-29: User shall filter by Admission Date Range and Class

### 5.7 Student Medical Profile & Exceptions Report
**As a** School Nurse / PE Teacher,
**I want** a report of students with medical conditions or missing vaccinations
**So that** I can provide appropriate care and plan health interventions.

**Requirements:**
- FR-30: Report shall list: Student Name, Class-Section, Blood Group
- FR-31: Report shall show all allergies and chronic conditions
- FR-32: Report shall show emergency contact name and mobile number
- FR-33: User shall filter by "Has Allergy", "Has Condition", or Blood Group

### 5.8 Additional Reports
**As a** School Admin / Principal,
**I want** access to various standard reports
**So that** I can meet compliance requirements and analyze student data.

**Requirements:**
- FR-34: Caste Category Distribution Report — category-wise student counts
- FR-35: Age-wise Student Report — students grouped by age as of a reference date
- FR-36: Suspended/Inactive Student Report — students with left/suspended/withdrawn status
- FR-37: RTE/EWS Quota Report — students under RTE and EWS categories
- FR-38: Attendance Summary Report — individual student attendance percentages with filters by session, class, date range

### 5.9 Student ID Card Generation
**As a** School Admin / Clerk,
**I want** to generate ID cards for students
**So that** students have official school identification for daily use.

**Requirements:**
- FR-39: System shall support single and batch ID card printing
- FR-40: ID card shall include: student photo, name, admission number, class-section, and QR code
- FR-41: ID card layout shall be template-based and configurable

### 5.10 Missing Optional Subjects Report
**As a** Academic Coordinator / School Admin,
**I want** to see which students have not selected their optional subjects
**So that** I can follow up and ensure all students have made their subject choices.

**Requirements:**
- FR-42: Report shall be part of the student list view as a dedicated tab
- FR-43: Report shall identify students with incomplete subject selections for follow-up

### 5.11 Student Login Credentials
**As a** School Admin,
**I want** to send login credentials to selected students
**So that** students and parents can access their portals.

**Requirements:**
- FR-44: System shall allow selecting multiple students and sending their login credentials by email

---

## 6. Business Rules

| Rule ID | Rule Description |
|---|---|
| BR-01 | Dashboard data refreshes on every page load (real-time, not cached) |
| BR-02 | KPI trends compare current session data with the previous academic session |
| BR-03 | Attendance percentage is calculated as (Present count / Total marked) × 100 for the current date |
| BR-04 | Total Students count includes only those with `is_active = 1` and status = "Active" |
| BR-05 | New Admissions count includes students admitted between the current session's start and end dates |
| BR-06 | ID card templates are defined by the school admin and can include custom fields |
| BR-07 | All reports respect role-based data access (teachers see only their class data) |

---

## 7. Acceptance Criteria

| Criterion | Description |
|---|---|
| AC-01 | Dashboard loads within 3 seconds and shows all 4 KPI cards with correct data |
| AC-02 | Clicking a KPI card navigates to the student list with appropriate filters applied |
| AC-03 | All 4 charts render correctly with data from the current academic session |
| AC-04 | Critical alerts show real counts of unverified documents, low attendance classes, and suspended students |
| AC-05 | Class-wise Strength Report shows correct student counts per class-section |
| AC-06 | Admission Register includes all required fields for government audit |
| AC-07 | Medical Report correctly filters students by selected health condition |
| AC-08 | ID Card generates with correct student details and QR code within 5 seconds |
| AC-09 | Missing Optional Subjects tab correctly identifies students needing follow-up |

---

## 8. Dependencies

| Dependency | Description |
|---|---|
| BRD-01 — Student Onboarding | Core student data for all counts and reports |
| BRD-03 — Academic Journey | Session and class-section data for class-wise reports |
| BRD-04 — Health & Attendance | Medical data for health reports; attendance data for attendance reports |
| BRD-03 — Subject Selection | Optional subjects data for missing subjects report |
| Document Management | Document verification status for dashboard alerts |
| Template System | ID card layout templates must be pre-configured |

---

## 9. Assumptions

- The dashboard is viewed primarily by school leadership on desktop screens
- Report filters are applied client-side/postback (not AJAX)
- All reports are generated from real-time data, not from a data warehouse
- ID card QR codes use the student's unique identifier (employee code)
- Exported reports are formatted for A4/Letter paper size

---

*End of BRD-06*

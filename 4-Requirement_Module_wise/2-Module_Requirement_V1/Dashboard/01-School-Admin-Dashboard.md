# Business Requirements Document (BRD)
## Module: Dashboard
### Role: School Admin (Super User)

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **School Admin Dashboard** is the command center for the IT Admin or System Administrator of the school. It aggregates data from every single module across the database to provide a 30,000-foot view of the system's health, infrastructure, and ongoing pipeline configurations.

### 1.2 Why is this necessary? (Business Justification)
- **System Overview:** Admins need to know if the system is fully configured. For example, if the "Timetable Pipeline" is stuck at 40%, the admin knows teachers haven't submitted their availability yet.
- **Quick Navigation:** With over 20+ modules, the admin needs categorized "Module Cards" (Core Setup, Academics, Operations) to navigate quickly.

---

## 2. Document Scope
- **In-Scope:** The main `DashboardController.php`, `BaseDashboardController.php` metrics aggregation, Timetable Pipeline calculation, and Module Cards rendering.
- **Out-of-Scope:** Role-specific dashboards (Teacher/Principal) and Student Portal.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Global Safe Metrics Aggregation
The backend uses a `safeCount()` and `safeSum()` trait in `BaseDashboardController` to count rows while strictly respecting `deleted_at` (soft deletes) and `is_active` flags.
**Metrics Gathered:**
- **Users & Staff:** Students, Teachers, Employees, Users.
- **Infrastructure:** Classes, Sections, Subjects, Rooms.
- **LMS:** Active Exams, Quizzes, Quests, Homeworks.
- **Alerts:** Complaints, Notifications, Pending Evaluations, Open Grievances.

### FR-02: Chart Data Engines
The dashboard feeds data into frontend charts:
- **Students Per Class:** Groups `sch_class_section_jnt` by Class Ordinal and sums the `actual_total_student`.
- **Staff Breakdown:** Pie chart comparing Teachers vs Other Staff.
- **Timetable Pipeline Progress:** Calculates a percentage (%) completion based on the presence of data in 6 sequential tables: Groups -> Consolidations -> Teacher Availability -> Activities -> Slot Requirements -> Final Timetables.

### FR-03: Categorized Module Cards
Provides a heavily curated, icon-driven quick-access menu categorized by:
1. **Core Setup:** School Setup, Timetable Foundation, Smart Timetable.
2. **Student Management:** Profiles, Admissions, HPC Reports.
3. **Academics:** Exams, Syllabus, Question Bank.
4. **LMS:** Quizzes, Homework, Grievance Review, Proctoring Violations.
5. **Operations:** Transport, Cafeteria, Inventory, Complaints, HR, Notifications.

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Monitoring Timetable Progress
**As a** School Admin,
**I want to** see the percentage completion of the Timetable Pipeline on my dashboard,
**So that** I know if the school is ready for the new academic session.

**Acceptance Criteria:**
- **Given** I am on the Admin Dashboard, **When** I view the Pipeline card, **Then** the system checks `tt_requirement_consolidation`, `tt_teacher_availability`, etc., and displays a progress bar (e.g., 83% Complete).

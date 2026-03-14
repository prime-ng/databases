# Agent: School Domain Expert

## Role
Domain expert for school management business logic in the Prime-AI platform. Ensures all school-specific features follow educational domain rules.

## Before Starting
1. Read `.ai/memory/school-domain.md` — All school entities and relationships
2. Read `.ai/rules/school-rules.md` — Mandatory school domain rules

## Key Business Rules

### Academic Context
- **Every academic operation must have an active academic session.** Resolve it first.
- **Academic terms define scheduling periods.** Timetables, exams, and assessments are term-bound.
- **Class-Section is the fundamental student grouping.** Students belong to a Class+Section.

### Student Lifecycle
1. **Enrollment:** Student → Academic Session → Class+Section → Fee Assignment
2. **Daily:** Attendance → Teaching → Homework → Activities
3. **Assessment:** Quiz → Exam → Results → Report Card → HPC
4. **Year-end:** Promotion → Next Academic Session → New Class

### Teacher Lifecycle
1. **Setup:** Teacher → Profile → Subject Assignment → Capability
2. **Daily:** Availability → Timetable → Attendance → Teaching
3. **Assessment:** Create Questions → Conduct Exams → Grade Results
4. **Monitoring:** Workload Analysis → Substitution → Analytics

### Fee Collection Workflow
1. Fee Head Master → Define fee components (tuition, transport, lab, etc.)
2. Fee Structure → Assign to Class/Section with amounts
3. Fee Invoice → Generate per student per installment
4. Payment → Record receipt → Update balance
5. Concession/Scholarship → Apply before or after invoice
6. Fine → Auto-calculate for late payment

### Timetable Generation Workflow
1. Configure: Days, Periods, Shifts, Working Days
2. Setup: Activities (Class+Section+Subject+StudyFormat+Teacher)
3. Configure: Constraints (teacher limits, room requirements, etc.)
4. Generate: FETSolver (backtracking + greedy + rescue + forced)
5. Post-process: Room Allocation (RoomAllocationPass)
6. Review: Analytics (workload, utilization, violations)
7. Refine: Manual adjustments (swap, move, lock)
8. Publish: Activate timetable for the term
9. Maintain: Substitution management for absences

### Complaint Resolution Workflow
1. Raise: Student/Parent/Teacher files complaint with category
2. Assign: SLA-based routing to department
3. Action: Assigned staff takes action, logs it
4. Resolve: Resolution documented
5. Close: Complainant feedback

## Entity Relationship Rules

### Students
- Must have at least one Guardian linked
- Must be assigned to an Academic Session
- Must have a Class+Section assignment
- Fee invoices auto-generated based on fee structure
- Attendance tracked per subject per day

### Teachers
- Subject assignments define what they can teach
- Capabilities define their skill levels per subject
- Availability defines when they can be scheduled
- Workload analytics track actual vs planned periods

### Rooms
- Room types determine what activities can use them
- Capacity limits student count per activity
- Unavailability blocks scheduling in those periods
- Building association for building-change constraints

## Common School Workflows

### New Academic Year Setup
1. Create Academic Session
2. Define Terms/Semesters
3. Set up Classes and Sections
4. Assign Students to Sections
5. Assign Teachers to Subjects
6. Configure Fee Structure
7. Generate Timetable
8. Start Operations

### Mid-Year Transfers
1. Student transfer request
2. Update Class+Section assignment
3. Recalculate fee prorations
4. Update attendance records
5. Update timetable if needed

### Report Card Generation
1. Collect exam results per subject
2. Calculate grades based on grading system
3. Include attendance percentage
4. Include HPC assessment (if configured)
5. Generate PDF via DomPDF
6. Distribute to parents

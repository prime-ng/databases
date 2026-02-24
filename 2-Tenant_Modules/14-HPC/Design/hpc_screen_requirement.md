4. SCREEN REQUIREMENTS
Screen Set 1: Admin Configuration
SC-01: HPC Template Builder
```text
Purpose: Create/edit HPC templates from PDFs
Features:
- Upload PDF reference
- Define template structure (Parts → Sections → Rubrics)
- Configure grade range (BV1 to Grade 12)
- Set version control
- Preview template
- Clone existing template
Data Tables: hpc_templates, hpc_template_parts, hpc_template_sections, hpc_template_rubrics
```

SC-02: Circular Goals Manager
```text
Purpose: Configure NCF circular goals and competencies
Features:
- Add/Edit circular goals
- Map competencies to goals
- Link to classes
- Import from NCF repository
Data Tables: hpc_circular_goals, hpc_circular_goal_competency_jnt
```

SC-03: Learning Outcomes Mapper
```text
Purpose: Map outcomes to topics/subjects
Features:
- Create learning outcomes
- Link to Bloom's taxonomy
- Map to topics/lessons
- Map to questions
- Validate coverage
Data Tables: hpc_learning_outcomes, hpc_outcome_entity_jnt, hpc_outcome_question_jnt
```

SC-04: Activity Type Configurator
```text
Purpose: Define learning activity types
Features:
- Add activity types (Project, Discussion, Art, etc.)
- Configure assessment templates
- Set default rubrics
Data Tables: hpc_learning_activity_type, hpc_learning_activities
```

Screen Set 2: Teacher Interface
SC-05: My Class Dashboard
```text
Purpose: Teacher's home for HPC activities
Features:
- Class overview with student list
- Pending assessments count
- Upcoming activities
- Quick entry for attendance/observations
- Progress tracking charts
Data Sources: hpc_reports, hpc_report_items, attendance_students
```

SC-06: Part-A Data Entry
```text
Purpose: Capture general information
Features:
- Student selector dropdown
- Form fields matching Part-A (1)
- Parent information display (read-only from ERP)
- School information (auto-filled)
- Save as draft / Mark complete
- Photo capture/upload
Data Tables: hpc_report_items (with rubric mapping to Part-A fields)
```

SC-07: Attendance Manager
```text
Purpose: Monthly attendance tracking
Features:
- Calendar view per month
- Bulk mark attendance
- Working days configuration
- Low attendance reason capture
- Percentage calculation
Data Tables: attendance_students (existing), custom reason table
```

SC-08: Domain Assessment Dashboard
```text
Purpose: Central hub for all 5 domains
Features:
- Tabbed interface for each domain
- Student-wise view
- Competency selection
- Rubric-based assessment (Stream/Mountain/Sky or Beginner/Proficient/Advanced)
- Observational notes
- Evidence attachment
Data Tables: hpc_student_evaluation, hpc_report_items
```

SC-09: Activity Assessment Screen
```text
Purpose: Assess students for specific activities
Features:
- Select activity type
- Choose competencies being assessed
- Student-wise rubric selection
- Self-assessment collection (emoji-based for younger students)
- Peer assessment collection
- Teacher feedback
Data Tables: hpc_learning_activities, hpc_student_evaluation, hpc_report_items
```

SC-10: Teacher Feedback Form
```text
Purpose: End-term teacher observations
Features:
- Domain-wise strength/concern areas
- Free text observations
- Performance wheel shading (for Middle/Secondary)
- Areas of strength checklist
- Barriers to success checklist
- Recommendations
Data Tables: hpc_report_items
```

Screen Set 3: Student Interface
SC-11: Student Dashboard
```text
Purpose: Student's view of their progress
Features:
- Profile overview
- Recent activities
- Pending self-assessments
- Progress charts (simplified)
- Goal setting (for older students)
Data Sources: hpc_reports (student-specific)
```

SC-12: Self-Assessment Screen
```text
Purpose: Student self-reflection on activities
Features:
- Activity list
- Emoji-based assessment (Foundation/Preparatory)
- Statement-based assessment (Middle/Secondary)
- "I need help with" section
- "I am proud of" section
Data Tables: hpc_report_items
```

SC-13: Peer Assessment Screen
```text
Purpose: Assess peer performance
Features:
- Group activity selection
- Peer selector
- Assessment statements
- Open feedback
Data Tables: hpc_report_items
```

SC-14: My Goals & Aspirations
```text
Purpose: Student goal setting (Secondary)
Features:
- Career aspirations
- Skill gap analysis
- Goal setting with timeline
- Support identification
- Progress tracking
Data Tables: Custom goal-setting tables (to be created)
```

Screen Set 4: Parent Interface
SC-15: Parent Portal Dashboard
```text
Purpose: Parent view of child's progress
Features:
- Summary view of all domains
- Attendance overview
- Teacher feedback highlights
- Download reports
Data Sources: hpc_reports (child-specific)
```

SC-16: Parent Input Form
```text
Purpose: Capture parent observations
Features:
- Child's home behavior
- Resources available at home
- Support needs identification
- Open comments
Data Tables: hpc_report_items
```

SC-17: Parent-Teacher Communication
```text
Purpose: Facilitate parent-teacher partnership
Features:
- Message exchange
- Schedule meetings
- Share observations
- Action item tracking
Data Tables: Custom communication tables
```

Screen Set 5: Report Generation
SC-18: HPC Report Preview
```text
Purpose: Preview and validate report before finalizing
Features:
- PDF preview
- Page-by-page navigation
- Data validation warnings
- Missing data highlights
- Manual override option (with audit)
Data Sources: All hpc_report_items for the student
```

SC-19: Bulk Report Generator
```text
Purpose: Generate reports for entire class/section
Features:
- Class/Section selector
- Term selection
- Generate all / Selected students
- Download as ZIP
- Email distribution
Data Sources: hpc_reports with status = 'final'
```

SC-20: Credit Calculator
```text
Purpose: Calculate NCrF credit points
Features:
- Domain-wise credit input
- NCrF level selection
- Automatic credit point calculation
- Year-wise accumulation tracking
Data Tables: Credit calculation views, hpc_reports
```


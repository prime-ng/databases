# Screen Design Specification: Assessment Assignments
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Assessment Assignments Module**, enabling educators to assign assessments and exams to specific classes, student groups, or individual students with configurable availability windows, attempt limits, and visibility rules.

### 1.2 User Roles & Permissions
| Role         | Create | View | Update | Delete | Print | Export | Import |
|--------------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| PG Support   |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| School Admin |   ✓    |   ✓  |   ✓    |   ✗    |   ✓   |   ✗    |   ✗    |
| Principal    |   ✓    |   ✓  |   ✓    |   ✗    |   ✓   |   ✗    |   ✗    |
| Teacher      |   ✓    |   ✓  |   ✓    |   ✗    |   ✓   |   ✗    |   ✗    |
| Student      |   ✗    |   ✓  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |
| Parents      |   ✗    |   ✓  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |

### 1.3 Data Context

**Database Tables:**
- sch_assessment_assignments
  ├── id (BIGINT PRIMARY KEY)
  ├── assessment_id (FK to sch_assessments)
  ├── assignment_type (ENUM: CLASS, GROUP, INDIVIDUAL)
  ├── target_class_id (FK) - If CLASS assignment
  ├── target_student_group_id (FK) - If GROUP assignment
  ├── target_student_id (FK) - If INDIVIDUAL assignment
  ├── assigned_date (DATE)
  ├── availability_start (DATETIME) - When students can start
  ├── availability_end (DATETIME) - When students must finish
  ├── max_attempts (INT) - 1, 2, 3, or unlimited
  ├── show_results_to_student (BOOLEAN) - Can student see score?
  ├── show_answers (BOOLEAN) - Can student see correct answers?
  ├── assigned_by (FK to sys_users)
  └── created_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Assessment Assignments List
**Route:** `/curriculum/assessments/{assessmentId}/assignments`

#### 2.1.1 Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ ASSESSMENT ASSIGNMENTS: Unit 3 - Photosynthesis Assessment                 │
├────────────────────────────────────────────────────────────────────────────┤
│
│ Filter: [Type: All ▼] [Status: All ▼] [Class: All ▼]
│ Search: [Search by class/group/student...]
│
│ ┌─────┬──────────────────────┬──────────┬────────┬──────────┬────────────┐
│ │ ID  │ Assigned To          │ Type     │ Start  │ End      │ Attempts   │
│ ├─────┼──────────────────────┼──────────┼────────┼──────────┼────────────┤
│ │ A1  │ Class IX-A           │ CLASS    │ 2024   │ 2024     │ 1          │
│ │     │ (50 students)        │          │ -12-01 │ -12-05   │ (Limited)  │
│ ├─────┼──────────────────────┼──────────┼────────┼──────────┼────────────┤
│ │ A2  │ Class IX-B           │ CLASS    │ 2024   │ 2024     │ 1          │
│ │     │ (48 students)        │          │ -12-01 │ -12-05   │ (Limited)  │
│ ├─────┼──────────────────────┼──────────┼────────┼──────────┼────────────┤
│ │ A3  │ Advanced Group       │ GROUP    │ 2024   │ 2024     │ 2          │
│ │     │ (12 students)        │          │ -12-01 │ -12-10   │ (Limited)  │
│ ├─────┼──────────────────────┼──────────┼────────┼──────────┼────────────┤
│ │ A4  │ Arjun (STU-123)     │ INDIVIDUAL│ 2024  │ 2024     │ Unlimited  │
│ │     │                      │          │ -12-01 │ -12-20   │            │
│ └─────┴──────────────────────┴──────────┴────────┴──────────┴────────────┘
│
│ [Assign to Class] [Assign to Group] [Assign to Student] [View Results]
│
│ ─────────────────────────────────────────────────────────────────────────
│ ASSIGNMENT SUMMARY:
│ Total Assignments: 4
│ Total Students Assigned: 110 (50+48+12+1)
│ Attempts Completed: 89/110 (81%)
│ Average Score: 72%
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.2 Create Assignment
**Route:** `/curriculum/assessments/{assessmentId}/assignments/new`

#### 2.2.1 Layout (Multi-Step Form)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ ASSIGN ASSESSMENT                                      [Save] [Cancel]      │
├────────────────────────────────────────────────────────────────────────────┤
│
│ STEP 1: SELECT ASSIGNMENT TARGET
│ ═════════════════════════════════════════════════════════════════════════
│
│ Assessment: Unit 3 - Photosynthesis Assessment (FORMATIVE)
│ Marks: 50 | Passing: 20 marks
│
│ Assign To: [Select Type ▼]
│
│ ○ Entire Class
│   Select Class *      [IX-A ▼]  (50 students)
│
│ ○ Student Group
│   Select Group *      [Advanced Group ▼]  (12 students)
│   Group Composition: Students performing >85% in similar topics
│
│ ○ Individual Students
│   Select Students *   [Search/Add Students]
│   [Add Arjun] [Add Priya] [Add Neha] ... [+ Add More]
│   Selected: 5 students
│
│
│ STEP 2: AVAILABILITY WINDOW
│ ═════════════════════════════════════════════════════════════════════════
│
│ Assessment Available From *    [01-Dec-2024] at [10:00 AM]
│ (When students can start the assessment)
│
│ Assessment Due By *            [05-Dec-2024] at [11:59 PM]
│ (Final deadline to submit)
│
│ Assessment Status After Due:
│ ○ Assessment closes (students cannot submit)
│ ○ Assessment remains open (students can still submit, but marked late)
│
│
│ STEP 3: ATTEMPT SETTINGS
│ ═════════════════════════════════════════════════════════════════════════
│
│ Maximum Attempts Allowed *
│ ○ 1 (Single attempt - typical for formal assessment)
│ ○ 2 (Two chances)
│ ○ 3 (Three chances)
│ ● Unlimited (Students can retake multiple times)
│
│ Attempt Visibility:
│ ☑ Show previous attempt results to student
│ ☑ Show timing/submission history
│
│
│ STEP 4: RESULT VISIBILITY
│ ═════════════════════════════════════════════════════════════════════════
│
│ When assignment is due:
│ ☑ Show score to students immediately after submission
│ ☑ Show correct answers after submission
│ ☐ Hide results until teacher reviews
│ ☐ Hide results until specific date: [10-Dec-2024]
│
│ Display to Parents:
│ ○ Parents cannot see assessment results
│ ● Parents can see score and pass/fail status
│ ○ Parents can see detailed results with answers
│
│ Display to Student:
│ ☑ Student can print result slip
│ ☑ Student can download PDF report
│
│
│ STEP 5: REVIEW & ASSIGN
│ ═════════════════════════════════════════════════════════════════════════
│
│ Assignment Summary:
│ • Assessment: Unit 3 Assessment (50 marks, FORMATIVE)
│ • Assign To: Class IX-A (50 students)
│ • Available: 01-Dec-2024 10:00 AM to 05-Dec-2024 11:59 PM
│ • Duration: 5 days (120 hours)
│ • Attempts: 1 attempt
│ • Results Visibility: Immediate (show score and answers)
│
│ [Back] [Assign Assessment] [Cancel]
│
│ Note: Assignment notification will be sent to all students
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3 Assignment Results Dashboard
**Route:** `/curriculum/assessments/{assessmentId}/assignments/{assignmentId}/results`

#### 2.3.1 Layout (Class Results)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ ASSIGNMENT RESULTS: Unit 3 Assessment → Class IX-A                          │
├────────────────────────────────────────────────────────────────────────────┤
│
│ Assignment Status: [Live - Due: 05-Dec-2024 11:59 PM]
│ Total Students: 50 | Completed: 45 (90%) | In Progress: 2 | Not Started: 3
│
│ ─────────────────────────────────────────────────────────────────────────
│ CLASS PERFORMANCE SNAPSHOT:
│
│ Average Score: 72% (36/50 marks)
│ Pass Rate: 88% (44 students passed ≥20 marks)
│ Highest: 95% (Arjun Singh)
│ Lowest: 35% (Rahul Patel - Below passing)
│
│ Score Distribution:
│ A (90-100): 12 students ████████████
│ B (80-89):  18 students ██████████████████
│ C (70-79):  14 students ██████████████
│ D (60-69):  5  students █████
│ E (<60):    1  student  █
│
│ ─────────────────────────────────────────────────────────────────────────
│ DETAILED RESULTS:
│
│ Sort: [Score ▼] [Name ▼] [Status ▼]
│
│ ┌─────┬──────────────────────┬──────────┬────────┬──────────┬──────────┐
│ │ Rank│ Student              │ Score    │ Grade  │ Status   │ Submitted│
│ ├─────┼──────────────────────┼──────────┼────────┼──────────┼──────────┤
│ │ 1   │ Arjun Singh          │ 47/50    │ A      │ ✓ Subm   │ 03-Dec   │
│ │     │ (STU-001)            │ (94%)    │        │          │ 14:23    │
│ ├─────┼──────────────────────┼──────────┼────────┼──────────┼──────────┤
│ │ 2   │ Priya Sharma         │ 45/50    │ A      │ ✓ Subm   │ 04-Dec   │
│ │     │ (STU-002)            │ (90%)    │        │          │ 10:45    │
│ ├─────┼──────────────────────┼──────────┼────────┼──────────┼──────────┤
│ │ 3   │ Neha Gupta           │ 44/50    │ A      │ ✓ Subm   │ 02-Dec   │
│ │     │ (STU-003)            │ (88%)    │        │          │ 09:12    │
│ │ ...  │                     │          │        │          │          │
│ ├─────┼──────────────────────┼──────────┼────────┼──────────┼──────────┤
│ │ 48  │ Vikram Mishra        │ 28/50    │ E      │ ✓ Subm   │ 04-Dec   │
│ │     │ (STU-048)            │ (56%)    │        │          │ 11:30    │
│ ├─────┼──────────────────────┼──────────┼────────┼──────────┼──────────┤
│ │ -   │ Rohit Joshi          │ -        │ -      │ ⏳ In Pro │ -        │
│ │     │ (STU-049)            │          │        │          │          │
│ ├─────┼──────────────────────┼──────────┼────────┼──────────┼──────────┤
│ │ -   │ Sanjay Kumar         │ -        │ -      │ ✗ Not    │ -        │
│ │     │ (STU-050)            │          │        │ Started  │          │
│ └─────┴──────────────────────┴──────────┴────────┴──────────┴──────────┘
│
│ [Export Results to Excel] [Print Report] [Send Reminder to Not Started]
│ [View Individual Answer] [View Analytics] [Download All Answer Scripts]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.4 Student Assignment Dashboard
**Route:** `/student/assignments`

#### 2.4.1 Layout (Student View)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ MY ASSIGNMENTS                                                              │
├────────────────────────────────────────────────────────────────────────────┤
│
│ Filter: [Subject: All ▼] [Status: All ▼] [Class: All ▼]
│
│ ┌──────────────────────────────────────────────────────────────────────────┐
│ │ ACTIVE ASSIGNMENTS (Due Soon)                                            │
│ │                                                                          │
│ │ [Unit 3 - Photosynthesis Assessment]                                    │
│ │ Status: Assigned | Due: 05-Dec-2024 (2 days left)                      │
│ │ Subject: Biology | Class: IX-A                                          │
│ │ Marks: 50 | Questions: 27 | Time: 90 minutes                            │
│ │                                                                          │
│ │ Progress: Not Started                                                  │
│ │ Attempts: 0/1 remaining                                                │
│ │                                                                          │
│ │ [Start Assessment] [View Assignment Details] [Remind Me Later]          │
│ └──────────────────────────────────────────────────────────────────────────┘
│
│ ┌──────────────────────────────────────────────────────────────────────────┐
│ │ COMPLETED ASSIGNMENTS (View Results)                                     │
│ │                                                                          │
│ │ [Ch-2 Respiration Quiz]                                                 │
│ │ Status: Submitted | Completed: 02-Dec-2024                              │
│ │ Subject: Biology | Class: IX-A                                          │
│ │ Score: 45/50 marks (90%) | Grade: A | Pass: ✓ Yes                      │
│ │ Attempts Used: 1/1                                                      │
│ │ Feedback: "Excellent understanding of dark reactions!"                  │
│ │                                                                          │
│ │ [View Results] [Download Report] [Review Answers]                       │
│ └──────────────────────────────────────────────────────────────────────────┘
│
│ ┌──────────────────────────────────────────────────────────────────────────┐
│ │ UPCOMING ASSIGNMENTS (Starts in Future)                                  │
│ │                                                                          │
│ │ [Mock Board Exam - Biology]                                             │
│ │ Status: Scheduled | Starts: 15-Dec-2024 | Due: 15-Dec-2024              │
│ │ Subject: Biology | Class: IX-A                                          │
│ │ Marks: 100 | Questions: 45 | Time: 180 minutes                          │
│ │                                                                          │
│ │ Assignment starts in 10 days                                            │
│ │                                                                          │
│ │ [Add to Calendar] [Remind Me] [View Details]                            │
│ └──────────────────────────────────────────────────────────────────────────┘
│
│ Showing 3 of 12 assignments | [View All] [Calendar View]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Assignment
```json
POST /api/v1/assessments/{assessmentId}/assignments
{
  "assignment_type": "CLASS",
  "target_class_id": 5,
  "availability_start": "2024-12-01T10:00:00Z",
  "availability_end": "2024-12-05T23:59:00Z",
  "max_attempts": 1,
  "show_results_to_student": true,
  "show_answers": true,
  "show_results_to_parents": true
}
```

### 3.2 Assignment Created Response
```json
{
  "success": true,
  "data": {
    "id": "ASGNM-1",
    "assessment_id": "A001",
    "target_type": "CLASS",
    "target_count": 50,
    "availability_window": "01-Dec to 05-Dec",
    "created_at": "2024-12-01T08:00:00Z",
    "notification_status": "sent_to_50_students"
  }
}
```

### 3.3 Get Assignment Results
```
GET /api/v1/assessments/{assessmentId}/assignments/{assignmentId}/results
Response: Detailed results for all students in assignment
```

### 3.4 Update Assignment
```json
PATCH /api/v1/assessments/{assessmentId}/assignments/{assignmentId}
{
  "availability_end": "2024-12-06T23:59:00Z",
  "max_attempts": 2
}
```

---

## 4. USER WORKFLOWS

### 4.1 Assign Assessment to Class Workflow
**Goal:** Make assessment available to all students in class

1. Click **[Assign to Class]**
2. Select class: "IX-A" (50 students)
3. Set availability:
   - Start: 01-Dec-2024 10:00 AM
   - End: 05-Dec-2024 11:59 PM (5 days)
4. Set attempts: 1 (single attempt)
5. Configure results:
   - ✓ Show score immediately
   - ✓ Show answers after submission
6. Click **[Assign Assessment]**
7. System sends notification to 50 students
8. Assessment appears in student dashboard

---

### 4.2 View Class Results
**Goal:** See how all students performed

1. Click assignment: "Unit 3 Assessment"
2. Click **[View Results]**
3. See class overview:
   - Average: 72%
   - Pass rate: 88%
   - Distribution: A/B/C/D/E
4. Click student name → See detailed answers
5. Export results to Excel

---

### 4.3 Send Reminder to Incomplete Students
**Goal:** Remind students who haven't submitted

1. Open assignment results
2. See: "Not Started: 3"
3. Click **[Send Reminder]**
4. System sends email to 3 non-starters:
   - "Assignment due in 2 days"
   - Direct link to start assessment
5. Reminders sent

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Status Indicators
- Active: Green badge
- Completed: Blue badge
- In Progress: Orange badge
- Overdue: Red badge
- Not Started: Gray badge

### 5.2 Results Display
- Scores: Large font, color-coded (A-E)
- Pass status: Green checkmark or red X
- Progress bars: Visual fill 0-100%

---

## 6. TESTING CHECKLIST

### 6.1 Functional Testing
- [ ] Assign to entire class (50+ students)
- [ ] Assign to student group
- [ ] Assign to individual student
- [ ] Set availability window
- [ ] Prevent access before start date
- [ ] Prevent submission after end date
- [ ] Limit attempts (1, 2, 3, unlimited)
- [ ] Show/hide results by setting
- [ ] Send notifications to students
- [ ] Export results to Excel
- [ ] View individual student answers

### 6.2 UI/UX Testing
- [ ] Assignment appears in student dashboard
- [ ] Status clearly indicated
- [ ] Results table readable (50+ rows)
- [ ] Sort/filter functional
- [ ] Responsive on mobile

### 6.3 Integration Testing
- [ ] Attempts linked to assignment
- [ ] Results stored correctly
- [ ] Notifications sent to correct students
- [ ] Parents see results if enabled

### 6.4 Performance Testing
- [ ] Load results for 200 students <3 sec
- [ ] Export 100 student results <5 sec
- [ ] Display class performance dashboard quickly

### 6.5 Accessibility Testing
- [ ] Assignment list keyboard navigable
- [ ] Date picker accessible
- [ ] Results table has headers
- [ ] Color not sole indicator of status

---

## 7. FUTURE ENHANCEMENTS

- **Smart Assignment:** Auto-assign based on student performance
- **Staggered Assignments:** Assign different start times per group
- **Conditional Assignments:** Show Assignment B only after passing A
- **Progress Reminders:** Auto-send reminders at 2 days, 1 day, 1 hour
- **Performance Tracking:** Show student progress vs. class average
- **Parent Notifications:** Email parents about assignment grades
- **Assignment Analytics:** Which assignment has lowest pass rate
- **Peer Comparison:** Show student where they rank in class
- **Adaptive Assignments:** Difficulty adjusts based on performance
- **Assignment Calendar:** Sync assignments to student calendars


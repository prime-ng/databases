# LMS Module — LMS Report Screen Design (v2.5)
# New Reports — Homework, Exam & Cross-Module Analytics

---

## Table of Contents

1. [Rep-7:  Homework Submission Tracker](#rep-7-homework-submission-tracker)
2. [Rep-8:  Homework Performance Analysis (Class-wise Marks)](#rep-8-homework-performance-analysis)
3. [Rep-9:  Exam Result Report (Class-wise)](#rep-9-exam-result-report)
4. [Rep-10: Student Exam Performance History](#rep-10-student-exam-performance-history)
5. [Rep-11: Exam Subject-wise Comparison (Cross-Subject Matrix)](#rep-11-exam-subject-wise-comparison)
6. [Rep-12: LMS Activity Summary Dashboard](#rep-12-lms-activity-summary-dashboard)

Data Sources:
- `lms_homework` / `lms_homework_assignments` / `lms_homework_submissions`
- `lms_quizzes` / `lms_quiz_quest_attempts` / `lms_quiz_quest_results`
- `lms_quests` / `lms_quest_allocations`
- `lms_exams` / `lms_exam_papers` / `lms_exam_attempts` / `lms_exam_results` / `lms_exam_marks_entry`

---

## Main Screen — LMS Analytical Reports (Extended)

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  PRIME ERP  |  LMS – Analytical Reports                                                                                      [User Profile] │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                       Breadcrumb: LMS > Analytical Reports  │
│┌─ Tabs (LMS Reports) ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐│
││ [HW Submission]  [HW Performance]  [Exam Result]  [Student Exam History]  [Exam Comparison]  [LMS Activity Summary]  [Config: Auto-Quiz]  ││
││                                                                                                                                           ││
│└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘│
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


---

## Rep-7: Homework Submission Tracker

**Report Title:** Homework Submission Tracker
**Sub-Title:** Class-wise Homework Submission & Grading Status Report

### Rep-7A: Filter Panel

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Rep-7 : Homework Submission Tracker  —  Class-wise Homework Submission & Grading Status                                                    │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│  *Class       : [ Select Class              ▼ ]   *Section      : [ Select Section         ▼ ]    Subject    : [ Select Subject     ▼ ]     │
│  *Date From   : [ DD-MM-YYYY                ]     *Date To       : [ DD-MM-YYYY            ]       HW Status  : [ All / Pending /   ▼ ]     │
│   Lesson      : [ Select Lesson (Optional)  ▼ ]    Topic        : [ Select Topic (Opt.)    ▼ ]                  [ Graded / Late ]           │
│                                                                                                                                             │
│                                                                                                    [Search]    [Clear]    [PDF]   [Excel]   │
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


### Rep-7B: Report Output — Section 1: Homework Summary

One row per Homework. Shows overall submission health at a glance.

┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Homework Summary                                                                                                       Total H.W. : 12    │
├──────┬────────────────────────────┬───────────┬────────────┬──────────┬──────────┬──────────┬──────────┬──────────┬────────────────────────┤
│  #   │  Homework Title            │ Assign Dt │  Due Date  │ # Asgnd. │ # Subm.  │ # Late   │ # Graded │ # Resubm │  Pending               │
├──────┼────────────────────────────┼───────────┼────────────┼──────────┼──────────┼──────────┼──────────┼──────────┼────────────────────────┤
│  1   │ Rational Numbers – Topic-1 │ 01-Jan-25 │ 03-Jan-25  │    34    │   32     │    2     │   30     │    1     │    2                   │
│  2   │ Playing With Numbers T-1   │ 02-Jan-25 │ 04-Jan-25  │    34    │   34     │    0     │   34     │    0     │    0                   │
│  3   │ Rational Numbers – Topic-2 │ 03-Jan-25 │ 06-Jan-25  │    34    │   29     │    3     │   25     │    2     │    5                   │
│  4   │ Square & Square Roots T-1  │ 06-Jan-25 │ 08-Jan-25  │    34    │   28     │    4     │   20     │    3     │    6                   │
│  5   │ Algebra – Introduction     │ 07-Jan-25 │ 09-Jan-25  │    34    │   34     │    1     │   34     │    0     │    0                   │
│  ... │  ... (7 more rows)         │    ...    │    ...     │   ...    │   ...    │   ...    │   ...    │   ...    │   ...                  │
├──────┴────────────────────────────┴───────────┴────────────┴──────────┴──────────┴──────────┴──────────┴──────────┴────────────────────────┤
│  Totals :  # Assigned = 408   # Submitted = 389   # Late = 28   # Graded = 360   # Resubmit Requested = 12   # Pending = 19                │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
  * Click on a Homework row to expand student-level detail (Section 2 below)


### Rep-7C: Report Output — Section 2: Student-wise Submission Detail

(Shown on row-click / or filtered by selecting a specific Homework from Section 1)

┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Student Detail  :  Rational Numbers – Topic-1  |  Assign Date: 01-Jan-25  |  Due Date: 03-Jan-25  |  Max Marks: 10                       │
├─────┬──────────────────────────┬──────────────────┬──────────┬────────┬────────────┬──────────┬──────────┬────────────────────────────────┤
│  #  │  Student Name            │  Submitted On    │  Status  │  Late  │ Marks / 10 │  Grade   │ Resubmit │  Teacher Feedback              │
├─────┼──────────────────────────┼──────────────────┼──────────┼────────┼────────────┼──────────┼──────────┼────────────────────────────────┤
│  1  │ Meera Sharma             │  02-Jan-25 10:15 │ Graded   │   No   │    9.0     │    A     │    No    │  Excellent work                │
│  2  │ Ravi Kumar               │  03-Jan-25 23:50 │ Graded   │  Yes   │    7.5     │    B+    │    No    │  Good but late                 │
│  3  │ Ritika Verma             │  02-Jan-25 09:00 │ Graded   │   No   │    8.5     │    A     │    No    │  Well done                     │
│  4  │ Neha Sharma              │  02-Jan-25 14:30 │ Graded   │   No   │    6.0     │    B     │   Yes    │  Redo Q3 and Q5                │
│  5  │ Ankit Kumar              │        —         │ Pending  │   —    │     —      │    —     │    —     │  —                             │
│  6  │ Ayush Kumar              │  03-Jan-25 08:45 │ Graded   │   No   │    5.0     │    C     │   Yes    │  Needs improvement             │
│  7  │ Divya Sharma             │  01-Jan-25 20:10 │ Graded   │   No   │   10.0     │   A+     │    No    │  Perfect                       │
│  8  │ Isha Mehta               │  04-Jan-25 07:00 │ Graded   │  Yes   │    4.0     │    D     │   Yes    │  Please redo sections 1-3      │
│  ... │  ... (26 more rows)     │       ...        │  ...     │  ...   │    ...     │   ...    │   ...    │  ...                           │
│ 34  │ Anushka Rani             │  02-Jan-25 11:00 │ Graded   │   No   │    8.0     │    A     │    No    │  Good effort                   │
└─────┴──────────────────────────┴──────────────────┴──────────┴────────┴────────────┴──────────┴──────────┴────────────────────────────────┘
  * Status values: Graded | Submitted (Pending Grading) | Resubmission Requested | Pending (Not Submitted)
  * Late = submitted after Due Date


### Rep-7D: Summary

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Summary  :  Rational Numbers – Topic-1                                                                                                     │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Total Students : 34    Submitted : 32    Pending : 2    Late Submissions : 2    Graded : 30    Resubmit Requested : 3                      │
│  Class Average Marks : 7.4 / 10   (74%)          Highest : 10.0     Lowest : 4.0                                                            │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


Notes:
- Submission Status filter uses `lms_homework_submissions.status_id` (SUBMITTED / GRADED / RESUBMISSION_REQUESTED).
- Late flag uses `lms_homework_submissions.is_late`.
- Marks = `marks_obtained`. Grade calculated from school grade config.
- `resubmission_count` shows how many times student has resubmitted.


---

## Rep-8: Homework Performance Analysis

**Report Title:** Homework Performance Analysis
**Sub-Title:** Class-wise Marks Obtained in Homework (Student × Homework Matrix)

### Rep-8A: Filter Panel

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Rep-8 : Homework Performance Analysis  —  Class-wise Marks in Homework                                                                     │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│  *Class       : [ Select Class              ▼ ]   *Section      : [ Select Section         ▼ ]   *Subject   : [ Select Subject      ▼ ]     │
│  *Date From   : [ DD-MM-YYYY                ]     *Date To       : [ DD-MM-YYYY            ]      Gradable   : [ Yes / No / Both     ▼ ]    │
│   Lesson      : [ Select Lesson (Optional)  ▼ ]    Topic        : [ Select Topic (Opt.)    ▼ ]                                              │
│                                                                                                                                             │
│                                                                                                    [Search]    [Clear]    [PDF]   [Excel]   │
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


### Rep-8B: Report Output — Student × Homework Matrix

Rows = Students | Columns = Homework (by assign date) | Cell = Marks Obtained / Max Marks

┌───────────────────────────┬────────────────────┬────────────────────┬────────────────────┬────────────────────┬──────┬──────────┬────────┐
│  Student Name             │ HW-1 (01-Jan) /10  │ HW-2 (02-Jan) /10  │ HW-3 (03-Jan) /15  │ HW-4 (06-Jan) /10  │  ... │ Total %  │  Grade │
├───────────────────────────┼────────────────────┼────────────────────┼────────────────────┼────────────────────┼──────┼──────────┼────────┤
│  Meera Sharma             │      9.0           │      10.0          │      13.5          │      8.5           │  ... │  91.1%   │   A+   │
│  Ravi Kumar               │      7.5 (Late)    │       8.0          │      10.0          │      6.0           │  ... │  77.3%   │   B+   │
│  Ritika Verma             │      8.5           │       9.5          │      12.0          │      9.0           │  ... │  86.7%   │   A    │
│  Neha Sharma              │      6.0           │       7.0          │       NS           │      5.0           │  ... │  64.4%   │   C    │
│  Ankit Kumar              │       NS           │       NS           │       NS           │       NS           │  ... │    —     │   —    │
│  Ayush Kumar              │      5.0           │       6.5          │       9.0          │      4.5           │  ... │  66.7%   │   C+   │
│  Divya Sharma             │     10.0           │      10.0          │      15.0          │     10.0           │  ... │ 100.0%   │   A+   │
│  Isha Mehta               │      4.0 (Late)    │       5.5          │       7.0          │      3.5           │  ... │  53.3%   │   D+   │
│  ...                      │        ...         │        ...         │        ...         │        ...         │  ... │   ...    │  ...   │
├───────────────────────────┼────────────────────┼────────────────────┼────────────────────┼────────────────────┼──────┼──────────┼────────┤
│  Class Average            │      7.4 (74%)     │      8.1 (81%)     │     11.2 (75%)     │      6.9 (69%)     │  ... │  76.6%   │   B+   │
└───────────────────────────┴────────────────────┴────────────────────┴────────────────────┴────────────────────┴──────┴──────────┴────────┘
  * NS  = Not Submitted  * (Late) = submitted after Due Date  * Cells colour-coded by % score


### Rep-8C: Summary

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Summary                                                                                                                                    │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Total Students : 34    Total HW Assigned : 12    Class Average : 76.6%    Highest : 100.0%    Lowest : 53.3%                               │
│  # Not Submitted (NS) : 8    # Late Submissions : 6    # Resubmit Requested : 5                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


Colour Coding (applied to cell marks %):
┌──────────────────┬──────────────────────────────────────┐
│  Colour          │  Category                            │
├──────────────────┼──────────────────────────────────────┤
│  RED             │  Struggling       (Below 35%)        │
│  ORANGE          │  Needs Attention  (35% - 49%)        │
│  YELLOW          │  Satisfactory     (50% - 69%)        │
│  LIGHT GREEN     │  Good             (70% - 84%)        │
│  DARK GREEN      │  Outstanding      (85% - 100%)       │
└──────────────────┴──────────────────────────────────────┘


Notes:
- Cell value = `marks_obtained / max_marks × 100` from `lms_homework_submissions`.
- Total % = aggregate across all homeworks in the selected date range.
- Grade column derived from school-configured grade ranges.
- Only gradable homeworks (`is_gradable = true`) shown when Gradable filter = Yes.


---

## Rep-9: Exam Result Report

**Report Title:** Exam Result Report
**Sub-Title:** Class-wise Exam Results — Marks, Grade, Division & Rank

### Rep-9A: Filter Panel

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Rep-9 : Exam Result Report  —  Class-wise Exam Results                                                                                     │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│  *Exam        : [ Select Exam               ▼ ]   *Subject (Paper): [ Select Exam Paper    ▼ ]                                              │
│  *Class       : [ Select Class              ▼ ]    Section         : [ Select Section      ▼ ]                                              │
│   Mode        : [ Online / Offline / Both   ▼ ]    Result Status   : [ All / Pass / Fail / Absent ▼ ]                                       │
│                                                                                                                                             │
│  Note: Only Exam and Subject are compulsory.                               [Search]    [Clear]    [PDF]    [Excel]    [Report Card PDF]     │
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


### Rep-9B: Report Output

┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Exam Result Report  :  Mid-Term Exam Jan-2025  |  Subject: Mathematics  |  Class 8 – A                                                   │
├─────┬────────────────────────────┬──────────────┬────────────────┬────────┬───────┬───────────┬──────────┬────────┬───────────────────────┤
│  #  │  Student Name              │  Mode        │  Total Marks   │ Marks  │   %   │   Grade   │ Division │ Result │  Rank in Class        │
├─────┼────────────────────────────┼──────────────┼────────────────┼────────┼───────┼───────────┼──────────┼────────┼───────────────────────┤
│  1  │ Meera Sharma               │  Online      │     100        │  92    │ 92.0% │    A+     │   I      │  PASS  │    2                  │
│  2  │ Ravi Kumar                 │  Online      │     100        │  78    │ 78.0% │    B+     │   II     │  PASS  │    8                  │
│  3  │ Ritika Verma               │  Online      │     100        │  88    │ 88.0% │    A      │   I      │  PASS  │    4                  │
│  4  │ Neha Sharma                │  Online      │     100        │  74    │ 74.0% │    B      │   II     │  PASS  │   11                  │
│  5  │ Ankit Kumar                │  Offline     │     100        │   —    │   —   │    —      │   —      │ ABSENT │    —                  │
│  6  │ Ayush Kumar                │  Online      │     100        │  55    │ 55.0% │    C      │   II     │  PASS  │   20                  │
│  7  │ Divya Sharma               │  Online      │     100        │  97    │ 97.0% │    A+     │   I      │  PASS  │    1                  │
│  8  │ Isha Mehta                 │  Online      │     100        │  32    │ 32.0% │    F      │   —      │  FAIL  │   27                  │
│  9  │ Krishna Verma              │  Online      │     100        │  61    │ 61.0% │    C+     │   II     │  PASS  │   18                  │
│ 10  │ Pranav Kumar               │  Online      │     100        │  84    │ 84.0% │    A      │   I      │  PASS  │    5                  │
│ ... │  ... (17 more rows)        │     ...      │     ...        │  ...   │  ...  │   ...     │   ...    │  ...   │   ...                 │
│ 27  │ Anushka Rani               │  Online      │     100        │  81    │ 81.0% │    A      │   I      │  PASS  │    6                  │
└─────┴────────────────────────────┴──────────────┴────────────────┴────────┴───────┴───────────┴──────────┴────────┴───────────────────────┘
  * Marks from `lms_exam_results.total_marks_obtained`  * Grade from `lms_exam_results.grade_obtained`
  * Division: I = 60%+  II = 45-59%  * Result: PASS / FAIL / ABSENT


### Rep-9C: Summary

┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Summary                                                                                                                                   │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Total Students : 27    Present : 26    Absent : 1    Passed : 24    Failed : 2    Pass % : 92.3%                                          │
│  Class Average : 72.4%     Highest : 97.0% (Divya Sharma)     Lowest : 32.0% (Isha Mehta)                                                  │
├────────────┬────────────┬────────────┬────────────┬────────────┬────────────┬────────────┬────────────┬────────────────────────────────────┤
│  A+ (90%+) │  A (80-89%)│  B+ (75-79)│  B (60-74) │  C+ (55-59)│  C (50-54) │  D (40-49) │  F (<40%)  │  Absent                            │
├────────────┼────────────┼────────────┼────────────┼────────────┼────────────┼────────────┼────────────┼────────────────────────────────────┤
│     3      │     6      │     4      │     7      │     2      │     2      │     1      │     1      │     1                              │
└────────────┴────────────┴────────────┴────────────┴────────────┴────────────┴────────────┴────────────┴────────────────────────────────────┘


Colour Coding (% column):
┌──────────────────┬──────────────────────────────────────┐
│  Colour          │  Category                            │
├──────────────────┼──────────────────────────────────────┤
│  RED             │  Fail / Below 35%                    │
│  ORANGE          │  D Grade (35% - 49%)                 │
│  YELLOW          │  C Grade (50% - 59%)                 │
│  LIGHT GREEN     │  B/B+ Grade (60% - 79%)              │
│  DARK GREEN      │  A/A+ Grade (80% - 100%)             │
└──────────────────┴──────────────────────────────────────┘


Notes:
- Marks source: `lms_exam_results` (populated after teacher marks entry via `lms_exam_marks_entry`).
- Absent students: `lms_exam_attempts.status = ABSENT` or `lms_exam_results.result_status = ABSENT`.
- [Report Card PDF] button generates individual student report cards via DomPDF.
- Mode = ONLINE (attempt via portal) or OFFLINE (paper exam, marks entered manually).


---

## Rep-10: Student Exam Performance History

**Report Title:** Student Exam Performance History
**Sub-Title:** Student's Exam-wise Results Over Time

### Rep-10A: Filter Panel

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Rep-10 : Student Exam Performance History  —  Student's Exam Results Over Time                                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│  *Student     : [ Select Student            ▼ ]    Exam Type     : [ Select Exam Type      ▼ ]                                              │
│  *Date From   : [ DD-MM-YYYY                ]     *Date To        : [ DD-MM-YYYY           ]                                                │
│   Subject     : [ Select Subject (Optional) ▼ ]    Result Status : [ All / Pass / Fail     ▼ ]                                              │
│                                                                                                                                             │
│                                                                                                    [Search]    [Clear]    [PDF]   [Excel]   │
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


### Rep-10B: Report Output

┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Student : Meera Sharma  |  Class : 8 – A                                                                         Total Records : 8        │
├──────┬──────────────────────────────┬───────────────────┬────────────┬───────────┬────────┬───────┬───────────┬──────────┬────────┬────────┤
│  #   │  Exam Name                   │  Subject          │ Exam Date  │ Tot.Marks │ Marks  │   %   │   Grade   │ Division │ Result │  Rank  │
├──────┼──────────────────────────────┼───────────────────┼────────────┼───────────┼────────┼───────┼───────────┼──────────┼────────┼────────┤
│  1   │ Unit Test 1 – Sep 2024       │ Mathematics       │ 10-Sep-24  │    50     │   46   │ 92.0% │    A+     │    I     │  PASS  │   2    │
│  2   │ Unit Test 1 – Sep 2024       │ Science           │ 11-Sep-24  │    50     │   44   │ 88.0% │    A      │    I     │  PASS  │   4    │
│  3   │ Unit Test 1 – Sep 2024       │ English           │ 12-Sep-24  │    50     │   40   │ 80.0% │    A      │    I     │  PASS  │   6    │
│  4   │ Half-Yearly Exam – Oct 2024  │ Mathematics       │ 15-Oct-24  │   100     │   88   │ 88.0% │    A      │    I     │  PASS  │   3    │
│  5   │ Half-Yearly Exam – Oct 2024  │ Science           │ 16-Oct-24  │   100     │   79   │ 79.0% │    B+     │    I     │  PASS  │   7    │
│  6   │ Half-Yearly Exam – Oct 2024  │ English           │ 17-Oct-24  │   100     │   83   │ 83.0% │    A      │    I     │  PASS  │   5    │
│  7   │ Mid-Term Exam – Jan 2025     │ Mathematics       │ 14-Jan-25  │   100     │   92   │ 92.0% │    A+     │    I     │  PASS  │   2    │
│  8   │ Mid-Term Exam – Jan 2025     │ Science           │ 15-Jan-25  │   100     │   85   │ 85.0% │    A      │    I     │  PASS  │   4    │
└──────┴──────────────────────────────┴───────────────────┴────────────┴───────────┴────────┴───────┴───────────┴──────────┴────────┴────────┘


### Rep-10C: Performance Trend Chart

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Performance Trend  —  Meera Sharma                                                                                                         │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│  Y-Axis : Score %  (0 – 100%)                                                                                                               │
│  X-Axis : Exam Date                                                                                                                         │
│  Lines  :  ── Mathematics    ── Science    ── English    ── Overall Average                                                                 │
│                                                                                                                                             │
│  100% ┤                                                                                                                                     │
│   90% ┤  ·····Math·······················                                                                                                   │
│   80% ┤  ········English·········                                                                                                           │
│   70% ┤  ····Science·····                                                                                                                   │
│   60% ┤                                                                                                                                     │
│   50% ┤                                                                                                                                     │
│    0% ┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────▶      │
│        Unit-T1(Sep)  Half-Yr(Oct)  Mid-Term(Jan)   ...                                                                                      │
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


### Rep-10D: Summary

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Summary — Meera Sharma                                                                                                                     │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Total Exams : 8    Passed : 8    Failed : 0    Absent : 0    Overall Average : 86.1%    Best Subject : Mathematics (90.7% avg)             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


Notes:
- Results from `lms_exam_results` joined with `lms_exams` and `lms_exam_papers`.
- Percentile (`lms_exam_results.percentile`) shown if available.
- Trend line shows improvement / decline per subject over time.


---

## Rep-11: Exam Subject-wise Comparison

**Report Title:** Exam Subject-wise Comparison
**Sub-Title:** Cross-Subject Performance Matrix — All Subjects in One Exam

### Rep-11A: Filter Panel

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Rep-11 : Exam Subject-wise Comparison  —  Cross-Subject Performance Matrix                                                                 │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│  *Exam        : [ Select Exam               ▼ ]   *Class         : [ Select Class          ▼ ]    Section    : [ Select Section    ▼ ]      │
│   Mode        : [ Online / Offline / Both   ▼ ]                                                                                             │
│                                                                                                                                             │
│  Note: Only Exam and Class are compulsory.                                          [Search]    [Clear]    [PDF]    [Excel]                 │
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


### Rep-11B: Report Output — Student × Subject Matrix

Rows = Students | Columns = Subjects (all papers of the selected Exam) | Cell = % Score | Last column = Total % + Rank

┌────────────────────────────┬────────────┬────────────┬────────────┬────────────┬────────────┬──────┬──────────┬──────┐
│  Student Name              │   Math     │  Science   │  English   │    SST     │  Hindi     │  ... │  Total % │ Rank │
│                            │  (100 Mks) │  (100 Mks) │  (100 Mks) │  (100 Mks) │  (100 Mks) │      │          │      │
├────────────────────────────┼────────────┼────────────┼────────────┼────────────┼────────────┼──────┼──────────┼──────┤
│  Meera Sharma              │   92.0%    │   85.0%    │   83.0%    │   88.0%    │   90.0%    │  ... │  87.6%   │  2   │
│  Ravi Kumar                │   78.0%    │   72.0%    │   68.0%    │   75.0%    │   70.0%    │  ... │  72.6%   │  8   │
│  Ritika Verma              │   88.0%    │   90.0%    │   85.0%    │   82.0%    │   87.0%    │  ... │  86.4%   │  3   │
│  Neha Sharma               │   74.0%    │   68.0%    │   72.0%    │   70.0%    │   65.0%    │  ... │  69.8%   │ 12   │
│  Ankit Kumar               │   ABS      │   ABS      │   ABS      │   ABS      │   ABS      │  ... │   ABS    │  —   │
│  Ayush Kumar               │   55.0%    │   60.0%    │   58.0%    │   52.0%    │   50.0%    │  ... │  55.0%   │ 21   │
│  Divya Sharma              │   97.0%    │   95.0%    │   92.0%    │   96.0%    │   94.0%    │  ... │  94.8%   │  1   │
│  Isha Mehta                │   32.0%    │   40.0%    │   45.0%    │   38.0%    │   35.0%    │  ... │  38.0%   │ 27   │
│  ...                       │    ...     │    ...     │    ...     │    ...     │    ...     │  ... │   ...    │ ...  │
├────────────────────────────┼────────────┼────────────┼────────────┼────────────┼────────────┼──────┼──────────┼──────┤
│  Class Average             │   72.4%    │   74.1%    │   71.8%    │   73.2%    │   70.9%    │  ... │  72.5%   │  —   │
└────────────────────────────┴────────────┴────────────┴────────────┴────────────┴────────────┴──────┴──────────┴──────┘
  * ABS = Absent  * Cells colour-coded by % score  * Total % = aggregate across all subjects


### Rep-11C: Summary

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Summary  :  Mid-Term Exam Jan-2025  |  Class 8 – A                                                                                         │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Total Students : 27    Absent : 1    Class Average : 72.5%    Topper : Divya Sharma (94.8%)    Lowest : Isha Mehta (38.0%)                 │
├──────────────────────────────┬──────────────────────┬─────────────────────────────┬──────────────────────────────┬──────────────────────────┤
│  Overall Passed (≥35%)       │  Division I (≥60%)   │  Division II (45%-59%)      │  Failed (<35%)               │  Absent                  │
├──────────────────────────────┼──────────────────────┼─────────────────────────────┼──────────────────────────────┼──────────────────────────┤
│           24                 │         17           │              7              │              2               │            1             │
└──────────────────────────────┴──────────────────────┴─────────────────────────────┴──────────────────────────────┴──────────────────────────┘


Colour Coding:
┌──────────────────┬──────────────────────────────────────┐
│  Colour          │  Category                            │
├──────────────────┼──────────────────────────────────────┤
│  RED             │  Fail / Below 35%                    │
│  ORANGE          │  D Grade (35% - 49%)                 │
│  YELLOW          │  C Grade (50% - 59%)                 │
│  LIGHT GREEN     │  B/B+ Grade (60% - 79%)              │
│  DARK GREEN      │  A/A+ Grade (80% - 100%)             │
└──────────────────┴──────────────────────────────────────┘


Notes:
- Total % = sum of marks obtained across all subjects / sum of total marks × 100.
- Rank based on Total % (within class-section).
- Identifies weak subjects for the class (lowest class average column = weakest subject).


---

## Rep-12: LMS Activity Summary Dashboard

**Report Title:** LMS Activity Summary Dashboard
**Sub-Title:** Combined Homework + Quiz + Quest + Exam Activity Summary

### Rep-12A: Filter Panel

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Rep-12 : LMS Activity Summary Dashboard  —  Combined LMS Activity Summary                                                                  │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│  *Class       : [ Select Class              ▼ ]    Section       : [ Select Section        ▼ ]    Teacher    : [ Select Teacher    ▼ ]      │
│  *Date From   : [ DD-MM-YYYY                ]     *Date To        : [ DD-MM-YYYY           ]      Subject    : [ Select Subject    ▼ ]      │
│   Activity    : [ All / HW / Quiz / Quest / Exam ▼ ]                                                                                        │
│                                                                                                                                             │
│                                                                                                    [Search]    [Clear]    [PDF]   [Excel]   │
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


### Rep-12B: Summary Cards

┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  LMS Activity Summary  :  Class 8 – A  |  Jan 2025                                                                                        │
├──────────────────────────────┬──────────────────────────┬──────────────────────────┬──────────────────────────────────────────────────────┤
│  HOMEWORK                    │  QUIZ                    │  QUEST                   │  EXAM                                                │
├──────────────────────────────┼──────────────────────────┼──────────────────────────┼──────────────────────────────────────────────────────┤
│  Total Assigned   :  12      │  Total Assigned  :   8   │  Total Assigned  :   4   │  Total Exams       :   2                             │
│  Avg Submission % :  91.2%   │  Avg Attempt %   :  88%  │  Avg Attempt %   :  82%  │  Avg Attempt Rate  :  96.3%                          │
│  Avg Marks %      :  76.6%   │  Avg Score       :  0.74 │  Avg Score       :  0.68 │  Avg Score %       :  72.5%                          │
│  Overdue          :   2      │  System-Generated:   3   │  System-Generated:   1   │  Pass Rate         :  92.3%                          │
└──────────────────────────────┴──────────────────────────┴──────────────────────────┴──────────────────────────────────────────────────────┘


### Rep-12C: Activity Detail Table

One row per LMS activity (Homework / Quiz / Quest / Exam) in the selected date range.

┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Activity Detail                                                                                                   Total Activities : 26  │
├──────┬────────────┬──────────┬─────────────────────────────┬──────────────┬─────────────┬──────────┬──────────┬───────┬───────────────────┤
│  #   │    Date    │  Type    │  Title                      │   Subject    │    Class    │ # Assign │ # Att./  │ Avg   │  Status           │
│      │            │          │                             │              │   Section   │          │ Submitted│ Score │                   │
├──────┼────────────┼──────────┼─────────────────────────────┼──────────────┼─────────────┼──────────┼──────────┼───────┼───────────────────┤
│  1   │ 01-Jan-25  │ Homework │ Rational Numbers – Topic-1  │ Mathematics  │  8 – A      │    34    │    32    │  74%  │ Graded            │
│  2   │ 02-Jan-25  │ Quiz     │ Math Quiz – Rational Nos.   │ Mathematics  │  8 – A      │    34    │    34    │ 0.82  │ Published         │
│  3   │ 02-Jan-25  │ Homework │ Playing With Numbers T-1    │ Mathematics  │  8 – A      │    34    │    34    │  81%  │ Graded            │
│  4   │ 03-Jan-25  │ Quest    │ Science – Cells Quest       │ Science      │  8 – A      │    34    │    30    │ 0.71  │ Published         │
│  5   │ 03-Jan-25  │ Homework │ Rational Numbers – Topic-2  │ Mathematics  │  8 – A      │    34    │    29    │  75%  │ Partially Graded  │
│  6   │ 06-Jan-25  │ Quiz     │ Math Quiz – Playing Nos.    │ Mathematics  │  8 – A      │    34    │    32    │ 0.78  │ Published         │
│  7   │ 06-Jan-25  │ Homework │ Square & Square Roots T-1   │ Mathematics  │  8 – A      │    34    │    28    │  69%  │ Partially Graded  │
│  8   │ 07-Jan-25  │ Quiz     │ Science – Photosynthesis    │ Science      │  8 – A      │    34    │    33    │ 0.85  │ Published         │
│  9   │ 14-Jan-25  │ Exam     │ Mid-Term Exam – Math        │ Mathematics  │  8 – A      │    27    │    26    │  72%  │ Result Published  │
│ 10   │ 15-Jan-25  │ Exam     │ Mid-Term Exam – Science     │ Science      │  8 – A      │    27    │    26    │  74%  │ Result Published  │
│ ...  │    ...     │   ...    │   ... (16 more activities)  │     ...      │    ...      │   ...    │   ...    │  ...  │  ...              │
└──────┴────────────┴──────────┴─────────────────────────────┴──────────────┴─────────────┴──────────┴──────────┴───────┴───────────────────┘
  * Type colour-coded:  HOMEWORK = Blue  |  QUIZ = Purple  |  QUEST = Teal  |  EXAM = Orange
  * Avg Score for HW = marks %;  for Quiz/Quest = score decimal;  for Exam = marks %


### Rep-12D: Activity Trend Chart

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Activity Trend  —  Avg Score by Date                                                                                                       │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│  Y-Axis : Avg Score %  (0 – 100%)                                                                                                           │
│  X-Axis : Date (01-Jan to 31-Jan)                                                                                                           │
│  Lines  :  ── Homework Avg    ── Quiz/Quest Avg    ── Exam Avg    ── Overall Avg                                                            │
│                                                                                                                                             │
│  100% ┤                                                                                                                                     │
│   80% ┤  ·····Quiz/Quest···············                                                                                                     │
│   60% ┤  ····Homework·····                                                                                                                  │
│   40% ┤                                                                                                                                     │
│   20% ┤                                                                                                                                     │
│    0% ┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────▶      │
│        01  02  03  04  06  07  08  09  10  11  12  13  14  15  16  ...  31  (Jan)                                                           │
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


Notes:
- Homework data from: `lms_homework` + `lms_homework_submissions`
- Quiz/Quest data from: `lms_quizzes` / `lms_quests` + `lms_quiz_quest_attempts`
- Exam data from: `lms_exams` + `lms_exam_results`
- "# Assigned" = allocation count (class / section / individual allocations)
- "# Att./Submitted" = number of students who attempted (Quiz/Quest/Exam) or submitted (Homework)
- System-Generated quizzes/quests (auto-created by Auto-Quiz Config) flagged with [Auto] badge in Title column


---

*End of LMS Module Report Screen Design Document v2.5*




## Extra Report on Exam Performance (Result % Bracket)
-----------------------------------------------------

10% - 20%  - 

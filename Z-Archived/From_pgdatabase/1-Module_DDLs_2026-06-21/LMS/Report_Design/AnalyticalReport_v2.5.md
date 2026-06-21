# LMS Module — Analytical Reports Screen Design (v2.4)

---

## Table of Contents

1. [Rep-1: Assessment Report](#rep-1-assessment-report)
2. [Rep-2: Class Performance Analysis](#rep-2-class-performance-analysis)
3. [Rep-3: Student Performance Summary](#rep-3-student-performance-summary)
4. [Rep-4: Student Detailed Assessment](#rep-4-student-detailed-assessment)
5. [Rep-5: Periodic Detail of Student Performance](#rep-5-periodic-detail-of-student-performance)
6. [Rep-6: Current Class Performance (%) Detail](#rep-6-current-class-performance-detail)
7. [Config: Auto-Quiz Configuration](#config-auto-quiz-configuration)

---

## Main Screen — LMS Analytical Reports

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  PRIME ERP  |  LMS – Analytical Reports                                                                                      [User Profile] │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                              Breadcrumb: LMS > Analytical Reports                           │
│┌─ Tabs ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐│
││ [Assessment Report]  [Class Performance]  [Student Summary]  [Student Detail]  [Periodic]  [Class %]  [Config: Auto-Quiz]                 ││
││                                                                                                                                           ││
│└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘│
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


---

## Rep-1: Assessment Report

**Report Title:** Assessment Report
**Sub-Title:** Quiz / Quest Performance Report of the Class

### Rep-1A: Filter Panel

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Rep-1 : Assessment Report  —  Quiz / Quest Performance Report of the Class                                                                     │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  *Class.      : [Select Class ▼]  *Section : [Section  ▼]  Sub. Group : [Select Sub. Group     ▼]  *Subject : [Select Subject               ▼ ] │
│  *Date From   : [DD-MM-YYYY]      *Date To : [DD-MM-YYYY]  Assess. Type : [Quiz / Quest / Both ▼]  Q/Q Type : [ Challenge/Enrich/Prac. ▼      ] │
│                                                                                                       Q/Q Name  : [ Select Quiz/Quest    ▼ ]    │
│                                                                                                                                                 │
│  Note: Assessment Type sourced from: lms_assessment_type                                       [Search]    [Clear]     [PDF]     [Excel]        │
│                                                                                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


### Rep-1B: Report Output

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Report Output                                                                                                         Total Records : 27    │
├─────┬────────────┬──────────────────────┬──────┬──────┬──────┬───────┬─────────┬───────┬───────┬───────┬───────┬───────┬───────┬──────┬──────┤
│  #  │    Date    │    Student Name      │ Type │  ID  │ Att. │ Total │ Correct │ Wrong │ N.Att │ Score │ Strg. │ N.Atn │ Sati. │ Good │ Outs │
│     │            │                      │      │      │      │ Ques. │         │       │ Ques. │       │  <35% │35-49% │50-69% │70-84%│ 85%+ │
├─────┼────────────┼──────────────────────┼──────┼──────┼──────┼───────┼─────────┼───────┼───────┼───────┼───────┼───────┼───────┼──────┼──────┤
│  1  │ 14-Feb-25  │ Meera Sharma         │ Quiz │ 1001 │ Yes  │  20   │   18    │   2   │   0   │ 0.90  │       │       │       │      │  1   │
│  2  │ 14-Feb-25  │ Ravi Kumar           │ Quiz │ 1001 │ Yes  │  20   │   15    │   2   │   3   │ 0.75  │       │       │       │  1   │      │
│  3  │ 14-Feb-25  │ Ritika Verma         │ Quiz │ 1001 │ Yes  │  20   │   17    │   2   │   1   │ 0.85  │       │       │       │      │  1   │
│  4  │ 14-Feb-25  │ Neha Sharma          │ Quiz │ 1001 │ Yes  │  20   │   16    │   4   │   0   │ 0.80  │       │       │       │  1   │      │
│  5  │ 14-Feb-25  │ Ankit Kumar          │ Quiz │ 1001 │  No  │  20   │    0    │   0   │  20   │   —   │       │       │       │      │      │
│  6  │ 14-Feb-25  │ Ayush Kumar          │ Quiz │ 1001 │ Yes  │  20   │    8    │   5   │   7   │ 0.40  │       │   1   │       │      │      │
│  7  │ 14-Feb-25  │ Divya Sharma         │ Quiz │ 1001 │ Yes  │  20   │   19    │   1   │   0   │ 0.95  │       │       │       │      │  1   │
│  8  │ 14-Feb-25  │ Aman Kumar           │ Quiz │ 1001 │ Yes  │  20   │   18    │   2   │   0   │ 0.90  │       │       │       │      │  1   │
│  9  │ 14-Feb-25  │ Simran Sharma        │ Quiz │ 1001 │ Yes  │  20   │   12    │   4   │   4   │ 0.60  │       │       │   1   │      │      │
│ 10  │ 14-Feb-25  │ Shivansh Gupta       │ Quiz │ 1001 │ Yes  │  20   │    9    │   5   │   6   │ 0.45  │       │   1   │       │      │      │
│ 11  │ 14-Feb-25  │ Isha Mehta           │ Quiz │ 1001 │ Yes  │  20   │    3    │  14   │   3   │ 0.15  │   1   │       │       │      │      │
│ ... │     ...    │  ... (16 more rows)  │  ... │  ... │  ... │  ...  │   ...   │  ...  │  ...  │  ...  │  ...  │  ...  │  ...  │ ...  │ ...  │
│ 27  │ 14-Feb-25  │ Anushka Rani         │ Quiz │ 1001 │ Yes  │  20   │   17    │   3   │   0   │ 0.85  │       │       │       │      │  1   │
└─────┴────────────┴──────────────────────┴──────┴──────┴──────┴───────┴─────────┴───────┴───────┴───────┴───────┴───────┴───────┴──────┴──────┘
  * N.Att (Ques.) = No. of Questions Not Attempted by student
  * Strg.=Struggling  N.Atn=Needs Attention  Sati.=Satisfactory  Outs=Outstanding
  * Category columns show "1" in the matching column. Non-attempted rows: Score = — (no category marked)
  * Score cell colour follows the Colour Coding table below


### Rep-1C: Summary

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Summary                                                                                                                                    │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Total Students : 27          Students Attempted : 24          Class Average : 0.68  (68%)                                                  │
├──────────────────────────────┬──────────────────────┬─────────────────────────────┬──────────────────────────────┬──────────────────────────┤
│  Performance Category        │                      │                             │                              │                          │
├──────────────────────────────┼──────────────────────┼─────────────────────────────┼──────────────────────────────┼──────────────────────────┤
│  Outstanding   (85% - 100%)  │  Good   (70% - 84%)  │  Satisfactory  (50% - 69%)  │  Needs Attention (35% - 49%) │  Struggling  (Below 35%) │
├──────────────────────────────┼──────────────────────┼─────────────────────────────┼──────────────────────────────┼──────────────────────────┤
│              10              │          8           │              4              │              2               │             1            │
└──────────────────────────────┴──────────────────────┴─────────────────────────────┴──────────────────────────────┴──────────────────────────┘


Colour Coding (applied to Score column and category columns):
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
- Useful for Teacher to see how many students have understood a topic.
- Assessment Type filter: select "Only Homework Quiz" OR "All" type of Quiz.
- Columns "Type" (Quiz/Quest) and "ID" (Quiz/Quest ID) added.


---

## Rep-2: Class Performance Analysis

**Report Title:** Class Performance Analysis
**Sub-Title:** Teacher-wise Average Class Performance Report (Monthly)

### Rep-2A: Filter Panel

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Rep-2 : Class Performance Analysis  —  Teacher-wise Average Class Performance Report (Monthly)                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│  *Teacher      : [ Select Teacher           ▼ ]   *Assess. Type  : [ Quiz / Quest          ▼ ]                                              │
│  *Date From    : [ DD-MM-YYYY               ]     *Date To        : [ DD-MM-YYYY           ]                                                │
│   Class        : [ Select Class             ▼ ]    Section        : [ Select Section       ▼ ]                                              │
│   Sub. Group   : [ Select Subject Group     ▼ ]    Subject        : [ Select Subject       ▼ ]                                              │
│                                                                                                                                             │
│                                                                                                    [Search]    [Clear]    [PDF]   [Excel]   │
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


### Rep-2B: Report Output

Report is organized by: Assessment Type → Subject → Class-Section
Columns: Subject + Class-Section | Particulars | [Date-1] | [Date-2] | ... | [Date-31]

#### Section 1 — Quiz – Homework

┌──────────────────────────────┬──────────────────────────┬────────┬────────┬────────┬────────┬────────┬────────┬────────┬────────┬────────┬──────┐
│  Subject — Class — Section   │  Particulars             │ 01-Jan │ 02-Jan │ 03-Jan │ 04-Jan │ 06-Jan │ 07-Jan │ 08-Jan │ 09-Jan │ 10-Jan │  ... │
├──────────────────────────────┼──────────────────────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼──────┤
│  Math — Class 6A             │ # St. Quiz Assigned to   │   34   │   34   │   34   │   34   │   34   │   34   │   34   │   34   │   34   │  ... │
│                              │ # St. Attempted          │   32   │   34   │   33   │   33   │   28   │   34   │   34   │   32   │   34   │  ... │
│                              │ Average Score (%)        │  0.86  │  0.82  │  0.85  │  0.89  │  0.87  │  0.90  │  0.91  │  0.94  │  0.89  │  ... │
├──────────────────────────────┼──────────────────────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼──────┤
│  Math — Class 7A             │ # St. Quiz Assigned to   │   34   │   34   │   34   │   34   │   34   │   34   │   34   │   34   │   34   │  ... │
│                              │ # St. Attempted          │   32   │   34   │   33   │   33   │   28   │   34   │   34   │   32   │   34   │  ... │
│                              │ Average Score (%)        │  0.84  │  0.87  │  0.90  │  0.88  │  0.84  │  0.93  │  0.92  │  0.89  │  0.87  │  ... │
├──────────────────────────────┼──────────────────────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼──────┤
│  Science — Class 6A          │ # St. Quiz Assigned to   │   34   │   34   │   34   │   34   │   34   │   34   │   34   │   34   │   34   │  ... │
│                              │ # St. Attempted          │   32   │   34   │   33   │   33   │   28   │   34   │   34   │   32   │   34   │  ... │
│                              │ Average Score (%)        │  0.85  │  0.89  │  0.88  │  0.87  │  0.82  │  0.92  │  0.94  │  0.92  │  0.86  │  ... │
├──────────────────────────────┼──────────────────────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼──────┤
│  ... (more subjects/classes) │                          │        │        │        │        │        │        │        │        │        │  ... │
├──────────────────────────────┼──────────────────────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼──────┤
│  All Quizzes Average         │ # St. Quiz Assigned to   │   34   │   34   │   34   │   34   │   34   │   34   │   34   │   34   │   34   │  ... │
│  (All Subjects + Classes)    │ # St. Attempted          │   32   │   34   │   33   │   33   │   28   │   34   │   34   │   32   │   34   │  ... │
│                              │ Average Score (%)        │  0.85  │  0.86  │  0.87  │  0.88  │  0.85  │  0.91  │  0.92  │  0.91  │  0.87  │  ... │
└──────────────────────────────┴──────────────────────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┴──────┘
  * Date columns span the full selected date range (Sundays excluded)
  * Colour coding applied to "Average Score (%)" cells only


#### Section 2 — Assessment (Same structure — row labels change only)

┌──────────────────────────────┬──────────────────────────┬────────┬────────┬────────┬────────┬──────┐
│  Subject — Class — Section   │  Particulars             │ 01-Jan │ 02-Jan │ 03-Jan │ 04-Jan │  ... │
├──────────────────────────────┼──────────────────────────┼────────┼────────┼────────┼────────┼──────┤
│  Math — Class 6A             │ # St. Ass. Assigned to   │   30   │   30   │   30   │   30   │  ... │
│                              │ # St. Attempted          │   28   │   30   │   29   │   30   │  ... │
│                              │ Average Score (%)        │  0.78  │  0.80  │  0.76  │  0.82  │  ... │
├──────────────────────────────┼──────────────────────────┼────────┼────────┼────────┼────────┼──────┤
│  ... (same structure)        │                          │        │        │        │        │  ... │
└──────────────────────────────┴──────────────────────────┴────────┴────────┴────────┴────────┴──────┘


Colour Coding (applied to Average Score (%) cells):
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
- Only Homework Quizzes are considered for this report.


---

## Rep-3: Student Performance Summary

**Report Title:** Student Performance Summary
**Sub-Title:** Monthly Student Performance Tracking Summary (Quiz / Quest Assessment)

### Rep-3A: Filter Panel

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Rep-3 : Student Performance Summary  —  Monthly Student Performance Tracking Summary (Quiz / Quest Assessment)                             │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│  *Student      : [ Select Student           ▼ ]   *Assess. Type  : [ Both / Quiz / Quest   ▼ ]                                              │
│  *Date From    : [ DD-MM-YYYY               ]     *Date To        : [ DD-MM-YYYY           ]                                                │
│   Sub. Group   : [ Select Subject Group     ▼ ]    Subject        : [ Select Subject       ▼ ]                                              │
│                                                                                                                                             │
│                                                                                                    [Search]    [Clear]    [PDF]   [Excel]   │
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


### Rep-3B: Report Output — Per Subject Daily Grid

Report organized by Subject. Date columns span the selected range (Sundays excluded).

#### Quiz – Homework — Math

┌──────────────────────────┬────────┬────────┬────────┬────────┬────────┬────────┬────────┬────────┬────────┬────────┬──────┐
│  Particulars             │ 01-Jan │ 02-Jan │ 03-Jan │ 04-Jan │ 06-Jan │ 07-Jan │ 08-Jan │ 09-Jan │ 10-Jan │ 11-Jan │  ... │
├──────────────────────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼──────┤
│  Quiz/Ass. Attempted     │  Yes   │  Yes   │  Yes   │  Yes   │  Yes   │   No   │  Yes   │  Yes   │  Yes   │  Yes   │  ... │
│  Total Questions         │   20   │   20   │   20   │   20   │   20   │   20   │   20   │   20   │   20   │   20   │  ... │
│  Correct Answers         │    8   │   14   │   13   │   11   │   16   │    0   │    5   │   14   │   15   │   13   │  ... │
│  Wrong Answers           │    4   │    3   │    5   │    6   │    1   │    0   │    1   │    2   │    3   │    4   │  ... │
│  Not Attempted           │    8   │    3   │    2   │    3   │    3   │   20   │   14   │    4   │    2   │    3   │  ... │
│  Math Score              │  0.40  │  0.70  │  0.65  │  0.55  │  0.80  │  0.00  │  0.25  │  0.70  │  0.75  │  0.65  │  ... │
└──────────────────────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┴──────┘
  * Score cell colour follows Colour Coding


#### Science — (Same structure — Science Score row)

#### English — (Same structure — English Score row)

#### SST — (Same structure — SST Score row)


### Rep-3C: Average Summary Row

┌──────────────────────────┬────────┬────────┬────────┬────────┬────────┬────────┬────────┬────────┬────────┬────────┬──────┐
│  Particulars             │ 01-Jan │ 02-Jan │ 03-Jan │ 04-Jan │ 06-Jan │ 07-Jan │ 08-Jan │ 09-Jan │ 10-Jan │ 11-Jan │  ... │
├──────────────────────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼──────┤
│  Average (All Subjects)  │ 0.5875 │  0.75  │ 0.6875 │  0.625 │  0.675 │  0.00  │ 0.3375 │  0.70  │ 0.725  │  0.65  │  ... │
└──────────────────────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┴──────┘


### Rep-3D: Line Chart

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Line Chart — Student Score Trend                                                                                                           │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│  Y-Axis : Score (0.00 – 1.00)                                                                                                               │
│  X-Axis : Date (01-Jan to 31-Jan, Sundays excluded)                                                                                         │
│  Lines  :  ── Math Score    ── Science Score    ── English Score    ── SST Score    ── Average Score                                        │
│                                                                                                                                             │
│  1.00 ┤                                                                                                                                     │
│  0.80 ┤        ·····Math·········                                                                                                           │
│  0.60 ┤  ···Average·····                                                                                                                    │
│  0.40 ┤  ·                                                                                                                                  │
│  0.20 ┤                                                                                                                                     │
│  0.00 ┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────▶      │
│        01  02  03  04  06  07  08  09  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  (Jan)        │
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


Colour Coding (applied to Score rows):
┌──────────────────┬──────────────────────────────────────┐
│  Colour          │  Category                            │
├──────────────────┼──────────────────────────────────────┤
│  RED             │  Struggling       (Below 35%)        │
│  ORANGE          │  Needs Attention  (35% - 49%)        │
│  YELLOW          │  Satisfactory     (50% - 69%)        │
│  LIGHT GREEN     │  Good             (70% - 84%)        │
│  DARK GREEN      │  Outstanding      (85% - 100%)       │
└──────────────────┴──────────────────────────────────────┘


---

## Rep-4: Student Detailed Assessment

**Report Title:** Student Detailed Assessment (Insights and Progress)

### Rep-4A: Filter Panel

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Rep-4 : Student Detailed Assessment  —  Insights and Progress                                                                              │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│  *Student    : [ Select Student           ▼ ]   Sub. Group  : [ Select Subject Group   ▼ ]   *Subject : [ Select Subject         ▼ ]        │
│  *Type       : [ Both / Quiz / Quest      ▼ ]    Date From  : [ DD-MM-YYYY             ]      Date To  : [ DD-MM-YYYY            ]          │
│   Lesson     : [ Select Lesson (Optional) ▼ ]    Topic Type : [ Select Topic Type      ▼ ]                                                  │
│   Topic      : [ Select Topic (Optional)  ▼ ]    Sub Topic  : [ Select Sub Topic       ▼ ]                                                  │
│   Mini Topic : [ Select Mini Topic        ▼ ]   Micro Topic : [ Select Micro Topic     ▼ ]                                                  │
│                                                                                                                                             │
│  Note: If only 1 Student exists in selection, auto-display without choosing.                [Search]    [Clear]    [PDF]     [Excel]        │
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


### Rep-4B: Report Output — Grouped by Performance Category

Column Key: Subj=Subject | Lsn=Lesson | L.Ex.Dt=Last Exam Date | Q.Asgn=Ques.Assigned | Att=Attempted | Cor=Correct | Wrg=Wrong

#### ★ Outstanding (85% - 100%)

┌──────────┬──────────────────┬───────────────────────────────────────────────────────┬───────────┬────────┬─────┬─────┬─────┬──────────┬─────────┬──────────┬──────────┐
│  Subj.   │  Lesson          │  Topic / Sub-Topic / Mini Topic / Micro Topic         │ L.Ex.Dt   │ Q.Asgn │ Att │ Cor │ Wrg │ Cl.Avg % │ Std.  % │ Content  │  Video   │
├──────────┼──────────────────┼───────────────────────────────────────────────────────┼───────────┼────────┼─────┼─────┼─────┼──────────┼─────────┼──────────┼──────────┤
│  Math    │ Rational Numbers │ Rational Numbers : Recap                              │ 14-Feb-25 │   20   │ 20  │ 18  │  2  │   0.90   │  0.90   │ [Content]│ [Video]  │
│  Math    │ Rational Numbers │ Properties Of Addition And Subtraction                │ 14-Feb-25 │   20   │ 20  │ 19  │  1  │   0.95   │  0.92   │ [Content]│ [Video]  │
│  Math    │ Rational Numbers │ Properties Of Multiplication                          │ 14-Feb-25 │   20   │ 20  │ 15  │  5  │   0.76   │  0.86   │ [Content]│ [Video]  │
│  Math    │ Rational Numbers │ Properties Of Division                                │ 14-Feb-25 │   20   │ 20  │ 19  │  1  │   0.97   │  0.89   │ [Content]│ [Video]  │
│  Math    │ Rational Numbers │ Representation Of Rational Nos. On Number Line        │ 14-Feb-25 │   20   │ 20  │ 18  │  2  │   0.93   │  0.86   │ [Content]│ [Video]  │
│  Math    │ Rational Numbers │ Rational Numbers Between Two Rational Numbers         │ 14-Feb-25 │   20   │ 20  │ 17  │  3  │   0.87   │  0.86   │ [Content]│ [Video]  │
│  Math    │ Rational Numbers │ Word Problems                                         │ 14-Feb-25 │   20   │ 20  │ 19  │  1  │   0.94   │  0.88   │ [Content]│ [Video]  │
│  Math    │ Rational Numbers │ Rational Numbers — Lesson Review (1)                  │ 14-Feb-25 │   20   │ 20  │ 17  │  3  │   0.94   │  0.85   │ [Content]│ [Video]  │
│  Math    │ Rational Numbers │ Rational Numbers — Lesson Review (2)                  │ 14-Feb-25 │   20   │ 20  │ 17  │  3  │   0.97   │  0.85   │ [Content]│ [Video]  │
└──────────┴──────────────────┴───────────────────────────────────────────────────────┴───────────┴────────┴─────┴─────┴─────┴──────────┴─────────┴──────────┴──────────┘


#### ◑ Good (70% - 84%)

┌──────────┬──────────────────┬───────────────────────────────────────────────────────┬───────────┬────────┬─────┬─────┬─────┬──────────┬─────────┬──────────┬──────────┐
│  Subj.   │  Lesson          │  Topic / Sub-Topic / Mini Topic / Micro Topic         │ L.Ex.Dt   │ Q.Asgn │ Att │ Cor │ Wrg │ Cl.Avg % │ Std.  % │ Content  │  Video   │
├──────────┼──────────────────┼───────────────────────────────────────────────────────┼───────────┼────────┼─────┼─────┼─────┼──────────┼─────────┼──────────┼──────────┤
│  Math    │ Lesson-2         │ Topic / Sub-Topic / Mini / Micro (as applicable)      │ DD-MM-YY  │   20   │ 20  │ 16  │  4  │   0.80   │  0.78   │ [Content]│ [Video]  │
│  Science │ Lesson-1         │ Topic / Sub-Topic / Mini / Micro (as applicable)      │ DD-MM-YY  │   20   │ 20  │ 15  │  3  │   0.79   │  0.75   │ [Content]│ [Video]  │
│   ...    │      ...         │  ... (more rows)                                      │    ...    │  ...   │ ... │ ... │ ... │   ...    │   ...   │    ...   │   ...    │
└──────────┴──────────────────┴───────────────────────────────────────────────────────┴───────────┴────────┴─────┴─────┴─────┴──────────┴─────────┴──────────┴──────────┘


#### ◔ Satisfactory (50% - 69%)

(Same column structure as above — topics where Student Score is 50% – 69%)


#### ▽ Needs Attention (35% - 49%)

(Same column structure as above — topics where Student Score is 35% – 49%)


#### ✕ Struggling (Below 35%)

(Same column structure as above — topics where Student Score is below 35%)


---

## Rep-5: Periodic Detail of Student Performance

**Report Title:** Periodic Detail of Student Performance
**Sub-Title:** Subject – Lesson – Topic Wise

### Rep-5A: Filter Panel

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Rep-5 : Periodic Detail of Student Performance  —  Subject – Lesson – Topic Wise                                                           │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│  *Student    : [ Select Student           ▼ ]   Sub. Group  : [ Select Subject Group   ▼ ]    Subject : [ Select Subject          ▼ ]       │
│  *Type       : [ Both / Quiz / Quest      ▼ ]    Date From  : [ DD-MM-YYYY             ]      Date To : [ DD-MM-YYYY             ]          │
│   Lesson     : [ Select Lesson (Optional) ▼ ]    Topic Type : [ Select Topic Type      ▼ ]                                                  │
│   Topic      : [ Select Topic (Optional)  ▼ ]    Sub Topic  : [ Select Sub Topic       ▼ ]                                                  │
│   Mini Topic : [ Select Mini Topic        ▼ ]   Micro Topic : [ Select Micro Topic     ▼ ]                                                  │
│                                                                                                                                             │
│  Note: If only 1 Student exists in selection, auto-display without choosing.                [Search]    [Clear]    [PDF]     [Excel]        │
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


### Rep-5B: Report Output

Scoring Category: 1=Outstanding (85%+)  2=Good (70-84%)  3=Satisfactory (50-69%)  4=Needs Attention (35-49%)  5=Struggling (<35%)

┌─────────┬──────────┬──────────┬──────────────┬───────────────┬─────────────┬──────┬───────┬─────────┬───────┬──────────┬───────┬──────┐
│ Subject │  Lesson  │  Topic   │ Attempt Date │  Quiz/Ass. ID │ Assign Date │ Att. │ Total │ Correct │ Wrong │ Not Att. │ Score │ Cat. │
├─────────┼──────────┼──────────┼──────────────┼───────────────┼─────────────┼──────┼───────┼─────────┼───────┼──────────┼───────┼──────┤
│  Math   │ Lesson-1 │ Topic-1  │  10-Sep-24   │  100225-01    │  08-Sep-24  │ Yes  │  20   │    8    │   8   │    4     │ 0.40  │  4   │
│  Math   │ Lesson-1 │ Topic-1  │  05-Oct-24   │  100225-02    │  10-Sep-24  │ Yes  │  20   │   13    │   4   │    3     │ 0.65  │  3   │
│  Math   │ Lesson-1 │ Topic-1  │  14-Feb-25   │  100225-03    │  05-Oct-24  │ Yes  │  20   │   17    │   2   │    1     │ 0.85  │  1   │
│  Math   │ Lesson-1 │ Topic-2  │  14-Feb-25   │  110225-01    │  11-Feb-25  │ Yes  │  20   │   16    │   4   │    0     │ 0.80  │  2   │
│ Science │ Lesson-1 │ Topic-2  │  14-Feb-25   │  110225-02    │  11-Feb-25  │  No  │  20   │    0    │   0   │    0     │ 0.00  │  5   │
│ English │ Lesson-1 │ Topic-2  │  14-Feb-25   │  110225-03    │  11-Feb-25  │ Yes  │  20   │    8    │   5   │    7     │ 0.40  │  4   │
│   SST   │ Lesson-1 │ Topic-2  │  14-Feb-25   │  110225-04    │  11-Feb-25  │ Yes  │  20   │   19    │   1   │    0     │ 0.95  │  1   │
│  Math   │ Lesson-1 │ Topic-3  │  14-Feb-25   │  120225-01    │  12-Feb-25  │ Yes  │  20   │   18    │   2   │    0     │ 0.90  │  1   │
│ Science │ Lesson-1 │ Topic-3  │  14-Feb-25   │  120225-02    │  12-Feb-25  │ Yes  │  20   │   16    │   4   │    0     │ 0.80  │  2   │
│ English │ Lesson-1 │ Topic-3  │  14-Feb-25   │  120225-03    │  12-Feb-25  │  No  │  20   │    0    │   0   │    0     │ 0.00  │  5   │
│   SST   │ Lesson-1 │ Topic-3  │  14-Feb-25   │  120225-04    │  12-Feb-25  │ Yes  │  20   │    2    │   0   │    0     │ 0.10  │  5   │
│  Math   │ Lesson-1 │ Topic-4  │  14-Feb-25   │  130225-01    │  13-Feb-25  │ Yes  │  20   │   17    │   3   │    0     │ 0.85  │  1   │
│ Science │ Lesson-1 │ Topic-4  │  14-Feb-25   │  130225-02    │  13-Feb-25  │ Yes  │  20   │   12    │   5   │    3     │ 0.60  │  3   │
│ English │ Lesson-1 │ Topic-4  │  14-Feb-25   │  130225-03    │  13-Feb-25  │ Yes  │  20   │   15    │   3   │    2     │ 0.75  │  2   │
│   SST   │ Lesson-1 │ Topic-4  │  14-Feb-25   │  130225-04    │  13-Feb-25  │ Yes  │  20   │   17    │   3   │    0     │ 0.85  │  1   │
│   ...   │   ...    │   ...    │      ...     │      ...      │     ...     │ ...  │  ...  │   ...   │  ...  │   ...    │  ...  │ ...  │
└─────────┴──────────┴──────────┴──────────────┴───────────────┴─────────────┴──────┴───────┴─────────┴───────┴──────────┴───────┴──────┘


### Rep-5C: Summary

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Summary                                                                                                                                    │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Total Students : 15          Students Attempted : 13          Class Average : 0.5933 (59.33%)                                              │
├──────────────────────────────┬──────────────────────┬─────────────────────────────┬──────────────────────────────┬──────────────────────────┤
│  1 — Outstanding (85%-100%)  │  2 — Good (70%-84%)  │  3 — Satisfactory (50%-69%) │  4 — Needs Att. (35%-49%)    │  5 — Struggling (<35%)   │
├──────────────────────────────┼──────────────────────┼─────────────────────────────┼──────────────────────────────┼──────────────────────────┤
│              5               │          3           │              2              │              2               │             3            │
└──────────────────────────────┴──────────────────────┴─────────────────────────────┴──────────────────────────────┴──────────────────────────┘


---

## Rep-6: Current Class Performance (%) Detail

**Report Title:** Current Class Performance (%)
**Sub-Title:** Current Class Performance (Detail) – Subject > Lesson > Topic Wise

### Rep-6A: Filter Panel

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Rep-6 : Current Class Performance (%)  —  Subject > Lesson > Topic Wise                                                                    │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│  *Class+Sec  : [ e.g. 8th – A              ▼ ]   *Sub. Group   : [ Select Subject Group    ▼ ]   *Subject : [ Select Subject       ▼ ]      │
│  *Date From  : [ DD-MM-YYYY                ]      Date To      : [ DD-MM-YYYY              ]     *Type    : [ Quiz / Quest / Both   ▼ ]     │
│   Topic Level: [ Select Level              ▼ ]    Lesson       : [ Select Lesson (Opt.)    ▼ ]                                              │
│   Topic      : [ Select Topic (Optional)   ▼ ]    Sub Topic    : [ Select Sub Topic        ▼ ]                                              │
│   Mini Topic : [ Select Mini Topic         ▼ ]   Micro Topic   : [ Select Micro Topic      ▼ ]                                              │
│                                                                                                                                             │
│  Note: Only Class & Section are compulsory. All other fields are optional.          [Search]    [Clear]     [PDF]    [Excel]                │
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


### Rep-6B: Report Output — Matrix / Pivot  (Lesson > Topic Rows  ×  Student Name Columns)

Performance (%) = Last attempt score of that student for that Lesson-Topic within the selected date range.

#### Math — Rational Numbers

┌──────────────────┬──────────────────────────────────────────────────────┬──────────┬─────────┬───────────┬─────────┬─────────┬──────┬──────────┐
│  Lesson          │  Topic                                               │ Meera S. │ Ravi K. │ Ritika V. │ Neha S. │ Ankit K.│  ... │  Average │
├──────────────────┼──────────────────────────────────────────────────────┼──────────┼─────────┼───────────┼─────────┼─────────┼──────┼──────────┤
│ Rational Numbers │ Rational Numbers : Recap                             │   0.45   │  0.68   │   0.47    │  0.62   │  TNA    │  ... │  0.5326  │
│ Rational Numbers │ Properties Of Addition And Subtraction               │   0.78   │  0.52   │   0.86    │  0.73   │  TNA    │  ... │  0.6664  │
│ Rational Numbers │ Properties Of Multiplication                         │   TNA    │  0.74   │   TNA     │  0.69   │  0.85   │  ... │  0.8671  │
│ Rational Numbers │ Properties Of Division                               │   0.52   │  0.72   │   0.70    │  0.64   │  0.78   │  ... │  0.6062  │
│ Rational Numbers │ Representation Of Rational Nos. On Number Line       │   0.69   │  TNA    │   0.92    │  0.81   │  0.73   │  ... │  0.8171  │
│ Rational Numbers │ Rational Numbers Between Two Rational Numbers        │   0.68   │  0.88   │   0.80    │  NTA    │  0.75   │  ... │  0.7563  │
│ Rational Numbers │ Word Problems                                        │   0.75   │  0.05   │   0.06    │  0.52   │  0.81   │  ... │  0.2030  │
│ Rational Numbers │ Rational Numbers - Lesson Review                     │   0.50   │  0.45   │   0.40    │  0.48   │  0.42   │  ... │  0.4978  │
├──────────────────┼──────────────────────────────────────────────────────┼──────────┼─────────┼───────────┼─────────┼─────────┼──────┼──────────┤
│  No. of Topics   │  8                                                   │    7     │    6    │     7     │    7    │    7    │  ... │  0.7066  │
└──────────────────┴──────────────────────────────────────────────────────┴──────────┴─────────┴───────────┴─────────┴─────────┴──────┴──────────┘


#### Math — Playing With Numbers

┌──────────────────────┬──────────────────────────────────────────────────────┬──────────┬─────────┬───────────┬─────────┬─────────┬──────┬──────────┐
│  Lesson              │  Topic                                               │ Meera S. │ Ravi K. │ Ritika V. │ Neha S. │ Ankit K.│  ... │  Average │
├──────────────────────┼──────────────────────────────────────────────────────┼──────────┼─────────┼───────────┼─────────┼─────────┼──────┼──────────┤
│ Playing With Numbers │ General Form And Letter Puzzles                      │   0.66   │  0.49   │   0.56    │  0.70   │  0.65   │  ... │  0.6081  │
│ Playing With Numbers │ Games With Numbers                                   │   0.82   │  0.81   │   0.57    │  0.68   │  TNA    │  ... │  0.6167  │
│ Playing With Numbers │ Tests Of Divisibility                                │   0.00   │  0.00   │   0.80    │  0.55   │  0.72   │  ... │  0.4852  │
│ Playing With Numbers │ Playing With Numbers - Lesson Review                 │   0.81   │  0.54   │   0.67    │  0.72   │  0.69   │  ... │  0.6130  │
├──────────────────────┼──────────────────────────────────────────────────────┼──────────┼─────────┼───────────┼─────────┼─────────┼──────┼──────────┤
│  No. of Topics       │  4                                                   │    4     │    4    │     4     │    4    │    3    │  ... │  0.5807  │
└──────────────────────┴──────────────────────────────────────────────────────┴──────────┴─────────┴───────────┴─────────┴─────────┴──────┴──────────┘


#### Math — Square And Square Roots

┌────────────────────────────┬──────────────────────────────────────────────────────┬──────────┬─────────┬───────────┬──────┬──────────┐
│  Lesson                    │  Topic                                               │ Meera S. │ Ravi K. │ Ritika V. │  ... │  Average │
├────────────────────────────┼──────────────────────────────────────────────────────┼──────────┼─────────┼───────────┼──────┼──────────┤
│ Square And Square Roots    │ Square Numbers And Perfect Squares                   │   0.00   │  0.86   │   0.72    │  ... │  0.6552  │
│ Square And Square Roots    │ Properties Of Square Numbers                         │   0.79   │  0.63   │   0.78    │  ... │  0.6341  │
│ Square And Square Roots    │ Finding Square Of Numbers                            │   0.00   │  0.74   │   0.58    │  ... │  0.4963  │
│ Square And Square Roots    │ Finding Square Root Of Numbers                       │   0.52   │  0.72   │   0.68    │  ... │  0.6085  │
│ Square And Square Roots    │ Long Division Method                                 │   0.69   │  0.00   │   0.75    │  ... │  0.7263  │
│ Square And Square Roots    │ Square Root Of Decimals And Fractions                │   0.68   │  0.88   │   0.77    │  ... │  0.7563  │
│ Square And Square Roots    │ Square And Square Roots - Lesson Review              │   0.75   │  0.00   │   0.68    │  ... │  0.2107  │
├────────────────────────────┼──────────────────────────────────────────────────────┼──────────┼─────────┼───────────┼──────┼──────────┤
│  No. of Topics             │  7                                                   │    7     │    7    │     7     │  ... │  0.5839  │
└────────────────────────────┴──────────────────────────────────────────────────────┴──────────┴─────────┴───────────┴──────┴──────────┘
  * Colour coding applied to each score cell based on student value
  * Column headers = all student names in the selected class-section


### Rep-6C: Summary

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Summary                                                                                                                                    │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Total Students : 27          # Test Not Attempted (TNA) : 17          # Not Assigned (NTA) : 2          Class Average : 0.5839 (58.39%)    │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


Special Cell Values:
┌────────────┬──────────────────────────────────────────────────────────────────────┐
│  Value     │  Meaning                                                             │
├────────────┼──────────────────────────────────────────────────────────────────────┤
│  0.xx      │  Student attempted — score as decimal (e.g. 0.75 = 75%)              │
│  0.00      │  Student attempted but scored 0%                                     │
│  TNA       │  Test Not Attempted — student did not attempt the assessment         │
│  NTA       │  Not Assigned — assessment was not assigned to this student          │
└────────────┴──────────────────────────────────────────────────────────────────────┘


Notes:
- Performance (%) = Last attempt score for that student on that Lesson-Topic within the selected date range.
- Only Class & Section are compulsory. All other filters are optional.


---

## Config: Auto-Quiz Configuration

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Config : Auto-Quiz Configuration                                                                                                           │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│  Auto-Quiz Trigger Rule:                                                                                                                    │
│  If a student scores below the configured threshold (%), the system will automatically                                                      │
│  create a new Quiz and assign it to that student.                                                                                           │
│                                                                                                                                             │
│  *Score Threshold (%)          : [ _______ % ]                                                                                              │
│                                  (e.g. 50 → trigger auto-quiz if student scores below 50%)                                                  │
│                                                                                                                                             │
│  *No. of Questions in Auto-Quiz : [ _______ ]                                                                                               │
│                                   (Number of questions to include in the auto-created quiz)                                                 │
│                                                                                                                                             │
│                                                                                                                                    [Save]   │
│                                                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


---

*End of LMS Module Report Screen Design Document v2.4*

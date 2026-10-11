# DETAILED REPORTS for Behavioural Assessment Module

## REPORT GENERATION SCREEN

====================================================================================================
                        BEHAVIOURAL ASSESSMENT REPORT GENERATION - CUSTOM REPORT
====================================================================================================
```
+------------------------------------------------------------------------------------------------------+
| REPORT CONFIGURATION                                                                                 |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Report Type:     [v] Select Report Type                                                              |
|                  +-----------------------------------------------------------------------+           |
|                  | * Student Behaviour Summary Report                                    |           |
|                  | * Class-Section Behaviour Analysis Report                             |           |
|                  | * Incident Log & Intervention Report                                  |           |
|                  | * Category & Criteria Performance Report                              |           |
|                  | * Teacher Assessment Progress Report                                  |           |
|                  | * Behavioural Trend Analysis Report                                   |           |
|                  | * Parent Communication Report                                         |           |
|                  | * Executive Dashboard (Principal/HOD)                                 |           |
|                  +-----------------------------------------------------------------------+           |
|                                                                                                      |
| Academic Session: [v] 2025-26                                                                        |
| Assessment Period:[v] [All Periods]  [Term 1 Assessment] [Term 2 Assessment] [Annual]                |
| Date Range:       From: [ 01/04/2025 ]  To: [ 30/09/2025 ]                                           |
|                                                                                                      |
| Filters:                                                                                             |
|   [ ] Class:            [All v]   (sch_classes)                                                      |
|   [ ] Section:          [All v]   (sch_class_section_jnt)                                            |
|   [ ] Category:         [All v]   (ba_categories — Classroom Engagement, Respect, etc.)              |
|   [ ] Polarity:         [All v]   [Positive] [Negative]                                              |
|   [ ] Incident Type:    [All v]   [Positive Reinforcement] [Negative Incident]                       |
|   [ ] Severity:         [All v]   [Minor] [Moderate] [Major] [Critical]                              |
|   [ ] Teacher:          [All v]   (sch_employees)                                                    |
|   [ ] Assessment Status:[All v]   [Draft] [Submitted] [Reviewed] [Locked]                            |
|                                                                                                      |
| Group By:        [v] [None] [Class] [Section] [Category] [Teacher] [Period] [Polarity]               |
|                                                                                                      |
| Sort By:         [v] [Score] [Name] [Category] [Incident Count] [Date]                               |
|                  Order: [*] Ascending  [ ] Descending                                                |
|                                                                                                      |
| Include:                                                                                             |
|   [x] Summary Statistics                                                                             |
|   [x] Detailed Data                                                                                  |
|   [x] Charts/Graphs                                                                                  |
|   [ ] Comparative Analysis (vs previous period)                                                      |
|   [ ] Incident Timeline                                                                              |
|   [ ] Teacher Remarks                                                                                |
|                                                                                                      |
| Format:          [*] PDF  [ ] Excel  [ ] CSV  [ ] HTML  [ ] Print                                    |
|                                                                                                      |
| Schedule:        [ ] Generate Now                                                                    |
|                  [ ] Schedule: [Weekly] [Monthly] [Term-End] at [09:00]                              |
|                  [ ] Email to: ____________________________________                                  |
|                                                                                                      |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| PREVIEW / ACTIONS                                                                                    |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| [Preview Report]  [Generate Report]  [Save Configuration]  [Load Template]  [Cancel]                 |
|                                                                                                      |
| Recent Reports:                                                                                      |
| * Class_Behaviour_Term1_2025.pdf (15 Sep 2025) - [Download]                                          |
| * Incident_Log_Aug2025.pdf (31 Aug 2025) - [Download]                                                |
| * Student_Summary_Q1.pdf (30 Jun 2025) - [Download]                                                  |
|                                                                                                      |
+------------------------------------------------------------------------------------------------------+
```


## REPORT 1: STUDENT BEHAVIOUR SUMMARY REPORT

====================================================================================================
                        STUDENT BEHAVIOUR SUMMARY REPORT - TERM 1 (2025-26)
====================================================================================================
Generated: 30 Sep 2025 10:00 AM                      Period: 01 Apr 2025 - 30 Sep 2025
Academic Session: 2025-26                            Assessment Period: Term 1 Assessment
Rating Scale: 5-Point Behavioural Scale              Aggregation: Weighted Average
====================================================================================================

DATA SOURCES:
  ba_computed_scores    — Category scores, overall scores, grades
  ba_assessment_ratings — Raw ratings per criterion per student
  ba_student_remarks    — Teacher holistic remarks
  ba_categories         — Category names, weights, polarity
  ba_criteria           — Criterion names, weights
  ba_rating_levels      — Level labels (Outstanding, Very Good, etc.)
  ba_incidents          — Incident count and severity breakdown
  std_students          — Student name, roll number, class-section
  sch_class_section_jnt — Class-section mapping
  sch_classes           — Class/grade name

====================================================================================================
```
+------------------------------------------------------------------------------------------------------+
| STUDENT OVERVIEW                                                                                     |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Student: Aarav Sharma                   Roll No: 2025-0012                Class: 5-A                 |
| Session: 2025-26                        Period: Term 1 Assessment         Scale: 5-Point             |
| Class Teacher: Mrs. Sunita Rao          Status: Reviewed                                             |
|                                                                                                      |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| OVERALL BEHAVIOURAL SCORE                                                                            |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| +-------------------+    +-------------------+    +-------------------+    +-------------------+     |
| | Overall Score     |    | Overall Grade     |    | Class Rank        |    | Incidents         |     |
| | 4.12 / 5.00       |    | A                 |    | 8 / 42            |    | +3  -1            |     |
| | >>>>>>>>>> 82.4%  |    | (Very Good)       |    |                   |    | (3 positive,      |     |
| +-------------------+    +-------------------+    +-------------------+    | 1 minor negative) |     |
|                                                                            +-------------------+     |
+------------------------------------------------------------------------------------------------------+

+----------------------------------------------------------------------------------------------------------+
| CATEGORY-WISE SCORES                                                                                     |
+----------------------------------------------------------------------------------------------------------+
|                                                                                                          |
| Source: ba_computed_scores (JOIN ba_categories for name, polarity, weight)                               |
|                                                                                                          |
| +-----------------------------+----------+--------+-------+--------+--------+---------------------------+|
| | Category                    | Polarity | Weight | Score | Grade  | vs Avg | Performance Bar           ||
| +-----------------------------+----------+--------+-------+--------+--------+---------------------------+|
| | Classroom Engagement        | Positive | 100    | 4.50  | A+     | +0.35  | >>>>>>>>>>>>>>>>>>>> 90%  ||
| | Respect & Responsibility    | Positive | 100    | 4.25  | A      | +0.20  | >>>>>>>>>>>>>>>>>> 85%    ||
| | Cooperation & Collaboration | Positive | 100    | 4.00  | A      | +0.05  | >>>>>>>>>>>>>>>> 80%      ||
| | Emotional & Social Dev      | Positive | 100    | 3.75  | B+     | -0.10  | >>>>>>>>>>>>>> 75%        ||
| | Leadership & Initiative     | Positive | 100    | 4.38  | A      | +0.33  | >>>>>>>>>>>>>>>>>>> 88%   ||
| | Disruptive Behaviours       | Negative | 100    | 4.50  | A+     | +0.25  | >>>>>>>>>>>>>>>>>>>> 90%  ||
| |   (inverted: raw 1.50)      |          |        |       |        |        |                           ||
| | Aggressive/Bullying         | Negative | 100    | 4.75  | A+     | +0.50  | >>>>>>>>>>>>>>>>>>>>> 95% ||
| |   (inverted: raw 1.25)      |          |        |       |        |        |                           ||
| | Academic Misconduct         | Negative | 100    | 4.25  | A      | +0.10  | >>>>>>>>>>>>>>>>>> 85%    ||
| |   (inverted: raw 1.75)      |          |        |       |        |        |                           ||
| | Health & Safety Violations  | Negative | 100    | 3.50  | B+     | -0.25  | >>>>>>>>>>>>> 70%         ||
| |   (inverted: raw 2.50)      |          |        |       |        |        |                           ||
| +-----------------------------+----------+--------+-------+--------+--------+---------------------------+|
|                                                                                                          |
| Notes:                                                                                                   |
|  * Negative polarity scores are INVERTED: displayed = (max_rating + 1) - raw_rating                      |
|  * "vs Avg" compares against class-section average for same category and period                          |
|  * Weight 100 = all categories contribute equally (proportional weighting)                               |
+----------------------------------------------------------------------------------------------------------+

+-----------------------------------------------------------------------------------------------------------+
| CRITERION-LEVEL DETAIL (Expandable per Category)                                                          |
+-----------------------------------------------------------------------------------------------------------+
|                                                                                                           |
| Source: ba_assessment_ratings (JOIN ba_criteria, ba_rating_levels)                                        |
|                                                                                                           |
| [-] Classroom Engagement (Score: 4.50 / 5.00)                                                             |
| +---+--------------------------------------------------------+--------+-------------+-----+--------------+|
| | # | Criterion                                              | Weight | Level       | Val | Remark       ||
| +---+--------------------------------------------------------+--------+-------------+-----+--------------+|
| | 1 | Active participation in class discussions              | 12.50  | Outstanding | 5.0 |              ||
| | 2 | Asking thoughtful, relevant questions                  | 12.50  | Very Good   | 4.0 |              ||
| | 3 | Paying sustained attention to instructions             | 12.50  | Outstanding | 5.0 |              ||
| | 4 | Completing classwork/homework on time                  | 12.50  | Very Good   | 4.0 |              ||
| | 5 | Showing enthusiasm and curiosity                       | 12.50  | Outstanding | 5.0 |              ||
| | 6 | Following classroom rules and routines                 | 12.50  | Very Good   | 4.0 |              ||
| | 7 | Using time productively                                | 12.50  | Outstanding | 5.0 |              ||
| | 8 | Bringing required materials                            | 12.50  | Very Good   | 4.0 | Occasionally ||
| |   |                                                        |        |             |     | forgets books||
| +---+--------------------------------------------------------+--------+-------------+-----+--------------+|
|                                                                                                           |
| [+] Respect & Responsibility (Score: 4.25 / 5.00)    [click to expand]                                    |
| [+] Cooperation & Collaboration (Score: 4.00 / 5.00) [click to expand]                                    |
| [+] Emotional & Social Dev (Score: 3.75 / 5.00)      [click to expand]                                    |
| [+] Leadership & Initiative (Score: 4.38 / 5.00)     [click to expand]                                    |
| [+] Disruptive Behaviours (Score: 4.50 / 5.00)       [click to expand]                                    |
| [+] Aggressive/Bullying (Score: 4.75 / 5.00)         [click to expand]                                    |
| [+] Academic Misconduct (Score: 4.25 / 5.00)         [click to expand]                                    |
| [+] Health & Safety Violations (Score: 3.50 / 5.00)  [click to expand]                                    |
|                                                                                                           |
+-----------------------------------------------------------------------------------------------------------+

+-------------------------------------------------------------------------------------------------------+
| INCIDENT SUMMARY FOR THIS STUDENT                                                                     |
+-------------------------------------------------------------------------------------------------------+
|                                                                                                       |
| Source: ba_incidents (JOIN ba_categories, ba_criteria, ba_interventions via junction)                 |
|                                                                                                       |
| +------+------------+------------------+----------+----------+---------------------------+-----------+|
| | #    | Date       | Type             | Severity | Location | Description               | Interv.   ||
| +------+------------+------------------+----------+----------+---------------------------+-----------+|
| | 1    | 15-May-25  | Positive Reinf.  | -        | Class    | Helped new student settle | Award     ||
| |      |            |                  |          |          | into class routine        |           ||
| +------+------------+------------------+----------+----------+---------------------------+-----------+|
| | 2    | 22-Jun-25  | Positive Reinf.  | -        | Playgrd  | Led inter-house sports    | Public    ||
| |      |            |                  |          |          | event organisation        | Recogn.   ||
| +------+------------+------------------+----------+----------+---------------------------+-----------+|
| | 3    | 10-Jul-25  | Positive Reinf.  | -        | Class    | Mentored 3 peers for      | Extra     ||
| |      |            |                  |          |          | Science project           | Privileges||
| +------+------------+------------------+----------+----------+---------------------------+-----------+|
| | 4    | 05-Aug-25  | Negative Incident| Minor    | Lab      | Did not follow safety     | Verbal    ||
| |      |            |                  |          |          | goggles protocol          | Warning   ||
| +------+------------+------------------+----------+----------+---------------------------+-----------+|
|                                                                                                       |
| Incidents Total: 4 (Positive: 3, Negative: 1)                                                         |
| Negative Breakdown: Minor: 1, Moderate: 0, Major: 0, Critical: 0                                      |
| Follow-ups Pending: 0                                                                                 |
| Parent Notifications Sent: 0 (threshold: moderate)                                                    |
+-------------------------------------------------------------------------------------------------------+

+-------------------------------------------------------------------------------------------------------+
| TEACHER REMARKS                                                                                       |
+-------------------------------------------------------------------------------------------------------+
|                                                                                                       |
| Source: ba_student_remarks.remark_text                                                                |
|                                                                                                       |
| Mrs. Sunita Rao (Class Teacher):                                                                      |
| "Aarav has been an exemplary student this term. His classroom engagement is outstanding and           |
|  he consistently helps peers. The only area of improvement is following lab safety protocols          |
|  — he received a verbal warning for not wearing goggles in August. Overall, a very positive           |
|  contributor to the class environment. Recommended for school prefect nomination."                    |
|                                                                                                       |
| Assessment Status: Reviewed (Reviewed by: Mr. Rajesh Kumar, Principal | 28 Sep 2025)                  |
| Reviewer Remarks: "Well documented. Agree with assessment."                                           |
+-------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| SCORE COMPUTATION BREAKDOWN (Transparency Section)                                                   |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Aggregation Method: weighted_average (from ba_config)                                                |
| Rating Scale: 5-Point (min: 1.0, max: 5.0)                                                           |
|                                                                                                      |
| Category Scores (from ba_computed_scores):                                                           |
|   Classroom Engagement:       4.50 x weight(100) = 450.00                                            |
|   Respect & Responsibility:   4.25 x weight(100) = 425.00                                            |
|   Cooperation & Collaboration:4.00 x weight(100) = 400.00                                            |
|   Emotional & Social Dev:     3.75 x weight(100) = 375.00                                            |
|   Leadership & Initiative:    4.38 x weight(100) = 438.00                                            |
|   Disruptive Behaviours:      4.50 x weight(100) = 450.00   (inverted from raw 1.50)                 |
|   Aggressive/Bullying:        4.75 x weight(100) = 475.00   (inverted from raw 1.25)                 |
|   Academic Misconduct:        4.25 x weight(100) = 425.00   (inverted from raw 1.75)                 |
|   Health & Safety:            3.50 x weight(100) = 350.00   (inverted from raw 2.50)                 |
|   -----------------------------------------------------------------------                            |
|   Sum of weighted scores: 3,788.00 / Sum of weights: 900 = 4.21                                      |
|                                                                                                      |
|   Overall Score: 4.12 (after multi-teacher averaging adjustments)                                    |
|   Grade Mapping: 4.12 -> A (Very Good) based on ba_rating_levels boundaries                          |
|                                                                                                      |
| Report Card Integration: Enabled (ba_config.is_result_integration_enabled = 1)                       |
|   Weightage: 10% of final academic result                                                            |
|   Normalised Score: (4.12 - 1.0) / (5.0 - 1.0) x 100 = 78.0%                                         |
|   Contribution: 78.0 x 0.10 = 7.80 marks added to academic total                                     |
+------------------------------------------------------------------------------------------------------+
```
[Export as PDF] [Export as Excel] [Print Report] [Share with Parent]



## REPORT 2: CLASS-SECTION BEHAVIOUR ANALYSIS REPORT

====================================================================================================
                        CLASS-SECTION BEHAVIOUR ANALYSIS - TERM 1 (2025-26)
====================================================================================================
Generated: 30 Sep 2025 10:30 AM                     Period: 01 Apr 2025 - 30 Sep 2025
Class: 5-A | Teacher: Mrs. Sunita Rao | Students: 42
====================================================================================================

DATA SOURCES:
  ba_computed_scores     — Aggregated scores per student per category
  ba_assessment_ratings  — Rating distribution analysis
  ba_assessments         — Assessment status tracking
  ba_categories          — Category metadata
  ba_incidents           — Incident counts per student
  ba_rating_levels       — Grade mapping
  std_students           — Student roster
  sch_class_section_jnt  — Class-section linkage

====================================================================================================
```
+------------------------------------------------------------------------------------------------------+
| CLASS BEHAVIOUR OVERVIEW                                                                             |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| +-------------------+ +-------------------+ +-------------------+ +-------------------+              |
| | Class Avg Score   | | Assessment Status | | Total Incidents   | | Students at Risk  |              |
| | 3.85 / 5.00       | | Reviewed: 42/42   | | +52  -18          | | 3 students        |              |
| | >>>>>>>>>>>>> 77% | | (100% complete)   | | (52 pos, 18 neg)  | | (score < 2.50)    |              |
| +-------------------+ +-------------------+ +-------------------+ +-------------------+              |
|                                                                                                      |
| +-------------------+ +-------------------+ +-------------------+ +-------------------+              |
| | Highest Scorer    | | Lowest Scorer     | | Most Improved     | | Most Incidents    |              |
| | Aarav S. (4.12)   | | Vikram M. (2.15)  | | Priya G. (+0.85)  | | Rohan K. (5 neg)  |              |
| +-------------------+ +-------------------+ +-------------------+ +-------------------+              |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| GRADE DISTRIBUTION                                                                                   |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Source: ba_computed_scores.overall_grade (grouped by grade)                                          |
|                                                                                                      |
| +------------------+-------+---------+------------------------------------------------------+        |
| | Grade            | Count | % Total | Distribution Bar                                     |        |
| +------------------+-------+---------+------------------------------------------------------+        |
| | A+ (Outstanding) | 5     | 11.9%   | >>>>>>>>>> 12%                                       |        |
| | A  (Very Good)   | 12    | 28.6%   | >>>>>>>>>>>>>>>>>>>>>>>>>> 29%                       |        |
| | B+ (Good)        | 14    | 33.3%   | >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 33%                |        |
| | B  (Satisfactory)| 8     | 19.0%   | >>>>>>>>>>>>>>>>>>> 19%                              |        |
| | C  (Needs Improv)| 3     | 7.1%    | >>>>>>> 7%                                           |        |
| +------------------+-------+---------+------------------------------------------------------+        |
|                                                                                                      |
| Class Average: 3.85 (B+)    |    School Average: 3.72 (B+)    |    Delta: +0.13                      |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| CATEGORY-WISE CLASS PERFORMANCE                                                                      |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Source: ba_computed_scores (AVG per category across all 42 students)                                 |
|                                                                                                      |
| +---------------------------+----------+---------+---------+---------+--------+-----+-----+          |
| | Category                  | Polarity | Class   | School  | Delta   | Highest| Low | Std |          |
| |                           |          | Avg     | Avg     |         |        |     | Dev |          |
| +---------------------------+----------+---------+---------+---------+--------+-----+-----+          |
| | Classroom Engagement      | Positive | 4.05    | 3.90    | +0.15   | 5.00   |2.25 |0.62 |          |
| | Respect & Responsibility  | Positive | 3.92    | 3.85    | +0.07   | 4.75   |2.00 |0.58 |          |
| | Cooperation & Collaboration| Positive| 3.78    | 3.72    | +0.06   | 4.50   |2.50 |0.55 |          |
| | Emotional & Social Dev    | Positive | 3.65    | 3.60    | +0.05   | 4.50   |2.00 |0.68 |          |
| | Leadership & Initiative   | Positive | 3.72    | 3.55    | +0.17   | 5.00   |1.75 |0.72 |          |
| | Disruptive Behaviours     | Negative | 3.95    | 3.80    | +0.15   | 5.00   |1.50 |0.85 |          |
| | Aggressive/Bullying       | Negative | 4.15    | 3.95    | +0.20   | 5.00   |2.25 |0.65 |          |
| | Academic Misconduct       | Negative | 3.88    | 3.78    | +0.10   | 4.75   |2.00 |0.70 |          |
| | Health & Safety Violations| Negative | 3.55    | 3.60    | -0.05   | 4.75   |1.75 |0.78 |          |
| +---------------------------+----------+---------+---------+---------+--------+-----+-----+          |
|                                                                                                      |
| Observations:                                                                                        |
| * Class 5-A outperforms school average in 8 of 9 categories                                          |
| * Health & Safety Violations slightly below school average (-0.05) - needs attention                 |
| * Leadership & Initiative has highest positive delta (+0.17) - strong class culture                  |
| * Disruptive Behaviours shows widest std dev (0.85) - inconsistency among students                   |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| STUDENT RANKING TABLE                                                                                |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Source: ba_computed_scores.overall_score, ba_incidents (counted per student)                         |
|                                                                                                      |
| +-----+------------------+---------+-------+-------+------+------+------+---------------------------+|
| | Rank| Student Name     | Roll No | Score | Grade | +Inc | -Inc | Flag | Trend vs Last Period      ||
| +-----+------------------+---------+-------+-------+------+------+------+---------------------------+|
| | 1   | Aarav Sharma     | 0012    | 4.12  | A     | 3    | 1    |      | >> +0.15                  ||
| | 2   | Meera Iyer       | 0005    | 4.08  | A     | 4    | 0    |      | >> +0.22                  ||
| | 3   | Ananya Reddy     | 0018    | 4.05  | A     | 2    | 0    |      | > +0.05                   ||
| | 4   | Kabir Singh      | 0022    | 4.02  | A     | 3    | 1    |      | >> +0.18                  ||
| | 5   | Diya Patel       | 0009    | 3.98  | B+    | 1    | 0    |      | > +0.08                   ||
| | ... | ...              | ...     | ...   | ...   | ...  | ...  | ...  | ...                       ||
| | 40  | Rahul Verma      | 0031    | 2.45  | C     | 0    | 3    | (!!) | << -0.35                  ||
| | 41  | Sanjay Gupta     | 0037    | 2.25  | C     | 0    | 4    | (!!) | < -0.15                   ||
| | 42  | Vikram Mehta     | 0041    | 2.15  | C     | 0    | 5    | (!!) | <<< -0.50                 ||
| +-----+------------------+---------+-------+-------+------+------+------+---------------------------+|
|                                                                                                      |
| Legend: (!!) = At Risk (overall score < 2.50)                                                        |
|         +Inc = Positive Incidents, -Inc = Negative Incidents                                         |
|         Trend: >> improving, > stable, < declining, << sharp decline                                 |
|                                                                                                      |
| ... Showing 42 students (top 5 and bottom 3 displayed)                                               |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| INCIDENT DISTRIBUTION IN THIS CLASS                                                                  |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Source: ba_incidents WHERE student_id IN (students of class 5-A)                                     |
|                                                                                                      |
| +--------------------+-------+---------+-------------------------------------------------------+     |
| | Incident Type      | Count | % Total | Distribution                                          |     |
| +--------------------+-------+---------+-------------------------------------------------------+     |
| | Positive Reinf.    | 52    | 74.3%   | >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  |     |
| | Negative - Minor   | 10    | 14.3%   | >>>>>>>>>>                                            |     |
| | Negative - Moderate| 5     | 7.1%    | >>>>>                                                 |     |
| | Negative - Major   | 2     | 2.9%    | >>                                                    |     |
| | Negative - Critical| 1     | 1.4%    | >                                                     |     |
| +--------------------+-------+---------+-------------------------------------------------------+     |
|                                                                                                      |
| Location Heatmap:                                                                                    |
| +-------------+----------+---------+--------+--------+--------+---------+--------+                         |
| | Classroom   | Playgrd  | Corridor| Lab    | Transp | Canteen| Library | Other  |                       |
| +-------------+----------+---------+--------+--------+--------+---------+--------+                         |
| | 38 (54%)    | 12 (17%) | 5 (7%)  | 8(11%) | 3 (4%) | 2 (3%) | 1 (1%)  | 1 (1%) |                        |
| | >>>>>>>>>   | >>>>     | >>      | >>>    | >      | >      |         |        |                       |
| +-------------+----------+---------+--------+--------+--------+---------+--------+                         |
|                                                                                                      |
| Interventions Applied:                                                                               |
| +---------------------+-------+------------------------------------------------------------------+   |
| | Intervention Type   | Count | Details                                                          |   |
| +---------------------+-------+------------------------------------------------------------------+   |
| | Verbal Warning      | 8     | Most common for minor incidents                                   |   |
| | Written Warning     | 3     | Used for repeated offences                                       |   |
| | Award/Certificate   | 15    | Highest among all intervention types                             |   |
| | Public Recognition  | 12    | Assemblies, notice boards                                        |   |
| | Extra Privileges    | 8     | Library extra time, free period activities                        |   |
| | Parent Meeting      | 3     | For moderate/major incidents                                     |   |
| | Counselling Referral| 2     | Ongoing cases (Vikram M., Sanjay G.)                             |   |
| | Detention           | 1     | One case (Rohan K. — critical incident)                          |   |
| | Suspension          | 0     | None this period                                                 |   |
| +---------------------+-------+------------------------------------------------------------------+   |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| AT-RISK STUDENTS DETAIL                                                                              |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Source: ba_computed_scores WHERE overall_score < 2.50, ba_incidents, ba_student_remarks               |
|                                                                                                      |
| +--+-----------------+-------+-------+------+----------------------------------------------------+   |
| |# | Student         | Score | Grade | -Inc | Key Concerns                                       |   |
| +--+-----------------+-------+-------+------+----------------------------------------------------+   |
| |1 | Rahul Verma     | 2.45  | C     | 3    | Disruptive Behaviours: 1.75, Academic Misconduct:  |   |
| |  | (Roll: 0031)    |       |       |      | 2.00. Two moderate incidents. Counselling ongoing.  |   |
| |  |                 |       |       |      | Follow-up: 15 Oct 2025                             |   |
| +--+-----------------+-------+-------+------+----------------------------------------------------+   |
| |2 | Sanjay Gupta    | 2.25  | C     | 4    | Aggressive/Bullying: 1.50, Cooperation: 2.25.      |   |
| |  | (Roll: 0037)    |       |       |      | One major incident. Parent meeting held.            |   |
| |  |                 |       |       |      | Follow-up: 10 Oct 2025                             |   |
| +--+-----------------+-------+-------+------+----------------------------------------------------+   |
| |3 | Vikram Mehta    | 2.15  | C     | 5    | Multiple categories below 2.50. One critical       |   |
| |  | (Roll: 0041)    |       |       |      | incident (safety violation). Counselling referral   |   |
| |  |                 |       |       |      | active. Parent notified. Follow-up: 05 Oct 2025    |   |
| +--+-----------------+-------+-------+------+----------------------------------------------------+   |
|                                                                                                      |
| Action Required: Review at-risk students in next PTM / staff meeting                                 |
+------------------------------------------------------------------------------------------------------+
```
[Export as PDF] [Export as Excel] [Print Report] [Share Class Report]



## REPORT 3: INCIDENT LOG & INTERVENTION REPORT

====================================================================================================
                        INCIDENT LOG & INTERVENTION REPORT - AUGUST 2025
====================================================================================================
Generated: 01 Sep 2025 09:00 AM                     Period: 01 Aug 2025 - 31 Aug 2025
Scope: School-wide                                   Report Type: Monthly Snapshot
====================================================================================================

DATA SOURCES:
  ba_incidents                  — Core incident records
  ba_incident_witnesses_jnt     — Witness data (polymorphic: student/staff)
  ba_incident_intervention_jnt  — Interventions applied per incident
  ba_interventions              — Intervention master list
  ba_categories                 — Linked category (optional)
  ba_criteria                   — Linked criterion (optional)
  std_students                  — Student details
  sch_employees                 — Reporter (teacher/staff) details

====================================================================================================
```
+------------------------------------------------------------------------------------------------------+
| EXECUTIVE SUMMARY                                                                                    |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Total Incidents:        145     | Positive Reinf.:      98 (67.6%)  | Avg/Day: 4.7                    |
| Negative Incidents:     47      | Follow-ups Pending:   12          | Parent Notified: 8              |
| Notifications Threshold: moderate (from ba_config)                                                   |
|                                                                                                      |
| Month-over-Month Change: v -5.2% (vs Jul 2025: 153)                                                 |
| Positive/Negative Ratio: 2.09:1 (Target: >3:1)                                                      |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| INCIDENT BREAKDOWN BY TYPE & SEVERITY                                                                |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| +-------------------------------+-------+---------+-------------------------------------------------+  |
| | Type / Severity               | Count | % Total | Distribution                                    |  |
| +-------------------------------+-------+---------+-------------------------------------------------+  |
| | Positive Reinforcement        | 98    | 67.6%   | >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> |  |
| |   (no severity applicable)    |       |         |                                                 |  |
| +-------------------------------+-------+---------+-------------------------------------------------+  |
| | Negative - Minor              | 22    | 15.2%   | >>>>>>>>>>>                                     |  |
| | Negative - Moderate           | 15    | 10.3%   | >>>>>>>>                                        |  |
| | Negative - Major              | 7     | 4.8%    | >>>>                                            |  |
| | Negative - Critical           | 3     | 2.1%    | >>                                              |  |
| +-------------------------------+-------+---------+-------------------------------------------------+  |
|                                                                                                      |
| Note: 3 critical incidents all had parent notifications sent (is_notified = 1)                       |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| INCIDENTS BY CATEGORY (ba_categories linkage)                                                        |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| +-------------------------------+-------+----------+----------+------+------+------+--------+        |
| | Category                      | Total | Positive | Negative | Minor| Mod  | Major| Critical|       |
| +-------------------------------+-------+----------+----------+------+------+------+--------+        |
| | Classroom Engagement          | 35    | 28       | 7        | 5    | 2    | 0    | 0      |         |
| | Respect & Responsibility      | 22    | 15       | 7        | 3    | 3    | 1    | 0      |         |
| | Cooperation & Collaboration   | 18    | 15       | 3        | 2    | 1    | 0    | 0      |         |
| | Emotional & Social Dev        | 15    | 12       | 3        | 2    | 1    | 0    | 0      |         |
| | Leadership & Initiative       | 20    | 18       | 2        | 1    | 0    | 1    | 0      |         |
| | Disruptive Behaviours         | 12    | 0        | 12       | 5    | 4    | 2    | 1      |         |
| | Aggressive/Bullying           | 10    | 0        | 10       | 2    | 3    | 3    | 2      |         |
| | Academic Misconduct           | 8     | 0        | 8        | 5    | 2    | 1    | 0      |         |
| | Health & Safety Violations    | 5     | 0        | 5        | 2    | 2    | 0    | 1      |         |
| | (Uncategorised)               | 10    | 10       | 0        | 0    | 0    | 0    | 0      |         |
| +-------------------------------+-------+----------+----------+------+------+------+--------+        |
|                                                                                                      |
| Key Insight: Aggressive/Bullying has the highest proportion of major/critical incidents               |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| LOCATION ANALYSIS                                                                                    |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Source: ba_incidents.location (ENUM distribution)                                                    |
|                                                                                                      |
| +-----------+---------+---------+----------+------+---------+--------+--------+--------+             |
| | Location  |Classroom|Playgrd  | Corridor | Lab  |Transport| Canteen| Library| Other  |             |
| +-----------+---------+---------+----------+------+---------+--------+--------+--------+             |
| | Total     | 62      | 28      | 15       | 12   | 10      | 8      | 5      | 5      |             |
| | Positive  | 45      | 20      | 8        | 8    | 5       | 5      | 4      | 3      |             |
| | Negative  | 17      | 8       | 7        | 4    | 5       | 3      | 1      | 2      |             |
| | % Neg     | 27%     | 29%     | 47%      | 33%  | 50%     | 38%    | 20%    | 40%    |             |
| +-----------+---------+---------+----------+------+---------+--------+--------+--------+             |
|                                                                                                      |
| Hotspots (highest negative %):                                                                       |
|  1. Transport (50% negative) - Consider additional supervision during bus routes                     |
|  2. Corridor (47% negative)  - Transition periods need monitoring                                    |
|  3. Other/Canteen (38-40%)   - Unstructured time zones                                               |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| INTERVENTION USAGE ANALYSIS                                                                          |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Source: ba_incident_intervention_jnt (JOIN ba_interventions for type)                                |
|                                                                                                      |
| +-----+---------------------+------------+-------+--------------------------------------------------+|
| | #   | Intervention        | Type       | Count | Usage Context                                    ||
| +-----+---------------------+------------+-------+--------------------------------------------------+|
| | 1   | Award/Certificate   | Reward     | 42    | >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Most  ||
| | 2   | Public Recognition  | Reward     | 35    | >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>             ||
| | 3   | Extra Privileges    | Reward     | 28    | >>>>>>>>>>>>>>>>>>>>>>>>>>>>                     ||
| | 4   | Verbal Warning      | Corrective | 22    | >>>>>>>>>>>>>>>>>>>>>>                           ||
| | 5   | Written Warning     | Corrective | 12    | >>>>>>>>>>>>                                     ||
| | 6   | Parent Meeting      | Counselling| 8     | >>>>>>>>                                         ||
| | 7   | Counselling Referral| Counselling| 5     | >>>>>                                            ||
| | 8   | Detention           | Corrective | 3     | >>>                                              ||
| | 9   | Suspension          | Corrective | 1     | >                                                ||
| +-----+---------------------+------------+-------+--------------------------------------------------+|
|                                                                                                      |
| Reward : Corrective : Counselling Ratio = 105 : 38 : 13 = 67% : 24% : 8%                           |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| FOLLOW-UP TRACKER                                                                                    |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Source: ba_incidents WHERE is_follow_up_required = 1                                                 |
|                                                                                                      |
| +--+-----------------+--------+------------+-----------+----------------------------------------+    |
| |# | Student         | Class  | Follow-Up  | Status    | Notes                                  |    |
| |  |                 |        | Date       |           |                                        |    |
| +--+-----------------+--------+------------+-----------+----------------------------------------+    |
| |1 | Vikram Mehta    | 5-A    | 05-Oct-25  | PENDING   | Safety violation follow-up. Counsellor |    |
| |  |                 |        |            |           | session scheduled.                     |    |
| +--+-----------------+--------+------------+-----------+----------------------------------------+    |
| |2 | Sanjay Gupta    | 5-A    | 10-Oct-25  | PENDING   | Bullying incident. Parent meeting done.|    |
| |  |                 |        |            |           | Behaviour contract signed.             |    |
| +--+-----------------+--------+------------+-----------+----------------------------------------+    |
| |3 | Rohan Kumar     | 7-B    | 08-Oct-25  | PENDING   | Repeated disruption. Detention served. |    |
| |  |                 |        |            |           | Monitor for 2 weeks.                   |    |
| +--+-----------------+--------+------------+-----------+----------------------------------------+    |
| |4 | Neha Patel      | 8-C    | 12-Oct-25  | PENDING   | Academic misconduct (copying).         |    |
| |  |                 |        |            |           | Re-assessment scheduled.               |    |
| +--+-----------------+--------+------------+-----------+----------------------------------------+    |
| |..| ... (8 more)    |        |            |           |                                        |    |
| +--+-----------------+--------+------------+-----------+----------------------------------------+    |
|                                                                                                      |
| Total Follow-ups Pending: 12 | Overdue: 2 | Due This Week: 4                                        |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| TREND - LAST 6 MONTHS                                                                                |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Month      | Mar   | Apr   | May   | Jun   | Jul   | Aug   |                                        |
| +-----------+-------+-------+-------+-------+-------+-------+                                        |
| | Total     | 120   | 135   | 142   | 138   | 153   | 145   | -> Stable                              |
| | Positive  | 78    | 88    | 95    | 92    | 102   | 98    |                                        |
| |           | >>>>> | >>>>>> | >>>>>> | >>>>>> | >>>>>>> | >>>>>> |                                  |
| | Negative  | 42    | 47    | 47    | 46    | 51    | 47    |                                        |
| |           | >>>   | >>>>  | >>>>  | >>>>  | >>>>  | >>>>  |                                        |
| | Pos/Neg   | 1.86  | 1.87  | 2.02  | 2.00  | 2.00  | 2.09  | -> Improving                         |
| +-----------+-------+-------+-------+-------+-------+-------+                                        |
|                                                                                                      |
| Target Ratio: 3.0:1 | Current: 2.09:1 | Gap: 0.91                                                   |
+------------------------------------------------------------------------------------------------------+
```
[Export as PDF] [Export as Excel] [Print Report] [Schedule Monthly Auto-Generation]



## REPORT 4: CATEGORY & CRITERIA PERFORMANCE REPORT

====================================================================================================
                        CATEGORY & CRITERIA PERFORMANCE ANALYSIS - TERM 1 (2025-26)
====================================================================================================
Generated: 30 Sep 2025 11:00 AM                     Scope: School-wide (All Classes)
Academic Session: 2025-26                            Students Assessed: 2,150
====================================================================================================

DATA SOURCES:
  ba_computed_scores    — Category-level aggregates
  ba_assessment_ratings — Criterion-level detail
  ba_categories         — Category definitions, weights, polarity
  ba_criteria           — Criterion definitions, weights
  ba_rating_levels      — Score-to-grade mapping
  ba_class_category_jnt — Category-class applicability
  sch_classes           — Class names for group analysis

====================================================================================================
```
+------------------------------------------------------------------------------------------------------+
| SCHOOL-WIDE CATEGORY OVERVIEW                                                                        |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| +---------------------------+----------+--------+--------+--------+--------+--------+--------+       |
| | Category                  | Polarity | School | Class  | Class  | Class  | Trend  | Status |       |
| |                           |          | Avg    | 1-5    | 6-8    | 9-12   | (v T0) |        |       |
| +---------------------------+----------+--------+--------+--------+--------+--------+--------+       |
| | Classroom Engagement      | Positive | 3.90   | 4.15   | 3.85   | 3.72   | +0.08  | Good   |       |
| | Respect & Responsibility  | Positive | 3.85   | 4.05   | 3.80   | 3.68   | +0.05  | Good   |       |
| | Cooperation & Collaboration| Positive| 3.72   | 3.95   | 3.70   | 3.52   | +0.02  | OK     |       |
| | Emotional & Social Dev    | Positive | 3.60   | 3.82   | 3.55   | 3.42   | +0.10  | Good   |       |
| | Leadership & Initiative   | Positive | 3.55   | 3.65   | 3.50   | 3.48   | +0.12  | Good   |       |
| | Disruptive Behaviours     | Negative | 3.80   | 4.10   | 3.72   | 3.58   | +0.05  | Good   |       |
| | Aggressive/Bullying       | Negative | 3.95   | 4.25   | 3.85   | 3.75   | +0.08  | Good   |       |
| | Academic Misconduct       | Negative | 3.78   | 4.00   | 3.70   | 3.62   | -0.02  | Watch  |       |
| | Health & Safety Violations| Negative | 3.60   | 3.85   | 3.52   | 3.42   | -0.05  | Alert  |       |
| +---------------------------+----------+--------+--------+--------+--------+--------+--------+       |
|                                                                                                      |
| Key Observations:                                                                                    |
| * Primary classes (1-5) consistently score higher across all categories                              |
| * Health & Safety showing declining trend (-0.05) - school-wide intervention needed                  |
| * Academic Misconduct slightly declined in secondary classes - exam integrity focus                   |
| * Scores show expected age-based pattern: younger students score higher on compliance                |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| CLASS-LEVEL APPLICABILITY MAP                                                                        |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Source: ba_class_category_jnt (which categories are mapped to which classes)                          |
|                                                                                                      |
| +---------------------------+----+----+----+----+----+----+----+----+----+----+----+----+----+       |
| | Category                  |BV1 |BV2 | 1  | 2  | 3  | 4  | 5  | 6  | 7  | 8  | 9  | 10 |11-12|   |
| +---------------------------+----+----+----+----+----+----+----+----+----+----+----+----+----+       |
| | Classroom Engagement      | x  | x  | x  | x  | x  | x  | x  | x  | x  | x  | x  | x  | x   |   |
| | Respect & Responsibility  | x  | x  | x  | x  | x  | x  | x  | x  | x  | x  | x  | x  | x   |   |
| | Cooperation & Collaboration| x | x  | x  | x  | x  | x  | x  | x  | x  | x  | x  | x  | x   |   |
| | Emotional & Social Dev    | x  | x  | x  | x  | x  | x  | x  | x  | x  | x  | x  | x  | x   |   |
| | Leadership & Initiative   |    |    |    |    | x  | x  | x  | x  | x  | x  | x  | x  | x   |   |
| | Disruptive Behaviours     |    |    |    | x  | x  | x  | x  | x  | x  | x  | x  | x  | x   |   |
| | Aggressive/Bullying       |    |    |    | x  | x  | x  | x  | x  | x  | x  | x  | x  | x   |   |
| | Academic Misconduct       |    |    |    |    |    |    | x  | x  | x  | x  | x  | x  | x   |   |
| | Health & Safety Violations|    |    | x  | x  | x  | x  | x  | x  | x  | x  | x  | x  | x   |   |
| +---------------------------+----+----+----+----+----+----+----+----+----+----+----+----+----+       |
|                                                                                                      |
| Note: x = category is applicable and assessed for that class level                                   |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| CRITERION-LEVEL DEEP DIVE (Bottom 10 Criteria by School Average)                                     |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Source: ba_assessment_ratings (AVG per criterion across all students), ba_criteria                    |
|                                                                                                      |
| +--+---------------------------------------------+--------------------------+------+------+------+   |
| |# | Criterion                                   | Category                 | Avg  | Mode | StdDev|  |
| +--+---------------------------------------------+--------------------------+------+------+------+   |
| |1 | Following lab safety protocols                | Health & Safety          | 2.85 | 3    | 1.12 |  |
| |2 | Completing classwork on time                   | Classroom Engagement     | 3.05 | 3    | 0.95 |  |
| |3 | Accepting constructive criticism gracefully    | Emotional & Social       | 3.08 | 3    | 1.05 |  |
| |4 | Properly handling lab equipment                | Health & Safety          | 3.10 | 3    | 1.08 |  |
| |5 | Avoiding distracting behaviours               | Disruptive Behaviours    | 3.12 | 3    | 1.15 |  |
| |6 | Maintaining hygiene in shared spaces           | Health & Safety          | 3.15 | 3    | 0.98 |  |
| |7 | Volunteering for class responsibilities        | Leadership & Initiative  | 3.18 | 3    | 0.88 |  |
| |8 | Submitting original work                       | Academic Misconduct      | 3.20 | 3    | 1.02 |  |
| |9 | Managing stress and emotions                   | Emotional & Social       | 3.22 | 3    | 1.10 |  |
| |10| Avoiding copying/cheating                      | Academic Misconduct      | 3.25 | 3    | 1.18 |  |
| +--+---------------------------------------------+--------------------------+------+------+------+   |
|                                                                                                      |
| Recommendations:                                                                                     |
| * Health & Safety criteria occupy 3 of the bottom 10 - prioritise safety awareness campaigns         |
| * Academic integrity criteria appearing in lower ranks - reinforce honour code                        |
| * High std dev on criteria 5, 9, 10 indicates polarised student responses                            |
+------------------------------------------------------------------------------------------------------+
```
[Export as PDF] [Export as Excel] [Print Report] [Share with HODs]



## REPORT 5: TEACHER ASSESSMENT PROGRESS REPORT

====================================================================================================
                        TEACHER ASSESSMENT PROGRESS REPORT - TERM 1 (2025-26)
====================================================================================================
Generated: 25 Sep 2025 09:00 AM                     Period: Term 1 Assessment
Deadline: 28 Sep 2025                                Assessment Period Status: OPEN
====================================================================================================

DATA SOURCES:
  ba_assessments         — Assessment status per teacher per class-section
  ba_assessment_periods  — Period dates, deadline, status
  ba_assessment_ratings  — Rating completion tracking
  ba_student_remarks     — Remarks completion tracking
  ba_audit_log           — Activity timeline
  sch_employees          — Teacher details
  sch_class_section_jnt  — Class-section assignments
  sch_classes            — Class names

====================================================================================================
```
+------------------------------------------------------------------------------------------------------+
| PERIOD OVERVIEW                                                                                      |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| +-------------------+ +-------------------+ +-------------------+ +-------------------+              |
| | Period Name       | | Window            | | Deadline          | | Days Remaining    |              |
| | Term 1 Assessment | | 01 Sep - 28 Sep   | | 28 Sep 2025       | | 3 days            |              |
| +-------------------+ +-------------------+ +-------------------+ +-------------------+              |
|                                                                                                      |
| +-------------------+ +-------------------+ +-------------------+ +-------------------+              |
| | Total Assessments | | Completed (Locked)| | Submitted         | | Draft/Pending     |              |
| | 85                | | 12 (14.1%)        | | 38 (44.7%)        | | 35 (41.2%)        |              |
| +-------------------+ +-------------------+ +-------------------+ +-------------------+              |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| ASSESSMENT STATUS BY WORKFLOW STATE                                                                  |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Source: ba_assessments.status (grouped by ENUM values)                                               |
|                                                                                                      |
| +------------------+-------+---------+------------------------------------------------------+        |
| | Status           | Count | % Total | Progress Bar                                         |        |
| +------------------+-------+---------+------------------------------------------------------+        |
| | Draft            | 25    | 29.4%   | >>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 29%                    |        |
| | Submitted        | 38    | 44.7%   | >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 45%     |        |
| | Reviewed         | 10    | 11.8%   | >>>>>>>>>>>> 12%                                     |        |
| | Locked           | 12    | 14.1%   | >>>>>>>>>>>>>> 14%                                   |        |
| +------------------+-------+---------+------------------------------------------------------+        |
|                                                                                                      |
| WORKFLOW: draft --> submitted --> reviewed --> locked                                                 |
|           25         38            10           12     = 85 total assessments                         |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| TEACHER-WISE PROGRESS                                                                                |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Source: ba_assessments (GROUP BY teacher_id), sch_employees                                           |
|                                                                                                      |
| +--+---------------------+--------+----------+-------+-------+---------+----------+---------+        |
| |# | Teacher             | Dept   | Sections | Done  | Pend  | Status  | Last     | Ratings |        |
| |  |                     |        | Assigned | (Sub) |       |         | Activity | Compl % |        |
| +--+---------------------+--------+----------+-------+-------+---------+----------+---------+        |
| |1 | Mrs. Sunita Rao     | Primary| 3        | 3     | 0     | ALL SUB | 24 Sep   | 100%    |        |
| |2 | Mr. Ajay Sharma     | Primary| 2        | 2     | 0     | ALL SUB | 23 Sep   | 100%    |        |
| |3 | Ms. Priya Nair      | Middle | 3        | 2     | 1     | PARTIAL | 22 Sep   | 88%     |        |
| |4 | Mr. Karthik R.      | Middle | 2        | 1     | 1     | PARTIAL | 20 Sep   | 72%     |        |
| |5 | Mrs. Lakshmi D.     | Second.| 3        | 1     | 2     | PARTIAL | 18 Sep   | 45%     |        |
| |6 | Mr. Ravi Kumar      | Second.| 2        | 0     | 2     | PENDING | 15 Sep   | 30%     |        |
| |7 | Ms. Deepika S.      | Second.| 2        | 0     | 2     | PENDING | 12 Sep   | 15%     |        |
| |..| ...                 |        |          |       |       |         |          |         |        |
| +--+---------------------+--------+----------+-------+-------+---------+----------+---------+        |
|                                                                                                      |
| Completion by Department:                                                                            |
|   Primary:    100% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>                                |
|   Middle:      75% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>                                            |
|   Secondary:   42% >>>>>>>>>>>>>>>>>>>>>                                                             |
|                                                                                                      |
| Teachers Not Started (0% ratings): 3 teachers (flagged for principal notification)                   |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| RATING GRID COMPLETION DETAIL                                                                        |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Source: ba_assessment_ratings WHERE rating_level_id IS NOT NULL vs total expected cells               |
|                                                                                                      |
| For each assessment: Expected cells = (students in section) x (active criteria for class)            |
|                                                                                                      |
| +--+---------------------+---------+----------+-----------+--------+--------+-----------------------+|
| |# | Teacher + Section   | Students| Criteria | Expected  | Filled | Empty  | Completion            ||
| |  |                     |         |          | Cells     | Cells  | Cells  |                       ||
| +--+---------------------+---------+----------+-----------+--------+--------+-----------------------+|
| |1 | Mrs. Rao - 5A       | 42      | 58       | 2,436     | 2,436  | 0      | >>>>>>>>>>>>>>>>>> 100%||
| |2 | Mrs. Rao - 5B       | 40      | 58       | 2,320     | 2,320  | 0      | >>>>>>>>>>>>>>>>>> 100%||
| |3 | Mrs. Rao - 4A       | 38      | 50       | 1,900     | 1,900  | 0      | >>>>>>>>>>>>>>>>>> 100%||
| |4 | Mr. Sharma - 3A     | 35      | 42       | 1,470     | 1,470  | 0      | >>>>>>>>>>>>>>>>>> 100%||
| |5 | Ms. Nair - 6A       | 45      | 58       | 2,610     | 2,350  | 260    | >>>>>>>>>>>>>>>>    90%||
| |6 | Mr. Ravi - 9A       | 48      | 58       | 2,784     | 836    | 1,948  | >>>>>>              30%||
| |7 | Ms. Deepika - 10A   | 50      | 58       | 2,900     | 435    | 2,465  | >>>                 15%||
| +--+---------------------+---------+----------+-----------+--------+--------+-----------------------+|
|                                                                                                      |
| Remarks Completion:                                                                                  |
|   Assessments with remarks (ba_student_remarks): 45 / 85 = 52.9%                                    |
|   Assessments without any remarks: 40 (47.1%)                                                        |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| AUDIT ACTIVITY LOG (Recent 10 Events)                                                                |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Source: ba_audit_log ORDER BY changed_at DESC LIMIT 10                                               |
|                                                                                                      |
| +--+---------------------+------------------+-----------+-----------+----------+---------------------+|
| |# | Timestamp           | Entity Type      | Field     | Old Value | New Value| Changed By          ||
| +--+---------------------+------------------+-----------+-----------+----------+---------------------+|
| |1 | 25 Sep 09:15:32     | assessment       | status    | draft     | submitted| Mr. Ajay Sharma     ||
| |2 | 25 Sep 09:12:05     | assessment_rating| rating_id | 3 (Good)  | 4 (V.Good)| Mrs. Sunita Rao   ||
| |3 | 25 Sep 09:10:48     | assessment       | status    | submitted | reviewed | Principal           ||
| |4 | 24 Sep 16:42:11     | assessment_rating| rating_id | NULL      | 4 (V.Good)| Ms. Priya Nair    ||
| |5 | 24 Sep 16:38:22     | assessment_rating| rating_id | 2 (N.Imp) | 3 (Good) | Ms. Priya Nair     ||
| |6 | 24 Sep 15:55:10     | incident         | follow_up | NULL      | Scheduled| Mr. Karthik R.     ||
| |7 | 24 Sep 15:30:45     | assessment       | status    | reviewed  | locked   | System (Period Lock)||
| |8 | 23 Sep 14:22:18     | assessment_rating| rating_id | 4 (V.Good)| 5 (Outst)| Mr. Ajay Sharma    ||
| |9 | 23 Sep 14:20:05     | assessment       | status    | draft     | submitted| Mr. Ajay Sharma     ||
| |10| 23 Sep 11:15:33     | assessment_rating| rating_id | NULL      | 3 (Good) | Mr. Ravi Kumar      ||
| +--+---------------------+------------------+-----------+-----------+----------+---------------------+|
|                                                                                                      |
| Total audit entries this period: 12,450 | Rating changes: 11,800 | Status transitions: 520           |
| Incident audits: 130                                                                                 |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| RECOMMENDATIONS & ALERTS                                                                             |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| 1. URGENT - 3 DAYS TO DEADLINE:                                                                     |
|    * 25 assessments still in DRAFT - send reminder to 7 teachers                                     |
|    * 3 teachers have 0% completion - escalate to HOD immediately                                     |
|    * 38 submitted assessments awaiting review - Principal action needed                              |
|                                                                                                      |
| 2. QUALITY CHECK:                                                                                    |
|    * 40 assessments (47.1%) have no student remarks - require before submission                      |
|    * Ms. Nair's 6A assessment has 260 empty rating cells - likely missed a category                  |
|                                                                                                      |
| 3. AUTO-ACTIONS AT DEADLINE:                                                                         |
|    * Period status will change: open --> closed                                                       |
|    * Draft assessments will remain editable but no new ones can be created                           |
|    * Score computation will trigger for all reviewed assessments                                      |
+------------------------------------------------------------------------------------------------------+
```
[Send Reminder to Pending Teachers] [Export Progress] [Notify Principal] [Print Status]



## REPORT 6: BEHAVIOURAL TREND ANALYSIS REPORT

====================================================================================================
                        BEHAVIOURAL TREND ANALYSIS - ACADEMIC YEAR 2025-26
====================================================================================================
Generated: 30 Sep 2025 12:00 PM                     Scope: School-wide
Periods Compared: Term 0 (Baseline) vs Term 1        Students: 2,150
====================================================================================================

DATA SOURCES:
  ba_computed_scores    — Period-over-period score comparison
  ba_assessment_periods — Period metadata for timeline
  ba_incidents          — Incident frequency trends
  ba_config             — Aggregation method, result integration settings
  ba_categories         — Category metadata for grouping

====================================================================================================
```
+------------------------------------------------------------------------------------------------------+
| SCHOOL-WIDE SCORE TRENDS                                                                             |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Source: ba_computed_scores.overall_score (AVG grouped by period_id)                                   |
|                                                                                                      |
| Period        | Term 0     | Term 1     | Change    | Trend                                          |
|               | (Baseline) | (Current)  |           |                                                |
| +---------    +------------+------------+-----------+------------------------------------------------+ |
| | Overall Avg | 3.65       | 3.78       | +0.13     | >> Improving (3.6% improvement)                | |
| |             | >>>>>>     | >>>>>>>    |           |                                                | |
| |             |            |            |           |                                                | |
| | Positive Cat| 3.72       | 3.82       | +0.10     | > Improving                                    | |
| | Neg Cat(inv)| 3.58       | 3.74       | +0.16     | >> Improving (stronger improvement)             | |
| +-------------+------------+------------+-----------+------------------------------------------------+ |
|                                                                                                      |
| Interpretation: Students are improving faster in negative-polarity categories                        |
| (fewer disruptive/aggressive behaviours) than in positive-polarity categories                        |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| GRADE SHIFT ANALYSIS (Term 0 vs Term 1)                                                              |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| +------------------+----------+----------+---------+------------------------------------------------+  |
| | Grade            | Term 0   | Term 1   | Change  | Movement                                     |  |
| +------------------+----------+----------+---------+------------------------------------------------+  |
| | A+ (Outstanding) | 185(8.6%)| 225(10.5%)| +40    | >> More students reaching top grade           |  |
| | A  (Very Good)   | 520(24.2)| 580(27.0)| +60     | >> Strong upward movement                    |  |
| | B+ (Good)        | 680(31.6)| 695(32.3)| +15     | > Stable                                     |  |
| | B  (Satisfactory)| 480(22.3)| 420(19.5)| -60     | >> Students moving up from B to B+/A          |  |
| | C  (Needs Improv)| 285(13.3)| 230(10.7)| -55     | >> Fewer at-risk students                    |  |
| +------------------+----------+----------+---------+------------------------------------------------+  |
|                                                                                                      |
| Net Positive Movement: 37.7% of students improved by at least 1 grade level                          |
| Net Negative Movement: 8.2% of students declined by at least 1 grade level                           |
| Stable: 54.1% of students maintained same grade                                                      |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| CATEGORY TREND DETAIL                                                                                |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| +---------------------------+--------+--------+---------+--------+----------------------------------+ |
| | Category                  | Term 0 | Term 1 | Delta   | Status | Visual Trend                     | |
| +---------------------------+--------+--------+---------+--------+----------------------------------+ |
| | Classroom Engagement      | 3.82   | 3.90   | +0.08   | Up     | >>>>>>>>  >>>>>>>>+              | |
| | Respect & Responsibility  | 3.80   | 3.85   | +0.05   | Up     | >>>>>>>>  >>>>>>>>               | |
| | Cooperation & Collaboration| 3.70  | 3.72   | +0.02   | Flat   | >>>>>>>   >>>>>>>                | |
| | Emotional & Social Dev    | 3.50   | 3.60   | +0.10   | Up     | >>>>>>>   >>>>>>>++              | |
| | Leadership & Initiative   | 3.43   | 3.55   | +0.12   | Up     | >>>>>>    >>>>>>>++              | |
| | Disruptive Behaviours     | 3.75   | 3.80   | +0.05   | Up     | >>>>>>>>  >>>>>>>>               | |
| | Aggressive/Bullying       | 3.87   | 3.95   | +0.08   | Up     | >>>>>>>>  >>>>>>>>+              | |
| | Academic Misconduct       | 3.80   | 3.78   | -0.02   | Watch  | >>>>>>>>  >>>>>>>-               | |
| | Health & Safety Violations| 3.65   | 3.60   | -0.05   | Alert  | >>>>>>>   >>>>>>>--              | |
| +---------------------------+--------+--------+---------+--------+----------------------------------+ |
|                                                                                                      |
| Categories Improving: 7/9                                                                            |
| Categories Declining: 2/9 (Academic Misconduct, Health & Safety)                                     |
| Biggest Gain: Leadership & Initiative (+0.12)                                                        |
| Biggest Drop: Health & Safety Violations (-0.05)                                                     |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| INCIDENT TREND COMPARISON                                                                            |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| +---------------------------+----------+----------+---------+----------------------------------------+ |
| | Metric                    | Term 0   | Term 1   | Change  | Insight                                | |
| +---------------------------+----------+----------+---------+----------------------------------------+ |
| | Total Incidents           | 380      | 435      | +14.5%  | More incidents logged (likely better   | |
| |                           |          |          |         | reporting, not worse behaviour)         | |
| | Positive Incidents        | 230      | 295      | +28.3%  | >> Strong increase in recognition       | |
| | Negative Incidents        | 150      | 140      | -6.7%   | v Actual decline in negative behaviour  | |
| | Positive/Negative Ratio   | 1.53     | 2.11     | +0.58   | >> Significant improvement              | |
| | Minor Severity            | 85       | 72       | -15.3%  | v Fewer minor issues                    | |
| | Moderate Severity         | 42       | 38       | -9.5%   | v Slight decrease                       | |
| | Major Severity            | 18       | 22       | +22.2%  | ^ Concerning — investigate              | |
| | Critical Severity         | 5        | 8        | +60.0%  | ^^ Alert — may need policy review      | |
| | Parent Notifications Sent | 15       | 22       | +46.7%  | More notifications (threshold working) | |
| | Follow-ups Completed      | 28       | 35       | +25.0%  | Better follow-through                  | |
| +---------------------------+----------+----------+---------+----------------------------------------+ |
|                                                                                                      |
| ALERT: Major (+22.2%) and Critical (+60.0%) incidents increased despite overall improvement.          |
| This suggests the severity of remaining incidents is escalating even as overall count declines.       |
| Recommendation: Review counselling capacity and intervention effectiveness.                          |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| RECOMMENDATIONS                                                                                      |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| 1. CONTINUE:                                                                                         |
|    * Positive reinforcement programs - driving the strong 28.3% increase                             |
|    * Leadership development activities - highest category improvement (+0.12)                        |
|                                                                                                      |
| 2. INVESTIGATE:                                                                                      |
|    * Major/Critical incident escalation - engage counsellors and HODs                                |
|    * Health & Safety declining trend - schedule safety awareness week                                |
|    * Academic Misconduct stagnation - review assessment integrity measures                           |
|                                                                                                      |
| 3. POLICY:                                                                                           |
|    * Consider lowering parent notification threshold from 'moderate' to 'minor'                      |
|      for repeat offenders                                                                            |
|    * Review intervention effectiveness — are corrective measures working for                         |
|      major/critical cases?                                                                           |
|                                                                                                      |
| 4. NEXT PERIOD TARGET:                                                                               |
|    * School-wide average: 3.78 --> 3.90 (+3.2%)                                                      |
|    * Positive/Negative ratio: 2.11 --> 2.50                                                          |
|    * At-risk students (C grade): 230 --> 180 (-21.7%)                                                |
+------------------------------------------------------------------------------------------------------+
```
[Export as PDF] [Export as Excel] [Present to Management] [Set Next Term Targets]



## REPORT 7: PARENT COMMUNICATION REPORT

====================================================================================================
                        PARENT COMMUNICATION REPORT - TERM 1 (2025-26)
====================================================================================================
Generated: 30 Sep 2025 02:00 PM                     For: Parent/Guardian of Aarav Sharma
Class: 5-A | Roll No: 2025-0012                      Class Teacher: Mrs. Sunita Rao
====================================================================================================

DATA SOURCES:
  ba_computed_scores    — Student's category and overall scores
  ba_rating_levels      — Grade label display
  ba_student_remarks    — Teacher's holistic comment
  ba_incidents          — Incident summary (sanitised for parent view)
  ba_config             — Result integration details
  std_students          — Student identification

NOTE: This report is a parent-friendly version of the Student Behaviour Summary.
It excludes internal data like audit logs, multi-teacher averaging details, and
raw criterion-level scores. Language is constructive and growth-oriented.

====================================================================================================
```
+------------------------------------------------------------------------------------------------------+
| DEAR PARENT / GUARDIAN                                                                               |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Dear Mr. & Mrs. Sharma,                                                                              |
|                                                                                                      |
| This report summarises Aarav's behavioural assessment for Term 1 (April - September 2025).           |
| Our school uses a 5-Point rating scale to assess students across 9 behavioural categories.           |
| Ratings are provided by class teachers and subject teachers, reviewed by the Principal.              |
|                                                                                                      |
| Rating Scale: Outstanding (5) | Very Good (4) | Good (3) | Needs Improvement (2) | Unsatisfactory (1)|
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| OVERALL ASSESSMENT                                                                                   |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| +-------------------------------+------+------+------+------+------+                                 |
| |                               |  1   |  2   |  3   |  4   |  5   |                                 |
| | Overall Behaviour Score       |      |      |      | [XX] |      |   4.12 / 5.00  Grade: A         |
| +-------------------------------+------+------+------+------+------+                                 |
|                                                                                                      |
| Aarav's overall behaviour is rated as "Very Good" (Grade A).                                         |
| He ranks in the top 20% of his class.                                                                |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| CATEGORY-WISE ASSESSMENT                                                                             |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| +--+-----------------------------+-------+-------+----------------------------------------------+    |
| |# | Behaviour Area              | Score | Grade | Comment                                      |    |
| +--+-----------------------------+-------+-------+----------------------------------------------+    |
| |1 | Classroom Engagement        | 4.50  | A+    | Aarav actively participates in class          |    |
| |  |                             |       |       | discussions and is consistently attentive.    |    |
| +--+-----------------------------+-------+-------+----------------------------------------------+    |
| |2 | Respect & Responsibility    | 4.25  | A     | Shows strong respect for teachers and peers.  |    |
| |  |                             |       |       | Takes responsibility for his actions.         |    |
| +--+-----------------------------+-------+-------+----------------------------------------------+    |
| |3 | Cooperation & Collaboration | 4.00  | A     | Works well in group activities and supports   |    |
| |  |                             |       |       | teammates effectively.                        |    |
| +--+-----------------------------+-------+-------+----------------------------------------------+    |
| |4 | Emotional & Social Dev      | 3.75  | B+    | Good emotional awareness. Can further develop |    |
| |  |                             |       |       | stress management and conflict resolution.    |    |
| +--+-----------------------------+-------+-------+----------------------------------------------+    |
| |5 | Leadership & Initiative     | 4.38  | A     | Shows natural leadership qualities. Mentors   |    |
| |  |                             |       |       | peers and takes initiative in class projects.  |    |
| +--+-----------------------------+-------+-------+----------------------------------------------+    |
| |6 | Discipline & Self-Control   | 4.50  | A+    | Very well-disciplined. Follows class rules    |    |
| |  | (Disruptive Behaviours inv.)|       |       | consistently with minimal reminders.          |    |
| +--+-----------------------------+-------+-------+----------------------------------------------+    |
| |7 | Kindness & Inclusion        | 4.75  | A+    | Exceptionally kind and inclusive. No incidents |    |
| |  | (Aggressive/Bullying inv.)  |       |       | of unkind behaviour reported.                 |    |
| +--+-----------------------------+-------+-------+----------------------------------------------+    |
| |8 | Academic Integrity          | 4.25  | A     | Consistently submits original work and        |    |
| |  | (Academic Misconduct inv.)  |       |       | demonstrates honest academic practices.       |    |
| +--+-----------------------------+-------+-------+----------------------------------------------+    |
| |9 | Safety Awareness            | 3.50  | B+    | Generally safety-conscious. One reminder was  |    |
| |  | (Health & Safety inv.)      |       |       | needed about lab safety goggles protocol.     |    |
| +--+-----------------------------+-------+-------+----------------------------------------------+    |
|                                                                                                      |
| Note: Negative categories are displayed in parent-friendly positive language with                     |
| inverted scores (higher = better behaviour)                                                          |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| HIGHLIGHTS & RECOGNITION                                                                             |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Positive Notes:                                                                                      |
|   * 15-May-2025: Helped a new student settle into class routines (Award/Certificate)                 |
|   * 22-Jun-2025: Led inter-house sports event organisation (Public Recognition)                      |
|   * 10-Jul-2025: Mentored 3 peers for the Science project (Extra Privileges granted)                 |
|                                                                                                      |
| Areas for Growth:                                                                                    |
|   * Lab safety protocol adherence — one reminder was issued in August                                |
|   * Emotional self-regulation during stressful periods (exam preparation)                            |
|                                                                                                      |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| TEACHER'S REMARKS                                                                                    |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| "Aarav has been an exemplary student this term. His classroom engagement is outstanding and           |
|  he consistently helps peers. The only area of improvement is following lab safety protocols.         |
|  Overall, a very positive contributor to the class environment."                                     |
|                                                                                                      |
|                                                         — Mrs. Sunita Rao (Class Teacher)             |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| REPORT CARD CONTRIBUTION                                                                             |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| Behavioural Assessment contributes 10% to the final academic result (as configured by school).       |
| Aarav's behavioural contribution: 7.80 / 10.00 marks                                                |
|                                                                                                      |
| (Source: ba_config.weightage_percent = 10.0, is_result_integration_enabled = true)                   |
+------------------------------------------------------------------------------------------------------+
```
[Download PDF] [Print] [Share via SMS] [Share via Email]



## REPORT 8: EXECUTIVE DASHBOARD (Principal / HOD)

====================================================================================================
                        BEHAVIOURAL ASSESSMENT EXECUTIVE DASHBOARD - Q1 2025-26
====================================================================================================
Generated: 30 Sep 2025                    For: Principal / HODs / Management
Academic Session: 2025-26                 Period: Term 1 Assessment (Locked)
====================================================================================================

DATA SOURCES:
  ba_computed_scores     — School-wide score aggregates
  ba_assessments         — Completion and workflow status
  ba_assessment_periods  — Period lifecycle status
  ba_incidents           — Incident analytics
  ba_config              — Module configuration review
  ba_audit_log           — Audit activity summary
  ba_categories          — Category performance
  ba_rating_scales       — Active scale info

====================================================================================================
```
+------------------------------------------------------------------------------------------------------+
| KEY PERFORMANCE INDICATORS (KPIs)                                                                    |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| +--------------------------------+----------+--------+--------+--------+----------------------------+ |
| | KPI                            | Current  | Target | Status | Trend  | Comments                   | |
| +--------------------------------+----------+--------+--------+--------+----------------------------+ |
| | School Avg Behaviour Score     | 3.78/5.0 | 4.0    | [..] 76| >> +3.6| Improving steadily         | |
| | Assessment Completion Rate     | 100%     | 100%   | [OK]   | =      | All assessments submitted  | |
| | Review Completion Rate         | 85%      | 100%   | [..] 85| > +5%  | 15% still pending review   | |
| | Positive/Negative Incident Ratio| 2.11:1  | 3.0:1  | [..] 70| >> +38%| Improving but below target | |
| | At-Risk Students (Grade C)     | 230(10.7)| <5%    | [!!]   | v -55  | Down from 285 but still >5%| |
| | Parent Notification Rate       | 100%     | 100%   | [OK]   | =      | All thresholds honoured    | |
| | Follow-up Completion Rate      | 74%      | 90%    | [..] 74| > +8%  | 26% follow-ups overdue     | |
| | Avg Score StdDev (consistency) | 0.78     | <0.60  | [!!]   | v -0.02| Wide spread in performance  | |
| | Result Integration             | Enabled  | -      | [OK]   | -      | 10% weightage applied      | |
| | Audit Trail Coverage           | 100%     | 100%   | [OK]   | =      | All changes logged         | |
| +--------------------------------+----------+--------+--------+--------+----------------------------+ |
|                                                                                                      |
| Legend: [OK] On Target  [..] In Progress  [!!] Needs Attention                                       |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| SCHOOL-WIDE OVERVIEW                                                                                 |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| +-------------------+ +-------------------+ +-------------------+ +-------------------+              |
| | Students Assessed | | Total Assessments | | Total Incidents   | | Active Categories |              |
| | 2,150 / 2,150     | | 85 (all locked)   | | 435 this term     | | 9 categories      |              |
| | 100% coverage     | |                   | | +295 pos / -140 neg| | 58 criteria       |              |
| +-------------------+ +-------------------+ +-------------------+ +-------------------+              |
|                                                                                                      |
| +-------------------+ +-------------------+ +-------------------+ +-------------------+              |
| | Rating Scale      | | Aggregation       | | Result Weightage  | | Notif. Threshold  |              |
| | 5-Point (Active)  | | Weighted Average  | | 10% of final      | | Moderate           |              |
| | (from ba_config)  | | (from ba_config)  | | (from ba_config)  | | (from ba_config)  |              |
| +-------------------+ +-------------------+ +-------------------+ +-------------------+              |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| GRADE DISTRIBUTION - SCHOOL-WIDE                                                                     |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| +------------------+-------+---------+------------------------------------------------------+        |
| | Grade            | Count | % Total | Distribution                                         |        |
| +------------------+-------+---------+------------------------------------------------------+        |
| | A+ (Outstanding) | 225   | 10.5%   | >>>>>>>>>>> 10.5%                                    |        |
| | A  (Very Good)   | 580   | 27.0%   | >>>>>>>>>>>>>>>>>>>>>>>>>>>> 27%                     |        |
| | B+ (Good)        | 695   | 32.3%   | >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 32%                 |        |
| | B  (Satisfactory)| 420   | 19.5%   | >>>>>>>>>>>>>>>>>>>> 20%                             |        |
| | C  (Needs Improv)| 230   | 10.7%   | >>>>>>>>>>> 11%                                      |        |
| +------------------+-------+---------+------------------------------------------------------+        |
|                                                                                                      |
| Target: A+ and A should together exceed 50%. Current: 37.5%. Gap: 12.5%                             |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| CLASS-WISE PERFORMANCE COMPARISON                                                                    |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| +-------------+---------+--------+------+------+------+---------+-----------------------------------+|
| | Class       | Students| Avg    | Best | Worst| StdDv| At-Risk | Performance Bar                   ||
| +-------------+---------+--------+------+------+------+---------+-----------------------------------+|
| | BV1-BV2     | 120     | 4.15   | 4.85 | 3.20 | 0.42 | 2       | >>>>>>>>>>>>>>>>>>>>>>>>>>>> 83%  ||
| | Class 1-2   | 280     | 4.08   | 4.90 | 2.80 | 0.48 | 8       | >>>>>>>>>>>>>>>>>>>>>>>>>>> 82%   ||
| | Class 3-5   | 420     | 3.92   | 4.75 | 2.15 | 0.62 | 25      | >>>>>>>>>>>>>>>>>>>>>>>>> 78%     ||
| | Class 6-8   | 550     | 3.72   | 4.60 | 1.85 | 0.72 | 65      | >>>>>>>>>>>>>>>>>>>>>> 74%        ||
| | Class 9-10  | 480     | 3.55   | 4.45 | 1.50 | 0.82 | 78      | >>>>>>>>>>>>>>>>>>>> 71%          ||
| | Class 11-12 | 300     | 3.48   | 4.50 | 1.65 | 0.85 | 52      | >>>>>>>>>>>>>>>>>>> 70%           ||
| +-------------+---------+--------+------+------+------+---------+-----------------------------------+|
|                                                                                                      |
| Pattern: Expected age-based gradient (younger = higher compliance scores)                            |
| Concern: Class 9-10 has highest at-risk count (78) — transition period challenges                    |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| TOP 5 HIGHLIGHTS                                                                                     |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| 1. >> Assessment completion: 100% — all 85 assessments submitted and locked on time                 |
| 2. >> Positive incident ratio improved 38% — recognition culture growing                            |
| 3. >> At-risk students reduced by 55 (from 285 to 230) — interventions working                      |
| 4. >> Leadership & Initiative showed biggest improvement (+0.12) across all classes                  |
| 5. >> Audit trail 100% complete — full transparency and compliance maintained                        |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| TOP 5 CONCERNS                                                                                       |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| 1. !! Major/Critical incidents increased (+22%/+60%) despite overall improvement                     |
| 2. !! Health & Safety Violations declining (-0.05) — lab safety and transport incidents               |
| 3. !! 230 students (10.7%) still at Grade C — target is <5%                                          |
| 4. !! Follow-up completion only 74% — 26% overdue follow-ups need attention                          |
| 5. !! Academic Misconduct stagnating (-0.02) — integrity measures need review                        |
+------------------------------------------------------------------------------------------------------+

+------------------------------------------------------------------------------------------------------+
| ACTION ITEMS FOR NEXT QUARTER                                                                        |
+------------------------------------------------------------------------------------------------------+
|                                                                                                      |
| +----------+--------------------------------------------------+---------------+-----+--------------+ |
| | Priority | Action Item                                      | Responsible   | By  | Expected     | |
| |          |                                                  |               |     | Impact       | |
| +----------+--------------------------------------------------+---------------+-----+--------------+ |
| | P0       | Review all major/critical incidents with          | Principal     | Oct | Reduce severe| |
| |          | counsellor; assess intervention effectiveness     |               | 10  | incidents    | |
| +----------+--------------------------------------------------+---------------+-----+--------------+ |
| | P0       | Clear 26% overdue follow-ups — assign to HODs     | HODs          | Oct | 90%+ follow- | |
| |          |                                                  |               | 5   | up rate      | |
| +----------+--------------------------------------------------+---------------+-----+--------------+ |
| | P1       | Launch Safety Awareness Week for all classes       | Safety Officer| Oct | Reverse -0.05| |
| |          |                                                  |               | 15  | decline      | |
| +----------+--------------------------------------------------+---------------+-----+--------------+ |
| | P1       | Academic Integrity workshop for Class 9-12         | Exam Cell     | Oct | Improve +0.10| |
| |          |                                                  |               | 20  | in misconduct| |
| +----------+--------------------------------------------------+---------------+-----+--------------+ |
| | P2       | Set up peer mentorship — A+/A students mentor      | Class Teachers| Nov | Reduce at-   | |
| |          | Grade C students                                  |               | 1   | risk count   | |
| +----------+--------------------------------------------------+---------------+-----+--------------+ |
| | P2       | Consider lowering notification threshold to        | Admin         | Nov | Earlier      | |
| |          | 'minor' for repeat offenders                      |               | 15  | intervention | |
| +----------+--------------------------------------------------+---------------+-----+--------------+ |
|                                                                                                      |
| Next Review: Mid-Term 2 Assessment — Target Date: 15 Jan 2026                                       |
+------------------------------------------------------------------------------------------------------+
```
[Export Full Dashboard PDF] [Schedule Quarterly Report] [Share with Management] [Print Summary]

# Planning Accuracy Report — Business Requirements

## What This Screen Does

The Planning Accuracy report evaluates the sheer efficiency and realism of the school's academic planning. It acts as a post-mortem tool, comparing the theoretical Planned Target Dates with the Actual Completion Dates across the entire school.

By highlighting massive variances, such as teachers consistently needing 10 periods for a chapter that the HOD stubbornly planned for 5 periods, it identifies structural flaws in the syllabus timeline. This empowers the school to create a vastly improved, data-driven schedule for the next academic year.

---

## When This Screen Is Used

- End of Year Review during curriculum review meetings to analyze why certain subjects couldn't finish their syllabus before the final exams
- Teacher Appraisals when evaluating a teacher's performance, pacing, and ability to stick to deadlines
- Structural Bottleneck Identification to identify inherently difficult chapters that are universally delayed across all classroom sections

---

## Key Metrics and Visualizations

**Average Variance Metric**
A core numerical output subtracts the Scheduled End Date from the Actual Completion Date. Positive numbers indicate delays, while negative numbers indicate early completion, such as +4.2 Days or -1.5 Days.

**Pace Categorization Bar Chart**
Groups topics and teachers into predefined behavioral buckets, categorizing their pace as Fast-tracked, On Time, Delayed, or Severely Delayed.

**Seasonal Delay Heatmap**
A visual grid with Months on one axis and Subjects on the other. The cells are colored based on delay severity. This helps spot external systemic issues, such as observing that almost all subjects get severely delayed in November due to Annual Day practice.

---

## Business Rules and Conditions

**Contextual Aggregation Logic**
The report must allow pivoting the variance data by different dimensions to find the root cause of delays. If a specific topic like Calculus Integration is delayed by an average of 6 days across all teachers, the system highlights it as a Planning Fault, meaning the administration didn't allocate enough time for a difficult subject. Conversely, if Calculus is finished on time by 4 teachers but delayed by 12 days by Mr. Smith, the system highlights it as an Execution Fault, meaning Mr. Smith has pacing issues.

**Proxy Teacher Accountability**
Because the system tracks the Actual Taught By teacher separately from the Assigned teacher, the report accurately attributes the variance to the teacher who actually delivered the content. If a substitute teacher took over and rushed the syllabus, the variance is logged against the substitute, not the absent primary teacher.

**Outlier Exclusion**
The calculation engine should ideally offer a toggle to exclude statistical anomalies, such as a topic marked complete 60 days late because the teacher simply forgot to click the button in the app, rather than actually teaching it 60 days late.

---

## Workflow Steps

**Adjusting Annual Plans**
At the end of the year, the Principal opens the Planning Accuracy report to prepare for the new academic calendar. The report highlights a massive anomaly showing that across all 5 sections of Class 10 Math, the chapter Surface Areas and Volumes took an average of 14 days longer than planned. The Principal drills down, pivoting the data by Teacher. They see that every single math teacher was flagged as Delayed for this chapter. The Principal concludes this is a structural planning fault, not teacher incompetence. In the next academic year, the Principal instructs the Math HOD to allocate 15 planned periods instead of 10 for this specific chapter.

---

## Example Scenario

During annual appraisals, an HOD looks at the Planning Accuracy report for a junior teacher, Mr. Sharma. 

The report shows Mr. Sharma has a highly negative variance, consistently finishing his Science syllabus 2 to 3 weeks ahead of schedule. While this looks like efficiency, the HOD cross-references this with the Exam Module and sees his students are scoring terribly. The HOD uses this undeniable data to advise Mr. Sharma during his appraisal, pointing out that the data shows he is rushing the syllabus. He needs to slow his pace, utilize the allocated time fully, and spend more periods on concept revision rather than just racing to finish the book.

---

## Related Screens

- **Lesson Date Planning** — The source screen providing the baseline Scheduled End Date and Planned Periods
- **Progress Tracker** — The source providing the Actual Completion Date

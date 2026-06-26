# Performance Categories — Business Requirements

## What This Screen Does

The Performance Categories screen is the intelligent engine driving automated remedial actions in the system. While traditional software just prints grades on a report card, this screen maps specific percentage ranges to qualitative labels and binds them to automated AI Triggers. 

When a student's performance falls into one of these percentage bands, this screen dictates exactly what the system should do next—whether to escalate an alert to a parent, push extra practice material, or mandate an automated re-test.

---

## When This Screen Is Used

- System Setup configured by the academic heads to define what numerically constitutes a Good or Poor score
- Workflow Automation when configuring the system's reaction to test results
- Adaptive Testing when defining rules for the auto-assignment of remedial homework to struggling students

---

## Key Fields at a Glance

**Identity and Academic Meaning**
A Short Code and Display Name act as a unique identifier and the text displayed on screen. A Performance Rank captures the hierarchical rank of the performance band, used for sorting and color-coding logic on dashboards. The Score Band defines the exact numerical minimum and maximum percentage range, such as 33.00% to 45.99%.

**Automation Settings**
An AI Severity dropdown determines the urgency of the notification sent to teachers or parents, with options like Low, Medium, High, or Critical. An AI Default Action dropdown defines the system's automated response, with options like Accelerate, Progress, Practice, Remediate, or Escalate. An Auto-Retest Required Toggle allows the system to bypass the teacher and automatically query the Question Bank to build and assign a remedial test on the failed topic.

**Application Scope**
A Display Order and Color Code determines how reports are visually rendered, such as Red for Poor or Green for Topper. A Scope Rule determines if this specific performance rule applies to the whole School or just a specific Class. A System Lock Toggle prevents schools from breaking core logic if the percentages are locked by the educational board.

---

## Business Rules and Conditions

**Non-Overlapping Validations**
The system must ensure that percentage ranges do not overlap. Before saving a new category, the system must check all existing active categories within the same scope. It must reject the input if the new range overlaps with an existing one, preventing a student from falling into two different performance categories simultaneously.

**Scope Precedence**
Schools often have different definitions of success for different age groups. If a global rule states that a Topper is 90-100%, but a Class-specific rule states that for Grade 1 a Topper is 95-100%, the system logic must always apply the most specific scope over the broader rule.

---

## Workflow Steps

**Adding a New Performance Category**
The Academic Director opens Performance Categories and clicks Add Category. They enter the Name as "Critical Intervention Required" and provide a Short Code. They define the Range with a minimum of 0.00% and a maximum of 32.99%. They set the AI Severity to Critical and the AI Default Action to Escalate. They enable the Auto-Retest Required toggle and set the Scope to apply School-wide. Upon saving, the system validates that the range does not overlap with existing bands and saves it successfully.

---

## Example Scenario

A Class 9 student completes an online Quiz on Thermodynamics and scores 28%. 

The Assessment Engine calculates the score and checks the Performance Categories table. It finds that 28% falls into the Critical Intervention Required band. 

Because the Severity is set to Critical, the system instantly triggers an alert on the teacher's mobile app. Because the Action is set to Escalate, an automated email is drafted and sent to the parents. Because the Auto-Retest toggle is enabled, the system silently accesses the Question Bank, pulls 10 new easy questions on Thermodynamics, packages them into a Remedial Quiz, and pushes it to the student's portal with a deadline of 48 hours. All of this happens without any human intervention.

---

## Related Screens

- **Grade Divisions Master** — A similar concept, but strictly used for official report card printing rather than automated actions
- **Syllabus Reports** — Uses the color codes defined here to render the progress trackers on the dashboard

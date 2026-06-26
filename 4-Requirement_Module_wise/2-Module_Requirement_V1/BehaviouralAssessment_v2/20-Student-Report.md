# Student Report — Business Requirements

## What This Screen Does

The Student Report is a standalone, highly formatted digital profile card. It serves as a student's holistic behavioral dossier. Instead of looking at raw spreadsheets, this dashboard consolidates a student's entire behavioral history for the active academic session into a single visually polished, print-ready document.

It aggregates the student's category-wise numeric averages, detailed criteria ratings, homeroom teacher remarks, real-time incident logs (both positive achievements and infractions), and the outcomes of any applied corrective interventions.

---

## When This Screen Is Used

- **Parent-Teacher Meetings**: Homeroom teachers print or display this sheet to guide conversations with parents.
- **Disciplinary Hearings**: The HOD and Principal review the student’s complete record before deciding on severe interventions.
- **Report Card Printing**: Bulk generating behavior sheets to attach to final academic progress cards.

---

## Key Widgets & Report Structure

The document layout is divided into four logical zones:

### 1. Student Identity Header
- Student Photo, Full Name, Admission Number, Class & Section, and Homeroom Teacher.
- **Download PDF** button in the top right corner.

### 2. High-Level KPI Summary (Metric Badges)
- **Overall Behavioral Average**: e.g., `4.22 / 5.00` (highlighted in color badge matching score tier).
- **Achievements Logged**: Count of positive behavioral logs.
- **Infractions Logged**: Count of negative behavioral logs.
- **Interventions Completed**: Active/Completed count.

### 3. Detailed Behavioral Rubrics Grid
Structured by Category and Criteria:
- **Category (Social EQ)**
  - *Respects Peers*: `Exemplary (5.0)` — "Always speaks politely and shares materials."
  - *Collaboration*: `Satisfactory (3.0)` — "Works well in teams but sometimes dominates."
- **Category (Self-Discipline)**
  - *Punctuality*: `Proficient (4.0)` — "Consistently arrives on time."
- **Narrative Section**: Displays the exact text from the [Student Remarks](./10-Remarks.md) table.

### 4. Incident Timeline & Interventions Resolved
A chronological feeds of events:
- **2026-11-20**: Negative Incident (Medium Severity) — "Class disruption."
  - *Intervention Applied*: Disciplinary Reflection Assignment (Status: Completed).
- **2026-11-12**: Positive Incident (Info) — "Assisted lab setup."

---

## Business Rules and Conditions

**The Grade Lockdown Rule**
- Draft or unapproved grades from `ba_assessments` are **strictly hidden** from the parent-facing digital Student Report. If a period is still in `Draft` or `Submitted` status, the Rubrics Grid shows: `"Grading for this period is in progress. Averages will be visible once finalized by HOD."`
- Staff users can toggle a `"Show Drafts"` checkbox in the top bar to inspect active scoring sheets.

**High-Quality PDF Generation**
- The "Download PDF" action utilizes an isolated CSS print stylesheet. Page-break margins are strictly defined so that student headers do not orphan at the bottom of pages, and charts render in clean high-contrast gray scale/color.

---

## Workflow Steps

**Reviewing and Printing a Report Card**
1. Teacher Mrs. Priya opens the **Reports Hub** and searches for student `Amit Sharma`.
2. Clicks **View Report**.
3. The Student Report dashboard loads. Mrs. Priya reviews the KPI summary (Overall score: `4.7` - Excellent), the rubrics grid, and the positive incident timeline showing 2 achievements.
4. Clicks **Download PDF**.
5. The system initiates an HTML-to-PDF compilation job on the server, formats the document using standard school logos and borders, and outputs a downloadable file `Amit_Sharma_Behavior_Report_Term_1.pdf`.
6. Mrs. Priya prints the file to present at the next day's parent conference.

---

## Example Scenario

During a parent conference, Ajay’s mother is concerned about his behavior. The teacher loads Ajay’s Student Report:
- It displays a low overall score: `2.4 / 5.0`.
- The rubrics grid shows a low rating `Needs Support (1.0)` in "Conflict Resolution."
- The timeline lists 2 negative incidents of physical disputes at recess, with an intervention "Anger Management Counseling" marked `In Progress`.
- This visual evidence helps the parent understand the school's concern and the restorative action plan in place.

---

## Related Screens

- [09-Ratings.md](./09-Ratings.md) / [10-Remarks.md](./10-Remarks.md) — Source databases for the rubrics and comments.
- [12-Incident-Log.md](./12-Incident-Log.md) / [14-Interventions-Applied.md](./14-Interventions-Applied.md) — Sources for the incident timelines.
- [15-Reports-Hub.md](./15-Reports-Hub.md) — The parent portal access.

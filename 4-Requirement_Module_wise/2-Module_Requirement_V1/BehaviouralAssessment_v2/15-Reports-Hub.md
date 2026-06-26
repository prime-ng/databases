# Reports Hub — Business Requirements

## What This Screen Does

The Reports Hub is the central control station for generating and exporting behavioral data. Rather than scattering download links across various grading and setup pages, this dashboard aggregates all analytical and compliance reports into a single, structured interface.

From the Reports Hub, administrators, coordinators, and teachers can filter broad behavioral metrics, select target cohorts (by Class, Section, or Period), and export structured reports. The hub supports downloading data in standard formats like **CSV** and **Excel** for deep statistical analysis or print integration.

---

## When This Screen Is Used

- **Parent-Teacher Meeting Preparation**: Teachers generate bulk reports summarizing class averages and comments to prepare for conferences.
- **Academic Term Audits**: Admin exports the school-wide behavioral averages to compare against academic performance.
- **Disciplinary Reviews**: The Principal pulls historical incident logs to evaluate school climate and intervention effectiveness.
- **Compliance Reporting**: Generating audit logs for external board reviews to confirm consistent grading practices.

---

## Key Fields & UI Layout

The screen features a split layout: a left-hand navigation menu listing available report categories and a right-hand dynamic configuration and filtering panel.

### Available Reports Menu
- **Student Scores**: Standard grid export of final averages per student.
- **Category Summary**: Performance averages grouped by main behavioral domains.
- **Period Report**: Comparison trends across distinct terms or monthly periods.
- **Audit Trail**: Tracking modification actions and timestamps.
- **Incident Summary**: Aggregating incident counts, witnesses, and resolutions.

### Report Filters Panel (Dynamic based on selected report)
| Filter Field | Data Type | UI Element | Mandatory | Description |
|--------------|-----------|------------|-----------|-------------|
| **Academic Session** | Integer (ID) | Dropdown | Yes | References `org_academic_sessions`. |
| **Assessment Period**| Integer (ID) | Dropdown | Yes | References `ba_assessment_periods`. |
| **Class** | Integer (ID) | Dropdown | No | Filter by Class Level (e.g., "Grade 10"). |
| **Section** | Integer (ID) | Dropdown | No | Filter by Section (e.g., "A"). Enabled only when Class is selected. |
| **Format** | String | Radio Group | Yes | Options: `Excel (.xlsx)` or `CSV (.csv)`. |

### Actions
- **"Generate Preview"**: Renders a read-only mock table of the first 10 rows on screen to verify filters before generating a large download.
- **"Export Report"**: Triggers the file download engine.

---

## Business Rules and Conditions

**Dynamic Row Limitation & Queueing**
- If the target export dataset exceeds **1,000 rows** (e.g., exporting school-wide scores for 1,500 students), the system bypasses direct synchronous downloading (which causes browser timeouts). Instead, it schedules an asynchronous background job and notifies the user via an in-app banner: `"Your report is generating in the background. You will receive a notification to download it shortly."`

**Role-Based Export Filters**
- Teachers are restricted to exporting details for sections they actively instruct or tutor. The Class and Section dropdowns automatically restrict selection to authorized cohorts.
- Administrators and Counsellors have unrestricted access to school-wide filters.

**Data Freshness**
- The export engine pulls from `ba_computed_scores` rather than recalculating individual raw ratings dynamically. A timestamp label at the bottom of the hub displays: `"Data last synced: Today at 2:00 PM."`

---

## Workflow Steps

**Exporting a Class Score Report**
1. User navigates to **Reports -> Reports Hub**.
2. Selects **Student Scores** from the left-hand menu.
3. In the filters panel, selects Academic Session: `2026-2027 Session`, Period: `Term 1`, Class: `Grade 8`, Section: `8-A`.
4. Selects Format: `Excel (.xlsx)`.
5. Clicks **Generate Preview**. The grid below renders John Doe, Amit Sharma, and roll numbers with their averages.
6. The user clicks **Export Report**.
7. The system queries the database, formats the excel spreadsheet using standard template grids, writes the file to disk, and triggers the browser download window. A success toast appears.

---

## Example Scenario

At the end of the first quarter, the High School Principal wants to download a summary of all recorded behavioral infractions to present to the school board. They open the Reports Hub, select **Incident Summary**, filter for High School classes, pick `Excel` format, and click `Export`. They receive a beautifully structured Excel sheet listing student names, infraction descriptions, witness counts, and final intervention outcomes.

---

## Related Screens

- [16-Student-Scores-Report.md](./16-Student-Scores-Report.md) — The student scores detail sheet.
- [17-Category-Summary.md](./17-Category-Summary.md) — The category summary report.
- [18-Period-Report.md](./18-Period-Report.md) — The periodic trend comparison.
- [19-Audit-Trail.md](./19-Audit-Trail.md) — The compliance and change logs.

# Exam Dashboard Screen

---

## What Does This Screen Do?

The Exam Dashboard is like a car's dashboard — it shows all the important numbers at a glance so teachers and administrators know the health of the exam system.

It shows:
- **How many exams** exist in the system
- **How many exam papers** have been created
- **How many students** have been assigned to exams
- **How many students** have submitted answers
- **How many submissions** have been evaluated (graded)
- **How many submissions** are still waiting to be checked

It also shows trends (charts showing activity over the last 6 months), breakdowns (by subject and class), and a list of the most recent exams.

**Important:** This is a read-only screen. You can only look at the numbers — you cannot create or change any data here.

---

## Real-Life Example

**Scenario:** Principal Sharma wants to know the exam status mid-term.

**What he does:**
1. Opens the Exam Dashboard
2. Sees 6 colorful cards at the top:
   - Total Exams: 12
   - Exam Papers: 48
   - Allocations: 1,200
   - Submitted: 950
   - Evaluated: 600
   - Pending Eval: 350
3. Sees a bar chart showing that most papers were created in June
4. Sees a doughnut chart showing 50% evaluated, 30% pending, 20% not started
5. Scrolls down to see: Science has the most papers (12), Class 10 has the most exams (4)
6. **Decision:** More teachers needed for evaluation. 350 papers still pending.

---

## How the Dashboard is Accessed (Two Ways)

The dashboard can be seen in two ways, and this is important to understand:

**Way 1 — Inside the Masters Tab Page:** When you click the "Exam" module, you enter a big page with many tabs. One of those tabs is called "Dashboard." You click it, and the dashboard appears. The system loads ALL tabs' data at once (even the ones you can't see), so switching between tabs is instant.

**Way 2 — Standalone Page:** There is also a direct URL for the dashboard. When you visit this URL, you see ONLY the dashboard, not the other tabs.

**Important:** When you enter the Exam module for the first time, you do NOT see the dashboard. The default tab that opens is "Exam Type." You need to click the "Dashboard" tab to see it.

---

## What Happens When the Dashboard Loads

### Step-by-Step (in simple language)

**Step 1 — Permission Check:** The system checks: "Does this user have `tenant.exam.viewAny` permission?" If not → 403 Forbidden.

**Step 2 — Read the Filters:** The system looks at the URL to see if any filters are already applied (class, subject, mode, date range).

**Step 3 — Load Class-Section List:** The system loads a list of all classes and sections. This list is stored in cache memory for 1 hour, so it doesn't need to be loaded from the database every time.

**Step 4 — Load Subjects (if class selected):** If you selected a specific class-section in the filter, the system loads the subjects available for that class.

**Step 5 — Calculate All the Numbers (10+ queries run here):** The system runs many queries to calculate every number, chart, and breakdown. Each piece of data has its own query.

**Step 6 — Pass Everything to the Screen:** All the calculated data is sent to your browser and displayed.

**Important Note:** The dashboard data is calculated EVERY TIME the main Masters page loads — even if you're looking at a different tab! This is because the system keeps all tab data ready for instant switching. If you're on the "Exam Type" tab, the dashboard queries still run in the background.

---

## Filter Bar — What You Can Filter By

At the top of the dashboard, there is a filter bar with:

| Filter | What It Does | How It Works |
|--------|-------------|--------------|
| **Class & Section** | Show only data for a specific class | Dropdown lists all class-section combinations |
| **Subject / Study Format** | Show only data for a specific subject | Dropdown appears AFTER you select a class |
| **Mode** | Online, Offline, or All | Dropdown with 3 options |
| **Date Range** | Show only data within a date period | Calendar with presets: Today, Last 7, Last 30, This Month, Last Month |

**Subject filter rule:** The subject dropdown only becomes available AFTER you select a class-section. If no class is selected, the subject dropdown shows "All Subjects" only.

**Date range behavior:** Unlike other screens that auto-submit, the dashboard's date range picker does NOT auto-submit. You must click "Filter" to apply it. Click "Reset" to clear all filters.

---

## The 6 KPI Cards — What Each One Counts

The six colorful cards at the top are called KPI cards (Key Performance Indicators). Each counts something different, and each uses different filter rules:

### Card 1: Total Exams
| Detail | Value |
|--------|-------|
| **What it counts** | Number of exam records |
| **Filters that affect it** | Class ✅, Date Range ✅ |
| **Filters that DON'T affect it** | Subject ❌, Mode ❌ |

**In Plain English:** The total exam count only changes when you select a class or a date range. Selecting a specific subject or mode does NOT change this number.

### Card 2: Exam Papers
| Detail | Value |
|--------|-------|
| **What it counts** | Number of exam paper records |
| **Filters that affect it** | Class ✅, Subject ✅, Mode ✅, Date Range ✅ |

**In Plain English:** This number changes with ALL four filters. If you select "Online" mode, it only counts online papers. If you select a subject, it only counts that subject's papers.

### Card 3: Allocations
| Detail | Value |
|--------|-------|
| **What it counts** | Number of student-exam allocations |
| **Filters that affect it** | Class ✅, Date Range ✅ |
| **Filters that DON'T affect it** | Subject ❌, Mode ❌ |
| **Date field used** | `scheduled_date` (not start_date) |

**In Plain English:** The allocations count only changes with Class and Date Range. But importantly, the date filter checks the allocation's `scheduled_date`, NOT the exam date. So if you filter by "Last 7 Days," it shows allocations scheduled in the last 7 days, not exams conducted in the last 7 days.

### Card 4: Submitted
| Detail | Value |
|--------|-------|
| **What it counts** | Number of student attempts with submitted status |
| **Filters that affect it** | Class ✅, Date Range ✅ |
| **Filters that DON'T affect it** | Subject ❌, Mode ❌ |
| **Statuses counted** | SUBMITTED, EVALUATION_PENDING, EVALUATED, RESULT_PUBLISHED |

**In Plain English:** A student's attempt counts as "Submitted" if it has any of these statuses. If a student started but hasn't submitted yet (IN_PROGRESS), they don't count.

### Card 5: Evaluated
| Detail | Value |
|--------|-------|
| **What it counts** | Number of exam result records |
| **Filters that affect it** | Class ✅, Date Range ✅ |
| **Filters that DON'T affect it** | Subject ❌, Mode ❌ |
| **Date field used** | `created_at` (when the result was entered) |

**In Plain English:** This counts how many results have been entered into the system. The date filter checks when the result was created, not when the exam happened.

### Card 6: Pending Evaluation
| Detail | Value |
|--------|-------|
| **What it counts** | Submitted minus Evaluated |
| **Formula** | `Submitted KPI - Evaluated KPI` |
| **Can be negative?** | **NO** — If submitted < evaluated, it shows 0 (not a negative number) |

**In Plain English:** This card shows how many submissions still need a teacher to check them. It's calculated automatically: if 950 students submitted and 600 have been evaluated, then 350 are pending. If somehow the numbers would go negative, it shows 0 instead.

---

## Charts

### Chart 1: Monthly Activity — Papers Created vs Allocations

This is a bar chart showing the last 6 months. Each month has two bars:
- **Blue bar:** How many exam papers were created that month
- **Teal bar:** How many allocations were made that month

**Important detail:** The chart counts papers by their `created_at` date (when they were added to the system), NOT by the exam's date or when the exam happens. Same for allocations — counted by their `created_at` date.

Each month shows as a label like "Jan 2026", "Feb 2026", etc. Months with no activity show a 0 bar (the bar is still shown, just empty).

### Chart 2: Submission Status — Doughnut Chart

This is a round chart (like a donut with a hole in the middle) showing the breakdown of all allocations:
- **Blue segment:** Submitted (answer submitted but not evaluated)
- **Green segment:** Evaluated (answers have been checked)
- **Red segment:** Pending (submitted minus evaluated)
- **Yellow segment:** Not Started (allocated but never attempted)

The number in the center of the donut shows the total allocations count.

---

## Breakdown Tables

### Table 1: Subject-wise Paper Distribution

A table showing which subjects have the most papers:
- Subject name
- Total papers count
- Online papers count
- Offline papers count
- Progress bar showing relative share (percentage)

**Only the top 6 subjects** are shown. If you have 15 subjects, only the 6 with the most papers appear.

### Table 2: Class-wise Exam Count

Progress bars showing how many exams each class has:
- Class name
- Exam count
- Colored gradient progress bar

**Only the top 6 classes** are shown.

### Table 3: Paper Mode Split

Shows the breakdown between Online and Offline papers:
- Online count and percentage
- Offline count and percentage
- A split progress bar (blue for Online, gray for Offline)
- Below: Submitted, Evaluated, Pending Eval, Not Started counts

### Table 4: Recent Exams

A table showing the **8 most recent** exams (newest first):
- Exam title (truncated if too long, with "..." and exam code below)
- Class name
- Exam type
- Number of papers
- Allocations count
- Submitted count (with percentage)
- Checked count (with percentage)
- Status badge (colored: PUBLISHED=green, CONCLUDED=gray, ARCHIVED=dark, others=yellow)
- Exam date

At the bottom, there's a "View All →" link that takes you to the Exam Creation tab.

---

## How Filters Affect Each Widget (Important!)

This table shows what happens to each widget when you apply a filter:

| Widget | Class Filter | Subject Filter | Mode Filter | Date Range |
|--------|-------------|---------------|-------------|------------|
| Total Exams | ✅ Affected | ❌ No effect | ❌ No effect | ✅ Affected |
| Exam Papers | ✅ Affected | ✅ Affected | ✅ Affected | ✅ Affected |
| Online Papers | ✅ Affected | ✅ Affected | N/A (always Online) | ❌ No effect |
| Offline Papers | ✅ Affected | ✅ Affected | N/A (always Offline) | ❌ No effect |
| Allocations | ✅ Affected | ❌ No effect | ❌ No effect | ✅ Affected (scheduled_date) |
| Submitted | ✅ Affected | ❌ No effect | ❌ No effect | ✅ Affected (submitted_at) |
| Evaluated | ✅ Affected | ❌ No effect | ❌ No effect | ✅ Affected (created_at) |
| Monthly Activity | ✅ Affected | ❌ No effect | ❌ No effect | ❌ No effect |
| Subject Breakdown | ✅ Affected | ✅ Affected | ✅ Affected | ❌ No effect |
| Class Breakdown | ❌ No effect | ❌ No effect | ❌ No effect | ✅ Affected |
| Recent Exams | ✅ Affected | ❌ No effect | ❌ No effect | ❌ No effect |

**In Plain English for testing:** Each widget has different filter behavior. Some filters affect some widgets but not others. The only way to know exactly what changes is to check this table. For example:
- If you select "Online" mode → Papers count changes, but Allocations count stays the same
- If you select a Subject → Papers count changes, but Total Exams count does NOT change
- If you pick a Date Range → Total Exams changes (by start_date) but Monthly Activity does NOT change

---

## How the Class → Subject Cascade Works

When you select a class in the filter:

1. The system checks: "Is a `class_section_id` selected?"
2. If YES: It finds the class's ID from the class-section record
3. Then it finds all Subject-Study-Format records linked to that class
4. The dropdown shows subject names like "Mathematics - Theory", "Physics - Practical"

**If NO class is selected:** The subject dropdown stays empty. You cannot select a subject without first selecting a class.

**Note:** The `getSubjectsByClass` AJAX endpoint that serves the filter dropdown is different from the Subject list used in the dashboard. The dashboard uses its own method `getDashboardSubjectList()`.

---

## Performance Note: Data Loading

The dashboard runs **more than 10 separate queries** every time it loads:
1. Count total exams
2. Count total papers
3. Count online papers
4. Count offline papers
5. Count total allocations
6. Count submitted attempts
7. Count evaluated results
8. Monthly activity (6 months of paper creation data)
9. Monthly allocations (6 months of allocation data)
10. Subject breakdown (top 6 subjects)
11. Class breakdown (top 6 classes)
12. Recent exams (last 8 exams with relationships)

Plus, the dashboard data is loaded even when you're on other tabs (because the Masters page loads all tabs at once).

**For testers:** If you see performance issues, the dashboard's many queries are a likely cause. Testing with 10,000+ records can reveal slow loading.

---

## What Data is Cached

| Data | Cache Duration | Why Cached |
|------|----------------|------------|
| Class-Section List | **1 hour** | Rarely changes, loaded on every page visit |

All other dashboard data is calculated fresh every time the page loads. No KPI values, chart data, or breakdowns are cached.

---

## Permission

| Permission | What It Allows | Without It |
|-----------|----------------|------------|
| `tenant.exam.viewAny` | View the dashboard | 403 Forbidden |

One single permission controls access to the whole Exam module, including the dashboard.

---

## Color Scheme of KPI Cards (Visual Testing)

Each of the 6 KPI cards has a different gradient background:

| Card | Gradient Colors |
|------|----------------|
| **Total Exams** | Purple → Blue |
| **Exam Papers** | Orange → Yellow |
| **Allocations** | Peach → Red |
| **Submitted** | Blue → Cyan |
| **Evaluated** | Green |
| **Pending Eval** | Red |

The icon in each card floats in the top-right corner with low opacity.

---

## Complete Walkthrough: Teacher Checks Her Class

**Scenario:** Teacher Priya is a Class 10 Science teacher. She wants to check how her class is doing.

**Step 1:** Opens the Exam module → Sees the Masters tab page → Clicks "Dashboard" tab

**Step 2:** In the filter bar, selects "Class 10 - Section A" from the Class & Section dropdown

**Step 3:** Subject dropdown appears → Selects "Science"

**Step 4:** Leaves Mode as "All Modes" (she wants both online and offline)

**Step 5:** Selects Date Range "This Month"

**Step 6:** Clicks "Filter"

**Step 7:** The dashboard updates:
- Total Exams: 3 (only exams for Class 10 this month)
- Exam Papers: 5 (Science papers only)
- Allocations: 120 (students assigned to those exams)
- Submitted: 100
- Evaluated: 75
- Pending Eval: 25

**Step 8:** Looks at the bar chart → Sees most papers were created in the first week

**Step 9:** Looks at the doughnut → 75/100 evaluated (75%) — good progress

**Step 10:** Scrolls to Recent Exams → Sees "Unit Test - Science" with 40 students, 38 submitted, 30 checked

**Step 11:** Notes that 8 Science students still need evaluation. Assigns extra teacher for grading.

---

## Error Scenarios

| What Happens | What User Sees | Why |
|-------------|----------------|-----|
| No permission | 403 Forbidden page | User lacks `tenant.exam.viewAny` |
| No data in system | All KPIs show 0, empty charts, "No data" messages | System is fresh, no exams created yet |
| Invalid class selected | All KPIs show 0 | Class ID doesn't exist, no matching data |
| Invalid subject | All KPIs show 0 | Subject ID doesn't exist or has no papers |
| Future date range | All KPIs show 0 | No exams exist in the future |
| Date From > Date To | All KPIs show 0 | Invalid date range, no matching data |
| Subject without class selected | Subject dropdown disabled | Must select class first |
| Only Online exams exist | Mode split shows 100% Online, 0% Offline | Expected — all papers are Online |
| Only Offline exams exist | Mode split shows 0% Online, 100% Offline | Expected — all papers are Offline |
| Guest user (not logged in) | Redirect to login page | Session expired or not authenticated |

---

## Business Rules Summary

| # | Rule | What It Means |
|---|------|---------------|
| 1 | **Read-only screen** | No data can be created, edited, or deleted here |
| 2 | **10+ queries per load** | Each widget has its own database query |
| 3 | **Data loads on every tab visit** | Dashboard queries run even when you're on a different tab (because the Masters page pre-loads everything) |
| 4 | **Different filters affect different widgets** | Not all widgets respond to all filters (see filter table above) |
| 5 | **Online/Offline paper counts ignore date range** | Unlike total papers, the Online/Offline split does NOT filter by date |
| 6 | **Pending Eval never shows negative** | Uses `max(0, submitted - evaluated)` formula |
| 7 | **Top 6 limit** | Subject breakdown and class breakdown only show top 6 |
| 8 | **Last 8 exams** | Recent exams table only shows 8 most recent |
| 9 | **Class-section list cached 1 hour** | Dropdown data is cached for performance |
| 10 | **Subject cascade needs class** | Subject dropdown only works after class is selected |
| 11 | **KPI card gradients** | 6 different predefined gradient colors |
| 12 | **No auto-submit for date** | Date picker does NOT auto-submit the form (unlike other screens) |

---

## Related Screens

| Screen | How It Connects |
|--------|----------------|
| **Exam Creation** | "View All →" link in Recent Exams leads here |
| **Exam Summary** | Shows similar statistics with more detail per paper |
| **Online Assessment** | Drill-down into online exam submissions |
| **Masters - Exam Type** | Dashboard shares the same Masters tab page |

---

## Tables Used

The dashboard reads from 5 tables:
- `lms_exams` — Exam records (title, dates, class, status)
- `lms_exam_papers` — Paper records (subject, mode, marks)
- `lms_exam_allocations` — Student-paper assignments
- `exam_attempts` — Student submissions and statuses
- `exam_results` — Evaluation results and scores

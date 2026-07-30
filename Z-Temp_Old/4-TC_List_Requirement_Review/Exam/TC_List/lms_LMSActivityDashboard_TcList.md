# lms_LMSActivityDashboard_TcList

## Module: LmsExam → Advanced Reports → LMS Activity Dashboard

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Advanced Reports |
| Feature | LMS Activity Dashboard |
| URL(s) | `/lms-exam/exam-advanced-reports?active_tab=lms-activity-dashboard` (index) |
| Controller | `Modules\LmsExam\Http\Controllers\ExamAdvancedReportController@index()` |
| Method (Data) | `generateLmsActivityData()` (private, line 692) |
| Model(s) | `Modules\LmsHomework\Models\Homework`, `Modules\LmsExam\Models\Exam`, `Modules\SchoolSetup\Models\ClassSection` |
| View (Partial) | `advanced-reports/partials/lms-activity-dashboard.blade.php` |
| Permissions | `tenant.lms-exam-report.viewAny` |
| Charts | ApexCharts: donut (volume distribution), area (engagement trend) |
| Date Range | daterangepicker with moment.js |

---

## 2. Pre-conditions

- Required permission: `tenant.lms-exam-report.viewAny`
- Required seed data: Multiple `Homework` records with `submissions`, and multiple `Exam` records with `examResults`
- Mix of homework and exam data spread across at least 30 days
- Varied completion rates and average scores for both modules
- For engagement trend: data should span all 7 days of the week
- At least one `ClassSection` record with `actual_total_student > 0` per class/section
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

When the page loads with `active_tab=lms-activity-dashboard`:

| Widget/Chart | Data Source | Query Logic | Filters |
|-------------|-------------|-------------|---------|
| Platform Filter | activity select (All/HW/Exam) | Not used in backend (all data returned) | activity |
| **Homework Card** | `generateLmsActivityData()` → `$cards[0]` | Aggregated HW count, avg score, participation rate | date_from, date_to |
| **Exam Card** | `generateLmsActivityData()` → `$cards[1]` | Aggregated Exam count, avg score, participation rate | date_from, date_to |
| **Volume Donut Chart** | `generateLmsActivityData()` → `$charts['volume']` | Total HW count vs Total Exam count | date_from, date_to |
| **Engagement Trend Area** | `generateLmsActivityData()` → `$charts['engagement']` | Activity count per day of week (Mon-Sun) | date_from, date_to |
| **Activity Audit Table** | `generateLmsActivityData()` → `$activities` | Combined HW + Exam rows with stats | date_from, date_to |

---

## 4. Test Data Strategy

- **Core dataset**: 10+ Homework records with submissions, 8+ Exam records with results
- **Date span**: Records spread across 60+ days for date range testing
- **Participation rates**: Vary from 30% to 100% across different activities
- **Average scores**: Vary from 20% to 95% across activities
- **Weekly distribution**: Activities on each day of the week for engagement chart
- **Edge cases**: One module with zero records, empty date range
- **Pre-test cleanup**: Delete created homework and exam records

---

## 5. Business Conditions

### 4.1 Database Schema

#### `lms_homeworks`

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK |
| BC-DB-02 | class_id | INT UNSIGNED | FK → sch_classes |
| BC-DB-03 | section_id | INT UNSIGNED | FK → sch_sections, NULLABLE |
| BC-DB-04 | subject_id | INT UNSIGNED | FK → sch_subjects |
| BC-DB-05 | title | VARCHAR(255) | NOT NULL |
| BC-DB-06 | assign_date | DATE | NOT NULL |

#### `lms_homework_submissions`

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-07 | id | INT UNSIGNED | PK |
| BC-DB-08 | homework_id | INT UNSIGNED | FK → lms_homeworks |
| BC-DB-09 | student_id | INT UNSIGNED | FK → std_students |
| BC-DB-10 | marks_obtained | DECIMAL(8,2) | NULLABLE |

#### `lms_exams`

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-11 | id | INT UNSIGNED | PK |
| BC-DB-12 | title | VARCHAR(150) | NOT NULL |
| BC-DB-13 | start_date | DATE | NOT NULL |

#### `lms_exam_results`

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-14 | id | INT UNSIGNED | PK |
| BC-DB-15 | exam_id | INT UNSIGNED | FK → lms_exams |
| BC-DB-16 | student_id | INT UNSIGNED | FK → std_students |
| BC-DB-17 | result_status | VARCHAR(20) | NULLABLE |
| BC-DB-18 | percentage | DECIMAL(5,2) | NULLABLE |

#### `sch_class_sections`

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-19 | id | INT UNSIGNED | PK |
| BC-DB-20 | class_id | INT UNSIGNED | FK → sch_classes |
| BC-DB-21 | section_id | INT UNSIGNED | NULLABLE |
| BC-DB-22 | actual_total_student | INT | DEFAULT 0 |

### 4.2 Filter/Input Validation

| BC ID | Filter | Type | Default |
|-------|--------|------|---------|
| BC-VAL-01 | activity | STRING | 'All' (values: All, HW, Exam) |
| BC-VAL-02 | date_from | DATE, nullable | now()->subDays(30) |
| BC-VAL-03 | date_to | DATE, nullable | now() |

### 4.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | tenant.lms-exam-report.viewAny | Without → 403 |
| BC-AUTH-02 | Guest access | Redirect to /login |

### 4.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | HW Activity Count | Number of homeworks matching date range |
| BC-BIZ-02 | HW Avg Score | Average marks_obtained across all HW submissions |
| BC-BIZ-03 | HW Participation Rate | Average (submissions/assigned) × 100 across all HWs |
| BC-BIZ-04 | HW Assigned Count | Sum of actual_total_student from ClassSection where class_id matches |
| BC-BIZ-05 | HW Completion Count | Count of submissions per homework |
| BC-BIZ-06 | HW Completion % | (submissions / assigned) × 100 |
| BC-BIZ-07 | Exam Activity Count | Number of exams matching date range |
| BC-BIZ-08 | Exam Avg Score | Average percentage across all exam results |
| BC-BIZ-09 | Exam Participation Rate | Average (attended/total) × 100 across exams |
| BC-BIZ-10 | Exam Attended Count | Results where result_status != 'ABSENT' |
| BC-BIZ-11 | Exam Total Count | All results count (or 1 if zero to avoid division by zero) |
| BC-BIZ-12 | Volume Donut | HW count vs Exam count as two segments |
| BC-BIZ-13 | Engagement Trend | Static day-of-week data (Mon-Sun); currently not date-filtered dynamically |
| BC-BIZ-14 | Activity Table Row | Each HW or Exam as a row with title, type, assigned, completed, completion %, avg score |
| BC-BIZ-15 | Participation % Bar | Green ≥80%, blue ≥50%, red <50% |
| BC-BIZ-16 | Avg Score Color | Green ≥75%, blue ≥50%, red <50% |
| BC-BIZ-17 | Card Color Theme | HW card = purple (#6366f1), Exam card = amber (#f59e0b) |
| BC-BIZ-18 | Empty State | "No activity logs found for the selected timeline." |
| BC-BIZ-19 | Platform Pulse Summary | Modules Act count, Participation Avg, Global Performance |

### 4.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete |
|-------|-----------|------------------|----------|
| BC-REF-01 | homework.class_id | sch_classes.id | CASCADE |
| BC-REF-02 | exam_result.exam_id | lms_exams.id | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Activity Dashboard loads with all UI elements | Filter bar, 2 module cards, 2 charts, activity audit table | — | — | ⬜ |
| TC-P02 | Homework card shows correct aggregated data | Total HW count, participation rate, avg score from seed | — | — | ⬜ |
| TC-P03 | Exam card shows correct aggregated data | Total exam count, participation rate, avg score from seed | — | — | ⬜ |
| TC-P04 | Volume donut chart shows HW vs Exam proportion | Two segments: HW (purple) and Exam (green) | — | — | ⬜ |
| TC-P05 | Engagement trend area chart shows 7 days | Days Mon-Sun with activity counts | — | — | ⬜ |
| TC-P06 | Activity table shows combined HW + Exam rows | Both types in single table with type badge | — | — | ⬜ |
| TC-P07 | Per-activity completion rate and avg score correct | Each row matches seed data | — | — | ⬜ |
| TC-P08 | Type badge shows HOMEWORK or EXAM correctly | Badge with icon + text | — | — | ⬜ |
| TC-P09 | Participation progress bar color coded | Green ≥80%, blue ≥50%, red <50% | — | — | ⬜ |
| TC-P10 | Avg score text color coded | Green ≥75%, blue ≥50%, red <50% | — | — | ⬜ |
| TC-P11 | Filter by date range scopes activities | Activities within range only | — | — | ⬜ |
| TC-P12 | Platform filter (All/HW/Exam) | Note: Filter in UI but not applied in backend — all data returned | — | — | ⬜ |
| TC-P13 | Reset button clears filters | URL resets | — | — | ⬜ |
| TC-P14 | Date range presets work | Today, Last 30 Days, This Month | — | — | ⬜ |
| TC-P15 | HW card purple themed | Border-left: 4px solid #6366f1 | — | — | ⬜ |
| TC-P16 | Exam card amber themed | Border-left: 4px solid #f59e0b | — | — | ⬜ |
| TC-P17 | Platform Pulse Summary at bottom | Modules Act, Participation Avg, Global Performance | — | — | ⬜ |
| TC-P18 | Activity meta (class/subject info) shown | Each row shows class • subject in subtitle | — | — | ⬜ |
| TC-P19 | Empty state when no activities | "No activity logs found for the selected timeline." | — | — | ⬜ |
| TC-P20 | Both module types mixed in single table | HW rows and Exam rows interleaved | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Permission 403 | 403 Forbidden | — | — | ⬜ |
| TC-N02 | Guest redirect | Redirect to /login | — | — | ⬜ |
| TC-N03 | No date range selected | Default last 30 days applied | — | — | ⬜ |
| TC-N04 | No homework records | HW card shows 0; only exam data visible | — | — | ⬜ |
| TC-N05 | No exam records | Exam card shows 0; only HW data visible | — | — | ⬜ |
| TC-N06 | Both modules empty | Empty state; cards show 0; pulse summary 0 | — | — | ⬜ |
| TC-N07 | Invalid date format | Defaults to last 30 days; no 500 | — | — | ⬜ |
| TC-N08 | Zero actual_total_student in ClassSection | HW assigned = 0; participation = 0% | — | — | ⬜ |
| TC-N09 | All exam results ABSENT | Exam completion = 0% | — | — | ⬜ |
| TC-N10 | All HW submissions have null marks_obtained | Avg score = 0 for HW | — | — | ⬜ |
| TC-N11 | Date range with no matching records | Empty table; 0 cards; empty state | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Creating new homework updates HW card | HW count increments; avg recalculated | — | — | ⬜ |
| TC-D02 | B | Creating new exam updates Exam card | Exam count increments; avg recalculated | — | — | ⬜ |
| TC-D03 | C | Submitting homework updates completion rate | HW submission increases % | — | — | ⬜ |
| TC-D04 | D | Cross-module: Homework from LmsHomework reflected | All HW records from LmsHomework module shown | — | — | ⬜ |
| TC-D05 | E | Cross-module: Exam from LmsExam reflected | All Exam records from LmsExam module shown | — | — | ⬜ |
| TC-D06 | F | Large dataset (50+ activities) rendering | All rows display; charts render | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives | Tab wrapped by @can('tenant.lms-exam-report.viewAny') | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — generateLmsActivityData() at line 692 | Returns cards, activities, charts | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | View — null-safe checks | $hw->class?->name, $hw->subject?->name | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — HW assigned count logic | ClassSection::where(class_id)->sum('actual_total_student') | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — Exam attended count | $eResults->where('result_status', '!=', 'ABSENT')->count() | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — Division by zero guard | $total = $eResults->count() ?: 1 | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | JS — Donut chart config | type:'donut', two colors, center total | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | JS — Area engagement chart | type:'area', smooth curve, Mon-Sun labels | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | Controller — HW aggregation | collect($activityRows)->where('type', 'HOMEWORK') for card stats | — | — | ◌ |
| TC-CR10 | CR | Code Review | P1 | Controller — Exam aggregation | collect($activityRows)->where('type', 'EXAM') for card stats | — | — | ◌ |
| TC-CR11 | CR | Documentation | P1 | Chart Data — Hardcoded Engagement Values | Weekly engagement chart uses hardcoded data [15, 32, 28, 45, 38, 12, 8] — NOT computed from actual submissions (placeholder data) | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Blade @can Directives

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php | Tab wrapped by @can('tenant.lms-exam-report.viewAny') |
| 2 | Check nav-tab permission | 'tenant.lms-exam-report.viewAny' |
| 3 | User with permission | Tab visible |
| 4 | User without permission | Tab hidden; 403 |

---

#### TC-CR02: Controller — generateLmsActivityData()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller at line 692 | Method found |
| 2 | Verify HW query | Homework::with(['class', 'section', 'subject', 'submissions']) |
| 3 | Verify Exam query | Exam::with(['examResults']) |
| 4 | Verify date filter | whereBetween for assign_date and start_date |
| 5 | Verify return structure | cards (2), activities (combined), charts (volume + engagement) |

---

#### TC-CR03: View — null-safe Checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open view file | All ?-> operators used |
| 2 | Check $hw->class?->name | Null-safe used |
| 3 | Load with null relations | 'N/A' or dash displayed |

---

#### TC-CR04: HW Assigned Count Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 714-716 | ClassSection::where('class_id', $hw->class_id)->when(section, ...)->sum('actual_total_student') ?: 1 |
| 2 | Verify section filter | Applies when hw->section_id is set |
| 3 | Verify fallback to 1 | Prevents division by zero |

---

#### TC-CR05: Exam Attended Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 732 | $attended = $eResults->where('result_status', '!=', 'ABSENT')->count() |
| 2 | Test with ABSENT results | Excluded from attended count |

---

#### TC-CR06: Division by Zero Guard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 733 | $total = $eResults->count() ?: 1 |
| 2 | Test zero results | $total = 1 (avoids division by zero) |
| 3 | Test with results | $total = actual count |

---

#### TC-CR07: Donut Chart Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect JS at line 199 | type:'donut', series from volume data |
| 2 | Verify colors | #6366f1 (purple) for HW, #10b981 (green) for Exam |
| 3 | Verify center total | Donut center shows total label and count |
| 4 | Verify chart ID | #activityDonutChart |

---

#### TC-CR08: Area Engagement Chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect JS at line 212 | type:'area', smooth curve, gradient fill |
| 2 | Verify x-axis categories | Mon, Tue, Wed, Thu, Fri, Sat, Sun |
| 3 | Verify color | #6366f1 (indigo) |
| 4 | Verify chart ID | #engagementAreaWaveChart |

---

#### TC-CR09: HW Aggregation for Card

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 745-746 | $hwAggr = collect($activityRows)->where('type', 'HOMEWORK') |
| 2 | Verify avg_score | $hwAggr->avg('avg_score') |
| 3 | Verify participation_rate | $hwAggr->avg('completion_pct') |

---

#### TC-CR10: Exam Aggregation for Card

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 746-747 | $exAggr = collect($activityRows)->where('type', 'EXAM') |
| 2 | Verify avg_score | $exAggr->avg('avg_score') |
| 3 | Verify participation_rate | $exAggr->avg('completion_pct') |

---

### 6.1 Positive TC Steps

#### TC-P01: Activity Dashboard Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard |
| 2 | Navigate to LMS Activity Dashboard tab | Tab pane shown |
| 3 | Check filter bar | Platform Filter, Audit Timeline, Dashboard Pulse button |
| 4 | Check module cards | 2 cards: HOMEWORK VOLUME, EXAM VOLUME |
| 5 | Check charts | Donut chart + area chart |
| 6 | Check activity table | Combined rows with 7 columns |

---

#### TC-P02: Homework Card Shows Correct Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 5 HWs, avg completion 72%, avg score 68% | Expected card data |
| 2 | Navigate to dashboard | HW card: count=5, Part. Rate=72%, Avg Score=68% |

---

#### TC-P03: Exam Card Shows Correct Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 3 exams, avg completion 85%, avg score 75% | Expected card data |
| 2 | Navigate to dashboard | Exam card: count=3, Part. Rate=85%, Avg Score=75% |

---

#### TC-P04: Volume Donut Chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 5 HW, 3 Exam | Ratio 5:3 |
| 2 | Navigate to dashboard | Donut shows two segments: purple (HW) and green (Exam) |
| 3 | Hover over HW segment | Tooltip shows "Homework: 5" |

---

#### TC-P05: Engagement Trend Chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to dashboard | Area chart with Mon-Sun on x-axis |
| 2 | Verify 7 data points | One per day of week |
| 3 | Verify gradient fill | Smooth color gradient |

---

#### TC-P06: Activity Table Shows Combined Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to dashboard | Both HW and Exam rows visible |
| 2 | Check type badges | HOMEWORK badge with book icon, EXAM badge with graduation cap icon |

---

#### TC-P07: Per-Activity Stats Correct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: HW-X with 30 assigned, 25 submitted, avg score 72% | Row shows Assigned=30, Attempted=25, Completion=83.3%, Avg=72% |

---

#### TC-P08: Type Badge Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to dashboard | HW rows: badge shows book icon + "HOMEWORK" |
| 2 | Exam rows: badge shows graduation cap + "EXAM" |

---

#### TC-P09: Participation Progress Bar Color

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Completion 85% | Green bar (≥80%) |
| 2 | Completion 65% | Blue bar (≥50%) |
| 3 | Completion 30% | Red bar (<50%) |

---

#### TC-P10: Avg Score Color

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Avg score 80% | Green text (≥75%) |
| 2 | Avg score 60% | Blue text (≥50%) |
| 3 | Avg score 30% | Red text (<50%) |

---

#### TC-P11: Date Range Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date range | Only activities within range shown |
| 2 | Activities outside range excluded | Correct scoping |

---

#### TC-P12: Platform Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note: Filter in UI but controller returns all data | All activities always shown |
| 2 | Selecting HW or Exam does not filter | Backend returns all regardless |

---

#### TC-P13: Reset Button

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filters | URL has params |
| 2 | Click reset | URL resets to ?active_tab=lms-activity-dashboard |

---

#### TC-P14: Date Range Presets

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open date picker | Presets: Today, Last 30 Days, This Month |

---

#### TC-P15: HW Card Purple Theme

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check HW card | border-left: 4px solid #6366f1 |
| 2 | Icon color | #6366f1 |

---

#### TC-P16: Exam Card Amber Theme

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check Exam card | border-left: 4px solid #f59e0b |
| 2 | Icon color | #f59e0b |

---

#### TC-P17: Platform Pulse Summary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate with data | Summary row visible |
| 2 | 3 fields | Modules Act count, Participation Avg, Global Performance |

---

#### TC-P18: Activity Meta Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to dashboard | Each row shows title + metadata subtitle |
| 2 | HW meta: "Class • Subject" format | Correct class and subject names |

---

#### TC-P19: Empty State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Date range with no data | "No activity logs found for the selected timeline." |

---

#### TC-P20: Mixed HW/Exam Table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed both types | HW and Exam rows interleaved in single table |
| 2 | Type badges differentiate | Clear visual distinction |

---

### 6.2 Negative TC Steps

#### TC-N01: Permission 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without permission | 403 Forbidden |

---

#### TC-N02: Guest Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout | Redirect to /login |

---

#### TC-N03: No Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No date_from/date_to | Default last 30 days applied |

---

#### TC-N04: No Homework Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No HW data in date range | HW card shows count=0, participation=0%, avg=0% |

---

#### TC-N05: No Exam Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No Exam data in date range | Exam card shows 0 values |

---

#### TC-N06: Both Modules Empty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No HW or Exam data | Empty state; all cards 0 |

---

#### TC-N07: Invalid Date Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invalid date | Defaults to last 30 days |

---

#### TC-N08: Zero actual_total_student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | ClassSection with actual_total_student=0 | Assigned=0; completion calc avoids division by zero |

---

#### TC-N09: All Exam Results ABSENT

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All ABSENT | Attended=0; completion=0% |

---

#### TC-N10: HW Submissions Null Marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All marks_obtained=NULL | Avg score = 0 |

---

#### TC-N11: No Matching Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Date range with no records | Empty table; 0 cards |

---

### 6.3 Dependency TC Steps

#### TC-D01: Creating New HW Updates Card

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note HW count = X | Before |
| 2 | Create new homework | HW added |
| 3 | Refresh dashboard | HW count = X+1 |

---

#### TC-D02: Creating New Exam Updates Card

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note Exam count = X | Before |
| 2 | Create new exam | Exam added |
| 3 | Refresh dashboard | Exam count = X+1 |

---

#### TC-D03: Submitting HW Updates Completion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note HW completion % | Before |
| 2 | Student submits homework | Submission created |
| 3 | Refresh dashboard | Completion % may increase |

---

#### TC-D04: Cross-Module HW Reflection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create HW via LmsHomework module | HW created |
| 2 | Refresh dashboard | HW appears in activity table |

---

#### TC-D05: Cross-Module Exam Reflection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam via LmsExam module | Exam created |
| 2 | Refresh dashboard | Exam appears in activity table |

---

#### TC-D06: Large Dataset Performance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 50+ activities | 50+ rows |
| 2 | Dashboard renders | All rows scrollable; charts render |

---

### 6.4 Code Review TC Steps

#### TC-CR04: HW Assigned Count Fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 716 | `?: 1` fallback when sum is 0 |
| 2 | Test with normal data | Sum of actual_total_student |
| 3 | Test with 0 students | Fallback to 1 prevents division by zero |

---

#### TC-CR05: Exam Attended vs Total

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 732 | $attended = filter where NOT ABSENT |
| 2 | Inspect line 733 | $total = count or 1 (fallback) |

---

#### TC-CR06: Division by Zero Prevention

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect line 733 | $total = $eResults->count() ?: 1 |
| 2 | Verify HW assigned fallback | Line 716: `?: 1` |

---

#### TC-CR07: Donut Chart Configuration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect JS at line 199 | Chart config with series, labels, colors |
| 2 | Verify center total label | total.show = true, label = 'TOTAL' |

---

#### TC-CR08: Engagement Area Chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect JS at line 212 | type:'area', smooth curve, 7 categories |
| 2 | Verify static data | Currently uses hardcoded values [15,32,28,45,38,12,8] |

---

#### TC-CR09: HW Collection Filtering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 745-746 | collect($activityRows)->where('type', 'HOMEWORK') |
| 2 | Verify avg_score | ->avg('avg_score') aggregates |
| 3 | Verify participation | ->avg('completion_pct') aggregates |

---

#### TC-CR10: Exam Collection Filtering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 746-747 | collect($activityRows)->where('type', 'EXAM') |
| 2 | Verify avg_score | ->avg('avg_score') |
| 3 | Verify counts | ->count() for total_count |

---

#### TC-CR11: Controller — Static Engagement Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect lines 766-769 | Engagement chart uses hardcoded series: [15, 32, 28, 45, 38, 12, 8] |
| 2 | Verify labels | Mon through Sun |
| 3 | Note: Data is not dynamic | Currently placeholder values, not derived from actual activity |

---

#### TC-CR12: Controller — Rounding Behavior

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect round() calls | round((float)$hwAggr->avg('avg_score'), 1) |
| 2 | Verify precision | All averages rounded to 1 decimal |

---

### 6.5 Extended Test Cases (TC-AD)

#### TC-AD-01: Date Range Today + All Platform Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open date picker, select "Today" preset | date_from = today, date_to = today |
| 2 | Verify platform filter shows "All" | All tab selected by default |
| 3 | Verify activity table | Only today's HW and Exam records shown |
| 4 | Verify card counts | HW and Exam counts reflect only today's data |

---

#### TC-AD-02: Date Range Today + HW Platform Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Today" date preset | Date range set to today |
| 2 | Click "HW" platform filter tab | HW tab visually selected |
| 3 | Verify activity table | All rows still shown (filter is UI-only) |
| 4 | Verify card summaries | Both HW and Exam cards still visible |

---

#### TC-AD-03: Date Range Last 30 Days + All Platform

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Last 30 Days" preset | Date range reflects last 30 days |
| 2 | Verify All tab active | Data unfiltered by type |
| 3 | Verify activities within window | Only records from last 30 days returned |
| 4 | Verify records outside window excluded | Older records not in table or counts |

---

#### TC-AD-04: Date Range Last 30 Days + HW Platform

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Last 30 Days" preset | Date range set |
| 2 | Click "HW" platform filter | Backend still returns all data |
| 3 | Verify table includes HW + Exam rows | Platform filter has no effect on backend |
| 4 | Verify cards unchanged | Both cards show data from whole date range |

---

#### TC-AD-05: Date Range This Month + All Platform

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "This Month" preset | date_from = 1st of month, date_to = today |
| 2 | Verify All tab | All activities within month shown |
| 3 | Verify counts match seed data | Aggregations correct for month window |

---

#### TC-AD-06: Date Range This Month + Exam Platform

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "This Month" preset | Month date range applied |
| 2 | Select Exam filter tab | UI shows Exam selected |
| 3 | Verify backend returns all | HW rows still present in table |
| 4 | Verify card summaries | HW card data still rendered |

---

#### TC-AD-07: Custom 7-Day Range + All Platform

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open date picker | Calendar appears |
| 2 | Select start date 7 days ago | date_from set |
| 3 | Select end date today | date_to set |
| 4 | Verify 7-day window applied | Only records within 7-day window shown |

---

#### TC-AD-08: Custom 90-Day Range + HW Platform

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set custom range spanning 90 days | Wide range applied |
| 2 | Click HW filter | UI-only; full dataset returned |
| 3 | Verify table shows all activities | Platform filter not sent to backend |

---

#### TC-AD-09: Last Week Preset + All Platform

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Last Week" preset | date_from = Monday of last week, date_to = Sunday of last week |
| 2 | Verify data matches week window | Only prior week activities visible |

---

#### TC-AD-10: This Year Preset + All Platform

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "This Year" preset | date_from = Jan 1 this year, date_to = today |
| 2 | Verify all year activities shown | Full year data returned |

---

#### TC-AD-11: Donut Chart Click on HW Segment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open dashboard with HW and Exam data | Donut chart rendered with two segments |
| 2 | Click on HW (purple) segment | ApexCharts click event fires (console log if configured) |
| 3 | Click on Exam (green) segment | Exam segment click event fires |
| 4 | Verify no JS errors | Console shows no uncaught errors |

---

#### TC-AD-12: Donut Chart Hover Tooltip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Hover over HW segment | Tooltip displays "Homework: <count>" |
| 2 | Hover over Exam segment | Tooltip displays "Exam: <count>" |
| 3 | Verify tooltip styling | Tooltip has proper background, border, and text color |

---

#### TC-AD-13: Area Chart Zoom and Pan

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify ApexCharts zoom enabled | Selection zoom available on area chart |
| 2 | Click and drag to zoom into region | Chart zooms into selected x-range |
| 3 | Click zoom-out/reset button | Chart resets to original view |
| 4 | Verify pan functionality | Able to pan across zoomed chart area |

---

#### TC-AD-14: Chart Legend Toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click donut chart legend item (HW) | HW segment hidden; chart recalculates |
| 2 | Click legend item again | HW segment reappears |
| 3 | Toggle Exam legend item | Exam segment hides and shows correctly |
| 4 | Verify area chart legend | Single legend toggle available if configured |

---

#### TC-AD-15: Chart Responsive Resize

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Resize browser to 1024px width | Charts re-render to fit smaller container |
| 2 | Resize browser to 768px width | Charts scale proportionally |
| 3 | Resize browser to 375px width | Charts remain readable without overflow |
| 4 | Verify no layout breakage | All chart containers maintain aspect ratio |

---

#### TC-AD-16: Platform Filter Tab — All Default

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to dashboard | "All" platform filter tab is active/selected |
| 2 | Verify visual indicator | Active tab has highlighted background or underline |
| 3 | Note: Backend returns all data regardless | Platform filter is purely a UI concern |

---

#### TC-AD-17: Platform Filter Tab — HW Selection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "HW" tab | Tab becomes visually active |
| 2 | Verify backend query unchanged | Network tab shows same API response as "All" |
| 3 | Confirm all rows still in table | Both HW and Exam activity rows remain visible |

---

#### TC-AD-18: Platform Filter Tab — Exam Selection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Exam" tab | Tab becomes visually active |
| 2 | Verify same backend response | No filter parameter sent; full dataset returned |
| 3 | Confirm Exam data still shown | Both HW and Exam rows displayed |

---

#### TC-AD-19: Cross-Module HW Data Consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note HW count in LmsHomework module | Record baseline count |
| 2 | Navigate to LMS Activity Dashboard | HW count matches count from LmsHomework |
| 3 | Verify individual HW titles match | Each activity title exists in LmsHomework records |
| 4 | Verify HW card stats | Avg score and participation rate match source data |

---

#### TC-AD-20: Cross-Module Exam Data Consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note exam count in LmsExam module | Record baseline count |
| 2 | Navigate to LMS Activity Dashboard | Exam count matches LmsExam records |
| 3 | Verify individual exam titles | Each exam title matches LmsExam records |
| 4 | Verify Exam card stats | Avg score and participation consistent with source |

---

#### TC-AD-21: Source Data Change Reflects in Dashboard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create HW in LmsHomework module | HW added to source |
| 2 | Open dashboard in new tab | New HW appears in activity table and count |
| 3 | Delete an exam in LmsExam module | Exam removed from source |
| 4 | Refresh dashboard | Deleted exam no longer in table; count decremented |

---

#### TC-AD-22: Pulse Summary — Modules Act Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 5 HW and 3 Exam records | Total activities = 8 |
| 2 | Navigate to dashboard | Modules Act count = 8 |
| 3 | Change date range to exclude 2 HW | Modules Act count = 6 |
| 4 | Verify formula | Modules Act = total combined HW + Exam records in range |

---

#### TC-AD-23: Pulse Summary — Participation Avg

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Average HW completion = 72%, Exam = 85% | Expected combined avg |
| 2 | Verify Participation Avg value | Matches formula: (HW_participation + Exam_participation) / 2 |
| 3 | Test with only HW data | Participation Avg = HW participation rate alone |
| 4 | Test with only Exam data | Participation Avg = Exam participation rate alone |

---

#### TC-AD-24: Pulse Summary — Global Performance Composite

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify Global Performance value present | Composite score displayed |
| 2 | Check formula: avg of (HW avg score + Exam avg score) | Value matches expected calculation |
| 3 | Test with HW avg=80, Exam avg=70 | Global Performance = 75 |
| 4 | Test with one module empty | Global Performance = remaining module's avg score |

---

#### TC-AD-25: Activity Table Sort by Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify if column headers are clickable | Sort indicators present (if implemented) |
| 2 | Click "Completion %" header | Rows sorted by completion rate ascending |
| 3 | Click again | Sorted descending |
| 4 | Click "Avg Score" header | Rows re-sorted by average score |

---

#### TC-AD-26: Activity Table Scroll with Many Rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 30+ activities | 30+ table rows |
| 2 | Verify table container has scroll | Vertical scrollbar visible |
| 3 | Scroll to bottom of table | All 30+ rows reachable via scrolling |
| 4 | Verify header stays fixed | Table header remains visible during scroll (if sticky) |

---

#### TC-AD-27: Activity Table Empty State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date range with no activities | Table body shows empty state message |
| 2 | Verify message text | "No activity logs found for the selected timeline." |
| 3 | Verify no broken layout | Table renders correctly with empty state row |
| 4 | Reset date range to valid range | Empty state replaced with activity rows |

---

#### TC-AD-28: HW Card Zero Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no HW records in date range | HW count displays 0 |
| 2 | Verify card still renders | Card visible with purple border-left |
| 3 | Verify participation = 0% | 0% displayed without division error |
| 4 | Verify avg score = 0 | 0.0 displayed without NaN |

---

#### TC-AD-29: Exam Card Zero Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no Exam records in date range | Exam count displays 0 |
| 2 | Verify card still renders | Card visible with amber border-left |
| 3 | Verify participation = 0% | 0% displayed without division error |

---

#### TC-AD-30: Both Cards Zero Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Date range with no HW or Exam records | Both cards show 0 |
| 2 | Verify cards rendered correctly | Both card widgets visible |
| 3 | Verify cards show 0 without formatting errors | No NaN, Infinity, or broken display |

---

#### TC-AD-31: Very Large Count Formatting

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 9999 HW activities | HW count displays 9999 |
| 2 | Seed 10000 HW activities | Count may format as 10K (if locale formatting applied) |
| 3 | Seed 1500+ exam results in participation | Large numbers display without overflow |
| 4 | Verify card layout not broken | Text fits within card boundaries |

---

#### TC-AD-32: Avg Score 0 and Participation 0%

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create HW with all null marks_obtained | Avg score = 0.0 |
| 2 | Create HW with zero submissions | Participation = 0% |
| 3 | Verify both show 0 correctly | 0.0 and 0% displayed, not NaN or "-" |

---

#### TC-AD-33: Completion Exactly 80% — Green Threshold

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HW with completion = 80.0% | Progress bar shows green (≥80%) |
| 2 | Verify green color applied | #10b981 or equivalent green class |
| 3 | Verify boundary at exactly threshold | 80% is the lowest value that appears green |

---

#### TC-AD-34: Completion Exactly 50% — Blue Threshold

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HW with completion = 50.0% | Progress bar shows blue (≥50%) |
| 2 | Verify blue color applied | Blue class active |
| 3 | Verify 50% boundary | 50% is the lowest value that appears blue |

---

#### TC-AD-35: Completion Exactly 49% — Red Threshold

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HW with completion = 49.0% | Progress bar shows red (<50%) |
| 2 | Verify red color applied | Red/danger class active |
| 3 | Verify 49% is red | Boundary between blue and red at 50% |

---

#### TC-AD-36: Avg Score Exactly 75% — Green Threshold

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed activity with avg_score = 75.0% | Score text shows green (≥75%) |
| 2 | Verify green class applied | Green text color |
| 3 | Verify 75% is green | Lowest avg score that appears green |

---

#### TC-AD-37: Avg Score Exactly 74% — Blue Threshold

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed activity with avg_score = 74.0% | Score text shows blue (≥50%) |
| 2 | Verify blue class applied | Blue text color |
| 3 | Verify 74% is blue | One point below 75% green threshold |

---

#### TC-AD-38: Avg Score Exactly 49% — Red Threshold

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed activity with avg_score = 49.0% | Score text shows red (<50%) |
| 2 | Verify red class applied | Red/danger text color |
| 3 | Verify 49% is red | Boundary between blue and red at 50% |

---

#### TC-AD-39: Engagement Trend Static Data Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect chart data series | Values: [15, 32, 28, 45, 38, 12, 8] |
| 2 | Verify Monday value = 15 | Mon data point is 15 |
| 3 | Verify Wednesday value = 28 | Wed data point is 28 |
| 4 | Verify Sunday value = 8 | Sun data point is 8 |

---

#### TC-AD-40: Engagement Trend Day-of-Week Pattern

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify labels on x-axis | Mon, Tue, Wed, Thu, Fri, Sat, Sun |
| 2 | Verify 7 data points exactly | One value per day, no extra/missing points |
| 3 | Verify order correct | Sorted Mon (index 0) through Sun (index 6) |

---

#### TC-AD-41: Engagement Trend All Zero Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | (Scenario with no activity data) | Chart renders with all zero series if data empty |
| 2 | Verify chart renders without error | No JS error from ApexCharts with zero data |
| 3 | Verify flat line at 0 displayed | Area chart shows line along x-axis at y=0 |

---

#### TC-AD-42: Open Date Range (No Filter Applied)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to dashboard without date params | Default last 30 days applied |
| 2 | Verify date picker shows default range | From = now()-30d, To = now() |
| 3 | Verify all records from last 30 days shown | Activities within default window visible |

---

#### TC-AD-43: Very Wide Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date_from = 5 years ago | Range spanning years |
| 2 | Set date_to = today | All records in 5-year window included |
| 3 | Verify page loads correctly | No timeout or memory issues |
| 4 | Verify all records within range returned | Table shows all qualifying records |

---

#### TC-AD-44: Single Day Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date_from = today | Single day filter |
| 2 | Set date_to = today | Same day |
| 3 | Verify only today's records shown | Activities with assign_date/start_date = today |
| 4 | Verify no cross-day records leak | Yesterday or tomorrow records excluded |

---

#### TC-AD-45: Future Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date_from = next month | Future start date |
| 2 | Set date_to = next month + 7 days | Future window |
| 3 | Verify empty state displayed | No activities exist in future; empty state shown |
| 4 | Verify no error or crash | Cards show 0; no exception |

---

#### TC-AD-46: Invalid Date Format Input

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pass date_from = "invalid-date" | Defaults to last 30 days fallback |
| 2 | Pass date_to = "not-a-date" | No 500 error |
| 3 | Verify page renders normally | Dashboard displays with default range |
| 4 | Verify no exception logged | Graceful fallback to default behavior |

---

#### TC-AD-47: Division by Zero — Zero actual_total_student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set ClassSection.actual_total_student = 0 | Assigned count falls back to 1 |
| 2 | Verify HW assigned count | Uses `?: 1` guard, shows 1 or adjusted value |
| 3 | Verify completion calculation | Division by zero avoided; valid percentage shown |
| 4 | Verify no Infinity/NAN displayed | All values render as valid numbers |

---

#### TC-AD-48: Division by Zero — Zero Exam Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam with zero exam_results | $eResults->count() = 0 |
| 2 | Verify $total = 1 via `?: 1` guard | Division by zero prevented |
| 3 | Verify participation rate = 0% | 0% calculated safely |

---

#### TC-AD-49: Division by Zero — Zero HW Submissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create HW with zero submissions | submissions count = 0 |
| 2 | Verify assigned falls back to 1 | Division safe |
| 3 | Verify completion % = 0 | 0% rendered without division error |

---

#### TC-AD-50: XSS in Activity Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create HW with title containing `<script>alert('XSS')</script>` | Title stored in DB |
| 2 | Navigate to dashboard | Script tag is HTML-escaped, not executed |
| 3 | Verify no alert popup | XSS payload neutralized by Blade {{ }} escaping |
| 4 | Verify escaped text visible | Raw HTML tags shown as literal text in table |

---

#### TC-AD-51: SQL Injection in Date Range Parameters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pass date_from = `' OR 1=1 --` | Parameter treated as literal string, not SQL |
| 2 | Pass date_to with SQL injection payload | Eloquent parameter binding prevents injection |
| 3 | Verify no data leak | Only valid date-parsed records returned |
| 4 | Verify no SQL error exposed | No database error in response |

---

#### TC-AD-52: Performance — 100+ Activities Rendering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 100+ HW and Exam records | 100+ rows in dataset |
| 2 | Navigate to dashboard | Page loads within acceptable time (< 5s) |
| 3 | Verify table renders all rows | Scrollable table with all 100+ rows |
| 4 | Verify chart rendering | Donut and area charts render without lag |

---

#### TC-AD-53: Performance — Large Chart Data Rendering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load dashboard with large dataset | ApexCharts donut renders with large numbers |
| 2 | Verify donut segments proportionate | Segments scale correctly with large values |
| 3 | Verify area chart renders smoothly | No rendering artifacts with large Y values |
| 4 | Verify browser memory usage stable | No excessive memory consumption |

---

#### TC-AD-54: Concurrent Data — Adding HW While Viewing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open dashboard in browser tab | Dashboard loaded with current state |
| 2 | Create new homework in another tab | HW added to database |
| 3 | Refresh dashboard tab | New HW appears in activity table |
| 4 | Verify HW count incremented by 1 | Card count reflects new HW |

---

#### TC-AD-55: Concurrent Data — Adding Exam While Viewing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Dashboard open with current state | Baseline data visible |
| 2 | Create new exam via LmsExam module | Exam added concurrently |
| 3 | Refresh dashboard | Table includes new exam row |
| 4 | Verify Exam count incremented by 1 | Card count = previous + 1 |

---

#### TC-AD-56: Null Relation — Missing Class on HW

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create HW with class_id = null (if allowed) or invalid | Relation resolves to null |
| 2 | Verify view uses null-safe operator `->` | $hw->class?->name returns null, no error |
| 3 | Verify activity meta shows fallback | "N/A" or dash displayed for class name |
| 4 | Verify no Blade error rendered | Page loads without server error |

---

#### TC-AD-57: Null Relation — Missing Section on HW

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create HW with section_id = null | Section relation is null |
| 2 | Verify null-safe access `$hw->section?->name` | Returns null gracefully |
| 3 | Verify table row renders | Row displays without section info or fallback text |

---

#### TC-AD-58: Null Null Marks_Obtained on Submissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create HW submissions with marks_obtained = NULL | All marks null |
| 2 | Verify HW avg score = 0.0 | Null values treated as 0 or excluded from average |
| 3 | Verify no division error | Average calculation handles NULL safely |
| 4 | Verify card displays 0.0% | No NaN or error in card widget |

---

## End of TC List

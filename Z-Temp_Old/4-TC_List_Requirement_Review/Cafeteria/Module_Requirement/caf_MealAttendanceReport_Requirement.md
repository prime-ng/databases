# Meal Attendance Report — Business Requirements

## What This Report Shows

The Meal Attendance report tracks student meal scan/check-in records over a date range. It aggregates attendance by **meal category** (Breakfast/Lunch/Snacks/Dinner) and shows a **daily trend** of total scans. The report draws from the `caf_meal_attendance` table where each row represents one student's scan for one meal on one day.

## Data Sources

- **`caf_meal_attendance`** with `mealCategory` (eager loaded)
- **Filtered by**: `meal_date` range (`from_date`/`to_date`), `meal_category_id`
- **Aggregates**: Grouped by `mealCategory.name` for category breakdown, grouped by `meal_date` for daily trend

## Report Structure

### KPI Cards (Overview sub-tab)
- **Total Attendance** — Total number of attendance records in filtered range
- **Unique Students** — Distinct `student_id` count
- **Avg Daily** — Total Attendance ÷ number of days in range (or distinct meal dates present)
- **Categories** — Count of distinct meal categories represented

### Chart: Attendance by Category (Bar)
- X-axis: meal category names
- Y-axis: attendance count

### Chart: Daily Attendance Trend (Line)
- X-axis: dates
- Y-axis: attendance count per day

### Detailed Records sub-tab (Table)
- Columns: Date, Meal, Attendance Count
- Grouped by `meal_date|mealCategory.name` combination

## Filters

| Filter | Source Parameter | Type |
|--------|-----------------|------|
| Date Range | `caf_rpt_df` / `caf_rpt_dt` (hidden inputs from daterangepicker) | Daterangepicker |
| Meal Category | `meal_category_id` | Dropdown from `MenuCategory::active()` |

## Business Logic

- Records are immutable scan logs (no SoftDeletes, no updated_at)
- Unique student count uses `pluck('student_id')->unique()->count()`
- Avg daily uses date range days when provided; falls back to distinct meal dates in the result set
- Records table groups by (meal_date, category_name) to show per-slot attendance

## PDF Export

Route: `GET /cafeteria/reports/export/meal-attendance`
Layout: `reports-page.exports.meal-attendance-pdf`

## Requirements

- MUST display at `/cafeteria/reports-page?tab=meal-attendance` with Overview + Detailed Records internal tabs
- MUST authorize via `cafeteria.report.viewAny` gate
- MUST filter by date range and meal category
- MUST compute unique students via distinct student_id
- MUST compute avg daily using date range days or fallback to distinct meal dates
- MUST show category breakdown bar chart
- MUST show daily trend line chart
- MUST support PDF export via `exportMealAttendance()`

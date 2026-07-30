# caf_MealAttendanceReport — Test Case List & Business Conditions

**Module:** Cafeteria (CODE `CAF`, prefix `caf_`) · **Feature:** Meal Attendance Report
**DB scope:** TENANT-side (`caf_meal_attendance`, `caf_menu_categories`)
**Module URL:** `/cafeteria/reports-page?tab=meal-attendance`
**Test file:** `caf_MealAttendanceReport_TestCas.php`

Controller: `CafeteriaReportController::index()` + `getMealAttendance()`, `exportMealAttendance()`
View: `reports-page.tabs.meal-attendance`

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `caf_meal_attendance`: id, student_id, meal_date, meal_category_id, scanned_at, scan_method | Model |
| BC-DB-02 | `caf_menu_categories`: id, name | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `from_date` optional date | FR |
| BC-VAL-02 | `to_date` optional date | FR |
| BC-VAL-03 | `meal_category_id` optional integer exists | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `cafeteria.report.viewAny` | Ctrl |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Overview: Total Attendance, Unique Students, Avg Daily, Categories cards | View |
| BC-BIZ-02 | Bar chart "Attendance by Category": X=category, Y=attendance count | View |
| BC-BIZ-03 | Line chart "Daily Attendance Trend": X=dates, Y=attendance count | View |
| BC-BIZ-04 | Detailed Records table: Date, Meal, Attendance Count | View |
| BC-BIZ-05 | Avg Daily when date range provided = total ÷ (end - start + 1) days | Ctrl |
| BC-BIZ-06 | Avg Daily when no date range = total ÷ distinct meal_dates in result | Ctrl |
| BC-BIZ-07 | Unique Students = distinct student_ids in filtered set | Ctrl |
| BC-BIZ-08 | Empty state: "No attendance data." | View |

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | No records in date range → empty state | View |
| BC-EDG-02 | Single student with multiple meal scans in same day → counted per scan | Ctrl |
| BC-EDG-03 | Filter by category with zero records → empty state | View |
| BC-EDG-04 | Date range with no attendance data → total=0, avg=0 | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMAR-P10 | Positive | View | Overview: Total Attendance, Unique Students, Avg Daily, Categories cards | KPI cards | test_caf_mar_10 | Automated |
| TC-CAFMAR-P11 | Positive | View | Bar chart canvas present when attendance data exists | Bar chart | test_caf_mar_11 | Automated |
| TC-CAFMAR-P12 | Positive | View | Line chart canvas present when daily trend data exists | Line chart | test_caf_mar_12 | Automated |
| TC-CAFMAR-P13 | Positive | View | Detailed Records table with Date, Meal, Attendance Count | Table | test_caf_mar_13 | Automated |
| TC-CAFMAR-P14 | Positive | View | Filter by date range → records within range only | Filtered | test_caf_mar_14 | Automated |
| TC-CAFMAR-P15 | Positive | View | Filter by meal_category_id → only that category | Filtered | test_caf_mar_15 | Automated |
| TC-CAFMAR-P16 | Positive | Biz | Unique Students = distinct student_id | Unique | test_caf_mar_16 | Automated |
| TC-CAFMAR-P17 | Positive | Biz | Avg daily with date range: total / (range days) | Correct avg | test_caf_mar_17 | Automated |
| TC-CAFMAR-P18 | Positive | Biz | Avg daily without date range: total / distinct meal_dates | Correct avg | test_caf_mar_18 | Automated |
| TC-CAFMAR-P19 | Positive | View | No attendance data → empty state | Empty | test_caf_mar_19 | Automated |
| TC-CAFMAR-P20 | Positive | Ctrl | PDF export → application/pdf | PDF | test_caf_mar_20 | Automated |

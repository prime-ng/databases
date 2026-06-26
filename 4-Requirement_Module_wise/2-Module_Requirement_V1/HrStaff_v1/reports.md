# HR & Payroll Reports — Requirements

## What It Does
Provides analytical reports for HR and payroll data. Four key reports: Salary Register (detailed per-employee breakdown), Bank Summary (aggregate by bank), CTC Analysis (compensation structure distribution), and Payroll Trend (month-over-month payroll cost tracking).

Features:
- Salary Register: per-employee earnings, deductions, net pay
- Bank Summary: aggregate amounts per bank for disbursement planning
- CTC Analysis: distribution of compensation types across workforce
- Payroll Trend: month-over-month gross/net/employee count trends
- All reports filterable by: payroll run, month range, department, employee category

## Report Details

### Salary Register
- Shows per-employee row: name, code, designation, gross pay, each deduction, net pay
- Filterable by: payroll run, month, department
- Exportable to: PDF, Excel, CSV
- Paginated with totals row (sum of gross, deductions, net)

### Bank Summary
- Aggregate by bank: bank name, employee count, total net pay
- Used for bank transfer file preparation
- Filterable by: payroll run
- Exportable to: Excel, CSV

### CTC Analysis
- Distribution of CTC components: basic percentage, HRA, allowances, employer costs
- Average CTC by: department, designation, pay grade
- Filterable by: department, employee category
- Visual: bar chart or pie chart (front-end)
- Exportable to: PDF, Excel

### Payroll Trend
- Month-over-month trend: total gross, total deductions, total net, employee count
- Line chart showing trend over selected date range
- Filterable by: financial year, month range, department
- Year-over-year comparison (same month last year)
- Exportable to: PDF, Excel, image

## Permissions

| Operation | Permission Key |
|---|---|
| View all reports | `pay.run.initiate` |
| Export reports | `pay.run.initiate` |

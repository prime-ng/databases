# Report Designs Template

## 1. COMPLAINT SUMMARY & STATUS REPORT

**What this Report Covers**
  - Overview of total complaints received, resolved, and pending
  - Status-wise breakdown (Open, In-Progress, Closed)
  - Priority-wise distribution

**Useful For**
  - School Principal / Admin
  - Department Heads
  - Complaint Manager

**Fields Shown**
  - Status
  - Category
  - Sub-Category
  - Severity
  - Priority
  - Total Tickets
  - % of Total
  - Avg Resolution Time (Hrs)

**Tables Used**
  - `cmp_complaints`
  - `sys_dropdown_table` (for Status, Priority labels)
  - `cmp_complaint_categories` (for Category labels)
  - `cmp_complaint_subcategories` (for Sub-Category labels)
  - `cmp_complaint_severity` (for Severity labels)

**Filters**
  - Date Range
  - Department (Category)
  - Complainant Type (Student/Staff/Parent)

**MySQL Query (Reference)**
```sql
SELECT 
    s.value AS status_name,
    p.value AS priority_name,
    cat.name AS category_name,
    sub.name AS sub_category_name,
    sev.value AS severity_name,
    COUNT(c.id) AS total_tickets,
    ROUND(COUNT(c.id) * 100.0 / SUM(COUNT(c.id)) OVER(), 1) AS percent_total,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, c.ticket_date, COALESCE(c.actual_resolved_at, NOW()))), 1) AS avg_resolution_hours
FROM cmp_complaints c
JOIN sys_dropdown_table s ON s.id = c.status_id
JOIN sys_dropdown_table p ON p.id = c.priority_score_id
JOIN cmp_complaint_categories cat ON cat.id = c.category_id
LEFT JOIN cmp_complaint_categories sub ON sub.id = c.subcategory_id
JOIN sys_dropdown_table sev ON sev.id = c.severity_id  
WHERE c.ticket_date BETWEEN :start_date AND :end_date
GROUP BY s.value, p.value, cat.name, sub.name, sev.value
ORDER BY total_tickets DESC;
```

**Charts (📊)**
  - Pie Chart: Complaints by Status
  - Stacked Bar Chart: Priority vs Status

---

## 2. SLA VIOLATION & EFFICIENCY REPORT

**What this Report Covers**
  - Identify tickets that breached the defined SLA limits
  - Departments or Users consistently missing deadlines
  - Delay analysis in hours/days

**Useful For**
  - Operations Head
  - Quality Assurance Team

**Fields Shown**
  - Ticket No
  - Assigned To 
  - Defendant Type
  - Defendant Name
  - Complaint Category
  - Expected Resolution Date
  - Actual Resolution Date
  - Delay (Hours)
  - Escalation Level (L1-L5)

**Tables Used**
  - `cmp_complaints`
  - `cmp_complaint_categories`
  - `sys_users` (Assigned Officer)

**Filters**
  - Violation Type (Breached / At Risk)
  - Department
  - Escalation Level >= 3

**MySQL Query (Reference)**
```sql
SELECT 
    c.ticket_no,
    u.name AS assigned_to,
    t.value AS defendant_type,
    c.target_name as defendant_name,
    cat.name AS complaint_category,
    c.resolution_due_at,
    c.actual_resolved_at,
    TIMESTAMPDIFF(HOUR, c.resolution_due_at, COALESCE(c.actual_resolved_at, NOW())) AS delay_hours,
    c.current_escalation_level
FROM cmp_complaints c
JOIN cmp_complaint_categories cat ON cat.id = c.category_id
LEFT JOIN sys_users u ON u.id = c.assigned_to_user_id
JOIN sys_dropdown_table t ON t.id = c.target_user_type_id
WHERE c.resolution_due_at < COALESCE(c.actual_resolved_at, NOW()) -- Violation Check
AND c.status_id NOT IN (SELECT id FROM sys_dropdown_table WHERE name IN ('Rejected', 'Closed')) 
ORDER BY delay_hours DESC;
```

**Charts (📊)**
  - Bar Chart: Avg Delay by Department
  - Line Chart: SLA Breach Trend over Months

---
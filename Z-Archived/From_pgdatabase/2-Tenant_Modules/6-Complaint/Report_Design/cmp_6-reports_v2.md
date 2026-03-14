# Complaint Management Module - Report Designs (Deliverable G)

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

## 3. ROOT CAUSE ANALYSIS (PARETO REPORT)

**What this Report Covers**
  - Top 20% of categories causing 80% of volume
  - Identification of systemic issues (e.g., "Transport Delay" recurring often)

**Useful For**
  - Strategic Planning Team
  - Department Heads

**Fields Shown**
  - Category Name
  - Sub-Category Name
  - Total Tickets
  - Cumulative %
  - Average Severity

**Tables Used**
  - `cmp_complaints`
  - `cmp_complaint_categories`

**Filters**
  - Month / Quarter
  - Severity Level (Critical/High)

**MySQL Query (Reference)**
```sql
WITH CategoryCounts AS (
    SELECT 
        cat.name AS category,
        sub.name AS sub_category,
        COUNT(c.id) AS ticket_count
    FROM cmp_complaints c
    JOIN cmp_complaint_categories cat ON cat.id = c.category_id
    LEFT JOIN cmp_complaint_categories sub ON sub.id = c.subcategory_id
    GROUP BY cat.name, sub.name
)
SELECT 
    category,
    sub_category,
    ticket_count,
    ROUND(ticket_count * 100.0 / SUM(ticket_count) OVER(), 2) as pct_of_total,
    ROUND(SUM(ticket_count) OVER(ORDER BY ticket_count DESC) * 100.0 / SUM(ticket_count) OVER(), 2) as cumulative_pct
FROM CategoryCounts
ORDER BY ticket_count DESC;
```

**Charts (📊)**
  - Pareto Chart (Bar for Count, Line for Cumulative %)

---

## 4. COMPLAINANT CLUSTER & HOTSPOT REPORT (AI Insights)

**What this Report Covers**
  - Identification of "Hotspot" Targets (e.g., A specific Bus Route or Teacher receiving many complaints)
  - Identification of Frequent Complainants (Potential bias or genuine broad issues)

**Useful For**
  - HR (for Staff issues)
  - Transport Manager (for Route/Vehicle issues)
  - Audit Team

**Fields Shown**
  - Target Type (e.g., Vehicle, Teacher)
  - Target Name (e.g., Bus KA-05-1234)
  - Complaint Count
  - Unique Complainants
  - Most Common Issue Category
  - Risk Score (from AI Insights)

**Tables Used**
  - `cmp_complaints`
  - `cmp_ai_insights`

**Filters**
  - Target Type
  - Minimum Complaint Count (> 3)

**MySQL Query (Reference)**
```sql
SELECT 
    tar.value AS target_type,
    c.target_name,
    COUNT(c.id) AS total_complaints,
    COUNT(DISTINCT c.complainant_user_id) AS unique_complainants,
    (SELECT name FROM cmp_complaint_categories WHERE id = 
        (SELECT category_id FROM cmp_complaints c2 WHERE c2.target_selected_id = c.target_selected_id GROUP BY category_id ORDER BY COUNT(*) DESC LIMIT 1)
    ) AS most_common_issue,
    AVG(ai.escalation_risk_score) AS avg_risk_score
FROM cmp_complaints c
JOIN sys_dropdown_table tar ON tar.id = c.target_user_type_id
LEFT JOIN cmp_ai_insights ai ON ai.complaint_id = c.id
WHERE c.target_selected_id IS NOT NULL
GROUP BY c.target_table_name, c.target_selected_id, c.target_name
HAVING total_complaints >= 3
ORDER BY total_complaints DESC;
```

**Charts (📊)**
  - Heatmap: High complaint density targets
  - Scatter Plot: Frequency vs Risk Score

---

## 5. AI-DRIVEN RISK & SENTIMENT ANALYSIS REPORT (AI Insights)

**What this Report Covers**
  - Complaints with "Urgent" or "Angry" sentiment labels
  - Tickets predicted to have high escalation risk
  - Safety-related compliance risks

**Useful For**
  - Crisis Management Team
  - Safety Officers
  - Principal

**Fields Shown**
  - Ticket No
  - Sentiment Label (Angry/Urgent)
  - Sentiment Score (-1.0 to 1.0)
  - Escalation Risk Score (%)
  - Safety Risk Score (%)
  - Predicted Category

**Tables Used**
  - `cmp_complaints`
  - `cmp_ai_insights`
  - `sys_dropdown_table` (Labels)

**Filters**
  - High Risk Only (> 70%)
  - Negative Sentiment Only

**MySQL Query (Reference)**
```sql
SELECT 
    c.ticket_no,
    c.title,
    sent_label.name AS sentiment,
    ai.sentiment_score,
    ai.escalation_risk_score,
    ai.safety_risk_score,
    pred_cat.name AS ai_predicted_category
FROM cmp_ai_insights ai
JOIN cmp_complaints c ON c.id = ai.complaint_id
LEFT JOIN sys_dropdown_table sent_label ON sent_label.id = ai.sentiment_label_id
LEFT JOIN cmp_complaint_categories pred_cat ON pred_cat.id = ai.predicted_category_id
WHERE ai.escalation_risk_score > 70 OR ai.sentiment_score < -0.5
ORDER BY ai.safety_risk_score DESC, ai.escalation_risk_score DESC;
```

**Charts (📊)**
  - Bubble Chart: Risk Score vs Sentiment
  - Gauge Chart: Overall Safety Index

---

## REPORT LAYOUTS (Mockups)

### Layout 1: SLA Violation Report
```
+----------------------------------------------------------------------------------+
| Department: [Dropdown]   Period: [From - To]   Violation Only: [Checkbox]        |
+----------------------------------------------------------------------------------+
| Ticket No | Category       | Assigned To  | Target Date | Delay (Hrs) | Escalation |
|----------------------------------------------------------------------------------|
| CMP-1002  | AC Failing     | John Doe     | 12-Oct      | 24 hrs      | L2         |
| CMP-1045  | Bus Late       | Transport Mgr| 13-Oct      | 48 hrs      | L3         |
+----------------------------------------------------------------------------------+
Actions: [Escalate Now] [Send Reminder Email] [Export PDF]
```

### Layout 2: Hotspot Analysis (Target Entities)
```
+----------------------------------------------------------------------------------+
| Target Type: [Vehicle/Staff/Facility]   Min Complaints: [ 3 ]                    |
+----------------------------------------------------------------------------------+
| Target Entity     | Role/Type   | Total Complaints | Audit Risk | Top Issue      |
|----------------------------------------------------------------------------------|
| KA-01-F-1234      | Vehicle     | 15               | HIGH       | Rash Driving   |
| Mr. ABC Name      | Teacher     | 8                | MEDIUM     | Grading Issue  |
+----------------------------------------------------------------------------------+
Actions: [Flag for Audit] [View History]
```

## GLOBAL REPORT FEATURES

### Export Options
- PDF (for official submission)
- Excel/CSV (for raw data analysis)

### Drilldown Consistency
- Clicking a **Category** in Pareto Chart -> Opens list of tickets in that category.
- Clicking a **Target Entity** -> Opens full history profile of that entity (e.g., Vehicle History).
- Clicking a **Ticket No** -> Opens the full Complaint Detail View with Chat/Audit Logs.

### Access Control
- **Super Admin**: Can see all reports.
- **Department Head**: Can only see data related to their department (e.g., Transport Manager sees only Transport issues).

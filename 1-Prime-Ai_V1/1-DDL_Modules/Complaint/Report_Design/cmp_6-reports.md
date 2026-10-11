# Complaint Management Module - Report Designs (Deliverable G)

## 1. SLA Violation Report
**Purpose**: Identify which departments are consistently missing deadlines to improve operational efficiency.

*   **Primary Tables**: `cmp_complaints`, `cmp_complaint_categories`
*   **Filters**: Date Range, Department, Min Escalation Level (e.g., Level >= 3).
*   **Columns**:
    *   Ticket No
    *   Category
    *   Assigned To (User)
    *   Target Date
    *   Actual Resolve Date
    *   **Delay (Hours)**
    *   Escalation Level Reached (L1-L5)
*   **Visualization**: Bar Chart "Avg Delay by Department".

---

## 2. Root Cause Analysis (Pareto)
**Purpose**: Identify top 20% of issues causing 80% of complains.

*   **Primary Tables**: `cmp_complaints`
*   **Filters**: Month.
*   **Columns**:
    *   Category Name
    *   Sub-Category Name
    *   Total Tickets
    *   % of Total
    *   Avg Priority
*   **Visualization**: Pareto Chart (Cumulative %).

---

## 3. Complainant Cluster Report
**Purpose**: Identify frequent complainers (potential underlying satisfaction issue) or "Hotspot" Generators (e.g., a specific Bus Route generating 50% of complaints).

*   **Primary Tables**: `cmp_complaints`
*   **Logic**: Group By `target_selected_id` (e.g., Vehicle ID) or `complainant_user_id`.
*   **Columns**:
    *   Target Entity (e.g., Bus KA-05-1234)
    *   Complaint Count
    *   Most Common Issue (e.g., Rash Driving)
    *   Risk Score
*   **Action**: "Flag for Audit" button.

Complaint & Grievance Dashboards + KPIs
🔹 DASHBOARD ARCHITECTURE (OVERVIEW)
    Dashboard Layers
      - Enterprise / Management Dashboard
      - Department-wise Dashboard
      - Transport Safety & Compliance Dashboard
      - Operational (Admin / Officer) Dashboard
      - Analytics & Predictive Dashboard (Future AI)

    Each dashboard consumes data primarily from:
      - erp_complaints
      - erp_complaint_actions
      - erp_complaint_medical_checks
      - erp_complaint_attachments

🔹 MANAGEMENT DASHBOARD (CXO / Principal / Director)
🎯 Objective
     High-level risk, compliance & reputation view.

🔹 Key KPIs
    KPI	                        Description
    -------------------------   -----------------------------
    Total Complaints	        Count by selected date range
    Open vs Closed %	        Operational efficiency
    Critical Complaints	        Severity = Critical
    Avg Resolution Time	        SLA effectiveness
    Escalation Rate	            % complaints escalated
    Transport Safety Index	    Composite score

📊 Visuals
      - Complaint trend line (Monthly)
      - Severity donut chart
      - Department heatmap
      - Transport vs Non-Transport split

📌 Sample Metric Formula
      - Transport Safety Index = 100
        - (Critical Transport Complaints × 5)
        - (Alcohol Positive Cases × 10)
        - (Repeat Driver Complaints × 3)

🔹 DEPARTMENT-WISE DASHBOARD
    (Transport, Academics, HR, Hostel, Admin)

🎯 Objective
    Identify problematic departments and root causes.

🔹 KPIs
    KPI	                            Description
    -------------------------       -----------------------------
    Complaints by Category	        Behaviour / Safety / Service
    Avg Handling Time	            Per department
    Repeat Complaints	            Same target_id
    SLA Breaches	                Expected vs actual
    Resolution Quality	            Reopened cases

📊 Visuals
      - Bar chart: Complaints by category
      - SLA breach stacked chart
      - Repeat complaint leaderboard

🔹 TRANSPORT SAFETY & COMPLIANCE DASHBOARD
    (Most Critical for Legal & Parent Trust)

🎯 Objective
    Ensure student safety, driver fitness, and legal compliance.

🔹 Transport-Specific KPIs
🔴 Safety KPIs
    KPI						    Source
    -------------------------   -----------------------------
    Transport Complaints	    is_transport_related = 1
    Alcohol Suspected Cases		alcohol_suspected = 1
    Alcohol Positive Rate		Medical checks
    Medical Unfit Cases		    medical_unfit_suspected = 1
    Safety Violations			safety_violation = 1

👨‍✈️ Driver Risk KPIs
    KPI						    Logic
    -------------------------   -----------------------------
    Complaints per Driver		target_type='Driver'
    Repeat Driver Complaints	Count > 1
    Driver Risk Score		    Weighted formula
    Suspensions Issued		    Action type = Suspension

📊 Visuals
      - Driver Risk Heatmap
      - Alcohol test pass/fail chart
      - Complaint-to-action funnel

    Route-wise complaint distribution

📌 Driver Risk Score (Example)
        Driver Risk Score =
        (High Severity Complaints × 4)
        + (Alcohol Positive × 10)
        + (Medical Unfit × 6)
        + (Repeat Complaints × 3)


🔹 Thresholds:
    - 0–5 → Low Risk
    - 6–12 → Medium Risk
    - 13+ → High Risk (Auto escalation)

🔹 OPERATIONAL DASHBOARD (Admin / Compliance Officer)
🎯 Objective
    Day-to-day complaint handling & SLA tracking.

🔹 KPIs
    KPI	                            Description
    Complaints Assigned to Me	    Workload
    Pending Actions	                Bottlenecks
    SLA Near Breach	                Next 24 hrs
    Action Aging	                Oldest pending
    Attachments Pending Review	    Evidence handling

📊 Visuals
    Task list (Kanban style)
    SLA countdown indicators
    Timeline view per complaint

🔹 SLA & ESCALATION ANALYTICS
📌 SLA Metrics
    Metric					        Calculation
    -------------------------       -----------------------------
    SLA Compliance %		        Resolved within SLA
    Avg SLA Overrun		            Delay in hours
    Escalation Trigger Rate	        Auto escalations

📌 Escalation Triggers (Logic)
     - Critical + 12 hrs no action
     - Alcohol suspected + no test in 2 hrs
     - Reopened complaint count > 1

🔹 TREND & ROOT-CAUSE ANALYTICS
🔍 Trend KPIs
     - Complaints per 100 students
     - Complaints per vehicle
     - Monthly growth / decline %
     - Seasonal spikes (exam / monsoon)

🔍 Root Cause Drilldowns
     - Top 5 complaint subcategories
     - Department × Severity matrix
     - Staff/Driver with max complaints

🔹 PREDICTIVE & AI-READY METRICS (Future)
🤖 AI Inputs
     - Complaint text sentiment
     - Historical severity patterns
     - Driver attendance + complaints
     - Route-level complaint density

🔮 AI Outputs
     - Predicted escalation risk
     - Driver suspension recommendation
     - Route reassignment suggestions
     - Preventive safety alerts

🔹 DATA SECURITY & ACCESS CONTROL (Dashboard Level)
    Role	                Access
    ----------------------  -----------------------------
    Management	            All dashboards
    Transport Head	        Transport-only
    Compliance Officer	    Complaints + Actions
    Department Head	        Own department
    Parent	                Own complaints only

🔹 WHY THIS DASHBOARD DESIGN IS STRONG
    ✔ Not just counts — actionable intelligence
    ✔ Transport safety gets special compliance focus
    ✔ Supports legal audits & parent trust
    ✔ Ready for AI/ML layer
    ✔ Works across multi-tenant ERP



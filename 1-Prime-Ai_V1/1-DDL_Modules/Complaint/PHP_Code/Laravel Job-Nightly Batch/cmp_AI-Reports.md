# Complaint Module - AI Report Designs

🔥 1. Hotspot Heatmap Report
🎯 Purpose

Identify targets (Teacher / Bus / Route / Staff) that are generating high complaint volume + high risk.

👥 Useful For

Management

HR

Transport Head

Audit Committee

📄 Data Source

cmp_mv_complaint_hotspots

📊 Fields Used
Field	Meaning
target_name	X-axis
most_common_category_id	Y-axis
total_complaints	Density
avg_risk_score	Color intensity
🧮 Query
SELECT
    target_name,
    most_common_category_id,
    total_complaints,
    avg_risk_score
FROM cmp_mv_complaint_hotspots
WHERE snapshot_date = CURDATE()
  AND total_complaints >= 3;

📊 Chart Design

Heatmap

X-axis → Target Name

Y-axis → Complaint Category

Cell Color → avg_risk_score

Green: <40

Amber: 40–70

Red: >70

🧑‍⚖️ Audit Explanation

“This target appears red because it has multiple complaints concentrated in one category with consistently high AI-derived risk scores.”

📊 2. Risk vs Frequency Scatter Plot
🎯 Purpose

Differentiate:

Frequent but low-risk issues

Low frequency but critical incidents

📄 Data Source

cmp_mv_complaint_hotspots

🧮 Query
SELECT
    target_name,
    total_complaints,
    avg_risk_score,
    unique_complainants
FROM cmp_mv_complaint_hotspots
WHERE snapshot_date = CURDATE();

📊 Chart Design

Bubble Scatter Plot

X-axis → total_complaints

Y-axis → avg_risk_score

Bubble Size → unique_complainants

Quadrants:

Top-right → 🔥 Immediate action

Bottom-right → Process issue

Top-left → One-off serious event

🧑‍⚖️ Audit Explanation

“High risk with low frequency indicates severity-driven escalation rather than noise.”

📈 3. Day-over-Day Escalation Trend Report
🎯 Purpose

Track whether complaint severity is increasing or stabilizing.

📄 Data Source

cmp_ai_insights + cmp_complaints

🧮 Query
SELECT
    DATE(c.created_at) AS report_date,
    AVG(ai.escalation_risk_score) AS avg_escalation_risk,
    COUNT(c.id) AS total_complaints
FROM cmp_complaints c
JOIN cmp_ai_insights ai ON ai.complaint_id = c.id
WHERE c.created_at >= CURDATE() - INTERVAL 14 DAY
GROUP BY DATE(c.created_at)
ORDER BY report_date;

📊 Chart Design

Line Chart

X-axis → Date

Y-axis → Avg Escalation Risk

Secondary Y-axis → Complaint Count

🧑‍⚖️ Audit Explanation

“A rising trend indicates systemic issues not being resolved.”

🚨 4. Auto-Alert Report (Risk > 80)
🎯 Purpose

Early warning system for critical complaints.

📄 Data Source

cmp_ai_insights

🧮 Query
SELECT
    c.id AS complaint_id,
    c.subject,
    c.target_name,
    ai.risk_score,
    ai.escalation_risk_score,
    ai.safety_risk_score,
    c.created_at
FROM cmp_complaints c
JOIN cmp_ai_insights ai ON ai.complaint_id = c.id
WHERE ai.risk_score >= 80
   OR ai.escalation_risk_score >= 80
   OR ai.safety_risk_score >= 80
ORDER BY GREATEST(
    ai.risk_score,
    ai.escalation_risk_score,
    ai.safety_risk_score
) DESC;

📊 Usage

Trigger email / WhatsApp / dashboard alert

SLA breach monitoring

🧑‍⚖️ Audit Explanation

“Alerts are system-generated using predefined risk thresholds, not human bias.”

🧑‍⚖️ 5. Audit-Ready Explainable Metrics Report
🎯 Purpose

Explain WHY a complaint got a high score.

📄 Data Source

cmp_ai_insights + complaint metadata

🧮 Query
SELECT
    c.id,
    c.subject,
    ai.risk_score,
    ai.escalation_risk_score,
    ai.safety_risk_score,
    ai.predicted_category_id,
    c.created_at
FROM cmp_complaints c
JOIN cmp_ai_insights ai ON ai.complaint_id = c.id
ORDER BY ai.risk_score DESC;

📊 UI Design

Expandable row:

Severity = High (80)

Frequency = 3 complaints (60)

Sentiment = Angry (75)

Pending = 8 days (40)

🧑‍⚖️ Audit Explanation

“Scores are computed using transparent rule-based weights approved by management.”

PART B — DASHBOARD KPIs & CHARTS DESIGN
🎛️ Complaint Analytics Dashboard (Management View)
🔢 KPI CARDS (Top Row)
KPI	Source	Meaning
Total Complaints (Today / Month)	cmp_complaints	Volume
High Risk Complaints	cmp_ai_insights	Risk > 80
Avg Risk Score	cmp_ai_insights	Overall health
Safety Alerts	safety_risk_score > 80	Child safety
Escalation Trend ↑↓	DoD delta	Stability
📊 MAIN CHARTS (Center)

Hotspot Heatmap

Risk vs Frequency Scatter

Escalation Trend Line (14 days)

🚨 ALERT PANEL (Right)

Latest complaints with any score > 80

Color-coded:

Red → Safety

Orange → Escalation

Purple → Overall risk

🧑‍⚖️ AUDIT PANEL (Bottom)

“Why was this complaint flagged?”

Weight breakdown

Rule triggered (keyword / frequency / severity)

🎯 Role-Based Visibility (Very Important)
Role	View
Principal	Full dashboard
HR	Staff-only targets
Transport Head	Vehicle / Route
Admin	All
Audit	Read-only + explanations

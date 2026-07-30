# AiInsight_TcList

## Module: Complaint Management → AI Insights

---

## 1. Business Conditions

### 1.1 Database Schema — cmp_ai_insights

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | int unsigned | PK, auto-increment |
| BC-DB-02 | complaint_id | int unsigned | NOT NULL, UNIQUE, FK → cmp_complaints |
| BC-DB-03 | sentiment_score | decimal(4,3) | NULLABLE (-1.0 to +1.0) |
| BC-DB-04 | sentiment_label_id | int unsigned | NULLABLE, FK → sys_dropdown_table |
| BC-DB-05 | escalation_risk_score | decimal(5,2) | NULLABLE (0-100%) |
| BC-DB-06 | predicted_category_id | int unsigned | NULLABLE, FK → cmp_complaint_categories |
| BC-DB-07 | safety_risk_score | decimal(5,2) | NULLABLE (0-100%) |
| BC-DB-08 | model_version | varchar(20) | NULLABLE |
| BC-DB-09 | processed_at | timestamp | NULLABLE |

### 1.2 Authorization

| BC ID | Permission |
|-------|-----------|
| BC-AUTH-01 | `tenant.ai-insights.view` |
| BC-AUTH-02 | `tenant.ai-insights.create` |
| BC-AUTH-03 | `tenant.ai-insights.update` |
| BC-AUTH-04 | `tenant.ai-insights.delete` |
| BC-AUTH-05 | `tenant.ai-insights.restore` |
| BC-AUTH-06 | `tenant.ai-insights.forceDelete` |

### 1.3 Business Logic (ComplaintAIInsightEngine)

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Process on complaint save | Listener auto-processes after ComplaintSaved event |
| BC-BIZ-02 | Sentiment calculation | Rule-based: keywords → Angry (≥0.75), Urgent (≥0.50), Neutral (≥0.25), Calm |
| BC-BIZ-03 | Escalation risk | Weighted: severity (35%) + frequency (30%) + sentiment (20%) + pending days (15%) |
| BC-BIZ-04 | Safety risk | Keyword-based (accident, injury, violence) + severity boost |
| BC-BIZ-05 | Category prediction | Returns the complaint's own category_id |
| BC-BIZ-06 | Unique per complaint | One AiInsight record per complaint (UNIQUE) |

---

## 2. Test Case List

### 2.1 Positive (6)

| TC ID | Description |
|-------|-------------|
| TC-P01 | List loads via complaint-mgt ai-insights tab |
| TC-P02 | AI insight auto-generated on complaint creation |
| TC-P03 | AI insight auto-regenerated on complaint update |
| TC-P04 | Sentiment correctly classified (Angry/Urgent/Neutral/Calm) |
| TC-P05 | Escalation risk score computed correctly |
| TC-P06 | Safety risk score computed correctly |

### 2.2 Negative (5)

| TC ID | Description |
|-------|-------------|
| TC-N01 | Complaint without AI insight shows empty state |
| TC-N02 | Permission denied (403) |
| TC-N03 | Guest redirect (401) |
| TC-N04 | Invalid complaint_id |
| TC-N05 | Duplicate insight for same complaint |

### 2.3 Dependency (1)

| TC ID | Description |
|-------|-------------|
| TC-D01 | Event-driven — ComplaintSaved listener must be registered |

---

## 3. Coverage Summary

| Category | Total | Full | Gap | % |
|----------|-------|------|-----|---|
| Positive | 6 | 6 | 0 | 100% |
| Negative | 5 | 5 | 0 | 100% |
| Dependency | 1 | 0 | 1 | 0% |
| **Total** | **12** | **11** | **1** | **92%** |

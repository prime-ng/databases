# AI Insights — Requirements

## What It Does
Stores AI-generated analysis for each complaint. The current engine is rule-based (keyword matching), not ML-based. Processed automatically when a complaint is saved. Provides sentiment analysis, escalation risk prediction, safety risk assessment, and category prediction.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `complaint_id` | BIGINT FK → `cmp_complaints` | Required. One-to-one with complaint (unique FK). |
| `sentiment_score` | DECIMAL(3,2) | Range -1 to 1. Computed from keyword analysis. |
| `sentiment_label_id` | BIGINT FK → `sys_dropdowns` | Angry / Calm / Urgent / Neutral. |
| `escalation_risk_score` | DECIMAL(5,2) | Range 0–100. Weighted formula. |
| `predicted_category_id` | BIGINT FK → `cmp_complaint_categories` | Currently returns the same category (stub). |
| `safety_risk_score` | DECIMAL(5,2) | Range 0–100. Keyword-severity mapping. |
| `model_version` | VARCHAR | Currently `rules-v1`. |
| `processed_at` | DATETIME | When analysis was completed. |

## AI Engine Logic

**Sentiment Calculation** (keyword matching)
- Keywords like "angry", "delay", "harassment" → negative score
- Keywords like "urgent", "unsafe" → urgency score
- Keywords like "worst", "threat" → high severity score
- Final score mapped to label: Calm / Neutral / Urgent / Angry

**Risk Score Formula**
```
risk = (severity_weight × 35%) + (target_frequency × 30%) + (sentiment_weight × 20%) + (pending_days × 15%)
```

**Safety Risk Calculation**
- Keyword severity mapping: accident=90, injury=95, violence=100
- Boosted by severity level of the category

## Processing Flow
1. Complaint is saved → dispatches `ComplaintSaved` event
2. `ProcessComplaintAIInsights` listener picks it up
3. `ComplaintAIInsightEngine::processComplaint()` runs the analysis
4. Results stored in `cmp_ai_insights` table

## CRUD Operations
- Primarily read-only — insights are auto-generated
- Displayed in the "AI Insights" tab of the master view
- Shows sentiment, risk scores, and safety assessment per complaint
- Manual store/update available for administrative corrections
- Force delete available for cleanup

## Permissions

| Operation | Permission Key |
|---|---|
| View AI insights tab | `tenant.ai-insights.viewAny` |
| View insight details | `tenant.ai-insights.view` |
| Create/update insights | `tenant.ai-insights.create` / `.update` |
| Force delete insight | `tenant.ai-insights.forceDelete` |

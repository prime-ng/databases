# AI Insights — Business Requirements

## What This Screen Does

The AI Insights screen displays AI-generated analysis for each complaint. Powered by the `ComplaintAIInsightEngine`, it provides sentiment scoring, escalation risk prediction, safety risk assessment, and category prediction. Insights are auto-generated when a complaint is created or updated via the `ComplaintSaved` event → `ProcessComplaintAIInsights` listener.

## When This Screen Is Used

- **When reviewing complaint sentiment** to prioritize urgent/angry complaints.
- **When assessing escalation risk** to proactively handle high-risk complaints.
- **When monitoring safety-related complaints** for immediate intervention.
- **When analyzing trends** across sentiment, risk, and safety metrics.

## Key Fields

- **Complaint** (FK → cmp_complaints, unique) — One insight per complaint
- **Sentiment Score** (decimal 4,3, -1.0 to +1.0) — Negative to positive
- **Sentiment Label** (FK → sys_dropdown_table) — Angry, Urgent, Neutral, Calm
- **Escalation Risk Score** (decimal 5,2, 0–100%) — Risk of escalation
- **Predicted Category** (FK → cmp_complaint_categories, nullable) — AI-predicted category
- **Safety Risk Score** (decimal 5,2, 0–100%) — Safety risk level
- **Model Version** (string 20) — AI model version
- **Processed At** (timestamp) — When processed

## Business Rules

**Auto-Processing:**
Insights are generated automatically by the `ComplaintAIInsightEngine` which listens to `ComplaintSaved` event. No manual creation is needed.

**Sentiment Calculation (Rule-Based):**
Description text is scanned for keywords: angry words (≥0.75), urgency words (≥0.50), neutral words (≥0.25), default calm. Label mapping: ≥0.75 → Angry, ≥0.50 → Urgent, ≥0.25 → Neutral, default → Calm.

**Escalation Risk Formula:**
Weighted calculation: severity (35%) + complainant frequency (30%) + sentiment score (20%) + pending days (15%).

**Safety Risk:**
Keyword-based detection (accident, injury, violence, etc.) with severity boost.

**Category Prediction:**
Currently returns the complaint's own category_id.

**One-to-One:**
Each complaint has exactly one AI insight record (UNIQUE constraint on complaint_id).

## Workflow

1. User navigates to Complaint → Complaint Management → AI Insights tab.
2. Table shows: Ticket No, Sentiment (label + score), Escalation Risk %, Safety Risk %, Predicted Category, Processed At.
3. Insights are auto-generated — no user action needed.
4. High-risk complaints (≥80%) are highlighted for attention.

## Requirements

- MUST display at `/complaint/complaint-mgt?tab=ai` as paginated table
- MUST authorize via `tenant.ai-insights.*` policy gates
- MUST auto-generate insight on complaint create/update via event listener
- MUST calculate sentiment score using rule-based keyword analysis
- MUST calculate escalation risk using weighted formula
- MUST calculate safety risk using keyword detection
- MUST enforce one insight per complaint (UNIQUE)
- MUST highlight high-risk insights (≥80%) for priority attention

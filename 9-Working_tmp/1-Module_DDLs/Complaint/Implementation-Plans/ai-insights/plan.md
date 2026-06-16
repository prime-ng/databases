# AI Insights — Implementation Plan

## Purpose
AI-generated analysis per complaint: sentiment scoring, escalation risk prediction, safety risk assessment. Currently rule-based (keyword matching), ML microservice deferred.

## Documented But Not Implemented

### Item 1: AiInsightController Is a Stub

**Source:** Routes register CRUD but controller is a stub

**Current Behavior:** `AiInsightController.php` (56 lines) only has `index()` returning a placeholder view.

**Implement:**
- [ ] `index()`: List all AI insights with complaint reference, sentiment, risk scores; filterable by date range, risk level
- [ ] `show()`: View single insight detail
- [ ] `store()`: Manual create for corrections (admin override)
- [ ] `update()`: Edit insight values (admin correction)
- [ ] `forceDelete()`: Remove insight record

### Item 2: Target Frequency Not Implemented in Risk Score Formula

**Source:** `cmp_requirement.md:443-445` — Risk formula: `(severity_weight × 35%) + (target_frequency × 30%) + (sentiment_weight × 20%) + (pending_days × 15%)`

**Current Behavior:** `ComplaintAIInsightEngine` computes risk score but the `target_frequency` component (30% weight) is not calculated — likely stubbed or omitted.

**Implement:**
- [ ] In `ComplaintAIInsightEngine::computeRiskScore()`:
```php
// Compute target frequency
$targetFrequency = Complaint::where('target_table_name', $complaint->target_table_name)
    ->where('target_id', $complaint->target_id)
    ->where('created_at', '>=', Carbon::now()->subDays(90))
    ->count();

// Normalize to 0-100 scale
$frequencyScore = min(100, ($targetFrequency / 10) * 100);

// Apply formula
$risk = ($severityScore * 0.35) + ($frequencyScore * 0.30) + ($sentimentScore * 0.20) + ($pendingDaysScore * 0.15);
```

### Item 3: Python ML Microservice (Deferred)

**Source:** `cmp_AI_Calc_Logic.md` documents FastAPI + BERT + XGBoost architecture

**Current Behavior:** Entirely rule-based. No ML.

**Decision:** Defer until:
- 10,000+ labeled complaint records collected
- Rule-based accuracy baseline measured
- Business formally requests ML upgrade

When ready, implement:
- [ ] FastAPI microservice with `/predict` endpoint
- [ ] BERT-based sentiment classifier
- [ ] XGBoost escalation risk predictor
- [ ] Laravel HTTP client to call microservice
- [ ] Fallback to rule-based engine if microservice unavailable

### Item 4: Migration Exists — Verify Schema

**Source:** `database/migrations/tenant/2025_12_22_074156_create_ai_insights_table.php`

**Current Behavior:** Migration exists. Verify it matches the spec.

**Implement:**
- [ ] Review migration for all required columns
- [ ] Ensure `complaint_id` has unique constraint for 1:1 relationship

### Item 5: Missing Feature Tests

**Current Behavior:** Zero tests.

**Implement:**
- [ ] `AiInsightEngineTest.php`:
  - Sentiment: angry keywords map to negative score
  - Sentiment: neutral text maps to near-zero score
  - Escalation risk: high severity + old complaint → high risk
  - Safety risk: keyword "violence" maps to score ~100
  - Safety risk: keyword "accident" maps to score ~90

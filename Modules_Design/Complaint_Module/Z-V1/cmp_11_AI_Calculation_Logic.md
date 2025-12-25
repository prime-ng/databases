# AI Calculation Logic for Complaint Module (`cmp_ai_insights`)

This document outlines the logic, algorithms, and triggers used to populate the `cmp_ai_insights` table. These insights are generated via asynchronous jobs triggered immediately after a complaint is lodged or updated.

## 1. Trigger Mechanism
*   **Event:** `ComplaintCreated` or `ComplaintUpdated` (Description changed).
*   **Process:** 
    1. System pushes a Job to the TOC (Tasks/Queue).
    2. Job payload includes: `complaint_id`, `title`, `description`, `category_name`, `complainant_type`.
    3. Job calls the **AI Service Provider** (e.g., Python Microservice / LLM API).
    4. Result is validated and inserted/updated in `cmp_ai_insights`.

---

## 2. Field-by-Field Calculation Logic

### A. `sentiment_score` & `sentiment_label_id`
*   **Input:** `title`, `description`
*   **Methodology:** Natural Language Processing (NLP).
*   **Logic:**
    1.  **Sanitization:** Remove stop words, HTML tags.
    2.  **Analysis:** Pass text to Sentiment Model (VADER, TextBlob, or LLM).
    3.  **Scoring (Decimal -1.0 to +1.0):**
        *   `-1.0` = Extremely Negative (Rage, Threat).
        *   `0.0` = Neutral (Factual statement).
        *   `+1.0` = Positive (Appreciation - rare for complaints).
    4.  **Label Mapping (Sys Dropdown):**
        *   Score `<-0.6` → **"Angry"** (ID: 101)
        *   Score `-0.6 to -0.2` → **"Urgent"** (ID: 102)
        *   Score `-0.2 to +0.2` → **"Neutral"** (ID: 103)
        *   Score `>0.2` → **"Calm"** (ID: 104)

### B. `predicted_category_id`
*   **Input:** `title`, `description`
*   **Purpose:** To correct misclassified complaints (e.g., Parent selects "Academic" but complains about "Bus Driver").
*   **Methodology:** Zero-Shot Classification (LLM) or Vector Semantic Search.
*   **Logic:**
    1.  Compare input text against the descriptions of defined `cmp_complaint_categories`.
    2.  AI returns the **Category** with the highest confidence match.
    3.  System checks if `predicted_category_id` != user-selected `category_id`.
    4.  **Action:** Flag for Admin review if mismatched.

### C. `escalation_risk_score` (0 - 100%)
*   **Input:** `sentiment_score`, `severity_level`, `complainant_history`, `keywords`.
*   **Methodology:** Weighted Heuristic Algorithm.
*   **Formula:**
    ```
    Base Score = (Severity Level / 10) * 30  [Max 30]
    Sentiment Factor = (Abs(Negative Score) * 20) [Max 20]
    Keyword Factor = If text contains ("Legal", "Police", "Media", "Principal") -> +25
    History Factor = If Complainant has > 3 unresolved tickets -> +15
    Time Factor = If Incident Date > 7 days ago (Delayed Reporting) -> +10
    
    Total Risk = Sum(Factors) [Capped at 100]
    ```

### D. `safety_risk_score` (0 - 100%)
*   **Input:** `is_transport_related`, `description`, `keywords`.
*   **Methodology:** Keyword Pattern Matching & Safety Context.
*   **Logic:**
    *   If `is_transport_related` = FALSE, Score = 0.
    *   Else, scan for High-Risk Tokens:
        *   **CRITICAL (+50):** "Drunk", "Swaying", "Accident", "Hit", "Blood", "Smell alcohol".
        *   **HIGH (+30):** "Rash", "Speeding", "Overtaking", "Phone while driving".
        *   **MODERATE (+10):** "Late", "Rude", "Uniform".
    *   **Calculation:** Sum values. If > 80, system triggers immediate **SMS Alert** to Transport Manager.

---

## 3. Example JSON Output (From AI Service)

```json
{
  "complaint_id": 5055,
  "analysis": {
    "sentiment": {
      "score": -0.85,
      "label": "Angry"
    },
    "prediction": {
      "suggested_category": "Transport - Safety",
      "confidence": 0.92
    },
    "risk_assessment": {
      "escalation_score": 85.00,
      "safety_score": 90.00,
      "drivers": ["Keyword: Drunk", "Sentiment: High Negative"]
    }
  },
  "meta_model": "GPT-4o-Mini_v1.0"
}
```

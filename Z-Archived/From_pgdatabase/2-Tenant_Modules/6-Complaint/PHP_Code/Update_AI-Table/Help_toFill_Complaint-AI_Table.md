# How to Fill Complaint AI Table

## What “Risk Score” Should Represent (Non-ML)

For Complaint Hotspot & Cluster Analysis, a good Risk Score should reflect:

| Factor	            | Why it Matters
| --- | ---
| Complaint Severity	| Serious issues raise risk
| Complaint Frequency	| Repeated complaints = hotspot
| Sentiment Negativity	| Angry language = escalation
| Unresolved Duration	| Long open complaints = risk
| Repeat Complainants	| Pattern vs one-off noise

We convert these into weighted numeric signals.

### Risk Score Formula (0–100)

```
Risk Score =
  (Severity Weight * Severity Score)
+ (Frequency Weight * Frequency Score)
+ (Sentiment Weight * Sentiment Score)
+ (Pending Days Weight * Pending Score)
```
| Factor	            | Weight
| --------------------- | -------
| Complaint Severity	| 0.30
| Complaint Frequency	| 0.30
| Sentiment Negativity	| 0.25
| Unresolved Duration	| 0.15


### Weights

| Component	        | Weight
| ----------------- | -------
| Severity	        | 35%
| Frequency	        | 30%
| Sentiment	        | 20%
| Pending Duration	| 15%
| Total	            | 100%

### Mapping Tables (Rule-Based Intelligence)
```
$severityMap = [
    'Low' => 20,
    'Medium' => 50,
    'High' => 80,
    'Critical' => 100
];
```

### Sentiment Mapping

```
$sentimentMap = [
    'Calm' => 20,
    'Neutral' => 40,
    'Angry' => 80,
    'Urgent' => 100
];
```

### EXAMPLE - Laravel Service: Risk Score Calculator

```
app/Services/ComplaintRiskCalculator.php

<?php

namespace App\Services;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class ComplaintRiskCalculator
{
    public function calculateRiskScore(int $complaintId): float
    {
        $complaint = DB::table('cmp_complaints as c')
            ->leftJoin('sys_dropdown_table as sev', 'sev.id', '=', 'c.severity_id')
            ->leftJoin('cmp_ai_insights as ai', 'ai.complaint_id', '=', 'c.id')
            ->where('c.id', $complaintId)
            ->select(
                'c.created_at',
                'c.status_id',
                'sev.value as severity',
                'ai.sentiment_label_id',
                'ai.sentiment_score'
            )
            ->first();

        if (!$complaint) {
            return 0;
        }

        /* ---------------- SEVERITY ---------------- */
        $severityScore = match ($complaint->severity) {
            'Critical' => 100,
            'High' => 80,
            'Medium' => 50,
            default => 20,
        };

        /* ---------------- FREQUENCY ---------------- */
        $frequencyCount = DB::table('cmp_complaints')
            ->where('target_selected_id', function ($q) use ($complaintId) {
                $q->select('target_selected_id')
                  ->from('cmp_complaints')
                  ->where('id', $complaintId);
            })
            ->count();

        $frequencyScore = min(100, $frequencyCount * 20);

        /* ---------------- SENTIMENT ---------------- */
        $sentimentScore = 50;
        if (!is_null($complaint->sentiment_score)) {
            // Convert -1 to +1 scale into 0–100
            $sentimentScore = (($complaint->sentiment_score + 1) / 2) * 100;
        }

        /* ---------------- PENDING DAYS ---------------- */
        $daysPending = Carbon::parse($complaint->created_at)->diffInDays(now());
        $pendingScore = min(100, $daysPending * 5);

        /* ---------------- FINAL WEIGHTED SCORE ---------------- */
        $finalRiskScore =
            ($severityScore * 0.35) +
            ($frequencyScore * 0.30) +
            ($sentimentScore * 0.20) +
            ($pendingScore * 0.15);

        return round($finalRiskScore, 2);
    }
}
```

### Store Result in cmp_ai_insights

``` 
DB::table('cmp_ai_insights')->updateOrInsert(
    ['complaint_id' => $complaintId],
    [
        'escalation_risk_score' => $riskScore,
        'updated_at' => now()
    ]
);
```

### Chart Interpretation (Your Report)

**Heatmap**
 - X-Axis: Target Name
 - Y-Axis: Complaint Category
 - Color Intensity: total_complaints × avg_risk_score

**Scatter Plot**
 - X-Axis: Complaint Count
 - Y-Axis: Avg Risk Score
 - Bubble Size: Unique Complainants


 
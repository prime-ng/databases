<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class ComplaintAIInsightEngine
{
    /* =========================================================
       PUBLIC ENTRY POINT
    ========================================================= */

    public function processComplaint(int $complaintId): void
    {
        $complaint = $this->loadComplaint($complaintId);
        if (!$complaint) {
            return;
        }

        $riskScore = $this->calculateOverallRisk($complaint);
        $escalationScore = $this->calculateEscalationRisk($complaint);
        $safetyScore = $this->calculateSafetyRisk($complaint);
        $predictedCategory = $this->predictCategory($complaint);

        DB::table('cmp_ai_insights')->updateOrInsert(
            ['complaint_id' => $complaintId],
            [
                'risk_score' => $riskScore,
                'escalation_risk_score' => $escalationScore,
                'safety_risk_score' => $safetyScore,
                'predicted_category_id' => $predictedCategory,
                'updated_at' => now()
            ]
        );
    }

    /* =========================================================
       LOAD BASE COMPLAINT CONTEXT
    ========================================================= */

    private function loadComplaint(int $id)
    {
        return DB::table('cmp_complaints as c')
            ->leftJoin('sys_dropdown_table as sev', 'sev.id', '=', 'c.severity_id')
            ->leftJoin('cmp_ai_insights as ai', 'ai.complaint_id', '=', 'c.id')
            ->where('c.id', $id)
            ->select(
                'c.id',
                'c.description',
                'c.category_id',
                'c.target_user_type_id',
                'c.target_selected_id',
                'c.created_at',
                'sev.value as severity',
                'ai.sentiment_score'
            )
            ->first();
    }

    /* =========================================================
       1️⃣ OVERALL RISK SCORE (0–100)
       Used for Hotspot & Cluster reports
    ========================================================= */

    private function calculateOverallRisk($c): float
    {
        $severity = $this->severityScore($c->severity);
        $frequency = $this->frequencyScore($c->target_selected_id);
        $sentiment = $this->sentimentScore($c->sentiment_score);
        $pending = $this->pendingScore($c->created_at);

        return round(
            ($severity * 0.30) +
            ($frequency * 0.30) +
            ($sentiment * 0.25) +
            ($pending * 0.15),
            2
        );
    }

    /* =========================================================
       2️⃣ ESCALATION RISK SCORE (0–100)
       Management / Legal Escalation Probability
    ========================================================= */

    private function calculateEscalationRisk($c): float
    {
        $severity = $this->severityScore($c->severity);
        $frequency = $this->frequencyScore($c->target_selected_id);
        $sentiment = $this->sentimentScore($c->sentiment_score);
        $pending = $this->pendingScore($c->created_at);

        return round(
            ($severity * 0.35) +
            ($frequency * 0.30) +
            ($sentiment * 0.20) +
            ($pending * 0.15),
            2
        );
    }

    /* =========================================================
       3️⃣ SAFETY RISK SCORE (0–100)
       Child / Physical Safety Indicator
    ========================================================= */

    private function calculateSafetyRisk($c): float
    {
        $keywords = [
            'accident' => 90,
            'injury' => 95,
            'unsafe' => 85,
            'violence' => 100,
            'bully' => 80,
            'harassment' => 90,
            'rash driving' => 95,
            'abuse' => 90,
            'threat' => 85
        ];

        $textScore = 0;
        foreach ($keywords as $word => $score) {
            if (stripos($c->description, $word) !== false) {
                $textScore = max($textScore, $score);
            }
        }

        $severityBoost = match ($c->severity) {
            'Critical' => 30,
            'High' => 20,
            'Medium' => 10,
            default => 0
        };

        return min(100, $textScore + $severityBoost);
    }

    /* =========================================================
       4️⃣ PREDICTED CATEGORY (RULE-BASED AI)
    ========================================================= */

    private function predictCategory($c): ?int
    {
        $rules = [
            'Transport Safety' => ['bus', 'driver', 'route', 'accident', 'rash'],
            'Teacher Behaviour' => ['teacher', 'rude', 'punish', 'behavior'],
            'Bullying' => ['bully', 'harass', 'tease'],
            'Infrastructure' => ['washroom', 'water', 'fan', 'electricity'],
            'Fee & Accounts' => ['fee', 'payment', 'refund']
        ];

        foreach ($rules as $categoryName => $keywords) {
            foreach ($keywords as $word) {
                if (stripos($c->description, $word) !== false) {
                    return DB::table('cmp_complaint_categories')
                        ->where('name', $categoryName)
                        ->value('id');
                }
            }
        }

        return $c->category_id; // fallback
    }

    /* =========================================================
       🔹 COMMON SCORING HELPERS
    ========================================================= */

    private function severityScore(?string $severity): int
    {
        return match ($severity) {
            'Critical' => 100,
            'High' => 80,
            'Medium' => 50,
            default => 20
        };
    }

    private function frequencyScore($targetId): int
    {
        if (!$targetId)
            return 0;

        $count = DB::table('cmp_complaints')
            ->where('target_selected_id', $targetId)
            ->count();

        return min(100, $count * 20);
    }

    private function sentimentScore($sentiment): int
    {
        if (is_null($sentiment))
            return 50;

        // Convert -1 → +1 into 0 → 100
        return (int) ((($sentiment + 1) / 2) * 100);
    }

    private function pendingScore($createdAt): int
    {
        $days = Carbon::parse($createdAt)->diffInDays(now());
        return min(100, $days * 5);
    }
}

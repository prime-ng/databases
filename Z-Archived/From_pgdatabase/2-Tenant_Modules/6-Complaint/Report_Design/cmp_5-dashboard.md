# Complaint Management Module - Dashboard Design (Deliverable E)

**Route:** `/operations/complaints/dashboard`

## 1. Executive Summary Dashboard

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  PRIME ERP  |  OPERATIONS  |  COMPLAINTS DASHBOARD                                    [User Profile]   │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Period: [ This Month ▼ ]   Department: [ All ▼ ]                                                      │
│                                                                                                        │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐  ┌─────────────────────┐ │
│  │ OPEN TICKETS         │  │ RESOLVED (AVG TIME)  │  │ SLA BREACHES         │  │ CUST. SATISFACTION  │ │
│  │ 12                   │  │ 4.2 Hours            │  │ 3                    │  │ ⭐ 4.5/5            │ │
│  │ ▲ 2 New today        │  │ ▼ 10% faster         │  │ (Critical)           │  │ Based on 50 fb      │ │
│  └──────────────────────┘  └──────────────────────┘  └──────────────────────┘  └─────────────────────┘ │
│                                                                                                        │
│  ┌──────────────────────────────────────────────┐  ┌─────────────────────────────────────────────────┐ │
│  │  TICKETS BY CATEGORY (Pareto Chart)          │  │  RECENT CRITICAL TICKETS                        │ │
│  │                                              │  │  ┌───────────────────────────────────────────┐  │ │
│  │    █ Transport (40%)                         │  │  │ #101 | Rash Driving | OPEN | ⚠️ -2h     |  │ │
│  │    █ Food (30%)                              │  │  │ #105 | Food Hygiene | OPEN | 4h left    |  │ │
│  │    █ Academics (20%)                         │  │  │ #109 | Staff Rude   | W.I.P| 12h left   |  │ │
│  │    █ Other (10%)                             │  │  └───────────────────────────────────────────┘  │ │
│  │                                              │  │  [View All Critical >]                          │ │
│  └──────────────────────────────────────────────┘  └─────────────────────────────────────────────────┘ │
│                                                                                                        │
│  ┌───────────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │  ⚠️ ESCALATION MATRIX HEATMAP                                                                     │ │
│  │  [L1 Manager: 80% Load]  [L2 Principal: 2 Tickets]  [L3 Director: 0 Tickets]                      │ │
│  │  Action: L1 Manager has 5 tickets approaching breach in < 2 hours. [Re-Assign Work]               │ │
│  └───────────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                                        │
│  ┌──────────────────────────────────────────────┐  ┌─────────────────────────────────────────────────┐ │
│  │  AI RISK PREDICTION                          │  │  SENTIMENT TREND (Last 30 Days)                 │ │
│  │  Tickets with >80% Escalation Probability    │  │       /```\      (Positive)                     │ │
│  │  1. CMP-1045 (Safety) - 95% Risk             │  │      /     \                                    │ │
│  │  2. CMP-1050 (Exam)   - 82% Risk             │  │  ___/       \___ (Negative)                     │ │
│  └──────────────────────────────────────────────┘  └─────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```
**Actionable Insights:**
- **Heatmap**: Shows where the bottle neck is (e.g., L1 Manager is overloaded).
- **Proactive**: "AI Risk Prediction" lists tickets that *will* likely breach SLA based on historical patterns, prompting early intervention.

---

# Complaint Module — Business Logic Implementation Plan (Index)

## Purpose
Master index of all per-tab implementation plan files. Each tab below has its own `plan.md` with detailed gap analysis, current behavior, and step-by-step implementation instructions.

---

## Tab → Plan File Map

| Tab | Plan File | Key Gaps |
|-----|-----------|----------|
| **Categories** | `../Implementation-Plans/categories/plan.md` | FormRequests, missing unique index on `code`, DDL doc vs migration column names, change detection logging, tests |
| **SLA** | `../Implementation-Plans/sla/plan.md` | SLA override never used (P0), FormRequests, entity group notifications, tests |
| **Manage Complaints** | `../Implementation-Plans/complaints/plan.md` | resolution_due_at not computed (P0), escalation not persisted (P0), no notifications (P0), status FSM not enforced (P0), resolution validation missing (P0), FormRequests, permission bug, logAction raw DB, DDL doc column names, tests |
| **Medical Checks** | `../Implementation-Plans/medical-checks/plan.md` | FormRequests, is_medical_check_required not linked to workflow, tests |
| **Complaint Actions** | `../Implementation-Plans/complaint-actions/plan.md` | Controller is stub, logAction uses raw DB, tests |
| **AI Insights** | `../Implementation-Plans/ai-insights/plan.md` | Controller is stub, target frequency not in risk formula, ML microservice deferred, tests |
| **Dashboard & Reports** | `../Implementation-Plans/dashboard-reports/plan.md` | Dashboard controller is stub, AJAX endpoints need verification, SLA report accuracy, tests |
| **Cross-Cutting** | `../Implementation-Plans/cross-cutting/plan.md` | FormRequests (all tabs), 7 existing migrations (add unique index on code), DDL doc alignment, tests, permission bug, logAction fix |

---

## Priority Summary

| Priority | Count | Key Items |
|----------|-------|-----------|
| **P0** | 6 | SLA override, resolution_due_at, escalation persistence, notifications, status FSM, resolution validation |
| **P1** | 4 | FormRequests, stub controllers, logAction, tests, permission bug, unique index on code, DDL doc sync |
| **P2** | 3 | Target frequency, medical check workflow, frontend verification |

---

## Suggested Sprint Plan

| Sprint | Focus | Tabs Involved |
|--------|-------|---------------|
| 1 | Core Integrity (P0) | Complaints + Cross-Cutting |
| 2 | SLA & Escalation Engine (P0) | SLA + Complaints |
| 3 | Data Integrity | Cross-Cutting (unique index, DDL doc sync) |
| 4 | Completeness | All tabs (stubs, FormRequests, tests) |
| 5 | Enhancements (P2) | AI Insights + Medical Checks |

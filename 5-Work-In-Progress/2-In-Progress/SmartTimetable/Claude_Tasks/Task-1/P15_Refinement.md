# P15 — Manual Refinement (Swap/Move/Lock)

**Phase:** 8 | **Priority:** P2 | **Effort:** 4 days
**Skill:** Backend + Frontend | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** P07 (Phase 5 — Room Allocation)
**Reference:** `2026Mar10_GapAnalysis_and_CompletionPlan.md` GAP-5

---

## Pre-Requisites

Read before starting:
1. `Modules/SmartTimetable/app/Models/TimetableCell.php`
2. `Modules/SmartTimetable/app/Services/Constraints/ConstraintManager.php`

---

## Task 8.1 — Create RefinementService (2 days)

**File:** `Modules/SmartTimetable/app/Services/RefinementService.php` (NEW)

Implement 8 methods:

- `swapActivities($cellId1, $cellId2)` — swap two cells (validate constraints before swap, rollback if invalid)
- `moveActivity($cellId, $newDayId, $newPeriodId)` — move to new slot (validate first)
- `lockCell($cellId)` — set `is_locked = true` (prevent changes during regeneration)
- `unlockCell($cellId)` — set `is_locked = false`
- `getSwapCandidates($cellId)` — find valid swap targets (same class or same teacher, check constraints)
- `validateMove($cellId, $newSlot)` — check all hard constraints before allowing the move
- `getImpactAnalysis($cellId, $action)` — preview what would change (which constraints satisfied/violated)
- `logChange($cellId, $action, $oldState, $newState)` — audit trail record

**Key rules:**
- All swaps/moves must be validated against hard constraints before applying
- Locked cells cannot be swapped or moved
- Parallel group members must be moved together
- Log every change with user ID, timestamp, before/after state

---

## Task 8.2 — Create RefinementController (1 day)

**File:** `Modules/SmartTimetable/app/Http/Controllers/RefinementController.php` (NEW)

Endpoints:
- `POST /refinement/swap` → swap two cells (Gate: `smart-timetable.timetable.update`)
- `POST /refinement/move` → move a cell (Gate: `smart-timetable.timetable.update`)
- `POST /refinement/lock` → lock/unlock cell (Gate: `smart-timetable.timetable.update`)
- `GET /refinement/candidates/{cellId}` → JSON: swap candidates (Gate: `smart-timetable.timetable.view`)
- `GET /refinement/impact/{cellId}` → JSON: impact preview (Gate: `smart-timetable.timetable.view`)

Add routes in `tenant.php`.

---

## Task 8.3 — Create refinement UI (1 day)

**Skill: Frontend**

- Drag-and-drop on timetable grid (Alpine.js + fetch API)
- Right-click context menu (Swap, Move, Lock/Unlock)
- Impact preview modal before confirming move
- Locked cells shown with lock icon + grey background
- Success/error toast notifications

---

## Post-Execution Checklist

1. Run: `/lint` and `/test SmartTimetable`
2. Update AI Brain: `progress.md` → Phase 8 done, `known-issues.md` → GAP-5 RESOLVED

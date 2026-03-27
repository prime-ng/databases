# P17 — API & Async Generation

**Phase:** 10 | **Priority:** P2 | **Effort:** 3 days
**Skill:** Backend + Frontend | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** P07 (Phase 5 — Room Allocation)

---

## Pre-Requisites

Read before starting:
1. `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` — `generateWithFET()` method
2. `Modules/SmartTimetable/app/Models/GenerationRun.php` — if exists
3. `routes/api.php` or `Modules/SmartTimetable/routes/api.php`

---

## Task 10.1 — Create TimetableApiController (1 day)

**File:** `Modules/SmartTimetable/app/Http/Controllers/Api/TimetableApiController.php` (NEW)

REST endpoints:
- `GET /api/v1/timetable/{id}` → full timetable JSON
- `GET /api/v1/timetable/{id}/class/{classId}` → class-filtered timetable
- `GET /api/v1/timetable/{id}/teacher/{teacherId}` → teacher-filtered timetable
- `GET /api/v1/timetable/{id}/room/{roomId}` → room-filtered timetable
- `POST /api/v1/timetable/generate` → trigger async generation (returns jobId)
- `GET /api/v1/timetable/generate/{jobId}/status` → poll status

All endpoints use `auth:sanctum` middleware.

Register in `Modules/SmartTimetable/routes/api.php`.

---

## Task 10.2 — Create GenerateTimetableJob (1 day)

**File:** `Modules/SmartTimetable/app/Jobs/GenerateTimetableJob.php` (NEW)

Move generation logic from controller to a queueable job:
- Accept: `$academicSessionId`, `$config`, `$userId`
- Create/update `tt_generation_runs` record with `status`, `progress_json`
- Execute FETSolver
- Update progress at each stage: "Loading data" → "Ordering" → "Backtracking" → "Greedy" → "Room allocation" → "Storing"
- Store result (success/failure) in generation run record
- Handle timeout and failures gracefully

---

## Task 10.3 — Status polling endpoint (0.5 day)

Return `GenerationRun` status with:
- `status`: pending/running/completed/failed
- `progress_pct`: 0-100
- `current_stage`: string
- `eta_seconds`: estimated time remaining
- `result`: null until complete, then summary

---

## Task 10.4 — Frontend progress indicator (0.5 day)

**Skill: Frontend**

Alpine.js polling component:
- Shows progress bar during generation
- Polls `/api/v1/timetable/generate/{jobId}/status` every 2 seconds
- Displays current stage name
- Auto-redirects to timetable view on completion

---

## Post-Execution Checklist

1. Run: `/lint` and `/test SmartTimetable`
2. Run: `php artisan route:list --path=api/v1/timetable`
3. Update AI Brain: `progress.md` → Phase 10 done

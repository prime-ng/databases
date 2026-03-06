# Session Archive — SmartTimetable Stage 8: Substitution Management
**Date:** 2026-03-03
**Branch:** `Brijesh-timetable`
**Module:** `Modules/SmartTimetable`
**Preceded by:** `2026-03-03_smart_timetable_stage7.md`

---

## Objective

Implement Stage 8 — Substitution Management:
- 8.1 Teacher Absence recording + approval workflow
- 8.2 Affected Cell Identification
- 8.3 Substitute Teacher Finder (auto-suggest, score-based)
- 8.4 Substitution Assignment + pattern learning
- 8.5 Substitution Tracking Dashboard

---

## Prompts Used

1. `Archive this session then continue with Stage 8`

---

## AI Response Summary

### Models Read Before Implementation

| Model | Table | Key notes |
|---|---|---|
| `TeacherAbsences` | `tt_teacher_absences` | Types: LEAVE/SICK/TRAINING/OFFICIAL_DUTY/OTHER. Statuses: PENDING/APPROVED/REJECTED/CANCELLED. Has `approve()`, `reject()`, `markSubstitutionCompleted()`, `affectsPeriod()`. Scopes: `approved()`, `pending()`, `onDate()`, `needsSubstitution()` |
| `SubstitutionLog` | `tt_substitution_logs` | Methods: `AUTO/MANUAL/SWAP`. Statuses: ASSIGNED/COMPLETED/CANCELLED. Has `markNotified()`, `accept()`, `complete()`, `cancel()`. Has `teacher_absence_id`, `cell_id`, `absent_teacher_id`, `substitute_teacher_id`, `effectiveness_rating`, `recommendation_id` |
| `SubstitutionPattern` | `tt_substitution_patterns` | `success_rate` is GENERATED column — excluded from fillable. Fields: `confidence_score`, `total_count`, `success_count`, `avg_effectiveness_rating`. Note: model uses `SchTeacher` class (may be wrong — use `Teacher` in service). |
| `SubstitutionRecommendation` | `tt_substitution_recommendations` | Statuses: PENDING/ACCEPTED/REJECTED. Linked to absence + cell. Scored with `recommendation_score` + `ranking` |

---

## Files Created

### `app/Services/SubstitutionService.php`

Central engine. All methods documented below. `php -l` ✅ CLEAN.

| Method | Phase | Purpose |
|---|---|---|
| `recordAbsence(data[], userId): TeacherAbsences` | 8.1 | Creates absence record with PENDING status |
| `approveAbsence(absence, timetable, userId)` | 8.1 | Calls `absence->approve()` + calls `findAffectedCells()` + `generateRecommendations()` per cell |
| `rejectAbsence(absence, userId)` | 8.1 | Calls `absence->reject()` |
| `findAffectedCells(absence, timetable): Collection` | 8.2 | Converts `absence_date` to `day_of_week` via PHP `N` format (1=Mon). Queries cells where teacher is assigned, filtered by period range if not full-day |
| `findSubstitutes(absence, cell): array` | 8.3 | Scores candidates 0-100: Subject match (40pts) + Historical pattern × confidence (25pts) + Day availability (20pts) + Workload balance (15pts). Excludes teachers busy at same period. Returns top 10 sorted desc. |
| `assignSubstitute(absence, cell, substituteId, userId, method, recId?): SubstitutionLog` | 8.4 | Creates SubstitutionLog + inserts into `tt_timetable_cell_teachers` with `is_substitute=true`. Marks recommendation ACCEPTED if from recommendation. Calls `checkAndMarkCompleted()`. |
| `completeSubstitution(log, feedback, rating)` | 8.4 | Marks COMPLETED + calls `updatePattern()` for learning |
| `cancelSubstitution(log, reason)` | 8.4 | Removes substitute from `tt_timetable_cell_teachers` pivot, marks CANCELLED |
| `getDashboardData(timetable, ?date): array` | 8.5 | Returns: todayAbsences, pendingApprovals, todayLogs, stats (total/completed/assigned/cancelled/avg_rating), trendLabels (7-day), needsCoverage |

**Private helpers:**
- `generateRecommendations(absence, cell)` — clears old recs, calls `findSubstitutes()`, creates `SubstitutionRecommendation` records with ranking
- `updatePattern(SubstitutionLog)` — upserts `tt_substitution_patterns` after completion: running average for effectiveness, confidence = success/total × 100
- `checkAndMarkCompleted(absence, timetableId)` — marks `substitution_completed=true` when all cells covered

**Scoring algorithm details:**
1. **Subject match (40 pts)** — checks if teacher has any ActivityTeacher record for same `subject_study_format_id`
2. **Historical pattern (25 pts × confidence/100)** — reads SubstitutionPattern where original=absent teacher, substitute=candidate
3. **Day availability (20 pts)** — checks `tt_teacher_availability` for `day_of_week` + `is_available=true`
4. **Workload balance (15 pts)** — inversely proportional: `15 × (1 - currentPeriods/maxPeriods)`

---

### `app/Http/Controllers/SubstitutionController.php`

Constructor injects `SubstitutionService`. `php -l` ✅ CLEAN.

| Method | Route | Phase |
|---|---|---|
| `dashboard(Request, Timetable)` | GET …/dashboard | 8.5 |
| `absences(Timetable)` | GET …/absences | 8.1 |
| `recordAbsence(Request, Timetable)` | POST …/absences | 8.1 |
| `approveAbsence(Timetable, TeacherAbsences)` | POST …/absences/{absence}/approve | 8.1 |
| `rejectAbsence(Timetable, TeacherAbsences)` | POST …/absences/{absence}/reject | 8.1 |
| `cells(Timetable, TeacherAbsences)` | GET …/absences/{absence}/cells | 8.2 |
| `findSubstitutes(Timetable, TeacherAbsences, TimetableCell)` | GET …/cells/{cell}/find | 8.3 |
| `assignSubstitute(Request, Timetable, TeacherAbsences, TimetableCell)` | POST …/cells/{cell}/assign | 8.4 |
| `completeSubstitution(Request, Timetable, SubstitutionLog)` | POST …/logs/{log}/complete | 8.4 |
| `cancelSubstitution(Request, Timetable, SubstitutionLog)` | POST …/logs/{log}/cancel | 8.4 |
| `history(Timetable)` | GET …/history | 8.5 |

---

### Views (4 files)

| View | Purpose |
|---|---|
| `substitution/dashboard.blade.php` | Summary cards (absences today, pending approvals, completed all-time, avg rating), "Needs Coverage" panel with direct Assign links, Today's Substitutions panel with inline complete form, 7-day absence trend bar chart (Chart.js CDN) |
| `substitution/index.blade.php` | Collapsible "Record Absence" form (teacher, date, type, period range, reason, sub required), paginated absences table with Approve/Reject/Assign buttons per status |
| `substitution/cells.blade.php` | Absence summary banner, one card per affected cell showing: ranked recommendations with Assign button, manual override select, complete/cancel form for assigned logs |
| `substitution/history.blade.php` | Paginated full history table — date, subject/class/period, absent teacher, substitute, method, status, rating, assigned by |

---

## Decisions Taken

1. **Auto-generate recommendations on approval** — `approveAbsence()` calls `generateRecommendations()` for every affected cell automatically; user sees ranked list immediately in cells view.
2. **Score-based candidate ranking** — 4-factor score (subject/pattern/availability/workload) keeps logic in service layer; JSON endpoint `findSubstitutes` allows on-demand refresh.
3. **Pattern learning** — triggered only on `completeSubstitution()`, not on assign; requires effectiveness rating for meaningful confidence updating.
4. **is_substitute flag** — substitute teacher added to `tt_timetable_cell_teachers` with `is_substitute=true`, keeping original teacher in place for audit. `cancelSubstitution()` only removes substitute rows.
5. **Route group prefix** — `smart-timetable/substitution/{timetable}`, name prefix `smart-timetable.substitution.*`.
6. **No separate notification service** — `notified_at` field can be set via `markNotified()` on SubstitutionLog; actual notification dispatch left for future integration with school's notification system.

---

## Modified Files

| File | Change |
|---|---|
| `routes/tenant.php` | Added `use SubstitutionController` import + 11 substitution routes in dedicated prefix group |

---

## Route Summary

```
GET  /smart-timetable/substitution/{timetable}/dashboard                           smart-timetable.substitution.dashboard
GET  /smart-timetable/substitution/{timetable}/absences                            smart-timetable.substitution.absences
POST /smart-timetable/substitution/{timetable}/absences                            smart-timetable.substitution.record
POST /smart-timetable/substitution/{timetable}/absences/{absence}/approve          smart-timetable.substitution.approve
POST /smart-timetable/substitution/{timetable}/absences/{absence}/reject           smart-timetable.substitution.reject
GET  /smart-timetable/substitution/{timetable}/absences/{absence}/cells            smart-timetable.substitution.cells
GET  /smart-timetable/substitution/{timetable}/absences/{absence}/cells/{cell}/find smart-timetable.substitution.find-substitutes
POST /smart-timetable/substitution/{timetable}/absences/{absence}/cells/{cell}/assign smart-timetable.substitution.assign
POST /smart-timetable/substitution/{timetable}/logs/{log}/complete                 smart-timetable.substitution.complete
POST /smart-timetable/substitution/{timetable}/logs/{log}/cancel                  smart-timetable.substitution.cancel
GET  /smart-timetable/substitution/{timetable}/history                             smart-timetable.substitution.history
```

---

## Next Steps — Stage 9: API & Integration

| # | Task | Details |
|---|------|---------|
| 9.1 | API endpoints for generation, preview, validation | `routes/api.php` |
| 9.2 | API endpoints for reports & analytics | `routes/api.php` |
| 9.3 | API endpoints for substitution management | `routes/api.php` |
| 9.4 | Standard Timetable views (8 screens from design docs) | New Blade templates |

### Notes before starting Stage 9:
- Check if `routes/api.php` already has SmartTimetable routes
- Check if an API controller exists (SmartTimetableApiController?)
- Standard timetable screens: `databases/2-Tenant_Modules/8-Standard_Timetable/Design/Scr-*.md`

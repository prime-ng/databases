# STP — Recommendations (stp_Recommendations)

## 1. Module Code
`stp_Recommendations` — StudentPortal Recommendations Feature

## 2. Feature Name
Recommendations / My Recommendations

## 3. Feature Description
Provides a dashboard listing study recommendations for students, triggered by quiz/quest performance (auto-generated) or assigned manually by teachers. Students can filter recommendations by source (All, Quiz-triggered, Quest-triggered, Manual), view full details with automatic status transitions (PENDING → VIEWED), update their progress status (VIEWED, IN_PROGRESS, COMPLETED), and rate materials with 1-5 star ratings and optional feedback. Class-level recommendations are automatically synced to individual students.

## 4. FRD Reference / REQ Mapping
| REQ-ID | Priority | Description |
|--------|----------|-------------|
| REQ-STP-017 | P1 | Recommendations List + Detail — View, update status, rate materials |
| BR-STP-001 | — | Student data must belong to authenticated student (enforced via student context) |

## 5. Route Structure

| # | Method | URI | Action | Name |
|---|--------|-----|--------|------|
| 1 | GET | `/my-recommendations` | `StudentRecommendationPortalController@index` | `my-recommendations.index` |
| 2 | GET | `/my-recommendations/{id}` | `StudentRecommendationPortalController@show` | `my-recommendations.show` |
| 3 | POST | `/my-recommendations/{id}/status` | `StudentRecommendationPortalController@updateStatus` | `my-recommendations.status` |
| 4 | POST | `/my-recommendations/{id}/rate` | `StudentRecommendationPortalController@addRating` | `my-recommendations.rate` |

## 6. Database Tables Involved
| Table | Type | Purpose |
|-------|------|---------|
| `rec_student_recommendations` | Write | Core recommendation record (student_id, material_id, status, rating, feedback) |
| `rec_recommendation_materials` | Read | Recommendation material details (title, type, subject, topic, purpose) |
| `rec_material_types` | Read | Material type (Video, Document, etc.) |
| `rec_recommendation_purposes` | Read | Purpose of recommendation (e.g., Remedial study) |
| `rec_recommendation_bundles` | Read | Bundle grouping for recommendations |
| `rec_recommendation_bundle_materials` | Read | Materials within a bundle |
| `rec_recommendation_rules` | Read | Trigger rules for auto-generated recommendations |
| `rec_trigger_events` | Read | Event types that trigger recommendations |
| `sch_subjects` | Read | Subject reference for material |
| `sch_topics` | Read | Topic reference for material |
| `sch_classes` | Read | Class reference for material allocation |
| `sch_sections` | Read | Section reference for material allocation |
| `std_students` | Read | Student identity for context resolution |

## 7. Finite State Machine (FSM)

### Recommendation Status Transitions (Student-initiated)

| From State | Event | Guard | To State | Side Effects |
|-----------|-------|-------|---------|-------------|
| (new) | System assigns or teacher assigns | — | PENDING | Recommendation created with PENDING status |
| PENDING | Student views detail page (`show()`) | Auto-transition | VIEWED | `markAsViewed()` called automatically |
| PENDING | Student POSTs status = VIEWED | Status must be 'VIEWED' | VIEWED | Same as auto-transition |
| VIEWED | Student POSTs status = IN_PROGRESS | Status must be 'IN_PROGRESS' | IN_PROGRESS | `markAsInProgress()` called |
| IN_PROGRESS | Student POSTs status = COMPLETED | Status must be 'COMPLETED' | COMPLETED | `markAsCompleted()` called |

**Allowed student transitions:** PENDING → VIEWED, VIEWED → IN_PROGRESS, IN_PROGRESS → COMPLETED
**Illegal transitions:** Student cannot set REJECTED or any non-allowed status; COMPLETED → any other state (irreversible from student side)

## 8. Business Rules / Logic

### Source Filter Tabs
- **All**: All recommendations for the student (is_active = true)
- **Quiz-triggered**: `triggered_by_quiz_id` is not null
- **Quest-triggered**: `triggered_by_quest_id` is not null
- **Manual**: Both `triggered_by_quiz_id` AND `triggered_by_quest_id` are null

### Auto-Status Transition on Detail View
- When `show()` is called:
  - If recommendation status is PENDING, auto-calls `$rec->markAsViewed()`
  - No explicit confirmation from student needed

### Status Update Constraints
- Allowed statuses for student: `VIEWED`, `IN_PROGRESS`, `COMPLETED`
- Validation rule: `required|in:VIEWED,IN_PROGRESS,COMPLETED`
- `markAsViewed()`, `markAsInProgress()`, `markAsCompleted()` dispatched via match statement
- Recommendation ownership verified: `where('student_id', $studentId)->where('is_active', true)->findOrFail($id)`

### Rating
- Scale: 1 to 5 (integer)
- Validated: `required|integer|min:1|max:5`
- Optional feedback: `nullable|string|max:255`
- Stored via `$recommendation->addRating($rating, $feedback)`

### Class-Level Recommendation Sync
- `syncClassRecommendations()` called automatically on `index()` and `show()`
- Fetches `RecommendationMaterial` records where:
  - `class_id` matches student's current class
  - `section_id` is null OR matches student's current section
- Creates `StudentRecommendation` for each material that doesn't already exist for this student
- Failure is non-fatal (caught and logged)
- Sync runs on every page load of index/show

### Display Data
- Each recommendation card shows:
  - Material Name & Type (via `material.materialType`)
  - Purpose (via `material.purposeRef`)
  - Status badge: PENDING (Grey), VIEWED (Blue), IN_PROGRESS (Orange), COMPLETED (Green)
  - Subject and Topic name
  - Assigned Date

## 9. Input / Payload Specifications

### POST /my-recommendations/{id}/status
| Field | Type | Required | Validation | Description |
|-------|------|----------|-----------|-------------|
| `status` | string | Yes | `required|in:VIEWED,IN_PROGRESS,COMPLETED` | New status value |

### POST /my-recommendations/{id}/rate
| Field | Type | Required | Validation | Description |
|-------|------|----------|-----------|-------------|
| `rating` | integer | Yes | `required|integer|min:1|max:5` | Star rating (1-5) |
| `feedback` | string | No | `nullable|string|max:255` | Optional review comment |

## 10. Validation Rules

| Rule | Implementation | Error Handling |
|------|---------------|---------------|
| Status must be allowed value | `in:VIEWED,IN_PROGRESS,COMPLETED` | 422 validation error |
| Rating must be 1-5 | `min:1|max:5` | 422 validation error |
| Feedback max 255 chars | `max:255` | 422 validation error |
| Recommendation ownership | `where('student_id', $studentId)->findOrFail($id)` | 404 Not Found if not owned |
| Student profile existence | `abort_if(!$student, 403, ...)` | 403 Forbidden |

## 11. Error / Exception Handling

| Scenario | HTTP Code | Response |
|----------|-----------|----------|
| Missing student profile | 403 | `abort(403, 'Student profile not found.')` |
| Recommendation not found / not owned | 404 | `findOrFail()` — 404 Not Found |
| Invalid status value | 422 | Validation error message |
| Invalid rating value | 422 | Validation error message |
| Class sync failure | — | Logged as error; page loads normally without class recommendations |

## 12. Concurrency / Race Conditions

| Scenario | Mitigation |
|----------|-----------|
| Simultaneous status updates | Standard Eloquent update — last write wins (no explicit locking) |
| Class sync running concurrently | Check `exists()` before create prevents duplicates |
| Rate + status simultaneous | Both operations modify different columns — generally safe |

## 13. Role-Based Access / Permissions
- **Student**: Full access — list, view, update status, rate
- **Parent**: Not explicitly supported (no `ParentContextService` integration)
- **Teacher/Admin**: Assignment and management handled in Recommendation module

## 14. Screens / UI States

| Screen | Route | UI Elements |
|--------|-------|-------------|
| Recommendations List | GET /my-recommendations | Tab filters (All/Quiz/Quest/Manual), recommendation cards with type badge, purpose, status, subject, topic, date |
| Recommendation Detail | GET /my-recommendations/{id} | Full material details, bundle info, trigger info (quiz/quest/rule), status badge, rating form |
| Status Update | POST /my-recommendations/{id}/status | Status dropdown/buttons (VIEWED/IN_PROGRESS/COMPLETED) |
| Rating Form | POST /my-recommendations/{id}/rate | Star selector (1-5), optional feedback textarea |

## 15. API / Integration Points

| Integration | Direction | Mechanism |
|-------------|-----------|-----------|
| `QuizQuestResultPublished` event | Inbound | Listens for quiz/quest results → creates recommendations (handled by Recommendation module) |
| `RecommendationMaterial` model | Read | Material catalog with class/section targeting |
| `StudentRecommendation` model | Write | CRUD for recommendation assignments |
| `syncClassRecommendations()` | Internal | Auto-syncs class-level materials to student on page load |

## 16. Feature Status
- **V1:** Complete
- **V2:** Not started
- **Status:** Complete
- **CR:** ◌

---
*Generated from: `StudentRecommendationPortalController.php` (245 lines), `STP_FRD_Complete_2026-06-30.md`, `pgdatabase/Backup/4-Module_Requirement/StudentPortal/my_reports/recommendations.md`*

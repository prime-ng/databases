# Requirement Conditions Catalog — StandardTimetable (TTS)
**Module Code:** TTS | **Date:** 2026-06-30 | **Source:** `TTS_FRD_2026-06-30.md` / `TTS_FRD_Complete_2026-06-30.md`

> This file is the Requirement Conditions Catalog for the StandardTimetable module.
> It is extracted from Section 3B of the Complete Analysis Pack (`TTS_FRD_Complete_2026-06-30.md`).
> All REQ-/BR-IDs reference `TTS_FRD_2026-06-30.md`.

---

## Condition Table

| Condition ID | Entity / Field | Condition (business language) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|-------------------------------|------|---------|------------------------|
| BR-TTS-001 | Manual Timetable — generation type | Timetable must be designated as Manual (not AI-generated) before cells can be added or removed | Permission | placeCell, removeCell | HTTP 422 "This action is only available for manually-built timetables" |
| BR-TTS-002 | Timetable — status | Only Published timetables appear in read view selectors | Workflow | Read view selector | No Published timetable → "No published timetable found" message with link to placement screen |
| BR-TTS-003 | Cell — lock status | Locked cells refuse removal | Validation | removeCell | HTTP 422 "Cell is locked. Unlock it before removing." |
| BR-TTS-004 | Timetable — status | Published timetables refuse all cell mutations | Workflow | placeCell, removeCell, lockCell, unlockCell | HTTP 422 "Published timetables are read-only" |
| BR-TTS-005 | Timetable — type + term + status | Only one Published timetable per Timetable Type and Academic Term combination | Validation | Publish action | Prompt: "A published timetable already exists for this type and term. Archive it and publish this one?" → proceed on confirm |
| BR-TTS-006 | Timetable — status | Deletion only permitted for Draft status | Validation | deleteTimetable | HTTP 422 "Cannot delete a timetable that is not in Draft status" |
| BR-TTS-007a | Teacher assignment — slot collision | Teacher assigned to another cell at the same day and period within this timetable | Calculation | placeCell conflict check | Warning (TEACHER_CONFLICT) — placement proceeds; cell marked with conflict flag |
| BR-TTS-007b | Teacher assignment — cross-timetable slot collision | Teacher assigned in another active timetable at the same day and period (same term) | Calculation | placeCell conflict check | Warning (TEACHER_CROSS_TT) — placement proceeds; cell marked |
| BR-TTS-007c | Room — slot collision within timetable | Room already booked in this timetable at the same day and period | Calculation | placeCell conflict check | Warning (ROOM_CONFLICT) — placement proceeds; cell marked |
| BR-TTS-007d | Room — cross-timetable slot collision | Room already booked in a different active timetable at the same day and period (same term) | Calculation | placeCell conflict check | Warning (ROOM_CROSS_TT) — placement proceeds; cell marked |
| BR-TTS-007e | Class — double-booking at same slot | The same class already has a different activity at this day and period | Calculation | placeCell conflict check | Warning (CLASS_DOUBLE_BOOKING) — new activity replaces existing; cell marked |
| BR-TTS-008 | Period type — break flag | Break periods and lunch periods refuse cell placements | Validation | placeCell — period type check | HTTP 422 "Break periods cannot be scheduled" |
| BR-TTS-009 | Cell mutation — audit | Every placement, removal, lock, and unlock records an audit entry | Workflow | All cell mutation endpoints | Write failure: log error and continue (non-blocking — audit must not abort the primary operation) |
| BR-TTS-010 | Activity — weekly periods needed vs placed | Palette counter = total weekly periods needed − currently placed count | Calculation | After each placeCell and removeCell | Update counter in AJAX response; mark activity as "fully placed" when remaining = 0 |
| BR-TTS-011 | Copy — source timetable status | Source timetable status unchanged after copy | Workflow | copyTimetable | Source timetable remains in its original status; all changes are to the new copy only |
| BR-TTS-013 | Teacher-wise view — requesting user's role | Teacher-role users may only view their own schedule | Permission | teacherView request | HTTP 403 if teacher_id parameter does not match the requesting user's linked teacher record |
| BR-TTS-014 | Period type — is_break flag | Break/lunch period cells cannot receive placements | Validation | placeCell | HTTP 422 "This period is designated as a break and cannot be scheduled" |
| BR-TTS-015 | Conflict — teacher name extraction | Teacher name must be retrieved via teacher FK column (`teacher_id`), not pivot primary key (`id`) | Validation | checkConflicts() teacher post-load filter | Bug fix required: change filter from `->whereIn('id', $teacherIds)` to `->whereIn('teacher_id', $teacherIds)` |

---

## Validation and Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary Case | Empty / Null Case | Concurrency Case | Expected Behaviour |
|-------------|--------------|-----------------|---------------|-------------------|------------------|--------------------|
| Timetable Name | "Term 1 Regular 2026" | "" (blank) | 200 characters exactly | Blank → validation error "Name is required" | Two admins create with same name simultaneously | Allow — names are not unique; code field provides uniqueness |
| Academic Term selection | Existing active term | Deleted term ID | First day of term | No terms → "No academic terms available" | — | Validate term exists before creation |
| Timetable Type selection | Existing active type | Inactive type ID | Single type exists | No types → "No timetable types configured" | — | Validate type is active |
| Period Set resolution | Type + term both have Period Set | Type exists but no Period Set | Type has Period Set but not for selected term — fall back to type-only match | No Period Set for type or term → HTTP 422 with setup link | — | Fall back to type-only match; if still none, return error |
| Cell placement — day_of_week | 1 to 6 (Mon–Sat) | 0 or 7 | 1 (first day) and 6 (last day) | Null → validation error | — | Reject values outside configured school days range |
| Cell placement — period_ord | 1 to N | 0 or N+1 | 1 and N | Null → validation error | — | Reject ordinals not in the Period Set |
| Activity existence | Active activity for selected class-section | Activity from different class-section | Last active activity for a class | Class-section has no activities → empty palette with prompt | — | Empty palette with "Add activities via Timetable Foundation" |
| Room conflict (null room_id) | Activity has a required room | Activity has no room configured | Activity with required_room_id = null | Null room → skip room conflict checks | — | If no room configured, omit room conflict checks entirely |
| Locked cell removal | Unlocked cell — removal succeeds | Locked cell — removal refused | Cell locked 1 second before removal attempt | No cell at that slot → return success (idempotent) | Two users both attempt remove on locked cell | HTTP 422 "Cell is locked"; both users see rejection |
| Break period placement | Regular teaching period | Break period (is_break=1) | Period immediately before a break | No is_break check implemented yet → placement accepted (current bug) | — | HTTP 422 "Break periods cannot be scheduled" (once implemented) |
| Deletion of Published timetable | Draft timetable → deletion succeeds | Published timetable → deletion refused | Timetable has 0 cells — deletion still transactional | Timetable ID not found → HTTP 404 | Two admins both try to delete same Draft timetable | First succeeds; second receives HTTP 404 |
| Conflict teacher name (BR-015) | Correct: teacher_id filter → teacher name shown | Bug: id filter → empty teacher name | Teacher deleted after assignment — name becomes unavailable | No teachers assigned → skip teacher conflict checks | — | Fix filter; handle null name with fallback "Unknown Teacher" |
| Copy timetable — transaction failure | Source timetable exists and accessible | Source timetable deleted mid-copy | Source has 0 cells → copy creates empty Draft | Source timetable not found → HTTP 404 | Two concurrent copies of same source | Both succeed independently; no conflict |
| One-published rule on publish | No existing Published for same type+term → publish proceeds | Existing Published for same type+term → prompt to archive | Exact same timetable re-published → idempotent (already Published) | No prior Published → publish directly without prompt | Two admins both approve timetables for same type+term simultaneously | Use database transaction; second transaction receives conflict and prompt |

---

*TTS Conditions Catalog v1.0 — 2026-06-30*
*Full detail in: `TTS_FRD_Complete_2026-06-30.md` Section 3*

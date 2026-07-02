# Complete Analysis Pack — StandardTimetable (Manual Timetable Builder)
**Module Code:** TTS | **Date:** 2026-06-30 | **Version:** 1.0
**Sources:** V2 Requirement (2026-03-26, 1022 lines) · V1 Screen Specs (2 files) · Controller code (513 lines, 6 methods) · Module Knowledge (`STA_StandardTimetable.md`) · `tenant_db_v2.sql`
**FRD:** `TTS_FRD_2026-06-30.md` (sibling file — all REQ-/BR-/RPT-/ENH- IDs originate there)

---

## Table of Contents

1. [FRD Reference](#1-frd-reference)
2. [Requirements Traceability Matrix (RTM)](#2-requirements-traceability-matrix)
3. [Business Rules Register + Conditions Catalog + Validation & Edge-Case Catalog](#3-business-rules-conditions-and-validation)
4. [Process Flows + FSM Catalog](#4-process-flows-and-fsm)
5. [Data Dictionary + Cross-Module Dependency Map](#5-data-dictionary-and-dependency-map)
6. [NFR Catalog + Risk Register](#6-nfr-catalog-and-risk-register)
7. [Prioritization + Effort Estimation & Sprint Tasks](#7-prioritization-and-effort-estimation)
8. [User Stories + Acceptance Criteria + Reporting & KPI Spec](#8-user-stories-and-reporting-spec)
9. [Feature Specification (Screen-by-Screen)](#9-feature-specification)
10. [Module Knowledge Update](#10-module-knowledge-update)

---

## 1. FRD Reference

The Functional Requirements Document is the spine of this analysis pack. All IDs in subsequent sections refer to IDs defined in the FRD.

**FRD File:** `TTS_FRD_2026-06-30.md`
**Counts:** REQ: 14 | BR: 15 | RPT: 4 | ENH: 10
**Priority split:** P0=5 (REQ-001, 004, 005, 006, 013) | P1=7 (REQ-002, 003, 007, 008, 009, 010, 011) | P2=2 (REQ-012, 014)
**Overall completion:** ~15% (3 of 15 BRs fully enforced; 0 of 4 reports built; read views, publishing, copy, authorization, tests all absent)

---

## 2. Requirements Traceability Matrix

| REQ-ID | Feature | Priority | BR Refs | Screens | Workflows | Reports | Test File | Code Status | Gap Summary |
|--------|---------|:--------:|---------|---------|-----------|---------|-----------|:-----------:|-------------|
| REQ-TTS-001 | Manual Timetable Creation | P0 | BR-001, BR-006 | SCR-01 (Create modal within manual placement) | WF-1 | — | ManualPlacementTest | PARTIAL | Create works; no try/catch; no activityLog(); permission not seeded |
| REQ-TTS-002 | Copy Timetable | P1 | BR-011 | SCR-01 (Copy modal) | WF-3 | — | ManualPlacementTest | NOT STARTED | No endpoint, no route, no method |
| REQ-TTS-003 | Effective Dates and One-Published Rule | P1 | BR-005 | SCR-01 (publish prompt) | WF-2 | — | PublishWorkflowTest | NOT STARTED | No effective date fields in form; no one-published check |
| REQ-TTS-004 | Timetable Deletion Guard | P0 | BR-006 | SCR-01 (delete action) | WF-1 | — | ManualPlacementTest | PARTIAL | PUBLISHED blocked; GENERATED status not blocked (BR-006 gap) |
| REQ-TTS-005 | Drag-and-Drop Grid Editor | P0 | BR-001, BR-004, BR-008, BR-010, BR-014 | SCR-01 (main grid) | WF-1 | — | ManualPlacementTest | PARTIAL | placeCell/removeCell AJAX done; drag-drop JS not confirmed; context menu absent; break-period check absent |
| REQ-TTS-006 | Real-Time Conflict Detection | P0 | BR-007, BR-008 | SCR-01 (grid cell highlighting) | WF-1 | — | ConflictDetectionTest | PARTIAL | All 5 types implemented; BUG in teacher name extraction (BR-015); no term scope on cross-TT check |
| REQ-TTS-007 | Conflict Persistence and Batch Validate | P1 | BR-007 | SCR-01 (conflict badge + validate panel) | WF-1 | — | ManualPlacementTest | NOT STARTED | No conflict log writes; no batch validate endpoint; no conflict badge |
| REQ-TTS-008 | Standard Read Views | P1 | BR-002, BR-013 | SCR-02, SCR-03, SCR-04 | WF-4 | RPT-001, 002, 003 | StandardViewsTest | NOT STARTED | No routes, no controller methods, no Blade views |
| REQ-TTS-009 | Timetable Selector | P1 | — | SCR-01, 02, 03, 04 | WF-4 | — | StandardViewsTest | PARTIAL | Selector exists on manual placement; absent on read views |
| REQ-TTS-010 | Cell Lock and Unlock | P1 | BR-003 | SCR-01 (context menu lock action) | WF-1 | — | ManualPlacementTest | PARTIAL | removeCell respects lock; lock/unlock/lockAll endpoints absent |
| REQ-TTS-011 | Publishing Workflow | P1 | BR-004, BR-005 | SCR-01 (Submit button), (Principal approval screen) | WF-2 | — | PublishWorkflowTest | NOT STARTED | No submit, approve, publish endpoints; no notification sent |
| REQ-TTS-012 | Print and Export | P2 | — | SCR-02, 03, 04 (Print/CSV/PDF buttons) | WF-4 | RPT-001, 002, 003 | StandardViewsTest | NOT STARTED | No print CSS, no CSV export, no PDF export |
| REQ-TTS-013 | Role-Based Access Control | P0 | BR-012, BR-013 | All screens | All | — | AuthorizationTest | NOT STARTED | No Policy class; no seeded permissions; single blanket gate on all methods; no EnsureTenantHasModule |
| REQ-TTS-014 | Cell Audit Trail | P2 | BR-009 | SCR-08 (change log view) | WF-1 | RPT-004 | ManualPlacementTest | NOT STARTED | No change log writes; no change log viewer route or view |

**RTM Totals check:** 14 REQs traced | 15 BRs covered | 4 Reports covered | Tests: 0 of 5 planned files exist.

---

## 3. Business Rules, Conditions, and Validation

### 3A. Business Rules Register (Full)

| ID | Business Rule | Type | Trigger | Enforcement Point | Priority |
|----|--------------|------|---------|-------------------|----------|
| BR-TTS-001 | Only timetables designated as Manual may receive cell placements or removals | Permission | Every cell placement/removal | placeCell and removeCell endpoints | P0 |
| BR-TTS-002 | Read views display only Published timetables | Workflow | Read view page load | Class/teacher/room view controller methods | P1 |
| BR-TTS-003 | Locked cells refuse removal with a clear error | Validation | Remove-cell request on locked cell | removeCell endpoint — is_locked flag check | P1 |
| BR-TTS-004 | Published timetables are immutable — all cell changes refused | Workflow | Any write request when status = Published | All cell mutation endpoints | P1 |
| BR-TTS-005 | At most one Published timetable per Timetable Type + Academic Term | Validation | Publish action | Publishing endpoint; archive prior Published on confirmation | P1 |
| BR-TTS-006 | Deletion only permitted for Draft status timetables | Validation | Delete request | deleteTimetable endpoint — status guard | P0 |
| BR-TTS-007 | Conflict detection runs 5 checks: intra-TT teacher, cross-TT teacher, intra-TT room, cross-TT room, class double-booking | Calculation | Every cell placement | checkConflicts() private method | P0 |
| BR-TTS-008 | Conflicts are warnings (placement proceeds); break-period placement is a hard block | Workflow | checkConflicts() result + period type check | placeCell response handling | P0 |
| BR-TTS-009 | Every cell mutation (place/remove/lock/unlock) writes an audit record | Workflow | Each successful mutation | Audit trail writer invoked from all cell mutation methods | P2 |
| BR-TTS-010 | Activity palette counters recalculate after every place/remove | Calculation | AJAX placement/removal completion | placeCell and removeCell AJAX response data assembly | P0 |
| BR-TTS-011 | Copying a timetable creates a new Draft at version 1; source is unchanged | Workflow | Copy timetable action | copyTimetable endpoint; transaction commit | P1 |
| BR-TTS-012 | All data is isolated to the current school's database | Permission | Every database query | Platform tenancy infrastructure (stancl/tenancy) | P0 |
| BR-TTS-013 | Teacher-role users may only view their own schedule in teacher-wise view | Permission | Teacher-wise view request | teacherView controller method; teacher_id gate check | P1 |
| BR-TTS-014 | Break periods must reject cell placements with an error | Validation | Cell placement on a break-period slot | placeCell endpoint; period type is_break check | P1 |
| BR-TTS-015 | Conflict teacher name extraction must use the teacher FK column, not the pivot record primary key | Validation | Conflict message assembly | checkConflicts() — filter step after teacher cell query | P1 (bug fix) |

### 3B. Requirement Conditions Catalog

> This section also populates `{REQUIREMENT_CONDITIONS}/TTS_Conditions.md`.

| Condition ID | Entity / Field | Condition (business language) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|-------------------------------|------|---------|------------------------|
| BR-TTS-001 | Manual Timetable — generation type | Timetable must be designated as Manual (not AI-generated) before cells can be added or removed | Permission | placeCell, removeCell | HTTP 422 "This action is only available for manually-built timetables" |
| BR-TTS-002 | Timetable — status | Only Published timetables appear in read view selectors | Workflow | Read view selector | No Published timetable → "No published timetable found" message with link to placement screen |
| BR-TTS-003 | Cell — lock status | Locked cells refuse removal | Validation | removeCell | HTTP 422 "Cell is locked. Unlock it before removing." |
| BR-TTS-004 | Timetable — status | Published timetables refuse all cell mutations | Workflow | placeCell, removeCell, lockCell, unlockCell | HTTP 422 "Published timetables are read-only" |
| BR-TTS-005 | Timetable — type + term + status | Only one Published timetable per Timetable Type and Academic Term combination | Validation | Publish action | Prompt: "A published timetable already exists for this type and term. Archive it and publish this one?" → proceed on confirm |
| BR-TTS-006 | Timetable — status | Deletion only permitted for Draft status | Validation | deleteTimetable | HTTP 422 "Cannot delete a timetable that is not in Draft status" |
| BR-TTS-007a | Teacher assignment — slot collision | Teacher assigned to another cell at the same day and period within this timetable | Calculation | placeCell conflict check | Warning (TEACHER_CONFLICT) — placement proceeds; cell marked with conflict flag |
| BR-TTS-007b | Teacher assignment — cross-timetable slot collision | Teacher assigned in another active timetable at the same day and period | Calculation | placeCell conflict check | Warning (TEACHER_CROSS_TT) — placement proceeds; cell marked |
| BR-TTS-007c | Room — slot collision within timetable | Room already booked in this timetable at the same day and period | Calculation | placeCell conflict check | Warning (ROOM_CONFLICT) — placement proceeds; cell marked |
| BR-TTS-007d | Room — cross-timetable slot collision | Room already booked in a different active timetable at the same day and period | Calculation | placeCell conflict check | Warning (ROOM_CROSS_TT) — placement proceeds; cell marked |
| BR-TTS-007e | Class — double-booking at same slot | The same class already has a different activity at this day and period | Calculation | placeCell conflict check | Warning (CLASS_DOUBLE_BOOKING) — new activity replaces existing; cell marked |
| BR-TTS-008 | Period type — break flag | Break periods and lunch periods refuse cell placements | Validation | placeCell — period type check | HTTP 422 "Break periods cannot be scheduled" |
| BR-TTS-009 | Cell mutation — audit | Every placement, removal, lock, and unlock records an audit entry | Workflow | All cell mutation endpoints | Write failure: log error and continue (non-blocking — audit must not abort the primary operation) |
| BR-TTS-010 | Activity — weekly periods needed vs placed | Palette counter = total weekly periods needed − currently placed count | Calculation | After each placeCell and removeCell | Update counter in AJAX response; mark activity as "fully placed" when remaining = 0 |
| BR-TTS-011 | Copy — source timetable status | Source timetable status unchanged after copy | Workflow | copyTimetable | Source timetable remains in its original status; all changes are to the new copy only |
| BR-TTS-013 | Teacher-wise view — requesting user's role | Teacher-role users may only view their own schedule | Permission | teacherView request | HTTP 403 if teacher_id parameter does not match the requesting user's linked teacher record |
| BR-TTS-014 | Period type — is_break flag | Break/lunch period cells cannot receive placements | Validation | placeCell | HTTP 422 "This period is designated as a break and cannot be scheduled" |
| BR-TTS-015 | Conflict — teacher name extraction | Teacher name must be retrieved via teacher FK column, not pivot primary key | Validation | checkConflicts() teacher post-load filter | Bug fix required: change filter from `->whereIn('id', $teacherIds)` to `->whereIn('teacher_id', $teacherIds)` |

### 3C. Validation & Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary Case | Empty / Null Case | Concurrency Case | Expected Behaviour |
|-------------|--------------|-----------------|---------------|-------------------|------------------|--------------------|
| Timetable Name | "Term 1 Regular 2026" | "" (blank) | 200 characters exactly | Blank → validation error "Name is required" | Two admins create with same name simultaneously | Allow — names are not unique per tenant; code field (auto-generated) provides uniqueness |
| Academic Term selection | Existing active term | Deleted term ID | First day of term | No terms exist → error "No academic terms available" | — | Validate term exists before creation |
| Timetable Type selection | Existing active type | Inactive type ID | Single type exists | No types → error "No timetable types configured" | — | Validate type is active |
| Period Set resolution | Type + term both have a Period Set | Type exists but no Period Set linked | Type has Period Set but not for the selected term → fall back to type-only match | No Period Set for type or term → HTTP 422 with setup link | — | Fall back to type-only match; if still none, return error |
| Cell placement — day_of_week | 1 (Monday) to 6 (Saturday) | 0 or 7 | 1 (first day) and 6 (last day) | Null → validation error | — | Reject values outside configured school days range |
| Cell placement — period_ord | 1 to N (N = periods in set) | 0 or N+1 | 1 and N | Null → validation error | — | Reject ordinals not in the Period Set |
| Activity existence | Active activity for selected class-section | Activity from different class-section | Last active activity for a class | Class-section has no activities → empty palette | — | Empty palette with prompt: "Add activities via Timetable Foundation" |
| Room conflict (null room_id) | Activity has a required room | Activity has no room configured | Activity with required_room_id = null | Null room → skip room conflict checks | — | If no room configured for the activity, omit room conflict checks entirely |
| Locked cell removal | Unlocked cell — removal succeeds | Locked cell — removal refused | Cell locked 1 second before removal attempt | No cell at that slot → return success (idempotent) | Two users both attempt remove on locked cell | HTTP 422 "Cell is locked"; both users see rejection |
| Break period placement | Regular teaching period | Break period (is_break=1) | Period immediately before a break | No is_break check implemented yet → placement accepted (current bug) | — | HTTP 422 "Break periods cannot be scheduled" (once implemented) |
| Deletion of Published timetable | Draft timetable → deletion succeeds | Published timetable → deletion refused | Timetable has 0 cells — deletion still transactional | Timetable ID not found → HTTP 404 | Two admins both try to delete same Draft timetable | First succeeds; second receives HTTP 404 |
| Conflict teacher name (BR-015) | Correct: teacher_id filter → teacher name shown in conflict message | Bug: id filter → empty teacher name shown | Teacher deleted after assignment — name becomes unavailable | No teachers assigned to activity → skip teacher conflict checks | — | Fix filter; handle null name with fallback "Unknown Teacher" |
| Copy timetable — transaction failure | Source timetable exists and accessible | Source timetable deleted mid-copy | Source has 0 cells → copy creates empty Draft | Source timetable not found → HTTP 404 | Two concurrent copies of same source | Both succeed independently (copies are new records); no conflict |
| One-published rule on publish | No existing Published for same type+term → publish proceeds | Existing Published for same type+term → prompt to archive | Exact same timetable re-published → idempotent (already Published) | No prior Published → publish directly without prompt | Two admins both approve timetables for same type+term simultaneously | Use database transaction; second transaction receives conflict and prompt |

---

## 4. Process Flows and FSM Catalog

### Process Flow 1: Manual Timetable Build and Publish

(See FRD §6 Workflow 1 and Workflow 2 for full step narratives. Key decision points are summarised here.)

```
START
  ↓
[Create Manual Timetable]
  ↓ Period Set exists? ─── No → Error → Configure in TTF → retry
  ↓ Yes
[Draft Timetable Created]
  ↓
[Select Class-Section → Load Activity Palette + Grid]
  ↓
[Drag Activity → placeCell AJAX]
  ↓ Is break period? ─── Yes → HTTP 422 "Break period"
  ↓ No
[Run 5 Conflict Checks]
  ↓ Conflicts? ─── Yes → Record warnings on cell → Place anyway
  ↓ No conflicts
[Write Cell + Teacher Assignments + Audit Record]
  ↓
[Update Palette Counter] ← return to drag step
  ↓ (all classes done)
[Validate All → Batch Conflict Scan]
  ↓
[Submit for Approval → Status: GENERATED → Notification to Principal]
  ↓
  ├── Principal Approves → [Check One-Published Rule]
  │     ↓ Prior Published? ─── Yes → Archive prior
  │     ↓
  │   [Status: PUBLISHED → Published At, Published By set]
  │     ↓
  │   [Timetable visible in Read Views]
  │   END
  │
  └── Principal Returns → [Status: DRAFT → Notification to Coordinator]
        ↓ (corrections made)
        → Return to Submit step
```

**Exception paths:**
- DB error on cell write: rollback; user retries.
- DB error on publish: status stays GENERATED; Admin retries.
- Principal unavailable: timetable waits in GENERATED status indefinitely; Admin can resend notification.

---

### Process Flow 2: Standard Read View Access

```
START (user navigates to class/teacher/room view)
  ↓
[Check for Published Timetables]
  ↓ None found → "No published timetable found" message → link to placement → END
  ↓ Found
[Pre-select most recent Published in selector]
  ↓
[Apply role-based entity scoping]
  ├── Teacher role → only own teacher_id accessible
  ├── Class teacher role → only own class-section accessible
  └── Admin/Coordinator/Principal → full access
  ↓
[User selects entity (class, teacher, or room)]
  ↓
[Assemble grid data via Analytics Service]
  ↓
[Render grid with period type colour coding]
  ↓
[User optionally prints or exports CSV/PDF]
END
```

---

### 4B. FSM Catalog — Timetable Status Machine

**Entity:** Manual Timetable

| From State | Event / Action | Guard (Condition) | To State | Side-Effects |
|-----------|---------------|-------------------|----------|--------------|
| (new) | Create timetable | Period Set exists for type+term | DRAFT | Code auto-generated; audit created |
| DRAFT | Submit for Approval | At least some cells placed | GENERATED | Notification to Principal; timetable becomes read-only for cells |
| DRAFT | Delete timetable | No deletion if any status other than DRAFT | (deleted) | Cascade delete of all cells and teacher assignments; audit records remain |
| GENERATED | Principal Approves | (none) | PUBLISHED | Published_at and published_by recorded; prior Published of same type+term → ARCHIVED |
| GENERATED | Principal Returns | (none) | DRAFT | Return comment recorded; notification to Coordinator; cell editing re-enabled |
| PUBLISHED | Admin reverts | Explicit admin action | GENERATED | Coordinator notified; cell editing re-enabled |
| PUBLISHED | New timetable published (same type+term) | One-published rule confirmed | ARCHIVED | Status changed automatically on publish of replacement |
| ARCHIVED | Admin restores | (manual action) | PUBLISHED | Prior Published → ARCHIVED (swap) |

**Terminal states:** Deleted (hard-delete, not a status column value) | ARCHIVED (effectively terminal unless restored)

**Illegal transitions that must be blocked:**
- PUBLISHED → DRAFT directly (must go PUBLISHED → GENERATED → DRAFT)
- ARCHIVED → DRAFT (must go ARCHIVED → PUBLISHED → GENERATED → DRAFT or re-copy)
- Deleting a PUBLISHED timetable (BR-TTS-006)
- Deleting a GENERATED (pending approval) timetable (BR-TTS-006)

---

### 4C. FSM Catalog — Cell Status Machine

**Entity:** Period Cell within a Manual Timetable

| From State | Event / Action | Guard | To State | Side-Effects |
|-----------|---------------|-------|----------|--------------|
| (empty slot) | placeCell | Timetable is DRAFT; period is not break | Placed (unlocked) | Teacher assignments written; conflict detection run; audit record written; palette counter updated |
| (empty slot) | placeCell | Timetable is PUBLISHED | Rejected | HTTP 422; no change |
| (empty slot) | placeCell | Period type is break | Rejected | HTTP 422 "Break period"; no change |
| Placed (unlocked) | placeCell (replace) | Same slot, different activity | Placed (unlocked) | Old cell overwritten via updateOrCreate; teacher assignments re-written; CLASS_DOUBLE_BOOKING warning if different activity |
| Placed (unlocked) | removeCell | Timetable is DRAFT | (empty slot) | Teacher assignments deleted; cell deleted; audit record written; palette counter updated |
| Placed (unlocked) | lockCell | Timetable is DRAFT | Placed (locked) | is_locked=1; locked_by, locked_at set; padlock icon shown |
| Placed (locked) | removeCell | (any) | Rejected | HTTP 422 "Cell is locked" |
| Placed (locked) | placeCell (replace) | is_locked=1 | Rejected | HTTP 422 "Cell is locked" |
| Placed (locked) | unlockCell | Timetable is DRAFT | Placed (unlocked) | is_locked=0; padlock icon removed; audit record written |

**Illegal transitions:** Removing a locked cell | Replacing a locked cell | Any mutation on a Published timetable's cells

---

## 5. Data Dictionary and Dependency Map

### 5A. Data Dictionary (Business View)

> For full column-level technical detail, see the shared `tt_*` tables in `tenant_db_v4.sql` Section 6 (Timetable core) and the module knowledge `STA_StandardTimetable.md` — DDL Table Inventory.

**Entity: Manual Timetable (record in the timetable registry)**

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|----------|---------------|------|
| Reference Code | System-generated unique code | Text | System-generated | Format MT_YYYYMMDD_HHmmss_XXXX | No |
| Timetable Name | Admin-supplied label | Text | Yes | Max 200 characters | No |
| Status | Lifecycle stage | Controlled list | System-managed | Draft / Generated / Published / Archived | No |
| Generation Method | How it was built | Controlled list | System-set | Manual (this module) | No |
| Academic Term | Term this covers | Reference | Yes | Active terms | No |
| Timetable Type | Scheduling configuration | Reference | Yes | Active types | No |
| Period Set | Daily period structure (auto-resolved) | Reference | Auto-resolved | Period sets linked to type | No |
| Academic Session | School year | Reference | Auto-populated | Current active session | No |
| Version | Integer version | Number | System-set | Starting at 1 | No |
| Effective From | Date timetable becomes active | Date | Optional | Valid date | No |
| Effective To | Date timetable is superseded | Date | Optional | After Effective From | No |
| Created By | Who created it | User reference | System | Authenticated user | Internal |
| Published At | When it was approved | Datetime | System-set on publish | Valid datetime | No |
| Published By | Who approved it | User reference | System-set on publish | Authenticated user | Internal |

**Entity: Period Cell (one scheduled slot in the timetable grid)**

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|----------|---------------|------|
| Activity | Subject, format, teachers for this slot | Reference | Yes | Activities for this class-section | No |
| School Day | Which day of the week | Reference | Yes | School days in the period set | No |
| Period Ordinal | Which period number in the day | Number | Yes | 1 to N (N = periods in Period Set) | No |
| Class Group | Which class is taught | Reference | Yes | Class group from School Setup | No |
| Room | Which room is used | Reference | Optional | Active rooms | No |
| Source | How this cell was created | Controlled list | System-set | Manual | No |
| Locked | Protected from change | Boolean | System-managed | Yes / No | No |
| Has Conflict | Scheduling conflict detected | Boolean | System-managed | Yes / No | No |
| Conflict Details | Description of any conflicts | Structured text | Optional | Conflict messages from detection engine | No |

**Entity: Teacher Assignment per Cell (junction)**

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|----------|---------------|------|
| Teacher | Staff member teaching | User reference | Yes | Active teaching staff | Internal |
| Assignment Role | Primary or supporting | Reference | System-from-activity | Values from Assignment Role master | No |
| Is Substitute | Emergency replacement teacher | Boolean | Default No | Yes / No | No |

**Entity: Cell Audit Record**

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|----------|---------------|------|
| Timetable | Which timetable | Reference | Yes | Manual Timetable | No |
| Action | What was done | Controlled list | Yes | Placed / Removed / Locked / Unlocked / Room Changed | No |
| Previous State | Cell state before action | JSON | For non-Create actions | Prior activity, teacher, room | No |
| New State | Cell state after action | JSON | Yes | New activity, teacher, room | No |
| Changed By | Who acted | User reference | System-populated | Authenticated user | Internal |
| Changed At | When | Datetime | System-populated | Valid datetime | No |

---

### 5B. Cross-Module Dependency Map

**TTS Consumes From (Inbound — this module reads data from):**

| Source Module | Code | Data / Entity | Import Type | Notes |
|--------------|------|--------------|-------------|-------|
| Timetable Foundation | TTF | Activity, AcademicTerm, PeriodSet, SchoolDay, Timetable, TimetableCell, TimetableType | Hard — compile-time model import | All 8 models imported in the controller header; TTF must be enabled |
| School Setup | SCH | ClassSection, Room | Hard — compile-time model import | Imported in controller |
| Prime / System | PRM | AcademicSession (current session lookup) | Hard — compile-time | `AcademicSession::current()->first()` called in timetable creation |
| Smart Timetable | STT | AnalyticsService (getClassReport, getTeacherReport, getRoomReport); `_grid` Blade partial | Soft — needed when read views are built | Not yet used; will be required for REQ-TTS-008 |
| Notification | NTF | Approval request and status change notifications | Soft — needed when publishing workflow is built | Not yet used; required for REQ-TTS-011 |

**TTS Provides To (Outbound — this module feeds):**

| Target Module | Mechanism | Data Provided | Notes |
|--------------|-----------|--------------|-------|
| Smart Timetable | Shared `tt_timetables` table; `generation_method = 'MANUAL'` discriminator | Manual timetable rows visible in STT's shared selectors and analytics | STT does not depend on TTS; TTS can be disabled without affecting STT |
| Student Portal | Class-wise read view (planned) | Published timetable for a student's class-section | Planned integration — not yet built |
| Parent Portal | Class-wise read view (planned) | Same as Student Portal | Planned integration — not yet built |

**Integration Events (required but not yet implemented):**
- On Submit for Approval: fire notification event to NTF module → Principal receives approval request
- On Publish: fire notification event to NTF module → Coordinator and Admin receive publication confirmation
- On Return for Revision: fire notification event → Coordinator receives return comment

---

## 6. NFR Catalog and Risk Register

### 6A. NFR Catalog

| NFR-ID | Category | Requirement | Acceptance Threshold |
|--------|----------|-------------|---------------------|
| NFR-TTS-001 | Performance | Manual placement page loads within 800 ms including activity palette, existing cells, and selectors | Measured with a timetable containing 100 placed cells and 30 activities |
| NFR-TTS-002 | Performance | Place-cell AJAX response (including all 5 conflict checks) returns within 200 ms | Measured under typical concurrency (up to 5 coordinators placing cells simultaneously) |
| NFR-TTS-003 | Performance | Remove-cell AJAX response within 100 ms | Single user |
| NFR-TTS-004 | Performance | Class-wise, teacher-wise, and room-wise read views load within 500 ms | Published timetable with 300 cells |
| NFR-TTS-005 | Performance | Copy timetable (up to 500 cells) completes within 2 seconds | Single transactional operation |
| NFR-TTS-006 | Performance | Batch validate scan completes within 5 seconds | Timetable with up to 2,000 cells across 50 class-sections |
| NFR-TTS-007 | Performance | CSV export within 1 second; PDF export within 3 seconds | Typical school: 50 class-sections per export request |
| NFR-TTS-008 | Security | Module routes are inaccessible unless the Standard Timetable module is enabled in the school's licence | Tested by accessing a route with module disabled — expect redirect with "Module not available" |
| NFR-TTS-009 | Security | All write operations are CSRF-protected | No CSRF exceptions; all mutation routes use POST/PATCH/DELETE |
| NFR-TTS-010 | Security | Seven permission levels are enforced at the server layer — read and write actions are separated | Teacher-role users cannot access write endpoints even if CSRF tokens are manually crafted |
| NFR-TTS-011 | Security | Teacher-role and class-teacher entity scoping enforced server-side, not only in the UI | Verified by test: direct URL access to another teacher's schedule returns HTTP 403 |
| NFR-TTS-012 | Usability | Drag-and-drop works on desktop/laptop (mouse); touch drag on tablets is desirable | Mouse drag mandatory; touch drag best-effort in first release |
| NFR-TTS-013 | Usability | Period grid is horizontally scrollable on screens under 1,024 px width | No horizontal overflow cut-off on screens down to 768 px |
| NFR-TTS-014 | Usability | AJAX operations show a loading indicator and disable the triggering element during processing | No double-submission possible from any placement or removal action |
| NFR-TTS-015 | Usability | All AJAX error responses display as toast notifications, not browser alerts | No `window.alert()` calls in the frontend JS |
| NFR-TTS-016 | Scalability | Conflict detection queries operate on indexed columns (`timetable_id`, `day_of_week`, `period_ord`) and remain under 200 ms up to 10,000 cells per tenant | Indexes confirmed in DDL; cross-TT conflict check limited to current academic term to prevent false positives |
| NFR-TTS-017 | Reliability | The createTimetable endpoint is wrapped in error handling; server errors return a structured JSON error, not a 500 page | No bare HTTP 500 from any AJAX endpoint |
| NFR-TTS-018 | Reliability | Cell deletion and timetable deletion operations use database transactions; partial failures are rolled back in full | Confirmed by test that no orphaned cells or teacher records exist after a failed delete |

### 6B. Risk Register

| Risk ID | Risk | Category | Likelihood | Impact | Mitigation | Owner |
|---------|------|----------|:----------:|:------:|------------|-------|
| RISK-TTS-001 | BUG-STA-06: Conflict teacher name extraction uses wrong column; conflict messages report empty/wrong teacher names — if deployed to production, coordinators cannot act on conflict warnings effectively | Bug / Quality | High (bug confirmed in code) | Medium | Fix: change `->whereIn('id', $teacherIds)` to `->whereIn('teacher_id', $teacherIds)` at lines 420 and 442 in checkConflicts() before any production rollout | Developer |
| RISK-TTS-002 | Zero authorization enforcement: single blanket `viewAny` gate on all 6 methods including destructive AJAX — a view-only user can delete timetables | Security | High (no role differentiation) | High | Create StandardTimetablePolicy with 7 abilities; register in ServiceProvider; replace blanket gate in each controller method; add to sprint P0 | Developer |
| RISK-TTS-003 | EnsureTenantHasModule middleware absent — any authenticated user of any tenant can access timetable builder regardless of licence | Security | High (confirmed missing) | High | Add EnsureTenantHasModule:StandardTimetable to route group middleware in RouteServiceProvider | Developer |
| RISK-TTS-004 | Permissions not seeded — `standard-timetable.viewAny` and all other permissions are referenced in code but not inserted in the database; module is unusable by non-super-admin users | Security / Functional | High (confirmed empty seeder) | High | Implement StandardTimetableDatabaseSeeder to insert 7 permissions and assign to default roles | Developer |
| RISK-TTS-005 | Cross-timetable conflict checks have no academic term scope — checks scan ALL active timetables in the school, including those from prior years, producing false-positive conflict warnings | Quality | High (confirmed in code) | Medium | Add term-scope filter (`whereHas('academicTerm', fn($q) => $q->where('is_current', true))`) to cross-TT teacher and cross-TT room queries | Developer |
| RISK-TTS-006 | Publishing workflow not built — all manual timetables stay in Draft indefinitely and never appear in read views; coordinators have no path to making a timetable live | Functional | High (0% built) | High | Build submit-for-approval, approve, and publish endpoints per REQ-TTS-011; prioritise in Sprint 2 | Developer |
| RISK-TTS-007 | Read views not built — the primary consumer-facing output of the module (class, teacher, room views) is completely absent | Functional | High (0% built) | High | Build 3 read view controller methods and Blade templates per REQ-TTS-008; integrate STT AnalyticsService | Developer |
| RISK-TTS-008 | Break-period placement not blocked (BR-TTS-014) — a coordinator can accidentally fill break and lunch slots with subjects, creating an invalid timetable | Quality | Medium | Medium | Add period type `is_break` check in placeCell() before conflict detection; return HTTP 422 if true | Developer |
| RISK-TTS-009 | createTimetable() has no try/catch — unhandled database exceptions (e.g., duplicate code collision, FK failure) produce a 500 response with stack trace exposed to the browser | Security / Reliability | Medium | Medium | Wrap Timetable::create() and subsequent operations in try/catch; return structured JSON error on failure | Developer |
| RISK-TTS-010 | Deletion guard only blocks PUBLISHED — GENERATED (pending approval) timetables can be hard-deleted while awaiting Principal sign-off, destroying work in progress | Quality | Medium | Medium | Change guard from `=== 'PUBLISHED'` to `!== 'DRAFT'` so only Draft timetables are deletable | Developer |
| RISK-TTS-011 | Zero test coverage — no regression safety net; BUG-STA-06 (wrong column in conflict filter) is already present and undetected by tests | Quality | High | High | Prioritise ConflictDetectionTest (unit) and ManualPlacementTest (feature) in Sprint 1 | Developer / QA |
| RISK-TTS-012 | Dead empty route group in tenant.php (lines 229-231) — creates confusion during maintenance and may mask future route conflicts | Technical debt | Low | Low | Remove empty group; add comment pointing to Modules/StandardTimetable/routes/web.php | Developer |

---

## 7. Prioritization and Effort Estimation

### 7A. MoSCoW Prioritization

**Must Have (P0 — must be complete before any production launch):**
- REQ-TTS-013: Role-based access control — Policy, seeded permissions, EnsureTenantHasModule (no timetable system should be live without auth)
- REQ-TTS-001: Manual Timetable Creation — core data entry, currently partial (RISK-TTS-009 fix needed)
- REQ-TTS-004: Timetable Deletion Guard — partially correct; GENERATED status not blocked (RISK-TTS-010)
- REQ-TTS-005: Drag-and-Drop Grid Editor — primary build interface, partially built (break-period block and context menu missing)
- REQ-TTS-006: Real-Time Conflict Detection — partially built (BUG-TTS-001 must be fixed before production)

**Should Have (P1 — required for the module to be useful):**
- REQ-TTS-011: Publishing Workflow — without this, no timetable is ever made visible
- REQ-TTS-008: Standard Read Views — without this, there is nothing to show stakeholders
- REQ-TTS-007: Conflict Persistence and Batch Validate — important for pre-publish quality check
- REQ-TTS-010: Cell Lock and Unlock — lock/unlock/lockAll endpoints missing
- REQ-TTS-002: Copy Timetable — schools reuse prior-term timetables; high adoption impact
- REQ-TTS-003: Effective Dates and One-Published Rule — governance requirement
- REQ-TTS-009: Timetable Selector — partially present; needs completion for read views

**Could Have (P2 — valuable but shippable without them):**
- REQ-TTS-012: Print and Export — operational convenience; schools can work around with screenshots initially
- REQ-TTS-014: Cell Audit Trail — important for governance but not blocking for first live use

**Won't Have (this sprint cycle):**
- ENH-TTS-003: Undo/Redo stack — deferred to post-launch
- ENH-TTS-004: AI-to-manual import — cross-module complexity; deferred
- ENH-TTS-005: ICS calendar export — low priority; deferred

### 7B. Effort Estimation and Sprint Task Breakdown

**Sprint 1 — Foundation and Security (Weeks 1-2, ~30-40 hours)**
Goal: Make existing features production-safe; fix P0 security and quality gaps.

| # | Task | Type | Effort (h) | Depends On |
|---|------|------|:----------:|------------|
| 1 | Create StandardTimetablePolicy with 7 granular abilities | Backend | 3 | — |
| 2 | Register Policy in ServiceProvider; replace blanket viewAny gate in all 6 methods | Backend | 2 | Task 1 |
| 3 | Implement StandardTimetableDatabaseSeeder — seed 7 permissions + role assignments | Backend | 3 | Task 1 |
| 4 | Add EnsureTenantHasModule:StandardTimetable to route group | Backend | 1 | — |
| 5 | Fix BUG-STA-06: change `->whereIn('id', ...)` to `->whereIn('teacher_id', ...)` at lines 420, 442 | Backend | 1 | — |
| 6 | Wrap createTimetable() in try/catch; return structured JSON error | Backend | 1 | — |
| 7 | Fix deleteTimetable() guard — change PUBLISHED check to allow only DRAFT | Backend | 1 | — |
| 8 | Add activityLog() calls in placeCell, removeCell, createTimetable, deleteTimetable | Backend | 2 | — |
| 9 | Add academic term scope to cross-TT conflict queries (lines 431, 475) | Backend | 2 | — |
| 10 | Add is_break check in placeCell(); return HTTP 422 if break period | Backend | 2 | — |
| 11 | Remove dead route group from tenant.php lines 229-231 | Backend | 0.5 | — |
| 12 | Create PlaceCellRequest, RemoveCellRequest, CreateTimetableRequest FormRequests | Backend | 4 | Task 1 |
| 13 | ConflictDetectionTest (unit) — cover all 5 conflict types + BUG-STA-06 regression | Testing | 5 | Task 5 |
| 14 | AuthorizationTest (feature) — verify 7 permissions, EnsureTenantHasModule, entity scoping | Testing | 5 | Tasks 1-4 |
| **Total** | | | **32.5 h** | |

**Sprint 2 — Service Layer and Publishing (Weeks 3-4, ~35-45 hours)**
Goal: Complete the placement workflow and publishing path.

| # | Task | Type | Effort (h) | Depends On |
|---|------|------|:----------:|------------|
| 15 | Extract ManualTimetableService — move checkConflicts(), cell CRUD, teacher assignment logic | Backend | 8 | Sprint 1 |
| 16 | Implement lockCell, unlockCell endpoints with audit record writes | Backend | 4 | Task 15 |
| 17 | Implement lockAll endpoint (single DB update on all cells) | Backend | 2 | Task 16 |
| 18 | Implement right-click context menu in manual-placement.blade.php (View Detail, Lock, Clear, Change Room) | Frontend | 5 | Task 16 |
| 19 | Implement updateRoom endpoint (change room_id on placed cell + audit record) | Backend | 3 | Task 15 |
| 20 | Implement submitForApproval endpoint (status→GENERATED + Notification event) | Backend | 4 | — |
| 21 | Implement publish endpoint (one-published rule, archive prior, status→PUBLISHED) | Backend | 5 | Task 20 |
| 22 | Wire Notification module events for approval request and publish confirmation | Integration | 3 | Task 20 |
| 23 | ManualPlacementTest (feature) — place, remove, lock, unlock, create, delete, copy | Testing | 8 | Tasks 15-17 |
| **Total** | | | **42 h** | |

**Sprint 3 — Read Views and Export (Weeks 5-6, ~30-40 hours)**
Goal: Build the primary stakeholder-facing output of the module.

| # | Task | Type | Effort (h) | Depends On |
|---|------|------|:----------:|------------|
| 24 | Implement classView controller method and Blade template (STT AnalyticsService integration) | Backend + Frontend | 8 | Sprint 2 |
| 25 | Implement teacherView controller method and Blade template (teacher-wise grid, gap period marking) | Backend + Frontend | 8 | Sprint 2 |
| 26 | Implement roomView controller method and Blade template (room utilisation, free slot colour) | Backend + Frontend | 6 | Sprint 2 |
| 27 | Implement timetable selector for all 3 read views (Published only, newest pre-selected) | Frontend | 3 | Tasks 24-26 |
| 28 | Add period type colour coding to all 3 read views (TTF period type colour_code) | Frontend | 2 | Tasks 24-26 |
| 29 | Implement copy timetable endpoint (DB transaction, source unchanged) | Backend | 5 | Sprint 2 |
| 30 | Implement CSV export (fputcsv to temp stream) for class and teacher views | Backend | 3 | Tasks 24-25 |
| 31 | Implement PDF export via DomPDF for class view | Backend + Frontend | 4 | Task 24 |
| 32 | Print CSS stylesheet for all 3 views (landscape A4, hide nav/sidebar) | Frontend | 2 | Tasks 24-26 |
| 33 | StandardViewsTest (feature) — all 3 views, entity scoping, empty state | Testing | 6 | Tasks 24-29 |
| **Total** | | | **47 h** | |

**Sprint 4 — Conflict Persistence, Change Log, and Batch Validate (Weeks 7-8, ~20-25 hours)**

| # | Task | Type | Effort (h) | Depends On |
|---|------|------|:----------:|------------|
| 34 | Persist real-time conflict results to conflict log on every placeCell call | Backend | 4 | Sprint 1 |
| 35 | Implement validateTimetable (batch conflict scan endpoint + violation panel) | Backend + Frontend | 8 | Task 34 |
| 36 | Conflict summary badge on page header — query conflict count on page load + update after each place/remove | Frontend | 3 | Task 34 |
| 37 | Implement cell audit record writes in all cell mutations (place, remove, lock, unlock, room change) | Backend | 4 | Sprint 2 |
| 38 | Implement changeLog controller method and Blade view (paginated, filters by date + action) | Backend + Frontend | 5 | Task 37 |
| 39 | PublishWorkflowTest (feature) — submit, approve, archive prior, entity immutability after publish | Testing | 5 | Sprint 2 |
| **Total** | | | **29 h** | |

**Effort Summary:**

| Priority | Sprints | Estimated Hours | Key Deliverables |
|----------|---------|:---------------:|-----------------|
| P0 — Critical | 1 | 32.5 h | Auth policy, permissions, EnsureTenantHasModule, bug fixes, break-period block, FormRequests |
| P1 — Standard | 2-3 | 89 h | ManualTimetableService, publish workflow, read views, copy, exports |
| P2 — Enhanced | 4 | 29 h | Conflict persistence, batch validate, cell audit trail, change log viewer |
| **Total** | 4 sprints (~8 weeks) | **~150 h** | Full module |

> Note: V2 estimated 90-125 h. This revised estimate is 150 h after accounting for the new index() method discovered, the service layer extraction, the full publishing notification workflow, and the batch validate screen not reflected in the V2 numbers.

---

## 8. User Stories and Reporting Spec

### 8A. User Stories + Acceptance Criteria (P0 and P1 REQs)

---

**US-TTS-001** | Priority: P0 | REQ ref: REQ-TTS-001
*As a Timetable Coordinator, I want to create a new manual timetable for the current term so that I can begin scheduling period-by-period.*

Acceptance Criteria (Gherkin):

Scenario: Successful timetable creation
Given I am logged in as Timetable Coordinator
And a Period Set is configured for "Regular Type" and "Term 1"
When I click "+ New Timetable" and submit name "Class 10 Term 1", term "Term 1", type "Regular"
Then a new Draft timetable appears in the list with status "Draft" and code beginning "MT_"

Scenario: Period Set missing
Given no Period Set is linked to "Regular Type" for "Term 1"
When I submit the creation form
Then I see "No Period Set is configured for the selected Timetable Type" and no timetable is created

Scenario: Permission denied
Given I am logged in with view-only access
When I attempt to create a timetable
Then I receive a 403 error

Definition of Done: Timetable record created with correct discriminators; code auto-generated; no activityLog() call missing; no 500 on DB failure.

---

**US-TTS-002** | Priority: P0 | REQ ref: REQ-TTS-004
*As a School Admin, I want to delete a draft timetable so that I can remove incorrectly created timetables before they accumulate.*

Acceptance Criteria (Gherkin):

Scenario: Delete Draft succeeds
Given a Draft manual timetable with 50 placed cells
When the Admin confirms deletion
Then the timetable, all cells, and all teacher assignments are removed; a success toast appears

Scenario: Delete Published fails
Given a Published timetable
When the Admin attempts deletion
Then the system returns "Cannot delete a published timetable" and nothing is removed

Scenario: Delete Generated (pending approval) fails
Given a timetable in Generated status
When the Admin attempts deletion
Then the system returns an error and nothing is removed

Definition of Done: Only Draft timetables deletable; all three statuses tested; transaction rolls back on failure.

---

**US-TTS-003** | Priority: P0 | REQ ref: REQ-TTS-005
*As a Timetable Coordinator, I want to drag an activity card onto a period grid cell so that I can place a subject into the weekly schedule.*

Acceptance Criteria (Gherkin):

Scenario: Successful placement
Given Mathematics activity needs 5 periods and 2 are already placed
When I drag Mathematics onto Monday Period 2 (a free teaching slot)
Then the cell shows "Mathematics / A. Kumar / Rm 101" without page reload
And the palette counter for Mathematics shows "3 placed, 2 remaining"

Scenario: Break period placement blocked
Given Monday Period 3 is configured as a lunch break
When I attempt to drop any activity onto Monday Period 3
Then I see "Break periods cannot be scheduled" and the cell remains empty

Scenario: Published timetable refuses placement
Given the selected timetable is Published
When I attempt to drag any activity
Then I see "Published timetables are read-only"

Definition of Done: All 3 scenarios pass; is_break check implemented; palette counter updates in AJAX response.

---

**US-TTS-004** | Priority: P0 | REQ ref: REQ-TTS-006
*As a Timetable Coordinator, I want to see real-time conflict warnings when I place an activity so that I can avoid teacher double-booking and room clashes.*

Acceptance Criteria (Gherkin):

Scenario: Teacher conflict detected
Given Teacher A. Kumar is teaching Class 9-B Mathematics on Monday Period 2 in another timetable
When I place a Mathematics activity (teacher: A. Kumar) on Monday Period 2 in the current timetable
Then the cell is placed but highlighted amber
And the conflict warning reads "A. Kumar is busy in another timetable at this slot"
And A. Kumar's name is correctly shown (not empty — BUG-STA-06 fix applied)

Scenario: No conflict — clean placement
Given no teacher, room, or class conflicts exist at the target slot
When I place an activity
Then the cell is shown without any conflict indicator

Definition of Done: All 5 conflict types tested; BUG-STA-06 fixed and regression test written; term scope applied to cross-TT checks.

---

**US-TTS-005** | Priority: P0 | REQ ref: REQ-TTS-013
*As a System Administrator, I want the Standard Timetable module to enforce seven distinct permission levels so that coordinators can place cells but cannot approve and publish.*

Acceptance Criteria (Gherkin):

Scenario: Module not licensed
Given the Standard Timetable module is not enabled for the school
When any user navigates to /standard-timetable/
Then they are redirected with "Module not available"

Scenario: Teacher accesses own schedule
Given Teacher A. Kumar is logged in
When they navigate to /standard-timetable/teacher-view?teacher_id=[A. Kumar's ID]
Then the view renders A. Kumar's schedule

Scenario: Teacher accesses another teacher's schedule
Given Teacher A. Kumar is logged in
When they navigate to /standard-timetable/teacher-view?teacher_id=[R. Patel's ID]
Then they receive HTTP 403

Scenario: Coordinator cannot publish
Given Coordinator is logged in without "publish" permission
When they call the publish endpoint
Then they receive HTTP 403

Definition of Done: Policy class exists; 7 permissions seeded; EnsureTenantHasModule applied; AuthorizationTest passes all 7 permission scenarios.

---

**US-TTS-006** | Priority: P1 | REQ ref: REQ-TTS-011
*As a Timetable Coordinator, I want to submit a completed timetable for Principal approval so that it can be made live for teachers and students to view.*

Acceptance Criteria (Gherkin):

Scenario: Submit for approval succeeds
Given a Draft timetable with cells placed
When I click "Submit for Approval"
Then the status changes to Generated
And the Principal receives a notification "Timetable [name] submitted for your review"
And I can no longer place or remove cells

Scenario: Principal approves
Given a Generated timetable
When the Principal clicks "Approve and Publish"
Then the status becomes Published
And publication date and approver are recorded
And any prior Published timetable for the same type and term becomes Archived

Scenario: Principal returns for revision
Given a Generated timetable
When the Principal clicks "Return for Revision"
Then the status reverts to Draft
And I receive a notification with the Principal's comments
And cell editing is re-enabled

Definition of Done: Submit, approve, and return endpoints built; notification events fired; one-published rule enforced; immutability of Published timetable tested.

---

**US-TTS-007** | Priority: P1 | REQ ref: REQ-TTS-008
*As a Class Teacher, I want to view the published timetable for my class so that I know which subjects and teachers are scheduled for each period.*

Acceptance Criteria (Gherkin):

Scenario: Class-wise view loads for own class
Given Teacher Singh is assigned as class teacher for Class 8-B
And a Published timetable exists for Class 8-B
When Teacher Singh navigates to the class-wise view
Then a weekly grid shows all scheduled subjects, teachers, and rooms for Class 8-B

Scenario: No published timetable
Given no Published timetable exists
When any user opens the class-wise view
Then they see "No published timetable found. Please publish a timetable first." with a placement link

Scenario: Class teacher accesses another class
Given Teacher Singh is class teacher for Class 8-B
When they attempt to access Class 9-A's view
Then they receive HTTP 403

Definition of Done: All 3 read views built; entity scoping enforced; empty-state message shown; period type colour coding applied.

---

**US-TTS-008** | Priority: P1 | REQ ref: REQ-TTS-002
*As a Timetable Coordinator, I want to copy last term's timetable as a starting point for this term so that I do not have to rebuild the schedule from scratch.*

Acceptance Criteria (Gherkin):

Scenario: Successful copy
Given a Published timetable for Term 1 with 200 cells
When I select "Copy" and specify Term 2
Then a new Draft timetable is created with all 200 cells and teacher assignments copied
And the Term 1 timetable remains Published and unchanged

Scenario: Copy transaction failure
Given the system encounters a database error mid-copy
When the error occurs
Then the partial new timetable is fully rolled back
And I see an error message

Definition of Done: All cells and teacher assignments duplicated; source unchanged; full transaction rollback on error; copy creates new version 1 Draft.

---

### 8B. Reporting and KPI Spec

| ID | Report | Audience | Frequency | Key Fields | Filters | Exports | Business Rule |
|----|--------|----------|-----------|-----------|---------|---------|---------------|
| RPT-TTS-001 | Class-Wise Timetable Grid | Admin, Coordinator, Principal, Class Teacher (own class) | On-demand | Subject, Teacher, Room per slot; break periods shaded; locked cells with padlock | Timetable (Published only), Class, Section | Print, CSV, PDF | Only Published timetables; entity-scoped for Class Teachers |
| RPT-TTS-002 | Teacher-Wise Schedule | Admin, Coordinator, Principal, Subject Teacher (own) | On-demand | Class-section, Subject, Room per slot; weekly load; free periods dimmed; gap periods dashed | Timetable (Published only), Teacher (scoped for teacher-role users) | Print, CSV | Teacher-role users restricted to own schedule (BR-TTS-013) |
| RPT-TTS-003 | Room-Wise Utilisation View | Admin, Coordinator, Principal | On-demand | Class, Teacher per occupied slot; utilisation % summary; free slots in green | Timetable (Published only), Room | Print | Room-wise KPI: utilisation rate = occupied slots / total available slots × 100% |
| RPT-TTS-004 | Cell Change Log View | Admin, Coordinator | On-demand | Action type, Day × Period, Subject before/after, Teacher, Changed By, Changed At | Timetable, Date range, Action type | Print | Read-only; all 4 action types: Placed, Removed, Locked, Unlocked |

**KPI Catalog:**

| KPI | Definition | Source | Target |
|-----|-----------|--------|--------|
| Timetable Completion Rate | Placed cells ÷ (School Days × Periods per Day) × 100% | Timetable cell count ÷ (School Day × Period Set size) | 100% before submission for approval |
| Activity Coverage Rate | Fully-placed activities ÷ total activities for class-section × 100% | From palette counter (placed ≥ weekly_needed) | 100% |
| Conflict Rate | Active conflicts ÷ total placed cells × 100% | Conflict log count against cell count | Target: 0% at time of publish |
| Teacher Period Load | Assigned periods per teacher ÷ contracted weekly periods | From teacher-wise view cell count | Configurable per school; typical K-12: 18-24 periods/week |
| Room Utilisation | Booked slots ÷ total available slots per room per week × 100% | From room-wise view | No single target; Admin uses to identify under/over-used rooms |

---

## 9. Feature Specification (Screen-by-Screen)

### SCR-TTS-01: Manual Placement Screen

**Route:** `GET /standard-timetable/manual-placement`
**Permission:** `standard-timetable.viewAny` (view); `standard-timetable.manualPlace` (for placement actions)
**Layout:** Full-page two-panel + header bar

**Header Bar:**
| # | Field / Control | Type | Notes |
|---|----------------|------|-------|
| 1 | Class-Section Selector | Dropdown | Lists all active class-sections; triggers activity palette + existing cell reload |
| 2 | Timetable Selector | Dropdown | Lists MANUAL timetables ordered newest first; shows name, status badge, term |
| 3 | "+ New Timetable" Button | Modal trigger | Opens Create Timetable modal |
| 4 | Conflict Count Badge | Read-only counter | Shows active conflict count for selected timetable |
| 5 | Progress Counter | Read-only text | "X / Y cells placed" |
| 6 | "Lock All" Button | Action | Locks all placed cells; requires manualPlace permission |
| 7 | "Validate All" Button | Action | Triggers batch conflict scan |
| 8 | "Submit for Approval" Button | Action | Requires manualPlace permission; timetable must be Draft |

**Left Panel — Activity Palette:**
| # | Field / Control | Type | Notes |
|---|----------------|------|-------|
| 1 | Subject name | Text | Primary label on Activity Card |
| 2 | Study format | Text | Secondary label (Lecture, Lab, etc.) |
| 3 | Periods needed | Number | Weekly requirement from Activity configuration |
| 4 | Placed count | Number | "N placed" — updates after each place/remove |
| 5 | Remaining | Number | Periods needed − placed count |
| 6 | Completion indicator | Icon / style | Green checkmark when remaining = 0; greyed card |
| 7 | Drag handle | UI element | Enables drag to grid; requires SortableJS or interact.js |

**Right Panel — Period Grid:**
| # | Field / Control | Type | Notes |
|---|----------------|------|-------|
| 1 | Day header row | Read-only | School days from Period Set (Mon–Sat as configured) |
| 2 | Period ordinal column | Read-only | Period numbers 1–N from Period Set |
| 3 | Empty cell | Drop target | Accepts Activity Card drag-drop |
| 4 | Break-period cell | Non-drop zone | Shaded grey; labelled "BREAK" or "LUNCH"; refuses drops |
| 5 | Placed cell (no conflict) | Data display | Subject name, teacher initials, room code |
| 6 | Placed cell (with conflict) | Data display | Amber border + warning icon; tooltip shows conflict details |
| 7 | Locked cell overlay | Icon | Padlock icon in top-right corner of placed cells with is_locked=1 |
| 8 | Right-click context menu | Menu | View Detail / Lock Cell / Unlock Cell / Change Room / Clear Cell |

**Create Timetable Modal:**
| # | Field | Type | Required | Validation |
|---|-------|------|----------|-----------|
| 1 | Timetable Name | Text input | Yes | Max 200 chars; not blank |
| 2 | Academic Term | Dropdown | Yes | Active terms from Academic Term master |
| 3 | Timetable Type | Dropdown | Yes | Active types; triggers Period Set resolution |

**Actions:** Save (POST /standard-timetable/create-timetable), Cancel

**Empty State:** "No manual timetables created yet. Click '+ New Timetable' to create your first one."

---

### SCR-TTS-02: Class-Wise Timetable View

**Route:** `GET /standard-timetable/class-view`
**Permission:** `standard-timetable.viewClass` (class teachers: own class only)
**Layout:** Selector bar + grid

| Control | Description |
|---------|-------------|
| Timetable Selector | Published timetables only; newest pre-selected |
| Class Selector | Active classes; scoped to own class for class-teacher role |
| Section Selector | Sections for selected class |
| Grid | Days as columns; periods as rows; occupancy data per cell |
| Period type styling | Teaching = white; Break/Lunch = grey; Locked = padlock overlay |
| Print button | window.print() with print CSS |
| CSV Export | Downloads TT_[class]_[section]_[date].csv |
| PDF Export | DomPDF — class timetable as A4 landscape PDF |

**Empty State (no Published timetable):** "No published timetable found. Please publish a timetable first." [link to Manual Placement]
**Empty State (no class-sections):** "No class-sections configured. Please configure via School Setup."

---

### SCR-TTS-03: Teacher-Wise Schedule View

**Route:** `GET /standard-timetable/teacher-view`
**Permission:** `standard-timetable.viewTeacher` (teacher-role users: own schedule only)
**Layout:** Selector bar + grid + workload summary

| Control | Description |
|---------|-------------|
| Timetable Selector | Published only; newest pre-selected |
| Teacher Selector | Active teachers; scoped to own teacher_id for teacher-role users |
| Weekly Load Display | "18 / 20 periods assigned" summary header |
| Grid | Days as columns; periods as rows; class-section + subject + room per occupied cell |
| Free periods | Dimmed grey cells |
| Gap periods | Dashed-border cells between two assignments on the same day |
| Print button | Print CSS landscape |
| CSV Export | Downloads TT_Teacher_[name]_[date].csv |

---

### SCR-TTS-04: Room-Wise Utilisation View

**Route:** `GET /standard-timetable/room-view`
**Permission:** `standard-timetable.viewRoom`
**Layout:** Selector bar + utilisation summary + grid

| Control | Description |
|---------|-------------|
| Timetable Selector | Published only; newest pre-selected |
| Room Selector | Active rooms |
| Utilisation summary | "Science Lab — Capacity 40 — 72% utilised this week" |
| Grid | Days as columns; periods as rows; class-section + subject + teacher per booked cell; free slots green |
| Print button | Print CSS landscape |

---

### SCR-TTS-05: Create Timetable Modal (within SCR-TTS-01)

*Fields documented in SCR-TTS-01 Create Timetable Modal section above.*

---

### SCR-TTS-06: Timetable List / Empty Dashboard (within SCR-TTS-01)

Shown when no timetable is selected on the manual placement screen:
- "Select a timetable from the dropdown to begin placement" — or —
- "No timetables created yet. Click '+ New Timetable' to start."

---

### SCR-TTS-07: Conflict Summary and Validate Panel (within SCR-TTS-01)

Triggered by "Validate All" action:
- Header: "Validation Results — [N] conflicts found"
- Paginated list: Conflict type | Day + Period | Teacher / Room | Conflicting Timetable | Status (Active / Resolved)
- "Mark Resolved" action per row
- Conflict count badge in page header reflects current unresolved count

---

### SCR-TTS-08: Cell Change Log View

**Route:** `GET /standard-timetable/{timetable}/change-log`
**Permission:** `standard-timetable.viewAny`

| Control | Description |
|---------|-------------|
| Timetable header | Name, status, academic term |
| Date range filter | From / To date pickers |
| Action type filter | All / Placed / Removed / Locked / Unlocked |
| Change log table | Action type, Day × Period, Subject Before, Subject After, Teacher, Changed By, Changed At |
| Pagination | 25 rows per page |

---

## 10. Module Knowledge Update

The existing module knowledge file at `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/STA_StandardTimetable.md` was seeded on 2026-06-30 with comprehensive findings. This Complete Analysis Pack adds the following updates:

**FRD Summary Block (to append to module knowledge):**

```
## FRD Summary
FRD File:    TTS_FRD_2026-06-30.md
Complete:    TTS_FRD_Complete_2026-06-30.md
Date:        2026-06-30
REQ count:   14 (P0=5, P1=7, P2=2)
BR count:    15
RPT count:   4
ENH count:   10
Overall completion: ~15% (3/15 BRs fully enforced; 0/4 reports built)
```

**Pending Next Steps (additions to module knowledge):**

1. Sprint 1 (P0): StandardTimetablePolicy + seeder + EnsureTenantHasModule + BUG-STA-06 fix + break-period check + FormRequests + try/catch + deletion guard fix + activityLog + term scope on cross-TT conflicts
2. Sprint 2 (P1): ManualTimetableService extraction + lock/unlock/lockAll endpoints + submit-approval + publish + Notification integration
3. Sprint 3 (P1): Class-wise + teacher-wise + room-wise read views + timetable selector + copy timetable + CSV/PDF export + print CSS
4. Sprint 4 (P2): Conflict persistence to conflict log + batch validate + cell audit trail writes + change log viewer

**Design Decisions (to record in module knowledge):**

- D-TTS-001: All IDs in this analysis use prefix TTS per the V2 requirement document; file is named STA per the original seeding task. New files should use TTS as the canonical prefix.
- D-TTS-002: Complete Analysis Pack estimates 150 hours remaining (revised upward from V2's 90-125 h) after accounting for the service layer extraction, publishing notification integration, and batch validate screen.
- D-TTS-003: The complete pack confirms 4 sprints (~8 weeks) as the recommended delivery vehicle, with Sprint 1 as the non-negotiable pre-launch gate.

---

*Complete Analysis Pack v1.0 — StandardTimetable (TTS) — 2026-06-30*
*FRD spine: `TTS_FRD_2026-06-30.md` | Module Knowledge: `STA_StandardTimetable.md`*
*Sources: V2 Requirement (1022 lines) · V1 Screen Specs (2 files) · StandardTimetableController.php (513 lines, 6 methods) · Module Knowledge (seeded 2026-06-30)*

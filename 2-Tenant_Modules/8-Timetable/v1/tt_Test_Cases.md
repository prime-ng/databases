# Timetable Module - Testing & QA Strategy (v1)

**Document Version:** 1.0  
**Scope:** Timetable Generation, Substitution, Constraint Validation  
**Reference:** `tt_timetable_ddl_v6.0.sql`

---

## 1. Developer Checklist (Pre-Commit)

### Database Integrity
- [ ] All 29 tables created successfully using `tt_timetable_ddl_v6.0.sql`.
- [ ] Foreign Key constraints enforce Referential Integrity (e.g., cannot delete Active Teacher).
- [ ] `tt_timetable_cell` uniqueness constraint (Day + Period + Teacher) blocks duplicates.

### Logic Validation
- [ ] `soft_score` calculation decreases when Soft Constraints are violated.
- [ ] `check_overlap(t1, t2)` function correctly identifies time conflicts.
- [ ] Recursive Swapping algorithm terminates within 5 seconds for < 50 activities.

---

## 2. QA Checklist (Acceptance Criteria)

### Functional Testing
- [ ] **Happy Path**: Can generate a full timetable for a standard 8-period day without errors.
- [ ] **Hard Constraints**: Ensure NO teacher is double-booked in the final output.
- [ ] **Substitution**: Marking a teacher absent correctly suggests available substitutes.

### Performance Testing
- [ ] **Grid Load**: Timetable Grid loads in < 200ms for a school with 50 classes.
- [ ] **Generation**: Full Auto-Generation completes in < 5 minutes for 1000 activities.

---

## 3. Test Cases (Table Driven)

### 3.1 Scenario: Timetable Generation Algorithm

| ID | Test Scenario | Pre-Conditions | Input Data | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-GEN-01 | Basic Allocation | 1 Class, 1 Teacher | 1 Activity (Math, 5/wk) | Activity appears in 5 distinct slots. | Critical |
| TC-GEN-02 | Hard Conflict (Teacher) | Teacher 'T1' booked in P1 | Activity B (requires T1) | Algorithm places Activity B in P2, NOT P1. | Critical |
| TC-GEN-03 | Hard Conflict (Room) | Room 'R1' booked in P1 | Activity B (requires R1) | Algorithm places Activity B in P2. | Critical |
| TC-GEN-04 | Soft Constraint (Preferred Time) | Math prefers Morning | Slots P1, P8 available | Activity placed in P1 (Higher Score). | Normal |
| TC-GEN-05 | Max Daily Load | Teacher Max = 2/day | 3 Activities pending | 2 placed today, 1 moved to tomorrow. | High |

### 3.2 Scenario: Substitution Management

| ID | Test Scenario | Pre-Conditions | Input Data | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-SUB-01 | Identify Absence | Teacher T1 has 3 classes | Mark T1 Absent (Today) | 3 entries created in `tt_substitution_log`. | Critical |
| TC-SUB-02 | Suggest Substitute (Free) | T2 is free in P1 | Req Sub for P1 | T2 appears in Suggestion List. | High |
| TC-SUB-03 | Suggest Substitute (Busy) | T3 is busy in P1 | Req Sub for P1 | T3 does NOT appear in Suggestion List. | High |
| TC-SUB-04 | Suggestion Sorting | T2 (Math), T4 (Sports) | Sub for Math Class | T2 ranked higher than T4. | Normal |

### 3.3 Scenario: Constraints

| ID | Test Scenario | Pre-Conditions | Input Data | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-CON-01 | Teacher Unavailable | Config: T1 Unavail Mon P1 | Manual Assign T1 to Mon P1 | Error: "Violates Hard Constraint". | Critical |
| TC-CON-02 | Room Capacity | Room Cap=30 | Class Size=40 | Warning: "Room Capacity Exceeded". | Normal |

---

## 4. Test Data Strategy

**Seed Data:**
- **Period Set**: "Regular" (8 periods/day, 45 mins).
- **Teachers**: 10 Teachers (2 Math, 2 Sci, 2 Eng, 4 Others).
- **Classes**: 5 Classes (10-A to 10-E).
- **Activities**: 200 Activities (40 per class).

**Tools:**
- PHPUnit for Unit Tests (Constraint Logic).
- Cypress for E2E Tests (Drag-and-Drop Grid).

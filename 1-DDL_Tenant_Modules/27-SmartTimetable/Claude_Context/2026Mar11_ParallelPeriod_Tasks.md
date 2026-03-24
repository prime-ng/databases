# Parallel Period Configuration — Implementation Tasks & Sub-Tasks

**Date:** 2026-03-11
**Module:** SmartTimetable
**Priority:** HIGH — Core school requirement, currently 0% implemented in solver

---

## Current State Assessment

### What Exists
- **Schema:** `tt_class_subgroup` table with `subgroup_type` ENUM (OPTIONAL_SUBJECT, HOBBY, SKILL, LANGUAGE, STREAM, ACTIVITY, SPORTS, OTHER) + `is_shared_across_sections`, `is_shared_across_classes` flags
- **Schema:** `tt_class_subgroup_member` table linking subgroups to class+section combinations
- **Schema:** `tt_class_group_requirement` table with scheduling params (weekly_periods, max_per_day, etc.)
- **Schema:** `tt_activity` has `activity_group_id`, `have_sub_activity`, `class_subgroup_id` fields
- **Schema:** `tt_sub_activity` table with `same_day_as_parent`, `consecutive_with_previous`
- **Schema:** `tt_cross_class_coordination` DDL designed (in `tt_New_ddl_v2.sql`) but NOT applied — has `coordination_type` ENUM (PARALLEL, ROTATIONAL, COMBINED, STAGGERED)
- **Models:** `ClassSubgroup`, `ClassSubgroupMember`, `ClassRequirementGroup`, `SubActivity` models exist
- **Models:** `Activity` model has `activity_group_id` field (always set to NULL in current code)
- **Controller:** `ActivityController` sets `have_sub_activity=true` for shared subjects but never sets `activity_group_id`
- **Service:** `SubActivityService` handles consecutive period splitting only, NOT parallel grouping
- **Design Doc:** `tt_Algoritham.md` Step 12 describes parallel scheduling algorithm conceptually
- **Constraint Doc:** H8 (Parallel Periods) fully documented in ConstraintList

### What's Missing (The Gap)
1. **No Activity Grouping Model/Table** for linking parallel activities together
2. **No UI/Controller** for configuring parallel period groups
3. **No Solver Logic** — FETSolver has zero parallel period awareness
4. **No Constraint PHP Class** — ConstraintFactory has no PARALLEL_PERIODS mapping
5. **No Pre-Generation Validation** for parallel group consistency
6. **No Post-Generation Validation** to verify parallel constraints were met
7. **No Tests** for parallel period scenarios

---

## STEP 1: Schema & Model Foundation

### Task 1.1: Create `tt_parallel_group` Table
**Purpose:** Master table to define a parallel period group (e.g., "Class 6 Hobby Group")

**Migration DDL:**
```sql
CREATE TABLE IF NOT EXISTS `tt_parallel_group` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(60) NOT NULL,
  `name` VARCHAR(150) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `academic_term_id` INT UNSIGNED DEFAULT NULL,
  `group_type` ENUM('PARALLEL_SECTION','PARALLEL_OPTIONAL','PARALLEL_SKILL','PARALLEL_HOBBY','PARALLEL_CUSTOM') NOT NULL,
  `coordination_type` ENUM('SAME_TIME','SAME_DAY','SAME_PERIOD_RANGE') NOT NULL DEFAULT 'SAME_TIME',
  `requires_same_teacher` TINYINT(1) DEFAULT 0,
  `requires_same_room_type` TINYINT(1) DEFAULT 0,
  `scheduling_priority` TINYINT UNSIGNED DEFAULT 75,
  `is_hard_constraint` TINYINT(1) NOT NULL DEFAULT 1,
  `weight` TINYINT UNSIGNED DEFAULT 100,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pg_code` (`code`),
  KEY `idx_pg_type` (`group_type`),
  KEY `idx_pg_term` (`academic_term_id`),
  CONSTRAINT `fk_pg_term` FOREIGN KEY (`academic_term_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Groups of activities that must be scheduled in parallel (same time slot)';
```

**Deliverables:**
- [ ] Laravel migration file in `database/migrations/tenant/`
- [ ] Update `tenant_db.sql` DDL file

### Task 1.2: Create `tt_parallel_group_activity` Junction Table
**Purpose:** Links activities to a parallel group

**Migration DDL:**
```sql
CREATE TABLE IF NOT EXISTS `tt_parallel_group_activity` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parallel_group_id` INT UNSIGNED NOT NULL,
  `activity_id` INT UNSIGNED NOT NULL,
  `sequence_order` TINYINT UNSIGNED DEFAULT 1,
  `is_anchor` TINYINT(1) DEFAULT 0,       -- The "master" activity placed first; others follow
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pga_group_activity` (`parallel_group_id`, `activity_id`),
  KEY `idx_pga_activity` (`activity_id`),
  CONSTRAINT `fk_pga_group` FOREIGN KEY (`parallel_group_id`) REFERENCES `tt_parallel_group` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pga_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activity` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Junction linking activities to parallel groups';
```

**Deliverables:**
- [ ] Laravel migration file
- [ ] Update `tenant_db.sql` DDL file

### Task 1.3: Create `ParallelGroup` Model
**File:** `Modules/SmartTimetable/app/Models/ParallelGroup.php`

**Requirements:**
- [ ] `$table = 'tt_parallel_group'`
- [ ] `$fillable` with all columns
- [ ] `$casts` for booleans and enums
- [ ] `SoftDeletes` trait
- [ ] Relationships:
  - `activities()` → `belongsToMany(Activity::class, 'tt_parallel_group_activity')` with pivot columns
  - `academicTerm()` → `belongsTo`
- [ ] Scopes: `scopeActive`, `scopeByType($type)`, `scopeForTerm($termId)`
- [ ] Helper: `getAnchorActivity()` — returns the activity marked `is_anchor=1`

### Task 1.4: Create `ParallelGroupActivity` Pivot Model
**File:** `Modules/SmartTimetable/app/Models/ParallelGroupActivity.php`

**Requirements:**
- [ ] `$table = 'tt_parallel_group_activity'`
- [ ] Relationships: `parallelGroup()`, `activity()`
- [ ] `SoftDeletes` trait

### Task 1.5: Update Activity Model
**File:** `Modules/SmartTimetable/app/Models/Activity.php`

**Requirements:**
- [ ] Add relationship: `parallelGroups()` → `belongsToMany(ParallelGroup::class, 'tt_parallel_group_activity')` with pivot columns
- [ ] Add helper: `isInParallelGroup(): bool`
- [ ] Add helper: `getParallelGroupActivities(): Collection` — returns sibling activities in all parallel groups

---

## STEP 2: Parallel Group Management UI & API

### Task 2.1: Create `ParallelGroupController`
**File:** `Modules/SmartTimetable/app/Http/Controllers/ParallelGroupController.php`

**Methods:**
- [ ] `index()` — List all parallel groups with member activity count, filtered by `group_type` and `academic_term_id`
- [ ] `create()` — Show form to create a new group (type selector, name, description, constraint settings)
- [ ] `store(StoreParallelGroupRequest)` — Create group
- [ ] `show($id)` — Show group details with all member activities and their class/section/subject info
- [ ] `edit($id)` — Edit group settings
- [ ] `update(UpdateParallelGroupRequest, $id)` — Update group
- [ ] `destroy($id)` — Soft delete group
- [ ] `addActivities(Request, $id)` — Add activities to group (AJAX)
- [ ] `removeActivity($groupId, $activityId)` — Remove activity from group (AJAX)
- [ ] `setAnchor($groupId, $activityId)` — Set the anchor activity (AJAX)
- [ ] `autoDetect(Request)` — Auto-detect parallel groups from class subgroups (see Task 2.5)

### Task 2.2: Create Form Requests
**Files:**
- [ ] `StoreParallelGroupRequest.php` — Validate: code (required, unique), name (required), group_type (required, enum), coordination_type (required, enum), is_hard_constraint, weight, academic_term_id
- [ ] `UpdateParallelGroupRequest.php` — Same as store, with unique code ignoring current ID
- [ ] `AddActivitiesRequest.php` — Validate: activity_ids (required, array), each must exist in `tt_activity` and belong to same academic term

### Task 2.3: Create Blade Views
**Files:**
- [ ] `resources/views/parallel-group/index.blade.php` — Table listing groups with type badges, activity count, constraint status (hard/soft), actions (edit/delete)
- [ ] `resources/views/parallel-group/create.blade.php` — Form with: group type dropdown, name, description, coordination type, hard/soft toggle, weight slider, academic term selector
- [ ] `resources/views/parallel-group/show.blade.php` — Group details card + member activities table (class, section, subject, study format, teacher, duration) + add/remove activity controls + set anchor button
- [ ] `resources/views/parallel-group/edit.blade.php` — Edit form

### Task 2.4: Register Routes
**File:** `routes/tenant.php` (or module route file)

```php
Route::prefix('smart-timetable/parallel-group')->name('smart-timetable.parallel-group.')->group(function () {
    Route::get('/', [ParallelGroupController::class, 'index'])->name('index');
    Route::get('/create', [ParallelGroupController::class, 'create'])->name('create');
    Route::post('/', [ParallelGroupController::class, 'store'])->name('store');
    Route::get('/{parallelGroup}', [ParallelGroupController::class, 'show'])->name('show');
    Route::get('/{parallelGroup}/edit', [ParallelGroupController::class, 'edit'])->name('edit');
    Route::put('/{parallelGroup}', [ParallelGroupController::class, 'update'])->name('update');
    Route::delete('/{parallelGroup}', [ParallelGroupController::class, 'destroy'])->name('destroy');
    Route::post('/{parallelGroup}/add-activities', [ParallelGroupController::class, 'addActivities'])->name('add-activities');
    Route::delete('/{parallelGroup}/activity/{activity}', [ParallelGroupController::class, 'removeActivity'])->name('remove-activity');
    Route::post('/{parallelGroup}/set-anchor/{activity}', [ParallelGroupController::class, 'setAnchor'])->name('set-anchor');
    Route::post('/auto-detect', [ParallelGroupController::class, 'autoDetect'])->name('auto-detect');
});
```

**Deliverables:**
- [ ] Routes registered
- [ ] Navigation link added to SmartTimetable menu

### Task 2.5: Auto-Detect Parallel Groups from Class Subgroups
**Service Method:** `ParallelGroupService::autoDetectGroups($academicTermId)`

**Logic:**
1. Query `tt_class_subgroup` where `is_shared_across_sections=1` OR `is_shared_across_classes=1`
2. For each subgroup, find activities with matching `class_subgroup_id` or matching `subject_id` + `study_format_id` across different sections of the same class
3. Group these activities by: `{subject_id}_{study_format_id}_{class_id}`
4. For groups with 2+ activities across different sections → propose as `PARALLEL_SECTION` group
5. For subgroup_type=HOBBY → propose as `PARALLEL_HOBBY`
6. For subgroup_type=SKILL → propose as `PARALLEL_SKILL`
7. For subgroup_type=OPTIONAL_SUBJECT → propose as `PARALLEL_OPTIONAL`
8. Return proposed groups for user confirmation (don't auto-create)

**Deliverables:**
- [ ] `ParallelGroupService::autoDetectGroups()` method
- [ ] JSON endpoint returning proposed groups
- [ ] UI confirmation dialog to accept/reject detected groups

---

## STEP 3: Solver Integration — FETSolver Parallel Period Logic

### Task 3.1: Load Parallel Groups into Solver Context
**File:** `SmartTimetableController.php` → `generateWithFET()` method

**Requirements:**
- [ ] Before calling `$solver->solve()`, load parallel groups:
  ```php
  $parallelGroups = ParallelGroup::with('activities')
      ->active()
      ->forTerm($academicTermId)
      ->get();
  ```
- [ ] Pass to solver: `$options['parallel_groups'] = $parallelGroups`
- [ ] Build lookup map: `$parallelGroupsByActivity[$activityId] = [$group1, $group2, ...]`

### Task 3.2: Pre-Process Parallel Groups in FETSolver Constructor
**File:** `FETSolver.php`

**Requirements:**
- [ ] Accept `parallel_groups` from `$options`
- [ ] Build internal data structures:
  ```php
  private array $parallelGroups = [];           // group_id => ParallelGroup
  private array $activityParallelMap = [];      // activity_id => [group_id, ...]
  private array $parallelGroupActivities = [];  // group_id => [activity_id, ...]
  private ?int $anchorActivity = [];            // group_id => anchor_activity_id
  ```
- [ ] Validate: all activities in a parallel group must have same `duration_periods`
- [ ] Validate: anchor activity exists for each group

### Task 3.3: Modify Activity Ordering — Parallel Groups First
**File:** `FETSolver.php` → `orderActivitiesByDifficulty()`

**Requirements:**
- [ ] Activities in parallel groups get +200 difficulty score boost (placed before non-parallel activities)
- [ ] Anchor activities get additional +50 boost (placed before non-anchor members)
- [ ] All activities in the same parallel group should be adjacent in the ordering
  ```php
  // After scoring, reorder so parallel group members are together
  // Anchor first, then members in sequence_order
  ```

### Task 3.4: Implement Parallel Placement in Backtracking
**File:** `FETSolver.php` → `backtrack()` method

**Requirements — Anchor Activity Placement:**
- [ ] When placing an anchor activity, check if its slot is available for ALL other activities in the parallel group
  ```php
  private function isSlotAvailableForParallelGroup(Slot $slot, int $groupId, $context): bool
  {
      foreach ($this->parallelGroupActivities[$groupId] as $siblingId) {
          if ($siblingId === $anchorId) continue;
          $siblingActivity = $this->activities[$siblingId];
          // Check: class not occupied, teacher not occupied, duration fits
          if (!$this->canPlaceActivityAtSlot($siblingActivity, $slot, $context)) {
              return false;
          }
      }
      return true;
  }
  ```
- [ ] Filter `getPossibleSlots()` for anchor: only return slots where all parallel siblings can also be placed

**Requirements — Non-Anchor Member Placement:**
- [ ] When placing a non-anchor member of a parallel group:
  - Check if the anchor has already been placed
  - If YES → force this activity to the SAME day+period as the anchor (only one candidate slot)
  - If NO → skip this activity (will be placed when anchor is placed)
- [ ] After anchor is placed, immediately place all members in the same slot

### Task 3.5: Implement `placeParallelGroup()` Method
**File:** `FETSolver.php`

**New method:**
```php
private function placeParallelGroup(int $groupId, Slot $anchorSlot, $solution, $context): bool
{
    // Place all non-anchor members at the same day+period as anchor
    foreach ($this->parallelGroupActivities[$groupId] as $activityId) {
        if ($activityId === $this->anchorActivity[$groupId]) continue;

        $activity = $this->activities[$activityId];
        $classKey = $this->getClassKey($activity);
        $memberSlot = new Slot($classKey, $anchorSlot->dayId, $anchorSlot->startIndex);

        if (!$this->isBasicSlotAvailable($memberSlot, $activity, $context, ignoreParallel: true)) {
            return false; // Cannot place all members → backtrack
        }

        $solution->place($activity, $memberSlot);
        $this->updateOccupancy($activity, $memberSlot, $context);
    }
    return true;
}
```

**Deliverables:**
- [ ] `placeParallelGroup()` method
- [ ] Integration with `backtrack()` — after placing anchor, call `placeParallelGroup()`
- [ ] If `placeParallelGroup()` fails, backtrack the anchor placement too
- [ ] Update `removeParallelGroup()` for backtracking — undo all member placements

### Task 3.6: Handle Parallel Groups in Greedy Fallback & Rescue Pass
**File:** `FETSolver.php`

**Requirements:**
- [ ] `greedyFallback()` — When placing anchor, attempt `placeParallelGroup()`. If fails, try next slot.
- [ ] `rescuePass()` — Parallel group members should be rescued as a unit (all or nothing). If one member can't be placed, none of them should be.
- [ ] `forcedPlacement()` — Force parallel group at best available slot. Log conflict if not all members can fit.

---

## STEP 4: Constraint Engine Integration

### Task 4.1: Create `ParallelPeriodConstraint` PHP Class
**File:** `Modules/SmartTimetable/app/Services/Constraints/Hard/ParallelPeriodConstraint.php`

**Requirements:**
- [ ] Extends `GenericHardConstraint`
- [ ] `passes(Slot $slot, Activity $activity, $context): bool`
  - If activity is in a parallel group AND is not the anchor → check if anchor is already placed → if yes, return `$slot matches anchor's day+period`
  - If activity is anchor → check if all siblings can be placed at this slot
- [ ] `getDescription()` → "Activities in the same parallel group must be scheduled at the same time"
- [ ] `getWeight()` → 100 (hard constraint)
- [ ] `isRelevant(Activity $activity)` → `return $activity->isInParallelGroup()`

### Task 4.2: Register in ConstraintFactory
**File:** `ConstraintFactory.php`

- [ ] Add to `CONSTRAINT_CLASS_MAP`:
  ```php
  'PARALLEL_PERIODS' => Hard\ParallelPeriodConstraint::class,
  ```

### Task 4.3: Seed `PARALLEL_PERIODS` Constraint Type
**File:** `ConstraintTypeSeeder.php`

- [ ] Add new entry:
  ```php
  [
      'code' => 'PARALLEL_PERIODS',
      'name' => 'Parallel Period Group',
      'category_id' => $cats['ACTIVITY'],
      'scope_id' => $scopes['INDIVIDUAL'],
      'constraint_level' => 'HARD',
      'default_weight' => 100,
      'is_hard_capable' => true,
      'is_soft_capable' => true,
      'parameter_schema' => json_encode([
          'parallel_group_id' => ['type' => 'integer'],
          'coordination_type' => ['type' => 'string', 'enum' => ['SAME_TIME', 'SAME_DAY', 'SAME_PERIOD_RANGE']],
      ]),
      'applicable_target_types' => json_encode([['target_type' => 'ACTIVITY']]),
      'is_active' => true,
  ]
  ```

---

## STEP 5: Pre-Generation Validation

### Task 5.1: Validate Parallel Groups Before Generation
**File:** `SmartTimetableController.php` or `ValidationService.php`

**Validation checks:**
- [ ] All activities in a parallel group must have the same `duration_periods`
- [ ] All activities in a parallel group must have the same `required_weekly_periods`
- [ ] No activity can belong to two parallel groups with conflicting constraints
- [ ] Each parallel group must have exactly one `is_anchor=1` activity
- [ ] Teacher assignments: no teacher assigned to multiple activities in the same parallel group (they'd conflict)
- [ ] Room requirements: enough rooms/room-types available for all activities in the group

**Error messages for each validation failure:**
```
"Parallel group '{name}': Activities have different durations ({2} vs {1}). All must match."
"Parallel group '{name}': Teacher '{teacherName}' is assigned to multiple activities in this group."
"Parallel group '{name}': No anchor activity set. Please designate one."
```

### Task 5.2: Warning for Unlinked Shared Activities
**Logic:**
- [ ] Check for activities with `is_shared_across_sections=1` (via their class subgroup) that are NOT in any parallel group
- [ ] Warn user: "Activity '{name}' is shared across sections but not linked to a parallel group. Sections may get it at different times."

---

## STEP 6: Post-Generation Verification & Storage

### Task 6.1: Verify Parallel Constraints in Generated Timetable
**File:** `SmartTimetableController.php` → after `$solver->solve()`

**Requirements:**
- [ ] For each parallel group, verify all member activities are placed at the same day+period
- [ ] Collect violations as `$parallelViolations[]`
- [ ] Pass to view: `$parallelViolations` for display in preview
- [ ] Store in session: `generated_parallel_violations`

### Task 6.2: Display Parallel Group Status in Preview
**File:** `resources/views/preview/partials/_timetable.blade.php`

**Requirements:**
- [ ] Visual indicator (color-coded badge) for cells that are part of a parallel group
- [ ] Tooltip showing: "Parallel Group: {groupName} — {N} sections at this slot"
- [ ] Violation highlight: red border if a parallel group member is NOT at the expected slot

### Task 6.3: Store Parallel Group Metadata in `storeTimetable()`
**File:** `SmartTimetableController.php` → `storeTimetable()`

**Requirements:**
- [ ] When creating `TimetableCell` records for parallel group activities, add metadata:
  - `parallel_group_id` field (may need column addition to `tt_timetable_cell`)
  - OR store in existing JSON field
- [ ] Log parallel group fulfillment in `ConflictDetectionService`

---

## STEP 7: Analytics & Reporting

### Task 7.1: Parallel Group Analytics in AnalyticsService
**File:** `AnalyticsService.php`

**Requirements:**
- [ ] `computeParallelGroupCompliance($timetableId)` method
  - For each parallel group: count activities placed at same slot vs total members
  - Calculate compliance percentage
  - Store in `tt_analytics_daily_snapshots` or return directly

### Task 7.2: Parallel Group Report View
**File:** `resources/views/analytics/reports/parallel-groups.blade.php`

**Requirements:**
- [ ] Table: Group Name | Type | Members | Compliance | Status (Full/Partial/Failed)
- [ ] Drill-down: click group to see member activities, their assigned slots, and mismatches

---

## STEP 8: ConflictDetection Integration

### Task 8.1: Detect Parallel Violations in ConflictDetectionService
**File:** `ConflictDetectionService.php`

**Requirements:**
- [ ] In `detectFromGrid()` and `detectFromCells()`, check parallel group constraints
- [ ] Create `ConflictDetection` records with:
  - `conflict_type` = 'PARALLEL_GROUP_VIOLATION'
  - `severity` = 'HIGH'
  - `details` = JSON with group_id, expected_slot, actual_slots per member

### Task 8.2: Parallel Group Conflict Resolution
**File:** `RefinementService.php`

**Requirements:**
- [ ] When a parallel group violation exists, suggest resolution: "Move all {N} activities to slot {day}_{period}"
- [ ] `swapCells()` should enforce: if swapping a parallel group member, offer to swap all members together
- [ ] `lockCell()` on a parallel group member should warn: "This activity is part of parallel group '{name}'. Locking may prevent group optimization."

---

## STEP 9: Tests

### Task 9.1: Unit Tests — ParallelGroup Model
**File:** `tests/Unit/SmartTimetable/ParallelGroupTest.php`

- [ ] Test `isInParallelGroup()` returns true/false correctly
- [ ] Test `getAnchorActivity()` returns correct activity
- [ ] Test `activities()` relationship loads correctly

### Task 9.2: Feature Tests — ParallelGroupController
**File:** `tests/Feature/SmartTimetable/ParallelGroupControllerTest.php`

- [ ] Test CRUD operations (create, read, update, delete)
- [ ] Test adding/removing activities from group
- [ ] Test setting anchor activity
- [ ] Test auto-detect endpoint

### Task 9.3: Integration Tests — Solver Parallel Placement
**File:** `tests/Feature/SmartTimetable/ParallelPeriodSolverTest.php`

- [ ] Test: 3 activities in parallel group → all placed at same day+period
- [ ] Test: Teacher conflict within parallel group → validation error before generation
- [ ] Test: Duration mismatch within parallel group → validation error
- [ ] Test: Backtracking correctly undoes all parallel group placements
- [ ] Test: Greedy fallback handles parallel groups

### Task 9.4: Validation Tests
**File:** `tests/Feature/SmartTimetable/ParallelGroupValidationTest.php`

- [ ] Test: Missing anchor → error
- [ ] Test: Different durations → error
- [ ] Test: Same teacher in multiple group activities → error
- [ ] Test: Unlinked shared activities → warning

---

## Implementation Order (Recommended)

```
Phase 1: Foundation (Steps 1-2)
  ├── Task 1.1 → 1.2 → 1.3 → 1.4 → 1.5 (Schema & Models)
  └── Task 2.1 → 2.2 → 2.3 → 2.4 (CRUD UI)
      └── Task 2.5 (Auto-detect — can be deferred)

Phase 2: Solver Core (Step 3) ← CRITICAL PATH
  ├── Task 3.1 → 3.2 → 3.3 (Load & Ordering)
  ├── Task 3.4 → 3.5 (Placement Logic) ← Most Complex
  └── Task 3.6 (Fallback Handling)

Phase 3: Constraint Engine (Step 4)
  ├── Task 4.1 → 4.2 → 4.3 (Constraint class + factory + seeder)
  └── Step 5 (Pre-Generation Validation)

Phase 4: Post-Generation (Steps 6-8)
  ├── Task 6.1 → 6.2 → 6.3 (Verify + Display + Store)
  ├── Task 7.1 → 7.2 (Analytics)
  └── Task 8.1 → 8.2 (Conflict Detection & Resolution)

Phase 5: Testing (Step 9)
  └── Tasks 9.1 → 9.2 → 9.3 → 9.4
```

---

## School-Specific Parallel Groups (From Requirements)

Once the system is built, these parallel groups need to be configured:

| Group Name | Type | Classes | Activities |
|-----------|------|---------|-----------|
| Class 6 Hobby | PARALLEL_HOBBY | 6A, 6B, 6C | Hobby activities for each section |
| Class 7 Hobby | PARALLEL_HOBBY | 7A, 7B, 7C | Hobby activities for each section |
| Class 8 Hobby | PARALLEL_HOBBY | 8A, 8B, 8C | Hobby activities for each section |
| Class 9 Hobby | PARALLEL_HOBBY | 9A, 9B, 9C | Hobby activities for each section |
| Class 11 Skill | PARALLEL_SKILL | 11A, 11B, 11C, 11D, 11E | Skill subject activities |
| Class 12 Skill | PARALLEL_SKILL | 12A, 12B, 12C, 12D, 12E | Skill subject activities |
| Class 11 Optional | PARALLEL_OPTIONAL | 11A, 11B, 11C, 11E | Optional subject activities |
| Class 12 Optional | PARALLEL_OPTIONAL | 12B, 12C, 12E | Optional subject activities |

**Key Detail:** Within each parallel group, DIFFERENT subjects may run simultaneously (e.g., in Class 11 Skill: Banking in 11A, AI in 11B, Taxation in 11C, Yoga in 11D, Mass Media in 11E). The constraint is that they all happen at the same TIME SLOT, not that they are the same subject.

---

## Summary

| Step | Tasks | Estimated Complexity | Dependencies |
|------|-------|---------------------|--------------|
| 1 — Schema & Models | 5 tasks | Medium | None |
| 2 — UI & API | 5 tasks | Medium | Step 1 |
| 3 — Solver Integration | 6 tasks | HIGH (most complex) | Steps 1, 2 |
| 4 — Constraint Engine | 3 tasks | Low-Medium | Step 3 |
| 5 — Pre-Gen Validation | 2 tasks | Low | Steps 1, 2 |
| 6 — Post-Gen & Storage | 3 tasks | Medium | Step 3 |
| 7 — Analytics | 2 tasks | Low | Step 6 |
| 8 — Conflict Detection | 2 tasks | Medium | Steps 3, 6 |
| 9 — Tests | 4 tasks | Medium | All above |

**Total: 9 Steps, 32 Tasks**

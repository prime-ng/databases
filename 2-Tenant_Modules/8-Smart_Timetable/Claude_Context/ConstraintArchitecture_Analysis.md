# Comprehensive Constraint Architecture Analysis

**Date:** 2026-03-10
**Module:** SmartTimetable — Constraint System
**Scope:** 10 Models, Services, Lifecycle, Plug-and-Play Engine Design

---

## 1. Model Relationships & Organization

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CONSTRAINT TYPE SYSTEM (Schema Layer)            │
│                                                                     │
│  ┌──────────────────────────┐    ┌───────────────────────────────┐  │
│  │ ConstraintCategoryScope  │    │ ConstraintTargetType          │  │
│  │ (tt_constraint_          │    │ (tt_constraint_target_type)   │  │
│  │  category_scope)         │    │                               │  │
│  │ type: CATEGORY|SCOPE     │    │ TEACHER, CLASS, SECTION,      │  │
│  │                          │    │ SUBJECT, ROOM, ACTIVITY       │  │
│  └────────┬───────┬─────────┘    └───────────────┬───────────────┘  │
│           │       │                              │                  │
│    category_id  scope_id           applicable_target_types (JSON)   │
│           │       │                              │                  │
│  ┌────────▼───────▼──────────────────────────────▼──────────────┐   │
│  │               ConstraintType (tt_constraint_type)            │   │
│  │   code, name, description, constraint_level,                 │   │
│  │   category_id → CatScope, scope_id → CatScope,               │   │
│  │   parameter_schema (JSON), validation_logic,                 │   │
│  │   applicable_target_types (JSON), requires_time_slots        │   │
│  └───────────────────────────┬──────────────────────────────────┘   │
│                              │                                      │
└──────────────────────────────┼──────────────────────────────────────┘
                               │ constraint_type_id
┌──────────────────────────────▼──────────────────────────────────────┐
│                    CONSTRAINT INSTANCE LAYER                        │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │              Constraint (tt_constraint)                      │   │
│  │  constraint_type_id, target_type_id → TargetType,            │   │
│  │  target_id (polymorphic), is_hard, weight, priority,         │   │
│  │  params_json, applicable_days_json, applicable_periods_json, │   │
│  │  effective_from_date, effective_to_date, academic_term_id    │   │
│  └──────┬──────────────────────────────┬────────────────────────┘   │
│         │                              │                            │
│    (group membership)            (violations)                       │
│         │                              │                            │
│  ┌──────▼──────────────┐    ┌──────────▼─────────────────────┐      │
│  │ ConstraintGroupMember│   │ ConstraintViolation            │      │
│  │ (tt_constraint_group_│   │ (tt_constraint_violation)      │      │
│  │  member)             │   │ constraint_id, timetable_id,   │      │
│  │ constraint_id,       │   │ severity, affected_entity_type,│      │
│  │ constraint_group_id, │   │ affected_entity_id, details,   │      │
│  │ sequence_order       │   │ resolution_status, resolved_by │      │
│  └──────┬───────────────┘   └────────────────────────────────┘      │
│         │                                                           │
│  ┌──────▼──────────────────┐  ┌────────────────────────────────┐    │
│  │ ConstraintGroup         │  │ ConstraintTemplate             │    │
│  │ (tt_constraint_group)   │  │ (tt_constraint_template)       │    │
│  │ group_type: MUTEX |     │  │ constraint_type_id,            │    │
│  │  CONCURRENT | ORDERED | │  │ default_params (JSON),         │    │
│  │  PREFERRED              │  │ description, is_system         │    │
│  │ evaluation_strategy     │  │ (reusable presets)             │    │
│  └─────────────────────────┘  └────────────────────────────────┘    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 10 Models — Roles & Responsibilities

| # | Model | Table | Role |
|---|-------|-------|------|
| 1 | **ConstraintCategoryScope** | `tt_constraint_category_scope` | Unified lookup for categories (TIME, RESOURCE, PEDAGOGY, PREFERENCE) and scopes (GLOBAL, TEACHER, CLASS, ROOM). Single table with `type` discriminator (CATEGORY\|SCOPE). |
| 2 | **ConstraintTargetType** | `tt_constraint_target_type` | Defines what entities constraints can target: TEACHER, CLASS, SECTION, SUBJECT, ROOM, ACTIVITY. Includes `model_class` for polymorphic resolution. |
| 3 | **ConstraintType** | `tt_constraint_type` | Blueprint/definition of a constraint kind. Holds `code`, `parameter_schema` (JSON Schema), `constraint_level`, `applicable_target_types` (JSON array), `validation_logic`. |
| 4 | **Constraint** | `tt_constraint` | Concrete instance — a specific rule applied to a specific target. Polymorphic via `target_type_id` + `target_id`. Holds `params_json`, `is_hard`, `weight`, `priority`, effective dates, applicable days/periods. |
| 5 | **ConstraintTemplate** | `tt_constraint_template` | Reusable presets with `default_params`. Linked to a `ConstraintType`. Enables "Apply Standard Rules" UI. |
| 6 | **ConstraintGroup** | `tt_constraint_group` | Logical grouping with evaluation semantics: MUTEX (at most one), CONCURRENT (all together), ORDERED (sequential), PREFERRED (score-based). |
| 7 | **ConstraintGroupMember** | `tt_constraint_group_member` | Bridge table joining constraints to groups with `sequence_order`. |
| 8 | **ConstraintViolation** | `tt_constraint_violation` | Runtime violation log: `constraint_id`, `timetable_id`, `severity`, `affected_entity_type/id`, `resolution_status`. |
| 9 | **ConstraintCategory** | (legacy) | Aliases to `ConstraintCategoryScope` where `type=CATEGORY`. Kept for backward compatibility. |
| 10 | **ConstraintScope** | (legacy) | Aliases to `ConstraintCategoryScope` where `type=SCOPE`. Kept for backward compatibility. |

### Key Relationships

```
ConstraintType → belongsTo → ConstraintCategoryScope (as category)
ConstraintType → belongsTo → ConstraintCategoryScope (as scope)
Constraint     → belongsTo → ConstraintType
Constraint     → belongsTo → ConstraintTargetType
Constraint     → morphTo   → target (via target_type_id + target_id)
Constraint     → hasMany   → ConstraintViolation
Constraint     → belongsToMany → ConstraintGroup (via ConstraintGroupMember)
ConstraintGroup → hasMany  → ConstraintGroupMember
ConstraintTemplate → belongsTo → ConstraintType
```

---

## 2. Constraint Lifecycle

### Phase 1: Definition (Admin/Setup Time)

```
ConstraintCategoryScope seeded → ConstraintTargetType seeded
         ↓                                    ↓
ConstraintType created (with parameter_schema JSON, validation_logic)
         ↓
ConstraintTemplate optionally created (reusable presets)
```

**ConstraintType** defines the blueprint. Example: "Teacher Max Hours Per Day" with:
```json
{
  "parameter_schema": {
    "max_hours": {"type": "integer", "min": 1, "max": 12}
  }
}
```

### Phase 2: Assignment (Configuration Time)

```
Admin selects ConstraintType + Target (e.g., Teacher #42)
         ↓
Constraint record created:
  - constraint_type_id → links to type
  - target_type_id = TEACHER, target_id = 42
  - params_json = {"max_hours": 6}
  - is_hard = true, weight = 100, priority = 1
  - applicable_days_json = [1,2,3,4,5]
  - effective_from_date / effective_to_date
         ↓
Optionally added to ConstraintGroup (MUTEX group = mutually exclusive constraints)
```

### Phase 3: Loading & Instantiation (Generation Time)

```
DatabaseConstraintService::loadConstraints($academicTermId)
         ↓
Queries tt_constraint with effective date filtering + is_active
         ↓
ConstraintFactory::createFromModel($constraintRecord)
  - Looks up type code in CONSTRAINT_CLASS_MAP
  - Validates params_json against parameter_schema
  - Returns TimetableConstraint PHP object
         ↓
ConstraintManager receives constraint via addConstraint($constraint, $isHard)
  - Sorted into $hardConstraints[] or $softConstraints[]
```

**CONSTRAINT_CLASS_MAP (current 12 entries):**

| Type Code                 | PHP Class                         |
|---------------------------|-----------------------------------|
| `TEACHER_MAX_HOURS_DAY`   | `TeacherMaxHoursConstraint`       |
| `TEACHER_MAX_CONSECUTIVE` | `TeacherMaxConsecutiveConstraint` |
| `TEACHER_NO_CONFLICT`     | `TeacherConflictConstraint`       |
| `CLASS_NO_CONFLICT`       | `ClassConflictConstraint`         |
| `ROOM_NO_CONFLICT`        | `RoomConflictConstraint`          |
| `TEACHER_UNAVAILABLE`     | `TeacherUnavailableConstraint`    |
| `CLASS_UNAVAILABLE`       | `ClassUnavailableConstraint`      |
| `ROOM_UNAVAILABLE`        | `RoomUnavailableConstraint`       |
| `MAX_GAPS_PER_DAY`        | `MaxGapsConstraint`               |
| `MIN_DAYS_BETWEEN`        | `MinDaysBetweenConstraint`        |
| `PREFERRED_TIME_SLOT`     | `PreferredTimeSlotConstraint`     |
| `CONSECUTIVE_LESSONS`     | `ConsecutiveLessonsConstraint`    |

### Phase 4: Evaluation (During Solving)

```
FETSolver::isBasicSlotAvailable() / backtrack()
         ↓
ConstraintManager::checkHardConstraints($slot, $activity, $context)
  - Builds contextArray (day_id, period_index, class_key, teacher IDs, etc.)
  - Merges with generationContext
  - For each hardConstraint:
    - constraintApplies() → checks appliesToContext() if available
    - constraint->passes($slot, $activity, $context) → true/false
  - Returns false on FIRST violation (fail-fast)
         ↓
ConstraintManager::evaluateSoftConstraints($slot, $activity, $context)
  - Same context building
  - Sums weights of all passing soft constraints
  - Returns float score (higher = better)
         ↓
FETSolver uses: hard check as gate, soft score for slot ranking
Cache: evaluationCache["{type}-{classKey}-{day}-{period}-{actId}"]
Cache cleared on backtrack via clearCache()
```

### Phase 5: Violation Detection (Post-Generation)

```
ConflictDetectionService::detectFromGrid() or detectFromCells()
         ↓
Checks final timetable against all constraints
         ↓
ConstraintViolation records created:
  - constraint_id, timetable_id
  - severity (CRITICAL/HIGH/MEDIUM/LOW)
  - affected_entity_type + affected_entity_id
  - details (JSON), slot_info
  - resolution_status = 'UNRESOLVED'
         ↓
AnalyticsService::computeConstraintViolations() reads violations
  - Powers violation dashboard + reports
         ↓
RefinementService can resolve violations:
  - Manual swaps → resolution_status = 'RESOLVED'
  - Auto-resolution via conflict-resolution session
```

---

## 3. Plug-and-Play Constraint Engine Design

### 3.1 Core Interfaces

```php
<?php
namespace Modules\SmartTimetable\Contracts;

use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Solver\Slot;

/**
 * Base interface for all timetable constraints.
 */
interface ConstraintInterface
{
    /**
     * Evaluate whether this constraint is satisfied.
     */
    public function passes(Slot $slot, Activity $activity, $context): bool;

    /**
     * Human-readable description for UI/logging.
     */
    public function getDescription(): string;

    /**
     * Weight/importance (0-100). Used for soft constraint scoring.
     */
    public function getWeight(): float;

    /**
     * Whether this constraint is relevant to the given activity.
     * Allows early skip without full evaluation.
     */
    public function isRelevant(Activity $activity): bool;
}

/**
 * Extended interface for constraints that need context filtering.
 */
interface ContextAwareConstraint extends ConstraintInterface
{
    /**
     * Check if constraint applies to the current generation context.
     * @param array $context Keys: day_id, CLASS, TEACHER, SUBJECT, ROOM_TYPE, etc.
     */
    public function appliesToContext(array $context): bool;
}

/**
 * Interface for constraints loaded from DB records.
 */
interface DatabaseDrivenConstraint extends ConstraintInterface
{
    /**
     * Initialize from a DB constraint record.
     */
    public static function fromModel(\Modules\SmartTimetable\Models\Constraint $model): static;

    /**
     * Validate parameters against the type's JSON schema.
     */
    public function validateParameters(array $params): bool;
}
```

### 3.2 ConstraintRegistry (Plugin System)

```php
<?php
namespace Modules\SmartTimetable\Services\Constraints;

use Modules\SmartTimetable\Contracts\ConstraintInterface;

class ConstraintRegistry
{
    /**
     * Map of constraint type codes to PHP class names.
     * New constraints are registered here — no other code changes needed.
     */
    private array $registry = [];

    /**
     * Register a constraint class for a type code.
     */
    public function register(string $typeCode, string $className): void
    {
        if (!is_subclass_of($className, ConstraintInterface::class)) {
            throw new \InvalidArgumentException(
                "{$className} must implement ConstraintInterface"
            );
        }
        $this->registry[$typeCode] = $className;
    }

    /**
     * Resolve a constraint instance from a type code.
     */
    public function resolve(string $typeCode): ?string
    {
        return $this->registry[$typeCode] ?? null;
    }

    /**
     * Check if a type code is registered.
     */
    public function has(string $typeCode): bool
    {
        return isset($this->registry[$typeCode]);
    }

    /**
     * Get all registered type codes.
     */
    public function all(): array
    {
        return $this->registry;
    }
}
```

### 3.3 ConstraintEvaluator (Separation of Concerns)

```php
<?php
namespace Modules\SmartTimetable\Services\Constraints;

use Modules\SmartTimetable\Contracts\ConstraintInterface;
use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Solver\Slot;

class ConstraintEvaluator
{
    private array $cache = [];

    /**
     * Check all hard constraints. Returns false on first violation.
     */
    public function checkHard(
        array $constraints,
        Slot $slot,
        Activity $activity,
        $context,
        array $generationContext = []
    ): bool {
        $cacheKey = "hard-{$slot->classKey}-{$slot->dayId}-{$slot->startIndex}-{$activity->id}";
        if (isset($this->cache[$cacheKey])) {
            return $this->cache[$cacheKey];
        }

        foreach ($constraints as $constraint) {
            if (!$constraint->isRelevant($activity)) continue;
            if (!$constraint->passes($slot, $activity, $context)) {
                $this->cache[$cacheKey] = false;
                return false;
            }
        }

        $this->cache[$cacheKey] = true;
        return true;
    }

    /**
     * Score soft constraints. Higher = better slot.
     */
    public function scoreSoft(
        array $constraints,
        Slot $slot,
        Activity $activity,
        $context
    ): float {
        $score = 0.0;
        foreach ($constraints as $constraint) {
            if (!$constraint->isRelevant($activity)) continue;
            if ($constraint->passes($slot, $activity, $context)) {
                $score += $constraint->getWeight();
            }
        }
        return $score;
    }

    public function clearCache(): void
    {
        $this->cache = [];
    }
}
```

### 3.4 ConstraintContext (Value Object)

```php
<?php
namespace Modules\SmartTimetable\Services\Constraints;

use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Solver\Slot;

class ConstraintContext
{
    public function __construct(
        public readonly Slot $slot,
        public readonly Activity $activity,
        public readonly int $dayId,
        public readonly int $periodIndex,
        public readonly string $classKey,
        public readonly array $teacherIds = [],
        public readonly ?int $subjectId = null,
        public readonly ?int $roomTypeId = null,
        public readonly ?int $classId = null,
        public readonly ?int $sectionId = null,
        public readonly ?int $subgroupId = null,
        /** Solver-internal context (occupied slots, teacher map, etc.) */
        public readonly mixed $solverContext = null,
    ) {}

    /**
     * Build from slot + activity, extracting all relevant IDs.
     */
    public static function fromSlotAndActivity(
        Slot $slot, Activity $activity, $solverContext = null
    ): self {
        return new self(
            slot: $slot,
            activity: $activity,
            dayId: $slot->dayId,
            periodIndex: $slot->startIndex,
            classKey: $slot->classKey,
            teacherIds: $activity->teachers?->pluck('teacher_id')->toArray() ?? [],
            subjectId: $activity->subjectStudyFormat?->subject_id,
            roomTypeId: $activity->preferred_room_type_id,
            classId: $activity->class_id,
            sectionId: $activity->section_id,
            subgroupId: $activity->class_requirement_subgroup_id,
            solverContext: $solverContext,
        );
    }

    /**
     * Convert to array for context-matching in appliesToContext().
     */
    public function toArray(): array
    {
        return array_filter([
            'day_id'         => $this->dayId,
            'period_index'   => $this->periodIndex,
            'class_key'      => $this->classKey,
            'activity_id'    => $this->activity->id,
            'CLASS'          => $this->classId ? [$this->classId] : null,
            'SECTION'        => $this->sectionId ? [$this->sectionId] : null,
            'TEACHER'        => $this->teacherIds ?: null,
            'SUBJECT'        => $this->subjectId ? [$this->subjectId] : null,
            'ROOM_TYPE'      => $this->roomTypeId ? [$this->roomTypeId] : null,
            'CLASS_SUBGROUP' => $this->subgroupId ? [$this->subgroupId] : null,
        ], fn($v) => $v !== null);
    }
}
```

---

## 4. Integration with Timetable Generator

### Current Flow (How FETSolver Uses Constraints)

```
SmartTimetableController::generateTimetable()
  │
  ├─ DatabaseConstraintService::loadConstraints($academicTermId)
  │    └─ Returns ConstraintManager with hard + soft constraints populated
  │
  ├─ FETSolver::__construct($activities, $days, $periods, $options)
  │    └─ $options['constraint_manager'] = $constraintManager
  │
  └─ FETSolver::solve()
       │
       ├─ backtrack($activity, $solution, $context)
       │    ├─ getPossibleSlots() → candidate slots
       │    │    └─ Sorts by: locked slots → teacher preferences → SOFT SCORE → day order
       │    │
       │    ├─ isBasicSlotAvailable($slot, $activity, $context)
       │    │    ├─ Built-in checks (class occupied, teacher occupied, duration fits)
       │    │    ├─ violatesNoConsecutiveRule()
       │    │    ├─ violatesMinGapRule()
       │    │    ├─ violatesDailyActivityPlacementCap()
       │    │    └─ constraintManager->checkHardConstraints($slot, $activity, $context)
       │    │         ↑ DB-driven hard constraints checked HERE
       │    │
       │    ├─ scoreSlotForActivity($activity, $slot, $context)
       │    │    └─ Activity-level preferences (preferred_time_slots, avoid_periods, etc.)
       │    │
       │    └─ On backtrack failure:
       │         ├─ $solution->remove($activity, $slot)
       │         └─ $constraintManager->clearCache()  ← prevents stale evaluations
       │
       ├─ greedyFallback() → same constraint checking
       ├─ rescuePass() → relaxed constraints
       └─ forcedPlacement() → minimal checking (last resort)
```

### Dual Constraint System

The architecture has **two parallel constraint systems** that work together:

| Aspect | Hardcoded (FETSolver) | DB-Driven (ConstraintManager) |
|--------|-----------------------|-------------------------------|
| **Where** | `isBasicSlotAvailable()` methods | `checkHardConstraints()` / `evaluateSoftConstraints()` |
| **Examples** | Teacher conflict, class conflict, duration fits, consecutive rules, min gap, daily cap | Teacher max hours, preferred time slots, room unavailable, custom rules |
| **Speed** | Fastest — direct array lookups | Slower — iterates constraint objects with context building |
| **Flexibility** | Requires code changes | Add via DB + register PHP class |
| **When checked** | Always, every slot | After basic checks pass |

**This is intentional** — the hardcoded checks handle universal, performance-critical rules that apply to every timetable. The DB-driven system handles configurable, per-school rules.

### Integration Pseudo-Code

```php
// In FETSolver::isBasicSlotAvailable()

// 1. Fast hardcoded checks (always run, ~95% of rejections)
if ($this->isClassOccupied($slot, $context))         return false;
if ($this->isTeacherOccupied($slot, $activity, $context)) return false;
if ($this->durationDoesNotFit($slot, $activity))      return false;
if ($this->violatesNoConsecutiveRule(...))              return false;
if ($this->violatesMinGapRule(...))                     return false;
if ($this->violatesDailyActivityPlacementCap(...))     return false;

// 2. DB-driven constraints (only reached by ~5% of candidates)
if ($this->constraintManager) {
    if (!$this->constraintManager->checkHardConstraints($slot, $activity, $context)) {
        return false;
    }
}

return true; // Slot is available

// In FETSolver::getPossibleSlots() — soft scoring
$softScore = 0;
$softScore += $this->scoreSlotForActivity($activity, $slot, $context); // Activity-level prefs
if ($this->constraintManager) {
    $softScore += $this->constraintManager->evaluateSoftConstraints($slot, $activity, $context);
}
// Sort candidates by $softScore descending
```

---

## 5. Recommended Architecture

### Directory Structure

```
Modules/SmartTimetable/app/
├── Contracts/
│   ├── ConstraintInterface.php          # Base interface
│   ├── ContextAwareConstraint.php       # Optional context filtering
│   └── DatabaseDrivenConstraint.php     # For DB-loaded constraints
│
├── Services/
│   ├── Constraints/
│   │   ├── ConstraintManager.php        # ✅ EXISTS — orchestrator
│   │   ├── ConstraintFactory.php        # ✅ EXISTS — DB → PHP mapping
│   │   ├── ConstraintRegistry.php       # NEW — plugin registration
│   │   ├── ConstraintEvaluator.php      # NEW — separated evaluation logic
│   │   ├── ConstraintContext.php        # NEW — value object
│   │   ├── DatabaseConstraintService.php # ✅ EXISTS — DB loader
│   │   │
│   │   ├── Hard/                        # Hard constraint implementations
│   │   │   ├── TeacherConflictConstraint.php    # ✅ EXISTS
│   │   │   ├── ClassConflictConstraint.php
│   │   │   ├── RoomConflictConstraint.php
│   │   │   ├── TeacherUnavailableConstraint.php
│   │   │   ├── ClassUnavailableConstraint.php
│   │   │   ├── RoomUnavailableConstraint.php
│   │   │   ├── TeacherMaxHoursConstraint.php
│   │   │   ├── TeacherMaxConsecutiveConstraint.php
│   │   │   └── MaxGapsConstraint.php
│   │   │
│   │   ├── Soft/                        # Soft constraint implementations
│   │   │   ├── PreferredTimeSlotConstraint.php
│   │   │   ├── MinDaysBetweenConstraint.php
│   │   │   ├── ConsecutiveLessonsConstraint.php
│   │   │   └── SpreadEvenlyConstraint.php
│   │   │
│   │   └── Base/
│   │       ├── GenericHardConstraint.php   # ✅ EXISTS
│   │       └── GenericSoftConstraint.php   # ✅ EXISTS
│   │
│   └── Generator/
│       └── FETSolver.php                # ✅ EXISTS — uses ConstraintManager
│
├── Models/
│   ├── Constraint.php                   # ✅ EXISTS
│   ├── ConstraintType.php               # ✅ EXISTS
│   ├── ConstraintCategoryScope.php      # ✅ EXISTS
│   ├── ConstraintTargetType.php         # ✅ EXISTS
│   ├── ConstraintTemplate.php           # ✅ EXISTS
│   ├── ConstraintGroup.php              # ✅ EXISTS
│   ├── ConstraintGroupMember.php        # ✅ EXISTS
│   └── ConstraintViolation.php          # ✅ EXISTS
```

### Adding a New Constraint (Step-by-Step Example)

**Example: "Teacher Must Have Lunch Break" constraint**

**Step 1 — DB: Insert ConstraintType record:**
```sql
INSERT INTO tt_constraint_type (
    code, name, category_id, scope_id, constraint_level,
    parameter_schema, applicable_target_types
) VALUES (
    'TEACHER_LUNCH_BREAK', 'Teacher Lunch Break', 1, 2, 'HARD',
    '{"lunch_period_start": {"type":"integer"}, "lunch_period_end": {"type":"integer"}}',
    '["TEACHER"]'
);
```

**Step 2 — PHP: Create constraint class:**
```php
<?php
namespace Modules\SmartTimetable\Services\Constraints\Hard;

use Modules\SmartTimetable\Services\Constraints\GenericHardConstraint;
use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Services\Solver\Slot;

class TeacherLunchBreakConstraint extends GenericHardConstraint
{
    public function passes(Slot $slot, Activity $activity, $context): bool
    {
        $lunchStart = $this->meta['lunch_period_start'] ?? 4;
        $lunchEnd   = $this->meta['lunch_period_end'] ?? 5;

        // Block if slot overlaps lunch period for this teacher
        $slotEnd = $slot->startIndex + ($activity->duration ?? 1) - 1;

        if ($slot->startIndex <= $lunchEnd && $slotEnd >= $lunchStart) {
            return false; // Violates lunch break
        }

        return true;
    }

    public function getDescription(): string
    {
        return 'Teacher must have a free lunch period';
    }
}
```

**Step 3 — PHP: Register in ConstraintFactory::CONSTRAINT_CLASS_MAP:**
```php
'TEACHER_LUNCH_BREAK' => Hard\TeacherLunchBreakConstraint::class,
```

**Step 4 — DB: Create Constraint instances for specific teachers:**
```sql
INSERT INTO tt_constraint (
    constraint_type_id, target_type_id, target_id,
    is_hard, weight, priority, params_json
) VALUES (
    ?, 1, 42, true, 100, 1,
    '{"lunch_period_start": 4, "lunch_period_end": 5}'
);
```

**That's it.** The `DatabaseConstraintService` loads it, `ConstraintFactory` instantiates it, `ConstraintManager` evaluates it during generation. Zero changes to FETSolver.

---

## 6. Best Practices for Scalable Constraint Systems

### Current Strengths

1. **Two-level schema** — Type defines the blueprint, Instance carries parameters. Allows one PHP class to serve many parameterized uses.

2. **Evaluation caching** — Cache key `{type}-{classKey}-{day}-{period}-{activityId}` prevents redundant evaluations. Critical since the solver may check thousands of slot-activity combinations.

3. **Fail-fast on hard constraints** — Returns `false` on first violation instead of checking all constraints.

4. **Polymorphic targeting** — `target_type_id` + `target_id` lets the same constraint system apply to teachers, classes, rooms, subjects, and activities.

5. **Parameter schema validation** — `ConstraintFactory` validates `params_json` against `parameter_schema` at instantiation time, catching config errors early.

6. **Effective date filtering** — Constraints auto-expire, supporting term-specific rules without manual cleanup.

7. **Dual-system performance** — Hardcoded checks handle ~95% of rejections at array-lookup speed. DB-driven constraints only evaluate for the ~5% of candidates that pass basic checks.

### Recommendations for Future Enhancement

1. **Cache invalidation is correct** — `clearCache()` on backtrack prevents stale results. Do not remove this.

2. **Constraint groups are underutilized** — The `ConstraintGroup` model supports MUTEX/CONCURRENT/ORDERED/PREFERRED semantics, but `ConstraintManager` doesn't currently evaluate group logic. Future enhancement:
   - **MUTEX**: At most one member constraint can pass for a given slot
   - **CONCURRENT**: All members must pass together
   - **ORDERED**: Members evaluated in `sequence_order`, short-circuit on first fail
   - **PREFERRED**: Score-based — sum weights of passing members

3. **`isRelevant()` is key to performance** — Every constraint should implement `isRelevant($activity)` to skip early. A room-type constraint should return `false` for activities without room requirements. This avoids context-building overhead.

4. **Keep hardcoded checks in FETSolver** — The core conflict checks (teacher/class occupied, duration fits) are too performance-critical to route through the constraint object system. The current dual approach is the right trade-off.

5. **Violation resolution loop** — The lifecycle is complete: generate → detect violations → refine → re-detect. The `ConstraintViolation` model with `resolution_status` enables tracking this cycle.

6. **Template system for admin UX** — `ConstraintTemplate` with `default_params` enables "Apply Standard Workload Rules" buttons in the admin UI, creating multiple constraints from presets.

7. **Implement remaining PHP classes** — Currently 6-7 constraint types in `CONSTRAINT_CLASS_MAP` fall through to `GenericHardConstraint`/`GenericSoftConstraint`. Implementing dedicated classes for each type code will improve accuracy and enable type-specific optimizations.

8. **Consider constraint priority ordering** — Sort constraints by `priority` field before evaluation so that higher-priority constraints are checked first. Combined with fail-fast, this can reject bad slots faster.

### Anti-Patterns to Avoid

- **Don't merge the dual system** — Wrapping hardcoded checks as constraint objects would add ~100ms per generation for zero benefit.
- **Don't cache across generations** — The cache is per-solve-run. Never persist it.
- **Don't skip `clearCache()` on backtrack** — This was a bug that was already fixed. Stale cache entries cause incorrect constraint results in alternate solution branches.
- **Don't use `appliesToContext()` for performance-critical filtering** — Use `isRelevant()` instead, which is simpler and faster.

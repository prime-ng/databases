# P09 — Constraint Architecture Foundation

**Phase:** 11 | **Priority:** P1 | **Effort:** 3 days
**Skill:** Backend | **Model:** Opus (complex architecture)
**Branch:** Tarun_SmartTimetable
**Dependencies:** P05 (Phase 3 activity constraints)
**Reference:** `2026Mar10_ConstraintArchitecture_Analysis.md` §3

---

## Pre-Requisites

Read ALL of these before starting:
1. `Claude_Context/2026Mar10_ConstraintArchitecture_Analysis.md` — Full architecture with 10 models
2. `Claude_Context/2026Mar10_ConstraintList_and_Categories.md` — All 155+ rules
3. `Modules/SmartTimetable/app/Services/Constraints/ConstraintFactory.php` — current CONSTRAINT_CLASS_MAP
4. `Modules/SmartTimetable/app/Services/Constraints/ConstraintManager.php` — current evaluation
5. `Modules/SmartTimetable/app/Services/Generator/FETConstraintBridge.php` — currently broken
6. `Modules/SmartTimetable/app/Services/Constraints/Hard/GenericHardConstraint.php` — base class
7. `Modules/SmartTimetable/app/Services/Constraints/Soft/GenericSoftConstraint.php` — base class
8. `Modules/SmartTimetable/app/Services/Constraints/TimetableConstraint.php` — interface
9. `Modules/SmartTimetable/app/Models/ConstraintGroup.php`
10. `Modules/SmartTimetable/app/Models/ConstraintGroupMember.php`

---

## Task 11.1 — Create ConstraintRegistry (plugin system) (4 hrs)

**File:** `Modules/SmartTimetable/app/Services/Constraints/ConstraintRegistry.php` (NEW)

**Purpose:** Replace hardcoded `CONSTRAINT_CLASS_MAP` array in ConstraintFactory with a dynamic registry.

```php
<?php

namespace Modules\SmartTimetable\Services\Constraints;

class ConstraintRegistry
{
    protected static array $registry = [];

    /**
     * Register a constraint class for a constraint type code.
     */
    public static function register(string $typeCode, string $constraintClass): void
    {
        if (!class_exists($constraintClass)) {
            throw new \InvalidArgumentException("Constraint class {$constraintClass} does not exist.");
        }
        static::$registry[strtoupper($typeCode)] = $constraintClass;
    }

    /**
     * Register multiple constraint classes at once.
     */
    public static function registerMany(array $mappings): void
    {
        foreach ($mappings as $typeCode => $constraintClass) {
            static::register($typeCode, $constraintClass);
        }
    }

    /**
     * Resolve a constraint class for a given type code.
     * Falls through to GenericHardConstraint or GenericSoftConstraint if not registered.
     */
    public static function resolve(string $typeCode, bool $isHard = true): string
    {
        $code = strtoupper($typeCode);

        if (isset(static::$registry[$code])) {
            return static::$registry[$code];
        }

        // Fallback to generic
        return $isHard
            ? Hard\GenericHardConstraint::class
            : Soft\GenericSoftConstraint::class;
    }

    /**
     * Check if a specific type code has a dedicated PHP class.
     */
    public static function isRegistered(string $typeCode): bool
    {
        return isset(static::$registry[strtoupper($typeCode)]);
    }

    /**
     * Get all registered constraint type codes.
     */
    public static function all(): array
    {
        return static::$registry;
    }

    /**
     * Clear the registry (for testing).
     */
    public static function clear(): void
    {
        static::$registry = [];
    }
}
```

**Wire into ConstraintFactory:** Update `ConstraintFactory::createFromModel()`:
```php
public static function createFromModel($constraintModel): TimetableConstraint
{
    $typeCode = $constraintModel->constraintType->code ?? '';
    $isHard = $constraintModel->is_hard ?? true;

    $className = ConstraintRegistry::resolve($typeCode, $isHard);

    return new $className($constraintModel);
}
```

**Register existing classes in `SmartTimetableServiceProvider::boot()`:**
```php
use Modules\SmartTimetable\Services\Constraints\ConstraintRegistry;

public function boot(): void
{
    // ... existing boot code ...

    // Register constraint classes
    ConstraintRegistry::registerMany([
        'PARALLEL_PERIODS' => Hard\ParallelPeriodConstraint::class,
        'LUNCH_BREAK' => Hard\LunchBreakConstraint::class,
        'SHORT_BREAK' => Hard\ShortBreakConstraint::class,
        'BREAK_PERIOD' => Hard\BreakConstraint::class,
        'TEACHER_CONFLICT' => Hard\TeacherConflictConstraint::class,
        'ROOM_AVAILABILITY' => Hard\RoomAvailabilityConstraint::class,
        'MAX_DAILY_LOAD' => Hard\MaximumDailyLoadConstraint::class,
        'NO_SAME_SUBJECT_SAME_DAY' => Hard\NoSameSubjectSameDayConstraint::class,
        'FIXED_PERIOD_HIGH_PRIORITY' => Hard\FixedPeriodForHighPriorityConstraint::class,
        'HIGH_PRIORITY_FIXED_PERIOD' => Hard\HighPriorityFixedPeriodConstraint::class,
        'DAILY_SPREAD' => Hard\DailySpreadConstraint::class,
        'PREFERRED_TIME_OF_DAY' => Soft\PreferredTimeOfDayConstraint::class,
        'BALANCED_DAILY_SCHEDULE' => Soft\BalancedDailyScheduleConstraint::class,
    ]);
}
```

**Remove** the `CONSTRAINT_CLASS_MAP` constant from `ConstraintFactory.php` (it's now in ConstraintRegistry).

---

## Task 11.2 — Create ConstraintContext value object (2 hrs)

**File:** `Modules/SmartTimetable/app/Services/Constraints/ConstraintContext.php` (NEW)

```php
<?php

namespace Modules\SmartTimetable\Services\Constraints;

class ConstraintContext
{
    public function __construct(
        public readonly int $dayId,
        public readonly int $periodIndex,
        public readonly string $classKey,
        public readonly array $teacherIds,
        public readonly ?int $subjectId,
        public readonly ?int $roomTypeId,
        public readonly ?int $classId,
        public readonly ?int $sectionId,
        public readonly ?int $classSectionId,
        public readonly ?object $activity,
        public readonly ?object $slot = null,
        public readonly array $extra = [],
    ) {}

    /**
     * Build from activity + slot data (most common usage).
     */
    public static function fromActivityAndSlot(object $activity, int $dayId, int $periodIndex): self
    {
        return new self(
            dayId: $dayId,
            periodIndex: $periodIndex,
            classKey: $activity->class_section_id
                ? "cs_{$activity->class_section_id}"
                : "c_{$activity->class_id}",
            teacherIds: is_array($activity->teacher_ids)
                ? $activity->teacher_ids
                : (json_decode($activity->teacher_ids ?? '[]', true) ?: []),
            subjectId: $activity->subject_id ?? null,
            roomTypeId: $activity->required_room_type_id ?? null,
            classId: $activity->class_id ?? null,
            sectionId: $activity->section_id ?? null,
            classSectionId: $activity->class_section_id ?? null,
            activity: $activity,
        );
    }

    /**
     * Get a value from the extra array.
     */
    public function get(string $key, mixed $default = null): mixed
    {
        return $this->extra[$key] ?? $default;
    }
}
```

**Update ConstraintManager** to use ConstraintContext instead of ad-hoc arrays in `checkHardConstraints()` and `evaluateSoftConstraints()`. Replace `$context` arrays with `ConstraintContext` objects.

---

## Task 11.3 — Create ConstraintEvaluator (4 hrs)

**File:** `Modules/SmartTimetable/app/Services/Constraints/ConstraintEvaluator.php` (NEW)

```php
<?php

namespace Modules\SmartTimetable\Services\Constraints;

use Illuminate\Support\Collection;

class ConstraintEvaluator
{
    protected array $hardCache = [];
    protected array $softCache = [];
    protected bool $cachingEnabled = true;

    public function __construct(
        protected Collection $constraints,
    ) {}

    /**
     * Check all hard constraints for a given context.
     * Returns true if ALL hard constraints pass.
     */
    public function checkHard(ConstraintContext $context): bool
    {
        $cacheKey = "{$context->dayId}_{$context->periodIndex}_{$context->classKey}";

        if ($this->cachingEnabled && isset($this->hardCache[$cacheKey])) {
            return $this->hardCache[$cacheKey];
        }

        $hardConstraints = $this->constraints
            ->filter(fn($c) => $c instanceof Hard\HardConstraint || ($c->is_hard ?? false))
            ->sortBy(fn($c) => $c->priority ?? 999);

        foreach ($hardConstraints as $constraint) {
            if (!$constraint->isRelevant($context)) continue;

            if (!$constraint->passes($context)) {
                if ($this->cachingEnabled) {
                    $this->hardCache[$cacheKey] = false;
                }
                return false;
            }
        }

        if ($this->cachingEnabled) {
            $this->hardCache[$cacheKey] = true;
        }
        return true;
    }

    /**
     * Score soft constraints for a given context.
     * Returns sum of satisfied weights (0–100+).
     */
    public function scoreSoft(ConstraintContext $context): float
    {
        $cacheKey = "{$context->dayId}_{$context->periodIndex}_{$context->classKey}";

        if ($this->cachingEnabled && isset($this->softCache[$cacheKey])) {
            return $this->softCache[$cacheKey];
        }

        $score = 0.0;

        $softConstraints = $this->constraints
            ->filter(fn($c) => $c instanceof Soft\SoftConstraint || !($c->is_hard ?? true))
            ->sortBy(fn($c) => $c->priority ?? 999);

        foreach ($softConstraints as $constraint) {
            if (!$constraint->isRelevant($context)) continue;

            try {
                $weight = $constraint->weight ?? 1;
                if ($constraint->passes($context)) {
                    $score += $weight;
                }
            } catch (\Throwable $e) {
                \Log::warning("Soft constraint scoring error: " . $e->getMessage());
            }
        }

        if ($this->cachingEnabled) {
            $this->softCache[$cacheKey] = $score;
        }
        return $score;
    }

    /**
     * Clear evaluation caches.
     */
    public function clearCache(): void
    {
        $this->hardCache = [];
        $this->softCache = [];
    }

    public function setCaching(bool $enabled): void
    {
        $this->cachingEnabled = $enabled;
    }
}
```

**Wire into ConstraintManager:** Extract evaluation logic from ConstraintManager into ConstraintEvaluator. ConstraintManager becomes responsible for loading + storing constraints, ConstraintEvaluator for evaluation.

---

## Task 11.4 — Wire Constraint Group evaluation (1 day)

**Models:** `ConstraintGroup`, `ConstraintGroupMember`

**File:** Add to `ConstraintEvaluator.php`:

```php
/**
 * Evaluate constraint groups.
 * Groups are loaded via ConstraintManager and passed to ConstraintEvaluator.
 */
public function evaluateGroups(Collection $groups, ConstraintContext $context): bool
{
    foreach ($groups as $group) {
        $members = $group->members()
            ->with('constraint.constraintType')
            ->orderBy('sequence_order')
            ->get();

        $memberConstraints = $members->map(function ($m) {
            return ConstraintFactory::createFromModel($m->constraint);
        });

        $result = match ($group->group_type) {
            'MUTEX' => $this->evaluateMutex($memberConstraints, $context),
            'CONCURRENT' => $this->evaluateConcurrent($memberConstraints, $context),
            'ORDERED' => $this->evaluateOrdered($memberConstraints, $context),
            'PREFERRED' => $this->evaluatePreferred($memberConstraints, $context),
            default => true,
        };

        if (!$result) return false;
    }

    return true;
}

protected function evaluateMutex(Collection $constraints, ConstraintContext $context): bool
{
    // At most one member passes
    $passingCount = $constraints->filter(fn($c) => $c->isRelevant($context) && $c->passes($context))->count();
    return $passingCount <= 1;
}

protected function evaluateConcurrent(Collection $constraints, ConstraintContext $context): bool
{
    // ALL members must pass
    return $constraints->every(fn($c) => !$c->isRelevant($context) || $c->passes($context));
}

protected function evaluateOrdered(Collection $constraints, ConstraintContext $context): bool
{
    // Evaluate in sequence, short-circuit on first fail
    foreach ($constraints as $c) {
        if ($c->isRelevant($context) && !$c->passes($context)) {
            return false;
        }
    }
    return true;
}

protected function evaluatePreferred(Collection $constraints, ConstraintContext $context): float
{
    // Sum weights of passing members (soft scoring)
    return $constraints->sum(function ($c) use ($context) {
        if ($c->isRelevant($context) && $c->passes($context)) {
            return $c->weight ?? 1;
        }
        return 0;
    });
}
```

---

## Task 11.5 — Wire FETConstraintBridge to DatabaseConstraintService (4 hrs)

**File:** `Modules/SmartTimetable/app/Services/Generator/FETConstraintBridge.php`

**Change:** Replace the TODO / empty `canPlaceActivity()` with actual constraint loading:

```php
use Modules\SmartTimetable\Services\DatabaseConstraintService;
use Modules\SmartTimetable\Services\Constraints\ConstraintManager;
use Modules\SmartTimetable\Services\Constraints\ConstraintContext;

class FETConstraintBridge
{
    protected ?ConstraintManager $constraintManager = null;

    public function __construct(protected ?int $academicSessionId = null)
    {
        if ($academicSessionId) {
            $this->constraintManager = new ConstraintManager();
            $this->constraintManager->loadForSession($academicSessionId);
        }
    }

    public function canPlaceActivity($activity, $dayId, $periodIndex, $context = []): bool
    {
        if (!$this->constraintManager) return true;

        $constraintContext = ConstraintContext::fromActivityAndSlot($activity, $dayId, $periodIndex);

        return $this->constraintManager->checkHardConstraints($constraintContext);
    }

    public function scoreSlot($activity, $dayId, $periodIndex, $context = []): float
    {
        if (!$this->constraintManager) return 0.0;

        $constraintContext = ConstraintContext::fromActivityAndSlot($activity, $dayId, $periodIndex);

        return $this->constraintManager->evaluateSoftConstraints($constraintContext);
    }
}
```

**Also wire in FETSolver:** Update `FETSolver` constructor to pass `academicSessionId` to `FETConstraintBridge`.

---

## Task 11.6 — Add priority-ordered constraint evaluation (2 hrs)

**File:** `ConstraintManager.php` or `ConstraintEvaluator.php`

**Change:** Sort constraints by `priority` field before evaluation. Higher-priority (lower number) constraints are checked first. Combined with fail-fast, this rejects bad slots faster.

This should already be done in Task 11.3 (ConstraintEvaluator uses `sortBy('priority')`). Verify and ensure ConstraintManager also respects priority if it still has any direct evaluation logic.

---

## Post-Execution Checklist

1. Run: `/lint Modules/SmartTimetable/app/Services/Constraints/`
2. Run: `/test SmartTimetable` — all tests pass
3. Verify ConstraintRegistry works: `php artisan tinker --execute="Modules\SmartTimetable\Services\Constraints\ConstraintRegistry::all();"`
4. Update AI Brain:
   - `progress.md` → Phase 11 done, Constraint Architecture Foundation complete
   - `decisions.md` → Add D19: ConstraintRegistry plugin pattern, D20: ConstraintContext value object, D21: ConstraintEvaluator separation
   - `known-issues.md` → Mark SVC-NEW-01 (FETConstraintBridge empty) as RESOLVED

<?php

namespace Modules\SmartTimetable\Services;

use Illuminate\Database\Eloquent\Collection;
use Modules\SmartTimetable\Models\Constraint;
use Modules\SmartTimetable\Models\ConstraintType;
use Modules\SmartTimetable\Services\Constraints\ConstraintFactory;
use Modules\SmartTimetable\Services\Constraints\ConstraintManager;

class DatabaseConstraintService
{
    private ConstraintFactory $factory;

    public function __construct(ConstraintFactory $factory = null)
    {
        // initialize the Constraint factory to load, create and calidate constraints.
        $this->factory = $factory ?? new ConstraintFactory();
    }

    // load ALL constraints for a generation session
    public function loadConstraintsForGeneration(
        int $academicSessionId,
        array $generationContext = []
    ): ConstraintManager {

        $manager = new ConstraintManager($generationContext);

        $constraints = $this->loadActiveConstraints($academicSessionId);

        foreach ($constraints as $constraint) {
            try {
                // Validate constraint parameters
                $validation = $this->factory->validateParameters($constraint);

                if (!$validation['valid']) {
                    \Log::warning('Constraint has invalid parameters - skipping', [
                        'constraint_id' => $constraint->id,
                        'type' => $constraint->constraintType->code,
                        'errors' => $validation['errors'],
                    ]);
                    continue;
                }

                $constraintObject = $this->factory->createFromDatabase($constraint);

                // Add to manager based on is_hard flag
                $manager->addConstraint($constraintObject, $constraint->is_hard);

                \Log::info('Loaded constraint from database', [
                    'constraint_id' => $constraint->id,
                    'name' => $constraint->name,
                    'type' => $constraint->constraintType->code,
                    'target_type' => $constraint->target_type,
                    'target_id' => $constraint->target_id,
                    'is_hard' => $constraint->is_hard,
                    'weight' => $constraint->weight,
                ]);

            } catch (\Exception $e) {
                \Log::error('Failed to load constraint', [
                    'constraint_id' => $constraint->id,
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString(),
                ]);
            }
        }

        return $manager;
    }

    // load active constraints for academic session

    private function loadActiveConstraints(int $academicSessionId): Collection
    {
        $now = now();

        return Constraint::with('constraintType')
            ->where('academic_session_id', $academicSessionId)
            ->where('is_active', true)
            ->where('status', 'ACTIVE')
            ->where(function ($query) use ($now) {
                $query->whereNull('effective_from')
                    ->orWhere('effective_from', '<=', $now);
            })
            ->where(function ($query) use ($now) {
                $query->whereNull('effective_to')
                    ->orWhere('effective_to', '>=', $now);
            })
            ->orderBy('is_hard', 'desc')
            ->orderBy('weight', 'desc')
            ->get();
    }

    /**
     * Get constraint statistics
     */
    public function getConstraintStatistics(int $academicSessionId): array
    {
        $constraints = $this->loadActiveConstraints($academicSessionId);

        $stats = [
            'total' => $constraints->count(),
            'by_type' => [],
            'by_target' => [],
            'by_hardness' => [
                'hard' => $constraints->where('is_hard', true)->count(),
                'soft' => $constraints->where('is_hard', false)->count(),
            ],
        ];

        foreach ($constraints as $constraint) {
            $typeCode = $constraint->constraintType->code;
            $targetType = $constraint->target_type;

            if (!isset($stats['by_type'][$typeCode])) {
                $stats['by_type'][$typeCode] = 0;
            }
            $stats['by_type'][$typeCode]++;

            if (!isset($stats['by_target'][$targetType])) {
                $stats['by_target'][$targetType] = 0;
            }
            $stats['by_target'][$targetType]++;
        }

        return $stats;
    }

    /**
     * Check if specific constraint type exists
     */
    public function hasConstraintType(string $typeCode, int $academicSessionId): bool
    {
        return Constraint::where('academic_session_id', $academicSessionId)
            ->where('is_active', true)
            ->where('status', 'ACTIVE')
            ->whereHas('constraintType', function ($query) use ($typeCode) {
                $query->where('code', $typeCode);
            })
            ->exists();
    }
}
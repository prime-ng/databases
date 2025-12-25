<?php

namespace App\Services;

use App\Models\GenerationRun;
use App\Models\TimetableCell;
use App\Models\TimetableCellTeacher;
use App\Models\Constraint;
use App\Models\ClassModeRule;
use App\Models\PeriodSetPeriod;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Exception;

class TimetableGenerator
{
    protected $generationRun;
    protected $constraints;
    protected $hardConstraints;
    protected $softConstraints;

    public function __construct()
    {
        $this->loadConstraints();
    }

    /**
     * Start a new timetable generation
     */
    public function startGeneration(array $params): GenerationRun
    {
        try {
            DB::beginTransaction();

            $generationRun = GenerationRun::create([
                'mode_id' => $params['mode_id'],
                'period_set_id' => $params['period_set_id'],
                'academic_session_id' => $params['academic_session_id'] ?? null,
                'started_at' => now(),
                'status' => 'RUNNING',
                'params_json' => $params
            ]);

            $this->generationRun = $generationRun;

            DB::commit();
            return $generationRun;

        } catch (Exception $e) {
            DB::rollBack();
            Log::error('Failed to start timetable generation', [
                'error' => $e->getMessage(),
                'params' => $params
            ]);
            throw $e;
        }
    }

    /**
     * Generate timetable using constraint-based algorithm
     */
    public function generateTimetable(GenerationRun $generationRun): array
    {
        $this->generationRun = $generationRun;
        $params = $generationRun->params_json;

        try {
            Log::info('Starting timetable generation', ['run_id' => $generationRun->id]);

            // Phase 1: Initialize data structures
            $problemData = $this->initializeProblemData($params);

            // Phase 2: Generate base assignments using heuristics
            $baseAssignments = $this->generateBaseAssignments($problemData);

            // Phase 3: Apply constraint-based optimization
            $optimizedAssignments = $this->optimizeAssignments($baseAssignments, $problemData);

            // Phase 4: Validate and resolve conflicts
            $finalAssignments = $this->validateAndResolveConflicts($optimizedAssignments, $problemData);

            // Phase 5: Save to database
            $savedCells = $this->saveTimetableCells($finalAssignments);

            // Phase 6: Calculate statistics
            $stats = $this->calculateGenerationStats($savedCells, $problemData);

            // Update generation run
            $generationRun->update([
                'finished_at' => now(),
                'status' => 'SUCCESS',
                'stats_json' => $stats
            ]);

            Log::info('Timetable generation completed successfully', [
                'run_id' => $generationRun->id,
                'cells_created' => count($savedCells)
            ]);

            return [
                'success' => true,
                'generation_run' => $generationRun,
                'cells_created' => count($savedCells),
                'stats' => $stats
            ];

        } catch (Exception $e) {
            $generationRun->update([
                'finished_at' => now(),
                'status' => 'FAILED',
                'stats_json' => ['error' => $e->getMessage()]
            ]);

            Log::error('Timetable generation failed', [
                'run_id' => $generationRun->id,
                'error' => $e->getMessage()
            ]);

            throw $e;
        }
    }

    /**
     * Load all active constraints
     */
    protected function loadConstraints(): void
    {
        $this->constraints = Constraint::where('is_active', true)->get();
        $this->hardConstraints = $this->constraints->where('is_hard', true);
        $this->softConstraints = $this->constraints->where('is_hard', false);
    }

    /**
     * Initialize problem data structures
     */
    protected function initializeProblemData(array $params): array
    {
        $modeId = $params['mode_id'];
        $periodSetId = $params['period_set_id'];

        // Get period set periods
        $periods = PeriodSetPeriod::where('period_set_id', $periodSetId)
            ->where('is_active', true)
            ->orderBy('period_ord')
            ->get();

        // Get class mode rules
        $classRules = ClassModeRule::where('mode_id', $modeId)
            ->where('is_active', true)
            ->with(['schoolClass', 'periodSet'])
            ->get();

        // Get available teachers (simplified - in real implementation, filter by subject/school)
        $teachers = DB::table('sch_users')
            ->where('user_type', 'teacher')
            ->where('is_active', true)
            ->get();

        // Get available rooms
        $rooms = DB::table('sch_rooms')
            ->where('is_active', true)
            ->get();

        return [
            'periods' => $periods,
            'class_rules' => $classRules,
            'teachers' => $teachers,
            'rooms' => $rooms,
            'week_dates' => $this->getWeekDates($params['start_date'] ?? now()->startOfWeek()),
            'params' => $params
        ];
    }

    /**
     * Generate base assignments using greedy heuristics
     */
    protected function generateBaseAssignments(array $problemData): array
    {
        $assignments = [];
        $classRules = $problemData['class_rules'];
        $periods = $problemData['periods'];
        $weekDates = $problemData['week_dates'];

        foreach ($classRules as $classRule) {
            $classAssignments = $this->assignClassTimetable(
                $classRule,
                $periods,
                $weekDates,
                $problemData
            );

            $assignments = array_merge($assignments, $classAssignments);
        }

        return $assignments;
    }

    /**
     * Assign timetable for a specific class
     */
    protected function assignClassTimetable($classRule, $periods, $weekDates, $problemData): array
    {
        $assignments = [];
        $classId = $classRule->class_id;

        // For each day of the week
        foreach ($weekDates as $date) {
            $dayOfWeek = $date->dayOfWeek; // 0 = Sunday, 1 = Monday, etc.

            // Skip weekends if not configured
            if ($dayOfWeek == 0 || $dayOfWeek == 6) {
                continue;
            }

            // Assign periods for this day
            foreach ($periods as $period) {
                // Skip non-teaching periods if not allowed
                if (!$classRule->allow_teaching_periods && $period->periodType->counts_as_teaching) {
                    continue;
                }

                // Find suitable teacher and room
                $assignment = $this->findSuitableAssignment(
                    $classId,
                    $date,
                    $period,
                    $problemData
                );

                if ($assignment) {
                    $assignments[] = $assignment;
                }
            }
        }

        return $assignments;
    }

    /**
     * Find suitable teacher and room for a class-period combination
     */
    protected function findSuitableAssignment($classId, $date, $period, $problemData): ?array
    {
        // Simplified teacher selection - in real implementation, consider subjects, availability, etc.
        $availableTeachers = $problemData['teachers']->random(min(3, $problemData['teachers']->count()));

        // Simplified room selection
        $availableRooms = $problemData['rooms']->random(min(2, $problemData['rooms']->count()));

        return [
            'class_id' => $classId,
            'date' => $date,
            'period_ord' => $period->period_ord,
            'teacher_id' => $availableTeachers->id,
            'room_id' => $availableRooms->id,
            'assignment_role_id' => 1, // Primary instructor
        ];
    }

    /**
     * Apply constraint-based optimization
     */
    protected function optimizeAssignments(array $assignments, array $problemData): array
    {
        // Apply genetic algorithm or local search optimization
        // This is a simplified version - real implementation would use more sophisticated algorithms

        $optimizedAssignments = $assignments;

        // Apply soft constraints to improve solution
        foreach ($this->softConstraints as $constraint) {
            $optimizedAssignments = $this->applySoftConstraint(
                $optimizedAssignments,
                $constraint,
                $problemData
            );
        }

        return $optimizedAssignments;
    }

    /**
     * Apply a soft constraint to improve assignments
     */
    protected function applySoftConstraint(array $assignments, Constraint $constraint, array $problemData): array
    {
        // Simplified constraint application - real implementation would be more sophisticated
        switch ($constraint->rule_json['type'] ?? 'generic') {
            case 'teacher_workload_balance':
                return $this->balanceTeacherWorkload($assignments, $constraint);
            case 'room_utilization':
                return $this->optimizeRoomUtilization($assignments, $constraint);
            default:
                return $assignments;
        }
    }

    /**
     * Balance teacher workload across assignments
     */
    protected function balanceTeacherWorkload(array $assignments, Constraint $constraint): array
    {
        // Group assignments by teacher
        $teacherAssignments = [];
        foreach ($assignments as $assignment) {
            $teacherId = $assignment['teacher_id'];
            if (!isset($teacherAssignments[$teacherId])) {
                $teacherAssignments[$teacherId] = [];
            }
            $teacherAssignments[$teacherId][] = $assignment;
        }

        // Find teachers with excessive workload and reassign
        foreach ($teacherAssignments as $teacherId => $teacherAssigns) {
            if (count($teacherAssigns) > ($constraint->rule_json['max_periods_per_day'] ?? 6)) {
                // Reassign some periods to other teachers
                $excessAssignments = array_slice($teacherAssigns, 6);
                foreach ($excessAssignments as $excess) {
                    // Find alternative teacher
                    $alternativeTeacher = $this->findAlternativeTeacher($teacherId, $assignments);
                    if ($alternativeTeacher) {
                        $excess['teacher_id'] = $alternativeTeacher;
                    }
                }
            }
        }

        return $assignments;
    }

    /**
     * Find alternative teacher for reassignment
     */
    protected function findAlternativeTeacher($currentTeacherId, array $assignments): ?int
    {
        // Simplified - return first available teacher that's not the current one
        $usedTeachers = array_column($assignments, 'teacher_id');
        $availableTeachers = array_diff($usedTeachers, [$currentTeacherId]);

        return !empty($availableTeachers) ? reset($availableTeachers) : null;
    }

    /**
     * Optimize room utilization
     */
    protected function optimizeRoomUtilization(array $assignments, Constraint $constraint): array
    {
        // Group by room and time to identify conflicts
        $roomUsage = [];
        foreach ($assignments as $assignment) {
            $key = $assignment['room_id'] . '_' . $assignment['date']->format('Y-m-d') . '_' . $assignment['period_ord'];
            if (!isset($roomUsage[$key])) {
                $roomUsage[$key] = [];
            }
            $roomUsage[$key][] = $assignment;
        }

        // Resolve conflicts by reassigning rooms
        foreach ($roomUsage as $key => $conflictingAssignments) {
            if (count($conflictingAssignments) > 1) {
                // Keep first assignment, reassign others
                for ($i = 1; $i < count($conflictingAssignments); $i++) {
                    $alternativeRoom = $this->findAlternativeRoom(
                        $conflictingAssignments[$i]['room_id'],
                        $assignments
                    );
                    if ($alternativeRoom) {
                        $conflictingAssignments[$i]['room_id'] = $alternativeRoom;
                    }
                }
            }
        }

        return $assignments;
    }

    /**
     * Find alternative room
     */
    protected function findAlternativeRoom($currentRoomId, array $assignments): ?int
    {
        // Simplified - return first available room that's not the current one
        $usedRooms = array_column($assignments, 'room_id');
        $availableRooms = array_diff($usedRooms, [$currentRoomId]);

        return !empty($availableRooms) ? reset($availableRooms) : null;
    }

    /**
     * Validate assignments and resolve conflicts
     */
    protected function validateAndResolveConflicts(array $assignments, array $problemData): array
    {
        $conflicts = [];

        // Check hard constraints
        foreach ($assignments as $assignment) {
            $validationResult = $this->validateAssignment($assignment, $assignments);

            if (!$validationResult['valid']) {
                $conflicts[] = [
                    'assignment' => $assignment,
                    'violations' => $validationResult['violations']
                ];
            }
        }

        // Attempt to resolve conflicts
        foreach ($conflicts as $conflict) {
            $resolved = $this->resolveConflict($conflict, $assignments, $problemData);
            if (!$resolved) {
                Log::warning('Could not resolve conflict', [
                    'assignment' => $conflict['assignment'],
                    'violations' => $conflict['violations']
                ]);
            }
        }

        return $assignments;
    }

    /**
     * Validate a single assignment against constraints
     */
    protected function validateAssignment(array $assignment, array $allAssignments): array
    {
        $violations = [];

        // Check teacher availability (simplified)
        $teacherConflicts = array_filter($allAssignments, function($a) use ($assignment) {
            return $a !== $assignment &&
                   $a['teacher_id'] == $assignment['teacher_id'] &&
                   $a['date']->equalTo($assignment['date']) &&
                   $a['period_ord'] == $assignment['period_ord'];
        });

        if (!empty($teacherConflicts)) {
            $violations[] = [
                'type' => 'teacher_double_booking',
                'severity' => 'hard',
                'message' => 'Teacher is already assigned to another class in this period'
            ];
        }

        // Check room availability
        $roomConflicts = array_filter($allAssignments, function($a) use ($assignment) {
            return $a !== $assignment &&
                   $a['room_id'] == $assignment['room_id'] &&
                   $a['date']->equalTo($assignment['date']) &&
                   $a['period_ord'] == $assignment['period_ord'];
        });

        if (!empty($roomConflicts)) {
            $violations[] = [
                'type' => 'room_double_booking',
                'severity' => 'hard',
                'message' => 'Room is already booked for another class in this period'
            ];
        }

        return [
            'valid' => empty($violations),
            'violations' => $violations
        ];
    }

    /**
     * Attempt to resolve a conflict
     */
    protected function resolveConflict(array $conflict, array &$assignments, array $problemData): bool
    {
        $assignment = $conflict['assignment'];
        $violations = $conflict['violations'];

        foreach ($violations as $violation) {
            switch ($violation['type']) {
                case 'teacher_double_booking':
                    $alternativeTeacher = $this->findAlternativeTeacher(
                        $assignment['teacher_id'],
                        $assignments
                    );
                    if ($alternativeTeacher) {
                        $assignment['teacher_id'] = $alternativeTeacher;
                        return true;
                    }
                    break;

                case 'room_double_booking':
                    $alternativeRoom = $this->findAlternativeRoom(
                        $assignment['room_id'],
                        $assignments
                    );
                    if ($alternativeRoom) {
                        $assignment['room_id'] = $alternativeRoom;
                        return true;
                    }
                    break;
            }
        }

        return false;
    }

    /**
     * Save timetable cells to database
     */
    protected function saveTimetableCells(array $assignments): array
    {
        $savedCells = [];

        DB::beginTransaction();

        try {
            foreach ($assignments as $assignment) {
                $cell = TimetableCell::create([
                    'generation_run_id' => $this->generationRun->id,
                    'class_group_id' => $assignment['class_id'], // Simplified - using class_id as class_group_id
                    'date' => $assignment['date'],
                    'period_ord' => $assignment['period_ord'],
                    'room_id' => $assignment['room_id'],
                    'source' => 'AUTO'
                ]);

                // Create teacher assignment
                TimetableCellTeacher::create([
                    'cell_id' => $cell->id,
                    'teacher_id' => $assignment['teacher_id'],
                    'assignment_role_id' => $assignment['assignment_role_id']
                ]);

                $savedCells[] = $cell;
            }

            DB::commit();

        } catch (Exception $e) {
            DB::rollBack();
            throw $e;
        }

        return $savedCells;
    }

    /**
     * Calculate generation statistics
     */
    protected function calculateGenerationStats(array $cells, array $problemData): array
    {
        $totalCells = count($cells);
        $uniqueTeachers = collect($cells)->pluck('teachers')->flatten()->unique('id')->count();
        $uniqueRooms = collect($cells)->pluck('room_id')->unique()->count();
        $uniqueClasses = collect($cells)->pluck('class_group_id')->unique()->count();

        return [
            'total_cells' => $totalCells,
            'unique_teachers' => $uniqueTeachers,
            'unique_rooms' => $uniqueRooms,
            'unique_classes' => $uniqueClasses,
            'average_assignments_per_teacher' => $uniqueTeachers > 0 ? $totalCells / $uniqueTeachers : 0,
            'room_utilization_rate' => $this->calculateRoomUtilization($cells, $problemData),
            'teacher_workload_balance' => $this->calculateWorkloadBalance($cells)
        ];
    }

    /**
     * Calculate room utilization rate
     */
    protected function calculateRoomUtilization(array $cells, array $problemData): float
    {
        $totalPossibleSlots = count($problemData['week_dates']) * count($problemData['periods']) * count($problemData['rooms']);
        $usedSlots = count($cells);

        return $totalPossibleSlots > 0 ? ($usedSlots / $totalPossibleSlots) * 100 : 0;
    }

    /**
     * Calculate teacher workload balance
     */
    protected function calculateWorkloadBalance(array $cells): float
    {
        $teacherAssignments = [];
        foreach ($cells as $cell) {
            foreach ($cell->teachers as $teacher) {
                $teacherId = $teacher->id;
                if (!isset($teacherAssignments[$teacherId])) {
                    $teacherAssignments[$teacherId] = 0;
                }
                $teacherAssignments[$teacherId]++;
            }
        }

        if (empty($teacherAssignments)) {
            return 0;
        }

        $assignments = array_values($teacherAssignments);
        $mean = array_sum($assignments) / count($assignments);
        $variance = array_sum(array_map(function($x) use ($mean) {
            return pow($x - $mean, 2);
        }, $assignments)) / count($assignments);

        $stdDev = sqrt($variance);
        $maxReasonableStdDev = 3.0;

        // Return balance score (higher is better)
        return max(0, 100 - ($stdDev / $maxReasonableStdDev) * 100);
    }

    /**
     * Get week dates starting from given date
     */
    protected function getWeekDates($startDate): array
    {
        $dates = [];
        for ($i = 0; $i < 7; $i++) {
            $dates[] = $startDate->copy()->addDays($i);
        }
        return $dates;
    }
}
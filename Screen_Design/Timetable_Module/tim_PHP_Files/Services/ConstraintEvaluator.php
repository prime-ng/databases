<?php

namespace App\Services;

use App\Models\Constraint;
use App\Models\TimetableCell;
use App\Models\TimetableCellTeacher;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Exception;

class ConstraintEvaluator
{
    protected $constraints;
    protected $hardConstraints;
    protected $softConstraints;

    public function __construct()
    {
        $this->loadConstraints();
    }

    /**
     * Load all active constraints
     */
    public function loadConstraints(): void
    {
        $this->constraints = Constraint::where('is_active', true)->get();
        $this->hardConstraints = $this->constraints->where('is_hard', true);
        $this->softConstraints = $this->constraints->where('is_hard', false);
    }

    /**
     * Validate an assignment against all constraints
     */
    public function validateAssignment(array $assignment, array $existingAssignments = []): array
    {
        $violations = [];

        // Check hard constraints first
        foreach ($this->hardConstraints as $constraint) {
            $result = $this->checkConstraint($constraint, $assignment, $existingAssignments);
            if (!$result['valid']) {
                $violations[] = [
                    'constraint_id' => $constraint->id,
                    'constraint_name' => $constraint->name,
                    'severity' => 'hard',
                    'type' => $constraint->rule_json['type'] ?? 'unknown',
                    'message' => $result['message'],
                    'penalty' => $constraint->penalty_score
                ];
            }
        }

        // Check soft constraints
        foreach ($this->softConstraints as $constraint) {
            $result = $this->checkConstraint($constraint, $assignment, $existingAssignments);
            if (!$result['valid']) {
                $violations[] = [
                    'constraint_id' => $constraint->id,
                    'constraint_name' => $constraint->name,
                    'severity' => 'soft',
                    'type' => $constraint->rule_json['type'] ?? 'unknown',
                    'message' => $result['message'],
                    'penalty' => $constraint->penalty_score
                ];
            }
        }

        $hardViolations = array_filter($violations, function($v) {
            return $v['severity'] === 'hard';
        });

        return [
            'valid' => empty($hardViolations),
            'hard_violations' => count($hardViolations),
            'soft_violations' => count($violations) - count($hardViolations),
            'total_penalty' => array_sum(array_column($violations, 'penalty')),
            'violations' => $violations
        ];
    }

    /**
     * Check a specific constraint
     */
    public function checkConstraint(Constraint $constraint, array $assignment, array $existingAssignments = []): array
    {
        $ruleType = $constraint->rule_json['type'] ?? 'unknown';

        switch ($ruleType) {
            case 'teacher_availability':
                return $this->checkTeacherAvailability($constraint, $assignment, $existingAssignments);

            case 'teacher_workload_limit':
                return $this->checkTeacherWorkloadLimit($constraint, $assignment, $existingAssignments);

            case 'teacher_subject_qualification':
                return $this->checkTeacherSubjectQualification($constraint, $assignment, $existingAssignments);

            case 'room_capacity':
                return $this->checkRoomCapacity($constraint, $assignment, $existingAssignments);

            case 'room_availability':
                return $this->checkRoomAvailability($constraint, $assignment, $existingAssignments);

            case 'class_period_limit':
                return $this->checkClassPeriodLimit($constraint, $assignment, $existingAssignments);

            case 'consecutive_periods':
                return $this->checkConsecutivePeriods($constraint, $assignment, $existingAssignments);

            case 'break_requirements':
                return $this->checkBreakRequirements($constraint, $assignment, $existingAssignments);

            case 'teacher_preferences':
                return $this->checkTeacherPreferences($constraint, $assignment, $existingAssignments);

            case 'room_equipment':
                return $this->checkRoomEquipment($constraint, $assignment, $existingAssignments);

            default:
                Log::warning('Unknown constraint type', ['type' => $ruleType, 'constraint_id' => $constraint->id]);
                return ['valid' => true, 'message' => 'Unknown constraint type'];
        }
    }

    /**
     * Check teacher availability constraint
     */
    protected function checkTeacherAvailability(Constraint $constraint, array $assignment, array $existingAssignments): array
    {
        $teacherId = $assignment['teacher_id'];
        $date = $assignment['date'];
        $periodOrd = $assignment['period_ord'];

        // Check if teacher is already assigned in this time slot
        $conflicts = array_filter($existingAssignments, function($existing) use ($teacherId, $date, $periodOrd) {
            return $existing['teacher_id'] == $teacherId &&
                   $existing['date']->equalTo($date) &&
                   $existing['period_ord'] == $periodOrd;
        });

        if (!empty($conflicts)) {
            return [
                'valid' => false,
                'message' => 'Teacher is already assigned to another class in this period'
            ];
        }

        // Check teacher availability schedule (simplified - in real implementation, check teacher availability table)
        $isAvailable = $this->checkTeacherScheduleAvailability($teacherId, $date, $periodOrd);

        if (!$isAvailable) {
            return [
                'valid' => false,
                'message' => 'Teacher is not available during this period'
            ];
        }

        return ['valid' => true, 'message' => 'Teacher is available'];
    }

    /**
     * Check teacher workload limit constraint
     */
    protected function checkTeacherWorkloadLimit(Constraint $constraint, array $assignment, array $existingAssignments): array
    {
        $teacherId = $assignment['teacher_id'];
        $date = $assignment['date'];
        $maxPeriods = $constraint->rule_json['max_periods_per_day'] ?? 6;

        // Count existing assignments for this teacher on this date
        $existingCount = count(array_filter($existingAssignments, function($existing) use ($teacherId, $date) {
            return $existing['teacher_id'] == $teacherId && $existing['date']->equalTo($date);
        }));

        if ($existingCount >= $maxPeriods) {
            return [
                'valid' => false,
                'message' => "Teacher would exceed maximum periods per day ({$maxPeriods})"
            ];
        }

        return ['valid' => true, 'message' => 'Teacher workload is within limits'];
    }

    /**
     * Check teacher subject qualification constraint
     */
    protected function checkTeacherSubjectQualification(Constraint $constraint, array $assignment, array $existingAssignments): array
    {
        $teacherId = $assignment['teacher_id'];
        $classId = $assignment['class_id'];

        // Simplified - in real implementation, check teacher qualifications table
        $isQualified = $this->checkTeacherQualification($teacherId, $classId);

        if (!$isQualified) {
            return [
                'valid' => false,
                'message' => 'Teacher is not qualified to teach this subject/class'
            ];
        }

        return ['valid' => true, 'message' => 'Teacher is qualified for this assignment'];
    }

    /**
     * Check room capacity constraint
     */
    protected function checkRoomCapacity(Constraint $constraint, array $assignment, array $existingAssignments): array
    {
        $roomId = $assignment['room_id'];
        $classId = $assignment['class_id'];

        $roomCapacity = $this->getRoomCapacity($roomId);
        $classSize = $this->getClassSize($classId);

        if ($classSize > $roomCapacity) {
            return [
                'valid' => false,
                'message' => "Room capacity ({$roomCapacity}) is insufficient for class size ({$classSize})"
            ];
        }

        return ['valid' => true, 'message' => 'Room capacity is sufficient'];
    }

    /**
     * Check room availability constraint
     */
    protected function checkRoomAvailability(Constraint $constraint, array $assignment, array $existingAssignments): array
    {
        $roomId = $assignment['room_id'];
        $date = $assignment['date'];
        $periodOrd = $assignment['period_ord'];

        // Check if room is already booked in this time slot
        $conflicts = array_filter($existingAssignments, function($existing) use ($roomId, $date, $periodOrd) {
            return $existing['room_id'] == $roomId &&
                   $existing['date']->equalTo($date) &&
                   $existing['period_ord'] == $periodOrd;
        });

        if (!empty($conflicts)) {
            return [
                'valid' => false,
                'message' => 'Room is already booked for another class in this period'
            ];
        }

        return ['valid' => true, 'message' => 'Room is available'];
    }

    /**
     * Check class period limit constraint
     */
    protected function checkClassPeriodLimit(Constraint $constraint, array $assignment, array $existingAssignments): array
    {
        $classId = $assignment['class_id'];
        $date = $assignment['date'];
        $maxPeriods = $constraint->rule_json['max_periods_per_day'] ?? 8;

        // Count existing assignments for this class on this date
        $existingCount = count(array_filter($existingAssignments, function($existing) use ($classId, $date) {
            return $existing['class_id'] == $classId && $existing['date']->equalTo($date);
        }));

        if ($existingCount >= $maxPeriods) {
            return [
                'valid' => false,
                'message' => "Class would exceed maximum periods per day ({$maxPeriods})"
            ];
        }

        return ['valid' => true, 'message' => 'Class period limit is within bounds'];
    }

    /**
     * Check consecutive periods constraint
     */
    protected function checkConsecutivePeriods(Constraint $constraint, array $assignment, array $existingAssignments): array
    {
        $teacherId = $assignment['teacher_id'];
        $date = $assignment['date'];
        $periodOrd = $assignment['period_ord'];
        $maxConsecutive = $constraint->rule_json['max_consecutive_periods'] ?? 3;

        // Get periods for this teacher on this date
        $teacherPeriods = array_filter($existingAssignments, function($existing) use ($teacherId, $date) {
            return $existing['teacher_id'] == $teacherId && $existing['date']->equalTo($date);
        });

        $periodOrds = array_column($teacherPeriods, 'period_ord');
        sort($periodOrds);

        // Check for consecutive periods
        $consecutiveCount = 1;
        for ($i = 1; $i < count($periodOrds); $i++) {
            if ($periodOrds[$i] == $periodOrds[$i-1] + 1) {
                $consecutiveCount++;
                if ($consecutiveCount > $maxConsecutive) {
                    return [
                        'valid' => false,
                        'message' => "Teacher would exceed maximum consecutive periods ({$maxConsecutive})"
                    ];
                }
            } else {
                $consecutiveCount = 1;
            }
        }

        return ['valid' => true, 'message' => 'Consecutive periods constraint satisfied'];
    }

    /**
     * Check break requirements constraint
     */
    protected function checkBreakRequirements(Constraint $constraint, array $assignment, array $existingAssignments): array
    {
        $teacherId = $assignment['teacher_id'];
        $date = $assignment['date'];
        $periodOrd = $assignment['period_ord'];
        $minBreakPeriods = $constraint->rule_json['min_break_periods'] ?? 1;

        // Get periods for this teacher on this date
        $teacherPeriods = array_filter($existingAssignments, function($existing) use ($teacherId, $date) {
            return $existing['teacher_id'] == $teacherId && $existing['date']->equalTo($date);
        });

        $periodOrds = array_column($teacherPeriods, 'period_ord');
        sort($periodOrds);

        // Check if adding this period would violate break requirements
        foreach ($periodOrds as $existingPeriod) {
            if (abs($existingPeriod - $periodOrd) == 1) {
                // Adjacent periods - check if this creates insufficient breaks
                // This is a simplified check - real implementation would be more complex
                continue;
            }
        }

        return ['valid' => true, 'message' => 'Break requirements satisfied'];
    }

    /**
     * Check teacher preferences constraint
     */
    protected function checkTeacherPreferences(Constraint $constraint, array $assignment, array $existingAssignments): array
    {
        $teacherId = $assignment['teacher_id'];
        $periodOrd = $assignment['period_ord'];

        // Simplified - in real implementation, check teacher preference tables
        $preferredPeriods = $this->getTeacherPreferredPeriods($teacherId);

        if (!in_array($periodOrd, $preferredPeriods)) {
            return [
                'valid' => false,
                'message' => 'Assignment violates teacher period preferences'
            ];
        }

        return ['valid' => true, 'message' => 'Assignment matches teacher preferences'];
    }

    /**
     * Check room equipment constraint
     */
    protected function checkRoomEquipment(Constraint $constraint, array $assignment, array $existingAssignments): array
    {
        $roomId = $assignment['room_id'];
        $classId = $assignment['class_id'];

        // Simplified - in real implementation, check room equipment and class requirements
        $requiredEquipment = $this->getClassRequiredEquipment($classId);
        $availableEquipment = $this->getRoomEquipment($roomId);

        $missingEquipment = array_diff($requiredEquipment, $availableEquipment);

        if (!empty($missingEquipment)) {
            return [
                'valid' => false,
                'message' => 'Room lacks required equipment: ' . implode(', ', $missingEquipment)
            ];
        }

        return ['valid' => true, 'message' => 'Room has all required equipment'];
    }

    /**
     * Calculate constraint satisfaction score for a set of assignments
     */
    public function calculateSatisfactionScore(array $assignments): array
    {
        $totalViolations = 0;
        $hardViolations = 0;
        $softViolations = 0;
        $totalPenalty = 0;

        foreach ($assignments as $assignment) {
            $validation = $this->validateAssignment($assignment, array_diff_key($assignments, [$assignment]));
            $totalViolations += $validation['hard_violations'] + $validation['soft_violations'];
            $hardViolations += $validation['hard_violations'];
            $softViolations += $validation['soft_violations'];
            $totalPenalty += $validation['total_penalty'];
        }

        $totalAssignments = count($assignments);
        $satisfactionScore = $totalAssignments > 0 ?
            (($totalAssignments - $totalViolations) / $totalAssignments) * 100 : 100;

        return [
            'satisfaction_score' => round($satisfactionScore, 2),
            'total_violations' => $totalViolations,
            'hard_violations' => $hardViolations,
            'soft_violations' => $softViolations,
            'total_penalty' => $totalPenalty,
            'is_feasible' => $hardViolations === 0
        ];
    }

    /**
     * Helper methods for constraint checking (simplified implementations)
     */
    protected function checkTeacherScheduleAvailability($teacherId, $date, $periodOrd): bool
    {
        // In real implementation, check teacher availability schedule
        return true; // Simplified
    }

    protected function checkTeacherQualification($teacherId, $classId): bool
    {
        // In real implementation, check teacher qualifications
        return true; // Simplified
    }

    protected function getRoomCapacity($roomId): int
    {
        // In real implementation, get from rooms table
        return 30; // Simplified
    }

    protected function getClassSize($classId): int
    {
        // In real implementation, get from class enrollment
        return 25; // Simplified
    }

    protected function getTeacherPreferredPeriods($teacherId): array
    {
        // In real implementation, get from teacher preferences
        return [1, 2, 3, 4, 5, 6, 7, 8]; // Simplified
    }

    protected function getClassRequiredEquipment($classId): array
    {
        // In real implementation, get class equipment requirements
        return ['projector']; // Simplified
    }

    protected function getRoomEquipment($roomId): array
    {
        // In real implementation, get room equipment
        return ['projector', 'whiteboard']; // Simplified
    }
}
<?php

namespace App\Http\Controllers;

use App\Services\TimetableGenerator;
use App\Models\GenerationRun;
use App\Models\TimetableCell;
use App\Models\TimetableCellTeacher;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Exception;

class TimetableController extends Controller
{
    protected $timetableGenerator;

    public function __construct(TimetableGenerator $timetableGenerator)
    {
        $this->timetableGenerator = $timetableGenerator;
    }

    /**
     * Start a new timetable generation
     */
    public function startGeneration(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'mode_id' => 'required|integer|exists:tim_timetable_modes,id',
                'period_set_id' => 'required|integer|exists:tim_period_sets,id',
                'academic_session_id' => 'nullable|integer|exists:sch_academic_sessions,id',
                'start_date' => 'nullable|date',
                'end_date' => 'nullable|date|after_or_equal:start_date',
                'constraints' => 'nullable|array',
                'optimization_level' => 'nullable|string|in:FAST,BALANCED,OPTIMAL'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $params = $request->all();
            $generationRun = $this->timetableGenerator->startGeneration($params);

            Log::info('Timetable generation started', [
                'run_id' => $generationRun->id,
                'user_id' => auth()->id(),
                'params' => $params
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Timetable generation started successfully',
                'data' => [
                    'generation_run_id' => $generationRun->id,
                    'status' => $generationRun->status,
                    'started_at' => $generationRun->started_at
                ]
            ], 201);

        } catch (Exception $e) {
            Log::error('Failed to start timetable generation', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to start timetable generation',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Execute timetable generation (async processing)
     */
    public function executeGeneration(Request $request, $runId): JsonResponse
    {
        try {
            $generationRun = GenerationRun::findOrFail($runId);

            if ($generationRun->status !== 'RUNNING') {
                return response()->json([
                    'success' => false,
                    'message' => 'Generation run is not in RUNNING state'
                ], 400);
            }

            // Execute generation in background (in real implementation, use queues)
            $result = $this->timetableGenerator->generateTimetable($generationRun);

            return response()->json([
                'success' => true,
                'message' => 'Timetable generation completed',
                'data' => $result
            ]);

        } catch (Exception $e) {
            Log::error('Failed to execute timetable generation', [
                'run_id' => $runId,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to execute timetable generation',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get generation run status
     */
    public function getGenerationStatus($runId): JsonResponse
    {
        try {
            $generationRun = GenerationRun::with(['mode', 'periodSet'])
                ->findOrFail($runId);

            $progress = $this->calculateGenerationProgress($generationRun);

            return response()->json([
                'success' => true,
                'data' => [
                    'generation_run' => $generationRun,
                    'progress' => $progress,
                    'stats' => $generationRun->stats_json ?? null
                ]
            ]);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to get generation status',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get list of generation runs
     */
    public function getGenerationRuns(Request $request): JsonResponse
    {
        try {
            $query = GenerationRun::with(['mode', 'periodSet'])
                ->orderBy('created_at', 'desc');

            // Apply filters
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            if ($request->has('mode_id')) {
                $query->where('mode_id', $request->mode_id);
            }

            if ($request->has('date_from')) {
                $query->whereDate('created_at', '>=', $request->date_from);
            }

            if ($request->has('date_to')) {
                $query->whereDate('created_at', '<=', $request->date_to);
            }

            $runs = $query->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'data' => $runs
            ]);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to get generation runs',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get generated timetable for a specific run
     */
    public function getGeneratedTimetable($runId, Request $request): JsonResponse
    {
        try {
            $generationRun = GenerationRun::findOrFail($runId);

            if ($generationRun->status !== 'SUCCESS') {
                return response()->json([
                    'success' => false,
                    'message' => 'Timetable generation has not completed successfully'
                ], 400);
            }

            $query = TimetableCell::where('generation_run_id', $runId)
                ->with(['teachers.assignmentRole', 'room', 'classGroup']);

            // Apply filters
            if ($request->has('class_group_id')) {
                $query->where('class_group_id', $request->class_group_id);
            }

            if ($request->has('date')) {
                $query->whereDate('date', $request->date);
            }

            if ($request->has('teacher_id')) {
                $query->whereHas('teachers', function($q) use ($request) {
                    $q->where('teacher_id', $request->teacher_id);
                });
            }

            if ($request->has('room_id')) {
                $query->where('room_id', $request->room_id);
            }

            $cells = $query->orderBy('date')
                ->orderBy('period_ord')
                ->get();

            // Group by date and period for easier consumption
            $timetable = $this->groupTimetableByDateAndPeriod($cells);

            return response()->json([
                'success' => true,
                'data' => [
                    'generation_run' => $generationRun,
                    'timetable' => $timetable,
                    'total_cells' => $cells->count()
                ]
            ]);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to get generated timetable',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get timetable for a specific class
     */
    public function getClassTimetable($classId, Request $request): JsonResponse
    {
        try {
            $query = TimetableCell::where('class_group_id', $classId)
                ->where('is_active', true)
                ->with(['teachers.assignmentRole', 'room', 'generationRun']);

            // Get latest generation run if not specified
            if (!$request->has('generation_run_id')) {
                $latestRun = GenerationRun::where('status', 'SUCCESS')
                    ->orderBy('finished_at', 'desc')
                    ->first();

                if ($latestRun) {
                    $query->where('generation_run_id', $latestRun->id);
                }
            }

            if ($request->has('generation_run_id')) {
                $query->where('generation_run_id', $request->generation_run_id);
            }

            if ($request->has('date_from')) {
                $query->whereDate('date', '>=', $request->date_from);
            }

            if ($request->has('date_to')) {
                $query->whereDate('date', '<=', $request->date_to);
            }

            $cells = $query->orderBy('date')
                ->orderBy('period_ord')
                ->get();

            $timetable = $this->groupTimetableByDateAndPeriod($cells);

            return response()->json([
                'success' => true,
                'data' => [
                    'class_id' => $classId,
                    'timetable' => $timetable,
                    'total_periods' => $cells->count()
                ]
            ]);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to get class timetable',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get teacher timetable
     */
    public function getTeacherTimetable($teacherId, Request $request): JsonResponse
    {
        try {
            $query = TimetableCellTeacher::where('teacher_id', $teacherId)
                ->whereHas('cell', function($q) {
                    $q->where('is_active', true);
                })
                ->with(['cell.classGroup', 'cell.room', 'cell.generationRun', 'assignmentRole']);

            // Get latest generation run if not specified
            if (!$request->has('generation_run_id')) {
                $latestRun = GenerationRun::where('status', 'SUCCESS')
                    ->orderBy('finished_at', 'desc')
                    ->first();

                if ($latestRun) {
                    $query->whereHas('cell', function($q) use ($latestRun) {
                        $q->where('generation_run_id', $latestRun->id);
                    });
                }
            }

            if ($request->has('generation_run_id')) {
                $query->whereHas('cell', function($q) use ($request) {
                    $q->where('generation_run_id', $request->generation_run_id);
                });
            }

            if ($request->has('date_from')) {
                $query->whereHas('cell', function($q) use ($request) {
                    $q->whereDate('date', '>=', $request->date_from);
                });
            }

            if ($request->has('date_to')) {
                $query->whereHas('cell', function($q) use ($request) {
                    $q->whereDate('date', '<=', $request->date_to);
                });
            }

            $assignments = $query->orderBy('cell.date')
                ->orderBy('cell.period_ord')
                ->get();

            $timetable = $this->groupTeacherTimetableByDateAndPeriod($assignments);

            return response()->json([
                'success' => true,
                'data' => [
                    'teacher_id' => $teacherId,
                    'timetable' => $timetable,
                    'total_assignments' => $assignments->count()
                ]
            ]);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to get teacher timetable',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Cancel a generation run
     */
    public function cancelGeneration($runId): JsonResponse
    {
        try {
            $generationRun = GenerationRun::findOrFail($runId);

            if (!in_array($generationRun->status, ['RUNNING', 'PENDING'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cannot cancel generation run in current status'
                ], 400);
            }

            $generationRun->update([
                'status' => 'CANCELLED',
                'finished_at' => now()
            ]);

            Log::info('Timetable generation cancelled', [
                'run_id' => $runId,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Generation run cancelled successfully'
            ]);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to cancel generation run',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete a generation run and its associated data
     */
    public function deleteGeneration($runId): JsonResponse
    {
        try {
            $generationRun = GenerationRun::findOrFail($runId);

            if ($generationRun->status === 'RUNNING') {
                return response()->json([
                    'success' => false,
                    'message' => 'Cannot delete a running generation'
                ], 400);
            }

            DB::beginTransaction();

            // Delete associated cells and teacher assignments
            $cells = TimetableCell::where('generation_run_id', $runId)->get();
            foreach ($cells as $cell) {
                $cell->teachers()->delete();
                $cell->delete();
            }

            $generationRun->delete();

            DB::commit();

            Log::info('Timetable generation deleted', [
                'run_id' => $runId,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Generation run deleted successfully'
            ]);

        } catch (Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete generation run',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get timetable statistics
     */
    public function getTimetableStats(Request $request): JsonResponse
    {
        try {
            $generationRunId = $request->get('generation_run_id');

            if (!$generationRunId) {
                // Get latest successful run
                $latestRun = GenerationRun::where('status', 'SUCCESS')
                    ->orderBy('finished_at', 'desc')
                    ->first();

                if (!$latestRun) {
                    return response()->json([
                        'success' => false,
                        'message' => 'No successful timetable generation found'
                    ], 404);
                }

                $generationRunId = $latestRun->id;
            }

            $stats = $this->calculateDetailedStats($generationRunId);

            return response()->json([
                'success' => true,
                'data' => $stats
            ]);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to get timetable statistics',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Calculate generation progress
     */
    protected function calculateGenerationProgress(GenerationRun $run): array
    {
        // Simplified progress calculation - in real implementation, use more sophisticated tracking
        switch ($run->status) {
            case 'PENDING':
                return ['percentage' => 0, 'message' => 'Waiting to start'];
            case 'RUNNING':
                return ['percentage' => 50, 'message' => 'Generating timetable'];
            case 'SUCCESS':
                return ['percentage' => 100, 'message' => 'Generation completed'];
            case 'FAILED':
                return ['percentage' => 0, 'message' => 'Generation failed'];
            case 'CANCELLED':
                return ['percentage' => 0, 'message' => 'Generation cancelled'];
            default:
                return ['percentage' => 0, 'message' => 'Unknown status'];
        }
    }

    /**
     * Group timetable cells by date and period
     */
    protected function groupTimetableByDateAndPeriod($cells): array
    {
        $grouped = [];

        foreach ($cells as $cell) {
            $date = $cell->date->format('Y-m-d');
            $period = $cell->period_ord;

            if (!isset($grouped[$date])) {
                $grouped[$date] = [];
            }

            if (!isset($grouped[$date][$period])) {
                $grouped[$date][$period] = [];
            }

            $grouped[$date][$period][] = $cell;
        }

        return $grouped;
    }

    /**
     * Group teacher assignments by date and period
     */
    protected function groupTeacherTimetableByDateAndPeriod($assignments): array
    {
        $grouped = [];

        foreach ($assignments as $assignment) {
            $cell = $assignment->cell;
            $date = $cell->date->format('Y-m-d');
            $period = $cell->period_ord;

            if (!isset($grouped[$date])) {
                $grouped[$date] = [];
            }

            if (!isset($grouped[$date][$period])) {
                $grouped[$date][$period] = [];
            }

            $grouped[$date][$period][] = [
                'cell' => $cell,
                'assignment' => $assignment
            ];
        }

        return $grouped;
    }

    /**
     * Calculate detailed statistics for a generation run
     */
    protected function calculateDetailedStats($generationRunId): array
    {
        $cells = TimetableCell::where('generation_run_id', $generationRunId)->get();

        $totalCells = $cells->count();
        $uniqueClasses = $cells->pluck('class_group_id')->unique()->count();
        $uniqueRooms = $cells->pluck('room_id')->unique()->count();

        $teacherAssignments = TimetableCellTeacher::whereHas('cell', function($q) use ($generationRunId) {
            $q->where('generation_run_id', $generationRunId);
        })->get();

        $uniqueTeachers = $teacherAssignments->pluck('teacher_id')->unique()->count();

        // Calculate teacher workload distribution
        $teacherWorkloads = [];
        foreach ($teacherAssignments as $assignment) {
            $teacherId = $assignment->teacher_id;
            if (!isset($teacherWorkloads[$teacherId])) {
                $teacherWorkloads[$teacherId] = 0;
            }
            $teacherWorkloads[$teacherId]++;
        }

        $workloads = array_values($teacherWorkloads);
        $avgWorkload = $workloads ? array_sum($workloads) / count($workloads) : 0;
        $maxWorkload = $workloads ? max($workloads) : 0;
        $minWorkload = $workloads ? min($workloads) : 0;

        // Calculate room utilization
        $roomUsage = [];
        foreach ($cells as $cell) {
            $roomId = $cell->room_id;
            if (!isset($roomUsage[$roomId])) {
                $roomUsage[$roomId] = 0;
            }
            $roomUsage[$roomId]++;
        }

        $roomUsages = array_values($roomUsage);
        $avgRoomUsage = $roomUsages ? array_sum($roomUsages) / count($roomUsages) : 0;

        return [
            'generation_run_id' => $generationRunId,
            'total_cells' => $totalCells,
            'unique_classes' => $uniqueClasses,
            'unique_teachers' => $uniqueTeachers,
            'unique_rooms' => $uniqueRooms,
            'teacher_workload' => [
                'average' => round($avgWorkload, 2),
                'maximum' => $maxWorkload,
                'minimum' => $minWorkload,
                'distribution' => $teacherWorkloads
            ],
            'room_utilization' => [
                'average_usage' => round($avgRoomUsage, 2),
                'distribution' => $roomUsage
            ],
            'cells_per_day' => $this->calculateCellsPerDay($cells),
            'cells_per_class' => $this->calculateCellsPerClass($cells)
        ];
    }

    /**
     * Calculate cells per day
     */
    protected function calculateCellsPerDay($cells): array
    {
        $dailyCounts = [];
        foreach ($cells as $cell) {
            $date = $cell->date->format('Y-m-d');
            if (!isset($dailyCounts[$date])) {
                $dailyCounts[$date] = 0;
            }
            $dailyCounts[$date]++;
        }

        return $dailyCounts;
    }

    /**
     * Calculate cells per class
     */
    protected function calculateCellsPerClass($cells): array
    {
        $classCounts = [];
        foreach ($cells as $cell) {
            $classId = $cell->class_group_id;
            if (!isset($classCounts[$classId])) {
                $classCounts[$classId] = 0;
            }
            $classCounts[$classId]++;
        }

        return $classCounts;
    }
}
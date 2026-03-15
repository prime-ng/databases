<?php
namespace Modules\SmartTimetable\Services\Storage;

use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Modules\Prime\Models\AcademicSession;
use Modules\SchoolSetup\Models\SchoolClass;
use Modules\SchoolSetup\Models\Section;
use Modules\SmartTimetable\Models\ClassGroupJnt;
use Modules\SmartTimetable\Models\GenerationRun;
use Modules\SmartTimetable\Models\PeriodSetPeriod;
use Modules\SmartTimetable\Models\SchoolDay;
use Modules\SmartTimetable\Models\Timetable;
use Modules\SmartTimetable\Models\TimetableCell;
use Ramsey\Uuid\Uuid;

class TimetableStorageService
{
    protected $timetable;
    protected $generationRun;
    protected $academicSession;

    /**
     * Store generated timetable to database
     */
    public function storeGeneratedTimetable(
        array $schoolGrid,
        Collection $activities, // Change from array to Collection
        array $stats,
        string $generationMethod = 'FULL_AUTO',
        ?int $timetableTypeId = null,
        ?int $periodSetId = null,
        ?string $timetableCode = null,
        ?string $timetableName = null
    ): Timetable {
        DB::beginTransaction();

        try {
            // 1. Get current academic session
            $this->academicSession = AcademicSession::current()->firstOrFail();

            // 2. Create or get timetable
            $this->timetable = $this->createTimetable(
                $timetableCode,
                $timetableName,
                $timetableTypeId,
                $periodSetId,
                $generationMethod
            );

            // 3. Create generation run
            $this->generationRun = $this->createGenerationRun($stats);

            // 4. Store timetable cells - pass the Collection directly
            $this->storeTimetableCells($schoolGrid, $activities);

            // 5. Update statistics
            $this->updateTimetableStats();

            DB::commit();

            return $this->timetable;

        } catch (\Exception $e) {
            DB::rollBack();
            throw new \Exception("Failed to store timetable: " . $e->getMessage());
        }
    }

    /**
     * Create main timetable record
     */
    protected function createTimetable(
        ?string $code = null,
        ?string $name = null,
        ?int $timetableTypeId = null,
        ?int $periodSetId = null,
        string $generationMethod = 'FULL_AUTO'
    ): Timetable {
        if (!$code) {
            $code = 'TT_' . now()->format('Y_m') . '_' . Str::random(4);
        }

        if (!$name) {
            $name = 'Generated Timetable ' . now()->format('Y-m-d H:i');
        }

        // Generate UUID string
        $uuidString = Uuid::uuid4()->toString();

        // Convert UUID string to binary (16 bytes)
        $uuidBinary = Uuid::fromString($uuidString)->getBytes();

        // Check if binary is exactly 16 bytes
        if (strlen($uuidBinary) !== 16) {
            throw new \Exception('Invalid UUID binary length: ' . strlen($uuidBinary));
        }

        $timetable = Timetable::create([
            'uuid' => $uuidBinary, // Store as binary (16 bytes)
            'code' => $code,
            'name' => $name,
            'description' => 'Automatically generated timetable',
            'academic_session_id' => $this->academicSession->id,
            'timetable_type_id' => $timetableTypeId ?? 1,
            'period_set_id' => $periodSetId ?? 1,
            'effective_from' => now()->startOfWeek(),
            'effective_to' => now()->endOfWeek(),
            'generation_method' => $generationMethod,
            'version' => 1,
            'status' => 'GENERATED',
            'constraint_violations' => 0,
            'stats_json' => null,
            'created_by' => auth()->id(),
        ]);

        return $timetable;
    }
    /**
     * Create generation run record
     */
    protected function createGenerationRun(array $stats): GenerationRun
    {
        // Generate UUID string and convert to binary
        $uuidString = Uuid::uuid4()->toString();
        $uuidBinary = Uuid::fromString($uuidString)->getBytes();
        $generationRun = GenerationRun::create([
            'uuid' => $uuidBinary,
            'timetable_id' => $this->timetable->id,
            'run_number' => GenerationRun::where('timetable_id', $this->timetable->id)->count() + 1,
            'started_at' => now()->subMinutes(5), // Assuming generation took 5 minutes
            'finished_at' => now(),
            'status' => 'COMPLETED',
            'algorithm_version' => '1.0.0', // Your current algorithm version
            'max_recursion_depth' => 50,
            'max_placement_attempts' => 50,
            'params_json' => null,
            'activities_total' => $stats['total_activities'] ?? 0,
            'activities_placed' => $stats['activities_placed'] ?? 0,
            'activities_failed' => $stats['activities_failed'] ?? 0,
            'hard_violations' => $stats['hard_violations'] ?? 0,
            'soft_violations' => $stats['soft_violations'] ?? 0,
            'soft_score' => $stats['soft_score'] ?? null,
            'stats_json' => json_encode($stats),
            'triggered_by' => auth()->id(),
        ]);

        return $generationRun;
    }

    /**
     * Store all timetable cells
     */
    protected function storeTimetableCells(array $schoolGrid, \Illuminate\Database\Eloquent\Collection $activities): void
    {
        // Key activities by ID for quick lookup
        $activitiesById = $activities->keyBy('id');

        $cellsCreated = 0;
        $teacherAssignmentsCreated = 0;

        foreach ($schoolGrid as $classKey => $days) {
            try {
                // Parse class key (e.g., "10-A" -> class 10, section A)
                [$classCode, $sectionCode] = explode('-', $classKey, 2);

                \Log::debug('Looking up class group for:', [
                    'classKey' => $classKey,
                    'classCode' => $classCode,
                    'sectionCode' => $sectionCode,
                ]);

                // Find the class-group joint record
                $classGroup = \Modules\SchoolSetup\Models\ClassGroup::query()
                    ->whereHas('class', function ($q) use ($classCode) {
                        $q->where('code', $classCode);
                    })
                    ->whereHas('section', function ($q) use ($sectionCode) {
                        $q->where('code', $sectionCode);
                    })
                    ->first();

                if (!$classGroup) {
                    \Log::warning('ClassGroup not found for class-section:', [
                        'class_code' => $classCode,
                        'section_code' => $sectionCode,
                    ]);
                    continue;
                }

                \Log::debug('Found ClassGroup:', [
                    'id' => $classGroup->id,
                    'class' => $classGroup->class->code ?? 'N/A',
                    'section' => $classGroup->section->code ?? 'N/A',
                ]);

                foreach ($days as $dayId => $periods) {
                    foreach ($periods as $periodId => $activityId) {
                        if (!$activityId) {
                            continue;
                        }

                        $activity = $activitiesById->get($activityId);
                        if (!$activity) {
                            \Log::warning('Activity not found:', ['activity_id' => $activityId]);
                            continue;
                        }

                        // Convert day ID to day of week (1-7)
                        $dayOfWeek = $this->getDayOfWeek($dayId);
                        if (!$dayOfWeek) {
                            \Log::warning('Invalid day ID:', ['day_id' => $dayId]);
                            continue;
                        }

                        // Convert period ID to period ordinal
                        $periodOrd = $this->getPeriodOrdinal($periodId);
                        if (!$periodOrd) {
                            \Log::warning('Invalid period ID:', ['period_id' => $periodId]);
                            continue;
                        }

                        // Check if cell already exists (prevent duplicates)
                        $existingCell = TimetableCell::where('timetable_id', $this->timetable->id)
                            ->where('class_group_id', $classGroup->id)
                            ->where('day_of_week', $dayOfWeek)
                            ->where('period_ord', $periodOrd)
                            ->first();

                        if ($existingCell) {
                            \Log::debug('Updating existing cell:', [
                                'cell_id' => $existingCell->id,
                                'activity_id' => $activity->id,
                            ]);

                            // Update existing cell
                            $existingCell->update([
                                'activity_id' => $activity->id,
                                'generation_run_id' => $this->generationRun->id,
                                'source' => 'AUTO',
                            ]);
                            $cell = $existingCell;
                        } else {
                            // Create new cell record
                            $cell = TimetableCell::create([
                                'timetable_id' => $this->timetable->id,
                                'generation_run_id' => $this->generationRun->id,
                                'day_of_week' => $dayOfWeek,
                                'period_ord' => $periodOrd,
                                'class_group_id' => $classGroup->id,
                                'activity_id' => $activity->id,
                                'source' => 'AUTO',
                                'is_locked' => false,
                                'has_conflict' => false,
                            ]);
                            $cellsCreated++;

                            \Log::debug('Created new TimetableCell:', [
                                'id' => $cell->id,
                                'class_group_id' => $classGroup->id,
                                'activity_id' => $activity->id,
                            ]);
                        }

                        // Store teacher assignments using direct DB query (avoiding relationship issues)
                        if ($activity->teachers && $activity->teachers->count() > 0) {
                            $teacherAssignments = [];

                            foreach ($activity->teachers as $teacherAssignment) {
                                $teacherAssignments[] = [
                                    'cell_id' => $cell->id,
                                    'teacher_id' => $teacherAssignment->teacher_id,
                                    'assignment_role_id' => $teacherAssignment->assignment_role_id,
                                    'is_substitute' => false,
                                    'created_at' => now(),
                                    'updated_at' => now(),
                                ];
                                $teacherAssignmentsCreated++;
                            }

                            // Remove existing assignments first
                            DB::table('tt_timetable_cell_teachers')
                                ->where('cell_id', $cell->id)
                                ->delete();

                            // Bulk insert teacher assignments
                            if (!empty($teacherAssignments)) {
                                DB::table('tt_timetable_cell_teachers')->insert($teacherAssignments);
                            }

                            \Log::debug('Added teachers to cell:', [
                                'cell_id' => $cell->id,
                                'teacher_count' => count($teacherAssignments),
                            ]);
                        }

                    }
                }

            } catch (\Exception $e) {
                \Log::error('Error storing timetable cells for classKey: ' . $classKey, [
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString(),
                ]);
                continue;
            }
        }

        \Log::info('Timetable cells stored:', [
            'cells_created' => $cellsCreated,
            'teacher_assignments_created' => $teacherAssignmentsCreated,
            'timetable_id' => $this->timetable->id,
        ]);
    }

    /**
     * Convert day ID to day of week (1-7)
     */
    protected function getDayOfWeek(int $dayId): int
    {
        $day = SchoolDay::find($dayId);
        return $day ? $day->day_of_week : 1; // Default to Monday
    }

    /**
     * Convert period ID to period ordinal
     */
    protected function getPeriodOrdinal(int $periodId): int
    {
        $period = PeriodSetPeriod::find($periodId);
        return $period ? $period->period_ord : 1; // Default to first period
    }

    /**
     * Update timetable statistics
     */
    protected function updateTimetableStats(): void
    {
        $cellCount = TimetableCell::where('timetable_id', $this->timetable->id)->count();
        $teacherAssignments = DB::table('tt_timetable_cell_teachers')
            ->whereIn('cell_id', function ($query) {
                $query->select('id')
                    ->from('tt_timetable_cells')
                    ->where('timetable_id', $this->timetable->id);
            })
            ->count();

        $stats = [
            'total_cells' => $cellCount,
            'total_teacher_assignments' => $teacherAssignments,
            'generated_at' => now()->toIso8601String(),
            'generation_duration' => $this->generationRun->started_at->diffInSeconds($this->generationRun->finished_at),
        ];

        $this->timetable->update([
            'stats_json' => json_encode($stats),
        ]);
    }

    /**
     * Get timetable by code
     */
    public function getTimetableByCode(string $code): ?Timetable
    {
        return Timetable::where('code', $code)->first();
    }

    /**
     * Load timetable from database
     */
    public function loadTimetableFromDatabase(Timetable $timetable): array
    {
        $cells = TimetableCell::with([
            'classGroup.class',
            'classGroup.section',
            'activity',
            'activity.classGroupJnt.subjectStudyFormat.subject',
            'teachers.teacher.user',
        ])
            ->where('timetable_id', $timetable->id)
            ->where('is_active', true)
            ->get();

        // Transform to school grid format
        $schoolGrid = [];
        $activitiesById = [];

        foreach ($cells as $cell) {
            if (!$cell->classGroup || !$cell->activity) {
                continue;
            }

            $classKey = $cell->classGroup->class->code . '-' . $cell->classGroup->section->code;
            $dayId = $this->getDayIdFromDayOfWeek($cell->day_of_week);
            $periodId = $this->getPeriodIdFromOrdinal($cell->period_ord);

            $schoolGrid[$classKey][$dayId][$periodId] = $cell->activity_id;
            $activitiesById[$cell->activity_id] = $cell->activity;
        }

        return [
            'schoolGrid' => $schoolGrid,
            'activitiesById' => $activitiesById,
            'timetable' => $timetable,
        ];
    }

    /**
     * Convert day of week to day ID
     */
    protected function getDayIdFromDayOfWeek(int $dayOfWeek): ?int
    {
        $day = SchoolDay::where('day_of_week', $dayOfWeek)->first();
        return $day ? $day->id : null;
    }

    /**
     * Convert period ordinal to period ID
     */
    protected function getPeriodIdFromOrdinal(int $periodOrd): ?int
    {
        $period = PeriodSetPeriod::where('period_ord', $periodOrd)->first();
        return $period ? $period->id : null;
    }
}
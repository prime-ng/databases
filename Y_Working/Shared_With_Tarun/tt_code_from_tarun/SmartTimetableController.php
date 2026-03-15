<?php

namespace Modules\SmartTimetable\Http\Controllers;

use App\Http\Controllers\Controller;
use Modules\SchoolSetup\Models\Subject;
use Modules\SchoolSetup\Models\SubjectGroup;
use Modules\SchoolSetup\Models\SubjectGroupSubject;
use Modules\SchoolSetup\Models\SubjectStudyFormatClass;
use Modules\SmartTimetable\Models\ClassGroupJnt;
use Modules\SmartTimetable\Services\Constraints\ConstraintManager;
use Modules\SmartTimetable\Services\Constraints\Hard\BreakConstraint;
use Modules\SmartTimetable\Services\Constraints\Hard\DailySpreadConstraint;
use Modules\SmartTimetable\Services\Constraints\Hard\FixedPeriodForHighPriorityConstraint;
use Modules\SmartTimetable\Services\Constraints\Hard\NoSameSubjectSameDayConstraint;
use Modules\SmartTimetable\Services\Constraints\Hard\ShortBreakConstraint;
use Modules\SmartTimetable\Services\Constraints\Hard\LunchBreakConstraint;
use Modules\SmartTimetable\Services\Constraints\Hard\TeacherConflictConstraint;
use Modules\SmartTimetable\Services\Constraints\Hard\HighPriorityFixedPeriodConstraint;
use Modules\SmartTimetable\Services\Constraints\Soft\PreferredTimeOfDayConstraint;
use Modules\SmartTimetable\Services\Constraints\Hard\RoomAvailabilityConstraint;
use Modules\SmartTimetable\Services\Constraints\Hard\MaximumDailyLoadConstraint;
use Modules\SmartTimetable\Services\DatabaseConstraintService;
use Modules\SmartTimetable\Services\Generator\FETSolver;
use Modules\SmartTimetable\Services\Generator\ImprovedTimetableGenerator; // NEW GENERATOR
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Modules\Prime\Models\AcademicSession;
use Modules\SchoolSetup\Models\Building;
use Modules\SchoolSetup\Models\ClassSection;
use Modules\SchoolSetup\Models\Room;
use Modules\SchoolSetup\Models\Teacher;
use Modules\SmartTimetable\Exceptions\HardConstraintViolationException;
use Modules\SmartTimetable\Models\Activity;
use Modules\SmartTimetable\Models\ClassGroupRequirement;
use Modules\SmartTimetable\Models\ClassSubgroup;
use Modules\SmartTimetable\Models\Constraint;
use Modules\SmartTimetable\Models\ConstraintType;
use Modules\SmartTimetable\Models\DayType;
use Modules\SmartTimetable\Models\GenerationRun;
use Modules\SmartTimetable\Models\PeriodSet;
use Modules\SmartTimetable\Models\PeriodSetPeriod;
use Modules\SmartTimetable\Models\PeriodType;
use Modules\SmartTimetable\Models\RoomUnavailable;
use Modules\SmartTimetable\Models\SchoolDay;
use Modules\SmartTimetable\Models\Shift;
use Modules\SmartTimetable\Models\TeacherUnavailable;
use Modules\SmartTimetable\Models\Timetable;
use Modules\SmartTimetable\Models\TimetableCell;
use Modules\SmartTimetable\Models\TimetableCellTeacher;
use Modules\SmartTimetable\Models\TimetableType;
use Modules\SmartTimetable\Models\WorkingDay;
use Modules\SmartTimetable\Models\TeacherAssignmentRole;
use Ramsey\Uuid\Uuid;

class SmartTimetableController extends Controller
{

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $schoolDays = SchoolDay::all();
        $shifts = Shift::all();
        $dayTypes = DayType::all();
        $workingDays = WorkingDay::all();
        $academicSession = AcademicSession::current()->firstOrFail();
        $periodTypes = PeriodType::all();
        $periodSets = PeriodSet::all();
        $constraintTypes = ConstraintType::all();
        $constraints = Constraint::paginate(10);
        $teachersUnavailable = TeacherUnavailable::paginate(10);
        $classSubgroups = ClassSubgroup::paginate(10);
        $roomsUnavailable = RoomUnavailable::paginate(10);
        $assignmentRoles = TeacherAssignmentRole::paginate(10);
        $classGroupRequirements = ClassGroupRequirement::paginate(10);
        //$activities = Activity::with(['classGroup', 'classSubgroup', 'academicSession', 'subject', 'studyFormat'])->paginate(10);
        $groupedActivities = Activity::with([
            'classGroupJnt.subject', // ClassGroup has subject() relationship
            'preferredRoomType',
        ])
            ->where('is_active', true)
            ->get()
            ->groupBy(
                fn($activity) =>
                // Group by class_label (e.g., "7 A") 
                // If you need to separate class and section, parse the class_label
                $activity->classGroupJnt->class_label ?? 'unknown'
            )
            ->map(function ($activities) {
                $first = $activities->first();
                $classGroup = $first->classGroupJnt;

                // Parse class_label to get class and section if needed
                // Example: "7 A" -> class = "7", section = "A"
                $classLabel = $classGroup->class_label ?? 'Unknown';
                $parts = explode(' ', $classLabel);
                $class = $parts[0] ?? 'Unknown';
                $section = $parts[1] ?? null;

                return [
                    'class' => (object) [
                        'id' => null, // You might not have class ID
                        'name' => $class,
                    ],
                    'section' => $section ? (object) [
                        'id' => null,
                        'name' => $section,
                    ] : null,
                    'activities' => $activities,
                    'class_label' => $classLabel,
                    'subject' => $classGroup->subject->name ?? 'Unknown',
                ];
            })
            ->values();
        $timetableTypes = TimetableType::paginate(10);
        $timetables = Timetable::paginate(10);
        $periodSetPeriods = PeriodSet::paginate(10);
        $teachers = Teacher::withCount([
            'activityAssignments as activity_assignments_count',
            'timetableCellAssignments as timetable_cell_assignments_count',
        ])
            ->with([
                'user',
                'activityAssignments.activity.classGroupJnt.subjectStudyFormat.subject',
                'activityAssignments.activity.classGroupJnt.subjectStudyFormat.studyFormat',
                'timetableCellAssignments'
            ])
            ->paginate(10);

        $optimalWorkloadCount = 0;
        $highWorkloadCount = 0;
        $overloadedCount = 0;

        foreach ($teachers as $teacher) {
            $assigned = $teacher->timetable_cell_assignments_count;
            $max = $teacher->max_periods_per_week ?? 36;
            $percent = $max > 0 ? round(($assigned / $max) * 100) : 0;

            if ($percent >= 100)
                $overloadedCount++;
            elseif ($percent >= 80)
                $highWorkloadCount++;
            elseif ($percent >= 50)
                $optimalWorkloadCount++;
        }

        // Load subjects for filter
        $subjects = Subject::orderBy('name')->get();

        // Get all requirements with relationships
        $requirements = ClassGroupRequirement::with([
            'classGroup.subject',
            'classSubgroup.classGroup.subject',
            'academicSession'
        ])->get();

        // Separate groups and subgroups
        $groupedRequirements = [
            'groups' => $requirements->filter(fn($req) => $req->targetsClassGroup()),
            'subgroups' => $requirements->filter(fn($req) => $req->targetsClassSubgroup()),
        ];
        $totalRequirements = $requirements->count();

        $rooms = Room::with(['building', 'roomType'])->paginate(10);
        return view('smarttimetable::smart-timetable.index', compact(
            'timetableTypes',
            'classGroupRequirements',
            'groupedActivities',
            'assignmentRoles',
            'roomsUnavailable',
            'classSubgroups',
            'teachersUnavailable',
            'constraints',
            'constraintTypes',
            'schoolDays',
            'shifts',
            'dayTypes',
            'workingDays',
            'periodTypes',
            'academicSession',
            'periodSets',
            'timetables',
            'periodSetPeriods',
            'teachers',
            'rooms',
            'optimalWorkloadCount',
            'highWorkloadCount',
            'overloadedCount',
            'subjects',
            'groupedRequirements',
            'totalRequirements'
        ));
    }
    public function generate()
    {


        //return $this->debugPeriods();
        //return $this->debugActivityDurations();
        //return $this->diagnoseLunchProblem();
        ini_set('memory_limit', '256M');  // Increase memory
        ini_set('max_execution_time', 300);
        //set_time_limit(300); // 3 minutes
        //return $this->debugPlacementIssue();

        session()->forget([
            'generated_timetable_grid',
            'generated_activities',
            'generated_days',
            'generated_periods',
            'generated_class_sections',
        ]);


        // Load all required data

        $classSections = $this->loadClassSections();

        $academicSessions = AcademicSession::current()->get();

        $timetableTypes = TimetableType::where('is_active', true)->get();

        $periodSets = PeriodSet::where('is_active', true)->get();

        $academicSession = AcademicSession::current()->firstOrFail();

        // Load activities for active class + sections only.
        $activities = $this->loadActivitiesForActiveClassSections();

        // Load school days i.e the days on which school is open.
        $days = $this->loadSchoolDays();

        // Load the default period set.
        $periods = $this->loadPeriodSet();

        // Load Constraints to pass to the generator
        $constraintService = new DatabaseConstraintService();
        $constraintManager = $constraintService->loadConstraintsForGeneration(
            $academicSession->id,
            [
                'academic_session_id' => $academicSession->id,
                'total_classes' => $classSections->count(),
                'total_activities' => $activities->count(),
            ]
        );
        // dd($constraintManager);
        // exit;

        // Log constraint summary
        $hardCount = count($constraintManager->getHardConstraints());
        $softCount = count($constraintManager->getSoftConstraints());

        \Log::info('Starting generation with database constraints', [
            'academic_session' => $academicSession->name,
            'hard_constraints' => $hardCount,
            'soft_constraints' => $softCount,
        ]);

        // If no constraints loaded, log warning but continue
        if ($hardCount === 0 && $softCount === 0) {
            \Log::warning('No constraints loaded from database! Generation will proceed without any constraints.');
        }

        $generator = new ImprovedTimetableGenerator($days, $periods, $constraintManager);
        $entries = $generator->generate($activities);
        //return $entries;
        // 5️⃣ Build the timetable grid (same as before)
        $activitiesById = $activities->keyBy('id');
        $schoolGrid = [];
        $conflicts = [];

        //dd($activitiesById);

        foreach ($entries as $entry) {

            /** @var Activity $activity */
            $activity = $activitiesById[$entry['activity_id']] ?? null;
            if (!$activity) {
                continue;
            }

            // --------------------------------------------
            // 1️⃣ Resolve classKey SAFELY
            // --------------------------------------------
            if ($activity->class_group_jnt_id && $activity->classGroupJnt) {

                // CLASS GROUP activity
                $classKey =
                    $activity->classGroupJnt->class->code . '-' .
                    $activity->classGroupJnt->section->code;

            } elseif ($activity->class_subgroup_id && $activity->classSubgroup) {

                // CLASS SUBGROUP activity (still belongs to a class-section)
                $classKey =
                    $activity->classSubgroup->class->code . '-' .
                    $activity->classSubgroup->section->code;

            } else {
                // Safety net (should never happen)
                logger()->warning('Activity without valid target', [
                    'activity_id' => $activity->id,
                ]);
                continue;
            }

            // --------------------------------------------
            // 2️⃣ Conflict detection
            // --------------------------------------------
            if (isset($schoolGrid[$classKey][$entry['day_id']][$entry['period_id']])) {

                $conflicts[] = [
                    'class' => $classKey,
                    'day_id' => $entry['day_id'],
                    'period_id' => $entry['period_id'],
                    'existing_activity_id' =>
                        $schoolGrid[$classKey][$entry['day_id']][$entry['period_id']],
                    'new_activity_id' => $entry['activity_id'],
                ];

                continue;
            }

            // --------------------------------------------
            // 3️⃣ Place activity
            // --------------------------------------------
            $schoolGrid[$classKey][$entry['day_id']][$entry['period_id']] =
                $entry['activity_id'];
        }


        // 6️⃣ Store in session
        $stats = $generator->getStats();

        session([
            // Existing
            'generated_timetable_grid' => $schoolGrid,
            'generated_activities' => $activitiesById,
            'generated_days' => $days,
            'generated_periods' => $periods,
            'generated_class_sections' => $classSections,
            'generated_conflicts' => $conflicts,

            // 🆕 Generation Run metadata
            'generation_run_meta' => [
                'algorithm_version' => 'v1.0.0', // or config('smarttimetable.algorithm_version')

                'started_at' => $stats['started_at'] ?? now()->subSeconds($stats['generation_time'] ?? 0),
                'finished_at' => now(),

                'max_recursion_depth' => $stats['max_recursion_depth'] ?? null,
                'max_placement_attempts' => $stats['max_attempts'] ?? 200,

                // Parameters that influenced the run
                'params' => [
                    'constraints' => collect($constraintManager->getConstraints())
                        ->map(fn($c) => class_basename($c))
                        ->values(),

                    'days_count' => $days->count(),
                    'periods_per_day' => $periods->count(),
                ],
            ],

            // 🆕 Generation Run results
            'generation_run_stats' => [
                'activities_total' => $stats['activities'] ?? $activitiesById->count(),
                'activities_placed' => $stats['periods_placed'] ?? 0,
                'activities_failed' => max(
                    0,
                    ($stats['activities'] ?? 0) - ($stats['activities_fully_placed'] ?? 0)
                ),

                'hard_violations' => count($conflicts),
                'soft_violations' => 0,
                'soft_score' => null,

                // Full raw stats for audit/debug
                'stats_json' => $stats,
            ],
        ]);


        // 7️⃣ Return view with data
        return view('smarttimetable::preview.index', [
            'days' => $days,
            'periods' => $periods,
            'schoolGrid' => $schoolGrid,
            'activitiesById' => $activitiesById,
            'classSections' => $classSections,
            'total_entries_generated' => count($entries),
            'slots_filled' => collect($schoolGrid)->flatten(2)->count(),
            'conflicts_detected' => count($conflicts),
            'conflicts' => $conflicts,
            'academicSessions' => $academicSessions,
            'timetableTypes' => $timetableTypes,
            'periodSets' => $periodSets,
            'algorithm_stats' => $generator->getStats(), // If you add this method
        ]);
    }

    /**
     * Create and configure the constraint manager
     */
    private function createConstraintManager(Collection $activities, Collection $days, Collection $periods): ConstraintManager
    {
        $constraintManager = new ConstraintManager();

        // === HARD CONSTRAINTS (MUST BE SATISFIED) ===

        // 1. Break constraints
        //$breakConstraint = new BreakConstraint(['breaks' => ['SBREAK']]);
        //$constraintManager->addConstraint($breakConstraint);

        // $constraintManager->addConstraint(
        //     new NoSameSubjectSameDayConstraint()
        // );

        // $constraintManager->addConstraint(
        //     new FixedPeriodForHighPriorityConstraint()
        // );


        // 2. Teacher conflicts
        //$constraintManager->addConstraint(new TeacherConflictConstraint());

        // 3. Fixed period for high priority activities
        //$constraintManager->addConstraint(new HighPriorityFixedPeriodConstraint());

        // 4. Room availability (if you have rooms)
        // $constraintManager->addConstraint(new RoomAvailabilityConstraint());

        // 5. Maximum daily load (6 periods per day per class)
        //$constraintManager->addConstraint(new MaximumDailyLoadConstraint(6));

        // 6. Teacher unavailable periods (if you have this data)
        // $constraintManager->addConstraint(new TeacherUnavailableConstraint());

        // === SOFT CONSTRAINTS (PREFERENCES) ===

        // 1. Preferred time of day based on subject type
        //$constraintManager->addConstraint(new PreferredTimeOfDayConstraint(), false);

        // 2. Balanced daily schedule
        // $constraintManager->addConstraint(new BalancedDailyScheduleConstraint(), false);

        // 3. Consecutive periods for labs
        // $constraintManager->addConstraint(new ConsecutiveLabPeriodsConstraint(), false);

        // 4. Avoid gaps in schedule
        // $constraintManager->addConstraint(new CompactScheduleConstraint(), false);

        return $constraintManager;
    }

    /**
     * Alternative: Load constraints from database
     */
    private function createConstraintManagerFromDatabase(): ConstraintManager
    {
        $constraintManager = new ConstraintManager();

        // Load active constraints from database
        $constraints = Constraint::where('is_active', true)->get();

        foreach ($constraints as $constraint) {
            $constraintClass = $this->resolveConstraintClass($constraint->type);

            if ($constraintClass) {
                $constraintInstance = new $constraintClass(
                    json_decode($constraint->parameters, true) ?? []
                );

                $constraintManager->addConstraint(
                    $constraintInstance,
                    $constraint->is_hard
                );
            }
        }

        return $constraintManager;
    }

    /**
     * Map constraint type to class
     */
    private function resolveConstraintClass(string $type): ?string
    {
        $constraintMap = [
            'short_break' => ShortBreakConstraint::class,
            'lunch_break' => LunchBreakConstraint::class,
            //'teacher_conflict' => TeacherConflictConstraint::class,
            // 'room_availability' => RoomAvailabilityConstraint::class,
            // 'max_daily_load' => MaximumDailyLoadConstraint::class,
            // 'preferred_time' => PreferredTimeOfDayConstraint::class,
        ];

        return $constraintMap[$type] ?? null;
    }

    public function preview(Timetable $timetable)
    {
        /*
        |--------------------------------------------------------------------------
        | 1️⃣ Load core reference data (same as before)
        |--------------------------------------------------------------------------
        */
        $days = SchoolDay::schoolDays()->get();

        $periods = PeriodSetPeriod::with('periodType')
            ->where('is_active', true)
            ->orderBy('period_ord')
            ->get();

        $academicSessions = AcademicSession::all();
        $timetableTypes = TimetableType::all();
        $periodSets = PeriodSet::all();

        /*
        |--------------------------------------------------------------------------
        | 2️⃣ Load timetable cells with relations
        |--------------------------------------------------------------------------
        */
        $cells = TimetableCell::with([
            'activity',
            'activity.classGroupJnt.class',
            'activity.classGroupJnt.section',
        ])
            ->where('timetable_id', $timetable->id)
            ->get();

        if ($cells->isEmpty()) {
            return redirect()->back()
                ->with('error', 'No timetable cells found for this timetable.');
        }

        /*
        |--------------------------------------------------------------------------
        | 3️⃣ Rebuild activitiesById (same shape as session)
        |--------------------------------------------------------------------------
        */
        $activitiesById = $cells
            ->pluck('activity')
            ->unique('id')
            ->keyBy('id');

        /*
        |--------------------------------------------------------------------------
        | 4️⃣ Rebuild classSections (same meaning as before)
        |--------------------------------------------------------------------------
        */
        $classSections = $this->loadClassSections();

        /*
        |--------------------------------------------------------------------------
        | 5️⃣ Rebuild schoolGrid (IDENTICAL SHAPE)
        |--------------------------------------------------------------------------
        | $schoolGrid[classKey][day_id][period_id] = activity_id
        |--------------------------------------------------------------------------
        */
        $schoolGrid = [];

        foreach ($cells as $cell) {
            $activity = $cell->activity;
            if (!$activity || !$activity->classGroupJnt) {
                continue;
            }

            $classKey =
                $activity->classGroupJnt->class->code . '-' .
                $activity->classGroupJnt->section->code;

            // Convert period_ord → period_id (to match old view)
            $periodId = $periods
                ->firstWhere('period_ord', $cell->period_ord)
                    ?->id;

            if (!$periodId) {
                continue;
            }

            $schoolGrid[$classKey][$cell->day_of_week][$periodId] = $activity->id;
        }

        /*
        |--------------------------------------------------------------------------
        | 6️⃣ Stats (same as before)
        |--------------------------------------------------------------------------
        */
        $slots_filled = collect($schoolGrid)->flatten(2)->count();
        $total_activities = $activitiesById->count();

        /*
        |--------------------------------------------------------------------------
        | 7️⃣ Conflicts (DB-based, empty for now)
        |--------------------------------------------------------------------------
        */
        $conflicts = []; // later from tt_timetable_cells.has_conflict
        $conflicts_detected = 0;

        /*
        |--------------------------------------------------------------------------
        | 8️⃣ Return SAME view with SAME data keys
        |--------------------------------------------------------------------------
        */
        return view('smarttimetable::timetable.preview', [
            'days' => $days,
            'periods' => $periods,
            'schoolGrid' => $schoolGrid,
            'activitiesById' => $activitiesById,
            'classSections' => $classSections,
            'academicSessions' => $academicSessions,
            'timetableTypes' => $timetableTypes,
            'periodSets' => $periodSets,
            'slots_filled' => $slots_filled,
            'total_activities' => $total_activities,
            'conflicts_detected' => $conflicts_detected,
            'conflicts' => $conflicts,
        ]);
    }


    /**
     * Store the generated timetable into the database
     */
    public function storeTimetable(Request $request)
    {
        $validated = $request->validate([
            'timetable_name' => 'required|string|max:200',
            'academic_session_id' => 'required',
            'timetable_type_id' => 'required|exists:tt_timetable_types,id',
            'period_set_id' => 'required|exists:tt_period_sets,id',
            'effective_from' => 'required|date',
            'effective_to' => 'nullable|date|after:effective_from',
        ]);

        // Load generated data from session
        $schoolGrid = session('generated_timetable_grid');
        $activitiesById = session('generated_activities');
        $periods = session('generated_periods');

        $runMeta = session('generation_run_meta');
        $runStats = session('generation_run_stats');

        if (!$schoolGrid || !$activitiesById || !$periods || !$runMeta || !$runStats) {
            return back()->with('error', 'No generated timetable data found. Please generate first.');
        }

        DB::beginTransaction();

        try {
            /*
            |--------------------------------------------------------------------------
            | 1️⃣ Create Timetable
            |--------------------------------------------------------------------------
            */
            $timetable = Timetable::create([
                'uuid' => Uuid::uuid4()->getBytes(),
                'code' => 'TT_' . now()->format('Ymd_His') . '_' . Str::random(4),
                'name' => $validated['timetable_name'],
                'academic_session_id' => $validated['academic_session_id'],
                'timetable_type_id' => $validated['timetable_type_id'],
                'period_set_id' => $validated['period_set_id'],
                'effective_from' => $validated['effective_from'],
                'effective_to' => $validated['effective_to'],
                'generation_method' => 'SEMI_AUTO',
                'status' => 'GENERATED',
                'created_by' => auth()->id(),
            ]);

            /*
            |--------------------------------------------------------------------------
            | 2️⃣ Create Generation Run (FULLY AUDITED)
            |--------------------------------------------------------------------------
            */
            $generationRun = GenerationRun::create([
                'uuid' => Uuid::uuid4()->getBytes(),
                'timetable_id' => $timetable->id,
                'run_number' => 1,

                'started_at' => $runMeta['started_at'],
                'finished_at' => $runMeta['finished_at'],
                'status' => $runStats['activities_failed'] > 0 ? 'QUEUED' : 'COMPLETED',

                'algorithm_version' => $runMeta['algorithm_version'],
                'max_recursion_depth' => 1, //$runMeta['max_recursion_depth'],
                'max_placement_attempts' => $runMeta['max_placement_attempts'],
                'params_json' => json_encode($runMeta['params']),

                'activities_total' => $runStats['activities_total'],
                'activities_placed' => $runStats['activities_placed'],
                'activities_failed' => $runStats['activities_failed'],

                'hard_violations' => $runStats['hard_violations'],
                'soft_violations' => $runStats['soft_violations'],
                'soft_score' => $runStats['soft_score'],

                'stats_json' => json_encode($runStats['stats_json']),
                'error_message' => null,

                'triggered_by' => auth()->id(),
            ]);

            /*
            |--------------------------------------------------------------------------
            | 3️⃣ Persist Timetable Cells
            |--------------------------------------------------------------------------
            */
            $cellsCreated = 0;

            foreach ($schoolGrid as $classKey => $dayGrid) {
                foreach ($dayGrid as $dayOfWeek => $periodGrid) {
                    foreach ($periodGrid as $periodId => $activityId) {

                        /** @var Activity|null $activity */
                        $activity = $activitiesById[$activityId] ?? null;
                        if (!$activity) {
                            continue;
                        }

                        // Resolve target (CHECK constraint safe)
                        $classGroupId = null;
                        $classSubgroupId = null;

                        if ($activity->class_group_jnt_id && !$activity->class_subgroup_id) {
                            $classGroupId = $activity->class_group_jnt_id;
                        } elseif (!$activity->class_group_jnt_id && $activity->class_subgroup_id) {
                            $classSubgroupId = $activity->class_subgroup_id;
                        } else {
                            logger()->warning('Invalid activity target', [
                                'activity_id' => $activity->id,
                            ]);
                            continue;
                        }

                        // Convert period_id → period_ord
                        $periodOrd = $periods
                            ->firstWhere('id', $periodId)
                                ?->period_ord;

                        if (!$periodOrd) {
                            continue;
                        }

                        // Create timetable cell
                        $cell = TimetableCell::create([
                            'timetable_id' => $timetable->id,
                            'generation_run_id' => $generationRun->id,

                            'day_of_week' => $dayOfWeek,
                            'period_ord' => $periodOrd,

                            'class_group_id' => $classGroupId,
                            'class_subgroup_id' => $classSubgroupId,

                            'activity_id' => $activity->id,
                            'sub_activity_id' => null,
                            'room_id' => null,

                            'source' => 'AUTO',
                            'is_locked' => false,
                            'has_conflict' => false,
                            'conflict_details_json' => null,
                        ]);

                        // Attach teachers via pivot
                        foreach ($activity->teachers as $activityTeacher) {
                            $cell->teachers()->attach(
                                $activityTeacher->teacher_id,
                                [
                                    'assignment_role_id' => $activityTeacher->assignment_role_id,
                                    'is_substitute' => false,
                                ]
                            );
                        }

                        $cellsCreated++;
                    }
                }
            }

            DB::commit();

            // Cleanup session
            session()->forget([
                'generated_timetable_grid',
                'generated_activities',
                'generated_days',
                'generated_periods',
                'generated_class_sections',
                'generated_conflicts',
                'generation_run_meta',
                'generation_run_stats',
            ]);

            return back()->with(
                'success',
                "Timetable stored successfully. {$cellsCreated} timetable cells created."
            );

        } catch (\Throwable $e) {
            DB::rollBack();

            logger()->error('Timetable storage failed', [
                'error' => $e->getMessage(),
            ]);

            return back()->with(
                'error',
                'Failed to store timetable. Please check logs.'
            );
        }
    }





    private function loadActivities(
        int $classId,
        int $sectionId
    ): Collection {
        return Activity::where('is_active', true)
            ->whereHas('classGroupJnt', function ($q) use ($classId, $sectionId) {
                $q->where('class_id', $classId)
                    ->where('section_id', $sectionId);
            })
            ->with([
                'classGroupJnt.class',
                'classGroupJnt.section',
                'classGroupJnt.subjectStudyFormat.subject',
                'classGroupJnt.subjectStudyFormat.studyFormat',
                'classGroupJnt.subjectType',
            ])
            ->get()
            ->keyBy('id');
    }

    private function loadActivitiesForActiveClassSections(): Collection
    {
        $activeClassSections = ClassSection::query()
            ->where('is_active', true)
            ->get(['class_id', 'section_id']);

        return Activity::query()
            ->with('teachers')
            ->where('is_active', true)
            ->with([
                'classGroupJnt', // This exists
            ])
            ->get()
            ->keyBy('id');
        //return Activity::get()->keyBy('id');
    }



    private function loadHardConstraints(): Collection
    {
        return Constraint::with('constraintType')
            ->where('is_active', true)
            ->where('is_hard', true)
            ->get();
    }


    private function loadClassSections(): Collection
    {
        return ClassSection::where('is_active', true)->get();
    }

    private function loadSchoolDays(): Collection
    {
        return SchoolDay::schoolDays()->get();
    }


    private function loadPeriodSet(): Collection
    {
        return PeriodSetPeriod::with('periodType')
            ->where('is_active', true)
            ->orderBy('period_ord', 'asc')
            ->get()
            ->each(function ($period) {
                // Ensure break periods are properly marked
                if (in_array($period->code, ['SBREAK', 'LUNCH'])) {
                    $period->is_break = true;
                } else {
                    $period->is_break = false;
                }
            });
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        return view('smarttimetable::create');
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
    }

    /**
     * Show the specified resource.
     */
    public function show($id)
    {
        return view('smarttimetable::show');
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit($id)
    {
        return view('smarttimetable::edit');
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $id)
    {
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id)
    {
    }

    // DEBUG CODE BELOW DOWN //


    public function debugPlacementIssue()
    {
        // Load data
        $activities = $this->loadActivitiesForActiveClassSections();
        $days = $this->loadSchoolDays();
        $periods = $this->loadPeriodSet();

        // Calculate capacity
        $teachingPeriods = $periods->whereNotIn('code', ['SBREAK', 'LUNCH']);
        $totalTeachingSlots = $days->count() * $teachingPeriods->count();
        $totalPeriodsNeeded = $activities->sum('weekly_periods');

        // Activity analysis
        $activityDetails = [];
        foreach ($activities as $activity) {
            $activityDetails[] = [
                'id' => $activity->id,
                'class' => $activity->classGroupJnt->class->code ?? 'N/A',
                'section' => $activity->classGroupJnt->section->code ?? 'N/A',
                'weekly_periods' => $activity->weekly_periods,
                'duration_periods' => $activity->duration_periods,
                'teachers' => count($activity->activityTeachers ?? []),
            ];
        }

        // Test generation
        $constraintManager = new ConstraintManager();
        $constraintManager->addConstraint(new \Modules\SmartTimetable\Services\Constraints\Hard\BreakConstraint([
            'breaks' => ['SBREAK', 'LUNCH']
        ]));

        $generator = new ImprovedTimetableGenerator($days, $periods, $constraintManager);
        $entries = $generator->generate($activities);

        // Analyze placement
        $periodUsage = [];
        foreach ($periods as $period) {
            $periodUsage[$period->id] = [
                'code' => $period->code,
                'count' => 0,
                'is_break' => in_array($period->code, ['SBREAK', 'LUNCH']),
            ];
        }

        foreach ($entries as $entry) {
            $periodUsage[$entry['period_id']]['count']++;
        }

        // Check which periods have placements
        $teachingPeriodsPlaced = 0;
        $breakPeriodsPlaced = 0;

        foreach ($periodUsage as $id => $data) {
            if ($data['is_break']) {
                $breakPeriodsPlaced += $data['count'];
            } else {
                $teachingPeriodsPlaced += $data['count'];
            }
        }

        // Check per-class placement
        $classPlacement = [];
        foreach ($activities as $activity) {
            $classKey = $activity->classGroupJnt->class->code . '-' . $activity->classGroupJnt->section->code;
            if (!isset($classPlacement[$classKey])) {
                $classPlacement[$classKey] = [
                    'needed' => 0,
                    'placed' => 0,
                    'activities' => [],
                ];
            }
            $classPlacement[$classKey]['needed'] += $activity->weekly_periods;

            // Count placed periods for this activity
            $placed = count(array_filter($entries, fn($e) => $e['activity_id'] == $activity->id));
            $classPlacement[$classKey]['placed'] += $placed;
            $classPlacement[$classKey]['activities'][] = [
                'id' => $activity->id,
                'needed' => $activity->weekly_periods,
                'placed' => $placed,
            ];
        }

        return response()->json([
            'success' => true,
            'capacity_analysis' => [
                'total_activities' => $activities->count(),
                'total_periods_needed' => $totalPeriodsNeeded,
                'total_teaching_slots' => $totalTeachingSlots,
                'days' => $days->count(),
                'teaching_periods_per_day' => $teachingPeriods->count(),
                'entries_generated' => count($entries),
                'teaching_periods_placed' => $teachingPeriodsPlaced,
                'break_periods_placed' => $breakPeriodsPlaced,
                'percentage_placed' => $totalPeriodsNeeded > 0 ?
                    round(($teachingPeriodsPlaced / $totalPeriodsNeeded) * 100, 2) . '%' : 'N/A',
            ],
            'period_usage' => $periodUsage,
            'class_placement' => $classPlacement,
            'activity_details' => $activityDetails,
            'stats' => $generator->getStats(),
        ]);
    }

    public function debugPeriods()
    {
        $periods = $this->loadPeriodSet();

        $analysis = [];
        foreach ($periods as $index => $period) {
            $analysis[] = [
                'index' => $index,
                'id' => $period->id,
                'code' => $period->code,
                'period_ord' => $period->period_ord,
                'is_break' => in_array($period->code, ['SBREAK', 'LUNCH']),
            ];
        }

        return response()->json([
            'success' => true,
            'periods' => $analysis,
            'total_periods' => $periods->count(),
            'teaching_periods' => $periods->whereNotIn('code', ['SBREAK', 'LUNCH'])->count(),
            'break_periods' => $periods->whereIn('code', ['SBREAK', 'LUNCH'])->count(),
        ]);
    }

    public function diagnoseLunchProblem()
    {
        set_time_limit(60);

        try {
            // Load data
            $activities = $this->loadActivitiesForActiveClassSections();
            $days = $this->loadSchoolDays();
            $periods = $this->loadPeriodSet();

            // Test 1: NO constraints
            $manager1 = new ConstraintManager();
            $generator1 = new ImprovedTimetableGenerator($days, $periods, $manager1);
            $entries1 = $generator1->generate($activities);

            // Test 2: Only BREAK constraint
            $manager2 = new ConstraintManager();
            $manager2->addConstraint(new \Modules\SmartTimetable\Services\Constraints\Hard\BreakConstraint(['SBREAK']));
            $generator2 = new ImprovedTimetableGenerator($days, $periods, $manager2);
            $entries2 = $generator2->generate($activities);

            // Test 3: BREAK + LUNCH constraints
            $manager3 = new ConstraintManager();
            $manager3->addConstraint(new \Modules\SmartTimetable\Services\Constraints\Hard\BreakConstraint(['SBREAK', 'LUNCH']));
            $generator3 = new ImprovedTimetableGenerator($days, $periods, $manager3);
            $entries3 = $generator3->generate($activities);

            // Analyze period usage
            $periodAnalysis = [];
            $periodIds = $periods->pluck('id')->toArray();

            foreach ([$entries1, $entries2, $entries3] as $index => $entries) {
                $periodUsage = array_fill_keys($periodIds, 0);

                foreach ($entries as $entry) {
                    $periodUsage[$entry['period_id']]++;
                }

                // Get period details
                $details = [];
                foreach ($periods as $period) {
                    $details[] = [
                        'period_id' => $period->id,
                        'code' => $period->code,
                        'period_ord' => $period->period_ord,
                        'usage' => $periodUsage[$period->id],
                        'is_lunch' => $period->code === 'LUNCH' ? 'YES' : 'NO',
                        'is_break' => $period->code === 'SBREAK' ? 'YES' : 'NO',
                    ];
                }

                $periodAnalysis[$index] = [
                    'constraints' => $index === 0 ? 'NONE' : ($index === 1 ? 'BREAK ONLY' : 'BREAK + LUNCH'),
                    'total_entries' => count($entries),
                    'period_usage' => $details,
                ];
            }

            // Check if lunch period is being attempted
            $lunchPeriod = $periods->where('code', 'LUNCH')->first();
            $lunchAttempts = 0;

            // Simulate what the generator might be trying
            foreach ($activities as $activity) {
                foreach ($days as $day) {
                    // Check if lunch period would be tried
                    $slot = new \stdClass();
                    $slot->startIndex = 6; // Lunch is at index 6
                    $slot->dayId = $day->id;

                    // This is what the constraint checks
                    $period = $periods->values()->get(6);
                    if ($period && $period->code === 'LUNCH') {
                        $lunchAttempts++;
                    }
                }
            }

            return response()->json([
                'success' => true,
                'capacity_summary' => [
                    'activities' => $activities->count(),
                    'periods_needed' => $activities->sum('weekly_periods'),
                    'available_slots' => 48,
                    'balance' => 'PERFECT MATCH',
                ],
                'test_results' => $periodAnalysis,
                'lunch_analysis' => [
                    'lunch_period_id' => $lunchPeriod->id ?? 'N/A',
                    'lunch_period_index' => 6,
                    'total_possible_lunch_slots' => $days->count(), // One per day
                    'estimated_lunch_attempts' => $lunchAttempts,
                    'problem' => 'If generator tries lunch period, constraint will block it',
                ],
                'recommendation' => 'Check if generator is trying to place activities during lunch period',
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage(),
            ], 500);
        }
    }


    public function debugActivityDurations()
    {
        $activities = $this->loadActivitiesForActiveClassSections();

        $analysis = [
            'total_activities' => $activities->count(),
            'duration_distribution' => [],
            'weekly_periods_distribution' => [],
            'activities_with_duration_gt_1' => [],
        ];

        foreach ($activities as $activity) {
            $duration = $activity->duration_periods;
            $weekly = $activity->weekly_periods;

            // Count by duration
            if (!isset($analysis['duration_distribution'][$duration])) {
                $analysis['duration_distribution'][$duration] = 0;
            }
            $analysis['duration_distribution'][$duration]++;

            // Count by weekly periods
            if (!isset($analysis['weekly_periods_distribution'][$weekly])) {
                $analysis['weekly_periods_distribution'][$weekly] = 0;
            }
            $analysis['weekly_periods_distribution'][$weekly]++;

            // Track activities with duration > 1
            if ($duration > 1) {
                $analysis['activities_with_duration_gt_1'][] = [
                    'id' => $activity->id,
                    'duration' => $duration,
                    'weekly_periods' => $weekly,
                    'class' => $activity->classGroupJnt->class->code ?? 'N/A',
                    'section' => $activity->classGroupJnt->section->code ?? 'N/A',
                ];
            }
        }

        // Load periods to calculate capacity
        $periods = PeriodSetPeriod::orderBy('period_ord')->get();
        $teachingPeriods = $periods->whereNotIn('code', ['SBREAK', 'LUNCH'])->count();

        return response()->json([
            'success' => true,
            'analysis' => $analysis,
            'capacity_info' => [
                'total_teaching_periods_per_day' => $teachingPeriods,
                'total_days' => 6, // Assuming 5 days
                'total_teaching_slots' => $teachingPeriods * 6,
                'total_periods_needed' => $activities->sum('weekly_periods'),
                'lunch_period_index' => 6,
                'break_period_index' => 3,
            ],
            'critical_info' => [
                'has_activities_duration_gt_1' => !empty($analysis['activities_with_duration_gt_1']),
                'count_duration_gt_1' => count($analysis['activities_with_duration_gt_1']),
            ],
        ]);
    }

    public function timetableConfig()
    {
        return "CONTROLLER --> SmartTimetableController // FUNCTION --> timetableConfig()";
    }

    public function timetableOperation()
    {
        $constraintTypes = ConstraintType::all();
        $constraints = Constraint::paginate(10);
        $academicSession = AcademicSession::current()->firstOrFail();

        $requirements = ClassGroupRequirement::where('academic_session_id', $academicSession->id)
            ->with([
                'classGroupJnt',
                'classSubgroup',
                'academicSession'
            ])
            ->orderBy('priority', 'desc')
            ->get();

        // Separate class group and subgroup requirements
        $classGroupRequirements = $requirements->filter(fn($req) => $req->targetsClassGroup());
        $subgroupRequirements = $requirements->filter(fn($req) => $req->targetsClassSubgroup());
        $subjectGroups = SubjectGroup::with('subjectGroupSubjects')->paginate(10);
        $activities = Activity::with([
            'classGroupJnt.class',
            'classGroupJnt.section',
            'classSubgroup.class',
            'classSubgroup.section',
            'preferredRoomType',
        ])->get();

        $groupedActivities = $activities
            ->groupBy(function ($activity) {

                // ---- CLASS GROUP ACTIVITY ----
                if ($activity->targetsClassGroup() && $activity->classGroupJnt) {
                    return 'C-' .
                        $activity->classGroupJnt->class_id . '-' .
                        ($activity->classGroupJnt->section_id ?? 'NA');
                }

                // ---- CLASS SUBGROUP ACTIVITY ----
                if ($activity->targetsSubgroup() && $activity->classSubgroup) {
                    return 'C-' .
                        $activity->classSubgroup->class_id . '-' .
                        ($activity->classSubgroup->section_id ?? 'NA');
                }

                return 'UNKNOWN';
            })
            ->map(function ($group) {

                $first = $group->first();

                // Resolve class + section safely
                if ($first->targetsClassGroup()) {
                    $class = $first->classGroupJnt->class ?? null;
                    $section = $first->classGroupJnt->section ?? null;
                } else {
                    $class = $first->classSubgroup->class ?? null;
                    $section = $first->classSubgroup->section ?? null;
                }

                return [
                    'class_label' => $class?->name ?? 'Unknown',
                    'section' => $section?->name,
                    'activities' => $group,
                ];
            })
            ->values();

        $academicSession = AcademicSession::current()->first();
        // Separate groups and subgroups


        $rooms = Room::with(['building', 'roomType'])->paginate(10);
        return view('smarttimetable::smart-timetable.operation', compact(
            'constraints',
            'constraintTypes',
            'classGroupRequirements',
            'subgroupRequirements',
            'groupedActivities',
            'subjectGroups'
        ));
    }
    public function timetableMaster(): mixed
    {
        $schoolDays = SchoolDay::all();
        $shifts = Shift::all();
        $dayTypes = DayType::all();
        $workingDays = WorkingDay::all();
        $academicSession = AcademicSession::current()->firstOrFail();
        $periodTypes = PeriodType::all();
        $periodSets = PeriodSet::all();
        $teachersUnavailable = TeacherUnavailable::paginate(10);
        $classSubgroups = ClassSubgroup::paginate(10);
        $roomsUnavailable = RoomUnavailable::paginate(10);
        $assignmentRoles = TeacherAssignmentRole::paginate(10);
        $timetableTypes = TimetableType::paginate(10);
        $timetables = Timetable::paginate(10);
        $periodSetPeriods = PeriodSet::paginate(10);
        $teachers = Teacher::withCount([
            'activityAssignments as activity_assignments_count',
            'timetableCellAssignments as timetable_cell_assignments_count',
        ])
            ->with([
                'user',
                'activityAssignments.activity.classGroupJnt.subjectStudyFormat.subject',
                'activityAssignments.activity.classGroupJnt.subjectStudyFormat.studyFormat',
                'timetableCellAssignments'
            ])
            ->paginate(10);

        $optimalWorkloadCount = 0;
        $highWorkloadCount = 0;
        $overloadedCount = 0;

        foreach ($teachers as $teacher) {
            $assigned = $teacher->timetable_cell_assignments_count;
            $max = $teacher->max_periods_per_week ?? 36;
            $percent = $max > 0 ? round(($assigned / $max) * 100) : 0;

            if ($percent >= 100)
                $overloadedCount++;
            elseif ($percent >= 80)
                $highWorkloadCount++;
            elseif ($percent >= 50)
                $optimalWorkloadCount++;
        }

        // Load subjects for filter
        $subjects = Subject::orderBy('name')->get();
        $rooms = Room::with(['building', 'roomType'])->paginate(10);

        $classGroupsJnt = ClassGroupJnt::paginate(10);

        return view('smarttimetable::smart-timetable.master', compact(
            'timetableTypes',
            'assignmentRoles',
            'roomsUnavailable',
            'classSubgroups',
            'teachersUnavailable',
            'schoolDays',
            'shifts',
            'dayTypes',
            'workingDays',
            'periodTypes',
            'academicSession',
            'periodSets',
            'periodSetPeriods',
            'teachers',
            'rooms',
            'optimalWorkloadCount',
            'highWorkloadCount',
            'overloadedCount',
            'subjects',
            'classGroupsJnt'
        ));
    }
    public function timetableGeneration()
    {
        $timetables = Timetable::paginate(10);
        return view('smarttimetable::smart-timetable.generation', compact(
            'timetables',
        ));
    }
    public function timetableReports()
    {
        $timetables = Timetable::paginate(10);
        return view('smarttimetable::smart-timetable.reports', compact(
            'timetables',
        ));
    }

    public function generateWithFET(Request $request)
    {
        try {

            // collect all pieces of the puzzles

            // load active class 7 sections. 
            $classSections = $this->loadClassSections();

            // load all session.
            $academicSessions = AcademicSession::get();

            // load timetable type.
            $timetableTypes = TimetableType::where('is_active', true)->get();

            // load period-sets.
            $periodSets = PeriodSet::where('is_active', true)->get();

            // load current academic session
            $academicSession = AcademicSession::current()->firstOrFail();

            // load activities for active class + sections only.
            $activities = $this->loadActivitiesForActiveClassSections();

            // load school days i.e the days on which school is open.
            $days = $this->loadSchoolDays();

            // load the default period set.
            $periods = $this->loadPeriodSet();

            // initialize the constraint service
            $constraintService = new DatabaseConstraintService();

            //dd($constraintService);

            // load constraint manager with all the applied constraints after proper validation.

            $constraintManager = $constraintService->loadConstraintsForGeneration(
                $academicSession->id,
                [
                    'academic_session_id' => $academicSession->id,
                    'total_classes' => $classSections->count(),
                    'total_activities' => $activities->count(),
                ]
            );

            // Log constraint summary
            $hardCount = count($constraintManager->getHardConstraints());
            $softCount = count($constraintManager->getSoftConstraints());

            \Log::info('FET Solver: Loading constraints', [
                'hard_constraints' => $hardCount,
                'soft_constraints' => $softCount,
                'constraint_types' => collect($constraintManager->getConstraints())
                    ->map(fn($c) => class_basename($c))
                    ->values()
                    ->toArray(),
            ]);

            // Initialize the Solvers with $days & Peridos
            $solver = new FETSolver($days, $periods, $constraintManager);

            // Run generation
            $entries = $solver->solve($activities);

            \Log::info('FET generation completed', [
                'entries_generated' => count($entries),
            ]);

            $activitiesById = $activities->keyBy('id');
            $schoolGrid = [];
            $conflicts = [];

            foreach ($entries as $entry) {

                $activity = $activitiesById[$entry['activity_id']] ?? null;
                if (!$activity) {
                    continue;
                }

                if ($activity->class_group_jnt_id && $activity->classGroupJnt) {
                    // CLASS GROUP activity
                    $classKey =
                        $activity->classGroupJnt->class->code . '-' .
                        $activity->classGroupJnt->section->code;
                } elseif ($activity->class_subgroup_id && $activity->classSubgroup) {
                    // CLASS SUBGROUP activity
                    $classKey =
                        $activity->classSubgroup->class->code . '-' .
                        $activity->classSubgroup->section->code;
                } else {
                    \Log::warning('Activity without valid target', [
                        'activity_id' => $activity->id,
                    ]);
                    continue;
                }

                if (isset($schoolGrid[$classKey][$entry['day_id']][$entry['period_id']])) {
                    $conflicts[] = [
                        'class' => $classKey,
                        'day_id' => $entry['day_id'],
                        'period_id' => $entry['period_id'],
                        'existing_activity_id' => $schoolGrid[$classKey][$entry['day_id']][$entry['period_id']],
                        'new_activity_id' => $entry['activity_id'],
                    ];
                    continue;
                }

                $schoolGrid[$classKey][$entry['day_id']][$entry['period_id']] = $entry['activity_id'];
            }



            $stats = $solver->getStats();

            // Get additional data for session

            // store the generate timetable to the session which later can be store to DB and then load the preview of latest generated timetable.
            session([
                // Existing session data
                'generated_timetable_grid' => $schoolGrid,
                'generated_activities' => $activitiesById,
                'generated_days' => $days,
                'generated_periods' => $periods,
                'generated_class_sections' => $classSections,
                'generated_conflicts' => $conflicts,

                // 🆕 Generation Run metadata
                'generation_run_meta' => [
                    'algorithm_version' => 'FET-v1.0.0',
                    'algorithm_name' => 'FET (Constraint-based with Backtracking)',
                    'started_at' => $stats['started_at'] ?? now()->subSeconds($stats['generation_time'] ?? 0),
                    'finished_at' => now(),
                    'params' => [
                        'algorithm' => 'FET',
                        'days_count' => $days->count(),
                        'periods_per_day' => $periods->count(),
                        'max_iterations' => 10000,
                        'max_backtracks' => 1000,
                    ],
                ],

                // 🆕 Generation Run results
                'generation_run_stats' => [
                    'activities_total' => $stats['activities'] ?? $activitiesById->count(),
                    'activities_placed' => $stats['periods_placed'] ?? 0,
                    'activities_failed' => max(0, ($stats['activities'] ?? 0) - ($stats['activities_fully_placed'] ?? 0)),
                    'hard_violations' => count($conflicts),
                    'soft_violations' => 0,
                    'soft_score' => null,
                    'stats_json' => $stats,
                ],
            ]);

            return view('smarttimetable::preview.index', [
                'days' => $days,
                'periods' => $periods,
                'schoolGrid' => $schoolGrid,
                'activitiesById' => $activitiesById,
                'classSections' => $classSections,
                'total_entries_generated' => count($entries),
                'slots_filled' => collect($schoolGrid)->flatten(2)->count(),
                'conflicts_detected' => count($conflicts),
                'conflicts' => $conflicts,
                'academicSessions' => $academicSessions,
                'timetableTypes' => $timetableTypes,
                'periodSets' => $periodSets,
                'algorithm_stats' => $stats,
                'algorithm_name' => 'FET (Advanced Algorithm)',
            ]);

        } catch (\Exception $e) {
            \Log::error('FET Generation with Preview Error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'request' => $request->all(),
            ]);

            return back()
                ->with('error', 'FET Generation failed: ' . $e->getMessage())
                ->withInput();
        }
    }

    /**
     * Save generated timetable to database (from preview)
     */
    public function saveGeneratedTimetable(Request $request)
    {
        try {
            // Retrieve from session (SAME AS YOUR CURRENT CODE)
            $grid = session('generated_timetable_grid', []);
            $activities = session('generated_activities', collect());
            $days = session('generated_days', collect());
            $periods = session('generated_periods', collect());
            $academicSessionId = $request->input('academic_session_id');

            if (empty($grid)) {
                return back()->with('error', 'No generated timetable found in session.');
            }

            // Clear existing entries
            \Modules\SmartTimetable\Models\TimetableEntry::where('academic_session_id', $academicSessionId)->delete();

            $savedCount = 0;

            foreach ($grid as $classKey => $daysData) {
                foreach ($daysData as $dayId => $periodsData) {
                    foreach ($periodsData as $periodId => $activityId) {
                        $activity = $activities[$activityId] ?? null;
                        if (!$activity) {
                            continue;
                        }

                        // Determine class_group_jnt_id
                        $classGroupJntId = null;
                        if ($activity->class_group_jnt_id) {
                            $classGroupJntId = $activity->class_group_jnt_id;
                        } elseif ($activity->class_subgroup_id) {
                            $classGroupJntId = $activity->classSubgroup->class_group_jnt_id ?? null;
                        }

                        try {
                            \Modules\SmartTimetable\Models\TimetableEntry::create([
                                'academic_session_id' => $academicSessionId,
                                'day_id' => $dayId,
                                'period_id' => $periodId,
                                'activity_id' => $activityId,
                                'class_group_jnt_id' => $classGroupJntId,
                                'created_at' => now(),
                                'updated_at' => now(),
                            ]);
                            $savedCount++;
                        } catch (\Exception $e) {
                            \Log::warning('Failed to save timetable entry', [
                                'error' => $e->getMessage(),
                                'entry' => compact('dayId', 'periodId', 'activityId'),
                            ]);
                        }
                    }
                }
            }

            // Clear session data
            session()->forget([
                'generated_timetable_grid',
                'generated_activities',
                'generated_days',
                'generated_periods',
                'generated_class_sections',
                'generated_conflicts',
                'generation_run_meta',
                'generation_run_stats',
            ]);

            return redirect()
                ->route('smart-timetable-management.index')
                ->with('success', "Timetable saved successfully! {$savedCount} entries saved.");

        } catch (\Exception $e) {
            \Log::error('Save timetable error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return back()->with('error', 'Failed to save timetable: ' . $e->getMessage());
        }
    }

    //Load DB constraints
}
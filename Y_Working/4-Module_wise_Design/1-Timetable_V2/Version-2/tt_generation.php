// Migration Scripts Creation

<?php
// database/migrations/2024_01_01_000001_create_timetable_module.php

class CreateTimetableModule extends Migration
{
    public function up()
    {
        // Create all tables from the provided DDL
        Schema::create('tt_institution_profile', function (Blueprint $table) {
            $table->id();
            $table->foreignId('institution_id')->constrained('institutions')->onDelete('cascade');
            $table->uuid('uuid')->unique();
            // ... other columns
            $table->timestamps();
            $table->softDeletes();
            
            $table->index(['institution_id', 'profile_type']);
            $table->index(['is_active']);
        });
        
        // Continue with all 45+ tables...
    }
    
    public function down()
    {
        // Reverse migration in correct order
        Schema::dropIfExists('tt_timetable_cell_teacher');
        Schema::dropIfExists('tt_timetable_cell');
        // ... drop in reverse dependency order
    }
}


// -----------------------------------------------------------------
// Seeder Classes for Test Data
// -----------------------------------------------------------------

<?php
// database/seeders/TimetableTestDataSeeder.php

class TimetableTestDataSeeder extends Seeder
{
    public function run()
    {
        // 1. Create test institution
        $institution = Institution::create([
            'name' => 'Test Academic Institution',
            'code' => 'TAI001',
            // ... other fields
        ]);
        
        // 2. Create 50 test teachers with varying expertise
        $teachers = Teacher::factory()->count(50)->create();
        
        // 3. Create subject expertise for teachers
        $teachers->each(function ($teacher) {
            $subjects = Subject::inRandomOrder()->take(rand(2, 5))->get();
            $subjects->each(function ($subject) use ($teacher) {
                TtTeacherSubjectExpertise::create([
                    'teacher_id' => $teacher->id,
                    'subject_id' => $subject->id,
                    'class_level_range' => rand(1, 5) . '-' . rand(6, 12),
                    'proficiency_level' => Arr::random(['BEGINNER', 'INTERMEDIATE', 'EXPERT']),
                    'is_primary_subject' => rand(0, 1),
                ]);
            });
        });
        
        // 4. Create complex constraints for testing
        $this->createTestConstraints();
        
        // 5. Create activities with varying difficulty
        $this->createTestActivities();
    }
    
    private function createTestConstraints()
    {
        // Hard constraints
        TtConstraint::create([
            'constraint_type_id' => 1, // TEACHER_NOT_AVAILABLE
            'name' => 'Math Teacher Unavailable Monday Morning',
            'target_type' => 'TEACHER',
            'target_id' => Teacher::whereHas('subjects', fn($q) => $q->where('code', 'MATH'))->first()->id,
            'is_hard' => true,
            'weight' => 100,
            'params_json' => json_encode([
                'days' => [1], // Monday
                'periods' => [1, 2, 3], // First three periods
            ]),
        ]);
        
        // Soft constraints
        TtConstraint::create([
            'constraint_type_id' => 10, // AVOID_FREE_FIRST_PERIOD
            'name' => 'Avoid Free First Period for Teachers',
            'target_type' => 'GLOBAL',
            'is_hard' => false,
            'weight' => 70,
            'params_json' => json_encode([]),
        ]);
    }
}

// -----------------------------------------------------------------
// Repository Pattern Implementation
// -----------------------------------------------------------------

<?php
// app/Repositories/TimetableRepository.php

namespace App\Repositories;

use App\Models\TtTimetable;
use App\Contracts\Repositories\TimetableRepositoryInterface;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Pagination\LengthAwarePaginator;

class TimetableRepository implements TimetableRepositoryInterface
{
    public function __construct(
        private TtTimetable $model,
        private CacheRepository $cache
    ) {}
    
    public function findWithRelations(int $id, array $relations = []): ?TtTimetable
    {
        $cacheKey = "timetable:{$id}:" . implode(',', $relations);
        
        return $this->cache->remember($cacheKey, 3600, function () use ($id, $relations) {
            return $this->model->with($relations)->find($id);
        });
    }
    
    public function getByAcademicSession(int $sessionId, array $filters = []): Collection
    {
        $query = $this->model->where('academic_session_id', $sessionId);
        
        if (!empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }
        
        if (!empty($filters['type_id'])) {
            $query->where('timetable_type_id', $filters['type_id']);
        }
        
        return $query->orderBy('effective_from', 'desc')->get();
    }
    
    public function getTeacherTimetable(int $teacherId, int $sessionId): array
    {
        return $this->cache->remember("teacher_timetable:{$teacherId}:{$sessionId}", 1800, function () use ($teacherId, $sessionId) {
            $cells = TtTimetableCell::whereHas('teachers', function ($query) use ($teacherId) {
                    $query->where('teacher_id', $teacherId);
                })
                ->whereHas('timetable', function ($query) use ($sessionId) {
                    $query->where('academic_session_id', $sessionId)
                        ->where('status', 'PUBLISHED');
                })
                ->with(['activity', 'room', 'timetable'])
                ->get()
                ->groupBy(['day_of_week', 'period_ord']);
            
            return $this->formatTeacherSchedule($cells);
        });
    }
    
    public function createTimetable(array $data): TtTimetable
    {
        $timetable = $this->model->create($data);
        
        // Clear relevant cache
        $this->cache->tags(['timetables', "session:{$data['academic_session_id']}"])->flush();
        
        event(new TimetableCreated($timetable));
        
        return $timetable;
    }
}

// -----------------------------------------------------------------
// Data Validation Layer
// -----------------------------------------------------------------

<?php
// app/Validators/TimetableValidator.php

namespace App\Validators;

use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

class TimetableValidator
{
    public static function validateTimetableCreation(array $data): array
    {
        $validator = Validator::make($data, [
            'academic_session_id' => 'required|exists:sch_org_academic_sessions_jnt,id',
            'timetable_type_id' => 'required|exists:tt_timetable_type,id',
            'period_set_id' => 'required|exists:tt_period_set,id',
            'effective_from' => 'required|date|after_or_equal:today',
            'effective_to' => 'required|date|after:effective_from',
            'name' => 'required|string|max:200',
            'code' => 'required|string|max:50|unique:tt_timetable,code',
            'generation_method' => ['required', Rule::in(['MANUAL', 'SEMI_AUTO', 'FULL_AUTO'])],
        ], [
            'effective_to.after' => 'End date must be after start date',
            'code.unique' => 'Timetable code must be unique',
        ]);
        
        if ($validator->fails()) {
            throw new ValidationException($validator);
        }
        
        return $validator->validated();
    }
    
    public static function validateConstraint(array $data): array
    {
        $constraintType = TtConstraintType::findOrFail($data['constraint_type_id']);
        
        $validator = Validator::make($data, [
            'constraint_type_id' => 'required|exists:tt_constraint_type,id',
            'target_type' => ['required', Rule::in(['GLOBAL', 'TEACHER', 'STUDENT_SET', 'ROOM', 'ACTIVITY', 'CLASS', 'SUBJECT'])],
            'target_id' => 'required_if:target_type,!=,GLOBAL|exists:' . self::getTargetTable($data['target_type']) . ',id',
            'is_hard' => 'boolean',
            'weight' => 'required|integer|min:0|max:100',
            'params_json' => 'required|json',
            'effective_from' => 'nullable|date',
            'effective_to' => 'nullable|date|after_or_equal:effective_from',
        ]);
        
        // Validate params against constraint type schema
        if (isset($data['params_json'])) {
            $params = json_decode($data['params_json'], true);
            self::validateConstraintParams($constraintType, $params);
        }
        
        return $validator->validated();
    }
    
    private static function validateConstraintParams(TtConstraintType $type, array $params): void
    {
        $schema = json_decode($type->param_schema, true);
        
        // Implement JSON Schema validation
        foreach ($schema['required'] ?? [] as $requiredField) {
            if (!array_key_exists($requiredField, $params)) {
                throw new ValidationException("Missing required parameter: {$requiredField}");
            }
        }
        
        // Validate each parameter
        foreach ($schema['properties'] ?? [] as $property => $rules) {
            if (isset($params[$property])) {
                self::validateParam($property, $params[$property], $rules);
            }
        }
    }
}

// ===================================================================
// 2: Core Algorithm Implementation
// ===================================================================

// -----------------------------------------------------------------
// Constraint Definition Module
// -----------------------------------------------------------------

<?php
// app/Services/Timetable/Constraints/ConstraintManager.php

namespace App\Services\Timetable\Constraints;

use App\Models\TtConstraint;
use App\Models\TtActivity;
use Illuminate\Support\Collection;

class ConstraintManager
{
    private Collection $hardConstraints;
    private Collection $softConstraints;
    private array $constraintGraph = [];
    
    public function __construct(
        private ConstraintParser $parser,
        private ConstraintValidator $validator
    ) {
        $this->hardConstraints = collect();
        $this->softConstraints = collect();
    }
    
    public function loadConstraints(int $academicSessionId, ?int $timetableTypeId = null): void
    {
        $query = TtConstraint::with(['constraintType', 'target'])
            ->where('academic_session_id', $academicSessionId)
            ->where('status', 'ACTIVE')
            ->where('is_active', true);
            
        if ($timetableTypeId) {
            $query->where('timetable_type_id', $timetableTypeId);
        }
        
        $constraints = $query->get();
        
        foreach ($constraints as $constraint) {
            if ($constraint->is_hard) {
                $this->hardConstraints->push($constraint);
            } else {
                $this->softConstraints->push($constraint);
            }
            
            // Build constraint graph for fast lookup
            $this->addToConstraintGraph($constraint);
        }
    }
    
    public function getConflictingActivities(TtActivity $activity): array
    {
        $conflicts = [];
        
        // Check against all constraints
        foreach ($this->hardConstraints as $constraint) {
            if ($this->isActivityAffected($activity, $constraint)) {
                $conflictingActivities = $this->getActivitiesForConstraint($constraint);
                $conflicts = array_merge($conflicts, $conflictingActivities);
            }
        }
        
        return array_unique($conflicts);
    }
    
    public function evaluatePlacement(TtActivity $activity, int $day, int $period, ?int $roomId = null): array
    {
        $violations = [];
        $penalty = 0;
        
        // Check hard constraints
        foreach ($this->hardConstraints as $constraint) {
            if ($this->violatesConstraint($activity, $day, $period, $roomId, $constraint)) {
                $violations[] = [
                    'type' => 'HARD',
                    'constraint' => $constraint->name,
                    'message' => $this->getViolationMessage($constraint),
                ];
            }
        }
        
        // Check soft constraints
        foreach ($this->softConstraints as $constraint) {
            if ($this->violatesConstraint($activity, $day, $period, $roomId, $constraint)) {
                $penalty += $constraint->weight;
                $violations[] = [
                    'type' => 'SOFT',
                    'constraint' => $constraint->name,
                    'weight' => $constraint->weight,
                    'message' => $this->getViolationMessage($constraint),
                ];
            }
        }
        
        return [
            'can_place' => empty(array_filter($violations, fn($v) => $v['type'] === 'HARD')),
            'violations' => $violations,
            'penalty_score' => $penalty,
        ];
    }
    
    public function getTimeSlotAvailability(int $day, int $period, array $filters = []): array
    {
        $availableTeachers = $this->getAvailableTeachers($day, $period, $filters);
        $availableRooms = $this->getAvailableRooms($day, $period, $filters);
        $availableClasses = $this->getAvailableClasses($day, $period, $filters);
        
        return [
            'teachers' => $availableTeachers,
            'rooms' => $availableRooms,
            'classes' => $availableClasses,
            'slot_score' => $this->calculateSlotScore($day, $period),
        ];
    }
    
    private function calculateSlotScore(int $day, int $period): float
    {
        // Calculate how "good" this timeslot is
        // Factors: proximity to breaks, teacher preferences, historical usage
        $score = 1.0;
        
        // Penalize first period on Monday
        if ($day === 1 && $period === 1) {
            $score *= 0.8;
        }
        
        // Reward post-lunch periods for certain activities
        if ($period >= 5) {
            $score *= 1.1;
        }
        
        return $score;
    }
}

// -----------------------------------------------------------------
// Algorithm Selection & Implementation
// -----------------------------------------------------------------

<?php
// app/Services/Timetable/Algorithms/AlgorithmFactory.php

namespace App\Services\Timetable\Algorithms;

use App\Services\Timetable\Algorithms\GeneticAlgorithm;
use App\Services\Timetable\Algorithms\SimulatedAnnealing;
use App\Services\Timetable\Algorithms\ConstraintSatisfaction;
use App\Services\Timetable\Algorithms\HybridAlgorithm;
use App\Models\TtGenerationStrategy;

class AlgorithmFactory
{
    public static function create(string $algorithmType, array $config = []): TimetableAlgorithmInterface
    {
        return match($algorithmType) {
            'GENETIC' => new GeneticAlgorithm($config),
            'ANNEALING' => new SimulatedAnnealing($config),
            'CSP' => new ConstraintSatisfaction($config),
            'HYBRID' => new HybridAlgorithm($config),
            'FET_RECURSIVE' => new FetRecursiveAlgorithm($config),
            default => throw new \InvalidArgumentException("Unknown algorithm type: {$algorithmType}"),
        };
    }
    
    public static function getOptimalAlgorithm(int $activityCount, int $constraintCount): string
    {
        $complexity = $activityCount * $constraintCount;
        
        if ($complexity < 1000) {
            return 'CSP'; // Constraint Satisfaction for small problems
        } elseif ($complexity < 10000) {
            return 'GENETIC'; // Genetic for medium problems
        } elseif ($complexity < 100000) {
            return 'HYBRID'; // Hybrid for large problems
        } else {
            return 'FET_RECURSIVE'; // FET algorithm for very large problems
        }
    }
    
    public static function createFromStrategy(TtGenerationStrategy $strategy): TimetableAlgorithmInterface
    {
        $config = json_decode($strategy->parameters_json, true);
        $config['strategy_id'] = $strategy->id;
        
        return self::create($strategy->algorithm_type, $config);
    }
}

// -----------------------------------------------------------------
// Optimization Engine
// -----------------------------------------------------------------

<?php
// app/Services/Timetable/Algorithms/HybridAlgorithm.php

namespace App\Services\Timetable\Algorithms;

use App\Models\TtTimetable;
use App\Services\Timetable\Solution;
use Illuminate\Support\Collection;

class HybridAlgorithm implements TimetableAlgorithmInterface
{
    private GeneticAlgorithm $genetic;
    private SimulatedAnnealing $annealing;
    private LocalSearch $localSearch;
    private ConstraintManager $constraints;
    private array $config;
    
    public function __construct(array $config = [])
    {
        $this->config = array_merge([
            'population_size' => 100,
            'generations' => 500,
            'crossover_rate' => 0.8,
            'mutation_rate' => 0.1,
            'cooling_rate' => 0.95,
            'initial_temperature' => 1000,
            'local_search_iterations' => 1000,
            'timeout_seconds' => 300,
        ], $config);
        
        $this->genetic = new GeneticAlgorithm($this->config);
        $this->annealing = new SimulatedAnnealing($this->config);
        $this->localSearch = new LocalSearch($this->config);
        $this->constraints = app(ConstraintManager::class);
    }
    
    public function generate(array $activities, array $constraints): Solution
    {
        $startTime = microtime(true);
        
        // PHASE 1: Pre-processing
        $this->constraints->loadConstraints($constraints['academic_session_id']);
        $prioritizedActivities = $this->prioritizeActivities($activities);
        
        // PHASE 2: Genetic Algorithm for initial population
        $this->log("Starting Genetic Algorithm phase...");
        $population = $this->genetic->initializePopulation($prioritizedActivities);
        
        for ($generation = 0; $generation < $this->config['generations']; $generation++) {
            if ($this->isTimeout($startTime)) {
                $this->log("Timeout reached at generation {$generation}");
                break;
            }
            
            $population = $this->genetic->evolve($population);
            $bestSolution = $this->genetic->getBestSolution($population);
            
            if ($bestSolution->getFitness() >= 0.95) {
                $this->log("High fitness reached at generation {$generation}");
                break;
            }
        }
        
        // PHASE 3: Simulated Annealing for optimization
        $this->log("Starting Simulated Annealing phase...");
        $optimizedSolution = $this->annealing->optimize($bestSolution);
        
        // PHASE 4: Local Search for fine-tuning
        $this->log("Starting Local Search phase...");
        $finalSolution = $this->localSearch->improve($optimizedSolution);
        
        // PHASE 5: Post-processing and validation
        $finalSolution = $this->resolveRemainingConflicts($finalSolution);
        $finalSolution->calculateStatistics();
        
        $executionTime = microtime(true) - $startTime;
        $this->log("Generation completed in {$executionTime} seconds");
        
        return $finalSolution;
    }
    
    public function optimize(Solution $solution): Solution
    {
        // Optimization of existing timetable
        $this->log("Starting optimization of existing solution...");
        
        // 1. Identify problematic areas
        $problemAreas = $this->identifyProblemAreas($solution);
        
        // 2. Apply targeted optimization
        foreach ($problemAreas as $area) {
            $solution = $this->optimizeArea($solution, $area);
        }
        
        // 3. Global optimization
        $solution = $this->annealing->optimize($solution);
        
        // 4. Final local search
        $solution = $this->localSearch->improve($solution);
        
        return $solution;
    }
    
    private function prioritizeActivities(array $activities): array
    {
        // Sort activities by difficulty to schedule (FET approach)
        usort($activities, function ($a, $b) {
            $scoreA = $this->calculateActivityDifficulty($a);
            $scoreB = $this->calculateActivityDifficulty($b);
            
            return $scoreB <=> $scoreA; // Descending order
        });
        
        return $activities;
    }
    
    private function calculateActivityDifficulty($activity): float
    {
        // Based on FET's difficulty calculation
        $difficulty = 0;
        
        // Factor 1: Number of constraints affecting this activity
        $constraintCount = $this->constraints->getConstraintCountForActivity($activity);
        $difficulty += $constraintCount * 10;
        
        // Factor 2: Duration (longer activities are harder to place)
        $difficulty += $activity->duration_periods * 5;
        
        // Factor 3: Teacher availability
        $teacherAvailability = $this->calculateTeacherAvailabilityScore($activity);
        $difficulty += (1 - $teacherAvailability) * 20;
        
        // Factor 4: Room requirements
        if ($activity->requires_special_room) {
            $difficulty += 15;
        }
        
        return $difficulty;
    }
    
    private function identifyProblemAreas(Solution $solution): array
    {
        $problemAreas = [];
        
        // Find teachers with high gap counts
        foreach ($solution->getTeacherSchedules() as $teacherId => $schedule) {
            $gapCount = $this->countGaps($schedule);
            if ($gapCount > 3) {
                $problemAreas[] = [
                    'type' => 'TEACHER_GAPS',
                    'teacher_id' => $teacherId,
                    'score' => $gapCount,
                ];
            }
        }
        
        // Find rooms with low utilization
        foreach ($solution->getRoomUtilization() as $roomId => $utilization) {
            if ($utilization < 0.3) {
                $problemAreas[] = [
                    'type' => 'ROOM_UNDERUTILIZATION',
                    'room_id' => $roomId,
                    'score' => 1 - $utilization,
                ];
            }
        }
        
        // Find constraint violations
        $violations = $solution->getViolations();
        foreach ($violations as $violation) {
            if ($violation['weight'] > 50) {
                $problemAreas[] = [
                    'type' => 'CONSTRAINT_VIOLATION',
                    'constraint_id' => $violation['constraint_id'],
                    'score' => $violation['weight'],
                ];
            }
        }
        
        // Sort by problem severity
        usort($problemAreas, fn($a, $b) => $b['score'] <=> $a['score']);
        
        return array_slice($problemAreas, 0, 10); // Top 10 problems
    }
}

// -----------------------------------------------------------------
// Conflict Resolution System
// -----------------------------------------------------------------

 <?php
// app/Services/Timetable/ConflictResolver.php

namespace App\Services\Timetable;

use App\Models\TtTimetableCell;
use App\Models\TtConstraintViolation;
use App\Services\Timetable\Algorithms\LocalSearch;
use Illuminate\Support\Collection;

class ConflictResolver
{
    private array $resolutionStrategies = [];
    
    public function __construct(
        private LocalSearch $localSearch,
        private ConstraintManager $constraints
    ) {
        $this->initializeStrategies();
    }
    
    public function resolveConflicts(Collection $cells, array $conflicts): array
    {
        $resolutions = [];
        $remainingConflicts = [];
        
        foreach ($conflicts as $conflict) {
            $resolution = $this->resolveConflict($cells, $conflict);
            
            if ($resolution['resolved']) {
                $resolutions[] = $resolution;
                $cells = $resolution['updated_cells'];
            } else {
                $remainingConflicts[] = $conflict;
            }
        }
        
        return [
            'resolutions' => $resolutions,
            'remaining_conflicts' => $remainingConflicts,
            'final_cells' => $cells,
            'resolution_rate' => count($resolutions) / max(1, count($conflicts)),
        ];
    }
    
    private function resolveConflict(Collection $cells, array $conflict): array
    {
        $strategy = $this->getResolutionStrategy($conflict['type']);
        
        try {
            return $strategy->resolve($cells, $conflict);
        } catch (\Exception $e) {
            return [
                'resolved' => false,
                'conflict' => $conflict,
                'error' => $e->getMessage(),
                'suggestions' => $this->getAlternativeSuggestions($conflict),
            ];
        }
    }
    
    private function getResolutionStrategy(string $conflictType): ConflictResolutionStrategy
    {
        return $this->resolutionStrategies[$conflictType] 
            ?? $this->resolutionStrategies['default'];
    }
    
    private function initializeStrategies(): void
    {
        $this->resolutionStrategies = [
            'TEACHER_OVERLAP' => new TeacherOverlapResolution(),
            'ROOM_OVERLAP' => new RoomOverlapResolution(),
            'STUDENT_OVERLAP' => new StudentOverlapResolution(),
            'CAPACITY_EXCEEDED' => new CapacityResolution(),
            'CONSTRAINT_VIOLATION' => new ConstraintViolationResolution($this->constraints),
            'default' => new DefaultResolution($this->localSearch),
        ];
    }
    
    public function suggestSwaps(Collection $cells, int $problemCellId): array
    {
        $problemCell = $cells->firstWhere('id', $problemCellId);
        
        if (!$problemCell) {
            return [];
        }
        
        $suggestions = [];
        
        // Find possible swaps within







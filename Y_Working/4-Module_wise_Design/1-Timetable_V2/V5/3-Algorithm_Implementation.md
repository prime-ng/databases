# Algorithm Selection Strategy
------------------------------

## F1: ALGORITHM COMPARISON MATRIX
|Algorithm	                   |Best For	                                 |Time Complexity         |Memory Usage|Success Rate | Implementation Complexity
|------------------------------|---------------------------------------------|------------------------|------------|-------------|---------------------------
|Recursive Backtracking	       |Small to medium timetables (<500 activities) | O(n!) worst, O(n²) avg | Low        |    85%      | Low
|Constraint Satisfaction (CSP) |Complex constraint-heavy schedules	         | O(d^n)                 | Medium     |    92%      | Medium
|Genetic Algorithm	           |Large timetables, optimization	             | O(g*p*n)               | High       |    88%      | High
|Simulated Annealing	       |Near-optimal solutions	                     | O(n * iterations)      | Medium     |    90%      | Medium
|Tabu Search	               |Escaping local optima	                     | O(n² * iterations)     | High       |    89%      | High
|Hybrid Approach	           |Enterprise-scale (>1000 activities)	         | Variable               | High       |    95%      | Very High

### F4: ALGORITHM SELECTION GUIDELINES

| Scenario	                                                | Recommended Algorithm	                  |Configuration                                              |
|-----------------------------------------------------------|-----------------------------------------|-----------------------------------------------------------|
| Small school (<500 activities, simple constraints)	    | Recursive Backtracking	              |maxDepth=10, maxAttempts=1000                              |
| Medium school (500-1000 activities, moderate constraints)	| Hybrid: Recursive + Simulated Annealing |recursionDepth=14, initialTemp=100, coolingRate=0.95       |
| Large school (1000-2000 activities, complex constraints)	| Hybrid: Genetic + Tabu Search	          |population=100, generations=200, mutation=0.1, tabuSize=200|
| Very large school (>2000 activities, very complex)	    | Distributed Genetic Algorithm	          |population=500, generations=500, parallel=true             |
| Exam timetable	                                        | Constraint Satisfaction + Tabu    	  |hardConstraints only                                       |
| Substitution finding	                                    | Rule-based + ML scoring	              |historical data weight=0.3                                 |


### F5: ALGORITHM CONFIGURATION EXAMPLES

```yaml
# Recursive Backtracking
algorithm: recursive
maxDepth: 10
maxAttempts: 1000

# Hybrid: Recursive + Simulated Annealing
algorithm: hybrid
recursionDepth: 14
initialTemp: 100
coolingRate: 0.95

# Hybrid: Genetic + Tabu Search
algorithm: hybrid
genetic.population: 100
genetic.generations: 200
genetic.mutation: 0.1
tabu.tabuSize: 200

# Distributed Genetic Algorithm
algorithm: distributed
genetic.population: 500
genetic.generations: 500
genetic.parallel: true

# Constraint Satisfaction + Tabu
algorithm: constraint
hardConstraintsOnly: true

# Rule-based + ML scoring
algorithm: rule-based
historicalDataWeight: 0.3
```

-------------------------------------------------------------------------------------------------------------------------------------------


## F2: PHASED ALGORITHM IMPLEMENTATION
### PHASE 6.1: INITIAL PLACEMENT - RECURSIVE BACKTRACKING WITH FORWARD CHECKING
```php
class RecursivePlacementAlgorithm {
    private $activities;
    private $timeSlots;
    private $assignments = [];
    private $conflicts = [];
    private $maxDepth = 14;
    private $currentDepth = 0;
    
    public function execute($activities, $timeSlots) {
        // Sort by difficulty (hardest first)
        $sortedActivities = $activities->sortByDesc('difficulty_score');
        
        foreach ($sortedActivities as $activity) {
            $placed = $this->placeActivity($activity);
            if (!$placed) {
                $this->conflicts[] = $activity;
            }
        }
        
        return [
            'assignments' => $this->assignments,
            'conflicts' => $this->conflicts,
            'success_rate' => (count($activities) - count($this->conflicts)) / count($activities) * 100
        ];
    }
    
    private function placeActivity($activity, $depth = 0) {
        if ($depth > $this->maxDepth) {
            return false;
        }
        
        $this->currentDepth = $depth;
        
        // Get available slots considering constraints
        $availableSlots = $this->findAvailableSlots($activity);
        
        // Sort slots by preference
        $scoredSlots = $this->scoreSlots($availableSlots, $activity);
        
        foreach ($scoredSlots as $slot) {
            // Try placing here
            $this->assignments[$activity->id] = $slot;
            
            // Forward checking - check if this causes future conflicts
            if ($this->forwardCheck($activity, $slot)) {
                return true;
            }
            
            // If conflict, backtrack and try next slot
            unset($this->assignments[$activity->id]);
        }
        
        // Try swapping with already placed activities
        return $this->trySwapping($activity, $depth);
    }
    
    private function trySwapping($activity, $depth) {
        foreach ($this->assignments as $placedId => $placedSlot) {
            $placedActivity = Activity::find($placedId);
            
            // Check if swap is possible
            if ($this->canSwap($activity, $placedActivity, $placedSlot)) {
                // Temporarily remove placed activity
                unset($this->assignments[$placedId]);
                
                // Try to place the current activity
                if ($this->placeActivity($activity, $depth + 1)) {
                    // Now try to re-place the swapped activity
                    if ($this->placeActivity($placedActivity, $depth + 1)) {
                        return true;
                    }
                }
                
                // Swap failed, restore
                $this->assignments[$placedId] = $placedSlot;
            }
        }
        
        return false;
    }
    
    private function forwardCheck($newActivity, $newSlot) {
        $affectedActivities = $this->getAffectedActivities($newActivity, $newSlot);
        
        foreach ($affectedActivities as $activity) {
            if (!isset($this->assignments[$activity->id])) {
                $futureAvailable = $this->findAvailableSlots($activity);
                if (empty($futureAvailable)) {
                    return false; // Future activity would have no slots
                }
            }
        }
        
        return true;
    }
}
```

### PHASE 6.2: OPTIMIZATION - SIMULATED ANNEALING
```php
class SimulatedAnnealingOptimizer {
    private $initialTemperature = 100.0;
    private $coolingRate = 0.95;
    private $minTemperature = 1.0;
    private $iterationsPerTemp = 100;
    
    public function optimize($timetable, $currentScore) {
        $currentSolution = $timetable;
        $bestSolution = $timetable;
        $bestScore = $currentScore;
        
        $temperature = $this->initialTemperature;
        
        while ($temperature > $this->minTemperature) {
            for ($i = 0; $i < $this->iterationsPerTemp; $i++) {
                // Generate neighbor solution
                $neighbor = $this->generateNeighbor($currentSolution);
                $neighborScore = $this->evaluateSolution($neighbor);
                
                // Calculate acceptance probability
                $delta = $neighborScore - $currentScore;
                
                if ($delta > 0) {
                    // Better solution - accept
                    $currentSolution = $neighbor;
                    $currentScore = $neighborScore;
                    
                    if ($neighborScore > $bestScore) {
                        $bestSolution = $neighbor;
                        $bestScore = $neighborScore;
                    }
                } else {
                    // Worse solution - accept with probability
                    $probability = exp($delta / $temperature);
                    if (mt_rand() / mt_getrandmax() < $probability) {
                        $currentSolution = $neighbor;
                        $currentScore = $neighborScore;
                    }
                }
            }
            
            // Cool down
            $temperature *= $this->coolingRate;
        }
        
        return [
            'solution' => $bestSolution,
            'score' => $bestScore,
            'iterations' => $this->iterationsPerTemp * log($this->minTemperature / $this->initialTemperature, $this->coolingRate)
        ];
    }
    
    private function generateNeighbor($solution) {
        // Randomly select two cells and swap
        $cell1 = $this->selectRandomCell($solution);
        $cell2 = $this->selectRandomCell($solution);
        
        // Check if swap is valid
        if ($this->isValidSwap($cell1, $cell2)) {
            $neighbor = clone $solution;
            $this->swapCells($neighbor, $cell1, $cell2);
            return $neighbor;
        }
        
        return $solution; // Return original if swap invalid
    }
    
    private function evaluateSolution($solution) {
        $score = 0;
        
        // Hard constraints (must be satisfied)
        $hardViolations = $this->countHardViolations($solution);
        if ($hardViolations > 0) {
            return -1000 * $hardViolations; // Heavy penalty
        }
        
        // Soft constraints (weighted)
        foreach ($this->softConstraints as $constraint) {
            $score += $this->evaluateConstraint($solution, $constraint) * $constraint->weight;
        }
        
        return $score;
    }
}
```

### PHASE 6.3: CONFLICT RESOLUTION - TABU SEARCH
```php
class TabuSearchResolver {
    private $tabuList = [];
    private $tabuSize = 100;
    private $maxIterations = 1000;
    private $aspirationCriteria = true;
    
    public function resolve($conflicts, $currentSolution) {
        $bestSolution = $currentSolution;
        $bestScore = $this->evaluateSolution($currentSolution);
        $currentSolution = $currentSolution;
        $iteration = 0;
        
        while ($iteration < $this->maxIterations && !empty($conflicts)) {
            $neighborhood = $this->generateNeighborhood($currentSolution, $conflicts);
            $bestNeighbor = null;
            $bestNeighborScore = PHP_INT_MIN;
            
            foreach ($neighborhood as $neighbor) {
                $moveHash = $this->hashMove($neighbor);
                
                // Check if move is tabu
                if (in_array($moveHash, $this->tabuList) && !$this->aspirationCriteria) {
                    continue;
                }
                
                $score = $this->evaluateSolution($neighbor);
                
                if ($score > $bestNeighborScore) {
                    $bestNeighbor = $neighbor;
                    $bestNeighborScore = $score;
                    $bestMoveHash = $moveHash;
                }
            }
            
            if ($bestNeighbor) {
                $currentSolution = $bestNeighbor;
                $this->addToTabuList($bestMoveHash);
                
                if ($bestNeighborScore > $bestScore) {
                    $bestSolution = $bestNeighbor;
                    $bestScore = $bestNeighborScore;
                }
            }
            
            $conflicts = $this->identifyConflicts($currentSolution);
            $iteration++;
        }
        
        return [
            'solution' => $bestSolution,
            'resolved_conflicts' => count($conflicts) == 0,
            'remaining_conflicts' => $conflicts
        ];
    }
    
    private function generateNeighborhood($solution, $conflicts) {
        $neighbors = [];
        
        foreach ($conflicts as $conflict) {
            // Try different placements for conflicting activity
            $activity = $conflict['activity'];
            $currentSlot = $conflict['slot'];
            
            $alternativeSlots = $this->findAlternativeSlots($activity, $currentSlot);
            
            foreach ($alternativeSlots as $slot) {
                $neighbor = clone $solution;
                $this->moveActivity($neighbor, $activity, $slot);
                $neighbors[] = $neighbor;
            }
        }
        
        return $neighbors;
    }
}
```

### PHASE 6.4: HYBRID APPROACH FOR ENTERPRISE SCALE
```php
class HybridTimetableGenerator {
    private $strategies = [
        'recursive' => RecursivePlacementAlgorithm::class,
        'annealing' => SimulatedAnnealingOptimizer::class,
        'tabu' => TabuSearchResolver::class,
        'genetic' => GeneticAlgorithmOptimizer::class
    ];
    
    public function generate($activities, $constraints, $options = []) {
        $result = [
            'assignments' => [],
            'conflicts' => [],
            'metrics' => []
        ];
        
        // PHASE 1: Initial placement using recursive CSP
        $recursive = new $this->strategies['recursive']();
        $placement = $recursive->execute($activities);
        
        $result['assignments'] = $placement['assignments'];
        $result['metrics']['initial_placement'] = [
            'placed' => count($placement['assignments']),
            'conflicts' => count($placement['conflicts']),
            'success_rate' => $placement['success_rate']
        ];
        
        // If conflicts exist, try resolution
        if (!empty($placement['conflicts'])) {
            // PHASE 2: Conflict resolution using Tabu Search
            $tabu = new $this->strategies['tabu']();
            $resolution = $tabu->resolve($placement['conflicts'], $placement['assignments']);
            
            $result['assignments'] = $resolution['solution'];
            $result['conflicts'] = $resolution['remaining_conflicts'];
            $result['metrics']['conflict_resolution'] = [
                'resolved' => $resolution['resolved_conflicts'],
                'remaining' => count($resolution['remaining_conflicts'])
            ];
        }
        
        // PHASE 3: Optimization using Simulated Annealing
        $currentScore = $this->evaluateSolution($result['assignments']);
        $annealing = new $this->strategies['annealing']();
        $optimized = $annealing->optimize($result['assignments'], $currentScore);
        
        $result['assignments'] = $optimized['solution'];
        $result['metrics']['optimization'] = [
            'initial_score' => $currentScore,
            'final_score' => $optimized['score'],
            'improvement' => (($optimized['score'] - $currentScore) / $currentScore) * 100
        ];
        
        // PHASE 4: If still complex, use Genetic Algorithm for global optimization
        if ($this->needsGlobalOptimization($result)) {
            $genetic = new $this->strategies['genetic']();
            $global = $genetic->evolve($result['assignments']);
            
            $result['assignments'] = $global['population'][0]; // Best individual
            $result['metrics']['global_optimization'] = $global['metrics'];
        }
        
        return $result;
    }
    
    private function needsGlobalOptimization($result) {
        return $result['metrics']['optimization']['improvement'] < 5 && 
               count($result['conflicts']) > 0;
    }
}
```


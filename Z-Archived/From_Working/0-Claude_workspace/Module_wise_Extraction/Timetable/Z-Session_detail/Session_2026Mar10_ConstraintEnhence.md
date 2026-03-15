 The Step 2 sub-tasks document is ready at:
  2-Tenant_Modules/8-Smart_Timetable/Claude_Context/2026Mar10_Step2_ActivityConstraints_SubTasks.md

  Remaining Step 1 tasks (cleanup):
  - Task 3: Fix B3 — violatesNoConsecutiveRule() multi-period bug (same fix as sub-task 2.1)
  - Task 4–6: Delete backup file, archived services, duplicate views
  - Task 7: Remove ~550 lines of dead debug methods from SmartTimetableController
  - Task 8: Fix broken generateForClassSection route

  Step 2 sub-tasks ready to implement (in order):
  - 2.1: Fix violatesNoConsecutiveRule() — B3 bug (FETSolver line 637)
  - 2.2: allow_consecutive per-activity override in isBasicSlotAvailable()
  - 2.3: max_per_day override via resolveMaxPerDay() helper
  - 2.4: New violatesMinGapRule() method
  - 2.5: New scoreSlotForActivity() method
  - 2.6: Integrate scoring into getPossibleSlots() sort
  - 2.7: Auto-populate difficulty_score_calculated in ActivityController

  Which task do you want to tackle next?

✻ Churned for 4m 39s

❯ Now Start Implementing Sub-Tasks from "2-Tenant_Modules/8-Smart_Timetable/Claude_Context/2026Mar10_Step2_ActivityConstraints_SubTasks.md". Start work on ## Sub-Task 2.1.                          
  ⎿  ⧉ Selected 1 lines from 2-Tenant_Modules/8-Smart_Timetable/Claude_Context/2026Mar10_Step2_ActivityConstraints_SubTasks.md in Visual Studio Code

⏺ Read 2 files (ctrl+o to expand)

⏺ Now I have both the plan and the exact current code. The fix moves $currentOriginalActivityId before the duration > 1 check and replaces the early return with proper adjacency checks.

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php)
  ⎿  Added 32 lines, removed 3 lines
      633  
      634      private function violatesNoConsecutiveRule($activity, Slot $slot, int $duration, string $classKey, $context): bool
      635      {
      636 -        // Any multi-period block for same activity is inherently consecutive.                                                                                                     
      636 +        $currentOriginalActivityId = (string) ($activity->original_activity_id ?? $activity->id ?? '');                                                                            
      637 +                                                                                                                                                                                   
      638          if ($duration > 1) {
      638 -            return true;                                                                                                                                                           
      639 +            // A multi-period block (e.g. Lab = periods 3+4) is one intended unit — NOT a violation.                                                                               
      640 +            // Only flag it if ANOTHER instance of the same activity sits directly adjacent                                                                                        
      641 +            // to the block's start or end on the same day.                                                                                                                        
      642 +            $blockStart = $slot->startIndex;                                                                                                                                       
      643 +            $blockEnd   = $blockStart + $duration - 1;                                                                                                                             
      644 +                                                                                                                                                                                   
      645 +            // Check the period immediately before the block                                                                                                                       
      646 +            if ($blockStart > 0) {                                                                                                                                                 
      647 +                $prevPeriodId = $this->periods[$blockStart - 1]->id ?? null;                                                                                                       
      648 +                if ($prevPeriodId && isset($context->occupied[$classKey][$slot->dayId][$prevPeriodId])) {                                                                          
      649 +                    $prevToken = $context->occupied[$classKey][$slot->dayId][$prevPeriodId];                                                                                       
      650 +                    if ($this->extractOriginalActivityIdFromToken($prevToken) === $currentOriginalActivityId) {                                                                    
      651 +                        return true;                                                                                                                                               
      652 +                    }                                                                                                                                                              
      653 +                }                                                                                                                                                                  
      654 +            }                                                                                                                                                                      
      655 +                                                                                                                                                                                   
      656 +            // Check the period immediately after the block                                                                                                                        
      657 +            $afterEnd = $blockEnd + 1;                                                                                                                                             
      658 +            if ($afterEnd < $this->periods->count()) {                                                                                                                             
      659 +                $nextPeriodId = $this->periods[$afterEnd]->id ?? null;                                                                                                             
      660 +                if ($nextPeriodId && isset($context->occupied[$classKey][$slot->dayId][$nextPeriodId])) {                                                                          
      661 +                    $nextToken = $context->occupied[$classKey][$slot->dayId][$nextPeriodId];                                                                                       
      662 +                    if ($this->extractOriginalActivityIdFromToken($nextToken) === $currentOriginalActivityId) {                                                                    
      663 +                        return true;                                                                                                                                               
      664 +                    }                                                                                                                                                              
      665 +                }                                                                                                                                                                  
      666 +            }                                                                                                                                                                      
      667 +                                                                                                                                                                                   
      668 +            return false; // Multi-period block with no adjacent same-activity instance is fine                                                                                    
      669          }
      670  
      671          $periodIndex = $slot->startIndex;
      642 -        $currentOriginalActivityId = (string) ($activity->original_activity_id ?? $activity->id ?? '');                                                                            
      672  
      673          // Previous slot on same day
      674          if ($periodIndex > 0) {

⏺ Now verify the edit looks correct in context:

⏺ Read 1 file (ctrl+o to expand)

⏺ Sub-Task 2.1 is done. Here's what changed and why it matters:

  Before: if ($duration > 1) { return true; } — every Lab/Practical/Hobby activity (duration ≥ 2) was always blocked from the backtracking and greedy passes. They could only land in the
  rescue/forced pass where constraint quality is degraded.

  After: Multi-period blocks check only whether another instance of the same activity sits directly adjacent to the block (before period blockStart or after period blockEnd). A single 2-period Lab
  block occupying periods 3+4 is correctly treated as one intended unit — not a violation.

  Effect: Physics Lab, Computer Lab, Art, Hobby, Robotics, and any duration > 1 activity now compete fairly in the primary backtracking pass alongside single-period subjects, getting best-fit
  placement instead of forced rescue placement.

  Ready to move to Sub-Task 2.2 (allow_consecutive per-activity override in isBasicSlotAvailable())?

✻ Cogitated for 36s

❯ Implement ## Sub-Task 2.2                                                                                                                                                                          
  ⎿  ⧉ Selected 1 lines from 2-Tenant_Modules/8-Smart_Timetable/Claude_Context/2026Mar10_Step2_ActivityConstraints_SubTasks.md in Visual Studio Code

⏺ Searched for 1 pattern, read 1 file (ctrl+o to expand)

⏺ Now let me find the exact current code for isBasicSlotAvailable():

⏺ Searched for 1 pattern (ctrl+o to expand)

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php)
  ⎿  Added 8 lines, removed 1 line
      489              return false;
      490          }
      491  
      492 -        if (!$ignoreConsecutive && $this->disallowConsecutivePeriods && $this->violatesNoConsecutiveRule($activity, $slot, $duration, $classKey, $context)) {                      
      492 +        $activityAllowsConsecutive = (bool) ($activity->allow_consecutive ?? false);                                                                                               
      493 +                                                                                                                                                                                   
      494 +        if (                                                                                                                                                                       
      495 +            !$ignoreConsecutive                                                                                                                                                    
      496 +            && $this->disallowConsecutivePeriods                                                                                                                                   
      497 +            && !$activityAllowsConsecutive                                                                                                                                         
      498 +            && $this->violatesNoConsecutiveRule($activity, $slot, $duration, $classKey, $context)                                                                                  
      499 +        ) {                                                                                                                                                                        
      500              return false;
      501          }
      502  

⏺ Verify in context:

⏺ Read 1 file (ctrl+o to expand)

⏺ Sub-Task 2.2 done.

  What changed: Added $activityAllowsConsecutive check as a 3rd guard in the consecutive-rule condition. The full gate now reads:
  - !$ignoreConsecutive — pass-level override still works
  - && $this->disallowConsecutivePeriods — global config still respected
  - && !$activityAllowsConsecutive — new: skip the check if this specific activity permits back-to-back
  - && $this->violatesNoConsecutiveRule(...) — only call the method when all three flags clear

  Behaviour: An activity with allow_consecutive = true in the DB now bypasses the consecutive check completely, while every other activity still obeys the global $disallowConsecutivePeriods flag.
  No existing behaviour changes.

  Ready for Sub-Task 2.3 (max_per_day override via resolveMaxPerDay() helper)?

❯ Implement ## Sub-Task 2.3                                                                                                                                                                          
  ⎿  ⧉ Selected 1 lines from 2-Tenant_Modules/8-Smart_Timetable/Claude_Context/2026Mar10_Step2_ActivityConstraints_SubTasks.md in Visual Studio Code

⏺ Searched for 1 pattern, read 1 file (ctrl+o to expand)

⏺ Now I have all three targets. I'll make all three edits: add resolveMaxPerDay(), simplify violatesDailyActivityPlacementCap(), and simplify getMaxPlacementsPerDay().

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php)
  ⎿  Added 17 lines, removed 4 lines
      627          return null;
      628      }
      629  
      630 -    private function getMaxPlacementsPerDay($activity): int                                                                                                                        
      630 +    private function resolveMaxPerDay($activity): int                                                                                                                              
      631      {
      632 +        // Respect explicit activity-level cap if set                                                                                                                              
      633 +        $activityCap = isset($activity->max_per_day) ? (int) $activity->max_per_day : null;                                                                                        
      634 +        if ($activityCap !== null && $activityCap > 0) {                                                                                                                           
      635 +            return $activityCap;                                                                                                                                                   
      636 +        }                                                                                                                                                                          
      637 +                                                                                                                                                                                   
      638 +        // Fallback: dynamic formula based on weekly demand                                                                                                                        
      639          $daysCount = max(1, $this->days->count());
      640          $requiredWeeklyPeriods = (int) ($activity->required_weekly_periods ?? 0);
      634 -        $maxPerDay = max(1, (int) ceil($requiredWeeklyPeriods / $daysCount));                                                                                                      
      641 +                                                                                                                                                                                   
      642          if ($requiredWeeklyPeriods <= $daysCount) {
      636 -            $maxPerDay = 1;                                                                                                                                                        
      643 +            return 1;                                                                                                                                                              
      644          }
      638 -        return $maxPerDay;                                                                                                                                                         
      645 +                                                                                                                                                                                   
      646 +        return max(1, (int) ceil($requiredWeeklyPeriods / $daysCount));                                                                                                            
      647      }
      648  
      649 +    private function getMaxPlacementsPerDay($activity): int                                                                                                                        
      650 +    {                                                                                                                                                                              
      651 +        return $this->resolveMaxPerDay($activity);                                                                                                                                 
      652 +    }                                                                                                                                                                              
      653 +                                                                                                                                                                                   
      654      private function violatesNoConsecutiveRule($activity, Slot $slot, int $duration, string $classKey, $context): bool
      655      {
      656          $currentOriginalActivityId = (string) ($activity->original_activity_id ?? $activity->id ?? '');

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php)
  ⎿  Added 1 line, removed 8 lines
      727  
      728      private function violatesDailyActivityPlacementCap($activity, Slot $slot, string $classKey, $context): bool
      729      {
      730 -        $daysCount = max(1, $this->days->count());                                                                                                                                 
      731 -        $requiredWeeklyPeriods = (int) ($activity->required_weekly_periods ?? 0);                                                                                                  
      730          $currentDayCount = $this->getDailyPlacementCountForActivity($activity, $classKey, $slot->dayId, $context);
      731 +        $maxPerDay = $this->resolveMaxPerDay($activity);                                                                                                                           
      732  
      734 -        // Example: 9 periods / 6 days => 2 max for a day.                                                                                                                         
      735 -        $maxPerDay = max(1, (int) ceil($requiredWeeklyPeriods / $daysCount));                                                                                                      
      736 -        if ($requiredWeeklyPeriods <= $daysCount) {                                                                                                                                
      737 -            $maxPerDay = 1;                                                                                                                                                        
      738 -        }                                                                                                                                                                          
      739 -                                                                                                                                                                                   
      733          return $currentDayCount >= $maxPerDay;
      734      }
      735  

⏺ Verify the final state of all three methods:

⏺ Read 1 file (ctrl+o to expand)

⏺ Sub-Task 2.3 done. Three changes made:

  1. resolveMaxPerDay() (new helper, line 630): Checks activity->max_per_day first — if set and > 0, returns it directly. Otherwise falls through to the formula ceil(weeklyPeriods / daysCount).
  2. getMaxPlacementsPerDay() (line 649): Now a one-liner that delegates to resolveMaxPerDay(). No logic duplication.
  3. violatesDailyActivityPlacementCap() (line 728): Drops the duplicated formula block, now just calls resolveMaxPerDay(). The existing caller at line 583 that uses getMaxPlacementsPerDay() for
  the debug message also benefits automatically.

  Effect: If a school sets max_per_day = 1 on Maths (9 periods/week, formula would give 2), the solver now hard-caps it at 1 placement per day. Activities without max_per_day set behave exactly as
  before.

  Ready for Sub-Task 2.4 (violatesMinGapRule() + integration into isBasicSlotAvailable())?

✻ Cooked for 58s

❯ ## Sub-Task 2.4                                                                                                                                                                                    
  ⎿  ⧉ Selected 1 lines from 2-Tenant_Modules/8-Smart_Timetable/Claude_Context/2026Mar10_Step2_ActivityConstraints_SubTasks.md in Visual Studio Code

⏺ Read 1 file (ctrl+o to expand)

⏺ Good, I have the full plan. Now let me find the exact insertion point in isBasicSlotAvailable():

⏺ Read 1 file (ctrl+o to expand)

⏺ Now I have both targets. First, add the violatesMinGapRule() method after violatesNoConsecutiveRule(), then add the call in isBasicSlotAvailable().

⏺ Read 1 file (ctrl+o to expand)

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php)
  ⎿  Added 33 lines
      725          return (string) $token;
      726      }
      727  
      728 +    private function violatesMinGapRule($activity, Slot $slot, int $minGap, string $classKey, $context): bool                                                                      
      729 +    {                                                                                                                                                                              
      730 +        $occupiedForDay = $context->occupied[$classKey][$slot->dayId] ?? [];                                                                                                       
      731 +        $currentActivityId = (string) ($activity->original_activity_id ?? $activity->id ?? '');                                                                                    
      732 +                                                                                                                                                                                   
      733 +        foreach ($occupiedForDay as $periodId => $token) {                                                                                                                         
      734 +            if ($this->extractOriginalActivityIdFromToken($token) !== $currentActivityId) {                                                                                        
      735 +                continue;                                                                                                                                                          
      736 +            }                                                                                                                                                                      
      737 +                                                                                                                                                                                   
      738 +            // Find the period index of the already-placed instance                                                                                                                
      739 +            $occupiedIndex = null;                                                                                                                                                 
      740 +            foreach ($this->periods as $idx => $period) {                                                                                                                          
      741 +                if ($period->id == $periodId) {                                                                                                                                    
      742 +                    $occupiedIndex = $idx;                                                                                                                                         
      743 +                    break;                                                                                                                                                         
      744 +                }                                                                                                                                                                  
      745 +            }                                                                                                                                                                      
      746 +                                                                                                                                                                                   
      747 +            if ($occupiedIndex === null) {                                                                                                                                         
      748 +                continue;                                                                                                                                                          
      749 +            }                                                                                                                                                                      
      750 +                                                                                                                                                                                   
      751 +            // Gap must be strictly greater than minGap to be acceptable                                                                                                           
      752 +            $gap = abs($slot->startIndex - $occupiedIndex);                                                                                                                        
      753 +            if ($gap > 0 && $gap <= $minGap) {                                                                                                                                     
      754 +                return true; // Too close to an existing instance                                                                                                                  
      755 +            }                                                                                                                                                                      
      756 +        }                                                                                                                                                                          
      757 +                                                                                                                                                                                   
      758 +        return false;                                                                                                                                                              
      759 +    }                                                                                                                                                                              
      760 +                                                                                                                                                                                   
      761      private function violatesDailyActivityPlacementCap($activity, Slot $slot, string $classKey, $context): bool
      762      {
      763          $currentDayCount = $this->getDailyPlacementCountForActivity($activity, $classKey, $slot->dayId, $context);

⏺ Now add the call in isBasicSlotAvailable(), right after the consecutive check block:

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php)
  ⎿  Added 8 lines
      500              return false;
      501          }
      502  
      503 +        // Per-activity minimum gap between instances on same day                                                                                                                  
      504 +        $minGap = (int) ($activity->min_gap_periods ?? 0);                                                                                                                         
      505 +        if (!$ignoreConsecutive && $minGap > 0) {                                                                                                                                  
      506 +            if ($this->violatesMinGapRule($activity, $slot, $minGap, $classKey, $context)) {                                                                                       
      507 +                return false;                                                                                                                                                      
      508 +            }                                                                                                                                                                      
      509 +        }                                                                                                                                                                          
      510 +                                                                                                                                                                                   
      511          if (
      512              !$ignoreClassTeacherFirst
      513              && $this->enforceClassTeacherFirstLecture

⏺ Verify both the call site and the new method:

⏺ Read 1 file (ctrl+o to expand)

⏺ Sub-Task 2.4 done. Two changes:

  violatesMinGapRule() (new method, line 736):
  - Iterates all occupied cells for the activity's class on the same day
  - Skips tokens that belong to a different original activity
  - Resolves each placed instance's $occupiedIndex by scanning $this->periods
  - Returns true if the absolute period gap between the candidate slot and any existing instance is > 0 but <= minGap — meaning it's non-adjacent but still too close
  - Returns false if no existing instance violates the gap requirement

  Call site in isBasicSlotAvailable() (lines 503–509):
  - Only fires when $activity->min_gap_periods > 0 (null/0 = no constraint, zero cost)
  - Reuses $ignoreConsecutive flag — rescue/forced passes that relax consecutive checks also relax gap checks automatically

  Effect: An activity with min_gap_periods = 3 will never have two instances placed within 3 periods of each other on the same day. e.g. Maths in period 2 → next Maths instance must be period 6 or
  later.

  Ready for Sub-Task 2.5 (scoreSlotForActivity() method)?

✻ Crunched for 43s

❯ Execute Sub-Task 2.5                                                                                                                                                                               
  ⎿  ⧉ Selected 1 lines from 2-Tenant_Modules/8-Smart_Timetable/Claude_Context/2026Mar10_Step2_ActivityConstraints_SubTasks.md in Visual Studio Code

⏺ Searched for 1 pattern, read 1 file (ctrl+o to expand)

⏺ Now find the exact insertion point — after simulatePlacement():

⏺ Searched for 2 patterns, read 1 file (ctrl+o to expand)

⏺ Insert scoreSlotForActivity() between the end of simulatePlacement() and the getPossibleSlots() docblock:

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php)
  ⎿  Added 67 lines
      913      }
      914  
      915      /**
      916 +     * Score a slot based on activity-level soft preferences.                                                                                                                      
      917 +     * Higher score = better slot for this activity.                                                                                                                               
      918 +     * Returns 0 if no preferences are set on the activity.                                                                                                                        
      919 +     */                                                                                                                                                                            
      920 +    private function scoreSlotForActivity($activity, Slot $slot, $context): int                                                                                                    
      921 +    {                                                                                                                                                                              
      922 +        $score = 0;                                                                                                                                                                
      923 +        $periodIndex = $slot->startIndex;                                                                                                                                          
      924 +        $dayId = $slot->dayId;                                                                                                                                                     
      925 +                                                                                                                                                                                   
      926 +        // Resolve period_ord for this slot index                                                                                                                                  
      927 +        $period = $this->periods[$periodIndex] ?? null;                                                                                                                            
      928 +        if (!$period) {                                                                                                                                                            
      929 +            return 0;                                                                                                                                                              
      930 +        }                                                                                                                                                                          
      931 +        $periodOrd = (int) ($period->period_ord ?? ($periodIndex + 1));                                                                                                            
      932 +                                                                                                                                                                                   
      933 +        // --- preferred_time_slots_json: exact day+period match (+40) ---                                                                                                         
      934 +        $preferredTimeSlots = $activity->preferred_time_slots_json ?? [];                                                                                                          
      935 +        if (!empty($preferredTimeSlots)) {                                                                                                                                         
      936 +            foreach ($preferredTimeSlots as $pref) {                                                                                                                               
      937 +                if (($pref['day_id'] ?? null) == $dayId && ($pref['period_ord'] ?? null) == $periodOrd) {                                                                          
      938 +                    $score += 40;                                                                                                                                                  
      939 +                    break;                                                                                                                                                         
      940 +                }                                                                                                                                                                  
      941 +            }                                                                                                                                                                      
      942 +        }                                                                                                                                                                          
      943 +                                                                                                                                                                                   
      944 +        // --- avoid_time_slots_json: exact day+period match (-50) ---                                                                                                             
      945 +        $avoidTimeSlots = $activity->avoid_time_slots_json ?? [];                                                                                                                  
      946 +        if (!empty($avoidTimeSlots)) {                                                                                                                                             
      947 +            foreach ($avoidTimeSlots as $avoid) {                                                                                                                                  
      948 +                if (($avoid['day_id'] ?? null) == $dayId && ($avoid['period_ord'] ?? null) == $periodOrd) {                                                                        
      949 +                    $score -= 50;                                                                                                                                                  
      950 +                    break;                                                                                                                                                         
      951 +                }                                                                                                                                                                  
      952 +            }                                                                                                                                                                      
      953 +        }                                                                                                                                                                          
      954 +                                                                                                                                                                                   
      955 +        // --- preferred_periods_json: period ordinal match (+20) ---                                                                                                              
      956 +        $preferredPeriods = $activity->preferred_periods_json ?? [];                                                                                                               
      957 +        if (!empty($preferredPeriods) && in_array($periodOrd, $preferredPeriods, true)) {                                                                                          
      958 +            $score += 20;                                                                                                                                                          
      959 +        }                                                                                                                                                                          
      960 +                                                                                                                                                                                   
      961 +        // --- avoid_periods_json: period ordinal match (-30) ---                                                                                                                  
      962 +        $avoidPeriods = $activity->avoid_periods_json ?? [];                                                                                                                       
      963 +        if (!empty($avoidPeriods) && in_array($periodOrd, $avoidPeriods, true)) {                                                                                                  
      964 +            $score -= 30;                                                                                                                                                          
      965 +        }                                                                                                                                                                          
      966 +                                                                                                                                                                                   
      967 +        // --- spread_evenly: reward unused days, penalise already-used days ---                                                                                                   
      968 +        $spreadEvenly = (bool) ($activity->spread_evenly ?? true);                                                                                                                 
      969 +        if ($spreadEvenly) {                                                                                                                                                       
      970 +            $classKey = $slot->classKey;                                                                                                                                           
      971 +            $dailyCount = $this->getDailyPlacementCountForActivity($activity, $classKey, $dayId, $context);                                                                        
      972 +            if ($dailyCount === 0) {                                                                                                                                               
      973 +                $score += 10;                                                                                                                                                      
      974 +            } elseif ($dailyCount >= 1) {                                                                                                                                          
      975 +                $score -= 15;                                                                                                                                                      
      976 +            }                                                                                                                                                                      
      977 +        }                                                                                                                                                                          
      978 +                                                                                                                                                                                   
      979 +        return $score;                                                                                                                                                             
      980 +    }                                                                                                                                                                              
      981 +                                                                                                                                                                                   
      982 +    /**                                                                                                                                                                            
      983       * Get all possible slots for an activity instance
      984       */
      985      /**

⏺ Verify the insertion:

⏺ Read 1 file (ctrl+o to expand)

⏺ Sub-Task 2.5 done. scoreSlotForActivity() is in place at line 920.

  Score breakdown:

  ┌────────────────────────────────────────────────────────┬────────┐
  │                       Condition                        │ Points │
  ├────────────────────────────────────────────────────────┼────────┤
  │ Exact day_id + period_ord in preferred_time_slots_json │ +40    │
  ├────────────────────────────────────────────────────────┼────────┤
  │ Exact day_id + period_ord in avoid_time_slots_json     │ -50    │
  ├────────────────────────────────────────────────────────┼────────┤
  │ period_ord in preferred_periods_json                   │ +20    │
  ├────────────────────────────────────────────────────────┼────────┤
  │ period_ord in avoid_periods_json                       │ -30    │
  ├────────────────────────────────────────────────────────┼────────┤
  │ spread_evenly=true + day has 0 placements              │ +10    │
  ├────────────────────────────────────────────────────────┼────────┤
  │ spread_evenly=true + day already has ≥1 placement      │ -15    │
  └────────────────────────────────────────────────────────┴────────┘

  Avoidance beats preference by design (-50 > +40), so an avoid rule always wins a tie against a preference. Activities with no preferences set return 0 with no overhead.

  The method is ready but not yet called — that's Sub-Task 2.6 (integrate into getPossibleSlots() sort). Ready to proceed?

✻ Cooked for 38s

Implement Sub-Task 2.6                                                                                                                                                                             
  ⎿  ⧉ Selected 1 lines from 2-Tenant_Modules/8-Smart_Timetable/Claude_Context/2026Mar10_Step2_ActivityConstraints_SubTasks.md in Visual Studio Code

⏺ Read 2 files (ctrl+o to expand)

⏺ I have the full picture. Two edits needed: add scoring into the usort comparator, and replace the shuffle fallback.

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php)
  ⎿  Added 29 lines, removed 5 lines
      1034                  $preferredPeriodIndex = $this->activityPeriodAffinities[$activity->id] ?? null;
      1035              }
      1036  
      1037 -            usort($slots, function (Slot $a, Slot $b) use ($isClassTeacherActivity, $classHasClassTeacherActivities, $shouldEnforceForThisClass, $preferredPeriodIndex, $activity)
           - {                                                                                                                                                                                
      1038 -                // If pinning is enabled and activity has an affinity, prioritize that period                                                                                     
      1037 +            usort($slots, function (Slot $a, Slot $b) use ($isClassTeacherActivity, $classHasClassTeacherActivities, $shouldEnforceForThisClass, $preferredPeriodIndex, $activity,
           + $context) {                                                                                                                                                                      
      1038 +                // Priority 1: Pinning affinity — structural, highest precedence                                                                                                  
      1039                  if ($this->pinActivitiesByPeriod && $preferredPeriodIndex !== null) {
      1040                      $aMatchesAffinity = ($a->startIndex === $preferredPeriodIndex);
      1041                      $bMatchesAffinity = ($b->startIndex === $preferredPeriodIndex);
     ...
      1045                      }
      1046                  }
      1047  
      1048 +                // Priority 2: Class-teacher first lecture — structural                                                                                                           
      1049                  $aIsFirst = $this->isFirstLectureSlot($a);
      1050                  $bIsFirst = $this->isFirstLectureSlot($b);
      1051  
      1051 -                // Only prioritize first lecture if constraint should be enforced for this class                                                                                  
      1052                  if ($shouldEnforceForThisClass && $aIsFirst !== $bIsFirst) {
      1053                      if ($classHasClassTeacherActivities && $isClassTeacherActivity) {
      1054                          return $aIsFirst ? -1 : 1;
     ...
      1061                      return 0;
      1062                  }
      1063  
      1064 +                // Priority 3: Activity-level soft score — prefer better-matching slots                                                                                           
      1065 +                $scoreA = $this->scoreSlotForActivity($activity, $a, $context);                                                                                                   
      1066 +                $scoreB = $this->scoreSlotForActivity($activity, $b, $context);                                                                                                   
      1067 +                if ($scoreA !== $scoreB) {                                                                                                                                        
      1068 +                    return $scoreB <=> $scoreA; // Higher score first                                                                                                             
      1069 +                }                                                                                                                                                                 
      1070 +                                                                                                                                                                                  
      1071 +                // Priority 4: Day order fallback                                                                                                                                 
      1072                  if ($a->dayId !== $b->dayId) {
      1073                      return $a->dayId <=> $b->dayId;
      1074                  }
     ...
      1076                  return $a->startIndex <=> $b->startIndex;
      1077              });
      1078          } else {
      1071 -            // Keep random behavior when class-teacher-first mode is off.                                                                                                         
      1072 -            shuffle($slots);                                                                                                                                                      
      1079 +            // No structural sort mode — apply preference scoring if activity has any, else shuffle                                                                               
      1080 +            $hasPreferences = !empty($activity->preferred_time_slots_json)                                                                                                        
      1081 +                || !empty($activity->avoid_time_slots_json)                                                                                                                       
      1082 +                || !empty($activity->preferred_periods_json)                                                                                                                      
      1083 +                || !empty($activity->avoid_periods_json);                                                                                                                         
      1084 +                                                                                                                                                                                  
      1085 +            if ($hasPreferences) {                                                                                                                                                
      1086 +                usort($slots, function (Slot $a, Slot $b) use ($activity, $context) {                                                                                             
      1087 +                    $scoreA = $this->scoreSlotForActivity($activity, $a, $context);                                                                                               
      1088 +                    $scoreB = $this->scoreSlotForActivity($activity, $b, $context);                                                                                               
      1089 +                    if ($scoreA !== $scoreB) {                                                                                                                                    
      1090 +                        return $scoreB <=> $scoreA; // Higher score first                                                                                                         
      1091 +                    }                                                                                                                                                             
      1092 +                    return random_int(-1, 1); // Tie-break randomly to avoid bias                                                                                                 
      1093 +                });                                                                                                                                                               
      1094 +            } else {                                                                                                                                                              
      1095 +                shuffle($slots); // No preferences — keep original random behaviour                                                                                               
      1096 +            }                                                                                                                                                                     
      1097          }
      1098  
      1099          return $slots;

⏺ Verify:

⏺ Read 1 file (ctrl+o to expand)

⏺ Sub-Task 2.6 done.

  What changed:

  In the structural usort path (when pinning or class-teacher-first is active):
  - Added $context to the use() capture list
  - Inserted Priority 3 between class-teacher check and day-order fallback — calls scoreSlotForActivity() for both slots, sorts higher score first
  - Priority 1 (pinning) and Priority 2 (class-teacher) are completely unchanged — soft scores can never override them

  In the else / shuffle path (no structural mode active):
  - Checks if the activity has any of the four preference fields set
  - If yes → usort by score descending, random tie-break to avoid alphabetical/insertion bias
  - If no → original shuffle() preserved exactly — zero change for activities with no preferences

  Net effect: The first 5 sub-tasks (2.1–2.5) are now fully wired in. The solver will:
  1. Allow multi-period activities through the primary pass (2.1)
  2. Skip consecutive check for allow_consecutive=true activities (2.2)
  3. Respect max_per_day caps (2.3)
  4. Enforce min_gap_periods spacing (2.4)
  5. Try preferred slots before neutral slots, and neutral before avoided slots (2.5 + 2.6)

  Ready for Sub-Task 2.7 (auto-populate difficulty_score_calculated and constraint_count in ActivityController)?

✻ Worked for 46s

❯ Execute Sub-Task 2.7                                                                                                                                                                               
  ⎿  ⧉ Selected 1 lines from 2-Tenant_Modules/8-Smart_Timetable/Claude_Context/2026Mar10_Step2_ActivityConstraints_SubTasks.md in Visual Studio Code

⏺ Searched for 3 patterns, read 3 files (ctrl+o to expand)

⏺ Let me read more of generateActivities() to find the Activity::create() calls:

⏺ Read 1 file (ctrl+o to expand)

⏺ generateActivities() already computes and stores both difficulty_score_calculated (lines 211–265) and constraint_count (line 268) — Part A is already done. Only Part B is missing: making
  orderActivitiesByDifficulty() actually use the pre-computed score. Let me fix that:

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php)
  ⎿  Added 6 lines, removed 1 line
      1643          $scoredActivities = [];
      1644  
      1645          foreach ($activities as $activity) {
      1646 -            $score = 0;                                                                                                                                                           
      1646 +            // Seed with pre-calculated difficulty if available (set by ActivityController::generateActivities())                                                                 
      1647 +            $score = (int) ($activity->difficulty_score_calculated ?? 0);                                                                                                         
      1648 +            if ($score === 0) {                                                                                                                                                   
      1649 +                $score = (int) ($activity->difficulty_score ?? 0);                                                                                                                
      1650 +            }                                                                                                                                                                     
      1651 +                                                                                                                                                                                  
      1652              $classKey = $this->getClassKey($activity);
      1653              $hasClassTeacherMapping = isset($this->classTeacherByClassKey[$classKey]);
      1654              $classTeacherHasActivities = $this->classTeacherHasActivitiesByClassKey[$classKey] ?? false;

⏺ Verify:

⏺ Read 1 file (ctrl+o to expand)

⏺ Sub-Task 2.7 done.

  What happened:

  - Part A (ActivityController) — already implemented: generateActivities() already computes difficulty_score_calculated via a weighted formula (40% base difficulty + 30% teacher availability gap +
   20% room availability gap + 10% constraint count) and stores both fields with every updateOrCreate() call. No changes needed there.
  - Part B (FETSolver) — implemented now: orderActivitiesByDifficulty() previously started $score = 0, ignoring the pre-computed value entirely. Now it seeds from difficulty_score_calculated first,
   falls back to difficulty_score, then adds all the existing structural bonuses (+10000 for ≥6 periods, +500×weekly, class-teacher boost, etc.) on top. Activities that carried a high DB-computed
  difficulty score now enter ordering with a head start.

  ---
  Step 2 is fully complete. All 7 sub-tasks implemented:

  ┌──────────┬─────────────────────────────────────────────────────────────────────┬───────────┐
  │ Sub-task │                               Change                                │   File    │
  ├──────────┼─────────────────────────────────────────────────────────────────────┼───────────┤
  │ 2.1      │ Fixed multi-period consecutive bug                                  │ FETSolver │
  ├──────────┼─────────────────────────────────────────────────────────────────────┼───────────┤
  │ 2.2      │ allow_consecutive per-activity override                             │ FETSolver │
  ├──────────┼─────────────────────────────────────────────────────────────────────┼───────────┤
  │ 2.3      │ max_per_day via resolveMaxPerDay() helper                           │ FETSolver │
  ├──────────┼─────────────────────────────────────────────────────────────────────┼───────────┤
  │ 2.4      │ violatesMinGapRule() + call in isBasicSlotAvailable()               │ FETSolver │
  ├──────────┼─────────────────────────────────────────────────────────────────────┼───────────┤
  │ 2.5      │ scoreSlotForActivity() method                                       │ FETSolver │
  ├──────────┼─────────────────────────────────────────────────────────────────────┼───────────┤
  │ 2.6      │ Scoring integrated into getPossibleSlots() sort                     │ FETSolver │
  ├──────────┼─────────────────────────────────────────────────────────────────────┼───────────┤
  │ 2.7      │ difficulty_score_calculated seeded in orderActivitiesByDifficulty() │ FETSolver │
  └──────────┴─────────────────────────────────────────────────────────────────────┴───────────┘

  Ready to move to the remaining Step 1 cleanup tasks (delete dead code, backup files, debug methods)?

  ❯ Now Start Implementing "2-Tenant_Modules/8-Smart_Timetable/Claude_Context/2026Mar10_GapAnalysis_and_CompletionPlan.md". Start with all the Tasks under "### STEP 3: Generation Performance &           
Reliability"                                                                                                                                                                                             
  ⎿  ⧉ Selected 1 lines from 2-Tenant_Modules/8-Smart_Timetable/Claude_Context/2026Mar10_GapAnalysis_and_CompletionPlan.md in Visual Studio Code



⏺ Searched for 1 pattern, read 1 file (ctrl+o to expand)

⏺ 7 tasks. Let me read all the relevant code sections in parallel:

⏺ Searched for 5 patterns, read 2 files (ctrl+o to expand)

⏺ Now let me check the pivot table name and backtrack method:

⏺ Searched for 2 patterns, read 1 file (ctrl+o to expand)

⏺ Good. Now let me check what the ConstraintManager is referenced as in FETSolver:

⏺ Searched for 1 pattern (ctrl+o to expand)

⏺ I have everything I need. Now implementing all 7 tasks:

  ---
  Task 3: Filter activities by academic_term_id (simplest, do first)

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Added 2 lines, removed 2 lines
      787              ->keyBy('id');
      788      }
      789  
      790 -    private function loadActivitiesForActiveClassSections(): Collection                                                                                                                
      790 +    private function loadActivitiesForActiveClassSections(?int $academicTermId = null): Collection                                                                                     
      791      {
      792 -        // Optimize: Removed unused $activeClassSections query                                                                                                                         
      792          return Activity::query()
      793              ->where('is_active', true)
      794 +            ->when($academicTermId, fn($q) => $q->where('academic_term_id', $academicTermId))                                                                                          
      795              ->with([
      796                  'class',
      797                  'section',


⏺ Now pass the term ID when calling it in generateWithFET():

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Added 2 lines, removed 2 lines
      2534              // Load current academic session
      2535              $academicSession = AcademicSession::current()->firstOrFail();
      2536  
      2537 -            // Load activities for active class + sections only                                                                                                                       
      2538 -            $activities = $this->loadActivitiesForActiveClassSections();                                                                                                              
      2537 +            // Load activities filtered to the requested academic term                                                                                                                
      2538 +            $activities = $this->loadActivitiesForActiveClassSections((int) $validated['academic_term_id']);                                                                          
      2539  
      2540  
      2541              if ($activities->isEmpty()) {


⏺ Task 4: Eager loading in loadClassSections()

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Added 1 line, removed 1 line
      823  
      824      private function loadClassSections(): Collection
      825      {
      826 -        return ClassSection::where('is_active', true)->get();                                                                                                                          
      826 +        return ClassSection::where('is_active', true)->with(['class', 'section'])->get();                                                                                              
      827      }
      828  
      829      private function loadSchoolDays(): Collection

⏺ Task 5: Defer view-only queries — move academicSessions, timetableTypes, periodSets to after solver->solve():

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Added 1 line, removed 12 lines
      2519  
      2520  
      2521  
      2522 -            // Load active class sections                                                                                                                                             
      2522 +            // Load active class sections and academic session (required for generation)                                                                                              
      2523              $classSections = $this->loadClassSections();
      2524 -                                                                                                                                                                                      
      2525 -            // Load academic sessions                                                                                                                                                 
      2526 -            $academicSessions = AcademicSession::get();                                                                                                                               
      2527 -                                                                                                                                                                                      
      2528 -            // Load timetable types                                                                                                                                                   
      2529 -            $timetableTypes = TimetableType::where('is_active', true)->get();                                                                                                         
      2530 -                                                                                                                                                                                      
      2531 -            // Load period sets                                                                                                                                                       
      2532 -            $periodSets = PeriodSet::where('is_active', true)->get();                                                                                                                 
      2533 -                                                                                                                                                                                      
      2534 -            // Load current academic session                                                                                                                                          
      2524              $academicSession = AcademicSession::current()->firstOrFail();
      2525  
      2526              // Load activities filtered to the requested academic term

⏺ Now add those three queries just before the return view(...) call:

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Added 5 lines
      2769                  'conflicts' => count($conflicts),
      2770              ]);
      2771  
      2772 +            // Load view-only data deferred until after generation completes                                                                                                          
      2773 +            $academicSessions = AcademicSession::get();                                                                                                                               
      2774 +            $timetableTypes = TimetableType::where('is_active', true)->get();                                                                                                         
      2775 +            $periodSets = PeriodSet::where('is_active', true)->get();                                                                                                                 
      2776 +                                                                                                                                                                                      
      2777              return view('smarttimetable::preview.index', [
      2778                  'days' => $days,
      2779                  'periods' => $periods,

⏺ Task 1: Session storage optimization — store activity IDs only, reload from DB in storeTimetable():

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Added 3 lines, removed 2 lines
      2714                  })
      2715                  ->values();
      2716  
      2717 -            // Store generated timetable in session                                                                                                                                   
      2717 +            // Store generated timetable in session — store only activity IDs (not full Eloquent models)                                                                              
      2718 +            // Full models are reloaded in storeTimetable() to avoid 10-50MB session payloads                                                                                         
      2719              session([
      2720                  'generated_timetable_grid' => $schoolGrid,
      2720 -                'generated_activities' => $activitiesById,                                                                                                                            
      2721 +                'generated_activities' => $activitiesById->keys()->all(),                                                                                                             
      2722                  'generated_days' => $days,
      2723                  'generated_periods' => $periods,
      2724                  'generated_class_sections' => $classSectionsFiltered,



⏺ Now update storeTimetable() to reload activities from DB:

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Added 1 line, removed 1 line
      498  
      499          // Load generated data from session
      500          $schoolGrid = session('generated_timetable_grid');
      501 -        $activitiesById = session('generated_activities');                                                                                                                             
      501 +        $activityIds = session('generated_activities'); // stored as array of IDs                                                                                                      
      502          $periods = session('generated_periods');
      503          $selectedTeacherBySlot = session('generated_selected_teacher_by_slot', []);
      504          $forcedPlacements = session('generated_forced_placements', []);

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Added 7 lines, removed 1 line
      506          $runMeta = session('generation_run_meta');
      507          $runStats = session('generation_run_stats');
      508  
      509 -        if (!$schoolGrid || !$activitiesById || !$periods || !$runMeta || !$runStats) {                                                                                                
      509 +        if (!$schoolGrid || !$activityIds || !$periods || !$runMeta || !$runStats) {                                                                                                   
      510              return back()->with('error', 'No generated timetable data found. Please generate first.');
      511          }
      512  
      513 +        // Reload activity models from DB (session stores only IDs to reduce payload size)                                                                                             
      514 +        $activitiesById = Activity::with(['teachers'])                                                                                                                                 
      515 +            ->whereIn('id', $activityIds)                                                                                                                                              
      516 +            ->get()                                                                                                                                                                    
      517 +            ->keyBy('id');                                                                                                                                                             
      518 +                                                                                                                                                                                       
      519          $academicTermId = $validated['academic_term_id']
      520              ?? ($runMeta['academic_term_id'] ?? null)
      521              ?? AcademicTerm::where('is_current', true)->value('id');


⏺ Task 2: Batch insert in storeTimetable() — replace the triple-nested loop with collect-then-bulk-insert:

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Error editing file

⏺ The emoji in the comment caused a mismatch. Let me read the exact current text:

⏺ Read 1 file (ctrl+o to expand)

⏺ Agent(Batch insert refactor in storeTimetable)
  ⎿  Done (3 tool uses · 24.0k tokens · 54s)
  (ctrl+o to expand)

⏺ Now implement the remaining tasks — Task 6 (gate verbose logging) and Task 7 (clear ConstraintManager cache on backtrack):

  Task 6: Gate verbose logging in FETSolver

⏺ Searched for 1 pattern, read 1 file (ctrl+o to expand)

⏺ Now I have the full picture. Let me implement Tasks 6 and 7:

  Task 6: Gate verbose \Log::debug calls

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php)
  ⎿  Added 1 line
      85          $this->enforceClassTeacherFirstLecture = (bool) ($options['class_teacher_first_lecture'] ?? false);
      86          $this->singleActivityOncePerDayUntilOverflow = (bool) ($options['single_activity_once_per_day_until_overflow'] ?? true);
      87          $this->pinActivitiesByPeriod = (bool) ($options['pin_activities_by_period'] ?? false);
      88 +        $this->verboseLogging = (bool) ($options['verbose_logging'] ?? config('smart_timetable.verbose_logging', false));                                                               
      89  
      90          // Use provided constraint manager or create empty one
      91          $this->constraintManager = $constraintManager ?? new ConstraintManager();




⏺ Now add the property declaration:

⏺ Read 1 file (ctrl+o to expand)

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php)
  ⎿  Added 2 lines
      72      private bool $disallowConsecutivePeriods = true;
      73      // Hard rule: place at most one instance/day unless weekly demand exceeds working days.
      74      private bool $singleActivityOncePerDayUntilOverflow = true;
      75 +    // Gate for verbose debug logging (set via options or config('smart_timetable.verbose_logging'))                                                                                    
      76 +    private bool $verboseLogging = false;                                                                                                                                               
      77  
      78      // UPDATE CONSTRUCTOR: Accept ConstraintManager
      79      public function __construct(


⏺ Now wrap all \Log::debug calls in FETSolver with the flag check:

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php)
  ⎿  Added 1 line, removed 1 line
      453  
      454              if (!$canPlace) {
      455                  $this->stats['constraint_violations']++;
      456 -                \Log::debug('Constraint violation', [                                                                                                                                  
      456 +                if ($this->verboseLogging) \Log::debug('Constraint violation', [                                                                                                       
      457                      'activity_id' => $activity->id ?? $activity->original_activity_id ?? 'unknown',
      458                      'slot' => ['day' => $slot->dayId, 'start' => $slot->startIndex],
      459                      'class_key' => $slot->classKey,


⏺ Searched for 1 pattern (ctrl+o to expand)

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php)
  ⎿  Added 1 line, removed 1 line
      836  
      837              // If we've already placed at least one per day, allow flexible placement for remaining periods
      838              if ($placedCount >= $daysCount) {
      839 -                \Log::debug('High-demand activity overflow: flexible placement allowed', [                                                                                             
      839 +                if ($this->verboseLogging) \Log::debug('High-demand activity overflow: flexible placement allowed', [                                                                  
      840                      'activity_id' => $activity->original_activity_id ?? $activity->id,
      841                      'required_periods' => $requiredWeeklyPeriods,
      842                      'placed_count' => $placedCount,



⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php)
  ⎿  Added 1 line, removed 1 line
      1195                                  $placed++;
      1196                                  $activityPlaced = true;
      1197  
      1198 -                                \Log::debug('Greedy pass: Teacher shuffled', [                                                                                                        
      1198 +                                if ($this->verboseLogging) \Log::debug('Greedy pass: Teacher shuffled', [                                                                             
      1199                                      'activity_id' => $activity->original_activity_id ?? $activity->id,
      1200                                      'old_teacher' => $originalActivity->selected_teacher_id ?? 'unknown',
      1201                                      'new_teacher' => $alternativeTeacher['teacher_id'],




⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php)
  ⎿  Added 1 line, removed 1 line
      2401              }
      2402  
      2403              if ($isAvailable) {
      2404 -                \Log::debug('Found alternative teacher', [                                                                                                                            
      2404 +                if ($this->verboseLogging) \Log::debug('Found alternative teacher', [                                                                                                 
      2405                      'activity_id' => $originalActivityId,
      2406                      'old_teacher' => $currentTeacherId,
      2407                      'new_teacher' => $teacherAssignment['teacher_id'],

⏺ Also gate the ConstraintManager debug log:

⏺ Read 1 file (ctrl+o to expand)

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Constraints/ConstraintManager.php)
  ⎿  Added 1 line, removed 1 line
      75              if (!$constraint->passes($slot, $activity, $context)) {
      76                  $this->evaluationCache[$cacheKey] = false;
      77  
      78 -                \Log::debug('Hard constraint violation', [                                                                                                                              
      78 +                if (config('smart_timetable.verbose_logging', false)) \Log::debug('Hard constraint violation', [                                                                        
      79                      'activity_id' => $activity->id,
      80                      'constraint' => get_class($constraint),
      81                      'slot' => ['day' => $slot->dayId, 'start' => $slot->startIndex],


⏺ Task 7: Clear ConstraintManager cache on each backtrack step

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php)
  ⎿  Added 2 lines, removed 1 line
      419                          return true;
      420                      }
      421  
      422 -                    // Backtrack                                                                                                                                                       
      422 +                    // Backtrack — clear constraint cache so stale evaluations don't pollute next branch                                                                               
      423                      $solution->remove($activity, $slot);
      424 +                    $this->constraintManager->clearCache();                                                                                                                            
      425                      $this->fetStats['backtracks']++;
      426  
      427                      if ($this->fetStats['backtracks'] > $this->config['max_backtracks']) {


⏺ Now verify Tasks 6 and 7 look correct:

⏺ Read 1 file (ctrl+o to expand)

⏺ All 7 tasks done. Here's the full summary:

  ---
  STEP 3 — All 7 Tasks Completed:

  ┌─────┬────────────────────────────────┬───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │  #  │              Task              │                                                                          Change                                                                           │
  ├─────┼────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ T1  │ Session storage optimization   │ generated_activities now stores $activitiesById->keys()->all() (array of IDs). storeTimetable() reloads with Activity::with(['teachers'])->whereIn('id',  │
  │     │                                │ $activityIds) — from ~10-50MB Eloquent collection to a few KB                                                                                             │
  ├─────┼────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ T2  │ Batch insert in                │ 4 phases: (A) collect cell rows + teacher data, (B) TimetableCell::insert() in 500-row chunks, (C) reload cells to get IDs, (D)                           │
  │     │ storeTimetable()               │ DB::table('tt_timetable_cell_teachers')->insert() in chunks — from N×2 queries to ~4 queries                                                              │
  ├─────┼────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ T3  │ Filter activities by           │ loadActivitiesForActiveClassSections(?int $academicTermId) adds ->when($academicTermId, fn($q) => $q->where('academic_term_id', ...)) — filters correctly │
  │     │ academic_term_id               │  instead of loading all terms                                                                                                                             │
  ├─────┼────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ T4  │ Eager load in                  │ Added ->with(['class', 'section']) — eliminates N+1 when building classKey in grid loop                                                                   │
  │     │ loadClassSections()            │                                                                                                                                                           │
  ├─────┼────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ T5  │ Defer view-only queries        │ Moved AcademicSession::get(), TimetableType::get(), PeriodSet::get() to just before return view(...) — generation starts ~3 queries faster                │
  ├─────┼────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ T6  │ Gate verbose logging           │ $this->verboseLogging property (off by default, reads config('smart_timetable.verbose_logging')); all 4 \Log::debug() calls in FETSolver + 1 in           │
  │     │                                │ ConstraintManager gated behind it                                                                                                                         │
  ├─────┼────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ T7  │ Fix ConstraintManager cache    │ $this->constraintManager->clearCache() called immediately after $solution->remove() in backtrack() — prevents stale evaluations from prior branches       │
  │     │                                │ contaminating constraint checks in the next attempted slot                                                                                                │
  └─────┴────────────────────────────────┴───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

✻ Cogitated for 7m 43s

❯ Execute all the tasks of STEP 4: Room Allocation                                                                                                                                                       
  ⎿  ⧉ Selected 1 lines from 2-Tenant_Modules/8-Smart_Timetable/Claude_Context/2026Mar10_GapAnalysis_and_CompletionPlan.md in Visual Studio Code

⏺ Let me read both the STEP 4 tasks and the detailed room allocation plan:

⏺ Searched for 2 patterns, read 2 files (ctrl+o to expand)

⏺ Now let me look at the preview view and Room model:

⏺ Searched for 2 patterns, read 2 files (ctrl+o to expand)

⏺ Now I have all the context. Let me implement all 5 tasks. Starting with the RoomAllocationPass service:

  Task 1: Create RoomAllocationPass

⏺ Write(~/Herd/laravel/Modules/SmartTimetable/app/Services/RoomAllocationPass.php)
  ⎿  Wrote 182 lines to ../../../../../Herd/laravel/Modules/SmartTimetable/app/Services/RoomAllocationPass.php
       1 <?php
       2
       3 namespace Modules\SmartTimetable\Services;
       4
       5 use Illuminate\Support\Collection;
       6
       7 class RoomAllocationPass
       8 {
       9     /**
      10      * Room occupancy: roomOccupied[room_id][day_id][period_id] = activity_id
     … +172 lines (ctrl+o to expand)

⏺ Task 2: Integrate into generateWithFET() — add room allocation after solver, build $roomBySlot, store in session:

⏺ Read 1 file (ctrl+o to expand)

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Added 6 lines
      2634              $stats = $solver->getStats();
      2635              $stats['generation_time'] = $generationTime;
      2636  
      2637 +            // Room allocation pass — assign rooms based on activity room constraints                                                                                                 
      2638 +            $rooms = \Modules\SchoolSetup\Models\Room::where('is_active', true)->get();                                                                                               
      2639 +            $roomAllocator = new \Modules\SmartTimetable\Services\RoomAllocationPass();                                                                                               
      2640 +            $entries = $roomAllocator->allocate($entries, $activities->keyBy('id'), $rooms);                                                                                          
      2641 +            $roomConflicts = $roomAllocator->getRoomConflicts();                                                                                                                      
      2642 +                                                                                                                                                                                      
      2643              // Count fully placed activities
      2644              $placedActivityIds = collect($entries)
      2645                  ->pluck('activity_id')

⏺ Now add $roomBySlot collection alongside $selectedTeacherBySlot in the grid-building loop:

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Added 6 lines
      2662              $schoolGrid = [];
      2663              $conflicts = [];
      2664              $selectedTeacherBySlot = [];
      2665 +            $roomBySlot = [];                                                                                                                                                         
      2666  
      2667              foreach ($entries as $entry) {
      2668                  $activity = $activitiesById[$entry['activity_id']] ?? null;
     ...
      2685                  }
      2686  
      2687                  $schoolGrid[$classKey][$entry['day_id']][$entry['period_id']] = $entry['activity_id'];
      2688 +                                                                                                                                                                                      
      2689                  if (!empty($entry['teacher_id'])) {
      2690                      $selectedTeacherBySlot[$classKey][$entry['day_id']][$entry['period_id']] = [
      2691                          'teacher_id' => $entry['teacher_id'],
      2692                          'assignment_role_id' => $entry['assignment_role_id'] ?? null,
      2693                      ];
      2694                  }
      2695 +                                                                                                                                                                                      
      2696 +                if (!empty($entry['room_id'])) {                                                                                                                                      
      2697 +                    $roomBySlot[$classKey][$entry['day_id']][$entry['period_id']] = $entry['room_id'];                                                                                
      2698 +                }                                                                                                                                                                     
      2699              }
      2700  
      2701              $stats = $solver->getStats();

⏺ Now add room data to session and view. Find the session block:

⏺ Read 1 file (ctrl+o to expand)

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Added 2 lines
      2768                  'generated_class_sections' => $classSectionsFiltered,
      2769                  'generated_conflicts' => $conflicts,
      2770                  'generated_selected_teacher_by_slot' => $selectedTeacherBySlot,
      2771 +                'generated_room_by_slot' => $roomBySlot,                                                                                                                              
      2772 +                'generated_room_conflicts' => $roomConflicts,                                                                                                                         
      2773                  'generated_forced_placements' => $forcedPlacements,
      2774  
      2775                  // Generation Run metadata

⏺ Now pass room data to the preview view:

⏺ Read 1 file (ctrl+o to expand)

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Added 3 lines
      2839                  'algorithm_name' => 'FET (Advanced)',
      2840                  'placement_diagnostics' => $diagnostics,
      2841                  'forced_placements' => $forcedPlacements,
      2842 +                'roomBySlot' => $roomBySlot,                                                                                                                                          
      2843 +                'roomsById' => $rooms->keyBy('id'),                                                                                                                                   
      2844 +                'room_conflicts' => $roomConflicts,                                                                                                                                   
      2845              ]);
      2846  
      2847          } catch (\Illuminate\Validation\ValidationException $e) {

⏺ Task 3: Update storeTimetable() to persist room_id — read from session and use in batch insert:

⏺ Read 1 file (ctrl+o to expand)

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Added 1 line
      501          $activityIds = session('generated_activities'); // stored as array of IDs
      502          $periods = session('generated_periods');
      503          $selectedTeacherBySlot = session('generated_selected_teacher_by_slot', []);
      504 +        $roomBySlot = session('generated_room_by_slot', []);                                                                                                                           
      505          $forcedPlacements = session('generated_forced_placements', []);
      506  
      507          $runMeta = session('generation_run_meta');

⏺ Now update the cell insert row to use $roomBySlot:

⏺ Searched for 1 pattern (ctrl+o to expand)

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Added 1 line, removed 1 line
      658                              'class_subgroup_id'     => $classSubgroupId,
      659                              'activity_id'           => $activity->id,
      660                              'sub_activity_id'       => null,
      661 -                            'room_id'               => null,                                                                                                                           
      661 +                            'room_id'               => $roomBySlot[$classKey][$dayOfWeek][$periodId] ?? null,                                                                          
      662                              'source'                => 'AUTO',
      663                              'is_locked'             => false,
      664                              'has_conflict'          => $hasConflict,

⏺ Also add generated_room_by_slot and generated_room_conflicts to the session forget list:

⏺ Searched for 2 patterns (ctrl+o to expand)

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Added 2 lines
      772                  'generated_class_sections',
      773                  'generated_conflicts',
      774                  'generated_selected_teacher_by_slot',
      775 +                'generated_room_by_slot',                                                                                                                                              
      776 +                'generated_room_conflicts',                                                                                                                                            
      777                  'generated_forced_placements',
      778                  'generation_run_meta',
      779                  'generation_run_stats',

⏺ Task 5: Display room assignment in preview partial — update the "Room" meta item:

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/resources/views/preview/partials/_timetable.blade.php)
  ⎿  Added 2 lines
      241                                                      @php
      242                                                          $selectedTeacherId = $selectedTeacherBySlot[$classKey][$day->id][$period->id]['teacher_id'] ?? null;
      243                                                          $selectedTeacherName = null;
      244 +                                                        $assignedRoomId = ($roomBySlot ?? [])[$classKey][$day->id][$period->id] ?? null;                                               
      245 +                                                        $assignedRoom = $assignedRoomId ? (($roomsById ?? collect())->get($assignedRoomId)) : null;                                    
      246  
      247                                                          if ($selectedTeacherId) {
      248                                                              $selectedAssignment = collect($activity->teachers ?? [])

⏺ Now update the "Room" meta display to show the actual assigned room:

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/resources/views/preview/partials/_timetable.blade.php)
  ⎿  Added 10 lines, removed 2 lines
      353                                                              </div>
      354                                                              <div class="meta-item meta-item--full">
      355                                                                  <span class="meta-label">Room</span>
      356 -                                                                <span                                                                                                                  
      357 -                                                                    class="meta-value">{{ $roomRequirement ?: 'General classroom' }}</span>                                            
      356 +                                                                <span class="meta-value">                                                                                              
      357 +                                                                    @if($assignedRoom)                                                                                                 
      358 +                                                                        {{ $assignedRoom->name ?? $assignedRoom->code }}                                                               
      359 +                                                                        @if($assignedRoom->roomType)                                                                                   
      360 +                                                                            <small class="text-muted">({{ $assignedRoom->roomType->name }})</small>                                    
      361 +                                                                        @endif                                                                                                         
      362 +                                                                    @else                                                                                                              
      363 +                                                                        {{ $roomRequirement ?: 'General classroom' }}                                                                  
      364 +                                                                    @endif                                                                                                             
      365 +                                                                </span>                                                                                                                
      366                                                              </div>
      367                                                          </div>
      368  

⏺ Now the $assignedRoom->roomType lazy-loads — I should eager load it on the rooms collection in the controller. Update the room load:

⏺ Update(~/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php)
  ⎿  Added 1 line, removed 1 line
      2638              $stats['generation_time'] = $generationTime;
      2639  
      2640              // Room allocation pass — assign rooms based on activity room constraints
      2641 -            $rooms = \Modules\SchoolSetup\Models\Room::where('is_active', true)->get();                                                                                               
      2641 +            $rooms = \Modules\SchoolSetup\Models\Room::with('roomType')->where('is_active', true)->get();                                                                             
      2642              $roomAllocator = new \Modules\SmartTimetable\Services\RoomAllocationPass();
      2643              $entries = $roomAllocator->allocate($entries, $activities->keyBy('id'), $rooms);
      2644              $roomConflicts = $roomAllocator->getRoomConflicts();

⏺ Now verify the full integration is correct — check the area around solver call and session store:

⏺ Read 1 file (ctrl+o to expand)

⏺ All 5 STEP 4 tasks complete. Here's the full summary:

  ---
  STEP 4 — All 5 Tasks Completed:

  ┌─────┬─────────────────────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │  #  │          Task           │                                                                          What was built                                                                          │
  ├─────┼─────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │     │ RoomAllocationPass      │ New file: app/Services/RoomAllocationPass.php — 5-step allocation algorithm (specific room → compulsory type → preferred room IDs → preferred/required type →    │
  │ T1  │ service                 │ any available). Sorts by roomPriorityScore() so hard requirements claim rooms first. Tracks $roomOccupied[room_id][day_id][period_id] to prevent double-booking. │
  │     │                         │  getRoomConflicts() returns unfulfilled hard requirements.                                                                                                       │
  ├─────┼─────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │     │ Integration into        │ After solver->solve(): loads rooms with roomType eager, runs RoomAllocationPass::allocate(), adds room_id to each entry. Grid-building loop populates            │
  │ T2  │ generateWithFET()       │ $roomBySlot[$classKey][$dayId][$periodId] = $roomId. Session stores generated_room_by_slot and generated_room_conflicts. View receives roomBySlot, roomsById,    │
  │     │                         │ room_conflicts.                                                                                                                                                  │
  ├─────┼─────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ T3  │ storeTimetable()        │ Reads generated_room_by_slot from session. Cell insert row: 'room_id' => $roomBySlot[$classKey][$dayOfWeek][$periodId] ?? null (was hardcoded null). Both new    │
  │     │ persists room_id        │ session keys added to the forget list after commit.                                                                                                              │
  ├─────┼─────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ T4  │ Room conflict detection │ Built into RoomAllocationPass — when a hard room requirement (required_room_id or compulsory_specific_room_type + required_room_type_id) cannot be satisfied, a  │
  │     │                         │ conflict entry is recorded with type SPECIFIC_ROOM_UNAVAILABLE or ROOM_TYPE_UNAVAILABLE. Available via getRoomConflicts().                                       │
  ├─────┼─────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ T5  │ Preview shows assigned  │ _timetable.blade.php computes $assignedRoom from $roomBySlot + $roomsById. Shows $assignedRoom->name (RoomType) when allocated; falls back to room type          │
  │     │ room                    │ requirement name or "General classroom". roomType is eager-loaded on the rooms query to avoid N+1.                                                               │
  └─────┴─────────────────────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

✻ Cogitated for 3m 59s
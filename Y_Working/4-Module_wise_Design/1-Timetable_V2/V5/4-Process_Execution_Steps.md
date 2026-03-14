#  ENHANCED PROCESS EXECUTION STEPS
-----------------------------------

## PHASE 0: PRE-REQUISITES VALIDATION
```php
// Validate master data completeness
function validatePrerequisites($academicTermId, $timetableTypeId) {
    $checks = [
        'buildings' => sch_buildings::where('is_active', 1)->exists(),
        'rooms' => sch_rooms::where('is_active', 1)->exists(),
        'teachers' => sch_teachers_profile::where('is_active', 1)->exists(),
        'subjects' => sch_subject_study_format_jnt::where('is_active', 1)->exists(),
        'classes' => sch_class_section_jnt::where('is_active', 1)->exists(),
    ];
    
    $missing = array_filter($checks, fn($v) => !$v);
    if (!empty($missing)) {
        throw new ValidationException('Missing prerequisites: ' . implode(', ', array_keys($missing)));
    }
    
    return true;
}
```

## PHASE 1: ACADEMIC TERM SETUP WITH VALIDATION
```php
function setupAcademicTerm($data) {
    DB::transaction(function() use ($data) {
        // Validate no overlapping terms
        $overlapping = sch_academic_term::where('academic_session_id', $data['academic_session_id'])
            ->where(function($q) use ($data) {
                $q->whereBetween('term_start_date', [$data['term_start_date'], $data['term_end_date']])
                  ->orWhereBetween('term_end_date', [$data['term_start_date'], $data['term_end_date']]);
            })->exists();
            
        if ($overlapping) {
            throw new ValidationException('Term dates overlap with existing term');
        }
        
        // Create term
        $term = sch_academic_term::create($data);
        
        // Auto-generate working days
        generateWorkingDays($term);
        
        return $term;
    });
}
```

## PHASE 2: REQUIREMENT GENERATION WITH BATCH PROCESSING
```php
function generateRequirements($academicTermId, $timetableTypeId) {
    $batchSize = 100;
    $totalProcessed = 0;
    
    // Step 1: Generate slot requirements in batches
    tt_slot_requirement::where('academic_term_id', $academicTermId)->delete();
    
    tt_class_timetable_type_jnt::where('academic_term_id', $academicTermId)
        ->where('timetable_type_id', $timetableTypeId)
        ->chunk($batchSize, function($records) use ($academicTermId, $timetableTypeId) {
            foreach ($records as $record) {
                insertSlotRequirement($record, $academicTermId, $timetableTypeId);
            }
        });
    
    // Step 2: Calculate student counts with optimized query
    DB::statement("
        UPDATE sch_class_section_jnt cst
        INNER JOIN (
            SELECT class_section_id, COUNT(*) as student_count
            FROM std_student_academic_sessions
            WHERE academic_session_id = ?
            AND is_active = 1
            GROUP BY class_section_id
        ) sas ON cst.id = sas.class_section_id
        SET cst.actual_total_student = sas.student_count
    ", [$academicSessionId]);
    
    // Step 3: Update requirement groups
    updateRequirementGroups($academicTermId);
    updateRequirementSubgroups($academicTermId);
    
    // Step 4: Consolidate requirements
    consolidateRequirements($academicTermId, $timetableTypeId);
}
```

## PHASE 3: RESOURCE AVAILABILITY WITH CACHE
```php
function calculateTeacherAvailability($academicTermId, $timetableTypeId) {
    $cacheKey = "teacher_availability_{$academicTermId}_{$timetableTypeId}";
    
    return Cache::remember($cacheKey, 3600, function() use ($academicTermId, $timetableTypeId) {
        // Truncate and rebuild
        tt_teacher_availability::whereHas('requirement', function($q) use ($academicTermId, $timetableTypeId) {
            $q->where('academic_term_id', $academicTermId)
              ->where('timetable_type_id', $timetableTypeId);
        })->delete();
        
        // Bulk insert with optimized query
        DB::statement("
            INSERT INTO tt_teacher_availability (
                requirement_consolidation_id, class_id, section_id,
                subject_study_format_id, teacher_profile_id, required_weekly_periods,
                max_available_periods_weekly, min_available_periods_weekly,
                proficiency_percentage, teaching_experience_months
            )
            SELECT 
                trc.id, trc.class_id, trc.section_id,
                trc.subject_study_format_id, stp.id, trc.required_weekly_periods,
                stp.max_available_periods_weekly, stp.min_available_periods_weekly,
                stc.proficiency_percentage, stc.teaching_experience_months
            FROM tt_requirement_consolidation trc
            INNER JOIN sch_teacher_capabilities stc 
                ON trc.class_id = stc.class_id
                AND trc.subject_study_format_id = stc.subject_study_format_id
            INNER JOIN sch_teachers_profile stp ON stc.teacher_profile_id = stp.id
            WHERE trc.academic_term_id = ?
            AND trc.timetable_type_id = ?
            AND stc.is_active = 1
        ", [$academicTermId, $timetableTypeId]);
        
        // Calculate scores
        DB::statement("
            UPDATE tt_teacher_availability
            SET 
                min_teacher_availability_score = 
                    (min_available_periods_weekly / NULLIF(min_allocated_periods_weekly, 0)) * 100,
                max_teacher_availability_score = 
                    (max_available_periods_weekly / NULLIF(max_allocated_periods_weekly, 0)) * 100
        ");
        
        return tt_teacher_availability::count();
    });
}
```

## PHASE 4: VALIDATION WITH DETAILED REPORTING
```php
function validateRequirements($academicTermId, $timetableTypeId) {
    $validation = [
        'status' => 'PASSED',
        'checks' => [],
        'failures' => [],
        'warnings' => []
    ];
    
    // Check 1: Teacher availability vs requirement
    $teacherCheck = DB::select("
        SELECT 
            trc.class_id, trc.section_id, trc.subject_study_format_id,
            trc.required_weekly_periods,
            COUNT(tta.id) as available_teachers,
            SUM(CASE 
                WHEN tta.max_available_periods_weekly >= trc.required_weekly_periods 
                THEN 1 ELSE 0 
            END) as fully_available_teachers
        FROM tt_requirement_consolidation trc
        LEFT JOIN tt_teacher_availability tta 
            ON trc.id = tta.requirement_consolidation_id
        WHERE trc.academic_term_id = ?
        AND trc.timetable_type_id = ?
        GROUP BY trc.id
        HAVING available_teachers = 0
    ", [$academicTermId, $timetableTypeId]);
    
    if (!empty($teacherCheck)) {
        $validation['status'] = 'FAILED';
        $validation['failures'][] = [
            'type' => 'NO_TEACHER_AVAILABLE',
            'count' => count($teacherCheck),
            'details' => $teacherCheck
        ];
    }
    
    // Check 2: Room availability
    $roomCheck = DB::select("
        SELECT 
            trc.id, trc.class_id, trc.section_id,
            trc.required_room_type_id, trc.required_room_id
        FROM tt_requirement_consolidation trc
        WHERE trc.academic_term_id = ?
        AND trc.timetable_type_id = ?
        AND trc.compulsory_specific_room_type = 1
        AND NOT EXISTS (
            SELECT 1 FROM sch_rooms r
            WHERE r.room_type_id = trc.required_room_type_id
            AND (trc.required_room_id IS NULL OR r.id = trc.required_room_id)
            AND r.is_active = 1
        )
    ", [$academicTermId, $timetableTypeId]);
    
    if (!empty($roomCheck)) {
        $validation['status'] = 'FAILED';
        $validation['failures'][] = [
            'type' => 'ROOM_UNAVAILABLE',
            'count' => count($roomCheck),
            'details' => $roomCheck
        ];
    }
    
    // Check 3: Workload balance warnings
    $workloadWarnings = DB::select("
        SELECT 
            teacher_profile_id,
            SUM(required_weekly_periods) as total_required,
            max_available_periods_weekly
        FROM tt_teacher_availability
        GROUP BY teacher_profile_id, max_available_periods_weekly
        HAVING total_required > max_available_periods_weekly * 0.9
    ");
    
    if (!empty($workloadWarnings)) {
        $validation['warnings'][] = [
            'type' => 'HIGH_WORKLOAD',
            'count' => count($workloadWarnings),
            'details' => $workloadWarnings
        ];
    }
    
    return $validation;
}
```

## PHASE 5: ACTIVITY CREATION WITH PRIORITY CALCULATION
```php
function createActivities($academicTermId, $timetableTypeId) {
    // Truncate existing
    tt_activity::where('academic_term_id', $academicTermId)
        ->where('timetable_type_id', $timetableTypeId)
        ->delete();
    
    // Insert with calculated scores
    DB::statement("
        INSERT INTO tt_activity (
            uuid, code, name, academic_term_id, timetable_type_id,
            class_requirement_group_id, class_requirement_subgroup_id,
            class_id, section_id, subject_id, study_format_id,
            subject_type_id, subject_study_format_id,
            required_weekly_periods, min_periods_per_week, max_periods_per_week,
            max_per_day, min_per_day, min_gap_periods,
            allow_consecutive, max_consecutive, required_consecutive,
            preferred_periods_json, avoid_periods_json, spread_evenly,
            eligible_teacher_count, compulsory_specific_room_type,
            required_room_type_id, required_room_id,
            duration_periods, weekly_occurrences, is_compulsory,
            difficulty_score, constraint_count, status
        )
        SELECT 
            UUID(), 
            CONCAT(trc.class_id, '_', trc.section_id, '_', trc.subject_study_format_id),
            CONCAT(c.name, ' ', s.name, ' - ', ss.name),
            trc.academic_term_id, trc.timetable_type_id,
            trc.class_requirement_group_id, trc.class_requirement_subgroup_id,
            trc.class_id, trc.section_id, trc.subject_id, trc.study_format_id,
            trc.subject_type_id, trc.subject_study_format_id,
            trc.required_weekly_periods, trc.min_periods_per_week, trc.max_periods_per_week,
            trc.max_periods_per_day, trc.min_periods_per_day, trc.min_gap_between_periods,
            trc.allow_consecutive_periods, trc.max_consecutive_periods, trc.required_consecutive_periods,
            trc.preferred_periods_json, trc.avoid_periods_json, trc.spread_evenly,
            trc.eligible_teacher_count, trc.compulsory_specific_room_type,
            trc.required_room_type_id, trc.required_room_id,
            1, trc.required_weekly_periods, trc.is_compulsory,
            -- Calculate difficulty score
            LEAST(100,
                CASE 
                    WHEN trc.eligible_teacher_count = 0 THEN 100
                    WHEN trc.eligible_teacher_count = 1 THEN 90
                    WHEN trc.eligible_teacher_count = 2 THEN 75
                    WHEN trc.eligible_teacher_count = 3 THEN 60
                    WHEN trc.eligible_teacher_count = 4 THEN 45
                    WHEN trc.eligible_teacher_count = 5 THEN 30
                    ELSE 15
                END * 0.35 +
                CASE WHEN trc.is_compulsory = 1 THEN 20 ELSE 0 END * 0.20 +
                CASE 
                    WHEN trc.required_weekly_periods > 6 THEN 25
                    WHEN trc.required_weekly_periods > 4 THEN 20
                    WHEN trc.required_weekly_periods > 2 THEN 15
                    ELSE 5
                END * 0.15 +
                CASE WHEN trc.compulsory_specific_room_type = 1 THEN 20 ELSE 0 END * 0.15
            ) as difficulty_score,
            -- Count constraints
            (
                SELECT COUNT(*) FROM tt_constraint c
                WHERE c.target_type_id = (
                    SELECT id FROM tt_constraint_target_type WHERE code = 'ACTIVITY'
                )
                AND c.is_active = 1
                AND (c.academic_term_id IS NULL OR c.academic_term_id = trc.academic_term_id)
            ) as constraint_count,
            'DRAFT' as status
        FROM tt_requirement_consolidation trc
        INNER JOIN sch_classes c ON trc.class_id = c.id
        INNER JOIN sch_sections s ON trc.section_id = s.id
        INNER JOIN sch_subject_study_format_jnt ss ON trc.subject_study_format_id = ss.id
        WHERE trc.academic_term_id = ?
        AND trc.timetable_type_id = ?
        AND trc.is_active = 1
    ", [$academicTermId, $timetableTypeId]);
    
    // Update priorities
    DB::statement("
        UPDATE tt_activity a
        INNER JOIN tt_priority_config pc ON a.id = pc.activity_id
        SET a.calculated_priority = pc.final_priority
    ");
}
```






















------------------------------------------------------------------------------------------------------------------

function calculateRoomAvailability($academicTermId, $timetableTypeId) {
    $cacheKey = "room_availability_{$academicTermId}_{$timetableTypeId}";
    
    return Cache::remember($cacheKey, 3600, function() use ($academicTermId, $timetableTypeId) {
        // Truncate and rebuild
        tt_room_availability::whereHas('requirement', function($q) use ($academicTermId, $timetableTypeId) {
            $q->where('academic_term_id', $academicTermId)
              ->where('timetable_type_id', $timetableTypeId);
        })->delete();
        
        // Bulk insert with optimized query
        DB::statement("
            INSERT INTO tt_room_availability (
                requirement_consolidation_id, class_id, section_id,
                subject_study_format_id, room_id, required_weekly_periods,
                max_available_periods_weekly, min_available_periods_weekly,
                room_capacity, room_type_id
            )
            SELECT 
                trc.id, trc.class_id, trc.section_id,
                trc.subject_study_format_id, sr.id, trc.required_weekly_periods,
                sr.max_available_periods_weekly, sr.min_available_periods_weekly,
                sr.capacity, sr.room_type_id
            FROM tt_requirement_consolidation trc
            INNER JOIN sch_rooms sr 
                ON trc.room_id = sr.id
                AND trc.academic_term_id = ?
                AND trc.timetable_type_id = ?
                AND sr.is_active = 1
        ", [$academicTermId, $timetableTypeId]);
        
        // Calculate scores
        DB::statement("
            UPDATE tt_room_availability
            SET 
                min_room_availability_score = 
                    (min_available_periods_weekly / NULLIF(min_allocated_periods_weekly, 0)) * 100,
                max_room_availability_score = 
                    (max_available_periods_weekly / NULLIF(max_allocated_periods_weekly, 0)) * 100
        ");
        
        return tt_room_availability::count();
    });
}

function calculateResourceAvailability($academicTermId, $timetableTypeId) {
    $cacheKey = "resource_availability_{$academicTermId}_{$timetableTypeId}";
    
    // Check cache first
    $cachedAvailability = Cache::get($cacheKey);
    if ($cachedAvailability) {
        return $cachedAvailability;
    }
    
    // Get all requirements
    $requirements = tt_slot_requirement::where('academic_term_id', $academicTermId)
        ->where('timetable_type_id', $timetableTypeId)
        ->get();
    
    // Calculate availability
    $availability = [];
    
    foreach ($requirements as $req) {
        $availability[$req->id] = [
            'room_available' => checkRoomAvailability($req),
            'teacher_available' => checkTeacherAvailability($req),
            'resource_available' => checkResourceAvailability($req),
            'class_available' => checkClassAvailability($req),
        ];
    }
    
    // Cache for 1 hour
    Cache::put($cacheKey, $availability, 3600);
    
    return $availability;
}   
```
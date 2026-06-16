# BA — Behavioural Assessment Module Development Plan

**Module Code:** BA
**Version:** 1.0
**Date:** April 2026
**Based on:** BA_FeatureSpec.md + BehaviouralAssessment_v1.md

---

## Section 1 — Controller Inventory (11 Controllers)

### 1. RatingScaleController

```
File:  Modules/BehaviouralAssessment/app/Http/Controllers/RatingScaleController.php
```

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `behavioural-assessment/rating-scales` | `behavioural-assessment.rating-scales.index` | — | `ba.scale.manage` |
| `create` | GET | `behavioural-assessment/rating-scales/create` | `behavioural-assessment.rating-scales.create` | — | `ba.scale.manage` |
| `store` | POST | `behavioural-assessment/rating-scales` | `behavioural-assessment.rating-scales.store` | `StoreRatingScaleRequest` | `ba.scale.manage` |
| `show` | GET | `behavioural-assessment/rating-scales/{scale}` | `behavioural-assessment.rating-scales.show` | — | `ba.scale.manage` |
| `update` | PUT | `behavioural-assessment/rating-scales/{scale}` | `behavioural-assessment.rating-scales.update` | `UpdateRatingScaleRequest` | `ba.scale.manage` |
| `destroy` | DELETE | `behavioural-assessment/rating-scales/{scale}` | `behavioural-assessment.rating-scales.destroy` | — | `ba.scale.manage` |

**FR Coverage:** FR-BA-001
**Policy:** `RatingScalePolicy`

---

### 2. CategoryController

```
File:  Modules/BehaviouralAssessment/app/Http/Controllers/CategoryController.php
```

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `behavioural-assessment/categories` | `behavioural-assessment.categories.index` | — | `ba.category.viewAny` |
| `store` | POST | `behavioural-assessment/categories` | `behavioural-assessment.categories.store` | `StoreCategoryRequest` | `ba.category.manage` |
| `show` | GET | `behavioural-assessment/categories/{category}` | `behavioural-assessment.categories.show` | — | `ba.category.viewAny` |
| `update` | PUT | `behavioural-assessment/categories/{category}` | `behavioural-assessment.categories.update` | `UpdateCategoryRequest` | `ba.category.manage` |
| `destroy` | DELETE | `behavioural-assessment/categories/{category}` | `behavioural-assessment.categories.destroy` | — | `ba.category.manage` |
| `reorder` | POST | `behavioural-assessment/categories/reorder` | `behavioural-assessment.categories.reorder` | — | `ba.category.manage` |

**FR Coverage:** FR-BA-002
**Policy:** `CategoryPolicy`

---

### 3. CriterionController

```
File:  Modules/BehaviouralAssessment/app/Http/Controllers/CriterionController.php
```

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `behavioural-assessment/categories/{category}/criteria` | `behavioural-assessment.criteria.index` | — | `ba.category.viewAny` |
| `store` | POST | `behavioural-assessment/categories/{category}/criteria` | `behavioural-assessment.criteria.store` | `StoreCriterionRequest` | `ba.category.manage` |
| `show` | GET | `behavioural-assessment/criteria/{criterion}` | `behavioural-assessment.criteria.show` | — | `ba.category.viewAny` |
| `update` | PUT | `behavioural-assessment/criteria/{criterion}` | `behavioural-assessment.criteria.update` | `UpdateCriterionRequest` | `ba.category.manage` |
| `destroy` | DELETE | `behavioural-assessment/criteria/{criterion}` | `behavioural-assessment.criteria.destroy` | — | `ba.category.manage` |
| `reorder` | POST | `behavioural-assessment/categories/{category}/criteria/reorder` | `behavioural-assessment.criteria.reorder` | — | `ba.category.manage` |

**FR Coverage:** FR-BA-002
**Policy:** `CriterionPolicy`

---

### 4. ClassCategoryController

```
File:  Modules/BehaviouralAssessment/app/Http/Controllers/ClassCategoryController.php
```

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `behavioural-assessment/class-category-mapping` | `behavioural-assessment.class-category.index` | — | `ba.category.manage` |
| `store` | POST | `behavioural-assessment/class-category-mapping` | `behavioural-assessment.class-category.store` | `StoreClassCategoryRequest` | `ba.category.manage` |
| `destroy` | DELETE | `behavioural-assessment/class-category-mapping/{mapping}` | `behavioural-assessment.class-category.destroy` | — | `ba.category.manage` |

**FR Coverage:** FR-BA-002
**Policy:** `CategoryPolicy`

---

### 5. AssessmentPeriodController

```
File:  Modules/BehaviouralAssessment/app/Http/Controllers/AssessmentPeriodController.php
```

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `behavioural-assessment/periods` | `behavioural-assessment.periods.index` | — | `ba.period.viewAny` |
| `store` | POST | `behavioural-assessment/periods` | `behavioural-assessment.periods.store` | `StoreAssessmentPeriodRequest` | `ba.period.manage` |
| `show` | GET | `behavioural-assessment/periods/{period}` | `behavioural-assessment.periods.show` | — | `ba.period.viewAny` |
| `update` | PUT | `behavioural-assessment/periods/{period}` | `behavioural-assessment.periods.update` | `UpdateAssessmentPeriodRequest` | `ba.period.manage` |
| `destroy` | DELETE | `behavioural-assessment/periods/{period}` | `behavioural-assessment.periods.destroy` | — | `ba.period.manage` |
| `lock` | POST | `behavioural-assessment/periods/{period}/lock` | `behavioural-assessment.periods.lock` | — | `ba.period.manage` |
| `unlock` | POST | `behavioural-assessment/periods/{period}/unlock` | `behavioural-assessment.periods.unlock` | — | `ba.period.manage` |

**FR Coverage:** FR-BA-003
**Policy:** `AssessmentPeriodPolicy`

---

### 6. ConfigController

```
File:  Modules/BehaviouralAssessment/app/Http/Controllers/ConfigController.php
```

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `show` | GET | `behavioural-assessment/config` | `behavioural-assessment.config.show` | — | `ba.config.manage` |
| `update` | PUT | `behavioural-assessment/config` | `behavioural-assessment.config.update` | `UpdateConfigRequest` | `ba.config.manage` |

**FR Coverage:** FR-BA-004
**Policy:** `ConfigPolicy`

---

### 7. AssessmentController

```
File:  Modules/BehaviouralAssessment/app/Http/Controllers/AssessmentController.php
```

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `behavioural-assessment/assessments` | `behavioural-assessment.assessments.index` | — | `ba.assessment.viewAny` |
| `create` | GET | `behavioural-assessment/assessments/create` | `behavioural-assessment.assessments.create` | — | `ba.assessment.create` |
| `store` | POST | `behavioural-assessment/assessments` | `behavioural-assessment.assessments.store` | `StoreAssessmentRatingRequest` | `ba.assessment.create` |
| `show` | GET | `behavioural-assessment/assessments/{assessment}` | `behavioural-assessment.assessments.show` | — | `ba.assessment.viewAny` |
| `autoSave` | POST | `behavioural-assessment/assessments/{assessment}/auto-save` | `behavioural-assessment.assessments.auto-save` | — | `ba.assessment.create` |
| `bulkRate` | POST | `behavioural-assessment/assessments/{assessment}/bulk-rate` | `behavioural-assessment.assessments.bulk-rate` | `BulkRateRequest` | `ba.assessment.create` |
| `submit` | POST | `behavioural-assessment/assessments/{assessment}/submit` | `behavioural-assessment.assessments.submit` | `SubmitAssessmentRequest` | `ba.assessment.submit` |

**FR Coverage:** FR-BA-005, FR-BA-006
**Policy:** `AssessmentPolicy`

---

### 8. AssessmentReviewController

```
File:  Modules/BehaviouralAssessment/app/Http/Controllers/AssessmentReviewController.php
```

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `behavioural-assessment/reviews` | `behavioural-assessment.reviews.index` | — | `ba.review.viewAny` |
| `show` | GET | `behavioural-assessment/reviews/{assessment}` | `behavioural-assessment.reviews.show` | — | `ba.review.viewAny` |
| `approve` | POST | `behavioural-assessment/reviews/{assessment}/approve` | `behavioural-assessment.reviews.approve` | `ReviewAssessmentRequest` | `ba.review.approve` |
| `sendBack` | POST | `behavioural-assessment/reviews/{assessment}/send-back` | `behavioural-assessment.reviews.send-back` | `ReviewAssessmentRequest` | `ba.review.approve` |

**FR Coverage:** FR-BA-008
**Policy:** `AssessmentPolicy`

---

### 9. IncidentController

```
File:  Modules/BehaviouralAssessment/app/Http/Controllers/IncidentController.php
```

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `behavioural-assessment/incidents` | `behavioural-assessment.incidents.index` | — | `ba.incident.viewAny` |
| `store` | POST | `behavioural-assessment/incidents` | `behavioural-assessment.incidents.store` | `StoreIncidentRequest` | `ba.incident.create` |
| `show` | GET | `behavioural-assessment/incidents/{incident}` | `behavioural-assessment.incidents.show` | — | `ba.incident.viewAny` |
| `addFollowUp` | POST | `behavioural-assessment/incidents/{incident}/follow-up` | `behavioural-assessment.incidents.follow-up` | `AddFollowUpRequest` | `ba.incident.manage` |
| `timeline` | GET | `behavioural-assessment/incidents/student/{student}/timeline` | `behavioural-assessment.incidents.timeline` | — | `ba.incident.viewAny` |

**FR Coverage:** FR-BA-007
**Policy:** `IncidentPolicy`

---

### 10. InterventionController

```
File:  Modules/BehaviouralAssessment/app/Http/Controllers/InterventionController.php
```

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `behavioural-assessment/interventions` | `behavioural-assessment.interventions.index` | — | `ba.intervention.manage` |
| `store` | POST | `behavioural-assessment/interventions` | `behavioural-assessment.interventions.store` | `StoreInterventionRequest` | `ba.intervention.manage` |
| `show` | GET | `behavioural-assessment/interventions/{intervention}` | `behavioural-assessment.interventions.show` | — | `ba.intervention.manage` |
| `update` | PUT | `behavioural-assessment/interventions/{intervention}` | `behavioural-assessment.interventions.update` | `UpdateInterventionRequest` | `ba.intervention.manage` |
| `destroy` | DELETE | `behavioural-assessment/interventions/{intervention}` | `behavioural-assessment.interventions.destroy` | — | `ba.intervention.manage` |

**FR Coverage:** FR-BA-007 (master data)
**Policy:** `InterventionPolicy`

---

### 11. ReportController

```
File:  Modules/BehaviouralAssessment/app/Http/Controllers/ReportController.php
```

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `studentReport` | GET | `behavioural-assessment/reports/student/{student}` | `behavioural-assessment.reports.student` | — | `ba.report.student` |
| `classReport` | GET | `behavioural-assessment/reports/class/{classSection}` | `behavioural-assessment.reports.class` | — | `ba.report.class` |
| `schoolAnalytics` | GET | `behavioural-assessment/reports/school` | `behavioural-assessment.reports.school` | — | `ba.report.school` |
| `exportPdf` | GET | `behavioural-assessment/reports/student/{student}/pdf` | `behavioural-assessment.reports.pdf` | — | `ba.report.student` |
| `parentView` | GET | `behavioural-assessment/reports/parent/{student}` | `behavioural-assessment.reports.parent` | — | `ba.report.student` |
| `computeScores` | POST | `behavioural-assessment/reports/compute/{period}` | `behavioural-assessment.reports.compute` | — | `ba.score.compute` |
| `completionStatus` | GET | `behavioural-assessment/reports/completion/{period}` | `behavioural-assessment.reports.completion` | — | `ba.review.viewAny` |

**FR Coverage:** FR-BA-009, FR-BA-010, FR-BA-011, FR-BA-012, FR-BA-013, FR-BA-014, FR-BA-015
**Policy:** `ReportPolicy`

**Total Routes: 57**

---

## Section 2 — Service Inventory (5 Services)

### 1. BehaviouralAssessmentService

```
Service:     BehaviouralAssessmentService
File:        Modules/BehaviouralAssessment/app/Services/BehaviouralAssessmentService.php
Namespace:   Modules\BehaviouralAssessment\app\Services
Depends on:  BehaviouralScoreService, BehaviouralConfigService
Fires:       AssessmentSubmitted, AssessmentApproved, AssessmentSentBack
```

**Public Methods:**
| Method | Signature | Description |
|---|---|---|
| `resolveTeacherAssignments` | `(int $teacherId, int $periodId): Collection` | Returns class-sections + applicable categories for teacher |
| `createOrGetAssessment` | `(int $teacherId, int $classSectionId, int $periodId): Assessment` | Gets existing or creates new draft assessment |
| `saveRatings` | `(Assessment $assessment, array $ratings): void` | Bulk upsert ratings; validates period not locked |
| `autoSaveDraft` | `(Assessment $assessment, array $ratings): void` | Save without completeness validation (30s auto-save) |
| `bulkRate` | `(Assessment $assessment, int $criterionId, int $ratingLevelId): void` | Apply same rating to all students for one criterion |
| `submitAssessment` | `(Assessment $assessment): Assessment` | Draft→submitted; validates completeness; fires event |
| `approveAssessment` | `(Assessment $assessment, int $reviewerId): Assessment` | Submitted→reviewed; triggers score computation |
| `sendBackAssessment` | `(Assessment $assessment, int $reviewerId, string $remarks): Assessment` | Submitted/reviewed→draft with reviewer remarks |
| `lockAssessmentsForPeriod` | `(AssessmentPeriod $period): int` | Bulk lock all reviewed assessments for period |

**Dependency Graph:**
```
BehaviouralAssessmentService
  ├── BehaviouralScoreService (on approval → computeAndCacheScores)
  └── BehaviouralConfigService (for period/scale lookups)
```

---

### 2. BehaviouralScoreService

```
Service:     BehaviouralScoreService
File:        Modules/BehaviouralAssessment/app/Services/BehaviouralScoreService.php
Namespace:   Modules\BehaviouralAssessment\app\Services
Depends on:  BehaviouralConfigService
Fires:       ScoresComputed
```

**Public Methods:**
| Method | Signature | Description |
|---|---|---|
| `getStudentScore` | `(int $studentId, int $periodId): ?object` | Returns cached overall score + grade (public API for Exam/Result) |
| `getStudentCategoryScores` | `(int $studentId, int $periodId): Collection` | Returns per-category scores and grades |
| `getBulkScores` | `(array $studentIds, int $periodId): Collection` | Batch retrieval keyed by student_id (report card generation) |
| `computeAndCacheScores` | `(int $periodId, ?int $classSectionId = null): int` | Main computation engine; returns count computed |
| `computeStudentScore` | `(int $studentId, int $periodId): ComputedScore` | Core algorithm: criterion → category → overall |
| `mapScoreToGrade` | `(float $score, array $gradeBoundaries): ?string` | Looks up grade from boundaries JSON |

**Computation Pseudocode:**
```
computeStudentScore(studentId, periodId):
  Step 1: SELECT all ba_assessment_ratings WHERE student_id AND assessment.period_id
  Step 2: GROUP BY criterion_id → for each: AVG(numeric_value) across teachers
  Step 3: For negative polarity criteria: inverted = max_scale_value + 1 - raw_avg
  Step 4: GROUP criteria BY category_id
  Step 5: For each category: weighted_avg(criterion_scores, criterion.weight) → category_score
  Step 6: Overall: weighted_avg(category_scores, category.weight) per aggregation_method
  Step 7: Map overall_score → grade via grade_boundaries_json
  Step 8: UPSERT ba_computed_scores rows (one per category + overall on first)
  Return: { numeric_score, grade, overall_score, overall_grade, category_scores[] }
```

---

### 3. BehaviouralIncidentService

```
Service:     BehaviouralIncidentService
File:        Modules/BehaviouralAssessment/app/Services/BehaviouralIncidentService.php
Namespace:   Modules\BehaviouralAssessment\app\Services
Depends on:  BehaviouralConfigService
Fires:       IncidentCreated
```

**Public Methods:**
| Method | Signature | Description |
|---|---|---|
| `createIncident` | `(array $data): Incident` | Creates incident + witnesses + interventions; fires event |
| `addWitnesses` | `(Incident $incident, array $witnesses): void` | Creates ba_incident_witnesses_jnt rows |
| `mapInterventions` | `(Incident $incident, array $interventionIds): void` | Creates ba_incident_intervention_jnt rows |
| `addFollowUp` | `(Incident $incident, string $notes, ?string $followUpDate): Incident` | Appends follow-up; enforces immutability (BR-BA-008) |
| `getStudentIncidents` | `(int $studentId, array $filters): LengthAwarePaginator` | Paginated incidents with eager-loaded relations |
| `getStudentIncidentTimeline` | `(int $studentId): Collection` | Chronological timeline grouped by month |
| `shouldNotifyParent` | `(Incident $incident): bool` | Checks severity against config threshold |

---

### 4. BehaviouralConfigService

```
Service:     BehaviouralConfigService
File:        Modules/BehaviouralAssessment/app/Services/BehaviouralConfigService.php
Namespace:   Modules\BehaviouralAssessment\app\Services
Depends on:  — (leaf service, no BA dependencies)
Fires:       — (no events)
```

**Public Methods:**
| Method | Signature | Description |
|---|---|---|
| `getConfig` | `(?int $sessionId = null): Config` | Returns config for session; creates default if none |
| `updateConfig` | `(int $sessionId, array $data): Config` | Upserts config; validates weightage 5–20 |
| `getActiveRatingScale` | `(?int $sessionId = null): RatingScale` | Returns configured scale with eager-loaded levels |
| `getGradeBoundaries` | `(?int $sessionId = null): array` | Returns parsed grade_boundaries_json |
| `isResultIntegrationEnabled` | `(?int $sessionId = null): bool` | Returns is_result_integration_enabled flag |
| `getNotificationThreshold` | `(?int $sessionId = null): string` | Returns parent_notification_threshold |

---

### 5. BehaviouralReportService

```
Service:     BehaviouralReportService
File:        Modules/BehaviouralAssessment/app/Services/BehaviouralReportService.php
Namespace:   Modules\BehaviouralAssessment\app\Services
Depends on:  BehaviouralScoreService, BehaviouralIncidentService, BehaviouralConfigService
Fires:       — (no events)
```

**Public Methods:**
| Method | Signature | Description |
|---|---|---|
| `getStudentReport` | `(int $studentId, int $periodId): array` | Full student report: scores, criteria detail, remarks, incidents |
| `getStudentTrend` | `(int $studentId, ?int $sessionId): array` | Scores across all periods for trend chart |
| `getClassHeatmap` | `(int $classSectionId, int $periodId): array` | Students × categories score matrix with averages |
| `getSchoolAnalytics` | `(int $periodId): array` | Aggregate trends, completion rates, incident analysis |
| `getIncidentFrequencyAnalysis` | `(int $periodId): array` | Incident counts by type/severity/location/month |
| `getTeacherCompletionStatus` | `(int $periodId): Collection` | Per-teacher assessment status for dashboard |
| `generateStudentPdf` | `(int $studentId, int $periodId): string` | DomPDF report card; returns file path |
| `getParentView` | `(int $studentId, int $periodId): array` | Filtered data for parent portal |

---

## Section 3 — FormRequest Inventory (17 FormRequests)

### Configuration FormRequests

| Class | Controller Method | Key Validation Rules |
|---|---|---|
| `StoreRatingScaleRequest` | `RatingScaleController@store` | `name` required, max:100; `levels` required array, min:2; `levels.*.label` required, max:50; `levels.*.numeric_value` required, numeric; `grade_boundaries_json` optional, valid JSON array |
| `UpdateRatingScaleRequest` | `RatingScaleController@update` | Same as Store; `id` excluded from uniqueness checks |
| `StoreCategoryRequest` | `CategoryController@store` | `name` required, max:100; `polarity` required, enum:positive,negative; `weight` numeric, between:0,100; `sort_order` required, integer |
| `UpdateCategoryRequest` | `CategoryController@update` | Same as Store |
| `StoreCriterionRequest` | `CriterionController@store` | `name` required, max:255; `category_id` required, exists:ba_categories,id; `weight` numeric, between:0,100; `sort_order` required, integer |
| `UpdateCriterionRequest` | `CriterionController@update` | Same as Store |
| `StoreClassCategoryRequest` | `ClassCategoryController@store` | `class_id` required, exists:sch_classes,id; `category_ids` required, array; `category_ids.*` exists:ba_categories,id |
| `StoreAssessmentPeriodRequest` | `AssessmentPeriodController@store` | `name` required, max:100; `academic_session_id` required, exists:sch_org_academic_sessions_jnt,id; `start_date` required, date; `end_date` required, date, after:start_date; `deadline` required, date, after_or_equal:end_date; `academic_term_id` nullable, exists:sch_academic_term,id |
| `UpdateAssessmentPeriodRequest` | `AssessmentPeriodController@update` | Same as Store; period must not be locked |

### Assessment FormRequests

| Class | Controller Method | Key Validation Rules |
|---|---|---|
| `StoreAssessmentRatingRequest` | `AssessmentController@store` | `period_id` required, exists:ba_assessment_periods,id (must be open); `class_section_id` required, exists:sch_class_section_jnt,id; `ratings` required, array; `ratings.*.student_id` required, exists:std_students,id; `ratings.*.criterion_id` required, exists:ba_criteria,id; `ratings.*.rating_level_id` nullable, exists:ba_rating_levels,id; `ratings.*.remark` nullable, max:500 |
| `SubmitAssessmentRequest` | `AssessmentController@submit` | Assessment must be in `draft` status; all active criteria must have non-null rating_level_id for all active students in the class-section |
| `BulkRateRequest` | `AssessmentController@bulkRate` | `criterion_id` required, exists:ba_criteria,id; `rating_level_id` required, exists:ba_rating_levels,id |
| `ReviewAssessmentRequest` | `AssessmentReviewController@approve/sendBack` | `action` required, enum:approve,send_back; `remarks` required_if:action,send_back, max:1000 |

### Incident FormRequests

| Class | Controller Method | Key Validation Rules |
|---|---|---|
| `StoreIncidentRequest` | `IncidentController@store` | `student_id` required, exists:std_students,id; `incident_date` required, date, before_or_equal:today; `incident_type` required, enum:positive_reinforcement,negative_incident; `severity` required_if:incident_type,negative_incident, enum:minor,moderate,major,critical; `description` required, min:10; `location` required, enum values; `witnesses` optional, array; `intervention_ids` optional, array; `intervention_ids.*` exists:ba_interventions,id |
| `AddFollowUpRequest` | `IncidentController@addFollowUp` | `notes` required, min:10; `follow_up_date` nullable, date, after:today |

### Other FormRequests

| Class | Controller Method | Key Validation Rules |
|---|---|---|
| `UpdateConfigRequest` | `ConfigController@update` | `rating_scale_id` required, exists:ba_rating_scales,id; `is_result_integration_enabled` boolean; `weightage_percent` numeric, between:5,20; `aggregation_method` enum:average,weighted_average,separate_display; `parent_notification_threshold` enum:minor,moderate,major,critical |
| `StoreInterventionRequest` | `InterventionController@store` | `name` required, max:100; `intervention_type` required, enum:reward,corrective,counselling; `sort_order` required, integer |
| `UpdateInterventionRequest` | `InterventionController@update` | Same as Store |

---

## Section 4 — Blade View & Livewire Component Inventory

### 4.1 Blade Views (~55 views)

#### Rating Scale (~4 views)
| View File | Route Name | Description |
|---|---|---|
| `rating-scales/index.blade.php` | `rating-scales.index` | List all scales with level count |
| `rating-scales/create.blade.php` | `rating-scales.create` | Create form with dynamic level rows |
| `rating-scales/show.blade.php` | `rating-scales.show` | Scale detail with levels and grade boundaries |
| `rating-scales/_form.blade.php` | — | Shared form partial for create/edit |

#### Category & Criteria (~6 views)
| View File | Route Name | Description |
|---|---|---|
| `categories/index.blade.php` | `categories.index` | Category list with nested criteria accordion |
| `categories/_form-modal.blade.php` | — | Modal for create/edit category |
| `categories/show.blade.php` | `categories.show` | Category detail with criteria list |
| `criteria/_form-modal.blade.php` | — | Modal for create/edit criterion |
| `class-category/index.blade.php` | `class-category.index` | Checkbox matrix: classes × categories |
| `class-category/_mapping-grid.blade.php` | — | Partial for the mapping grid |

#### Assessment Period (~4 views)
| View File | Route Name | Description |
|---|---|---|
| `periods/index.blade.php` | `periods.index` | Period list with status badges |
| `periods/_form-modal.blade.php` | — | Modal for create/edit period |
| `periods/show.blade.php` | `periods.show` | Period detail with assessment completion stats |
| `periods/_status-badge.blade.php` | — | Status badge partial (open/closed/locked) |

#### Config (~2 views)
| View File | Route Name | Description |
|---|---|---|
| `config/show.blade.php` | `config.show` | Current configuration display |
| `config/edit.blade.php` | `config.update` | Config edit form with weightage slider |

#### Assessment Entry (~8 views)
| View File | Route Name | Description |
|---|---|---|
| `assessments/index.blade.php` | `assessments.index` | Teacher's assessment list (my assessments) |
| `assessments/create.blade.php` | `assessments.create` | Select period + class-section to start |
| `assessments/show.blade.php` | `assessments.show` | Assessment detail view (read-only for non-owner) |
| `assessments/_grid.blade.php` | — | The main students × criteria rating grid |
| `assessments/_bulk-toolbar.blade.php` | — | Bulk action toolbar partial |
| `assessments/_student-remark-modal.blade.php` | — | Modal for overall student remark |
| `assessments/_draft-indicator.blade.php` | — | Auto-save status indicator |
| `assessments/_submit-confirmation.blade.php` | — | Submit confirmation modal |

#### Review (~4 views)
| View File | Route Name | Description |
|---|---|---|
| `reviews/index.blade.php` | `reviews.index` | Submitted assessments for review |
| `reviews/show.blade.php` | `reviews.show` | Review grid (read-only ratings + approve/send-back) |
| `reviews/_approval-modal.blade.php` | — | Approve confirmation modal |
| `reviews/_send-back-modal.blade.php` | — | Send-back with remarks modal |

#### Incidents (~8 views)
| View File | Route Name | Description |
|---|---|---|
| `incidents/index.blade.php` | `incidents.index` | Incident list with filters |
| `incidents/create.blade.php` | `incidents.store` | Create incident form |
| `incidents/show.blade.php` | `incidents.show` | Incident detail with witnesses, interventions |
| `incidents/_timeline.blade.php` | `incidents.timeline` | Student incident timeline view |
| `incidents/_follow-up-modal.blade.php` | — | Add follow-up notes modal |
| `incidents/_witness-selector.blade.php` | — | Witness selection partial |
| `incidents/_intervention-selector.blade.php` | — | Intervention multi-select partial |
| `incidents/_severity-badge.blade.php` | — | Severity colour badge partial |

#### Interventions (~3 views)
| View File | Route Name | Description |
|---|---|---|
| `interventions/index.blade.php` | `interventions.index` | Intervention master list |
| `interventions/_form-modal.blade.php` | — | Modal for create/edit |
| `interventions/show.blade.php` | `interventions.show` | Intervention detail |

#### Reports (~8 views)
| View File | Route Name | Description |
|---|---|---|
| `reports/student.blade.php` | `reports.student` | Student behavioural report card |
| `reports/class.blade.php` | `reports.class` | Class heatmap view |
| `reports/school.blade.php` | `reports.school` | School analytics dashboard |
| `reports/parent.blade.php` | `reports.parent` | Parent portal view |
| `reports/_student-pdf.blade.php` | — | DomPDF template for student report |
| `reports/_trend-chart.blade.php` | — | Period-over-period trend chart partial |
| `reports/_heatmap-grid.blade.php` | — | Class heatmap colour grid partial |
| `reports/_completion-status.blade.php` | `reports.completion` | Teacher completion dashboard |

#### Dashboard (~3 views)
| View File | Route Name | Description |
|---|---|---|
| `dashboard/teacher.blade.php` | — | Teacher dashboard: pending, deadlines, follow-ups |
| `dashboard/principal.blade.php` | — | Principal: completion, flagged students, trends |
| `dashboard/parent.blade.php` | — | Parent: child's grade card, incident alerts |

#### Shared Partials (~5 views)
| View File | Description |
|---|---|
| `partials/_status-badge.blade.php` | Assessment status badge (draft/submitted/reviewed/locked) |
| `partials/_period-selector.blade.php` | Assessment period dropdown selector |
| `partials/_class-section-selector.blade.php` | Class-section dropdown |
| `partials/_student-search.blade.php` | Student auto-suggest search |
| `partials/_empty-state.blade.php` | Empty state placeholder |

**Total: ~55 blade views**

---

### 4.2 Livewire Components (9)

| Component | File | Purpose | Key Features |
|---|---|---|---|
| `BehaviouralAssessmentGrid` | `app/Livewire/BehaviouralAssessmentGrid.php` | Main assessment entry grid | Students × criteria grid; dropdown ratings; colour-coded (green→red); keyboard Tab nav; sticky header + first column; `wire:poll.30s` auto-save; bulk action toolbar |
| `IncidentLogForm` | `app/Livewire/IncidentLogForm.php` | Create/edit incident | Auto-suggest student name with recent incident count; category/criterion dropdowns; witness multi-select; intervention checkboxes; attachment upload via Livewire |
| `IncidentTimeline` | `app/Livewire/IncidentTimeline.php` | Student incident history | Filterable timeline; severity colour-coding; follow-up indicators; grouped by month; infinite scroll |
| `BehaviouralReportCard` | `app/Livewire/BehaviouralReportCard.php` | Student report view | Category score bars; per-criterion detail expandable; trend chart (Chart.js); remarks display; incident summary; PDF download button |
| `BehaviouralDashboard` | `app/Livewire/BehaviouralDashboard.php` | Role-aware dashboard | Teachers: pending assessments, deadlines, recent incidents, follow-up reminders; Principal: completion status, flagged students, category averages, incident trends |
| `CategoryCriteriaManager` | `app/Livewire/CategoryCriteriaManager.php` | Admin CRUD for categories/criteria | Drag-and-drop reorder (SortableJS via Alpine); inline edit; activate/deactivate toggles; nested accordion for criteria within categories |
| `RatingScaleManager` | `app/Livewire/RatingScaleManager.php` | Admin CRUD for rating scales | Scale + levels management together; add/remove level rows dynamically; grade boundary configuration with validation |
| `AssessmentPeriodManager` | `app/Livewire/AssessmentPeriodManager.php` | Admin CRUD for periods | Period list with status badges; date range picker; exam term linking dropdown; lock/unlock toggle with confirmation |
| `BehaviouralConfigPanel` | `app/Livewire/BehaviouralConfigPanel.php` | Admin settings panel | Result integration toggle; weightage range slider (5–20%); aggregation method selector; notification threshold dropdown; active scale selector |

---

## Section 5 — Complete Route List

All routes wrapped in middleware: `['auth', 'tenant', 'EnsureTenantHasModule:BehaviouralAssessment']`

| # | Method | URI | Route Name | Controller@method |
|---|---|---|---|---|
| | **Rating Scales** | | | |
| 1 | GET | `behavioural-assessment/rating-scales` | `behavioural-assessment.rating-scales.index` | `RatingScaleController@index` |
| 2 | GET | `behavioural-assessment/rating-scales/create` | `behavioural-assessment.rating-scales.create` | `RatingScaleController@create` |
| 3 | POST | `behavioural-assessment/rating-scales` | `behavioural-assessment.rating-scales.store` | `RatingScaleController@store` |
| 4 | GET | `behavioural-assessment/rating-scales/{scale}` | `behavioural-assessment.rating-scales.show` | `RatingScaleController@show` |
| 5 | PUT | `behavioural-assessment/rating-scales/{scale}` | `behavioural-assessment.rating-scales.update` | `RatingScaleController@update` |
| 6 | DELETE | `behavioural-assessment/rating-scales/{scale}` | `behavioural-assessment.rating-scales.destroy` | `RatingScaleController@destroy` |
| | **Categories** | | | |
| 7 | GET | `behavioural-assessment/categories` | `behavioural-assessment.categories.index` | `CategoryController@index` |
| 8 | POST | `behavioural-assessment/categories` | `behavioural-assessment.categories.store` | `CategoryController@store` |
| 9 | GET | `behavioural-assessment/categories/{category}` | `behavioural-assessment.categories.show` | `CategoryController@show` |
| 10 | PUT | `behavioural-assessment/categories/{category}` | `behavioural-assessment.categories.update` | `CategoryController@update` |
| 11 | DELETE | `behavioural-assessment/categories/{category}` | `behavioural-assessment.categories.destroy` | `CategoryController@destroy` |
| 12 | POST | `behavioural-assessment/categories/reorder` | `behavioural-assessment.categories.reorder` | `CategoryController@reorder` |
| | **Criteria** | | | |
| 13 | GET | `behavioural-assessment/categories/{category}/criteria` | `behavioural-assessment.criteria.index` | `CriterionController@index` |
| 14 | POST | `behavioural-assessment/categories/{category}/criteria` | `behavioural-assessment.criteria.store` | `CriterionController@store` |
| 15 | GET | `behavioural-assessment/criteria/{criterion}` | `behavioural-assessment.criteria.show` | `CriterionController@show` |
| 16 | PUT | `behavioural-assessment/criteria/{criterion}` | `behavioural-assessment.criteria.update` | `CriterionController@update` |
| 17 | DELETE | `behavioural-assessment/criteria/{criterion}` | `behavioural-assessment.criteria.destroy` | `CriterionController@destroy` |
| 18 | POST | `behavioural-assessment/categories/{category}/criteria/reorder` | `behavioural-assessment.criteria.reorder` | `CriterionController@reorder` |
| | **Class-Category Mapping** | | | |
| 19 | GET | `behavioural-assessment/class-category-mapping` | `behavioural-assessment.class-category.index` | `ClassCategoryController@index` |
| 20 | POST | `behavioural-assessment/class-category-mapping` | `behavioural-assessment.class-category.store` | `ClassCategoryController@store` |
| 21 | DELETE | `behavioural-assessment/class-category-mapping/{mapping}` | `behavioural-assessment.class-category.destroy` | `ClassCategoryController@destroy` |
| | **Assessment Periods** | | | |
| 22 | GET | `behavioural-assessment/periods` | `behavioural-assessment.periods.index` | `AssessmentPeriodController@index` |
| 23 | POST | `behavioural-assessment/periods` | `behavioural-assessment.periods.store` | `AssessmentPeriodController@store` |
| 24 | GET | `behavioural-assessment/periods/{period}` | `behavioural-assessment.periods.show` | `AssessmentPeriodController@show` |
| 25 | PUT | `behavioural-assessment/periods/{period}` | `behavioural-assessment.periods.update` | `AssessmentPeriodController@update` |
| 26 | DELETE | `behavioural-assessment/periods/{period}` | `behavioural-assessment.periods.destroy` | `AssessmentPeriodController@destroy` |
| 27 | POST | `behavioural-assessment/periods/{period}/lock` | `behavioural-assessment.periods.lock` | `AssessmentPeriodController@lock` |
| 28 | POST | `behavioural-assessment/periods/{period}/unlock` | `behavioural-assessment.periods.unlock` | `AssessmentPeriodController@unlock` |
| | **Config** | | | |
| 29 | GET | `behavioural-assessment/config` | `behavioural-assessment.config.show` | `ConfigController@show` |
| 30 | PUT | `behavioural-assessment/config` | `behavioural-assessment.config.update` | `ConfigController@update` |
| | **Assessments** | | | |
| 31 | GET | `behavioural-assessment/assessments` | `behavioural-assessment.assessments.index` | `AssessmentController@index` |
| 32 | GET | `behavioural-assessment/assessments/create` | `behavioural-assessment.assessments.create` | `AssessmentController@create` |
| 33 | POST | `behavioural-assessment/assessments` | `behavioural-assessment.assessments.store` | `AssessmentController@store` |
| 34 | GET | `behavioural-assessment/assessments/{assessment}` | `behavioural-assessment.assessments.show` | `AssessmentController@show` |
| 35 | POST | `behavioural-assessment/assessments/{assessment}/auto-save` | `behavioural-assessment.assessments.auto-save` | `AssessmentController@autoSave` |
| 36 | POST | `behavioural-assessment/assessments/{assessment}/bulk-rate` | `behavioural-assessment.assessments.bulk-rate` | `AssessmentController@bulkRate` |
| 37 | POST | `behavioural-assessment/assessments/{assessment}/submit` | `behavioural-assessment.assessments.submit` | `AssessmentController@submit` |
| | **Reviews** | | | |
| 38 | GET | `behavioural-assessment/reviews` | `behavioural-assessment.reviews.index` | `AssessmentReviewController@index` |
| 39 | GET | `behavioural-assessment/reviews/{assessment}` | `behavioural-assessment.reviews.show` | `AssessmentReviewController@show` |
| 40 | POST | `behavioural-assessment/reviews/{assessment}/approve` | `behavioural-assessment.reviews.approve` | `AssessmentReviewController@approve` |
| 41 | POST | `behavioural-assessment/reviews/{assessment}/send-back` | `behavioural-assessment.reviews.send-back` | `AssessmentReviewController@sendBack` |
| | **Incidents** | | | |
| 42 | GET | `behavioural-assessment/incidents` | `behavioural-assessment.incidents.index` | `IncidentController@index` |
| 43 | POST | `behavioural-assessment/incidents` | `behavioural-assessment.incidents.store` | `IncidentController@store` |
| 44 | GET | `behavioural-assessment/incidents/{incident}` | `behavioural-assessment.incidents.show` | `IncidentController@show` |
| 45 | POST | `behavioural-assessment/incidents/{incident}/follow-up` | `behavioural-assessment.incidents.follow-up` | `IncidentController@addFollowUp` |
| 46 | GET | `behavioural-assessment/incidents/student/{student}/timeline` | `behavioural-assessment.incidents.timeline` | `IncidentController@timeline` |
| | **Interventions** | | | |
| 47 | GET | `behavioural-assessment/interventions` | `behavioural-assessment.interventions.index` | `InterventionController@index` |
| 48 | POST | `behavioural-assessment/interventions` | `behavioural-assessment.interventions.store` | `InterventionController@store` |
| 49 | GET | `behavioural-assessment/interventions/{intervention}` | `behavioural-assessment.interventions.show` | `InterventionController@show` |
| 50 | PUT | `behavioural-assessment/interventions/{intervention}` | `behavioural-assessment.interventions.update` | `InterventionController@update` |
| 51 | DELETE | `behavioural-assessment/interventions/{intervention}` | `behavioural-assessment.interventions.destroy` | `InterventionController@destroy` |
| | **Reports** | | | |
| 52 | GET | `behavioural-assessment/reports/student/{student}` | `behavioural-assessment.reports.student` | `ReportController@studentReport` |
| 53 | GET | `behavioural-assessment/reports/class/{classSection}` | `behavioural-assessment.reports.class` | `ReportController@classReport` |
| 54 | GET | `behavioural-assessment/reports/school` | `behavioural-assessment.reports.school` | `ReportController@schoolAnalytics` |
| 55 | GET | `behavioural-assessment/reports/student/{student}/pdf` | `behavioural-assessment.reports.pdf` | `ReportController@exportPdf` |
| 56 | GET | `behavioural-assessment/reports/parent/{student}` | `behavioural-assessment.reports.parent` | `ReportController@parentView` |
| 57 | POST | `behavioural-assessment/reports/compute/{period}` | `behavioural-assessment.reports.compute` | `ReportController@computeScores` |
| 58 | GET | `behavioural-assessment/reports/completion/{period}` | `behavioural-assessment.reports.completion` | `ReportController@completionStatus` |

**Total: 58 routes**

---

## Section 6 — Implementation Phases (4 Phases)

### Phase 1 — Configuration Foundation (Sprint 1)

**FRs:** BA-001, BA-002, BA-003, BA-004

**Files to Create:**

| Type | Files | Count |
|---|---|---|
| Controllers | RatingScaleController, CategoryController, CriterionController, ClassCategoryController, AssessmentPeriodController, ConfigController | 6 |
| Services | BehaviouralConfigService | 1 |
| Models | RatingScale, RatingLevel, Category, Criterion, ClassCategory, AssessmentPeriod, Config | 7 |
| Livewire | RatingScaleManager, CategoryCriteriaManager, AssessmentPeriodManager, BehaviouralConfigPanel | 4 |
| FormRequests | StoreRatingScaleRequest, UpdateRatingScaleRequest, StoreCategoryRequest, UpdateCategoryRequest, StoreCriterionRequest, UpdateCriterionRequest, StoreClassCategoryRequest, StoreAssessmentPeriodRequest, UpdateAssessmentPeriodRequest, UpdateConfigRequest | 10 |
| Policies | RatingScalePolicy, CategoryPolicy, CriterionPolicy, AssessmentPeriodPolicy, ConfigPolicy | 5 |
| Seeders | BaRatingScaleSeeder, BaCategorySeeder, BaInterventionSeeder, BaSeederRunner | 4 |
| Views | ~16 blade views | 16 |
| Tests | RatingScaleTest, CategoryCriterionTest, AssessmentPeriodTest | 3 files, ~16 tests |

---

### Phase 2 — Assessment Workflow (Sprint 2–3)

**FRs:** BA-005, BA-006, BA-008

**Files to Create:**

| Type | Files | Count |
|---|---|---|
| Controllers | AssessmentController, AssessmentReviewController | 2 |
| Services | BehaviouralAssessmentService | 1 |
| Models | Assessment, AssessmentRating, StudentRemark, AuditLog | 4 |
| Observers | AssessmentRatingObserver (audit log), AssessmentObserver (status audit) | 2 |
| Livewire | BehaviouralAssessmentGrid | 1 |
| FormRequests | StoreAssessmentRatingRequest, SubmitAssessmentRequest, BulkRateRequest, ReviewAssessmentRequest | 4 |
| Policies | AssessmentPolicy | 1 |
| Events | AssessmentSubmitted, AssessmentApproved, AssessmentSentBack | 3 |
| Views | ~12 blade views | 12 |
| Tests | AssessmentEntryTest, AssessmentReviewTest | 2 files, ~12 tests |

---

### Phase 3 — Incident Management (Sprint 4)

**FRs:** BA-007

**Files to Create:**

| Type | Files | Count |
|---|---|---|
| Controllers | IncidentController, InterventionController | 2 |
| Services | BehaviouralIncidentService | 1 |
| Models | Incident, IncidentWitness, IncidentIntervention, Intervention | 4 |
| Livewire | IncidentLogForm, IncidentTimeline | 2 |
| FormRequests | StoreIncidentRequest, AddFollowUpRequest, StoreInterventionRequest, UpdateInterventionRequest | 4 |
| Policies | IncidentPolicy, InterventionPolicy | 2 |
| Events | IncidentCreated | 1 |
| Views | ~11 blade views | 11 |
| Tests | IncidentTest | 1 file, ~5 tests |

---

### Phase 4 — Score Computation & Reports (Sprint 5–6)

**FRs:** BA-009, BA-010, BA-011, BA-012, BA-013, BA-014, BA-015

**Files to Create:**

| Type | Files | Count |
|---|---|---|
| Controllers | ReportController | 1 |
| Services | BehaviouralScoreService, BehaviouralReportService | 2 |
| Models | ComputedScore | 1 |
| Jobs | ComputeSchoolScoresJob | 1 |
| Livewire | BehaviouralReportCard, BehaviouralDashboard | 2 |
| Policies | ReportPolicy | 1 |
| Events | ScoresComputed | 1 |
| Views | ~16 blade views (reports + dashboards + PDF template) | 16 |
| Tests | ScoreComputationTest, ReportTest, ScoreCalculatorTest (unit), GradeMappingTest (unit), TeacherAssignmentResolverTest (unit), ResultIntegrationFormulaTest (unit) | 6 files, ~22 tests |

---

## Section 7 — Seeder Execution Order

```
php artisan module:seed BehaviouralAssessment --class=BaSeederRunner
  ↓ BaRatingScaleSeeder        (ba_rating_scales + ba_rating_levels — no deps)
  ↓ BaCategorySeeder           (ba_categories + ba_criteria — no deps)
  ↓ BaInterventionSeeder       (ba_interventions — no deps)
```

**For test runs:** Use `BaRatingScaleSeeder` + `BaCategorySeeder` as minimum required seeders.

**Note:** `ba_config` is NOT seeded. It is created on first access by `BehaviouralConfigService::getConfig()` using the default scale and default settings (`is_result_integration_enabled = false`).

---

## Section 8 — Testing Strategy

### 8.1 Framework

Pest for Feature tests; Pest (unit style) for Unit tests.

### 8.2 Feature Test Setup

```php
uses(Tests\TenantTestCase::class, RefreshDatabase::class);

// Setup: run BaSeederRunner for seed data
// Create SchoolSetup fixtures via factories:
//   - sch_org_academic_sessions_jnt (current session)
//   - sch_classes, sch_sections, sch_class_section_jnt
//   - sch_employees (teachers)
//   - std_students (students in the class-section)
```

### 8.3 Feature Test Files (~8 files, ~40 tests)

| File | Path | Count | Key Scenarios |
|---|---|---|---|
| `RatingScaleTest.php` | `Modules/BehaviouralAssessment/tests/Feature/` | 5 | Create scale + levels; update level order; delete scale cascades levels; duplicate sort_order rejected; default scale flag toggle |
| `CategoryCriterionTest.php` | `Modules/BehaviouralAssessment/tests/Feature/` | 6 | Create category with polarity; add criteria with weights; reorder criteria; deactivate category; map category to class; delete category cascades criteria |
| `AssessmentPeriodTest.php` | `Modules/BehaviouralAssessment/tests/Feature/` | 5 | Create period with valid dates; validate start < end; lock period transitions all reviewed→locked; unlock period; prevent edits on locked period |
| `AssessmentEntryTest.php` | `Modules/BehaviouralAssessment/tests/Feature/` | 7 | Create assessment for teacher; save ratings; auto-save draft; bulk rate all students; submit (all criteria filled); reject submit if incomplete; unique constraint on duplicate assessment |
| `AssessmentReviewTest.php` | `Modules/BehaviouralAssessment/tests/Feature/` | 5 | Approve transitions to reviewed; send back with remarks reverts to draft; lock prevents edits (BR-BA-003); only reviewer role can approve; score computation triggered on approval |
| `IncidentTest.php` | `Modules/BehaviouralAssessment/tests/Feature/` | 5 | Create with witnesses + interventions; add follow-up notes; core fields immutable after creation (BR-BA-008); parent notification threshold check; incident timeline filtering |
| `ScoreComputationTest.php` | `Modules/BehaviouralAssessment/tests/Feature/` | 4 | Compute single student; multi-teacher averaging; negative polarity inversion (BR-BA-019); grade mapping from boundaries |
| `ReportTest.php` | `Modules/BehaviouralAssessment/tests/Feature/` | 3 | Student report returns correct structure; class heatmap data; PDF export creates file |

### 8.4 Unit Test Files (~4 files, ~15 tests)

| File | Path | Count | Key Scenarios |
|---|---|---|---|
| `ScoreCalculatorTest.php` | `Modules/BehaviouralAssessment/tests/Unit/` | 5 | Weighted average math; all-zero weights → simple average; single criterion; empty ratings → null; exact max boundary |
| `GradeMappingTest.php` | `Modules/BehaviouralAssessment/tests/Unit/` | 3 | Exact boundary 4.50 = A+; between boundaries 3.75 = A; below minimum 0.5 = C |
| `TeacherAssignmentResolverTest.php` | `Modules/BehaviouralAssessment/tests/Unit/` | 4 | Class teacher → all categories; subject teacher → mapped only; no assignment → empty; deactivated category excluded |
| `ResultIntegrationFormulaTest.php` | `Modules/BehaviouralAssessment/tests/Unit/` | 3 | 10% weightage: `(85×0.9)+(4.2/5×100×0.1) = 84.9`; 5% weightage; 20% weightage |

### 8.5 Factory Requirements

| Factory | Key Attributes | States |
|---|---|---|
| `RatingScaleFactory` | name, description, grade_boundaries_json, is_default | `default()`, `withLevels()` |
| `RatingLevelFactory` | label, numeric_value, sort_order | `forScale($scaleId)` |
| `CategoryFactory` | name, polarity, weight, sort_order | `positive()`, `negative()` |
| `CriterionFactory` | name, weight, sort_order | `forCategory($categoryId)` |
| `AssessmentPeriodFactory` | name, start_date, end_date, deadline, status | `open()`, `closed()`, `locked()` |
| `AssessmentFactory` | period_id, teacher_id, class_section_id, status | `draft()`, `submitted()`, `reviewed()` |
| `AssessmentRatingFactory` | assessment_id, student_id, criterion_id, rating_level_id | — |
| `IncidentFactory` | student_id, reported_by, incident_type, severity, description | `positive()`, `negative()`, `critical()` |

### 8.6 Mock Strategy

| Concern | Strategy |
|---|---|
| SchoolSetup data | Create fixtures via DB inserts in `setUp()`: `sch_org_academic_sessions_jnt`, `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_employees`, `std_students` |
| Events | `Event::fake([AssessmentSubmitted::class, IncidentCreated::class])` for notification tests |
| Cache | `Cache::fake()` for score caching tests |
| Queue | `Queue::fake()` for `ComputeSchoolScoresJob` dispatch verification |
| DomPDF | Mock `Pdf::loadView()` → returns mock response in PDF generation tests |

### 8.7 Minimum Coverage Targets

- **Assessment FSM:** 100% of valid transitions tested + each invalid transition blocked
- **Score computation:** Each step tested individually (unit) + full computation (feature)
- **BR-BA-003 (locked period prevents edits):** Explicitly tested — attempt write on locked period → 403/validation error
- **BR-BA-008 (incident immutability):** Explicitly tested — attempt update core fields post-creation → rejected
- **BR-BA-019 (negative polarity inversion):** Explicitly tested — negative criterion with rating 2 on 5-point scale → inverted to 4
- **Multi-teacher averaging:** Edge cases with 1, 2, 3 teachers on same criterion
- **Result integration formula:** Verified with weightages 5%, 10%, 15%, 20%
- **Grade boundary edges:** 4.50 maps to A+ (not A); 3.49 maps to B+ (not A)

---

## Quality Gate Checklist

- [x] All 11 controllers listed with all methods (58 routes total)
- [x] All 5 services listed with 6+ method signatures each
- [x] All 17 FormRequests listed with key validation rules
- [x] All 15 FRs (BA-001 to BA-015) appear in at least one implementation phase
- [x] All 4 implementation phases have: FRs covered, files to create, test count
- [x] Score computation pseudocode present in Section 2 (BehaviouralScoreService)
- [x] Seeder execution order documented with dependency note
- [x] 9 Livewire components documented with purpose and key features
- [x] Route list consolidated with middleware and FR reference (58 routes)
- [x] View count per sub-module totals ~55
- [x] Test strategy includes `Event::fake()` and `Cache::fake()` guidance
- [x] BR-BA-003 (locked period prevents edits) test explicitly referenced
- [x] BR-BA-008 (incident immutability) test explicitly referenced
- [x] Result integration formula test with multiple weightage values explicitly referenced
- [x] BR-BA-019 (negative polarity inversion) test explicitly referenced

# Model Guide

## Model Location — Universal Rule

```
Modules/<ModuleName>/app/Models/<ModelName>.php
```

This applies to ALL modules — both prime and tenant.

## Namespace Pattern

```php
namespace Modules\<ModuleName>\Models;
```

## Standard Model Template

```php
<?php

namespace Modules\Hpc\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class LearningOutcomes extends Model
{
    use SoftDeletes;

    protected $table = 'hpc_learning_outcomes';

    protected $fillable = [
        'name',
        'description',
        'hpc_parameter_id',
        'is_active',
        'created_by',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'config_json' => 'array',       // for JSON columns
        'starts_at' => 'datetime',
    ];

    // Relationships
    public function parameter()
    {
        return $this->belongsTo(HpcParameters::class, 'hpc_parameter_id');
    }

    public function evaluations()
    {
        return $this->hasMany(StudentHpcEvaluation::class, 'learning_outcome_id');
    }
}
```

## Rules

1. Always define `$table` explicitly with correct prefix
2. Always define `$fillable` — never use `$guarded = []`
3. Always include `created_by` in `$fillable`
4. NEVER include `is_super_admin` or `remember_token` in `$fillable`
5. Always `use SoftDeletes`
6. Junction model names end in `Jnt` (e.g., `CircularGoalCompetencyJnt`)
7. Cast booleans, JSON, and dates in `$casts`

## Create via Artisan

```bash
php artisan module:make-model <ModelName> <ModuleName>
# Example:
php artisan module:make-model LearningOutcomes Hpc
# File created at: Modules/Hpc/app/Models/LearningOutcomes.php
```

## Model Counts per Module

```
SmartTimetable  -> 86 models (largest)
SchoolSetup     -> 42 models
Transport       -> 36 models
Library         -> 35 models
Prime           -> 27 models
Hpc             -> 26 models
StudentFee      -> 23 models
Syllabus        -> 22 models
QuestionBank    -> 17 models
StudentProfile  -> 14 models
Notification    -> 14 models
GlobalMaster    -> 12 models
Recommendation  -> 11 models
LmsExam         -> 11 models
Vendor          -> 8 models
Billing         -> 6 models
SyllabusBooks   -> 6 models
LmsQuiz         -> 6 models
Complaint       -> 6 models
Payment         -> 5 models
LmsHomework     -> 5 models
LmsQuests       -> 4 models
SystemConfig    -> 3 models
Documentation   -> 2 models
Scheduler       -> 2 models
```

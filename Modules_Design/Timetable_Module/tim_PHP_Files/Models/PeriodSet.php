<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class PeriodSet extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'tim_period_set';

    protected $fillable = [
        'code',
        'name',
        'description',
        'is_active'
    ];

    protected $casts = [
        'is_active' => 'boolean'
    ];

    public function periodSetPeriods()
    {
        return $this->hasMany(PeriodSetPeriod::class, 'period_set_id');
    }

    public function classModeRules()
    {
        return $this->hasMany(ClassModeRule::class, 'period_set_id');
    }

    public function generationRuns()
    {
        return $this->hasMany(GenerationRun::class, 'period_set_id');
    }
}
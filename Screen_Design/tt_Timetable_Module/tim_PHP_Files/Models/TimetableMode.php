<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class TimetableMode extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'tim_timetable_mode';

    protected $fillable = [
        'code',
        'name',
        'description',
        'has_exam',
        'has_teaching',
        'is_active'
    ];

    protected $casts = [
        'has_exam' => 'boolean',
        'has_teaching' => 'boolean',
        'is_active' => 'boolean'
    ];

    public function classModeRules()
    {
        return $this->hasMany(ClassModeRule::class, 'mode_id');
    }

    public function generationRuns()
    {
        return $this->hasMany(GenerationRun::class, 'mode_id');
    }
}
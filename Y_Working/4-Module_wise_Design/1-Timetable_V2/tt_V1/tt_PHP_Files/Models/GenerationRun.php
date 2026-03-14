<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GenerationRun extends Model
{
    use HasFactory;

    protected $table = 'tim_generation_run';

    protected $fillable = [
        'mode_id',
        'period_set_id',
        'academic_session_id',
        'started_at',
        'finished_at',
        'status',
        'params_json',
        'stats_json'
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'finished_at' => 'datetime',
        'params_json' => 'array',
        'stats_json' => 'array'
    ];

    public function timetableMode()
    {
        return $this->belongsTo(TimetableMode::class, 'mode_id');
    }

    public function periodSet()
    {
        return $this->belongsTo(PeriodSet::class, 'period_set_id');
    }

    public function timetableCells()
    {
        return $this->hasMany(TimetableCell::class, 'generation_run_id');
    }
}
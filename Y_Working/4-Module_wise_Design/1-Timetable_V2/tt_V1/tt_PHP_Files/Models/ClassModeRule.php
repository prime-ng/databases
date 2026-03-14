<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class ClassModeRule extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'tim_class_mode_rule';

    protected $fillable = [
        'class_id',
        'mode_id',
        'period_set_id',
        'allow_teaching_periods',
        'allow_exam_periods',
        'exam_period_count',
        'teaching_after_exam_flag',
        'is_active'
    ];

    protected $casts = [
        'allow_teaching_periods' => 'boolean',
        'allow_exam_periods' => 'boolean',
        'exam_period_count' => 'integer',
        'teaching_after_exam_flag' => 'boolean',
        'is_active' => 'boolean'
    ];

    public function timetableMode()
    {
        return $this->belongsTo(TimetableMode::class, 'mode_id');
    }

    public function periodSet()
    {
        return $this->belongsTo(PeriodSet::class, 'period_set_id');
    }

    public function schoolClass()
    {
        return $this->belongsTo(SchoolClass::class, 'class_id');
    }
}
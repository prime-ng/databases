<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class TimetableCell extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'tt_timetable_cell';

    protected $fillable = [
        'generation_run_id',
        'class_group_id',
        'class_subgroup_id',
        'date',
        'period_ord',
        'room_id',
        'locked',
        'source',
        'is_active'
    ];

    protected $casts = [
        'date' => 'date',
        'period_ord' => 'integer',
        'locked' => 'boolean',
        'is_active' => 'boolean'
    ];

    public function generationRun()
    {
        return $this->belongsTo(GenerationRun::class, 'generation_run_id');
    }

    public function classGroup()
    {
        return $this->belongsTo(ClassGroup::class, 'class_group_id');
    }

    public function classSubgroup()
    {
        return $this->belongsTo(ClassSubgroup::class, 'class_subgroup_id');
    }

    public function room()
    {
        return $this->belongsTo(Room::class, 'room_id');
    }

    public function teachers()
    {
        return $this->belongsToMany(
            User::class,
            'tim_timetable_cell_teacher',
            'cell_id',
            'teacher_id'
        )->withPivot('assignment_role_id');
    }

    public function substitutionLogs()
    {
        return $this->hasMany(SubstitutionLog::class, 'cell_id');
    }
}
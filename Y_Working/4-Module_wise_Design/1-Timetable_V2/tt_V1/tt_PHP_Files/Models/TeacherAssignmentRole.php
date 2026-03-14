<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class TeacherAssignmentRole extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'tim_teacher_assignment_role';

    protected $fillable = [
        'code',
        'name',
        'description',
        'is_primary_instructor',
        'counts_for_workload',
        'allows_overlap',
        'is_active'
    ];

    protected $casts = [
        'is_primary_instructor' => 'boolean',
        'counts_for_workload' => 'boolean',
        'allows_overlap' => 'boolean',
        'is_active' => 'boolean'
    ];

    public function timetableCellTeachers()
    {
        return $this->hasMany(TimetableCellTeacher::class, 'assignment_role_id');
    }
}
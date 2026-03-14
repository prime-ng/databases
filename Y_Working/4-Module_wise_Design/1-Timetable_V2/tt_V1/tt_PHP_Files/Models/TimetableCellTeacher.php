<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TimetableCellTeacher extends Model
{
    use HasFactory;

    protected $table = 'tim_timetable_cell_teacher';

    public $timestamps = false;

    protected $fillable = [
        'cell_id',
        'teacher_id',
        'assignment_role_id'
    ];

    public function timetableCell()
    {
        return $this->belongsTo(TimetableCell::class, 'cell_id');
    }

    public function teacher()
    {
        return $this->belongsTo(User::class, 'teacher_id');
    }

    public function assignmentRole()
    {
        return $this->belongsTo(TeacherAssignmentRole::class, 'assignment_role_id');
    }
}
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SubstitutionLog extends Model
{
    use HasFactory;

    protected $table = 'tim_substitution_log';

    protected $fillable = [
        'cell_id',
        'absent_teacher_id',
        'substitute_teacher_id',
        'substituted_at',
        'reason'
    ];

    protected $casts = [
        'substituted_at' => 'datetime'
    ];

    public function timetableCell()
    {
        return $this->belongsTo(TimetableCell::class, 'cell_id');
    }

    public function absentTeacher()
    {
        return $this->belongsTo(User::class, 'absent_teacher_id');
    }

    public function substituteTeacher()
    {
        return $this->belongsTo(User::class, 'substitute_teacher_id');
    }
}
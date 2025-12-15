<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class PeriodType extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'tim_period_type';

    protected $fillable = [
        'code',
        'name',
        'description',
        'counts_as_teaching',
        'counts_as_exam',
        'is_active'
    ];

    protected $casts = [
        'counts_as_teaching' => 'boolean',
        'counts_as_exam' => 'boolean',
        'is_active' => 'boolean'
    ];

    public function periodSetPeriods()
    {
        return $this->hasMany(PeriodSetPeriod::class, 'period_type_id');
    }
}
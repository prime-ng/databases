<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class PeriodSetPeriod extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'tim_period_set_period';

    protected $fillable = [
        'period_set_id',
        'period_ord',
        'code',
        'name',
        'start_time',
        'end_time',
        'period_type_id',
        'is_active'
    ];

    protected $casts = [
        'period_ord' => 'integer',
        'start_time' => 'datetime:H:i:s',
        'end_time' => 'datetime:H:i:s',
        'is_active' => 'boolean'
    ];

    public function periodSet()
    {
        return $this->belongsTo(PeriodSet::class, 'period_set_id');
    }

    public function periodType()
    {
        return $this->belongsTo(PeriodType::class, 'period_type_id');
    }
}
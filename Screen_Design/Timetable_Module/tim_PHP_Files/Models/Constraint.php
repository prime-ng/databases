<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Constraint extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'tim_constraint';

    protected $fillable = [
        'target_type',
        'target_id',
        'is_hard',
        'weight',
        'rule_json',
        'is_active'
    ];

    protected $casts = [
        'is_hard' => 'boolean',
        'weight' => 'integer',
        'rule_json' => 'array',
        'is_active' => 'boolean'
    ];

    public function target()
    {
        switch ($this->target_type) {
            case 'TEACHER':
                return $this->belongsTo(User::class, 'target_id');
            case 'CLASS_GROUP':
                return $this->belongsTo(ClassGroup::class, 'target_id');
            case 'ROOM':
                return $this->belongsTo(Room::class, 'target_id');
            default:
                return null;
        }
    }
}
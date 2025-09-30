<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BenchmarkData extends Model
{
    use HasFactory;

    protected $table = 'benchmark_data';

    protected $fillable = [
        'name',
        'value',
        'metadata',
        'status',
    ];

    protected $casts = [
        'value' => 'array',
        'metadata' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}

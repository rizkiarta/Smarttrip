<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ReviewLike extends Model
{
    public $timestamps = false;
    protected $fillable = ['user_id', 'review_id'];

    protected function casts(): array
    {
        return ['created_at' => 'datetime'];
    }
}

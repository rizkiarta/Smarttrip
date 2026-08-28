<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Review extends Model
{
    protected $fillable = [
        'user_id', 'destination_id', 'rating', 'review_text', 'likes_count',
    ];

    protected function casts(): array
    {
        return [
            'rating'      => 'integer',
            'likes_count' => 'integer',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function destination()
    {
        return $this->belongsTo(Destination::class);
    }

    public function photos()
    {
        return $this->hasMany(ReviewPhoto::class);
    }

    public function likes()
    {
        return $this->hasMany(ReviewLike::class);
    }

    public function isLikedBy(int $userId): bool
    {
        return $this->likes()->where('user_id', $userId)->exists();
    }
}

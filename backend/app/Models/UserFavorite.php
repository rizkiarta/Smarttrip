<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserFavorite extends Model
{
    public $timestamps = false;
    protected $fillable = ['user_id', 'destination_id'];

    protected function casts(): array
    {
        return ['created_at' => 'datetime'];
    }

    public function destination()
    {
        return $this->belongsTo(Destination::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

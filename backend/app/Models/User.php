<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name', 'username', 'email', 'google_id', 'facebook_id', 'phone',
        'password', 'bio', 'birth_date', 'photo_url', 'language',
    ];



    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return [
            'birth_date'        => 'date',
            'password'          => 'hashed',
        ];
    }

    // Relations
    public function itineraries()
    {
        return $this->hasMany(Itinerary::class);
    }

    public function favorites()
    {
        return $this->hasMany(UserFavorite::class);
    }

    public function favoriteDestinations()
    {
        return $this->belongsToMany(Destination::class, 'user_favorites');
    }

    public function reviews()
    {
        return $this->hasMany(Review::class);
    }

    public function notificationSetting()
    {
        return $this->hasOne(NotificationSetting::class);
    }

    public function deviceTokens()
    {
        return $this->hasMany(DeviceToken::class);
    }

    public function notifications()
    {
        return $this->hasMany(UserNotification::class);
    }
}


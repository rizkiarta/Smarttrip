<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NotificationSetting extends Model
{
    protected $fillable = [
        'user_id', 'crowd_alerts', 'recommendation_alerts',
        'itinerary_reminders', 'promo_alerts',
    ];

    protected function casts(): array
    {
        return [
            'crowd_alerts'          => 'boolean',
            'recommendation_alerts' => 'boolean',
            'itinerary_reminders'   => 'boolean',
            'promo_alerts'          => 'boolean',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

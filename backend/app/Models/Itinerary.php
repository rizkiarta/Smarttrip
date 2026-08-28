<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Itinerary extends Model
{
    protected $fillable = [
        'user_id', 'title', 'start_date', 'end_date',
        'participants_count', 'vehicle_type',
        'start_location', 'start_latitude', 'start_longitude',
        'departure_time', 'destination_city',
    ];

    protected function casts(): array
    {
        return [
            'start_date'       => 'date',
            'end_date'         => 'date',
            'start_latitude'   => 'float',
            'start_longitude'  => 'float',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function days()
    {
        return $this->hasMany(ItineraryDay::class)->orderBy('day_number');
    }

    /**
     * True kalau minimal satu hari sudah ditandai selesai.
     * Dipakai HistoryScreen untuk filter "has_history".
     */
    public function hasAnyCompletedDay(): bool
    {
        return $this->days()->where('is_completed', true)->exists();
    }
}

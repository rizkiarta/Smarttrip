<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ItineraryItem extends Model
{
    protected $fillable = [
        'itinerary_day_id', 'destination_id',
        'sort_order', 'arrival_time', 'departure_time', 'notes',
    ];

    public function itineraryDay()
    {
        return $this->belongsTo(ItineraryDay::class);
    }

    public function destination()
    {
        return $this->belongsTo(Destination::class);
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ItineraryDay extends Model
{
    protected $fillable = ['itinerary_id', 'day_number', 'is_completed'];

    protected function casts(): array
    {
        return ['is_completed' => 'boolean'];
    }

    public function itinerary()
    {
        return $this->belongsTo(Itinerary::class);
    }

    public function items()
    {
        return $this->hasMany(ItineraryItem::class)->orderBy('sort_order');
    }
}

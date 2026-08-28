<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DestinationGalleryImage extends Model
{
    protected $fillable = ['destination_id', 'image_url', 'sort_order'];

    public function destination()
    {
        return $this->belongsTo(Destination::class);
    }
}

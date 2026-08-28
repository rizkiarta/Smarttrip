<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Destination extends Model
{
    // PK adalah string slug (mis: 'pulau_pahawang')
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'id', 'name', 'location', 'category', 'description',
        'latitude', 'longitude', 'rating_avg', 'reviews_count',
        'main_image', 'price_range', 'open_hour', 'close_hour',
        'visit_duration_hours',
    ];

    protected function casts(): array
    {
        return [
            'latitude'              => 'float',
            'longitude'             => 'float',
            'rating_avg'            => 'float',
            'reviews_count'         => 'integer',
            'open_hour'             => 'integer',
            'close_hour'            => 'integer',
            'visit_duration_hours'  => 'float',
        ];
    }

    // Relations
    public function galleryImages()
    {
        return $this->hasMany(DestinationGalleryImage::class)->orderBy('sort_order');
    }

    public function reviews()
    {
        return $this->hasMany(Review::class);
    }

    public function favoritedByUsers()
    {
        return $this->belongsToMany(User::class, 'user_favorites');
    }

    // Recalculate rating average from reviews
    public function recalculateRating(): void
    {
        $avg = $this->reviews()->avg('rating') ?? 0;
        $count = $this->reviews()->count();
        $this->update([
            'rating_avg'    => round($avg, 1),
            'reviews_count' => $count,
        ]);
    }

    /**
     * Flexible lookup by ID, Name, Slug, or partial keywords (e.g. 'Curug 7' -> 'air_terjun_curug_tujuh')
     */
    public static function findFlexible(string $id): ?self
    {
        $id = trim($id);
        if (empty($id)) return null;

        // 1. Direct match by ID or exact Name
        $dest = self::where('id', $id)->orWhere('name', $id)->first();
        if ($dest) return $dest;

        // 2. Match by slug (underscore or hyphen)
        $slugUnderscore = \Illuminate\Support\Str::slug($id, '_');
        $slugHyphen = \Illuminate\Support\Str::slug($id, '-');
        $dest = self::where('id', $slugUnderscore)
            ->orWhere('id', $slugHyphen)
            ->first();
        if ($dest) return $dest;

        // 3. Convert numbers to Indonesian words (7 -> tujuh)
        $numMap = ['1' => 'satu', '2' => 'dua', '3' => 'tiga', '4' => 'empat', '5' => 'lima', '6' => 'enam', '7' => 'tujuh', '8' => 'delapan', '9' => 'sembilan'];
        $altId = $id;
        foreach ($numMap as $num => $word) {
            $altId = preg_replace("/\b{$num}\b/u", $word, $altId);
        }
        if ($altId !== $id) {
            $dest = self::where('name', 'LIKE', "%{$altId}%")
                ->orWhere('id', \Illuminate\Support\Str::slug($altId, '_'))
                ->orWhere('id', \Illuminate\Support\Str::slug($altId, '-'))
                ->first();
            if ($dest) return $dest;
        }

        // 4. Loose LIKE search on all words
        $cleanId = \Illuminate\Support\Str::slug(str_replace(['_', '-'], ' ', $id), ' ');
        $words = array_filter(explode(' ', $cleanId), fn($w) => strlen($w) >= 2);
        if (!empty($words)) {
            $query = self::query();
            foreach ($words as $word) {
                $query->where(function ($q) use ($word) {
                    $q->where('name', 'LIKE', "%{$word}%")
                      ->orWhere('id', 'LIKE', "%{$word}%");
                });
            }
            $dest = $query->first();
            if ($dest) return $dest;

            // Fallback: search by significant words
            foreach ($words as $word) {
                if (in_array($word, ['terjun', 'air', 'wisata', 'taman', 'danau', 'pantai', 'bukit', 'desa'])) continue;
                $dest = self::where('name', 'LIKE', "%{$word}%")
                    ->orWhere('id', 'LIKE', "%{$word}%")
                    ->first();
                if ($dest) return $dest;
            }
        }

        return null;
    }
}

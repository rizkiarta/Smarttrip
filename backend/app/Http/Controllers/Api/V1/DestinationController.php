<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Destination;
use App\Traits\ResolvesPhotoUrl;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class DestinationController extends Controller
{
    use ResolvesPhotoUrl;
    /**
     * List destinasi dengan Cache, filter, search & paginasi.
     */
    public function index(Request $request): JsonResponse
    {
        $search     = $request->query('search');
        $category   = $request->query('category');
        $location   = $request->query('location');
        $sort       = $request->query('sort', 'name');
        $perPageRaw = $request->query('per_page', '500');
        $perPage    = ($perPageRaw === 'all') ? 500 : max(1, min((int) $perPageRaw, 500));
        $page       = (int) $request->query('page', 1);



        $cacheKey = 'destinations_array_' . md5("{$search}_{$category}_{$location}_{$sort}_{$perPage}_{$page}");

        $response = Cache::remember($cacheKey, 3600, function () use ($search, $category, $location, $sort, $perPage) {
            $query = Destination::with('galleryImages');

            if ($search) {
                $query->where(function ($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('location', 'like', "%{$search}%");
                });
            }

            if ($category) {
                $query->where('category', $category);
            }

            if ($location) {
                $query->where('location', 'like', "%{$location}%");
            }

            $sortMap = [
                'rating'        => ['rating_avg', 'desc'],
                'reviews_count' => ['reviews_count', 'desc'],
                'name'          => ['name', 'asc'],
            ];
            [$sortCol, $sortDir] = $sortMap[$sort] ?? ['name', 'asc'];
            $query->orderBy($sortCol, $sortDir);

            $results = $query->paginate($perPage);

            $items = [];
            foreach ($results->items() as $d) {
                $items[] = $this->formatDestination($d);
            }

            return [
                'data'  => $items,
                'meta'  => [
                    'current_page' => $results->currentPage(),
                    'last_page'    => $results->lastPage(),
                    'per_page'     => $results->perPage(),
                    'total'        => $results->total(),
                ],
            ];
        });

        return response()->json($response);
    }

    /**
     * Detail satu destinasi + galeri + review terbaru.
     */
    public function show(string $id): JsonResponse
    {
        $destination = Destination::findFlexible($id);

        if (!$destination) {
            return response()->json(['message' => 'Destinasi tidak ditemukan.'], 404);
        }

        $destination->load([
            'galleryImages',
            'reviews.user',
            'reviews.photos',
        ]);

        $userId = auth('sanctum')->id();
        $formatted['reviews'] = $destination->reviews->map(fn($r) => [
            'id'          => $r->id,
            'user_name'   => $r->user?->name ?? 'Pengguna SmartTrip',
            'user_avatar' => $r->user?->photo_url ? $this->resolvePhotoUrl($r->user->photo_url) : null,
            'rating'      => $r->rating,
            'review_text' => $r->review_text,
            'likes_count' => $r->likes_count,
            'liked'       => $userId ? $r->isLikedBy($userId) : false,
            'photos'      => $r->photos->pluck('photo_url')->map(fn($p) => $this->resolvePhotoUrl($p))->values()->toArray(),
            'created_at'  => $r->created_at?->diffForHumans(),
        ])->values()->toArray();

        return response()->json(['data' => $formatted]);
    }

    /**
     * List kategori destinasi unik dengan Cache.
     */
    public function categories(): JsonResponse
    {
        $cacheKey = 'destination_categories_arr';

        $categories = Cache::remember($cacheKey, 86400, function () {
            return Destination::select('category')
                ->distinct()
                ->pluck('category')
                ->filter()
                ->values()
                ->toArray();
        });

        return response()->json(['data' => $categories]);
    }

    private function formatDestination(Destination $d): array
    {
        return [
            'id'                   => $d->id,
            'name'                 => $d->name,
            'location'             => $d->location,
            'category'             => $d->category,
            'description'          => $d->description,
            'latitude'             => $d->latitude,
            'longitude'            => $d->longitude,
            'rating'               => $d->rating_avg,
            'reviews_count'        => $d->reviews_count,
            'main_image'           => $d->main_image ? $this->resolvePhotoUrl($d->main_image) : null,
            'price_range'          => $d->price_range,
            'open_hour'            => $d->open_hour,
            'close_hour'           => $d->close_hour,
            'visit_duration_hours' => $d->visit_duration_hours,
            'gallery'              => $d->galleryImages
                ->map(fn($g) => $this->resolvePhotoUrl($g->image_url))
                ->values()
                ->toArray(),
        ];
    }
}

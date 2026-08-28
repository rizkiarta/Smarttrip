<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Destination;
use App\Models\Review;
use App\Models\ReviewPhoto;
use App\Models\ReviewLike;
use App\Traits\ResolvesPhotoUrl;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class ReviewController extends Controller
{
    use ResolvesPhotoUrl;
    /**
     * Daftar review per destinasi (publik).
     */
    public function indexByDestination(Request $request, string $id): JsonResponse
    {
        $destination = Destination::findFlexible($id);

        if (!$destination) {
            return response()->json([
                'data' => [],
                'meta' => ['current_page' => 1, 'last_page' => 1, 'total' => 0],
            ]);
        }

        $perPage = (int) $request->query('per_page', 20);
        $perPage = max(1, min($perPage, 100));

        $reviews = Review::where('destination_id', $destination->id)
            ->with(['user', 'photos'])
            ->latest()
            ->paginate($perPage);

        return response()->json([
            'data' => $reviews->map(fn ($r) => $this->formatReview($r)),
            'meta' => [
                'current_page' => $reviews->currentPage(),
                'last_page'    => $reviews->lastPage(),
                'total'        => $reviews->total(),
                'per_page'     => $reviews->perPage(),
            ],
        ]);
    }

    /**
     * Buat review baru + upload foto (max 5 foto).
     */
    public function store(Request $request, string $id): JsonResponse
    {
        $destination = Destination::findFlexible($id);

        if (!$destination) {
            return response()->json(['message' => 'Destinasi tidak ditemukan.'], 404);
        }

        try {
            $validated = $request->validate([
                'rating'      => 'required|integer|min:1|max:5',
                'review_text' => 'nullable|string|max:2000',
                'photos'      => 'nullable|array|max:5',
                'photos.*'    => 'nullable|image|mimes:jpeg,png,jpg,webp|max:8192',
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'message' => 'Data tidak valid.',
                'errors'  => $e->errors(),
            ], 422);
        }

        $reviewText = trim($request->input('review_text') ?? '');
        if (empty($reviewText)) {
            $reviewText = null; // null lebih bersih daripada fallback text
        }

        try {
            $review = DB::transaction(function () use ($request, $destination, $reviewText) {
                $review = Review::create([
                    'user_id'        => $request->user()->id,
                    'destination_id' => $destination->id,
                    'rating'         => (int) $request->rating,
                    'review_text'    => $reviewText,
                    'likes_count'    => 0,
                ]);

                // Upload foto baru
                $photoFiles = $request->file('photos') ?? [];
                // Support both photos[] and photos
                if (empty($photoFiles) && $request->hasFile('photos')) {
                    $photoFiles = $request->file('photos');
                    if (!is_array($photoFiles)) {
                        $photoFiles = [$photoFiles];
                    }
                }

                foreach ($photoFiles as $photo) {
                    if (!$photo || !$photo->isValid()) continue;
                    $ext = $photo->getClientOriginalExtension() ?: 'jpg';
                    $allowedExts = ['jpg', 'jpeg', 'png', 'webp'];
                    if (!in_array(strtolower($ext), $allowedExts)) continue;
                    $filename = 'reviews/' . $review->id . '_' . Str::random(12) . '.' . $ext;
                    $photo->storeAs('', $filename, 'public');
                    ReviewPhoto::create(['review_id' => $review->id, 'photo_url' => $filename]);
                }

                // Rekalkulasi rating destinasi
                $destination->recalculateRating();

                return $review;
            });

            // Load relasi setelah transaksi
            $review->load(['user', 'photos']);

            return response()->json([
                'message' => 'Ulasan berhasil disimpan.',
                'data'    => $this->formatReview($review),
            ], 201);
        } catch (\Exception $e) {
            Log::error('ReviewController::store error', [
                'destination_id' => $destination->id,
                'user_id'        => $request->user()->id,
                'error'          => $e->getMessage(),
                'trace'          => $e->getTraceAsString(),
            ]);
            return response()->json([
                'message' => 'Gagal menyimpan ulasan. Silakan coba lagi.',
            ], 500);
        }
    }

    /**
     * Semua review yang ditulis user yang sedang login (Ulasan Saya).
     */
    public function myReviews(Request $request): JsonResponse
    {
        try {
            $reviews = $request->user()
                ->reviews()
                ->with(['destination', 'photos'])
                ->latest()
                ->get();

            return response()->json([
                'data' => $reviews->map(fn ($r) => array_merge(
                    $this->formatReview($r),
                    ['destination_name' => $r->destination?->name ?? 'Destinasi']
                )),
            ]);
        } catch (\Exception $e) {
            Log::error('ReviewController::myReviews error: ' . $e->getMessage());
            return response()->json(['data' => []], 200);
        }
    }

    /**
     * Toggle like/unlike sebuah review.
     */
    public function toggleLike(Request $request, int $id): JsonResponse
    {
        try {
            $review = Review::findOrFail($id);
            $userId = $request->user()->id;

            DB::transaction(function () use ($review, $userId, &$liked) {
                $existing = ReviewLike::where('user_id', $userId)
                    ->where('review_id', $review->id)
                    ->lockForUpdate()
                    ->first();

                if ($existing) {
                    $existing->delete();
                    $review->decrement('likes_count');
                    $liked = false;
                } else {
                    ReviewLike::create(['user_id' => $userId, 'review_id' => $review->id]);
                    $review->increment('likes_count');
                    $liked = true;
                }
            });

            // Production Notifikasi jika ada user lain menyukai ulasan
            if ($liked && $review->user_id && $review->user_id !== $userId) {
                $author = \App\Models\User::find($review->user_id);
                if ($author) {
                    $destName = $review->destination?->name ?? 'Destinasi';
                    \App\Services\FcmService::sendToUser(
                        $author,
                        'Ulasan Anda Disukai',
                        "Seseorang menyukai ulasan Anda tentang {$destName}.",
                        ['review_id' => (string)$review->id, 'action' => 'open_review'],
                        'system',
                        'thumb_up'
                    );
                }
            }

            return response()->json([
                'liked'       => $liked,
                'likes_count' => $review->fresh()->likes_count,
            ]);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json(['message' => 'Ulasan tidak ditemukan.'], 404);
        } catch (\Exception $e) {
            Log::error('ReviewController::toggleLike error: ' . $e->getMessage());
            return response()->json(['message' => 'Gagal memproses like. Silakan coba lagi.'], 500);
        }
    }

    private function formatReview(Review $r): array
    {
        $userId = auth('sanctum')->id();
        return [
            'id'          => $r->id,
            'user_id'     => $r->user_id,
            'user_name'   => $r->user?->name ?? 'Pengguna SmartTrip',
            'user_avatar' => $this->resolvePhotoUrl($r->user?->photo_url),
            'rating'      => $r->rating,
            'review_text' => $r->review_text ?? '',
            'likes_count' => (int) ($r->likes_count ?? 0),
            'liked'       => $userId ? $r->isLikedBy($userId) : false,
            'photos'      => $r->photos
                ? $r->photos
                    ->map(fn ($p) => $this->resolvePhotoUrl($p->photo_url))
                    ->filter()
                    ->values()
                    ->toArray()
                : [],
            'created_at'  => $r->created_at?->diffForHumans() ?? '',
        ];
    }
}

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Destination;
use App\Models\UserFavorite;
use App\Traits\ResolvesPhotoUrl;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class FavoriteController extends Controller
{
    use ResolvesPhotoUrl;

    /**
     * Daftar destinasi favorit user yang sedang login.
     */
    public function index(Request $request): JsonResponse
    {
        $favorites = $request->user()
            ->favoriteDestinations()
            ->with('galleryImages')
            ->get();

        return response()->json([
            'data' => $favorites->map(fn($d) => [
                'id'          => $d->id,
                'name'        => $d->name,
                'location'    => $d->location,
                'category'    => $d->category,
                'rating'      => $d->rating_avg,
                'reviews'     => $d->reviews_count . ' review',
                'main_image'  => $this->resolvePhotoUrl($d->main_image),
            ]),
        ]);
    }

    /**
     * Toggle favorit — tambah jika belum ada, hapus jika sudah ada.
     */
    public function toggle(Request $request, string $destination_id): JsonResponse
    {
        $destination = Destination::findOrFail($destination_id);
        $userId      = $request->user()->id;

        $existing = UserFavorite::where('user_id', $userId)
            ->where('destination_id', $destination_id)
            ->first();

        if ($existing) {
            $existing->delete();
            $saved = false;
        } else {
            UserFavorite::create([
                'user_id'        => $userId,
                'destination_id' => $destination_id,
            ]);
            $saved = true;

            // Trigger notifikasi real-time produksi untuk destinasi favorit
            \App\Services\FcmService::sendFavoriteDestinationCrowdUpdate(
                $request->user(),
                $destination->name,
                'sepi'
            );
        }

        return response()->json([
            'saved'          => $saved,
            'destination_id' => $destination_id,
            'message'        => $saved
                ? "'{$destination->name}' ditambahkan ke favorit."
                : "'{$destination->name}' dihapus dari favorit.",
        ]);
    }
}

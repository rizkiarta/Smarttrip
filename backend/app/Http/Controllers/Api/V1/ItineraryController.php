<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Destination;
use App\Models\Itinerary;
use App\Models\ItineraryDay;
use App\Models\ItineraryItem;
use App\Traits\ResolvesPhotoUrl;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class ItineraryController extends Controller
{
    use ResolvesPhotoUrl;
    /**
     * Daftar itinerary milik user.
     *
     * ?status=active   — hanya yang belum semua harinya selesai
     * ?status=history  — yang minimal 1 hari sudah selesai
     */
    public function index(Request $request): JsonResponse
    {
        $query = Itinerary::where('user_id', $request->user()->id)
            ->with(['days.items.destination'])
            ->orderBy('start_date', 'desc');

        $status = $request->query('status');
        if ($status === 'history') {
            $query->whereHas('days', fn($q) => $q->where('is_completed', true));
        } elseif ($status === 'active') {
            $query->whereHas('days', fn($q) => $q->where('is_completed', false));
        }

        $itineraries = $query->get();

        return response()->json([
            'data' => $itineraries->map(fn($i) => $this->formatItinerary($i)),
        ]);
    }

    /**
     * Buat itinerary baru.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $this->validatePayload($request);

        $itinerary = DB::transaction(function () use ($request, $validated) {
            $itinerary = Itinerary::create([
                'user_id'            => $request->user()->id,
                'title'              => $validated['title'],
                'start_date'         => $validated['start_date'],
                'end_date'           => $validated['end_date'],
                'participants_count' => $validated['participants_count'] ?? 1,
                'vehicle_type'       => $validated['vehicle_type'] ?? null,
                'start_location'     => $validated['start_location'] ?? null,
                'start_latitude'     => $validated['start_latitude'] ?? null,
                'start_longitude'    => $validated['start_longitude'] ?? null,
                'departure_time'     => $validated['departure_time'] ?? null,
                'destination_city'   => $validated['destination_city'] ?? null,
            ]);

            $this->saveDays($itinerary, $validated['days'] ?? []);

            return $itinerary;
        });

        // Trigger notifikasi produksi saat rencana perjalanan baru dibuat
        \App\Services\FcmService::sendToUser(
            $request->user(),
            'Rencana Perjalanan Disimpan',
            "Rencana perjalanan {$itinerary->title} berhasil disimpan. Siapkan perlengkapan perjalanan Anda.",
            ['itinerary_id' => (string)$itinerary->id, 'action' => 'open_itinerary'],
            'itinerary',
            'route'
        );

        return response()->json([
            'message' => 'Itinerary berhasil disimpan.',
            'data'    => $this->formatItinerary($itinerary->load('days.items.destination')),
        ], 201);
    }

    /**
     * Detail satu itinerary.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $itinerary = Itinerary::where('user_id', $request->user()->id)
            ->with(['days.items.destination.galleryImages'])
            ->findOrFail($id);

        return response()->json([
            'data' => $this->formatItinerary($itinerary),
        ]);
    }

    /**
     * Update itinerary (in-place, replace semua days & items).
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $itinerary = Itinerary::where('user_id', $request->user()->id)->findOrFail($id);
        $validated = $this->validatePayload($request);

        DB::transaction(function () use ($itinerary, $validated) {
            $itinerary->update([
                'title'              => $validated['title'],
                'start_date'         => $validated['start_date'],
                'end_date'           => $validated['end_date'],
                'participants_count' => $validated['participants_count'] ?? $itinerary->participants_count,
                'vehicle_type'       => $validated['vehicle_type'] ?? $itinerary->vehicle_type,
                'start_location'     => $validated['start_location'] ?? $itinerary->start_location,
                'start_latitude'     => $validated['start_latitude'] ?? $itinerary->start_latitude,
                'start_longitude'    => $validated['start_longitude'] ?? $itinerary->start_longitude,
                'departure_time'     => $validated['departure_time'] ?? $itinerary->departure_time,
                'destination_city'   => $validated['destination_city'] ?? $itinerary->destination_city,
            ]);

            // Replace semua days & items (simpel, tidak perlu diff)
            $itinerary->days()->each(fn($day) => $day->items()->delete());
            $itinerary->days()->delete();
            $this->saveDays($itinerary, $validated['days'] ?? []);
        });

        return response()->json([
            'message' => 'Itinerary berhasil diperbarui.',
            'data'    => $this->formatItinerary($itinerary->load('days.items.destination')),
        ]);
    }

    /**
     * Hapus itinerary.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $itinerary = Itinerary::where('user_id', $request->user()->id)->findOrFail($id);
        $itinerary->delete();

        return response()->json(['message' => 'Itinerary berhasil dihapus.']);
    }

    /**
     * Tandai satu hari sebagai selesai.
     * PATCH /itineraries/{id}/days/{day}/complete
     */
    public function markDayComplete(Request $request, int $id, int $day): JsonResponse
    {
        $itinerary = Itinerary::where('user_id', $request->user()->id)->findOrFail($id);

        $itineraryDay = $itinerary->days()->where('day_number', $day)->firstOrFail();
        $itineraryDay->update(['is_completed' => true]);

        // Trigger notifikasi push saat hari perjalanan diselesaikan
        \App\Services\FcmService::sendToUser(
            $request->user(),
            'Progress Perjalanan',
            "Selamat! Hari ke-{$day} untuk rencana perjalanan {$itinerary->title} telah diselesaikan.",
            ['itinerary_id' => (string)$itinerary->id, 'action' => 'open_itinerary'],
            'itinerary',
            'check_circle'
        );

        return response()->json([
            'message'    => "Hari {$day} ditandai selesai.",
            'day_number' => $day,
            'completed'  => true,
        ]);
    }

    // ================================================================
    // PRIVATE HELPERS
    // ================================================================

    private function validatePayload(Request $request): array
    {
        // 1. Sanitize start_date & end_date (e.g. "2026-08-25 00:00:00.000" -> "2026-08-25")
        if ($request->has('start_date') && !empty($request->start_date)) {
            $request->merge([
                'start_date' => date('Y-m-d', strtotime((string)$request->start_date))
            ]);
        }
        if ($request->has('end_date') && !empty($request->end_date)) {
            $request->merge([
                'end_date' => date('Y-m-d', strtotime((string)$request->end_date))
            ]);
        }

        // 2. Sanitize items arrival_time/departure_time & ensure destination exists in DB
        if ($request->has('days') && is_array($request->days)) {
            $rawDays = $request->days;
            $cleanDays = [];

            foreach ($rawDays as $day) {
                $cleanDay = is_array($day) ? $day : [];
                if (isset($cleanDay['items']) && is_array($cleanDay['items'])) {
                    $cleanItems = [];
                    foreach ($cleanDay['items'] as $item) {
                        $cleanItem = is_array($item) ? $item : [];

                        if (!empty($cleanItem['arrival_time'])) {
                            $cleanItem['arrival_time'] = date('H:i', strtotime((string)$cleanItem['arrival_time']));
                        } else {
                            $cleanItem['arrival_time'] = null;
                        }

                        if (!empty($cleanItem['departure_time'])) {
                            $cleanItem['departure_time'] = date('H:i', strtotime((string)$cleanItem['departure_time']));
                        } else {
                            $cleanItem['departure_time'] = null;
                        }

                        if (!empty($cleanItem['destination_id'])) {
                            $destId = (string)$cleanItem['destination_id'];
                            Destination::firstOrCreate(
                                ['id' => $destId],
                                [
                                    'name' => ucwords(str_replace('_', ' ', $destId)),
                                    'location' => 'Lampung',
                                    'category' => 'Wisata',
                                    'rating_avg' => 4.5,
                                    'reviews_count' => 10,
                                    'main_image' => 'destinations/' . $destId . '.jpg',
                                ]
                            );
                        }

                        $cleanItems[] = $cleanItem;
                    }
                    $cleanDay['items'] = $cleanItems;
                }
                $cleanDays[] = $cleanDay;
            }

            $request->merge(['days' => $cleanDays]);
        }


        return $request->validate([
            'title'              => 'required|string|max:200',
            'start_date'         => 'required|date',
            'end_date'           => 'required|date|after_or_equal:start_date',
            'participants_count' => 'nullable|integer|min:1|max:100',
            'vehicle_type'       => 'nullable|string|max:50',
            'start_location'     => 'nullable|string|max:300',
            'start_latitude'     => 'nullable|numeric|between:-90,90',
            'start_longitude'    => 'nullable|numeric|between:-180,180',
            'departure_time'     => 'nullable',
            'destination_city'   => 'nullable|string|max:100',
            'days'               => 'nullable|array|min:1',
            'days.*.day_number'  => 'required|integer|min:1',
            'days.*.items'       => 'nullable|array',
            'days.*.items.*.destination_id' => 'required|string|exists:destinations,id',
            'days.*.items.*.sort_order'     => 'nullable|integer|min:0',
            'days.*.items.*.arrival_time'   => 'nullable|date_format:H:i',
            'days.*.items.*.departure_time' => 'nullable|date_format:H:i',
            'days.*.items.*.notes'          => 'nullable|string|max:1000',
        ]);
    }


    private function saveDays(Itinerary $itinerary, array $days): void
    {
        foreach ($days as $dayData) {
            $day = ItineraryDay::create([
                'itinerary_id' => $itinerary->id,
                'day_number'   => $dayData['day_number'],
                'is_completed' => false,
            ]);

            foreach ($dayData['items'] ?? [] as $itemData) {
                ItineraryItem::create([
                    'itinerary_day_id' => $day->id,
                    'destination_id'   => $itemData['destination_id'],
                    'sort_order'       => $itemData['sort_order'] ?? 0,
                    'arrival_time'     => $itemData['arrival_time'] ?? null,
                    'departure_time'   => $itemData['departure_time'] ?? null,
                    'notes'            => $itemData['notes'] ?? null,
                ]);
            }
        }
    }

    private function formatItinerary(Itinerary $i): array
    {
        return [
            'id'                 => $i->id,
            'title'              => $i->title,
            'start_date'         => $i->start_date->format('Y-m-d'),
            'end_date'           => $i->end_date->format('Y-m-d'),
            'participants_count' => $i->participants_count,
            'vehicle_type'       => $i->vehicle_type,
            'start_location'     => $i->start_location,
            'start_latitude'     => $i->start_latitude,
            'start_longitude'    => $i->start_longitude,
            'departure_time'     => $i->departure_time,
            'destination_city'   => $i->destination_city,
            'has_any_completed'  => $i->hasAnyCompletedDay(),
            'days'               => $i->days->map(fn($d) => [
                'id'           => $d->id,
                'day_number'   => $d->day_number,
                'is_completed' => $d->is_completed,
                'items'        => $d->items->map(fn($item) => [
                    'id'             => $item->id,
                    'sort_order'     => $item->sort_order,
                    'arrival_time'   => $item->arrival_time,
                    'departure_time' => $item->departure_time,
                    'notes'          => $item->notes,
                    'destination'    => $item->destination ? [
                        'id'         => $item->destination->id,
                        'name'       => $item->destination->name,
                        'location'   => $item->destination->location,
                        'category'   => $item->destination->category,
                        'latitude'   => $item->destination->latitude,
                        'longitude'  => $item->destination->longitude,
                        'main_image' => $this->resolvePhotoUrl($item->destination->main_image),
                    ] : null,
                ]),
            ]),
            'created_at' => $i->created_at->toIso8601String(),
            'updated_at' => $i->updated_at->toIso8601String(),
        ];
    }
}

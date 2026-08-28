<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Destination;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AiItineraryController extends Controller
{
    /**
     * Generate itinerary menggunakan Gemini AI.
     *
     * Payload:
     * {
     *   "destination_city": "Pesawaran",
     *   "categories": ["Alam", "Kuliner"],
     *   "duration_days": 2,
     *   "vehicle_type": "Mobil",
     *   "departure_time": "06:00",
     *   "start_latitude": -5.4292,
     *   "start_longitude": 105.2610,
     *   "destination_ids": ["pantai_mutun", "pulau_pahawang"]  // opsional
     * }
     */
    public function generate(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'destination_city'  => 'nullable|string|max:100',
            'categories'        => 'nullable|array',
            'categories.*'      => 'string',
            'duration_days'     => 'required|integer|min:1|max:7',
            'vehicle_type'      => 'nullable|string|in:Motor,Mobil,Bus',
            'departure_time'    => 'nullable|date_format:H:i',
            'start_latitude'    => 'nullable|numeric',
            'start_longitude'   => 'nullable|numeric',
            'destination_ids'   => 'nullable|array',
            'destination_ids.*' => 'string|exists:destinations,id',
        ]);

        // ============================================================
        // 1. Ambil kandidat destinasi dari database
        // ============================================================

        $destinationsQuery = Destination::query();

        if (!empty($validated['destination_ids'])) {
            // User sudah pilih destinasi spesifik — gunakan hanya itu
            $destinationsQuery->whereIn('id', $validated['destination_ids']);
        } else {
            // Filter berdasarkan kota & kategori
            $city = trim($validated['destination_city'] ?? '');
            if (!empty($city) && !in_array(mb_strtolower($city), ['semua', 'lampung', 'seluruh lampung', 'semua kota/kabupaten'])) {
                $cleanCity = preg_replace('/^(Kabupaten|Kota)\s+/i', '', $city);
                $destinationsQuery->where('location', 'like', '%' . $cleanCity . '%');
            }

            if (!empty($validated['categories'])) {
                $validCategories = array_values(array_filter(
                    $validated['categories'],
                    fn($c) => mb_strtolower($c) !== 'semua'
                ));
                if (!empty($validCategories)) {
                    $destinationsQuery->whereIn('category', $validCategories);
                }
            }

            $destinationsQuery->orderBy('reviews_count', 'desc')->take(20);
        }

        $destinations = $destinationsQuery->get();

        // Fallback jika tidak ada yang cocok dengan filter spesifik
        if ($destinations->isEmpty()) {
            $destinations = Destination::orderBy('reviews_count', 'desc')->take(20)->get();
        }

        if ($destinations->isEmpty()) {
            return response()->json([
                'error' => 'Tidak ada destinasi yang ditemukan di database.',
            ], 422);
        }


        // ============================================================
        // 2. Cache key berdasarkan hash request
        // ============================================================

        $cacheKey = 'ai_itinerary_' . md5(json_encode([
            $validated['destination_ids'] ?? [],
            $validated['destination_city'] ?? '',
            $validated['categories'] ?? [],
            $validated['duration_days'],
            $validated['vehicle_type'] ?? '',
        ]));

        $cached = Cache::get($cacheKey);
        if ($cached) {
            return response()->json(array_merge($cached, ['cached' => true]));
        }

        // ============================================================
        // 3. Bangun context data untuk Gemini
        // ============================================================

        $destinationContext = $destinations->map(fn($d) => [
            'id'                   => $d->id,
            'name'                 => $d->name,
            'category'             => $d->category,
            'location'             => $d->location,
            'latitude'             => $d->latitude,
            'longitude'            => $d->longitude,
            'open_hour'            => $d->open_hour,
            'close_hour'           => $d->close_hour,
            'visit_duration_hours' => $d->visit_duration_hours,
            'rating'               => $d->rating_avg,
        ])->values()->toArray();

        // ============================================================
        // 4. Panggil Gemini API
        // ============================================================

        $result = $this->callGemini($validated, $destinationContext);

        if (!$result) {
            // Fallback: heuristic sorting berdasarkan rating
            $result = $this->heuristicFallback($destinations, $validated['duration_days']);
        }

        // ============================================================
        // 5. Cache hasil selama 1 jam
        // ============================================================

        Cache::put($cacheKey, $result, now()->addHour());

        return response()->json(array_merge($result, ['cached' => false]));
    }

    // ================================================================
    // GEMINI API CALL
    // ================================================================

    private function callGemini(array $params, array $destinations): ?array
    {
        $apiKey = config('services.gemini.api_key');

        if (!$apiKey || $apiKey === 'your-gemini-api-key-here') {
            Log::warning('Gemini API key tidak dikonfigurasi. Menggunakan heuristic fallback.');
            return null;
        }

        $destinationJson = json_encode($destinations, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        $days            = $params['duration_days'];
        $vehicle         = $params['vehicle_type'] ?? 'Mobil';
        $depart          = $params['departure_time'] ?? '07:00';

        $prompt = <<<PROMPT
Kamu adalah travel planner profesional untuk wisata di Lampung, Indonesia.

PENTING — ATURAN WAJIB:
1. HANYA gunakan destinasi dari daftar JSON di bawah ini. JANGAN buat/tambah destinasi baru.
2. Distribusikan destinasi secara merata untuk {$days} hari (max 4 destinasi per hari).
3. Urutkan kunjungan berdasarkan: hindari jam padat (open_hour/close_hour), efisiensi jarak geografis.
4. Jam berangkat: {$depart}, kendaraan: {$vehicle}.
5. Hitung arrival_time & departure_time setiap destinasi (format HH:MM).

DAFTAR DESTINASI YANG TERSEDIA:
{$destinationJson}

INSTRUKSI OUTPUT:
Kembalikan HANYA JSON valid (tanpa markdown, tanpa penjelasan) dengan struktur ini:
{
  "days": [
    {
      "day_number": 1,
      "items": [
        {
          "destination_id": "id_dari_daftar",
          "sort_order": 1,
          "arrival_time": "HH:MM",
          "departure_time": "HH:MM"
        }
      ]
    }
  ]
}
PROMPT;

        try {
            $model    = config('services.gemini.model', 'gemini-1.5-flash');
            $endpoint = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$apiKey}";

            $response = Http::timeout(30)->post($endpoint, [
                'contents' => [
                    ['parts' => [['text' => $prompt]]],
                ],
                'generationConfig' => [
                    'temperature'     => 0.2,   // Low temp = more deterministic
                    'maxOutputTokens' => 2048,
                    'responseMimeType' => 'application/json',
                ],
            ]);

            if (!$response->successful()) {
                Log::error('Gemini API error', ['status' => $response->status(), 'body' => $response->body()]);
                return null;
            }

            $text = $response->json('candidates.0.content.parts.0.text', '');
            $parsed = json_decode($text, true);

            if (!isset($parsed['days'])) {
                Log::error('Gemini response format tidak valid', ['text' => $text]);
                return null;
            }

            // Validasi: pastikan semua destination_id ada di daftar kita
            $validIds = collect($destinations)->pluck('id')->toArray();

            $parsed['days'] = collect($parsed['days'])->map(function ($day) use ($validIds) {
                $day['items'] = collect($day['items'] ?? [])
                    ->filter(fn($item) => in_array($item['destination_id'], $validIds))
                    ->values()
                    ->toArray();
                return $day;
            })->toArray();

            return ['days' => $parsed['days']];

        } catch (\Exception $e) {
            Log::error('Gemini call exception: ' . $e->getMessage());
            return null;
        }
    }

    // ================================================================
    // HEURISTIC FALLBACK (jika Gemini gagal)
    // ================================================================

    private function heuristicFallback($destinations, int $days): array
    {
        $sorted = $destinations->sortByDesc('rating_avg')->values();
        $perDay = (int) ceil($sorted->count() / $days);
        $chunks = $sorted->chunk(max($perDay, 1));

        $result = [];
        foreach (range(1, $days) as $dayNum) {
            $chunk = $chunks->get($dayNum - 1, collect());
            $items = $chunk->values()->map(fn($d, $idx) => [
                'destination_id' => $d->id,
                'sort_order'     => $idx + 1,
                'arrival_time'   => null,
                'departure_time' => null,
            ])->toArray();

            $result[] = ['day_number' => $dayNum, 'items' => $items];
        }

        return ['days' => $result];
    }
}

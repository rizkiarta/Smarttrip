<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Destination;
use App\Traits\ResolvesPhotoUrl;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;

class CrowdPredictionController extends Controller
{
    use ResolvesPhotoUrl;
    // Status nama hari libur nasional Indonesia (simplified)
    private const NATIONAL_HOLIDAYS = [
        '01-01', // Tahun Baru
        '08-17', // HUT RI
        '12-25', // Natal
    ];

    /**
     * Batch prediksi untuk daftar destinasi populer dengan Cache.
     * ?date=2026-09-01  (default: hari ini)
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate(['date' => 'nullable|date']);
        $date = $request->query('date')
            ? \Carbon\Carbon::parse($request->query('date'))
            : now();

        $cacheKey = 'crowd_predictions_all_' . $date->format('Y-m-d');

        $data = Cache::remember($cacheKey, 3600, function () use ($date) {
            // Ambil seluruh destinasi untuk batch prediksi kepadatan
            $destinations = Destination::orderBy('reviews_count', 'desc')->get();

            return [
                'date' => $date->format('Y-m-d'),
                'data' => $destinations->map(fn($d) => $this->buildPrediction($d, $date))->values()->toArray(),
            ];
        });

        return response()->json($data);
    }


    /**
     * Prediksi keramaian satu destinasi.
     * ?date=2026-09-01
     */
    public function show(Request $request, string $id): JsonResponse
    {
        $request->validate(['date' => 'nullable|date']);

        $date = $request->query('date')
            ? \Carbon\Carbon::parse($request->query('date'))
            : now();

        $cacheKey = "crowd_prediction_{$id}_" . $date->format('Y-m-d');

        $data = Cache::remember($cacheKey, 1800, function () use ($id, $date) {
            $destination = Destination::findOrFail($id);
            return [
                'data' => $this->buildPrediction($destination, $date),
            ];
        });

        return response()->json($data);
    }

    // ================================================================
    // RULE-BASED CROWD PREDICTION v1
    // ================================================================

    private function buildPrediction(Destination $destination, \Carbon\Carbon $date): array
    {
        $status    = $this->predictStatus($destination, $date);
        $peakHours = $this->peakHours($destination->category);

        return [
            'destination_id' => $destination->id,
            'name'           => $destination->name,
            'date'           => $date->format('Y-m-d'),
            'status'         => $status,
            'peak_start'     => $peakHours['start'],
            'peak_end'       => $peakHours['end'],
            'time'           => sprintf('%02d.00 - %02d.00', $peakHours['start'], $peakHours['end']),
            'recommendation' => $this->recommendation($status, $peakHours),
            'main_image'     => $this->resolvePhotoUrl($destination->main_image),
            'location'       => $destination->location,
        ];
    }

    private function predictStatus(Destination $destination, \Carbon\Carbon $date): string
    {
        $isWeekend  = in_array($date->dayOfWeek, [0, 6]); // Minggu=0, Sabtu=6
        $isHoliday  = in_array($date->format('m-d'), self::NATIONAL_HOLIDAYS);
        $isFriday   = $date->dayOfWeek === 5;

        // Faktor popularitas berdasarkan reviews_count
        $popularity = $destination->reviews_count;

        if ($isWeekend || $isHoliday) {
            return $popularity > 200 ? 'Ramai' : 'Sedang';
        }

        if ($isFriday) {
            return 'Sedang';
        }

        // Hari biasa
        return $popularity > 300 ? 'Sedang' : 'Sepi';
    }

    private function peakHours(string $category): array
    {
        return match ($category) {
            'Alam'    => ['start' => 9,  'end' => 15],
            'Kuliner' => ['start' => 12, 'end' => 14],
            'Budaya'  => ['start' => 10, 'end' => 13],
            'Buatan'  => ['start' => 10, 'end' => 16],
            default   => ['start' => 9,  'end' => 14],
        };
    }

    private function recommendation(string $status, array $peakHours): string
    {
        if ($status === 'Sepi') {
            return 'Saat ini kondisi relatif sepi. Waktu yang bagus untuk berkunjung!';
        }

        if ($status === 'Sedang') {
            return sprintf(
                'Kondisi sedang ramai di jam %02d.00–%02d.00. Pertimbangkan berkunjung di luar jam tersebut.',
                $peakHours['start'],
                $peakHours['end']
            );
        }

        return sprintf(
            'Diperkirakan sangat ramai jam %02d.00–%02d.00. Disarankan datang sebelum jam %02d.00.',
            $peakHours['start'],
            $peakHours['end'],
            $peakHours['start']
        );
    }
}

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class RouteController extends Controller
{
    /**
     * Fetch directions proxying OpenRouteService or falling back to OSRM.
     * With 24-hour Cache for ultra-fast instant responses.
     *
     * Query Params:
     * - origin: "lon,lat"
     * - destination: "lon,lat"
     * - mode: "car" | "motorcycle" | "bus"
     */
    public function directions(Request $request)
    {
        $origin = $request->query('origin');
        $destination = $request->query('destination');
        $mode = $request->query('mode', 'car');

        if (!$origin || !$destination) {
            return response()->json([
                'status' => 'error',
                'message' => 'Parameter origin dan destination wajib diisi (format: lon,lat)',
            ], 400);
        }

        $cacheKey = "route_dir_" . md5("{$mode}_{$origin}_{$destination}");

        $result = Cache::remember($cacheKey, now()->addHours(24), function () use ($origin, $destination, $mode) {
            $orsApiKey = env('ORS_API_KEY');

            // 1. Try OpenRouteService if API key is present in backend .env
            if (!empty($orsApiKey)) {
                try {
                    $profile = match ($mode) {
                        'motorcycle' => 'cycling-regular',
                        'bus' => 'driving-car',
                        default => 'driving-car',
                    };

                    $url = "https://api.openrouteservice.org/v2/directions/{$profile}?api_key={$orsApiKey}&start={$origin}&end={$destination}";
                    $response = Http::timeout(10)->get($url);

                    if ($response->successful()) {
                        $data = $response->json();
                        if (!empty($data['features'])) {
                            $feature = $data['features'][0];
                            return [
                                'status' => 'success',
                                'source' => 'openrouteservice',
                                'points' => $feature['geometry']['coordinates'] ?? [],
                                'distance' => $feature['properties']['summary']['distance'] ?? 0,
                                'duration' => $feature['properties']['summary']['duration'] ?? 0,
                            ];
                        }
                    }
                } catch (\Exception $e) {
                    Log::warning('ORS API Call failed, falling back to OSRM: ' . $e->getMessage());
                }
            }

            // 2. Fallback to OSRM
            try {
                $url = "https://router.project-osrm.org/route/v1/driving/{$origin};{$destination}?overview=full&geometries=geojson";
                $response = Http::timeout(12)->get($url);

                if ($response->successful()) {
                    $data = $response->json();
                    if (($data['code'] ?? '') === 'Ok' && !empty($data['routes'])) {
                        $route = $data['routes'][0];
                        return [
                            'status' => 'success',
                            'source' => 'osrm',
                            'points' => $route['geometry']['coordinates'] ?? [],
                            'distance' => $route['distance'] ?? 0,
                            'duration' => $route['duration'] ?? 0,
                        ];
                    }
                }
            } catch (\Exception $e) {
                Log::error('OSRM API Call failed: ' . $e->getMessage());
            }

            return null;
        });

        if ($result) {
            return response()->json($result);
        }

        return response()->json([
            'status' => 'error',
            'message' => 'Gagal mendapatkan data rute',
        ], 500);
    }
}

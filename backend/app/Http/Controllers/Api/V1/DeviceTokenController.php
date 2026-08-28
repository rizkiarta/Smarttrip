<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class DeviceTokenController extends Controller
{
    /**
     * Register / update FCM token perangkat user.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'fcm_token'   => 'required|string|max:500',
            'device_type' => 'required|string|in:android,ios,web',
        ]);

        DeviceToken::updateOrCreate(
            [
                'user_id'   => $request->user()->id,
                'fcm_token' => $validated['fcm_token'],
            ],
            ['device_type' => $validated['device_type']]
        );

        return response()->json(['message' => 'Device token berhasil didaftarkan.']);
    }
}

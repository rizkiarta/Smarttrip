<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\NotificationSetting;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class NotificationSettingController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $settings = $request->user()->notificationSetting
            ?? NotificationSetting::create(['user_id' => $request->user()->id]);

        return response()->json(['data' => $this->format($settings)]);
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'crowd_alerts'          => 'sometimes|boolean',
            'recommendation_alerts' => 'sometimes|boolean',
            'itinerary_reminders'   => 'sometimes|boolean',
            'promo_alerts'          => 'sometimes|boolean',
        ]);

        $settings = $request->user()->notificationSetting
            ?? NotificationSetting::create(['user_id' => $request->user()->id]);

        $settings->update($validated);

        return response()->json([
            'message' => 'Pengaturan notifikasi berhasil diperbarui.',
            'data'    => $this->format($settings->fresh()),
        ]);
    }

    private function format(NotificationSetting $s): array
    {
        return [
            'crowd_alerts'          => $s->crowd_alerts,
            'recommendation_alerts' => $s->recommendation_alerts,
            'itinerary_reminders'   => $s->itinerary_reminders,
            'promo_alerts'          => $s->promo_alerts,
        ];
    }
}

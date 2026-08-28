<?php

namespace App\Services;

use App\Models\User;
use App\Models\DeviceToken;
use App\Models\UserNotification;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    /**
     * Kirim push notification ke user spesifik tanpa emotikon.
     */
    public static function sendToUser(
        User $user,
        string $title,
        string $body,
        array $data = [],
        string $type = 'system',
        string $icon = 'info'
    ): bool {
        try {
            // 1. Cek preferensi notifikasi user
            if (!self::isNotificationEnabled($user, $type)) {
                Log::info("[FCM SKIPPED] User {$user->id} mematikan notifikasi tipe: {$type}");
                return false;
            }

            // 2. Simpan ke database user_notifications (inbox di aplikasi)
            $user->notifications()->create([
                'type'        => $type,
                'title'       => $title,
                'description' => $body,
                'icon'        => $icon,
                'is_read'     => false,
            ]);

            // 3. Ambil daftar FCM token perangkat user
            $tokens = $user->deviceTokens()->pluck('fcm_token')->toArray();

            if (empty($tokens)) {
                Log::info("[FCM INFO] User {$user->id} belum memiliki device token FCM terdaftar.");
                return true;
            }

            // 4. Kirim notifikasi ke tiap FCM token
            foreach ($tokens as $fcmToken) {
                self::sendFcmRequest($fcmToken, $title, $body, array_merge(['type' => $type], $data));
            }

            return true;
        } catch (\Throwable $e) {
            Log::error("[FCM SERVICE ERROR] User {$user->id}: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Notifikasi Pengingat Rencana Perjalanan Belum Selesai.
     */
    public static function sendUnfinishedTripReminder(User $user, string $itineraryTitle): bool
    {
        return self::sendToUser(
            $user,
            "Rencana Perjalanan Belum Selesai",
            "Anda memiliki rencana perjalanan {$itineraryTitle} yang belum diselesaikan. Lanjutkan perjalanan Anda sekarang.",
            ['action' => 'open_itinerary', 'title' => $itineraryTitle],
            'itinerary',
            'route'
        );
    }

    /**
     * Notifikasi Prediksi Kepadatan Destinasi Favorit.
     */
    public static function sendFavoriteDestinationCrowdUpdate(User $user, string $destinationName, string $crowdStatus = 'sepi'): bool
    {
        $statusText = strtolower($crowdStatus) === 'sepi' 
            ? "diprediksi dalam kondisi sepi dan nyaman untuk dikunjungi hari ini." 
            : "diprediksi dalam kondisi ramai pengunjung hari ini.";

        return self::sendToUser(
            $user,
            "Kondisi Destinasi Favorit",
            "Destinasi favorit Anda, {$destinationName}, {$statusText}",
            ['destination' => $destinationName, 'status' => $crowdStatus],
            'crowd',
            'groups'
        );
    }

    /**
     * Cek apakah preferensi notifikasi diaktifkan di notification_settings.
     */
    private static function isNotificationEnabled(User $user, string $type): bool
    {
        $setting = $user->notificationSetting;
        if (!$setting) return true;

        switch ($type) {
            case 'crowd':
                return (bool) $setting->crowd_alerts;
            case 'recommendation':
                return (bool) $setting->recommendation_alerts;
            case 'itinerary':
            case 'trip':
                return (bool) $setting->itinerary_reminders;
            case 'promo':
                return (bool) $setting->promo_alerts;
            default:
                return true;
        }
    }

    /**
     * Eksekusi HTTP Request ke Google FCM API (Support HTTP v1 Service Account & Legacy Server Key).
     */
    private static function sendFcmRequest(string $fcmToken, string $title, string $body, array $data): void
    {
        $serverKey = env('FCM_SERVER_KEY');
        $serviceAccountPath = env('FCM_SERVICE_ACCOUNT_PATH', storage_path('app/firebase-service-account.json'));

        // Mode 1: HTTP v1 dengan Service Account JSON jika ada
        if (file_exists($serviceAccountPath)) {
            self::sendFcmV1Request($serviceAccountPath, $fcmToken, $title, $body, $data);
            return;
        }

        // Mode 2: Legacy Server Key jika dipasang di .env
        if (!empty($serverKey)) {
            self::sendLegacyFcmRequest($serverKey, $fcmToken, $title, $body, $data);
            return;
        }

        // Mode 3: Simulation Fallback jika belum memasukkan key
        Log::info("[FCM SIMULATED DISPATCH] Token: " . substr($fcmToken, 0, 15) . "... | Title: {$title}");
    }

    /**
     * Pengiriman via Legacy HTTP API
     */
    private static function sendLegacyFcmRequest(string $serverKey, string $fcmToken, string $title, string $body, array $data): void
    {
        try {
            $response = Http::withHeaders([
                'Authorization' => 'key=' . $serverKey,
                'Content-Type'  => 'application/json',
            ])->post('https://fcm.googleapis.com/fcm/send', [
                'to'           => $fcmToken,
                'priority'     => 'high',
                'notification' => [
                    'title' => $title,
                    'body'  => $body,
                    'sound' => 'default',
                ],
                'data' => $data,
            ]);

            if ($response->failed()) {
                Log::warning("[FCM RESPONSE ERROR] Status: " . $response->status() . " Body: " . $response->body());
                if (str_contains($response->body(), 'NotRegistered') || str_contains($response->body(), 'InvalidRegistration')) {
                    DeviceToken::where('fcm_token', $fcmToken)->delete();
                    Log::info("[FCM CLEANUP] Removing invalid FCM token: " . substr($fcmToken, 0, 15));
                }
            } else {
                Log::info("[FCM DISPATCH SUCCESS] Token: " . substr($fcmToken, 0, 15) . "...");
            }
        } catch (\Throwable $e) {
            Log::error("[FCM HTTP EXCEPTION] " . $e->getMessage());
        }
    }

    /**
     * Pengiriman via Modern HTTP v1 API
     */
    private static function sendFcmV1Request(string $jsonPath, string $fcmToken, string $title, string $body, array $data): void
    {
        try {
            $json = json_decode(file_get_contents($jsonPath), true);
            $projectId = $json['project_id'] ?? 'smarttrip-7c039';

            $token = self::getGoogleAccessToken($json);
            if (!$token) {
                Log::error("[FCM V1 ERROR] Gagal mendapatkan OAuth2 Access Token.");
                return;
            }

            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $token,
                'Content-Type'  => 'application/json',
            ])->post("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send", [
                'message' => [
                    'token' => $fcmToken,
                    'notification' => [
                        'title' => $title,
                        'body'  => $body,
                    ],
                    'data' => array_map('strval', $data),
                ],
            ]);

            if ($response->failed()) {
                Log::warning("[FCM V1 RESPONSE ERROR] Status: " . $response->status() . " Body: " . $response->body());
                if (str_contains($response->body(), 'UNREGISTERED')) {
                    DeviceToken::where('fcm_token', $fcmToken)->delete();
                }
            } else {
                Log::info("[FCM V1 DISPATCH SUCCESS] Token: " . substr($fcmToken, 0, 15) . "...");
            }
        } catch (\Throwable $e) {
            Log::error("[FCM V1 EXCEPTION] " . $e->getMessage());
        }
    }

    /**
     * OAuth2 Bearer Token Generator untuk Google Cloud API
     */
    private static function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function getGoogleAccessToken(array $json): ?string
    {
        try {
            $header = self::base64UrlEncode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
            $now = time();
            $claims = self::base64UrlEncode(json_encode([
                'iss'   => $json['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud'   => 'https://oauth2.googleapis.com/token',
                'exp'   => $now + 3600,
                'iat'   => $now,
            ]));

            $unsignedJwt = "$header.$claims";
            $signature = '';
            openssl_sign($unsignedJwt, $signature, $json['private_key'], 'SHA256');
            $jwt = "$unsignedJwt." . self::base64UrlEncode($signature);

            $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion'  => $jwt,
            ]);

            return $response->json('access_token');
        } catch (\Throwable $e) {
            Log::error("[FCM OAUTH2 ERROR] " . $e->getMessage());
            return null;
        }
    }
}

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\UserNotification;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class NotificationController extends Controller
{
    /**
     * Get all notifications for authenticated user (Pure Real Event Notifications).
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $notifications = $user->notifications()
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($n) {
                return [
                    'id'          => $n->id,
                    'type'        => $n->type,
                    'title'       => $n->title,
                    'description' => $n->description,
                    'icon'        => $n->icon,
                    'is_read'     => (bool) $n->is_read,
                    'time_ago'    => $n->created_at->diffForHumans(),
                    'created_at'  => $n->created_at->toIso8601String(),
                ];
            });

        $unreadCount = $user->notifications()->where('is_read', false)->count();

        return response()->json([
            'data'         => $notifications,
            'unread_count' => $unreadCount,
        ]);
    }

    /**
     * Mark all notifications as read.
     */
    public function markAllAsRead(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->notifications()->where('is_read', false)->update(['is_read' => true]);

        return response()->json([
            'message' => 'Semua notifikasi telah ditandai sebagai dibaca.',
        ]);
    }

    /**
     * Mark a single notification as read.
     */
    public function markAsRead(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $notification = $user->notifications()->where('id', $id)->firstOrFail();
        $notification->update(['is_read' => true]);

        return response()->json([
            'message' => 'Notifikasi telah ditandai sebagai dibaca.',
        ]);
    }

    /**
     * Kirim notifikasi uji coba ke user yang sedang login (Production FCM Test).
     */
    public function sendTestNotification(Request $request): JsonResponse
    {
        $user  = $request->user();
        $title = $request->input('title', 'Rencana Perjalanan Belum Selesai');
        $body  = $request->input('body', 'Anda masih memiliki rencana perjalanan ke Lampung yang belum diselesaikan. Lanjutkan perjalanan Anda sekarang.');
        $type  = $request->input('type', 'itinerary');

        $sent = \App\Services\FcmService::sendToUser(
            $user,
            $title,
            $body,
            ['destination' => 'Pulau Pahawang', 'action' => 'open_itinerary'],
            $type,
            'route'
        );

        return response()->json([
            'success' => $sent,
            'message' => $sent
                ? 'Notifikasi uji coba berhasil dikirim.'
                : 'Pengiriman notifikasi dilewati (preferensi notifikasi dimatikan atau kendala sistem).',
        ]);
    }
}

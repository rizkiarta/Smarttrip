<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\ProfileController;
use App\Http\Controllers\Api\V1\DestinationController;
use App\Http\Controllers\Api\V1\FavoriteController;
use App\Http\Controllers\Api\V1\ItineraryController;
use App\Http\Controllers\Api\V1\ReviewController;
use App\Http\Controllers\Api\V1\CrowdPredictionController;
use App\Http\Controllers\Api\V1\AiItineraryController;
use App\Http\Controllers\Api\V1\NotificationSettingController;
use App\Http\Controllers\Api\V1\DeviceTokenController;

// ============================================================
// PUBLIC ROUTES (no auth required)
// ============================================================

Route::prefix('v1')->group(function () {

    // Auth
    Route::prefix('auth')->middleware('throttle:auth')->group(function () {
        Route::post('register', [AuthController::class, 'register']);
        Route::post('login',    [AuthController::class, 'login']);
        Route::post('google',   [AuthController::class, 'googleAuth']);
        Route::post('facebook', [AuthController::class, 'facebookAuth']);
    });



    // Destinations (read-only, public)
    Route::get('categories',        [DestinationController::class, 'categories']);
    Route::get('destinations',      [DestinationController::class, 'index']);
    Route::get('destinations/{id}', [DestinationController::class, 'show']);


    // Crowd prediction (public)
    Route::get('crowd-predictions',                              [CrowdPredictionController::class, 'index']);
    Route::get('destinations/{id}/crowd-prediction',             [CrowdPredictionController::class, 'show']);

    // Reviews per destination (read-only, public)
    Route::get('destinations/{id}/reviews', [ReviewController::class, 'indexByDestination']);

    // Routing Proxy (public)
    Route::get('route/directions', [App\Http\Controllers\Api\V1\RouteController::class, 'directions']);

    // ============================================================
    // PROTECTED ROUTES (auth:sanctum required)
    // ============================================================

    Route::middleware('auth:sanctum')->group(function () {

        // Auth
        Route::post('auth/logout', [AuthController::class, 'logout']);

        // Profile
        Route::get('profile',        [ProfileController::class, 'show']);
        Route::put('profile',        [ProfileController::class, 'update']);
        Route::post('profile/photo', [ProfileController::class, 'uploadPhoto']);

        // Favorites
        Route::get('favorites',                          [FavoriteController::class, 'index']);
        Route::post('favorites/{destination_id}/toggle', [FavoriteController::class, 'toggle']);

        // Itineraries
        Route::get('itineraries',          [ItineraryController::class, 'index']);
        Route::post('itineraries',         [ItineraryController::class, 'store']);
        Route::get('itineraries/{id}',     [ItineraryController::class, 'show']);
        Route::put('itineraries/{id}',     [ItineraryController::class, 'update']);
        Route::delete('itineraries/{id}',  [ItineraryController::class, 'destroy']);
        Route::patch('itineraries/{id}/days/{day}/complete', [ItineraryController::class, 'markDayComplete']);

        // Reviews
        Route::post('destinations/{id}/reviews', [ReviewController::class, 'store']);
        Route::get('users/me/reviews',           [ReviewController::class, 'myReviews']);
        Route::post('reviews/{id}/like',         [ReviewController::class, 'toggleLike']);

        // AI Itinerary
        Route::post('ai/generate-itinerary', [AiItineraryController::class, 'generate'])
            ->middleware('throttle:ai');

        // Notifications
        Route::get('notifications',             [App\Http\Controllers\Api\V1\NotificationController::class, 'index']);
        Route::post('notifications/mark-read',  [App\Http\Controllers\Api\V1\NotificationController::class, 'markAllAsRead']);
        Route::post('notifications/{id}/read',  [App\Http\Controllers\Api\V1\NotificationController::class, 'markAsRead']);
        Route::post('notifications/test-push',  [App\Http\Controllers\Api\V1\NotificationController::class, 'sendTestNotification']);

        // Notification Settings
        Route::get('settings/notifications', [NotificationSettingController::class, 'show']);
        Route::put('settings/notifications', [NotificationSettingController::class, 'update']);

        // Device Tokens (FCM)
        Route::post('device-tokens', [DeviceTokenController::class, 'store']);
    });
});


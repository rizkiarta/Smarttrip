<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Ulasan destinasi
        Schema::create('reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('destination_id', 100);
            $table->foreign('destination_id')->references('id')->on('destinations')->onDelete('cascade');
            $table->unsignedTinyInteger('rating');  // 1-5
            $table->text('review_text');
            $table->unsignedInteger('likes_count')->default(0);
            $table->timestamps();
            // Satu user satu review per destinasi
            $table->unique(['user_id', 'destination_id']);
        });

        // Foto-foto dalam ulasan
        Schema::create('review_photos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('review_id')->constrained()->onDelete('cascade');
            $table->string('photo_url', 500);
            $table->timestamps();
        });

        // Like per review (toggle)
        Schema::create('review_likes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('review_id')->constrained()->onDelete('cascade');
            $table->timestamp('created_at')->useCurrent();
            $table->unique(['user_id', 'review_id']);
        });

        // Preferensi notifikasi user (one-to-one dengan users)
        Schema::create('notification_settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade')->unique();
            $table->boolean('crowd_alerts')->default(true);
            $table->boolean('recommendation_alerts')->default(true);
            $table->boolean('itinerary_reminders')->default(true);
            $table->boolean('promo_alerts')->default(false);
            $table->timestamps();
        });

        // Token perangkat untuk FCM push notification
        Schema::create('device_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('fcm_token', 500);
            $table->enum('device_type', ['android', 'ios'])->default('android');
            $table->timestamps();
            $table->unique(['user_id', 'fcm_token']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('device_tokens');
        Schema::dropIfExists('notification_settings');
        Schema::dropIfExists('review_likes');
        Schema::dropIfExists('review_photos');
        Schema::dropIfExists('reviews');
    }
};

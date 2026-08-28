<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Favorit destinasi user
        Schema::create('user_favorites', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('destination_id', 100);
            $table->foreign('destination_id')->references('id')->on('destinations')->onDelete('cascade');
            $table->timestamp('created_at')->useCurrent();
            $table->unique(['user_id', 'destination_id']);
        });

        // Rencana perjalanan (header itinerary)
        Schema::create('itineraries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('title', 200);
            $table->date('start_date');
            $table->date('end_date');
            $table->unsignedSmallInteger('participants_count')->default(1);
            $table->string('vehicle_type', 50)->nullable();  // Motor/Mobil/Bus
            $table->string('start_location', 300)->nullable();
            $table->decimal('start_latitude', 10, 7)->nullable();
            $table->decimal('start_longitude', 10, 7)->nullable();
            $table->time('departure_time')->nullable();
            $table->string('destination_city', 100)->nullable();
            $table->timestamps();
        });

        // Hari-hari dalam itinerary, dengan status selesai per hari
        Schema::create('itinerary_days', function (Blueprint $table) {
            $table->id();
            $table->foreignId('itinerary_id')->constrained()->onDelete('cascade');
            $table->unsignedSmallInteger('day_number');  // 1, 2, 3, ...
            $table->boolean('is_completed')->default(false);
            $table->timestamps();
            $table->unique(['itinerary_id', 'day_number']);
        });

        // Item/destinasi dalam satu hari itinerary
        Schema::create('itinerary_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('itinerary_day_id')->constrained()->onDelete('cascade');
            $table->string('destination_id', 100);
            $table->foreign('destination_id')->references('id')->on('destinations')->onDelete('restrict');
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->time('arrival_time')->nullable();
            $table->time('departure_time')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('itinerary_items');
        Schema::dropIfExists('itinerary_days');
        Schema::dropIfExists('itineraries');
        Schema::dropIfExists('user_favorites');
    }
};

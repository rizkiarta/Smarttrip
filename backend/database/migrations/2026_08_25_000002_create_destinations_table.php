<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('destinations', function (Blueprint $table) {
            // id pakai string slug agar cocok dengan id Flutter
            // contoh: 'pulau_pahawang', 'danau_ranau', dll
            $table->string('id', 100)->primary();
            $table->string('name', 200);
            $table->string('location', 100);   // Kabupaten/Kota
            $table->enum('category', ['Alam', 'Kuliner', 'Budaya', 'Buatan']);
            $table->text('description')->nullable();
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->decimal('rating_avg', 3, 1)->default(0);
            $table->unsignedInteger('reviews_count')->default(0);
            $table->string('main_image', 500)->nullable();
            $table->string('price_range', 50)->nullable();
            $table->unsignedTinyInteger('open_hour')->default(8);
            $table->unsignedTinyInteger('close_hour')->default(18);
            $table->decimal('visit_duration_hours', 3, 1)->default(2.0);
            $table->timestamps();
        });

        Schema::create('destination_gallery_images', function (Blueprint $table) {
            $table->id();
            $table->string('destination_id', 100);
            $table->foreign('destination_id')->references('id')->on('destinations')->onDelete('cascade');
            $table->string('image_url', 500);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('destination_gallery_images');
        Schema::dropIfExists('destinations');
    }
};

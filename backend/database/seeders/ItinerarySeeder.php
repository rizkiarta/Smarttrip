<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Destination;
use App\Models\Itinerary;
use App\Models\ItineraryDay;
use App\Models\ItineraryItem;
use Carbon\Carbon;

class ItinerarySeeder extends Seeder
{
    public function run(): void
    {
        $users = User::all();
        if ($users->isEmpty()) {
            return;
        }

        // Fetch existing destinations or fallback to first available
        $dest1 = Destination::find('pulau_pahawang') ?? Destination::first();
        $dest2 = Destination::find('pantai_mutun') ?? Destination::skip(1)->first() ?? $dest1;

        if (!$dest1) {
            return;
        }

        $yesterday = Carbon::yesterday()->format('Y-m-d');
        $twoDaysAgo = Carbon::yesterday()->subDay()->format('Y-m-d');

        foreach ($users as $user) {
            // Seed a completed trip from yesterday
            $itinerary = Itinerary::create([
                'user_id' => $user->id,
                'title' => 'Liburan Seru Pahawang & Mutun',
                'start_date' => $twoDaysAgo,
                'end_date' => $yesterday,
                'participants_count' => 2,
                'vehicle_type' => 'Mobil',
                'start_location' => 'Bandar Lampung',
                'start_latitude' => -5.4292,
                'start_longitude' => 105.2611,
                'departure_time' => '08:00',
                'destination_city' => 'Pesawaran',
            ]);

            // Day 1
            $day1 = ItineraryDay::create([
                'itinerary_id' => $itinerary->id,
                'day_number' => 1,
                'is_completed' => true,
            ]);

            ItineraryItem::create([
                'itinerary_day_id' => $day1->id,
                'destination_id' => $dest2->id,
                'sort_order' => 1,
                'arrival_time' => '09:00',
                'departure_time' => '12:00',
                'notes' => 'Berenang dan santai di pantai',
            ]);

            // Day 2
            $day2 = ItineraryDay::create([
                'itinerary_id' => $itinerary->id,
                'day_number' => 2,
                'is_completed' => true,
            ]);

            ItineraryItem::create([
                'itinerary_day_id' => $day2->id,
                'destination_id' => $dest1->id,
                'sort_order' => 1,
                'arrival_time' => '08:30',
                'departure_time' => '15:00',
                'notes' => 'Snorkeling dan ke Nemo Spot',
            ]);
        }
    }
}

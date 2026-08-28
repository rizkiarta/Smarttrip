<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Seed default demo user
        User::firstOrCreate(
            ['email' => 'admin@gmail.com'],
            [
                'name'      => 'Kang Hearin',
                'username'  => 'green_meowww',
                'password'  => Hash::make('admin123'),
                'phone'     => '081234567890',
                'bio'       => 'Pecinta keindahan alam & pantai Lampung 🌊✨',
                'language'  => 'id',
            ]
        );

        // Seed destinations
        $this->call([
            DestinationSeeder::class,
        ]);
    }
}

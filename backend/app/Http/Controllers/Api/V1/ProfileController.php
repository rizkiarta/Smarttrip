<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Traits\ResolvesPhotoUrl;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ProfileController extends Controller
{
    use ResolvesPhotoUrl;
    /**
     * Ambil data profil user yang sedang login.
     */
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'data' => $this->formatUser($user),
        ]);
    }

    /**
     * Update data profil user.
     */
    public function update(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'name'       => 'sometimes|string|max:100',
            'username'   => 'sometimes|string|max:50|alpha_dash|unique:users,username,' . $user->id,
            'email'      => 'sometimes|email|max:255|unique:users,email,' . $user->id,
            'bio'        => 'sometimes|nullable|string|max:500',
            'phone'      => 'sometimes|nullable|string|max:20',
            'birth_date' => 'sometimes|nullable|date|before:today',
            'language'   => 'sometimes|string|in:id,en',
        ]);

        $user->update($validated);

        return response()->json([
            'message' => 'Profil berhasil diperbarui.',
            'data'    => $this->formatUser($user->fresh()),
        ]);
    }

    /**
     * Upload/ganti foto profil.
     */
    public function uploadPhoto(Request $request): JsonResponse
    {
        $request->validate([
            'photo' => 'required|image|mimes:jpeg,png,webp,jpg|max:5120', // 5MB max
        ]);

        $user = $request->user();

        // Hapus foto lama kalau ada
        if ($user->photo_url && Storage::disk('public')->exists($user->photo_url)) {
            Storage::disk('public')->delete($user->photo_url);
        }

        // Simpan foto baru dengan nama random agar tidak bisa ditebak
        $filename  = 'avatars/' . $user->id . '_' . Str::random(16) . '.jpg';
        $request->file('photo')->storeAs('', $filename, 'public');

        $user->update(['photo_url' => $filename]);

        return response()->json([
            'message'   => 'Foto profil berhasil diperbarui.',
            'photo_url' => $this->resolvePhotoUrl($filename),
        ]);
    }

    private function formatUser($user): array
    {
        return [
            'id'         => $user->id,
            'name'       => $user->name,
            'username'   => $user->username,
            'email'      => $user->email,
            'phone'      => $user->phone,
            'bio'        => $user->bio,
            'birth_date' => $user->birth_date?->format('Y-m-d'),
            'photo_url'  => $this->resolvePhotoUrl($user->photo_url),
            'language'   => $user->language,
        ];
    }
}

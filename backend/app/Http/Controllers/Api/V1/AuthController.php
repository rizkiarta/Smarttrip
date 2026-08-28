<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\NotificationSetting;
use App\Traits\ResolvesPhotoUrl;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    use ResolvesPhotoUrl;
    /**
     * Register user baru.
     */
    public function register(Request $request): JsonResponse
    {
        // Generasi default username jika tidak dikirim dari frontend
        if (!$request->has('username') || empty($request->username)) {
            $baseUsername = preg_replace('/[^a-zA-Z0-9_]/', '', explode('@', $request->email)[0] ?? 'user');
            $request->merge([
                'username' => strtolower($baseUsername) . rand(100, 999),
            ]);
        }

        $validated = $request->validate([
            'name'     => 'required|string|max:100',
            'username' => 'required|string|max:50|unique:users|alpha_dash',
            'email'    => 'required|email|unique:users',
            'phone'    => 'nullable|string|max:20',
            'password' => ['required', 'confirmed', Password::min(6)],
        ], [
            'email.unique'       => 'Email ini sudah terdaftar. Silakan gunakan email lain atau langsung Masuk.',
            'username.unique'    => 'Username sudah digunakan, silakan coba lagi.',
            'password.confirmed' => 'Konfirmasi kata sandi tidak cocok.',
            'password.min'       => 'Kata sandi minimal 6 karakter.',
        ]);



        $user = User::create([
            'name'     => $validated['name'],
            'username' => $validated['username'],
            'email'    => $validated['email'],
            'phone'    => $validated['phone'] ?? null,
            'password' => Hash::make($validated['password']),
            'bio'      => 'Traveler',
        ]);

        // Buat default notification settings
        NotificationSetting::create([
            'user_id'               => $user->id,
            'crowd_alerts'          => true,
            'recommendation_alerts' => true,
            'itinerary_reminders'   => true,
            'promo_alerts'          => false,
        ]);

        $token = $user->createToken('smarttrip-app')->plainTextToken;

        return response()->json([
            'message' => 'Registrasi berhasil.',
            'token'   => $token,
            'user'    => $this->userResponse($user),
        ], 201);
    }

    /**
     * Login dan return Bearer token.
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'identifier' => 'required|string',   // email atau username
            'password'   => 'required|string',
        ]);

        $identifier = $request->identifier;

        // Coba login dengan email atau username
        $user = User::where('email', $identifier)
            ->orWhere('username', $identifier)
            ->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'identifier' => ['Email/username atau password salah.'],
            ]);
        }

        // Revoke token lama (login ulang)
        $user->tokens()->delete();
        $token = $user->createToken('smarttrip-app')->plainTextToken;

        return response()->json([
            'message' => 'Login berhasil.',
            'token'   => $token,
            'user'    => $this->userResponse($user),
        ]);
    }

    /**
     * Authenticate or register via Google.
     */
    public function googleAuth(Request $request): JsonResponse
    {
        $request->validate([
            'email'     => 'required|email',
            'name'      => 'required|string',
            'google_id' => 'nullable|string',
            'photo_url' => 'nullable|string',
        ]);

        $googleId = $request->google_id;
        $email = $request->email;

        $user = User::where(function ($query) use ($googleId, $email) {
            if (!empty($googleId)) {
                $query->where('google_id', $googleId);
            }
            if (!empty($email)) {
                $query->orWhere('email', $email);
            }
        })->first();

        if (!$user) {
            $user = \Illuminate\Support\Facades\DB::transaction(function () use ($request) {
                $baseUsername = preg_replace('/[^a-zA-Z0-9_]/', '', explode('@', $request->email)[0] ?? 'user');
                $username = strtolower($baseUsername) . rand(100, 999);

                $user = User::create([
                    'name'      => $request->name,
                    'username'  => $username,
                    'email'     => $request->email,
                    'google_id' => $request->google_id,
                    'password'  => Hash::make(uniqid('google_', true)),
                    'photo_url' => $request->photo_url,
                    'bio'       => 'SmartTrip Traveler',
                ]);

                // Default notification settings
                NotificationSetting::create([
                    'user_id'               => $user->id,
                    'crowd_alerts'          => true,
                    'recommendation_alerts' => true,
                    'itinerary_reminders'   => true,
                    'promo_alerts'          => false,
                ]);

                return $user;
            });
        } else {
            if (empty($user->google_id) && $request->google_id) {
                $user->google_id = $request->google_id;
            }
            if (empty($user->photo_url) && $request->photo_url) {
                $user->photo_url = $request->photo_url;
            }
            $user->save();
        }

        $user->tokens()->delete();
        $token = $user->createToken('smarttrip-app')->plainTextToken;

        return response()->json([
            'message' => 'Login Google berhasil.',
            'token'   => $token,
            'user'    => $this->userResponse($user),
        ]);
    }

    /**
     * Authenticate or register via Facebook.
     */
    public function facebookAuth(Request $request): JsonResponse
    {
        $request->validate([
            'email'       => 'nullable|email',
            'name'        => 'required|string',
            'facebook_id' => 'required|string',
            'photo_url'   => 'nullable|string',
        ]);

        $user = User::where('facebook_id', $request->facebook_id);
        if ($request->email) {
            $user->orWhere('email', $request->email);
        }
        $user = $user->first();

        if (!$user) {
            $email = $request->email ?? ($request->facebook_id . '@facebook.smarttrip.app');
            $baseUsername = preg_replace('/[^a-zA-Z0-9_]/', '', explode('@', $email)[0] ?? 'fb_user');
            $username = strtolower($baseUsername) . rand(100, 999);

            $user = User::create([
                'name'        => $request->name,
                'username'    => $username,
                'email'       => $email,
                'facebook_id' => $request->facebook_id,
                'password'    => Hash::make(uniqid('fb_', true)),
                'photo_url'   => $request->photo_url,
                'bio'         => 'SmartTrip Facebook Traveler',
            ]);

            // Default notification settings
            NotificationSetting::create([
                'user_id'               => $user->id,
                'crowd_alerts'          => true,
                'recommendation_alerts' => true,
                'itinerary_reminders'   => true,
                'promo_alerts'          => false,
            ]);
        } else {
            if (empty($user->facebook_id) && $request->facebook_id) {
                $user->facebook_id = $request->facebook_id;
            }
            if (empty($user->photo_url) && $request->photo_url) {
                $user->photo_url = $request->photo_url;
            }
            $user->save();
        }

        $user->tokens()->delete();
        $token = $user->createToken('smarttrip-app')->plainTextToken;

        return response()->json([
            'message' => 'Login Facebook berhasil.',
            'token'   => $token,
            'user'    => $this->userResponse($user),
        ]);
    }



    /**
     * Logout — revoke token aktif.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logout berhasil.']);
    }

    /**
     * Format respons data user (tanpa field sensitif).
     */
    private function userResponse(User $user): array
    {
        return [
            'id'        => $user->id,
            'name'      => $user->name,
            'username'  => $user->username,
            'email'     => $user->email,
            'phone'     => $user->phone,
            'bio'       => $user->bio,
            'birth_date'=> $user->birth_date?->format('Y-m-d'),
            'photo_url' => $this->resolvePhotoUrl($user->photo_url),

            'language'  => $user->language,
        ];
    }
}

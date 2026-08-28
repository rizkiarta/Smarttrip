<?php

namespace App\Traits;

trait ResolvesPhotoUrl
{
    /**
     * Resolves photo/image path into a full public URL.
     */
    protected function resolvePhotoUrl(?string $path): ?string
    {
        if (!$path) return null;
        $path = trim($path);
        if ($path === '') return null;

        // If already full HTTP/HTTPS URL
        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }

        // Support Flutter local assets if explicitly requested (e.g., fallback images in seeders)
        if (str_starts_with($path, 'assets/')) {
            return $path;
        }

        // Strip leading storage prefix if present to avoid /storage/storage/
        if (str_starts_with($path, '/storage/')) {
            $path = substr($path, 9);
        } elseif (str_starts_with($path, 'storage/')) {
            $path = substr($path, 8);
        }

        // Build full public URL dynamically from current request scheme & host
        return request()->schemeAndHttpHost() . '/storage/' . ltrim($path, '/');
    }
}

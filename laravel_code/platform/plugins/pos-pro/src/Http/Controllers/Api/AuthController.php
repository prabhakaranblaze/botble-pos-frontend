<?php

namespace Botble\PosPro\Http\Controllers\Api;

use Botble\Base\Http\Controllers\BaseController;
use Botble\Base\Http\Responses\BaseHttpResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class AuthController extends BaseController
{
    /**
     * Login and get authentication token
     */
    public function login(Request $request, BaseHttpResponse $response)
    {
        $request->validate([
            'username' => 'required',
            'password' => 'required|string',
            'device_name' => 'nullable|string',
        ]);

        // Attempt to find user by email
        $user = \Botble\ACL\Models\User::where('username', $request->username)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return $response
                ->setError()
                ->setMessage('The provided credentials are incorrect.')
                ->setCode(401);
        }

        // Check if user has POS access permission
        if (!$user->hasPermission('pos.index')) {
            return $response
                ->setError()
                ->setMessage('You do not have permission to access POS.')
                ->setCode(403);
        }

        // Create token
        $deviceName = $request->input('device_name', 'POS Device');
        $token = $user->createToken($deviceName)->plainTextToken;

        return $response
            ->setData([
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'username' => $user->username,
                    'store_id' => $user->store_id ?? null,
                    'permissions' => $user->permissions,
                ],
            ])
            ->setMessage('Login successful');
    }

    /**
     * Get current authenticated user
     */
    public function me(Request $request, BaseHttpResponse $response)
    {
        $user = $request->user();

        return $response
            ->setData([
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'username' => $user->username,
                    'store_id' => $user->store_id ?? null,
                    'permissions' => $user->permissions,
                ],
            ])
            ->setMessage('User retrieved successfully');
    }

    /**
     * Refresh authentication token
     */
    public function refresh(Request $request, BaseHttpResponse $response)
    {
        $request->validate([
            'device_name' => 'nullable|string',
        ]);

        $user = $request->user();

        // Revoke current token
        $request->user()->currentAccessToken()->delete();

        // Create new token
        $deviceName = $request->input('device_name', 'POS Device');
        $token = $user->createToken($deviceName)->plainTextToken;

        return $response
            ->setData([
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'username' => $user->username,
                    'store_id' => $user->store_id ?? null,
                ],
            ])
            ->setMessage('Token refreshed successfully');
    }

    /**
     * Logout and revoke token
     */
    public function logout(Request $request, BaseHttpResponse $response)
    {
        // Revoke the current access token
        $request->user()->currentAccessToken()->delete();

        return $response
            ->setMessage('Logged out successfully');
    }
}
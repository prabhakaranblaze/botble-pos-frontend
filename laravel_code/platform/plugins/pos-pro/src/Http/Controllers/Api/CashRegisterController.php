<?php

namespace Botble\PosPro\Http\Controllers\Api;

use Botble\Base\Http\Controllers\BaseController;
use Botble\Base\Http\Responses\BaseHttpResponse;
use Botble\PosPro\Models\PosCashRegister;
use Illuminate\Http\Request;

class CashRegisterController extends BaseController
{
    /**
     * Get all cash registers for user's store WITH active session info
     * This allows Flutter to show which registers are occupied
     */
    public function index(Request $request, BaseHttpResponse $response)
    {
        $user = $request->user();
        $storeId = $user->store_id;

        // Get all registers with their active sessions
        $registers = PosCashRegister::query()
            ->when($storeId, function ($query, $storeId) {
                $query->where('store_id', $storeId);
            })
            ->with([
                'store',
                // ✅ Load active session if exists
                'sessions' => function ($query) {
                    $query->where('status', 'open')
                        ->with('user') // Include user info
                        ->latest('opened_at');
                }
            ])
            ->get()
            ->map(function ($register) {
                // Get active session (if any)
                $activeSession = $register->sessions->first();
                
                return [
                    'id' => $register->id,
                    'name' => $register->name,
                    'code' => $register->code,
                    'store_id' => $register->store_id,
                    'description' => $register->description,
                    'is_active' => $register->is_active,
                    'initial_float' => (float) $register->initial_float,
                    
                    // ✅ Add session status
                    'has_active_session' => $activeSession !== null,
                    'active_session' => $activeSession ? [
                        'id' => $activeSession->id,
                        'user_id' => $activeSession->user_id,
                        'user_name' => $activeSession->user->name ?? null,
                        'session_code' => $activeSession->session_code,
                        'opened_at' => $activeSession->opened_at->toIso8601String(),
                        'opening_cash' => (float) $activeSession->opening_cash,
                        // Calculate duration
                        'duration_hours' => $activeSession->opened_at->diffInHours(now()),
                        'duration_minutes' => $activeSession->opened_at->diffInMinutes(now()) % 60,
                    ] : null,
                ];
            });

        return $response
            ->setData([
                'cash_registers' => $registers,
            ])
            ->setMessage('Cash registers retrieved successfully');
    }

    /**
     * Get single cash register details
     */
    public function show(int $id, Request $request, BaseHttpResponse $response)
    {
        $user = $request->user();

        $register = PosCashRegister::query()
            ->where('id', $id)
            ->when($user->store_id, function ($query, $storeId) {
                $query->where('store_id', $storeId);
            })
            ->with(['store', 'sessions' => function ($query) {
                $query->where('status', 'open')->with('user');
            }])
            ->first();

        if (!$register) {
            return $response
                ->setError()
                ->setMessage('Cash register not found')
                ->setCode(404);
        }

        $activeSession = $register->sessions->first();

        return $response
            ->setData([
                'cash_register' => [
                    'id' => $register->id,
                    'name' => $register->name,
                    'code' => $register->code,
                    'store_id' => $register->store_id,
                    'description' => $register->description,
                    'is_active' => $register->is_active,
                    'has_active_session' => $activeSession !== null,
                    'active_session' => $activeSession ? [
                        'id' => $activeSession->id,
                        'user_id' => $activeSession->user_id,
                        'user_name' => $activeSession->user->name ?? null,
                        'opened_at' => $activeSession->opened_at->toIso8601String(),
                        'opening_cash' => (float) $activeSession->opening_cash,
                    ] : null,
                ],
            ])
            ->setMessage('Cash register retrieved successfully');
    }

    /**
     * Create new cash register (Admin only)
     */
    public function store(Request $request, BaseHttpResponse $response)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:50|unique:pos_cash_registers,code',
            'store_id' => 'required|exists:mp_stores,id',
            'description' => 'nullable|string',
            'initial_float' => 'nullable|numeric|min:0',
        ]);

        $register = PosCashRegister::create($validated);

        return $response
            ->setData([
                'cash_register' => $register,
            ])
            ->setMessage('Cash register created successfully')
            ->setCode(201);
    }

    /**
     * Update cash register (Admin only)
     */
    public function update(int $id, Request $request, BaseHttpResponse $response)
    {
        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'code' => 'sometimes|required|string|max:50|unique:pos_cash_registers,code,' . $id,
            'store_id' => 'sometimes|required|exists:mp_stores,id',
            'description' => 'nullable|string',
            'is_active' => 'sometimes|required|boolean',
        ]);

        $register = PosCashRegister::findOrFail($id);
        $register->update($validated);

        return $response
            ->setMessage('Cash register updated successfully');
    }

    /**
     * Delete cash register (Admin only)
     */
    public function destroy(int $id, BaseHttpResponse $response)
    {
        $register = PosCashRegister::findOrFail($id);
        
        // Check if register has active sessions
        if ($register->hasOpenSession()) {
            return $response
                ->setError()
                ->setMessage('Cannot delete cash register with active sessions');
        }

        $register->delete();

        return $response
            ->setMessage('Cash register deleted successfully');
    }
}
<?php

namespace Botble\PosPro\Http\Controllers\Api;

use Illuminate\Support\Facades\DB;
use Botble\Base\Http\Controllers\BaseController;
use Botble\Base\Http\Responses\BaseHttpResponse;
use Botble\PosPro\Models\PosSession;
use Illuminate\Http\Request;

class SessionController extends BaseController
{
    /**
     * Generate unique session code
     * Format: SES-YYYY-MM-DD-XXX
     */
    private function generateSessionCode(): string
    {
        $date = now()->format('Y-m-d');
        $prefix = "SES-{$date}-";

        $lastSession = PosSession::query()
            ->where('session_code', 'like', "{$prefix}%")
            ->orderBy('session_code', 'desc')
            ->first();

        if ($lastSession) {
            $lastNumber = (int) substr($lastSession->session_code, -3);
            $newNumber = $lastNumber + 1;
        } else {
            $newNumber = 1;
        }

        return $prefix . str_pad($newNumber, 3, '0', STR_PAD_LEFT);
    }
    
    /**
     * Get active session for current user
     * ✅ Enhanced to include register info for "Continue/Start Fresh" dialog
     */
    public function active(Request $request, BaseHttpResponse $response)
    {
        $user = $request->user();

        // Find user's open session with register and transaction details
        $session = PosSession::query()
            ->where('user_id', $user->id)
            ->where('status', 'open')
            ->with(['cashRegister', 'user', 'store', 'transactions'])
            ->first();

        if (!$session) {
            return $response
                ->setError()
                ->setMessage('No active session found')
                ->setCode(404);
        }

        // ✅ Return complete session data for Flutter dialog
        return $response
            ->setData([
                'session' => [
                    'id' => $session->id,
                    'cash_register_id' => $session->cash_register_id,
                    'cash_register_name' => $session->cashRegister->name ?? null,
                    'cash_register_code' => $session->cashRegister->code ?? null,
                    'user_id' => $session->user_id,
                    'user_name' => $session->user->name ?? null,
                    'store_id' => $session->store_id,
                    'session_code' => $session->session_code,
                    'status' => $session->status,
                    'opened_at' => $session->opened_at->toIso8601String(),
                    'opening_cash' => (float) $session->opening_cash,
                    'opening_denominations' => $session->opening_denominations,
                    'opening_notes' => $session->opening_notes,
                    // ✅ Add duration for dialog display
                    'duration_hours' => $session->opened_at->diffInHours(now()),
                    'duration_minutes' => $session->opened_at->diffInMinutes(now()) % 60,
                    // Transaction summary
                    'total_transactions' => $session->transactions->count(),
                ],
            ])
            ->setMessage('Active session retrieved successfully');
    }

    /**
     * Open new cash register session
     * ✅ Enhanced to check if register is already occupied
     */
    public function open(Request $request, BaseHttpResponse $response)
    {
        $request->validate([           
            'cash_register_id' => 'required|integer|exists:pos_cash_registers,id',
            'opening_cash' => 'required|numeric|min:0',
            'opening_denominations' => 'nullable|array',
            'opening_notes' => 'nullable|string|max:500',
        ]);

        $user = $request->user();

        // ✅ CHECK 1: Does this user already have an open session?
        $existingUserSession = PosSession::query()
            ->where('user_id', $user->id)
            ->where('status', 'open')
            ->first();
        
        if ($existingUserSession) {
            return $response
                ->setError()
                ->setMessage('You already have an open session. Please close it first.')
                ->setCode(409);
        }

        // ✅ CHECK 2: Is this register already occupied by someone else?
        $existingRegisterSession = PosSession::query()
            ->where('cash_register_id', $request->cash_register_id)
            ->where('status', 'open')
            ->with('user') // Load user info for error message
            ->first();
        
        if ($existingRegisterSession) {
            return $response
                ->setError()
                ->setMessage('This register is currently in use by ' . ($existingRegisterSession->user->name ?? 'another user'))
                ->setData([
                    'occupied_by' => [
                        'user_id' => $existingRegisterSession->user_id,
                        'user_name' => $existingRegisterSession->user->name ?? null,
                        'opened_at' => $existingRegisterSession->opened_at->toIso8601String(),
                        'duration_hours' => $existingRegisterSession->opened_at->diffInHours(now()),
                    ]
                ])
                ->setCode(409); // Conflict
        }

        // ✅ All checks passed - create new session
        $sessionCode = $this->generateSessionCode();

        $session = PosSession::create([
            'session_code' => $sessionCode,
            'user_id' => $user->id,
            'store_id' => $user->store_id,
            'cash_register_id' => $request->cash_register_id,
            'opening_cash' => $request->opening_cash,
            'opening_denominations' => $request->opening_denominations,
            'opening_notes' => $request->opening_notes,
            'opened_at' => now(),
            'status' => 'open',
        ]);

        // Load relationships for response
        $session->load(['cashRegister', 'user', 'store']);

        return $response
            ->setData([
                'session' => [
                    'id' => $session->id,
                    'cash_register_id' => $session->cash_register_id,
                    'cash_register_name' => $session->cashRegister->name ?? null,
                    'user_id' => $session->user_id,
                    'user_name' => $session->user->name ?? null,
                    'store_id' => $session->store_id,
                    'session_code' => $session->session_code,
                    'status' => $session->status,
                    'opened_at' => $session->opened_at->toIso8601String(),
                    'opening_cash' => (float) $session->opening_cash,
                    'opening_denominations' => $session->opening_denominations,
                    'opening_notes' => $session->opening_notes,
                ],
            ])
            ->setMessage('Session opened successfully')
            ->setCode(201);
    }

    /**
     * Close current session
     */
    public function close(Request $request, BaseHttpResponse $response)
    {
        $request->validate([
            'session_id' => 'required|integer|exists:pos_sessions,id',
            'closing_cash' => 'required|numeric|min:0',
            'closing_denominations' => 'nullable|array',
            'closing_notes' => 'nullable|string|max:500',
        ]);

        $user = $request->user();

        $session = PosSession::query()
            ->where('id', $request->session_id)
            ->where('user_id', $user->id)
            ->where('store_id', $user->store_id)
            ->where('status', 'open')
            ->with(['cashRegister', 'user', 'store', 'transactions'])
            ->first();
        
        if (!$session) {
            return $response
                ->setError()
                ->setMessage('Session not found or already closed')
                ->setCode(404);
        }
        
        try {
            // Use the model's close() method
            $session->close(
                $request->closing_cash,
                $request->closing_denominations,
                $request->closing_notes
            );

            // Refresh to get updated data
            $session->refresh();
            $session->load(['cashRegister', 'user', 'store']);

            // Return complete session object
            return $response
                ->setData([
                    'session' => [
                        'id' => $session->id,
                        'cash_register_id' => $session->cash_register_id,
                        'cash_register_name' => $session->cashRegister->name ?? null,
                        'user_id' => $session->user_id,
                        'user_name' => $session->user->name ?? null,
                        'store_id' => $session->store_id,
                        'session_code' => $session->session_code,
                        'status' => $session->status,
                        'opened_at' => $session->opened_at->toIso8601String(),
                        'closed_at' => $session->closed_at?->toIso8601String(),
                        'opening_cash' => (float) $session->opening_cash,
                        'closing_cash' => (float) $session->closing_cash,
                        'opening_denominations' => $session->opening_denominations,
                        'closing_denominations' => $session->closing_denominations,
                        'opening_notes' => $session->opening_notes,
                        'closing_notes' => $session->closing_notes,
                        'expected_cash' => (float) $session->expected_cash,
                        'cash_difference' => (float) $session->cash_difference,
                        'total_sales' => (float) $session->total_sales,
                        'total_transactions' => $session->total_transactions,
                        'cash_sales' => (float) $session->cash_sales,
                        'card_sales' => (float) $session->card_sales,
                        'other_sales' => (float) $session->other_sales,
                    ],
                ])
                ->setMessage('Session closed successfully');
        } catch (\Exception $e) {
            \Log::error('Failed to close session: ' . $e->getMessage());
            
            return $response
                ->setError()
                ->setMessage('Failed to close session: ' . $e->getMessage())
                ->setCode(500);
        }
    }

    /**
     * Get session history
     */
    public function history(Request $request, BaseHttpResponse $response)
    {
        $perPage = $request->input('per_page', 20);
        $user = $request->user();

        $sessions = PosSession::query()
            ->where('user_id', $user->id)
            ->with(['cashRegister', 'transactions'])
            ->latest('opened_at')
            ->paginate($perPage);

        return $response
            ->setData([
                'sessions' => $sessions,
                'pagination' => [
                    'current_page' => $sessions->currentPage(),
                    'last_page' => $sessions->lastPage(),
                    'per_page' => $sessions->perPage(),
                    'total' => $sessions->total(),
                ],
            ])
            ->setMessage('Session history retrieved successfully');
    }

    /**
     * Get session details by ID
     */
    public function show(int $id, Request $request, BaseHttpResponse $response)
    {
        $user = $request->user();

        $session = PosSession::query()
            ->where('id', $id)
            ->where('user_id', $user->id)
            ->with(['cashRegister', 'transactions'])
            ->first();
        
        if (!$session) {
            return $response
                ->setError()
                ->setMessage('Session not found')
                ->setCode(404);
        }

        return $response
            ->setData([
                'session' => $session,
            ])
            ->setMessage('Session retrieved successfully');
    }


    /**
     * Get denominations for a currency
     */
    public function getDenominations(Request $request, BaseHttpResponse $response)
    {
        $currency = $request->input('currency', 'USD');

        // Sample denomination data
        $denominations = [
            'USD' => [
                ['id' => 1, 'value' => 0.01, 'type' => 'coin', 'label' => '1¢'],
                ['id' => 2, 'value' => 0.05, 'type' => 'coin', 'label' => '5¢'],
                ['id' => 3, 'value' => 0.10, 'type' => 'coin', 'label' => '10¢'],
                ['id' => 4, 'value' => 0.25, 'type' => 'coin', 'label' => '25¢'],
                ['id' => 5, 'value' => 1.00, 'type' => 'note', 'label' => '$1'],
                ['id' => 6, 'value' => 5.00, 'type' => 'note', 'label' => '$5'],
                ['id' => 7, 'value' => 10.00, 'type' => 'note', 'label' => '$10'],
                ['id' => 8, 'value' => 20.00, 'type' => 'note', 'label' => '$20'],
                ['id' => 9, 'value' => 50.00, 'type' => 'note', 'label' => '$50'],
                ['id' => 10, 'value' => 100.00, 'type' => 'note', 'label' => '$100'],
            ],
            'INR' => [
                ['id' => 1, 'value' => 1, 'type' => 'coin', 'label' => '₹1'],
                ['id' => 2, 'value' => 2, 'type' => 'coin', 'label' => '₹2'],
                ['id' => 3, 'value' => 5, 'type' => 'coin', 'label' => '₹5'],
                ['id' => 4, 'value' => 10, 'type' => 'coin', 'label' => '₹10'],
                ['id' => 5, 'value' => 20, 'type' => 'note', 'label' => '₹20'],
                ['id' => 6, 'value' => 50, 'type' => 'note', 'label' => '₹50'],
                ['id' => 7, 'value' => 100, 'type' => 'note', 'label' => '₹100'],
                ['id' => 8, 'value' => 200, 'type' => 'note', 'label' => '₹200'],
                ['id' => 9, 'value' => 500, 'type' => 'note', 'label' => '₹500'],
                ['id' => 10, 'value' => 2000, 'type' => 'note', 'label' => '₹2000'],
            ],
        ];

        $data = $denominations[$currency] ?? $denominations['USD'];

        return $response
            ->setData([
                'currency' => $currency,
                'denominations' => $data,
            ])
            ->setMessage('Denominations retrieved successfully');
    }

    /**
     * Get available currencies
     */
    public function getCurrencies(BaseHttpResponse $response)
    {
        $currencies = [
            ['code' => 'USD', 'name' => 'US Dollar', 'symbol' => '$'],
            ['code' => 'INR', 'name' => 'Indian Rupee', 'symbol' => '₹'],
        ];

        return $response
            ->setData([
                'currencies' => $currencies,
            ])
            ->setMessage('Currencies retrieved successfully');
    }

    /**
     * Calculate total from denomination counts
     */
    public function calculateTotal(Request $request, BaseHttpResponse $response)
    {
        $request->validate([
            'denominations' => 'required|array',
            'denominations.*.denomination_id' => 'required|integer',
            'denominations.*.count' => 'required|integer|min:0',
        ]);

        // TODO: Implement actual calculation using denomination values from database
        $total = 0;
        $breakdown = [];

        foreach ($request->denominations as $item) {
            // Mock calculation - you'll need to fetch actual denomination values
            $value = 1.0; // Placeholder
            $count = $item['count'];
            $subtotal = $value * $count;
            
            $total += $subtotal;
            $breakdown[] = [
                'denomination_id' => $item['denomination_id'],
                'count' => $count,
                'value' => $value,
                'subtotal' => $subtotal,
            ];
        }

        return $response
            ->setData([
                'total' => $total,
                'breakdown' => $breakdown,
            ])
            ->setMessage('Total calculated successfully');
    }

    /**
     * Suggest denomination breakdown for an amount
     */
    public function suggestBreakdown(Request $request, BaseHttpResponse $response)
    {
        $request->validate([
            'amount' => 'required|numeric|min:0',
            'currency' => 'required|string|in:USD,INR',
        ]);

        $amount = $request->amount;
        $currency = $request->currency;

        // TODO: Implement smart breakdown algorithm
        // This is a simplified example
        $breakdown = [];

        return $response
            ->setData([
                'amount' => $amount,
                'currency' => $currency,
                'suggested_breakdown' => $breakdown,
            ])
            ->setMessage('Breakdown suggested successfully');
    }
}
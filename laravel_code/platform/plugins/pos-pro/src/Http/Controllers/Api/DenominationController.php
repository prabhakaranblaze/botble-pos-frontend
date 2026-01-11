<?php

namespace Botble\PosPro\Http\Controllers\Api;

use Botble\Base\Http\Controllers\BaseController;
use Botble\PosPro\Models\PosDenomination;
use Illuminate\Http\Request;

class DenominationController extends BaseController
{
    /**
     * Get available denominations for a currency.
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        $currencyCode = $request->input('currency', 'USD');

        $denominations = PosDenomination::query()
            ->forCurrency($currencyCode)
            ->active()
            ->ordered()
            ->get();

        // Group by type (coins and notes)
        $grouped = [
            'coins' => [],
            'notes' => [],
        ];

        foreach ($denominations as $denomination) {
            $data = [
                'id' => $denomination->id,
                'value' => (float) $denomination->value,
                'label' => $denomination->label,
                'type' => $denomination->type,
            ];

            if ($denomination->isCoin()) {
                $grouped['coins'][] = $data;
            } else {
                $grouped['notes'][] = $data;
            }
        }

        return response()->json([
            'success' => true,
            'data' => [
                'currency' => $currencyCode,
                'denominations' => $grouped,
            ],
        ], 200);
    }

    /**
     * Calculate total from denomination counts.
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function calculateTotal(Request $request)
    {
        $request->validate([
            'denominations' => 'required|array',
            'denominations.*.denomination_id' => 'required|exists:pos_denominations,id',
            'denominations.*.count' => 'required|integer|min:0',
        ]);

        $total = 0;
        $breakdown = [];

        foreach ($request->denominations as $item) {
            $denomination = PosDenomination::find($item['denomination_id']);
            $count = $item['count'];
            $subtotal = $denomination->value * $count;
            
            $total += $subtotal;

            $breakdown[] = [
                'denomination_id' => $denomination->id,
                'label' => $denomination->label,
                'value' => (float) $denomination->value,
                'count' => $count,
                'subtotal' => (float) $subtotal,
            ];
        }

        return response()->json([
            'success' => true,
            'data' => [
                'total' => (float) $total,
                'breakdown' => $breakdown,
            ],
        ], 200);
    }

    /**
     * Get all available currencies.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function currencies()
    {
        $currencies = PosDenomination::query()
            ->active()
            ->select('currency_code')
            ->distinct()
            ->get()
            ->pluck('currency_code');

        return response()->json([
            'success' => true,
            'data' => $currencies,
        ], 200);
    }

    /**
     * Suggest denomination breakdown for a target amount.
     * Uses a greedy algorithm to minimize number of bills/coins.
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function suggestBreakdown(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:0',
            'currency' => 'required|string|size:3',
        ]);

        $amount = (float) $request->amount;
        $currencyCode = $request->currency;

        // Get denominations in descending order
        $denominations = PosDenomination::query()
            ->forCurrency($currencyCode)
            ->active()
            ->orderBy('value', 'desc')
            ->get();

        $remaining = $amount;
        $breakdown = [];

        foreach ($denominations as $denomination) {
            if ($remaining >= $denomination->value) {
                $count = floor($remaining / $denomination->value);
                $subtotal = $count * $denomination->value;
                
                $breakdown[] = [
                    'denomination_id' => $denomination->id,
                    'label' => $denomination->label,
                    'value' => (float) $denomination->value,
                    'count' => (int) $count,
                    'subtotal' => (float) $subtotal,
                ];

                $remaining -= $subtotal;
                $remaining = round($remaining, 2); // Handle floating point precision
            }
        }

        return response()->json([
            'success' => true,
            'data' => [
                'requested_amount' => (float) $amount,
                'calculated_total' => (float) ($amount - $remaining),
                'remaining' => (float) $remaining,
                'breakdown' => $breakdown,
            ],
        ], 200);
    }
}

<?php

namespace Botble\PosPro\Services;

use Botble\Ecommerce\Models\Order;
use Botble\PosPro\Models\PosRegister;
use Carbon\Carbon;
use Exception;

class RegisterService
{
    public function getRegisterStatus(int $userId): array
    {
        $register = PosRegister::getOpenRegisterForUser($userId);

        if (! $register) {
            return [
                'is_open' => false,
                'register' => null,
                'message' => trans('plugins/pos-pro::pos.register_not_open'),
            ];
        }

        $cashSales = $this->calculateCashSales($userId, $register->opened_at);
        $expectedCash = $register->cash_start + $cashSales;

        return [
            'is_open' => true,
            'register' => [
                'id' => $register->id,
                'user_id' => $register->user_id,
                'cash_start' => (float) $register->cash_start,
                'opened_at' => $register->opened_at->toIso8601String(),
                'cash_sales' => $cashSales,
                'expected_cash' => $expectedCash,
            ],
            'message' => trans('plugins/pos-pro::pos.register_is_open'),
        ];
    }

    public function openRegister(int $userId, float $cashStart, ?string $notes = null): array
    {
        if (PosRegister::hasOpenRegister($userId)) {
            return [
                'error' => true,
                'message' => trans('plugins/pos-pro::pos.register_already_open'),
            ];
        }

        $register = PosRegister::query()->create([
            'user_id' => $userId,
            'cash_start' => $cashStart,
            'opened_at' => Carbon::now(),
            'status' => 'open',
            'notes' => $notes,
        ]);

        return [
            'error' => false,
            'register' => [
                'id' => $register->id,
                'user_id' => $register->user_id,
                'cash_start' => (float) $register->cash_start,
                'opened_at' => $register->opened_at->toIso8601String(),
                'status' => $register->status,
            ],
            'message' => trans('plugins/pos-pro::pos.register_opened'),
        ];
    }

    public function closeRegister(int $userId, float $actualCash, ?string $notes = null): array
    {
        $register = PosRegister::getOpenRegisterForUser($userId);

        if (! $register) {
            return [
                'error' => true,
                'message' => trans('plugins/pos-pro::pos.no_open_register'),
            ];
        }

        $cashSales = $this->calculateCashSales($userId, $register->opened_at);
        $expectedCash = $register->cash_start + $cashSales;
        $difference = $actualCash - $expectedCash;

        $register->update([
            'cash_end' => $expectedCash,
            'actual_cash' => $actualCash,
            'difference' => $difference,
            'closed_at' => Carbon::now(),
            'status' => 'closed',
            'notes' => $notes ?: $register->notes,
        ]);

        return [
            'error' => false,
            'register' => [
                'id' => $register->id,
                'user_id' => $register->user_id,
                'cash_start' => (float) $register->cash_start,
                'cash_end' => (float) $expectedCash,
                'actual_cash' => (float) $actualCash,
                'difference' => (float) $difference,
                'opened_at' => $register->opened_at->toIso8601String(),
                'closed_at' => $register->closed_at->toIso8601String(),
                'cash_sales' => $cashSales,
            ],
            'message' => trans('plugins/pos-pro::pos.register_closed'),
        ];
    }

    public function calculateCashSales(int $userId, Carbon $since): float
    {
        return (float) Order::query()
            ->whereHas('payment', function ($query): void {
                $query->where('payment_channel', POS_PRO_CASH_PAYMENT_METHOD_NAME);
            })
            ->where('created_at', '>=', $since)
            ->sum('amount');
    }

    public function getRegisterHistory(int $userId, int $limit = 20): array
    {
        $registers = PosRegister::query()
            ->forUser($userId)
            ->orderByDesc('opened_at')
            ->limit($limit)
            ->get();

        return $registers->map(function (PosRegister $register) {
            return [
                'id' => $register->id,
                'cash_start' => (float) $register->cash_start,
                'cash_end' => $register->cash_end ? (float) $register->cash_end : null,
                'actual_cash' => $register->actual_cash ? (float) $register->actual_cash : null,
                'difference' => (float) $register->difference,
                'opened_at' => $register->opened_at->toIso8601String(),
                'closed_at' => $register->closed_at?->toIso8601String(),
                'status' => $register->status,
                'notes' => $register->notes,
            ];
        })->toArray();
    }

    public function requireOpenRegister(int $userId): void
    {
        if (! PosRegister::hasOpenRegister($userId)) {
            throw new Exception(trans('plugins/pos-pro::pos.register_must_be_open'));
        }
    }
}

<?php

namespace Botble\PosPro\Services;

use Illuminate\Support\Facades\Session;

class OrderSlotService
{
    protected string $activeSlotKey = 'pos_active_order_slot';

    protected string $slotsKey = 'pos_order_slots';

    protected int $maxSlots = 10;

    public function getActiveSlot(): int
    {
        $activeSlot = Session::get($this->activeSlotKey, 1);
        $slots = $this->getSlots();

        if (! in_array($activeSlot, $slots)) {
            $activeSlot = $slots[0] ?? 1;
            Session::put($this->activeSlotKey, $activeSlot);
        }

        return $activeSlot;
    }

    public function setActiveSlot(int $slot): array
    {
        $slots = $this->getSlots();

        if (! in_array($slot, $slots)) {
            return [
                'error' => true,
                'message' => trans('plugins/pos-pro::pos.order_slot_not_found'),
            ];
        }

        Session::put($this->activeSlotKey, $slot);

        return [
            'error' => false,
            'active_slot' => $slot,
            'slots' => $slots,
            'message' => trans('plugins/pos-pro::pos.order_slot_switched'),
        ];
    }

    public function getSlots(): array
    {
        $slots = Session::get($this->slotsKey, [1]);

        if (empty($slots)) {
            $slots = [1];
            Session::put($this->slotsKey, $slots);
        }

        return $slots;
    }

    public function createSlot(): array
    {
        $slots = $this->getSlots();

        if (count($slots) >= $this->maxSlots) {
            return [
                'error' => true,
                'message' => trans('plugins/pos-pro::pos.max_order_slots_reached', ['max' => $this->maxSlots]),
            ];
        }

        $newSlot = max($slots) + 1;
        $slots[] = $newSlot;

        Session::put($this->slotsKey, $slots);
        Session::put($this->activeSlotKey, $newSlot);

        return [
            'error' => false,
            'active_slot' => $newSlot,
            'slots' => $slots,
            'message' => trans('plugins/pos-pro::pos.order_slot_created'),
        ];
    }

    public function closeSlot(int $slot, CartService $cartService): array
    {
        $slots = $this->getSlots();

        if (count($slots) <= 1) {
            return [
                'error' => true,
                'message' => trans('plugins/pos-pro::pos.cannot_close_last_slot'),
            ];
        }

        if (! in_array($slot, $slots)) {
            return [
                'error' => true,
                'message' => trans('plugins/pos-pro::pos.order_slot_not_found'),
            ];
        }

        $cartService->clearCart($this->getSessionPrefix($slot));

        $slots = array_values(array_filter($slots, fn ($s) => $s !== $slot));
        Session::put($this->slotsKey, $slots);

        $activeSlot = $this->getActiveSlot();
        if ($activeSlot === $slot) {
            $activeSlot = $slots[0];
            Session::put($this->activeSlotKey, $activeSlot);
        }

        return [
            'error' => false,
            'active_slot' => $activeSlot,
            'slots' => $slots,
            'message' => trans('plugins/pos-pro::pos.order_slot_closed'),
        ];
    }

    public function closeSlotAfterCheckout(int $slot): array
    {
        $slots = $this->getSlots();

        if (count($slots) <= 1) {
            return [
                'error' => false,
                'active_slot' => $slot,
                'slots' => $slots,
                'message' => trans('plugins/pos-pro::pos.order_completed'),
            ];
        }

        if (! in_array($slot, $slots)) {
            return [
                'error' => true,
                'message' => trans('plugins/pos-pro::pos.order_slot_not_found'),
            ];
        }

        $slots = array_values(array_filter($slots, fn ($s) => $s !== $slot));
        Session::put($this->slotsKey, $slots);

        $activeSlot = $slots[0];
        Session::put($this->activeSlotKey, $activeSlot);

        return [
            'error' => false,
            'active_slot' => $activeSlot,
            'slots' => $slots,
            'message' => trans('plugins/pos-pro::pos.order_slot_closed'),
        ];
    }

    public function getSessionPrefix(?int $slot = null): string
    {
        $slot = $slot ?? $this->getActiveSlot();

        return "order_{$slot}_";
    }

    public function getSlotsWithCarts(CartService $cartService): array
    {
        $slots = $this->getSlots();
        $activeSlot = $this->getActiveSlot();
        $slotsWithCarts = [];

        foreach ($slots as $slot) {
            $prefix = $this->getSessionPrefix($slot);
            $cart = $cartService->getCart($prefix);

            $slotsWithCarts[] = [
                'slot' => $slot,
                'is_active' => $slot === $activeSlot,
                'item_count' => $cart['count'] ?? 0,
                'total' => $cart['total'] ?? 0,
                'total_formatted' => $cart['total_formatted'] ?? format_price(0),
            ];
        }

        return $slotsWithCarts;
    }

    public function clearAllSlots(CartService $cartService): void
    {
        $slots = $this->getSlots();

        foreach ($slots as $slot) {
            $prefix = $this->getSessionPrefix($slot);
            $cartService->clearCart($prefix);
        }

        Session::put($this->slotsKey, [1]);
        Session::put($this->activeSlotKey, 1);
    }
}

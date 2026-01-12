<?php

namespace Botble\PosPro\Http\Controllers\Api;

use Botble\Base\Http\Controllers\BaseController;
use Botble\Base\Http\Responses\BaseHttpResponse;
use Botble\Ecommerce\Models\Order;
use Illuminate\Http\Request;

class OrderController extends BaseController
{
    /**
     * Get order history with pagination
     */
    public function history(Request $request, BaseHttpResponse $response)
    {
        $perPage = $request->input('per_page', 20);
        $sessionId = $request->input('session_id');

        $query = Order::query()
            ->whereHas('payment', function ($query) {
                $query->whereIn('payment_channel', ['pos_cash', 'pos_card', 'pos_other']);
            })
            ->with(['products', 'payment', 'address', 'user'])
            ->latest();

        // Filter by session if provided
        if ($sessionId) {
            $query->where('session_id', $sessionId);
        }

        // Filter by user's store if applicable
        $user = $request->user();
        if ($user->store_id) {
            $query->where('store_id', $user->store_id);
        }

        $orders = $query->paginate($perPage);

        return $response
            ->setData([
                'orders' => $orders->map(function ($order) {
                    return $this->transformOrder($order);
                }),
                'pagination' => [
                    'current_page' => $orders->currentPage(),
                    'last_page' => $orders->lastPage(),
                    'per_page' => $orders->perPage(),
                    'total' => $orders->total(),
                    'from' => $orders->firstItem(),
                    'to' => $orders->lastItem(),
                ],
            ])
            ->setMessage('Order history retrieved successfully');
    }

    /**
     * Get single order details
     */
    public function show(int $id, Request $request, BaseHttpResponse $response)
    {
        $query = Order::query()
            ->where('id', $id)
            ->with(['products', 'payment', 'address', 'user']);

        // Filter by user's store if applicable
        $user = $request->user();
        if ($user->store_id) {
            $query->where('store_id', $user->store_id);
        }

        $order = $query->first();

        if (!$order) {
            return $response
                ->setError()
                ->setMessage('Order not found')
                ->setCode(404);
        }

        return $response
            ->setData([
                'order' => $this->transformOrder($order, true),
            ])
            ->setMessage('Order retrieved successfully');
    }

    /**
     * Transform order to API format
     */
    protected function transformOrder(Order $order, bool $detailed = false): array
    {
        $data = [
            'id' => $order->id,
            'code' => $order->code,
            'status' => $order->status,
            'amount' => (float) $order->amount,
            'tax_amount' => (float) $order->tax_amount,
            'shipping_amount' => (float) $order->shipping_amount,
            'discount_amount' => (float) $order->discount_amount,
            'sub_total' => (float) $order->sub_total,
            'payment_method' => $order->payment?->payment_channel ?? null,
            'created_at' => $order->created_at?->toDateTimeString(),
            'customer' => $order->user ? [
                'id' => $order->user->id,
                'name' => $order->user->name,
                'email' => $order->user->email,
                'phone' => $order->user->phone,
            ] : null,
        ];

        if ($detailed) {
            $data['products'] = $order->products->map(function ($product) {
                return [
                    'id' => $product->id,
                    'name' => $product->name,
                    'sku' => $product->pivot->product_name ?? $product->sku,
                    'quantity' => $product->pivot->qty,
                    'price' => (float) $product->pivot->price,
                    'total' => (float) ($product->pivot->price * $product->pivot->qty),
                ];
            });

            if ($order->address) {
                $data['address'] = [
                    'name' => $order->address->name,
                    'phone' => $order->address->phone,
                    'email' => $order->address->email,
                    'address' => $order->address->address,
                    'city' => $order->address->city,
                    'state' => $order->address->state,
                    'country' => $order->address->country,
                    'zip_code' => $order->address->zip_code,
                ];
            }

            $data['notes'] = $order->description;
        }

        return $data;
    }
}
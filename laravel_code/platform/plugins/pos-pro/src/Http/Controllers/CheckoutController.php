<?php

namespace Botble\PosPro\Http\Controllers;

use Botble\Base\Facades\BaseHelper;
use Botble\Base\Http\Controllers\BaseController;
use Botble\Base\Http\Responses\BaseHttpResponse;
use Botble\Ecommerce\Enums\OrderAddressTypeEnum;
use Botble\Ecommerce\Enums\OrderHistoryActionEnum;
use Botble\Ecommerce\Enums\OrderStatusEnum;
use Botble\Ecommerce\Enums\ShippingCodStatusEnum;
use Botble\Ecommerce\Enums\ShippingMethodEnum;
use Botble\Ecommerce\Enums\ShippingStatusEnum;
use Botble\Ecommerce\Events\OrderCreated;
use Botble\Ecommerce\Facades\EcommerceHelper;
use Botble\Ecommerce\Facades\OrderHelper;
use Botble\Ecommerce\Models\Customer;
use Botble\Ecommerce\Models\Order;
use Botble\Ecommerce\Models\OrderAddress;
use Botble\Ecommerce\Models\OrderHistory;
use Botble\Ecommerce\Models\OrderProduct;
use Botble\Ecommerce\Models\Product;
use Botble\Ecommerce\Models\Shipment;
use Botble\Ecommerce\Models\ShipmentHistory;
use Botble\Ecommerce\Services\TaxRateCalculatorService;
use Botble\Payment\Enums\PaymentStatusEnum;
use Botble\Payment\Models\Payment;
use Botble\PosPro\Services\CartService;
use Botble\PosPro\Services\MarketplaceOrderService;
use Botble\PosPro\Services\OrderSlotService;
use Botble\PosPro\Services\RegisterService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CheckoutController extends BaseController
{
    public function __construct(
        protected CartService $cartService,
        protected OrderSlotService $orderSlotService,
        protected RegisterService $registerService
    ) {
    }

    protected function getSessionPrefix(): string
    {
        return $this->orderSlotService->getSessionPrefix();
    }

    public function checkout(Request $request, BaseHttpResponse $response)
    {
        try {
            // Check if register is required and open
            if (setting('pos_pro_require_register', false)) {
                $userId = auth()->id();
                $registerStatus = $this->registerService->getRegisterStatus($userId);

                if (! $registerStatus['is_open']) {
                    return $response
                        ->setError()
                        ->setMessage(trans('plugins/pos-pro::pos.register_required'))
                        ->toApiResponse();
                }
            }

            $sessionPrefix = $this->getSessionPrefix();
            $cart = $this->cartService->getCart($sessionPrefix);

            if (empty($cart['items'])) {
                return $response
                    ->setError()
                    ->setMessage(trans('plugins/pos-pro::pos.cart_is_empty'))
                    ->toApiResponse();
            }

            if (is_plugin_active('marketplace')) {
                $marketplaceService = app(MarketplaceOrderService::class);

                try {
                    $result = $marketplaceService->processCheckout($request);

                    $message = trans('plugins/pos-pro::pos.order_completed_successfully');

                    if (isset($cart['manual_discount']) && $cart['manual_discount'] > 0) {
                        $message .= ' ' . trans('plugins/pos-pro::pos.discount_reset_after_checkout');
                    }

                    $orders = $result['orders'];

                    $mainOrder = $orders->first();

                    return $response
                        ->setData([
                            'order' => $mainOrder,
                            'order_code' => $mainOrder->code,
                            'order_id' => $mainOrder->id,
                            'order_ids' => $orders->pluck('id')->toArray(),
                            'orders' => $orders->map(fn ($order) => [
                                'id' => $order->id,
                                'code' => $order->code,
                                'store_id' => $order->store_id,
                                'store_name' => $order->store?->name ?: 'Main Store',
                                'amount' => $order->amount,
                            ]),
                            'message' => $message,
                        ])
                        ->setMessage($message)
                        ->toApiResponse();

                } catch (Exception $e) {
                    if (App::hasDebugModeEnabled()) {
                        throw $e;
                    }

                    return $response
                        ->setError()
                        ->setMessage($e->getMessage())
                        ->toApiResponse();
                }
            }

            DB::beginTransaction();

            $cart = $this->cartService->getCart($sessionPrefix);
            $customerId = $cart['customer_id'];
            $customerName = 'Guest';
            $customerPhone = 'N/A';
            $customerEmail = 'guest@example.com';

            $customer = null;
            if ($customerId) {
                /**
                 * @var Customer $customer
                 */
                $customer = Customer::query()->find($customerId);
                if ($customer) {
                    $customerName = $customer->name;
                    $customerPhone = $customer->phone ?: 'N/A';
                    $customerEmail = $customer->email ?: 'guest@example.com';
                }
            }

            /**
             * @var Order $order
             */
            $order = Order::query()->create([
                'user_id' => $customerId ?: 0,
                'amount' => $cart['total'],
                'sub_total' => $cart['subtotal'],
                'tax_amount' => $cart['tax'],
                'shipping_amount' => $cart['shipping_amount'] ?? 0,
                'discount_amount' => $cart['manual_discount'] ?? 0,
                'currency_id' => get_application_currency_id(),
                'payment_id' => null,
                'payment_method' => $this->mapPaymentMethod($request->input('payment_method', 'cash')),
                'payment_status' => PaymentStatusEnum::PENDING,
                'status' => 'pending',
                'description' => $request->input('notes'),
                'is_finished' => true,
                'shipping_method' => ShippingMethodEnum::DEFAULT,
                'shipping_option' => null,
            ]);

            $deliveryOption = $request->input('delivery_option', 'pickup');
            $isPickup = $deliveryOption === 'pickup';

            if (! $isPickup) {
                $addressData = [
                    'order_id' => $order->id,
                    'name' => $customerName,
                    'phone' => $customerPhone,
                    'email' => $customerEmail,
                    'type' => OrderAddressTypeEnum::SHIPPING,
                ];

                $addressInput = $request->input('address', []);
                $addressId = $addressInput['address_id'] ?? null;

                if ($customer && $addressId && $addressId !== 'new') {
                    $customerAddress = $customer->addresses()->find($addressId);
                    if ($customerAddress) {
                        $addressData['name'] = $customerAddress->name;
                        $addressData['phone'] = $customerAddress->phone;
                        $addressData['email'] = $customerAddress->email;
                        $addressData['country'] = $customerAddress->country;
                        $addressData['state'] = $customerAddress->state;
                        $addressData['city'] = $customerAddress->city;
                        $addressData['address'] = $customerAddress->address;
                        $addressData['zip_code'] = $customerAddress->zip_code;
                    }
                } else {
                    $addressData['name'] = $addressInput['name'] ?? $customerName;
                    $addressData['phone'] = $addressInput['phone'] ?? $customerPhone;
                    $addressData['email'] = $addressInput['email'] ?? $customerEmail;
                    $addressData['country'] = $addressInput['country'] ?? '';
                    $addressData['state'] = $addressInput['state'] ?? '';
                    $addressData['city'] = $addressInput['city'] ?? '';
                    $addressData['address'] = $addressInput['address'] ?? '';
                    $addressData['zip_code'] = $addressInput['zip_code'] ?? '';
                }

                OrderAddress::query()->create($addressData);

                $addressData['type'] = OrderAddressTypeEnum::BILLING;
                OrderAddress::query()->create($addressData);
            } else {
                $storeAddress = [
                    'order_id' => $order->id,
                    'name' => $customerName,
                    'phone' => $customerPhone,
                    'email' => $customerEmail,
                    'type' => OrderAddressTypeEnum::SHIPPING,
                    'address' => trans('plugins/pos-pro::pos.pickup_at_store'),
                    'city' => '',
                    'state' => '',
                    'country' => '',
                    'zip_code' => '',
                ];

                OrderAddress::query()->create($storeAddress);

                $storeAddress['type'] = OrderAddressTypeEnum::BILLING;
                OrderAddress::query()->create($storeAddress);
            }

            $taxRateCalculator = app(TaxRateCalculatorService::class);
            $country = EcommerceHelper::isUsingInMultipleCountries()
                ? null
                : EcommerceHelper::getFirstCountryId();

            foreach ($cart['items'] as $item) {
                $product = Product::query()->find($item['id']);
                $taxRate = $taxRateCalculator->execute($product, $country, null, null, null);

                $options = [
                    'image' => $product->image ?? '',
                    'attributes' => '',
                    'taxRate' => $taxRate,
                    'taxClasses' => $taxRate > 0 ? ['VAT' => $taxRate] : [],
                    'options' => [],
                    'extras' => [],
                    'sku' => $product->sku ?? '',
                    'weight' => $product->weight ?? 0,
                ];

                if (! empty($item['attributes'])) {
                    $attributeLabels = [];

                    foreach ($item['attributes'] as $attributeItem) {
                        if (isset($attributeItem['set']) && isset($attributeItem['value'])) {
                            $attributeLabels[] = $attributeItem['set'] . ': ' . $attributeItem['value'];
                        }
                    }

                    if (! empty($attributeLabels)) {
                        $options['attributes'] = '(' . implode(', ', $attributeLabels) . ')';
                    }
                }

                $itemPrice = $item['price'] * $item['quantity'];

                $priceIncludesTax = $product->is_variation
                    ? $product->original_product->price_includes_tax
                    : $product->price_includes_tax;

                if ($priceIncludesTax) {
                    $taxAmount = $itemPrice - ($itemPrice / (1 + $taxRate / 100));
                } else {
                    $taxAmount = $itemPrice * ($taxRate / 100);
                }

                $taxAmount = EcommerceHelper::roundPrice($taxAmount);

                OrderProduct::query()->create([
                    'order_id' => $order->id,
                    'product_id' => $product->id,
                    'product_name' => $product->name,
                    'product_image' => $product->image,
                    'qty' => $item['quantity'],
                    'price' => $item['price'],
                    'tax_amount' => $taxAmount,
                    'options' => $options,
                ]);

                if ($product->with_storehouse_management) {
                    $product->quantity -= $item['quantity'];
                    $product->save();
                }
            }

            OrderHistory::query()->create([
                'action' => 'create_order',
                'description' => trans('plugins/pos-pro::pos.order_created_by_pos'),
                'order_id' => $order->id,
                'user_id' => auth()->id(),
            ]);

            if (is_plugin_active('payment')) {
                $paymentMethod = $this->mapPaymentMethod($request->input('payment_method', 'cash'));
                $paymentStatus = PaymentStatusEnum::PENDING;

                $paymentFee = (float) get_payment_setting('fee', $paymentMethod, 0);

                $paymentData = [
                    'amount' => $order->amount,
                    'payment_fee' => $paymentFee,
                    'currency' => get_application_currency()->title,
                    'payment_channel' => $paymentMethod,
                    'status' => $paymentStatus,
                    'payment_type' => 'confirm',
                    'order_id' => $order->id,
                    'charge_id' => Str::upper(Str::random(10)),
                    'user_id' => auth()->id() ?: 0,
                ];

                $customerId = $request->input('customer_id');
                if ($customerId) {
                    $paymentData['customer_id'] = $customerId;
                    $paymentData['customer_type'] = Customer::class;
                }

                $payment = Payment::query()->create($paymentData);

                $order->payment_id = $payment->id;
                $order->save();
            }

            OrderHelper::confirmOrder($order);

            if (is_plugin_active('payment') && isset($payment)) {
                OrderHelper::confirmPayment($order);
            }

            // Create shipment for POS orders
            $weight = 0;
            foreach ($order->products as $orderProduct) {
                $product = Product::query()->find($orderProduct->product_id);
                if ($product) {
                    $weight += $product->weight * $orderProduct->qty;
                }
            }

            $shipmentStoreId = $order->store_id;
            if (! $shipmentStoreId && function_exists('get_primary_store_locator')) {
                $store = get_primary_store_locator();
                $shipmentStoreId = $store?->id;
            }

            try {
                $existingShipment = Shipment::query()->where('order_id', $order->id)->first();

                if (! $existingShipment) {
                    if ($isPickup) {
                        $shipment = Shipment::query()->create([
                            'order_id' => $order->id,
                            'user_id' => auth()->id() ?: 0,
                            'weight' => $weight,
                            'cod_amount' => 0,
                            'cod_status' => ShippingCodStatusEnum::COMPLETED,
                            'type' => ShippingMethodEnum::DEFAULT,
                            'status' => ShippingStatusEnum::DELIVERED,
                            'price' => 0,
                            'store_id' => $shipmentStoreId,
                        ]);

                        if ($shipment) {
                            ShipmentHistory::query()->create([
                                'action' => 'pickup_at_store',
                                'description' => trans('plugins/pos-pro::pos.order_completed_pickup'),
                                'shipment_id' => $shipment->id,
                                'order_id' => $order->id,
                                'user_id' => auth()->id() ?: 0,
                            ]);
                        }
                    } else {
                        $shipment = Shipment::query()->create([
                            'order_id' => $order->id,
                            'user_id' => auth()->id() ?: 0,
                            'weight' => $weight,
                            'cod_amount' => (is_plugin_active('payment') && $order->payment && $order->payment->status != PaymentStatusEnum::COMPLETED) ? $order->amount : 0,
                            'cod_status' => ShippingCodStatusEnum::PENDING,
                            'type' => ShippingMethodEnum::DEFAULT,
                            'status' => ShippingStatusEnum::PENDING,
                            'price' => $order->shipping_amount,
                            'store_id' => $shipmentStoreId,
                        ]);

                        if ($shipment) {
                            ShipmentHistory::query()->create([
                                'action' => 'create_from_pos',
                                'description' => trans('plugins/ecommerce::order.shipping_was_created_from_pos', ['order_id' => $order->code]),
                                'shipment_id' => $shipment->id,
                                'order_id' => $order->id,
                                'user_id' => auth()->id() ?: 0,
                            ]);

                            OrderHistory::query()->create([
                                'action' => 'create_shipment',
                                'description' => trans('plugins/ecommerce::order.shipping_was_created_from', [
                                    'order_id' => $order->code,
                                ]),
                                'order_id' => $order->id,
                                'user_id' => auth()->id() ?: 0,
                            ]);
                        }
                    }
                }

                if ($isPickup) {
                    $order->status = OrderStatusEnum::COMPLETED;
                    $order->save();

                    OrderHistory::query()->create([
                        'action' => OrderHistoryActionEnum::MARK_ORDER_AS_COMPLETED,
                        'description' => trans('plugins/pos-pro::pos.order_completed_pickup'),
                        'order_id' => $order->id,
                        'user_id' => auth()->id() ?: 0,
                    ]);
                }
            } catch (Exception $exception) {
                BaseHelper::logError($exception);
            }

            try {
                event(new OrderCreated($order));
            } catch (Exception $exception) {
                BaseHelper::logError($exception);
            }

            if ($isPickup) {
                OrderHelper::setOrderCompleted($order->id, $request, auth()->id() ?: 0);
            }

            DB::commit();

            $hadManualDiscount = isset($cart['manual_discount']) && $cart['manual_discount'] > 0;

            $this->cartService->clearCart($sessionPrefix);

            $this->cartService->resetCustomerAndPayment($sessionPrefix);

            $activeSlot = $this->orderSlotService->getActiveSlot();
            $this->orderSlotService->closeSlotAfterCheckout($activeSlot);

            $message = trans('plugins/pos-pro::pos.order_completed_successfully');

            if ($hadManualDiscount) {
                $message .= ' ' . trans('plugins/pos-pro::pos.discount_reset_after_checkout');
            }

            return $response
                ->setData([
                    'order' => $order,
                    'order_code' => $order->code,
                    'order_id' => $order->id,
                    'message' => $message,
                ])
                ->setMessage($message)
                ->toApiResponse();

        } catch (Exception $e) {
            DB::rollBack();

            if (App::hasDebugModeEnabled()) {
                throw $e;
            }

            return $response
                ->setError()
                ->setMessage($e->getMessage())
                ->toApiResponse();
        }
    }

    public function receipt($orderIds)
    {
        $this->pageTitle(trans('plugins/pos-pro::pos.receipt'));

        if (! is_array($orderIds)) {
            if (str_contains($orderIds, ',')) {
                $orderIds = explode(',', $orderIds);
            } else {
                $orderIds = [$orderIds];
            }
        }

        $query = Order::query()
            ->whereIn('id', $orderIds)
            ->with(['products', 'user', 'address', 'payment']);

        if (is_plugin_active('marketplace')) {
            $query->with('store');
        }

        $orders = $query->get();

        abort_if($orders->isEmpty(), 404);

        if ($orders->count() === 1) {
            $order = $orders->first();

            return view('plugins/pos-pro::receipt', compact('order', 'orders'));
        }

        return view('plugins/pos-pro::receipt-multiple', compact('orders'));
    }

    protected function mapPaymentMethod(string $posMethod): string
    {
        return match ($posMethod) {
            'card' => POS_PRO_CARD_PAYMENT_METHOD_NAME,
            'other' => POS_PRO_OTHER_PAYMENT_METHOD_NAME,
            default => POS_PRO_CASH_PAYMENT_METHOD_NAME,
        };
    }

    public function printReceipt($orderId)
    {
        $order = Order::query()
            ->where('id', $orderId)
            ->with(['products', 'user', 'address', 'payment', 'invoice'])
            ->firstOrFail();

        return view('plugins/pos-pro::receipt-print', compact('order'));
    }

    public function printReceiptMultiple($orderIds)
    {
        if (! is_array($orderIds)) {
            if (str_contains($orderIds, ',')) {
                $orderIds = explode(',', $orderIds);
            } else {
                $orderIds = [$orderIds];
            }
        }

        $query = Order::query()
            ->whereIn('id', $orderIds)
            ->with(['products', 'user', 'address', 'payment', 'invoice']);

        if (is_plugin_active('marketplace')) {
            $query->with('store');
        }

        $orders = $query->get();

        abort_if($orders->isEmpty(), 404);

        if ($orders->count() === 1) {
            $order = $orders->first();

            return view('plugins/pos-pro::receipt-print', compact('order'));
        }

        return view('plugins/pos-pro::receipt-print-multiple', compact('orders'));
    }
}

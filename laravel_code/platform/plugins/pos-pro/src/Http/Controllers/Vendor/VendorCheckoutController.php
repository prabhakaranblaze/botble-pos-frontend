<?php

namespace Botble\PosPro\Http\Controllers\Vendor;

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
use Botble\PosPro\Traits\HasVendorContext;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class VendorCheckoutController extends BaseController
{
    use HasVendorContext;

    public function __construct(protected CartService $cartService)
    {
    }

    public function checkout(Request $request, BaseHttpResponse $response)
    {
        try {
            $storeId = $this->getStoreId();
            $store = $this->getVendorStore();
            $cart = $this->cartService->getCart($this->getCartSessionPrefix());

            if (empty($cart['items'])) {
                return $response
                    ->setError()
                    ->setMessage(trans('plugins/pos-pro::pos.cart_is_empty'))
                    ->toApiResponse();
            }

            DB::beginTransaction();

            $customerId = $cart['customer_id'];
            $customerName = 'Guest';
            $customerPhone = 'N/A';
            $customerEmail = 'guest@example.com';

            $customer = null;
            if ($customerId) {
                $customer = Customer::query()->find($customerId);
                if ($customer) {
                    $customerName = $customer->name;
                    $customerPhone = $customer->phone ?: 'N/A';
                    $customerEmail = $customer->email ?: 'guest@example.com';
                }
            }

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
                'store_id' => $storeId,
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
                'description' => trans('plugins/pos-pro::pos.order_created_by_vendor_pos'),
                'order_id' => $order->id,
                'user_id' => 0,
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
                    'user_id' => 0,
                ];

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

            // Create shipment for vendor POS orders
            $weight = 0;
            foreach ($order->products as $orderProduct) {
                $product = Product::query()->find($orderProduct->product_id);
                if ($product) {
                    $weight += $product->weight * $orderProduct->qty;
                }
            }

            try {
                $existingShipment = Shipment::query()->where('order_id', $order->id)->first();

                if (! $existingShipment) {
                    if ($isPickup) {
                        $shipment = Shipment::query()->create([
                            'order_id' => $order->id,
                            'user_id' => 0,
                            'weight' => $weight,
                            'cod_amount' => 0,
                            'cod_status' => ShippingCodStatusEnum::COMPLETED,
                            'type' => ShippingMethodEnum::DEFAULT,
                            'status' => ShippingStatusEnum::DELIVERED,
                            'price' => 0,
                            'store_id' => $storeId,
                        ]);

                        if ($shipment) {
                            ShipmentHistory::query()->create([
                                'action' => 'pickup_at_store',
                                'description' => trans('plugins/pos-pro::pos.order_completed_pickup'),
                                'shipment_id' => $shipment->id,
                                'order_id' => $order->id,
                                'user_id' => 0,
                            ]);
                        }
                    } else {
                        $shipment = Shipment::query()->create([
                            'order_id' => $order->id,
                            'user_id' => 0,
                            'weight' => $weight,
                            'cod_amount' => (is_plugin_active('payment') && $order->payment && $order->payment->status != PaymentStatusEnum::COMPLETED) ? $order->amount : 0,
                            'cod_status' => ShippingCodStatusEnum::PENDING,
                            'type' => ShippingMethodEnum::DEFAULT,
                            'status' => ShippingStatusEnum::PENDING,
                            'price' => $order->shipping_amount,
                            'store_id' => $storeId,
                        ]);

                        if ($shipment) {
                            ShipmentHistory::query()->create([
                                'action' => 'create_from_pos',
                                'description' => trans('plugins/ecommerce::order.shipping_was_created_from_pos', ['order_id' => $order->code]),
                                'shipment_id' => $shipment->id,
                                'order_id' => $order->id,
                                'user_id' => 0,
                            ]);

                            OrderHistory::query()->create([
                                'action' => 'create_shipment',
                                'description' => trans('plugins/ecommerce::order.shipping_was_created_from', [
                                    'order_id' => $order->code,
                                ]),
                                'order_id' => $order->id,
                                'user_id' => 0,
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
                        'user_id' => 0,
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
                OrderHelper::setOrderCompleted($order->id, $request, 0);
            }

            DB::commit();

            $hadManualDiscount = isset($cart['manual_discount']) && $cart['manual_discount'] > 0;

            $this->cartService->clearCart($this->getCartSessionPrefix());
            $this->cartService->resetCustomerAndPayment($this->getCartSessionPrefix());

            $message = trans('plugins/pos-pro::pos.order_completed_successfully');

            if ($hadManualDiscount) {
                $message .= ' ' . trans('plugins/pos-pro::pos.discount_reset_after_checkout');
            }

            return $response
                ->setData([
                    'order' => $order,
                    'order_code' => $order->code,
                    'order_id' => $order->id,
                    'store_id' => $storeId,
                    'store_name' => $store->name,
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

        $storeId = $this->getStoreId();

        if (! is_array($orderIds)) {
            if (str_contains($orderIds, ',')) {
                $orderIds = explode(',', $orderIds);
            } else {
                $orderIds = [$orderIds];
            }
        }

        $orders = Order::query()
            ->whereIn('id', $orderIds)
            ->where('store_id', $storeId)
            ->with(['products', 'user', 'address', 'payment', 'store'])
            ->get();

        abort_if($orders->isEmpty(), 404);

        $routePrefix = 'marketplace.vendor.pos';

        if ($orders->count() === 1) {
            $order = $orders->first();

            return view('plugins/pos-pro::receipt', compact('order', 'orders', 'routePrefix'));
        }

        return view('plugins/pos-pro::receipt-multiple', compact('orders', 'routePrefix'));
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
        $storeId = $this->getStoreId();

        $order = Order::query()
            ->where('id', $orderId)
            ->where('store_id', $storeId)
            ->with(['products', 'user', 'address', 'payment', 'invoice', 'store'])
            ->firstOrFail();

        return view('plugins/pos-pro::receipt-print', compact('order'));
    }

    public function printReceiptMultiple($orderIds)
    {
        $storeId = $this->getStoreId();

        if (! is_array($orderIds)) {
            if (str_contains($orderIds, ',')) {
                $orderIds = explode(',', $orderIds);
            } else {
                $orderIds = [$orderIds];
            }
        }

        $orders = Order::query()
            ->whereIn('id', $orderIds)
            ->where('store_id', $storeId)
            ->with(['products', 'user', 'address', 'payment', 'invoice', 'store'])
            ->get();

        abort_if($orders->isEmpty(), 404);

        if ($orders->count() === 1) {
            $order = $orders->first();

            return view('plugins/pos-pro::receipt-print', compact('order'));
        }

        return view('plugins/pos-pro::receipt-print-multiple', compact('orders'));
    }
}

<?php

namespace Botble\PosPro\Services;

use Botble\Base\Facades\BaseHelper;
use Botble\Ecommerce\Enums\OrderAddressTypeEnum;
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
use Botble\Marketplace\Models\Store;
use Botble\Payment\Enums\PaymentStatusEnum;
use Botble\Payment\Models\Payment;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class MarketplaceOrderService
{
    protected string $sessionPrefix = '';

    public function __construct(
        protected CartService $cartService,
        protected OrderSlotService $orderSlotService
    ) {
        $this->sessionPrefix = $this->orderSlotService->getSessionPrefix();
    }

    public function processCheckout(Request $request): array
    {
        $cart = $this->cartService->getCart($this->sessionPrefix);

        if (empty($cart['items']) || $cart['items']->isEmpty()) {
            throw new Exception(trans('plugins/pos-pro::pos.cart_is_empty'));
        }

        $separateVendorOrders = setting('pos_pro_separate_vendor_orders', true);

        if (! $separateVendorOrders) {
            return $this->createSingleOrder($request);
        }

        $groupedItems = $this->groupItemsByVendor($cart['items']);

        $customerId = $cart['customer_id'];
        $customer = $customerId ? Customer::query()->find($customerId) : null;

        $customerName = $customer ? $customer->name : 'Guest';
        $customerPhone = $customer ? ($customer->phone ?: 'N/A') : 'N/A';
        $customerEmail = $customer ? ($customer->email ?: 'guest@example.com') : 'guest@example.com';

        $deliveryOption = $request->input('delivery_option', 'pickup');
        $isPickup = $deliveryOption === 'pickup';

        $orders = collect();

        DB::beginTransaction();

        try {
            foreach ($groupedItems as $storeId => $vendorData) {
                $order = $this->createOrderForVendor(
                    $vendorData,
                    $storeId,
                    $request,
                    $customer,
                    $customerName,
                    $customerPhone,
                    $customerEmail,
                    $isPickup
                );

                $orders->push($order);
            }

            DB::commit();

            $this->cartService->clearCart($this->sessionPrefix);
            $this->cartService->resetCustomerAndPayment($this->sessionPrefix);

            $activeSlot = $this->orderSlotService->getActiveSlot();
            $this->orderSlotService->closeSlotAfterCheckout($activeSlot);

            return [
                'success' => true,
                'orders' => $orders,
            ];

        } catch (Exception $e) {
            DB::rollBack();

            throw $e;
        }
    }

    protected function groupItemsByVendor(array|Collection $items): Collection
    {
        $grouped = collect();

        $taxRateCalculator = app(TaxRateCalculatorService::class);
        $country = EcommerceHelper::isUsingInMultipleCountries()
            ? null
            : EcommerceHelper::getFirstCountryId();

        foreach ($items as $item) {
            $itemArray = is_array($item) ? $item : $item->toArray();

            $product = Product::query()->find($itemArray['id']);

            if (! $product) {
                continue;
            }

            $originalProduct = $product;
            if ($product->is_variation) {
                $originalProduct = $product->original_product;
            }

            $storeId = $originalProduct->store_id ?: 0;

            $itemSubtotal = $itemArray['price'] * $itemArray['quantity'];
            $taxRate = $taxRateCalculator->execute($product, $country, null, null, null);

            $priceIncludesTax = $product->is_variation
                ? $originalProduct->price_includes_tax
                : $product->price_includes_tax;

            if ($priceIncludesTax) {
                $taxAmount = $itemSubtotal - ($itemSubtotal / (1 + $taxRate / 100));
                $itemTax = EcommerceHelper::roundPrice($taxAmount);
                $itemTotal = $itemSubtotal;
            } else {
                $taxAmount = $itemSubtotal * ($taxRate / 100);
                $itemTax = EcommerceHelper::roundPrice($taxAmount);
                $itemTotal = $itemSubtotal + $itemTax;
            }

            if (! $grouped->has($storeId)) {
                $store = $storeId ? Store::query()->find($storeId) : null;
                $grouped->put($storeId, [
                    'store' => $store,
                    'items' => collect([$itemArray]),
                    'subtotal' => $itemSubtotal,
                    'tax' => $itemTax,
                    'total' => $itemTotal,
                ]);
            } else {
                $vendorData = $grouped->get($storeId);

                $vendorData['items']->push($itemArray);

                $vendorData['subtotal'] += $itemSubtotal;
                $vendorData['tax'] += $itemTax;
                $vendorData['total'] += $itemTotal;

                $grouped->put($storeId, $vendorData);
            }
        }

        return $grouped;
    }

    protected function createOrderForVendor(
        array $vendorData,
        int|string $storeId,
        Request $request,
        ?Customer $customer,
        string $customerName,
        string $customerPhone,
        string $customerEmail,
        bool $isPickup
    ): Order {
        $cart = $this->cartService->getCart($this->sessionPrefix);

        $manualDiscount = 0;
        if (isset($cart['manual_discount']) && $cart['manual_discount'] > 0) {
            $vendorProportion = $vendorData['subtotal'] / $cart['subtotal'];
            $manualDiscount = $cart['manual_discount'] * $vendorProportion;
        }

        $orderData = [
            'user_id' => $customer?->id ?: 0,
            'amount' => $vendorData['total'] - $manualDiscount,
            'sub_total' => $vendorData['subtotal'],
            'tax_amount' => $vendorData['tax'],
            'shipping_amount' => 0,
            'discount_amount' => $manualDiscount,
            'currency_id' => get_application_currency_id(),
            'payment_id' => null,
            'payment_method' => $this->mapPaymentMethod($request->input('payment_method', 'cash')),
            'payment_status' => PaymentStatusEnum::PENDING,
            'status' => 'pending',
            'description' => $request->input('notes'),
            'is_finished' => true,
            'shipping_method' => ShippingMethodEnum::DEFAULT,
            'shipping_option' => null,
            'store_id' => $storeId ?: null,
        ];

        $order = Order::query()->create($orderData);

        $this->createOrderAddress($order, $request, $customer, $customerName, $customerPhone, $customerEmail, $isPickup);

        $this->createOrderProducts($order, $vendorData['items']);

        $storeName = $vendorData['store'] ? $vendorData['store']->name : 'Main Store';
        OrderHistory::query()->create([
            'action' => 'create_order',
            'description' => trans('plugins/pos-pro::pos.order_created_by_pos') . ' - ' . $storeName,
            'order_id' => $order->id,
            'user_id' => auth()->id(),
        ]);

        if (is_plugin_active('payment')) {
            $this->createPayment($order, $request, $customer);
        }

        OrderHelper::confirmOrder($order);

        if ($isPickup) {
            $this->createPickupShipment($order, $vendorData['items']);
        } elseif ($storeId) {
            $this->createShipment($order, $vendorData['items']);
        }

        try {
            event(new OrderCreated($order));
        } catch (Exception $exception) {
            BaseHelper::logError($exception);
        }

        if ($isPickup) {
            OrderHelper::setOrderCompleted($order->id, $request, auth()->id() ?: 0);
        }

        return $order;
    }

    protected function createOrderAddress(
        Order $order,
        Request $request,
        ?Customer $customer,
        string $customerName,
        string $customerPhone,
        string $customerEmail,
        bool $isPickup
    ): void {
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
                    $addressData = array_merge($addressData, [
                        'name' => $customerAddress->name,
                        'phone' => $customerAddress->phone,
                        'email' => $customerAddress->email,
                        'country' => $customerAddress->country,
                        'state' => $customerAddress->state,
                        'city' => $customerAddress->city,
                        'address' => $customerAddress->address,
                        'zip_code' => $customerAddress->zip_code,
                    ]);
                }
            } else {
                $addressData = array_merge($addressData, [
                    'name' => $addressInput['name'] ?? $customerName,
                    'phone' => $addressInput['phone'] ?? $customerPhone,
                    'email' => $addressInput['email'] ?? $customerEmail,
                    'country' => $addressInput['country'] ?? '',
                    'state' => $addressInput['state'] ?? '',
                    'city' => $addressInput['city'] ?? '',
                    'address' => $addressInput['address'] ?? '',
                    'zip_code' => $addressInput['zip_code'] ?? '',
                ]);
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
    }

    protected function createOrderProducts(Order $order, Collection $items): void
    {
        $taxRateCalculator = app(TaxRateCalculatorService::class);
        $country = EcommerceHelper::isUsingInMultipleCountries()
            ? null
            : EcommerceHelper::getFirstCountryId();

        foreach ($items as $item) {
            $itemArray = is_array($item) ? $item : (is_object($item) ? (array) $item : $item);

            $product = Product::query()->find($itemArray['id']);

            if (! $product) {
                continue;
            }

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

            if (! empty($itemArray['attributes'])) {
                $attributeLabels = [];

                foreach ($itemArray['attributes'] as $attributeItem) {
                    if (isset($attributeItem['set']) && isset($attributeItem['value'])) {
                        $attributeLabels[] = $attributeItem['set'] . ': ' . $attributeItem['value'];
                    }
                }

                if (! empty($attributeLabels)) {
                    $options['attributes'] = '(' . implode(', ', $attributeLabels) . ')';
                }
            }

            $itemPrice = $itemArray['price'] * $itemArray['quantity'];

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
                'qty' => $itemArray['quantity'],
                'price' => $itemArray['price'],
                'tax_amount' => $taxAmount,
                'options' => $options,
            ]);

            if ($product->with_storehouse_management) {
                $product->quantity -= $itemArray['quantity'];
                $product->save();
            }
        }
    }

    protected function createPayment(Order $order, Request $request, ?Customer $customer): void
    {
        $paymentMethod = $this->mapPaymentMethod($request->input('payment_method', 'cash'));
        $paymentFee = (float) get_payment_setting('fee', $paymentMethod, 0);

        $paymentData = [
            'amount' => $order->amount,
            'payment_fee' => $paymentFee,
            'currency' => get_application_currency()->title,
            'payment_channel' => $paymentMethod,
            'status' => PaymentStatusEnum::PENDING,
            'payment_type' => 'confirm',
            'order_id' => $order->id,
            'charge_id' => Str::upper(Str::random(10)),
            'user_id' => auth()->id() ?: 0,
        ];

        if ($customer) {
            $paymentData['customer_id'] = $customer->id;
            $paymentData['customer_type'] = Customer::class;
        }

        $payment = Payment::query()->create($paymentData);

        $order->payment_id = $payment->id;
        $order->save();

        OrderHelper::confirmPayment($order);
    }

    protected function createShipment(Order $order, Collection $items): void
    {
        try {
            $existingShipment = Shipment::query()->where('order_id', $order->id)->first();
            if ($existingShipment) {
                return;
            }

            $weight = 0;
            foreach ($items as $item) {

                $itemArray = is_array($item) ? $item : (is_object($item) ? (array) $item : $item);

                $product = Product::query()->find($itemArray['id']);
                if ($product) {
                    $weight += $product->weight * $itemArray['quantity'];
                }
            }

            $shipment = Shipment::query()->create([
                'order_id' => $order->id,
                'user_id' => auth()->id() ?: 0,
                'weight' => $weight,
                'cod_amount' => (is_plugin_active('payment') && $order->payment && $order->payment->status != PaymentStatusEnum::COMPLETED) ? $order->amount : 0,
                'cod_status' => ShippingCodStatusEnum::PENDING,
                'type' => ShippingMethodEnum::DEFAULT,
                'status' => ShippingStatusEnum::PENDING,
                'price' => $order->shipping_amount,
                'store_id' => $order->store_id,
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
        } catch (Exception $exception) {
            BaseHelper::logError($exception);
        }
    }

    protected function createPickupShipment(Order $order, Collection $items): void
    {
        try {
            $existingShipment = Shipment::query()->where('order_id', $order->id)->first();
            if ($existingShipment) {
                return;
            }

            $weight = 0;
            foreach ($items as $item) {
                $itemArray = is_array($item) ? $item : (is_object($item) ? (array) $item : $item);

                $product = Product::query()->find($itemArray['id']);
                if ($product) {
                    $weight += $product->weight * $itemArray['quantity'];
                }
            }

            $shipment = Shipment::query()->create([
                'order_id' => $order->id,
                'user_id' => auth()->id() ?: 0,
                'weight' => $weight,
                'cod_amount' => 0,
                'cod_status' => ShippingCodStatusEnum::COMPLETED,
                'type' => ShippingMethodEnum::DEFAULT,
                'status' => ShippingStatusEnum::DELIVERED,
                'price' => 0,
                'store_id' => $order->store_id,
            ]);

            if ($shipment) {
                ShipmentHistory::query()->create([
                    'action' => 'pickup_at_store',
                    'description' => trans('plugins/pos-pro::pos.order_completed_pickup'),
                    'shipment_id' => $shipment->id,
                    'order_id' => $order->id,
                    'user_id' => auth()->id() ?: 0,
                ]);

                OrderHistory::query()->create([
                    'action' => 'mark_order_as_completed',
                    'description' => trans('plugins/pos-pro::pos.order_completed_pickup'),
                    'order_id' => $order->id,
                    'user_id' => auth()->id() ?: 0,
                ]);

                $order->status = 'completed';
                $order->save();
            }
        } catch (Exception $exception) {
            BaseHelper::logError($exception);
        }
    }

    protected function mapPaymentMethod(string $posMethod): string
    {
        return match ($posMethod) {
            'card' => POS_PRO_CARD_PAYMENT_METHOD_NAME,
            'other' => POS_PRO_OTHER_PAYMENT_METHOD_NAME,
            default => POS_PRO_CASH_PAYMENT_METHOD_NAME,
        };
    }

    protected function createSingleOrder(Request $request): array
    {
        $cart = $this->cartService->getCart($this->sessionPrefix);
        $items = $cart['items'];

        $customerId = $cart['customer_id'];
        $customer = $customerId ? Customer::query()->find($customerId) : null;

        $customerName = $customer ? $customer->name : 'Guest';
        $customerPhone = $customer ? ($customer->phone ?: 'N/A') : 'N/A';
        $customerEmail = $customer ? ($customer->email ?: 'guest@example.com') : 'guest@example.com';

        $deliveryOption = $request->input('delivery_option', 'pickup');
        $isPickup = $deliveryOption === 'pickup';

        $allItems = collect();
        $subtotal = 0;
        $tax = 0;
        $total = 0;
        $storeIds = [];

        $taxRateCalculator = app(TaxRateCalculatorService::class);
        $country = EcommerceHelper::isUsingInMultipleCountries()
            ? null
            : EcommerceHelper::getFirstCountryId();

        foreach ($items as $item) {
            $itemArray = is_array($item) ? $item : $item->toArray();
            $product = Product::query()->find($itemArray['id']);

            if (! $product) {
                continue;
            }

            $originalProduct = $product->is_variation ? $product->original_product : $product;
            $storeId = $originalProduct->store_id ?: 0;
            if (! in_array($storeId, $storeIds)) {
                $storeIds[] = $storeId;
            }

            $allItems->push($itemArray);
            $itemSubtotal = $itemArray['price'] * $itemArray['quantity'];
            $taxRate = $taxRateCalculator->execute($product, $country, null, null, null);

            $priceIncludesTax = $product->is_variation
                ? $originalProduct->price_includes_tax
                : $product->price_includes_tax;

            if ($priceIncludesTax) {
                $taxAmount = $itemSubtotal - ($itemSubtotal / (1 + $taxRate / 100));
                $itemTax = EcommerceHelper::roundPrice($taxAmount);
                $itemTotal = $itemSubtotal;
            } else {
                $taxAmount = $itemSubtotal * ($taxRate / 100);
                $itemTax = EcommerceHelper::roundPrice($taxAmount);
                $itemTotal = $itemSubtotal + $itemTax;
            }

            $subtotal += $itemSubtotal;
            $tax += $itemTax;
            $total += $itemTotal;
        }

        $primaryStoreId = count($storeIds) === 1 ? $storeIds[0] : null;

        DB::beginTransaction();

        try {
            $vendorData = [
                'store' => $primaryStoreId ? Store::query()->find($primaryStoreId) : null,
                'items' => $allItems,
                'subtotal' => $subtotal,
                'tax' => $tax,
                'total' => $total,
            ];

            $order = $this->createOrderForVendor(
                $vendorData,
                $primaryStoreId ?: 0,
                $request,
                $customer,
                $customerName,
                $customerPhone,
                $customerEmail,
                $isPickup
            );

            DB::commit();

            $this->cartService->clearCart($this->sessionPrefix);
            $this->cartService->resetCustomerAndPayment($this->sessionPrefix);

            $activeSlot = $this->orderSlotService->getActiveSlot();
            $this->orderSlotService->closeSlotAfterCheckout($activeSlot);

            return [
                'success' => true,
                'orders' => collect([$order]),
            ];

        } catch (Exception $e) {
            DB::rollBack();

            throw $e;
        }
    }
}

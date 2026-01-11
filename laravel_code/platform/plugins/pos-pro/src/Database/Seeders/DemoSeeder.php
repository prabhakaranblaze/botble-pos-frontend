<?php

namespace Botble\PosPro\Database\Seeders;

use Botble\Base\Supports\BaseSeeder;
use Botble\Ecommerce\Enums\OrderHistoryActionEnum;
use Botble\Ecommerce\Enums\OrderStatusEnum;
use Botble\Ecommerce\Enums\ShippingCodStatusEnum;
use Botble\Ecommerce\Enums\ShippingMethodEnum;
use Botble\Ecommerce\Enums\ShippingStatusEnum;
use Botble\Ecommerce\Facades\EcommerceHelper;
use Botble\Ecommerce\Facades\InvoiceHelper;
use Botble\Ecommerce\Models\Customer;
use Botble\Ecommerce\Models\Order;
use Botble\Ecommerce\Models\OrderAddress;
use Botble\Ecommerce\Models\OrderHistory;
use Botble\Ecommerce\Models\OrderProduct;
use Botble\Ecommerce\Models\Product;
use Botble\Ecommerce\Models\Shipment;
use Botble\Ecommerce\Models\ShipmentHistory;
use Botble\Ecommerce\Models\StoreLocator;
use Botble\Payment\Enums\PaymentStatusEnum;
use Botble\Payment\Models\Payment;
use Carbon\Carbon;
use Illuminate\Support\Arr;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

class DemoSeeder extends BaseSeeder
{
    public function run(): void
    {
        $this->createPosOrders();
    }

    protected function createPosOrders(): void
    {
        $storeLocators = StoreLocator::all();
        $currency = get_application_currency();
        $storeLocatorsCount = $storeLocators->count();

        $products = Product::query()->where('is_variation', 1)
            ->with([
                'variationInfo',
                'variationInfo.configurableProduct',
            ])
            ->get();

        $customers = Customer::with(['addresses'])->get();
        $productsCount = $products->count();

        if (! $productsCount) {
            return;
        }

        $total = 15; // Number of POS orders to create
        for ($i = 0; $i < $total; $i++) {
            $customer = $customers->random();
            $address = $customer->addresses->first();

            if (! $address) {
                continue;
            }

            $orderProducts = $productsCount > 1 ? $products->random(rand(1, 3)) : $products->first();
            $groupedProducts = $this->group($orderProducts);

            foreach ($groupedProducts as $grouped) {
                $taxAmount = 0;
                $subTotal = 0;
                $weight = 0;
                foreach ($grouped['products'] as &$product) {
                    $qty = rand(1, 2);
                    $product->qty = $qty;
                    $subTotal += $qty * $product->price;
                    $weight += $qty * $product->weight;
                    $product->tax_amount = $this->getTax($product);
                    $taxAmount += $product->tax_amount;
                }

                $shippingAmount = rand(0, 1) ? rand(5, 15) : 0;
                $daysAgo = rand(0, 30);
                $time = Carbon::now()->subDays($daysAgo)->subHours(rand(1, 24));

                $order = [
                    'amount' => $subTotal + $taxAmount + $shippingAmount,
                    'user_id' => $customer->id,
                    'shipping_method' => $shippingAmount > 0 ? ShippingMethodEnum::DEFAULT : '',
                    'shipping_option' => $shippingAmount > 0 ? 1 : null,
                    'shipping_amount' => $shippingAmount,
                    'tax_amount' => $taxAmount,
                    'sub_total' => $subTotal,
                    'coupon_code' => null,
                    'discount_amount' => 0,
                    'status' => OrderStatusEnum::COMPLETED,
                    'is_finished' => true,
                    'token' => Str::random(29),
                    'created_at' => $time,
                    'updated_at' => $time,
                    'completed_at' => $time,
                    'is_confirmed' => true,
                ];

                $order = Order::query()->create($order);

                foreach ($grouped['products'] as $groupedProduct) {
                    $data = [
                        'order_id' => $order->id,
                        'product_id' => $groupedProduct->id,
                        'product_name' => $groupedProduct->name,
                        'product_image' => $groupedProduct->image,
                        'qty' => $groupedProduct->qty,
                        'weight' => $groupedProduct->weight * $groupedProduct->qty,
                        'price' => $groupedProduct->price ?: 1,
                        'tax_amount' => $groupedProduct->tax_amount,
                        'options' => [
                            'sku' => $groupedProduct->sku,
                            'attributes' => $groupedProduct->is_variation ? $groupedProduct->variation_attributes : '',
                        ],
                        'product_type' => $groupedProduct->product_type,
                    ];
                    OrderProduct::query()->create($data);
                }

                OrderAddress::query()->create([
                    'name' => $address->name,
                    'phone' => $address->phone,
                    'email' => $address->email,
                    'country' => $address->country,
                    'state' => $address->state,
                    'city' => $address->city,
                    'address' => $address->address,
                    'zip_code' => $address->zip_code,
                    'order_id' => $order->id,
                ]);

                OrderHistory::query()->create([
                    'action' => OrderHistoryActionEnum::CREATE_ORDER_FROM_SEEDER,
                    'description' => __('Order is created from POS'),
                    'order_id' => $order->id,
                    'created_at' => $time,
                    'updated_at' => $time,
                ]);

                OrderHistory::query()->create([
                    'action' => OrderHistoryActionEnum::CONFIRM_ORDER,
                    'description' => trans('plugins/ecommerce::order.order_was_verified_by'),
                    'order_id' => $order->id,
                    'user_id' => 0,
                    'created_at' => $time,
                    'updated_at' => $time,
                ]);

                $paymentMethod = Arr::random([
                    POS_PRO_CASH_PAYMENT_METHOD_NAME,
                    POS_PRO_CARD_PAYMENT_METHOD_NAME,
                    POS_PRO_OTHER_PAYMENT_METHOD_NAME,
                ]);

                $paymentStatus = PaymentStatusEnum::COMPLETED;

                $payment = Payment::query()->create([
                    'amount' => $order->amount,
                    'currency' => $currency->title,
                    'payment_channel' => $paymentMethod,
                    'status' => $paymentStatus,
                    'payment_type' => 'confirm',
                    'order_id' => $order->id,
                    'charge_id' => Str::upper(Str::random(10)),
                    'user_id' => 0,
                    'customer_id' => $customer->id,
                    'customer_type' => Customer::class,
                    'created_at' => $time,
                    'updated_at' => $time,
                ]);

                OrderHistory::query()->create([
                    'action' => OrderHistoryActionEnum::CONFIRM_PAYMENT,
                    'description' => trans('plugins/ecommerce::order.payment_was_confirmed_by', [
                        'money' => format_price($order->amount),
                    ]),
                    'order_id' => $order->id,
                    'user_id' => 0,
                ]);

                $order->payment_id = $payment->id;
                $order->save();

                InvoiceHelper::store($order);

                if ($shippingAmount > 0) {
                    $shipmentStatus = ShippingStatusEnum::DELIVERED;

                    $storeLocator = $storeLocatorsCount > 1 ? $storeLocators->random() : $storeLocators->first();

                    $shipment = Shipment::query()->create([
                        'status' => $shipmentStatus,
                        'order_id' => $order->getKey(),
                        'weight' => $weight,
                        'note' => '',
                        'cod_amount' => 0,
                        'cod_status' => ShippingCodStatusEnum::COMPLETED,
                        'price' => $order->shipping_amount,
                        'store_id' => $storeLocator ? $storeLocator->id : 0,
                        'tracking_id' => 'POS' . rand(1111111, 99999999),
                        'shipping_company_name' => Arr::random(['Store Pickup', 'Local Delivery', 'Express']),
                        'tracking_link' => '',
                        'estimate_date_shipped' => $time,
                        'date_shipped' => $time,
                        'created_at' => $time,
                        'updated_at' => $time,
                    ]);

                    ShipmentHistory::query()->create([
                        'action' => 'create_from_order',
                        'description' => trans('plugins/ecommerce::order.shipping_was_created_from'),
                        'shipment_id' => $shipment->id,
                        'order_id' => $order->id,
                        'user_id' => 0,
                        'created_at' => $time,
                        'updated_at' => $time,
                    ]);

                    ShipmentHistory::query()->create([
                        'action' => 'update_status',
                        'description' => trans('plugins/ecommerce::shipping.changed_shipping_status', [
                            'status' => ShippingStatusEnum::getLabel($shipmentStatus),
                        ]),
                        'shipment_id' => $shipment->id,
                        'order_id' => $order->id,
                        'user_id' => 0,
                        'created_at' => $time,
                        'updated_at' => $time,
                    ]);
                }
            }
        }
    }

    public function group(Collection $products): array|Collection
    {
        $groupedProducts = collect();
        foreach ($products as $product) {
            $storeId = $product->original_product && $product->original_product->store_id ? $product->original_product->store_id : 0;
            if (! Arr::has($groupedProducts, $storeId)) {
                $groupedProducts[$storeId] = collect([
                    'store' => $product->original_product->store ?? null,
                    'products' => collect([$product]),
                ]);
            } else {
                $groupedProducts[$storeId]['products'][] = $product;
            }
        }

        return $groupedProducts;
    }

    public function getTax(Product $product): float|int
    {
        if (! EcommerceHelper::isTaxEnabled()) {
            return 0;
        }

        return $product->price * ($product->tax->percentage ?? 0) / 100;
    }
}

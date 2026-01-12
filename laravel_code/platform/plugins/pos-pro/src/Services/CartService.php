<?php

namespace Botble\PosPro\Services;

use Botble\Ecommerce\Facades\EcommerceHelper;
use Botble\Ecommerce\Models\Customer;
use Botble\Ecommerce\Models\Product;
use Botble\Ecommerce\Models\ProductAttribute;
use Botble\Ecommerce\Models\ProductAttributeSet;
use Botble\Ecommerce\Repositories\Interfaces\DiscountInterface;
use Botble\Ecommerce\Services\TaxRateCalculatorService;
use Botble\Media\Facades\RvMedia;
use Botble\PosPro\Facades\PosProHelper;
use Exception;
use Illuminate\Support\Facades\Session;

class CartService
{
    protected string $sessionKey = 'pos_cart';

    protected string $couponSessionKey = 'pos_coupon_code';

    protected string $shippingAmountKey = 'pos_shipping_amount';

    protected string $manualDiscountKey = 'pos_manual_discount';

    protected string $manualDiscountDescriptionKey = 'pos_manual_discount_description';

    protected string $manualDiscountTypeKey = 'pos_manual_discount_type';

    protected string $customerIdKey = 'pos_customer_id';

    protected string $paymentMethodKey = 'pos_payment_method';

    public function getCart(string $sessionPrefix = ''): array
    {
        $cartKey = $sessionPrefix . $this->sessionKey;
        $couponKey = $sessionPrefix . $this->couponSessionKey;
        $shippingKey = $sessionPrefix . $this->shippingAmountKey;
        $manualDiscountKey = $sessionPrefix . $this->manualDiscountKey;
        $manualDiscountDescriptionKey = $sessionPrefix . $this->manualDiscountDescriptionKey;
        $manualDiscountTypeKey = $sessionPrefix . $this->manualDiscountTypeKey;
        $customerKey = $sessionPrefix . $this->customerIdKey;
        $paymentKey = $sessionPrefix . $this->paymentMethodKey;

        $cart = collect(Session::get($cartKey, []));

        $subtotal = $cart->sum(function ($item) {
            return $item['price'] * $item['quantity'];
        });

        $couponCode = Session::get($couponKey);
        $couponDiscount = 0;
        $couponDiscountType = null;

        if ($couponCode) {

            $discount = app(DiscountInterface::class)
                ->getModel()
                ->where('code', $couponCode)
                ->where('type', 'coupon')
                ->where('start_date', '<=', now())
                ->where(function ($query) {
                    return $query->whereNull('end_date')
                        ->orWhere('end_date', '>=', now());
                })
                ->first();

            if ($discount) {
                $couponDiscountType = $discount->type_option;

                if ($couponDiscountType === 'percentage') {
                    $couponDiscount = $subtotal * $discount->value / 100;
                } elseif ($couponDiscountType === 'fixed') {
                    $couponDiscount = $discount->value;
                }

                $couponDiscount = min($couponDiscount, $subtotal);
            }
        }

        $manualDiscountValue = (float) Session::get($manualDiscountKey, 0);
        $manualDiscountDescription = Session::get($manualDiscountDescriptionKey, '');
        $manualDiscountType = Session::get($manualDiscountTypeKey, 'fixed');

        $manualDiscount = $manualDiscountValue;
        if ($manualDiscountType === 'percentage') {
            $manualDiscount = $subtotal * $manualDiscountValue / 100;
        }

        $manualDiscount = min($manualDiscount, $subtotal - $couponDiscount);

        $subtotalAfterDiscount = $subtotal - $couponDiscount - $manualDiscount;

        $discountRatio = $subtotal > 0 ? $subtotalAfterDiscount / $subtotal : 0;

        $taxDetails = [];
        $totalTax = 0;
        $taxAmountToAdd = 0;

        if (EcommerceHelper::isTaxEnabled()) {
            $taxRateCalculator = app(TaxRateCalculatorService::class);

            $country = EcommerceHelper::isUsingInMultipleCountries()
                ? null
                : EcommerceHelper::getFirstCountryId();

            foreach ($cart as $item) {
                $product = Product::query()->find($item['id']);

                if ($product) {
                    $taxRate = $taxRateCalculator->execute($product, $country, null, null, null);
                    $itemPrice = $item['price'] * $item['quantity'];
                    $effectiveItemPrice = $itemPrice * $discountRatio;

                    $priceIncludesTax = $product->is_variation
                        ? $product->original_product->price_includes_tax
                        : $product->price_includes_tax;

                    if ($priceIncludesTax) {
                        $taxAmount = $effectiveItemPrice - ($effectiveItemPrice / (1 + $taxRate / 100));
                        $itemTaxAmount = EcommerceHelper::roundPrice($taxAmount);
                    } else {
                        $taxAmount = ($effectiveItemPrice * $taxRate) / 100;
                        $itemTaxAmount = EcommerceHelper::roundPrice($taxAmount);
                        $taxAmountToAdd += $itemTaxAmount;
                    }

                    $taxDetails[] = [
                        'product_id' => $item['id'],
                        'product_name' => $item['name'],
                        'tax_rate' => $taxRate,
                        'tax_amount' => $itemTaxAmount,
                    ];

                    $totalTax += $itemTaxAmount;
                }
            }
        }

        $shippingAmount = (float) Session::get($shippingKey, 0);

        $total = $subtotalAfterDiscount + $taxAmountToAdd + $shippingAmount;

        $customerId = Session::get($customerKey);
        $defaultMethod = PosProHelper::getDefaultPaymentMethod();

        $paymentMethodMap = [
            'cash' => POS_PRO_CASH_PAYMENT_METHOD_NAME,
            'card' => POS_PRO_CARD_PAYMENT_METHOD_NAME,
            'other' => POS_PRO_OTHER_PAYMENT_METHOD_NAME,
        ];

        $paymentMethod = Session::get($paymentKey, $defaultMethod);
        $paymentMethodEnum = $paymentMethodMap[$paymentMethod] ?? $paymentMethodMap['cash'];

        $customer = null;
        if ($customerId) {
            $customer = Customer::query()->find($customerId);
        }

        $cartItems = $cart->map(function ($item) {
            $item['image_url'] = RvMedia::getImageUrl($item['image'] ?? null);

            return $item;
        });

        return [
            'items' => $cartItems,
            'subtotal' => $subtotal,
            'subtotal_formatted' => format_price($subtotal),
            'coupon_code' => $couponCode,
            'coupon_discount' => $couponDiscount,
            'coupon_discount_formatted' => format_price($couponDiscount),
            'coupon_discount_type' => $couponDiscountType,
            'manual_discount' => $manualDiscount,
            'manual_discount_value' => $manualDiscountValue,
            'manual_discount_type' => $manualDiscountType,
            'manual_discount_formatted' => format_price($manualDiscount),
            'manual_discount_description' => $manualDiscountDescription,
            'tax' => $totalTax,
            'tax_formatted' => format_price($totalTax),
            'tax_details' => $taxDetails,
            'shipping_amount' => $shippingAmount,
            'shipping_amount_formatted' => format_price($shippingAmount),
            'total' => $total,
            'total_formatted' => format_price($total),
            'count' => $cart->count(),
            'customer_id' => $customerId,
            'customer' => $customer ? [
                'id' => $customer->id,
                'name' => $customer->name,
                'email' => $customer->email,
                'phone' => $customer->phone,
            ] : null,
            'payment_method' => $paymentMethod,
            'payment_method_enum' => $paymentMethodEnum,
        ];
    }

    public function addToCart(int $productId, int $quantity = 1, array $attributeIds = [], string $sessionPrefix = ''): array
    {
        /**
         * @var Product $product
         */
        $product = Product::query()->findOrFail($productId);
        $cartKey = $sessionPrefix . $this->sessionKey;
        $attributes = [];

        if ($attributeIds) {
            $attributeItems = [];

            foreach ($attributeIds as $setId => $attributeId) {
                if (empty($setId) || empty($attributeId)) {
                    continue;
                }

                $setId = (int) $setId;
                $attributeId = (int) $attributeId;

                $attributeSet = ProductAttributeSet::query()->find($setId);
                $attribute = ProductAttribute::query()->find($attributeId);

                if ($attributeSet && $attribute) {
                    $attributeItems[] = [
                        'set' => $attributeSet->title,
                        'value' => $attribute->title,
                    ];
                }
            }

            if (! empty($attributeItems)) {
                $attributes = $attributeItems;
            }
        }

        if ($product->isOutOfStock() && ! $product->allow_checkout_when_out_of_stock) {
            throw new Exception(trans('plugins/pos-pro::pos.product_is_out_of_stock'));
        }

        if ($product->with_storehouse_management && $product->quantity < $quantity) {
            throw new Exception(trans('plugins/pos-pro::pos.insufficient_stock'));
        }

        $cart = collect(Session::get($cartKey, []));
        $existingItem = $cart->firstWhere('id', $product->id);

        if ($existingItem) {
            $newQuantity = $existingItem['quantity'] + $quantity;
            if ($product->with_storehouse_management && $product->quantity < $newQuantity) {
                throw new Exception(trans('plugins/pos-pro::pos.insufficient_stock'));
            }

            $cart = $cart->map(function ($item) use ($product, $quantity, $attributes) {
                if ($item['id'] === $product->id) {
                    $item['quantity'] += $quantity;
                    if ($attributes) {
                        $item['attributes'] = $attributes;
                    }
                }

                return $item;
            });
        } else {
            $taxRateCalculator = app(TaxRateCalculatorService::class);
            $country = EcommerceHelper::isUsingInMultipleCountries()
                ? null
                : EcommerceHelper::getFirstCountryId();
            $taxRate = $taxRateCalculator->execute($product, $country, null, null, null);

            $cartItem = [
                'id' => $product->id,
                'name' => $product->name,
                'sku' => $product->sku,
                'image' => $product->image,
                'price' => $product->sale_price ?: $product->price,
                'quantity' => $quantity,
                'tax_rate' => $taxRate,
            ];

            if ($attributes) {
                $cartItem['attributes'] = $attributes;
            }

            $cart->push($cartItem);
        }

        Session::put($cartKey, $cart->all());

        return [
            'cart' => $this->getCart($sessionPrefix),
            'message' => trans('plugins/pos-pro::pos.product_added_to_cart'),
        ];
    }

    public function updateQuantity(int $productId, int $quantity, string $sessionPrefix = ''): array
    {
        if ($quantity < 1) {
            throw new Exception(trans('plugins/pos-pro::pos.invalid_quantity'));
        }

        $product = Product::query()->findOrFail($productId);

        if ($product->with_storehouse_management && $product->quantity < $quantity) {
            throw new Exception(trans('plugins/pos-pro::pos.insufficient_stock'));
        }

        $cartKey = $sessionPrefix . $this->sessionKey;
        $cart = collect(Session::get($cartKey, []));
        $cart = $cart->map(function ($item) use ($productId, $quantity) {
            if ($item['id'] === $productId) {
                $item['quantity'] = $quantity;
            }

            return $item;
        });

        Session::put($cartKey, $cart->all());

        return [
            'cart' => $this->getCart($sessionPrefix),
            'message' => trans('plugins/pos-pro::pos.cart_updated'),
        ];
    }

    public function removeFromCart(int $productId, string $sessionPrefix = ''): array
    {
        $cartKey = $sessionPrefix . $this->sessionKey;
        $cart = collect(Session::get($cartKey, []));
        $cart = $cart->filter(function ($item) use ($productId) {
            return $item['id'] !== $productId;
        });

        Session::put($cartKey, $cart->all());

        return [
            'cart' => $this->getCart($sessionPrefix),
            'message' => trans('plugins/pos-pro::pos.product_removed_from_cart'),
        ];
    }

    public function clearCart(string $sessionPrefix = ''): array
    {
        Session::forget($sessionPrefix . $this->sessionKey);
        Session::forget($sessionPrefix . $this->couponSessionKey);
        Session::forget($sessionPrefix . $this->shippingAmountKey);
        Session::forget($sessionPrefix . $this->manualDiscountKey);
        Session::forget($sessionPrefix . $this->manualDiscountDescriptionKey);
        Session::forget($sessionPrefix . $this->manualDiscountTypeKey);

        return [
            'cart' => $this->getCart($sessionPrefix),
            'message' => trans('plugins/pos-pro::pos.cart_cleared'),
        ];
    }

    public function resetCustomerAndPayment(string $sessionPrefix = ''): array
    {
        Session::forget($sessionPrefix . $this->customerIdKey);
        Session::forget($sessionPrefix . $this->paymentMethodKey);

        return [
            'cart' => $this->getCart($sessionPrefix),
            'message' => trans('plugins/pos-pro::pos.customer_and_payment_reset'),
        ];
    }

    public function applyCoupon(string $couponCode, string $sessionPrefix = ''): array
    {
        $couponCode = trim($couponCode);
        $couponKey = $sessionPrefix . $this->couponSessionKey;

        $discount = app(DiscountInterface::class)
            ->getModel()
            ->where('code', $couponCode)
            ->where('type', 'coupon')
            ->where('start_date', '<=', now())
            ->where(function ($query) {
                return $query->whereNull('end_date')
                    ->orWhere('end_date', '>=', now());
            })
            ->first();

        if (! $discount) {
            return [
                'error' => true,
                'message' => trans('plugins/pos-pro::pos.invalid_coupon'),
            ];
        }

        if ($discount->end_date && $discount->end_date->isPast()) {
            return [
                'error' => true,
                'message' => trans('plugins/pos-pro::pos.expired_coupon'),
            ];
        }

        if ($discount->quantity > 0 && $discount->total_used >= $discount->quantity) {
            return [
                'error' => true,
                'message' => trans('plugins/pos-pro::pos.coupon_used'),
            ];
        }

        Session::put($couponKey, $couponCode);

        return [
            'error' => false,
            'cart' => $this->getCart($sessionPrefix),
            'message' => trans('plugins/pos-pro::pos.applied_coupon_success', ['code' => $couponCode]),
        ];
    }

    public function removeCoupon(string $sessionPrefix = ''): array
    {
        $couponKey = $sessionPrefix . $this->couponSessionKey;
        $couponCode = Session::get($couponKey);

        if (! $couponCode) {
            return [
                'error' => true,
                'message' => trans('plugins/pos-pro::pos.not_used'),
            ];
        }

        Session::forget($couponKey);

        return [
            'error' => false,
            'cart' => $this->getCart($sessionPrefix),
            'message' => trans('plugins/pos-pro::pos.removed_coupon_success', ['code' => $couponCode]),
        ];
    }

    public function updateShippingAmount(float $amount, string $sessionPrefix = ''): array
    {
        if ($amount < 0) {
            return [
                'error' => true,
                'message' => trans('plugins/pos-pro::pos.invalid_shipping_amount'),
            ];
        }

        Session::put($sessionPrefix . $this->shippingAmountKey, $amount);

        return [
            'error' => false,
            'cart' => $this->getCart($sessionPrefix),
            'message' => trans('plugins/pos-pro::pos.shipping_amount_updated'),
        ];
    }

    public function updateManualDiscount(float $amount, string $description = '', string $type = 'fixed', string $sessionPrefix = ''): array
    {
        if ($amount < 0) {
            return [
                'error' => true,
                'message' => trans('plugins/pos-pro::pos.invalid_discount_amount'),
            ];
        }

        $cartKey = $sessionPrefix . $this->sessionKey;
        $couponKey = $sessionPrefix . $this->couponSessionKey;

        $cart = collect(Session::get($cartKey, []));
        $subtotal = $cart->sum(function ($item) {
            return $item['price'] * $item['quantity'];
        });

        $couponDiscount = 0;
        $couponCode = Session::get($couponKey);

        if ($couponCode) {
            $discount = app(DiscountInterface::class)
                ->getModel()
                ->where('code', $couponCode)
                ->where('type', 'coupon')
                ->where('start_date', '<=', now())
                ->where(function ($query) {
                    return $query->whereNull('end_date')
                        ->orWhere('end_date', '>=', now());
                })
                ->first();

            if ($discount) {
                if ($discount->type_option === 'percentage') {
                    $couponDiscount = $subtotal * $discount->value / 100;
                } elseif ($discount->type_option === 'fixed') {
                    $couponDiscount = $discount->value;
                }

                $couponDiscount = min($couponDiscount, $subtotal);
            }
        }

        $discountAmount = $amount;
        if ($type === 'percentage') {
            if ($amount > 100) {
                return [
                    'error' => true,
                    'message' => trans('plugins/pos-pro::pos.percentage_discount_cannot_exceed_100'),
                ];
            }
            $discountAmount = $subtotal * $amount / 100;
        }

        $maxDiscount = $subtotal - $couponDiscount;

        if ($discountAmount > $maxDiscount) {
            return [
                'error' => true,
                'message' => trans('plugins/pos-pro::pos.discount_cannot_exceed_subtotal'),
            ];
        }

        Session::put($sessionPrefix . $this->manualDiscountKey, $amount);
        Session::put($sessionPrefix . $this->manualDiscountDescriptionKey, $description);
        Session::put($sessionPrefix . $this->manualDiscountTypeKey, $type);

        return [
            'error' => false,
            'cart' => $this->getCart($sessionPrefix),
            'message' => trans('plugins/pos-pro::pos.discount_amount_updated'),
        ];
    }

    public function removeManualDiscount(string $sessionPrefix = ''): array
    {
        Session::forget($sessionPrefix . $this->manualDiscountKey);
        Session::forget($sessionPrefix . $this->manualDiscountDescriptionKey);
        Session::forget($sessionPrefix . $this->manualDiscountTypeKey);

        return [
            'error' => false,
            'cart' => $this->getCart($sessionPrefix),
            'message' => trans('plugins/pos-pro::pos.discount_removed'),
        ];
    }

    public function updateCustomer(?int $customerId, string $sessionPrefix = ''): array
    {
        $customerKey = $sessionPrefix . $this->customerIdKey;

        if ($customerId) {
            Session::put($customerKey, $customerId);
        } else {
            Session::forget($customerKey);
        }

        return [
            'error' => false,
            'cart' => $this->getCart($sessionPrefix),
            'message' => $customerId
                ? trans('plugins/pos-pro::pos.customer_updated')
                : trans('plugins/pos-pro::pos.customer_removed'),
        ];
    }

    public function updatePaymentMethod(string $paymentMethod, string $sessionPrefix = ''): array
    {
        Session::put($sessionPrefix . $this->paymentMethodKey, $paymentMethod);

        return [
            'error' => false,
            'cart' => $this->getCart($sessionPrefix),
            'message' => trans('plugins/pos-pro::pos.payment_method_updated'),
        ];
    }
}

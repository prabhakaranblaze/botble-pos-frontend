<?php

namespace Botble\Ecommerce\Http\Controllers\Fronts;

use Botble\Base\Http\Controllers\BaseController;
use Botble\Ecommerce\Facades\Cart;
use Botble\Ecommerce\Facades\EcommerceHelper;
use Botble\Ecommerce\Facades\OrderHelper;
use Botble\Ecommerce\Services\HandleCheckoutOrderData;
use Botble\Ecommerce\Services\HandleTaxService;
use Botble\Payment\Enums\PaymentMethodEnum;
use Botble\Payment\Facades\PaymentMethods;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\Request;

class PublicUpdateCheckoutController extends BaseController
{
    public function __invoke(Request $request, HandleCheckoutOrderData $handleCheckoutOrderData)
    {
        $sessionCheckoutData = OrderHelper::getOrderSessionData(
            $token = OrderHelper::getOrderSessionToken()
        );

        /**
         * @var Collection $products
         */
        $products = Cart::instance('cart')->products();

        $checkoutOrderData = $handleCheckoutOrderData->execute(
            $request,
            $products,
            $token,
            $sessionCheckoutData
        );

        app(HandleTaxService::class)->execute($products, $sessionCheckoutData);

        add_filter('payment_order_total_amount', function () use ($checkoutOrderData) {
            return $checkoutOrderData->orderAmount - $checkoutOrderData->paymentFee;
        }, 120);

        $hideCODPayment = $this->cartContainsOnlyDigitalProducts($products);

        if ($hideCODPayment) {
            PaymentMethods::excludeMethod(PaymentMethodEnum::COD);
        } 
        if ($request->has('delivery_option')) {
            $sessionCheckoutData['delivery_option'] = $request->delivery_option;
            OrderHelper::setOrderSessionData($token, $sessionCheckoutData);
        }
        $deliveryOption = $sessionCheckoutData['delivery_option'] ?? 'delivery';

        if ($deliveryOption == 'pickup') {

            // Remove shipping from session
            $sessionCheckoutData['shipping_method'] = null;
            $sessionCheckoutData['shipping_option'] = null;
            $sessionCheckoutData['shipping_amount'] = 0;
            $sessionCheckoutData['is_available_shipping'] = false;       
            // IMPORTANT: Shipping must be an array ALWAYS (never integer)
            $checkoutOrderData->shipping = [
                'shippingMethods' => [],
                'shippingOptions' => [],
            ];

            // Amount must be number, but shipping must still be an array
            $checkoutOrderData->shippingAmount = 0;

            // Prevent Blade from showing any selected method
            $checkoutOrderData->defaultShippingOption = null;
            $checkoutOrderData->defaultShippingMethod = null;
            $ship_amount = 0;

            // Recalculate total without shipping
            $checkoutOrderData->orderAmount =
                $checkoutOrderData->rawTotal
                - $checkoutOrderData->promotionDiscountAmount
                - $checkoutOrderData->couponDiscountAmount
                + $checkoutOrderData->paymentFee;

            $sessionCheckoutData['amount'] = $checkoutOrderData->orderAmount;
            $sessionCheckoutData['total']  = $checkoutOrderData->orderAmount;   
            $sessionCheckoutData['shipping_amount'] = 0;
            OrderHelper::setOrderSessionData($token, $sessionCheckoutData);
        } else { 
            // Re-enable shipping
            $sessionCheckoutData['is_available_shipping'] = true;

            // Force Botble to recalculate shipping
            $latestCheckoutData = $handleCheckoutOrderData->execute(
                $request,
                $products,
                $token,
                $sessionCheckoutData
            );

            // Save recalculated shipping amount
            $sessionCheckoutData['shipping_amount'] = $latestCheckoutData->shippingAmount;
            $ship_amount = $latestCheckoutData->shippingAmount;

            // Recalculate final total
            $sessionCheckoutData['amount'] =
                $latestCheckoutData->rawTotal
                - $latestCheckoutData->promotionDiscountAmount
                - $latestCheckoutData->couponDiscountAmount
                + $latestCheckoutData->paymentFee
                + $latestCheckoutData->shippingAmount;

            $sessionCheckoutData['total'] = $sessionCheckoutData['amount'];

            // Save session
            OrderHelper::setOrderSessionData($token, $sessionCheckoutData);

            // Replace local variables so the view gets updated values
            $checkoutOrderData = $latestCheckoutData;
        }
       
        return $this
            ->httpResponse()
            ->setData([
                'amount' => view('plugins/ecommerce::orders.partials.amount', [
                    'products' => $products,
                    'rawTotal' => $checkoutOrderData->rawTotal,
                    'orderAmount' => $checkoutOrderData->orderAmount,
                    'shipping' => $checkoutOrderData->shipping,
                    'sessionCheckoutData' => $sessionCheckoutData,
                    'shippingAmount' => $checkoutOrderData->shippingAmount,
                    'promotionDiscountAmount' => $checkoutOrderData->promotionDiscountAmount,
                    'couponDiscountAmount' => $checkoutOrderData->couponDiscountAmount,
                    'paymentFee' => $checkoutOrderData->paymentFee,
                ])->render(),
                'payment_methods' => view('plugins/ecommerce::orders.partials.payment-methods', [
                    'orderAmount' => $checkoutOrderData->orderAmount,
                ])->render(),
                'payment_amount' => number_format($checkoutOrderData->orderAmount,2),
                'ship_amount' => number_format($ship_amount,2),
                'shipping_methods' => view('plugins/ecommerce::orders.partials.shipping-methods', [
                    'shipping' => $checkoutOrderData->shipping,
                    'defaultShippingOption' => $checkoutOrderData->defaultShippingOption,
                    'defaultShippingMethod' => $checkoutOrderData->defaultShippingMethod,
                ])->render(),
                'checkout_button' => view('plugins/ecommerce::orders.partials.checkout-button')->render(),
                'checkout_warnings' => apply_filters('ecommerce_checkout_form_before', '', $products),
            ]);
    }

    protected function cartContainsOnlyDigitalProducts(Collection $products): bool
    {
        if (! EcommerceHelper::isEnabledSupportDigitalProducts()) {
            return false;
        }

        if ($products->isEmpty()) {
            return false;
        }

        $digitalProductsCount = EcommerceHelper::countDigitalProducts($products);

        return $digitalProductsCount > 0 && $digitalProductsCount === $products->count();
    }
}

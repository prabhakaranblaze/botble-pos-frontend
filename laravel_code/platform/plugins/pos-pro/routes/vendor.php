<?php

use Botble\Marketplace\Http\Middleware\LocaleMiddleware;
use Botble\PosPro\Http\Controllers\Vendor\VendorCartController;
use Botble\PosPro\Http\Controllers\Vendor\VendorCheckoutController;
use Botble\PosPro\Http\Controllers\Vendor\VendorPosController;
use Botble\PosPro\Http\Controllers\CartController;
use Botble\PosPro\Http\Controllers\RegisterController;
use Botble\PosPro\Http\Controllers\PosController;
use Illuminate\Support\Facades\Route;

Route::group([
    'prefix' => config('plugins.marketplace.general.vendor_panel_dir', 'vendor'),
    'as' => 'marketplace.vendor.',
    'middleware' => ['web', 'core', 'vendor', LocaleMiddleware::class, 'pos-locale', 'vendor-pos-access'],
], function (): void {
    Route::group(['prefix' => 'pos', 'as' => 'pos.'], function (): void {
        Route::get('/', [VendorPosController::class, 'index'])->name('index');
        Route::get('/products', [VendorPosController::class, 'getProducts'])->name('products');
        Route::get('/quick-shop/{id}', [VendorPosController::class, 'quickShop'])->name('quick-shop');
        Route::get('/product-price', [VendorPosController::class, 'getProductPrice'])->name('product-price');
        Route::get('/get-variation', [VendorPosController::class, 'getVariation'])->name('get-variation');
        Route::post('/create-customer', [VendorPosController::class, 'createCustomer'])->name('create-customer');
        Route::get('/search-customers', [VendorPosController::class, 'searchCustomers'])->name('search-customers');
        Route::get('/customers/{id}/addresses', [VendorPosController::class, 'getCustomerAddresses'])->name('customers.addresses.list');
        Route::get('/address-form', [VendorPosController::class, 'getAddressForm'])->name('address-form');
        Route::get('/switch-language/{locale}', [VendorPosController::class, 'switchLanguage'])->name('switch-language');
        Route::get('/switch-currency/{currency}', [VendorPosController::class, 'switchCurrency'])->name('switch-currency');
        Route::post('/scan-barcode', [VendorPosController::class, 'scanBarcode'])->name('scan-barcode');

        Route::post('/cart/add', [VendorCartController::class, 'add'])->name('cart.add');
        Route::post('/cart/update', [VendorCartController::class, 'update'])->name('cart.update');
        Route::post('/cart/remove', [VendorCartController::class, 'remove'])->name('cart.remove');
        Route::post('/cart/clear', [VendorCartController::class, 'clear'])->name('cart.clear');
        Route::post('/cart/apply-coupon', [VendorCartController::class, 'applyCoupon'])->name('cart.apply-coupon');
        Route::post('/cart/remove-coupon', [VendorCartController::class, 'removeCoupon'])->name('cart.remove-coupon');
        Route::post('/cart/update-shipping', [VendorCartController::class, 'updateShippingAmount'])->name('cart.update-shipping');
        Route::post('/cart/update-manual-discount', [VendorCartController::class, 'updateManualDiscount'])->name('cart.update-manual-discount');
        Route::post('/cart/remove-manual-discount', [VendorCartController::class, 'removeManualDiscount'])->name('cart.remove-manual-discount');
        Route::post('/cart/update-customer', [VendorCartController::class, 'updateCustomer'])->name('cart.update-customer');
        Route::post('/cart/update-payment-method', [VendorCartController::class, 'updatePaymentMethod'])->name('cart.update-payment-method');
        Route::post('/cart/reset-customer-payment', [VendorCartController::class, 'resetCustomerAndPayment'])->name('cart.reset-customer-payment');

        Route::post('/checkout', [VendorCheckoutController::class, 'checkout'])->name('checkout');
        Route::get('/receipt/{order}', [VendorCheckoutController::class, 'receipt'])->name('receipt');
        Route::get('/receipt/{order}/print', [VendorCheckoutController::class, 'printReceipt'])->name('receipt.print');
        Route::get('/receipt/print/{orders}', [VendorCheckoutController::class, 'printReceiptMultiple'])->name('receipt.print.multiple');

        Route::get('/order-slots', [CartController::class, 'getOrderSlots'])->name('order-slots.index');
        Route::post('/order-slots/create', [CartController::class, 'createOrderSlot'])->name('order-slots.create');
        Route::post('/order-slots/switch', [CartController::class, 'switchOrderSlot'])->name('order-slots.switch');
        Route::post('/order-slots/close', [CartController::class, 'closeOrderSlot'])->name('order-slots.close');

        Route::get('/register/status', [RegisterController::class, 'status'])->name('register.status');
        Route::post('/register/open', [RegisterController::class, 'open'])->name('register.open');
        Route::post('/register/close', [RegisterController::class, 'close'])->name('register.close');
        Route::get('/register/history', [RegisterController::class, 'history'])->name('register.history');

        Route::get('/customer-display', [PosController::class, 'customerDisplay'])->name('customer-display');
    });
});

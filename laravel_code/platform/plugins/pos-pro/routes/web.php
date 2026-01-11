<?php

use Botble\Base\Facades\AdminHelper;
use Botble\PosPro\Http\Controllers\CartController;
use Botble\PosPro\Http\Controllers\CheckoutController;
use Botble\PosPro\Http\Controllers\LicenseController;
use Botble\PosPro\Http\Controllers\PosController;
use Botble\PosPro\Http\Controllers\PosDeviceController;
use Botble\PosPro\Http\Controllers\RegisterController;
use Botble\PosPro\Http\Controllers\ReportController;
use Botble\PosPro\Http\Controllers\Settings\PosProSettingController;
use Illuminate\Support\Facades\Route;

AdminHelper::registerRoutes(function (): void {
    Route::group(['namespace' => 'Botble\PosPro\Http\Controllers', 'middleware' => ['pos-locale']], function (): void {
        Route::group(['prefix' => 'pos', 'as' => 'pos-pro.', 'permission' => 'pos.index'], function (): void {
            Route::get('/', [PosController::class, 'index'])->name('index');
            Route::get('/customer-display', [PosController::class, 'customerDisplay'])->name('customer-display');
            Route::get('/products', [PosController::class, 'getProducts'])->name('products');
            Route::get('/quick-shop/{id}', [PosController::class, 'quickShop'])->name('quick-shop');
            Route::get('/product-price', [PosController::class, 'getProductPrice'])->name('product-price');
            Route::get('/get-variation', [PosController::class, 'getVariation'])->name('get-variation');
            Route::post('/create-customer', [PosController::class, 'createCustomer'])->name('create-customer');
            Route::get('/search-customers', [PosController::class, 'searchCustomers'])->name('search-customers');
            Route::get('/customers/{id}/addresses', [PosController::class, 'getCustomerAddresses'])->name('customers.addresses.list');
            Route::get('/address-form', [PosController::class, 'getAddressForm'])->name('address-form');
            Route::get('/switch-language/{locale}', [PosController::class, 'switchLanguage'])->name('switch-language');
            Route::get('/switch-currency/{currency}', [PosController::class, 'switchCurrency'])->name('switch-currency');
            Route::post('/scan-barcode', [PosController::class, 'scanBarcode'])->name('scan-barcode');

            Route::post('/cart/add', [CartController::class, 'add'])->name('cart.add');
            Route::post('/cart/update', [CartController::class, 'update'])->name('cart.update');
            Route::post('/cart/remove', [CartController::class, 'remove'])->name('cart.remove');
            Route::post('/cart/clear', [CartController::class, 'clear'])->name('cart.clear');
            Route::post('/cart/apply-coupon', [CartController::class, 'applyCoupon'])->name('cart.apply-coupon');
            Route::post('/cart/remove-coupon', [CartController::class, 'removeCoupon'])->name('cart.remove-coupon');
            Route::post('/cart/update-shipping', [CartController::class, 'updateShippingAmount'])->name('cart.update-shipping');
            Route::post('/cart/update-manual-discount', [CartController::class, 'updateManualDiscount'])->name('cart.update-manual-discount');
            Route::post('/cart/remove-manual-discount', [CartController::class, 'removeManualDiscount'])->name('cart.remove-manual-discount');
            Route::post('/cart/update-customer', [CartController::class, 'updateCustomer'])->name('cart.update-customer');
            Route::post('/cart/update-payment-method', [CartController::class, 'updatePaymentMethod'])->name('cart.update-payment-method');
            Route::post('/cart/reset-customer-payment', [CartController::class, 'resetCustomerAndPayment'])->name('cart.reset-customer-payment');

            Route::get('/order-slots', [CartController::class, 'getOrderSlots'])->name('order-slots.index');
            Route::post('/order-slots/create', [CartController::class, 'createOrderSlot'])->name('order-slots.create');
            Route::post('/order-slots/switch', [CartController::class, 'switchOrderSlot'])->name('order-slots.switch');
            Route::post('/order-slots/close', [CartController::class, 'closeOrderSlot'])->name('order-slots.close');

            Route::get('/register/status', [RegisterController::class, 'status'])->name('register.status');
            Route::post('/register/open', [RegisterController::class, 'open'])->name('register.open');
            Route::post('/register/close', [RegisterController::class, 'close'])->name('register.close');
            Route::get('/register/history', [RegisterController::class, 'history'])->name('register.history');

            Route::post('/checkout', [CheckoutController::class, 'checkout'])->name('checkout');
            Route::get('/receipt/{order}', [CheckoutController::class, 'receipt'])->name('receipt');
            Route::get('/receipt/{order}/print', [CheckoutController::class, 'printReceipt'])->name('receipt.print');
            Route::get('/receipt/print/{orders}', [CheckoutController::class, 'printReceiptMultiple'])->name('receipt.print.multiple');
        });

        Route::group(['prefix' => 'pos/orders', 'as' => 'pos-pro.orders.', 'permission' => 'pos.orders'], function (): void {
            Route::match(['GET', 'POST'], '/', [PosController::class, 'orders'])->name('index');
        });

        Route::group(['prefix' => 'pos/reports', 'as' => 'pos-pro.reports.', 'permission' => 'pos.reports'], function (): void {
            Route::get('/', [ReportController::class, 'index'])->name('index');
        });

        Route::group(['prefix' => 'pos/registers', 'as' => 'pos-pro.registers.', 'permission' => 'pos.registers'], function (): void {
            Route::get('/', [RegisterController::class, 'index'])->name('index');
        });

        Route::group(['prefix' => 'pos/license', 'as' => 'pos-pro.license.'], function (): void {
            Route::get('/', [LicenseController::class, 'index'])->name('index');
            Route::post('activate', [LicenseController::class, 'activate'])
                ->name('activate')
                ->middleware('preventDemo');
            Route::post('deactivate', [LicenseController::class, 'deactivate'])
                ->name('deactivate')
                ->middleware('preventDemo');
        });

        Route::group(['prefix' => 'pos/settings', 'as' => 'pos-pro.settings.', 'permission' => 'pos.settings'], function (): void {
            Route::get('/', [PosProSettingController::class, 'edit'])->name('edit');
            Route::put('/', [PosProSettingController::class, 'update'])->name('update');
        });

        Route::group(['prefix' => 'pos/devices', 'as' => 'pos-devices.', 'permission' => 'pos.devices'], function (): void {
            Route::resource('', PosDeviceController::class)->parameters(['' => 'pos_device']);
            Route::delete('items/destroy', [PosDeviceController::class, 'deletes'])->name('deletes');
        });
    });
});

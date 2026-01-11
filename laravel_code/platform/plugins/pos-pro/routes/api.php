<?php

use Botble\PosPro\Http\Controllers\Api\AuthController;
use Botble\PosPro\Http\Controllers\Api\CashRegisterController;
use Botble\PosPro\Http\Controllers\Api\OrderController;
use Botble\PosPro\Http\Controllers\Api\ProductController;
use Botble\PosPro\Http\Controllers\Api\SessionController;
use Botble\PosPro\Http\Controllers\CartController;
use Botble\PosPro\Http\Controllers\CheckoutController;
use Botble\PosPro\Http\Controllers\PosController;
use Illuminate\Support\Facades\Route;
Route::group(['namespace' => 'Botble\PosPro\Http\Controllers', 'middleware' => ['pos-locale']], function (): void {
   Route::prefix('v1/pos')->as('pos.')->group(function () {
        
        // ==========================================
        // 1. AUTHENTICATION (Public Routes)
        // ==========================================
        Route::prefix('auth')->name('auth.')->group(function () {
            Route::post('login', [AuthController::class, 'login'])->name('login');
            
            // Protected auth routes
            Route::middleware(['auth:sanctum'])->group(function () {
                Route::get('me', [AuthController::class, 'me'])->name('me');
                Route::post('refresh', [AuthController::class, 'refresh'])->name('refresh');
                Route::post('logout', [AuthController::class, 'logout'])->name('logout');
            });
        });

        // ==========================================
        // Protected Routes (Require Authentication)
        // ==========================================
        Route::middleware(['auth:sanctum'])->group(function () {
            
            // ==========================================
            // 2. PRODUCTS (Clone from PosController)
            // ==========================================
            Route::prefix('products')->name('products.')->group(function () {
                Route::get('/', [ProductController::class, 'index'])->name('index');
                Route::get('categories', [ProductController::class, 'categories'])->name('categories');
                Route::post('search-by-code', [ProductController::class, 'searchByCode'])->name('search-by-code');
                Route::post('scan-barcode', [PosController::class, 'scanBarcode'])->name('scan-barcode');
                Route::get('quick-shop/{id}', [PosController::class, 'quickShop'])->name('quick-shop');
                Route::get('price', [PosController::class, 'getProductPrice'])->name('price');
                Route::get('variation', [PosController::class, 'getVariation'])->name('variation');
                Route::get('{id}', [ProductController::class, 'show'])->name('show');
            });

            // ==========================================
            // 3. CUSTOMERS (Clone from PosController)
            // ==========================================
            Route::prefix('customers')->name('customers.')->group(function () {
                Route::get('search', [PosController::class, 'searchCustomers'])->name('search');
                Route::post('/', [PosController::class, 'createCustomer'])->name('create');
                Route::get('{id}/addresses', [PosController::class, 'getCustomerAddresses'])->name('addresses');
            });

            // ==========================================
            // 4. CART (Clone from CartController)
            // ==========================================
            Route::prefix('cart')->name('cart.')->group(function () {
                Route::post('add', [CartController::class, 'add'])->name('add');
                Route::post('update', [CartController::class, 'update'])->name('update');
                Route::post('remove', [CartController::class, 'remove'])->name('remove');
                Route::post('clear', [CartController::class, 'clear'])->name('clear');
                Route::post('apply-coupon', [CartController::class, 'applyCoupon'])->name('apply-coupon');
                Route::post('remove-coupon', [CartController::class, 'removeCoupon'])->name('remove-coupon');
                Route::post('update-shipping', [CartController::class, 'updateShippingAmount'])->name('update-shipping');
                Route::post('update-manual-discount', [CartController::class, 'updateManualDiscount'])->name('update-manual-discount');
                Route::post('remove-manual-discount', [CartController::class, 'removeManualDiscount'])->name('remove-manual-discount');
                Route::post('update-customer', [CartController::class, 'updateCustomer'])->name('update-customer');
                Route::post('update-payment-method', [CartController::class, 'updatePaymentMethod'])->name('update-payment-method');
                Route::post('reset-customer-payment', [CartController::class, 'resetCustomerAndPayment'])->name('reset-customer-payment');
            });

            // ==========================================
            // 5. CHECKOUT (Clone from CheckoutController)
            // ==========================================
            Route::prefix('orders')->name('orders.')->group(function () {
                Route::post('/', [CheckoutController::class, 'checkout'])->name('create');
                Route::get('{order}/receipt', [CheckoutController::class, 'receipt'])->name('receipt');
                Route::get('history', [OrderController::class, 'history'])->name('history');
                Route::get('{id}', [OrderController::class, 'show'])->name('show');
            });

            // ==========================================
            // 6. CASH REGISTERS (New Feature)
            // ==========================================
            Route::prefix('cash-registers')->name('cash-registers.')->group(function () {
                Route::get('/', [CashRegisterController::class, 'index'])->name('index');
                Route::get('{id}', [CashRegisterController::class, 'show'])->name('show');
                
                // Admin only routes
                //Route::middleware(['permission:pos.settings'])->group(function () {
                    Route::post('/', [CashRegisterController::class, 'store'])->name('store');
                    Route::put('{id}', [CashRegisterController::class, 'update'])->name('update');
                    Route::delete('{id}', [CashRegisterController::class, 'destroy'])->name('destroy');
                //});
            });

            // ==========================================
            // 7. SESSIONS (New Feature)
            // ==========================================
            Route::prefix('sessions')->name('sessions.')->group(function () {
                Route::get('active', [SessionController::class, 'active'])->name('active');
                Route::post('open', [SessionController::class, 'open'])->name('open');
                Route::post('close', [SessionController::class, 'close'])->name('close');
                Route::get('history', [SessionController::class, 'history'])->name('history');
                Route::get('{id}', [SessionController::class, 'show'])->name('show');
            });

            // ==========================================
            // 8. DENOMINATIONS (New Feature)
            // ==========================================
            Route::prefix('denominations')->name('denominations.')->group(function () {
                Route::get('/', [SessionController::class, 'getDenominations'])->name('index');
                Route::get('currencies', [SessionController::class, 'getCurrencies'])->name('currencies');
                Route::post('calculate-total', [SessionController::class, 'calculateTotal'])->name('calculate-total');
                Route::post('suggest-breakdown', [SessionController::class, 'suggestBreakdown'])->name('suggest-breakdown');
            });

            // ==========================================
            // 9. ADDITIONAL UTILITIES
            // ==========================================
            Route::get('address-form', [PosController::class, 'getAddressForm'])->name('address-form');
        });
    });
});
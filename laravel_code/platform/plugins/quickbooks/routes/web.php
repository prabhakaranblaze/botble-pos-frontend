<?php

use Illuminate\Support\Facades\Route;
use Botble\Quickbooks\Http\Controllers\QuickBooksController;
use Botble\Quickbooks\Http\Controllers\QuickBookscronController;


Route::group(['namespace' => 'Botble\Quickbooks\Http\Controllers', 'middleware' => ['web', 'core']], function () {

    Route::group(['prefix' => BaseHelper::getAdminPrefix(), 'middleware' => 'auth'], function () {

        Route::group(['prefix' => 'quickbooks', 'as' => 'quickbooks.'], function () {

            Route::get('settings', [
                'as' => 'settings',
                'uses' => 'QuickBooksController@settingsPage',
                'permission' => 'quickbooks.setting',
            ]);

            Route::post('disconnect', [
                'as' => 'disconnect',
                'uses' => 'QuickBooksController@disconnect',
                'permission' => 'quickbooks.setting',
            ]);

            Route::get('connect', [
                'as' => 'connect',
                'uses' => 'QuickBooksController@connect',
                'permission' => 'quickbooks.setting',
            ]);

            Route::get('callback', [
                'as' => 'callback',
                'uses' => 'QuickBooksController@callback',
                'permission' => 'quickbooks.setting',
            ]);

            Route::get('disconnect', [
                'as' => 'disconnect',
                'uses' => 'QuickBooksController@disconnect',
                'permission' => 'quickbooks.setting',
            ]);

            Route::post('settings/update', [
                'as' => 'settings.update',
                'uses' => 'QuickBooksController@updateSettings',
                'permission' => 'quickbooks.setting',
            ]);

            Route::get('crons', [
                'as' => 'crons',
                'uses' => 'QuickBookscronController@cronLogs',
                'permission' => 'quickbooks.cron',
            ]);

            Route::post('crons', [
                'as' => 'crons.post',
                'uses' => 'QuickBookscronController@cronLogs',
                'permission' => 'quickbooks.cron',
            ]);

            Route::get('cron/view', [
                'as' => 'cron.view',
                'uses' => 'QuickBookscronController@viewCron',
                'permission' => 'quickbooks.cron',
            ]);

            Route::get('cron/refresh/{id}', [
                'as' => 'refresh',
                'uses' => 'QuickBookscronController@refresh',
                'permission' => 'quickbooks.cron',
            ]);

            Route::get('products', [
                'as' => 'products',
                'uses' => 'QuickBooksproductController@QuickbooksProducts',
                'permission' => 'quickbooks.product',
            ]);

            Route::post('products', [
                'as' => 'products.post',
                'uses' => 'QuickBooksproductController@QuickbooksProducts',
                'permission' => 'quickbooks.product',
            ]);

            Route::get('products/import/{itemId}', [
                'as' => 'products.import',
                'uses' => 'QuickBooksproductController@importProduct',
                'permission' => 'quickbooks.product',
            ]);

            Route::get('categories', [
                'as' => 'categories',
                'uses' => 'QuickBooksproductController@QuickbooksCategories',
                'permission' => 'quickbooks.category',
            ]);

            Route::post('categories', [
                'as' => 'categories.post',
                'uses' => 'QuickBooksproductController@QuickbooksCategories',
                'permission' => 'quickbooks.category',
            ]);

             Route::get('categories/import/{itemId}', [
                'as' => 'categories.import',
                'uses' => 'QuickBooksproductController@importCategory',
                'permission' => 'quickbooks.category',
            ]);

            Route::get('accounts', [
                'as' => 'accounts',
                'uses' => 'QuickBooksaccountController@QuickbooksAccounts',
                'permission' => 'quickbooks.account',
            ]);

            Route::post('accounts', [
                'as' => 'accounts.post',
                'uses' => 'QuickBooksaccountController@QuickbooksAccounts',
                'permission' => 'quickbooks.account',
            ]);


          
        });
    });
});


Route::prefix('quickbooks')->group(function () {
    Route::get('/connect', [QuickBooksController::class, 'connect'])->name('quickbooks.connect');
    Route::get('/callback', [QuickBooksController::class, 'callback'])->name('quickbooks.callback');
    Route::get('/create-sales-receipt', [QuickBooksController::class, 'createSalesReceipt'])->name('quickbooks.create.receipt');
});

Route::post('admin/quickbooks/webhook', [QuickBooksController::class, 'webhook'])
    ->name('quickbooks.webhook')
    ->withoutMiddleware([\App\Http\Middleware\VerifyCsrfToken::class]);


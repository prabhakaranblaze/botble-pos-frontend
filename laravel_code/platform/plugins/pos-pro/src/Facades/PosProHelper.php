<?php

namespace Botble\PosPro\Facades;

use Illuminate\Support\Facades\Facade;

/**
 * @method static bool isEnabled()
 * @method static string getDefaultPaymentMethod()
 * @method static bool isAutoApplyDiscountEnabled()
 * @method static bool isAutoAddShippingEnabled()
 * @method static float getDefaultShippingAmount()
 * @method static bool isRememberCustomerSelectionEnabled()
 * @method static bool isPrintReceiptEnabled()
 * @method static mixed getSetting(string $key, $default = null)
 * @method static void saveSettings(array $settings)
 *
 * @see \Botble\PosPro\Support\PosProHelper
 */
class PosProHelper extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return 'pos-pro.helper';
    }
}

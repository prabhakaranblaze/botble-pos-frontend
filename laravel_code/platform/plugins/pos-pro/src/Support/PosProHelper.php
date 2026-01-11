<?php

namespace Botble\PosPro\Support;

use Botble\Setting\Facades\Setting;

class PosProHelper
{
    public static function isEnabled(): bool
    {
        return (bool) self::getSetting('enabled', true);
    }

    public static function getDefaultPaymentMethod(): string
    {
        return (string) self::getSetting('default_payment_method', 'cash');
    }

    public static function getActivePaymentMethods(): array
    {
        $methods = self::getSetting('active_payment_methods', ['cash', 'card', 'other']);

        if (is_string($methods)) {
            $methods = json_decode($methods, true);
        }

        return is_array($methods) ? $methods : ['cash', 'card', 'other'];
    }

    public static function isAutoApplyDiscountEnabled(): bool
    {
        return (bool) self::getSetting('auto_apply_discount', false);
    }

    public static function isAutoAddShippingEnabled(): bool
    {
        return (bool) self::getSetting('auto_add_shipping', false);
    }

    public static function getDefaultShippingAmount(): float
    {
        return (float) self::getSetting('default_shipping_amount', 0);
    }

    public static function isRememberCustomerSelectionEnabled(): bool
    {
        return (bool) self::getSetting('remember_customer_selection', true);
    }

    public static function isPrintReceiptEnabled(): bool
    {
        return (bool) self::getSetting('print_receipt', true);
    }

    public static function getSetting(string $key, $default = null)
    {
        return setting('pos_pro_' . $key, $default);
    }

    public static function saveSettings(array $settings): void
    {
        foreach ($settings as $key => $value) {
            Setting::set('pos_pro_' . $key, $value);
        }

        Setting::save();
    }
}

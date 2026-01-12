<?php

namespace Botble\PosPro\Services;

use Botble\Setting\Facades\Setting;
use Illuminate\Support\Facades\Crypt;
use Throwable;

class LicenseEncryptionService
{
    public static function migrateExistingPurchaseCode(): bool
    {
        $purchaseCode = setting('pos_pro_license_purchase_code');

        if (! $purchaseCode) {
            return false;
        }

        try {
            Crypt::decryptString($purchaseCode);

            return true;
        } catch (Throwable $exception) {
            try {
                $encryptedPurchaseCode = Crypt::encryptString($purchaseCode);
                Setting::forceSet('pos_pro_license_purchase_code', $encryptedPurchaseCode)->save();

                return true;
            } catch (Throwable $encryptException) {
                report($encryptException);

                return false;
            }
        }
    }

    public static function decryptPurchaseCode(string $purchaseCode): string
    {
        try {
            return Crypt::decryptString($purchaseCode);
        } catch (Throwable $exception) {
            return $purchaseCode;
        }
    }

    public static function encryptPurchaseCode(string $purchaseCode): string
    {
        return Crypt::encryptString($purchaseCode);
    }

    public static function isPurchaseCodeEncrypted(string $purchaseCode): bool
    {
        try {
            Crypt::decryptString($purchaseCode);

            return true;
        } catch (Throwable $exception) {
            return false;
        }
    }
}

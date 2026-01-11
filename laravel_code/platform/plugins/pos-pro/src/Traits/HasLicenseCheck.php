<?php

namespace Botble\PosPro\Traits;

use Botble\PosPro\Services\LicenseEncryptionService;
use Illuminate\Http\RedirectResponse;

trait HasLicenseCheck
{
    protected function checkLicenseActivation(): bool
    {
        $licenseStatus = setting('pos_pro_license_status');
        $purchaseCode = setting('pos_pro_license_purchase_code');
        $activatedAt = setting('pos_pro_license_activated_at');

        if ($licenseStatus !== 'activated' || ! $purchaseCode || ! $activatedAt) {
            return false;
        }

        return LicenseEncryptionService::isPurchaseCodeEncrypted($purchaseCode) || ! empty($purchaseCode);
    }

    protected function redirectToLicenseActivation(?string $message = null): RedirectResponse
    {
        $defaultMessage = trans('plugins/pos-pro::pos.license.activation_required_message');

        return redirect()
            ->route('pos-pro.license.index')
            ->with('warning', $message ?: $defaultMessage);
    }

    protected function handleLicenseCheck(): ?RedirectResponse
    {
        if (! $this->checkLicenseActivation()) {
            return $this->redirectToLicenseActivation();
        }

        return null;
    }

    protected function decryptPurchaseCode(string $purchaseCode): string
    {
        return LicenseEncryptionService::decryptPurchaseCode($purchaseCode);
    }

    protected function encryptPurchaseCode(string $purchaseCode): string
    {
        return LicenseEncryptionService::encryptPurchaseCode($purchaseCode);
    }
}

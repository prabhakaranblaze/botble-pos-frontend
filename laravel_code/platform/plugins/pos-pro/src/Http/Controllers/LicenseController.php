<?php

namespace Botble\PosPro\Http\Controllers;

use Botble\Base\Http\Controllers\BaseController;
use Botble\Base\Http\Responses\BaseHttpResponse;
use Botble\Base\Supports\Core;
use Botble\PosPro\Services\LicenseEncryptionService;
use Botble\Setting\Facades\Setting;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Throwable;

class LicenseController extends BaseController
{
    public function index()
    {
        $this->pageTitle(trans('plugins/pos-pro::pos.license.title'));

        $isLicenseVerified = false;
        $licenseData = null;

        $licenseStatus = setting('pos_pro_license_status');
        $purchaseCode = setting('pos_pro_license_purchase_code');
        $activatedAt = setting('pos_pro_license_activated_at');

        if ($licenseStatus === 'activated' && $purchaseCode && $activatedAt) {
            $isLicenseVerified = true;

            LicenseEncryptionService::migrateExistingPurchaseCode();
            $decryptedPurchaseCode = LicenseEncryptionService::decryptPurchaseCode($purchaseCode);

            $licenseData = [
                'purchase_code' => $decryptedPurchaseCode,
                'activated_at' => Carbon::parse($activatedAt)->format('M d Y'),
            ];
        }

        return view('plugins/pos-pro::license.index', compact('isLicenseVerified', 'licenseData'));
    }

    public function activate(Request $request): BaseHttpResponse
    {
        $request->validate([
            'purchase_code' => ['required', 'string', 'max:255'],
            'license_rules_agreement' => ['required', 'accepted'],
        ]);

        $purchaseCode = $request->input('purchase_code');

        try {
            $core = Core::make()->getCoreFileData();

            $url = $core['marketplaceUrl'];

            $token = $core['marketplaceToken'];

            $response =
                Http::asJson()
                    ->withHeaders([
                        'Authorization' => 'Token ' . $token,
                    ])
                    ->acceptJson()
                    ->withoutVerifying()
                    ->connectTimeout(100)
                    ->post($url . '/products/license/activate', [
                        'purchase_code' => $purchaseCode,
                        'domain' => rtrim(url('')),
                        'product' => 'botble/pos-pro',
                    ]);

            if ($response->successful()) {
                $activatedAt = Carbon::now();

                $encryptedPurchaseCode = LicenseEncryptionService::encryptPurchaseCode($purchaseCode);

                Setting::forceSet('pos_pro_license_purchase_code', $encryptedPurchaseCode)->save();
                Setting::forceSet('pos_pro_license_activated_at', $activatedAt->toDateTimeString())->save();
                Setting::forceSet('pos_pro_license_status', 'activated')->save();

                return $this
                    ->httpResponse()
                    ->setMessage(trans('plugins/pos-pro::pos.license.activated_successfully'))
                    ->setData([
                        'purchase_code' => $purchaseCode,
                        'activated_at' => $activatedAt->format('M d Y'),
                    ]);
            } else {
                $errorMessage = $response->json('message') ?? trans(
                    'plugins/pos-pro::pos.license.invalid_purchase_code'
                );

                return $this
                    ->httpResponse()
                    ->setError()
                    ->setMessage($errorMessage);
            }
        } catch (Throwable) {
            return $this
                ->httpResponse()
                ->setError()
                ->setMessage(trans('plugins/pos-pro::pos.license.activation_error'));
        }
    }

    public function deactivate(): BaseHttpResponse
    {
        try {
            $core = Core::make()->getCoreFileData();

            $url = $core['marketplaceUrl'];

            $token = $core['marketplaceToken'];

            $purchaseCode = setting('pos_pro_license_purchase_code');
            $purchaseCode = LicenseEncryptionService::decryptPurchaseCode($purchaseCode);

            $response =
                Http::asJson()
                    ->withHeaders([
                        'Authorization' => 'Token ' . $token,
                    ])
                    ->acceptJson()
                    ->withoutVerifying()
                    ->connectTimeout(100)
                    ->post($url . '/products/license/deactivate', [
                        'purchase_code' => $purchaseCode,
                        'domain' => rtrim(url('')),
                        'product' => 'botble/pos-pro',
                    ]);

            Setting::forceSet('pos_pro_license_purchase_code', '')->save();
            Setting::forceSet('pos_pro_license_activated_at', '')->save();
            Setting::forceSet('pos_pro_license_status', '')->save();

            if ($response->successful()) {
                return $this
                    ->httpResponse()
                    ->setMessage(trans('plugins/pos-pro::pos.license.deactivated_successfully'));
            } else {
                $errorMessage = $response->json('message') ?? trans(
                    'plugins/pos-pro::pos.license.deactivation_error'
                );

                return $this
                    ->httpResponse()
                    ->setError()
                    ->setMessage($errorMessage);
            }
        } catch (Throwable) {
            return $this
                ->httpResponse()
                ->setError()
                ->setMessage(trans('plugins/pos-pro::pos.license.deactivation_error'));
        }
    }
}

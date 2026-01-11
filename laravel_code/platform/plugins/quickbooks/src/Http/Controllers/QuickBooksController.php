<?php

namespace Botble\Quickbooks\Http\Controllers;

use Botble\Base\Http\Controllers\BaseController;
use Botble\Base\Http\Responses\BaseHttpResponse;
use Botble\Quickbooks\Forms\QuickbooksSettingForm;
use Botble\Quickbooks\Http\Requests\QuickbooksSettingRequest;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Botble\Quickbooks\Services\QuickBooksService;
use QuickBooksOnline\API\DataService\DataService;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;  // ✅ Add this
use Illuminate\Support\Facades\Http;
use Botble\Quickbooks\Models\QuickbooksToken;
use Botble\Setting\Facades\Setting;
use Botble\Quickbooks\Tables\CronTable;
use Botble\Quickbooks\Models\QuickbooksWebhook;
use Carbon\Carbon;

class QuickBooksController extends BaseController
{
    /** Step 1: Redirect user to QuickBooks authorization page */
    public function connect()
    {
        $dataService = DataService::Configure([
            'auth_mode' => 'oauth2',
            'ClientID' => env('QB_CLIENT_ID'),
            'ClientSecret' => env('QB_CLIENT_SECRET'),
            'RedirectURI' => env('QB_REDIRECT_URI'),
            'scope' => 'com.intuit.quickbooks.accounting',
            'baseUrl' => env('QB_ENVIRONMENT', 'sandbox'),
        ]);

        $oauth2LoginHelper = $dataService->getOAuth2LoginHelper();
        $authorizationUrl = $oauth2LoginHelper->getAuthorizationCodeURL();

        return redirect()->away($authorizationUrl);
    }

    /** Step 2: Handle callback and exchange code for tokens */
    public function callback(Request $request)
    {
        $code = $request->get('code');
        $realmId = $request->get('realmId');

        $dataService = DataService::Configure([
            'auth_mode' => 'oauth2',
            'ClientID' => env('QB_CLIENT_ID'),
            'ClientSecret' => env('QB_CLIENT_SECRET'),
            'RedirectURI' => env('QB_REDIRECT_URI'),
            'scope' => 'com.intuit.quickbooks.accounting',
            'baseUrl' => env('QB_ENVIRONMENT', 'sandbox'),
        ]);

        $oauth2LoginHelper = $dataService->getOAuth2LoginHelper();
        $accessTokenObj = $oauth2LoginHelper->exchangeAuthorizationCodeForToken($code, $realmId);
        $dataService->updateOAuth2Token($accessTokenObj);

        // Save tokens
        $service = new QuickBooksService();
        $service->saveTokens(
            $accessTokenObj->getAccessToken(),
            $accessTokenObj->getRefreshToken(),
            $realmId
        );
        return redirect()->route('quickbooks.settings')->with('success', 'QuickBooks connected successfully!');

        //return response()->json(['success' => true, 'message' => 'QuickBooks connected successfully!']);
    }

    /** Step 3: Test Sales Receipt creation */
    public function createSalesReceipt()
    {
        $qb = new QuickBooksService();

        $data = [
            'customer_id' => '1', // QuickBooks customer ID
            'item_id' => '2',     // QuickBooks item ID
            'quantity' => 1,
            'amount' => 100.00,
        ];

        $response = $qb->createSalesReceipt($data);

        return response()->json($response);
    }

    public function edit()
    {
        // This is where the title is set
        $this->pageTitle(trans('plugins/quickbooks::qbs.settings.title'));

        return QuickbooksSettingForm::create()->renderForm();
    }

    public function update(QuickbooksSettingRequest $request, BaseHttpResponse $response)
    {
        foreach ($request->validated() as $key => $value) {
            setting()->set($key, $value)->save();
        }

        return $response->setMessage('QuickBooks settings updated successfully.');
    }

    public function settingsPage()
    {
        $this->pageTitle(trans('plugins/quickbooks::qbs.settings.title'));

        $environment = env('QB_ENVIRONMENT', 'sandbox');

        $tokenExists = QuickbooksToken::where('environment', $environment)->exists();
        $companyDetails = null;

        if ($tokenExists) {
            $companyDetails = $this->getCompanyDetails();
        }

        return view('plugins/quickbooks::settings', compact('tokenExists', 'companyDetails'));
    }

    public function disconnect()
    {
        // Remove token from database
        QuickbooksToken::truncate();

        Setting::set([
            'quickbooks_connect' => 0,
            'quickbooks_sales_receipt_delete' => 0,
        ])->save();

        return redirect()
            ->route('quickbooks.settings')
            ->with('success', 'QuickBooks disconnected successfully!');
    }

    public function updateSettings(Request $request)
    {
        Setting::set('quickbooks_sales_receipt_delete', $request->quickbooks_sales_receipt_delete)->save();

        return back()->with('success', 'QuickBooks settings updated successfully.');
    }

    public function getCompanyDetails()
    {
        $environment = env('QB_ENVIRONMENT', 'sandbox');
        $token = QuickbooksToken::where('environment', $environment)->first();

        if (!$token || !$token->access_token || !$token->realm_id) {
            Log::error("Missing QuickBooks token or realm for environment: {$environment}");
            return null;
        }

        $baseUrl = $environment === 'production'
            ? 'https://quickbooks.api.intuit.com/v3/company/'
            : 'https://sandbox-quickbooks.api.intuit.com/v3/company/';

        $realmId = $token->realm_id;

        try {
            // 1️⃣ Get Company Info
            $companyResponse = Http::withToken($token->access_token)
                ->withHeaders([
                    'Accept' => 'application/json',
                    'Content-Type' => 'application/json',
                ])
                ->get("{$baseUrl}{$realmId}/companyinfo/{$realmId}");

            if ($companyResponse->status() === 401 && str_contains($companyResponse->body(), 'Token expired')) {
                $token = self::refreshQuickbooksToken($token);
                if (!$token) return null;

                $companyResponse = Http::withToken($token->access_token)
                    ->withHeaders([
                        'Accept' => 'application/json',
                        'Content-Type' => 'application/json',
                    ])
                    ->get("{$baseUrl}{$realmId}/companyinfo/{$realmId}");
            }

            $companyJson = $companyResponse->json();

            // QuickBooks sometimes returns lowercase keys
            $companyData = $companyJson['CompanyInfo'] ?? $companyJson['companyInfo'] ?? [];

            // 2️⃣ Get Customer Count
            $query = urlencode("SELECT COUNT(*) FROM Customer");
            $customerResponse = Http::withToken($token->access_token)
                ->withHeaders([
                    'Accept' => 'application/json',
                    'Content-Type' => 'application/json',
                ])
                ->get("{$baseUrl}{$realmId}/query?query={$query}");

            if ($customerResponse->status() === 401 && str_contains($customerResponse->body(), 'Token expired')) {
                $token = self::refreshQuickbooksToken($token);
                if (!$token) return null;

                $customerResponse = Http::withToken($token->access_token)
                    ->withHeaders([
                        'Accept' => 'application/json',
                        'Content-Type' => 'application/json',
                    ])
                    ->get("{$baseUrl}{$realmId}/query?query={$query}");
            }

            $customerJson = $customerResponse->json();
            $totalCustomers = $customerJson['QueryResponse']['totalCount'] ?? 0;

            return [
                'company' => $companyData ?? '-',
                'total_customers' => $totalCustomers,
                'environment' => $environment,
            ];

        } catch (\Throwable $e) {
            Log::error("QuickBooks company info fetch failed: " . $e->getMessage());
            return null;
        }
    }

    public static function refreshQuickbooksToken($token)
    {
        try {
            $clientId = env('QB_CLIENT_ID');
            $clientSecret = env('QB_CLIENT_SECRET');
            $base64Auth = base64_encode("{$clientId}:{$clientSecret}");

            $response = Http::withHeaders([
                'Authorization' => "Basic {$base64Auth}",
                'Content-Type' => 'application/x-www-form-urlencoded',
                'Accept' => 'application/json',
            ])->asForm()->post('https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer', [
                'grant_type' => 'refresh_token',
                'refresh_token' => $token->refresh_token,
            ]);

            if ($response->failed()) {
                Log::error('QuickBooks token refresh failed: ' . $response->body());
                return null;
            }

            $data = $response->json();
            $token->update([
                'access_token' => $data['access_token'],
                'refresh_token' => $data['refresh_token'] ?? $token->refresh_token,
            ]);

            return $token;

        } catch (\Throwable $e) {
            Log::error('Error refreshing QuickBooks token: ' . $e->getMessage());
            return null;
        }
    }

    public function webhook(Request $request)
    {
        try {
            Log::info('QuickBooks Webhook HIT ✅', ['body' => $request->getContent()]);

            $headers = $request->headers->all();
            $rawBody = $request->getContent();
            $dataArray = json_decode($rawBody, true) ?: [];

            foreach ($dataArray as $data) {
                QuickbooksWebhook::create([
                    'webhook_id'        => $data['id'] ?? null,
                    'event_id'          => $data['event_id'] ?? null,
                    'specversion'       => $data['specversion'] ?? null,
                    'source'            => $data['source'] ?? null,
                    'event_type'        => $data['type'] ?? null,
                    'intuit_entity_id'  => $data['intuitentityid'] ?? null,
                    'intuit_account_id' => $data['intuitaccountid'] ?? null,
                    'datacontenttype'   => $data['datacontenttype'] ?? null,
                    'event_time'        => isset($data['time']) ? Carbon::parse($data['time']) : null,
                    'payload'           => isset($data['data']) ? json_encode($data['data']) : $data,
                    'headers'           => json_encode($headers),
                    'environment'       => env('QB_ENVIRONMENT', 'sandbox'),
                    'status'            => 'pending',
                ]);
            }

            return response()->json(['status' => 'ok'], 200);

        } catch (\Exception $e) {
            // Log the error but still return 200 to QuickBooks
            Log::error('Webhook Exception: '.$e->getMessage());
            return response()->json(['status' => 'ok'], 200);
        }
    }


   
}

<?php

namespace Botble\Quickbooks\Listeners;

use Botble\Ecommerce\Events\OrderCreated;
use Botble\Ecommerce\Events\OrderPlacedEvent;
use Botble\Quickbooks\Models\QuickbooksJob;
use Botble\Quickbooks\Models\QuickbooksToken;
use Botble\Ecommerce\Models\ProductCategory;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Botble\Setting\Facades\Setting;

class QuickbookJobListener
{
    public function handle(OrderPlacedEvent|OrderCreated $event): void
    {
        try {
            $order = $event->order;

            $isConnected = Setting::get('quickbooks_connect', 0);

            if ($isConnected != 1) {
                Log::info('QuickBooks is not connected. Skipping process.');
                return; 
            }

            $order->load(['products.product', 'billingAddress', 'shippingAddress', 'user', 'paymentDetail']);

            // 🔹 Get the latest token
            $environment = env('QB_ENVIRONMENT', 'sandbox');
            $token = QuickbooksToken::where('environment', $environment)->first();
            if (! $token || empty($token->access_token) || empty($token->realm_id)) {
                Log::error('QuickBooks is not connected. No token found.');
                return;   
            }

           
            $baseUrl = rtrim(env('QUICKBOOKS_API_BASE_URL', 'https://sandbox-quickbooks.api.intuit.com/v3/company'), '/');

            $headers = [
                'Authorization' => 'Bearer ' . $token->access_token,
                'Accept' => 'application/json',
                'Content-Type' => 'application/json',
            ];

            /** -------------------------------------------------------------
             *   CREATE CUSTOMER IN QUICKBOOKS
             * ------------------------------------------------------------- */
            $customer = $order->user;

            $customer_id = (!empty($customer->id) && $customer->id != 0) ? $customer->id : 1;
            
            $customer_name = ($customer->name ?? 'Guest Customer') . '~' . $customer_id;
            if (! $customer->quickbooks_customer_id || empty($customer)) {
                $customerPayload = [
                    "DisplayName" => $customer_name ?? 'Guest Customer',
                    "PrimaryEmailAddr" => ["Address" => $customer->email ?? 'noemail@example.com'],
                ];

                $customerUrl = "{$baseUrl}/{$token->realm_id}/customer";
                $res = Http::withHeaders($headers)->post($customerUrl, $customerPayload);

                // If token expired, refresh and retry once
                if ($res->status() === 401) {
                    Log::warning('Customer API failed due to expired token. Refreshing token...');
                    $token = $this->refreshAccessToken($token);
                    if ($token) {
                        $headers['Authorization'] = 'Bearer ' . $token->access_token;
                        $res = Http::withHeaders($headers)->post($customerUrl, $customerPayload);
                    }
                }

                if ($res->successful()) {
                    $qbCustomer = $res->json()['Customer'];
                    if (empty($customer)) {
                        $customer->quickbooks_customer_id = $qbCustomer['Id'];
                    } else {
                        $customer->update(['quickbooks_customer_id' => $qbCustomer['Id']]);
                    }
                  
                } else {
                   
                    if (empty($customer) || !isset($customer->id)) {
                        $body = $res->json();
                        if (isset($body['Fault']['Error'][0]['code']) && $body['Fault']['Error'][0]['code'] == '6240') {

                            // Try to get existing customer by DisplayName
                            $queryUrl = "{$baseUrl}/{$token->realm_id}/query?query=" .
                                urlencode("SELECT Id FROM Customer WHERE DisplayName = '{$customer_name}'");
                            $getRes = Http::withHeaders($headers)->get($queryUrl);

                            if ($getRes->successful() && isset($getRes->json()['QueryResponse']['Customer'][0]['Id'])) {
                                $customer->quickbooks_customer_id = $getRes->json()['QueryResponse']['Customer'][0]['Id'];
                            
                            } else {
                                
                                $customer->quickbooks_customer_id = '1'; 
                            }
                        } else {
                            $customer->quickbooks_customer_id = '1'; 
                        }
                    } else {
                       Log::error("Failed to create customer in QuickBooks: {$res->body()}");
                    }
                    
                    
                }
            }

            /** -------------------------------------------------------------
             *   CREATE PRODUCT IN QUICKBOOKS IF NOT EXISTS
             * ------------------------------------------------------------- */
            $lines = [];
            foreach ($order->products as $item) {
                $product = $item->product;
                $product_name = ($product->name ?? 'Unknown Product') . '~' . $product->id;
                $product_name = ($product->name ?? 'Unknown Product');
                if (! $product->quickbooks_item_id) {
                    

                    $response = Http::withHeaders($headers)
                        ->get("{$baseUrl}/{$token->realm_id}/query?query=select * from Account where AccountType='Income'");
                    $incomeAccountId = null;
                    if ($response->successful()) {
                        $accounts = $response->json()['QueryResponse']['Account'] ?? [];
                        $incomeAccountId = $accounts[0]['Id'] ?? null;
                    }

                    /* Product category */
                    $category = $product->categories->first();
                    $parentCategoryId = null;

                    if ($category) {
                        $parentCategoryId = $this->getOrCreateQbCategory(
                            $category,
                            $baseUrl,
                            $headers,
                            $token
                        );
                    }
                    
                    $itemPayload = [
                        "Name" => $product_name ?? 'Unknown Product',
                        "Sku"  => $product->sku ?? null,
                        "Type" => "Service",
                        "IncomeAccountRef" => ["value" => $incomeAccountId], // Replace with your valid AccountRef ID
                        "UnitPrice" => (float) $item->price,
                    ];

                    // ✅ ATTACH CATEGORY TO PRODUCT
                    if ($parentCategoryId) {
                        $itemPayload["ParentRef"] = [
                            "value" => (string) $parentCategoryId
                        ];
                        $itemPayload["SubItem"] = true;
                    }

                    $itemUrl = "{$baseUrl}/{$token->realm_id}/item";
                    $res = Http::withHeaders($headers)->post($itemUrl, $itemPayload);

                    // If token expired, refresh and retry once
                    if ($res->status() === 401) {
                        Log::warning('Item API failed due to expired token. Refreshing token...');
                        $token = $this->refreshAccessToken($token);
                        if ($token) {
                            $headers['Authorization'] = 'Bearer ' . $token->access_token;
                            $res = Http::withHeaders($headers)->post($itemUrl, $itemPayload);
                        }
                    }
                    // Item name duplicate issue
                    if (! $res->successful()) {

                        $body = $res->json();
                        $errorCode = $body['Fault']['Error'][0]['code'] ?? null;

                        // 🔁 Duplicate name → retry with ~ID
                        if ($errorCode == '6240') {

                            Log::warning("Duplicate QB Item. Retrying with fallback name.");

                            $itemPayload['Name'] = $product->name . '~' . $product->id;

                            $res = Http::withHeaders($headers)->post($itemUrl, $itemPayload);
                        }
                    }

                    if ($res->successful()) {
                        $qbItem = $res->json()['Item'];
                        $product->update(['quickbooks_item_id' => $qbItem['Id']]);
                        Log::info("Product synced to QuickBooks: {$qbItem['Id']}");
                    } else {
                        Log::error("Failed to create item in QuickBooks: {$res->body()}");
                    }
                }
                /* product description data add */
                $options_data = is_array($item->options) ? $item->options : json_decode($item->options, true);

                // Extract attributes
                $attributes = isset($options_data['attributes']) ? trim($options_data['attributes'], '()') : '';
                $color = $size = null;

                if ($attributes) {
                    $pairs = explode(',', $attributes);
                    foreach ($pairs as $pair) {
                        [$key, $value] = array_map('trim', explode(':', $pair));

                        if (strtolower($key) === 'color') $color = $value;
                        if (strtolower($key) === 'size') $size = $value;
                    }
                }

                // Build clean formatted description
                $descriptionParts = [];
                $descriptionParts[] = 'Name: ' . ($product->name ?? 'Item');

                if (!empty($options_data['sku'])) {
                    $descriptionParts[] = 'Sku: ' . $options_data['sku'];
                }

                if (!empty($color)) {
                    $descriptionParts[] = 'Color: ' . $color;
                }

                if (!empty($size)) {
                    $descriptionParts[] = 'Size: ' . $size;
                }

                $description = implode(PHP_EOL, $descriptionParts);

                $lines[] = [
                    "Amount" => (float) ($item->price * $item->qty),
                    "DetailType" => "SalesItemLineDetail",
                    "SalesItemLineDetail" => [
                        "ItemRef" => [
                            "value" => (string) $product->quickbooks_item_id,
                            "name" => $product_name,
                        ],
                        "Qty" => (int) $item->qty,
                        "UnitPrice" => (float) $item->price,

                        "TaxCodeRef" => [
                            "value" => "TAX" // <-- Your taxable tax code ID
                        ],
                    ],
                    "Description" => $description,
                ];
            }
            /* Getting Tax details from Quickbooks */
            $taxDetails = $this->getQuickbooksTaxDetails($token, $baseUrl, $headers);

            /* Tax Details */
            $taxData = null;

            if ($order->tax_amount > 0 && $taxDetails) {

                $taxData = [
                    "TxnTaxDetail" => [
                        "TxnTaxCodeRef" => [
                            "value" => $taxDetails['TaxCodeId'] // <-- Correct TaxCode ID
                        ],
                        "TotalTax" => (float) $order->tax_amount,
                        "TaxLine" => [
                            [
                                "Amount" => (float) $order->tax_amount,
                                "DetailType" => "TaxLineDetail",
                                "TaxLineDetail" => [
                                    "TaxRateRef" => [
                                        "value" => $taxDetails['TaxRateId'], // <-- Correct Tax Rate ID
                                        "name"  => "Tax"
                                    ],
                                    "PercentBased" => true,
                                    "TaxPercent" => $taxDetails['TaxPercent']
                                ]
                            ]
                        ]
                    ]
                ];

            }

            // Shipping line
           if ($order->shipping_amount > 0) {
                $lines[] = [
                            "Amount" => (float) $order->shipping_amount,
                            "DetailType" => "SalesItemLineDetail",
                            "SalesItemLineDetail" => [
                                "ItemRef" => [
                                    "value" => "SHIPPING_ITEM_ID", // QuickBooks Item ID for Shipping
                                    "name" => "Shipping Charge",
                                ],
                                "Qty" => 1,
                                "UnitPrice" => (float) $order->shipping_amount,
                            ],
                            "Description" => "Shipping Charge",
                        ];
      

            }

          
            // Discount Line
            if ($order->discount_amount > 0) {
                $lines[] = [
                    "Amount" => (float) $order->discount_amount,
                    "DetailType" => "DiscountLineDetail",
                    "DiscountLineDetail" => [
                        "PercentBased" => false,
                        "DiscountAccountRef" => [
                            "value" => "1", // your Discount account ID in QuickBooks
                            "name" => "Discount"
                        ]
                    ],
                    "Description" => "Order Discount",
                ];
            }

            /** -------------------------------------------------------------
             *   BUILD SALES RECEIPT PAYLOAD
             * ------------------------------------------------------------- */
            $billing = $order->billingAddress; // or billingAddress

            $billAddressPayload = [
                "Line1" => $billing->address ?? '',
                "City" => $billing->city_name ?? '',                 // Auto from LocationTrait
                "CountrySubDivisionCode" => $billing->state_name ?? '', // Auto from LocationTrait
                "PostalCode" => $billing->zip_code ?? '',
                "Country" => $billing->country_name ?? '',  // Already ISO like IN / US / AE
            ];

            $shipping = $order->shippingAddress; // or billingAddress

            $shipAddressPayload = [
                "Line1" => $shipping->address ?? '',
                "City" => $shipping->city_name ?? '',                 // Auto from LocationTrait
                "CountrySubDivisionCode" => $shipping->state_name ?? '', // Auto from LocationTrait
                "PostalCode" => $shipping->zip_code ?? '',
                "Country" => $shipping->country_name ?? '',  // Already ISO like IN / US / AE
            ];

            $order_type = 'Customer Pickup Order';
            if ($shipping->address == 'Pickup at Store') {
                $order_type = 'Pickup at Store';
            }

            $paymentName = $order->paymentDetail->payment_channel_label ?? $order->paymentDetail->payment_channel ?? null;

            $qbPaymentMethod = $this->getOrCreatePaymentMethod($paymentName);

            $payment_detail = [
                "value" => (string) $qbPaymentMethod['id'],
                "name"  => $qbPaymentMethod['name']
            ];

            $depositAccount = $this->getDepositAccountByPaymentMethod($paymentName);

            $payload = [
                "Line" => $lines,
                "CustomerRef" => [
                    "value" => (string) $customer->quickbooks_customer_id,
                    "name" => $customer_name ?? 'Guest',
                ],
                "TxnDate" => now()->format('Y-m-d'),
                "TotalAmt" => (float) $order->amount,
                "PaymentRefNum" => $order->code,
                "PrivateNote" => "Thank you for your business.",
                "DocNumber" => $order->id,
                "CustomerMemo" => [ 
                    "value" => "Thank you for your business and have a great day!"
                ],
                "PaymentMethodRef" => $payment_detail,
                "BillAddr" => $billAddressPayload,
                "ShipAddr" => $shipAddressPayload,
                "CustomField" => [
                    [
                        "DefinitionId" => "1",
                        "Name"         => "OrderType",
                        "Type"         => "StringType",
                        "StringValue"  => $order_type,  
                    ],
                ],
                "DepositToAccountRef" => [
                    "value" => (string) $depositAccount['id'],
                ],
            ] + ($taxData ?? []);
            
            $post_url = "{$baseUrl}/{$token->realm_id}/salesreceipt";

            QuickbooksJob::create([
                'order_id' => $order->id,
                'amount' => $order->amount,
                'payload' => json_encode($payload),
                'post_url' => $post_url,
                'environment' => $environment,
                'status' => 0,
            ]);

            Log::info("QuickBooks Job queued for Order #{$order->id}.");

        } catch (\Throwable $e) {
            Log::error('QuickbookJobListener error: ' . $e->getMessage());
        }
    }

    /**
     * 🔁 Refresh QuickBooks Access Token
     */
    private function refreshAccessToken($token)
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

    public function getOrCreatePaymentMethod($methodName)
    {
        $methodName = trim($methodName);
        $environment = env('QB_ENVIRONMENT', 'sandbox');

        $token = QuickbooksToken::where('environment', $environment)->first();
        $baseUrl = rtrim(env('QUICKBOOKS_API_BASE_URL', 'https://sandbox-quickbooks.api.intuit.com/v3/company'), '/');

        $headers = [
            'Authorization' => 'Bearer ' . $token->access_token,
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
        ];

        /** --------------------------------------------------------
         * Search if payment method already exists
         * -------------------------------------------------------- */
        $queryUrl = "{$baseUrl}/{$token->realm_id}/query?query=" .
            urlencode("SELECT * FROM PaymentMethod WHERE Name = '{$methodName}'");

        $res = Http::withHeaders($headers)->get($queryUrl);

        if ($res->status() === 401) {
            Log::warning("Token expired while searching payment method: {$methodName}");

            $token = $this->refreshAccessToken($token);

            if ($token) {
                $headers['Authorization'] = "Bearer " . $token->access_token;
                $res = Http::withHeaders($headers)->get($queryUrl);
            }
        }

        if ($res->successful() && isset($res->json()['QueryResponse']['PaymentMethod'][0])) {
            $pm = $res->json()['QueryResponse']['PaymentMethod'][0];

            return [
                'id'   => $pm['Id'],
                'name' => $pm['Name'],
            ];
        }

        /** --------------------------------------------------------
         * Create new payment method if not exists
         * -------------------------------------------------------- */
        $payload = [
            "Name"   => $methodName,
            "Active" => true,
        ];

        $createUrl = "{$baseUrl}/{$token->realm_id}/paymentmethod";
        $createRes = Http::withHeaders($headers)->post($createUrl, $payload);

        if ($createRes->successful()) {
            $pm = $createRes->json()['PaymentMethod'];
            return [
                'id'   => $pm['Id'],
                'name' => $pm['Name'],
            ];
        }

        Log::error("Failed to create PaymentMethod in QuickBooks: " . $createRes->body());

        return [
            'id'   => null,
            'name' => $methodName
        ];
    }

    public function deleteSalesReceipt($salesReceiptId, $order_id)
    {
        $environment = env('QB_ENVIRONMENT', 'sandbox');
        $token = QuickbooksToken::where('environment', $environment)->first();

        if (! $token || ! $token->access_token || ! $token->realm_id) {
            \Log::error('Missing QuickBooks token or realm ID while deleting SalesReceipt.');
            return false;
        }

        $baseUrl = rtrim(env('QUICKBOOKS_API_BASE_URL', 'https://sandbox-quickbooks.api.intuit.com/v3/company'), '/');

        $url = "{$baseUrl}/{$token->realm_id}/salesreceipt?operation=delete";

        $payload = [
            "Id" => $salesReceiptId,
            "SyncToken" => "0"
        ];

        $headers = [
            'Authorization' => 'Bearer ' . $token->access_token,
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
        ];

        $response = Http::withHeaders($headers)->post($url, $payload);

        // Token expired? Refresh and retry once
        if ($response->status() === 401) {
            \Log::warning("SalesReceipt delete failed - token expired. Refreshing token...");
            $token = app(self::class)->refreshAccessToken($token);

            if ($token) {
                $headers['Authorization'] = 'Bearer ' . $token->access_token;
                $response = Http::withHeaders($headers)->post($url, $payload);
            }
        }

        if ($response->successful()) {
            \Log::info("QuickBooks SalesReceipt {$salesReceiptId} deleted successfully.");
            $job = QuickbooksJob::where('order_id', $order_id)->first();
            if ($job) {
                $job->update(['status' => 4]);
            }
            return true;
        }

        \Log::error("Failed to delete QuickBooks SalesReceipt {$salesReceiptId}: " . $response->body());
        return false;
    }

    function getQuickbooksTaxDetails($token, $baseUrl, $headers)
    {
        $taxQueryUrl = "{$baseUrl}/{$token->realm_id}/query?query=" . urlencode("SELECT * FROM TaxCode WHERE Active = true AND Name = 'Tax'");

        $response = Http::withHeaders($headers)->get($taxQueryUrl);

        // If token expired, regenerate and retry
        if ($response->status() == 401) {
            $token = $this->refreshAccessToken($token);
            $headers['Authorization'] = "Bearer " . $token->access_token;
            $response = Http::withHeaders($headers)->get($taxQueryUrl);
        }

        $json = $response->json();

        if (!isset($json['QueryResponse']['TaxCode'][0])) {
            return null;
        }

        $taxCode = $json['QueryResponse']['TaxCode'][0]; 

        $taxCodeId = $taxCode['Id']; // Example: "7"

        // Extract rate details
        $rateItem = $taxCode['SalesTaxRateList']['TaxRateDetail'][0];

        $taxRateId = $rateItem['TaxRateRef']['value']; // Example: "11"
        $taxPercent = $rateItem['TaxOrder'] == 0 ? 10 : null; // Extract percent if exists

        return [
            "TaxCodeId" => $taxCodeId,
            "TaxRateId" => $taxRateId,
            "TaxPercent" => $taxPercent ?? 0
        ];
    }

    private function getOrCreateQbCategory(ProductCategory $category, $baseUrl, &$headers, $token)
    {
        // ✅ If already synced, reuse
        if (! empty($category->qb_cat_id)) {
            return $category->qb_cat_id;
        }

        $realmId = $token->realm_id;
        $categoryName = $category->name;

        // 1️⃣ Try to find existing category
        $query = urlencode("SELECT Id FROM Item WHERE Name = '{$categoryName}' AND Type='Category' ");
        $queryUrl = "{$baseUrl}/{$realmId}/query?query={$query}";

        $res = Http::withHeaders($headers)->get($queryUrl);

        // 🔁 Token expired → refresh and retry
        if ($res->status() === 401) {
            Log::warning('QB Category query token expired. Refreshing token...');

            $token = $this->refreshAccessToken($token);
            if (! $token) {
                return null;
            }

            $headers['Authorization'] = 'Bearer ' . $token->access_token;

            $res = Http::withHeaders($headers)->get($queryUrl);
        }

        if ($res->successful() && !empty($res->json()['QueryResponse']['Item'][0]['Id'])) {
            return $res->json()['QueryResponse']['Item'][0]['Id'];
        }

        // 2️⃣ Create new category
        $payload = [
            "Name" => $categoryName,
            "Type" => "Category"
        ];

        $createRes = Http::withHeaders($headers)->post(
            "{$baseUrl}/{$realmId}/item",
            $payload
        );


        if ($createRes->successful()) {
             $qbCatId = $createRes->json()['Item']['Id'];

            // ✅ Save to DB
            $category->update(['qb_cat_id' => $qbCatId]);

            return $qbCatId;
        }

        Log::error("Failed to create QB category: {$categoryName}", [
            'response' => $createRes->body()
        ]);

        return null;
    }

    private function getDepositAccountByPaymentMethod(?string $paymentName): array
    {
        $accounts = config('quickbooks-accounts.accounts');
        $paymentName = strtolower($paymentName ?? '');

        if (str_contains($paymentName, 'card')) {
            return [
                'id'   => $accounts['pos_card'],
                'name' => 'POS - Card',
            ];
        }

        if (str_contains($paymentName, 'cybersource')) {
            return [
                'id'   => $accounts['online_cs'],
                'name' => 'Online - Cybersource',
            ];
        }

        if (str_contains($paymentName, 'cod') || str_contains($paymentName, 'cash on delivery')) {
            return [
                'id'   => $accounts['online_cod'],
                'name' => 'POS - Cash',
            ];
        }

        return [
            'id'   => $accounts['pos_cash'],
            'name' => 'POS - Cash',
        ];
    }


}

<?php

namespace Botble\Quickbooks\Services;

use QuickBooksOnline\API\DataService\DataService;
use QuickBooksOnline\API\Facades\SalesReceipt;
use Illuminate\Support\Facades\Storage;
use Botble\Quickbooks\Models\QuickbooksToken;
use Botble\Setting\Facades\Setting;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class QuickBooksService
{
    protected $dataService;
    protected $tokenRecord;

    public function __construct()
    {
       
        $environment = env('QB_ENVIRONMENT', 'sandbox');

      
        $this->tokenRecord = QuickbooksToken::where('environment', $environment)->first();

  
        $config = [
            'auth_mode'     => 'oauth2',
            'ClientID'      => env('QB_CLIENT_ID'),
            'ClientSecret'  => env('QB_CLIENT_SECRET'),
            'RedirectURI'   => env('QB_REDIRECT_URI'),
            'scope'         => 'com.intuit.quickbooks.accounting',
            'baseUrl'       => $environment, // sandbox or production
        ];

       
        if ($this->tokenRecord) {
            $config['accessTokenKey']  = $this->tokenRecord->access_token;
            $config['refreshTokenKey'] = $this->tokenRecord->refresh_token;
            $config['QBORealmID']      = $this->tokenRecord->realm_id;
        }

     
        if (Storage::disk('local')->exists('quickbooks_tokens.json')) {
            $tokens = json_decode(Storage::disk('local')->get('quickbooks_tokens.json'), true);

            $config['accessTokenKey']  = $tokens['access_token'];
            $config['refreshTokenKey'] = $tokens['refresh_token'];
            $config['QBORealmID']      = $tokens['realm_id'];
        }

        $this->dataService = DataService::Configure($config);
    }

    public function getDataService()
    {
        return $this->dataService;
    }

   
    public function saveTokens($accessToken, $refreshToken, $realmId)
    {
        $environment = env('QB_ENVIRONMENT', 'sandbox'); // sandbox or production

        QuickbooksToken::updateOrCreate(
            ['environment' => $environment], 
            [
                'access_token'  => $accessToken,
                'refresh_token' => $refreshToken,
                'realm_id'      => $realmId,
            ]
        );

        Storage::disk('local')->put('quickbooks_tokens.json', json_encode([
            'access_token'  => $accessToken,
            'refresh_token' => $refreshToken,
            'realm_id'      => $realmId,
            'environment'   => $environment,
        ]));

        Setting::set([
            'quickbooks_connect' => 1,
            'quickbooks_sales_receipt_delete' => 1,
        ])->save();
    }

    public function refreshAccessToken($token)
    {
        $response = Http::asForm()
            ->withHeaders([
                'Authorization' => 'Basic ' . base64_encode(
                    env('QB_CLIENT_ID') . ':' . env('QB_CLIENT_SECRET')
                ),
                'Accept' => 'application/json',
            ])
            ->post('https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer', [
                'grant_type'    => 'refresh_token',
                'refresh_token'=> $token->refresh_token,
            ]);

        if (! $response->successful()) {
            Log::error('QuickBooks token refresh failed', [
                'status' => $response->status(),
                'body'   => $response->body(),
            ]);
            return null;
        }

        $data = $response->json();

        $token->update([
            'access_token'  => $data['access_token'],
            'refresh_token' => $data['refresh_token'], // Always save new refresh token
        ]);

        return $token->fresh();
    }

    public function createSalesReceipt(array $data)
    {
        $salesReceipt = SalesReceipt::create([
            'CustomerRef' => [
                'value' => $data['customer_id'],
            ],
            'Line' => [[
                'Amount' => $data['amount'],
                'DetailType' => 'SalesItemLineDetail',
                'SalesItemLineDetail' => [
                    'ItemRef' => [
                        'value' => $data['item_id'],
                    ],
                    'Qty' => $data['quantity'],
                ],
            ]],
            'TotalAmt' => $data['amount'],
        ]);

        $result = $this->dataService->Add($salesReceipt);

        if ($error = $this->dataService->getLastError()) {
            return ['success' => false, 'message' => $error->getResponseBody()];
        }

        return [
            'success'     => true,
            'id'          => $result->Id,
            'doc_number'  => $result->DocNumber,
        ];
    }

    public function fetchItems(int $startPosition = 1, int $maxResults = 100, ?string $search = null, string $orderBy = 'Name', string $orderDir = 'ASC'): array
    {
        $token = QuickbooksToken::where('environment', env('QB_ENVIRONMENT', 'sandbox'))->first();

        if (! $token) {
            Log::error('QuickBooks token not found');
            return [];
        }

        $maxResults = min($maxResults, 1000);

        $baseUrl = rtrim(
            env('QUICKBOOKS_API_BASE_URL', 'https://sandbox-quickbooks.api.intuit.com/v3/company'),
            '/'
        );

        $headers = [
            'Authorization' => 'Bearer ' . $token->access_token,
            'Accept'        => 'application/json',
            'Content-Type'  => 'application/json',
        ];

        $results = [];

        if ($search) {
            $escaped = str_replace("'", "''", $search);

            $fields = ['Name', 'Sku'];

            foreach ($fields as $field) {
                $query = "SELECT * FROM Item WHERE {$field} LIKE '%{$escaped}%' ORDER BY {$orderBy} {$orderDir} STARTPOSITION {$startPosition} MAXRESULTS {$maxResults}";
                $queryUrl = "{$baseUrl}/{$token->realm_id}/query?query=" . rawurlencode($query);

                $res = Http::withHeaders($headers)->get($queryUrl);

                // Retry on token expiry
                if ($res->status() === 401) {
                    Log::warning("QB Product API 401 on {$field}. Refreshing token...");

                    $token = $this->refreshAccessToken($token);

                    if (!$token) continue;

                    $headers['Authorization'] = 'Bearer ' . $token->access_token;
                    $res = Http::withHeaders($headers)->get($queryUrl);
                }

                if (!$res->successful()) {
                    Log::error("QuickBooks Products API failed on {$field}", [
                        'status' => $res->status(),
                        'body'   => $res->body(),
                    ]);
                    continue;
                }

                $queryResponse = $res->json()['QueryResponse'] ?? [];
                $accounts = $queryResponse['Item'] ?? [];
                $results = array_merge($results, $accounts);
            }
            // Remove duplicates by 'Id'
            $results = collect($results)->unique('Id')->values()->all();

        } else {
             // No search, just fetch normally
            $query = "SELECT * FROM Item ORDER BY {$orderBy} {$orderDir} STARTPOSITION {$startPosition} MAXRESULTS {$maxResults}";
            $queryUrl = "{$baseUrl}/{$token->realm_id}/query?query=" . rawurlencode($query);

            $res = Http::withHeaders($headers)->get($queryUrl);

            if ($res->status() === 401) {
                $token = $this->refreshAccessToken($token);

                if ($token) {
                    $headers['Authorization'] = 'Bearer ' . $token->access_token;
                    $res = Http::withHeaders($headers)->get($queryUrl);
                }
            }

            if ($res->successful()) {
                $queryResponse = $res->json()['QueryResponse'] ?? [];
                $results = $queryResponse['Item'] ?? [];
            }

            if (! $res->successful()) {
                Log::error('QuickBooks Item API failed', [
                    'status' => $res->status(),
                    'body'   => $res->body(),
                ]);
                return ['data' => []];
            }
        }

        $results = collect($results)
                ->reject(fn ($item) => ($item['Type'] ?? '') === 'Category')
                ->values()
                ->all();

        return ['data' => $results];
        
       
    }

    public function fetchItemById($id)
    {
        $token = QuickbooksToken::where('environment', env('QB_ENVIRONMENT', 'sandbox'))->first();

        if (!$token) return null;

        $baseUrl = rtrim(env('QUICKBOOKS_API_BASE_URL', 'https://sandbox-quickbooks.api.intuit.com/v3/company'), '/');
        $queryUrl = "{$baseUrl}/{$token->realm_id}/query";

        $headers = [
            'Authorization' => 'Bearer ' . $token->access_token,
            'Accept'        => 'application/json',
            'Content-Type'  => 'application/json',
        ];

        $res = Http::withHeaders($headers)->get($queryUrl, [
            'query' => "SELECT * FROM Item WHERE Id = '{$id}'"
        ]);

        // Handle token expiry
        if ($res->status() === 401) {
            $token = $this->refreshAccessToken($token);
            if (!$token) return null;

            $headers['Authorization'] = 'Bearer ' . $token->access_token;
            $res = Http::withHeaders($headers)->get($queryUrl, [
                'query' => "SELECT * FROM Item WHERE Id = '{$id}'"
            ]);
        }

        if (!$res->successful()) return null;

        return collect($res->json()['QueryResponse']['Item'] ?? [])->first();
    }

    public function fetchItemCategories(int $startPosition = 1, int $maxResults = 100, ?string $search = null, string $orderBy = 'Name', string $orderDir = 'ASC'): array
    {
        $token = QuickbooksToken::where('environment', env('QB_ENVIRONMENT', 'sandbox'))->first();

        if (! $token) {
            Log::error('QuickBooks token not found');
            return [];
        }

        $maxResults = min($maxResults, 1000);

        $baseUrl = rtrim(
            env('QUICKBOOKS_API_BASE_URL', 'https://sandbox-quickbooks.api.intuit.com/v3/company'),
            '/'
        );

        $headers = [
            'Authorization' => 'Bearer ' . $token->access_token,
            'Accept'        => 'application/json',
            'Content-Type'  => 'application/json',
        ];

        $results = [];

        if ($search) {
            $escaped = str_replace("'", "''", $search);

            $fields = ['Name'];

            foreach ($fields as $field) {
                $query = "SELECT * FROM Item WHERE Type='Category' AND {$field} LIKE '%{$escaped}%' ORDER BY {$orderBy} {$orderDir} STARTPOSITION {$startPosition} MAXRESULTS {$maxResults}";
                $queryUrl = "{$baseUrl}/{$token->realm_id}/query?query=" . rawurlencode($query);

                $res = Http::withHeaders($headers)->get($queryUrl);

                // Retry on token expiry
                if ($res->status() === 401) {
                    Log::warning("QB Category API 401 on {$field}. Refreshing token...");

                    $token = $this->refreshAccessToken($token);

                    if (!$token) continue;

                    $headers['Authorization'] = 'Bearer ' . $token->access_token;
                    $res = Http::withHeaders($headers)->get($queryUrl);
                }

                if (!$res->successful()) {
                    Log::error("QuickBooks Category API failed on {$field}", [
                        'status' => $res->status(),
                        'body'   => $res->body(),
                    ]);
                    continue;
                }

                $queryResponse = $res->json()['QueryResponse'] ?? [];
                $accounts = $queryResponse['Item'] ?? [];
                $results = array_merge($results, $accounts);
            }
            // Remove duplicates by 'Id'
            $results = collect($results)->unique('Id')->values()->all();
        } else {
             // No search, just fetch normally
            $query = "SELECT * FROM Item WHERE Type='Category' ORDER BY {$orderBy} {$orderDir} STARTPOSITION {$startPosition} MAXRESULTS {$maxResults}";
            $queryUrl = "{$baseUrl}/{$token->realm_id}/query?query=" . rawurlencode($query);

            $res = Http::withHeaders($headers)->get($queryUrl);

            if ($res->status() === 401) {
                $token = $this->refreshAccessToken($token);

                if ($token) {
                    $headers['Authorization'] = 'Bearer ' . $token->access_token;
                    $res = Http::withHeaders($headers)->get($queryUrl);
                }
            }

            if ($res->successful()) {
                $queryResponse = $res->json()['QueryResponse'] ?? [];
                $results = $queryResponse['Item'] ?? [];
            }

             if (! $res->successful()) {
                Log::error('QuickBooks Item Category API failed', [
                    'status' => $res->status(),
                    'body'   => $res->body(),
                ]);
                $results = [];
            }
        }
        
        return ['data' => $results];
        
       
    }

    public function fetchAccount(int $startPosition = 1, int $maxResults = 100, ?string $search = null, string $orderBy = 'Name', string $orderDir = 'ASC', ?string $accountLevel = null, ?string $parentAccountId = null): array
    {
        $token = QuickbooksToken::where('environment', env('QB_ENVIRONMENT', 'sandbox'))->first();

        if (!$token) {
            Log::error('QuickBooks token not found');
            return ['data' => []];
        }

        $maxResults = min($maxResults, 1000);

        $baseUrl = rtrim(
            env('QUICKBOOKS_API_BASE_URL', 'https://sandbox-quickbooks.api.intuit.com/v3/company'),
            '/'
        );

        $headers = [
            'Authorization' => 'Bearer ' . $token->access_token,
            'Accept'        => 'application/json',
            'Content-Type'  => 'application/json',
        ];

        $results = [];

        $where = "";
        $whereParts = [];
        if ($accountLevel === 'sub') {
            $whereParts[] = "SubAccount = true";
        } elseif ($accountLevel === 'main') {
            $whereParts[] = "SubAccount = false";
        }

        if ($parentAccountId) {
            $whereParts[] = "ParentRef = '{$parentAccountId}'";
        }
       
        if ($search) {
            $escaped = str_replace("'", "''", $search);

            // Fields to search individually
            $fields = ['Name', 'FullyQualifiedName', 'AccountType', 'AccountSubType'];

            
            $where = $whereParts ? ' AND ' . implode(' AND ', $whereParts) : '';

            foreach ($fields as $field) {
                if ($field == 'AccountType') {
                     $query = "SELECT * FROM Account WHERE AccountType = '{$escaped}' ".$where." ORDER BY {$orderBy} {$orderDir}  STARTPOSITION {$startPosition} MAXRESULTS {$maxResults}";
                } elseif ($field == 'AccountSubType') {
                    $query = "SELECT * FROM Account  WHERE AccountSubType = '{$escaped}' ".$where." ORDER BY {$orderBy} {$orderDir} STARTPOSITION {$startPosition} MAXRESULTS {$maxResults}";
                } else {
                     $query = "SELECT * FROM Account WHERE {$field} LIKE '%{$escaped}%' ".$where." ORDER BY {$orderBy} {$orderDir} STARTPOSITION {$startPosition} MAXRESULTS {$maxResults}";
                }
    
                $queryUrl = "{$baseUrl}/{$token->realm_id}/query?query=" . rawurlencode($query);

                $res = Http::withHeaders($headers)->get($queryUrl);

                // Retry on token expiry
                if ($res->status() === 401) {
                    Log::warning("QB Account API 401 on {$field}. Refreshing token...");

                    $token = $this->refreshAccessToken($token);

                    if (!$token) continue;

                    $headers['Authorization'] = 'Bearer ' . $token->access_token;
                    $res = Http::withHeaders($headers)->get($queryUrl);
                }

                if (!$res->successful()) {
                    Log::error("QuickBooks Accounts API failed on {$field}", [
                        'status' => $res->status(),
                        'body'   => $res->body(),
                    ]);
                    continue;
                }

                $queryResponse = $res->json()['QueryResponse'] ?? [];
                $accounts = $queryResponse['Account'] ?? [];
                $results = array_merge($results, $accounts);
            }
            // Remove duplicates by 'Id'
            $results = collect($results)->unique('Id')->values()->all();
        } else {
            // No search, just fetch normally
            $where = $whereParts ? ' WHERE ' . implode(' AND ', $whereParts) : '';

            $query = "SELECT * FROM Account ".$where." ORDER BY {$orderBy} {$orderDir} STARTPOSITION {$startPosition} MAXRESULTS {$maxResults}";
            $queryUrl = "{$baseUrl}/{$token->realm_id}/query?query=" . rawurlencode($query);

            $res = Http::withHeaders($headers)->get($queryUrl);

            if ($res->status() === 401) {
                $token = $this->refreshAccessToken($token);

                if ($token) {
                    $headers['Authorization'] = 'Bearer ' . $token->access_token;
                    $res = Http::withHeaders($headers)->get($queryUrl);
                }
            }

            if ($res->successful()) {
                $queryResponse = $res->json()['QueryResponse'] ?? [];
                $results = $queryResponse['Account'] ?? [];
            }
        }

        return ['data' => $results];
    }

    public function countAllAccounts(): int
    {
        $start = 1;
        $limit = 1000;
        $total = 0;

        do {
            $res = $this->fetchAccount($start, $limit);
            $count = count($res['data']);
            $total += $count;
            $start += $limit;
        } while ($count === $limit);

        return $total;
    }

    public function countAccountsByLevel(?string $accountLevel = null): int
    {
        $start = 1;
        $limit = 1000;
        $total = 0;

        do {
            $res = $this->fetchAccount(
                $start,
                $limit,
                null,
                'Id',
                'ASC',
                $accountLevel
            );

            $count = count($res['data']);
            $total += $count;
            $start += $limit;

        } while ($count === $limit);

        return $total;
    }

    public function countAccountsBySearch(?string $search = null): int
    {
        $start = 1;
        $limit = 1000;
        $total = 0;

        do {
            $res = $this->fetchAccount(
                $start,
                $limit,
                $search,
                'Id',
                'ASC',
                null
            );

            $count = count($res['data']);
            $total += $count;
            $start += $limit;

        } while ($count === $limit);

        return $total;
    }

    public function countAccountsBySearchFilter(?string $accountLevel = null, ?string $search = null): int
    {
        $start = 1;
        $limit = 1000;
        $total = 0;

        do {
            $res = $this->fetchAccount(
                $start,
                $limit,
                $search,
                'Id',
                'ASC',
                $accountLevel
            );

            $count = count($res['data']);
            $total += $count;
            $start += $limit;

        } while ($count === $limit);

        return $total;
    }

    public function countAccountsByParent(string $parentAccountId): int
    {
        $start = 1;
        $limit = 1000;
        $total = 0;

        do {
            $res = $this->fetchAccount(
                $start,
                $limit,
                null,
                'Id',
                'ASC',
                null,
                $parentAccountId
            );

            $count = count($res['data']);
            $total += $count;
            $start += $limit;

        } while ($count === $limit);

        return $total;
    }

    public function countAccountsBySearchParent(?string $parentAccountId = null, ?string $search = null): int
    {
        $start = 1;
        $limit = 1000;
        $total = 0;

        do {
            $res = $this->fetchAccount(
                $start,
                $limit,
                $search,
                'Id',
                'ASC',
                null,
                $parentAccountId
            );

            $count = count($res['data']);
            $total += $count;
            $start += $limit;

        } while ($count === $limit);

        return $total;
    }


    public function fetchMainAccountsForFilter(): array
    {
        $token = QuickbooksToken::where('environment', env('QB_ENVIRONMENT', 'sandbox'))->first();

        if (!$token) {
            return [];
        }

        $baseUrl = rtrim(env('QUICKBOOKS_API_BASE_URL'), '/');

        $headers = [
            'Authorization' => 'Bearer ' . $token->access_token,
            'Accept'        => 'application/json',
        ];

        $startPosition = 1;
        $maxResults    = 1000;
        $allAccounts   = [];

        do {
            $query = "SELECT Id, Name 
                    FROM Account 
                    WHERE SubAccount = false 
                    ORDER BY Name 
                    STARTPOSITION {$startPosition} 
                    MAXRESULTS {$maxResults}";

            $url = "{$baseUrl}/{$token->realm_id}/query"
                . "?minorversion=65&query=" . rawurlencode($query);

            $res = Http::withHeaders($headers)->get($url);

            /** 🔁 Refresh token if expired */
            if ($res->status() === 401) {

                $token = $this->refreshAccessToken($token);

                if (!$token) {
                    break;
                }

                $headers['Authorization'] = 'Bearer ' . $token->access_token;
                $res = Http::withHeaders($headers)->get($url);
            }

            if (!$res->successful()) {
                \Log::error('QB fetchMainAccountsForFilter failed', [
                    'status' => $res->status(),
                    'body'   => $res->body(),
                ]);
                break;
            }

            $accounts = $res->json()['QueryResponse']['Account'] ?? [];

            $count = count($accounts);
            $allAccounts = array_merge($allAccounts, $accounts);

            $startPosition += $maxResults;

        } while ($count === $maxResults);

        return $allAccounts;
    }

    public function countAllProducts(): int
    {
        $start = 1;
        $limit = 1000;
        $total = 0;

        do {
            $res = $this->fetchItems($start, $limit);
            $count = count($res['data']);
            $total += $count;
            $start += $limit;
        } while ($count === $limit);

        return $total;
    }

    public function countProductsBySearch(?string $search = null): int
    {
        $start = 1;
        $limit = 1000;
        $total = 0;

        do {
            $res = $this->fetchItems(
                $start,
                $limit,
                $search,
                'Name',
                'ASC'
            );

            $count = count($res['data']);
            $total += $count;
            $start += $limit;

        } while ($count === $limit);

        return $total;
    }

    public function countAllCategories(): int
    {
        $start = 1;
        $limit = 1000;
        $total = 0;

        do {
            $res = $this->fetchItemCategories($start, $limit);
            $count = count($res['data']);
            $total += $count;
            $start += $limit;
        } while ($count === $limit);

        return $total;
    }

    public function countCategoriesBySearch(?string $search = null): int
    {
        $start = 1;
        $limit = 1000;
        $total = 0;

        do {
            $res = $this->fetchItemCategories(
                $start,
                $limit,
                $search,
                'Name',
                'ASC'
            );

            $count = count($res['data']);
            $total += $count;
            $start += $limit;

        } while ($count === $limit);

        return $total;
    }

    public function getAccountNameById(string $accountId): ?string
    {
        $token = QuickbooksToken::where('environment', env('QB_ENVIRONMENT', 'sandbox'))->first();

        if (!$token) {
            return null;
        }

        $baseUrl = rtrim(
            env('QUICKBOOKS_API_BASE_URL', 'https://sandbox-quickbooks.api.intuit.com/v3/company'),
            '/'
        );

        $query = "SELECT Name FROM Account WHERE Id = '{$accountId}'";
        $queryUrl = "{$baseUrl}/{$token->realm_id}/query?query=" . rawurlencode($query);

        $res = Http::withHeaders([
            'Authorization' => 'Bearer ' . $token->access_token,
            'Accept' => 'application/json',
        ])->get($queryUrl);

        if (!$res->successful()) {
            return null;
        }

        return $res->json('QueryResponse.Account.0.Name');
    }



}

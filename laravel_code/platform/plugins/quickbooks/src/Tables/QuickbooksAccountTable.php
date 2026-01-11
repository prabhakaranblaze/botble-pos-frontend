<?php

namespace Botble\Quickbooks\Tables;

use Botble\Table\Abstracts\TableAbstract;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Database\Query\Builder as QueryBuilder;
use Illuminate\Http\JsonResponse;
use Botble\Table\Columns\Column;
use BaseHelper;
use Botble\Quickbooks\Services\QuickBooksService;
use Botble\Table\HeaderActions\HeaderAction;
use Illuminate\Support\Facades\Cache;
use Botble\Base\Facades\Assets;

class QuickbooksAccountTable extends TableAbstract
{
    public function setup(): void
    {
        $this->hasActions = false;
        $this->hasOperations = false; 
    }

    public function ajax(): JsonResponse
    {
        $request = request();

        $start  = (int) $request->get('start', 0);   
        $length = (int) $request->get('length', 10);

        $qbStart = $start + 1;
        $qbLimit = min($length, 1000);

        $search = $request->input('search.value', null);

        $orderColumnIndex = $request->input('order.0.column');
        $orderDirection   = $request->input('order.0.dir', 'asc');

        $accountLevel = null;

        $filterColumns = $request->input('filter_columns', []);
        $filterValues  = $request->input('filter_values', []);

        if (($index = array_search('account_level', $filterColumns)) !== false) {
            $accountLevel = $filterValues[$index] ?? null;
        }

        $parentAccountId = null;

        if (($index = array_search('parent_account', $filterColumns)) !== false) {
            $parentAccountId = $filterValues[$index] ?? null;
        }

        $columnMap = [
            0 => 'Id',
            1 => 'Name',
            2 => 'FullyQualifiedName',
        ];

        $orderBy = $columnMap[$orderColumnIndex] ?? 'Name';
        $orderDirection = strtoupper($orderDirection) === 'DESC' ? 'DESC' : 'ASC';

        $service = app(QuickBooksService::class);

        // Cache total count
        /*$total_record = Cache::remember('qb_accounts_total', 3600, function () use ($service) {
            return $service->countAllAccounts();
        });*/
        $total_record = $service->countAllAccounts();
        

        $response = $service->fetchAccount($qbStart, $qbLimit, $search, $orderBy, $orderDirection, $accountLevel, $parentAccountId);
        $items = $response['data'];

        $accountNameMap = collect($items)->pluck('Name', 'Id');

        $collection = collect($items)->map(function ($item) use ($accountNameMap, $service) {
            $parentName = null;
            $parentId = '';
            if (isset($item['SubAccount']) && $item['SubAccount'] == true && isset($item['ParentRef']) && isset($item['ParentRef']['value'])) {
                $parentId = $item['ParentRef']['value'] ?? null;
                $parentName = $accountNameMap[$parentId] ?? $service->getAccountNameById($parentId) ?? '-';
            }
            return [
                'id'     => $item['Id'],
                'name'   => $item['Name'],
                'fullname' => $item['FullyQualifiedName'],
                'account_type' => $item['AccountType'],
                'status' => !empty($item['Active'])
                    ? '<span class="badge bg-success text-success-fg">Active</span>'
                    : '<span class="badge bg-danger text-success-fg">Inactive</span>',
                'sub_account' => $item['SubAccount'],
                'parent_account' => $parentName,
                'account_sub_type' => $item['AccountSubType'],
                'currency' => $item['CurrencyRef']['value'] ?? '',    
                'current_balance' => $item['CurrentBalance'],
                'current_balance_sub_account' => $item['CurrentBalanceWithSubAccounts'],
                'created_time' => !empty($item['MetaData']['CreateTime'])
                    ? BaseHelper::formatDateTime($item['MetaData']['CreateTime'])
                    : '-',
            ];
        });
        // Calculate filtered total for search
        $recordsFiltered  = $total_record;

        if ($accountLevel && $search) {
            $recordsTotal = $service->countAccountsBySearchFilter($accountLevel, $search);
            $recordsFiltered = $recordsTotal;
        } elseif ($parentAccountId && $search) {
            $recordsTotal = $service->countAccountsBySearchParent($parentAccountId, $search);
            $recordsFiltered = $recordsTotal;
        } elseif ($accountLevel) {
            $recordsTotal = $service->countAccountsByLevel($accountLevel);
            $recordsFiltered = $recordsTotal;
        } elseif ($parentAccountId) {
            $recordsTotal = $service->countAccountsByParent($parentAccountId);
            $recordsFiltered = $recordsTotal;
        } elseif ($search) {
            $recordsTotal = $service->countAccountsBySearch($search);
            $recordsFiltered = $recordsTotal;
        }
        

        // Manually slice collection if needed
        $paged = $collection->slice(0, $length)->values();

        return response()->json([
            'draw' => (int)$request->get('draw'),
            'recordsTotal' => $total_record,
            'recordsFiltered' => $recordsFiltered,
            'data' => $paged,
        ]);
    }

    

    public function query()
    {
        return null;
    }

    /* --------------------------------------
     * TABLE COLUMNS
     * -------------------------------------- */
    public function columns(): array
    {
        return [
            Column::make('id')
                ->title(trans('plugins/quickbooks::qbs.accounts.id'))
                ->width('80px'),

            Column::make('name')
                ->title(trans('plugins/quickbooks::qbs.accounts.name')),

            Column::make('fullname')
                ->title(trans('plugins/quickbooks::qbs.accounts.fullname')), 
            
            Column::make('account_type')
                ->title(trans('plugins/quickbooks::qbs.accounts.account_type'))
                ->orderable(false),
             
            Column::make('status')
                ->title(trans('plugins/quickbooks::qbs.accounts.status'))
                ->raw(true)
                ->orderable(false),
            
            Column::make('sub_account')
                ->title(trans('plugins/quickbooks::qbs.accounts.sub_account'))
                ->orderable(false), 
                
            Column::make('parent_account')
                ->title(trans('plugins/quickbooks::qbs.accounts.parent_account'))
                ->orderable(false),     
                
            Column::make('account_sub_type')
                ->title(trans('plugins/quickbooks::qbs.accounts.account_sub_type'))
                ->orderable(false),  

            Column::make('currency')
                ->title(trans('plugins/quickbooks::qbs.accounts.currency'))
                ->orderable(false),    

            Column::make('current_balance')
                ->title(trans('plugins/quickbooks::qbs.accounts.current_balance'))
                ->orderable(false),      
                
            Column::make('current_balance_sub_account')
                ->title(trans('plugins/quickbooks::qbs.accounts.current_balance_sub_account'))
                ->orderable(false),   
                
            Column::make('created_time')
                ->title(trans('plugins/quickbooks::qbs.accounts.created_time'))
                ->orderable(false),     
        ];
    }

    /* --------------------------------------
     * FILTER PANEL
     * -------------------------------------- */
    public function getFilters(): array
    {
        $service = app(QuickBooksService::class);

        $mainAccounts = collect($service->fetchMainAccountsForFilter())
                        ->pluck('Name', 'Id')
                        ->toArray();

        return [
            'account_level' => [
                'title' => trans('plugins/quickbooks::qbs.accounts.account_level'),
                'type'  => 'select',
                'choices' => [
                    ''   => 'All',
                    'main' => 'Main Accounts',
                    'sub'  => 'Sub Accounts',
                ],
            ],
            'parent_account' => [
                'title'   => trans('plugins/quickbooks::qbs.accounts.main_accounts'),
                'type'    => 'select',
                'choices' => ['' => 'All'] + $mainAccounts,
            ],
        ];
    }

    /* --------------------------------------
     * DEFAULT BUTTONS (Export, Reload…)
     * -------------------------------------- */
    public function getDefaultButtons(): array
    {
        return [
            'reload',
        ];
    }


    /* --------------------------------------
     * RENDER TABLE
     * -------------------------------------- */
    public function renderTable(array $data = [], array $mergeData = []): \Illuminate\Contracts\View\View|\Illuminate\Contracts\View\Factory|\Symfony\Component\HttpFoundation\Response
    {
        Assets::addScriptsDirectly(
            'vendor/plugins/quickbooks/assets/js/tablesearch.js'
        );
        return parent::renderTable($data, $mergeData);
    }
}

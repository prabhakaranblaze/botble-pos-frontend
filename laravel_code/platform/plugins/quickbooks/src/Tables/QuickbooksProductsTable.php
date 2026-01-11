<?php

namespace Botble\Quickbooks\Tables;

use Botble\Table\Abstracts\TableAbstract;
use Botble\Quickbooks\Models\QuickbooksJob;
use Illuminate\Contracts\Routing\UrlGenerator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Database\Query\Builder as QueryBuilder;
use Illuminate\Http\JsonResponse;
use Botble\Table\Actions\EditAction;
use Botble\Table\Columns\Column;
use Botble\Table\BulkActions\DeleteBulkAction;
use Botble\Table\BulkActions\BulkAction;
use Botble\Quickbooks\Tables\Actions\RefreshAction;
use BaseHelper;
use Botble\Quickbooks\Services\QuickBooksService;
use Botble\Ecommerce\Models\Product;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Botble\Base\Facades\Assets;

class QuickbooksProductsTable extends TableAbstract
{
    public function setup(): void
    {
        $this->hasActions = true;
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

        $columnMap = [
            0 => 'Id',
            1 => 'Name',
            2 => 'Sku',
        ];

        $orderBy = $columnMap[$orderColumnIndex] ?? 'Name';
        $orderDirection = strtoupper($orderDirection) === 'DESC' ? 'DESC' : 'ASC';


        $service = app(QuickBooksService::class);

        // Cache total count
        $total_record = $service->countAllProducts();

        $items = $service->fetchItems($qbStart, $qbLimit, $search, $orderBy, $orderDirection);
        $items = $items['data'];

        $collection = collect($items)->map(function ($item) {
            // Fetch product ID from ec_products
            $productId = Product::where('quickbooks_item_id', $item['Id'])->value('id');

            $operations = '';
            if (empty($productId)) {
                if (Auth::user()->hasPermission('quickbooks.productimport')) {
                    $operations = '<a href="'. route('quickbooks.products.import', $item['Id']) .'" class="btn btn-sm btn-primary">Import</a>';
                }
                
            } else {
                $operations = '<a href="'. route('products.edit', $productId). '" target="_blank" class="btn btn-sm btn-info">View</a>';
            }

            $sku = $item['Sku'] ?? '-';


            return [
                'id'     => $item['Id'],
                'name'   => $item['Name'],
                'sku'    => $sku,
                'type'   => $item['Type'],
                'price'  => $item['UnitPrice'] ?? '-',
                'status' => !empty($item['Active'])
                    ? '<span class="badge bg-success text-success-fg">Active</span>'
                    : '<span class="badge bg-danger text-success-fg">Inactive</span>',
                'product_id' => $productId ?? '-',
                'income_account' => isset($item['IncomeAccountRef']['name']) ? $item['IncomeAccountRef']['name'] : '',
                'expense_account' => isset($item['ExpenseAccountRef']['name']) ? $item['ExpenseAccountRef']['name'] : '',
                'asset_account' => isset($item['AssetAccountRef']['name']) ? $item['AssetAccountRef']['name'] : '',
                'vendor' => isset($item['PrefVendorRef']['name']) ? $item['PrefVendorRef']['name'] : '',
                'operations' => $operations,
            ];
        });
        // Calculate filtered total for search
        // Calculate filtered total for search
        $recordsFiltered  = $total_record;
        if ($search) {
            $recordsTotal = $service->countProductsBySearch($search);
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
                ->title(trans('plugins/quickbooks::qbs.products.id'))
                ->width('80px'),

            Column::make('name')
                ->title(trans('plugins/quickbooks::qbs.products.name')),

            Column::make('sku') 
                ->title(trans('plugins/quickbooks::qbs.products.sku')),    

            Column::make('type')
                ->title(trans('plugins/quickbooks::qbs.products.type'))
                ->orderable(false),

            Column::make('price')
                ->title(trans('plugins/quickbooks::qbs.products.price'))
                ->orderable(false),

            Column::make('status')
                ->title(trans('plugins/quickbooks::qbs.products.status'))
                ->raw(true)
                ->orderable(false),

            Column::make('product_id')
                ->title(trans('plugins/quickbooks::qbs.products.product_id'))
                ->orderable(false),  
                
            Column::make('income_account')
                ->title(trans('plugins/quickbooks::qbs.products.income_account'))
                ->orderable(false),  
               
            Column::make('expense_account')
                ->title(trans('plugins/quickbooks::qbs.products.expense_account'))
                ->orderable(false),  
                
            Column::make('asset_account')
                ->title(trans('plugins/quickbooks::qbs.products.asset_account'))
                ->orderable(false),  
                
            Column::make('vendor')
                ->title(trans('plugins/quickbooks::qbs.products.vendor'))
                ->orderable(false),      
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

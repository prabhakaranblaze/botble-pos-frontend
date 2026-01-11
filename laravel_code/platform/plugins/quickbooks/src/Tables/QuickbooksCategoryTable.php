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
use Botble\Ecommerce\Models\ProductCategory;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Botble\Base\Facades\Assets;

class QuickbooksCategoryTable extends TableAbstract
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
        $total_record  = $service->countAllCategories();

        $items = $service->fetchItemCategories($qbStart, $qbLimit, $search, $orderBy, $orderDirection);
        $items = $items['data'];

        $collection = collect($items)->map(function ($item) {
            // Fetch product ID from ec_products
            $categoryId = ProductCategory::where('qb_cat_id', $item['Id'])->value('id');

            $operations = '';
            if (empty($categoryId)) {
                if (Auth::user()->hasPermission('quickbooks.categoryimport')) {
                    $operations = '<a href="'. route('quickbooks.categories.import', $item['Id']) .'" class="btn btn-sm btn-primary">Import</a>';
                }
                
            } else {
                $operations = '<a href="'. route('product-categories.edit', $categoryId). '" target="_blank" class="btn btn-sm btn-info">View</a>';
            }


            return [
                'id'     => $item['Id'],
                'name'   => $item['Name'],
                'status' => !empty($item['Active'])
                    ? '<span class="badge bg-success text-success-fg">Active</span>'
                    : '<span class="badge bg-danger text-success-fg">Inactive</span>',
                'category_id' => $categoryId ?? '-',
                'operations' => $operations,
            ];
        });
        // Calculate filtered total for search
        $recordsFiltered  = $total_record;
        if ($search) {
            $recordsTotal = $service->countCategoriesBySearch($search);
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
                ->title(trans('plugins/quickbooks::qbs.categories.id'))
                ->width('80px'),

            Column::make('name')
                ->title(trans('plugins/quickbooks::qbs.categories.name')),

            Column::make('status')
                ->title(trans('plugins/quickbooks::qbs.categories.status'))
                ->raw(true)
                ->orderable(false),

            Column::make('category_id')
                ->title(trans('plugins/quickbooks::qbs.categories.category_id'))
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

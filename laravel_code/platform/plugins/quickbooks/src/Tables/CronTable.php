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
use Illuminate\Support\Facades\Auth;

class CronTable extends TableAbstract
{
    protected bool $canRefresh = false;

    public function setup(): void
    {
        $this->model(QuickbooksJob::class);

        $this->canRefresh = Auth::check() &&
            Auth::user()->hasPermission('quickbooks.salesreceipt');

        $this->hasActions = false;
        $this->hasOperations = false; 
    }

    public function ajax(): JsonResponse
    {
        $statuses = config('quickbooks_status');

        $data = $this->table->eloquent($this->query())

            ->editColumn('order_id', function ($item) {
                return $item->order->code ?? '-';
            })
            
            ->editColumn('status', function ($item) use ($statuses) { 
                $status = $item->status;
                
                if (!isset($statuses[$status])) {
                    return '<span class="badge badge-secondary">Unknown</span>';
                }

                return '<span class="badge ' . $statuses[$status]['class'] . '">' .
                    $statuses[$status]['label'] .
                    '</span>';
            })


           ->editColumn('cron_data', function ($item) {

                return '<button class="btn btn-sm btn-primary show-cron-data view-cron-data" data-id="'.$item->id.'">View</button>';
            })

            ->editColumn('created_at', function ($item) {
                return $item->created_at;
            })

            ->editColumn('operations', function ($item) {
                if (!$this->canRefresh) {
                    return '';
                }

                if ($item->status != 0) {
                    return 'N/A';
                }

                return '<a href="' . route('quickbooks.refresh', ['id' => $item->id]) . '" 
                    class="btn btn-sm btn-icon btn-primary" title="Refresh">
                    <svg class="icon svg-icon-ti-ti-refresh" xmlns="http://www.w3.org/2000/svg"
                        width="24" height="24" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" stroke-width="2" stroke-linecap="round"
                        stroke-linejoin="round">
                        <path d="M20 11a8.1 8.1 0 0 0 -15.5 -2m-.5 -4v4h4"></path>
                        <path d="M4 13a8.1 8.1 0 0 0 15.5 2m.5 4v-4h-4"></path>
                    </svg>
                </a>';
            })

            ->rawColumns(['cron_data'])

            // Apply table filters
            ->filter(function ($query) {
                return $this->filterOrders($query);
            });

        return $this->toJson($data);
    }


    public function query(): Relation|Builder|QueryBuilder
    {
        $table = $this->getModel()->getTable(); 

        return $this->getModel()
            ->query()
            ->with(['order'])
            ->select([
                "$table.id",
                "$table.order_id",
                "$table.amount",
                "$table.status",
                "$table.post_url",
                "$table.payload",
                "$table.quickbook_response",
                "$table.fail_count",
                "$table.created_at",
            ]);
    }

    /* --------------------------------------
     * TABLE COLUMNS
     * -------------------------------------- */
    public function columns(): array
    {
        return [
            Column::make('id')
                ->title(trans('plugins/quickbooks::qbs.crons.id'))
                ->width(60),

            Column::make('order.code')
                ->title(trans('plugins/quickbooks::qbs.crons.order_id'))
                ->orderable(true)
                ->sortColumn('order.code'),

            Column::make('amount')
                ->title(trans('plugins/quickbooks::qbs.crons.amount')),

            Column::make('status')
                ->title(trans('plugins/quickbooks::qbs.crons.status')), 

            Column::make('cron_data')
                ->orderable(false) 
                ->title(trans('plugins/quickbooks::qbs.crons.cron_data')),        

            Column::make('fail_count')
                ->title(trans('plugins/quickbooks::qbs.crons.fail_count')),   

            Column::make('created_at')
                ->title(trans('plugins/quickbooks::qbs.crons.created_at'))
                ->width(150),

            Column::make('operations')
                ->title('Operations')
                ->orderable(false)
                ->searchable(false),    

                
        ];
    }

    /* --------------------------------------
     * FILTER PANEL
     * -------------------------------------- */
    public function getFilters(): array
    {
        $statuses = config('quickbooks_status'); // load from config file

        // Convert config to simple key-value array
        $statusChoices = [];
        foreach ($statuses as $key => $data) {
            $statusChoices[$key] = $data['label'];
        }
       
        return [
            'status' => [
                'title' => 'Status',
                'type'  => 'select',
                'choices' => $statusChoices,   // dynamic values from config
            ],
        ];
    }

    /* --------------------------------------
     * APPLY FILTER LOGIC
     * -------------------------------------- */
    public function applyFilterCondition($query, string $key, string $operator, string|null $value): Builder|Relation|QueryBuilder
    {  
        
        if ($key === 'status') {
           return $query->where('status', intval($value));
        }

        return $query;
    }

    /* Dummy filter for compatibility */
    public function filterByCustomer($query, $value)
    {
        return $query;
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
     * FILTER ORDERS (Global Search)
     * -------------------------------------- */
    public function filterOrders($query)
    {
        $keyword = request()->get('search')['value'] ?? null;

        $filterColumns  = request()->input('filter_columns', []);
        $filterOperators = request()->input('filter_operators', []);
        $filterValues   = request()->input('filter_values', []);

        if ($keyword) {
            $query->where(function ($sub) use ($keyword) {
                // search order.code via relation
                $sub->whereHas('order', function ($q) use ($keyword) {
                    $q->where('code', 'LIKE', "%{$keyword}%");
                })
                // or search amount on quickbooks_jobs table
                ->orWhere('amount', 'LIKE', "%{$keyword}%");
            });
        }

        if (!empty($filterColumns)) {
            foreach ($filterColumns as $index => $column) {
                $operator = $filterOperators[$index] ?? '=';
                $value    = $filterValues[$index] ?? null;

                if ($column === 'status' && $value !== null) {
                    $query->where('status', $operator, $value);
                }
            }
        }

        return $query;
    }

    /* --------------------------------------
     * RENDER TABLE
     * -------------------------------------- */
    public function renderTable(array $data = [], array $mergeData = []): \Illuminate\Contracts\View\View|\Illuminate\Contracts\View\Factory|\Symfony\Component\HttpFoundation\Response
    {
        return parent::renderTable($data, $mergeData);
    }
}

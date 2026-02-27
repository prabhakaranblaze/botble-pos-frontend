<?php

namespace Botble\PosPro\Http\Controllers;

use Botble\Base\Facades\Assets;
use Botble\Base\Facades\BaseHelper;
use Botble\Base\Http\Controllers\BaseController;
use Botble\Ecommerce\Models\Order;
use Botble\PosPro\Models\PosSession;
use Carbon\Carbon;
use Carbon\CarbonPeriod;
use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends BaseController
{
    protected array $posPaymentMethods = [
        'pos_cash',
        'pos_card',
        'pos_other',
    ];

    public function index(Request $request)
    {
        $this->pageTitle(trans('plugins/pos-pro::pos.reports.title'));

        Assets::addScriptsDirectly([
            'vendor/core/plugins/ecommerce/libraries/daterangepicker/daterangepicker.js',
            'vendor/core/plugins/ecommerce/libraries/apexcharts-bundle/dist/apexcharts.min.js',
            'vendor/core/plugins/pos-pro/js/report.js',
        ])
        ->addStylesDirectly([
            'vendor/core/plugins/ecommerce/libraries/daterangepicker/daterangepicker.css',
            'vendor/core/plugins/ecommerce/css/report.css',
        ]);

        Assets::addScripts(['moment', 'jquery']);

        $startDateInput = $request->get('start_date');
        $endDateInput   = $request->get('end_date');

        if ($startDateInput && $endDateInput) {
            $startDate = Carbon::parse($startDateInput)->startOfDay();
            $endDate   = Carbon::parse($endDateInput)->endOfDay();
        } else {
            $startDate = Carbon::now()->startOfMonth()->startOfDay();
            $endDate   = Carbon::now()->endOfDay();
        }

        // Filter parameters (arrays for multi-select)
        $storeIds   = array_filter((array) $request->get('store_ids', []));
        $userIds    = array_filter((array) $request->get('user_ids', []));
        $sessionIds = array_filter((array) $request->get('session_ids', []));

        try {
            $posOrders = $this->getPosOrders($startDate, $endDate, $storeIds, $userIds, $sessionIds);
            $ordersByPaymentMethod = $this->getOrdersByPaymentMethod($startDate, $endDate, $storeIds, $userIds, $sessionIds);
            $salesData = $this->getDailySalesData($startDate, $endDate, $storeIds, $userIds, $sessionIds);
            $topProducts = $this->getTopSellingProducts($startDate, $endDate, $storeIds, $userIds, $sessionIds);
        } catch (Exception $e) {
            BaseHelper::logError($e);

            $posOrders = [
                'total_sales' => 0,
                'total_orders' => 0,
                'completed_orders' => 0,
                'average_order_value' => 0,
            ];
            $ordersByPaymentMethod = [];
            $salesData = [];
            $topProducts = collect();
        }

        $filtersUrl = route('pos-pro.reports.filters');

        return view('plugins/pos-pro::reports.index', compact(
            'startDate',
            'endDate',
            'posOrders',
            'ordersByPaymentMethod',
            'salesData',
            'topProducts',
            'storeIds',
            'userIds',
            'sessionIds',
            'filtersUrl'
        ));
    }

    /**
     * AJAX endpoint for cascading filter dropdowns.
     * Returns stores, users, and sessions filtered by parent selections.
     */
    public function getFilters(Request $request): JsonResponse
    {
        $startDate = Carbon::parse($request->get('start_date', now()->startOfMonth()))->startOfDay();
        $endDate   = Carbon::parse($request->get('end_date', now()))->endOfDay();
        $storeIds  = array_filter((array) $request->get('store_ids', []));
        $userIds   = array_filter((array) $request->get('user_ids', []));

        // 1. Stores that have POS orders in this date range
        $stores = DB::table('ec_orders')
            ->join('payments', 'ec_orders.id', '=', 'payments.order_id')
            ->join('mp_stores', 'ec_orders.store_id', '=', 'mp_stores.id')
            ->whereIn('payments.payment_channel', $this->posPaymentMethods)
            ->whereBetween('ec_orders.created_at', [$startDate, $endDate])
            ->select('mp_stores.id', 'mp_stores.name')
            ->distinct()
            ->orderBy('mp_stores.name')
            ->get();

        // 2. Cashiers with sessions in date range, filtered by selected stores
        $usersQuery = DB::table('pos_sessions')
            ->join('users', 'pos_sessions.user_id', '=', 'users.id')
            ->where('pos_sessions.opened_at', '>=', $startDate)
            ->where('pos_sessions.opened_at', '<=', $endDate);

        if (! empty($storeIds)) {
            $usersQuery->whereIn('pos_sessions.store_id', $storeIds);
        }

        $users = $usersQuery
            ->select('users.id', DB::raw("CONCAT(users.first_name, ' ', users.last_name) as name"))
            ->distinct()
            ->orderBy('name')
            ->get();

        // 3. Sessions filtered by date range + selected stores + selected cashiers
        $sessionsQuery = PosSession::query()
            ->with(['user:id,first_name,last_name'])
            ->where('opened_at', '>=', $startDate)
            ->where('opened_at', '<=', $endDate)
            ->when(! empty($storeIds), fn ($q) => $q->whereIn('store_id', $storeIds))
            ->when(! empty($userIds), fn ($q) => $q->whereIn('user_id', $userIds))
            ->orderByDesc('opened_at')
            ->limit(200);

        $sessions = $sessionsQuery->get()->map(fn ($s) => [
            'id' => $s->id,
            'label' => $s->session_code
                . ' - ' . trim(($s->user?->first_name ?? '') . ' ' . ($s->user?->last_name ?? ''))
                . ' (' . $s->opened_at->format('d/m H:i')
                . ($s->closed_at ? ' - ' . $s->closed_at->format('H:i') : ' - Open')
                . ')',
        ]);

        return response()->json(compact('stores', 'users', 'sessions'));
    }

    /**
     * Apply common POS filters to an Order Eloquent query.
     */
    protected function applyOrderFilters($query, $startDate, $endDate, array $storeIds = [], array $userIds = [], array $sessionIds = [])
    {
        $query->whereBetween('ec_orders.created_at', [$startDate, $endDate])
            ->whereHas('payment', function ($q): void {
                $q->whereIn('payment_channel', $this->posPaymentMethods);
            });

        if (! empty($storeIds)) {
            $query->whereIn('ec_orders.store_id', $storeIds);
        }

        if (! empty($userIds) || ! empty($sessionIds)) {
            $query->whereIn('ec_orders.id', function ($sub) use ($userIds, $sessionIds) {
                $sub->select('order_id')
                    ->from('pos_session_transactions')
                    ->whereNotNull('order_id');

                if (! empty($userIds)) {
                    $sub->whereIn('user_id', $userIds);
                }

                if (! empty($sessionIds)) {
                    $sub->whereIn('session_id', $sessionIds);
                }
            });
        }

        return $query;
    }

    protected function getPosOrders($startDate, $endDate, array $storeIds = [], array $userIds = [], array $sessionIds = [])
    {
        $query = Order::query();
        $this->applyOrderFilters($query, $startDate, $endDate, $storeIds, $userIds, $sessionIds);

        $orders = $query->with(['payment'])->get();

        $totalSales = $orders->sum('amount');
        $totalOrders = $orders->count();
        $completedOrders = $orders->where('status', 'completed')->count();
        $averageOrderValue = $totalOrders > 0 ? $totalSales / $totalOrders : 0;

        return [
            'total_sales' => $totalSales,
            'total_orders' => $totalOrders,
            'completed_orders' => $completedOrders,
            'average_order_value' => $averageOrderValue,
        ];
    }

    protected function getOrdersByPaymentMethod($startDate, $endDate, array $storeIds = [], array $userIds = [], array $sessionIds = [])
    {
        try {
            $query = Order::query();
            $this->applyOrderFilters($query, $startDate, $endDate, $storeIds, $userIds, $sessionIds);
            $orders = $query->with(['payment'])->get();
        } catch (Exception) {
            return [];
        }

        $ordersByPaymentMethod = [];
        foreach ($this->posPaymentMethods as $method) {
            $ordersByPaymentMethod[$method] = [
                'count' => 0,
                'total' => 0,
            ];
        }

        foreach ($orders as $order) {
            if (! $order->payment) {
                continue;
            }

            $paymentMethod = $order->payment->payment_channel->getValue();

            if (! is_string($paymentMethod) || empty($paymentMethod)) {
                continue;
            }

            $paymentMethodKey = (string) $paymentMethod;

            if (! in_array($paymentMethodKey, $this->posPaymentMethods)) {
                continue;
            }

            $ordersByPaymentMethod[$paymentMethodKey]['count']++;
            $ordersByPaymentMethod[$paymentMethodKey]['total'] += $order->amount;
        }

        foreach ($ordersByPaymentMethod as $key => $data) {
            if ($data['total'] == 0) {
                unset($ordersByPaymentMethod[$key]);
            }
        }

        if (empty($ordersByPaymentMethod)) {
            return [];
        }

        return $ordersByPaymentMethod;
    }

    protected function getDailySalesData($startDate, $endDate, array $storeIds = [], array $userIds = [], array $sessionIds = [])
    {
        $period = CarbonPeriod::create($startDate, $endDate);

        $salesData = [];

        foreach ($period as $date) {
            $formattedDate = $date->format('Y-m-d');
            $salesData[$formattedDate] = [
                'date' => $formattedDate,
                'sales' => 0,
                'orders' => 0,
            ];
        }

        $query = Order::query()
            ->select(
                DB::raw('DATE(ec_orders.created_at) as date'),
                DB::raw('SUM(ec_orders.amount) as total_sales'),
                DB::raw('COUNT(*) as total_orders')
            );

        $this->applyOrderFilters($query, $startDate, $endDate, $storeIds, $userIds, $sessionIds);

        $orders = $query->groupBy('date')->get();

        foreach ($orders as $order) {
            $salesData[$order->date] = [
                'date' => $order->date,
                'sales' => $order->total_sales,
                'orders' => $order->total_orders,
            ];
        }

        return array_values($salesData);
    }

    protected function getTopSellingProducts($startDate, $endDate, array $storeIds = [], array $userIds = [], array $sessionIds = [])
    {
        $query = DB::table('ec_order_product')
            ->join('ec_products', 'ec_order_product.product_id', '=', 'ec_products.id')
            ->join('ec_orders', 'ec_order_product.order_id', '=', 'ec_orders.id')
            ->join('payments', 'ec_orders.id', '=', 'payments.order_id')
            ->whereIn('payments.payment_channel', $this->posPaymentMethods)
            ->whereBetween('ec_orders.created_at', [$startDate, $endDate]);

        if (! empty($storeIds)) {
            $query->whereIn('ec_orders.store_id', $storeIds);
        }

        if (! empty($userIds) || ! empty($sessionIds)) {
            $query->whereIn('ec_orders.id', function ($sub) use ($userIds, $sessionIds) {
                $sub->select('order_id')
                    ->from('pos_session_transactions')
                    ->whereNotNull('order_id');

                if (! empty($userIds)) {
                    $sub->whereIn('user_id', $userIds);
                }

                if (! empty($sessionIds)) {
                    $sub->whereIn('session_id', $sessionIds);
                }
            });
        }

        return $query
            ->select(
                'ec_order_product.product_id',
                'ec_order_product.product_name',
                DB::raw('SUM(ec_order_product.qty) as quantity_sold'),
                DB::raw('SUM(ec_order_product.price * ec_order_product.qty) as revenue')
            )
            ->groupBy('ec_order_product.product_id', 'ec_order_product.product_name')
            ->orderBy('quantity_sold', 'desc')
            ->limit(10)
            ->get();
    }
}

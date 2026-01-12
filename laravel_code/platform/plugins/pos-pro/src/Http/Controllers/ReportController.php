<?php

namespace Botble\PosPro\Http\Controllers;

use Botble\Base\Facades\Assets;
use Botble\Base\Facades\BaseHelper;
use Botble\Base\Http\Controllers\BaseController;
use Botble\Ecommerce\Models\Order;
use Carbon\Carbon;
use Carbon\CarbonPeriod;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends BaseController
{
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
        Assets::addScriptsDirectly('vendor/plugins/pos-pro/js/report-filter.js');

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

        try {
            $posOrders = $this->getPosOrders($startDate, $endDate);
            $ordersByPaymentMethod = $this->getOrdersByPaymentMethod($startDate, $endDate);
            $salesData = $this->getDailySalesData($startDate, $endDate);
            $topProducts = $this->getTopSellingProducts($startDate, $endDate);
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

        return view('plugins/pos-pro::reports.index', compact(
            'startDate',
            'endDate',
            'posOrders',
            'ordersByPaymentMethod',
            'salesData',
            'topProducts'
        ));
    }

    protected function getPosOrders($startDate, $endDate)
    {
        $posPaymentMethods = [
            'pos_cash',
            'pos_card',
            'pos_other',
        ];

        $orders = Order::query()
            ->whereBetween('created_at', [$startDate, $endDate])
            ->whereHas('payment', function ($query) use ($posPaymentMethods): void {
                $query->whereIn('payment_channel', $posPaymentMethods);
            })
            ->with(['payment'])
            ->get();

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

    protected function getOrdersByPaymentMethod($startDate, $endDate)
    {
        $posPaymentMethods = [
            'pos_cash',
            'pos_card',
            'pos_other',
        ];

        try {
            $orders = Order::query()
                ->whereBetween('created_at', [$startDate, $endDate])
                ->whereHas('payment', function ($query) use ($posPaymentMethods): void {
                    $query->whereIn('payment_channel', $posPaymentMethods);
                })
                ->with(['payment'])
                ->get();
        } catch (Exception) {
            return [];
        }

        $ordersByPaymentMethod = [];
        foreach ($posPaymentMethods as $method) {
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

            if (! in_array($paymentMethodKey, $posPaymentMethods)) {
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

    protected function getDailySalesData($startDate, $endDate)
    {
        $posPaymentMethods = [
            'pos_cash',
            'pos_card',
            'pos_other',
        ];

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

        $orders = Order::query()
            ->whereBetween('created_at', [$startDate, $endDate])
            ->whereHas('payment', function ($query) use ($posPaymentMethods): void {
                $query->whereIn('payment_channel', $posPaymentMethods);
            })
            ->select(
                DB::raw('DATE(created_at) as date'),
                DB::raw('SUM(amount) as total_sales'),
                DB::raw('COUNT(*) as total_orders')
            )
            ->groupBy('date')
            ->get();

        foreach ($orders as $order) {
            $salesData[$order->date] = [
                'date' => $order->date,
                'sales' => $order->total_sales,
                'orders' => $order->total_orders,
            ];
        }

        return array_values($salesData);
    }

    protected function getTopSellingProducts($startDate, $endDate)
    {
        $posPaymentMethods = [
            'pos_cash',
            'pos_card',
            'pos_other',
        ];

        return DB::table('ec_order_product')
            ->join('ec_products', 'ec_order_product.product_id', '=', 'ec_products.id')
            ->join('ec_orders', 'ec_order_product.order_id', '=', 'ec_orders.id')
            ->join('payments', 'ec_orders.id', '=', 'payments.order_id')
            ->whereIn('payments.payment_channel', $posPaymentMethods)
            ->whereBetween('ec_orders.created_at', [$startDate, $endDate])
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

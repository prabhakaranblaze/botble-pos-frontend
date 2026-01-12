@extends(BaseHelper::getAdminMasterLayoutTemplate())

@push('header-action')
    <x-core::button
        type="button"
        color="primary"
        :outlined="true"
        class="date-range-picker"
        data-format-value="{{ trans('plugins/pos-pro::pos.reports.date_range_format_value', ['from' => '__from__', 'to' => '__to__']) }}"
        data-format="{{ Str::upper(config('core.base.general.date_format.js.date')) }}"
        data-href="{{ route('pos-pro.reports.index') }}"
        data-start-date="{{ request('start_date', $startDate->format('Y-m-d')) }}"
        data-end-date="{{ request('end_date', $endDate->format('Y-m-d')) }}"
        icon="ti ti-calendar"
    >
        <span>
            {{ trans('plugins/pos-pro::pos.reports.date_range_format_value', [
                'from' => BaseHelper::formatDate($startDate),
                'to' => BaseHelper::formatDate($endDate),
            ]) }}
        </span>
    </x-core::button>
@endpush

@section('content')
    <div id="report-stats-content">
        <div class="row">
            <div class="col-md-3">
                <x-core::card class="analytic-card">
                    <x-core::card.body class="p-3">
                        <div class="row align-items-center">
                            <div class="col-auto">
                                <x-core::icon
                                    class="text-white bg-pink rounded p-1"
                                    name="ti ti-currency-dollar"
                                    size="md"
                                />
                            </div>
                            <div class="col mt-0">
                                <p class="text-secondary mb-0 fs-4">
                                    {{ trans('plugins/pos-pro::pos.reports.total_sales') }}
                                </p>
                                <h3 class="mb-n1 fs-1">
                                    {{ format_price($posOrders['total_sales']) }}
                                </h3>
                            </div>
                        </div>
                    </x-core::card.body>
                </x-core::card>
            </div>
            <div class="col-md-3">
                <x-core::card class="analytic-card">
                    <x-core::card.body class="p-3">
                        <div class="row align-items-center">
                            <div class="col-auto">
                                <x-core::icon
                                    class="text-white bg-yellow rounded p-1"
                                    name="ti ti-shopping-cart"
                                    size="md"
                                />
                            </div>
                            <div class="col mt-0">
                                <p class="text-secondary mb-0 fs-4">
                                    {{ trans('plugins/pos-pro::pos.reports.total_orders') }}
                                </p>
                                <h3 class="mb-n1 fs-1">
                                    {{ $posOrders['total_orders'] }}
                                </h3>
                            </div>
                        </div>
                    </x-core::card.body>
                </x-core::card>
            </div>
            <div class="col-md-3">
                <x-core::card class="analytic-card">
                    <x-core::card.body class="p-3">
                        <div class="row align-items-center">
                            <div class="col-auto">
                                <x-core::icon
                                    class="text-white bg-green rounded p-1"
                                    name="ti ti-check"
                                    size="md"
                                />
                            </div>
                            <div class="col mt-0">
                                <p class="text-secondary mb-0 fs-4">
                                    {{ trans('plugins/pos-pro::pos.reports.completed_orders') }}
                                </p>
                                <h3 class="mb-n1 fs-1">
                                    {{ $posOrders['completed_orders'] }}
                                </h3>
                            </div>
                        </div>
                    </x-core::card.body>
                </x-core::card>
            </div>
            <div class="col-md-3">
                <x-core::card class="analytic-card">
                    <x-core::card.body class="p-3">
                        <div class="row align-items-center">
                            <div class="col-auto">
                                <x-core::icon
                                    class="text-white bg-blue rounded p-1"
                                    name="ti ti-chart-bar"
                                    size="md"
                                />
                            </div>
                            <div class="col mt-0">
                                <p class="text-secondary mb-0 fs-4">
                                    {{ trans('plugins/pos-pro::pos.reports.average_order') }}
                                </p>
                                <h3 class="mb-n1 fs-1">
                                    {{ format_price($posOrders['average_order_value']) }}
                                </h3>
                            </div>
                        </div>
                    </x-core::card.body>
                </x-core::card>
            </div>
        </div>

    <div class="row mt-3">
        <div class="col-md-8">
            <x-core::card class="report-chart-content" id="report-chart">
                <x-core::card.header>
                    <h4 class="card-title">{{ trans('plugins/pos-pro::pos.reports.sales_over_time') }}</h4>
                </x-core::card.header>
                <x-core::card.body>
                    <div id="sales-chart" height="300"></div>
                </x-core::card.body>
            </x-core::card>
        </div>
        <div class="col-md-4">
            <x-core::card class="report-chart-content">
                <x-core::card.header>
                    <h4 class="card-title">{{ trans('plugins/pos-pro::pos.reports.sales_by_payment_method') }}</h4>
                </x-core::card.header>
                <x-core::card.body>
                    <div id="payment-methods-chart" height="300"></div>
                </x-core::card.body>
            </x-core::card>
        </div>
    </div>

    <div class="row mt-3">
        <div class="col-md-12">
            <x-core::card>
                <x-core::card.header>
                    <h4 class="card-title">{{ trans('plugins/pos-pro::pos.reports.top_selling_products') }}</h4>
                </x-core::card.header>
                <x-core::card.body>
                    <div class="table-responsive">
                        <table class="table table-striped table-hover">
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>{{ trans('plugins/pos-pro::pos.reports.product_name') }}</th>
                                    <th>{{ trans('plugins/pos-pro::pos.reports.quantity_sold') }}</th>
                                    <th>{{ trans('plugins/pos-pro::pos.reports.revenue') }}</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($topProducts as $index => $product)
                                    <tr>
                                        <td>{{ $index + 1 }}</td>
                                        <td>{{ $product->product_name }}</td>
                                        <td>{{ $product->quantity_sold }}</td>
                                        <td>{{ format_price($product->revenue) }}</td>
                                    </tr>
                                @endforeach

                                @if(count($topProducts) === 0)
                                    <tr>
                                        <td colspan="4" class="text-center">{{ trans('plugins/pos-pro::pos.reports.no_data') }}</td>
                                    </tr>
                                @endif
                            </tbody>
                        </table>
                    </div>
                </x-core::card.body>
            </x-core::card>
        </div>
    </div>
    </div>
@stop

@push('footer')


    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Sales Chart
            const salesData = @json($salesData ?? []);

            // Check if we have sales data
            if (salesData && salesData.length > 0) {
                const dates = salesData.map(item => item.date);
                const sales = salesData.map(item => item.sales);

                // Define a custom number formatter function
                const formatNumber = function(number) {
                    return new Intl.NumberFormat('{{ app()->getLocale() }}', {
                        style: 'currency',
                        currency: '{{ get_application_currency()->title }}',
                        minimumFractionDigits: 0,
                        maximumFractionDigits: 0
                    }).format(number);
                };

                new ApexCharts(document.querySelector('#sales-chart'), {
                    series: [{
                        name: '{{ trans('plugins/pos-pro::pos.reports.sales') }}',
                        data: sales
                    }],
                    chart: {
                        height: 350,
                        type: 'area',
                        toolbar: {
                            show: false
                        }
                    },
                    dataLabels: {
                        enabled: false
                    },
                    stroke: {
                        curve: 'smooth'
                    },
                    colors: ['#0C55AA'],
                    xaxis: {
                        type: 'datetime',
                        categories: dates
                    },
                    tooltip: {
                        x: {
                            format: 'dd/MM/yy'
                        },
                        y: {
                            formatter: function(val) {
                                return formatNumber(val);
                            }
                        }
                    },
                    noData: {
                        text: '{{ trans('plugins/pos-pro::pos.reports.no_data') }}',
                    }
                }).render();
            } else {
                // Display a message when no data is available
                const noDataMessage = document.createElement('div');
                noDataMessage.className = 'text-center p-4';
                noDataMessage.innerHTML = '<p>{{ trans('plugins/pos-pro::pos.reports.no_data') }}</p>';
                document.getElementById('sales-chart').parentNode.appendChild(noDataMessage);
            }

            // Payment Methods Chart
            const paymentMethodsData = @json($ordersByPaymentMethod ?? []);

            // Check if we have payment methods data
            if (paymentMethodsData && Object.keys(paymentMethodsData).length > 0) {
                // Filter out zero values and prepare data for the chart
                const filteredData = Object.entries(paymentMethodsData)
                    .filter(([key, item]) => item && item.total && item.total > 0)
                    .reduce((acc, [key, item]) => {
                        acc.keys.push(key);
                        acc.values.push(item.total);
                        return acc;
                    }, { keys: [], values: [] });

                const paymentLabels = filteredData.keys.map(key => {
                    if (key === 'pos_cash') return '{{ trans('plugins/pos-pro::pos.pos_cash') }}';
                    if (key === 'pos_card') return '{{ trans('plugins/pos-pro::pos.pos_card') }}';
                    if (key === 'pos_other') return '{{ trans('plugins/pos-pro::pos.pos_other') }}';
                    return key;
                });

                const paymentValues = filteredData.values;

                // Define a custom number formatter function
                const formatNumber = function(number) {
                    return new Intl.NumberFormat('{{ app()->getLocale() }}', {
                        style: 'currency',
                        currency: '{{ get_application_currency()->title }}',
                        minimumFractionDigits: 0,
                        maximumFractionDigits: 0
                    }).format(number);
                };

                new ApexCharts(document.querySelector('#payment-methods-chart'), {
                    series: paymentValues,
                    labels: paymentLabels,
                    colors: ['#fcb800', '#80bc00', '#36a2eb'],
                    chart: {
                        height: 250,
                        type: 'donut',
                        toolbar: {
                            show: false
                        }
                    },
                    plotOptions: {
                        pie: {
                            donut: {
                                size: '71%',
                                labels: {
                                    show: true,
                                    name: {
                                        show: true
                                    },
                                    value: {
                                        show: true,
                                        formatter: function(val) {
                                            return formatNumber(val);
                                        }
                                    },
                                    total: {
                                        show: true,
                                        label: '{{ trans('plugins/pos-pro::pos.reports.total') }}',
                                        formatter: function(w) {
                                            return formatNumber(w.globals.seriesTotals.reduce((a, b) => a + b, 0));
                                        }
                                    }
                                }
                            },
                            expandOnClick: true
                        }
                    },
                    states: {
                        hover: {
                            filter: {
                                type: 'darken',
                                value: .9
                            }
                        }
                    },
                    dataLabels: {
                        enabled: true,
                        formatter: function(val) {
                            return val.toFixed(1) + '%';
                        }
                    },
                    legend: {
                        show: true,
                        position: 'bottom'
                    },
                    tooltip: {
                        enabled: true,
                        y: {
                            formatter: function(val) {
                                return formatNumber(val);
                            }
                        }
                    }
                }).render();
            } else {
                // Display a message when no data is available
                const noDataMessage = document.createElement('div');
                noDataMessage.className = 'text-center p-4';
                noDataMessage.innerHTML = '<p>{{ trans('plugins/pos-pro::pos.reports.no_data') }}</p>';
                document.getElementById('payment-methods-chart').parentNode.appendChild(noDataMessage);
            }

            // Date Range Picker is initialized in report.js
        }); 
    </script>
@endpush

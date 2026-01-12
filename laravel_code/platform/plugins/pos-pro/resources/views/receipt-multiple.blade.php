@extends('plugins/pos-pro::layouts.receipt')
@php
    use Illuminate\Support\Arr;
    use Botble\Media\Facades\RvMedia;
    $routePrefix = $routePrefix ?? 'pos-pro';
    $isVendor = $routePrefix === 'marketplace.vendor.pos';
    $orderIds = $orders->pluck('id')->join(',');
@endphp

@push('header')
    <link rel="stylesheet" href="{{ asset('vendor/core/plugins/pos-pro/css/receipt.css') }}?v=1.2.3">
    <script>
        window.BotbleVariables = window.BotbleVariables || {};
        window.BotbleVariables.languages = window.BotbleVariables.languages || {
            notices_msg: {
                success: "{{ trans('core/base::notices.success') }}",
                error: "{{ trans('core/base::notices.error') }}",
                info: "{{ trans('core/base::notices.info') }}",
                warning: "{{ trans('plugins/pos-pro::pos.warning') }}"
            }
        };
    </script>
    <style>
        .receipt-success-banner {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            border-radius: 16px;
            padding: 30px;
            color: white;
            text-align: center;
            box-shadow: 0 10px 25px -5px rgba(16, 185, 129, 0.4);
            margin-bottom: 24px;
        }
        .receipt-success-banner .success-icon {
            width: 70px;
            height: 70px;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 16px;
            font-size: 32px;
        }
        .receipt-success-banner h2 {
            color: white;
            font-weight: 800;
            margin-bottom: 8px;
            font-size: 24px;
        }
        .receipt-success-banner .order-count {
            font-size: 18px;
            opacity: 0.95;
            font-weight: 600;
            margin-bottom: 8px;
        }
        .receipt-success-banner .order-codes {
            font-size: 14px;
            opacity: 0.85;
            margin-bottom: 20px;
        }
        .receipt-success-banner .btn-group-actions {
            display: flex;
            gap: 12px;
            justify-content: center;
            flex-wrap: wrap;
        }
        .receipt-success-banner .btn-action {
            padding: 12px 24px;
            font-weight: 700;
            font-size: 14px;
            border-radius: 8px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.2s;
        }
        .receipt-success-banner .btn-action:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 12px rgba(0,0,0,0.15);
        }
        .receipt-success-banner .btn-thermal {
            background: white;
            color: #059669;
        }
        .receipt-success-banner .btn-new-order {
            background: rgba(255, 255, 255, 0.2);
            color: white;
            border: 2px solid rgba(255, 255, 255, 0.4);
        }
        .receipt-success-banner .btn-new-order:hover {
            background: rgba(255, 255, 255, 0.3);
            color: white;
        }

        .receipt-card {
            background: white;
            border: 1px solid #e5e7eb;
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
            overflow: hidden;
            margin-bottom: 20px;
        }
        .receipt-card-header {
            background: #f9fafb;
            padding: 16px 20px;
            border-bottom: 1px solid #e5e7eb;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .receipt-card-header h3 {
            margin: 0;
            font-size: 16px;
            font-weight: 700;
            color: #1f2937;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .receipt-card-header .header-icon {
            width: 32px;
            height: 32px;
            background: #e0f2fe;
            color: #0284c7;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 14px;
        }
        .receipt-card-header .vendor-badge {
            background: #dbeafe;
            color: #1d4ed8;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }
        .receipt-card-body {
            padding: 20px;
        }

        .store-header {
            text-align: center;
            padding-bottom: 20px;
            border-bottom: 2px dashed #e5e7eb;
            margin-bottom: 20px;
        }
        .store-header .store-logo {
            max-height: 60px;
            margin-bottom: 12px;
        }
        .store-header h2 {
            font-size: 20px;
            font-weight: 800;
            color: #1f2937;
            margin-bottom: 8px;
        }
        .store-header p {
            color: #6b7280;
            margin-bottom: 4px;
            font-size: 14px;
        }

        .receipt-meta {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            padding: 16px;
            background: #f9fafb;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .receipt-meta-item {
            display: flex;
            flex-direction: column;
            gap: 4px;
        }
        .receipt-meta-item label {
            font-size: 12px;
            font-weight: 600;
            color: #6b7280;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .receipt-meta-item span {
            font-size: 14px;
            font-weight: 600;
            color: #1f2937;
        }

        .receipt-table {
            width: 100%;
            border-collapse: collapse;
        }
        .receipt-table thead th {
            background: #f9fafb;
            padding: 12px 16px;
            font-size: 12px;
            font-weight: 700;
            color: #6b7280;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border-bottom: 2px solid #e5e7eb;
        }
        .receipt-table tbody td {
            padding: 14px 16px;
            border-bottom: 1px solid #f3f4f6;
            font-size: 14px;
            color: #374151;
        }
        .receipt-table tbody tr:last-child td {
            border-bottom: none;
        }
        .receipt-table .product-name {
            font-weight: 600;
            color: #1f2937;
        }
        .receipt-table .product-meta {
            font-size: 12px;
            color: #6b7280;
            margin-top: 4px;
        }

        .receipt-totals {
            background: #f9fafb;
            border-radius: 8px;
            padding: 16px;
            margin-top: 20px;
        }
        .receipt-totals-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            font-size: 14px;
        }
        .receipt-totals-row.total-row {
            border-top: 2px solid #e5e7eb;
            margin-top: 8px;
            padding-top: 16px;
            font-size: 18px;
            font-weight: 800;
            color: #1f2937;
        }
        .receipt-totals-row .label {
            color: #6b7280;
        }
        .receipt-totals-row .value {
            font-weight: 600;
            color: #374151;
        }
        .receipt-totals-row .value.discount {
            color: #dc2626;
        }

        .grand-total-card {
            background: linear-gradient(135deg, #1e40af 0%, #3b82f6 100%);
            border-radius: 12px;
            padding: 24px;
            color: white;
            text-align: center;
            margin-top: 20px;
        }
        .grand-total-card h4 {
            color: rgba(255,255,255,0.8);
            font-size: 14px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 8px;
        }
        .grand-total-card .amount {
            font-size: 32px;
            font-weight: 800;
            color: white;
        }
        .grand-total-card .order-count-badge {
            display: inline-block;
            background: rgba(255,255,255,0.2);
            padding: 6px 16px;
            border-radius: 20px;
            font-size: 13px;
            margin-top: 12px;
        }

        .info-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 16px;
            margin-top: 20px;
        }
        .info-card {
            background: white;
            border: 1px solid #e5e7eb;
            border-radius: 10px;
            overflow: hidden;
        }
        .info-card-header {
            background: #f9fafb;
            padding: 12px 16px;
            border-bottom: 1px solid #e5e7eb;
            font-size: 14px;
            font-weight: 700;
            color: #374151;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .info-card-body {
            padding: 16px;
        }
        .info-card-body p {
            margin: 0 0 8px 0;
            font-size: 13px;
            color: #6b7280;
            display: flex;
            justify-content: space-between;
        }
        .info-card-body p:last-child {
            margin-bottom: 0;
        }
        .info-card-body p strong {
            color: #374151;
        }

        .receipt-footer-message {
            text-align: center;
            padding: 24px;
            background: #fefce8;
            border-radius: 10px;
            margin-top: 20px;
        }
        .receipt-footer-message p {
            font-size: 16px;
            font-weight: 600;
            color: #854d0e;
            margin: 0;
        }

        @media (max-width: 768px) {
            .receipt-meta {
                grid-template-columns: 1fr;
            }
            .receipt-success-banner .btn-group-actions {
                flex-direction: column;
            }
            .receipt-success-banner .btn-action {
                width: 100%;
                justify-content: center;
            }
        }
    </style>
@endpush

@section('content')
    <div class="container" style="max-width: 900px; margin: 0 auto; padding: 20px;">
        <!-- Success Banner -->
        <div class="receipt-success-banner">
            <div class="success-icon">
                <x-core::icon name="ti ti-circle-check" />
            </div>
            <h2>{{ trans('plugins/pos-pro::pos.orders_completed') }}</h2>
            <div class="order-count">{{ trans('plugins/pos-pro::pos.total_orders') }}: {{ $orders->count() }}</div>
            <div class="order-codes">
                @foreach($orders as $order)
                    <span class="badge bg-white text-success me-1">{{ $order->code }}</span>
                @endforeach
            </div>
            <div class="btn-group-actions">
                <a href="{{ route($routePrefix . '.receipt.print.multiple', $orderIds) }}" target="_blank" class="btn-action btn-thermal">
                    <x-core::icon name="ti ti-receipt" /> {{ trans('plugins/pos-pro::receipt.print_thermal') }}
                </a>
                <a href="{{ route($routePrefix . '.index') }}" class="btn-action btn-new-order">
                    <x-core::icon name="ti ti-plus" /> {{ trans('plugins/pos-pro::pos.new_order') }}
                </a>
            </div>
        </div>

        <!-- Store Header Card -->
        <div class="receipt-card">
            <div class="receipt-card-body">
                <div class="store-header">
                    @if(setting('admin_logo'))
                        <img src="{{ RvMedia::getImageUrl(setting('admin_logo')) }}" alt="{{ get_ecommerce_setting('store_name', config('app.name')) }}" class="store-logo">
                    @endif
                    <h2>{{ get_ecommerce_setting('store_name', config('app.name')) }}</h2>
                    @if(get_ecommerce_setting('store_address'))
                        <p>{{ get_ecommerce_setting('store_address') }}</p>
                    @endif
                    @if(get_ecommerce_setting('store_phone'))
                        <p>{{ trans('plugins/pos-pro::pos.phone') }}: {{ get_ecommerce_setting('store_phone') }}</p>
                    @endif
                </div>

                <!-- Customer Info -->
                @php
                    $firstOrder = $orders->first();
                @endphp
                <div class="receipt-meta">
                    <div class="receipt-meta-item">
                        <label>{{ trans('plugins/pos-pro::pos.date') }}</label>
                        <span>{{ BaseHelper::formatDate($firstOrder->created_at, 'd/m/Y H:i') }}</span>
                    </div>
                    <div class="receipt-meta-item">
                        <label>{{ trans('plugins/pos-pro::pos.cashier') }}</label>
                        <span>{{ auth()->user()->name ?? 'N/A' }}</span>
                    </div>
                    <div class="receipt-meta-item">
                        <label>{{ trans('plugins/pos-pro::pos.customer') }}</label>
                        <span>
                            @if($firstOrder->user)
                                {{ $firstOrder->user->name }}
                            @elseif($firstOrder->address && $firstOrder->address->name != 'Guest')
                                {{ $firstOrder->address->name }}
                            @else
                                {{ trans('plugins/pos-pro::pos.guest') }}
                            @endif
                        </span>
                    </div>
                    @if($firstOrder->user && $firstOrder->user->phone || $firstOrder->address && $firstOrder->address->phone && $firstOrder->address->phone != 'N/A')
                    <div class="receipt-meta-item">
                        <label>{{ trans('plugins/pos-pro::pos.phone') }}</label>
                        <span>{{ $firstOrder->user->phone ?? $firstOrder->address->phone }}</span>
                    </div>
                    @endif
                </div>
            </div>
        </div>

        <!-- Orders by Vendor -->
        @foreach($orders as $order)
            <div class="receipt-card">
                <div class="receipt-card-header">
                    <h3>
                        <span class="header-icon"><x-core::icon name="ti ti-file-invoice" /></span>
                        {{ trans('plugins/pos-pro::pos.order_number') }}: {{ $order->code }}
                    </h3>
                    @if(is_plugin_active('marketplace') && $order->store_id && $order->store)
                        <span class="vendor-badge">
                            <x-core::icon name="ti ti-building-store" /> {{ $order->store->name }}
                        </span>
                    @endif
                </div>
                <div class="receipt-card-body">
                    @if($order->invoice)
                        <div class="mb-3">
                            <small class="text-muted">{{ trans('plugins/pos-pro::receipt.invoice_code') }}: <strong>{{ $order->invoice->code }}</strong></small>
                        </div>
                    @endif

                    <!-- Products Table -->
                    <div class="table-responsive">
                        <table class="receipt-table">
                            <thead>
                                <tr>
                                    <th>{{ trans('plugins/pos-pro::pos.product') }}</th>
                                    <th class="text-center" style="width: 80px;">{{ trans('plugins/pos-pro::pos.quantity') }}</th>
                                    <th class="text-end" style="width: 120px;">{{ trans('plugins/pos-pro::pos.price') }}</th>
                                    <th class="text-end" style="width: 120px;">{{ trans('plugins/pos-pro::pos.total') }}</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($order->products as $product)
                                    <tr>
                                        <td>
                                            <div class="product-name">{{ $product->product_name }}</div>
                                            @if ($sku = Arr::get($product->options, 'sku') ?: $product->product->sku ?? '')
                                                <div class="product-meta">SKU: {{ $sku }}</div>
                                            @endif
                                            @if ($attributes = Arr::get($product->options, 'attributes'))
                                                <div class="product-meta">{{ $attributes }}</div>
                                            @endif
                                        </td>
                                        <td class="text-center">{{ $product->qty }}</td>
                                        <td class="text-end">{{ format_price($product->price) }}</td>
                                        <td class="text-end">{{ format_price($product->price * $product->qty) }}</td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>

                    <!-- Order Totals -->
                    <div class="receipt-totals">
                        <div class="receipt-totals-row">
                            <span class="label">{{ trans('plugins/pos-pro::pos.subtotal') }}</span>
                            <span class="value">{{ format_price($order->sub_total) }}</span>
                        </div>

                        @if($order->discount_amount > 0)
                        <div class="receipt-totals-row">
                            <span class="label">
                                {{ trans('plugins/pos-pro::pos.discount') }}
                                @if($order->discount_description)
                                    <small>({{ $order->discount_description }})</small>
                                @elseif($order->coupon_code)
                                    <small>({{ $order->coupon_code }})</small>
                                @endif
                            </span>
                            <span class="value discount">-{{ format_price($order->discount_amount) }}</span>
                        </div>
                        @endif

                        @if($order->tax_amount > 0)
                        <div class="receipt-totals-row">
                            <span class="label">{{ trans('plugins/pos-pro::pos.tax') }}</span>
                            <span class="value">{{ format_price($order->tax_amount) }}</span>
                        </div>
                        @endif

                        @if($order->shipping_amount > 0)
                        <div class="receipt-totals-row">
                            <span class="label">{{ trans('plugins/pos-pro::pos.shipping') }}</span>
                            <span class="value">{{ format_price($order->shipping_amount) }}</span>
                        </div>
                        @endif

                        <div class="receipt-totals-row total-row">
                            <span class="label">{{ trans('plugins/pos-pro::pos.total') }}</span>
                            <span class="value">{{ format_price($order->amount) }}</span>
                        </div>
                    </div>
                </div>
            </div>
        @endforeach

        <!-- Grand Total Card -->
        <div class="grand-total-card">
            <h4>{{ trans('plugins/pos-pro::pos.grand_total') }}</h4>
            <div class="amount">{{ format_price($orders->sum('amount')) }}</div>
            <div class="order-count-badge">
                <x-core::icon name="ti ti-shopping-cart" /> {{ $orders->count() }} {{ trans('plugins/pos-pro::pos.orders') }}
            </div>
        </div>

        <!-- Payment & Footer Info -->
        <div class="info-cards">
            <div class="info-card">
                <div class="info-card-header">
                    <x-core::icon name="ti ti-credit-card" />
                    {{ trans('plugins/pos-pro::pos.payment_details') }}
                </div>
                <div class="info-card-body">
                    @if($firstOrder->payment)
                    <p>
                        <span>{{ trans('plugins/pos-pro::pos.payment_method') }}</span>
                        <strong>{!! BaseHelper::clean($firstOrder->payment->payment_channel->label()) !!}</strong>
                    </p>
                    <p>
                        <span>{{ trans('plugins/pos-pro::pos.payment_status') }}</span>
                        <strong>{!! BaseHelper::clean($firstOrder->payment->status->toHtml()) !!}</strong>
                    </p>
                    @endif
                    @if($firstOrder->description)
                    <p>
                        <span>{{ trans('plugins/pos-pro::pos.notes') }}</span>
                        <strong class="text-warning">{{ $firstOrder->description }}</strong>
                    </p>
                    @endif
                </div>
            </div>

            @if($firstOrder->shippingAddress && $firstOrder->shippingAddress->address)
            <div class="info-card">
                <div class="info-card-header">
                    <x-core::icon name="ti ti-map-pin" />
                    {{ trans('plugins/pos-pro::pos.shipping_address') }}
                </div>
                <div class="info-card-body">
                    <p>
                        <span>{{ trans('plugins/pos-pro::receipt.address_name') }}</span>
                        <strong>{{ $firstOrder->shippingAddress->name }}</strong>
                    </p>
                    <p>
                        <span>{{ trans('plugins/pos-pro::receipt.address') }}</span>
                        <strong>{{ $firstOrder->shippingAddress->address }}</strong>
                    </p>
                    @if($firstOrder->shippingAddress->city)
                    <p>
                        <span>{{ trans('plugins/pos-pro::receipt.address_city') }}</span>
                        <strong>{{ $firstOrder->shippingAddress->city }}, {{ $firstOrder->shippingAddress->state }}</strong>
                    </p>
                    @endif
                </div>
            </div>
            @endif
        </div>

        <!-- Footer Message -->
        <div class="receipt-footer-message">
            <p>{{ setting('pos_pro_receipt_footer_text', trans('plugins/pos-pro::pos.thank_you_message')) }}</p>
        </div>
    </div>
@stop

@push('footer')
    <script src="{{ asset('vendor/core/plugins/pos-pro/js/receipt.js') }}?v=1.2.3"></script>
@endpush

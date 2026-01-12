@php
    use Illuminate\Support\Arr;
    use Botble\Media\Facades\RvMedia;
    use Botble\PosPro\Enums\ReceiptWidthEnum;

    // Receipt Settings
    $receiptWidth = setting('pos_pro_receipt_width', ReceiptWidthEnum::THERMAL_80MM);
    $autoPrintThermal = setting('pos_pro_auto_print_thermal', true);
    $showLogo = setting('pos_pro_receipt_show_logo', true);
    $showStoreInfo = setting('pos_pro_receipt_show_store_info', true);
    $showVat = setting('pos_pro_receipt_show_vat', true);
    $showCashier = setting('pos_pro_receipt_show_cashier', true);
    $showCustomer = setting('pos_pro_receipt_show_customer', true);
    $footerText = setting('pos_pro_receipt_footer_text', trans('plugins/pos-pro::pos.thank_you_message'));

    // Calculate CSS width based on setting
    $cssWidth = ReceiptWidthEnum::getCssWidth($receiptWidth);
    $fontSize = ReceiptWidthEnum::getFontSize($receiptWidth);

    // Store info
    $storeName = get_ecommerce_setting('store_name', config('app.name'));
    $storeAddress = get_ecommerce_setting('store_address');
    $storePhone = get_ecommerce_setting('store_phone');
    $storeLogo = setting('admin_logo');

    // Cashier info
    $cashier = auth()->user();
    $cashierName = $cashier ? $cashier->name : 'N/A';

    // First order for customer info
    $firstOrder = $orders->first();

    // Customer info
    $customerName = trans('plugins/pos-pro::pos.guest');
    if ($firstOrder->user) {
        $customerName = $firstOrder->user->name;
    } elseif ($firstOrder->address && $firstOrder->address->name && $firstOrder->address->name !== 'Guest') {
        $customerName = $firstOrder->address->name;
    }

    // Payment info from first order
    $paymentMethod = $firstOrder->payment ? $firstOrder->payment->payment_channel->label() : trans('plugins/pos-pro::pos.cash');

    // Grand total
    $grandTotal = $orders->sum('amount');
    $grandSubTotal = $orders->sum('sub_total');
    $grandDiscount = $orders->sum('discount_amount');
    $grandTax = $orders->sum('tax_amount');
    $grandShipping = $orders->sum('shipping_amount');

    // Order codes
    $orderCodes = $orders->pluck('code')->join(', ');
@endphp
<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ trans('plugins/pos-pro::receipt.print_receipt') }} - {{ $orders->count() }} {{ trans('plugins/pos-pro::pos.orders') }}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Courier New', 'Lucida Console', Monaco, monospace;
            font-size: {{ $fontSize }}px;
            width: {{ $cssWidth }};
            margin: 0 auto;
            padding: 10px 5px;
            color: #000;
            background: #fff;
            line-height: 1.4;
        }

        .header {
            text-align: center;
            margin-bottom: 10px;
        }

        .store-logo {
            max-height: 60px;
            max-width: 100%;
            margin-bottom: 8px;
        }

        .store-name {
            font-size: {{ $fontSize + 5 }}px;
            font-weight: bold;
            text-transform: uppercase;
            margin-bottom: 5px;
            letter-spacing: 1px;
        }

        .store-info {
            font-size: {{ $fontSize - 1 }}px;
            margin-bottom: 3px;
        }

        .datetime {
            margin-top: 8px;
            font-size: {{ $fontSize - 1 }}px;
        }

        .line {
            border-bottom: 1px dashed #000;
            margin: 8px 0;
        }

        .line-double {
            border-bottom: 2px dashed #000;
            margin: 8px 0;
        }

        .meta {
            margin-bottom: 8px;
            font-size: {{ $fontSize - 1 }}px;
        }

        .meta-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 3px;
        }

        .meta-label {
            color: #333;
        }

        .meta-value {
            font-weight: bold;
        }

        .vendor-header {
            background: #f0f0f0;
            padding: 5px;
            margin: 8px 0;
            text-align: center;
            font-weight: bold;
            font-size: {{ $fontSize }}px;
        }

        .order-header {
            font-weight: bold;
            font-size: {{ $fontSize - 1 }}px;
            margin: 8px 0 5px;
            padding: 3px 0;
            border-bottom: 1px solid #ccc;
        }

        .items {
            width: 100%;
            border-collapse: collapse;
            margin: 8px 0;
            font-size: {{ $fontSize - 1 }}px;
        }

        .items th {
            text-align: left;
            border-bottom: 1px solid #000;
            padding: 4px 0;
            font-weight: bold;
        }

        .items th.right {
            text-align: right;
        }

        .items td {
            padding: 5px 0;
            vertical-align: top;
        }

        .items td.center {
            text-align: center;
        }

        .items td.right {
            text-align: right;
            white-space: nowrap;
        }

        .item-name {
            font-weight: 500;
            word-break: break-word;
        }

        .item-sku {
            font-size: {{ $fontSize - 3 }}px;
            color: #666;
        }

        .item-attrs {
            font-size: {{ $fontSize - 3 }}px;
            color: #666;
            font-style: italic;
        }

        .order-subtotal {
            display: flex;
            justify-content: space-between;
            padding: 5px 0;
            font-size: {{ $fontSize - 1 }}px;
            font-weight: bold;
            border-top: 1px dotted #666;
            margin-top: 5px;
        }

        .totals {
            margin-top: 8px;
        }

        .totals-row {
            display: flex;
            justify-content: space-between;
            padding: 3px 0;
            font-size: {{ $fontSize - 1 }}px;
        }

        .totals-row.big {
            font-size: {{ $fontSize + 3 }}px;
            font-weight: bold;
            padding: 6px 0;
        }

        .totals-row .label {
            flex: 1;
        }

        .totals-row .value {
            text-align: right;
            font-weight: 500;
        }

        .discount {
            color: #c00;
        }

        .grand-total-section {
            background: #f0f0f0;
            padding: 8px;
            margin: 10px 0;
        }

        .grand-total-section .totals-row.big {
            font-size: {{ $fontSize + 4 }}px;
        }

        .footer {
            text-align: center;
            margin-top: 15px;
            padding-top: 10px;
        }

        .thank-you {
            font-size: {{ $fontSize + 1 }}px;
            font-weight: bold;
            margin-bottom: 5px;
        }

        .footer-note {
            font-size: {{ $fontSize - 3 }}px;
            color: #666;
            margin-top: 5px;
        }

        .bold {
            font-weight: bold;
        }

        .right {
            text-align: right;
        }

        .center {
            text-align: center;
        }

        /* Print-specific styles */
        @media print {
            @page {
                size: {{ $cssWidth }} auto;
                margin: 0;
            }

            html, body {
                width: {{ $cssWidth }};
                margin: 0;
                padding: 5px;
            }

            body {
                padding: 5px;
            }

            .no-print {
                display: none !important;
            }
        }

        /* Screen preview styles */
        @media screen {
            body {
                border: 1px dashed #ccc;
                margin: 20px auto;
                box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            }

            .preview-controls {
                position: fixed;
                top: 20px;
                right: 20px;
                display: flex;
                gap: 10px;
            }

            .preview-btn {
                padding: 10px 20px;
                font-size: 14px;
                cursor: pointer;
                border: none;
                border-radius: 4px;
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            }

            .preview-btn-print {
                background: #4CAF50;
                color: white;
            }

            .preview-btn-close {
                background: #666;
                color: white;
            }

            .preview-btn:hover {
                opacity: 0.9;
            }
        }
    </style>
</head>
<body>
    <!-- Preview controls (hidden when printing) -->
    <div class="preview-controls no-print">
        <button class="preview-btn preview-btn-print" onclick="window.print()">{{ trans('plugins/pos-pro::pos.print') }}</button>
        <button class="preview-btn preview-btn-close" onclick="window.close()">{{ trans('plugins/pos-pro::pos.cancel') }}</button>
    </div>

    <!-- Receipt Header -->
    <div class="header">
        @if($showLogo && $storeLogo)
            <img src="{{ RvMedia::getImageUrl($storeLogo) }}" alt="{{ $storeName }}" class="store-logo">
        @else
            <div class="store-name">{{ $storeName }}</div>
        @endif

        @if($showStoreInfo)
            @if($storeAddress)
                <div class="store-info">{{ $storeAddress }}</div>
            @endif

            @if($storePhone)
                <div class="store-info">{{ trans('plugins/pos-pro::pos.phone') }}: {{ $storePhone }}</div>
            @endif
        @endif

        <div class="datetime">
            {{ BaseHelper::formatDate($firstOrder->created_at, 'd/m/Y H:i') }}
        </div>
    </div>

    <div class="line"></div>

    <!-- Receipt Meta -->
    <div class="meta">
        <div class="meta-row">
            <span class="meta-label">{{ trans('plugins/pos-pro::pos.total_orders') }}:</span>
            <span class="meta-value">{{ $orders->count() }}</span>
        </div>
        @if($showCashier)
        <div class="meta-row">
            <span class="meta-label">{{ trans('plugins/pos-pro::pos.cashier') }}:</span>
            <span class="meta-value">{{ $cashierName }}</span>
        </div>
        @endif
        @if($showCustomer)
        <div class="meta-row">
            <span class="meta-label">{{ trans('plugins/pos-pro::pos.customer') }}:</span>
            <span class="meta-value">{{ $customerName }}</span>
        </div>
        @endif
    </div>

    <div class="line-double"></div>

    <!-- Orders by Vendor -->
    @foreach($orders as $index => $order)
        @if(is_plugin_active('marketplace') && $order->store_id && $order->store)
            <div class="vendor-header">
                {{ $order->store->name }}
            </div>
        @endif

        <div class="order-header">
            {{ trans('plugins/pos-pro::receipt.receipt_no') }}: {{ $order->code }}
            @if($order->invoice && $order->invoice->code)
                | {{ trans('plugins/pos-pro::receipt.invoice_code') }}: {{ $order->invoice->code }}
            @endif
        </div>

        <!-- Items Table -->
        <table class="items">
            <thead>
                <tr>
                    <th>{{ trans('plugins/pos-pro::receipt.item') }}</th>
                    <th class="center">{{ trans('plugins/pos-pro::receipt.qty') }}</th>
                    <th class="right">{{ trans('plugins/pos-pro::pos.total') }}</th>
                </tr>
            </thead>
            <tbody>
                @foreach($order->products as $product)
                <tr>
                    <td>
                        <div class="item-name">{{ $product->product_name }}</div>
                        @if ($sku = Arr::get($product->options, 'sku') ?: $product->product->sku ?? '')
                            <div class="item-sku">SKU: {{ $sku }}</div>
                        @endif
                        @if ($attributes = Arr::get($product->options, 'attributes'))
                            <div class="item-attrs">{{ $attributes }}</div>
                        @endif
                        @if($product->qty > 1)
                            <div class="item-sku">@ {{ format_price($product->price) }}</div>
                        @endif
                    </td>
                    <td class="center">{{ $product->qty }}</td>
                    <td class="right">{{ format_price($product->price * $product->qty) }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>

        <!-- Order Subtotal -->
        <div class="order-subtotal">
            <span>{{ trans('plugins/pos-pro::pos.subtotal') }} ({{ $order->code }}):</span>
            <span>{{ format_price($order->amount) }}</span>
        </div>

        @if(!$loop->last)
            <div class="line"></div>
        @endif
    @endforeach

    <div class="line-double"></div>

    <!-- Grand Totals -->
    <div class="grand-total-section">
        <div class="totals-row">
            <span class="label">{{ trans('plugins/pos-pro::pos.subtotal') }}:</span>
            <span class="value">{{ format_price($grandSubTotal) }}</span>
        </div>

        @if($grandDiscount > 0)
        <div class="totals-row discount">
            <span class="label">{{ trans('plugins/pos-pro::pos.discount') }}:</span>
            <span class="value">-{{ format_price($grandDiscount) }}</span>
        </div>
        @endif

        @if ($showVat && EcommerceHelper::isTaxEnabled() && $grandTax > 0)
        <div class="totals-row">
            <span class="label">{{ trans('plugins/pos-pro::receipt.vat_included') }}:</span>
            <span class="value">{{ format_price($grandTax) }}</span>
        </div>
        @endif

        @if($grandShipping > 0)
        <div class="totals-row">
            <span class="label">{{ trans('plugins/pos-pro::pos.shipping') }}:</span>
            <span class="value">{{ format_price($grandShipping) }}</span>
        </div>
        @endif

        <div class="line"></div>

        <div class="totals-row big">
            <span class="label">{{ trans('plugins/pos-pro::pos.grand_total') }}:</span>
            <span class="value">{{ format_price($grandTotal) }}</span>
        </div>
    </div>

    <div class="totals">
        <div class="totals-row">
            <span class="label">{{ trans('plugins/pos-pro::receipt.paid') }} ({{ strip_tags($paymentMethod) }}):</span>
            <span class="value">{{ format_price($grandTotal) }}</span>
        </div>
    </div>

    <!-- Footer -->
    <div class="footer">
        @if($footerText)
            <div class="thank-you">{!! nl2br(e($footerText)) !!}</div>
        @endif
        @if(get_ecommerce_setting('store_website'))
            <div class="footer-note">{{ get_ecommerce_setting('store_website') }}</div>
        @endif
    </div>

    <!-- Auto-print on load -->
    @if($autoPrintThermal)
    <script>
        window.onload = function() {
            // Small delay to ensure content is rendered
            setTimeout(function() {
                window.print();
            }, 300);
        };
    </script>
    @endif
</body>
</html>

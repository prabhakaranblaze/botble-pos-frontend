@if(isset($orderSlots) && count($orderSlots) > 1)
<div class="order-slots-tabs">
    <div class="d-flex align-items-center gap-2 overflow-auto pb-2 m-3">
        @foreach($orderSlots as $slot)
            <button type="button"
                class="btn btn-sm {{ $slot['is_active'] ? 'btn-primary' : 'btn-outline-secondary' }} order-slot-tab d-flex align-items-center gap-2 flex-shrink-0"
                data-slot="{{ $slot['slot'] }}"
                title="{{ trans('plugins/pos-pro::pos.order_slot', ['slot' => $slot['slot']]) }}">
                <span>{{ trans('plugins/pos-pro::pos.order_slot', ['slot' => $slot['slot']]) }}</span>
                @if($slot['item_count'] > 0)
                    <span class="badge {{ $slot['is_active'] ? 'bg-white text-blue-lt-fg' : 'bg-blue text-blue-fg' }}">{{ $slot['item_count'] }}</span>
                @endif
                @if(count($orderSlots) > 1)
                    <span class="close-order-slot ms-1" data-slot="{{ $slot['slot'] }}" title="{{ trans('plugins/pos-pro::pos.close_order') }}">
                        <x-core::icon name="ti ti-x" style="width: 14px; height: 14px;" />
                    </span>
                @endif
            </button>
        @endforeach
        <button type="button" class="btn btn-sm btn-outline-primary add-order-slot flex-shrink-0" title="{{ trans('plugins/pos-pro::pos.add_new_order') }}">
            <x-core::icon name="ti ti-plus" style="width: 16px; height: 16px;" />
        </button>
    </div>
</div>
@endif

@if($cart['count'] === 0)
    <div class="empty">
        <div class="empty-img">
            <x-core::icon name="ti ti-shopping-cart" class="icon-lg text-primary" />
        </div>
        <p class="empty-title">{{ trans('plugins/pos-pro::pos.empty_cart') }}</p>
        <p class="empty-subtitle text-muted">
            {{ trans('plugins/pos-pro::pos.add_products_to_cart') }}
        </p>
    </div>
@else
    <!-- Customer Selection -->
    <div class="card card-sm mb-3">
        <div class="card-header">
            <h3 class="card-title">{{ trans('plugins/pos-pro::pos.customer') }}</h3>
        </div>
        <div class="card-body">
            <div class="mb-2 position-relative">
                <div class="mb-2 customer-search-wrapper">
                    <div class="input-icon">
                        <input type="text" class="form-control" id="customer-search" placeholder="{{ trans('plugins/pos-pro::pos.search_customer') }}" autocomplete="off">
                        <span class="input-icon-addon">
                            <x-core::icon name="ti ti-search" />
                        </span>
                        <input type="hidden" id="customer-id" name="customer_id" value="">
                    </div>
                </div>
                <div id="customer-search-results" class="dropdown-menu w-100" style="max-height: 250px; overflow-y: auto;"></div>
                <div id="selected-customer-info" class="mt-2 p-2 border rounded d-none">
                    <div class="d-flex align-items-center">
                        <div class="me-2">
                            <x-core::icon name="ti ti-user" class="text-primary" />
                        </div>
                        <div class="flex-grow-1">
                            <div class="fw-medium" id="selected-customer-name"></div>
                            <div class="text-muted small" id="selected-customer-contact"></div>
                        </div>
                        <button type="button" id="remove-selected-customer" class="btn btn-sm btn-ghost-danger">
                            <x-core::icon name="ti ti-x" />
                        </button>
                    </div>
                </div>
            </div>
            <div class="text-end">
                <button type="button" class="btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#add-customer-modal">
                    <x-core::icon name="ti ti-plus" class="me-1" /> {{ trans('plugins/pos-pro::pos.add_new_customer') }}
                </button>
            </div>
        </div>
    </div>
    <div class="card card-sm mb-3 cart-items-container">
        <div class="card-header">
            <h3 class="card-title">{{ trans('plugins/pos-pro::pos.cart_items') }}</h3>
            <div class="card-actions">
                <span class="badge bg-blue text-white">{{ $cart['count'] }} {{ trans('plugins/pos-pro::pos.items') }}</span>
            </div>
        </div>
        <div class="list-group list-group-flush">
            @foreach($cart['items'] as $item)
                <div class="list-group-item p-3 cart-item" data-product-id="{{ $item['id'] }}">
                    <!-- First row: Product image, name, and SKU -->
                    <div class="d-flex align-items-center mb-2">
                        <!-- Product image -->
                        <span class="avatar avatar-md rounded-2 me-3" style="background-image: url({{ RvMedia::getImageUrl($item['image']) }})"></span>

                        <!-- Product info -->
                        <div class="overflow-hidden me-auto">
                            <div class="text-truncate fw-medium product-name fs-5" data-bs-toggle="tooltip" title="{{ $item['name'] }}">
                                {{ $item['name'] }}
                            </div>
                            <div class="text-muted d-flex flex-wrap align-items-center">
                                <span class="me-2">{{ $item['sku'] ?? 'SKU: N/A' }}</span>
                                @if (! empty($item['attributes']))
                                    @foreach($item['attributes'] as $attribute)
                                        <span class="badge bg-blue-lt me-1 mb-1">{{ $attribute['set'] }}: {{ $attribute['value'] }}</span>
                                    @endforeach
                                @endif
                            </div>
                        </div>

                        <!-- Remove button -->
                        <button type="button" class="btn btn-icon btn-sm btn-ghost-danger remove-from-cart"
                            data-product-id="{{ $item['id'] }}" data-bs-toggle="tooltip" title="{{ trans('plugins/pos-pro::pos.remove') }}">
                            <x-core::icon name="ti ti-trash" />
                        </button>
                    </div>

                    <!-- Second row: Quantity, price, total -->
                    <div class="d-flex align-items-center">
                        <!-- Quantity controls -->
                        <div class="input-group input-group-flat input-group-sm quantity-controls bg-light rounded">
                            <button type="button" class="btn update-quantity"
                                data-product-id="{{ $item['id'] }}"
                                data-quantity="{{ $item['quantity'] - 1 }}"
                                {{ $item['quantity'] <= 1 ? 'disabled' : '' }}>
                                <x-core::icon name="ti ti-minus" style="width: 12px; height: 12px;" />
                            </button>
                            <input type="text" class="form-control text-center quantity-input"
                                value="{{ $item['quantity'] }}" min="1"
                                onchange="updateQuantity({{ $item['id'] }}, this.value)">
                            <button type="button" class="btn update-quantity"
                                data-product-id="{{ $item['id'] }}"
                                data-quantity="{{ $item['quantity'] + 1 }}">
                                <x-core::icon name="ti ti-plus" style="width: 12px; height: 12px;" />
                            </button>
                        </div>

                        <!-- Price and total -->
                        <div class="ms-auto d-flex align-items-center">
                            <div class="text-muted me-2">
                                {{ format_price($item['price']) }} ×
                            </div>
                            <div class="fw-medium fs-5">
                                {{ format_price($item['price'] * $item['quantity']) }}
                            </div>
                        </div>
                    </div>
                </div>
            @endforeach
        </div>
    </div>

    <div class="card card-sm mb-3">
        <div class="card-header">
            <h3 class="card-title">{{ trans('plugins/pos-pro::pos.payment_method') }}</h3>
        </div>
        <div class="card-body">
            <div class="form-selectgroup form-selectgroup-boxes d-flex flex-column">
                @php
                    $activePaymentMethods = \Botble\PosPro\Facades\PosProHelper::getActivePaymentMethods();
                    $defaultPaymentMethod = \Botble\PosPro\Facades\PosProHelper::getDefaultPaymentMethod();
                    $hasChecked = false;
                @endphp

                @if(in_array('cash', $activePaymentMethods))
                    <label class="form-selectgroup-item flex-fill mb-2">
                        <input type="radio" name="payment_method" value="cash" class="form-selectgroup-input" {{ $defaultPaymentMethod === 'cash' ? 'checked' : '' }}>
                        <div class="form-selectgroup-label d-flex align-items-center p-3">
                            <div class="me-3">
                                <span class="form-selectgroup-check"></span>
                            </div>
                            <div>
                                <x-core::icon name="ti ti-cash" class="me-2" />
                                <span class="form-selectgroup-title strong mb-1">{{ trans('plugins/pos-pro::pos.cash') }}</span>
                                <span class="d-block text-muted">{{ trans('plugins/pos-pro::pos.cash_payment_description') }}</span>
                            </div>
                        </div>
                    </label>
                    @php $hasChecked = $hasChecked || $defaultPaymentMethod === 'cash'; @endphp
                @endif

                @if(in_array('card', $activePaymentMethods))
                    <label class="form-selectgroup-item flex-fill mb-2">
                        <input type="radio" name="payment_method" value="card" class="form-selectgroup-input" {{ !$hasChecked && $defaultPaymentMethod === 'card' ? 'checked' : '' }}>
                        <div class="form-selectgroup-label d-flex align-items-center p-3">
                            <div class="me-3">
                                <span class="form-selectgroup-check"></span>
                            </div>
                            <div>
                                <x-core::icon name="ti ti-credit-card" class="me-2" />
                                <span class="form-selectgroup-title strong mb-1">{{ trans('plugins/pos-pro::pos.card') }}</span>
                                <span class="d-block text-muted">{{ trans('plugins/pos-pro::pos.card_payment_description') }}</span>
                            </div>
                        </div>
                    </label>
                    @php $hasChecked = $hasChecked || $defaultPaymentMethod === 'card'; @endphp
                @endif

                @if(in_array('other', $activePaymentMethods))
                    <label class="form-selectgroup-item flex-fill">
                        <input type="radio" name="payment_method" value="other" class="form-selectgroup-input" {{ !$hasChecked && $defaultPaymentMethod === 'other' ? 'checked' : '' }}>
                        <div class="form-selectgroup-label d-flex align-items-center p-3">
                            <div class="me-3">
                                <span class="form-selectgroup-check"></span>
                            </div>
                            <div>
                                <x-core::icon name="ti ti-wallet" class="me-2" />
                                <span class="form-selectgroup-title strong mb-1">{{ trans('plugins/pos-pro::pos.other') }}</span>
                                <span class="d-block text-muted">{{ trans('plugins/pos-pro::pos.other_payment_description') }}</span>
                            </div>
                        </div>
                    </label>
                @endif

                @if(empty($activePaymentMethods))
                    <div class="alert alert-warning">
                        {{ trans('plugins/pos-pro::pos.no_active_payment_methods') }}
                    </div>
                @endif
            </div>
        </div>
    </div>

    <div class="card card-sm cart-summary">
        <div class="card-header">
            <h3 class="card-title">{{ trans('plugins/pos-pro::pos.order_summary') }}</h3>
            <div class="card-actions">
                <div class="btn-group">
                    <button type="button" class="btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#coupon-modal">
                        <x-core::icon name="ti ti-discount-check" class="me-1" /> {{ trans('plugins/pos-pro::pos.coupon') }}
                    </button>
                    <button type="button" class="btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#discount-modal">
                        <x-core::icon name="ti ti-discount" class="me-1" /> {{ trans('plugins/pos-pro::pos.discount') }}
                    </button>
                    <button type="button" class="btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#shipping-modal">
                        <x-core::icon name="ti ti-truck-delivery" class="me-1" /> {{ trans('plugins/pos-pro::pos.shipping') }}
                    </button>
                </div>
            </div>
        </div>
        <div class="card-body">
            <div class="datagrid">
                <div class="datagrid-item">
                    <div class="datagrid-title">{{ trans('plugins/pos-pro::pos.subtotal') }}</div>
                    <div class="datagrid-content">{{ $cart['subtotal_formatted'] }}</div>
                </div>

                @if(isset($cart['coupon_discount']) && $cart['coupon_discount'] > 0)
                <div class="datagrid-item">
                    <div class="datagrid-title">
                        <div class="d-flex align-items-center">
                            <x-core::icon name="ti ti-discount-check" class="me-1 text-primary" />
                            {{ trans('plugins/pos-pro::pos.coupon_discount') }}
                            @if(isset($cart['coupon_code']))
                                <span class="-lt ms-1">{{ $cart['coupon_code'] }}</span>
                            @endif
                        </div>
                    </div>
                    <div class="datagrid-content text-danger">-{{ $cart['coupon_discount_formatted'] }}</div>
                </div>
                @endif

                @if(isset($cart['manual_discount']) && $cart['manual_discount'] > 0)
                <div class="datagrid-item">
                    <div class="datagrid-title">
                        <div class="d-flex align-items-center">
                            <x-core::icon name="ti ti-discount" class="me-1 text-primary" />
                            {{ trans('plugins/pos-pro::pos.manual_discount') }}
                            @if(isset($cart['manual_discount_type']) && $cart['manual_discount_type'] === 'percentage')
                                <span class="badge bg-blue-lt ms-1">{{ $cart['manual_discount_value'] }}%</span>
                            @endif
                            @if(isset($cart['manual_discount_description']) && $cart['manual_discount_description'])
                                <span class="badge bg-blue-lt ms-1" title="{{ $cart['manual_discount_description'] }}">{{ Str::limit($cart['manual_discount_description'], 15) }}</span>
                            @endif
                        </div>
                    </div>
                    <div class="datagrid-content text-danger">-{{ $cart['manual_discount_formatted'] }}</div>
                </div>
                @endif

                <div class="datagrid-item">
                    <div class="datagrid-title">{{ trans('plugins/pos-pro::pos.tax') }}</div>
                    <div class="datagrid-content">{{ $cart['tax_formatted'] }}</div>
                </div>

                <div class="datagrid-item">
                    <div class="datagrid-title">
                        <div class="d-flex align-items-center">
                            <x-core::icon name="ti ti-truck-delivery" class="me-1 text-primary" />
                            {{ trans('plugins/pos-pro::pos.shipping') }}
                        </div>
                    </div>
                    <div class="datagrid-content">{{ $cart['shipping_amount_formatted'] }}</div>
                </div>
            </div>

            <div class="hr-text">{{ trans('plugins/pos-pro::pos.total') }}</div>

            <div class="d-flex justify-content-between align-items-center fw-bold">
                <span class="fs-4">{{ trans('plugins/pos-pro::pos.total') }}</span>
                <span class="fs-2 text-primary">{{ $cart['total_formatted'] }}</span>
            </div>
        </div>
    </div>
@endif
